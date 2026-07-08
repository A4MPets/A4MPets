import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/colored_route_segment.dart';
import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/lost_pet_report_record.dart';
import '../theme/app_palette.dart';

class MapControlsConfig {
  final bool hideDefaultControls, keepReportDangerVisible;
  final bool keepModifyLocationVisible;
  final Widget? panelOverlay;
  final VoidCallback? onSettingsTap, onReportDangerTap, onModifyLocationTap;
  final VoidCallback? onStartTrip, onProfileTap;

  const MapControlsConfig({
    this.hideDefaultControls = false,
    this.keepReportDangerVisible = false,
    this.keepModifyLocationVisible = false,
    this.panelOverlay,
    this.onSettingsTap,
    this.onReportDangerTap,
    this.onModifyLocationTap,
    this.onStartTrip,
    this.onProfileTap,
  });
}

class MapRouteOverlayConfig {
  final List<LatLng> routePoints, routePolylinePoints;
  final List<ColoredRouteSegment> coloredRouteSegments;
  final int? selectedRoutePointIndex;
  final bool canDragRoutePoints, isSelectingRoutePoint;
  final bool routeSelectionHintAtTop;
  final void Function(int index)? onRoutePointPointerDown, onRoutePointTap;
  final void Function(int index)? onRoutePointDragStart;
  final void Function(int index, LatLng point)? onRoutePointDragUpdate;
  final void Function(int index, LatLng point)? onRoutePointDragEnd;

  const MapRouteOverlayConfig({
    this.routePoints = const <LatLng>[],
    this.routePolylinePoints = const <LatLng>[],
    this.coloredRouteSegments = const <ColoredRouteSegment>[],
    this.selectedRoutePointIndex,
    this.canDragRoutePoints = false,
    this.isSelectingRoutePoint = false,
    this.routeSelectionHintAtTop = false,
    this.onRoutePointPointerDown,
    this.onRoutePointTap,
    this.onRoutePointDragStart,
    this.onRoutePointDragUpdate,
    this.onRoutePointDragEnd,
  });
}

class MapReportOverlayConfig {
  final List<HazardReportRecord> hazardReports, visibleHazardCircles;
  final List<LostPetReportRecord> lostPetReports;
  final List<FoundPetReportRecord> foundPetReports;
  final List<GenericReportRecord> genericReports;
  final HazardReportRecord? highlightedHazard;
  final LatLng? hazardDraftLocation;
  final int? hazardDraftImpactRadiusMeters;
  final String? hazardDraftRiskLevelCode;
  final bool isSelectingHazardLocation;
  final LatLng? lostPetDraftLocation, foundPetDraftLocation;
  final LatLng? genericReportDraftLocation;
  final int? genericReportDraftImpactRadiusMeters;
  final String? genericReportDraftRiskLevelCode;
  final bool isSelectingReportLocation, reportSelectionHintAtTop;
  final String reportSelectionHintText;
  final Color reportSelectionHintColor;
  final void Function(HazardReportRecord report)? onHazardTap;
  final void Function(LostPetReportRecord report)? onLostPetTap;
  final void Function(FoundPetReportRecord report)? onFoundPetTap;
  final void Function(GenericReportRecord report)? onGenericReportTap;
  final void Function(LatLng)? onMapTap;

  const MapReportOverlayConfig({
    this.hazardReports = const <HazardReportRecord>[],
    this.visibleHazardCircles = const <HazardReportRecord>[],
    this.lostPetReports = const <LostPetReportRecord>[],
    this.foundPetReports = const <FoundPetReportRecord>[],
    this.genericReports = const <GenericReportRecord>[],
    this.highlightedHazard,
    this.hazardDraftLocation,
    this.hazardDraftImpactRadiusMeters,
    this.hazardDraftRiskLevelCode,
    this.isSelectingHazardLocation = false,
    this.lostPetDraftLocation,
    this.foundPetDraftLocation,
    this.genericReportDraftLocation,
    this.genericReportDraftImpactRadiusMeters,
    this.genericReportDraftRiskLevelCode,
    this.isSelectingReportLocation = false,
    this.reportSelectionHintAtTop = false,
    this.reportSelectionHintText = 'Toca el mapa para ubicar el reporte',
    this.reportSelectionHintColor = AppPalette.primaryBlue,
    this.onHazardTap,
    this.onLostPetTap,
    this.onFoundPetTap,
    this.onGenericReportTap,
    this.onMapTap,
  });
}

class MapCameraConfig {
  final LatLng? cameraFocusTarget;
  final double? cameraFocusZoom;
  final int cameraFocusRevision;

  const MapCameraConfig({this.cameraFocusTarget, this.cameraFocusZoom, this.cameraFocusRevision = 0});
}

class MapLocationConfig {
  final int locationRefreshRevision;
  final LatLng? developerLocationMarker;
  final bool isDeveloperModifyingLocation;
  final void Function(LatLng location)? onUserLocationChanged;
  final void Function(bool isLoading, String? errorText)? onUserLocationStatusChanged;

  const MapLocationConfig({
    this.locationRefreshRevision = 0,
    this.developerLocationMarker,
    this.isDeveloperModifyingLocation = false,
    this.onUserLocationChanged,
    this.onUserLocationStatusChanged,
  });
}
