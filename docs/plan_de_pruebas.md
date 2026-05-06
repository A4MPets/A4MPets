# Plan de Pruebas A4MPets v2

| Campo | Valor |
|---|---|
| Proyecto | A4MPets |
| Documento | Plan de pruebas detallado |
| Version | 2.0 - guia operacional sin ejecucion |
| Fecha de inicio | 2026-05-05 |
| Fecha de cierre planeada | 2026-05-14 |
| Responsable | Equipo QA |
| Repositorio base | `C:\projects\Web\A4MPets` |
| Stack bajo prueba | Frontend Flutter, Backend Laravel 12, GraphHopper, Docker Compose y Cloudflare Tunnel |

> Este documento define como se van a planear, ejecutar, evidenciar y cerrar las pruebas de A4MPets. No representa una certificacion de calidad por si mismo. Cada actividad queda pendiente hasta que el equipo QA la ejecute, registre resultado real, adjunte evidencia y documente incidencias cuando corresponda.

---

## 1. Objetivo del testing

El objetivo principal del testing es comprobar, con evidencia trazable, que A4MPets permite a una persona usuaria registrarse, iniciar sesion, administrar mascotas, reportar mascotas perdidas, reportar mascotas encontradas, reportar peligros, comentar reportes, cargar imagenes, consultar informacion en mapa, crear rutas y planear recorridos usando GraphHopper sin romper la consistencia entre frontend, backend y datos persistidos.

Los objetivos especificos son verificables y deben revisarse contra evidencia real:

| Objetivo | Explicacion detallada | Evidencia minima esperada |
|---|---|---|
| Confirmar funcionalidad central | Validar los flujos que sostienen el producto: autenticacion, perfil, mascotas, reportes, comentarios, medios, rutas y mapa. Cada flujo debe probarse con datos validos, datos invalidos y condiciones de permisos. | Capturas, respuestas JSON, salidas de pruebas automatizadas y matriz de casos actualizada. |
| Confirmar contratos de API | Verificar que cada endpoint de Laravel responda con codigo HTTP, estructura JSON, validaciones y permisos acordes con el comportamiento esperado por el frontend. | Logs de PHPUnit, coleccion Postman o respuestas exportadas. |
| Confirmar comportamiento visual | Validar que la UI en Flutter web muestre mensajes claros, paneles consistentes, formularios utilizables, marcadores correctos y ausencia de errores visibles. | Capturas por viewport, consola sin errores severos y observaciones manuales. |
| Confirmar integracion local | Validar que Laravel, Flutter, GraphHopper, Docker y Cloudflare Tunnel funcionen juntos bajo un ambiente controlado. | Health checks, URL de tunel, logs de servicios y evidencia de flujo integrado. |
| Confirmar tolerancia ante condiciones de fallo | Validar respuestas cuando falta token, hay payload invalido, GraphHopper no responde, se pierde conexion o el usuario intenta modificar recursos ajenos. | Casos fallidos controlados, mensajes de error y ausencia de caidas no manejadas. |
| Confirmar estabilidad basica | Ejecutar solicitudes repetidas mediante Postman contra el ambiente local expuesto por Cloudflare para observar latencia, errores HTTP y comportamiento del servidor. | Reporte de Postman Runner con iteraciones, tiempos y errores. |

---

## 2. Alcance

### 2.1 Funcionalidades incluidas

| Modulo | Que se prueba | Detalles que no deben quedar implicitos |
|---|---|---|
| Autenticacion | Registro, login por correo, login por nombre de usuario, perfil autenticado, actualizacion de perfil y logout. | Se debe verificar emision de token, rechazo de credenciales invalidas, revocacion de token y persistencia de sesion en frontend. |
| Mascotas | Creacion, edicion, listado, detalle, eliminacion, mascotas propias, mascotas sin propietario y cambio de estado al reportar perdida o encontrada. | Se debe comprobar que una persona usuaria no pueda modificar mascotas de otra persona y que los estados se reflejen en UI y API. |
| Reportes de peligros | Creacion, listado, detalle, edicion, eliminacion, comentarios, categoria, nivel de peligro, radio de impacto y visualizacion en mapa. | Los endpoints usan nombres tecnicos como `hazards`, pero la documentacion QA siempre los nombra como reportes de peligros. |
| Reportes de mascotas perdidas | Creacion desde mascota propia, bloqueo de duplicados activos, comentarios, detalle, edicion, eliminacion y retorno de estado al encontrar la mascota. | Se debe verificar ubicacion, fecha, telefono, foto y relacion con mascota. |
| Reportes de mascotas encontradas | Creacion sin mascota asociada, creacion vinculada a un reporte de mascota perdida, comentarios, detalle, edicion y eliminacion. | Se debe comprobar la tarjeta navegable hacia el reporte de mascota perdida cuando exista vinculacion. |
| Reportes genericos de tipo otro | Creacion, nivel de peligro, radio de impacto, comentarios, listado, detalle y visualizacion en mapa. | Se debe validar que el radio influya en la visualizacion de rutas cuando corresponda. |
| Rutas y planeacion | CRUD de rutas, puntos de ruta, planificacion con GraphHopper, polilinea, instrucciones, filtros de peligro y recalculo. | Se debe probar una ruta con dos puntos, una ruta multipunto y condiciones de error cuando GraphHopper no este disponible. |
| Mapa | Marcadores, capas, seleccion manual de ubicacion, ubicacion del usuario, foco de camara, polilineas y paneles sobre el mapa. | Se debe validar desktop y viewport movil, con permisos de ubicacion aceptados y denegados. |
| Medios | Carga de imagenes, buckets permitidos, recuperacion de archivo, tipo de contenido y errores por archivo invalido. | Se debe verificar perfil, mascota, reporte de peligro, reporte perdido, reporte encontrado y reporte generico. |

