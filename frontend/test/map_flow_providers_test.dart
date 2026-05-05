import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/route_record.dart';
import 'package:frontend/providers/panel_flow_provider.dart';
import 'package:frontend/providers/report_flow_provider.dart';
import 'package:frontend/providers/route_editor_provider.dart';
import 'package:frontend/providers/trip_flow_provider.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('panel flow pushes, replaces, minimizes and pops panels', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final PanelFlowController controller = container.read(
      panelFlowProvider.notifier,
    );

    controller.push(PanelKind.login);
    controller.push(PanelKind.profile);
    expect(container.read(panelFlowProvider).stack.length, 2);
    expect(
      container.read(panelFlowProvider).activePanel?.kind,
      PanelKind.profile,
    );

    controller.toggleActiveMinimized();
    expect(container.read(panelFlowProvider).activePanel?.isMinimized, isTrue);

    controller.replaceTop(PanelKind.managePets);
    expect(container.read(panelFlowProvider).stack.length, 2);
    expect(
      container.read(panelFlowProvider).activePanel?.kind,
      PanelKind.managePets,
    );
    expect(container.read(panelFlowProvider).activePanel?.isMinimized, isFalse);

    controller.pop();
    expect(
      container.read(panelFlowProvider).activePanel?.kind,
      PanelKind.login,
    );
  });

  test('route editor manages draft points and edit selection', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final RouteEditorController controller = container.read(
      routeEditorProvider.notifier,
    );
    const LatLng first = LatLng(3.45, -76.53);
    const LatLng moved = LatLng(3.46, -76.54);

    controller.addDraftPoint(first);
    controller.setTool(RouteMapTool.editPoint);
    controller.selectPointForEdit(0);
    controller.updateDraftPoint(0, moved);

    final RouteEditorState state = container.read(routeEditorProvider);
    expect(state.activeTool, RouteMapTool.editPoint);
    expect(state.selectedPointIndexForEdit, 0);
    expect(state.draftRoutePoints, <LatLng>[moved]);

    controller.clearDraft();
    expect(container.read(routeEditorProvider).draftRoutePoints, isEmpty);
    expect(
      container.read(routeEditorProvider).selectedPointIndexForEdit,
      isNull,
    );
  });

  test('report flow stores manual locations and clears drafts', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final ReportFlowController controller = container.read(
      reportFlowProvider.notifier,
    );
    const LatLng location = LatLng(3.45, -76.53);

    controller.beginLocationSelection(ReportMapSelectionContext.lostPet);
    controller.setManualLocation(ReportMapSelectionContext.lostPet, location);
    controller.updateGenericDraft(
      const ReportDraftState(impactRadiusMeters: 250, riskLevelCode: 'high'),
    );

    ReportFlowState state = container.read(reportFlowProvider);
    expect(state.activeSelectionContext, isNull);
    expect(state.manualLostPetLocation, location);
    expect(state.genericReportDraftPreview?.impactRadiusMeters, 250);

    controller.clearReportingDrafts();
    state = container.read(reportFlowProvider);
    expect(state.manualLostPetLocation, isNull);
    expect(state.genericReportDraftPreview, isNull);
  });

  test('trip flow requires a route before starting and toggles filters', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final TripFlowController controller = container.read(
      tripFlowProvider.notifier,
    );

    controller.startTrip();
    expect(container.read(tripFlowProvider).isTripActive, isFalse);
    expect(container.read(tripFlowProvider).startErrorText, isNotNull);

    controller.toggleHazardRiskFilter('high', false);
    expect(
      container
          .read(tripFlowProvider)
          .selectedHazardRiskFilters
          .contains('high'),
      isFalse,
    );

    controller.selectRoute(_routeRecord());
    controller.startTrip();
    expect(container.read(tripFlowProvider).isTripActive, isTrue);
    expect(container.read(tripFlowProvider).startErrorText, isNull);
  });
}

RouteRecord _routeRecord() {
  final DateTime now = DateTime(2026, 5, 4);
  return RouteRecord(
    id: 1,
    name: 'Ruta QA',
    points: const <RoutePoint>[
      RoutePoint(latitude: 3.45, longitude: -76.53),
      RoutePoint(latitude: 3.46, longitude: -76.54),
    ],
    syncStatus: 'synced',
    lastModifiedAt: now,
    createdAt: now,
    updatedAt: now,
    needsSync: false,
  );
}
