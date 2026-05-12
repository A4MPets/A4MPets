# Reporte de Evidencias - Fase F7: Performance API con Postman y Cloudflare

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-11 a 2026-05-12
**Fase:** F7 - Performance API / No funcional  
**Herramienta:** Postman Desktop Performance Testing  
**Entorno:** Stack local A4MPets publicado mediante Cloudflare Tunnel  
**URL Cloudflare usada:** No registrada en el entorno actual; los escenarios fueron ejecutados mediante Cloudflare segun la evidencia reportada.

---

## Resumen Ejecutivo

La fase F7 valido estabilidad, latencia, throughput y comportamiento bajo carga controlada del backend cuando el sistema local se expuso mediante Cloudflare Tunnel. Se ejecutaron escenarios baseline, carga fija, ramp-up, spike, peak, endurance corta, seguridad sin token, rutas con GraphHopper y recuperacion posterior a carga.

La ejecucion queda **aprobada con observaciones**. No se reportaron errores HTTP ni respuestas 5xx en las metricas entregadas, y los percentiles principales se mantuvieron dentro de los umbrales definidos. Las observaciones relevantes son: fallos de assertions en escenarios ramp-up/spike/peak, un maximo aislado alto en `GET /api/pets autenticado` y un hallazgo funcional de seguridad en F7-015 porque `POST /api/pets sin token` y `POST /api/routes/plan sin token` no cumplieron la assertion esperada de rechazo sin token.

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

Las metricas deben interpretarse como performance local controlada. Los resultados no equivalen a un benchmark productivo porque dependen del host local, Wi-Fi, Docker/GraphHopper, Postman Desktop y Cloudflare Tunnel.

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
| `base_url` | URL Cloudflare temporal usada durante la ejecucion; no registrada en el entorno actual |
| `qa_login` | Usuario QA configurado en Postman para F7 |
| `qa_password` | Oculto |
| `access_token` | Generado por `00 - Setup` |
| `hazard_id` | Generado por `00 - Setup` o asignado manualmente |

## Resultado de Setup

| Paso | Resultado | Observaciones |
|---|---|---|
| Health inicial | Aprobado | Los escenarios baseline y de cierre confirmaron HTTP 200 y `status=ok`. |
| Login QA | Aprobado | F7-002 obtuvo 0.00% error y 0.00% failure con token valido. |
| Crear peligro base | Aprobado | Se uso `hazard_id` para comentarios y escenarios autenticados. |

## Umbrales de Aceptacion

| Tipo | p95 max | Error max | HTTP 5xx |
|---|---:|---:|---:|
| Health | 500 ms | 1% | 0 |
| Login y lecturas | 1500 ms | 1% | 0 |
| Escrituras y media | 3500 ms | 2% | 0 |
| GraphHopper/rutas | 15000 ms | 5% | 0 |
| Endpoints protegidos sin token | 100% HTTP 401 | N/A | 0 |

`Error %` se interpreta como errores HTTP reportados por Postman. `Failure %` se interpreta como assertions fallidas. En la evidencia entregada no se reportaron respuestas 5xx.

## Resultados por Request

