# Reporte de Evidencias - Fase F8: Regresion y Cierre QA

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-12, en progreso  
**Fase:** F8 - Regresion y cierre QA  
**Version bajo prueba:** `feature/fixes` - `4677558c24f87f014d6bae82ee0d6e28995024e0` - 2026-05-11 23:09:27 -0500 - graphhopper latest version  
**Responsable:** Equipo QA  
**Decision:** Pendiente de cierre F8  

---

## Resumen Ejecutivo

F8 consolida el estado de calidad de A4MPets desde F0 hasta F8, reejecuta regresion automatizada donde el ambiente lo permite y deja listos los retests pendientes. En esta corrida se corrigio el hallazgo F7-015 a nivel backend, se reejecutaron F0-F5 y se actualizo la trazabilidad de F6 y F7.

Nota de control documental: los reportes historicos F0-F7 se mantienen como evidencia inmutable. La informacion nueva de regresion, retest, bloqueos y cierre se registra en este reporte F8.

Estado general al 2026-05-12:

| Area | Estado |
|---|---|
| Fix F7-015 | Aplicado en backend y validado por F3 automatizado. |
| F0 | Retest parcial: backend, frontend y Cloudflare OK; GraphHopper bloqueado por Docker. |
| F1 | PASS: 67 pruebas, 327 aserciones. |
| F2 | PASS: `flutter analyze` sin issues; 102 tests Flutter aprobados. |
| F3 | PASS: 48 pruebas F3, 248 aserciones; backend completo 115 pruebas, 575 aserciones. |
| F4 | Retest bloqueado por Docker/GraphHopper; evidencia historica previa aprobada. |
| F5 | Retest bloqueado por Docker/GraphHopper; evidencia historica previa aprobada. |
| F6 | DEF-F6-001 documentado como corregido / retestado por QA. |
| F7 | Performance historica aprobada con observaciones; F7-015 corregido y pendiente de reejecucion Postman. |
| F8 | Casos F8-001 a F8-020 pendientes de ejecucion final documentada. |

## Ambiente

| Elemento | Valor |
|---|---|
| Backend | Laravel local |
| Frontend | Flutter web |
| GraphHopper | Docker local, bloqueado en retest 2026-05-12 porque Docker daemon no esta disponible |
| Navegador | Chrome / Chromium para F4-F5 |
| Base de datos | Local/test |
| Cloudflare | Tunnel temporal validado en F0 dry-run: `https://cloudy-girls-okay-toolbox.trycloudflare.com/` |

## Registro de Version

| Campo | Valor |
|---|---|
| Rama | `feature/fixes` |
| Commit | `4677558c24f87f014d6bae82ee0d6e28995024e0` |
| Fecha commit | 2026-05-11 23:09:27 -0500 |
| Mensaje commit | graphhopper latest version |
| Estado working tree | Con cambios de fix F7-015, reportes y evidencias de retest. Ver `git status --short`. |

## Consolidado F0-F8

| Fase | Enfoque | Resultado actual | Evidencia principal |
|---|---|---|---|
| F0 | Preparacion y smoke de ambiente | Parcial: backend/frontend/Cloudflare PASS; GraphHopper bloqueado por Docker | `docs/evidencias/F0/reporte_F0_ambiente.md` |
| F1 | Unitarias backend Laravel | PASS reejecutado | `docs/evidencias/F1/reporte_F1_backend.md` |
| F2 | Unitarias/widget frontend Flutter | PASS reejecutado | `docs/evidencias/F2/reporte_F2_frontend.md` |
| F3 | Integracion backend/API | PASS reejecutado; incluye fix F7-015 | `docs/evidencias/F3/reporte_F3_integracion_backend.md` |
| F4 | Sistema integrado local | Historico PASS; retest 2026-05-12 bloqueado por Docker | `docs/evidencias/F4/reporte_F4_sistema_integrado_local.md` |
| F5 | E2E navegador | Historico PASS; retest 2026-05-12 bloqueado por Docker | `docs/evidencias/F5/reporte_F5_e2e_navegador.md` |
| F6 | Manual funcional | Aprobada con observacion cerrada | `docs/evidencias/F6/reporte_F6_pruebas_manuales_funcionales.md` |
| F7 | Performance Postman + Cloudflare | Aprobada con observaciones; F7-015 corregido, pendiente Postman retest | `docs/evidencias/F7/reporte_F7_postman_cloudflare.md` |
| F8 | Regresion y cierre | En progreso | `docs/evidencias/F8/reporte_F8_regresion_cierre.md` |

