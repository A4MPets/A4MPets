# Evidencia Consolidada F8 - Regresion F0-F5

**Proyecto:** A4MPets  
**Fecha:** 2026-05-12  
**Responsable:** Equipo QA  
**Tipo de evidencia:** Consolidado de regresion F0-F5  

## Objetivo

Consolidar la evidencia de regresion de F0 a F5 sin duplicar ni modificar los reportes historicos de cada fase.

## Fuentes Historicas

| Fase | Fuente |
|---|---|
| F0 | `docs/evidencias/F0/reporte_F0_ambiente.md` |
| F1 | `docs/evidencias/F1/reporte_F1_backend.md` |
| F2 | `docs/evidencias/F2/reporte_F2_frontend.md` |
| F3 | `docs/evidencias/F3/reporte_F3_integracion_backend.md` |
| F4 | `docs/evidencias/F4/reporte_F4_sistema_integrado_local.md` |
| F5 | `docs/evidencias/F5/reporte_F5_e2e_navegador.md` |

## Resumen Por Fase

| Fase | Resultado | Comandos / Validaciones | Metricas | Observaciones |
|---|---|---|---|---|
| F0 - Ambiente | Aprobado con observaciones | `npm run backend -- --dry-run`, `npm run frontend -- --dry-run`, `npm run graphhopper`, `npm run backend:cloudflare -- --dry-run` | 0 fallos HTTP, 0 bloqueos criticos | Ambiente base validado. GraphHopper queda confirmado por la reejecucion integrada F4/F5 con Docker activo. |
| F1 - Backend unitario | Aprobado | `php artisan test --testsuite=F1`, coverage F1 | 67 pruebas, 327 aserciones, 0 fallos | Suite F1 aprobada sin regresiones. |
| F2 - Frontend unitario/widget | Aprobado | `flutter analyze`, `flutter test`, `flutter test --coverage` | 0 issues de analyze, 102 pruebas, 0 fallos | Analisis estatico y pruebas Flutter aprobadas. |
| F3 - Integracion backend/API | Aprobado | `php artisan test --testsuite=F3`, `php artisan test`, coverage F3 | F3: 48 pruebas y 248 aserciones; backend completo: 115 pruebas y 575 aserciones | Incluye validacion automatizada de endpoints protegidos sin token relacionados con F7-015. |
| F4 - Sistema integrado local | Aprobado | `node --check scripts/f4-system-check.js`, `node scripts/f4-system-check.js` | 22 checks PASS, exit code 0 | Backend, frontend, GraphHopper, persistencia, media upload y smoke Chromium aprobados. |
| F5 - E2E navegador | Aprobado | `node --check scripts/f5-stack.js`, `node --check playwright.f5.config.js`, `npm run test:e2e:f5` | 23 pruebas Playwright, 0 fallos, 0 bloqueos | Suite Playwright F5 aprobada despues de ajustar readiness/timeouts y validar autenticacion en planificacion de rutas. |

## Conclusion

La regresion automatizada e integrada de F0 a F5 queda aprobada para F8. No se identifican defectos criticos ni altos abiertos en estas fases al cierre.
