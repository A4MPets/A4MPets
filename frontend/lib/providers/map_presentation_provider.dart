import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_palette.dart';
import 'panel_flow_provider.dart';
import 'report_flow_provider.dart';
import 'trip_flow_provider.dart';

class MapPresentationState {
  final bool hideDefaultControls;
  final bool keepReportDangerVisible;
  final bool keepModifyLocationVisible;
  final bool isSelectingReportLocation;
  final String reportSelectionHintText;
  final Color reportSelectionHintColor;
  final LatLng? cameraFocusTarget;

  const MapPresentationState({
    this.hideDefaultControls = false,
    this.keepReportDangerVisible = false,
    this.keepModifyLocationVisible = false,
    this.isSelectingReportLocation = false,
    this.reportSelectionHintText = 'Toca el mapa para ubicar el reporte',
    this.reportSelectionHintColor = AppPalette.primaryBlue,
    this.cameraFocusTarget,
  });
}

final mapPresentationProvider = Provider<MapPresentationState>((ref) {
  final PanelFlowState panelFlow = ref.watch(panelFlowProvider);
  final ReportFlowState reportFlow = ref.watch(reportFlowProvider);
  final TripFlowState tripFlow = ref.watch(tripFlowProvider);
  final PanelKind? activeKind = panelFlow.activePanel?.kind;
  final ReportMapSelectionContext? selection =
      reportFlow.activeSelectionContext;

  return MapPresentationState(
    hideDefaultControls: panelFlow.hasOpenPanels,
    keepReportDangerVisible: activeKind == PanelKind.tripActive,
    keepModifyLocationVisible:
        activeKind == PanelKind.tripStart || activeKind == PanelKind.tripActive,
    isSelectingReportLocation:
        selection != null && selection != ReportMapSelectionContext.hazard,
    reportSelectionHintText: switch (selection) {
      ReportMapSelectionContext.lostPet =>
        'Toca el mapa para ubicar la mascota perdida',
      ReportMapSelectionContext.foundPet =>
        'Toca el mapa para ubicar la mascota encontrada',
      _ => 'Toca el mapa para ubicar el reporte',
    },
    reportSelectionHintColor: switch (selection) {
      ReportMapSelectionContext.lostPet => AppPalette.reportYellow,
      ReportMapSelectionContext.foundPet => AppPalette.reportGreen,
      _ => AppPalette.charcoal,
    },
    cameraFocusTarget: tripFlow.isTripActive
        ? tripFlow.latestUserLocation
        : null,
  );
});
