import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../models/hazard_report_record.dart';
import '../models/colored_route_segment.dart';
import '../theme/app_palette.dart';

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
  final HazardReportRecord? highlightedHazard;
  final void Function(HazardReportRecord report)? onHazardTap;
  final LatLng? cameraFocusTarget;
  final double? cameraFocusZoom;
  final int cameraFocusRevision;
  final void Function(LatLng location)? onUserLocationChanged;
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
    this.highlightedHazard,
    this.onHazardTap,
    this.cameraFocusTarget,
    this.cameraFocusZoom,
    this.cameraFocusRevision = 0,
    this.onUserLocationChanged,
    this.developerLocationMarker,
    this.isDeveloperModifyingLocation = false,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapController mapController;
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

  // Color cache for hazard rendering (avoid recalculation every frame)
  final Map<String, Color> _borderColorCache = {};
  final Map<String, Color> _fillColorCache = {};

  // Color palette
  static const Color primary = AppPalette.primaryBlue;
  static const Color secondary = Color(0xFF0F176E);
  static const Color white = AppPalette.white;
  static const Color contentGray = AppPalette.charcoal;
  static const Color translucentWhite = Color(0xCCFFFFFF);

  LatLng? get _effectiveUserLocation {
    return _isCustomPositionMode ? _customUserLocation : _userLocation;
  }

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _hasLocationPermission = false);
        return;
      }

      final LocationPermission permission =
          await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _hasLocationPermission = false);
      } else if (permission == LocationPermission.deniedForever) {
        setState(() => _hasLocationPermission = false);
      } else {
        setState(() => _hasLocationPermission = true);
        await _getCurrentLocationAndHeading();
        _startLocationTracking();
      }
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
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
        final LatLng? locationToEmit = _effectiveUserLocation;
        if (locationToEmit != null) {
          widget.onUserLocationChanged?.call(locationToEmit);
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
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
            }
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
            _userHeading = position.heading.isNaN ? _userHeading : position.heading;
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
    _positionStreamSub?.cancel();
    mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isMapReady &&
        widget.cameraFocusTarget != null &&
        widget.cameraFocusRevision != oldWidget.cameraFocusRevision) {
      final LatLng focusTarget = widget.cameraFocusTarget!;
      final double nextZoom =
          widget.cameraFocusZoom ?? mapController.camera.zoom;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _safeMove(focusTarget, nextZoom);
      });
    }
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

  // Report Danger - Ready to add functionality
  void _onReportarPeligro() {
    widget.onReportDangerTap?.call();
  }

  // Start Trip - Ready to add functionality
  void _onIniciarViaje() {
    // TODO: Implement logic to start trip
    widget.onStartTrip?.call();
  }

  // Profile - Ready to add functionality
  void _onProfileTap() {
    widget.onProfileTap?.call();
  }

  // Open settings panel
  void _openSettings() {
    widget.onSettingsTap?.call();
  }

  Color _hazardBorderColor(HazardReportRecord report) {
    final String key = '${report.riskLevelCode}_border';
    return _borderColorCache.putIfAbsent(key, () {
      switch (report.riskLevelCode) {
        case 'low':
          return AppPalette.dangerYellow;
        case 'medium':
          return AppPalette.dangerOrange;
        default:
          return AppPalette.dangerRed;
      }
    });
  }

  Color _hazardFillColor(HazardReportRecord report) {
    final String key = '${report.riskLevelCode}_fill';
    return _fillColorCache.putIfAbsent(key, () {
      switch (report.riskLevelCode) {
        case 'low':
          return AppPalette.dangerYellow40;
        case 'medium':
          return AppPalette.dangerOrange40;
        default:
          return AppPalette.dangerRed40;
      }
    });
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
    final bool reportDangerVisible =
        controlsVisible || widget.keepReportDangerVisible;
    final bool modifyLocationVisible =
      controlsVisible || widget.keepModifyLocationVisible;

    return Stack(
      children: [
        // MAP
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
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
            if (widget.hazardReports.isNotEmpty)
              RepaintBoundary(
                child: MarkerLayer(
                  markers: widget.hazardReports
                      .map((HazardReportRecord report) {
                        return Marker(
                          point: LatLng(
                            report.incidentLatitude,
                            report.incidentLongitude,
                          ),
                          width: 16,
                          height: 16,
                          child: GestureDetector(
                            onTap: () => widget.onHazardTap?.call(report),
                            child: const _HazardMarkerWidget(),
                          ),
                        );
                      })
                      .toList(growable: false),
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
            bottom: 16,
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
                            'Reportar Peligro',
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

          // User profile button - Mobile (top left corner)
          Positioned(
            top: 16,
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
            top: 16,
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
              child: SizedBox(
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
                    'Reportar Peligro',
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

          // User profile button - Web (top left corner)
          Positioned(
            top: 16,
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
            top: 16,
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

          // Modify location button - Web (dev tool, below settings)
          Positioned(
            top: 72,
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

        ],

        if (widget.isSelectingRoutePoint)
          Positioned(
            bottom: isWeb ? 24 : 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Toca el mapa para agregar el punto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.panelOverlay != null)
          Positioned.fill(child: widget.panelOverlay!),
      ],
    );
  }

  // Reusable widget for zoom buttons
  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isTop,
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
  const _HazardMarkerWidget();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.dangerRed,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 0.8),
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
                color: const Color(0xFF5984BC).withOpacity(0.3),
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
              color: const Color(0xFF5984BC).withOpacity(0.7),
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
