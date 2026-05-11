# Reporte de Evidencias - Fase F4: Sistema Integrado Local

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-08  
**Fase:** F4 - Sistema integrado local de caja blanca  
**Herramienta:** Node.js QA harness / Laravel API / Flutter web-server / Docker GraphHopper / Playwright Chromium  
**Entorno:** Stack local en `C:\projects\Web\A4MPets`

---

## Resumen Ejecutivo

La fase F4 fue ejecutada como validacion tecnica del sistema integrado local. Se agrego un harness de pruebas en `scripts/f4-system-check.js` para levantar o reutilizar los servicios locales, consumir el backend Laravel con HTTP real, persistir datos en la base de datos local, consultar GraphHopper local y validar el arranque del frontend Flutter web.

No se modifico codigo productivo. Los cambios se limitaron a:

- Script de verificacion tecnica F4 en `scripts/f4-system-check.js`.
- Evidencia JSON de ejecucion en `docs/evidencias/F4/f4_system_check_results.json`.
- Captura del smoke frontend en `docs/evidencias/F4/f4_frontend_smoke.png`.
- Creacion de este reporte F4.

Resultado general:

| Area | Resultado |
|---|---|
| Backend Laravel/API | PASS |
| Base de datos local y persistencia | PASS |
| GraphHopper local | PASS |
| Media upload | PASS |
| Frontend web-server disponible por HTTP | PASS |
| Renderizado Flutter en Chromium headless | PASS |

La integracion backend/base de datos/GraphHopper quedo validada. El smoke frontend tambien quedo aprobado despues de ajustar la espera tecnica: Chromium ya no abre el `index.html` antes de que Flutter termine de compilar y servir `main.dart`.

## Diferencia entre F3 y F4

F3 y F4 pueden tocar endpoints similares, pero no validan el mismo riesgo.

F3 es integracion backend/API. Su objetivo es comprobar que Laravel cumple sus contratos HTTP desde una suite controlada de PHPUnit: rutas, controladores, middleware, permisos, codigos de respuesta, estructura JSON y persistencia de prueba. En F3 no se levanta el frontend Flutter, no se valida renderizado en navegador y los servicios externos pueden estar simulados o controlados para aislar el contrato de la API.

F4 es sistema integrado local. Su objetivo es comprobar que los componentes reales del stack local trabajan juntos: backend Laravel, frontend Flutter web, base de datos local, GraphHopper Docker, media storage y variables de entorno. Por eso F4 usa peticiones HTTP reales contra el backend local, consulta GraphHopper real y verifica que el frontend web responda y renderice en navegador.

| Fase | Pregunta principal | Evidencia esperada |
|---|---|---|
| F3 | La API backend cumple sus contratos si se prueba de forma controlada? | Salida PHPUnit, respuestas JSON, codigos HTTP, base de datos de prueba y cobertura `coverageF3`. |
| F4 | El sistema completo local funciona cuando sus componentes reales estan conectados? | Health checks, estado de contenedores, peticiones HTTP reales, persistencia local, respuesta GraphHopper y captura del frontend. |

Esta diferencia explica por que F4 incluye un smoke visual que F3 no puede cubrir: las pruebas F3 pueden pasar correctamente aunque exista un problema de carga o renderizado del frontend, porque F3 no abre ni valida la aplicacion en navegador.

## Procedimiento de Ejecucion

El procedimiento se automatizo en `scripts/f4-system-check.js` para que la validacion pueda repetirse con el mismo criterio tecnico:

