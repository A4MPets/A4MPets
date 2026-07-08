const fs = require('fs');
const path = require('path');
const { fileURLToPath, pathToFileURL } = require('url');
const { PDFDocument } = require('pdf-lib');
const puppeteer = require('puppeteer');

const repoRoot = path.resolve(__dirname, '..');
const docsDir = path.join(repoRoot, 'docs');
const tempDir = path.join(repoRoot, '.runtime', 'coverage-pdfs');

const jobs = [
  {
    label: 'F1',
    rootDir: path.join(docsDir, 'coverageF1', 'coverageF1'),
    outputPath: path.join(docsDir, 'F1.pdf'),
  },
  {
    label: 'F2',
    rootDir: path.join(docsDir, 'coverageF2', 'html'),
    outputPath: path.join(docsDir, 'F2.pdf'),
  },
  {
    label: 'F3',
    rootDir: path.join(docsDir, 'coverageF3', 'coverageF3'),
    outputPath: path.join(docsDir, 'F3.pdf'),
  },
  {
    label: 'F1yF3',
    rootDir: path.join(docsDir, 'coverageF1yF3', 'coverage'),
    outputPath: path.join(docsDir, 'F1yF3.pdf'),
  },
];

function normalizeKey(filePath) {
  return path.resolve(filePath).toLowerCase();
}

function isInside(parentDir, filePath) {
  const relative = path.relative(parentDir, filePath);
  return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
}

function isHtmlFile(filePath) {
  return /\.html?$/i.test(filePath);
}

function shouldRenderStatsPage(filePath) {
  const fileName = path.basename(filePath).toLowerCase();

  return fileName === 'index.html';
}

function resolveLinkedHtml(currentFile, href, rootDir) {
  try {
    const currentUrl = pathToFileURL(currentFile);
    const linkedUrl = new URL(href, currentUrl);

    if (linkedUrl.protocol !== 'file:') {
      return null;
    }

    linkedUrl.hash = '';
    linkedUrl.search = '';

    const linkedPath = path.resolve(fileURLToPath(linkedUrl));

    if (!isHtmlFile(linkedPath) || !isInside(rootDir, linkedPath)) {
      return null;
    }

    if (!fs.existsSync(linkedPath)) {
      return null;
    }

    return linkedPath;
  } catch (_) {
    return null;
  }
}

async function extractLinks(page, filePath, rootDir) {
  await page.goto(pathToFileURL(filePath).href, {
    waitUntil: 'domcontentloaded',
    timeout: 45000,
  });

  const hrefs = await page.$$eval('a[href]', (anchors) =>
    anchors.map((anchor) => anchor.getAttribute('href')).filter(Boolean),
  );

  return hrefs
    .map((href) => resolveLinkedHtml(filePath, href, rootDir))
    .filter(Boolean);
}

async function crawlHtmlDfs(browser, rootDir) {
  const startFile = path.join(rootDir, 'index.html');

  if (!fs.existsSync(startFile)) {
    throw new Error(`No existe ${path.relative(repoRoot, startFile)}`);
  }

  const page = await browser.newPage();
  const visited = new Set();
  const order = [];
  let visitedCount = 0;

  async function visit(filePath) {
    const key = normalizeKey(filePath);

    if (visited.has(key)) {
      return;
    }

    visited.add(key);
    visitedCount += 1;

    if (shouldRenderStatsPage(filePath)) {
      order.push(filePath);
    }

    const links = await extractLinks(page, filePath, rootDir);

    for (const linkedPath of links) {
      await visit(linkedPath);
    }
  }

  await visit(startFile);
  await page.close();
  return { renderOrder: order, visitedCount };
}

async function renderHtmlToPdfDocument(browser, filePath) {
  const page = await browser.newPage();

  await page.setViewport({
    width: 1600,
    height: 1000,
    deviceScaleFactor: 1,
  });
  await page.emulateMediaType('screen');
  await page.goto(pathToFileURL(filePath).href, {
    waitUntil: 'networkidle0',
    timeout: 60000,
  });

  await page.addStyleTag({
    content: `
      @page { size: A4 landscape; margin: 8mm; }
      html, body { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
      a { text-decoration: none !important; }
    `,
  });

  await page.evaluate(() => {
    const targetWidth = 1062;
    const targetHeight = 733;
    const documentElement = document.documentElement;
    const body = document.body;
    const width = Math.max(
      documentElement.scrollWidth,
      body.scrollWidth,
      documentElement.offsetWidth,
      body.offsetWidth,
    );
    const height = Math.max(
      documentElement.scrollHeight,
      body.scrollHeight,
      documentElement.offsetHeight,
      body.offsetHeight,
    );
    const scale = Math.min(1, targetWidth / width, targetHeight / height);
    const wrapper = document.createElement('div');

    while (body.firstChild) {
      wrapper.appendChild(body.firstChild);
    }

    wrapper.style.width = `${width}px`;
    wrapper.style.transform = `scale(${scale})`;
    wrapper.style.transformOrigin = 'top left';

    body.appendChild(wrapper);
    body.style.width = `${targetWidth}px`;
    body.style.height = `${targetHeight}px`;
    body.style.margin = '0';
    body.style.overflow = 'hidden';
    documentElement.style.width = `${targetWidth}px`;
    documentElement.style.height = `${targetHeight}px`;
    documentElement.style.overflow = 'hidden';
  });

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
    scale: 0.78,
    preferCSSPageSize: true,
  });

  await page.close();
  return PDFDocument.load(pdfBuffer);
}

async function writeCombinedPdf(browser, job) {
  const { renderOrder: htmlFiles, visitedCount } = await crawlHtmlDfs(
    browser,
    job.rootDir,
  );
  const outputDoc = await PDFDocument.create();

  console.log(
    `[${job.label}] ${visitedCount} paginas HTML visitadas por DFS; ${htmlFiles.length} paginas estadisticas seleccionadas.`,
  );

  for (let index = 0; index < htmlFiles.length; index += 1) {
    const filePath = htmlFiles[index];
    const relativePath = path.relative(job.rootDir, filePath);
    console.log(`[${job.label}] ${index + 1}/${htmlFiles.length} ${relativePath}`);

    const sourceDoc = await renderHtmlToPdfDocument(browser, filePath);
    const copiedPages = await outputDoc.copyPages(
      sourceDoc,
      sourceDoc.getPageIndices(),
    );

    for (const copiedPage of copiedPages) {
      outputDoc.addPage(copiedPage);
    }
  }

  fs.mkdirSync(path.dirname(job.outputPath), { recursive: true });
  const pdfBytes = await outputDoc.save();
  fs.writeFileSync(job.outputPath, pdfBytes);

  console.log(
    `[${job.label}] PDF generado: ${path.relative(repoRoot, job.outputPath)} (${outputDoc.getPageCount()} hojas)`,
  );
}

async function main() {
  fs.mkdirSync(tempDir, { recursive: true });

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--allow-file-access-from-files', '--disable-web-security'],
  });

  try {
    for (const job of jobs) {
      await writeCombinedPdf(browser, job);
    }
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
