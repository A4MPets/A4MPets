# Inventario del frontend

Este archivo resume la funcion de cada archivo `.dart` del frontend, agrupado por carpetas.

## lib/

### main.dart
- Arranca la app Flutter, configura la barra del sistema y monta MapPage dentro de ProviderScope.

### theme/

#### theme/app_palette.dart
- Centraliza la paleta visual de la app y expone helpers de color para modo claro y oscuro.

### providers/

#### providers/theme_provider.dart
- Define el estado global simple que controla si la interfaz usa modo oscuro.

#### providers/local_data_providers.dart
- Declara los providers de Riverpod para base local, almacenamiento de media, sincronizacion, perfil, mascotas, rutas y peligros.

### repositories/

#### repositories/user_local_repository.dart
- Encapsula el acceso de alto nivel al backend y a la base local para login, registro, cierre de sesion, perfil, mascotas, rutas y reportes de peligro.

### models/

#### models/local_user_profile.dart
- Modela el usuario local, su estado autenticado o invitado y su serializacion hacia y desde la base local.

#### models/pet_record.dart
- Representa una mascota local con metadatos de sincronizacion y mapeo a persistencia.

#### models/route_record.dart
- Representa una ruta guardada y define RoutePoint para convertir puntos entre JSON, base local y LatLng.

#### models/hazard_report_record.dart
- Modela un reporte de peligro, sus comentarios locales y los helpers para etiquetas de categoria, duracion y riesgo.

#### models/colored_route_segment.dart
- Define el valor que usa el mapa para pintar segmentos de ruta con color y estado de peligro.

### services/

#### services/backend_api_client.dart
- Envuelve las llamadas HTTP al backend con URLs de respaldo, headers JSON y seguimiento de la base activa.

#### services/local_database_manager.dart
- Implementa la persistencia local con SQLite en escritorio y movil, incluyendo tablas, consultas y migraciones.

#### services/local_database_manager_io.dart
- Adaptador para IO que expone el mismo gestor local usando SQLite y sqflite/sqflite_ffi.

#### services/local_database_manager_web.dart
- Adaptador web del gestor local, respaldado por SharedPreferences y JSON en lugar de SQLite.

#### services/local_database_schema.dart
- Define la creacion de tablas y las migraciones de la base local para usuarios, mascotas, rutas, peligros y cache de rutas.

#### services/local_media_storage_service.dart
- Archivo de exportacion condicional para el servicio de media local segun la plataforma.

#### services/local_media_storage_service_io.dart
- Permite elegir imagenes en IO y copiar las fotos en un bucket local de la app para mascotas, peligros y perfil.

#### services/local_media_storage_service_web.dart
- Permite elegir imagenes en web y devolverlas como data URI para uso inmediato sin filesystem local.

#### services/media_source_encoder.dart
- Exportacion condicional para convertir fuentes de imagen segun la plataforma.

#### services/media_source_encoder_io.dart
- Convierte rutas locales de imagen en data URI para poder sincronizarlas o previsualizarlas.

#### services/media_source_encoder_web.dart
- Version web minima del codificador de imagen, pensada para fuentes ya representadas como data URI.

#### services/sync_api_gateway.dart
- Capa delgada sobre BackendApiClient para peticiones de sincronizacion con timeout corto.

#### services/sync_datetime_and_codes.dart
- Normaliza fechas y codigos de riesgo, categoria y duracion antes de enviar datos al backend.

#### services/sync_media_resolver.dart
- Resuelve imagenes locales a data URI o URL remota para sincronizar avatares y evidencias al backend.

#### services/trip_navigation_support.dart
- Agrupa la logica de progreso de waypoints y control de reruteo para viajes en curso.

#### services/user_data_sync_coordinator.dart
- Coordina la sincronizacion push/pull de perfil, mascotas, rutas y peligros, con auto-sync y cola de reintentos.

#### services/osm_routing_service.dart
- Calcula rutas consultando el backend y usa fallback local de endpoints cuando es necesario.

#### services/route_hazard_visualizer_service.dart
- Analiza una polilinea de ruta y la divide en segmentos coloreados segun si intersecta o no con peligros.

### widgets/

#### widgets/auth_panels.dart
- Contiene los paneles de inicio de sesion y registro con validacion, autofill y cambio entre formularios.

#### widgets/hazard_comments_panel.dart
- Muestra y permite publicar comentarios de un peligro usando el estado local y el provider de peligros.

#### widgets/hazard_details_panel.dart
- Presenta el detalle de un peligro, su foto y acceso al panel de comentarios.

#### widgets/hazard_layers_panel.dart
- Controla el modo oscuro y la visibilidad de los circulos de peligros por nivel de riesgo.

#### widgets/hazard_reporting_panel.dart
- Expone el formulario para reportar un peligro con ubicacion, categoria, duracion, riesgo y foto opcional.

#### widgets/map_widget.dart
- Envuelve flutter_map y renderiza ubicacion actual, rutas, puntos editables, circulos de peligro y controles del mapa.

#### widgets/panel_modal.dart
- Define el contenedor modal reutilizable para paneles flotantes con anclaje, animacion, scroll y boton de cierre o regreso.

#### widgets/pet_management_panels.dart
- Contiene el panel de gestion de mascotas y el formulario para crear o editar una mascota.

#### widgets/profile_menu_panel.dart
- Muestra el menu de perfil con login, registro, cierre de sesion, edicion de avatar y accesos a gestion de mascotas y rutas.

#### widgets/route_management_panels.dart
- Contiene la vista de gestion de rutas, las tarjetas de ruta y el formulario para agregar o editar rutas.

### widgets/shared/

#### widgets/shared/user_identity_header.dart
- Renderiza el avatar y el nombre del usuario, con acceso opcional para editar la imagen de perfil.

#### widgets/shared/local_image_widget.dart
- Exportacion condicional del widget compartido para mostrar imagenes locales, remotas o embebidas.

#### widgets/shared/local_image_widget_io.dart
- Implementacion IO del widget de imagen local, con soporte para archivos, data URI y URLs remotas.

#### widgets/shared/local_image_widget_web.dart
- Implementacion web del widget de imagen local, centrada en data URI y URLs remotas.

### pages/

#### pages/map_page.dart
- Es la pantalla principal de la app: coordina el mapa, la pila de paneles, el estado de rutas, peligros, viajes y autenticacion.

#### pages/map_page_auth.dart
- Separa la logica de autenticacion y perfil dentro de MapPage, incluyendo login, registro, logout y paneles de mascotas.

#### pages/map_page_components.dart
- Agrupa componentes y estructuras compartidas por los paneles de MapPage, como rutas de panel y widgets de viaje.

#### pages/map_page_hazards.dart
- Encapsula la apertura de paneles de peligros, su filtrado y el analisis visual de ruta contra hazards.

#### pages/map_page_panels.dart
- Maneja la pila de paneles, el overlay animado, el boton de volver/cerrar y el estado de carga por panel.

#### pages/map_page_routes.dart
- Encapsula la gestion de rutas: abrir, editar, borrar, mostrar en mapa y actualizar el borrador de ruta.

#### pages/map_page_trip.dart
- Contiene el flujo de viaje: seleccion de ruta y mascotas, inicio, seguimiento, reruteo y finalizacion del trayecto.

## test/

### test/widget_test.dart
- Es el test de smoke por defecto de Flutter; actualmente sigue el ejemplo base del contador y sirve como punto de partida para pruebas de UI.
