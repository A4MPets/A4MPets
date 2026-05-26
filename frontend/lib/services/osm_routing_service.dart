import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/planned_route_result.dart';
import '../models/route_navigation_instruction.dart';

class OsmRoutingService {
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'A4M_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static String? _workingApiBaseUrl;

  OsmRoutingService();

  List<String> get _apiBaseUrls {
    final List<String> urls = <String>[
      if (_workingApiBaseUrl != null && _workingApiBaseUrl!.isNotEmpty)
        _workingApiBaseUrl!,
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

  Future<PlannedRouteResult> buildRoadRoute({
    required List<LatLng> waypoints,
    List<String> hazardRiskFilters = const <String>[],
    String travelMode = 'walking',
    Map<String, Object?>? tripConfig,
  }) async {
    if (waypoints.length < 2) {
      return PlannedRouteResult(
        polyline: List<LatLng>.from(waypoints),
        navigationInstructions: const <RouteNavigationInstruction>[],
        distanceMeters: 0,
        durationSeconds: 0,
        profile: travelMode,
        hazardsConsidered: 0,
      );
    }

    final List<String> normalizedRiskFilters = hazardRiskFilters
        .map((String value) => value.trim().toLowerCase())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final bool avoidHazards = normalizedRiskFilters.isNotEmpty;

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
      'hazard_risk_filters': normalizedRiskFilters,
      'travel_mode': travelMode,
      'trip_config': tripConfig ?? <String, Object?>{},
    };

    http.Response? response;
    for (final String baseUrl in _apiBaseUrls) {
      try {
        final http.Response current = await http
            .post(
              Uri.parse('$baseUrl/routes/plan'),
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 8));

        if (current.statusCode < 500) {
          _workingApiBaseUrl = baseUrl;
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

    final List<LatLng> polyline = coords
        .map((dynamic raw) {
          final List<dynamic> pair = raw as List<dynamic>;
          return LatLng(
            (pair[1] as num).toDouble(),
            (pair[0] as num).toDouble(),
          );
        })
        .toList(growable: false);
    final List<RouteNavigationInstruction> navigationInstructions =
        (data?['navigation_instructions'] as List<dynamic>? ??
                const <dynamic>[])
            .map(
              (dynamic raw) => RouteNavigationInstruction.fromMap(
                (raw as Map<String, dynamic>),
              ),
            )
            .toList(growable: false);

    return PlannedRouteResult(
      polyline: polyline,
      navigationInstructions: navigationInstructions,
      distanceMeters: (data?['distance_meters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data?['duration_seconds'] as num?)?.toDouble() ?? 0,
      profile: data?['profile']?.toString() ?? travelMode,
      hazardsConsidered: (data?['hazards_considered'] as num?)?.toInt() ?? 0,
    );
  }
}
