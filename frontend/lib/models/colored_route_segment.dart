import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ColoredRouteSegment {
  final List<LatLng> points;
  final Color color;
  final bool hasHazard;

  const ColoredRouteSegment({required this.points, required this.color, required this.hasHazard});
}
