import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/local_user_profile.dart';
import 'package:frontend/models/route_record.dart';
import 'package:frontend/repositories/user_local_repository.dart';
import 'package:frontend/services/backend_api_client.dart';
import 'package:frontend/services/guest_data_store.dart';
import 'package:frontend/services/session_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    BackendApiClient.workingBaseUrl = null;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  UserLocalRepository repositoryWith(MockClient client) {
    return UserLocalRepository(
      sessionStore: SessionStore(),
      guestDataStore: GuestDataStore(),
      apiClient: BackendApiClient(httpClient: client),
    );
  }

  Future<void> saveAuthenticatedSession() {
    return SessionStore().saveLocalUserProfile(
      const LocalUserProfile(
        id: 7,
        username: 'Play Reviewer',
        isAuthenticated: true,
        backendUserId: 7,
        email: 'reviewer@a4mpets.test',
        accessToken: 'token-reviewer',
      ),
    );
  }

  group('UserLocalRepository.deleteAccount', () {
    test(
      'envia password y confirmacion, luego limpia sesion y datos locales',
      () async {
        await saveAuthenticatedSession();
        await GuestDataStore().addPet(name: 'Luna QA');
        await GuestDataStore().addRoute(
          name: 'Ruta QA',
          points: const <RoutePoint>[
            RoutePoint(latitude: 4.71, longitude: -74.07),
          ],
        );

        final UserLocalRepository repository = repositoryWith(
          MockClient((http.Request request) async {
            expect(request.method, equals('DELETE'));
            expect(request.url.path, equals('/api/auth/account'));
            expect(
              request.headers['Authorization'],
              equals('Bearer token-reviewer'),
            );
            expect(
              jsonDecode(request.body),
              equals(<String, Object?>{
                'password': 'ReviewerPass123!',
                'confirmation': 'ELIMINAR',
              }),
            );

            return http.Response('{"success":true}', 200);
          }),
        );

        await repository.deleteAccount(
          password: 'ReviewerPass123!',
          confirmation: 'ELIMINAR',
        );

        final LocalUserProfile profile = await SessionStore()
            .getLocalUserProfile();
        expect(profile.isAuthenticated, isFalse);
        expect(profile.accessToken, isNull);
        expect(await GuestDataStore().getPets(), isEmpty);
        expect(await GuestDataStore().getRoutes(), isEmpty);
      },
    );

    test('mapea error de password sin limpiar sesion local', () async {
      await saveAuthenticatedSession();
      await GuestDataStore().addPet(name: 'Luna QA');

      final UserLocalRepository repository = repositoryWith(
        MockClient((_) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'message': 'The given data was invalid.',
              'errors': <String, Object?>{
                'password': <String>['La contrasena no es valida.'],
              },
            }),
            422,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      await expectLater(
        repository.deleteAccount(password: 'bad', confirmation: 'ELIMINAR'),
        throwsA(
          predicate(
            (Object error) =>
                error.toString().contains('La contrasena no es valida.'),
          ),
        ),
      );

      final LocalUserProfile profile = await SessionStore()
          .getLocalUserProfile();
      expect(profile.isAuthenticated, isTrue);
      expect(await GuestDataStore().getPets(), isNotEmpty);
    });

    test('requiere sesion autenticada antes de llamar al backend', () async {
      final UserLocalRepository repository = repositoryWith(
        MockClient((_) async => http.Response('should-not-run', 500)),
      );

      await expectLater(
        repository.deleteAccount(password: 'secret', confirmation: 'ELIMINAR'),
        throwsA(
          predicate(
            (Object error) => error.toString().contains(
              'Debes iniciar sesion para realizar esta accion.',
            ),
          ),
        ),
      );
    });
  });
}