| Test case | Request | Perfil | VU | Duracion | Total requests | Requests/s | Error % | Failure % | Avg (ms) | Min (ms) | Max (ms) | P90 | P95 | P99 | Estado | Observacion |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---|
| F7-001 | GET F7-001 Baseline GET /api/health | fixed | 3 | 3m | 352 | 5.81 | 0.00 | 0.00 | 100 | 66 | 799 | 125 | 146 | 326 | Aprobado | P95 dentro del umbral health. |
| F7-002 | POST F7-002 Baseline POST /api/auth/login | fixed | 3 | 3m | 74 | 1.19 | 0.00 | 0.00 | 739 | 673 | 1201 | 778 | 834 | 1201 | Aprobado | Login estable, P95 dentro del umbral. |
| F7-003 | GET F7-003 GET /api/hazards | fixed | 3 | 3m | 1703 | 9.35 | 0.00 | 0.00 | 101 | 60 | 743 | 134 | 154 | 224 | Aprobado | Lectura publica estable. |
| F7-003 | GET F7-003 GET /api/lost-pet-reports | fixed | 3 | 3m | 1702 | 9.34 | 0.00 | 0.00 | 91 | 53 | 436 | 124 | 143 | 199 | Aprobado | Lectura publica estable. |
| F7-003 | GET F7-003 GET /api/found-pet-reports | fixed | 3 | 3m | 1701 | 9.34 | 0.00 | 0.00 | 91 | 53 | 306 | 121 | 140 | 194 | Aprobado | Lectura publica estable. |
| F7-003 | GET F7-003 GET /api/generic-reports | fixed | 3 | 3m | 1699 | 9.33 | 0.00 | 0.00 | 92 | 54 | 585 | 124 | 143 | 248 | Aprobado | Lectura publica estable. |
| F7-004 | GET F7-004 GET /api/routes autenticado | fixed | 3 | 3m | 2706 | 14.85 | 0.00 | 0.00 | 126 | 52 | 1215 | 210 | 255 | 391 | Aprobado | Lectura autenticada estable. |
| F7-004 | GET F7-004 GET /api/pets autenticado | fixed | 3 | 3m | 2703 | 14.83 | 0.00 | 0.04 | 128 | 54 | 8781 | 207 | 252 | 381 | Aprobado con observaciones | Assertion aislada y maximo alto no reflejado en P95/P99. |
| F7-005 | POST F7-005 POST /api/pets | fixed | 3 | 3m | 930 | 5.13 | 0.00 | 0.00 | 514 | 180 | 1502 | 780 | 890 | 1190 | Aprobado | Escritura dentro del umbral. |
| F7-006 | POST F7-006 POST /api/hazards | fixed | 3 | 3m | 760 | 4.20 | 0.00 | 0.00 | 640 | 196 | 2066 | 981 | 1221 | 1601 | Aprobado | Escritura dentro del umbral. |
| F7-007 | POST F7-007 POST /api/media/upload | fixed | 3 | 3m | 1508 | 8.32 | 0.00 | 0.00 | 305 | 159 | 3438 | 511 | 700 | 1383 | Aprobado | Upload dentro del umbral. |
| F7-008 | POST F7-008 POST /api/routes/plan simple | fixed | 3 | 3m | 1693 | 9.34 | 0.00 | 0.00 | 264 | 168 | 3499 | 338 | 403 | 1625 | Aprobado | GraphHopper responde dentro del umbral. |
| F7-009 | POST F7-009 POST /api/routes/plan multipunto | fixed | 3 | 3m | 1621 | 8.90 | 0.00 | 0.00 | 276 | 172 | 1227 | 393 | 476 | 710 | Aprobado | Multipunto estable y cercano a ruta simple. |
| F7-010 | POST F7-010 POST /api/routes/plan filtros riesgo | fixed | 3 | 3m | 1580 | 8.74 | 0.00 | 0.00 | 284 | 178 | 1081 | 398 | 506 | 856 | Aprobado | Filtros de riesgo sin timeout sistematico. |
| F7-011 | GET F7-011 GET /api/health | ramp-up | 3 a 10 | 3m | 1927 | 10.58 | 0.00 | 2.65 | 186 | 48 | 2376 | 298 | 398 | 736 | Aprobado con observaciones | Failure por assertions bajo ramp-up; sin error HTTP. |
| F7-011 | GET F7-011 GET /api/hazards | ramp-up | 3 a 10 | 3m | 1925 | 10.57 | 0.00 | 0.94 | 229 | 60 | 5577 | 339 | 471 | 1318 | Aprobado con observaciones | Failure menor y maximo alto aislado. |
| F7-011 | GET F7-011 GET /api/routes autenticado | ramp-up | 3 a 10 | 3m | 1922 | 10.55 | 0.00 | 0.31 | 199 | 52 | 2587 | 303 | 395 | 711 | Aprobado con observaciones | Failure menor bajo ramp-up. |
| F7-012 | GET F7-012 GET /api/hazards spike | spike | 3 a 20 | 3m | 1893 | 10.44 | 0.00 | 3.54 | 205 | 24 | 5031 | 417 | 569 | 844 | Aprobado con observaciones | Failure durante spike, sin error HTTP. |
| F7-012 | GET F7-012 GET /api/health post-spike incluido | spike | 3 a 20 | 3m | 1892 | 10.43 | 0.00 | 3.59 | 169 | 24 | 5032 | 323 | 481 | 755 | Aprobado con observaciones | Health posterior cumple P95, pero con assertions fallidas. |
| F7-013 | GET F7-013 GET /api/pets autenticado | peak | max 20 | 3m | 621 | 3.43 | 0.00 | 0.81 | 454 | 68 | 1739 | 904 | 1023 | 1378 | Aprobado con observaciones | Failure menor en pico autenticado. |
| F7-013 | GET F7-013 GET /api/routes autenticado | peak | max 20 | 3m | 620 | 3.42 | 0.00 | 0.81 | 484 | 53 | 1899 | 987 | 1087 | 1423 | Aprobado con observaciones | Failure menor en pico autenticado. |
| F7-013 | POST F7-013 POST /api/hazards/{id}/comments | peak | max 20 | 3m | 620 | 3.42 | 0.00 | 0.00 | 565 | 151 | 1635 | 991 | 1115 | 1381 | Aprobado | Comentarios dentro del umbral de escritura. |
| F7-014 | GET F7-014 GET /api/health endurance | fixed | 5 | 15m | 17390 | 19.30 | 0.00 | 0.00 | 81 | 44 | 799 | 123 | 163 | 266 | Aprobado | Endurance sin degradacion sostenida. |
| F7-014 | GET F7-014 GET /api/hazards endurance | fixed | 5 | 15m | 17387 | 19.30 | 0.00 | 0.00 | 101 | 56 | 820 | 151 | 185 | 304 | Aprobado | Endurance sin degradacion sostenida. |
| F7-015 | POST F7-015 POST /api/pets sin token | fixed | 3 | 3m | 868 | 4.82 | 0.00 | 100.00 | 372 | 132 | 937 | 547 | 592 | 717 | Fallido | Hallazgo de seguridad: assertion de rechazo sin token falla. |
| F7-015 | GET F7-015 GET /api/routes sin token | fixed | 3 | 3m | 868 | 4.82 | 0.00 | 0.00 | 228 | 44 | 682 | 392 | 445 | 571 | Aprobado | Rechazo sin token cumple assertion. |
| F7-015 | POST F7-015 POST /api/routes/plan sin token | fixed | 3 | 3m | 864 | 4.80 | 0.00 | 100.00 | 271 | 56 | 725 | 453 | 512 | 619 | Fallido | Hallazgo de seguridad: assertion de rechazo sin token falla. |
| F7-016 | GET F7-016 Recovery GET /api/health | recovery | 3 a 20 | 3m | 6699 | 37.15 | 0.00 | 0.21 | 93 | 43 | 853 | 191 | 205 | 293 | Aprobado con observaciones | Recuperacion estable; failure residual bajo. |
| F7-017 | Cloudflare stability | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | No aplica / justificado | Todos los escenarios reportados se ejecutaron mediante Cloudflare. |

