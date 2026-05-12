# Reporte de Evidencias - Fase F7: Performance API con Postman y Cloudflare

**Proyecto:** A4MPets  
**Fecha de ejecucion:** [PENDIENTE]  
**Fase:** F7 - Performance API / No funcional  
**Herramienta:** Postman Desktop Performance Testing  
**Entorno:** Stack local A4MPets publicado mediante Cloudflare Tunnel  
**URL Cloudflare usada:** [PENDIENTE]  

---

## Resumen Ejecutivo

La fase F7 valida estabilidad, latencia, throughput y comportamiento bajo carga controlada del backend cuando el sistema local se expone mediante Cloudflare Tunnel. A diferencia de los runs por iteraciones simples, esta fase usa escenarios de Postman Performance con usuarios virtuales, perfiles de carga, duracion, percentiles y assertions bajo carga.

Archivos usados:

```text
postman/F7_A4MPets_Performance.postman_collection.json
postman/F7_A4MPets_Cloudflare.postman_environment.json
postman/f7-performance-data.csv
```

## Entorno de Ejecucion F7

| Categoria | Valor |
|---|---|
| Sistema operativo | Ubuntu 24.04.4 LTS Noble Numbat |
| Kernel | Linux 6.8.0-111-generic x86_64 |
| Equipo | Laptop Toshiba Satellite C55-B |
| CPU | Intel Core i3-4005U, 2 nucleos / 4 hilos, hasta 1.70 GHz |
| Memoria RAM | 6 GiB total, 5.7 GiB disponible aprox. |
| Almacenamiento | Disco Toshiba 465.76 GiB, ext4, 170.94 GiB usados aprox. |
| Red activa | Wi-Fi Qualcomm Atheros AR9485 |
| Docker/red local | Interfaces Docker activas durante la prueba |
| Pantalla | 1366x768, aunque F7 se ejecuta principalmente por API |
| Entorno de ejecucion | Sesion SSH/terminal, Postman Desktop, Cloudflare Tunnel, Docker/GraphHopper y backend local |
| Limitacion relevante | Equipo local de recursos moderados; resultados no equivalen a infraestructura productiva |

Las metricas deben interpretarse como performance local controlada. Un fallo relacionado con saturacion del host, Wi-Fi o cambio de URL Cloudflare debe documentarse como condicion de ambiente cuando no corresponda a defecto backend.

## Diferencia Frente a F3, F4 y F5

| Fase | Enfoque | Diferencia con F7 |
|---|---|---|
| F3 | Integracion backend/API automatizada en PHPUnit | F3 valida contratos funcionales; F7 mide comportamiento bajo carga externa. |
| F4 | Sistema integrado local de caja blanca | F4 comprueba comunicacion entre componentes; F7 mide latencia, throughput y estabilidad. |
| F5 | Caja negra E2E en navegador | F5 simula usuario desde UI; F7 usa API HTTP y Postman Performance. |

## Preparacion

1. Levantar backend Laravel, base de datos, frontend y GraphHopper.
2. Ejecutar Cloudflare Tunnel:

```bash
npm run dev:cloudflare
```

3. Copiar URL generada desde:

```text
.runtime/cloudflare-url.txt
```

4. Importar en Postman Desktop la coleccion y environment F7.
5. Configurar variables:

| Variable | Valor usado |
|---|---|
| `base_url` | [PENDIENTE] |
| `qa_login` | [PENDIENTE] |
| `qa_password` | [OCULTO] |
| `access_token` | Generado por `00 - Setup` |
| `hazard_id` | Generado por `00 - Setup` o asignado manualmente |

## Resultado de Setup

| Paso | Resultado | Observaciones |
|---|---|---|
| Health inicial | [PENDIENTE] | Debe retornar HTTP 200 y `status=ok`. |
| Login QA | [PENDIENTE] | Debe retornar HTTP 200 y `access_token`. |
| Crear peligro base | [PENDIENTE] | Debe retornar HTTP 201 y guardar `hazard_id`. |

## Umbrales de Aceptacion

| Tipo | p95 max | Error max | HTTP 5xx |
|---|---:|---:|---:|
| Health | 500 ms | 1% | 0 |
| Login y lecturas | 1500 ms | 1% | 0 |
| Escrituras y media | 3500 ms | 2% | 0 |
| GraphHopper/rutas | 15000 ms | 5% | 0 |
| Endpoints protegidos sin token | 100% HTTP 401 | N/A | 0 |

## Resultados por Escenario

