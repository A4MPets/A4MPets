//run command: npx playwright test --config=playwright.f5.config.js --project=F5-desktop-chromium --headed


const fs = require('fs');
const path = require('path');
const { expect } = require('@playwright/test');

const evidenceDir = path.resolve(__dirname, '../../../test-results/f5-fixtures');

function installDiagnostics(page) {
  const diagnostics = {
    consoleErrors: [],
    pageErrors: [],
    requestFailures: [],
    http500: [],
  };

  page.on('console', (message) => {
    if (message.text().includes('F5 add pet failed')) {
      console.log(`[browser] ${message.text()}`);
    }
    if (message.type() === 'error') {
      diagnostics.consoleErrors.push(message.text());
    }
  });
  page.on('pageerror', (error) => diagnostics.pageErrors.push(error.message));
  page.on('requestfailed', (request) => {
    diagnostics.requestFailures.push({
      url: request.url(),
      error: request.failure()?.errorText || 'unknown',
    });
  });
  page.on('response', (response) => {
    if (response.status() >= 500) {
      diagnostics.http500.push({
        url: response.url(),
        status: response.status(),
      });
    }
  });

  return diagnostics;
}

async function attachDiagnostics(testInfo, diagnostics) {
  fs.mkdirSync(evidenceDir, { recursive: true });
  fs.writeFileSync(
    path.join(evidenceDir, `${testInfo.title.replace(/[^a-z0-9]+/gi, '-').toLowerCase()}-diagnostics.json`),
    JSON.stringify(diagnostics, null, 2),
    'utf8'
  );
  await testInfo.attach('browser-diagnostics', {
    body: JSON.stringify(diagnostics, null, 2),
    contentType: 'application/json',
  });
}

async function openApp(page, testInfo) {
  let bodyText = '';
  let flutterSurfaceCount = 0;
  let currentUrl = '';
  let lastError = null;

  for (let attempt = 0; attempt < 8; attempt += 1) {
    const url = attempt === 0 ? '/' : `/?f5Reload=${Date.now()}-${attempt}`;
    try {
      if (attempt > 0) {
        await page.context().clearCookies().catch(() => {});
        await page.evaluate(() => {
          window.localStorage?.clear();
          window.sessionStorage?.clear();
        }).catch(() => {});
      }
      await page.goto(url, { waitUntil: attempt < 2 ? 'networkidle' : 'domcontentloaded', timeout: 90000 });
      currentUrl = page.url();
    } catch (error) {
      lastError = error.message;
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 90000 }).catch((fallbackError) => {
        lastError = fallbackError.message;
      });
      currentUrl = page.url();
    }
    await page
      .waitForFunction(() => {
        const hasText = (document.body?.innerText || '').trim().length > 0;
        const hasSurface = document.querySelector('flutter-view, flt-glass-pane, canvas') !== null;
        return hasText || hasSurface;
      }, null, { timeout: 90000 })
      .catch(() => {});
    await page.waitForTimeout(2000 + attempt * 1000);

    bodyText = await page.locator('body').innerText({ timeout: 5000 }).catch(() => '');
    flutterSurfaceCount = await page.locator('flutter-view, flt-glass-pane, canvas').count().catch(() => 0);
    if (bodyText.trim().length > 0 || flutterSurfaceCount > 0) {
      break;
    }
  }

  let screenshot = null;
  let screenshotError = null;
  try {
    screenshot = await page.screenshot({ fullPage: true, timeout: 1500 });
  } catch (error) {
    screenshotError = error.message;
  }

  await testInfo.attach('initial-render-state', {
    body: JSON.stringify(
      {
        bodyTextLength: bodyText.trim().length,
        bodyTextPreview: bodyText.trim().slice(0, 300),
        flutterSurfaceCount,
        currentUrl,
        lastError,
        screenshotError,
      },
      null,
      2
    ),
    contentType: 'application/json',
  });
  if (screenshot) {
    await testInfo.attach('initial-screenshot', {
      body: screenshot,
      contentType: 'image/png',
    });
  }

  if (bodyText.trim().length === 0 && flutterSurfaceCount === 0) {
    throw new Error(
      'F5 precondition failed: the Flutter web app responded over HTTP but rendered a blank page. No user flow can be executed from the browser.'
    );
  }

  await enableFlutterSemantics(page);
}

