import 'package:flutter/material.dart';
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

/// Interactive map shell that renders user location, routes, hazards, and
/// report overlays while delegating workflow decisions to parent callbacks.
class MapWidget extends StatefulWidget {
  final bool isDarkMode;
  final LatLng center;
  final double zoom;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onReportDangerTap;
  final VoidCallback? onModifyLocationTap;
  final VoidCallback? onStartTrip;
  final VoidCallback? onProfileTap;
  final bool hideDefaultControls;
  final bool keepReportDangerVisible;
  final bool keepModifyLocationVisible;
  final Widget? panelOverlay;
  final List<LatLng> routePoints;
  final List<LatLng> routePolylinePoints;
  final List<dynamic> coloredRouteSegments;
  final int? selectedRoutePointIndex;
  final void Function(int index)? onRoutePointPointerDown;
  final void Function(int index)? onRoutePointTap;
  final bool canDragRoutePoints;
  final void Function(int index)? onRoutePointDragStart;
  final void Function(int index, LatLng point)? onRoutePointDragUpdate;
  final void Function(int index, LatLng point)? onRoutePointDragEnd;
  final bool isSelectingRoutePoint;
  final void Function(LatLng)? onMapTap;
  final List<HazardReportRecord> hazardReports;
  final List<HazardReportRecord> visibleHazardCircles;
  final List<LostPetReportRecord> lostPetReports;
  final List<FoundPetReportRecord> foundPetReports;
  final List<GenericReportRecord> genericReports;
  final HazardReportRecord? highlightedHazard;
  final LatLng? hazardDraftLocation;
  final int? hazardDraftImpactRadiusMeters;
  final String? hazardDraftRiskLevelCode;
  final bool isSelectingHazardLocation;
  final LatLng? lostPetDraftLocation;
  final LatLng? foundPetDraftLocation;
  final LatLng? genericReportDraftLocation;
  final int? genericReportDraftImpactRadiusMeters;
  final String? genericReportDraftRiskLevelCode;
  final bool isSelectingReportLocation;
  final bool routeSelectionHintAtTop;
  final bool reportSelectionHintAtTop;
  final String reportSelectionHintText;
  final Color reportSelectionHintColor;
  final void Function(HazardReportRecord report)? onHazardTap;
  final void Function(LostPetReportRecord report)? onLostPetTap;
  final void Function(FoundPetReportRecord report)? onFoundPetTap;
  final void Function(GenericReportRecord report)? onGenericReportTap;
  final LatLng? cameraFocusTarget;
  final double? cameraFocusZoom;
  final int cameraFocusRevision;
  final void Function(LatLng location)? onUserLocationChanged;
  final void Function(bool isLoading, String? errorText)?
  onUserLocationStatusChanged;
  final int locationRefreshRevision;
  final LatLng? developerLocationMarker;
  final bool isDeveloperModifyingLocation;

