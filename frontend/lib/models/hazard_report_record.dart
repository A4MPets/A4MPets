import 'model_parsing.dart';
import 'report_comment_record.dart';

typedef HazardCommentRecord = ReportCommentRecord;

class HazardReportRecord {
  final int id;
  final String localUuid, syncStatus;
  final String? remoteId;
  final DateTime lastModifiedAt, reportedAt, createdAt, updatedAt;
  final double incidentLatitude, incidentLongitude;
  final int impactRadiusMeters;
  final String categoryCode, narrativeDescription;
  final String estimatedDurationCode, riskLevelCode;
  final String? evidencePhotoUrl;
  final String reportedByUsername;
  final List<HazardCommentRecord> comments;
  final bool needsSync;

  const HazardReportRecord({
    required this.id,
    required this.localUuid,
    required this.remoteId,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.incidentLatitude,
    required this.incidentLongitude,
    required this.impactRadiusMeters,
    required this.categoryCode,
    required this.narrativeDescription,
    required this.reportedAt,
    required this.estimatedDurationCode,
    required this.riskLevelCode,
    required this.evidencePhotoUrl,
    required this.reportedByUsername,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory HazardReportRecord.fromMap(Map<String, Object?> map) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int idValue = readInt(map['id']);
    final int createdAtMs = readInt(map['created_at'], nowMs);
    final int updatedAtMs = readInt(map['updated_at'], createdAtMs);
    final String fallbackLocalUuid = 'legacy-${map['id'] ?? nowMs}';

    return HazardReportRecord(
      id: idValue,
      localUuid: map['local_uuid'] as String? ?? fallbackLocalUuid,
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: readDateTimeOr(map['last_modified_at'], updatedAtMs),
      incidentLatitude: readDouble(map['incident_latitude']),
      incidentLongitude: readDouble(map['incident_longitude']),
      impactRadiusMeters: readInt(map['impact_radius_meters']),
      categoryCode: map['category_code'] as String,
      narrativeDescription: map['narrative_description'] as String,
      reportedAt: readDateTimeOr(map['reported_at'], updatedAtMs),
      estimatedDurationCode: map['estimated_duration_code'] as String,
      riskLevelCode: map['risk_level_code'] as String,
      evidencePhotoUrl: map['evidence_photo_url'] as String?,
      reportedByUsername: map['reported_by_username'] as String? ?? 'Anonimo',
      comments: readReportComments(map['comments_json']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
      needsSync: readBool(map['needs_sync']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'local_uuid': localUuid,
      'remote_id': remoteId,
      'sync_status': syncStatus,
      'last_modified_at': lastModifiedAt.millisecondsSinceEpoch,
      'incident_latitude': incidentLatitude,
      'incident_longitude': incidentLongitude,
      'impact_radius_meters': impactRadiusMeters,
      'category_code': categoryCode,
      'narrative_description': narrativeDescription,
      'reported_at': reportedAt.millisecondsSinceEpoch,
      'estimated_duration_code': estimatedDurationCode,
      'risk_level_code': riskLevelCode,
      'evidence_photo_url': evidencePhotoUrl,
      'reported_by_username': reportedByUsername,
      'comments_json': writeReportComments(comments),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  static String categoryLabelFromCode(String code) {
    switch (code) {
      case 'contagious_disease':
        return 'Enfermedad contagiosa';
      case 'stagnant_water':
        return 'Aguas estancadas';
      case 'waste_accumulation':
        return 'Acumulación de residuos';
      case 'pest_presence':
        return 'Presencia de plagas';
      case 'possible_rabies_vectors':
        return 'Posibles transmisores de rabia';
      case 'undefined':
      case 'unknown':
      case 'unspecified':
      default:
        return 'No lo se';
    }
  }

  static String durationLabelFromCode(String code) {
    switch (code) {
      case '1_day':
        return '1 Dia';
      case '3_days':
        return '3 Dias';
      case '1_week':
        return '1 Semana';
      case '2_weeks':
        return '2 Semanas';
      case '1_month':
        return '1 Mes';
      case '3_months':
        return '3 Meses';
      case '6_months':
        return '6 Meses';
      case '1_year':
        return '1 Ano';
      case 'undefined':
      case 'unknown':
      default:
        return 'No lo se';
    }
  }

  static String riskLabelFromCode(String code) {
    switch (code) {
      case 'low':
        return 'Bajo';
      case 'medium':
        return 'Medio';
      case 'high':
        return 'Alto';
      case 'undefined':
      case 'unknown':
      default:
        return 'No lo se';
    }
  }
}
