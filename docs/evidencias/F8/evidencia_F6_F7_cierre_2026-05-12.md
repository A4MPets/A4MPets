# Evidencia Consolidada F8 - Cierre F6-F7

**Proyecto:** A4MPets  
**Fecha:** 2026-05-12  
**Responsable:** Equipo QA  
**Tipo de evidencia:** Cierre por trazabilidad F6-F7  

## Fuentes Historicas

| Fase | Fuente |
|---|---|
| F6 | `docs/evidencias/F6/reporte_F6_pruebas_manuales_funcionales.md` |
| F7 | `docs/evidencias/F7/reporte_F7_postman_cloudflare.md` |

## Cierre Por Fase

| Fase | Resultado | Variacion frente a evidencia historica | Defectos criticos abiertos | Defectos altos sin decision | Nota de cierre |
|---|---|---|---:|---:|---|
| F6 - Pruebas manuales funcionales | Aprobado | No | 0 | 0 | Los resultados funcionales no varian frente a la evidencia previa. `DEF-F6-001` queda corregido y retestado por QA segun validacion del usuario. |
| F7 - Performance API Postman + Cloudflare | Aprobado con observacion cerrada | No se recalculan metricas historicas | 0 | 0 | Las metricas historicas de performance no se modifican. El unico cambio de cierre es `F7-015`, solucionado y validado por QA. |

## Validacion F7-015

| Elemento | Resultado |
|---|---|
| Estado | Solucionado y validado por QA |
| Expectativa validada | Las operaciones protegidas sin token rechazan la solicitud con HTTP 401. |
| `POST /api/pets` sin token | Validado como rechazado |
| `POST /api/routes/plan` sin token | Validado como rechazado |
| `GET /api/routes` sin token | Validado como rechazado |
| Recalculo de metricas Postman | No aplica en F8; se conservan las metricas historicas de F7. |

## Conclusion

F6 y F7 quedan cerradas para F8 por trazabilidad. F7 conserva sus metricas historicas y registra `F7-015` como solucionado.
