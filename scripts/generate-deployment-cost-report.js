const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const repoRoot = path.resolve(__dirname, '..');
const docsDir = path.join(repoRoot, 'docs');
const htmlPath = path.join(docsDir, 'costos_despliegue_a4mpets_2026.html');
const pdfPath = path.join(docsDir, 'costos_despliegue_a4mpets_2026.pdf');

const USD_COP = 3433.71;
const VAT = 0.19;
const googlePlayUsd = 25;
const appleUsdPerYear = 99;
const domainUsdPerYear = 10.98;
const domainUsdPerMonth = domainUsdPerYear / 12;

function cop(usd) {
  return Math.round(usd * USD_COP);
}

function moneyCop(value) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(value);
}

function moneyUsd(value) {
  if (Array.isArray(value)) {
    return `$${value[0].toFixed(2)} - $${value[1].toFixed(2)} USD`;
  }

  return `$${value.toFixed(2)} USD`;
}

function annualUsd(monthlyUsd, oneTimeUsd = 0) {
  if (Array.isArray(monthlyUsd)) {
    return [monthlyUsd[0] * 12 + oneTimeUsd, monthlyUsd[1] * 12 + oneTimeUsd];
  }

  return monthlyUsd * 12 + oneTimeUsd;
}

function copForUsd(value) {
  if (Array.isArray(value)) {
    return `${moneyCop(cop(value[0]))} - ${moneyCop(cop(value[1]))}`;
  }

  return moneyCop(cop(value));
}

function monthlyWithDomain(baseMonthlyUsd) {
  if (Array.isArray(baseMonthlyUsd)) {
    return [baseMonthlyUsd[0] + domainUsdPerMonth, baseMonthlyUsd[1] + domainUsdPerMonth];
  }

  return baseMonthlyUsd + domainUsdPerMonth;
}

const options = [
  {
    name: '0. Landing/PWA demostrativa sin backend productivo',
    fit: 'Para presentar marca, historia, pantallas, video demo y formulario de contacto. No es el sistema completo.',
    architecture: 'Cloudflare Pages gratis + dominio .com opcional. Sin PostgreSQL ni GraphHopper público.',
    baseMonthlyUsd: 0,
    risk: 'Muy bajo costo, pero no demuestra la operación real del producto.',
    recommendation: 'Usar solo como vitrina inicial o página para captar interesados.',
  },
  {
    name: '1. VPS único mínimo',
    fit: 'Demo técnica con usuarios limitados y operación controlada.',
    architecture: 'Un VPS Linux de 2 GB: Docker Compose con frontend, Laravel, PostgreSQL, media local y GraphHopper para zona acotada.',
    baseMonthlyUsd: 12,
    risk: 'GraphHopper puede quedar justo de memoria; requiere administración manual, backups y monitoreo.',
    recommendation: 'Sirve para primera demostración si el tráfico es bajo y el mapa se limita geográficamente.',
  },
  {
    name: '2. VPS único recomendado',
    fit: 'Mejor balance costo/credibilidad para un MVP mostrado a inversionistas.',
    architecture: 'Un VPS Linux de 4 GB: Docker Compose, PostgreSQL, Nginx, backend Laravel, Flutter web estático y GraphHopper.',
    baseMonthlyUsd: 24,
    risk: 'Sigue siendo infraestructura autogestionada; un fallo del VPS afecta todo.',
    recommendation: 'Opción recomendada para el primer despliegue real de A4MPets.',
  },
  {
    name: '3. Render administrado, modo económico',
    fit: 'MVP con menos operación de servidor y despliegue desde Git.',
    architecture: 'Render Static Site gratis + backend Starter ($7) + GraphHopper Standard 2 GB ($25) + Postgres Basic-256MB ($6).',
    baseMonthlyUsd: 38,
    risk: 'Postgres Basic es pequeño; GraphHopper podría requerir subir de plan según memoria y datos OSM.',
    recommendation: 'Buena ruta si se prioriza facilidad de despliegue sobre costo mínimo.',
  },
  {
    name: '4. Render Pro administrado',
    fit: 'MVP con presentación más seria para aliados, soporte y entorno de producción administrado.',
    architecture: 'Render Pro workspace ($25) + backend Starter ($7) + GraphHopper Standard ($25) + Postgres Basic-256MB ($6).',
    baseMonthlyUsd: 63,
    risk: 'Costo sube rápido si se necesita Postgres de 1 GB, logs más largos o más ancho de banda.',
    recommendation: 'Adecuada cuando haya pilotos con entidades o empresas y se necesite soporte de plataforma.',
  },
  {
    name: '5. Frontend Vercel/Cloudflare + backend administrado',
    fit: 'Separación moderna: frontend global, backend y datos administrados.',
    architecture: 'Vercel Pro ($20) o Cloudflare Pages, backend Render Starter ($7), GraphHopper Render Standard ($25), Neon Launch típico ($15).',
    baseMonthlyUsd: 67,
    risk: 'Más piezas, más integraciones y más puntos de facturación.',
    recommendation: 'Interesante si el frontend necesita CI/CD premium y previews para stakeholders.',
  },
  {
    name: '6. Railway todo-en-uno',
    fit: 'Prototipado veloz con servicios Docker y PostgreSQL en una misma plataforma.',
    architecture: 'Railway Hobby/Pro con backend, Postgres y GraphHopper como servicios. Estimación por uso real.',
    baseMonthlyUsd: [35, 60],
    risk: 'El precio es usage-based; si GraphHopper consume RAM constante, la factura puede variar.',
    recommendation: 'Muy cómodo para iterar, menos predecible que un VPS para GraphHopper.',
  },
  {
    name: '7. Google Cloud serverless + VM para GraphHopper',
    fit: 'Ruta seria para escalar y solicitar créditos cloud/startup.',
    architecture: 'Cloud Run para backend, Cloud SQL PostgreSQL pequeño, Cloud Storage para media y una VM pequeña para GraphHopper.',
    baseMonthlyUsd: [35, 55],
    risk: 'Cloud SQL y la VM generan costo constante; requiere configuración cloud más cuidadosa.',
    recommendation: 'Buena opción si se busca apoyo de Google for Startups o trazabilidad enterprise.',
  },
  {
    name: '8. Refactor BaaS con Supabase/Firebase',
    fit: 'Si se decide migrar parte del backend a servicios administrados y reducir operación propia.',
    architecture: 'Supabase Pro ($25) o Firebase Blaze/Spark + frontend estático + GraphHopper en VPS pequeño.',
    baseMonthlyUsd: [38, 70],
    risk: 'No es despliegue directo del código actual; implica rediseñar auth, API, storage y reglas de seguridad.',
    recommendation: 'No usar para el primer despliegue si la prioridad es salir rápido con el proyecto existente.',
  },
];

