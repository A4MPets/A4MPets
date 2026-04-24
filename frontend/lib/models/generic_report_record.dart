class GenericReportRecord {
  final int id;
  final String localUuid;
  final String? remoteId;
  final String syncStatus;
  final DateTime lastModifiedAt;
  final double latitude;
  final double longitude;
  final String description;
  final DateTime reportedDate;
  final String riskLevelCode;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
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
    required this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory GenericReportRecord.fromMap(Map<String, Object?> map) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int createdAtMs = (map['created_at'] as num?)?.toInt() ?? nowMs;
    final int updatedAtMs = (map['updated_at'] as num?)?.toInt() ?? createdAtMs;
    final int lastModifiedMs =
        (map['last_modified_at'] as num?)?.toInt() ?? updatedAtMs;
    final int reportedDateMs =
        (map['reported_date'] as num?)?.toInt() ?? createdAtMs;

    return GenericReportRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      localUuid:
          map['local_uuid'] as String? ?? 'generic-${map['id'] ?? createdAtMs}',
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(lastModifiedMs),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      reportedDate: DateTime.fromMillisecondsSinceEpoch(reportedDateMs),
      riskLevelCode: map['risk_level_code'] as String? ?? 'undefined',
      photoUrl: map['photo_url'] as String?,
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
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'reported_date': reportedDate.millisecondsSinceEpoch,
      'risk_level_code': riskLevelCode,
      'photo_url': photoUrl,
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