async function expectVisibleText(page, pattern, options = {}) {
  await expectSemanticsText(page, pattern, options);
}

async function clickVisibleText(page, pattern, options = {}) {
  await clickSemanticsText(page, pattern, options);
}

async function fillFirstMatching(page, pattern, value) {
  await fillFlutterField(page, pattern, value);
}

async function fillAccessibleTextbox(page, namePattern, value) {
  await enableFlutterSemantics(page);
  const textbox = page.getByRole('textbox', { name: namePattern }).first();
  const typeIntoFocusedField = async () => {
    await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
    await page.keyboard.press('Backspace');
    await page.keyboard.type(value);
    await page.waitForTimeout(250);
  };

  await textbox.scrollIntoViewIfNeeded({ timeout: 10000 }).catch(() => {});
  try {
    await textbox.click({ timeout: 10000 });
    await typeIntoFocusedField();
  } catch (_) {
    // Flutter web can briefly expose stale textbox semantics while a date picker is open.
  }

  const typedValue = await page
    .evaluate(() => {
      const active = document.activeElement;
      return active && 'value' in active ? active.value : '';
    })
    .catch(() => '');
  if (String(typedValue).includes(value.slice(0, Math.min(value.length, 32)))) {
    return;
  }

  await closeMaterialDialogIfOpen(page);

  try {
    await textbox.fill(value, { timeout: 5000 });
  } catch (_) {
    await closeMaterialDialogIfOpen(page);
    try {
      await fillFlutterField(page, namePattern, value, { timeout: 15000 });
    } catch (fieldError) {
      await fillFieldAfterLabel(page, namePattern, value, { timeout: 15000 }).catch(() => {
        throw fieldError;
      });
    }
  }
  await page.waitForTimeout(250);
}

async function closeMaterialDialogIfOpen(page) {
  const dialogVisible = await page
    .getByRole('dialog')
    .first()
    .isVisible({ timeout: 500 })
    .catch(() => false);
  if (!dialogVisible) {
    return;
  }

  const cancelButton = page.getByRole('button', { name: /^Cancel(ar)?$/i }).first();
  if (await cancelButton.isVisible({ timeout: 500 }).catch(() => false)) {
    await cancelButton.click({ timeout: 3000 }).catch(() => {});
  } else {
    await page.keyboard.press('Escape').catch(() => {});
  }
  await page.waitForTimeout(300);
  await enableFlutterSemantics(page).catch(() => {});
}

async function enableFlutterSemantics(page) {
  await page.waitForSelector('flutter-view, flt-glass-pane, canvas', { timeout: 90000 });
  await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder');
    if (!placeholder) {
      return;
    }
    placeholder.focus();
    placeholder.dispatchEvent(
      new MouseEvent('click', { bubbles: true, cancelable: true, view: window })
    );
    placeholder.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', bubbles: true })
    );
    placeholder.dispatchEvent(
      new KeyboardEvent('keyup', { key: 'Enter', code: 'Enter', bubbles: true })
    );
  });
  await page.waitForFunction(
    () => Array.from(document.querySelectorAll('flt-semantics')).some((node) => {
      const text = `${node.textContent || ''}\n${node.getAttribute('aria-label') || ''}`.trim();
      const rect = node.getBoundingClientRect();
      return text.length > 0 && rect.width > 1 && rect.height > 1;
    }),
    null,
    { timeout: 15000 }
  );
}

function patternSource(pattern) {
  return pattern instanceof RegExp
    ? { source: pattern.source, flags: pattern.flags }
    : { source: String(pattern).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), flags: 'i' };
}

async function semanticsSnapshot(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('flt-semantics'))
      .map((node) => {
        const rect = node.getBoundingClientRect();
        return {
          text: `${node.textContent || ''}\n${node.getAttribute('aria-label') || ''}`.trim(),
          role: node.getAttribute('role'),
          aria: node.getAttribute('aria-label'),
          rect: {
            x: Math.round(rect.x),
            y: Math.round(rect.y),
            width: Math.round(rect.width),
            height: Math.round(rect.height),
          },
        };
      })
      .filter((item) => item.rect.width > 1 && item.rect.height > 1)
  );
}

