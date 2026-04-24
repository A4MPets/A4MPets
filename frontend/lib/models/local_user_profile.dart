class LocalUserProfile {
  final int id;
  final String username;
  final String? avatarPath;
  final bool isAuthenticated;
  final int? backendUserId;
  final String? email;
  final String? accessToken;
  final DateTime? lastSyncedAt;

  const LocalUserProfile({
    required this.id,
    required this.username,
    this.avatarPath,
    required this.isAuthenticated,
    this.backendUserId,
    this.email,
    this.accessToken,
    this.lastSyncedAt,
  });

  factory LocalUserProfile.guest() {
    return const LocalUserProfile(
      id: 1,
      username: 'Usuario',
      avatarPath: null,
      isAuthenticated: false,
      backendUserId: null,
      email: null,
      accessToken: null,
    );
  }

  factory LocalUserProfile.fromMap(Map<String, Object?> map) {
    return LocalUserProfile(
      id: map['id'] as int,
      username: map['username'] as String,
      avatarPath: map['avatar_path'] as String?,
      isAuthenticated: (map['is_authenticated'] as int? ?? 0) == 1,
      backendUserId: map['backend_user_id'] as int?,
      email: map['email'] as String?,
      accessToken: map['access_token'] as String?,
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
      'backend_user_id': backendUserId,
      'email': email,
      'access_token': accessToken,
      'last_synced_at': lastSyncedAt?.millisecondsSinceEpoch,
    };
  }

  LocalUserProfile copyWith({
    int? id,
    String? username,
    String? avatarPath,
    bool? isAuthenticated,
    int? backendUserId,
    String? email,
    String? accessToken,
    DateTime? lastSyncedAt,
  }) {
    return LocalUserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarPath: avatarPath ?? this.avatarPath,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      backendUserId: backendUserId ?? this.backendUserId,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
