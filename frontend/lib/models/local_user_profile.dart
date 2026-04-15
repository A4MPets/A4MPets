class LocalUserProfile {
  final int id;
  final String username;
  final String? avatarPath;
  final bool isAuthenticated;
  final DateTime? lastSyncedAt;

  const LocalUserProfile({
    required this.id,
    required this.username,
    this.avatarPath,
    required this.isAuthenticated,
    this.lastSyncedAt,
  });

  factory LocalUserProfile.guest() {
    return const LocalUserProfile(
      id: 1,
      username: 'Usuario',
      avatarPath: null,
      isAuthenticated: false,
    );
  }

  factory LocalUserProfile.fromMap(Map<String, Object?> map) {
    return LocalUserProfile(
      id: map['id'] as int,
      username: map['username'] as String,
      avatarPath: map['avatar_path'] as String?,
      isAuthenticated: (map['is_authenticated'] as int? ?? 0) == 1,
      lastSyncedAt: map['last_synced_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['last_synced_at'] as int),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'username': username,
      'avatar_path': avatarPath,
      'is_authenticated': isAuthenticated ? 1 : 0,
      'last_synced_at': lastSyncedAt?.millisecondsSinceEpoch,
    };
  }

  LocalUserProfile copyWith({
    int? id,
    String? username,
    String? avatarPath,
    bool? isAuthenticated,
    DateTime? lastSyncedAt,
  }) {
    return LocalUserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
