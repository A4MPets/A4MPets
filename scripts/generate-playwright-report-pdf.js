const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const { PDFDocument } = require('pdf-lib');
const puppeteer = require('puppeteer');

const repoRoot = path.resolve(__dirname, '..');
const reportPath = path.join(
  repoRoot,
  'docs',
  'playwright-report',
  'playwright-report',
  'index.html',
);
const outputPath = path.join(repoRoot, 'docs', 'F5.pdf');

function reportUrl(hash = '') {
  return `${pathToFileURL(reportPath).href}${hash}`;
}

async function openSummaryPage(page) {
  await page.goto(reportUrl('#?'), {
    waitUntil: 'networkidle0',
    timeout: 60000,
  });

  await page.waitForFunction(
    () => document.body.innerText.includes('All') && document.body.innerText.includes('Total time'),
    { timeout: 30000 },
  );
}

async function preparePageForPdf(page) {
  await page.emulateMediaType('screen');
  await page.addStyleTag({
    content: `
      @page { size: A4 landscape; margin: 8mm; }
      html, body {
        height: auto !important;
        overflow: visible !important;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
      }
      .htmlreport,
      .vbox,
      .tab-content,
      .test-case-column,
      .test-result {
        height: auto !important;
        max-height: none !important;
        overflow: visible !important;
      }
      button.copy-icon,
      pre,
      code,
      .test-error-view,
      .source,
      .source-code,
      .cm-editor,
      .monaco-editor,
      [class*="source-code"],
      [class*="CodeMirror"] {
        display: none !important;
      }
      .chip-header {
        break-after: avoid;
      }
      .tree-item,
      .test-file-test,
      .attachment-body,
      .screenshot {
        break-inside: avoid;
      }
      a {
        text-decoration: none !important;
      }
    `,
  });
}

async function renderCurrentPageToPdfDocument(page) {
  await preparePageForPdf(page);

  const pdfBuffer = await page.pdf({
    format: 'A4',
    landscape: true,
    printBackground: true,
    margin: {
      top: '8mm',
      right: '8mm',
      bottom: '8mm',
      left: '8mm',
    },
    scale: 0.82,
    preferCSSPageSize: true,
  });

  return PDFDocument.load(pdfBuffer);
}

async function appendRenderedPage(outputDoc, page) {
  const sourceDoc = await renderCurrentPageToPdfDocument(page);
  const copiedPages = await outputDoc.copyPages(
    sourceDoc,
    sourceDoc.getPageIndices(),
  );

  for (const copiedPage of copiedPages) {
    outputDoc.addPage(copiedPage);
  }

  return sourceDoc.getPageCount();
}

async function main() {
  if (!fs.existsSync(reportPath)) {
    throw new Error(`No existe ${path.relative(repoRoot, reportPath)}`);
  }

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--allow-file-access-from-files', '--disable-web-security'],
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({
      width: 1440,
      height: 1800,
      deviceScaleFactor: 1,
    });

    await openSummaryPage(page);
    const outputDoc = await PDFDocument.create();

    console.log('[F5] Generando PDF solo con la pagina principal del reporte Playwright.');
    const summaryPages = await appendRenderedPage(outputDoc, page);
    console.log(`[F5] pagina principal agregada (${summaryPages} hojas).`);

    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, await outputDoc.save());

    console.log(
      `[F5] PDF generado: ${path.relative(repoRoot, outputPath)} (${outputDoc.getPageCount()} hojas)`,
    );
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