async function findSemanticsNode(page, pattern, options = {}) {
  const { source, flags } = patternSource(pattern);
  const prefer = options.prefer || 'smallest';
  const mustBeButton = options.button || false;
  const timeout = options.timeout || 8000;
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeout) {
    const match = await page.evaluate(
      ({ source, flags, prefer, mustBeButton }) => {
        const regex = new RegExp(source, flags);
        const nodes = Array.from(document.querySelectorAll('flt-semantics'))
          .map((node) => {
            const rect = node.getBoundingClientRect();
            const text = `${node.textContent || ''}\n${node.getAttribute('aria-label') || ''}`.trim();
            return {
              text,
              role: node.getAttribute('role'),
              x: rect.x,
              y: rect.y,
              width: rect.width,
              height: rect.height,
              area: rect.width * rect.height,
            };
          })
          .filter((node) => {
            if (node.width <= 1 || node.height <= 1 || !regex.test(node.text)) {
              return false;
            }
            if (mustBeButton && node.role !== 'button') {
              return false;
            }
            return true;
          });

        if (nodes.length === 0) {
          return null;
        }
        nodes.sort((a, b) => {
          if (prefer === 'largest') {
            return b.area - a.area;
          }
          if (prefer === 'lowest') {
            return b.y - a.y || a.area - b.area;
          }
          if (prefer === 'highest') {
            return a.y - b.y || a.area - b.area;
          }
          return a.area - b.area;
        });
        return nodes[0];
      },
      { source, flags, prefer, mustBeButton }
    );

    if (match) {
      return match;
    }
    await page.waitForTimeout(250);
  }

  const snapshot = await semanticsSnapshot(page);
  throw new Error(
    `No Flutter semantics node matched ${pattern}. Visible semantics: ${JSON.stringify(
      snapshot.slice(0, 80),
      null,
      2
    )}`
  );
}

async function isPointInViewport(page, x, y) {
  const viewport = page.viewportSize() || { width: 1366, height: 768 };
  const bottomMargin = x < Math.min(viewport.width * 0.7, 520) ? 88 : 8;
  return x >= 8 && x <= viewport.width - 8 && y >= 8 && y <= viewport.height - bottomMargin;
}

async function scrollSemanticsNodeIntoView(page, findNode) {
  let node = await findNode();
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const viewport = page.viewportSize() || { width: 1366, height: 768 };
    const centerX = node.x + node.width / 2;
    const centerY = node.y + node.height / 2;
    if (await isPointInViewport(page, centerX, centerY)) {
      return node;
    }

    const anchorX = Math.min(Math.max(centerX, 24), viewport.width - 24);
    const anchorY =
      node.x < Math.min(viewport.width * 0.7, 520)
        ? Math.min(Math.max(viewport.height * 0.65, 160), viewport.height - 120)
        : centerY > viewport.height
          ? viewport.height - 120
          : 120;
    const deltaY =
      centerY > viewport.height
        ? centerY - viewport.height + 96
        : centerY - 96;

    await page.mouse.move(anchorX, anchorY);
    await page.mouse.wheel(0, deltaY);
    await page.waitForTimeout(350);
    await enableFlutterSemantics(page).catch(() => {});
    node = await findNode();
  }
  return node;
}

function visibleClickPoint(page, node) {
  const viewport = page.viewportSize() || { width: 1366, height: 768 };
  const x = Math.min(
    Math.max(node.x + node.width / 2, Math.max(node.x + 4, 8)),
    Math.min(node.x + node.width - 4, viewport.width - 8)
  );
  const y = Math.min(
    Math.max(node.y + node.height / 2, Math.max(node.y + 4, 8)),
    Math.min(node.y + node.height - 4, viewport.height - 8)
  );
  return { x, y };
}

