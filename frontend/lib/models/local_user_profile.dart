import 'dart:convert';

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
      id: _readInt(map['id']) ?? 1,
      username: map['username'] as String? ?? 'Usuario',
      avatarPath: map['avatar_path'] as String?,
      isAuthenticated: _readBool(map['is_authenticated']),
      backendUserId: _readInt(map['backend_user_id']),
      email: map['email'] as String?,
      accessToken: map['access_token'] as String?,
      lastSyncedAt: map['last_synced_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              _readInt(map['last_synced_at']) ?? 0,
            ),
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

  factory LocalUserProfile.fromJson(String raw) {
    return LocalUserProfile.fromMap(
      (jsonDecode(raw) as Map<String, dynamic>).cast<String, Object?>(),
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
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
