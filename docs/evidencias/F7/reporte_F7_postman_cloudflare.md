# Reporte de Evidencias - Fase F7: Pruebas No Funcionales con Postman y Cloudflare

**Proyecto:** A4MPets  
**Fecha de ejecucion:** [PENDIENTE]  
**Fase:** F7 - Pruebas no funcionales / carga ligera API  
**Herramienta:** Postman Runner  
**Entorno:** Stack local A4MPets publicado mediante Cloudflare Tunnel  
**URL Cloudflare usada:** [PENDIENTE]  

---

## Resumen Ejecutivo

La fase F7 valida estabilidad, tiempos de respuesta y comportamiento bajo carga ligera de los endpoints principales del backend cuando el sistema local se expone mediante Cloudflare Tunnel.

Esta fase no valida flujos visuales de usuario, sino contratos HTTP y resistencia basica de la API ante multiples iteraciones. Las peticiones fueron preparadas en:

```text
postman/F7_A4MPets_Load.postman_collection.json
postman/F7_A4MPets_Cloudflare.postman_environment.json
postman/f7-runner-data.csv
```

## Diferencia Frente a F3, F4 y F5

| Fase | Enfoque | Diferencia con F7 |
|---|---|---|
| F3 | Integracion backend/API automatizada en PHPUnit | F3 valida contratos funcionales con entorno de pruebas; F7 mide tiempos y estabilidad con Postman contra Cloudflare. |
| F4 | Sistema integrado local de caja blanca | F4 comprueba comunicacion entre componentes locales; F7 ejercita endpoints repetidamente desde un cliente externo. |
| F5 | Caja negra E2E en navegador | F5 simula una persona usuaria desde UI; F7 no usa navegador, mide API y carga ligera. |

## Preparacion del Entorno

Pasos ejecutados:

1. Levantar backend Laravel, base de datos, frontend y GraphHopper.
2. Ejecutar Cloudflare Tunnel:

```bash
npm run dev:cloudflare
```

3. Copiar URL generada desde:

```text
.runtime/cloudflare-url.txt
```

4. Importar en Postman la coleccion y environment F7.
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
| Login QA | [PENDIENTE] | Debe retornar HTTP 200 y `access_token`. |
| Crear peligro base | [PENDIENTE] | Debe retornar HTTP 201 y guardar `hazard_id`. |

## Resultados por Caso F7

| Caso | Endpoint / Flujo | Iteraciones | Esperado | HTTP exitosos | Fallos | Latencia avg | Latencia min | Latencia max | Estado |
|---|---|---:|---|---:|---:|---:|---:|---:|---|
| F7-001 | GET `/api/health` | 50 | HTTP 200, `status=ok` | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-002 | POST `/api/auth/login` | 30 | HTTP 200, token | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-003 | GET `/api/hazards` | 50 | HTTP 200, paginacion | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-004 | POST `/api/pets` | 20 | HTTP 201, id mascota | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-005 | POST `/api/hazards` | 20 | HTTP 201, riesgo low | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-006 | POST `/api/media/upload` | 10 | HTTP 200, URL media | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-007 | POST `/api/routes/plan` | 15 | HTTP 200, ruta con distancia/duracion | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-008 | GET `/api/health` incremental | 10/20/30/50 | Comparar promedio por carga | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-009 | Burst GET `/api/hazards` + health | 20 + 1 | Sin degradacion critica | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-010 | POST `/api/pets` sin token | 20 | HTTP 401, sin 500 | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-011 | Rutas 2 puntos vs 5 puntos | 10 + 10 | Comparar latencia | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-012 | Rutas sin filtros vs filtros | 10 + 10 | Sin timeout, comparar latencia | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-013 | GET `/api/lost-pet-reports` | 30 | HTTP 200, data array | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-014 | GET `/api/found-pet-reports` | 30 | HTTP 200, data array | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-015 | GET `/api/generic-reports` | 30 | HTTP 200, data array | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-016 | GET `/api/routes` | 30 | HTTP 200, data array | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-017 | POST `/api/hazards/{id}/comments` | 15 | HTTP 201, comentario | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-018 | Cloudflare URL tras 1 hora | 2 | URL vigente o cambio documentado | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-019 | Consolidacion sin HTTP 500 | Total F7 | 0 respuestas 500 | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |
| F7-020 | Reporte consolidado | Total F7 | Conclusion estabilidad | [ ] | [ ] | [ ] ms | [ ] ms | [ ] ms | [PENDIENTE] |

## Comparativas Requeridas

### F7-008 - Carga Incremental Health

| Iteraciones | Latencia promedio | Latencia minima | Latencia maxima | Fallos | Observacion |
|---:|---:|---:|---:|---:|---|
| 10 | [ ] ms | [ ] ms | [ ] ms | [ ] | [ ] |
| 20 | [ ] ms | [ ] ms | [ ] ms | [ ] | [ ] |
| 30 | [ ] ms | [ ] ms | [ ] ms | [ ] | [ ] |
| 50 | [ ] ms | [ ] ms | [ ] ms | [ ] | [ ] |

### F7-011 - Complejidad de Ruta

| Variante | Iteraciones | Latencia promedio | Fallos | Observacion |
|---|---:|---:|---:|---|
| 2 puntos | 10 | [ ] ms | [ ] | [ ] |
| 5 puntos | 10 | [ ] ms | [ ] | [ ] |

### F7-012 - Rutas con Filtros de Riesgo

| Variante | Iteraciones | Latencia promedio | Fallos | Observacion |
|---|---:|---:|---:|---|
| Sin filtros | 10 | [ ] ms | [ ] | [ ] |
| Filtros `high`, `medium` | 10 | [ ] ms | [ ] | [ ] |

## Evidencias Adjuntas

| Evidencia | Ruta / descripcion |
|---|---|
| Coleccion Postman | `postman/F7_A4MPets_Load.postman_collection.json` |
| Environment Postman | `postman/F7_A4MPets_Cloudflare.postman_environment.json` |
| Datos Runner | `postman/f7-runner-data.csv` |
| Export Runner F7-001 | [PENDIENTE] |
| Export Runner F7-002 | [PENDIENTE] |
| Export Runner completo/consolidado | [PENDIENTE] |
| Capturas Postman Runner | [PENDIENTE] |

## Hallazgos F7

| # | Hallazgo | Impacto | Evidencia | Tratamiento |
|---|---|---|---|---|
| 1 | [PENDIENTE] | [PENDIENTE] | [PENDIENTE] | [PENDIENTE] |

## Criterios de Aceptacion

| Criterio | Resultado |
|---|---|
| Todos los endpoints principales ejecutados desde Postman Runner | [PENDIENTE] |
| No se presentan respuestas HTTP 500 durante la fase | [PENDIENTE] |
| Endpoints protegidos responden con token valido | [PENDIENTE] |
| Endpoint protegido sin token responde 401 y no 500 | [PENDIENTE] |
| GraphHopper responde para planeacion de rutas | [PENDIENTE] |
| Cloudflare Tunnel permanece operativo o se documenta cambio de URL | [PENDIENTE] |
| Latencias promedio/min/max documentadas | [PENDIENTE] |

## Conclusion

[PENDIENTE: describir si el sistema se mantuvo estable bajo carga ligera, si hubo errores HTTP, si GraphHopper respondio correctamente y si Cloudflare Tunnel fue consistente durante la ejecucion.]
