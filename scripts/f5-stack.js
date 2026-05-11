const fs = require('fs');
const http = require('http');
const path = require('path');
const { spawn, spawnSync, execFileSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '..');
const backendDir = path.join(repoRoot, 'backend');
const frontendDir = path.join(repoRoot, 'frontend');
const evidenceDir = process.env.A4M_F5_EVIDENCE_DIR || path.join(repoRoot, 'test-results', 'f5-stack');
const runtimeEnvPath = path.join(frontendDir, 'env', 'runtime.local.json');
const logPath = path.join(evidenceDir, 'f5-stack.log');

const backendPort = process.env.A4M_F5_BACKEND_PORT || '8000';
const frontendPort = process.env.A4M_F5_FRONTEND_PORT || '7357';
const readyPort = process.env.A4M_F5_READY_PORT || '7358';
const backendBase = `http://127.0.0.1:${backendPort}`;
const apiBase = `${backendBase}/api`;
const frontendBase = `http://127.0.0.1:${frontendPort}`;
const graphhopperBase = process.env.GRAPHHOPPER_BASE_URL || 'http://127.0.0.1:8989';

const processes = [];
let readyServer = null;
let shuttingDown = false;

fs.mkdirSync(evidenceDir, { recursive: true });
fs.writeFileSync(logPath, '', 'utf8');

function writeLog(message) {
  const line = `[F5-stack] ${new Date().toISOString()} ${message}`;
  console.log(line);
  fs.appendFileSync(logPath, `${line}\n`, 'utf8');
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function commandExists(command, args = ['--version']) {
  const result = spawnSync(command, args, { stdio: 'ignore' });
  return result.status === 0;
}

function run(command, args, options = {}) {
  writeLog(`$ ${command} ${args.join(' ')}`);
  const output = execFileSync(command, args, {
    cwd: options.cwd || repoRoot,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, ...(options.env || {}) },
  });
  if (output.trim()) {
    writeLog(output.trim());
  }
  return output.trim();
}

function startProcess(command, args, options) {
  writeLog(`spawn ${command} ${args.join(' ')}`);
  const child =
    process.platform === 'win32'
      ? spawn('cmd.exe', ['/d', '/s', '/c', command, ...args], options)
      : spawn(command, args, options);

  processes.push(child);
  child.stdout?.on('data', (chunk) => writeLog(chunk.toString().trimEnd()));
  child.stderr?.on('data', (chunk) => writeLog(chunk.toString().trimEnd()));
  return child;
}

function waitForProcessOutput(child, pattern, timeoutMs, label) {
  return new Promise((resolve, reject) => {
    const startedAt = Date.now();
    let settled = false;

    const cleanup = () => {
      child.stdout?.off('data', onData);
      child.stderr?.off('data', onData);
      clearInterval(timer);
    };
    const finish = (callback, value) => {
      if (settled) {
        return;
      }
      settled = true;
      cleanup();
      callback(value);
    };
    const onData = (chunk) => {
      const text = chunk.toString();
      if (pattern.test(text)) {
        writeLog(`${label} ready from Flutter output`);
        finish(resolve);
      }
    };
    const timer = setInterval(() => {
      if (child.exitCode !== null) {
        finish(reject, new Error(`${label} stopped before readiness output.`));
        return;
      }
      if (Date.now() - startedAt > timeoutMs) {
        finish(reject, new Error(`${label} output was not observed before timeout.`));
      }
    }, 500);

    child.stdout?.on('data', onData);
    child.stderr?.on('data', onData);
  });
}

function stopProcess(child) {
  if (!child || child.exitCode !== null) {
    return;
  }
  if (process.platform === 'win32') {
    spawnSync('taskkill', ['/pid', String(child.pid), '/t', '/f'], {
      stdio: 'ignore',
    });
    return;
  }
  child.kill('SIGTERM');
}

function shutdown(code = 0) {
  if (shuttingDown) {
    return;
  }
  shuttingDown = true;
  writeLog(`shutdown ${code}`);
  readyServer?.close();
  for (const child of processes.reverse()) {
    stopProcess(child);
  }
  process.exit(code);
}

async function waitForHttp(url, predicate, timeoutMs, label) {
  const startedAt = Date.now();
  let lastError = null;

  while (Date.now() - startedAt < timeoutMs) {
    try {
      const response = await fetch(url, { redirect: 'follow' });
      const text = await response.text();
      if (predicate(response, text)) {
        writeLog(`${label} ready at ${url}`);
        return { status: response.status, text };
      }
      lastError = new Error(`${label} returned ${response.status}`);
    } catch (error) {
      lastError = error;
    }
    await wait(1500);
  }

  throw new Error(`${label} was not ready: ${lastError?.message || 'timeout'}`);
}

