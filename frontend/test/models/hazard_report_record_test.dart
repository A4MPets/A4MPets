import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/hazard_report_record.dart';

/// Tests unitarios para HazardReportRecord (serialización y labels)
/// Casos F2: F2-009, F2-010
void main() {
  final int now = DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> baseMap() => <String, Object?>{
        'id': 1,
        'local_uuid': 'hz_test_uuid',
        'remote_id': 'remote_hz_1',
        'sync_status': 'synced',
        'incident_latitude': 4.711,
        'incident_longitude': -74.072,
        'impact_radius_meters': 100,
        'category_code': 'stagnant_water',
        'narrative_description': 'Descripción de prueba QA',
        'estimated_duration_code': '1_week',
        'risk_level_code': 'high',
        'reported_by_username': 'qa_tester',
        'comments_json': '[]',
        'created_at': now,
        'updated_at': now,
        'reported_at': now,
        'last_modified_at': now,
        'needs_sync': 0,
      };

  group('HazardReportRecord - fromMap (F2-009)', () {
    test('fromMap construye HazardReportRecord con todos los campos', () {
      final HazardReportRecord record = HazardReportRecord.fromMap(baseMap());

      expect(record.id, equals(1));
      expect(record.localUuid, equals('hz_test_uuid'));
      expect(record.incidentLatitude, equals(4.711));
      expect(record.incidentLongitude, equals(-74.072));
      expect(record.impactRadiusMeters, equals(100));
      expect(record.categoryCode, equals('stagnant_water'));
      expect(record.riskLevelCode, equals('high'));
      expect(record.estimatedDurationCode, equals('1_week'));
      expect(record.reportedByUsername, equals('qa_tester'));
      expect(record.needsSync, isFalse);
      expect(record.comments, isEmpty);
    });

    test('fromMap genera localUuid de fallback cuando no se provee (F2-009)', () {
      final Map<String, Object?> map = baseMap();
      map['local_uuid'] = null;
      final HazardReportRecord record = HazardReportRecord.fromMap(map);
      expect(record.localUuid, startsWith('legacy-'));
    });

    test('fromMap usa syncStatus "created" por defecto cuando es nulo', () {
      final Map<String, Object?> map = baseMap();
      map['sync_status'] = null;
      final HazardReportRecord record = HazardReportRecord.fromMap(map);
      expect(record.syncStatus, equals('created'));
    });

    test('fromMap parsea lista de comentarios desde comments_json', () {
      final Map<String, Object?> map = baseMap();
      map['comments_json'] = '[{"id":1,"author_name":"QA","comment_text":"Test comment",'
          '"is_anonymous":0,"commented_at":$now,"created_at":$now}]';

      final HazardReportRecord record = HazardReportRecord.fromMap(map);
      expect(record.comments.length, equals(1));
      expect(record.comments.first.commentText, equals('Test comment'));
    });
  });

  group('HazardReportRecord - toMap (F2-009)', () {
    test('toMap serializa correctamente todos los campos numéricos', () {
      final HazardReportRecord record = HazardReportRecord.fromMap(baseMap());
      final Map<String, Object?> map = record.toMap();

      expect(map['incident_latitude'], equals(4.711));
      expect(map['incident_longitude'], equals(-74.072));
      expect(map['impact_radius_meters'], equals(100));
      expect(map['risk_level_code'], equals('high'));
      expect(map['needs_sync'], equals(0));
    });

    test('toMap roundtrip: fromMap → toMap preserva datos esenciales', () {
      final HazardReportRecord original = HazardReportRecord.fromMap(baseMap());
      final Map<String, Object?> map = original.toMap();
      final HazardReportRecord restored = HazardReportRecord.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.riskLevelCode, equals(original.riskLevelCode));
      expect(restored.categoryCode, equals(original.categoryCode));
      expect(restored.incidentLatitude, equals(original.incidentLatitude));
    });
  });

  group('HazardReportRecord - labels estáticos (F2-010)', () {
    test('categoryLabelFromCode retorna etiqueta correcta para stagnant_water', () {
      expect(
        HazardReportRecord.categoryLabelFromCode('stagnant_water'),
        equals('Aguas estancadas'),
      );
    });

    test('categoryLabelFromCode retorna etiqueta correcta para contagious_disease', () {
      expect(
        HazardReportRecord.categoryLabelFromCode('contagious_disease'),
        equals('Enfermedad contagiosa'),
      );
    });

    test('categoryLabelFromCode retorna fallback para código desconocido (F2-010)', () {
      expect(
        HazardReportRecord.categoryLabelFromCode('unknown_code'),
        equals('No lo se'),
      );
    });

    test('durationLabelFromCode retorna etiqueta para 1_week', () {
      expect(
        HazardReportRecord.durationLabelFromCode('1_week'),
        equals('1 Semana'),
      );
    });

    test('durationLabelFromCode retorna etiqueta para 3_months', () {
      expect(
        HazardReportRecord.durationLabelFromCode('3_months'),
        equals('3 Meses'),
      );
    });

    test('durationLabelFromCode retorna fallback para código desconocido', () {
      expect(
        HazardReportRecord.durationLabelFromCode('invalid'),
        equals('No lo se'),
      );
    });

    test('riskLabelFromCode retorna etiqueta para high', () {
      expect(HazardReportRecord.riskLabelFromCode('high'), equals('Alto'));
    });

    test('riskLabelFromCode retorna etiqueta para medium', () {
      expect(HazardReportRecord.riskLabelFromCode('medium'), equals('Medio'));
    });

    test('riskLabelFromCode retorna etiqueta para low', () {
      expect(HazardReportRecord.riskLabelFromCode('low'), equals('Bajo'));
    });

    test('riskLabelFromCode retorna fallback para código desconocido', () {
      expect(
        HazardReportRecord.riskLabelFromCode('undefined'),
        equals('No lo se'),
      );
    });
  });
}