async function dispatchSemanticsClick(page, pattern, options = {}) {
  const { source, flags } = patternSource(pattern);
  const prefer = options.prefer || 'smallest';
  const mustBeButton = options.button !== false;
  const forceKeyboard = options.forceKeyboard === true;

  await page.evaluate(
    ({ source, flags, prefer, mustBeButton, forceKeyboard }) => {
      const regex = new RegExp(source, flags);
      const nodes = Array.from(document.querySelectorAll('flt-semantics'))
        .map((element) => {
          const rect = element.getBoundingClientRect();
          const text = `${element.textContent || ''}\n${element.getAttribute('aria-label') || ''}`.trim();
          return {
            element,
            text,
            role: element.getAttribute('role'),
            y: rect.y,
            area: rect.width * rect.height,
          };
        })
        .filter((node) => {
          if (!regex.test(node.text)) {
            return false;
          }
          if (mustBeButton && node.role !== 'button') {
            return false;
          }
          return true;
        });

      if (nodes.length === 0) {
        return;
      }

      nodes.sort((a, b) => {
        if (prefer === 'largest') {
          return b.area - a.area;
        }
        if (prefer === 'lowest') {
          return b.y - a.y || a.area - b.area;
        }
        if (prefer === 'highest') {
          return a.y - b.y || a.area - b.area;
        }
        return a.area - b.area;
      });
      const target = nodes[0].element;
      target.focus?.();
      if (typeof target.click === 'function') {
        target.click();
        if (!forceKeyboard) {
          return;
        }
      }
      for (const type of ['pointerdown', 'mousedown', 'pointerup', 'mouseup', 'click']) {
        target.dispatchEvent(
          new MouseEvent(type, {
            bubbles: true,
            cancelable: true,
            view: window,
          })
        );
      }
      for (const key of ['Enter', ' ']) {
        target.dispatchEvent(
          new KeyboardEvent('keydown', {
            key,
            code: key === ' ' ? 'Space' : 'Enter',
            bubbles: true,
            cancelable: true,
          })
        );
        target.dispatchEvent(
          new KeyboardEvent('keyup', {
            key,
            code: key === ' ' ? 'Space' : 'Enter',
            bubbles: true,
            cancelable: true,
          })
        );
      }
    },
    { source, flags, prefer, mustBeButton, forceKeyboard }
  );
}

async function clickSemanticsText(page, pattern, options = {}) {
  await enableFlutterSemantics(page);
  let node = null;
  const findNode = async () => {
    if (options.button !== false) {
      node = await findSemanticsNode(page, pattern, { ...options, button: true }).catch(() => null);
    }
    if (!node) {
      node = await findSemanticsNode(page, pattern, { ...options, button: false });
    }
    return node;
  };
  node = await scrollSemanticsNodeIntoView(page, findNode);
  if (options.domClickOnly) {
    await dispatchSemanticsClick(page, pattern, options);
    await page.waitForTimeout(options.afterClickMs || 500);
    await enableFlutterSemantics(page).catch(() => {});
    return;
  }
  const point = visibleClickPoint(page, node);
  await page.mouse.click(point.x, point.y);
  if (options.domClick) {
    await dispatchSemanticsClick(page, pattern, options);
  }
  await page.waitForTimeout(options.afterClickMs || 500);
  await enableFlutterSemantics(page).catch(() => {});
}

async function clickSemanticsButton(page, pattern, options = {}) {
  await clickSemanticsText(page, pattern, { ...options, button: true });
}

async function expectSemanticsText(page, pattern, options = {}) {
  await enableFlutterSemantics(page);
  const node = await findSemanticsNode(page, pattern, options);
  expect(node).toBeTruthy();
}

async function hasSemanticsText(page, pattern, options = {}) {
  await enableFlutterSemantics(page);
  return findSemanticsNode(page, pattern, { ...options, timeout: options.timeout || 1000 })
    .then(() => true)
    .catch(() => false);
}

async function expectNoSemanticsText(page, pattern, options = {}) {
  await enableFlutterSemantics(page);
  const found = await hasSemanticsText(page, pattern, { timeout: options.timeout || 1500 });
  expect(found).toBeFalsy();
}

async function waitForApiResponse(page, method, urlPattern, action, options = {}) {
  const responsePromise = page.waitForResponse(
    (response) => {
      const request = response.request();
      if (request.method().toUpperCase() !== method.toUpperCase()) {
        return false;
      }
      const url = response.url();
      const matches =
        urlPattern instanceof RegExp ? urlPattern.test(url) : url.includes(String(urlPattern));
      return matches;
    },
    { timeout: options.timeout || 45000 }
  );
  await action();
  const response = await responsePromise;
  if (response.status() < 200 || response.status() >= 400) {
    const body = await response.text().catch(() => '<unavailable>');
    throw new Error(
      `${method.toUpperCase()} ${urlPattern} returned ${response.status()}: ${body.slice(0, 1000)}`
    );
  }
  return response;
}

