import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/colored_route_segment.dart';
import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/local_user_profile.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../models/planned_route_result.dart';
import '../models/route_navigation_instruction.dart';
import '../models/route_record.dart';
import '../providers/audio_feedback_provider.dart';
import '../providers/audio_feedback_settings_provider.dart';
import '../providers/local_data_providers.dart';
import '../providers/theme_provider.dart';
import '../providers/trip_transport_preference_provider.dart';
import '../services/navigation_audio_message_builder.dart';
import '../services/navigation_audio_progress.dart';
import '../services/hazard_risk_filtering.dart';
import '../services/osm_routing_service.dart';
import '../services/route_hazard_visualizer_service.dart';
import '../services/trip_navigation_support.dart';
import '../theme/app_palette.dart';
import '../widgets/auth_panels.dart';
import '../widgets/hazard_comments_panel.dart';
import '../widgets/hazard_details_panel.dart';
import '../widgets/hazard_layers_panel.dart';
import '../widgets/hazard_reporting_panel.dart';
import '../widgets/found_pet_details_panel.dart';
import '../widgets/found_pet_reports_list_panel.dart';
import '../widgets/found_pet_reporting_panel.dart';
import '../widgets/generic_report_details_panel.dart';
import '../widgets/generic_report_panel.dart';
import '../widgets/lost_pet_details_panel.dart';
import '../widgets/lost_pet_reports_list_panel.dart';
import '../widgets/lost_pet_reporting_panel.dart';
import '../widgets/map_widget.dart';
import '../widgets/map_widget_config.dart';
import '../widgets/panel_modal.dart';
import '../widgets/pet_details_panel.dart';
import '../widgets/pet_management_panels.dart';
import '../widgets/profile_menu_panel.dart';
import '../widgets/report_type_selector_panel.dart';
import '../widgets/route_management_panels.dart';
import '../widgets/shared/confirmation_dialog.dart';
import '../widgets/shared/local_image_widget.dart';
import '../widgets/shared/panel_action_button.dart';

part 'map_page_auth.dart';
part 'map_page_components.dart';
part 'map_page_hazards.dart';
part 'map_page_panels.dart';
part 'map_page_reports.dart';
part 'map_page_routes.dart';
part 'map_page_trip.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

enum _RouteMapTool { addPoint, editPoint }

enum _TripTransportMethod { walking, vehicle }

enum _ReportMapSelectionContext { hazard, lostPet, foundPet, generic }

class _MapPageState extends ConsumerState<MapPage> {
  final List<_PanelRoute> _panelStack = <_PanelRoute>[];
  int _panelTransitionSeed = 0;

  final OsmRoutingService _routingService = OsmRoutingService();
  final Distance _distanceCalculator = const Distance();

  // Route editor state.
  List<LatLng> _draftRoutePoints = <LatLng>[];
  List<LatLng> _draftRoutePolyline = <LatLng>[];
  List<LatLng> _routePolylineWaypoints = <LatLng>[];
  List<ColoredRouteSegment> _hazardColoredRouteSegments = <ColoredRouteSegment>[];
  _RouteMapTool _activeRouteTool = _RouteMapTool.addPoint;
  int? _selectedPointIndexForEdit;
  int? _selectedRouteId;
  int? _editingRouteId;
  String? _editingRouteName;

  // Hazard interaction state.
  bool _isSelectingHazardLocationOnMap = false;
  LatLng? _manualHazardLocation;
  HazardDraftPreview? _hazardDraftPreview;
  HazardReportRecord? _selectedHazard;
  LostPetReportRecord? _selectedLostPetReport;
  FoundPetReportRecord? _selectedFoundPetReport;
  GenericReportRecord? _selectedGenericReport;
  int _hazardFocusRevision = 0;
  bool _showLowRiskHazardCircles = true;
  bool _showMediumRiskHazardCircles = true;
  bool _showHighRiskHazardCircles = true;
  bool _isReportHazardPanelMinimized = false;
  _ReportMapSelectionContext? _activeReportSelectionContext;
  LatLng? _manualLostPetLocation;
  LatLng? _manualFoundPetLocation;
  LatLng? _manualGenericReportLocation;
  GenericReportDraftPreview? _genericReportDraftPreview;
  bool _showLostPetReports = true;
  bool _showFoundPetReports = true;
  bool _showGenericReports = true;
  PetRecord? _selectedLostPetForReport;
  LostPetReportRecord? _selectedLostReportForFoundReport;
  LatLng? _reportFocusTarget;
  int _reportFocusRevision = 0;
  _ProximityAlertTarget? _activeProximityAlert;
  Set<String> _currentProximityZoneKeys = <String>{};
  final Set<String> _acknowledgedProximityZoneKeys = <String>{};