  const MapWidget({
    super.key,
    required this.isDarkMode,
    required this.center,
    this.zoom = 13,
    this.onSettingsTap,
    this.onReportDangerTap,
    this.onModifyLocationTap,
    this.onStartTrip,
    this.onProfileTap,
    this.hideDefaultControls = false,
    this.keepReportDangerVisible = false,
    this.keepModifyLocationVisible = false,
    this.panelOverlay,
    this.routePoints = const [],
    this.routePolylinePoints = const [],
    this.coloredRouteSegments = const [],
    this.selectedRoutePointIndex,
    this.onRoutePointPointerDown,
    this.onRoutePointTap,
    this.canDragRoutePoints = false,
    this.onRoutePointDragStart,
    this.onRoutePointDragUpdate,
    this.onRoutePointDragEnd,
    this.isSelectingRoutePoint = false,
    this.onMapTap,
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
    this.routeSelectionHintAtTop = false,
    this.reportSelectionHintAtTop = false,
    this.reportSelectionHintText = 'Toca el mapa para ubicar el reporte',
    this.reportSelectionHintColor = AppPalette.primaryBlue,
    this.onHazardTap,
    this.onLostPetTap,
    this.onFoundPetTap,
    this.onGenericReportTap,
    this.cameraFocusTarget,
    this.cameraFocusZoom,
    this.cameraFocusRevision = 0,
    this.onUserLocationChanged,
    this.onUserLocationStatusChanged,
    this.locationRefreshRevision = 0,
    this.developerLocationMarker,
    this.isDeveloperModifyingLocation = false,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late MapController mapController;
  AnimationController? _cameraAnimationController;
  bool _isMapReady = false;
  bool _isDraggingRoutePoint = false;
  int? _draggingRoutePointIndex;
  LatLng? _draggingPoint;

  // Location tracking
  LatLng? _userLocation;
  double _userHeading = 0.0;
  bool _hasLocationPermission = false;
  bool _isCustomPositionMode = false;
  LatLng? _customUserLocation;
  StreamSubscription<Position>? _positionStreamSub;
  bool _isResolvingLocation = false;
  String? _userLocationErrorText;

  // Color cache for hazard rendering (avoid recalculation every frame)
  final Map<String, Color> _borderColorCache = {};
  final Map<String, Color> _fillColorCache = {};

  // Color palette
  static const Color primary = AppPalette.primaryBlue;
  static const Color secondary = Color(0xFF0F176E);
  static const Color white = AppPalette.white;
  static const Color contentGray = AppPalette.charcoal;
  static const Color translucentWhite = Color(0xCCFFFFFF);
  static const double _userFocusZoom = 17.5;
  static final LatLngBounds _caliBounds = LatLngBounds(
    const LatLng(3.289, -76.639),
    const LatLng(3.518, -76.445),
  );

  LatLng? get _effectiveUserLocation {
    return _isCustomPositionMode ? _customUserLocation : _userLocation;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    if (_isResolvingLocation) {
      return;
    }

    _emitUserLocationStatus(isLoading: true, errorText: null);

    try {
      _isResolvingLocation = true;
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _hasLocationPermission = false);
        }
        _emitUserLocationStatus(
          isLoading: false,
          errorText: 'Activa la ubicacion del dispositivo para continuar.',
        );
        return;
      }

      final LocationPermission permission =
          await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _hasLocationPermission = false);
        }
        _emitUserLocationStatus(
          isLoading: false,
          errorText: 'Debes habilitar los permisos de ubicacion.',
        );
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _hasLocationPermission = false);
        }
        _emitUserLocationStatus(
          isLoading: false,
          errorText:
              'Los permisos de ubicacion estan bloqueados. Debes habilitarlos manualmente.',
        );
      } else {
        if (mounted) {
          setState(() => _hasLocationPermission = true);
        }
        await _getCurrentLocationAndHeading();
        _startLocationTracking();
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      _emitUserLocationStatus(
        isLoading: false,
        errorText: 'No se pudo solicitar la ubicacion actual.',
      );
    } finally {
      _isResolvingLocation = false;
    }
  }

  Future<void> _getCurrentLocationAndHeading() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _userHeading = position.heading.isNaN ? 0.0 : position.heading;
        });
        _emitUserLocationStatus(isLoading: false, errorText: null);
        final LatLng? locationToEmit = _effectiveUserLocation;
        if (locationToEmit != null) {
          widget.onUserLocationChanged?.call(locationToEmit);
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _emitUserLocationStatus(
        isLoading: false,
        errorText: 'No se pudo obtener tu ubicacion actual.',
      );
    }
  }

  void _startLocationTracking() {
    if (!_hasLocationPermission) return;

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSub?.cancel();
    _positionStreamSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (mounted) {
              final LatLng nextLocation = LatLng(
                position.latitude,
                position.longitude,
              );
              setState(() {
                _userLocation = nextLocation;
                _userHeading = position.heading.isNaN
                    ? _userHeading
                    : position.heading;
              });
              if (!_isCustomPositionMode) {
                widget.onUserLocationChanged?.call(nextLocation);
              }
              _emitUserLocationStatus(isLoading: false, errorText: null);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Location stream error: $error');
            _emitUserLocationStatus(
              isLoading: false,
              errorText:
                  'Se perdio la actualizacion de ubicacion. Reintentando.',
            );

            if (!mounted) {
              return;
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _requestLocationPermission();
            });
          },
          onDone: () {
            if (!mounted) {
              return;
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _requestLocationPermission();
            });
          },
        );
  }

  Future<void> _toggleCustomPositionMode() async {
    if (_isCustomPositionMode) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCustomPositionMode = false;
      });

      final LatLng? locationToEmit = _effectiveUserLocation;
      if (locationToEmit != null) {
        widget.onUserLocationChanged?.call(locationToEmit);
      }
      widget.onModifyLocationTap?.call();
      return;
    }

    LatLng? seedLocation = _userLocation;
    if (seedLocation == null) {
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        seedLocation = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            _userLocation = seedLocation;
            _userHeading = position.heading.isNaN
                ? _userHeading
                : position.heading;
          });
        }
      } catch (e) {
        debugPrint('Error activating custom position mode: $e');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isCustomPositionMode = true;
      _customUserLocation = seedLocation;
    });

    final LatLng? locationToEmit = _effectiveUserLocation;
    if (locationToEmit != null) {
      widget.onUserLocationChanged?.call(locationToEmit);
    }
    widget.onModifyLocationTap?.call();
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
    _positionStreamSub?.cancel();
    mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _requestLocationPermission();
    });
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.locationRefreshRevision != oldWidget.locationRefreshRevision) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _requestLocationPermission();
      });
    }

    if (_isMapReady &&
        widget.cameraFocusTarget != null &&
        widget.cameraFocusRevision != oldWidget.cameraFocusRevision) {
      final LatLng focusTarget = widget.cameraFocusTarget!;
      final double nextZoom =
          widget.cameraFocusZoom ?? mapController.camera.zoom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateCameraFocus(focusTarget, nextZoom);
      });
    }
  }

  void _animateCameraFocus(LatLng center, double zoom) {
    if (!_isMapReady || !mounted) {
      return;
    }

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

    final Tween<double> latTween = Tween<double>(
      begin: startCenter.latitude,
      end: center.latitude,
    );
    final Tween<double> lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: center.longitude,
    );
    final Tween<double> zoomTween = Tween<double>(begin: startZoom, end: zoom);
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    bool hasTriggeredMove = false;

    _cameraAnimationController = controller;

    controller.addListener(() {
      if (!mounted || _cameraAnimationController != controller) {
        return;
      }

      final String moveId;
      if (animation.value == 1.0) {
        moveId = 'hazard-focus-finished';
      } else if (!hasTriggeredMove) {
        moveId =
            'hazard-focus-start#${center.latitude},${center.longitude},$zoom';
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
      if (_cameraAnimationController != controller) {
        return;
      }

      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _disposeCameraAnimation(controller);
      }
    });

    controller.forward();
  }

  void _cancelCameraAnimation() {
    _disposeCameraAnimation();
  }

  void _disposeCameraAnimation([AnimationController? controller]) {
    final AnimationController? activeController =
        controller ?? _cameraAnimationController;
    if (activeController == null) {
      return;
    }

    if (_cameraAnimationController == activeController) {
      _cameraAnimationController = null;
    }

    activeController.stop();
    activeController.dispose();
  }

  void _safeMove(LatLng center, double zoom) {
    if (!_isMapReady || !mounted) {
      return;
    }

    try {
      mapController.move(center, zoom);
    } catch (error) {
      debugPrint('Map move skipped due to runtime state: $error');
    }
  }

  void _emitUserLocationStatus({
    required bool isLoading,
    required String? errorText,
  }) {
    if (_userLocationErrorText == errorText &&
        _isResolvingLocation == isLoading) {
      return;
    }

    _isResolvingLocation = isLoading;
    _userLocationErrorText = errorText;
    widget.onUserLocationStatusChanged?.call(isLoading, errorText);
  }

  // Zoom In
  void _zoomIn() {
    if (!_isMapReady) return;
    final double nextZoom = (mapController.camera.zoom + 1).clamp(11.0, 22.0);
    _safeMove(mapController.camera.center, nextZoom);
  }

  // Zoom Out
  void _zoomOut() {
    if (!_isMapReady) return;
    final double nextZoom = (mapController.camera.zoom - 1).clamp(11.0, 22.0);
    _safeMove(mapController.camera.center, nextZoom);
  }

  void _centerOnUserLocation() {
    final LatLng? location = _effectiveUserLocation;
    if (!_isMapReady || location == null) {
      return;
    }

    _cancelCameraAnimation();
    final double targetZoom = math
        .max(mapController.camera.zoom, _userFocusZoom)
        .clamp(11.0, 22.0);
    _animateCameraFocus(location, targetZoom);
  }

  void _resetMapRotation() {
    if (!_isMapReady) {
      return;
    }

    final double currentRotation = mapController.camera.rotation;
    if (currentRotation.abs() < 0.01) {
      return;
    }

    try {
      mapController.moveAndRotate(
        mapController.camera.center,
        mapController.camera.zoom,
        0,
        id: 'reset-map-rotation',
      );
    } catch (error) {
      debugPrint('Map rotation reset skipped due to runtime state: $error');
    }
  }

  void _onReportarPeligro() {
    widget.onReportDangerTap?.call();
  }

  void _onIniciarViaje() {
    widget.onStartTrip?.call();
  }

  void _onProfileTap() {
    widget.onProfileTap?.call();
  }

  // Open settings panel
  void _openSettings() {
    widget.onSettingsTap?.call();
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

  Color _hazardBorderColor(HazardReportRecord report) {
    return _hazardBorderColorForRiskLevel(report.riskLevelCode);
  }

  Color _hazardFillColor(HazardReportRecord report) {
    return _hazardFillColorForRiskLevel(report.riskLevelCode);
  }

  Color _genericReportBorderColor(GenericReportRecord report) {
    return _hazardBorderColorForRiskLevel(report.riskLevelCode);
  }

  Color _genericReportFillColor(GenericReportRecord report) {
    return _hazardFillColorForRiskLevel(report.riskLevelCode);
  }

  LatLng _applyPixelDeltaToLatLng({
    required LatLng source,
    required Offset delta,
  }) {
    final double zoom = mapController.camera.zoom;
    final double latitudeRadians = source.latitude * (math.pi / 180.0);
    final double cosLat = math.cos(latitudeRadians).abs().clamp(0.0001, 1.0);
    final double metersPerPixel =
        156543.03392 * math.cos(latitudeRadians) / math.pow(2, zoom);

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

    final Color mapBackgroundColor = widget.isDarkMode
        ? const Color(0xFF1A1818)
        : const Color(0xFFEEEEEE);

    final bool isWeb = MediaQuery.of(context).size.width > 900;
    final bool controlsVisible = !widget.hideDefaultControls;
    final double topSystemInset = MediaQuery.of(context).padding.top;
    final bool reportDangerVisible =
        controlsVisible || widget.keepReportDangerVisible;
    final bool modifyLocationVisible =
        controlsVisible || widget.keepModifyLocationVisible;
    final bool isMobileTripOverlayActive =
        !controlsVisible && widget.keepReportDangerVisible;
    final double mobileBottomActionsOffset = isMobileTripOverlayActive
        ? 156
        : 16;

    return Stack(
      children: [
        // MAP
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: _caliBounds,
            ),
            onMapReady: () {
              if (_isMapReady || !mounted) {
                return;
              }
              _isMapReady = true;
              _prewarmTileCache();
            },
            minZoom: 11,
            maxZoom: 22,
            backgroundColor: mapBackgroundColor,
            keepAlive: true,
            interactionOptions: InteractionOptions(
              flags: _isDraggingRoutePoint
                  ? InteractiveFlag.none
                  : InteractiveFlag.all,
            ),
            onMapEvent: (MapEvent event) {
              if (_shouldCancelCameraAnimationForEvent(event)) {
                _cancelCameraAnimation();
              }
            },
            onTap: (TapPosition tapPosition, LatLng point) {
              if (_isCustomPositionMode) {
                setState(() {
                  _customUserLocation = point;
                });
                widget.onUserLocationChanged?.call(point);
                return;
              }
              widget.onMapTap?.call(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.app',
              maxNativeZoom: 19,
              minZoom: 11,
              maxZoom: 22,
              retinaMode: false,
              keepBuffer: 6,
              panBuffer: 3,
              tileDisplay: const TileDisplay.instantaneous(opacity: 1.0),
              tileUpdateTransformer: TileUpdateTransformers.throttle(
                const Duration(milliseconds: 90),
              ),
            ),
            // User location marker
            if (_effectiveUserLocation != null &&
                (_hasLocationPermission || _isCustomPositionMode))
              RepaintBoundary(
                child: MarkerLayer(
                  markers: [
                    Marker(
                      point: _effectiveUserLocation!,
                      width: 40,
                      height: 40,
                      child: _CurrentLocationMarker(heading: _userHeading),
                    ),
                  ],
                ),
              ),
            // Developer location marker
            if (widget.isDeveloperModifyingLocation &&
                widget.developerLocationMarker != null)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.developerLocationMarker!,
                      width: 50,
                      height: 50,
                      child: const _DeveloperLocationMarker(),
                    ),
                  ],
                ),
              ),
            if (widget.highlightedHazard != null)
              RepaintBoundary(
                child: CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        widget.highlightedHazard!.incidentLatitude,
                        widget.highlightedHazard!.incidentLongitude,
                      ),
                      color: _hazardFillColor(widget.highlightedHazard!),
                      borderColor: _hazardBorderColor(
                        widget.highlightedHazard!,
                      ),
                      borderStrokeWidth: 1.5,
                      useRadiusInMeter: true,
                      radius: widget.highlightedHazard!.impactRadiusMeters
                          .toDouble(),
                    ),
                  ],
                ),
              ),
            if (widget.highlightedHazard == null &&
                widget.visibleHazardCircles.isNotEmpty)
              RepaintBoundary(
                child: CircleLayer(
                  circles: widget.visibleHazardCircles
                      .map((HazardReportRecord report) {
                        return CircleMarker(
                          point: LatLng(
                            report.incidentLatitude,
                            report.incidentLongitude,
                          ),
                          color: _hazardFillColor(report),
                          borderColor: _hazardBorderColor(report),
                          borderStrokeWidth: 1.2,
                          useRadiusInMeter: true,
                          radius: report.impactRadiusMeters.toDouble(),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            if (widget.hazardDraftLocation != null &&
                widget.hazardDraftImpactRadiusMeters != null)
              RepaintBoundary(
                child: CircleLayer(
                  circles: [
                    CircleMarker(
                      point: widget.hazardDraftLocation!,
                      color: _hazardFillColorForRiskLevel(
                        widget.hazardDraftRiskLevelCode,
                      ),
                      borderColor: _hazardBorderColorForRiskLevel(
                        widget.hazardDraftRiskLevelCode,
                      ),
                      borderStrokeWidth: 1.5,
                      useRadiusInMeter: true,
                      radius: widget.hazardDraftImpactRadiusMeters!.toDouble(),
                    ),
                  ],
                ),
              ),
            if (widget.visibleHazardCircles.isNotEmpty)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: widget.visibleHazardCircles
                      .map((HazardReportRecord report) {
                        return Marker(
                          point: LatLng(
                            report.incidentLatitude,
                            report.incidentLongitude,
                          ),
                          width: 24,
                          height: 24,
                          child: GestureDetector(
                            onTap: () => widget.onHazardTap?.call(report),
                            child: _HazardMarkerWidget(
                              color: _hazardBorderColor(report),
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            if (widget.hazardDraftLocation != null)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.hazardDraftLocation!,
                      width: 24,
                      height: 24,
                      child: _HazardMarkerWidget(
                        color: _hazardBorderColorForRiskLevel(
                          widget.hazardDraftRiskLevelCode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.lostPetReports.isNotEmpty)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: widget.lostPetReports
                      .map((LostPetReportRecord report) {
                        return Marker(
                          point: LatLng(
                            report.lastSeenLatitude,
                            report.lastSeenLongitude,
                          ),
                          width: 24,
                          height: 24,
                          child: GestureDetector(
                            onTap: () => widget.onLostPetTap?.call(report),
                            child: const _HazardMarkerWidget(
                              color: AppPalette.reportYellow,
                              label: '?',
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            if (widget.foundPetReports.isNotEmpty)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: widget.foundPetReports
                      .map((FoundPetReportRecord report) {
                        return Marker(
                          point: LatLng(report.latitude, report.longitude),
                          width: 24,
                          height: 24,
                          child: GestureDetector(
                            onTap: () => widget.onFoundPetTap?.call(report),
                            child: const _HazardMarkerWidget(
                              color: AppPalette.reportGreen,
                              label: '!',
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            if (widget.genericReports.any(
              (GenericReportRecord report) => report.impactRadiusMeters > 0,
            ))
              RepaintBoundary(
                child: CircleLayer(
                  circles: widget.genericReports
                      .where(
                        (GenericReportRecord report) =>
                            report.impactRadiusMeters > 0,
                      )
                      .map((GenericReportRecord report) {
                        return CircleMarker(
                          point: LatLng(report.latitude, report.longitude),
                          color: _genericReportFillColor(report),
                          borderColor: _genericReportBorderColor(report),
                          borderStrokeWidth: 1.2,
                          useRadiusInMeter: true,
                          radius: report.impactRadiusMeters.toDouble(),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            if (widget.genericReports.isNotEmpty)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: widget.genericReports
                      .map((GenericReportRecord report) {
                        return Marker(
                          point: LatLng(report.latitude, report.longitude),
                          width: 24,
                          height: 24,
                          child: GestureDetector(
                            onTap: () =>
                                widget.onGenericReportTap?.call(report),
                            child: const _HazardMarkerWidget(
                              color: AppPalette.charcoal,
                              label: 'i',
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            if (widget.lostPetDraftLocation != null)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.lostPetDraftLocation!,
                      width: 24,
                      height: 24,
                      child: const _HazardMarkerWidget(
                        color: AppPalette.reportYellow,
                        label: '?',
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.foundPetDraftLocation != null)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.foundPetDraftLocation!,
                      width: 24,
                      height: 24,
                      child: const _HazardMarkerWidget(
                        color: AppPalette.reportGreen,
                        label: '!',
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.genericReportDraftLocation != null &&
                widget.genericReportDraftImpactRadiusMeters != null &&
                widget.genericReportDraftImpactRadiusMeters! > 0)
              RepaintBoundary(
                child: CircleLayer(
                  circles: [
                    CircleMarker(
                      point: widget.genericReportDraftLocation!,
                      color: _hazardFillColorForRiskLevel(
                        widget.genericReportDraftRiskLevelCode,
                      ),
                      borderColor: _hazardBorderColorForRiskLevel(
                        widget.genericReportDraftRiskLevelCode,
                      ),
                      borderStrokeWidth: 1.5,
                      useRadiusInMeter: true,
                      radius: widget.genericReportDraftImpactRadiusMeters!
                          .toDouble(),
                    ),
                  ],
                ),
              ),
            if (widget.genericReportDraftLocation != null)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.genericReportDraftLocation!,
                      width: 24,
                      height: 24,
                      child: const _HazardMarkerWidget(
                        color: AppPalette.charcoal,
                        label: 'i',
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.routePolylinePoints.length >= 2)
              RepaintBoundary(
                child: PolylineLayer(polylines: _buildRoutePolylines()),
              ),
            if (widget.routePoints.isNotEmpty)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: List<Marker>.generate(
                    widget.routePoints.length,
                    (int index) => Marker(
                      point: widget.routePoints[index],
                      width: 28,
                      height: 28,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) =>
                            widget.onRoutePointPointerDown?.call(index),
                        onTap: () => widget.onRoutePointTap?.call(index),
                        onPanStart: widget.canDragRoutePoints
                            ? (_) {
                                setState(() {
                                  _isDraggingRoutePoint = true;
                                  _draggingRoutePointIndex = index;
                                  _draggingPoint = widget.routePoints[index];
                                });
                                widget.onRoutePointDragStart?.call(index);
                              }
                            : null,
                        onPanUpdate: widget.canDragRoutePoints
                            ? (DragUpdateDetails details) {
                                if (_draggingRoutePointIndex != index ||
                                    _draggingPoint == null) {
                                  return;
                                }

                                final LatLng next = _applyPixelDeltaToLatLng(
                                  source: _draggingPoint!,
                                  delta: details.delta,
                                );
                                _draggingPoint = next;
                                widget.onRoutePointDragUpdate?.call(
                                  index,
                                  next,
                                );
                              }
                            : null,
                        onPanEnd: widget.canDragRoutePoints
                            ? (_) {
                                final LatLng? finalPoint = _draggingPoint;
                                setState(() {
                                  _isDraggingRoutePoint = false;
                                  _draggingRoutePointIndex = null;
                                  _draggingPoint = null;
                                });
                                if (finalPoint != null) {
                                  widget.onRoutePointDragEnd?.call(
                                    index,
                                    finalPoint,
                                  );
                                }
                              }
                            : null,
                        child: _NumberedMapMarker(
                          number: index + 1,
                          isSelected: widget.selectedRoutePointIndex == index,
                        ),
                      ),
                    ),
                  ).toList(growable: false),
                ),
              ),
          ],
        ),

        // MOBILE LAYOUT
        if (!isWeb) ...[
          // Bottom area - Mobile: expanded action buttons
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
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onReportarPeligro,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reportar',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (controlsVisible) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onIniciarViaje,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Iniciar Viaje',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Right: zoom buttons anchored above bottom action buttons
          Positioned(
            right: 16,
            bottom: 160,
            child: SafeArea(
              child: _buildAnimatedControl(
                visible: controlsVisible,
                hiddenOffset: const Offset(0.06, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomButton(
                      icon: Icons.add,
                      onPressed: _zoomIn,
                      isTop: true,
                    ),
                    const SizedBox(height: 8),
                    _buildZoomButton(
                      icon: Icons.remove,
                      onPressed: _zoomOut,
                      isTop: false,
                    ),
                  ],
                ),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapActionButton(
                      icon: Icons.my_location,
                      onPressed: _centerOnUserLocation,
                    ),
                    const SizedBox(height: 8),
                    _buildMapActionButton(
                      icon: Icons.explore_outlined,
                      onPressed: _resetMapRotation,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // User profile button - Mobile (top left corner)
          Positioned(
            top: 16 + topSystemInset,
            left: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(-0.06, 0),
              child: GestureDetector(
                onTap: _onProfileTap,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: translucentWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: contentGray,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Settings button - Mobile (top right corner)
          Positioned(
            top: 16 + topSystemInset,
            right: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(0.06, 0),
              child: GestureDetector(
                onTap: _openSettings,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: translucentWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: contentGray,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // WEB LAYOUT
        if (isWeb) ...[
          // "Report Danger" button - Web (bottom left corner)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildAnimatedControl(
              visible: reportDangerVisible,
              hiddenOffset: const Offset(-0.06, 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onReportarPeligro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reportar',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Start Trip + Zoom controls - Web (bottom right corner)
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
                  // Zoom buttons (above Start Trip), right-aligned
                  _buildZoomButton(
                    icon: Icons.add,
                    onPressed: _zoomIn,
                    isTop: true,
                  ),
                  const SizedBox(height: 8),
                  _buildZoomButton(
                    icon: Icons.remove,
                    onPressed: _zoomOut,
                    isTop: false,
                  ),
                  const SizedBox(height: 12),
                  // Start Trip - larger, below zoom buttons
                  SizedBox(
                    width: 220,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onIniciarViaje,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Iniciar Viaje',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapActionButton(
                    icon: Icons.my_location,
                    onPressed: _centerOnUserLocation,
                  ),
                  const SizedBox(height: 8),
                  _buildMapActionButton(
                    icon: Icons.explore_outlined,
                    onPressed: _resetMapRotation,
                  ),
                ],
              ),
            ),
          ),

          // User profile button - Web (top left corner)
          Positioned(
            top: 16 + topSystemInset,
            left: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(-0.06, 0),
              child: GestureDetector(
                onTap: _onProfileTap,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: contentGray,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Settings button - Web (top right corner)
          Positioned(
            top: 16 + topSystemInset,
            right: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(0.06, 0),
              child: GestureDetector(
                onTap: _openSettings,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: translucentWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: contentGray,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Modify location button - Dev tool, visible on both mobile and web
        Positioned(
          top: 72 + topSystemInset,
          right: 16,
          child: _buildAnimatedControl(
            visible: modifyLocationVisible,
            hiddenOffset: const Offset(0.06, 0),
            child: GestureDetector(
              onTap: _toggleCustomPositionMode,
              child: SizedBox(
                width: 48,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _isCustomPositionMode
                        ? AppPalette.primaryBlue.withValues(alpha: 0.92)
                        : translucentWhite,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: _isCustomPositionMode ? white : contentGray,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildSelectionHintPositioned(
          isWeb: isWeb,
          topSystemInset: topSystemInset,
          anchorTop: widget.routeSelectionHintAtTop,
          bottomOffset: isWeb ? 24 : 20,
          visible: widget.isSelectingRoutePoint,
          child: _buildSelectionHint(
            color: AppPalette.primaryBlue,
            icon: Icons.touch_app,
            text: 'Toca el mapa para agregar el punto',
          ),
        ),
        _buildSelectionHintPositioned(
          isWeb: isWeb,
          topSystemInset: topSystemInset,
          anchorTop: widget.reportSelectionHintAtTop,
          bottomOffset: isWeb ? 72 : 68,
          visible:
              widget.isSelectingHazardLocation ||
              widget.isSelectingReportLocation,
          child: _buildSelectionHint(
            color: widget.isSelectingHazardLocation
                ? _hazardBorderColorForRiskLevel(
                    widget.hazardDraftRiskLevelCode,
                  )
                : widget.reportSelectionHintColor,
            icon: Icons.place_rounded,
            text: widget.isSelectingHazardLocation
                ? 'Toca el mapa para ubicar el peligro'
                : widget.reportSelectionHintText,
          ),
        ),
        if (widget.panelOverlay != null)
          Positioned.fill(child: widget.panelOverlay!),
      ],
    );
  }

  // Reusable widget for map action buttons
  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton(
        mini: true,
        onPressed: onPressed,
        backgroundColor: translucentWhite,
        foregroundColor: contentGray,
        elevation: 0,
        shape: const CircleBorder(),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isTop,
  }) {
    return _buildMapActionButton(icon: icon, onPressed: onPressed);
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

  Widget _buildSelectionHint({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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

  /// Construye las polylines para la ruta, considerando segmentos coloreados si existen
  List<Polyline> _buildRoutePolylines() {
    if (widget.coloredRouteSegments.isNotEmpty) {
      // Si hay segmentos coloreados, renderizar cada uno con su color
      return (widget.coloredRouteSegments as List<ColoredRouteSegment>)
          .where((ColoredRouteSegment segment) => segment.points.length >= 2)
          .map(
            (ColoredRouteSegment segment) => Polyline(
              points: segment.points,
              color: segment.color,
              strokeWidth: 2.0,
            ),
          )
          .toList();
    } else {
      // Si no hay segmentos coloreados, renderizar la ruta normal (azul)
      return [
        Polyline(
          points: widget.routePolylinePoints,
          color: AppPalette.primaryBlue,
          strokeWidth: 2.0,
        ),
      ];
    }
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
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
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
      angle: (heading * math.pi) / 180, // Convert degrees to radians
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blue circle
          SizedBox(
            width: 36,
            height: 36,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppPalette.primaryBlue.withValues(alpha: 0.30),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // White center dot
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
          // Direction indicator (small tip)
          Positioned(
            top: 1,
            child: CustomPaint(
              size: const Size(10, 10),
              painter: _ArrowPainter(),
            ),
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
        // Outer pulsing circle
        ScaleTransition(
          scale: AlwaysStoppedAnimation(1.0),
          child: SizedBox(
            width: 50,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF5984BC).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        // Inner circle
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
        // Center dot
        SizedBox(
          width: 10,
          height: 10,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
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
