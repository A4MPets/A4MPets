import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsmRoutingService {
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'A4M_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  OsmRoutingService();

  List<String> get _apiBaseUrls {
    final List<String> urls = <String>[
      ..._splitConfiguredBaseUrls(_configuredApiBaseUrl),
      'http://127.0.0.1:8000/api',
      if (!kIsWeb) 'http://10.0.2.2:8000/api',
    ];

    final Set<String> seen = <String>{};
    return urls.where((String url) => seen.add(url)).toList(growable: false);
  }

  List<String> _splitConfiguredBaseUrls(String rawValue) {
    return rawValue
        .split(RegExp(r'[\s,;]+'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<LatLng>> buildRoadRoute({
    required List<LatLng> waypoints,
    bool avoidHazards = false,
    String travelMode = 'walking',
    Map<String, Object?>? tripConfig,
  }) async {
    if (waypoints.length < 2) {
      return waypoints;
    }

    final Map<String, Object?> payload = <String, Object?>{
      'points': waypoints
          .map(
            (LatLng point) => <String, double>{
              'lat': point.latitude,
              'lng': point.longitude,
            },
          )
          .toList(growable: false),
      'avoid_hazards': avoidHazards,
      'travel_mode': travelMode,
      'trip_config': tripConfig ?? <String, Object?>{},
    };

    http.Response? response;
    for (final String baseUrl in _apiBaseUrls) {
      try {
        final http.Response current = await http
            .post(
              Uri.parse('$baseUrl/routes/plan'),
              headers: <String, String>{'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 8));

        if (current.statusCode < 500) {
          response = current;
          break;
        }
      } catch (_) {
        continue;
      }
    }

    if (response == null) {
      throw Exception('No fue posible conectar con el backend de rutas.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Backend de rutas respondió con código ${response.statusCode}.',
      );
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      throw Exception('El backend no pudo calcular la ruta.');
    }

    final Map<String, dynamic>? data = decoded['data'] as Map<String, dynamic>?;
    final List<dynamic>? coords = data?['coordinates'] as List<dynamic>?;

    if (coords == null || coords.isEmpty) {
      throw Exception('La geometría de la ruta llegó vacía.');
    }

    return coords.map((dynamic raw) {
      final List<dynamic> pair = raw as List<dynamic>;
      return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
    }).toList();
  }
}
