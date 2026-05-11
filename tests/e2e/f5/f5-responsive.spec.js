const { test, expect } = require('@playwright/test');
const {
  installDiagnostics,
  attachDiagnostics,
  openApp,
  enableFlutterSemantics,
  expectVisibleText,
} = require('./helpers');

test.describe('F5 - Responsive caja negra', () => {
  test.beforeEach(async ({ page }, testInfo) => {
    testInfo.diagnostics = installDiagnostics(page);
  });

  test.afterEach(async ({}, testInfo) => {
    await attachDiagnostics(testInfo, testInfo.diagnostics);
  });

  test('F5-015 viewport escritorio y F5-016 viewport movil sin overflow critico', async ({ page }) => {
    await page.setViewportSize({ width: 1366, height: 768 });
    await openApp(page, test.info());
    await expectVisibleText(page, /Iniciar|Mascotas|Peligro|Viaje/i);
    const hasDesktopHorizontalOverflow = await page.evaluate(
      () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
    );
    expect(hasDesktopHorizontalOverflow).toBeFalsy();

    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForTimeout(1000);
    await enableFlutterSemantics(page);
    await expectVisibleText(page, /Iniciar|Mascotas|Peligro|Viaje/i);
    const hasMobileHorizontalOverflow = await page.evaluate(
      () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1
    );
    expect(hasMobileHorizontalOverflow).toBeFalsy();
  });
});
