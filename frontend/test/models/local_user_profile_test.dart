import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/local_user_profile.dart';

/// Tests unitarios para LocalUserProfile (serialización/deserialización)
/// Casos F2: F2-006
void main() {
  group('LocalUserProfile - factory guest (F2-006)', () {
    test('guest() crea perfil no autenticado con valores por defecto', () {
      final LocalUserProfile guest = LocalUserProfile.guest();

      expect(guest.isAuthenticated, isFalse);
      expect(guest.accessToken, isNull);
      expect(guest.backendUserId, isNull);
      expect(guest.email, isNull);
      expect(guest.id, equals(1));
      expect(guest.username, equals('Usuario'));
    });
  });

  group('LocalUserProfile - fromMap (F2-006)', () {
    test('fromMap construye perfil autenticado con todos los campos', () {
      final int now = DateTime.now().millisecondsSinceEpoch;

      final LocalUserProfile profile =
          LocalUserProfile.fromMap(<String, Object?>{
            'id': 42,
            'username': 'qa_user',
            'avatar_path': '/storage/avatar.jpg',
            'is_authenticated': 1,
            'backend_user_id': 100,
            'email': 'qa@a4mpets.test',
            'access_token': 'token_abc123',
            'token_expires_at': now,
            'last_synced_at': now,
          });

      expect(profile.id, equals(42));
      expect(profile.username, equals('qa_user'));
      expect(profile.isAuthenticated, isTrue);
      expect(profile.backendUserId, equals(100));
      expect(profile.email, equals('qa@a4mpets.test'));
      expect(profile.accessToken, equals('token_abc123'));
      expect(profile.tokenExpiresAt, isNotNull);
      expect(profile.lastSyncedAt, isNotNull);
    });

    test('fromMap con is_authenticated=0 produce isAuthenticated false', () {
      final LocalUserProfile profile = LocalUserProfile.fromMap(
        <String, Object?>{'id': 1, 'is_authenticated': 0},
      );

      expect(profile.isAuthenticated, isFalse);
    });

    test('fromMap con campos nulos usa valores por defecto', () {
      final LocalUserProfile profile = LocalUserProfile.fromMap(
        <String, Object?>{},
      );

      expect(profile.id, equals(1));
      expect(profile.username, equals('Usuario'));
      expect(profile.isAuthenticated, isFalse);
      expect(profile.accessToken, isNull);
    });
  });

  group('LocalUserProfile - toMap/toJson/fromJson (F2-006)', () {
    test('toMap serializa campos booleanos como enteros', () {
      final LocalUserProfile profile = LocalUserProfile(
        id: 5,
        username: 'qa_tester',
        isAuthenticated: true,
        accessToken: 'token_xyz',
        tokenExpiresAt: DateTime.fromMillisecondsSinceEpoch(123456789),
      );

      final Map<String, Object?> map = profile.toMap();

      expect(map['is_authenticated'], equals(1));
      expect(map['username'], equals('qa_tester'));
      expect(map['access_token'], equals('token_xyz'));
      expect(map['token_expires_at'], equals(123456789));
    });

    test('toJson y fromJson mantienen consistencia de datos (roundtrip)', () {
      final LocalUserProfile original = LocalUserProfile(
        id: 7,
        username: 'roundtrip_user',
        isAuthenticated: true,
        backendUserId: 200,
        email: 'rt@test.com',
        accessToken: 'rt_token',
        tokenExpiresAt: DateTime.fromMillisecondsSinceEpoch(987654321),
      );

      final String json = original.toJson();
      final LocalUserProfile restored = LocalUserProfile.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.username, equals(original.username));
      expect(restored.isAuthenticated, equals(original.isAuthenticated));
      expect(restored.backendUserId, equals(original.backendUserId));
      expect(restored.email, equals(original.email));
      expect(restored.accessToken, equals(original.accessToken));
      expect(restored.tokenExpiresAt, equals(original.tokenExpiresAt));
    });
  });

  group('LocalUserProfile - copyWith', () {
    test('copyWith preserva campos no modificados', () {
      const LocalUserProfile original = LocalUserProfile(
        id: 10,
        username: 'original',
        isAuthenticated: false,
      );

      final LocalUserProfile modified = original.copyWith(
        username: 'modificado',
        isAuthenticated: true,
        accessToken: 'new_token',
      );

      expect(modified.id, equals(original.id));
      expect(modified.username, equals('modificado'));
      expect(modified.isAuthenticated, isTrue);
      expect(modified.accessToken, equals('new_token'));
    });
  });
}
