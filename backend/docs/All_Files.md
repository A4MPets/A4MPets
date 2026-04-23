# Inventario del backend

Este archivo resume la funcion de cada archivo `.php` del backend, agrupado por carpetas.

## app/

### app/Http/Controllers/

#### app/Http/Controllers/Controller.php
- Controlador base compartido por los controladores de la aplicacion.

#### app/Http/Controllers/AuthController.php
- Gestiona registro, inicio de sesion, perfil actual, cierre de sesion y actualizacion del perfil autenticado.

#### app/Http/Controllers/HazardReportController.php
- Expone el CRUD, busqueda, comentarios y sincronizacion de peligros, con resolucion de conflictos por timestamps.

#### app/Http/Controllers/MediaController.php
- Recibe imagenes en data URI o base64, las guarda por bucket y sirve archivos de media publicos.

#### app/Http/Controllers/PetController.php
- Maneja el listado, alta, edicion, borrado y sincronizacion de mascotas por usuario.

#### app/Http/Controllers/RoutePlanningController.php
- Valida solicitudes de planificacion y delega el calculo de ruta al servicio de GraphHopper.

#### app/Http/Controllers/TravelRouteController.php
- Administra el listado, alta, edicion, borrado y sincronizacion de rutas con sus puntos.

### app/Http/Middleware/

#### app/Http/Middleware/ResolveApiTokenUser.php
- Resuelve el usuario autenticado a partir del bearer token, valida vigencia y expone el token actual en la request.

### app/Models/

#### app/Models/User.php
- Modelo autenticable principal de Laravel, con relaciones hacia tokens, peligros, mascotas y rutas.

#### app/Models/ApiToken.php
- Representa los tokens API persistidos en la base de datos y su relacion con el usuario.

#### app/Models/Pet.php
- Modelo de mascotas sincronizables, vinculado a usuario y campos locales/remotos.

#### app/Models/TravelRoute.php
- Modelo de rutas guardadas; expone los puntos como JSON y sincroniza la tabla hija `route_points`.

#### app/Models/RoutePoint.php
- Representa un punto individual de una ruta con secuencia, latitud y longitud.

#### app/Models/HazardReport.php
- Modelo principal de peligros; normaliza codigos, expone comentarios como JSON y resuelve conflictos LWW.

#### app/Models/HazardComment.php
- Modelo de comentarios de peligros, con hash de contenido y normalizacion de timestamps.

#### app/Models/HazardCategory.php
- Catálogo de categorias de peligro y helper para resolver IDs por codigo.

#### app/Models/HazardRiskLevel.php
- Catálogo de niveles de riesgo y helper para resolver IDs por codigo.

#### app/Models/HazardEstimatedDuration.php
- Catálogo de duraciones estimadas y helper para resolver IDs por codigo.

### app/Providers/

#### app/Providers/AppServiceProvider.php
- Provider general de la aplicacion; actualmente no registra ni inicia servicios extra.

### app/Services/

#### app/Services/GraphHopperRoutingService.php
- Construye payloads para GraphHopper, prueba URLs de respaldo y devuelve coordenadas, distancia y duracion.

## bootstrap/

#### bootstrap/app.php
- Configura el kernel Laravel, registra rutas web/API/commands y alias de middleware.

#### bootstrap/providers.php
- Lista los service providers cargados por la aplicacion.

## config/

#### config/app.php
- Configuracion general de Laravel: nombre, entorno, locale, providers y aliases.

#### config/auth.php
- Configuracion de autenticacion, guards y providers.

#### config/cache.php
- Configuracion del sistema de cache.

#### config/cors.php
- Reglas de CORS para exponer la API al frontend.

#### config/database.php
- Configuracion de conexiones, drivers y credenciales de base de datos.

#### config/filesystems.php
- Configuracion de discos locales y publicos para archivos y media.

#### config/logging.php
- Configuracion de canales y niveles de logging.

#### config/mail.php
- Configuracion del transporte y opciones de correo.

#### config/queue.php
- Configuracion de colas y conexiones de jobs.

#### config/session.php
- Configuracion de sesiones, almacenamiento y cookies.

#### config/services.php
- Credenciales y endpoints externos, incluyendo GraphHopper y otros servicios integrados.

## database/

### database/factories/

#### database/factories/UserFactory.php
- Factory de usuarios para pruebas y seeders.

### database/migrations/

#### database/migrations/0001_01_01_000000_create_users_table.php
- Crea la tabla base de usuarios de Laravel.

#### database/migrations/0001_01_01_000001_create_cache_table.php
- Crea la tabla de cache de Laravel.

#### database/migrations/0001_01_01_000002_create_jobs_table.php
- Crea la tabla de jobs para colas.

#### database/migrations/2024_01_01_000003_create_hazard_reports_table.php
- Crea la tabla inicial de peligros.

#### database/migrations/2026_03_26_000004_upgrade_hazard_reports_schema_for_undefined_codes.php
- Actualiza el esquema de peligros para soportar codigos `undefined` y campos normalizados.

#### database/migrations/2026_04_15_000005_create_api_tokens_table.php
- Crea la tabla de tokens API usados por la autenticacion propia del backend.

#### database/migrations/2026_04_15_000006_create_pets_table.php
- Crea la tabla de mascotas sincronizables.

#### database/migrations/2026_04_15_000007_create_routes_table.php
- Crea la tabla de rutas sincronizables.

#### database/migrations/2026_04_15_000008_scope_hazard_local_ids_by_user.php
- Ajusta el alcance de los identificadores locales de peligros por usuario.

#### database/migrations/2026_04_15_000009_make_hazard_local_id_globally_unique.php
- Fuerza unicidad global para el identificador local de peligros.

#### database/migrations/2026_04_19_000010_create_hazard_comments_table.php
- Crea la tabla de comentarios de peligros.

#### database/migrations/2026_04_19_000011_normalize_hazard_classifications_to_lookup_tables.php
- Normaliza categoria, riesgo y duracion de peligros hacia tablas catalogo.

#### database/migrations/2026_04_19_000012_normalize_route_points_into_child_table.php
- Normaliza los puntos de rutas hacia la tabla hija `route_points`.

#### database/migrations/2026_04_20_000013_add_profile_photo_url_to_users_table.php
- Agrega la URL de foto de perfil al usuario.

### database/seeders/

#### database/seeders/DatabaseSeeder.php
- Seeder principal que crea datos base de ejemplo, incluido un usuario de prueba.

## public/

#### public/index.php
- Front controller de Laravel que recibe la request HTTP y despacha la aplicacion.

## routes/

#### routes/api.php
- Registra los endpoints JSON de auth, peligros, mascotas, rutas, media y planificacion de rutas.

#### routes/console.php
- Registra comandos Artisan y tareas de consola.

#### routes/web.php
- Ruta web principal que devuelve la vista de bienvenida.

## scripts/

#### scripts/test_route_plan.php
- Script de prueba rapida para llamar al endpoint de planificacion de ruta y revisar la respuesta.

## tests/

### tests/

#### tests/TestCase.php
- Clase base de pruebas para el suite de Laravel.

### tests/Feature/

#### tests/Feature/ExampleTest.php
- Prueba funcional de ejemplo que verifica que la ruta principal responde correctamente.

### tests/Unit/

#### tests/Unit/ExampleTest.php
- Prueba unitaria de ejemplo para el esqueleto de PHPUnit.
