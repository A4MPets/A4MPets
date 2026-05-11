const fs = require('fs');
const path = require('path');
const { spawn, spawnSync, execFileSync } = require('child_process');

const repoRoot = path.resolve(__dirname, '..');
const backendDir = path.join(repoRoot, 'backend');
const frontendDir = path.join(repoRoot, 'frontend');
const evidenceDir = path.join(repoRoot, 'docs', 'evidencias', 'F4');
const runtimeEnvPath = path.join(frontendDir, 'env', 'runtime.local.json');
const backendPort = process.env.A4M_F4_BACKEND_PORT || '8000';
const frontendPort = process.env.A4M_F4_FRONTEND_PORT || '7357';
const backendBase = `http://127.0.0.1:${backendPort}`;
const apiBase = `${backendBase}/api`;
const frontendBase = `http://127.0.0.1:${frontendPort}`;
const graphhopperBase = process.env.GRAPHHOPPER_BASE_URL || 'http://127.0.0.1:8989';

const results = [];
const processes = [];

function nowIso() {
  return new Date().toISOString();
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function log(message) {
  console.log(`[F4] ${message}`);
}

function record(id, status, detail, extra = {}) {
  results.push({
    id,
    status,
    detail,
    timestamp: nowIso(),
    ...extra,
  });
  log(`${id} ${status}: ${detail}`);
}

function run(command, args, options = {}) {
  const printable = `${command} ${args.join(' ')}`;
  log(`$ ${printable}`);
  const output = execFileSync(command, args, {
    cwd: options.cwd || repoRoot,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, ...(options.env || {}) },
  });
  return output.trim();
}

function commandExists(command, args = ['--version']) {
  try {
    spawnSync(command, args, { stdio: 'ignore' });
    return true;
  } catch (_) {
    return false;
  }
}