const sources = [
  ['TRM Banco de la Republica, 26/06/2026: 3.433,71 COP/USD', 'https://www.banrep.gov.co/es/glosario/tasa-cambio-trm'],
  ['Google Play Console: tarifa unica de registro US$25', 'https://support.google.com/googleplay/android-developer/answer/6112435?hl=en'],
  ['Apple Developer Program: US$99 por ano', 'https://developer.apple.com/support/compare-memberships/'],
  ['Cloudflare Pages: Free $0; Pro $20 anual / $25 mensual', 'https://pages.cloudflare.com/'],
  ['Cloudflare Workers/Paid: minimo US$5 mensual', 'https://developers.cloudflare.com/workers/platform/pricing/'],
  ['Vercel Pricing: Hobby gratis; Pro US$20/mes', 'https://vercel.com/pricing'],
  ['Render Pricing: servicios, Postgres, workspace y storage', 'https://render.com/pricing'],
  ['Railway Pricing: Hobby US$5 minimo; Pro US$20 minimo', 'https://railway.com/pricing'],
  ['DigitalOcean Droplets desde US$4/mes; transferencia incluida segun plan', 'https://www.digitalocean.com/pricing/droplets'],
  ['Supabase Pricing: Pro US$25/mes', 'https://supabase.com/pricing'],
  ['Neon Pricing: Free y Launch con gasto tipico US$15/mes', 'https://neon.com/pricing'],
  ['Google Cloud Run: free tier de CPU, RAM y solicitudes', 'https://cloud.google.com/run/pricing'],
  ['Google Cloud Free: US$300 en creditos para nuevos clientes', 'https://cloud.google.com/free'],
  ['GraphHopper Open Source: motor Java desplegable en servidor propio', 'https://www.graphhopper.com/open-source/'],
  ['OpenStreetMap Tile Usage Policy: sin SLA, capacidad limitada, no uso pesado/offline', 'https://operations.osmfoundation.org/policies/tiles/'],
  ['Namecheap dominios .com desde US$10.98/ano', 'https://www.namecheap.com/domains/'],
];