| Caso | Escenario Postman | Perfil | VU | Duracion | Requests | RPS | Avg | P90 | P95 | P99 | Error % | 5xx | Assertions fallidas | Estado |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| F7-001 | Baseline health | fixed | 1 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-002 | Baseline login | fixed | 1 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-003 | Fixed read public | fixed | 5-10 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-004 | Fixed read auth | fixed | 5-10 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-005 | Create pets | fixed | 3-5 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-006 | Create hazards | fixed | 3-5 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-007 | Media upload | fixed | 3-5 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-008 | Route simple | fixed | 2-4 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-009 | Route multipunto | fixed | 2-4 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-010 | Route filtros riesgo | fixed | 2-4 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-011 | Ramp-up mixed API | ramp-up | max 10 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-012 | Spike read load | spike | max 20 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-013 | Peak authenticated mix | peak | max 10 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-014 | Short endurance | fixed | 5 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-015 | Security under load | fixed | 5 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-016 | Recovery post-carga | fixed/manual | 1 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-017 | Cloudflare stability | manual | 1 | [ ] | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-018 | Assertions vs VU | analisis | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-019 | Consolidacion 5xx/error budget | analisis | N/A | N/A | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |
| F7-020 | Reporte final | analisis | N/A | N/A | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [ ] ms | [ ]% | [ ] | [ ] | [PENDIENTE] |

## Analisis Tests vs VU

| Escenario | Assertion degradada | VU donde inicia degradacion | Failure rate | Observacion |
|---|---|---:|---:|---|
| [PENDIENTE] | [PENDIENTE] | [ ] | [ ]% | [PENDIENTE] |

## Comparativas Requeridas

### F7-009 - Ruta Simple vs Multipunto

| Variante | Perfil | VU | P95 | P99 | Error % | Observacion |
|---|---|---:|---:|---:|---:|---|
| 2 puntos | fixed | [ ] | [ ] ms | [ ] ms | [ ]% | [ ] |
| 5 puntos | fixed | [ ] | [ ] ms | [ ] ms | [ ]% | [ ] |

### F7-010 - Rutas con Filtros de Riesgo

| Variante | Perfil | VU | P95 | P99 | Error % | Observacion |
|---|---|---:|---:|---:|---:|---|
| Sin filtros | fixed | [ ] | [ ] ms | [ ] ms | [ ]% | [ ] |
| Filtros `high`, `medium` | fixed | [ ] | [ ] ms | [ ] ms | [ ]% | [ ] |

## Evidencias Adjuntas

| Evidencia | Ruta / descripcion |
|---|---|
| Coleccion Postman | `postman/F7_A4MPets_Performance.postman_collection.json` |
| Environment Postman | `postman/F7_A4MPets_Cloudflare.postman_environment.json` |
| Datos Performance | `postman/f7-performance-data.csv` |
| Captura/link performance run baseline | [PENDIENTE] |
| Captura/link performance run fixed read | [PENDIENTE] |
| Captura/link performance run fixed write | [PENDIENTE] |
| Captura/link performance run GraphHopper | [PENDIENTE] |
| Captura/link performance run ramp-up/spike/peak | [PENDIENTE] |
| Export o resumen consolidado | [PENDIENTE] |

## Hallazgos F7

| # | Hallazgo | Impacto | Evidencia | Tratamiento |
|---|---|---|---|---|
| 1 | [PENDIENTE] | [PENDIENTE] | [PENDIENTE] | [PENDIENTE] |

## Criterios de Aceptacion

| Criterio | Resultado |
|---|---|
| Escenarios F7-001 a F7-020 ejecutados o justificados | [PENDIENTE] |
| No se presentan respuestas HTTP 5xx sin documentar | [PENDIENTE] |
| Error % queda dentro del umbral por tipo de endpoint o se justifica | [PENDIENTE] |
| P95 queda dentro del umbral por tipo de endpoint o se justifica | [PENDIENTE] |
| GraphHopper responde para escenarios de rutas | [PENDIENTE] |
| Cloudflare Tunnel permanece operativo o se documenta cambio de URL | [PENDIENTE] |
| Tests vs VU revisado para detectar degradacion | [PENDIENTE] |

## Conclusion

[PENDIENTE: describir si el sistema se mantuvo estable bajo los perfiles de performance ejecutados, si hubo degradacion por VU, si GraphHopper fue el componente mas costoso, si Cloudflare o el equipo local limitaron la prueba y si F7 queda aprobada, aprobada con observaciones o no aprobada.]