  // Trip navigation state.
  final Set<int> _selectedTripPetIds = <int>{};
  _TripTransportMethod _selectedTripTransport = _TripTransportMethod.walking;
  Set<String> _selectedTripHazardRiskFilters = <String>{...HazardRiskFiltering.allRoutingFilters};
  RouteRecord? _selectedTripRoute;
  bool _isTripActive = false;
  bool _tripArrivalHandled = false;
  int _routePolylineRequestVersion = 0;
  String? _tripStartErrorText;
  LatLng? _latestUserLocation;
  int _tripUserFocusRevision = 0;
  bool _isUserLocationLoading = true;
  String? _userLocationErrorText;
  int _userLocationRefreshRevision = 0;
  List<LatLng> _tripRemainingWaypoints = <LatLng>[];
  bool _isTripStartPanelMinimized = false;
  List<RouteNavigationInstruction> _activeNavigationInstructions = const <RouteNavigationInstruction>[];
  final Set<String> _spokenFarApproachInstructionIds = <String>{};
  final Set<String> _spokenApproachInstructionIds = <String>{};
  final Set<String> _spokenImmediateInstructionIds = <String>{};
  String? _pendingImmediateNavigationCueKey;
  int _pendingImmediateNavigationCueCount = 0;

  // Auth panel state.
  bool _isAuthRequestLoading = false;

  static const double _tripWaypointArrivalMeters = 25;
  static const double _tripRerouteMinDistanceMeters = 18;
  static const Duration _tripRerouteMinInterval = Duration(seconds: 6);

  late final TripRerouteController _tripRerouteController = TripRerouteController(
    distanceCalculator: _distanceCalculator,
    minDistanceMeters: _tripRerouteMinDistanceMeters,
    minInterval: _tripRerouteMinInterval,
  );
  ProviderSubscription<String>? _tripTransportPreferenceSubscription;

