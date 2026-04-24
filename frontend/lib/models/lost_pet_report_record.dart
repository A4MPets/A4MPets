class LostPetReportRecord {
  final int id;
  final String localUuid;
  final String? remoteId;
  final String syncStatus;
  final DateTime lastModifiedAt;
  final double lastSeenLatitude;
  final double lastSeenLongitude;
  final String name;
  final String details;
  final DateTime disappearanceDate;
  final String? photoUrl;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  const LostPetReportRecord({
    required this.id,
    required this.localUuid,
    required this.remoteId,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.lastSeenLatitude,
    required this.lastSeenLongitude,
    required this.name,
    required this.details,
    required this.disappearanceDate,
    required this.photoUrl,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory LostPetReportRecord.fromMap(Map<String, Object?> map) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int createdAtMs = (map['created_at'] as num?)?.toInt() ?? nowMs;
    final int updatedAtMs = (map['updated_at'] as num?)?.toInt() ?? createdAtMs;
    final int lastModifiedMs =
        (map['last_modified_at'] as num?)?.toInt() ?? updatedAtMs;
    final int disappearanceDateMs =
        (map['disappearance_date'] as num?)?.toInt() ?? createdAtMs;

    return LostPetReportRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      localUuid:
          map['local_uuid'] as String? ?? 'lost-${map['id'] ?? createdAtMs}',
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(lastModifiedMs),
      lastSeenLatitude: (map['last_seen_latitude'] as num).toDouble(),
      lastSeenLongitude: (map['last_seen_longitude'] as num).toDouble(),
      name: map['name'] as String? ?? '',
      details: map['details'] as String? ?? '',
      disappearanceDate: DateTime.fromMillisecondsSinceEpoch(
        disappearanceDateMs,
      ),
      photoUrl: map['photo_url'] as String?,
      phone: map['phone'] as String?,
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
      'last_seen_latitude': lastSeenLatitude,
      'last_seen_longitude': lastSeenLongitude,
      'name': name,
      'details': details,
      'disappearance_date': disappearanceDate.millisecondsSinceEpoch,
      'photo_url': photoUrl,
      'phone': phone,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
