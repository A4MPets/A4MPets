# Frontend Refactoring - April 2026

## Objective

Incrementally reduce overloaded classes in the Flutter frontend without changing runtime behavior.

## Scope Applied

The refactor was applied only in `frontend/lib` and focused on high-risk, high-coupling areas:

1. `user_data_sync_coordinator.dart`
2. `map_page.dart` (trip navigation internals)
3. `local_database_manager_io.dart`

## Map Page Structural Split

To reduce file size and improve readability while preserving behavior, `map_page.dart` was split into library parts:

- `lib/pages/map_page.dart`
  - Main page state orchestration and interaction flow.
- `lib/pages/map_page_components.dart`
  - `_PanelRoute` and trip panel UI components (`_TripStartPanelContent`, selectors, arrival/active widgets, shared small widgets).

This keeps private symbols scoped to the same library without changing public APIs or widget contracts.

## New Modules Introduced

### Sync Layer

- `lib/services/sync_api_gateway.dart`
  - Encapsulates fallback HTTP operations and timeout policy.
- `lib/services/sync_datetime_and_codes.dart`
  - Centralizes date serialization and backend code normalization.
- `lib/services/sync_media_resolver.dart`
  - Isolates image URL decisions and media upload resolution logic.

### Trip Navigation Layer

- `lib/services/trip_navigation_support.dart`
  - `TripWaypointProgressor`: handles consumed/reached waypoints.
  - `TripRerouteController`: encapsulates reroute gating and queueing state.

### Local Database Layer

- `lib/services/local_database_schema.dart`
  - Isolates SQL schema creation and versioned migrations from manager CRUD code.

## What Changed (Behavior-Preserving)

### `user_data_sync_coordinator.dart`

- Delegated HTTP fallback to `SyncApiGateway`.
- Delegated media path/url resolution to `SyncMediaResolver`.
- Delegated datetime and code normalization to `SyncDateTimeAndCodes`.
- Kept public class API unchanged.

### `map_page.dart`

- Replaced reroute state fields with `TripRerouteController`.
- Replaced waypoint arrival loop with `TripWaypointProgressor`.
- Removed duplicated route-editor reset logic by reusing `_clearDraftRouteVisuals()`.
- Kept visual behavior and flow contracts intact.

### `local_database_manager_io.dart`

- Moved SQL schema and migration blocks to `LocalDatabaseSchema`.
- Kept data access methods and manager public API unchanged.

## Safety Notes

- No provider names were changed.
- No route/panel widget signatures were changed.
- Existing call sites continue to use the same public methods.

## Next Refactor Steps (Recommended)

1. Split sync by entity orchestration (`UserSync`, `PetSync`, `RouteSync`, `HazardSync`).
2. Extract panel stack navigation from `map_page.dart` into a dedicated coordinator.
3. Move trip setup state and actions to a dedicated controller/provider.
4. Add focused tests for:
   - reroute queue behavior,
   - waypoint consumption,
   - schema migration paths.
