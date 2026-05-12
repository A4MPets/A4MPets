const { defineConfig, devices } = require('@playwright/test');

const frontendPort = process.env.A4M_F5_FRONTEND_PORT || '7357';
const readyPort = process.env.A4M_F5_READY_PORT || '7358';
const baseURL = process.env.A4M_F5_BASE_URL || `http://127.0.0.1:${frontendPort}`;

module.exports = defineConfig({
  testDir: './tests/e2e/f5',
  outputDir: './test-results/f5',
  timeout: 300000,
  expect: {
    timeout: 8000,
  },
  fullyParallel: false,
  workers: 1,
  reporter: [
    ['list'],
    ['html', { outputFolder: 'test-results/f5-playwright-report', open: 'never' }],
    ['json', { outputFile: 'test-results/f5-playwright-results.json' }],
  ],
  use: {
    baseURL,
    actionTimeout: 30000,
    navigationTimeout: 90000,
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    video: 'off',
    permissions: ['geolocation'],
    geolocation: { latitude: 4.711, longitude: -74.0721 },
  },
  webServer: {
    command: 'node scripts/f5-stack.js',
    url: `http://127.0.0.1:${readyPort}/ready`,
    reuseExistingServer: true,
    timeout: 180000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
  projects: [
    {
      name: 'F5-desktop-chromium',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1366, height: 768 },
      },
    },
  ],
});
