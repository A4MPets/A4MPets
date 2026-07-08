import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/lost_pet_report_record.dart';
import '../models/colored_route_segment.dart';
import '../theme/app_palette.dart';
import 'map_widget_config.dart';

void _noop() {}

class MapWidget extends StatefulWidget {
  final bool isDarkMode;
  final LatLng center;
  final double zoom;
  final MapControlsConfig controls;
  final MapRouteOverlayConfig routeOverlay;
  final MapReportOverlayConfig reportOverlay;
  final MapCameraConfig camera;
  final MapLocationConfig location;

  const MapWidget({
    super.key,
    required this.isDarkMode,
    required this.center,
    this.zoom = 13,
    this.controls = const MapControlsConfig(),
    this.routeOverlay = const MapRouteOverlayConfig(),
    this.reportOverlay = const MapReportOverlayConfig(),
    this.camera = const MapCameraConfig(),
    this.location = const MapLocationConfig(),
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with TickerProviderStateMixin, WidgetsBindingObserver {
  late MapController mapController;
  AnimationController? _cameraAnimationController;
  bool _isMapReady = false;
  bool _isDraggingRoutePoint = false;
  int? _draggingRoutePointIndex;
  LatLng? _draggingPoint;

  LatLng? _userLocation;
  double _userHeading = 0.0;
  bool _hasLocationPermission = false;
  bool _isCustomPositionMode = false;
  LatLng? _customUserLocation;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<CompassEvent>? _compassStreamSub;
  Timer? _locationRestartTimer;
  bool _isResolvingLocation = false;
  String? _userLocationErrorText;
  DateTime? _lastLocationPermissionPromptAt;

  final Map<String, Color> _borderColorCache = {};
  final Map<String, Color> _fillColorCache = {};

  static const Color primary = AppPalette.primaryBlue;
  static const Color secondary = Color(0xFF0F176E);
  static const Color white = AppPalette.white;
  static const Color contentGray = AppPalette.charcoal;
  static const Color translucentWhite = Color(0xCCFFFFFF);
  static const double _userFocusZoom = 17.5;
  static const Duration _permissionPromptCooldown = Duration(seconds: 3);
  static const Duration _locationStreamRetryDelay = Duration(seconds: 2);
  static final LatLngBounds _caliBounds = LatLngBounds(const LatLng(3.289, -76.639), const LatLng(3.518, -76.445));

  LatLng? get _effectiveUserLocation => _isCustomPositionMode ? _customUserLocation : _userLocation;

  bool get _supportsCompass {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    mapController = MapController();
    _startCompassTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    if (_isResolvingLocation) return;

    _emitUserLocationStatus(isLoading: true, errorText: null);

    try {
      _isResolvingLocation = true;
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _hasLocationPermission = false);
        _emitUserLocationStatus(isLoading: false, errorText: 'Activa la ubicación del dispositivo para continuar.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final DateTime now = DateTime.now();
        final DateTime? lastPrompt = _lastLocationPermissionPromptAt;
        if (lastPrompt != null && now.difference(lastPrompt) < _permissionPromptCooldown) {
          if (mounted) setState(() => _hasLocationPermission = false);
          _emitUserLocationStatus(isLoading: false, errorText: 'Debes habilitar los permisos de ubicacion.');
          return;
        }

        _lastLocationPermissionPromptAt = now;
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _hasLocationPermission = false);
        _emitUserLocationStatus(isLoading: false, errorText: 'Debes habilitar los permisos de ubicación.');
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _hasLocationPermission = false);
        _emitUserLocationStatus(
          isLoading: false,
          errorText: 'Los permisos de ubicación están bloqueados. Debes habilitarlos manualmente.',
        );
      } else {
        if (mounted) setState(() => _hasLocationPermission = true);
        await _getCurrentLocationAndHeading();
        _startLocationTracking();
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      _emitUserLocationStatus(isLoading: false, errorText: 'No se pudo solicitar la ubicación actual.');
    } finally {
      _isResolvingLocation = false;
    }
  }

  Future<void> _getCurrentLocationAndHeading() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _userHeading = position.heading.isNaN ? 0.0 : position.heading;
        });
        _emitUserLocationStatus(isLoading: false, errorText: null);
        final LatLng? locationToEmit = _effectiveUserLocation;
        if (locationToEmit != null) widget.location.onUserLocationChanged?.call(locationToEmit);
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _emitUserLocationStatus(isLoading: false, errorText: 'No se pudo obtener tu ubicación actual.');
    }
  }

  void _startLocationTracking() {
    if (!_hasLocationPermission) return;

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (mounted) {
          final LatLng nextLocation = LatLng(position.latitude, position.longitude);
          setState(() {
            _userLocation = nextLocation;
            _userHeading = position.heading.isNaN ? _userHeading : position.heading;
          });
          if (!_isCustomPositionMode) widget.location.onUserLocationChanged?.call(nextLocation);
          _emitUserLocationStatus(isLoading: false, errorText: null);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Location stream error: $error');
        _emitUserLocationStatus(isLoading: false, errorText: 'Se perdió la actualización de ubicación. Reintentando.');

        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scheduleLocationTrackingRestart();
        });
      },
      onDone: () {
        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scheduleLocationTrackingRestart();
        });
      },
    );
  }

  void _scheduleLocationTrackingRestart() {
    if (!mounted || !_hasLocationPermission) return;

    _locationRestartTimer?.cancel();
    _locationRestartTimer = Timer(_locationStreamRetryDelay, () async {
      if (!mounted || !_hasLocationPermission || _isResolvingLocation) return;

      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _startLocationTracking();
        return;
      }

      if (mounted) setState(() => _hasLocationPermission = false);
      _emitUserLocationStatus(
        isLoading: false,
        errorText: permission == LocationPermission.deniedForever
            ? 'Los permisos de ubicación estan bloqueados. Debes habilitarlos manualmente.'
            : 'Debes habilitar los permisos de ubicacion.',
      );
    });
  }

  void _startCompassTracking() {
    if (!_supportsCompass) return;

    _compassStreamSub?.cancel();
    _compassStreamSub = FlutterCompass.events?.listen(
      (CompassEvent event) {
        final double? heading = event.heading;
        if (heading == null || heading.isNaN || !mounted) return;

        setState(() {
          _userHeading = heading;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Compass stream error: $error');
      },
    );
  }

  Future<void> _toggleCustomPositionMode() async {
    if (_isCustomPositionMode) {
      if (!mounted) return;
      setState(() {
        _isCustomPositionMode = false;
      });

      final LatLng? locationToEmit = _effectiveUserLocation;
      if (locationToEmit != null) widget.location.onUserLocationChanged?.call(locationToEmit);
      widget.controls.onModifyLocationTap?.call();
      return;
    }

    LatLng? seedLocation = _userLocation;
    if (seedLocation == null) {
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        seedLocation = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            _userLocation = seedLocation;
            _userHeading = position.heading.isNaN ? _userHeading : position.heading;
          });
        }
      } catch (e) {
        debugPrint('Error activating custom position mode: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      _isCustomPositionMode = true;
      _customUserLocation = seedLocation;
    });

    final LatLng? locationToEmit = _effectiveUserLocation;
    if (locationToEmit != null) widget.location.onUserLocationChanged?.call(locationToEmit);
    widget.controls.onModifyLocationTap?.call();
  }

  Future<void> _prewarmTileCache() async {
    // Desactivado: en web puede ejecutar move() antes de que flutter_map
    // termine su inicialización interna, provocando LateInitializationError
    // en _interactiveViewerState y errores de layout en cascada.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCameraAnimation();
    _locationRestartTimer?.cancel();
    _positionStreamSub?.cancel();
    _compassStreamSub?.cancel();
    mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startCompassTracking();
      _requestLocationPermission();
    });
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.location.locationRefreshRevision != oldWidget.location.locationRefreshRevision) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _requestLocationPermission();
      });
    }

    if (_isMapReady &&
        widget.camera.cameraFocusTarget != null &&
        widget.camera.cameraFocusRevision != oldWidget.camera.cameraFocusRevision) {
      final LatLng focusTarget = widget.camera.cameraFocusTarget!;
      final double nextZoom = widget.camera.cameraFocusZoom ?? mapController.camera.zoom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateCameraFocus(focusTarget, nextZoom);
      });
    }
  }

  void _animateCameraFocus(LatLng center, double zoom) {
    if (!_isMapReady || !mounted) return;

    final LatLng startCenter = mapController.camera.center;
    final double startZoom = mapController.camera.zoom;
    final bool sameCenter =
        (startCenter.latitude - center.latitude).abs() < 0.000001 &&
        (startCenter.longitude - center.longitude).abs() < 0.000001;
    final bool sameZoom = (startZoom - zoom).abs() < 0.01;

    if (sameCenter && sameZoom) {
      _safeMove(center, zoom);
      return;
    }

    _disposeCameraAnimation();

    final Tween<double> latTween = Tween<double>(begin: startCenter.latitude, end: center.latitude);
    final Tween<double> lngTween = Tween<double>(begin: startCenter.longitude, end: center.longitude);
    final Tween<double> zoomTween = Tween<double>(begin: startZoom, end: zoom);
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    bool hasTriggeredMove = false;

    _cameraAnimationController = controller;

    controller.addListener(() {
      if (!mounted || _cameraAnimationController != controller) return;

      final String moveId;
      if (animation.value == 1.0)
        moveId = 'hazard-focus-finished';
      else if (!hasTriggeredMove) {
        moveId = 'hazard-focus-start#${center.latitude},${center.longitude},$zoom';
      } else {
        moveId = 'hazard-focus-progress';
      }

      hasTriggeredMove |= mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        id: moveId,
      );
    });

    controller.addStatusListener((AnimationStatus status) {
      if (_cameraAnimationController != controller) return;

      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _disposeCameraAnimation(controller);
      }
    });

    controller.forward();
  }

  void _cancelCameraAnimation() {
    _disposeCameraAnimation();
  }

  void _disposeCameraAnimation([AnimationController? controller]) {
    final AnimationController? activeController = controller ?? _cameraAnimationController;
    if (activeController == null) return;

    if (_cameraAnimationController == activeController) _cameraAnimationController = null;

    activeController.stop();
    activeController.dispose();
  }

  void _safeMove(LatLng center, double zoom) {
    if (!_isMapReady || !mounted) return;

    try {
      mapController.move(center, zoom);
    } catch (error) {
      debugPrint('Map move skipped due to runtime state: $error');
    }
  }

  void _emitUserLocationStatus({required bool isLoading, required String? errorText}) {
    if (_userLocationErrorText == errorText && _isResolvingLocation == isLoading) {
      return;
    }

    _isResolvingLocation = isLoading;
    _userLocationErrorText = errorText;
    widget.location.onUserLocationStatusChanged?.call(isLoading, errorText);
  }

  void _zoomIn() {
    if (!_isMapReady) return;
    final double nextZoom = (mapController.camera.zoom + 1).clamp(11.0, 22.0);
    _safeMove(mapController.camera.center, nextZoom);
  }

  void _zoomOut() {
    if (!_isMapReady) return;
    final double nextZoom = (mapController.camera.zoom - 1).clamp(11.0, 22.0);
    _safeMove(mapController.camera.center, nextZoom);
  }

  void _centerOnUserLocation() {
    final LatLng? location = _effectiveUserLocation;
    if (!_isMapReady || location == null) return;

    _cancelCameraAnimation();
    final double targetZoom = math.max(mapController.camera.zoom, _userFocusZoom).clamp(11.0, 22.0);
    _animateCameraFocus(location, targetZoom);
  }

  void _resetMapRotation() {
    if (!_isMapReady) return;

    final double currentRotation = mapController.camera.rotation;
    if (currentRotation.abs() < 0.01) return;

    try {
      mapController.moveAndRotate(mapController.camera.center, mapController.camera.zoom, 0, id: 'reset-map-rotation');
    } catch (error) {
      debugPrint('Map rotation reset skipped due to runtime state: $error');
    }
  }

  Color _hazardBorderColorForRiskLevel(String? riskLevelCode) {
    final String normalizedRiskLevel = riskLevelCode ?? 'undefined';
    final String key = '${normalizedRiskLevel}_border';
    return _borderColorCache.putIfAbsent(key, () {
      switch (normalizedRiskLevel) {
        case 'low':
          return AppPalette.dangerYellow;
        case 'medium':
          return AppPalette.dangerOrange;
        default:
          return AppPalette.dangerRed;
      }
    });
  }

  Color _hazardFillColorForRiskLevel(String? riskLevelCode) {
    final String normalizedRiskLevel = riskLevelCode ?? 'undefined';
    final String key = '${normalizedRiskLevel}_fill';
    return _fillColorCache.putIfAbsent(key, () {
      switch (normalizedRiskLevel) {
        case 'low':
          return AppPalette.dangerYellow40;
        case 'medium':
          return AppPalette.dangerOrange40;
        default:
          return AppPalette.dangerRed40;
      }
    });
  }

  LatLng _applyPixelDeltaToLatLng({required LatLng source, required Offset delta}) {
    final double zoom = mapController.camera.zoom;
    final double latitudeRadians = source.latitude * (math.pi / 180.0);
    final double cosLat = math.cos(latitudeRadians).abs().clamp(0.0001, 1.0);
    final double metersPerPixel = 156543.03392 * math.cos(latitudeRadians) / math.pow(2, zoom);

    final double deltaMetersEast = delta.dx * metersPerPixel;
    final double deltaMetersNorth = -delta.dy * metersPerPixel;

    final double deltaLat = deltaMetersNorth / 111320.0;
    final double deltaLng = deltaMetersEast / (111320.0 * cosLat);

    return LatLng(source.latitude + deltaLat, source.longitude + deltaLng);
  }

  bool _shouldCancelCameraAnimationForEvent(MapEvent event) {
    switch (event.source) {
      case MapEventSource.dragStart:
      case MapEventSource.onDrag:
      case MapEventSource.multiFingerGestureStart:
      case MapEventSource.onMultiFinger:
      case MapEventSource.scrollWheel:
      case MapEventSource.flingAnimationController:
      case MapEventSource.doubleTapZoomAnimationController:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String tileUrl = widget.isDarkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    final Color mapBackgroundColor = widget.isDarkMode ? const Color(0xFF1A1818) : const Color(0xFFEEEEEE);

    final bool isWeb = MediaQuery.of(context).size.width > 900;
    final bool controlsVisible = !widget.controls.hideDefaultControls;
    final double topSystemInset = MediaQuery.of(context).padding.top;
    final bool reportDangerVisible = controlsVisible || widget.controls.keepReportDangerVisible;
    final bool modifyLocationVisible = controlsVisible || widget.controls.keepModifyLocationVisible;
    final bool isMobileTripOverlayActive = !controlsVisible && widget.controls.keepReportDangerVisible;
    final double mobileBottomActionsOffset = isMobileTripOverlayActive ? 244 : 16;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            cameraConstraint: CameraConstraint.containCenter(bounds: _caliBounds),
            onMapReady: () {
              if (_isMapReady || !mounted) return;
              _isMapReady = true;
              _prewarmTileCache();
            },
            minZoom: 11,
            maxZoom: 22,
            backgroundColor: mapBackgroundColor,
            keepAlive: true,
            interactionOptions: InteractionOptions(
              flags: _isDraggingRoutePoint ? InteractiveFlag.none : InteractiveFlag.all,
            ),
            onMapEvent: (MapEvent event) {
              if (_shouldCancelCameraAnimationForEvent(event)) _cancelCameraAnimation();
            },
            onTap: (TapPosition tapPosition, LatLng point) {
              if (_isCustomPositionMode) {
                setState(() {
                  _customUserLocation = point;
                });
                widget.location.onUserLocationChanged?.call(point);
                return;
              }
              widget.reportOverlay.onMapTap?.call(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.a4mpets.app',
              maxNativeZoom: 19,
              minZoom: 11,
              maxZoom: 22,
              retinaMode: false,
              keepBuffer: 6,
              panBuffer: 3,
              tileDisplay: const TileDisplay.instantaneous(opacity: 1.0),
              tileUpdateTransformer: TileUpdateTransformers.throttle(const Duration(milliseconds: 90)),
            ),
            if (_effectiveUserLocation != null && (_hasLocationPermission || _isCustomPositionMode))
              _buildSingleMarkerLayer(
                point: _effectiveUserLocation!,
                width: 40,
                height: 40,
                child: _CurrentLocationMarker(heading: _userHeading),
              ),
            if (widget.location.isDeveloperModifyingLocation && widget.location.developerLocationMarker != null)
              _buildSingleMarkerLayer(
                point: widget.location.developerLocationMarker!,
                width: 50,
                height: 50,
                child: const _DeveloperLocationMarker(),
              ),
            if (widget.reportOverlay.highlightedHazard != null)
              _buildHazardCircleLayer([widget.reportOverlay.highlightedHazard!], borderStrokeWidth: 1.5),
            if (widget.reportOverlay.highlightedHazard == null && widget.reportOverlay.visibleHazardCircles.isNotEmpty)
              _buildHazardCircleLayer(widget.reportOverlay.visibleHazardCircles),
            if (widget.reportOverlay.hazardDraftLocation != null &&
                widget.reportOverlay.hazardDraftImpactRadiusMeters != null)
              _buildDraftCircleLayer(
                point: widget.reportOverlay.hazardDraftLocation!,
                color: _hazardFillColorForRiskLevel(widget.reportOverlay.hazardDraftRiskLevelCode),
                borderColor: _hazardBorderColorForRiskLevel(widget.reportOverlay.hazardDraftRiskLevelCode),
                radius: widget.reportOverlay.hazardDraftImpactRadiusMeters!.toDouble(),
              ),
            if (widget.reportOverlay.visibleHazardCircles.isNotEmpty)
              _buildHazardMarkerLayer(widget.reportOverlay.visibleHazardCircles),
            if (widget.reportOverlay.hazardDraftLocation != null)
              _buildDraftMarkerLayer(
                widget.reportOverlay.hazardDraftLocation!,
                color: _hazardBorderColorForRiskLevel(widget.reportOverlay.hazardDraftRiskLevelCode),
                label: '!',
              ),
            if (widget.reportOverlay.lostPetReports.isNotEmpty)
              _buildReportMarkerLayer<LostPetReportRecord>(
                reports: widget.reportOverlay.lostPetReports,
                pointFor: (report) => LatLng(report.lastSeenLatitude, report.lastSeenLongitude),
                messageFor: (report) => 'Abrir mascota perdida ${report.details}',
                onTap: (report) => widget.reportOverlay.onLostPetTap?.call(report),
                color: AppPalette.reportYellow,
                label: '?',
              ),
            if (widget.reportOverlay.foundPetReports.isNotEmpty)
              _buildReportMarkerLayer<FoundPetReportRecord>(
                reports: widget.reportOverlay.foundPetReports,
                pointFor: (report) => LatLng(report.latitude, report.longitude),
                messageFor: (report) => 'Abrir mascota encontrada ${report.details}',
                onTap: (report) => widget.reportOverlay.onFoundPetTap?.call(report),
                color: AppPalette.reportGreen,
                label: '!',
              ),
            if (widget.reportOverlay.genericReports.any((GenericReportRecord report) => report.impactRadiusMeters > 0))
              _buildGenericReportCircleLayer(widget.reportOverlay.genericReports),
            if (widget.reportOverlay.genericReports.isNotEmpty)
              _buildReportMarkerLayer<GenericReportRecord>(
                reports: widget.reportOverlay.genericReports,
                pointFor: (report) => LatLng(report.latitude, report.longitude),
                messageFor: (report) => 'Abrir reporte generico ${report.description}',
                onTap: (report) => widget.reportOverlay.onGenericReportTap?.call(report),
                color: AppPalette.charcoal,
                label: 'i',
              ),
            if (widget.reportOverlay.lostPetDraftLocation != null)
              _buildDraftMarkerLayer(
                widget.reportOverlay.lostPetDraftLocation!,
                color: AppPalette.reportYellow,
                label: '?',
              ),
            if (widget.reportOverlay.foundPetDraftLocation != null)
              _buildDraftMarkerLayer(
                widget.reportOverlay.foundPetDraftLocation!,
                color: AppPalette.reportGreen,
                label: '!',
              ),
            if (widget.reportOverlay.genericReportDraftLocation != null &&
                widget.reportOverlay.genericReportDraftImpactRadiusMeters != null &&
                widget.reportOverlay.genericReportDraftImpactRadiusMeters! > 0)
              _buildDraftCircleLayer(
                point: widget.reportOverlay.genericReportDraftLocation!,
                color: AppPalette.borderLight.withValues(alpha: 0.45),
                borderColor: AppPalette.borderLight,
                radius: widget.reportOverlay.genericReportDraftImpactRadiusMeters!.toDouble(),
              ),
            if (widget.reportOverlay.genericReportDraftLocation != null)
              _buildDraftMarkerLayer(
                widget.reportOverlay.genericReportDraftLocation!,
                color: AppPalette.charcoal,
                label: 'i',
              ),
            if (widget.routeOverlay.routePolylinePoints.length >= 2)
              RepaintBoundary(child: PolylineLayer(polylines: _buildRoutePolylines())),
            if (widget.routeOverlay.routePoints.isNotEmpty)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: List<Marker>.generate(
                    widget.routeOverlay.routePoints.length,
                    (int index) => Marker(
                      point: widget.routeOverlay.routePoints[index],
                      width: 28,
                      height: 28,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => widget.routeOverlay.onRoutePointPointerDown?.call(index),
                        onTap: () => widget.routeOverlay.onRoutePointTap?.call(index),
                        onPanStart: widget.routeOverlay.canDragRoutePoints
                            ? (_) {
                                setState(() {
                                  _isDraggingRoutePoint = true;
                                  _draggingRoutePointIndex = index;
                                  _draggingPoint = widget.routeOverlay.routePoints[index];
                                });
                                widget.routeOverlay.onRoutePointDragStart?.call(index);
                              }
                            : null,
                        onPanUpdate: widget.routeOverlay.canDragRoutePoints
                            ? (DragUpdateDetails details) {
                                if (_draggingRoutePointIndex != index || _draggingPoint == null) {
                                  return;
                                }

                                final LatLng next = _applyPixelDeltaToLatLng(
                                  source: _draggingPoint!,
                                  delta: details.delta,
                                );
                                _draggingPoint = next;
                                widget.routeOverlay.onRoutePointDragUpdate?.call(index, next);
                              }
                            : null,
                        onPanEnd: widget.routeOverlay.canDragRoutePoints
                            ? (_) {
                                final LatLng? finalPoint = _draggingPoint;
                                setState(() {
                                  _isDraggingRoutePoint = false;
                                  _draggingRoutePointIndex = null;
                                  _draggingPoint = null;
                                });
                                if (finalPoint != null) {
                                  widget.routeOverlay.onRoutePointDragEnd?.call(index, finalPoint);
                                }
                              }
                            : null,
                        child: _NumberedMapMarker(
                          number: index + 1,
                          isSelected: widget.routeOverlay.selectedRoutePointIndex == index,
                        ),
                      ),
                    ),
                  ).toList(growable: false),
                ),
              ),
          ],
        ),

        if (!isWeb) ...[
          Positioned(
            left: 16,
            right: 16,
            bottom: mobileBottomActionsOffset,
            child: SafeArea(
              child: _buildAnimatedControl(
                visible: reportDangerVisible,
                hiddenOffset: const Offset(0, 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (reportDangerVisible)
                      _buildPrimaryMapButton(
                        label: 'Reportar',
                        backgroundColor: secondary,
                        foregroundColor: white,
                        onPressed: widget.controls.onReportDangerTap ?? _noop,
                        fontWeight: FontWeight.w600,
                      ),
                    if (controlsVisible) ...[
                      const SizedBox(height: 12),
                      _buildPrimaryMapButton(
                        label: 'Iniciar Viaje',
                        backgroundColor: primary,
                        foregroundColor: white,
                        onPressed: widget.controls.onStartTrip ?? _noop,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 160,
            child: SafeArea(
              child: _buildAnimatedControl(
                visible: controlsVisible,
                hiddenOffset: const Offset(0.06, 0),
                child: _buildZoomControls(),
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: 160,
            child: SafeArea(
              child: _buildAnimatedControl(
                visible: controlsVisible,
                hiddenOffset: const Offset(-0.06, 0),
                child: _buildMapUtilityControls(),
              ),
            ),
          ),

          ..._buildTopCornerControls(topSystemInset: topSystemInset, controlsVisible: controlsVisible, isWeb: false),
        ],

        if (isWeb) ...[
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildAnimatedControl(
              visible: reportDangerVisible,
              hiddenOffset: const Offset(-0.06, 0.06),
              child: _buildPrimaryMapButton(
                label: 'Reportar',
                backgroundColor: secondary,
                foregroundColor: white,
                onPressed: widget.controls.onReportDangerTap ?? _noop,
                width: 220,
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            right: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(0.06, 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildZoomControls(zoomInLabel: 'Acercar mapa', zoomOutLabel: 'Alejar mapa'),
                  const SizedBox(height: 12),
                  _buildPrimaryMapButton(
                    label: 'Iniciar Viaje',
                    backgroundColor: primary,
                    foregroundColor: white,
                    onPressed: widget.controls.onStartTrip ?? _noop,
                    width: 220,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: 84,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(-0.06, 0.06),
              child: _buildMapUtilityControls(),
            ),
          ),

          ..._buildTopCornerControls(topSystemInset: topSystemInset, controlsVisible: controlsVisible, isWeb: true),
        ],

        Positioned(
          top: 72 + topSystemInset,
          right: 16,
          child: _buildAnimatedControl(
            visible: modifyLocationVisible,
            hiddenOffset: const Offset(0.06, 0),
            child: _buildMapCornerButton(
              label: 'Cambiar ubicacion manual',
              icon: Icons.location_on,
              backgroundColor: _isCustomPositionMode
                  ? AppPalette.primaryBlue.withValues(alpha: 0.92)
                  : translucentWhite,
              iconColor: _isCustomPositionMode ? white : contentGray,
              onTap: _toggleCustomPositionMode,
            ),
          ),
        ),
        _buildSelectionHintPositioned(
          isWeb: isWeb,
          topSystemInset: topSystemInset,
          anchorTop: widget.routeOverlay.routeSelectionHintAtTop,
          bottomOffset: isWeb ? 24 : 20,
          visible: widget.routeOverlay.isSelectingRoutePoint,
          child: _buildSelectionHint(
            color: AppPalette.primaryBlue,
            icon: Icons.touch_app,
            text: 'Toca el mapa para agregar el punto',
          ),
        ),
        _buildSelectionHintPositioned(
          isWeb: isWeb,
          topSystemInset: topSystemInset,
          anchorTop: widget.reportOverlay.reportSelectionHintAtTop,
          bottomOffset: isWeb ? 72 : 68,
          visible: widget.reportOverlay.isSelectingHazardLocation || widget.reportOverlay.isSelectingReportLocation,
          child: _buildSelectionHint(
            color: widget.reportOverlay.isSelectingHazardLocation
                ? _hazardBorderColorForRiskLevel(widget.reportOverlay.hazardDraftRiskLevelCode)
                : widget.reportOverlay.reportSelectionHintColor,
            icon: Icons.place_rounded,
            text: widget.reportOverlay.isSelectingHazardLocation
                ? 'Toca el mapa para ubicar el peligro'
                : widget.reportOverlay.reportSelectionHintText,
          ),
        ),
        if (widget.controls.panelOverlay != null) Positioned.fill(child: widget.controls.panelOverlay!),
      ],
    );
  }

  Widget _buildMapActionButton({required IconData icon, required VoidCallback onPressed, String? semanticLabel}) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton(
        mini: true,
        onPressed: onPressed,
        tooltip: semanticLabel,
        backgroundColor: translucentWhite,
        foregroundColor: contentGray,
        elevation: 0,
        shape: const CircleBorder(),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildZoomControls({String? zoomInLabel, String? zoomOutLabel}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMapActionButton(icon: Icons.add, onPressed: _zoomIn, semanticLabel: zoomInLabel),
        const SizedBox(height: 8),
        _buildMapActionButton(icon: Icons.remove, onPressed: _zoomOut, semanticLabel: zoomOutLabel),
      ],
    );
  }

  Widget _buildMapUtilityControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMapActionButton(
          icon: Icons.my_location,
          onPressed: _centerOnUserLocation,
          semanticLabel: 'Centrar en mi ubicacion',
        ),
        const SizedBox(height: 8),
        _buildMapActionButton(
          icon: Icons.explore_outlined,
          onPressed: _resetMapRotation,
          semanticLabel: 'Restablecer rotacion del mapa',
        ),
      ],
    );
  }

  List<Widget> _buildTopCornerControls({
    required double topSystemInset,
    required bool controlsVisible,
    required bool isWeb,
  }) {
    return [
      _buildTopCornerControl(
        topSystemInset: topSystemInset,
        controlsVisible: controlsVisible,
        left: true,
        label: 'Abrir perfil',
        icon: Icons.person,
        backgroundColor: isWeb ? white : translucentWhite,
        onTap: widget.controls.onProfileTap ?? _noop,
      ),
      _buildTopCornerControl(
        topSystemInset: topSystemInset,
        controlsVisible: controlsVisible,
        left: false,
        label: 'Abrir configuracion',
        icon: Icons.settings,
        backgroundColor: translucentWhite,
        onTap: widget.controls.onSettingsTap ?? _noop,
      ),
    ];
  }

  Widget _buildTopCornerControl({
    required double topSystemInset,
    required bool controlsVisible,
    required bool left,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Positioned(
      top: 16 + topSystemInset,
      left: left ? 16 : null,
      right: left ? null : 16,
      child: _buildAnimatedControl(
        visible: controlsVisible,
        hiddenOffset: Offset(left ? -0.06 : 0.06, 0),
        child: _buildMapCornerButton(
          label: label,
          icon: icon,
          backgroundColor: backgroundColor,
          iconColor: contentGray,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildReportMarkerLayer<T>({
    required Iterable<T> reports,
    required LatLng Function(T report) pointFor,
    required String Function(T report) messageFor,
    required void Function(T report) onTap,
    required Color color,
    Color Function(T report)? colorFor,
    required String label,
  }) {
    return RepaintBoundary(
      child: MarkerLayer(
        markers: reports
            .map(
              (T report) => _buildReportMarker(
                point: pointFor(report),
                message: messageFor(report),
                onTap: () => onTap(report),
                color: colorFor?.call(report) ?? color,
                label: label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildHazardCircleLayer(Iterable<HazardReportRecord> reports, {double borderStrokeWidth = 1.2}) {
    return _buildCircleLayer(
      reports.map(
        (HazardReportRecord report) => _buildCircleMarker(
          point: LatLng(report.incidentLatitude, report.incidentLongitude),
          color: _hazardFillColorForRiskLevel(report.riskLevelCode),
          borderColor: _hazardBorderColorForRiskLevel(report.riskLevelCode),
          borderStrokeWidth: borderStrokeWidth,
          radius: report.impactRadiusMeters.toDouble(),
        ),
      ),
    );
  }

  Widget _buildGenericReportCircleLayer(Iterable<GenericReportRecord> reports) {
    return _buildCircleLayer(
      reports
          .where((GenericReportRecord report) => report.impactRadiusMeters > 0)
          .map(
            (GenericReportRecord report) => _buildCircleMarker(
              point: LatLng(report.latitude, report.longitude),
              color: AppPalette.borderLight.withValues(alpha: 0.45),
              borderColor: AppPalette.borderLight,
              radius: report.impactRadiusMeters.toDouble(),
            ),
          ),
    );
  }

  Widget _buildHazardMarkerLayer(Iterable<HazardReportRecord> reports) {
    return _buildReportMarkerLayer<HazardReportRecord>(
      reports: reports,
      pointFor: (HazardReportRecord report) => LatLng(report.incidentLatitude, report.incidentLongitude),
      messageFor: (HazardReportRecord report) => 'Abrir peligro ${report.narrativeDescription}',
      onTap: (HazardReportRecord report) => widget.reportOverlay.onHazardTap?.call(report),
      color: AppPalette.dangerRed,
      colorFor: (HazardReportRecord report) => _hazardBorderColorForRiskLevel(report.riskLevelCode),
      label: '!',
    );
  }

  Widget _buildSingleMarkerLayer({
    required LatLng point,
    required double width,
    required double height,
    required Widget child,
  }) {
    return RepaintBoundary(
      child: MarkerLayer(
        markers: [Marker(point: point, width: width, height: height, child: child)],
      ),
    );
  }

  Widget _buildDraftMarkerLayer(LatLng point, {required Color color, required String label}) {
    return _buildSingleMarkerLayer(
      point: point,
      width: 24,
      height: 24,
      child: _HazardMarkerWidget(color: color, label: label),
    );
  }

  Widget _buildDraftCircleLayer({
    required LatLng point,
    required Color color,
    required Color borderColor,
    required double radius,
  }) {
    return _buildCircleLayer([
      _buildCircleMarker(point: point, color: color, borderColor: borderColor, borderStrokeWidth: 1.5, radius: radius),
    ]);
  }

  Widget _buildCircleLayer(Iterable<CircleMarker> circles) {
    return RepaintBoundary(child: CircleLayer(circles: circles.toList(growable: false)));
  }

  CircleMarker _buildCircleMarker({
    required LatLng point,
    required Color color,
    required Color borderColor,
    required double radius,
    double borderStrokeWidth = 1.2,
  }) {
    return CircleMarker(
      point: point,
      color: color,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      useRadiusInMeter: true,
      radius: radius,
    );
  }

  Marker _buildReportMarker({
    required LatLng point,
    required String message,
    required VoidCallback onTap,
    required Color color,
    required String label,
  }) {
    return Marker(
      point: point,
      width: 24,
      height: 24,
      child: Tooltip(
        message: message,
        child: Semantics(
          label: message,
          button: true,
          child: GestureDetector(
            onTap: onTap,
            child: _HazardMarkerWidget(color: color, label: label),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryMapButton({
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
    double width = double.infinity,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return SizedBox(
      width: width,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: foregroundColor, fontSize: 16, fontWeight: fontWeight),
        ),
      ),
    );
  }

  Widget _buildMapCornerButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedControl({
    required bool visible,
    required Widget child,
    Offset hiddenOffset = const Offset(0, 0.04),
  }) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : hiddenOffset,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
          child: child,
        ),
      ),
    );
  }

  Widget _buildSelectionHint({required Color color, required IconData icon, required String text}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHintPositioned({
    required bool isWeb,
    required double topSystemInset,
    required bool anchorTop,
    required double bottomOffset,
    required bool visible,
    required Widget child,
  }) {
    return Positioned(
      top: anchorTop ? topSystemInset + (isWeb ? 44 : 40) : null,
      bottom: anchorTop ? null : bottomOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : Offset(0, anchorTop ? -0.05 : 0.05),
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: child,
          ),
        ),
      ),
    );
  }

  List<Polyline> _buildRoutePolylines() {
    if (widget.routeOverlay.coloredRouteSegments.isNotEmpty) {
      return widget.routeOverlay.coloredRouteSegments
          .where((ColoredRouteSegment segment) => segment.points.length >= 2)
          .map(
            (ColoredRouteSegment segment) => Polyline(points: segment.points, color: segment.color, strokeWidth: 2.0),
          )
          .toList();
    }
    return [Polyline(points: widget.routeOverlay.routePolylinePoints, color: AppPalette.primaryBlue, strokeWidth: 2.0)];
  }
}

class _HazardMarkerWidget extends StatelessWidget {
  final Color color;
  final String label;

  const _HazardMarkerWidget({required this.color, this.label = '!'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, height: 1),
        ),
      ),
    );
  }
}

class _NumberedMapMarker extends StatelessWidget {
  final int number;
  final bool isSelected;

  const _NumberedMapMarker({required this.number, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? AppPalette.dangerRed : AppPalette.primaryBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: isSelected ? 2 : 1.5),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, height: 1.0),
        ),
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  final double heading;

  const _CurrentLocationMarker({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (heading * math.pi) / 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppPalette.primaryBlue.withValues(alpha: 0.30), shape: BoxShape.circle),
            ),
          ),
          SizedBox(
            width: 14,
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.primaryBlue, width: 2),
              ),
            ),
          ),
          Positioned(
            top: 1,
            child: CustomPaint(size: const Size(10, 10), painter: _ArrowPainter()),
          ),
        ],
      ),
    );
  }
}

class _DeveloperLocationMarker extends StatelessWidget {
  const _DeveloperLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: AlwaysStoppedAnimation(1.0),
          child: SizedBox(
            width: 50,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFF5984BC).withValues(alpha: 0.3), shape: BoxShape.circle),
            ),
          ),
        ),
        SizedBox(
          width: 30,
          height: 30,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF5984BC).withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5984BC), width: 2),
            ),
          ),
        ),
        SizedBox(
          width: 10,
          height: 10,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppPalette.primaryBlue
      ..style = PaintingStyle.fill;

    final ui.Path path = ui.Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