async function fillFlutterField(page, pattern, value, options = {}) {
  await enableFlutterSemantics(page);
  const node = await scrollSemanticsNodeIntoView(page, () =>
    findSemanticsNode(page, pattern, {
      ...options,
      prefer: options.prefer || 'smallest',
    })
  );
  const point = visibleClickPoint(page, node);
  await page.mouse.click(point.x, point.y);
  await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await page.keyboard.type(value);
  await page.waitForTimeout(250);
}

async function fillFieldAfterLabel(page, labelPattern, value, options = {}) {
  let lastField = null;

  for (let attempt = 0; attempt < 6; attempt += 1) {
    await enableFlutterSemantics(page);
    const labelNode = await scrollSemanticsNodeIntoView(page, () =>
      findSemanticsNode(page, labelPattern, {
        ...options,
        button: false,
        prefer: options.prefer || 'smallest',
      })
    );

    const field = await page.evaluate((labelNode) => {
      const fields = Array.from(document.querySelectorAll('flt-semantics'))
        .map((node) => {
          const rect = node.getBoundingClientRect();
          return {
            text: `${node.textContent || ''}\n${node.getAttribute('aria-label') || ''}`.trim(),
            role: node.getAttribute('role'),
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
          };
        })
        .filter((node) => {
          if (node.role === 'button') {
            return false;
          }
          if (node.width < 120 || node.height < 32 || node.height > 100) {
            return false;
          }
          if (Math.abs(node.x - labelNode.x) > 24) {
            return false;
          }
          return node.y > labelNode.y;
        })
        .sort((a, b) => a.y - b.y || a.x - b.x);
      return fields[0] || null;
    }, labelNode);

    if (!field) {
      break;
    }
    lastField = field;

    const centerX = field.x + field.width / 2;
    const centerY = field.y + field.height / 2;
    if (await isPointInViewport(page, centerX, centerY)) {
      const point = visibleClickPoint(page, field);
      await page.mouse.click(point.x, point.y);
      await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
      await page.keyboard.type(value);
      await page.waitForTimeout(250);
      return;
    }

    const viewport = page.viewportSize() || { width: 1366, height: 768 };
    const anchorX = Math.min(Math.max(centerX, 24), viewport.width - 24);
    const anchorY = Math.min(Math.max(viewport.height * 0.65, 160), viewport.height - 120);
    const deltaY =
      centerY > viewport.height - 132
        ? centerY - viewport.height + 164
        : centerY - 132;
    await page.mouse.move(anchorX, anchorY);
    await page.mouse.wheel(0, deltaY);
    await page.waitForTimeout(350);
  }

  const snapshot = await semanticsSnapshot(page);
  throw new Error(
    `No clickable Flutter field found after label ${labelPattern}. Last field: ${JSON.stringify(
      lastField
    )}. Visible semantics: ${JSON.stringify(snapshot.slice(0, 80), null, 2)}`
  );
}

async function fillPanelField(page, index, value, options = {}) {
  await enableFlutterSemantics(page);
  const timeout = options.timeout || 8000;
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeout) {
    const fields = await page.evaluate(() =>
      Array.from(document.querySelectorAll('flt-semantics'))
        .map((node) => {
          const rect = node.getBoundingClientRect();
          return {
            text: `${node.textContent || ''}\n${node.getAttribute('aria-label') || ''}`.trim(),
            role: node.getAttribute('role'),
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
          };
        })
        .filter((node) => {
          if (node.role === 'button' || node.text.length > 0) {
            return false;
          }
          if (node.width < 120 || node.height < 32 || node.height > 80) {
            return false;
          }
          return node.x < Math.min(window.innerWidth * 0.7, 520);
        })
        .sort((a, b) => a.y - b.y || a.x - b.x)
    );

    if (fields[index]) {
      let field = fields[index];
      field = await scrollSemanticsNodeIntoView(page, async () => {
        const latestFields = await page.evaluate(() =>
          Array.from(document.querySelectorAll('flt-semantics'))
            .map((node) => {
              const rect = node.getBoundingClientRect();
              return {
                text: `${node.textContent || ''}\n${node.getAttribute('aria-label') || ''}`.trim(),
                role: node.getAttribute('role'),
                x: rect.x,
                y: rect.y,
                width: rect.width,
                height: rect.height,
              };
            })
            .filter((node) => {
              if (node.role === 'button' || node.text.length > 0) {
                return false;
              }
              if (node.width < 120 || node.height < 32 || node.height > 90) {
                return false;
              }
              return node.x < Math.min(window.innerWidth * 0.7, 520);
            })
            .sort((a, b) => a.y - b.y || a.x - b.x)
        );
        return latestFields[Math.min(index, latestFields.length - 1)] || field;
      });
      const point = visibleClickPoint(page, field);
      await page.mouse.click(point.x, point.y);
      await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
      await page.keyboard.type(value);
      await page.waitForTimeout(250);
      return;
    }
    await page.waitForTimeout(250);
  }

  const snapshot = await semanticsSnapshot(page);
  throw new Error(
    `No Flutter panel field found at index ${index}. Visible semantics: ${JSON.stringify(
      snapshot.slice(0, 80),
      null,
      2
    )}`
  );
}

