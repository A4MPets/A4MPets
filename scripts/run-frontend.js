const fs = require('fs');
const http = require('http');
const os = require('os');
const path = require('path');
const { spawn, spawnSync } = require('child_process');

const rawArgs = process.argv.slice(2);
const args = new Set(rawArgs);
const isAndroid = args.has('--android');
const useCloudflare = args.has('--cloudflare');
const useFrontendCloudflare = args.has('--frontend-cloudflare');
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
const frontendCloudflaredLogPath = path.join(
  repoRoot,
  'cloudflared-frontend-runtime.log',
);
const defaultRuntimeTunnelUrlPath = path.join(
  repoRoot,
  '.runtime',
  'cloudflare-url.txt',
);
const frontendRuntimeTunnelUrlPath = path.join(
  repoRoot,
  '.runtime',
  'frontend-cloudflare-url.txt',
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
let frontendCloudflaredProcess = null;
let flutterProcess = null;
let frontendStaticServer = null;
let activeCloudflaredLogPath = cloudflaredLogPath;
let activeFrontendCloudflaredLogPath = frontendCloudflaredLogPath;
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

function safeUnlink(filePath) {
  if (!fs.existsSync(filePath)) {
    return;
  }

  try {
    fs.unlinkSync(filePath);
  } catch (error) {
    if (error.code !== 'ENOENT') {
      console.warn(
        `[runner] No se pudo borrar ${path.relative(repoRoot, filePath)}: ${error.message}`,
      );
    }
  }
}

function prepareLogPath(filePath) {
  if (!fs.existsSync(filePath)) {
    return filePath;
  }

  try {
    fs.unlinkSync(filePath);
    return filePath;
  } catch (error) {
    const parsed = path.parse(filePath);
    const fallbackPath = path.join(
      parsed.dir,
      `${parsed.name}-${process.pid}-${Date.now()}${parsed.ext}`,
    );

    console.warn(
      `[runner] ${path.relative(repoRoot, filePath)} esta ocupado; usando ${path.relative(repoRoot, fallbackPath)}.`,
    );

    return fallbackPath;
  }
}

function closeFrontendStaticServer() {
  if (!frontendStaticServer) {
    return;
  }

  frontendStaticServer.close();
  frontendStaticServer = null;
}

function shutdown(code = 0) {
  if (shuttingDown) {
    return;
  }

  shuttingDown = true;
  closeFrontendStaticServer();
  killChild(flutterProcess);
  killChild(frontendCloudflaredProcess);
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

async function waitForTunnelUrl(
  child,
  timeoutMs = 45000,
  logPath = cloudflaredLogPath,
) {
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    if (child.exitCode !== null) {
      throw new Error(
        `cloudflared termino antes de entregar URL publica (codigo ${child.exitCode}).`,
      );
    }

    if (fs.existsSync(logPath)) {
      const logText = fs.readFileSync(logPath, 'utf8');
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
  const logPath = prepareLogPath(cloudflaredLogPath);
  activeCloudflaredLogPath = logPath;

  const child = spawn(
    cloudflaredCommand,
    [
      'tunnel',
      '--url',
      `http://localhost:${backendPort}`,
      '--no-autoupdate',
      '--logfile',
      logPath,
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

  const tunnelUrl = await waitForTunnelUrl(child, 45000, logPath);
  console.log(`[runner] Tunnel detectado: ${tunnelUrl}`);
  return tunnelUrl;
}

async function waitForTunnelReady(
  url,
  timeoutMs = 60000,
  getProcess = () => cloudflaredProcess,
) {
  const startedAt = Date.now();
  const readinessUrl = `${url.replace(/\/$/, '')}/`;

  while (Date.now() - startedAt < timeoutMs) {
    const processRef = getProcess();
    if (processRef?.exitCode !== null) {
      throw new Error(
        `cloudflared se cerro antes de que el tunel quedara disponible (codigo ${processRef.exitCode}).`,
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
    'Cloudflare entrego una URL, pero no quedo disponible a tiempo. Intenta nuevamente en unos segundos.',
  );
}

async function waitForLocalFrontendReady(timeoutMs = 120000) {
  const startedAt = Date.now();
  const url = `http://localhost:${webPort}/`;

  while (Date.now() - startedAt < timeoutMs) {
    if (flutterProcess?.exitCode !== null) {
      throw new Error(
        `Flutter se cerro antes de quedar disponible (codigo ${flutterProcess.exitCode}).`,
      );
    }

    try {
      const { status } = await readUrl(url);
      if (status < 500) {
        console.log(`[runner] Frontend listo en: ${url}`);
        return;
      }
    } catch (_) {
      // Flutter web todavia esta compilando o levantando el servidor.
    }

    await wait(1000);
  }

  throw new Error('Tiempo de espera agotado mientras Flutter web quedaba disponible.');
}

async function startFrontendCloudflareTunnel() {
  const logPath = prepareLogPath(frontendCloudflaredLogPath);
  activeFrontendCloudflaredLogPath = logPath;

  const child = spawn(
    cloudflaredCommand,
    [
      'tunnel',
      '--url',
      `http://localhost:${webPort}`,
      '--no-autoupdate',
      '--logfile',
      logPath,
      '--loglevel',
      'info',
    ],
    {
      cwd: repoRoot,
      stdio: ['inherit', 'pipe', 'pipe'],
    },
  );

  frontendCloudflaredProcess = child;
  pipeWithPrefix(child.stdout, process.stdout, '[frontend-cloudflared] ');
  pipeWithPrefix(child.stderr, process.stderr, '[frontend-cloudflared] ');

  const tunnelUrl = await waitForTunnelUrl(
    child,
    45000,
    logPath,
  );
  console.log(`[runner] Frontend Cloudflare detectado: ${tunnelUrl}`);
  await waitForTunnelReady(tunnelUrl, 60000, () => frontendCloudflaredProcess);

  fs.mkdirSync(path.dirname(frontendRuntimeTunnelUrlPath), { recursive: true });
  fs.writeFileSync(frontendRuntimeTunnelUrlPath, `${tunnelUrl}\n`, 'utf8');
  console.log(`[runner] URL publica del frontend: ${tunnelUrl}`);
  console.log(
    `[runner] URL publica guardada en: ${path.relative(repoRoot, frontendRuntimeTunnelUrlPath)}`,
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

function getContentType(filePath) {
  const extension = path.extname(filePath).toLowerCase();
  const contentTypes = {
    '.css': 'text/css; charset=utf-8',
    '.html': 'text/html; charset=utf-8',
    '.ico': 'image/x-icon',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.map': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.wasm': 'application/wasm',
    '.webmanifest': 'application/manifest+json; charset=utf-8',
  };

  return contentTypes[extension] || 'application/octet-stream';
}

function runFlutterBuildWebRelease() {
  const flutterArgs = [
    'build',
    'web',
    '--release',
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

  return new Promise((resolve, reject) => {
    child.on('exit', (code) => {
      flutterProcess = null;

      if (code === 0) {
        resolve();
        return;
      }

      reject(new Error(`Flutter build web fallo con codigo ${code ?? 'desconocido'}.`));
    });

    child.on('error', (error) => {
      flutterProcess = null;
      reject(new Error(`No se pudo iniciar Flutter build web: ${error.message}`));
    });
  });
}

function sendStaticFile(response, filePath) {
  response.writeHead(200, {
    'Content-Type': getContentType(filePath),
  });
  fs.createReadStream(filePath).pipe(response);
}

function startStaticFrontendServer() {
  const buildWebDir = path.join(frontendDir, 'build', 'web');
  const indexPath = path.join(buildWebDir, 'index.html');

  if (!fs.existsSync(indexPath)) {
    throw new Error(
      `No existe ${path.relative(repoRoot, indexPath)}. Ejecuta primero flutter build web.`,
    );
  }

  const server = http.createServer((request, response) => {
    try {
      const requestUrl = new URL(request.url || '/', `http://${request.headers.host || 'localhost'}`);
      const pathname = decodeURIComponent(requestUrl.pathname);
      let filePath = path.resolve(buildWebDir, `.${pathname}`);
      const isInsideBuildDir =
        filePath === buildWebDir || filePath.startsWith(`${buildWebDir}${path.sep}`);

      if (!isInsideBuildDir) {
        response.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
        response.end('Forbidden');
        return;
      }

      if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
        filePath = path.join(filePath, 'index.html');
      }

      if (!fs.existsSync(filePath)) {
        if (path.extname(filePath)) {
          response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
          response.end('Not found');
          return;
        }

        filePath = indexPath;
      }

      sendStaticFile(response, filePath);
    } catch (error) {
      response.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end(error.message);
    }
  });

  frontendStaticServer = server;

  return new Promise((resolve, reject) => {
    server.on('error', reject);
    server.listen(Number(webPort), 'localhost', () => {
      console.log(`[runner] Frontend release servido en: http://localhost:${webPort}/`);
      resolve();
    });
  });
}

async function startFlutterReleaseFrontend() {
  console.log('[runner] Compilando frontend Flutter web en modo release...');
  await runFlutterBuildWebRelease();
  await startStaticFrontendServer();
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

  if (useFrontendCloudflare && !isAndroid) {
    await startFlutterReleaseFrontend();
    await startFrontendCloudflareTunnel();
    return;
  }

  startFlutter();
}

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));
process.on('exit', () => {
  closeFrontendStaticServer();
  killChild(flutterProcess);
  killChild(frontendCloudflaredProcess);
  killChild(cloudflaredProcess);
  if (cloudflaredProcess) {
    safeUnlink(activeCloudflaredLogPath);
  }
  if (frontendCloudflaredProcess) {
    safeUnlink(activeFrontendCloudflaredLogPath);
  }
});

main().catch((error) => {
  console.error(`[runner] ${error.message}`);
  shutdown(1);
});