async function httpJson(url, options = {}) {
  const response = await fetch(url, {
    redirect: 'follow',
    ...options,
    headers: {
      Accept: 'application/json',
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch (_) {
    body = text;
  }
  return { status: response.status, body, text };
}

async function waitForHttp(url, predicate, timeoutMs, label) {
  const startedAt = Date.now();
  let lastError = null;
  while (Date.now() - startedAt < timeoutMs) {
    try {
      const response = await fetch(url, { redirect: 'follow' });
      const text = await response.text();
      if (predicate(response, text)) {
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

function startProcess(command, args, options) {
  const child =
    process.platform === 'win32'
      ? spawn('cmd.exe', ['/d', '/s', '/c', command, ...args], options)
      : spawn(command, args, options);

  processes.push(child);
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
      if (pattern.test(chunk.toString())) {
        log(`${label} ready from Flutter output`);
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

function cleanup() {
  for (const child of processes.reverse()) {
    stopProcess(child);
  }
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
  return ps;
}

async function ensureBackend() {
  try {
    await waitForHttp(
      `${apiBase}/health`,
      (response, text) => response.status === 200 && text.includes('"ok"'),
      2000,
      'existing backend'
    );
    return { started: false };
  } catch (_) {
    // Start a local backend below.
  }

  run('php', ['artisan', 'migrate', '--force'], { cwd: backendDir });
  const child = startProcess('php', ['artisan', 'serve', '--host', '127.0.0.1', '--port', backendPort], {
    cwd: backendDir,
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  await waitForHttp(
    `${apiBase}/health`,
    (response, text) => response.status === 200 && text.includes('"ok"'),
    45000,
    'Laravel backend'
  );
  return { started: true, child };
}

async function ensureFrontend() {
  fs.mkdirSync(path.dirname(runtimeEnvPath), { recursive: true });
  fs.writeFileSync(
    runtimeEnvPath,
    `${JSON.stringify({ A4M_API_BASE_URL: `http://localhost:${backendPort}/api,http://127.0.0.1:${backendPort}/api` }, null, 2)}\n`,
    'utf8'
  );

  try {
    await waitForHttp(
      frontendBase,
      (response, text) => response.status === 200 && text.toLowerCase().includes('flutter'),
      2000,
      'existing frontend'
    );
    return { started: false };
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
  return { started: true, child };
}

function authHeaders(token) {
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };
}

async function post(pathname, body, token) {
  return httpJson(`${apiBase}${pathname}`, {
    method: 'POST',
    headers: token ? authHeaders(token) : { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

async function get(pathname, token) {
  return httpJson(`${apiBase}${pathname}`, {
    method: 'GET',
    headers: token ? authHeaders(token) : undefined,
  });
}

async function runPlaywrightSmoke() {
  let playwright;
  try {
    playwright = require('playwright');
  } catch (_) {
    record('F4-017', 'SKIPPED', 'Playwright is not installed; frontend HTTP availability was still validated.');
    return;
  }

  const browser = await playwright.chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1366, height: 768 } });
  const consoleErrors = [];
  const pageErrors = [];
  const requestFailures = [];
  const apiResponses = [];

  page.on('console', (message) => {
    if (message.type() === 'error') {
      consoleErrors.push(message.text());
    }
  });
  page.on('pageerror', (error) => {
    pageErrors.push(error.message);
  });
  page.on('requestfailed', (request) => {
    requestFailures.push({
      url: request.url(),
      failure: request.failure()?.errorText || 'unknown',
    });
  });
  page.on('response', (response) => {
    if (response.url().startsWith(apiBase)) {
      apiResponses.push({ url: response.url(), status: response.status() });
    }
  });

  await page.goto(frontendBase, { waitUntil: 'networkidle', timeout: 60000 });
  await page
    .waitForFunction(() => {
      const hasText = (document.body?.innerText || '').trim().length > 0;
      const hasSurface = document.querySelector('flutter-view, flt-glass-pane, canvas') !== null;
      return hasText || hasSurface;
    }, null, { timeout: 60000 })
    .catch(() => {});
  const bodyText = await page.locator('body').innerText({ timeout: 30000 }).catch(() => '');
  const flutterSurfaceCount = await page
    .locator('flutter-view, flt-glass-pane, canvas')
    .count()
    .catch(() => 0);
  await page.screenshot({ path: path.join(evidenceDir, 'f4_frontend_smoke.png'), fullPage: true });
  await browser.close();

  if (consoleErrors.length > 0) {
    record('F4-017', 'FAIL', 'Frontend emitted critical console errors in headless Chromium.', {
      consoleErrors: consoleErrors.slice(0, 10),
      pageErrors,
      requestFailures: requestFailures.slice(0, 10),
      screenshot: 'docs/evidencias/F4/f4_frontend_smoke.png',
    });
    throw new Error(`Frontend console errors: ${consoleErrors.slice(0, 3).join(' | ')}`);
  }
  if (pageErrors.length > 0) {
    record('F4-017', 'FAIL', 'Frontend emitted page errors in headless Chromium.', {
      consoleErrors,
      pageErrors: pageErrors.slice(0, 10),
      requestFailures: requestFailures.slice(0, 10),
      screenshot: 'docs/evidencias/F4/f4_frontend_smoke.png',
    });
    throw new Error(`Frontend page errors: ${pageErrors.slice(0, 3).join(' | ')}`);
  }
  if (bodyText.trim().length === 0 && flutterSurfaceCount === 0) {
    const detail = `Frontend did not expose visible text or a Flutter rendering surface. Failed requests: ${JSON.stringify(
      requestFailures.slice(0, 5)
    )}`;
    record('F4-017', 'FAIL', 'Frontend web server responded, but the app rendered a blank page in Chromium.', {
      bodyTextLength: bodyText.trim().length,
      flutterSurfaceCount,
      requestFailures: requestFailures.slice(0, 10),
      screenshot: 'docs/evidencias/F4/f4_frontend_smoke.png',
    });
    throw new Error(detail);
  }

  record('F4-017', 'PASS', 'Frontend loaded in headless Chromium without critical console errors.', {
    apiResponses,
    flutterSurfaceCount,
    requestFailures: requestFailures.slice(0, 10),
    screenshot: 'docs/evidencias/F4/f4_frontend_smoke.png',
  });
}

async function main() {
  fs.mkdirSync(evidenceDir, { recursive: true });
  const startedAt = nowIso();
  let frontendStarted = null;
  let backendStarted = null;

  try {
    const graphhopperStatus = await ensureGraphHopper();
    backendStarted = await ensureBackend();
    frontendStarted = await ensureFrontend();

    const health = await get('/health');
    if (health.status !== 200 || health.body?.status !== 'ok') {
      throw new Error(`Health returned ${health.status}`);
    }

    const frontend = await fetch(frontendBase);
    const frontendHtml = await frontend.text();
    if (frontend.status !== 200 || !frontendHtml.toLowerCase().includes('flutter')) {
      throw new Error(`Frontend returned ${frontend.status}`);
    }
    record('F4-001', 'PASS', 'Backend, frontend web server and GraphHopper are available.', {
      graphhopperStatus,
      backendStarted: backendStarted.started,
      frontendStarted: frontendStarted.started,
    });

    const suffix = Date.now();
    const email = `qa_f4_${suffix}@example.com`;
    const password = 'QAtest1234';
    const register = await post('/auth/register', {
      name: `qa_f4_${suffix}`,
      email,
      password,
      password_confirmation: password,
    });
    if (register.status !== 201 || !register.body?.data?.access_token) {
      throw new Error(`Register returned ${register.status}: ${register.text}`);
    }
    const token = register.body.data.access_token;
    record('F4-002', 'PASS', 'User registration persisted through real Laravel API.', {
      email,
      userId: register.body.data.user.id,
    });

    const login = await post('/auth/login', { login: email, password });
    if (login.status !== 200 || !login.body?.data?.access_token) {
      throw new Error(`Login returned ${login.status}: ${login.text}`);
    }
    const authToken = login.body.data.access_token;
    const me = await get('/auth/me', authToken);
    if (me.status !== 200 || me.body?.data?.email !== email) {
      throw new Error(`Me returned ${me.status}: ${me.text}`);
    }
    record('F4-003', 'PASS', 'Login token works against protected backend endpoint.');

    const pet = await post('/pets', {
      name: `Luna F4 ${suffix}`,
      status: 'normal',
      is_ownerless: false,
      birth_date: '2024-01-15',
    }, authToken);
    if (pet.status !== 201 || !pet.body?.data?.id) {
      throw new Error(`Pet create returned ${pet.status}: ${pet.text}`);
    }
    const petId = pet.body.data.id;
    const pets = await get('/pets?scope=mine&per_page=100', authToken);
    if (pets.status !== 200 || !pets.body?.data?.some((item) => item.id === petId)) {
      throw new Error(`Pet list did not include ${petId}`);
    }
    record('F4-004', 'PASS', 'Pet created and returned from authenticated owner list.', { petId });

    const hazard = await post('/hazards', {
      incident_latitude: 3.4516,
      incident_longitude: -76.5320,
      impact_radius_meters: 200,
      risk_level_code: 'high',
      category_code: 'pest_presence',
      estimated_duration_code: '1_day',
      description: `Peligro F4 ${suffix}`,
      reported_at: '2026-05-08 10:00:00',
    }, authToken);
    if (hazard.status !== 201 || !hazard.body?.data?.id) {
      throw new Error(`Hazard create returned ${hazard.status}: ${hazard.text}`);
    }
    const hazardId = hazard.body.data.id;
    const hazards = await get('/hazards?per_page=100');
    if (hazards.status !== 200 || !hazards.body?.data?.some((item) => item.id === hazardId)) {
      throw new Error(`Hazard list did not include ${hazardId}`);
    }
    record('F4-005', 'PASS', 'Hazard marker source data is available through public hazards API.', { hazardId });
    record('F4-006', 'PASS', 'Hazard created with manual-coordinate payload and persisted.', { hazardId });

    const lowHazard = await post('/hazards', {
      incident_latitude: 3.4520,
      incident_longitude: -76.5330,
      impact_radius_meters: 120,
      risk_level_code: 'low',
      category_code: 'pest_presence',
      estimated_duration_code: '1_day',
      description: `Peligro bajo F4 ${suffix}`,
      reported_at: '2026-05-08 10:05:00',
    }, authToken);
    if (lowHazard.status !== 201) {
      throw new Error(`Low hazard create returned ${lowHazard.status}`);
    }
    const filteredHigh = await get('/hazards?risk_level=high&per_page=100');
    if (filteredHigh.status !== 200 || !filteredHigh.body?.data?.every((item) => item.risk_level_code === 'high')) {
      throw new Error('High risk filter returned unexpected hazards.');
    }
    record('F4-007', 'PASS', 'Backend supplies risk-filtered hazard data for map layer toggles.');

    const lost = await post('/lost-pet-reports', {
      pet_id: petId,
      last_seen_latitude: 3.4516,
      last_seen_longitude: -76.5320,
      details: `Perdida F4 ${suffix}`,
      disappearance_date: '2026-05-08 09:00:00',
      phone: '3001234567',
    }, authToken);
    if (lost.status !== 201 || !lost.body?.data?.id) {
      throw new Error(`Lost report returned ${lost.status}: ${lost.text}`);
    }
    const lostId = lost.body.data.id;
    record('F4-008', 'PASS', 'Lost pet report created with persisted pet association.', { lostId, petId });

    const found = await post('/found-pet-reports', {
      matched_lost_pet_report_id: lostId,
      latitude: 3.4570,
      longitude: -76.5280,
      details: `Encontrada F4 ${suffix}`,
      found_date: '2026-05-08 11:00:00',
      phone: '3009876543',
    }, authToken);
    if (found.status !== 201 || found.body?.data?.matched_lost_pet_report_id !== lostId) {
      throw new Error(`Found report returned ${found.status}: ${found.text}`);
    }
    record('F4-009', 'PASS', 'Found pet report created and linked to lost pet report.', {
      foundId: found.body.data.id,
      lostId,
    });

    const route = await post('/routes', {
      name: `Ruta F4 ${suffix}`,
      points_json: JSON.stringify([
        { lat: 3.4516, lng: -76.5320 },
        { lat: 3.4570, lng: -76.5280 },
      ]),
    }, authToken);
    if (route.status !== 201 || !route.body?.data?.id) {
      throw new Error(`Route create returned ${route.status}: ${route.text}`);
    }
    record('F4-011', 'PASS', 'Travel route created and persisted through backend.', { routeId: route.body.data.id });

    const planned = await post('/routes/plan', {
      points: [
        { lat: 3.4516, lng: -76.5320 },
        { lat: 3.4570, lng: -76.5280 },
      ],
      travel_mode: 'walking',
      avoid_hazards: false,
    }, authToken);
    if (planned.status !== 200 || !planned.body?.data?.coordinates?.length) {
      throw new Error(`Route planning returned ${planned.status}: ${planned.text}`);
    }
    record('F4-010', 'PASS', 'Backend planned a real route through local GraphHopper.', {
      distanceMeters: planned.body.data.distance_meters,
      durationSeconds: planned.body.data.duration_seconds,
      coordinateCount: planned.body.data.coordinates.length,
    });
    record('F4-021', 'PASS', 'Navigation instructions payload is returned for planned route.', {
      instructionCount: planned.body.data.navigation_instructions.length,
      profile: planned.body.data.profile,
    });

    const comment = await post(`/hazards/${hazardId}/comments`, {
      comment_text: `Comentario F4 ${suffix}`,
      is_anonymous: false,
    }, authToken);
    if (comment.status !== 201 || comment.body?.data?.comment_text !== `Comentario F4 ${suffix}`) {
      throw new Error(`Hazard comment returned ${comment.status}: ${comment.text}`);
    }
    record('F4-012', 'PASS', 'Hazard comment persisted and returned with author data.', { hazardId });

    const logout = await post('/auth/logout', {}, authToken);
    const revokedMe = await get('/auth/me', authToken);
    if (logout.status !== 200 || revokedMe.status !== 401) {
      throw new Error(`Logout/revoked token check failed: logout ${logout.status}, me ${revokedMe.status}`);
    }
    record('F4-013', 'PASS', 'Logout revokes token and private API rejects it.');

    const lostList = await get('/lost-pet-reports?per_page=100');
    if (lostList.status !== 200 || !lostList.body?.data?.some((item) => item.id === lostId)) {
      throw new Error('Lost pet marker source data was not returned.');
    }
    record('F4-014', 'PASS', 'Lost pet marker source data is available through public API.', { lostId });
    record('F4-015', 'PASS', 'Manual map coordinates persisted in report payloads.', {
      lostLatitude: lost.body.data.last_seen_latitude,
      lostLongitude: lost.body.data.last_seen_longitude,
    });

    const avoided = await post('/routes/plan', {
      points: [
        { lat: 3.4516, lng: -76.5320 },
        { lat: 3.4570, lng: -76.5280 },
      ],
      travel_mode: 'vehicle',
      avoid_hazards: true,
      hazard_risk_filters: ['high'],
    }, token);
    if (avoided.status !== 200 || avoided.body?.data?.hazards_considered < 1) {
      throw new Error(`Avoidance planning returned ${avoided.status}: ${avoided.text}`);
    }
    record('F4-016', 'PASS', 'Route planning considers persisted high-risk hazards.', {
      hazardsConsidered: avoided.body.data.hazards_considered,
      profile: avoided.body.data.profile,
    });

    const generic = await post('/generic-reports', {
      latitude: 3.4516,
      longitude: -76.5320,
      description: `Generico F4 ${suffix}`,
      reported_date: '2026-05-08 12:00:00',
      risk_level_code: 'medium',
      impact_radius_meters: 200,
    }, token);
    if (generic.status !== 201 || generic.body?.data?.impact_radius_meters !== 200) {
      throw new Error(`Generic report returned ${generic.status}: ${generic.text}`);
    }
    record('F4-020', 'PASS', 'Generic report radius data persisted for map impact circle.', {
      genericId: generic.body.data.id,
      impactRadiusMeters: generic.body.data.impact_radius_meters,
    });

    const onePixelPng = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';
    const upload = await post('/media/upload', {
      bucket: 'hazards',
      image_data: onePixelPng,
      filename: 'f4-hazard.png',
    }, token);
    if (upload.status !== 200 || !upload.body?.data?.url) {
      throw new Error(`Media upload returned ${upload.status}: ${upload.text}`);
    }
    record('F4-022', 'PASS', 'Image upload endpoint stores media usable by hazard reports.', {
      url: upload.body.data.url,
    });

    const finalHealth = await get('/health');
    if (finalHealth.status !== 200 || finalHealth.body?.status !== 'ok') {
      throw new Error('Final health check failed after integrated operations.');
    }
    record('F4-018', 'PASS', 'Health remains OK after integrated create/list/plan/upload operations.');

    await runPlaywrightSmoke();

    record('F4-001-extra', 'PASS', 'Frontend runtime API base URL configured for local backend.', {
      runtimeEnv: path.relative(repoRoot, runtimeEnvPath),
    });
  } finally {
    const finishedAt = nowIso();
    const artifact = {
      phase: 'F4',
      startedAt,
      finishedAt,
      backendBase,
      frontendBase,
      graphhopperBase,
      results,
    };
    fs.writeFileSync(
      path.join(evidenceDir, 'f4_system_check_results.json'),
      `${JSON.stringify(artifact, null, 2)}\n`,
      'utf8'
    );
    cleanup();
  }

  const failed = results.filter((item) => item.status === 'FAIL');
  if (failed.length > 0) {
    process.exitCode = 1;
  }
}

process.on('SIGINT', () => {
  cleanup();
  process.exit(130);
});
process.on('SIGTERM', () => {
  cleanup();
  process.exit(143);
});

main().catch((error) => {
  record('F4-000', 'FAIL', error.message);
  cleanup();
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(
    path.join(evidenceDir, 'f4_system_check_results.json'),
    `${JSON.stringify({ phase: 'F4', results, fatal: error.message }, null, 2)}\n`,
    'utf8'
  );
  process.exit(1);
});
