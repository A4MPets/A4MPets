import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/route_record.dart';
import 'package:frontend/services/guest_data_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('GuestDataStore (F2-018-extra)', () {
    test(
      'almacena, actualiza, incrementa y marca mascota encontrada',
      () async {
        final GuestDataStore store = GuestDataStore();
        final int id = await store.addPet(
          name: 'Luna QA',
          photoPath: '/tmp/luna.png',
          adoptionDate: DateTime(2024, 1, 2),
          birthDate: DateTime(2023, 3, 4),
        );

        expect(id, equals(1));
        expect((await store.getPets()).single.name, equals('Luna QA'));

        await store.updatePet(petId: id, name: 'Luna Editada', photoPath: null);
        expect((await store.getPets()).single.name, equals('Luna Editada'));

        await store.incrementPetWalks(petIds: <int>{id, 999});
        expect((await store.getPets()).single.totalWalks, equals(1));

        await store.markPetFound(petId: id);
        expect((await store.getPets()).single.status, equals('normal'));

        await store.deletePet(petId: id);
        expect(await store.getPets(), isEmpty);
      },
    );

    test('almacena, actualiza y elimina rutas locales', () async {
      final GuestDataStore store = GuestDataStore();
      final int id = await store.addRoute(
        name: 'Ruta QA',
        points: const <RoutePoint>[
          RoutePoint(latitude: 3.45, longitude: -76.53),
          RoutePoint(latitude: 3.46, longitude: -76.54),
        ],
      );

      expect(id, equals(1));
      expect((await store.getRoutes()).single.points.length, equals(2));

      await store.updateRoute(
        routeId: id,
        name: 'Ruta editada',
        points: const <RoutePoint>[
          RoutePoint(latitude: 3.47, longitude: -76.55),
        ],
      );
      expect((await store.getRoutes()).single.name, equals('Ruta editada'));
      expect(
        (await store.getRoutes()).single.points.single.latitude,
        equals(3.47),
      );

      await store.deleteRoute(routeId: id);
      expect(await store.getRoutes(), isEmpty);
    });

    test(
      'clear borra listas e ids y JSON corrupto retorna listas vacias',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'a4m_guest_pets': '{no-json',
          'a4m_guest_routes': '{"not":"list"}',
        });

        final GuestDataStore store = GuestDataStore();
        expect(await store.getPets(), isEmpty);
        expect(await store.getRoutes(), isEmpty);

        await store.addPet(name: 'Temporal');
        await store.addRoute(
          name: 'Temporal',
          points: const <RoutePoint>[RoutePoint(latitude: 1, longitude: 2)],
        );
        await store.clear();

        expect(await store.getPets(), isEmpty);
        expect(await store.getRoutes(), isEmpty);
        expect(await store.addPet(name: 'Reinicia id'), equals(1));
      },
    );
  });
}