1. Crear la carpeta de evidencia `docs/evidencias/F4`.
2. Levantar o reutilizar GraphHopper con `docker compose up -d graphhopper`.
3. Esperar disponibilidad de GraphHopper en `http://127.0.0.1:8989`.
4. Levantar o reutilizar Laravel en `http://127.0.0.1:8000` y validar `GET /api/health`.
5. Ejecutar migraciones si el backend es iniciado por el harness.
6. Generar `frontend/env/runtime.local.json` con las URLs locales del backend.
7. Levantar Flutter web-server en `http://127.0.0.1:7357` usando `--dart-define-from-file=env/runtime.local.json`.
8. Ejecutar peticiones HTTP reales contra Laravel para registro, login, mascotas, peligros, reportes, comentarios, rutas, planeacion, logout, health y media upload.
9. Planear rutas mediante Laravel usando GraphHopper local real.
10. Abrir el frontend con Playwright Chromium, capturar consola, errores de pagina, request failures, superficie Flutter y screenshot.
11. Guardar resultados estructurados en `f4_system_check_results.json`.
12. Guardar captura del frontend en `f4_frontend_smoke.png`.
13. Cerrar los procesos locales iniciados por el harness.

El harness no reemplaza F5, porque no ejecuta flujos completos de usuario final con interacciones visuales profundas. F4 se enfoca en comprobar comunicacion tecnica real entre componentes y dejar defectos de integracion listos para investigar antes de la fase E2E.

## Comandos Ejecutados

Validacion de sintaxis del harness:

```bash
node --check scripts\f4-system-check.js
```

Resultado:

```text
Exit code: 0
```

Ejecucion F4:

```bash
node scripts\f4-system-check.js
```

Resultado:

```text
F4-001 PASS: Backend, frontend web server and GraphHopper are available.
F4-002 PASS: User registration persisted through real Laravel API.
F4-003 PASS: Login token works against protected backend endpoint.
F4-004 PASS: Pet created and returned from authenticated owner list.
F4-005 PASS: Hazard marker source data is available through public hazards API.
F4-006 PASS: Hazard created with manual-coordinate payload and persisted.
F4-007 PASS: Backend supplies risk-filtered hazard data for map layer toggles.
F4-008 PASS: Lost pet report created with persisted pet association.
F4-009 PASS: Found pet report created and linked to lost pet report.
F4-011 PASS: Travel route created and persisted through backend.
F4-010 PASS: Backend planned a real route through local GraphHopper.
F4-021 PASS: Navigation instructions payload is returned for planned route.
F4-012 PASS: Hazard comment persisted and returned with author data.
F4-013 PASS: Logout revokes token and private API rejects it.
F4-014 PASS: Lost pet marker source data is available through public API.
F4-015 PASS: Manual map coordinates persisted in report payloads.
F4-016 PASS: Route planning considers persisted high-risk hazards.
F4-020 PASS: Generic report radius data persisted for map impact circle.
F4-022 PASS: Image upload endpoint stores media usable by hazard reports.
F4-018 PASS: Health remains OK after integrated create/list/plan/upload operations.
F4-017 PASS: Frontend loaded in headless Chromium without critical console errors.
F4-001-extra PASS: Frontend runtime API base URL configured for local backend.
Exit code: 0
```

El exit code final es `0`. La ejecucion registro 22 resultados `PASS`, incluyendo el smoke de renderizado frontend `F4-017`.

## Evidencias Generadas

| Evidencia | Ruta |
|---|---|
| Resultado estructurado F4 | `docs/evidencias/F4/f4_system_check_results.json` |
| Captura del frontend web | `docs/evidencias/F4/f4_frontend_smoke.png` |
| Script de ejecucion | `scripts/f4-system-check.js` |

Datos relevantes registrados:

| Dato | Valor |
|---|---|
| GraphHopper | `a4mpets-graphhopper Up 5 hours (healthy)` |
| Backend base URL | `http://127.0.0.1:8000/api` |
| Frontend URL | `http://127.0.0.1:7357` |
| GraphHopper URL | `http://127.0.0.1:8989` |
| Ruta planeada F4-010 | 967.585 m / 683.695 s / 19 coordenadas |
| Instrucciones F4-021 | 17 instrucciones, perfil `foot` |
| Peligros considerados F4-016 | 7 |
| Imagen subida F4-022 | URL `/api/media/hazards/...png` |
| Superficies Flutter F4-017 | 3 |

## Matriz de Casos F4