## Automatizadas Reejecutadas

| Suite | Comando | Resultado | Evidencia | Observaciones |
|---|---|---|---|---|
| F0 backend | `npm run backend -- --dry-run` | PASS | Registrado en este reporte F8 | Backend listo en puerto 8000. |
| F0 frontend | `npm run frontend -- --dry-run` | PASS | Registrado en este reporte F8 | Runtime local generado. |
| F0 GraphHopper | `npm run graphhopper` | BLOCKED | Registrado en este reporte F8 | Docker daemon no disponible. |
| F0 Cloudflare | `npm run backend:cloudflare -- --dry-run` | PASS | Registrado en este reporte F8 | Tunnel temporal creado y validado. |
| Backend F1 | `php artisan test --testsuite=F1` | PASS: 67 / 327 | Registrado en este reporte F8 | Sin regresion. |
| Backend F1 coverage | `php artisan test --testsuite=F1 --coverage-html coverageF1` | PASS: 67 / 327 | Registrado en este reporte F8 | Coverage HTML regenerado. |
| Frontend analyze | `flutter analyze` | PASS | Registrado en este reporte F8 | Sin issues. |
| Frontend test | `flutter test` | PASS: 102 tests | Registrado en este reporte F8 | Sin fallos. |
| Frontend coverage | `flutter test --coverage` | PASS: 102 tests | Registrado en este reporte F8 | LCOV regenerado. |
| Backend F3 | `php artisan test --testsuite=F3` | PASS: 48 / 248 | Registrado en este reporte F8 | Incluye endpoints sin token. |
| Backend completa | `php artisan test` | PASS: 115 / 575 | Registrado en este reporte F8 | Sin regresion backend. |
| Backend F3 coverage | `php artisan test --testsuite=F3 --coverage-html coverageF3` | PASS: 48 / 248 | Registrado en este reporte F8 | Coverage HTML regenerado. |
| F4 syntax | `node --check scripts\f4-system-check.js` | PASS | Registrado en este reporte F8 | Script valido. |
| F4 integrado | `node scripts\f4-system-check.js` | BLOCKED | Registrado en este reporte F8 | Bloqueado por Docker/GraphHopper. |
| F5 stack syntax | `node --check scripts\f5-stack.js` | PASS | Registrado en este reporte F8 | Script valido. |
| F5 config syntax | `node --check playwright.f5.config.js` | PASS | Registrado en este reporte F8 | Config valido. |
| E2E F5 | `npm run test:e2e:f5` | BLOCKED | Registrado en este reporte F8 | WebServer no inicia porque GraphHopper depende de Docker. |

## Retest De Hallazgos F0-F7

| ID / Origen | Descripcion | Estado F8 | Evidencia | Decision |
|---|---|---|---|---|
| DEF-F6-001 | Rutas visibles en cuenta nueva | Corregido / retestado por QA | `docs/evidencias/F6/reporte_F6_pruebas_manuales_funcionales.md` | Cerrado para F8, conservar evidencia historica. |
| F7-015 pets sin token | `POST /api/pets` aceptaba o no rechazaba como esperaba la assertion | Solucion aplicada | `PetCrudTest::test_create_pet_without_token_returns_401` | Pendiente reejecutar Postman Performance F7-015. |
| F7-015 route plan sin token | `POST /api/routes/plan` sin Authorization no cumplio assertion | Solucion aplicada | `TravelRouteAndPlanningControllerTest::test_route_planning_without_token_returns_401` | Pendiente reejecutar Postman Performance F7-015. |
| F7-015 routes sin token | `GET /api/routes` sin token | Validado | `TravelRouteAndPlanningControllerTest::test_routes_index_without_token_returns_401` | Cumple 401. |
| F7 ramp-up/spike/peak | Assertions menores bajo carga | Pendiente de retest no funcional | Reporte F7 historico | Repetir despues de F7-015 si Docker/Cloudflare estan disponibles. |
| F0/F4/F5 GraphHopper | Docker daemon no disponible en retest | Bloqueado por ambiente | Logs F0/F4/F5 2026-05-12 | Iniciar Docker Desktop y reejecutar F0 GraphHopper, F4 y F5. |

