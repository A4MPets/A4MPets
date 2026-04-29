const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, spawnSync } = require('child_process');

const rawArgs = process.argv.slice(2);
const args = new Set(rawArgs);
const isAndroid = args.has('--android');
const useCloudflare = args.has('--cloudflare');
const isDryRun = args.has('--dry-run');

function getFlagValue(flag) {
  const index = rawArgs.indexOf(flag);
  if (index === -1) {
    return null;
  }

  const value = rawArgs[index + 1];
  if (!value || value.startsWith('--')) {
    return null;
  }

  return value;
}

const repoRoot = path.resolve(__dirname, '..');
const frontendDir = path.join(repoRoot, 'frontend');
const runtimeEnvPath = path.join(frontendDir, 'env', 'runtime.local.json');
const cloudflaredLogPath = path.join(repoRoot, 'cloudflared-runtime.log');
const defaultRuntimeTunnelUrlPath = path.join(
  repoRoot,
  '.runtime',
  'cloudflare-url.txt',
);
const backendPort = process.env.A4M_BACKEND_PORT || '8000';
const webPort = process.env.A4M_WEB_PORT || '7357';
const cloudflaredCommand =
  process.platform === 'win32' ? 'cloudflared.exe' : 'cloudflared';
const explicitTunnelUrl = getFlagValue('--url');
const runtimeTunnelUrlFileArg = getFlagValue('--url-file');
const runtimeTunnelUrlFile = runtimeTunnelUrlFileArg
  ? path.resolve(repoRoot, runtimeTunnelUrlFileArg)
  : defaultRuntimeTunnelUrlPath;

let cloudflaredProcess = null;
let flutterProcess = null;
let shuttingDown = false;

function getLanIpv4Address() {
  const interfaces = os.networkInterfaces();

  for (const addresses of Object.values(interfaces)) {
    for (const address of addresses || []) {
      if (
        address &&
        address.family === 'IPv4' &&
        !address.internal &&
        !address.address.startsWith('169.254.')
      ) {
        return address.address;
      }
    }
  }

  return null;
}

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

function buildBaseUrls({ lanIp, tunnelUrl }) {
  const localUrls = isAndroid
    ? [
        lanIp ? `http://${lanIp}:${backendPort}/api` : null,
        `http://10.0.2.2:${backendPort}/api`,
        `http://127.0.0.1:${backendPort}/api`,
        `http://localhost:${backendPort}/api`,
      ]
    : [
        `http://localhost:${backendPort}/api`,
        `http://127.0.0.1:${backendPort}/api`,
        lanIp ? `http://${lanIp}:${backendPort}/api` : null,
      ];

  return unique([
    tunnelUrl ? `${tunnelUrl.replace(/\/$/, '')}/api` : null,
    ...localUrls,
  ]);
}

function writeRuntimeEnv(urls) {
  fs.mkdirSync(path.dirname(runtimeEnvPath), { recursive: true });
  fs.writeFileSync(
    runtimeEnvPath,
    `${JSON.stringify({ A4M_API_BASE_URL: urls.join(',') }, null, 2)}\n`,
    'utf8',
  );
}

function pipeWithPrefix(stream, target, prefix) {
  let buffer = '';

  stream.on('data', (chunk) => {
    buffer += chunk.toString();
    const lines = buffer.split(/\r?\n/);
    buffer = lines.pop() || '';

    for (const line of lines) {
      target.write(`${prefix}${line}\n`);
    }
  });

  stream.on('end', () => {
    if (buffer.length > 0) {
      target.write(`${prefix}${buffer}\n`);
    }
  });
}

function killChild(child) {
  if (!child || child.killed) {
    return;
  }

  if (process.platform === 'win32') {
    spawnSync('taskkill', ['/pid', String(child.pid), '/t', '/f'], {
      stdio: 'ignore',
    });
    return;
  }

  child.kill('SIGINT');

  setTimeout(() => {
    if (!child.killed) {
      child.kill('SIGTERM');
    }
  }, 1500);
}

function shutdown(code = 0) {
  if (shuttingDown) {
    return;
  }

  shuttingDown = true;
  killChild(flutterProcess);
  killChild(cloudflaredProcess);
  process.exit(code);
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function readUrl(url) {
  const response = await fetch(url, {
    method: 'GET',
    redirect: 'follow',
  });
  const body = await response.text();

  return {
    status: response.status,
    body,
  };
}

async function waitForTunnelUrl(child, timeoutMs = 45000) {
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    if (child.exitCode !== null) {
      throw new Error(
        `cloudflared terminó antes de entregar URL pública (código ${child.exitCode}).`,
      );
    }

    if (fs.existsSync(cloudflaredLogPath)) {
      const logText = fs.readFileSync(cloudflaredLogPath, 'utf8');
      const match = logText.match(/https:\/\/[-a-z0-9.]+trycloudflare\.com/i);
      if (match) {
        return match[0];
      }
    }

    await wait(500);
  }

  throw new Error('Tiempo de espera agotado para cloudflared.');
}