## Analisis Tests vs VU

| Escenario | Assertion degradada | VU donde inicia degradacion | Failure rate | Observacion |
|---|---|---:|---:|---|
| F7-011 ramp-up | Health, hazards y routes bajo ramp-up | Entre 3 y 10 VU | 0.31% a 2.65% | No hubo error HTTP; la degradacion fue de assertions bajo aumento progresivo. |
| F7-012 spike | Hazards y health durante/post spike | Hasta 20 VU | 3.54% a 3.59% | El backend no cae y health mantiene P95 <= 500 ms; quedan failures de assertion. |
| F7-013 peak | Pets/routes autenticados | Max 20 VU | 0.81% | Fallo menor de assertion en lecturas autenticadas; comentarios sin failure. |
| F7-015 security | Pets y route plan sin token | 3 VU | 100.00% | Caso funcional fallido: endpoints protegidos no cumplieron assertion esperada de rechazo sin token. |
| F7-018 runs consolidados | Analisis general de runs | 3, 5, 10 y 20 VU | 0% error HTTP | 71514 requests en tabla de runs, throughput variable por mezcla de endpoints y 0% error reportado. |

## Comparativas Requeridas

### F7-009 - Ruta Simple vs Multipunto

| Variante | Perfil | VU | P95 | P99 | Error % | Observacion |
|---|---|---:|---:|---:|---:|---|
| 2 puntos | fixed | 3 | 403 ms | 1625 ms | 0.00% | Ruta simple estable; mayor P99 por picos aislados. |
| 5 puntos | fixed | 3 | 476 ms | 710 ms | 0.00% | Multipunto aumenta P95 frente a simple, pero reduce P99 observado y cumple umbral. |

### F7-010 - Rutas con Filtros de Riesgo

| Variante | Perfil | VU | P95 | P99 | Error % | Observacion |
|---|---|---:|---:|---:|---:|---|
| Sin filtros | fixed | 3 | 403 ms | 1625 ms | 0.00% | Se toma F7-008 como referencia sin filtros. |
| Filtros `high`, `medium` | fixed | 3 | 506 ms | 856 ms | 0.00% | Los filtros agregan latencia moderada en P95, sin error HTTP ni timeout sistematico. |

