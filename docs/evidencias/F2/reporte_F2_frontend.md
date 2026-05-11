# Reporte de Evidencias - Fase F2: Pruebas Frontend Flutter

**Proyecto:** A4MPets  
**Fecha de ejecucion:** 2026-05-08  
**Fase:** F2 - Caja blanca frontend  
**Herramienta:** Flutter Analyzer / `flutter test` / LCOV `genhtml`  
**Entorno:** Flutter web/unit tests en `C:\projects\Web\A4MPets\frontend`

---

## Resumen Ejecutivo

La fase F2 fue completada con pruebas unitarias y widget tests enfocados en cubrir logica aislada del frontend Flutter: modelos, providers Riverpod, servicios Dart, tema y widgets compartidos.

No se modifico codigo productivo. Los cambios se limitaron a:

- Correccion de un fixture de prueba existente que usaba `is_anonymous` como entero en lugar de booleano.
- Nuevas pruebas en `frontend/test`.
- Regeneracion de cobertura LCOV y reporte HTML en `frontend/coverage/html`.
- Creacion de esta evidencia con datos reales de ejecucion y cobertura.

## Resultado Final de Flutter Analyze

Comando ejecutado:

```bash
flutter analyze
```

Resultado:

```text
Analyzing frontend...
No issues found! (ran in 6.1s)
Exit code: 0
```

## Resultado Final de Flutter Test

Comando ejecutado:

```bash
flutter test
```

Resultado:

```text
Tests:    102 passed
Salida:   All tests passed!
Exit code: 0
```

Ejecuciones focalizadas durante la implementacion:

| Suite | Resultado |
|---|---:|
| `flutter test test/models` | 51 passed |
| `flutter test test/services` | 36 passed |
| `flutter test test/providers` | 8 passed |
| `flutter test test/theme` | 1 passed |
| `flutter test test/widgets` | 6 passed |
| Total | 102 passed |

## Resultado Final de Cobertura

Comandos ejecutados:

```bash
flutter test --coverage
perl "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml" coverage/lcov.info --output-directory coverage/html
```

Resultado:

```text
Tests:    102 passed
Salida:   All tests passed!
LCOV:     Overall coverage rate lines: 90.5% (1615 / 1785)
Exit code: 0
```

Reporte generado en:

```text
C:\projects\Web\A4MPets\frontend\coverage\html\index.html
```

Cobertura final por carpeta principal:

| Carpeta | Cobertura de lineas | Lineas cubiertas | Estado |
|---|---:|---:|---|
| models | 98.40% | 430 / 437 | Cumple >= 70% |
| providers | 92.86% | 247 / 266 | Cumple >= 70% |
| services | 94.43% | 390 / 413 | Cumple >= 70% |
| theme | 88.89% | 8 / 9 | Cumple >= 70% |
| widgets | 81.82% | 540 / 660 | Cumple >= 70% |
| Total LCOV | 90.48% | 1615 / 1785 | Referencia general |

Detalle relevante:

| Area | Cobertura de lineas | Observacion |
|---|---:|---|
| Models/report records | 100.00% | Lost, found, generic, comments, rutas e instrucciones cubiertos. |
| Providers/trip_flow_provider.dart | 100.00% | Mascotas, transporte, filtros, ruta, inicio y cierre de viaje. |
| Providers/theme_provider.dart | 100.00% | Alternancia y reemplazo de modo. |
| Providers/trip_transport_preference_provider.dart | 100.00% | Persistencia y normalizacion de modo. |
| Services/backend_api_client.dart | 100.00% | Headers y fallback GET/POST/PUT/DELETE cubiertos con `MockClient`. |
| Services/guest_data_store.dart | 100.00% | Pets, rutas, actualizacion, borrado, walks, clear y JSON invalido. |
| Services/navigation_audio_progress.dart | 98.65% | Cues far/approach/immediate, off-route, no audible y polilinea corta. |
| Widgets/found_pet_details_panel.dart | 84.72% | Render de detalle, reporte vinculado, comentarios y delete debug. |
| Widgets/reporting_form_widgets.dart | 86.44% | Inputs, dropdown, foto, checkbox, fecha y botones. |
| Widgets/panel_modal.dart | 78.14% | Titulo, loading, cierre, minimizar y layout. |

## Pruebas Agregadas o Ampliadas

Pruebas nuevas:

