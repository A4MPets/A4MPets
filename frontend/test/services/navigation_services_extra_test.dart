import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/generic_report_record.dart';
import 'package:frontend/models/hazard_report_record.dart';
import 'package:frontend/models/route_navigation_instruction.dart';
import 'package:frontend/services/navigation_audio_message_builder.dart';
import 'package:frontend/services/navigation_audio_progress.dart';
import 'package:frontend/services/route_hazard_visualizer_service.dart';
import 'package:latlong2/latlong.dart';

void main() {
  RouteNavigationInstruction instruction({
    int sign = 2,
    int start = 1,
    String text = 'Continua por la ruta',
    int? exitNumber,
  }) {
    return RouteNavigationInstruction(
      sequence: 1,
      sign: sign,
      text: text,
      streetName: 'Calle QA',
      exitNumber: exitNumber,
      distanceMeters: 100,
      durationSeconds: 60,
      pointStartIndex: start,
      pointEndIndex: start,
    );
  }

  HazardReportRecord hazard({
    required double lat,
    required double lng,
    String risk = 'high',
    int radius = 60,
  }) {
    final DateTime now = DateTime(2026, 5, 8);
    return HazardReportRecord(
      id: 1,
      localUuid: 'hazard',
      remoteId: null,
      syncStatus: 'synced',
      lastModifiedAt: now,
      incidentLatitude: lat,
      incidentLongitude: lng,
      impactRadiusMeters: radius,
      categoryCode: 'stagnant_water',
      narrativeDescription: 'Peligro',
      reportedAt: now,
      estimatedDurationCode: '1_week',
      riskLevelCode: risk,
      evidencePhotoUrl: null,
      reportedByUsername: 'QA',
      comments: const <HazardCommentRecord>[],
      createdAt: now,
      updatedAt: now,
      needsSync: false,
    );
  }

  GenericReportRecord generic({
    required double lat,
    required double lng,
    int radius = 50,
  }) {
    final DateTime now = DateTime(2026, 5, 8);
    return GenericReportRecord(
      id: 2,
      localUuid: 'generic',
      remoteId: null,
      syncStatus: 'synced',
      lastModifiedAt: now,
      latitude: lat,
      longitude: lng,
      description: 'Generico',
      reportedDate: now,
      riskLevelCode: 'medium',
      impactRadiusMeters: radius,
      photoUrl: null,
      reportedByUsername: 'QA',
      comments: const <HazardCommentRecord>[],
      createdAt: now,
      updatedAt: now,
      needsSync: false,
    );
  }

  group('NavigationAudioMessageBuilder (F2-011-extra)', () {
    test('genera mensajes de giro, rotonda, peligro, llegada y fallback', () {
      expect(
        NavigationAudioMessageBuilder.buildFarApproachMessage(
          instruction(sign: -2),
        ),
        equals('En 100 metros, gira a la izquierda'),
      );
      expect(
        NavigationAudioMessageBuilder.buildApproachMessage(
          instruction(sign: 1),
        ),
        equals('En 30 metros, gira levemente a la derecha'),
      );
      expect(
        NavigationAudioMessageBuilder.buildImmediateMessage(
          instruction(sign: -98),
        ),
        equals('Haz ahora un retorno'),
      );
      expect(
        NavigationAudioMessageBuilder.buildImmediateMessage(
          instruction(sign: 6, text: 'Toma la 10 salida'),
        ),
        equals('Entra ahora a la rotonda y toma la salida numero 10'),
      );
      expect(
        NavigationAudioMessageBuilder.buildImmediateMessage(
          instruction(sign: 0, text: ''),
        ),
        equals('Continua por la ruta'),
      );
      expect(
        NavigationAudioMessageBuilder.buildDangerMessage(),
        contains('peligro'),
      );
      expect(
        NavigationAudioMessageBuilder.buildArrivalMessage(),
        contains('destino'),
      );
    });
  });

  group('NavigationAudioProgress (F2-012-extra)', () {
    final List<LatLng> polyline = <LatLng>[
      const LatLng(3.4516, -76.5320),
      const LatLng(3.4516, -76.5311),
      const LatLng(3.4516, -76.5302),
    ];
    const Distance distance = Distance();

    test('retorna cue de aproximacion lejana, cercana e inmediata', () {
      final RouteNavigationInstruction turn = instruction(sign: 2, start: 1);

      final NavigationAudioCue? far = NavigationAudioProgress.nextCue(
        currentLocation: const LatLng(3.4516, -76.5319),
        polyline: polyline,
        instructions: <RouteNavigationInstruction>[turn],
        spokenFarApproachKeys: <String>{},
        spokenApproachKeys: <String>{},
        spokenImmediateKeys: <String>{},
        distanceCalculator: distance,
      );
      final NavigationAudioCue? approach = NavigationAudioProgress.nextCue(
        currentLocation: const LatLng(3.4516, -76.5313),
        polyline: polyline,
        instructions: <RouteNavigationInstruction>[turn],
        spokenFarApproachKeys: <String>{},
        spokenApproachKeys: <String>{},
        spokenImmediateKeys: <String>{},
        distanceCalculator: distance,
      );
      final NavigationAudioCue? immediate = NavigationAudioProgress.nextCue(
        currentLocation: const LatLng(3.4516, -76.53111),
        polyline: polyline,
        instructions: <RouteNavigationInstruction>[turn],
        spokenFarApproachKeys: <String>{},
        spokenApproachKeys: <String>{},
        spokenImmediateKeys: <String>{},
        distanceCalculator: distance,
      );

      expect(far?.type, equals(NavigationAudioCueType.farApproach));
      expect(approach?.type, equals(NavigationAudioCueType.approach));
      expect(immediate?.type, equals(NavigationAudioCueType.immediate));
      expect(immediate?.maneuverKey, contains('2-'));
    });

    test(
      'retorna null para polilinea corta, fuera de ruta, no audible o ya hablado',
      () {
        final RouteNavigationInstruction turn = instruction(sign: 2, start: 1);

        expect(
          NavigationAudioProgress.nextCue(
            currentLocation: polyline.first,
            polyline: <LatLng>[polyline.first],
            instructions: <RouteNavigationInstruction>[turn],
            spokenFarApproachKeys: <String>{},
            spokenApproachKeys: <String>{},
            spokenImmediateKeys: <String>{},
            distanceCalculator: distance,
          ),
          isNull,
        );
        expect(
          NavigationAudioProgress.nextCue(
            currentLocation: const LatLng(3.46, -76.5319),
            polyline: polyline,
            instructions: <RouteNavigationInstruction>[turn],
            spokenFarApproachKeys: <String>{},
            spokenApproachKeys: <String>{},
            spokenImmediateKeys: <String>{},
            distanceCalculator: distance,
          ),
          isNull,
        );
        expect(
          NavigationAudioProgress.nextCue(
            currentLocation: const LatLng(3.4516, -76.5319),
            polyline: polyline,
            instructions: <RouteNavigationInstruction>[
              instruction(sign: 0, start: 1),
            ],
            spokenFarApproachKeys: <String>{},
            spokenApproachKeys: <String>{},
            spokenImmediateKeys: <String>{},
            distanceCalculator: distance,
          ),
          isNull,
        );
      },
    );
  });

  group('RouteHazardVisualizerService (F2-021-extra)', () {
    test('marca segmentos con peligro y respeta filtros de riesgo', () {
      final List<LatLng> route = <LatLng>[
        const LatLng(3.4516, -76.5320),
        const LatLng(3.4516, -76.5310),
        const LatLng(3.4516, -76.5300),
      ];

      final List<dynamic> highSegments =
          RouteHazardVisualizerService.analyzeRouteHazards(
            routePolyline: route,
            routeWaypoints: <LatLng>[route.first, route.last],
            segmentColors: const <Color>[Colors.blue, Colors.green],
            hazards: <HazardReportRecord>[
              hazard(lat: 3.4516, lng: -76.5315, risk: 'high', radius: 80),
            ],
            hazardRiskFilters: const <String>['high'],
          );
      final List<dynamic> lowOnlySegments =
          RouteHazardVisualizerService.analyzeRouteHazards(
            routePolyline: route,
            hazards: <HazardReportRecord>[
              hazard(lat: 3.4516, lng: -76.5315, risk: 'high', radius: 80),
            ],
            hazardRiskFilters: const <String>['low'],
          );

      expect(highSegments, hasLength(2));
      expect(
        highSegments.any((dynamic segment) => segment.hasHazard == true),
        isTrue,
      );
      expect(
        lowOnlySegments.any((dynamic segment) => segment.hasHazard == true),
        isFalse,
      );
    });

    test(
      'considera reportes genericos solo cuando filtro other esta activo',
      () {
        final List<LatLng> route = <LatLng>[
          const LatLng(3.4516, -76.5320),
          const LatLng(3.4516, -76.5310),
        ];

        final List<dynamic> withOther =
            RouteHazardVisualizerService.analyzeRouteHazards(
              routePolyline: route,
              hazards: const <HazardReportRecord>[],
              genericReports: <GenericReportRecord>[
                generic(lat: 3.4516, lng: -76.5315, radius: 80),
              ],
              hazardRiskFilters: const <String>['other'],
            );
        final List<dynamic> withoutOther =
            RouteHazardVisualizerService.analyzeRouteHazards(
              routePolyline: route,
              hazards: const <HazardReportRecord>[],
              genericReports: <GenericReportRecord>[
                generic(lat: 3.4516, lng: -76.5315, radius: 80),
              ],
              hazardRiskFilters: const <String>['high'],
            );

        expect(withOther.single.hasHazard, isTrue);
        expect(withoutOther.single.hasHazard, isFalse);
        expect(
          RouteHazardVisualizerService.analyzeRouteHazards(
            routePolyline: const <LatLng>[LatLng(1, 1)],
            hazards: const <HazardReportRecord>[],
          ),
          isEmpty,
        );
      },
    );
  });
}
