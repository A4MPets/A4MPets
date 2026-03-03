import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final bool isDarkMode;
  final LatLng center;
  final double zoom;

  const MapWidget({
    super.key,
    required this.isDarkMode,
    required this.center,
    this.zoom = 13,
  });

  @override
  Widget build(BuildContext context) {
    final String tileUrl = isDarkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png';

    final LatLngBounds caliBounds = LatLngBounds(
      const LatLng(3.30, -76.60), // SW
      const LatLng(3.52, -76.45), // NE
    );

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,

        // 🔒 Limitar zoom
        minZoom: 11,
        maxZoom: 17,

        // 🔒 Limitar desplazamiento
        cameraConstraint: CameraConstraint.contain(bounds: caliBounds),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.app',
        ),
      ],
    );
  }
}
