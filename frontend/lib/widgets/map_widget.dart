import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import '../models/hazard_report_record.dart';
import '../theme/app_palette.dart';

class MapWidget extends StatefulWidget {
  final bool isDarkMode;
  final LatLng center;
  final double zoom;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onReportDangerTap;
  final VoidCallback? onStartTrip;
  final VoidCallback? onProfileTap;
  final bool hideDefaultControls;
  final Widget? panelOverlay;
  final List<LatLng> routePoints;
  final List<LatLng> routePolylinePoints;
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

  const MapWidget({
    super.key,
    required this.isDarkMode,
    required this.center,
    this.zoom = 13,
    this.onSettingsTap,
    this.onReportDangerTap,
    this.onStartTrip,
    this.onProfileTap,
    this.hideDefaultControls = false,
    this.panelOverlay,
    this.routePoints = const [],
    this.routePolylinePoints = const [],
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
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  static final LatLngBounds _caliBounds = LatLngBounds(
    LatLng(3.3000, -76.6500),
    LatLng(3.5500, -76.4500),
  );
  static const double _minZoomLevel = 11;
  static const double _maxZoomLevel = 22;

  late MapController mapController;
  bool _isDraggingRoutePoint = false;
  int? _draggingRoutePointIndex;
  LatLng? _draggingPoint;

  // Color palette
  static const Color primary = AppPalette.primaryBlue; // Primary color - "Start Trip" button
  static const Color secondary = Color(0xFF0F176E); // Secondary color - "Report Danger" buttron
  static const Color white = AppPalette.white;
  static const Color contentGray = AppPalette.charcoal; // Text/icon color inside translucent buttons
  static const Color translucentWhite = Color(0xCCFFFFFF); // White with 0.8 alpha

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prewarmTileCache();
    });
  }

  void _prewarmTileCache() {
    final LatLng caliCenter = const LatLng(3.4372, -76.5197);
    final List<double> zoomLevels = [11.0, 12.0, 13.0, 14.0, 15.0, 16.0];
    for (final double zoom in zoomLevels) {
      mapController.move(caliCenter, zoom);
    }
    mapController.move(caliCenter, 13.0);
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.cameraFocusTarget != null &&
        widget.cameraFocusRevision != oldWidget.cameraFocusRevision) {
      final double nextZoom =
          widget.cameraFocusZoom ?? mapController.camera.zoom;
      mapController.move(widget.cameraFocusTarget!, nextZoom);
    }
  }

  // Zoom In
  void _zoomIn() {
    final double zoom = mapController.camera.zoom;
    if (zoom >= _maxZoomLevel) return;
    mapController.move(mapController.camera.center, (zoom + 1).clamp(_minZoomLevel, _maxZoomLevel));
  }

  // Zoom Out
  void _zoomOut() {
    final double zoom = mapController.camera.zoom;
    if (zoom <= _minZoomLevel) return;
    mapController.move(mapController.camera.center, (zoom - 1).clamp(_minZoomLevel, _maxZoomLevel));
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
    switch (report.riskLevelCode) {
      case 'low':
        return AppPalette.dangerYellow;
      case 'medium':
        return AppPalette.dangerOrange;
      default:
        return AppPalette.dangerRed;
    }
  }

  Color _hazardFillColor(HazardReportRecord report) {
    switch (report.riskLevelCode) {
      case 'low':
        return AppPalette.dangerYellow40;
      case 'medium':
        return AppPalette.dangerOrange40;
      default:
        return AppPalette.dangerRed40;
    }
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

    return LatLng(
      source.latitude + deltaLat,
      source.longitude + deltaLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String tileUrl = widget.isDarkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    final Color mapBackgroundColor = widget.isDarkMode
      ? AppPalette.cardDark
      : AppPalette.cardLight;

    final bool isWeb = MediaQuery.of(context).size.width > 900;
    final bool controlsVisible = !widget.hideDefaultControls;

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: mapBackgroundColor),
        ),
        // MAP
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            minZoom: _minZoomLevel,
            maxZoom: _maxZoomLevel,
            backgroundColor: mapBackgroundColor,
            keepAlive: true,
            cameraConstraint: CameraConstraint.contain(bounds: _caliBounds),
            interactionOptions: InteractionOptions(
              flags:
                  _isDraggingRoutePoint ? InteractiveFlag.none : InteractiveFlag.all,
            ),
            onTap: (TapPosition tapPosition, LatLng point) {
              widget.onMapTap?.call(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.app',
              maxNativeZoom: 22,
              minZoom: _minZoomLevel,
              maxZoom: _maxZoomLevel,
              retinaMode: false,
              keepBuffer: 12,
              panBuffer: 6,
              tileDisplay: const TileDisplay.instantaneous(opacity: 1.0),
              tileUpdateTransformer:
                  TileUpdateTransformers.throttle(Duration(milliseconds: 150)),
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
                      borderColor:
                          _hazardBorderColor(widget.highlightedHazard!),
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
                          borderStrokeWidth: 1.0,
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
                      width: 18,
                      height: 18,
                      child: GestureDetector(
                        onTap: () => widget.onHazardTap?.call(report),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppPalette.dangerRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppPalette.white,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ),
            if (widget.routePolylinePoints.length >= 2)
              RepaintBoundary(
                child: PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routePolylinePoints,
                      color: AppPalette.primaryBlue,
                      strokeWidth: 2.5,
                    ),
                  ],
                ),
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
                      onTapDown: (_) => widget.onRoutePointPointerDown?.call(index),
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
                              widget.onRoutePointDragUpdate?.call(index, next);
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
                                widget.onRoutePointDragEnd?.call(index, finalPoint);
                              }
                            }
                          : null,
                      child: _NumberedMapMarker(
                        number: index + 1,
                        isSelected: widget.selectedRoutePointIndex == index,
                      ),
                    ),
                    ),
                  ),
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
                visible: controlsVisible,
                hiddenOffset: const Offset(0, 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: translucentWhite,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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

          // Settings button - Mobile (top right corner)
          Positioned(
            top: 16,
            right: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(0.06, 0),
              child: GestureDetector(
                onTap: _openSettings,
              child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: translucentWhite,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
        ],

        // WEB LAYOUT
        if (isWeb) ...[
          // "Report Danger" button - Web (bottom left corner)
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
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
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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

          // Settings button - Web (top right corner)
          Positioned(
            top: 16,
            right: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(0.06, 0),
              child: GestureDetector(
                onTap: _openSettings,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: translucentWhite,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
        ],

        if (widget.isSelectingRoutePoint)
          Positioned(
            bottom: isWeb ? 24 : 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
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
          Positioned.fill(
            child: widget.panelOverlay!,
          ),
      ],
    );
  }

  // Reusable widget for zoom buttons
  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isTop,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isTop ? 8 : 0,
      ),
      child: FloatingActionButton(
        mini: true,
        onPressed: onPressed,
        backgroundColor: translucentWhite,
        foregroundColor: contentGray,
        elevation: 4,
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
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : hiddenOffset,
          duration: const Duration(milliseconds: 100),
          curve: Curves.linear,
          child: child,
        ),
      ),
    );
  }
}

class _NumberedMapMarker extends StatelessWidget {
  final int number;
  final bool isSelected;

  const _NumberedMapMarker({
    required this.number,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? AppPalette.dangerRed : AppPalette.primaryBlue,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isSelected ? 2.0 : 1.5,
        ),
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
