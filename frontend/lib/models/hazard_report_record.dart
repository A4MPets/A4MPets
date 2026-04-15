import 'dart:convert';

class HazardCommentRecord {
  final String authorUsername;
  final String? authorAvatarUrl;
  final bool isAnonymous;
  final String commentText;
  final DateTime createdAt;

  const HazardCommentRecord({
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.isAnonymous,
    required this.commentText,
    required this.createdAt,
  });

  factory HazardCommentRecord.fromMap(Map<String, dynamic> map) {
    return HazardCommentRecord(
      authorUsername: map['author_username'] as String? ?? 'Anónimo',
      authorAvatarUrl: map['author_avatar_url'] as String?,
      isAnonymous: (map['is_anonymous'] as bool?) ?? true,
      commentText: map['comment_text'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'author_username': authorUsername,
      'author_avatar_url': authorAvatarUrl,
      'is_anonymous': isAnonymous,
      'comment_text': commentText,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

class HazardReportRecord {
  final int id;
  final String localUuid;
  final String? remoteId;
  final String syncStatus;
  final DateTime lastModifiedAt;
  final double incidentLatitude;
  final double incidentLongitude;
  final int impactRadiusMeters;
  final String categoryCode;
  final String narrativeDescription;
  final DateTime reportedAt;
  final String estimatedDurationCode;
  final String riskLevelCode;
  final String? evidencePhotoUrl;
  final String reportedByUsername;
  final List<HazardCommentRecord> comments;
  final DateTime createdAt;
  final DateTime updatedAt;
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
    final String commentsJson = map['comments_json'] as String? ?? '[]';
    final List<dynamic> rawComments = jsonDecode(commentsJson) as List<dynamic>;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int idValue = (map['id'] as num?)?.toInt() ?? 0;
    final int createdAtMs = (map['created_at'] as num?)?.toInt() ?? nowMs;
    final int updatedAtMs = (map['updated_at'] as num?)?.toInt() ?? createdAtMs;
    final int reportedAtMs = (map['reported_at'] as num?)?.toInt() ?? updatedAtMs;
    final int lastModifiedMs =
        (map['last_modified_at'] as num?)?.toInt() ?? updatedAtMs;
    final String fallbackLocalUuid = 'legacy-${map['id'] ?? nowMs}';

    return HazardReportRecord(
      id: idValue,
      localUuid: map['local_uuid'] as String? ?? fallbackLocalUuid,
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(lastModifiedMs),
      incidentLatitude: (map['incident_latitude'] as num).toDouble(),
      incidentLongitude: (map['incident_longitude'] as num).toDouble(),
      impactRadiusMeters: (map['impact_radius_meters'] as num).toInt(),
      categoryCode: map['category_code'] as String,
      narrativeDescription: map['narrative_description'] as String,
      reportedAt: DateTime.fromMillisecondsSinceEpoch(reportedAtMs),
      estimatedDurationCode: map['estimated_duration_code'] as String,
      riskLevelCode: map['risk_level_code'] as String,
      evidencePhotoUrl: map['evidence_photo_url'] as String?,
        reportedByUsername: map['reported_by_username'] as String? ?? 'Anónimo',
        comments: rawComments
          .map((dynamic item) =>
            HazardCommentRecord.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
      needsSync: (map['needs_sync'] as int? ?? 0) == 1,
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
      'comments_json': jsonEncode(
        comments.map((HazardCommentRecord c) => c.toMap()).toList(),
      ),
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
      case 'aggressive_animals':
        return 'Animales agresivos';
      case 'undefined':
      case 'unspecified':
      default:
        return 'No lo sé';
    }
  }

  static String durationLabelFromCode(String code) {
    switch (code) {
      case '1_day':
        return '1 Día';
      case '3_days':
        return '3 Días';
      case '1_week':
        return '1 semana';
      case '2_weeks':
        return '2 semanas';
      case '1_month':
        return '1 mes';
      case '3_months':
        return '3 meses';
      case '6_months':
        return '6 meses';
      case '1_year':
        return '1 año';
      case 'undefined':
      case 'unknown':
      default:
        return 'No lo sé';
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
        return 'No lo sé';
    }
  }
}
