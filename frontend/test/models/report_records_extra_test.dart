import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/found_pet_report_record.dart';
import 'package:frontend/models/generic_report_record.dart';
import 'package:frontend/models/lost_pet_report_record.dart';
import 'package:frontend/models/report_comment_record.dart';
import 'package:frontend/models/route_navigation_instruction.dart';
import 'package:frontend/models/route_record.dart';

void main() {
  final int now = DateTime(2026, 5, 8, 14, 30).millisecondsSinceEpoch;
  final String commentsJson = jsonEncode(<Map<String, Object?>>[
    <String, Object?>{
      'author_username': 'QA Front',
      'author_avatar_url': '/avatar.png',
      'is_anonymous': false,
      'comment_text': 'Comentario visible',
      'created_at': now,
    },
  ]);

  group('ReportCommentRecord (F2-018-extra-comments)', () {
    test('fromMap usa defaults para comentario anonimo', () {
      final ReportCommentRecord comment = ReportCommentRecord.fromMap(
        <String, dynamic>{'comment_text': 'Sin autor', 'created_at': now},
      );

      expect(comment.authorUsername, equals('Anonimo'));
      expect(comment.authorAvatarUrl, isNull);
      expect(comment.isAnonymous, isTrue);
      expect(comment.commentText, equals('Sin autor'));
      expect(comment.createdAt.millisecondsSinceEpoch, equals(now));
    });

    test('toMap preserva autor, anonimato y fecha', () {
      final ReportCommentRecord comment = ReportCommentRecord(
        authorUsername: 'QA Front',
        authorAvatarUrl: '/avatar.png',
        isAnonymous: false,
        commentText: 'Texto',
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      );

      final Map<String, Object?> map = comment.toMap();
      expect(map['author_username'], equals('QA Front'));
      expect(map['author_avatar_url'], equals('/avatar.png'));
      expect(map['is_anonymous'], isFalse);
      expect(map['created_at'], equals(now));
    });

    test(
      'fromMap acepta anonimato como entero o texto desde API normalizada',
      () {
        final ReportCommentRecord numericComment =
            ReportCommentRecord.fromMap(<String, dynamic>{
              'author_username': 'QA Front',
              'is_anonymous': 0,
              'comment_text': 'Comentario visible',
              'created_at': now,
            });
        final ReportCommentRecord textComment =
            ReportCommentRecord.fromMap(<String, dynamic>{
              'is_anonymous': 'true',
              'comment_text': 'Comentario anonimo',
              'created_at': now,
            });

        expect(numericComment.isAnonymous, isFalse);
        expect(textComment.isAnonymous, isTrue);
      },
    );
  });

  group('LostPetReportRecord (F2-014-extra-lost)', () {
    Map<String, Object?> baseMap() => <String, Object?>{
      'id': 10,
      'local_uuid': 'lost-local',
      'remote_id': 88,
      'sync_status': 'synced',
      'last_modified_at': now,
      'pet_id': 5,
      'pet_local_uuid': 'pet-local',
      'last_seen_latitude': 3.4516,
      'last_seen_longitude': -76.532,
      'details': 'Visto cerca al parque',
      'disappearance_date': now,
      'photo_url': '/lost.png',
      'pet_photo_url': '/pet.png',
      'phone': '3001234567',
      'comments_json': commentsJson,
      'created_at': now,
      'updated_at': now,
      'needs_sync': 1,
    };

    test('fromMap deserializa campos, comentarios y needsSync', () {
      final LostPetReportRecord report = LostPetReportRecord.fromMap(baseMap());

      expect(report.id, equals(10));
      expect(report.remoteId, equals('88'));
      expect(report.petId, equals(5));
      expect(report.lastSeenLatitude, equals(3.4516));
      expect(report.lastSeenLongitude, equals(-76.532));
      expect(report.comments.single.authorUsername, equals('QA Front'));
      expect(report.needsSync, isTrue);
    });

    test('fromMap aplica defaults y genera localUuid fallback', () {
      final LostPetReportRecord report = LostPetReportRecord.fromMap(
        <String, Object?>{
          'id': 11,
          'last_seen_latitude': 3.45,
          'last_seen_longitude': -76.53,
        },
      );

      expect(report.localUuid, equals('lost-11'));
      expect(report.syncStatus, equals('created'));
      expect(report.petLocalUuid, isEmpty);
      expect(report.details, isEmpty);
      expect(report.comments, isEmpty);
      expect(report.needsSync, isFalse);
    });

    test('toMap serializa fechas y comentarios', () {
      final Map<String, Object?> map = LostPetReportRecord.fromMap(
        baseMap(),
      ).toMap();

      expect(map['local_uuid'], equals('lost-local'));
      expect(map['last_seen_latitude'], equals(3.4516));
      expect(map['disappearance_date'], equals(now));
      expect(map['needs_sync'], equals(1));
      expect(jsonDecode(map['comments_json']! as String), isA<List<dynamic>>());
    });
  });

  group('FoundPetReportRecord (F2-014-extra-found)', () {
    Map<String, Object?> baseMap() => <String, Object?>{
      'id': 20,
      'local_uuid': 'found-local',
      'remote_id': 'remote-found',
      'sync_status': 'synced',
      'last_modified_at': now,
      'pet_id': 6,
      'pet_local_uuid': 'pet-found',
      'matched_lost_pet_report_id': 10,
      'latitude': 3.457,
      'longitude': -76.528,
      'details': 'Mascota encontrada con collar',
      'found_date': now,
      'photo_url': '/found.png',
      'pet_photo_url': '/pet-found.png',
      'phone': '3111234567',
      'comments_json': commentsJson,
      'created_at': now,
      'updated_at': now,
      'needs_sync': 1,
    };

    test('fromMap deserializa vinculo a reporte perdido y comentarios', () {
      final FoundPetReportRecord report = FoundPetReportRecord.fromMap(
        baseMap(),
      );

      expect(report.id, equals(20));
      expect(report.matchedLostPetReportId, equals(10));
      expect(report.latitude, equals(3.457));
      expect(report.longitude, equals(-76.528));
      expect(report.comments.single.commentText, equals('Comentario visible'));
      expect(report.needsSync, isTrue);
    });

    test('fromMap usa defaults cuando faltan campos opcionales', () {
      final FoundPetReportRecord report = FoundPetReportRecord.fromMap(
        <String, Object?>{'id': 21, 'latitude': 3.45, 'longitude': -76.53},
      );

      expect(report.localUuid, equals('found-21'));
      expect(report.syncStatus, equals('created'));
      expect(report.details, isEmpty);
      expect(report.comments, isEmpty);
      expect(report.needsSync, isFalse);
    });

    test('toMap preserva campos principales', () {
      final Map<String, Object?> map = FoundPetReportRecord.fromMap(
        baseMap(),
      ).toMap();

      expect(map['matched_lost_pet_report_id'], equals(10));
      expect(map['found_date'], equals(now));
      expect(map['photo_url'], equals('/found.png'));
      expect(map['needs_sync'], equals(1));
    });
  });

  group('GenericReportRecord (F2-014-extra-generic)', () {
    Map<String, Object?> baseMap() => <String, Object?>{
      'id': 30,
      'local_uuid': 'generic-local',
      'remote_id': 'remote-generic',
      'sync_status': 'synced',
      'last_modified_at': now,
      'latitude': 3.46,
      'longitude': -76.54,
      'description': 'Reporte generico',
      'reported_date': now,
      'risk_level_code': 'medium',
      'impact_radius_meters': 75.6,
      'photo_url': '/generic.png',
      'reported_by_username': 'QA Reporter',
      'comments_json': commentsJson,
      'created_at': now,
      'updated_at': now,
      'needs_sync': 1,
    };

    test('fromMap redondea radio, comentarios y autor', () {
      final GenericReportRecord report = GenericReportRecord.fromMap(baseMap());

      expect(report.impactRadiusMeters, equals(76));
      expect(report.reportedByUsername, equals('QA Reporter'));
      expect(report.riskLevelCode, equals('medium'));
      expect(report.comments.single.isAnonymous, isFalse);
      expect(report.needsSync, isTrue);
    });

    test('fromMap aplica defaults para reporte anonimo', () {
      final GenericReportRecord report = GenericReportRecord.fromMap(
        <String, Object?>{'id': 31, 'latitude': 3.46, 'longitude': -76.54},
      );

      expect(report.localUuid, equals('generic-31'));
      expect(report.description, isEmpty);
      expect(report.riskLevelCode, equals('undefined'));
      expect(report.impactRadiusMeters, equals(0));
      expect(report.reportedByUsername, equals('Anonimo'));
    });

    test('riskLabelFromCode retorna etiquetas y fallback', () {
      expect(GenericReportRecord.riskLabelFromCode('low'), equals('Bajo'));
      expect(GenericReportRecord.riskLabelFromCode('medium'), equals('Medio'));
      expect(GenericReportRecord.riskLabelFromCode('high'), equals('Alto'));
      expect(
        GenericReportRecord.riskLabelFromCode('unknown'),
        equals('No lo se'),
      );
    });

    test('toMap serializa campos principales', () {
      final Map<String, Object?> map = GenericReportRecord.fromMap(
        baseMap(),
      ).toMap();

      expect(map['description'], equals('Reporte generico'));
      expect(map['reported_date'], equals(now));
      expect(map['impact_radius_meters'], equals(76));
      expect(map['needs_sync'], equals(1));
    });
  });

  group('RouteRecord y RouteNavigationInstruction (F2-022-extra)', () {
    test('RoutePoint convierte desde y hacia mapa y LatLng', () {
      final RoutePoint point = RoutePoint.fromMap(<String, dynamic>{
        'lat': 3.4516,
        'lng': -76.532,
      });

      expect(
        point.toMap(),
        equals(<String, dynamic>{'lat': 3.4516, 'lng': -76.532}),
      );
      expect(point.toLatLng().latitude, equals(3.4516));
      expect(point.toLatLng().longitude, equals(-76.532));
    });

    test('RouteRecord deserializa puntos ordenados y serializa roundtrip', () {
      final RouteRecord route = RouteRecord.fromMap(<String, Object?>{
        'id': 77,
        'remote_id': 88,
        'name': 'Ruta QA',
        'points_json': jsonEncode(<Map<String, double>>[
          <String, double>{'lat': 3.45, 'lng': -76.53},
          <String, double>{'lat': 3.46, 'lng': -76.54},
        ]),
        'sync_status': 'synced',
        'last_modified_at': now,
        'created_at': now,
        'updated_at': now,
        'needs_sync': 1,
      });

      expect(route.id, equals(77));
      expect(route.remoteId, equals('88'));
      expect(route.points.length, equals(2));
      expect(route.points.first.latitude, equals(3.45));
      expect(route.needsSync, isTrue);
      expect(
        RouteRecord.fromMap(route.toMap()).points.last.longitude,
        equals(-76.54),
      );
    });

    test('RouteRecord usa defaults de sincronizacion', () {
      final RouteRecord route = RouteRecord.fromMap(<String, Object?>{
        'id': 78,
        'name': 'Ruta default',
      });

      expect(route.points, isEmpty);
      expect(route.syncStatus, equals('created'));
      expect(route.needsSync, isFalse);
    });

    test('RouteNavigationInstruction calcula id y audibilidad', () {
      final RouteNavigationInstruction turn =
          RouteNavigationInstruction.fromMap(<String, dynamic>{
            'sequence': 2,
            'sign': -2,
            'text': 'Gira a la izquierda',
            'street_name': 'Calle QA',
            'exit_number': 3,
            'distance_meters': 120.5,
            'duration_seconds': 42,
            'point_start_index': 1,
            'point_end_index': 3,
          });
      final RouteNavigationInstruction arrival =
          RouteNavigationInstruction.fromMap(<String, dynamic>{
            'sign': 4,
            'point_start_index': 4,
            'point_end_index': 4,
          });
      final RouteNavigationInstruction fallback =
          RouteNavigationInstruction.fromMap(<String, dynamic>{});

      expect(turn.id, equals('instruction-2-1-3--2'));
      expect(turn.isAudibleTurn, isTrue);
      expect(turn.exitNumber, equals(3));
      expect(arrival.isArrival, isTrue);
      expect(arrival.isAudibleTurn, isFalse);
      expect(fallback.text, isEmpty);
      expect(fallback.distanceMeters, equals(0));
    });
  });
}
