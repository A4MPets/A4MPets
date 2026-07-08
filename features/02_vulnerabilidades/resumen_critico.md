# Resumen critico de vulnerabilidades

## 1. Tokens de sesion sin caducidad real

**Estado:** mitigado en codigo. Los tokens emitidos por login y registro ahora guardan `expires_at`, la respuesta HTTP informa `expires_at` al cliente y el middleware rechaza y elimina tokens vencidos o legacy sin caducidad.

**Evidencia en codigo:** `backend/app/Services/Auth/AuthTokenService.php` asigna `expires_at` con base en `auth.api_token_lifetime_minutes`; `backend/app/Http/Middleware/ResolveApiTokenUser.php` solo acepta tokens con `expires_at` futuro; `backend/app/Http/Controllers/AuthController.php` devuelve `expires_at` junto al bearer token.

**Riesgo residual:** un token comprometido sigue permitiendo acceso hasta su vencimiento o logout, pero ya no queda acceso persistente indefinido.

## 2. Exposicion publica de recursos personales y geolocalizados

**Impacto:** recursos sensibles se pueden leer sin autenticar, incluyendo rutas de viaje, mascotas y reportes con ubicacion, comentarios y en varios casos datos de usuario.

**Evidencia en codigo:** `backend/routes/api.php` deja `GET /pets/{pet}`, `GET /routes/{route}`, `GET /hazards/{hazardReport}`, `GET /lost-pet-reports/{lostPetReport}`, `GET /found-pet-reports/{foundPetReport}` y `GET /generic-reports/{genericReport}` sin middleware de autenticacion. Los controladores devuelven el modelo o relaciones cargadas directamente.

**Riesgo de negocio:** un tercero puede enumerar IDs y extraer inventario de mascotas, movimientos, ubicaciones y relaciones entre usuarios y reportes.

## 3. Media publica con direccionamiento predecible y retencion larga

**Impacto:** imagenes subidas quedan servidas por URL publica con cache de un año y sin validacion de ownership al leerlas.

**Evidencia en codigo:** `backend/app/Http/Controllers/MediaController.php` expone `GET /api/media/{bucket}/{fileName}` sin autenticacion, con `Cache-Control: public, max-age=31536000, immutable`.

**Riesgo de negocio:** fotos de perfil, mascotas o reportes pueden difundirse fuera de contexto durante largo tiempo, aun si el usuario deja de esperar visibilidad pública.

## 4. Carga de media sin limite visible de tamano

**Impacto:** el endpoint de upload procesa `image_data` como string base64 y decodifica en memoria sin un limite de tamano observable en la validacion.

**Evidencia en codigo:** `backend/app/Http/Controllers/MediaController.php` valida solo que `image_data` sea string y luego ejecuta `base64_decode` sobre el contenido recibido.

**Riesgo de negocio:** un actor puede forzar consumo alto de CPU, RAM y almacenamiento, degradando o bloqueando el backend y afectando disponibilidad.

## 5. Fuga de informacion interna en errores de ruteo

**Impacto:** cuando falla la planeacion, la respuesta devuelve `error` con el mensaje crudo de la excepcion.

**Evidencia en codigo:** `backend/app/Http/Controllers/RoutePlanningController.php` captura `Throwable` y responde `502` con `error => $e->getMessage()`.

**Riesgo de negocio:** se pueden exponer rutas internas, nombres de servicios, detalles de red, timeouts o configuracion de GraphHopper al cliente final.

## 6. Lectura publica de rutas guardadas ajenas

**Impacto:** cualquier ruta puede consultarse por ID sin comprobacion de ownership.

**Evidencia en codigo:** `backend/app/Http/Controllers/TravelRouteController.php` expone `show(TravelRoute $route)` sin verificar que la ruta pertenezca al usuario autenticado.

**Riesgo de negocio:** se filtran itinerarios, puntos guardados y posibles patrones de movilidad del usuario.

## 7. Lectura publica de mascotas con datos sensibles

**Impacto:** la ficha de una mascota puede consultarse por ID sin autenticar.

**Evidencia en codigo:** `backend/app/Http/Controllers/PetController.php` expone `show(Pet $pet)` sin middleware ni control de ownership.

**Riesgo de negocio:** se puede rastrear propiedad de mascotas, fotos, fechas y estados de adopcion o perdida.

## 8. Lectura publica de reportes con geolocalizacion y contexto social

**Impacto:** reportes de peligro, perdidos, encontrados y genericos se pueden leer sin autenticar, incluyendo comentarios y relaciones cargadas.

**Evidencia en codigo:** `backend/routes/api.php` deja los `show` y `comments` abiertos para hazards, lost-pet-reports, found-pet-reports y generic-reports. Los controladores cargan `comments`, `comments.user` y en algunos casos `user` directamente.

**Riesgo de negocio:** un tercero puede mapear zonas sensibles, horarios de actividad, autores de reportes y patrones de uso de la comunidad.

## 9. Autenticacion por nombre o correo sin friccion adicional

**Impacto:** el login acepta `email` o `name` en el mismo campo y no se observa limitacion de intentos ni otra barrera operativa visible.

**Evidencia en codigo:** `backend/app/Http/Controllers/AuthController.php` busca por `email` u `name` y `backend/app/Http/Requests/Auth/LoginRequest.php` no impone mecanismos antifuerza bruta.

**Riesgo de negocio:** aumenta la superficie para credential stuffing, enumeracion de cuentas y ataque de contrasenas contra usuarios reales.

## 10. Perfil editable con URL de foto sin validacion fuerte de origen

**Impacto:** el perfil acepta una `profile_photo_url` string directamente.

**Evidencia en codigo:** `backend/app/Http/Controllers/AuthController.php` asigna `profile_photo_url` desde el payload y `backend/app/Http/Requests/Auth/UpdateProfileRequest.php` solo valida longitud y tipo string.

**Riesgo de negocio:** se pueden introducir referencias arbitrarias a recursos externos o inconsistentes que afecten identidad visual y confianza.

## 11. Divulgacion de datos al publicarse como modelos completos

**Impacto:** varios controladores retornan modelos Eloquent directamente, lo que expone atributos del registro completos y dependencias cargadas.

**Evidencia en codigo:** `PetController`, `TravelRouteController`, `LostPetReportController`, `FoundPetReportController`, `GenericReportController` y `HazardReportController` responden con `data` conteniendo el modelo o relaciones cargadas.

**Riesgo de negocio:** aumenta la probabilidad de exponer campos que hoy parecen inocuos pero que mañana se convierten en datos sensibles o de alto valor.

## 12. Posible abuso por recursos publicos no autentificados

**Impacto:** varias superficies críticas del sistema se consumen sin autenticar y sin evidencia de throttling por ruta visible en el codigo revisado.

**Evidencia en codigo:** `backend/routes/api.php` deja públicas lecturas de entidades, media y salud, y los controladores no muestran limitacion de frecuencia.

**Riesgo de negocio:** scraping, sobrecarga de backend, extracción masiva de datos y exposición del inventario comunitario de A4MPets.
