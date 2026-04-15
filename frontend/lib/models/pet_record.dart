class PetRecord {
  final int id;
  final String name;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  const PetRecord({
    required this.id,
    required this.name,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory PetRecord.fromMap(Map<String, Object?> map) {
    return PetRecord(
      id: map['id'] as int,
      name: map['name'] as String,
      photoPath: map['photo_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      needsSync: (map['needs_sync'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