async function ensureGraphHopper() {
  if (!commandExists('docker')) {
    throw new Error('Docker is not available in PATH.');
  }

  run('docker', ['compose', 'up', '-d', 'graphhopper']);

  await waitForHttp(
    `${graphhopperBase}/health`,
    (response) => response.status < 500,
    180000,
    'GraphHopper health'
  ).catch(async () => {
    await waitForHttp(
      `${graphhopperBase}/route?point=3.4516,-76.5320&point=3.4570,-76.5280&profile=car&type=json`,
      (response, text) => response.status === 200 && text.includes('paths'),
      180000,
      'GraphHopper route'
    );
  });

  const ps = run('docker', [
    'ps',
    '--filter',
    'name=a4mpets-graphhopper',
    '--format',
    '{{.Names}} {{.Status}}',
  ]);

  if (!ps.includes('a4mpets-graphhopper')) {
    throw new Error('GraphHopper container is not running.');
  }
}

async function ensureBackend() {
  try {
    await waitForHttp(
      `${apiBase}/health`,
      (response, text) => response.status === 200 && text.includes('"ok"'),
      2000,
      'existing Laravel backend'
    );
    return;
  } catch (_) {
    // Start a local backend below.
  }

  run('php', ['artisan', 'migrate', '--force'], { cwd: backendDir });
  startProcess('php', ['artisan', 'serve', '--host', '127.0.0.1', '--port', backendPort], {
    cwd: backendDir,
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  await waitForHttp(
    `${apiBase}/health`,
    (response, text) => response.status === 200 && text.includes('"ok"'),
    45000,
    'Laravel backend'
  );
}

async function ensureFrontend() {
  fs.mkdirSync(path.dirname(runtimeEnvPath), { recursive: true });
  fs.writeFileSync(
    runtimeEnvPath,
    `${JSON.stringify({ A4M_API_BASE_URL: `http://127.0.0.1:${backendPort}/api` }, null, 2)}\n`,
    'utf8'
  );
  writeLog(`runtime env written to ${path.relative(repoRoot, runtimeEnvPath)}`);

  try {
    await waitForHttp(
      frontendBase,
      (response, text) => response.status === 200 && text.toLowerCase().includes('flutter'),
      2000,
      'existing Flutter frontend'
    );
    return;
  } catch (_) {
    // Start a local frontend web server below.
  }

  const child = startProcess(
    'flutter',
    [
      'run',
      '-d',
      'web-server',
      '--web-hostname',
      '127.0.0.1',
      '--web-port',
      frontendPort,
      '--dart-define-from-file=env/runtime.local.json',
      '--dart-define=A4M_DISABLE_BACKGROUND_REFRESH=true',
    ],
    {
      cwd: frontendDir,
      stdio: ['ignore', 'pipe', 'pipe'],
    }
  );

  await waitForHttp(
    frontendBase,
    (response, text) => response.status === 200 && text.toLowerCase().includes('flutter'),
    120000,
    'Flutter web frontend'
  );
  await waitForProcessOutput(child, /main\.dart is being served/i, 120000, 'Flutter web build');

  await waitForHttp(
    `${frontendBase}/main.dart.js`,
    (response, text) => response.status === 200 && text.length > 1000,
    120000,
    'Flutter compiled entrypoint'
  );
}

async function waitForFrontendRender() {
  const { chromium } = require('playwright');
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1366, height: 768 } });
  const consoleErrors = [];
  const pageErrors = [];

  page.on('console', (message) => {
    if (message.type() === 'error') {
      consoleErrors.push(message.text());
    }
  });
  page.on('pageerror', (error) => pageErrors.push(error.message));

  try {
    await page.goto(frontendBase, { waitUntil: 'domcontentloaded', timeout: 30000 });
    await page.waitForSelector('flutter-view, flt-glass-pane, canvas', { timeout: 90000 });
    await page.waitForTimeout(1500);
    const surfaceCount = await page.locator('flutter-view, flt-glass-pane, canvas').count();
    writeLog(`Flutter render surface ready in Chromium: ${surfaceCount}`);
    if (consoleErrors.length > 0 || pageErrors.length > 0) {
      writeLog(
        `Chromium render diagnostics consoleErrors=${JSON.stringify(consoleErrors.slice(0, 5))} pageErrors=${JSON.stringify(
          pageErrors.slice(0, 5)
        )}`
      );
    }
  } finally {
    await browser.close();
  }
}

function startReadyServer() {
  readyServer = http.createServer((request, response) => {
    if (request.url === '/ready') {
      response.writeHead(200, { 'Content-Type': 'application/json' });
      response.end(JSON.stringify({ status: 'ok', frontendBase }));
      return;
    }
    response.writeHead(404, { 'Content-Type': 'text/plain' });
    response.end('not found');
  });

  readyServer.listen(Number(readyPort), '127.0.0.1', () => {
    writeLog(`F5 readiness endpoint ready at http://127.0.0.1:${readyPort}/ready`);
  });
}

async function main() {
  await ensureGraphHopper();
  await ensureBackend();
  await ensureFrontend();
  await waitForFrontendRender();
  startReadyServer();
  writeLog(`stack ready: ${frontendBase}`);

  await new Promise(() => {
    // Keep the process alive while Playwright runs.
  });
}

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));
process.on('exit', () => {
  for (const child of processes.reverse()) {
    stopProcess(child);
  }
});

main().catch((error) => {
  writeLog(`ERROR ${error.stack || error.message}`);
  shutdown(1);
});