## Matriz F8

| Caso | Resultado | Evidencia | Observaciones |
|---|---|---|---|
| F8-001 | PENDIENTE | PENDIENTE | Health final del backend. |
| F8-002 | PENDIENTE | PENDIENTE | Registro de usuario de regresion. |
| F8-003 | PENDIENTE | PENDIENTE | Login por correo y username. |
| F8-004 | PENDIENTE | PENDIENTE | CRUD de mascotas. |
| F8-005 | PENDIENTE | PENDIENTE | Creacion de peligro y mapa. |
| F8-006 | PENDIENTE | PENDIENTE | Reporte de mascota perdida. |
| F8-007 | BLOQUEADO | Logs F0/F4/F5 | GraphHopper requiere Docker activo. |
| F8-008 | PARCIAL | Logs F3 | Endpoints protegidos sin token validados por F3; falta Postman F7-015. |
| F8-009 | PENDIENTE | PENDIENTE | Ownership de mascotas. |
| F8-010 | PENDIENTE | PENDIENTE | Upload invalido. |
| F8-011 | PARCIAL | Este reporte F8 | `flutter analyze` PASS; falta cierre formal de caso F8. |
| F8-012 | PARCIAL | Este reporte F8 | `php artisan test` PASS; falta cierre formal de caso F8. |
| F8-013 | PENDIENTE | PENDIENTE | Viewport 1366x768. |
| F8-014 | PENDIENTE | PENDIENTE | Viewport 390x844. |
| F8-015 | PARCIAL | Reportes F6/F7/F8 | Incidencias clasificadas, falta cierre final. |
| F8-016 | PARCIAL | Reportes F6/F7/F8 | Sin criticos/altos abiertos en backend; bloqueo ambiental pendiente. |
| F8-017 | PARCIAL | Logs F0-F5 | Casos automatizados reejecutados donde ambiente lo permitio. |
| F8-018 | PARCIAL | Este reporte | Evidencias F0-F7 consolidadas. |
| F8-019 | PENDIENTE | PENDIENTE | Conteo final tras ejecutar F8 manual/regresion completa. |
| F8-020 | PENDIENTE | PENDIENTE | Decision Go/No-Go final. |

## Conteo Actual

| Resultado | Total |
|---|---:|
| Aprobados formalmente en F8 | 0 |
| Parciales | 6 |
| Bloqueados | 1 |
| Pendientes | 13 |
| No aplica | 0 |

## Criterios De Salida

| Criterio | Resultado |
|---|---|
| Casos P0/P1 reejecutados | Parcial: backend/frontend unitario e integracion PASS; integrado/E2E bloqueado por Docker. |
| Sin defectos criticos abiertos | Cumple segun evidencia actual. |
| Sin defectos altos sin decision | Parcial: F7-015 solucionado en backend, pendiente retest Postman. |
| Evidencia suficiente por fase | Parcial: F0-F7 consolidados; falta cierre F8 y retest Docker. |
| Regresion automatizada ejecutada | Parcial: F1-F3/F2 PASS; F4-F5 bloqueados por Docker. |
| Incidencias clasificadas | Cumple parcialmente; falta decision final Go/No-Go. |

## Acciones Pendientes Para Cierre

1. Activar Docker Desktop o restaurar el daemon Docker Linux.
2. Reejecutar `npm run graphhopper`, `node scripts\f4-system-check.js` y `npm run test:e2e:f5`.
3. Reejecutar F7-015 en Postman Performance y completar la tabla de retest en F7.
4. Ejecutar los casos F8-001 a F8-020 y actualizar `Resultado real` en `docs/casos_de_prueba_a4mpets_v2.md`.
5. Emitir decision Go, Go con observaciones o No-Go con conteo final.

## Conclusion

F8 queda en progreso. El riesgo funcional principal F7-015 ya fue corregido y validado por pruebas automatizadas backend. La decision final aun no debe emitirse porque F4/F5 y GraphHopper estan bloqueados por ambiente Docker y porque F7-015 requiere reejecucion Postman Performance para cerrar sus metricas.