async function fillDialogField(page, value, options = {}) {
  await enableFlutterSemantics(page);
  const timeout = options.timeout || 8000;
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeout) {
    const field = await page.evaluate(() => {
      const candidates = Array.from(document.querySelectorAll('flt-semantics'))
        .map((node) => {
          const rect = node.getBoundingClientRect();
          return {
            text: `${node.textContent || ''}\n${node.getAttribute('aria-label') || ''}`.trim(),
            role: node.getAttribute('role'),
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            area: rect.width * rect.height,
          };
        })
        .filter((node) => {
          if (node.role === 'button' || node.text.length > 0) {
            return false;
          }
          return node.width >= 120 && node.height >= 32 && node.height <= 90;
        })
        .sort((a, b) => a.area - b.area);
      return candidates[0] || null;
    });

    if (field) {
      await page.mouse.click(field.x + field.width / 2, field.y + field.height / 2);
      await page.keyboard.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
      await page.keyboard.type(value);
      await page.waitForTimeout(250);
      return;
    }
    await page.waitForTimeout(250);
  }

  const snapshot = await semanticsSnapshot(page);
  throw new Error(
    `No Flutter dialog field found. Visible semantics: ${JSON.stringify(
      snapshot.slice(0, 80),
      null,
      2
    )}`
  );
}

async function clickAt(page, x, y, options = {}) {
  await page.mouse.click(x, y);
  await page.waitForTimeout(options.afterClickMs || 500);
  await enableFlutterSemantics(page).catch(() => {});
}

async function openProfileMenu(page) {
  const menuPattern = /Iniciar Sesi|Registrarse|Cerrar sesi|Gestionar Mascotas|Gestionar Rutas/i;
  for (let attempt = 0; attempt < 4; attempt += 1) {
    await clickSemanticsButton(page, /Abrir perfil|Perfil/i, { afterClickMs: 700 }).catch(async () => {
      await clickAt(page, 40, 40, { afterClickMs: 700 });
    });
    if (await hasSemanticsText(page, menuPattern, { timeout: 1200 })) {
      return;
    }
    await page.mouse.move(500, 220);
    await page.waitForTimeout(250);
  }
  throw new Error('The Flutter profile menu did not open after clicking Abrir perfil.');
}

async function openReportMenu(page) {
  await clickSemanticsButton(page, /Reportar/i);
}

async function openTripMenu(page) {
  await clickSemanticsButton(page, /Iniciar Viaje/i);
}

function createRuntimePng(fileName = 'f5-fixture.png') {
  fs.mkdirSync(evidenceDir, { recursive: true });
  const filePath = path.join(evidenceDir, fileName);
  if (!fs.existsSync(filePath)) {
    const pngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/lkyh7wAAAABJRU5ErkJggg==';
    fs.writeFileSync(filePath, Buffer.from(pngBase64, 'base64'));
  }
  return filePath;
}

module.exports = {
  installDiagnostics,
  attachDiagnostics,
  openApp,
  expectVisibleText,
  clickVisibleText,
  fillFirstMatching,
  fillAccessibleTextbox,
  closeMaterialDialogIfOpen,
  enableFlutterSemantics,
  semanticsSnapshot,
  clickSemanticsText,
  clickSemanticsButton,
  expectSemanticsText,
  hasSemanticsText,
  expectNoSemanticsText,
  waitForApiResponse,
  fillFlutterField,
  fillFieldAfterLabel,
  fillPanelField,
  fillDialogField,
  clickAt,
  openProfileMenu,
  openReportMenu,
  openTripMenu,
  createRuntimePng,
};
