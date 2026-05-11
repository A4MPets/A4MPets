# Reporte de Evidencias - Fase F3: Pruebas de Integracion Backend/API

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-08  
**Fase:** F3 - Integracion backend/API Laravel  
**Herramienta:** PHPUnit / `php artisan test` / cobertura HTML  
**Entorno:** Laravel con SQLite in-memory (`DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:`)

---

## Resumen Ejecutivo

La fase F3 fue implementada como suite separada para pruebas Feature/API del backend Laravel. Las pruebas de `tests/Feature` fueron reclasificadas como pruebas de integracion y movidas a `backend/tests/F3`; las pruebas unitarias quedaron en `backend/tests/F1`.

No se modifico codigo productivo. Los cambios se limitaron a:

- Reorganizacion de carpetas de pruebas backend.
- Ajuste de suites en `backend/phpunit.xml`.
- Nuevas variantes F3-extra sobre endpoints API.
- Cobertura separada en `backend/coverageF3`.
- Actualizacion de evidencia F1 para reflejar `coverageF1`.

## Estructura de Suites

| Suite | Carpeta | Proposito |
|---|---|---|
| F1 | `backend/tests/F1` | Pruebas unitarias backend. |
| F3 | `backend/tests/F3` | Pruebas de integracion backend/API. |

Comandos disponibles:

```bash
php artisan test --testsuite=F1
php artisan test --testsuite=F3
php artisan test --testsuite=F1 --coverage-html coverageF1
php artisan test --testsuite=F3 --coverage-html coverageF3
```

## Resultado de Validacion

Comando ejecutado:

```bash
composer dump-autoload
```

Resultado:

```text
Generated optimized autoload files containing 6812 classes
Exit code: 0
```

Comando ejecutado:

```bash
php artisan test --testsuite=F3
```

Resultado:

```text
Tests:    46 passed (235 assertions)
Duration: 9.50s
Exit code: 0
```

Regresion completa:

```bash
php artisan test
```

Resultado:

```text
Tests:    113 passed (562 assertions)
Duration: 17.67s
Exit code: 0
```

## Resultado Final de Cobertura F3

Comando ejecutado:

```bash
php artisan test --testsuite=F3 --coverage-html coverageF3
```

Resultado:

```text
Tests:    46 passed (235 assertions)
Duration: 15.14s
Exit code: 0
```

Reporte generado en:

```text
C:\projects\Web\A4MPets\backend\coverageF3\index.html
```

Cobertura real por carpeta principal:

| Carpeta | Cobertura de lineas | Lineas cubiertas | Estado |
|---|---:|---:|---|
| Http | 90.29% | 716 / 793 | Cumple >= 70% |
| Models | 70.33% | 192 / 273 | Cumple >= 70% |
| Providers | 100.00% | 2 / 2 | Mantiene 100% |
| Services | 47.86% | 582 / 1216 | No cumple; ver hallazgo F3-1 |
| Support | 100.00% | 16 / 16 | Cumple >= 70% |
| Total app | 65.48% | 1506 / 2300 | Referencia general |

Detalle relevante de Services:

| Area | Cobertura de lineas | Lineas cubiertas | Observacion |
|---|---:|---:|---|
| Services/Auth | 100.00% | 19 / 19 | Login, registro, perfil y logout cubiertos por API. |
| GraphHopperRoutingService.php | 89.10% | 188 / 211 | Endpoint `/api/routes/plan` con `Http::fake`, fallback y avoidance. |
| Services/Comments | 34.19% | 40 / 117 | Store/list via API cubierto; sync/formatters internos quedan para F1. |
| Services/Hazards | 37.12% | 121 / 326 | CRUD/comentarios via API cubiertos; sync interno sin endpoint. |
| Services/Pets | 32.74% | 37 / 113 | CRUD, listado propio y mark-found cubiertos; sync interno sin endpoint. |
| Services/Reports | 43.94% | 156 / 355 | Reportes principales cubiertos; sync interno sin endpoint. |
| Services/Routes | 28.00% | 21 / 75 | CRUD de rutas cubierto; sync interno sin endpoint. |

## Pruebas Agregadas o Ampliadas

| Archivo | Proposito |
|---|---|
| `tests/F3/Health/HealthEndpointTest.php` | Contrato de `/api/health`. |
| `tests/F3/Routes/TravelRouteAndPlanningControllerTest.php` | Planificacion real por endpoint con `Http::fake`, avoidance, instrucciones, fallback y 502. |
| `tests/F3/Pets/PetCrudTest.php` | `scope=mine`, show, mark-found, 403 y relaciones persistidas. |
| `tests/F3/Hazards/HazardControllerExtraTest.php` | Validacion adicional de relaciones owner/report tras flujos API. |

## Mapeo General F3

| Caso | Cobertura actual |
|---|---|
| F3-001 | `/api/health` y regresion base de disponibilidad API. |
| F3-002 a F3-004 | Registro, login por email/username, errores de credenciales y validaciones. |
| F3-005 | `/api/auth/me` con token valido y sin token. |
| F3-006 | `/api/auth/profile` con update de usuario resuelto por token. |
| F3-007 | `/api/auth/logout` y token revocado. |
| F3-008 a F3-010 | CRUD/listado de mascotas, ownership, guest behavior documentado. |
| F3-011 | `/api/pets/{pet}/mark-found` y borrado de reportes perdidos activos. |
| F3-012 a F3-014 | Peligros: crear, listar, detalle, update, delete, 403 y validaciones. |
| F3-015 | Comentarios de peligros por API. |
| F3-016 a F3-018 | Reportes de mascota perdida: CRUD, listado, detalle, comentarios, 401/403. |
| F3-019 a F3-021 | Reportes genericos y normalizacion de riesgo invalid/undefined. |
| F3-022 | Reportes de mascota encontrada con y sin reporte perdido vinculado. |
| F3-023 | Media upload base64, bucket invalido, data URI, show y 404. |
| F3-024 | Rutas guardadas: index/show/store/update/delete, validacion y ownership. |
| F3-025 | `/api/routes/plan` con GraphHopper fakeado, fallback, errores 422/502 y avoidance. |

## Hallazgos F3

| # | Hallazgo | Tratamiento |
|---|---|---|
| 1 | `Services` queda en 47.86% en F3 porque una parte grande de sus lineas corresponde a metodos internos de sincronizacion (`sync`) que no tienen endpoint en `routes/api.php`. | Se documenta como shortfall no factible dentro de F3 sin mezclar pruebas unitarias o crear endpoints productivos. Esos metodos quedan cubiertos/documentados en F1. |
| 2 | La integracion real con GraphHopper/Docker no se ejecuta en F3. | Se usa `Http::fake` sobre el cliente HTTP para validar contrato API y payload sin dependencia externa. La integracion real queda para fases posteriores. |
| 3 | El middleware `api.token` resuelve usuario cuando el token es valido, pero no rechaza por si solo token ausente/invalido. | Se valida el comportamiento final en controladores con respuestas 401/403 segun corresponda. |

## Conclusiones

F3 queda implementada y separada de F1:

- Suite F3: 46 pruebas aprobadas, 235 aserciones.
- Regresion backend completa: 113 pruebas aprobadas, 562 aserciones.
- Cobertura F3 separada en `backend/coverageF3`.
- `Http`, `Models`, `Providers` y `Support` cumplen el minimo esperado.
- `Services` no alcanza 70% por ausencia de endpoints para ramas internas de sincronizacion; queda documentado con detalle y sin alterar codigo productivo.
