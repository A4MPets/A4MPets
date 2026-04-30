const fs = require('fs');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '..');
const OUTPUT_DIR = path.join(ROOT_DIR, 'docs', 'requirements');
const DATA_FILES = [
  {
    fileName: 'requisitos_funcionales.json',
    idPrefix: 'RF-',
  },
  {
    fileName: 'requisitos_no_funcionales.json',
    idPrefix: 'RNF-',
  },
  {
    fileName: 'requisitos_interfaz.json',
    idPrefix: 'RI-',
  },
];

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function ensureDirectory(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function validateDocument(document, fileName, idPrefix) {
  assert(document && typeof document === 'object', `${fileName}: documento inválido.`);
  assert(typeof document.title === 'string' && document.title.trim(), `${fileName}: falta title.`);
  assert(typeof document.purpose === 'string' && document.purpose.trim(), `${fileName}: falta purpose.`);
  assert(typeof document.context === 'string' && document.context.trim(), `${fileName}: falta context.`);
  assert(Array.isArray(document.requirements), `${fileName}: falta requirements.`);
  assert(document.requirements.length === 100, `${fileName}: debe contener exactamente 100 requisitos y tiene ${document.requirements.length}.`);

  const seenIds = new Set();

  document.requirements.forEach((requirement, index) => {
    const position = index + 1;
    const tag = `${fileName} requisito #${position}`;
    assert(requirement && typeof requirement === 'object', `${tag}: objeto inválido.`);
    assert(typeof requirement.id === 'string' && requirement.id.startsWith(idPrefix), `${tag}: id inválido.`);
    assert(!seenIds.has(requirement.id), `${tag}: id duplicado ${requirement.id}.`);
    seenIds.add(requirement.id);

    for (const fieldName of ['title', 'statement', 'priority', 'source', 'verification_method', 'traceability']) {
      assert(
        typeof requirement[fieldName] === 'string' && requirement[fieldName].trim(),
        `${tag}: falta ${fieldName}.`,
      );
    }

    assert(
      ['Alta', 'Media', 'Baja'].includes(requirement.priority),
      `${tag}: prioridad inválida ${requirement.priority}.`,
    );
    assert(
      ['Prueba', 'Inspección', 'Medición'].includes(requirement.verification_method),
      `${tag}: método de verificación inválido ${requirement.verification_method}.`,
    );
  });
}

function renderGlossary(glossary) {
  if (!Array.isArray(glossary) || glossary.length === 0) {
    return '';
  }

  const rows = glossary
    .map(
      (item) => `
        <tr>
          <td class="term-cell">${escapeHtml(item.term)}</td>
          <td>${escapeHtml(item.definition)}</td>
        </tr>`,
    )
    .join('');

  return `
    <section class="section">
      <h2>Glosario</h2>
      <table class="glossary-table">
        <thead>
          <tr>
            <th>Término</th>
            <th>Definición</th>
          </tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    </section>
  `;
}

function renderRequirements(document) {
  return document.requirements
    .map(
      (requirement) => `
        <tr>
          <td class="id-cell">${escapeHtml(requirement.id)}</td>
          <td>${escapeHtml(requirement.title)}</td>
          <td>${escapeHtml(requirement.statement)}</td>
          <td>${escapeHtml(requirement.priority)}</td>
          <td>${escapeHtml(requirement.source)}</td>
          <td>${escapeHtml(requirement.verification_method)}</td>
          <td>${escapeHtml(requirement.traceability)}</td>
        </tr>`,
    )
    .join('');
}

function renderHtml(document) {
  const generatedAt = new Date().toLocaleString('es-CO', {
    dateStyle: 'long',
    timeStyle: 'short',
  });

  return `<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <title>${escapeHtml(document.title)}</title>
    <style>
      @page {
        size: A4;
        margin: 18mm 12mm 18mm 12mm;
      }

      :root {
        --ink: #1f2933;
        --muted: #52606d;
        --line: #d9e2ec;
        --surface: #f7f9fb;
        --accent: #5984bc;
        --accent-soft: #d9e8ff;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        color: var(--ink);
        font-family: "Segoe UI", Arial, sans-serif;
        font-size: 10.2pt;
        line-height: 1.35;
      }

      h1, h2, h3 {
        margin: 0;
      }

      .cover {
        min-height: 250mm;
        display: flex;
        flex-direction: column;
        justify-content: center;
        padding: 18mm;
        border: 1px solid var(--line);
        background: linear-gradient(180deg, #ffffff 0%, #f4f8ff 100%);
      }

      .cover-label {
        color: var(--accent);
        font-weight: 700;
        letter-spacing: 0.12em;
        text-transform: uppercase;
        margin-bottom: 10mm;
      }

      .cover h1 {
        font-size: 24pt;
        margin-bottom: 8mm;
      }

      .cover p {
        margin: 0 0 4mm 0;
        color: var(--muted);
        font-size: 11pt;
      }

      .section {
        margin-top: 10mm;
      }

      .section h2 {
        font-size: 14pt;
        margin-bottom: 4mm;
        color: var(--accent);
      }

      .section p {
        margin: 0;
      }

      .meta-grid {
        margin-top: 10mm;
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 4mm;
      }

      .meta-card {
        border: 1px solid var(--line);
        border-radius: 8px;
        background: #fff;
        padding: 4mm;
      }

      .meta-card strong {
        display: block;
        color: var(--accent);
        margin-bottom: 1.5mm;
      }

      table {
        width: 100%;
        border-collapse: collapse;
      }

      .requirements-table {
        margin-top: 5mm;
        table-layout: fixed;
      }

      .requirements-table thead th {
        position: sticky;
        top: 0;
        background: var(--accent-soft);
        color: var(--ink);
        font-size: 9.2pt;
      }

      .requirements-table th,
      .requirements-table td,
      .glossary-table th,
      .glossary-table td {
        border: 1px solid var(--line);
        padding: 2.3mm;
        text-align: left;
        vertical-align: top;
      }

      .requirements-table tr {
        page-break-inside: avoid;
      }

      .requirements-table tbody tr:nth-child(even) {
        background: var(--surface);
      }

      .id-cell {
        width: 12%;
        font-weight: 700;
        color: var(--accent);
      }

      .term-cell {
        width: 24%;
        font-weight: 700;
      }

      .footer-note {
        margin-top: 6mm;
        color: var(--muted);
        font-size: 8.7pt;
      }
    </style>
  </head>
  <body>
    <section class="cover">
      <div class="cover-label">A4MPets</div>
      <h1>${escapeHtml(document.title)}</h1>
      <p>${escapeHtml(document.purpose)}</p>
      <div class="meta-grid">
        <div class="meta-card">
          <strong>Contexto</strong>
          <span>${escapeHtml(document.context)}</span>
        </div>
        <div class="meta-card">
          <strong>Generado</strong>
          <span>${escapeHtml(generatedAt)}</span>
        </div>
      </div>
    </section>

    <section class="section">
      <h2>Propósito del documento</h2>
      <p>${escapeHtml(document.purpose)}</p>
    </section>

    <section class="section">
      <h2>Contexto del sistema</h2>
      <p>${escapeHtml(document.context)}</p>
    </section>

    ${renderGlossary(document.glossary)}

    <section class="section">
      <h2>Tabla de requisitos</h2>
      <table class="requirements-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Título</th>
            <th>Requisito</th>
            <th>Prioridad</th>
            <th>Fuente / Justificación</th>
            <th>Verificación</th>
            <th>Trazabilidad</th>
          </tr>
        </thead>
        <tbody>${renderRequirements(document)}</tbody>
      </table>
      <p class="footer-note">
        Documento elaborado bajo criterios de claridad, consistencia, verificabilidad y trazabilidad alineados con la definición de requisito empleada en RUP.
      </p>
    </section>
  </body>
</html>`;
}

async function exportPdf(htmlPath, pdfPath) {
  let puppeteer;
  try {
    puppeteer = require('puppeteer');
  } catch (error) {
    throw new Error(
      'No se encontró puppeteer. Ejecuta "npm install --save-dev puppeteer" antes de generar los PDFs.',
    );
  }

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();
    await page.goto(`file://${htmlPath.replaceAll('\\', '/')}`, {
      waitUntil: 'networkidle0',
    });
    await page.pdf({
      path: pdfPath,
      format: 'A4',
      printBackground: true,
      preferCSSPageSize: true,
    });
  } finally {
    await browser.close();
  }
}

async function main() {
  ensureDirectory(OUTPUT_DIR);

  for (const fileConfig of DATA_FILES) {
    const jsonPath = path.join(OUTPUT_DIR, fileConfig.fileName);
    const document = readJson(jsonPath);
    validateDocument(document, fileConfig.fileName, fileConfig.idPrefix);

    const html = renderHtml(document);
    const htmlPath = path.join(
      OUTPUT_DIR,
      fileConfig.fileName.replace('.json', '.html'),
    );
    const pdfPath = path.join(
      OUTPUT_DIR,
      fileConfig.fileName.replace('.json', '.pdf'),
    );

    fs.writeFileSync(htmlPath, html, 'utf8');
    await exportPdf(htmlPath, pdfPath);
    console.log(`Generado: ${path.relative(ROOT_DIR, pdfPath)}`);
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