function optionRows() {
  return options
    .map((option) => {
      const monthly = monthlyWithDomain(option.baseMonthlyUsd);
      const annualNoPlay = annualUsd(monthly);
      const annualWithPlay = annualUsd(monthly, googlePlayUsd);
      const monthlyVat = Array.isArray(monthly)
        ? [monthly[0] * (1 + VAT), monthly[1] * (1 + VAT)]
        : monthly * (1 + VAT);

      return `
        <tr>
          <td>
            <strong>${option.name}</strong>
            <div class="small muted">${option.fit}</div>
          </td>
          <td>${option.architecture}</td>
          <td class="num">${moneyUsd(monthly)}<br><span class="small">${copForUsd(monthly)}</span></td>
          <td class="num">${copForUsd(annualNoPlay)}<br><span class="small">${moneyUsd(annualNoPlay)}</span></td>
          <td class="num">${copForUsd(annualWithPlay)}<br><span class="small">${moneyUsd(annualWithPlay)}</span></td>
          <td class="num">${copForUsd(monthlyVat)}<br><span class="small">mensual con 19% ref.</span></td>
          <td>${option.risk}<br><strong>Lectura:</strong> ${option.recommendation}</td>
        </tr>
      `;
    })
    .join('');
}

function sourceRows() {
  return sources
    .map(([label, url], index) => `<li>[${index + 1}] <a href="${url}">${label}</a></li>`)
    .join('');
}