### 2.2 Elementos fuera de alcance

| Elemento | Motivo | Decision QA |
|---|---|---|
| Auditoria formal OWASP completa | Requiere metodologia, herramientas y tiempo de seguridad dedicado. | Solo se cubren validaciones basicas como payload HTML, permisos y tokens. |
| Publicacion en tiendas moviles | No forma parte del ciclo local de pruebas solicitado. | Se deja para una fase de release movil. |
| Validacion cartografica exhaustiva de todas las calles | El mapa depende de datos externos y no se busca certificar cartografia. | Se usan coordenadas representativas en Cali. |
| Pruebas con datos productivos reales | Puede comprometer privacidad y repetibilidad. | Se usan usuarios y datos QA. |
| Certificacion WCAG formal | Requiere checklist completo y herramientas especificas. | Se hace revision funcional minima de teclado, foco y legibilidad. |

---

## 3. Tipos de pruebas

| Familia | Tipo | Proposito | Herramientas | Criterio de aprobacion |
|---|---|---|---|---|
| Automatizadas | Caja blanca unitaria backend | Validar unidades de Laravel como servicios, formateadores, requests y reglas de dominio con conocimiento del codigo. | PHPUnit, `php artisan test`. | La prueba termina en verde y cubre al menos ruta exitosa y una condicion negativa relevante. |
| Automatizadas | Caja blanca integracion backend | Validar controladores, middleware, modelos, base de datos de prueba y respuestas JSON. | PHPUnit Feature. | Cada endpoint probado responde con codigo, estructura y persistencia esperada. |
| Automatizadas | Caja blanca frontend | Validar servicios, providers, widgets y logica de presentacion de Flutter. | `flutter analyze`, `flutter test`. | No hay errores de analyzer y las pruebas pasan. |
| Automatizadas | Caja negra E2E navegador | Simular comportamiento de una persona usuaria real sin depender del codigo interno. | Playwright sobre Flutter web. | El flujo termina con la pantalla, datos y respuestas API esperadas. |
| Sistema | Integracion local completa | Confirmar que frontend, backend y GraphHopper funcionan al mismo tiempo. | Scripts npm, Docker, navegador, logs. | Flujos P0 funcionan sin errores de consola ni HTTP 5xx inesperados. |
| Manuales | Funcionales exploratorias | Encontrar problemas de usabilidad, mensajes, estados vacios y flujos no cubiertos por automatizacion. | Navegador, DevTools, capturas. | Cada observacion queda documentada con pasos y evidencia. |
| No funcionales | Carga manual controlada | Observar comportamiento del backend local expuesto por Cloudflare ante muchas solicitudes repetidas. | Postman Runner, Cloudflare Tunnel. | Se registran latencias, errores, saturacion y comportamiento de recuperacion. |
| Regresion | Reejecucion de P0 y P1 | Confirmar que las correcciones no rompieron flujos criticos. | PHPUnit, Flutter test, Playwright, manual. | No quedan defectos criticos o altos sin decision formal. |

---

## 4. Estrategia por fases

La estrategia se divide en fases identificables para que el equipo pueda solicitar ejecuciones concretas por ID. Cada fase tiene entradas, actividades y salida esperada. Ninguna fase debe cerrarse sin evidencia.