## Analisis F7-018 - Runs Performance

| Run | Start Time | VUs | Duracion | Total Requests | Requests/s | Response Time (ms) | Error % | CPU Cores | Memory (GB) |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 29 | 2026-05-12 00:43:54 | 20 | 3m | 6699 | 37.26 | 93 | 0 | 6 | 15 |
| 28 | 2026-05-12 00:42:40 | 10 | 3m | 560 | 15.94 | 64 | 0 | 6 | 15 |
| 27 | 2026-05-12 00:28:45 | 5 | 3m | 2600 | 14.43 | 290 | 0 | 6 | 15 |
| 26 | 2026-05-12 00:09:18 | 5 | 15m | 34777 | 38.62 | 90 | 0 | 6 | 15 |
| 25 | 2026-05-11 23:55:24 | 10 | 3m | 1861 | 10.30 | 500 | 0 | 6 | 15 |
| 24 | 2026-05-11 23:49:30 | 20 | 3m | 3785 | 20.96 | 186 | 0 | 6 | 15 |
| 23 | 2026-05-11 23:44:22 | 10 | 3m | 5774 | 31.92 | 204 | 0 | 6 | 15 |
| 22 | 2026-05-11 23:37:59 | 10 | 3m | 3305 | 20.66 | 322 | 0 | 6 | 15 |
| 21 | 2026-05-11 23:28:28 | 3 | 3m | 1580 | 8.75 | 283 | 0 | 6 | 15 |
| 20 | 2026-05-11 23:23:54 | 3 | 3m | 1621 | 8.98 | 276 | 0 | 6 | 15 |
| 19 | 2026-05-11 23:18:52 | 3 | 3m | 1693 | 9.39 | 263 | 0 | 6 | 15 |
| 18 | 2026-05-11 23:18:08 | 3 | 3m | 60 | 3.66 | 515 | 0 | 6 | 15 |
| 17 | 2026-05-11 22:05:47 | 3 | 3m | 950 | 5.25 | 515 | 0 | 6 | 15 |
| 16 | 2026-05-11 22:01:29 | 3 | 3m | 1508 | 8.35 | 305 | 0 | 6 | 15 |
| 15 | 2026-05-11 22:00:54 | 3 | 3m | 170 | 6.22 | 391 | 0 | 6 | 15 |
| 14 | 2026-05-11 21:55:45 | 3 | 3m | 826 | 4.57 | 587 | 0 | 6 | 15 |
| 13 | 2026-05-11 20:11:34 | 3 | 3m | 290 | 6.53 | 388 | 0 | 6 | 15 |
| 12 | 2026-05-11 20:10:27 | 3 | 3m | 410 | 9.53 | 253 | 0 | 6 | 15 |
| 10 | 2026-05-11 20:04:15 | 3 | 3m | 1565 | 8.65 | 291 | 0 | 6 | 15 |
| 9 | 2026-05-11 20:00:13 | 3 | 3m | 1480 | 8.19 | 313 | 0 | 6 | 15 |

La tabla de runs consolida 71514 requests con 0% error HTTP. El throughput varia por mezcla de endpoints y perfil: rutas/GraphHopper y escrituras bajan RPS, mientras endurance y recovery sobre lecturas/health alcanzan los mayores RPS. No hay evidencia de HTTP 5xx en los datos entregados. Los campos CPU Cores y Memory (GB) se conservan tal como fueron reportados en el resumen de runs.

## F7-019 - Consolidacion 5xx, Error Budget y Endpoints Lentos

| Indicador | Resultado |
|---|---:|
| Requests totales en tabla granular | 76228 |
| Error HTTP consolidado | 0.00% |
| Avg ponderado | 151.48 ms |
| Failure ponderado incluyendo F7-015 | 2.58% |
| Failure ponderado excluyendo F7-015 | 0.32% |
| Max observado | 8781 ms en `GET /api/pets autenticado` |
| Mayor P95 observado | 1221 ms en `POST /api/hazards` |
| Mayor P99 observado | 1625 ms en `POST /api/routes/plan simple` |
| HTTP 5xx reportados | 0 |

Los endpoints mas lentos por promedio fueron `POST /api/auth/login` (739 ms), `POST /api/hazards` (640 ms), `POST /api/hazards/{id}/comments` (565 ms) y `POST /api/pets` (514 ms). Todos quedaron dentro de los umbrales de su categoria. El mayor riesgo no es latencia sino seguridad funcional en F7-015.

