import 'dart:convert';

import 'model_parsing.dart';

class LocalUserProfile {
  final int id;
  final String username;
  final String? avatarPath;
  final bool isAuthenticated;
  final int? backendUserId;
  final String? email;
  final String? accessToken;
  final DateTime? tokenExpiresAt;
  final DateTime? lastSyncedAt;

  const LocalUserProfile({
    required this.id,
    required this.username,
    this.avatarPath,
    required this.isAuthenticated,
    this.backendUserId,
    this.email,
    this.accessToken,
    this.tokenExpiresAt,
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
      tokenExpiresAt: null,
    );
  }

  factory LocalUserProfile.fromMap(Map<String, Object?> map) {
    return LocalUserProfile(
      id: readInt(map['id'], 1),
      username: map['username'] as String? ?? 'Usuario',
      avatarPath: map['avatar_path'] as String?,
      isAuthenticated: readBool(map['is_authenticated']),
      backendUserId: readOptionalInt(map['backend_user_id']),
      email: map['email'] as String?,
      accessToken: map['access_token'] as String?,
      tokenExpiresAt: readDateTime(map['token_expires_at']),
      lastSyncedAt: readDateTime(map['last_synced_at']),
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
      'token_expires_at': tokenExpiresAt?.millisecondsSinceEpoch,
      'last_synced_at': lastSyncedAt?.millisecondsSinceEpoch,
    };
  }

  factory LocalUserProfile.fromJson(String raw) {
    return LocalUserProfile.fromMap((jsonDecode(raw) as Map<String, dynamic>).cast<String, Object?>());
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  LocalUserProfile copyWith({
    int? id,
    String? username,
    String? avatarPath,
    bool? isAuthenticated,
    int? backendUserId,
    String? email,
    String? accessToken,
    DateTime? tokenExpiresAt,
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
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
