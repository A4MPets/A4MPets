class PetRecord {
  final int id;
  final String localUuid;
  final String? remoteId;
  final String? name;
  final String? photoPath;
  final int totalWalks;
  final DateTime registeredAt;
  final DateTime? adoptionDate;
  final DateTime? birthDate;
  final String status;
  final bool isOwnerless;
  final String syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  const PetRecord({
    required this.id,
    required this.localUuid,
    this.remoteId,
    required this.name,
    this.photoPath,
    required this.totalWalks,
    required this.registeredAt,
    this.adoptionDate,
    this.birthDate,
    required this.status,
    required this.isOwnerless,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory PetRecord.fromMap(Map<String, Object?> map) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int createdAtMs = (map['created_at'] as int?) ?? nowMs;
    DateTime? optionalDate(Object? value) {
      final int? ms = (value as num?)?.toInt();
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    }

    return PetRecord(
      id: map['id'] as int,
      localUuid: map['local_uuid'] as String? ?? 'pt_${map['id']}_$createdAtMs',
      remoteId: map['remote_id']?.toString(),
      name: map['name'] as String?,
      photoPath: map['photo_path'] as String?,
      totalWalks: (map['total_walks'] as num?)?.toInt() ?? 0,
      registeredAt: DateTime.fromMillisecondsSinceEpoch(
        (map['registered_at'] as num?)?.toInt() ?? createdAtMs,
      ),
      adoptionDate: optionalDate(map['adoption_date']),
      birthDate: optionalDate(map['birth_date']),
      status: _normalizeStatus(map['status'] as String?),
      isOwnerless: (map['is_ownerless'] as int? ?? 0) == 1,
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['last_modified_at'] as int?) ?? nowMs,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as int?) ?? nowMs,
      ),
      needsSync: (map['needs_sync'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'local_uuid': localUuid,
      'remote_id': remoteId,
      'name': name,
      'photo_path': photoPath,
      'total_walks': totalWalks,
      'registered_at': registeredAt.millisecondsSinceEpoch,
      'adoption_date': adoptionDate?.millisecondsSinceEpoch,
      'birth_date': birthDate?.millisecondsSinceEpoch,
      'status': status,
      'is_ownerless': isOwnerless ? 1 : 0,
      'sync_status': syncStatus,
      'last_modified_at': lastModifiedAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }

  bool get isLost => status == 'perdida';

  String get displayName {
    final String? value = name?.trim();
    return value == null || value.isEmpty ? 'Mascota sin nombre' : value;
  }

  PetRecord copyWith({
    String? localUuid,
    String? remoteId,
    String? name,
    String? photoPath,
    int? totalWalks,
    DateTime? registeredAt,
    DateTime? adoptionDate,
    bool clearAdoptionDate = false,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? status,
    bool? isOwnerless,
    String? syncStatus,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) {
    return PetRecord(
      id: id,
      localUuid: localUuid ?? this.localUuid,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      totalWalks: totalWalks ?? this.totalWalks,
      registeredAt: registeredAt ?? this.registeredAt,
      adoptionDate: clearAdoptionDate
          ? null
          : adoptionDate ?? this.adoptionDate,
      birthDate: clearBirthDate ? null : birthDate ?? this.birthDate,
      status: status ?? this.status,
      isOwnerless: isOwnerless ?? this.isOwnerless,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  static String _normalizeStatus(String? value) {
    return value == 'perdida' || value == 'lost' ? 'perdida' : 'normal';
  }
}
