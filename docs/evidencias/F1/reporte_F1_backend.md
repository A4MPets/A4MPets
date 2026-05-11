# Reporte de Evidencias - Fase F1: Pruebas Unitarias Backend Laravel

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-08  
**Fase:** F1 - Caja blanca backend unitaria  
**Herramienta:** PHPUnit / `php artisan test`  
**Entorno:** Laravel con SQLite in-memory (`DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:`)

---

## Resumen Ejecutivo

La fase F1 queda separada formalmente como suite de pruebas unitarias backend. Las pruebas que antes estaban en `tests/Feature` fueron reclasificadas como F3, por lo que esta evidencia ya no mezcla cobertura de controladores/API con pruebas unitarias.

No se modifico codigo productivo. Los cambios de esta reorganizacion fueron:

- Pruebas unitarias movidas a `backend/tests/F1`.
- Suite PHPUnit `F1` apuntando a `tests/F1`.
- Cobertura unitaria regenerada en `backend/coverageF1`.
- Pruebas Feature/API movidas fuera de F1 hacia `backend/tests/F3`.

## Resultado Final de PHPUnit F1

Comando ejecutado:

```bash
php artisan test --testsuite=F1
```

Resultado:

```text
Tests:    67 passed (327 assertions)
Duration: 9.45s
Exit code: 0
```

## Resultado Final de Cobertura F1

Comando ejecutado:

```bash
php artisan test --testsuite=F1 --coverage-html coverageF1
```

Resultado:

```text
Tests:    67 passed (327 assertions)
Duration: 14.44s
Exit code: 0
```

Reporte generado en:

```text
C:\projects\Web\A4MPets\backend\coverageF1\index.html
```

Cobertura real por carpeta principal, considerando solo F1:

| Carpeta | Cobertura de lineas | Lineas cubiertas | Observacion |
|---|---:|---:|---|
| Http | 20.55% | 163 / 793 | F1 cubre FormRequests; controladores pasan a F3. |
| Models | 86.08% | 235 / 273 | Cumple como cobertura unitaria de modelos. |
| Providers | 100.00% | 2 / 2 | Mantiene 100%. |
| Services | 67.60% | 822 / 1216 | Muy cercano al 70%; ramas legacy/sync quedan documentadas. |
| Support | 100.00% | 16 / 16 | Cumple. |
| Total app | 53.83% | 1238 / 2300 | Referencia general de F1 aislado. |

## Pruebas F1

| Carpeta | Proposito |
|---|---|
| `tests/F1/Http/Requests` | Reglas y autorizacion de FormRequests. |
| `tests/F1/Models` | Relaciones, accessors, hashes, scopes y `points_json`. |
| `tests/F1/Services` | Servicios de auth, mascotas, reportes, peligros, rutas, GraphHopper y comentarios. |
| `tests/F1/Support` | Normalizacion de instrucciones de navegacion. |

## Hallazgos F1

| # | Hallazgo | Tratamiento |
|---|---|---|
| 1 | Algunos metodos legacy de sincronizacion local-first referencian columnas removidas por migraciones recientes. | Documentado en pruebas unitarias como comportamiento/error actual. No se modifica codigo productivo en F1. |
| 2 | `api.token` resuelve usuario si el token es valido, pero no rechaza por si solo tokens ausentes o invalidos. | La autorizacion final se valida en controladores y queda cubierta en F3. |
| 3 | La cobertura `Http` baja en F1 es esperada despues de mover controladores/API a F3. | La cobertura de API queda reportada separadamente en `coverageF3`. |

## Conclusiones

F1 queda cerrada como suite unitaria backend separada y reproducible:

- Suite: `php artisan test --testsuite=F1`
- Cobertura: `php artisan test --testsuite=F1 --coverage-html coverageF1`
- Resultado: 67 pruebas aprobadas y 327 aserciones.

La cobertura de controladores/API ya no se informa en F1; corresponde a la fase F3.
