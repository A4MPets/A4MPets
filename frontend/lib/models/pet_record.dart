class PetRecord {
  final int id;
  final String? remoteId;
  final String name;
  final String? photoPath;
  final String syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  const PetRecord({
    required this.id,
    this.remoteId,
    required this.name,
    this.photoPath,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory PetRecord.fromMap(Map<String, Object?> map) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    return PetRecord(
      id: map['id'] as int,
      remoteId: map['remote_id']?.toString(),
      name: map['name'] as String,
      photoPath: map['photo_path'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['last_modified_at'] as int?) ?? nowMs,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? nowMs,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as int?) ?? nowMs,
      ),
      needsSync: (map['needs_sync'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'remote_id': remoteId,
      'name': name,
      'photo_path': photoPath,
      'sync_status': syncStatus,
      'last_modified_at': lastModifiedAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