async function waitForTunnelUrlFile(filePath, timeoutMs = 60000) {
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    if (fs.existsSync(filePath)) {
      const fileText = fs.readFileSync(filePath, 'utf8').trim();
      if (fileText.length > 0) {
        return fileText;
      }
    }

    await wait(500);
  }

  throw new Error(
    `Tiempo de espera agotado para la URL runtime en ${path.relative(repoRoot, filePath)}.`,
  );
}

async function startCloudflareTunnel() {
  if (fs.existsSync(cloudflaredLogPath)) {
    fs.unlinkSync(cloudflaredLogPath);
  }

  const child = spawn(
    cloudflaredCommand,
    [
      'tunnel',
      '--url',
      `http://localhost:${backendPort}`,
      '--no-autoupdate',
      '--logfile',
      cloudflaredLogPath,
      '--loglevel',
      'info',
    ],
    {
      cwd: repoRoot,
      stdio: ['inherit', 'pipe', 'pipe'],
    },
  );

  cloudflaredProcess = child;
  pipeWithPrefix(child.stdout, process.stdout, '[cloudflared] ');
  pipeWithPrefix(child.stderr, process.stderr, '[cloudflared] ');

  const tunnelUrl = await waitForTunnelUrl(child);
  console.log(`[runner] Tunnel detectado: ${tunnelUrl}`);
  return tunnelUrl;
}

async function waitForTunnelReady(url, timeoutMs = 60000) {
  const startedAt = Date.now();
  const readinessUrl = `${url.replace(/\/$/, '')}/`;

  while (Date.now() - startedAt < timeoutMs) {
    if (cloudflaredProcess?.exitCode !== null) {
      throw new Error(
        `cloudflared se cerró antes de que el túnel quedara disponible (código ${cloudflaredProcess.exitCode}).`,
      );
    }

    try {
      const { status, body } = await readUrl(readinessUrl);
      const normalizedBody = body.toLowerCase();
      const hasCloudflare1033 =
        status === 530 ||
        normalizedBody.includes('error 1033') ||
        normalizedBody.includes('cloudflare tunnel error');

      if (!hasCloudflare1033 && status < 500) {
        console.log(`[runner] Tunnel listo en: ${readinessUrl}`);
        return;
      }
    } catch (_) {
      // Seguimos intentando mientras Cloudflare propaga la URL.
    }

    await wait(1500);
  }

  throw new Error(
    'Cloudflare entregó una URL, pero no quedó disponible a tiempo. Intenta nuevamente en unos segundos.',
  );
}

function startFlutter() {
  const flutterArgs = isAndroid
    ? ['run', '--dart-define-from-file=env/runtime.local.json']
    : [
        'run',
        '-d',
        'chrome',
        '--web-hostname',
        'localhost',
        '--web-port',
        webPort,
        '--dart-define-from-file=env/runtime.local.json',
      ];

  const child =
    process.platform === 'win32'
      ? spawn('cmd.exe', ['/d', '/s', '/c', 'flutter', ...flutterArgs], {
          cwd: frontendDir,
          stdio: 'inherit',
        })
      : spawn('flutter', flutterArgs, {
          cwd: frontendDir,
          stdio: 'inherit',
        });

  flutterProcess = child;

  child.on('exit', (code) => {
    shutdown(code ?? 0);
  });

  child.on('error', (error) => {
    console.error(`[runner] No se pudo iniciar Flutter: ${error.message}`);
    shutdown(1);
  });
}

async function main() {
  const lanIp = getLanIpv4Address();
  let tunnelUrl = null;

  if (explicitTunnelUrl) {
    tunnelUrl = explicitTunnelUrl;
  } else if (args.has('--url-file')) {
    tunnelUrl = await waitForTunnelUrlFile(runtimeTunnelUrlFile);
    console.log(`[runner] URL runtime detectada: ${tunnelUrl}`);
  } else if (useCloudflare) {
    tunnelUrl = await startCloudflareTunnel();
    await waitForTunnelReady(tunnelUrl);
  }

  const urls = buildBaseUrls({ lanIp, tunnelUrl });

  if (urls.length === 0) {
    throw new Error('No fue posible construir ninguna URL base para el frontend.');
  }

  writeRuntimeEnv(urls);

  console.log(`[runner] URLs API configuradas: ${urls.join(' | ')}`);
  console.log(`[runner] Archivo generado: ${path.relative(repoRoot, runtimeEnvPath)}`);

  if (isDryRun) {
    shutdown(0);
    return;
  }

  startFlutter();
}

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));
process.on('exit', () => {
  killChild(flutterProcess);
  killChild(cloudflaredProcess);
  if (fs.existsSync(cloudflaredLogPath)) {
    fs.unlinkSync(cloudflaredLogPath);
  }
});

main().catch((error) => {
  console.error(`[runner] ${error.message}`);
  shutdown(1);
});
