import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/local_user_profile.dart';
import 'package:frontend/services/session_store.dart';

/// Tests unitarios para SessionStore
/// Casos F2: F2-003, F2-004, F2-005
void main() {
  setUp(() {
    // Inicializa SharedPreferences con estado vacío antes de cada test
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SessionStore.getLocalUserProfile (F2-003)', () {
    test('retorna perfil guest cuando no hay datos guardados', () async {
      final SessionStore store = SessionStore();
      final LocalUserProfile profile = await store.getLocalUserProfile();

      expect(profile.isAuthenticated, isFalse);
      expect(profile.username, equals('Usuario'));
      expect(profile.accessToken, isNull);
    });

    test('retorna perfil guardado correctamente (F2-003)', () async {
      final SessionStore store = SessionStore();

      final LocalUserProfile saved = LocalUserProfile(
        id: 42,
        username: 'qa_tester',
        isAuthenticated: true,
        backendUserId: 100,
        email: 'qa@a4mpets.test',
        accessToken: 'bearer_token_abc',
      );

      await store.saveLocalUserProfile(saved);
      final LocalUserProfile loaded = await store.getLocalUserProfile();

      expect(loaded.id, equals(42));
      expect(loaded.username, equals('qa_tester'));
      expect(loaded.isAuthenticated, isTrue);
      expect(loaded.accessToken, equals('bearer_token_abc'));
      expect(loaded.email, equals('qa@a4mpets.test'));
    });
  });

  group('SessionStore.saveLocalUserProfile (F2-004)', () {
    test('guarda y recupera perfil con accessToken no nulo', () async {
      final SessionStore store = SessionStore();
      const LocalUserProfile profile = LocalUserProfile(
        id: 1,
        username: 'save_test_user',
        isAuthenticated: true,
        accessToken: 'token_xyz_123',
      );

      await store.saveLocalUserProfile(profile);

      final LocalUserProfile loaded = await store.getLocalUserProfile();
      expect(loaded.accessToken, equals('token_xyz_123'));
      expect(loaded.isAuthenticated, isTrue);
    });

    test('sobreescribe perfil anterior cuando se llama saveLocalUserProfile', () async {
      final SessionStore store = SessionStore();

      await store.saveLocalUserProfile(const LocalUserProfile(
        id: 1,
        username: 'usuario_inicial',
        isAuthenticated: false,
      ));

      await store.saveLocalUserProfile(const LocalUserProfile(
        id: 2,
        username: 'usuario_actualizado',
        isAuthenticated: true,
        accessToken: 'nuevo_token',
      ));

      final LocalUserProfile loaded = await store.getLocalUserProfile();
      expect(loaded.username, equals('usuario_actualizado'));
      expect(loaded.isAuthenticated, isTrue);
    });
  });

  group('SessionStore.clearUserSessionData (F2-005)', () {
    test('limpia los datos de sesión y retorna guest al consultar', () async {
      final SessionStore store = SessionStore();

      // Primero guardar un perfil
      await store.saveLocalUserProfile(const LocalUserProfile(
        id: 99,
        username: 'borrar_usuario',
        isAuthenticated: true,
        accessToken: 'token_a_borrar',
      ));

      // Limpiar
      await store.clearUserSessionData();

      // Verificar que se limpiaron los datos
      final LocalUserProfile profile = await store.getLocalUserProfile();
      expect(profile.isAuthenticated, isFalse);
      expect(profile.accessToken, isNull);
      expect(profile.username, equals('Usuario'));
    });

    test('clearUserSessionData no lanza excepción si no hay datos previos', () async {
      final SessionStore store = SessionStore();
      // No debería lanzar ninguna excepción
      await expectLater(store.clearUserSessionData(), completes);
    });
  });
}
