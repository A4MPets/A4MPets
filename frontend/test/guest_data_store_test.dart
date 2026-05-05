import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/route_record.dart';
import 'package:frontend/services/guest_data_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('guest data store persists pets and routes until cleared', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final GuestDataStore store = GuestDataStore();

    final int petId = await store.addPet(
      name: 'Luna',
      photoPath: 'data:image/png;base64,abc',
      adoptionDate: DateTime(2024, 5, 20),
      birthDate: DateTime(2024, 1, 15),
    );
    final int routeId = await store.addRoute(
      name: 'Ruta parque',
      points: const <RoutePoint>[
        RoutePoint(latitude: 3.4516, longitude: -76.5320),
        RoutePoint(latitude: 3.4570, longitude: -76.5280),
      ],
    );

    final pets = await store.getPets();
    final routes = await store.getRoutes();

    expect(pets, hasLength(1));
    expect(pets.single.id, petId);
    expect(pets.single.name, 'Luna');
    expect(pets.single.photoPath, startsWith('data:image/png'));
    expect(routes, hasLength(1));
    expect(routes.single.id, routeId);
    expect(routes.single.points, hasLength(2));

    await store.clear();

    expect(await store.getPets(), isEmpty);
    expect(await store.getRoutes(), isEmpty);
  });
}
