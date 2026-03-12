import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsmRoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org';

  Future<List<LatLng>> buildRoadRoute({
    required List<LatLng> waypoints,
  }) async {
    if (waypoints.length < 2) {
      return waypoints;
    }

    final String coordinates = waypoints
        .map((LatLng point) => '${point.longitude},${point.latitude}')
        .join(';');

    final Uri uri = Uri.parse(
      '$_baseUrl/route/v1/driving/$coordinates?overview=full&geometries=geojson',
    );

    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('OSRM respondió con código ${response.statusCode}.');
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic>? routes = decoded['routes'] as List<dynamic>?;

    if (routes == null || routes.isEmpty) {
      throw Exception('No se encontró una ruta vial para esos puntos.');
    }

    final Map<String, dynamic>? geometry =
        routes.first['geometry'] as Map<String, dynamic>?;

    final List<dynamic>? coords = geometry?['coordinates'] as List<dynamic>?;

    if (coords == null || coords.isEmpty) {
      throw Exception('La geometría de la ruta llegó vacía.');
    }

    return coords.map((dynamic raw) {
      final List<dynamic> pair = raw as List<dynamic>;
      return LatLng(
        (pair[1] as num).toDouble(),
        (pair[0] as num).toDouble(),
      );
    }).toList();
  }
}