| Caso | Resultado | Evidencia tecnica |
|---|---|---|
| F4-001 | PASS | Backend, frontend web-server y GraphHopper disponibles; contenedor `a4mpets-graphhopper` healthy. |
| F4-002 | PASS | Registro por API Laravel real con usuario persistido. |
| F4-003 | PASS | Login real y token valido contra `/api/auth/me`. |
| F4-004 | PASS | Mascota creada y devuelta por listado autenticado. |
| F4-005 | PASS | Datos de peligro disponibles como fuente de marcadores. |
| F4-006 | PASS | Reporte de peligro creado con coordenadas manuales y persistido. |
| F4-007 | PASS | Filtro de peligros por riesgo devuelve datos compatibles con capas del mapa. |
| F4-008 | PASS | Reporte de mascota perdida creado con asociacion a mascota. |
| F4-009 | PASS | Reporte de mascota encontrada creado y vinculado al reporte de perdida. |
| F4-010 | PASS | Laravel planea ruta usando GraphHopper local real. |
| F4-011 | PASS | Ruta de viaje creada y persistida. |
| F4-012 | PASS | Comentario de peligro persistido y devuelto con datos de autor. |
| F4-013 | PASS | Logout revoca token y API privada rechaza el token anterior. |
| F4-014 | PASS | Reporte de mascota perdida disponible como fuente de marcador. |
| F4-015 | PASS | Coordenadas manuales persistidas en reportes. |
| F4-016 | PASS | Planeacion considera peligros persistidos de alto riesgo. |
| F4-017 | PASS | Frontend carga en Chromium headless con `flutterSurfaceCount=3`, sin errores criticos de consola ni request failures. |
| F4-018 | PASS | `/api/health` permanece estable despues de operaciones integradas. |
| F4-019 | NO EJECUTADO | Cloudflare Tunnel no estaba dentro del stack local ejecutado por este harness. Queda para F7/no funcional o ejecucion manual con URL publica. |
| F4-020 | PASS | Reporte generico guarda radio de impacto para circulo del mapa. |
| F4-021 | PASS | Payload de instrucciones de navegacion devuelto por la planeacion de ruta. |
| F4-022 | PASS | Upload de imagen base64 almacena media utilizable por reportes. |
| F4-001-extra | PASS | `frontend/env/runtime.local.json` queda configurado con URLs locales del backend. |

## Cobertura Tecnica por Componente

| Componente | Validacion F4 |
|---|---|
| Laravel API | Health, auth, mascotas, peligros, comentarios, reportes, rutas, planeacion y media. |
| Base de datos local | Persistencia verificada mediante creacion y lectura posterior de recursos. |
| GraphHopper | Contenedor activo y calculo real de ruta a traves de `/api/routes/plan`. |
| Flutter web | Servidor local responde y renderiza el mapa en Chromium headless. |
| Variables de entorno frontend | Se genero `frontend/env/runtime.local.json` con URLs locales antes de levantar Flutter. |
| Archivos/media | Upload real de imagen y URL devuelta por backend. |

## Hallazgos F4

| # | Hallazgo | Evidencia | Impacto | Tratamiento |
|---|---|---|---|---|
| F4-1 | La primera corrida del smoke frontend abria Chromium antes de que Flutter terminara de servir `main.dart`, generando pagina blanca. | Corrida anterior de `f4_frontend_smoke.png` y `F4-017 FAIL`. | Podia producir un falso negativo de carga frontend. | Corregido en `scripts/f4-system-check.js` esperando la salida `main.dart is being served` antes de abrir Chromium. |
| F4-2 | F4-019 no se ejecuto porque Cloudflare Tunnel no fue levantado por el harness local. | No existe URL publica en la evidencia F4. | No afecta la validacion local principal, pero impide confirmar acceso externo. | Ejecutar en F7/no funcional o en una corrida manual con tunnel activo. |

## Conclusiones

La fase F4 fue ejecutada con el stack local y genero evidencia reproducible. La comunicacion backend/base de datos/GraphHopper funciona correctamente para autenticacion, persistencia, reportes, comentarios, rutas, planeacion e imagenes.

La carga frontend en Chromium tambien queda validada: el screenshot `f4_frontend_smoke.png` muestra el mapa renderizado y el JSON registra `F4-017 PASS`.
