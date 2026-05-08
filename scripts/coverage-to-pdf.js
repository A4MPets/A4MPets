const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function exportCoverage(htmlPath, outputPdf) {
  const browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: { width: 1600, height: 1200 }
  });

  const fileUrl = 'file://' + path.resolve(htmlPath);

  await page.goto(fileUrl, {
    waitUntil: 'networkidle'
  });

  // Expandir altura completa
  await page.evaluate(async () => {
    await new Promise((resolve) => {
      let totalHeight = 0;
      const distance = 500;

      const timer = setInterval(() => {
        window.scrollBy(0, distance);
        totalHeight += distance;

        if (totalHeight >= document.body.scrollHeight) {
          clearInterval(timer);
          resolve();
        }
      }, 100);
    });
  });

  await page.pdf({
    path: outputPdf,
    format: 'A4',
    printBackground: true,
    margin: {
      top: '10mm',
      bottom: '10mm',
      left: '10mm',
      right: '10mm'
    }
  });

  await browser.close();
}

(async () => {
  await exportCoverage(
    'coverage/index.html',
    'laravel-coverage.pdf'
  );

  await exportCoverage(
    'coverage/html/index.html',
    'flutter-coverage.pdf'
  );
})();