# Frontend Inventory

This document summarizes the purpose of each frontend `.dart` file, grouped by folder.

## lib/

### main.dart
- Boots the Flutter app, configures the system UI overlays, and mounts `MyApp` inside `ProviderScope`.

### theme/

#### theme/app_palette.dart
- Centralizes the visual palette and exposes color helpers for light and dark surfaces.

### providers/

#### providers/theme_provider.dart
- Defines the global theme controller used to read, set, and toggle dark mode.

#### providers/async_list_controller.dart
- Provides the shared AsyncNotifier base used by list-oriented controllers with reload and optional background refresh behavior.

#### providers/local_data_providers.dart
- Declares Riverpod providers for local persistence, media storage, sync coordination, profile loading, pets, routes, hazards, and report collections.

### repositories/

#### repositories/user_local_repository.dart
- Encapsulates high-level access to the backend and local database for auth, profile, pets, routes, hazards, and report workflows.

### models/

#### models/local_user_profile.dart
- Models the local user profile, authenticated or guest state, and local serialization helpers.

#### models/pet_record.dart
- Represents a locally stored pet with sync metadata and persistence mapping.

#### models/route_record.dart
- Represents a saved route and defines `RoutePoint` conversion helpers for JSON, local storage, and `LatLng`.

#### models/hazard_report_record.dart
- Models a hazard report, its local comments, and label helpers for category, duration, and risk.

#### models/lost_pet_report_record.dart
- Represents a lost-pet report stored locally and mapped to backend sync payloads.

#### models/found_pet_report_record.dart
- Represents a found-pet report stored locally and mapped to backend sync payloads.

#### models/generic_report_record.dart
- Represents a generic report with location, risk level, media, and sync metadata.

#### models/colored_route_segment.dart
- Defines the map value object used to render route segments with hazard-aware colors.

### services/

#### services/backend_api_client.dart
- Wraps backend HTTP calls with fallback base URLs, JSON headers, and active endpoint tracking.

#### services/local_database_manager.dart
- Declares the cross-platform local persistence contract exposed to repositories and providers.

#### services/local_database_manager_io.dart
- Implements local persistence with SQLite on mobile and desktop platforms.

#### services/local_database_manager_web.dart
- Implements the web local database adapter with `SharedPreferences` and JSON blobs.

#### services/local_database_schema.dart
- Defines local database table creation and migrations for users, pets, routes, hazards, and route caches.

#### services/local_media_storage_service.dart
- Provides the conditional export for platform-specific local media storage.

#### services/local_media_storage_service_io.dart
- Picks images on IO platforms and copies them into the app-local media buckets.

#### services/local_media_storage_service_web.dart
- Picks images on web and returns data URIs for immediate preview and sync.

#### services/media_source_encoder.dart
- Provides the conditional export for platform-specific media source encoding.

#### services/media_source_encoder_io.dart
- Converts local image paths into data URIs for preview and sync on IO platforms.

#### services/media_source_encoder_web.dart
- Provides the lightweight web encoder for sources that already behave like data URIs.

#### services/sync_api_gateway.dart
- Wraps backend sync calls with shorter timeout behavior.

#### services/sync_datetime_and_codes.dart
- Normalizes sync timestamps and code values before sending them to the backend.

#### services/sync_media_resolver.dart
- Resolves local media sources into sync-ready data URIs or remote URLs.

#### services/trip_navigation_support.dart
- Groups waypoint progress and reroute decision helpers for active trips.

#### services/user_data_sync_coordinator.dart
- Coordinates push and pull sync cycles for profile, pets, routes, hazards, and report domains.

#### services/osm_routing_service.dart
- Requests route planning from the backend and falls back across configured endpoints when needed.

#### services/route_hazard_visualizer_service.dart
- Splits route polylines into colored segments based on hazard overlap.

### widgets/

#### widgets/auth_panels.dart
- Contains the login and registration panels with validation, autofill, and panel switching callbacks.

#### widgets/hazard_comments_panel.dart
- Displays hazard comments and lets the user submit new comments through the hazards controller.

#### widgets/hazard_details_panel.dart
- Renders hazard details, the evidence photo preview, and the entry point to the comments panel.

#### widgets/hazard_layers_panel.dart
- Controls dark mode and visibility toggles for hazard circles and report layers.

#### widgets/hazard_reporting_panel.dart
- Exposes the hazard reporting form with location, category, duration, risk, and optional evidence media.

#### widgets/lost_pet_reporting_panel.dart
- Exposes the lost-pet reporting form and draft location preview state.

#### widgets/lost_pet_details_panel.dart
- Renders the details view for a lost-pet report.

#### widgets/found_pet_reporting_panel.dart
- Exposes the found-pet reporting form and draft location preview state.

#### widgets/found_pet_details_panel.dart
- Renders the details view for a found-pet report.

#### widgets/generic_report_panel.dart
- Exposes the generic report form with category-neutral details and risk selection.

#### widgets/generic_report_details_panel.dart
- Renders the details view for a generic report.

#### widgets/location_picker_widget.dart
- Reusable location picker widget for report forms that need current or map-selected coordinates.

#### widgets/report_type_selector_panel.dart
- Lets the user choose which report flow to open from the map overlay.

#### widgets/reporting_form_widgets.dart
- Shares smaller form widgets used across the reporting panels.

#### widgets/map_widget.dart
- Wraps `flutter_map` and renders user location, routes, editable points, hazards, report markers, and map controls.

#### widgets/panel_modal.dart
- Defines the reusable floating modal panel shell with anchoring, animation, scroll behavior, and close or back controls.

#### widgets/pet_management_panels.dart
- Contains the pet management panel and the add or edit pet form.

#### widgets/profile_menu_panel.dart
- Renders the profile menu with auth actions, avatar editing, and navigation to pet and route management.

#### widgets/route_management_panels.dart
- Contains the route management view, route cards, and the add or edit route form.

### widgets/shared/

#### widgets/shared/user_identity_header.dart
- Renders the user avatar and name, with optional profile image editing entry points.

#### widgets/shared/local_image_widget.dart
- Provides the conditional export for platform-specific local image rendering.

#### widgets/shared/local_image_widget_io.dart
- Renders local, embedded, and remote images on IO platforms.

#### widgets/shared/local_image_widget_web.dart
- Renders embedded and remote images on web platforms.

### pages/

#### pages/map_page.dart
- Hosts the main app screen and coordinates map state, panel navigation, trip setup, auth, and reporting workflows.

#### pages/map_page_auth.dart
- Encapsulates auth and profile-related panel flows inside `MapPage`.

#### pages/map_page_components.dart
- Defines shared `MapPage` components, panel route models, and trip-related UI building blocks.

#### pages/map_page_hazards.dart
- Handles hazard panel opening, filtering state, hazard focus behavior, and hazard layer settings.

#### pages/map_page_panels.dart
- Manages the panel stack, overlay transitions, close behavior, and loading state resolution.

#### pages/map_page_reports.dart
- Handles report selector flows, report-specific map selection state, and report detail panel transitions.

#### pages/map_page_routes.dart
- Encapsulates route management, route editing, draft route visuals, and persistence callbacks.

#### pages/map_page_trip.dart
- Encapsulates trip selection, trip start, progress tracking, rerouting, and trip completion flows.

## test/

### test/widget_test.dart
- Verifies that `MyApp` boots correctly inside `ProviderScope` and that the theme controller updates state as expected.

### test/trip_navigation_support_test.dart
- Covers waypoint consumption and reroute queue behavior for the trip navigation support helpers.