  @override
  void initState() {
    super.initState();
    _tripTransportPreferenceSubscription = ref.listenManual<String>(tripTransportPreferenceProvider, (
      String? previous,
      String next,
    ) {
      final _TripTransportMethod resolved = _tripTransportMethodFromName(next);
      if (_selectedTripTransport == resolved || !mounted) return;

      _updatePageState(() {
        _selectedTripTransport = resolved;
      });
      _refreshTripRoutePreviewForPreferences();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _tripTransportPreferenceSubscription?.close();
    super.dispose();
  }

  bool get _hasOpenPanels => _panelStack.isNotEmpty;

  bool get _isDebugDetailPanelOpen {
    if (!_hasOpenPanels) return false;

    final _PanelRoute currentPanel = _panelStack.last;
    return currentPanel.isReportDetailsPanel;
  }

  String? get _debugDeleteLabel {
    if (!_isDebugDetailPanelOpen) return null;

    return switch (_panelStack.last.kind) {
      PanelKind.hazardDetails => 'Borrar peligro',
      PanelKind.lostPetDetails => 'Borrar mascota perdida',
      PanelKind.foundPetDetails => 'Borrar mascota encontrada',
      PanelKind.genericReportDetails => 'Borrar reporte',
      _ => null,
    };
  }

  void _updatePageState(VoidCallback mutation) {
    if (!mounted) return;

    setState(mutation);
  }

  bool get _isTripNavigationContext {
    if (_selectedTripRoute == null) return false;

    if (_isTripActive) return true;

    return _panelStack.any((_PanelRoute route) => route.isTripFlowPanel);
  }

  bool get _isAudioFeedbackEnabled {
    return ref.read(audioFeedbackEnabledProvider);
  }

  _TripTransportMethod _tripTransportMethodFromName(String value) {
    return value == _TripTransportMethod.vehicle.name ? _TripTransportMethod.vehicle : _TripTransportMethod.walking;
  }

  void _syncAndReloadData() {
    ref.read(myPetsControllerProvider.notifier).reload();
    ref.read(petsControllerProvider.notifier).reload();
    ref.read(routesControllerProvider.notifier).reload();
    ref.read(hazardReportsControllerProvider.notifier).reload();
    ref.read(lostPetReportsControllerProvider.notifier).reload();
    ref.read(foundPetReportsControllerProvider.notifier).reload();
    ref.read(genericReportsControllerProvider.notifier).reload();
  }

  void _reloadReportData() {
    ref.read(hazardReportsControllerProvider.notifier).reload();
    ref.read(lostPetReportsControllerProvider.notifier).reload();
    ref.read(foundPetReportsControllerProvider.notifier).reload();
    ref.read(genericReportsControllerProvider.notifier).reload();
    ref.read(petsControllerProvider.notifier).reload();
    ref.read(myPetsControllerProvider.notifier).reload();
  }

  List<HazardReportRecord> get _visibleHazardCircles {
    final List<HazardReportRecord> hazardReports =
        ref.watch(hazardReportsControllerProvider).asData?.value ?? const <HazardReportRecord>[];

    return hazardReports
        .where((HazardReportRecord report) {
          switch (report.riskLevelCode) {
            case 'low':
              return _showLowRiskHazardCircles;
            case 'medium':
              return _showMediumRiskHazardCircles;
            case 'high':
              return _showHighRiskHazardCircles;
            default:
              return _showHighRiskHazardCircles;
          }
        })
        .toList(growable: false);
  }

  List<LatLng> get _renderedRoutePoints {
    if (_hasOpenPanels && _panelStack.last.isAddRoutePanel) return List<LatLng>.from(_draftRoutePoints);

    if (_isTripNavigationContext) {
      final List<LatLng> activePoints = _tripRemainingWaypoints.isNotEmpty
          ? _tripRemainingWaypoints
          : _draftRoutePoints;
      return List<LatLng>.from(activePoints);
    }

    return List<LatLng>.from(_draftRoutePoints);
  }

  List<LatLng> get _renderedRoutePolylinePoints {
    if (_hasOpenPanels && _panelStack.last.isAddRoutePanel) return List<LatLng>.from(_draftRoutePolyline);

    if (_draftRoutePolyline.isNotEmpty) return List<LatLng>.from(_draftRoutePolyline);

    if (_isTripNavigationContext && _latestUserLocation != null)
      return <LatLng>[_latestUserLocation!, ..._renderedRoutePoints];

    return <LatLng>[];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = ref.watch(themeModeProvider);
    final _PanelRoute? activePanel = _hasOpenPanels ? _panelStack.last : null;
    final bool activePanelAnchoredBottom =
        activePanel != null &&
        (activePanel.anchor == PanelAnchor.bottomLeft || activePanel.anchor == PanelAnchor.bottomRight);
    final LatLng? tripFocusTarget = _isTripActive ? _latestUserLocation : null;
    final LatLng? hazardFocusTarget = _selectedHazard == null
        ? null
        : LatLng(_selectedHazard!.incidentLatitude, _selectedHazard!.incidentLongitude);

    return Scaffold(
      body: MapWidget(
        isDarkMode: isDarkMode,
        center: const LatLng(3.4516, -76.5320),
        zoom: 13,
        controls: MapControlsConfig(
          hideDefaultControls: _hasOpenPanels,
          keepReportDangerVisible: _hasOpenPanels && _panelStack.last.isTripPanel,
          keepModifyLocationVisible:
              _hasOpenPanels && (_panelStack.last.isTripStartPanel || _panelStack.last.isTripPanel),
          onProfileTap: () => _openProfilePanel(isDarkMode),
          panelOverlay: Stack(
            children: <Widget>[_buildPanelOverlay(isDarkMode), _buildProximityAlertOverlay(isDarkMode)],
          ),
          onSettingsTap: () => _openHazardLayersSettingsPanel(isDarkMode),
          onStartTrip: () => _openStartTripPanel(isDarkMode),
          onReportDangerTap: () => _openReportTypeSelectorPanel(isDarkMode),
        ),
        routeOverlay: MapRouteOverlayConfig(
          routePoints: _renderedRoutePoints,
          routePolylinePoints: _renderedRoutePolylinePoints,
          coloredRouteSegments: _hazardColoredRouteSegments,
          selectedRoutePointIndex: _selectedPointIndexForEdit,
          onRoutePointPointerDown: (int index) {
            if (_activeRouteTool != _RouteMapTool.editPoint) return;
            setState(() {
              _selectedPointIndexForEdit = index;
            });
          },
          canDragRoutePoints:
              _hasOpenPanels && _panelStack.last.isAddRoutePanel && _activeRouteTool == _RouteMapTool.editPoint,
          onRoutePointDragStart: _onRoutePointDragStart,
          onRoutePointDragUpdate: _onRoutePointDragUpdate,
          onRoutePointDragEnd: _onRoutePointDragEnd,
          onRoutePointTap: (int index) {
            if (_activeRouteTool != _RouteMapTool.editPoint) return;
            setState(() {
              _selectedPointIndexForEdit = index;
            });
          },
          isSelectingRoutePoint:
              _hasOpenPanels && _panelStack.last.isAddRoutePanel && _activeRouteTool == _RouteMapTool.addPoint,
          routeSelectionHintAtTop: activePanel != null && activePanel.isAddRoutePanel && activePanelAnchoredBottom,
        ),
        reportOverlay: MapReportOverlayConfig(
          hazardReports: _visibleHazardCircles,
          visibleHazardCircles: _visibleHazardCircles,
          lostPetReports: _visibleLostPetReports,
          foundPetReports: _visibleFoundPetReports,
          genericReports: _visibleGenericReports,
          highlightedHazard: _selectedHazard,
          hazardDraftLocation: _hasOpenPanels && _panelStack.last.isReportHazardPanel
              ? (_manualHazardLocation ?? _latestUserLocation)
              : null,
          hazardDraftImpactRadiusMeters: _hazardDraftPreview?.impactRadiusMeters,
          hazardDraftRiskLevelCode: _hazardDraftPreview?.riskLevelCode,
          isSelectingHazardLocation:
              _hasOpenPanels && _panelStack.last.isReportHazardPanel && _isSelectingHazardLocationOnMap,
          lostPetDraftLocation: _hasOpenPanels && _panelStack.last.isLostPetReportPanel
              ? (_manualLostPetLocation ?? _latestUserLocation)
              : null,
          foundPetDraftLocation: _hasOpenPanels && _panelStack.last.isFoundPetReportPanel
              ? (_manualFoundPetLocation ?? _latestUserLocation)
              : null,
          genericReportDraftLocation: _hasOpenPanels && _panelStack.last.isGenericReportPanel
              ? (_manualGenericReportLocation ?? _latestUserLocation)
              : null,
          genericReportDraftImpactRadiusMeters: _genericReportDraftPreview?.impactRadiusMeters,
          genericReportDraftRiskLevelCode: _genericReportDraftPreview?.riskLevelCode,
          isSelectingReportLocation:
              _activeReportSelectionContext != null &&
              _activeReportSelectionContext != _ReportMapSelectionContext.hazard,
          reportSelectionHintAtTop: activePanel != null && activePanel.isReportEditorPanel && activePanelAnchoredBottom,
          onHazardTap: (HazardReportRecord hazard) {
            _openHazardDetailsPanel(isDarkMode, hazard);
          },
          onLostPetTap: (LostPetReportRecord report) {
            _openLostPetDetailsPanel(isDarkMode, report);
          },
          onFoundPetTap: (FoundPetReportRecord report) {
            _openFoundPetDetailsPanel(isDarkMode, report);
          },
          onGenericReportTap: (GenericReportRecord report) {
            _openGenericReportDetailsPanel(isDarkMode, report);
          },
          reportSelectionHintText: _activeReportSelectionContext == _ReportMapSelectionContext.lostPet
              ? 'Toca el mapa para ubicar la mascota perdida'
              : (_activeReportSelectionContext == _ReportMapSelectionContext.foundPet
                    ? 'Toca el mapa para ubicar la mascota encontrada'
                    : 'Toca el mapa para ubicar el reporte'),
          reportSelectionHintColor: _activeReportSelectionContext == _ReportMapSelectionContext.lostPet
              ? AppPalette.reportYellow
              : (_activeReportSelectionContext == _ReportMapSelectionContext.foundPet
                    ? AppPalette.reportGreen
                    : AppPalette.charcoal),
          onMapTap: _onMapTap,
        ),
        camera: MapCameraConfig(
          cameraFocusTarget: tripFocusTarget ?? hazardFocusTarget ?? _reportFocusTarget,
          cameraFocusZoom: tripFocusTarget != null
              ? null
              : (hazardFocusTarget == null ? null : _hazardFocusZoomFor(_selectedHazard!)),
          cameraFocusRevision: tripFocusTarget != null
              ? _tripUserFocusRevision
              : (hazardFocusTarget != null ? _hazardFocusRevision : _reportFocusRevision),
        ),
        location: MapLocationConfig(
          onUserLocationChanged: _handleUserLocationChanged,
          onUserLocationStatusChanged: _handleUserLocationStatusChanged,
          locationRefreshRevision: _userLocationRefreshRevision,
        ),
      ),
    );
  }
}
