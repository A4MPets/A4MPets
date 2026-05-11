import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/route_record.dart';
import 'package:frontend/providers/audio_feedback_settings_provider.dart';
import 'package:frontend/providers/map_presentation_provider.dart';
import 'package:frontend/providers/panel_flow_provider.dart';
import 'package:frontend/providers/report_flow_provider.dart';
import 'package:frontend/providers/route_editor_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/providers/trip_flow_provider.dart';
import 'package:frontend/providers/trip_transport_preference_provider.dart';
import 'package:frontend/theme/app_palette.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  ProviderContainer container() {
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('panelFlowProvider (F2-005-extra)', () {
    test('push, replaceTop, minimize, removeWhere, pop y clear', () {
      final ProviderContainer c = container();
      final PanelFlowController controller = c.read(panelFlowProvider.notifier);

      expect(c.read(panelFlowProvider).hasOpenPanels, isFalse);
      controller.push(PanelKind.login);
      controller.push(PanelKind.reportHazard);
      expect(
        c.read(panelFlowProvider).activePanel?.kind,
        equals(PanelKind.reportHazard),
      );
      expect(c.read(panelFlowProvider).transitionSeed, equals(2));

      controller.replaceTop(PanelKind.hazardDetails);
      expect(
        c.read(panelFlowProvider).activePanel?.kind,
        equals(PanelKind.hazardDetails),
      );

      controller.toggleActiveMinimized();
      expect(c.read(panelFlowProvider).activePanel?.isMinimized, isTrue);
      controller.setActiveMinimized(false);
      expect(c.read(panelFlowProvider).activePanel?.isMinimized, isFalse);

      controller.removeWhere(
        (PanelEntry panel) => panel.kind == PanelKind.login,
      );
      expect(c.read(panelFlowProvider).stack, hasLength(1));
      controller.pop();
      controller.pop();
      expect(c.read(panelFlowProvider).stack, isEmpty);

      controller.push(PanelKind.profile);
      controller.clear();
      expect(c.read(panelFlowProvider).stack, isEmpty);
    });
  });

  group('reportFlowProvider (F2-006-extra)', () {
    test('selecciona ubicaciones, drafts y visibilidad de capas', () {
      final ProviderContainer c = container();
      final ReportFlowController controller = c.read(
        reportFlowProvider.notifier,
      );
      const LatLng hazardLocation = LatLng(3.4516, -76.532);

      controller.beginLocationSelection(ReportMapSelectionContext.hazard);
      expect(c.read(reportFlowProvider).isSelectingHazardLocationOnMap, isTrue);
      controller.setManualLocation(
        ReportMapSelectionContext.hazard,
        hazardLocation,
      );
      expect(
        c.read(reportFlowProvider).manualHazardLocation,
        equals(hazardLocation),
      );
      expect(c.read(reportFlowProvider).activeSelectionContext, isNull);

      controller.setManualLocation(
        ReportMapSelectionContext.lostPet,
        const LatLng(3.45, -76.53),
      );
      controller.setManualLocation(
        ReportMapSelectionContext.foundPet,
        const LatLng(3.46, -76.54),
      );
      controller.setManualLocation(
        ReportMapSelectionContext.generic,
        const LatLng(3.47, -76.55),
      );
      controller.updateHazardDraft(
        const ReportDraftState(
          location: LatLng(1, 2),
          impactRadiusMeters: 100,
          riskLevelCode: 'high',
        ),
      );
      controller.updateGenericDraft(
        const ReportDraftState(
          location: LatLng(2, 3),
          impactRadiusMeters: 80,
          riskLevelCode: 'medium',
        ),
      );
      controller.setHazardRiskVisibility(low: false, medium: true, high: false);
      controller.setReportLayerVisibility(
        lostPets: false,
        foundPets: true,
        generic: false,
      );

      final ReportFlowState state = c.read(reportFlowProvider);
      expect(state.manualLostPetLocation?.latitude, equals(3.45));
      expect(state.manualFoundPetLocation?.latitude, equals(3.46));
      expect(state.manualGenericReportLocation?.latitude, equals(3.47));
      expect(state.hazardDraftPreview?.riskLevelCode, equals('high'));
      expect(state.genericReportDraftPreview?.riskLevelCode, equals('medium'));
      expect(state.showLowRiskHazardCircles, isFalse);
      expect(state.showHighRiskHazardCircles, isFalse);
      expect(state.showLostPetReports, isFalse);
      expect(state.showGenericReports, isFalse);

      controller.clearReportingDrafts();
      expect(c.read(reportFlowProvider).manualHazardLocation, isNull);
      expect(c.read(reportFlowProvider).hazardDraftPreview, isNull);
    });
  });

  group('routeEditorProvider (F2-007-extra)', () {
    test('agrega, edita y limpia borrador de ruta', () {
      final ProviderContainer c = container();
      final RouteEditorController controller = c.read(
        routeEditorProvider.notifier,
      );
      const LatLng p1 = LatLng(3.4516, -76.532);
      const LatLng p2 = LatLng(3.457, -76.528);

      controller.addDraftPoint(p1);
      controller.addDraftPoint(p2);
      controller.updateDraftPoint(0, const LatLng(3.45, -76.53));
      controller.updateDraftPoint(-1, const LatLng(0, 0));
      controller.setTool(RouteMapTool.editPoint);
      controller.selectPointForEdit(1);
      controller.selectRoute(99);
      controller.startEditingRoute(routeId: 99, name: 'Ruta QA');
      controller.setPolyline(
        polyline: <LatLng>[p1, p2],
        waypoints: <LatLng>[p1],
      );

      final RouteEditorState state = c.read(routeEditorProvider);
      expect(state.draftRoutePoints, hasLength(2));
      expect(state.draftRoutePoints.first.latitude, equals(3.45));
      expect(state.activeTool, equals(RouteMapTool.editPoint));
      expect(state.selectedPointIndexForEdit, equals(1));
      expect(state.selectedRouteId, equals(99));
      expect(state.editingRouteName, equals('Ruta QA'));
      expect(state.draftRoutePolyline, hasLength(2));

      controller.setTool(RouteMapTool.addPoint);
      expect(c.read(routeEditorProvider).selectedPointIndexForEdit, isNull);
      controller.clearDraft();
      expect(c.read(routeEditorProvider).draftRoutePoints, isEmpty);
      expect(c.read(routeEditorProvider).editingRouteId, isNull);
    });
  });

  group('tripFlowProvider (F2-008-extra)', () {
    test('maneja mascotas, filtros, ruta, inicio y fin de viaje', () {
      final ProviderContainer c = container();
      final TripFlowController controller = c.read(tripFlowProvider.notifier);
      final RouteRecord route = RouteRecord(
        id: 1,
        name: 'Ruta QA',
        points: const <RoutePoint>[
          RoutePoint(latitude: 3.45, longitude: -76.53),
          RoutePoint(latitude: 3.46, longitude: -76.54),
        ],
        syncStatus: 'synced',
        lastModifiedAt: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        needsSync: false,
      );

      controller.startTrip();
      expect(c.read(tripFlowProvider).startErrorText, contains('ruta valida'));

      controller.setSelectedPets(<int>{1, 2});
      controller.togglePet(2);
      controller.togglePet(3);
      controller.setTransport(TripTransportMethod.vehicle);
      controller.toggleHazardRiskFilter('high', false);
      controller.toggleHazardRiskFilter('other', true);
      controller.selectRoute(route);
      controller.updateUserLocation(
        location: const LatLng(3.45, -76.53),
        isLoading: false,
        errorText: null,
      );
      controller.startTrip();

      final TripFlowState active = c.read(tripFlowProvider);
      expect(active.selectedPetIds, equals(<int>{1, 3}));
      expect(active.selectedTransport, equals(TripTransportMethod.vehicle));
      expect(active.selectedHazardRiskFilters, isNot(contains('high')));
      expect(active.selectedHazardRiskFilters, contains('other'));
      expect(active.remainingWaypoints, hasLength(2));
      expect(active.isTripActive, isTrue);
      expect(active.latestUserLocation?.latitude, equals(3.45));

      controller.finishTrip();
      expect(c.read(tripFlowProvider).isTripActive, isFalse);
      expect(c.read(tripFlowProvider).selectedRoute, isNull);
    });
  });

  group('theme y preferencias persistidas (F2-009/F2-019/F2-025-extra)', () {
    test('themeModeProvider alterna modo', () {
      final ProviderContainer c = container();
      final ThemeModeController controller = c.read(themeModeProvider.notifier);

      expect(c.read(themeModeProvider), isTrue);
      controller.setThemeMode(false);
      expect(c.read(themeModeProvider), isFalse);
      controller.toggle();
      expect(c.read(themeModeProvider), isTrue);
    });

    test('tripTransportPreferenceProvider normaliza y persiste modo', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'trip_transport_method': 'vehicle',
      });
      final ProviderContainer c = container();

      expect(c.read(tripTransportPreferenceProvider), equals('walking'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(tripTransportPreferenceProvider), equals('vehicle'));

      await c
          .read(tripTransportPreferenceProvider.notifier)
          .setTransportName('bike');
      expect(c.read(tripTransportPreferenceProvider), equals('walking'));
      await c
          .read(tripTransportPreferenceProvider.notifier)
          .setTransportName('vehicle');
      expect(c.read(tripTransportPreferenceProvider), equals('vehicle'));
    });

    test(
      'audioFeedbackEnabledProvider carga default y persiste cambios',
      () async {
        final ProviderContainer c = container();

        expect(c.read(audioFeedbackEnabledProvider), isTrue);
        await c.read(audioFeedbackEnabledProvider.notifier).setEnabled(false);
        expect(c.read(audioFeedbackEnabledProvider), isFalse);

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('audio_feedback_enabled'), isFalse);
      },
    );
  });

  group('mapPresentationProvider (F2-013-extra)', () {
    test(
      'deriva estado desde paneles, seleccion de reporte y viaje activo',
      () {
        final ProviderContainer c = container();

        c.read(panelFlowProvider.notifier).push(PanelKind.tripActive);
        c
            .read(reportFlowProvider.notifier)
            .beginLocationSelection(ReportMapSelectionContext.lostPet);
        c
            .read(tripFlowProvider.notifier)
            .replace(
              const TripFlowState(
                isTripActive: true,
                latestUserLocation: LatLng(3.45, -76.53),
              ),
            );

        final MapPresentationState state = c.read(mapPresentationProvider);
        expect(state.hideDefaultControls, isTrue);
        expect(state.keepReportDangerVisible, isTrue);
        expect(state.keepModifyLocationVisible, isTrue);
        expect(state.isSelectingReportLocation, isTrue);
        expect(state.reportSelectionHintText, contains('mascota perdida'));
        expect(state.reportSelectionHintColor, equals(AppPalette.reportYellow));
        expect(state.cameraFocusTarget?.longitude, equals(-76.53));
      },
    );
  });
}
