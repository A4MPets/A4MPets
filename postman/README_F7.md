# A4MPets F7 - Postman Performance Cloudflare

Este paquete prepara F7 como pruebas no funcionales de performance API usando Postman Desktop Performance Testing contra el backend local expuesto por Cloudflare Tunnel.

## Archivos

- `F7_A4MPets_Performance.postman_collection.json`: coleccion por escenarios F7-001 a F7-020.
- `F7_A4MPets_Cloudflare.postman_environment.json`: environment con URL, credenciales, token y umbrales.
- `f7-performance-data.csv`: datos por usuario virtual para variar nombres, coordenadas y comentarios.
- `f7-runner-data.csv`: archivo legado de apoyo si se requiere ejecutar Runner clasico.

## Preparacion

1. Levantar el stack local.
2. Levantar Cloudflare Tunnel:

```bash
npm run dev:cloudflare
```

3. Copiar la URL publica desde `.runtime/cloudflare-url.txt`.
4. Importar en Postman:
   - `postman/F7_A4MPets_Performance.postman_collection.json`.
   - `postman/F7_A4MPets_Cloudflare.postman_environment.json`.
5. Seleccionar el environment `A4MPets F7 Cloudflare`.
6. Editar variables:
   - `base_url`: URL Cloudflare sin slash final.
   - `qa_login`: usuario QA existente.
   - `qa_password`: contrasena QA.
7. Ejecutar primero `00 - Setup` con Run normal para guardar `access_token` y `hazard_id`.

## Ejecucion Performance

Usar Postman Desktop, abrir la coleccion o carpeta, seleccionar `Run`, entrar a la pestana `Performance` y configurar:

| Caso | Carpeta | Perfil | VU | Duracion |
|---|---|---|---:|---|
| F7-001/F7-002 | `Baseline` | fixed | 1 | 1-2 min |
| F7-003/F7-004 | `Fixed Read Load` | fixed | 5-10 | 3-5 min |
| F7-005/F7-007 | `Fixed Write Load` | fixed | 3-5 | 3-5 min |
| F7-008/F7-010 | `GraphHopper Performance` | fixed | 2-4 | 3-5 min |
| F7-011 | `Ramp-Up Mixed API` | ramp-up | max 10 | 5 min |
| F7-012 | `Spike Read Load` | spike | max 20 | 3 min |
| F7-013 | `Peak Authenticated Mix` | peak | max 10 | 5 min |
| F7-014 | `Short Endurance` | fixed | 5 | 15-30 min |
| F7-015 | `Security Under Load` | fixed | 5 | 3 min |
| F7-016/F7-020 | `Recovery And Analysis Checks` | Run normal o fixed | 1 | cierre |

Si tu plan de Postman permite data files en performance, carga `f7-performance-data.csv`.

## Umbrales

| Tipo | p95 max | Error max | 5xx |
|---|---:|---:|---:|
| Health | 500 ms | 1% | 0 |
| Login y lecturas | 1500 ms | 1% | 0 |
| Escrituras y media | 3500 ms | 2% | 0 |
| GraphHopper/rutas | 8000 ms | 5% | 0 |
| Sin token | 100% HTTP 401 | N/A | 0 |

La coleccion incluye assertions por request y umbrales de response time por tipo de escenario. Los percentiles p90/p95/p99, RPS y error % se toman del reporte Performance de Postman.

## Evidencia

Para cada escenario guardar:

- Perfil de carga, VU y duracion.
- Requests totales y RPS.
- Avg, p90, p95 y p99.
- Error %.
- Assertions fallidas.
- Cantidad de HTTP 5xx.
- Captura o link del run.
- Observaciones de `Tests vs VU` cuando existan degradaciones.

Completar:

```text
docs/evidencias/F7/reporte_F7_postman_cloudflare.md
```

Si exportas resultados JSON compatibles, puedes generar un resumen tecnico con:

```bash
node scripts/f7-postman-summary.js ruta/al/export-runner.json
```

## Entorno

F7 se interpreta como performance local controlada. El host de referencia es Ubuntu 24.04.4 LTS en laptop Toshiba Satellite C55-B con Intel Core i3-4005U, 6 GiB RAM, Wi-Fi, Docker/GraphHopper local, Postman Desktop y Cloudflare Tunnel.
