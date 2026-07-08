import 'model_parsing.dart';
import 'report_comment_record.dart';

class GenericReportRecord {
  final int id;
  final String localUuid, syncStatus;
  final String? remoteId, photoUrl;
  final DateTime lastModifiedAt, reportedDate, createdAt, updatedAt;
  final double latitude, longitude;
  final String description, riskLevelCode;
  final int impactRadiusMeters;
  final String reportedByUsername;
  final List<ReportCommentRecord> comments;
  final bool needsSync;

  const GenericReportRecord({
    required this.id,
    required this.localUuid,
    required this.remoteId,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.reportedDate,
    required this.riskLevelCode,
    required this.impactRadiusMeters,
    required this.photoUrl,
    required this.reportedByUsername,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory GenericReportRecord.fromMap(Map<String, Object?> map) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int createdAtMs = readInt(map['created_at'], nowMs);
    final int updatedAtMs = readInt(map['updated_at'], createdAtMs);

    return GenericReportRecord(
      id: readInt(map['id']),
      localUuid: map['local_uuid'] as String? ?? 'generic-${map['id'] ?? createdAtMs}',
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: readDateTimeOr(map['last_modified_at'], updatedAtMs),
      latitude: readDouble(map['latitude']),
      longitude: readDouble(map['longitude']),
      description: map['description'] as String? ?? '',
      reportedDate: readDateTimeOr(map['reported_date'], createdAtMs),
      riskLevelCode: map['risk_level_code'] as String? ?? 'undefined',
      impactRadiusMeters: readDouble(map['impact_radius_meters']).round(),
      photoUrl: map['photo_url'] as String?,
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
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'reported_date': reportedDate.millisecondsSinceEpoch,
      'risk_level_code': riskLevelCode,
      'impact_radius_meters': impactRadiusMeters,
      'photo_url': photoUrl,
      'reported_by_username': reportedByUsername,
      'comments_json': writeReportComments(comments),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  static String riskLabelFromCode(String code) {
    switch (code) {
      case 'low':
        return 'Bajo';
      case 'medium':
        return 'Medio';
      case 'high':
        return 'Alto';
      default:
        return 'No lo se';
    }
  }
}
