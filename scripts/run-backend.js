const fs = require('fs');
const path = require('path');
const { spawn, spawnSync } = require('child_process');

const rawArgs = process.argv.slice(2);
const useCloudflare = rawArgs.includes('--cloudflare');
const isDryRun = rawArgs.includes('--dry-run');

const repoRoot = path.resolve(__dirname, '..');
const backendDir = path.join(repoRoot, 'backend');
const runtimeDir = path.join(repoRoot, '.runtime');
const runtimeTunnelUrlPath = path.join(runtimeDir, 'cloudflare-url.txt');
const cloudflaredLogPath = path.join(repoRoot, 'cloudflared-runtime.log');
const backendPort = process.env.A4M_BACKEND_PORT || '8000';
const backendHost = process.env.A4M_BACKEND_HOST || '0.0.0.0';
const cloudflaredCommand =
  process.platform === 'win32' ? 'cloudflared.exe' : 'cloudflared';

let backendProcess = null;
let cloudflaredProcess = null;
let shuttingDown = false;

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
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

function cleanupRuntimeFiles() {
  if (fs.existsSync(runtimeTunnelUrlPath)) {
    fs.unlinkSync(runtimeTunnelUrlPath);
  }

  if (fs.existsSync(cloudflaredLogPath)) {
    fs.unlinkSync(cloudflaredLogPath);
  }
}

function shutdown(code = 0) {
  if (shuttingDown) {
    return;
  }

  shuttingDown = true;
  killChild(cloudflaredProcess);
  killChild(backendProcess);
  cleanupRuntimeFiles();
  process.exit(code);
}

async function readUrl(url) {
  const response = await fetch(url, {
    method: 'GET',
    redirect: 'follow',
  });

  return {
    status: response.status,
    body: await response.text(),
  };
}

async function waitForBackendReady(timeoutMs = 45000) {
  const startedAt = Date.now();
  const probeUrls = [
    `http://127.0.0.1:${backendPort}/`,
    `http://localhost:${backendPort}/`,
  ];

  while (Date.now() - startedAt < timeoutMs) {
    if (backendProcess?.exitCode !== null) {
      throw new Error(
        `El backend se cerró antes de quedar disponible (código ${backendProcess.exitCode}).`,
      );
    }

    for (const url of probeUrls) {
      try {
        const { status } = await readUrl(url);
        if (status < 500) {
          console.log(`[backend-runner] Backend listo en: ${url}`);
          return;
        }
      } catch (_) {
        // Seguir intentando mientras el backend termina de arrancar.
      }
    }

    await wait(1000);
  }

  throw new Error(
    'Tiempo de espera agotado mientras el backend quedaba disponible.',
  );
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
        console.log(`[backend-runner] Tunnel listo en: ${readinessUrl}`);
        return;
      }
    } catch (_) {
      // Seguir intentando mientras Cloudflare propaga la URL.
    }

    await wait(1500);
  }

  throw new Error(
    'Cloudflare entregó una URL, pero no quedó disponible a tiempo. Intenta nuevamente en unos segundos.',
  );
}

function writeRuntimeTunnelUrl(tunnelUrl) {
  fs.mkdirSync(runtimeDir, { recursive: true });
  fs.writeFileSync(runtimeTunnelUrlPath, `${tunnelUrl}\n`, 'utf8');
  console.log(
    `[backend-runner] URL pública guardada en: ${path.relative(repoRoot, runtimeTunnelUrlPath)}`,
  );
}

function startBackend() {
  const backendArgs = [
    'artisan',
    'serve',
    '--host',
    backendHost,
    '--port',
    backendPort,
  ];

  const child =
    process.platform === 'win32'
      ? spawn('cmd.exe', ['/d', '/s', '/c', 'php', ...backendArgs], {
          cwd: backendDir,
          stdio: ['inherit', 'pipe', 'pipe'],
        })
      : spawn('php', backendArgs, {
          cwd: backendDir,
          stdio: ['inherit', 'pipe', 'pipe'],
        });

  backendProcess = child;
  pipeWithPrefix(child.stdout, process.stdout, '[backend] ');
  pipeWithPrefix(child.stderr, process.stderr, '[backend] ');

  child.on('exit', (code) => {
    shutdown(code ?? 0);
  });

  child.on('error', (error) => {
    console.error(
      `[backend-runner] No se pudo iniciar Laravel: ${error.message}`,
    );
    shutdown(1);
  });
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
      `http://127.0.0.1:${backendPort}`,
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
  console.log(`[backend-runner] Tunnel detectado: ${tunnelUrl}`);
  await waitForTunnelReady(tunnelUrl);
  writeRuntimeTunnelUrl(tunnelUrl);
}

async function main() {
  cleanupRuntimeFiles();
  startBackend();
  await waitForBackendReady();

  if (useCloudflare) {
    await startCloudflareTunnel();
  }

  if (isDryRun) {
    shutdown(0);
  }
}

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));
process.on('exit', () => {
  killChild(cloudflaredProcess);
  killChild(backendProcess);
  cleanupRuntimeFiles();
});

main().catch((error) => {
  console.error(`[backend-runner] ${error.message}`);
  shutdown(1);
});
