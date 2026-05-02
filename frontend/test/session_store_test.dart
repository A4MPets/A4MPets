import 'package:frontend/models/local_user_profile.dart';
import 'package:frontend/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'session store persists authenticated profile across instances',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final SessionStore firstStore = SessionStore();
      await firstStore.saveLocalUserProfile(
        const LocalUserProfile(
          id: 42,
          username: 'Nestor',
          avatarPath: 'https://example.test/avatar.png',
          isAuthenticated: true,
          backendUserId: 42,
          email: 'nestor@example.test',
          accessToken: 'persisted-token',
        ),
      );

      final LocalUserProfile restored = await SessionStore()
          .getLocalUserProfile();

      expect(restored.isAuthenticated, isTrue);
      expect(restored.id, 42);
      expect(restored.username, 'Nestor');
      expect(restored.avatarPath, 'https://example.test/avatar.png');
      expect(restored.accessToken, 'persisted-token');
    },
  );

  test('local user profile parses bool session flags', () {
    final LocalUserProfile profile = LocalUserProfile.fromMap(<String, Object?>{
      'id': 7,
      'username': 'Ana',
      'is_authenticated': true,
      'backend_user_id': 7,
      'access_token': 'token',
    });

    expect(profile.isAuthenticated, isTrue);
    expect(profile.backendUserId, 7);
    expect(profile.accessToken, 'token');
  });
}
