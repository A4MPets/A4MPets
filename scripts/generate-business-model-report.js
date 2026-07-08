const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const puppeteer = require('puppeteer');

const repoRoot = path.resolve(__dirname, '..');
const reportDir = path.join(repoRoot, 'features', '03_negocio');
const htmlPath = path.join(reportDir, 'modelo_de_negocio_a4mpets.html');
const pdfPath = path.join(reportDir, 'modelo_de_negocio_a4mpets.pdf');

async function exportBusinessModel() {
  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();

  await page.setViewport({ width: 1600, height: 2200, deviceScaleFactor: 1 });
  await page.goto(pathToFileURL(htmlPath).href, {
    waitUntil: 'networkidle0'
  });

  await page.emulateMediaType('screen');

  await page.pdf({
    path: pdfPath,
    printBackground: true,
    preferCSSPageSize: true,
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
  if (!fs.existsSync(htmlPath)) {
    throw new Error(`HTML report not found: ${htmlPath}`);
  }

  await exportBusinessModel();
})();
