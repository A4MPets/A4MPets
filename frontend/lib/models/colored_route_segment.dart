import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

/// Representa un segmento de ruta con información de color y peligro
/// Utilizado para renderizar rutas con diferentes colores según detección de hazards
class ColoredRouteSegment {
  /// Puntos que componen este segmento de ruta
  final List<LatLng> points;
  
  /// Color a usar para renderizar este segmento
  final Color color;
  
  /// Si este segmento intersecta con un hazard
  final bool hasHazard;

  const ColoredRouteSegment({
    required this.points,
    required this.color,
    required this.hasHazard,
  });
}