| Fase | Fecha | Nombre | Actividades detalladas | Salida esperada |
|---|---:|---|---|---|
| F0 | 2026-05-05 | Preparacion y smoke de ambiente | Confirmar dependencias, scripts, health check, GraphHopper, Cloudflare Tunnel, datos QA, carpeta de evidencias y version bajo prueba. | Ambiente listo, datos definidos y bloqueos iniciales documentados. |
| F1 | 2026-05-05 a 2026-05-06 | Caja blanca backend | Ejecutar suites PHPUnit existentes, revisar cobertura de Auth, mascotas, reportes, comentarios, rutas, planeacion e instrucciones. | Resultado de cada suite backend y lista de fallos. |
| F2 | 2026-05-06 a 2026-05-07 | Caja blanca frontend | Ejecutar analyzer, pruebas de servicios, providers, widgets, audio, rutas y flujo de mapa. | Resultado completo de `flutter analyze` y `flutter test`. |
| F3 | 2026-05-07 a 2026-05-08 | Integracion backend API | Validar endpoints con tokens, payloads, permisos, errores 401/403/422, upload y health. | Evidencia de contratos API por modulo. |
| F4 | 2026-05-08 a 2026-05-09 | Sistema integrado local | Levantar stack local, ejecutar flujos desde UI, validar mapa, rutas, reportes y GraphHopper. | Smoke funcional integrado con capturas. |
| F5 | 2026-05-09 a 2026-05-11 | Caja negra E2E navegador | Ejecutar flujos de usuario en navegador: onboarding, mascotas, reportes, comentarios, rutas, permisos y responsive. | Reporte E2E o matriz manual equivalente si la automatizacion aun no existe. |
| F6 | 2026-05-11 a 2026-05-12 | Pruebas manuales funcionales | Revisar mensajes, errores, datos limite, viewport movil, permisos de ubicacion, estados vacios y recuperacion visual. | Matriz exploratoria con observaciones y defectos. |
| F7 | 2026-05-12 a 2026-05-13 | No funcional y carga con Postman + Cloudflare | Ejecutar iteraciones sobre health, login, listados, creacion de recursos, upload y planeacion usando URL Cloudflare. | Reporte de latencia, errores y comportamiento del servidor. |
| F8 | 2026-05-14 | Regresion y cierre QA | Reejecutar P0/P1, hacer retest, consolidar evidencias, clasificar incidencias abiertas y emitir decision de salida. | Informe final con decision Go/No-Go. |

### 4.1 Regla de clasificacion de casos por contexto

La clasificacion de los casos no se hara solamente por pantalla o por endpoint. Cada funcionalidad debe analizarse desde el contexto donde realmente puede observarse con precision. Por ejemplo, el login completo no debe tratarse como prueba unitaria del frontend, porque depende de formulario, API, token, persistencia de sesion y respuesta del backend. En frontend si se pueden probar unitariamente validaciones locales, transformacion de estado, almacenamiento de sesion simulado, providers y widgets aislados. El login completo se prueba como integracion API, sistema integrado y E2E de caja negra.

| Contexto | Que se valida | Que no se fuerza en ese contexto | Evidencia aceptada |
|---|---|---|---|
| Unitarias backend | Servicios, reglas de dominio, requests, normalizacion de payloads, autorizacion encapsulada, formateadores y transformaciones sin navegador. | No se valida experiencia visual ni navegacion de usuario. | Salida PHPUnit con metodo, clase y aserciones relevantes. |
| Integracion backend API | Rutas HTTP, middleware `api.token`, controladores, modelos, base de datos de prueba, codigos 200/201/401/403/404/422 y forma JSON. | No se valida renderizado Flutter ni interacciones del mapa. | Respuesta JSON, codigo HTTP, registro persistido y salida PHPUnit Feature o Postman. |
| Unitarias frontend | Providers Riverpod, clases de estado, servicios Dart, validaciones de formulario sin servidor, parsers, filtros, seleccion de capas, audio y preferencias. | No se valida login real contra Laravel ni subida real de archivos. | Salida `flutter test`, asserts de estado y widget tests aislados. |
| Integracion frontend | Widgets conectados a providers, repositorios mockeados, estados de carga/error/vacio, navegacion de paneles y lectura de datos de prueba. | No se asume disponibilidad del backend real. | Widget test, captura, log de test y descripcion de mock utilizado. |
| Sistema integrado local | Frontend Flutter, backend Laravel, SQLite local, medios, GraphHopper y Cloudflare Tunnel funcionando juntos. | No se mide carga maxima ni se simulan usuarios masivos. | Capturas, logs de servicios, respuestas HTTP y estado de contenedores. |
| Caja negra E2E | Flujos completos desde navegador usando Playwright o ejecucion manual equivalente mientras se crean los scripts. | No se inspecciona codigo interno ni se depende de clases especificas. | Reporte Playwright, screenshots, traces, consola y Network. |
| Contrato GraphHopper | Payload enviado por Laravel, respuesta de ruteo, polilinea, distancia, tiempo e instrucciones convertidas al formato de A4MPets. | No se prueba la logica interna de GraphHopper como producto externo. | Request/response, logs del servicio Laravel, estado del contenedor y salida del endpoint `/routes/plan`. |

### 4.2 Mapa detallado de cobertura Backend Laravel

La cobertura backend debe incluir pruebas unitarias, pruebas de integracion API y validaciones de sistema cuando el comportamiento dependa de frontend o GraphHopper. La cobertura de codigo debe revisarse por sentencia, rama y condicion en servicios con decisiones relevantes, especialmente validaciones, permisos, eliminaciones en cascada, comentarios, filtros de peligro y manejo de respuestas externas.

