import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/backend_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    BackendApiClient.workingBaseUrl = null;
  });

  group('BackendApiClient (F2-016-extra)', () {
    test('jsonHeaders agrega Content-Type, Accept y Authorization', () {
      final BackendApiClient client = BackendApiClient();

      expect(
        client.jsonHeaders(bearerToken: 'token-qa'),
        containsPair('Authorization', 'Bearer token-qa'),
      );
      expect(client.jsonHeaders(), isNot(contains('Authorization')));
      expect(
        client.jsonHeaders(),
        containsPair('Content-Type', 'application/json'),
      );
      expect(client.jsonHeaders(), containsPair('Accept', 'application/json'));
    });

    test('baseUrls elimina duplicados conocidos', () {
      final BackendApiClient client = BackendApiClient();

      expect(client.baseUrls, contains('http://localhost:8000/api'));
      expect(client.baseUrls, contains('http://127.0.0.1:8000/api'));
      expect(client.baseUrls.toSet().length, equals(client.baseUrls.length));
    });

    test(
      'postWithFallback devuelve primera respuesta menor a 500 y guarda base',
      () async {
        int calls = 0;
        final BackendApiClient client = BackendApiClient(
          httpClient: MockClient((http.Request request) async {
            calls += 1;
            expect(request.headers['Authorization'], equals('Bearer token-qa'));
            expect(request.body, contains('"name":"Luna"'));
            if (calls == 1) {
              return http.Response('server error', 500);
            }
            return http.Response('{"success":true}', 201);
          }),
        );

        final http.Response? response = await client.postWithFallback(
          '/pets',
          body: <String, Object?>{'name': 'Luna'},
          bearerToken: 'token-qa',
        );

        expect(response?.statusCode, equals(201));
        expect(calls, equals(2));
        expect(
          BackendApiClient.workingBaseUrl,
          equals('http://127.0.0.1:8000/api'),
        );
      },
    );

    test('getWithFallback continua despues de excepcion de red', () async {
      int calls = 0;
      final BackendApiClient client = BackendApiClient(
        httpClient: MockClient((http.Request request) async {
          calls += 1;
          if (calls == 1) {
            throw Exception('offline');
          }
          return http.Response('{"data":[]}', 200);
        }),
      );

      final http.Response? response = await client.getWithFallback('/hazards');

      expect(response?.statusCode, equals(200));
      expect(calls, equals(2));
    });

    test(
      'putWithFallback y deleteWithFallback retornan ultimo error servidor',
      () async {
        final BackendApiClient putClient = BackendApiClient(
          httpClient: MockClient(
            (_) async => http.Response('server error', 503),
          ),
        );
        final BackendApiClient deleteClient = BackendApiClient(
          httpClient: MockClient(
            (_) async => http.Response('server error', 502),
          ),
        );

        final http.Response? put = await putClient.putWithFallback(
          '/pets/1',
          body: <String, Object?>{'name': 'Mia'},
        );
        final http.Response? delete = await deleteClient.deleteWithFallback(
          '/pets/1',
        );

        expect(put?.statusCode, equals(503));
        expect(delete?.statusCode, equals(502));
      },
    );
  });
}
