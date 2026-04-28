import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/generic_report_record.dart';
import 'package:frontend/services/route_hazard_visualizer_service.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('generic reports with zero radius do not affect route hazards', () {
    final List<LatLng> route = <LatLng>[
      const LatLng(4.6500, -74.1000),
      const LatLng(4.6500, -74.0990),
    ];

    final segments = RouteHazardVisualizerService.analyzeRouteHazards(
      routePolyline: route,
      hazards: const [],
      genericReports: <GenericReportRecord>[_buildGenericReport(0)],
    );

    expect(segments.every((segment) => segment.hasHazard == false), isTrue);
  });

  test('generic reports with positive radius affect route hazards', () {
    final List<LatLng> route = <LatLng>[
      const LatLng(4.6500, -74.1000),
      const LatLng(4.6500, -74.0990),
    ];

    final segments = RouteHazardVisualizerService.analyzeRouteHazards(
      routePolyline: route,
      hazards: const [],
      genericReports: <GenericReportRecord>[_buildGenericReport(40)],
    );

    expect(segments.any((segment) => segment.hasHazard), isTrue);
  });
}

GenericReportRecord _buildGenericReport(int impactRadiusMeters) {
  final DateTime now = DateTime.now();

  return GenericReportRecord(
    id: 1,
    localUuid: 'generic-1',
    remoteId: null,
    syncStatus: 'synced',
    lastModifiedAt: now,
    latitude: 4.6500,
    longitude: -74.0995,
    description: 'Route-side generic report',
    reportedDate: now,
    riskLevelCode: 'medium',
    impactRadiusMeters: impactRadiusMeters,
    photoUrl: null,
    createdAt: now,
    updatedAt: now,
    needsSync: false,
  );
}