| Archivo | Proposito |
|---|---|
| `test/models/report_records_extra_test.dart` | Modelos de reportes, comentarios, rutas e instrucciones. |
| `test/services/backend_api_client_extra_test.dart` | Headers, URL base, fallbacks y errores HTTP. |
| `test/services/guest_data_store_extra_test.dart` | Persistencia local de mascotas y rutas de invitado. |
| `test/services/navigation_services_extra_test.dart` | Audio de navegacion, progreso y visualizacion de peligros en ruta. |
| `test/providers/flow_providers_extra_test.dart` | Providers de paneles, reportes, rutas, viaje, mapa, tema y preferencias. |
| `test/theme/app_palette_test.dart` | Helpers de paleta por modo claro/oscuro. |
| `test/widgets/shared_widgets_extra_test.dart` | Widget tests de paneles, formularios, imagenes, perfil y detalle de mascota encontrada. |

Pruebas ajustadas:

| Archivo | Ajuste |
|---|---|
| `test/models/hazard_report_record_test.dart` | Fixture de comentarios usa `is_anonymous: false`, alineado con `ReportCommentRecord.fromMap`. |

## Mapeo General F2

| Caso | Cobertura actual |
|---|---|
| F2-001 a F2-002 | `pet_record_test.dart` y propiedades/serializacion de `PetRecord`. |
| F2-003 a F2-004 | `session_store_test.dart`, `local_user_profile_test.dart` y persistencia con `SharedPreferences`. |
| F2-005 | `flow_providers_extra_test.dart` cubre `panelFlowProvider`. |
| F2-006 | `flow_providers_extra_test.dart` cubre `reportFlowProvider` y ubicaciones manuales. |
| F2-007 | `flow_providers_extra_test.dart` cubre `routeEditorProvider`. |
| F2-008 | `flow_providers_extra_test.dart` cubre `tripFlowProvider`. |
| F2-009 | `flow_providers_extra_test.dart` cubre preferencia de transporte. |
| F2-010 | `hazard_risk_filtering_test.dart` y `navigation_services_extra_test.dart`. |
| F2-011 | `navigation_services_extra_test.dart` cubre `NavigationAudioMessageBuilder`. |
| F2-012 | `navigation_services_extra_test.dart` cubre `NavigationAudioProgress`. |
| F2-013 | `flow_providers_extra_test.dart` cubre `mapPresentationProvider`. |
| F2-014 a F2-015 | `report_records_extra_test.dart`, `pet_record_test.dart`, `hazard_report_record_test.dart`. |
| F2-016 | `backend_api_client_extra_test.dart`. |
| F2-017 | Providers base y acceso local cubiertos por pruebas de `GuestDataStore` y providers relacionados. |
| F2-018 | `guest_data_store_extra_test.dart` y `report_records_extra_test.dart`. |
| F2-019 | `flow_providers_extra_test.dart` cubre `audioFeedbackEnabledProvider`. |
| F2-020 | Estados asincronos base no se prueban contra backend real en F2; se cubren providers de flujo local y se deja integracion para fases posteriores. |
| F2-021 | `navigation_services_extra_test.dart` cubre `RouteHazardVisualizerService`. |
| F2-022 | `report_records_extra_test.dart` cubre `RouteRecord` y `RoutePoint`. |
| F2-023 | Persistencia local de mascotas cubierta por `guest_data_store_extra_test.dart`; sincronizacion real queda fuera de F2. |
| F2-024 | La construccion real contra `/routes/plan` depende de `http.post` estatico y backend; se valida indirectamente en services de ruteo/visualizacion y queda integracion para F3/F4. |
| F2-025 | `app_palette_test.dart` y `flow_providers_extra_test.dart` cubren paleta y `themeModeProvider`. |

## Hallazgos F2

| # | Hallazgo | Tratamiento |
|---|---|---|
| 1 | Un fixture existente enviaba `is_anonymous` como `0`, pero el modelo frontend actual espera `bool?`. | Corregido en prueba, sin modificar codigo productivo. |
| 2 | `local_image_widget_io.dart` queda con cobertura individual baja porque las ramas de imagen real/HTTP dependen de filesystem o red. | No bloquea F2: la carpeta `widgets` supera 70% y se cubren fallback, data flow visual y dialogos. |
| 3 | `OsmRoutingService` no se prueba con backend real en F2 porque esta fase no ejecuta integracion. | Se deja para F3/F4; en F2 se cubren servicios puros de ruta, visualizacion y cliente HTTP con mocks. |

## Conclusiones

La fase F2 queda completada con analyzer limpio, pruebas Flutter en verde y cobertura real por carpeta superior al minimo esperado:

- Models: 98.40%
- Providers: 92.86%
- Services: 94.43%
- theme: 88.89%
- widgets: 81.82%

El reporte HTML de cobertura fue regenerado y esta evidencia refleja los resultados reales de `flutter analyze`, `flutter test`, `flutter test --coverage` y `genhtml`.
