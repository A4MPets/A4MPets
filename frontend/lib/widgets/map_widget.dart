import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

import '../theme/app_palette.dart';

class MapWidget extends StatefulWidget {
  final bool isDarkMode;
  final LatLng center;
  final double zoom;
  final VoidCallback? onThemeToggle;
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

  const MapWidget({
    super.key,
    required this.isDarkMode,
    required this.center,
    this.zoom = 13,
    this.onThemeToggle,
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
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapController mapController;
  double currentZoom = 13;
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
    currentZoom = widget.zoom;
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  // Zoom In
  void _zoomIn() {
    if (currentZoom < 17) {
      mapController.move(mapController.camera.center, currentZoom + 1);
      setState(() => currentZoom += 1);
    }
  }

  // Zoom Out
  void _zoomOut() {
    if (currentZoom > 11) {
      mapController.move(mapController.camera.center, currentZoom - 1);
      setState(() => currentZoom -= 1);
    }
  }

  // Report Danger - Ready to add functionality
  void _onReportarPeligro() {
    // TODO: Implement logic to report danger
    print('Report Danger - To implement');
  }

  // Start Trip - Ready to add functionality
  void _onIniciarViaje() {
    // TODO: Implement logic to start trip
    widget.onStartTrip?.call();
    print('Start Trip - To implement');
  }

  // Profile - Ready to add functionality
  void _onProfileTap() {
    widget.onProfileTap?.call();
  }

  // Toggle theme
  void _toggleTheme() {
    widget.onThemeToggle?.call();
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
        ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png';

    final bool isWeb = MediaQuery.of(context).size.width > 900;
    final bool controlsVisible = !widget.hideDefaultControls;

    return Stack(
      children: [
        // MAP
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.zoom,
            minZoom: 11,
            maxZoom: 17,
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
            ),
            if (widget.routePolylinePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePolylinePoints,
                    color: AppPalette.primaryBlue,
                    strokeWidth: 3.0,
                  ),
                ],
              ),
            if (widget.routePoints.isNotEmpty)
              MarkerLayer(
                markers: List<Marker>.generate(
                  widget.routePoints.length,
                  (int index) => Marker(
                    point: widget.routePoints[index],
                    width: 30,
                    height: 30,
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

          // Theme toggle button - Mobile (top right corner) - square with rounded corners
          Positioned(
            top: 16,
            right: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(0.06, 0),
              child: GestureDetector(
                onTap: _toggleTheme,
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
                  child: Icon(
                    widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
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

          // Theme toggle button - Web (top right corner) - square with rounded corners
          Positioned(
            top: 16,
            right: 16,
            child: _buildAnimatedControl(
              visible: controlsVisible,
              hiddenOffset: const Offset(0.06, 0),
              child: GestureDetector(
                onTap: _toggleTheme,
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
                  child: Icon(
                    widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : hiddenOffset,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
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
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppPalette.dangerRed : AppPalette.primaryBlue,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