## Evidencias Adjuntas

| Evidencia | Ruta / descripcion |
|---|---|
| Coleccion Postman | `postman/F7_A4MPets_Performance.postman_collection.json` |
| Environment Postman | `postman/F7_A4MPets_Cloudflare.postman_environment.json` |
| Datos Performance | `postman/f7-performance-data.csv` |
| Captura/link performance run baseline | No adjunta en el repositorio; metricas registradas en este reporte. |
| Captura/link performance run fixed read | No adjunta en el repositorio; metricas registradas en este reporte. |
| Captura/link performance run fixed write | No adjunta en el repositorio; metricas registradas en este reporte. |
| Captura/link performance run GraphHopper | No adjunta en el repositorio; metricas registradas en este reporte. |
| Captura/link performance run ramp-up/spike/peak | No adjunta en el repositorio; metricas registradas en este reporte. |
| Export o resumen consolidado | Tabla F7-018 y consolidado F7-019 en este documento. |

## Hallazgos F7

| # | Hallazgo | Impacto | Evidencia | Tratamiento |
|---|---|---|---|---|
| 1 | `POST /api/pets sin token` no cumple la assertion esperada de rechazo sin token. | Alto para seguridad funcional si el endpoint permite crear recursos sin autenticacion. | F7-015: 868 requests, 0.00% error HTTP, 100.00% failure. | Registrar defecto y revisar middleware/autorizacion de creacion de mascotas. |
| 2 | `POST /api/routes/plan sin token` no cumple la assertion esperada de rechazo sin token. | Medio/alto segun decision de producto; el caso espera 401 en endpoints protegidos. | F7-015: 864 requests, 0.00% error HTTP, 100.00% failure. | Confirmar si planificacion debe ser privada; si aplica, proteger endpoint con token. |
| 3 | Assertions fallidas menores durante ramp-up, spike y peak. | Bajo/medio; no se observaron errores HTTP ni 5xx, pero hay degradacion bajo concurrencia. | F7-011, F7-012, F7-013 con failures entre 0.31% y 3.59%. | Mantener como observacion y reejecutar despues de corregir F7-015 o al mover a infraestructura mas robusta. |
| 4 | Maximo aislado de 8781 ms en `GET /api/pets autenticado`. | Bajo si es outlier; no afecta P95/P99 de forma relevante. | F7-004 pets: P95 252 ms, P99 381 ms, max 8781 ms. | Monitorear en siguientes corridas; revisar logs si se repite. |

## Criterios de Aceptacion

| Criterio | Resultado |
|---|---|
| Escenarios F7-001 a F7-020 ejecutados o justificados | Cumplido: F7-001 a F7-016 ejecutados, F7-017 justificado, F7-018 a F7-020 completados por analisis. |
| No se presentan respuestas HTTP 5xx sin documentar | Cumplido: no se reportan 5xx en los datos entregados. |
| Error % queda dentro del umbral por tipo de endpoint o se justifica | Cumplido: Error % reportado en 0.00% para la tabla granular. |
| P95 queda dentro del umbral por tipo de endpoint o se justifica | Cumplido: todos los P95 reportados quedan dentro de umbrales. |
| GraphHopper responde para escenarios de rutas | Cumplido: F7-008, F7-009 y F7-010 completados sin error HTTP. |
| Cloudflare Tunnel permanece operativo o se documenta cambio de URL | Cumplido con observacion: se documenta que la URL exacta no esta registrada en el entorno actual. |
| Tests vs VU revisado para detectar degradacion | Cumplido: se documentan failures en ramp-up, spike, peak y seguridad sin token. |

## Conclusion

F7 queda **aprobada con observaciones** para performance local controlada. El backend sostuvo las cargas ejecutadas mediante Cloudflare sin errores HTTP reportados ni 5xx, con percentiles dentro de umbrales incluso en rutas con GraphHopper. La endurance corta mostro estabilidad sostenida con 34777 requests en el run de 15 minutos y 0% error HTTP.

La aprobacion queda condicionada por el hallazgo F7-015: `POST /api/pets sin token` y `POST /api/routes/plan sin token` fallaron el criterio esperado de rechazo sin autenticacion. Tambien se recomienda reejecutar ramp-up/spike/peak despues de atender ese hallazgo para confirmar que las assertions fallidas menores no esconden degradacion funcional.