| Modulo backend | Unitarias de caja blanca | Integracion API | Sistema / E2E relacionado |
|---|---|---|---|
| Autenticacion | Validar `AuthTokenService`, generacion y revocacion de token, hash de password, normalizacion de username/correo y ramas de credenciales invalidas. | `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `PUT /auth/profile`, `POST /auth/logout`, errores 401 y 422. | Registro desde UI, login por correo, login por username, persistencia de sesion, logout y bloqueo de acciones privadas sin token. |
| Perfil de usuario | Validar reglas de actualizacion de nombre, username, correo y telefono cuando aplique. | Actualizar perfil con token valido, rechazar correo duplicado, rechazar payload incompleto y confirmar que `me` devuelve datos actualizados. | Pantalla o panel que consume perfil local, comentarios mostrando autor y reportes asociados al usuario. |
| Mascotas | Validar servicio de creacion, actualizacion, eliminacion, `markFound`, campos obligatorios, foto y pertenencia por usuario. | `GET /pets`, `GET /pets/{pet}`, `POST /pets`, `PUT /pets/{pet}`, `DELETE /pets/{pet}`, `POST /pets/{pet}/mark-found`, 403 sobre mascotas ajenas. | Crear mascota desde UI, editar datos, eliminar mascota, marcar encontrada y usar la mascota en reportes de perdida. |
| Reportes de mascota perdida | Validar servicio de reporte, asociacion con mascota, coordenadas, fecha de desaparicion, telefono, foto, listado, detalle y borrado con comentarios. | `GET /lost-pet-reports`, `GET /lost-pet-reports/{id}`, `POST`, `PUT`, `DELETE`, `comments`, permisos de autor y validaciones 422. | Crear reporte en mapa, seleccionar ubicacion manual, ver marcador, abrir detalle, comentar y verificar que aparece en capas. |
| Reportes de mascota encontrada | Validar reporte con o sin vinculo a reporte de perdida, foto, descripcion, coordenadas, telefono y resolucion de mascota asociada. | `GET /found-pet-reports`, `GET /found-pet-reports/{id}`, `POST`, `PUT`, `DELETE`, comentarios y payloads con `matchedLostPetReportId`. | Crear reporte encontrado, vincularlo a reporte perdido, visualizar tarjeta con resumen de mascota y navegar a ubicacion. |
| Reportes genericos | Validar categoria `other`, descripcion, radio de impacto, fecha, foto, autor y comentarios. | `GET /generic-reports`, `POST /generic-reports`, `GET /generic-reports/{id}`, `PUT`, `DELETE`, `comments`, validaciones de coordenadas y radio. | Crear reporte generico desde UI, verlo en mapa, abrir detalles, comentar y confirmar persistencia. |
| Reportes de peligros | Validar niveles bajo, medio y alto, categoria, duracion, radio, foto, fecha, autor, sincronizacion de comentarios y eliminacion con dependencias. | `GET /hazards`, `POST /hazards`, `GET /hazards/{id}`, `PUT`, `DELETE`, `comments`, filtros por nivel/categoria y errores de payload. | Crear peligro desde mapa, alternar circulos de peligro, abrir detalle, confirmar/denegar con comentarios rapidos y usarlo en planeacion. |
| Comentarios | Validar `ReportCommentService`, `HazardCommentSyncService`, autor, texto vacio, fecha, relacion polimorfica y eliminacion del reporte padre. | Endpoints de comentarios para peligros, perdidos, encontrados y genericos; 401 sin token, 404 si el reporte no existe, 422 texto invalido. | Agregar comentario desde panel, ver actualizacion del contador/lista y comprobar que el autor se muestra correctamente. |
| Medios | Validar decodificacion base64, extension permitida, nombre generado, guardado local, lectura por bucket y rechazo de archivos invalidos. | `POST /media/upload`, `GET /media/{bucket}/{fileName}`, rechazo por tipo no permitido, payload corrupto o archivo inexistente. | Subir foto de mascota, foto de reporte y vista previa; confirmar que la URL queda visible desde frontend y Cloudflare. |
| Rutas guardadas | Validar `TravelRouteService`, orden de puntos, minimo de puntos, actualizacion transaccional, eliminacion de `route_points` y pertenencia. | `GET /routes`, `GET /routes/{id}`, `POST /routes`, `PUT /routes/{id}`, `DELETE /routes/{id}`, permisos y payloads invalidos. | Crear ruta desde editor de mapa, editar nombre/puntos, eliminar ruta, seleccionarla para viaje y verificar polilinea. |
| Planificacion de ruta | Validar `GraphHopperRoutingService`, construccion de payload, perfiles, exclusion por peligros, distancia, duracion, instrucciones y fallback controlado. | `POST /routes/plan` con dos puntos, multipunto, filtros de nivel de peligro, GraphHopper disponible y GraphHopper no disponible. | Planear ruta desde UI, observar polilinea, instrucciones, distancia, alertas de proximidad y recalculo si cambia la seleccion. |
| Health y configuracion | Validar respuesta de `/health`, dependencias minimas, variables `GRAPHHOPPER_BASE_URL`, DB SQLite y entorno local. | `GET /health`, arranque con Docker, arranque local y verificacion de respuesta estable. | Smoke F0/F4, Cloudflare Tunnel y monitoreo durante carga manual. |
| Seguridad y permisos | Validar middleware `api.token`, ownership por usuario, acciones anonimas permitidas solo en listados/detalles publicos y mutaciones privadas protegidas. | Repetir mutaciones sin token, con token invalido, con usuario no propietario y con recurso inexistente. | E2E: intentar acciones privadas despues de logout y confirmar que la UI no deja guardar datos protegidos. |

### 4.3 Mapa detallado de cobertura Frontend Flutter

La cobertura frontend se divide entre logica aislada, widget tests, integracion con repositorios mockeados y flujos completos en navegador. No se debe convertir cada flujo visual en una prueba unitaria. Formularios que dependen del backend, del mapa o de subida de archivos se cubren mejor con widget tests, integracion o E2E.

| Modulo frontend | Unitarias / providers | Widget o integracion Flutter | Sistema / E2E relacionado |
|---|---|---|---|
| Sesion local | `session_providers`, `SessionStore`, lectura/escritura de token, usuario invitado y perfil local. | Estado autenticado, estado invitado, expiracion simulada y limpieza despues de logout. | Login real, logout real, reinicio de app conservando sesion cuando el token existe. |
| Paneles de autenticacion | Validaciones locales de campos, habilitacion de botones, mensajes de error y estado de carga. | Render de `LoginPanelContent` y `RegisterPanelContent` con entradas validas e invalidas. | Registro y login contra backend desde navegador; no se trata como unitaria pura. |
| Providers de mapa | `panelFlowProvider`, `routeEditorProvider`, `reportFlowProvider`, `tripFlowProvider`, `mapPresentationProvider` y transiciones principales. | Panel activo, cierre, minimizado, seleccion de ubicacion manual, seleccion de reporte y reinicio de flujos. | Navegacion real entre paneles, apertura desde marcadores y consistencia visual del mapa. |
| Mapa y capas | Filtros de peligros bajo/medio/alto, reportes perdidos, encontrados y genericos, foco de camara y seleccion de marcador. | `MapWidget` con datos simulados, marcadores visibles, polilinea de ruta y taps sobre mapa. | Usuario activa/desactiva capas, selecciona marcadores y confirma que el detalle corresponde al item tocado. |
| Mascotas | Validaciones de formulario, modelo `PetRecord`, foto local, estados vacios y lista de mascotas. | Panel de gestion de mascotas con crear/editar/eliminar usando repositorio mockeado. | Crear mascota real, editarla, eliminarla, marcarla encontrada y usarla para reporte perdido. |
| Reporte de mascota perdida | Estado de ubicacion manual, mascota seleccionada, preview, fecha, telefono, foto y descripcion. | Formulario con mascota valida, sin mascota, ubicacion ausente y foto opcional. | Crear reporte perdido desde mapa, ver marcador, abrir detalle y comentar. |
| Reporte de mascota encontrada | Vinculo opcional a reporte perdido, seleccion de mascota, coordenadas, foto, telefono y descripcion. | Panel con reporte vinculado, reporte no vinculado y datos incompletos. | Crear reporte encontrado, vincularlo, comprobar tarjeta de resumen y navegar a ubicacion. |
| Reportes genericos | Categoria, descripcion, nivel/categoria de peligro cuando aplique, radio de impacto, foto y preview. | Formulario con datos validos, faltantes y limites de coordenadas/radio. | Crear reporte generico, verlo en mapa, abrir detalle y comentar. |
| Reportes de peligros | Categoria, duracion, nivel bajo/medio/alto, radio, foto, ubicacion manual, preview y circulos. | Formulario, panel de detalle, panel de comentarios rapidos y panel de capas. | Crear peligro, alternar capas, confirmar/denegar peligro, ver impacto en planeacion de ruta. |
| Comentarios | Construccion de comentario, validacion de texto vacio, seleccion de tipo de reporte y actualizacion optimista o recarga. | `ReportCommentsPanelContent` para peligro, perdido, encontrado y generico con repositorios mockeados. | Publicar comentario real y confirmar que aparece despues de refrescar. |
| Rutas y editor | `routeEditorProvider`, agregar punto, editar punto, seleccionar ruta, borrar borrador, polilinea y nombre. | Panel de rutas con crear/editar/eliminar usando rutas simuladas. | Crear ruta en mapa, editar puntos, guardar, seleccionar y eliminar. |
| Viaje y navegacion | `tripFlowProvider`, filtros de niveles de peligro, mascota/ruta seleccionada, instrucciones, progreso y finalizacion. | Panel de inicio de viaje, soporte de viaje, instrucciones y cambios de filtro. | Iniciar viaje con ruta real, recibir instrucciones, ver alertas y finalizar viaje. |
| Audio y preferencias | Preferencia de transporte, configuracion de audio, mensajes generados, progreso de reproduccion y mute. | Widgets de configuracion y clases de soporte con estados simulados. | Activar/desactivar audio durante viaje y confirmar mensajes esperados. |
| Estados visuales | Carga, error, vacio, datos offline simulados, formularios con texto largo, responsive y accesibilidad basica. | Widget tests con tamanos de viewport y datos limite. | E2E responsive en escritorio y movil, consola sin errores visibles. |

### 4.4 Mapa detallado de cobertura GraphHopper

GraphHopper se trata como servicio externo ejecutado localmente con Docker. No se prueba su algoritmo interno, sino la integracion de A4MPets con su API, la estabilidad del contenedor, la calidad de los datos de entrada y la forma en que Laravel convierte la respuesta para Flutter.

| Area GraphHopper | Contrato / integracion | Sistema integrado | No funcional |
|---|---|---|---|
| Contenedor y configuracion | Validar `docker-compose.yml`, puertos 8989/8990, volumen `map.osm.pbf`, cache de grafo y `backend/graphhopper/config.yml`. | `npm run graphhopper` deja el servicio disponible antes de planear rutas. | Registrar tiempo de arranque y condicion cuando el mapa no existe o el cache esta frio. |
| Endpoint de ruteo | Confirmar que Laravel envia puntos en orden, perfil esperado, coordenadas validas y payload compatible. | `POST /routes/plan` devuelve distancia, duracion, geometria e instrucciones consumibles por Flutter. | Medir latencia de rutas cortas, multipunto y rutas con filtros de peligro. |
| Transformacion de respuesta | Validar conversion de polilinea, instrucciones, distancia, tiempo, waypoints y mensajes de navegacion. | UI muestra polilinea, lista de instrucciones y resumen de viaje sin romper el mapa. | Documentar respuestas lentas, vacias o incompletas. |
| Filtros por peligros | Confirmar que los niveles bajo, medio y alto se consideran en el calculo o en la decision de advertencia segun implementacion. | Cambiar filtros en UI altera la planificacion o las alertas esperadas. | Comparar tiempos con todos los filtros activos, filtros parciales y sin filtros. |
| Fallo controlado | Simular GraphHopper detenido, URL incorrecta, timeout, coordenadas fuera de cobertura y respuesta no JSON. | Backend devuelve error controlado y frontend muestra mensaje comprensible. | Confirmar que el backend no queda caido y que `/health` sigue respondiendo. |

### 4.5 Mapa detallado de flujos E2E de caja negra

Los flujos E2E se ejecutaran preferiblemente con Playwright sobre Flutter web. Mientras no exista automatizacion completa, cada flujo puede ejecutarse manualmente siguiendo los mismos pasos y guardando evidencia equivalente. El objetivo es cubrir comportamiento real de una persona usuaria sin depender del conocimiento interno del codigo.

| Flujo E2E | Backend implicado | Frontend implicado | GraphHopper implicado | Validaciones principales |
|---|---|---|---|---|
| Registro, login y logout | Auth, tokens, perfil | Panel login/register, sesion local, paneles protegidos | No aplica | Usuario queda autenticado, puede ver datos privados, hace logout y pierde acceso a mutaciones protegidas. |
| Gestion de mascotas | Pets, media | Panel mascotas, formularios, foto, estados vacios | No aplica | Crear, editar, listar, eliminar y marcar encontrada sin afectar mascotas de otro usuario. |
| Reporte de mascota perdida | Pets, lost-pet-reports, media, comments | Seleccion de mascota, ubicacion manual, mapa, detalle, comentarios | No aplica | Reporte aparece en mapa, detalle corresponde al marcador, comentario queda persistido. |
| Reporte de mascota encontrada | Found-pet-reports, lost-pet-reports, media, comments | Vinculo a reporte perdido, formulario, lista, detalle | No aplica | Reporte encontrado puede quedar vinculado o independiente, y se visualiza correctamente. |
| Reporte de peligro | Hazards, media, comments | Formulario de peligro, capas bajo/medio/alto, detalle y comentario rapido | Indirecto cuando se planea ruta | Peligro aparece con circulo correcto, filtros lo ocultan/muestran y comentarios funcionan. |
| Reporte generico | Generic-reports, media, comments | Formulario generico, detalle y capas | No aplica | Reporte se crea, se lista, se abre, se comenta y respeta coordenadas/radio. |
| Rutas guardadas | Routes, route points | Editor de rutas, polilinea, panel de gestion | No aplica | Ruta de dos puntos y ruta multipunto se guardan, editan, eliminan y mantienen orden. |
| Planeacion de viaje | Routes, `/routes/plan`, hazards | Panel de viaje, filtros, instrucciones, audio, mapa | Si aplica | Se calcula ruta, se muestran instrucciones, alertas y finalizacion de viaje. |
| Permisos y errores | Middleware, validaciones, ownership | Mensajes de error, formularios, estados de carga | Puede aplicar si ruta falla | Sin token, token invalido, datos incompletos, recurso ajeno y servicio externo caido se manejan sin pantalla rota. |
| Responsive y compatibilidad | Todos los modulos publicos y privados | Layout movil/escritorio, paneles, mapa, formularios | Segun flujo | No hay overflow, texto ilegible, botones inaccesibles ni errores de consola. |

### 4.6 Relacion esperada entre esta estrategia y el documento de casos

El documento `casos_de_prueba_a4mpets_v2.md` contiene los casos ejecutables. Esta seccion del plan sirve como mapa de cobertura para verificar que cada modulo importante aparece en al menos una fase. Cuando se agreguen nuevos casos, deben conservar el formato por bloque y deben indicar fase, prioridad, tipo de prueba, modulo, descripcion detallada, objetivo, precondiciones, datos, pasos, resultado esperado, evidencia y resultado real.

La distribucion minima esperada es la siguiente:

| Sistema | Unitarias | Integracion | Sistema | E2E caja negra | Manual / no funcional |
|---|---:|---:|---:|---:|---:|
| Backend Laravel | Servicios, requests, permisos, formateadores, eliminaciones y transformaciones. | Endpoints API, middleware, base de datos, medios y comentarios. | Health, logs, SQLite, Cloudflare y relacion con frontend. | Flujos completos que crean y consultan datos desde navegador. | Carga con Postman, recuperacion y observabilidad. |
| Frontend Flutter | Providers, servicios Dart, validaciones locales, filtros, preferencias y audio. | Widgets con providers y repositorios mockeados. | Mapa, paneles, formularios y API real local. | Playwright sobre registro, mascotas, reportes, rutas y viaje. | Exploratoria visual, responsive, permisos de ubicacion y mensajes. |
| GraphHopper | No aplica como unidad interna del proyecto. | Contrato desde Laravel y conversion de respuesta. | Contenedor, rutas reales, instrucciones y fallos controlados. | Planeacion de viaje desde navegador. | Latencia, arranque, timeouts y estabilidad bajo repeticion. |

---

## 5. Recursos y herramientas

### 5.1 Flutter

| Herramienta | Uso exacto | Evidencia |
|---|---|---|
| `flutter analyze` | Detectar errores estaticos, imports rotos, tipos invalidos y advertencias relevantes. | Salida completa del comando. |
| `flutter test` | Ejecutar pruebas unitarias, providers y widgets. | Salida completa del comando o reporte machine si se configura despues. |
| Flutter web en Chrome | Ejecutar flujos visuales de sistema y manuales. | Capturas, consola y Network. |
| DevTools navegador | Revisar errores de JavaScript, solicitudes HTTP, CORS y tiempos de respuesta. | Captura de consola/Network o HAR. |
| Playwright | Automatizar flujos E2E de caja negra. | HTML report, screenshots y traces cuando existan. |

### 5.2 Laravel y PHP

| Herramienta | Uso exacto | Evidencia |
|---|---|---|
| `php artisan test` | Ejecutar Unit y Feature tests del backend. | Salida de PHPUnit. |
| PHPUnit Feature | Validar endpoints, middleware y base de datos de prueba. | Resultado por clase de prueba. |
| Laravel logs | Revisar excepciones, errores 500 y trazas no controladas. | Extracto de `storage/logs`. |
| Composer | Confirmar dependencias y paquetes instalados. | `composer install` o estado de `vendor`. |
| Artisan | Ejecutar health, pruebas, migraciones de test si aplica y utilidades del proyecto. | Salida del comando. |

### 5.3 Integracion y no funcionales

| Herramienta | Uso exacto | Evidencia |
|---|---|---|
| `npm run backend` | Levantar Laravel local desde scripts del repo. | Consola del proceso. |
| `npm run frontend` | Levantar Flutter web local. | URL y captura de app. |
| `npm run graphhopper` | Levantar GraphHopper con Docker Compose. | Estado del contenedor. |
| `npm run dev:cloudflare` | Levantar backend, frontend runtime y GraphHopper con tunel. | URL publica y logs Cloudflare. |
| Postman Runner | Ejecutar solicitudes repetidas para carga manual. | Reporte exportado con iteraciones. |

---

## 6. Ambiente de pruebas

| Componente | Configuracion obligatoria | Validacion antes de probar |
|---|---|---|
| Backend Laravel | Ejecutar desde `C:\projects\Web\A4MPets\backend` o mediante script npm del root. | `GET /api/health` responde JSON con `status=ok`. |
| Frontend Flutter | Ejecutar desde `C:\projects\Web\A4MPets\frontend` o mediante script npm del root. | La app carga el mapa y no muestra pantalla blanca. |
| GraphHopper | Ejecutar con Docker usando `npm run graphhopper`. | El endpoint de planeacion no falla por conexion rechazada. |
| Cloudflare Tunnel | Usar `cloudflared` mediante `npm run dev:cloudflare`. | `.runtime/cloudflare-url.txt` contiene URL `trycloudflare.com`. |
| Base de datos | Ambiente local o test DB controlada. | Usuarios QA y datos de prueba no colisionan con ejecuciones previas. |
| Navegador | Chrome desktop y viewport movil simulado. | DevTools disponible para consola y Network. |

### Datos QA controlados

| ID | Dato | Valor exacto o formato |
|---|---|---|
| D-001 | Usuario principal | Email `qa_a4m_01@example.com`, usuario `qa_a4m_01`, password `QAtest1234`. |
| D-002 | Usuario secundario | Email `qa_a4m_02@example.com`, usuario `qa_a4m_02`, password `QAtest1234`. |
| D-003 | Mascota base | Nombre `Luna QA`, nacimiento `2024-01-15`, adopcion `2024-05-20`. |
| D-004 | Coordenadas base | `3.4516,-76.5320`, `3.4570,-76.5280`, `3.4620,-76.5240`. |
| D-005 | Imagen valida | Archivo PNG o JPG pequeno, menor a 1 MB, legible por frontend y backend. |
| D-006 | Imagen invalida | Texto literal `no-es-base64` enviado como si fuera contenido de imagen. |
| D-007 | Texto de comentario | `Comentario QA generado para evidencia funcional`. |
| D-008 | Descripcion larga | Texto de al menos 500 caracteres para validar layout y persistencia. |

---

## 7. Criterios de entrada y salida

### 7.1 Criterios de entrada

| Criterio | Regla verificable |
|---|---|
| Version identificada | Antes de ejecutar, registrar branch, commit o descripcion exacta de build. |
| Ambiente levantado | Backend, frontend y GraphHopper deben estar disponibles para fases integradas. |
| Datos QA preparados | D-001 a D-008 deben existir o poder crearse durante la fase. |
| Evidencia definida | Cada fase debe tener lugar donde guardar capturas, logs y respuestas. |
| Matriz vigente | El documento de casos v2 debe ser la fuente de ejecucion. |

### 7.2 Criterios de salida

| Criterio | Regla verificable |
|---|---|
| Casos P0 | Todos los P0 ejecutados con resultado Aprobado, Fallido con defecto, o Bloqueado con causa documentada. |
| Defectos bloqueantes | No puede quedar defecto critico o alto sin decision formal del equipo. |
| Evidencia | Todo caso ejecutado debe tener evidencia suficiente para repetir o auditar el resultado. |
| Regresion | Los casos afectados por correcciones deben reejecutarse antes del cierre. |
| Informe final | Debe contener totales de aprobados, fallidos, bloqueados, no ejecutados e incidencias abiertas. |

---

## 8. Amenazas del proceso y mitigaciones

| Amenaza del proceso | Impacto posible | Mitigacion operacional |
|---|---|---|
| Cloudflare Tunnel cambia la URL publica durante la sesion | Las pruebas externas o de Postman apuntan a una URL vencida. | Registrar URL al inicio de cada ejecucion, validar health antes de cada bloque y actualizar variables de Postman. |
| GraphHopper no responde | Las pruebas de rutas y viaje quedan bloqueadas. | Separar casos de rutas del resto, registrar bloqueo y continuar con modulos no dependientes. |
| Datos QA duplicados | Registro, mascotas o reportes fallan por informacion previa. | Usar sufijos con timestamp cuando el caso lo permita y limpiar datos al cerrar fase. |
| Saturacion del equipo local | La carga con Postman produce errores no atribuibles al codigo. | Documentar hardware, cerrar aplicaciones no necesarias y aumentar iteraciones de forma gradual. |
| Cambios de codigo durante la ejecucion | Los resultados dejan de representar una version estable. | Registrar commit antes de empezar y reiniciar fase si cambia la version. |
| Evidencia incompleta | El resultado no se puede auditar ni repetir. | No cerrar casos sin captura, log, respuesta exportada o reporte de herramienta. |
| Diferencias desktop/movil | Un flujo aprobado en desktop falla en viewport movil. | Ejecutar smoke minimo en 1366x768 y 390x844 para fases visuales. |

---

## 9. Reglas de comunicacion y cierre

1. Ningun caso se marca como aprobado sin evidencia.
2. Ningun fallo se resume solamente como "no funciona"; debe incluir pasos, resultado actual, resultado esperado y evidencia.
3. Toda incidencia debe indicar modulo, severidad, ambiente, datos usados y si bloquea una fase.
4. Las palabras del dominio deben ser consistentes: se habla de peligros, reportes de peligros y niveles de peligro.
5. Si una prueba no puede ejecutarse por ambiente, se marca Bloqueada y no Fallida.
6. Si una prueba no aplica a la version evaluada, se marca No aplica con justificacion.