const recommendedMonthly = monthlyWithDomain(24);
const recommendedAnnual = annualUsd(recommendedMonthly, googlePlayUsd);
const html = `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>Costos de despliegue A4MPets 2026</title>
  <style>
    @page { size: A4 landscape; margin: 11mm; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: Arial, Helvetica, sans-serif;
      color: #172033;
      background: #fff;
      font-size: 11px;
      line-height: 1.35;
    }
    h1, h2, h3 { margin: 0 0 8px; color: #111827; }
    h1 { font-size: 28px; letter-spacing: 0; }
    h2 { font-size: 18px; margin-top: 18px; border-bottom: 2px solid #dbeafe; padding-bottom: 5px; }
    h3 { font-size: 14px; margin-top: 12px; }
    p { margin: 0 0 8px; }
    a { color: #1d4ed8; text-decoration: none; }
    .hero {
      background: linear-gradient(135deg, #0f172a, #1e3a8a);
      color: white;
      padding: 22px 26px;
      border-radius: 10px;
      margin-bottom: 14px;
    }
    .hero h1 { color: white; }
    .hero p { max-width: 980px; font-size: 13px; color: #dbeafe; }
    .grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 10px;
      margin: 12px 0;
    }
    .metric {
      border: 1px solid #d8dee9;
      border-radius: 8px;
      padding: 10px;
      background: #f8fafc;
      min-height: 78px;
    }
    .metric .label { color: #526174; font-size: 10px; text-transform: uppercase; letter-spacing: .05em; }
    .metric .value { font-size: 18px; font-weight: 700; color: #0f172a; margin-top: 4px; }
    .metric .note { color: #64748b; font-size: 10px; margin-top: 3px; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 10px 0 14px;
      page-break-inside: auto;
    }
    th, td {
      border: 1px solid #d8dee9;
      padding: 7px;
      vertical-align: top;
    }
    th {
      background: #eef2ff;
      color: #111827;
      font-size: 10px;
      text-align: left;
    }
    tr { page-break-inside: avoid; }
    .num { text-align: right; white-space: nowrap; }
    .small { font-size: 9px; }
    .muted { color: #64748b; }
    .callout {
      border-left: 5px solid #2563eb;
      background: #eff6ff;
      padding: 10px 12px;
      border-radius: 6px;
      margin: 10px 0;
    }
    .warning {
      border-left-color: #d97706;
      background: #fffbeb;
    }
    .page-break { page-break-before: always; }
    ul { margin: 6px 0 0 18px; padding: 0; }
    li { margin: 3px 0; }
    .two-col {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 14px;
    }
  </style>
</head>
<body>
  <section class="hero">
    <h1>Costos de despliegue inicial para A4MPets</h1>
    <p>Estimacion para convertir el proyecto de grado en una vitrina creible ante inversionistas, entidades publicas o empresas. Precios consultados el 26 de junio de 2026 y convertidos con TRM oficial de ${moneyCop(USD_COP)} por USD.</p>
  </section>

  <div class="grid">
    <div class="metric">
      <div class="label">TRM usada</div>
      <div class="value">${moneyCop(USD_COP)}</div>
      <div class="note">Banco de la Republica, 26/06/2026</div>
    </div>
    <div class="metric">
      <div class="label">Google Play</div>
      <div class="value">${moneyCop(cop(googlePlayUsd))}</div>
      <div class="note">US$25, pago unico</div>
    </div>
    <div class="metric">
      <div class="label">Apple opcional</div>
      <div class="value">${moneyCop(cop(appleUsdPerYear))}</div>
      <div class="note">US$99 por ano</div>
    </div>
    <div class="metric">
      <div class="label">Dominio .com ref.</div>
      <div class="value">${moneyCop(cop(domainUsdPerYear))}</div>
      <div class="note">US$10.98/ano, amortizado en tablas</div>
    </div>
  </div>

  <div class="callout">
    <strong>Recomendacion ejecutiva:</strong> para una primera demostracion publica, la opcion mas equilibrada es el <strong>VPS unico recomendado</strong>: aproximadamente <strong>${copForUsd(recommendedMonthly)} al mes</strong> y <strong>${copForUsd(recommendedAnnual)} el primer ano con Google Play</strong>. Es suficientemente barata para bootstrapping y suficientemente real para mostrar backend, rutas, reportes, archivos e instalacion Android.
  </div>

  <h2>Supuestos de arquitectura</h2>
  <div class="two-col">
    <div>
      <p><strong>Proyecto actual:</strong> Flutter web/PWA, backend Laravel API, base de datos relacional, subida de medios, rutas con GraphHopper y mapas basados en OpenStreetMap.</p>
      <p><strong>Produccion minima:</strong> HTTPS, dominio propio, base de datos persistente, backups, almacenamiento de imagenes, logs, monitoreo basico y una estrategia para GraphHopper.</p>
    </div>
    <div>
      <p><strong>Importante:</strong> Google Play no aloja backend ni base de datos. Solo permite publicar la app Android. Por eso se presenta como costo adicional de primer ano, no como hosting.</p>
      <p><strong>Impuestos:</strong> las columnas principales estan antes de IVA/comisiones bancarias. Se incluye una columna mensual con 19% como referencia conservadora.</p>
    </div>
  </div>

  <h2>Comparativo de opciones</h2>
  <table>
    <thead>
      <tr>
        <th>Opcion</th>
        <th>Componentes incluidos</th>
        <th>Costo mensual con dominio</th>
        <th>Primer ano sin Google Play</th>
        <th>Primer ano con Google Play</th>
        <th>Mensual + 19% ref.</th>
        <th>Riesgo y lectura</th>
      </tr>
    </thead>
    <tbody>
      ${optionRows()}
    </tbody>
  </table>

  <h2>Lectura estrategica para inversionistas</h2>
  <table>
    <thead>
      <tr>
        <th>Etapa</th>
        <th>Objetivo</th>
        <th>Infraestructura sugerida</th>
        <th>Rango mensual COP</th>
        <th>Mensaje para convocatoria/inversion</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>Pre-demo</strong></td>
        <td>Mostrar propuesta, capturar correos y validar interes.</td>
        <td>Landing en Cloudflare Pages + dominio.</td>
        <td>${copForUsd(monthlyWithDomain(0))}</td>
        <td>Muy bajo riesgo financiero; no demuestra operacion completa.</td>
      </tr>
      <tr>
        <td><strong>MVP publico</strong></td>
        <td>Permitir pruebas reales con usuarios aliados.</td>
        <td>VPS 4 GB con Docker, PostgreSQL y GraphHopper.</td>
        <td>${copForUsd(monthlyWithDomain(24))}</td>
        <td>Buen balance para presentar traccion inicial sin quemar presupuesto.</td>
      </tr>
      <tr>
        <td><strong>Piloto institucional</strong></td>
        <td>Usar con una alcaldia, universidad, fundacion o empresa aliada.</td>
        <td>Render Pro o Google Cloud con servicios administrados.</td>
        <td>${copForUsd(monthlyWithDomain([63, 80]))}</td>
        <td>Mayor confiabilidad, mejores logs y soporte para convenios.</td>
      </tr>
      <tr>
        <td><strong>Escalamiento</strong></td>
        <td>Usuarios recurrentes, app store, metricas, soporte y crecimiento regional.</td>
        <td>Cloud administrado, almacenamiento externo, backups, monitoreo, CDN y mapas comerciales si aplica.</td>
        <td>${copForUsd([300000 / USD_COP, 900000 / USD_COP])}</td>
        <td>Se justifica cuando exista traccion, pilotos pagos o recursos de convocatoria.</td>
      </tr>
    </tbody>
  </table>

  <h2>Costos de tienda movil</h2>
  <table>
    <thead>
      <tr>
        <th>Canal</th>
        <th>Costo oficial</th>
        <th>Equivalente COP</th>
        <th>Cuándo incluirlo</th>
        <th>Notas</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>Google Play</strong></td>
        <td>US$25, pago unico</td>
        <td>${moneyCop(cop(googlePlayUsd))}</td>
        <td>Cuando el MVP Android este listo para pruebas cerradas o publicacion.</td>
        <td>No aloja el sistema. Requiere politicas, ficha, imagenes, pruebas y verificacion de cuenta.</td>
      </tr>
      <tr>
        <td><strong>Sin Google Play</strong></td>
        <td>US$0</td>
        <td>${moneyCop(0)}</td>
        <td>Web/PWA, APK distribuido directamente o demos controladas.</td>
        <td>Menor confianza para usuarios finales; suficiente para demos tempranas.</td>
      </tr>
      <tr>
        <td><strong>Apple App Store</strong></td>
        <td>US$99/ano</td>
        <td>${moneyCop(cop(appleUsdPerYear))}/ano</td>
        <td>Solo si se prioriza iOS y hay presupuesto de validacion.</td>
        <td>No es necesario para la primera demostracion si Android/PWA cubre el piloto.</td>
      </tr>
    </tbody>
  </table>

  <div class="page-break"></div>
  <h2>Decision recomendada</h2>
  <div class="callout">
    <p><strong>Ruta practica:</strong> iniciar con <strong>VPS unico recomendado + dominio + Google Play</strong>. El primer ano queda alrededor de <strong>${copForUsd(recommendedAnnual)}</strong> antes de IVA/comisiones, y permite contar una historia de producto completo: app, backend, mapas, rutas, reportes, comentarios y evidencia tecnica.</p>
    <p><strong>Ruta para convocatoria estatal:</strong> presentar dos presupuestos: MVP austero en VPS y piloto institucional administrado en Render/Google Cloud. Eso muestra control financiero y capacidad de escalar si hay recursos.</p>
    <p><strong>Ruta para empresas:</strong> usar Render Pro o Google Cloud si la conversacion exige soporte, logs, auditoria, monitoreo y separacion de responsabilidades.</p>
  </div>

  <div class="callout warning">
    <strong>Advertencias tecnicas:</strong> OpenStreetMap permite usar sus datos, pero sus servidores publicos de tiles no tienen SLA y pueden bloquear uso pesado. Para traccion real conviene usar proveedor de tiles o self-host. GraphHopper open source no cobra licencia, pero consume servidor, memoria y mantenimiento de datos OSM.
  </div>

  <h2>Fuentes consultadas</h2>
  <ol class="small">
    ${sourceRows()}
  </ol>
</body>
</html>`;

async function main() {
  fs.mkdirSync(docsDir, { recursive: true });
  fs.writeFileSync(htmlPath, html, 'utf8');

  const browser = await puppeteer.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 1600, height: 1000, deviceScaleFactor: 1 });
    await page.goto(`file://${htmlPath.replace(/\\/g, '/')}`, {
      waitUntil: 'networkidle0',
      timeout: 60000,
    });
    await page.pdf({
      path: pdfPath,
      format: 'A4',
      landscape: true,
      printBackground: true,
      margin: {
        top: '10mm',
        right: '10mm',
        bottom: '10mm',
        left: '10mm',
      },
    });
  } finally {
    await browser.close();
  }

  console.log(`HTML generado: ${path.relative(repoRoot, htmlPath)}`);
  console.log(`PDF generado: ${path.relative(repoRoot, pdfPath)}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
