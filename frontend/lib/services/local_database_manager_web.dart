import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user_profile.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';

class LocalDatabaseManager {
  LocalDatabaseManager();

  static const String _userKey = 'local_user_profile_json';
  static const String _petsKey = 'pets_list_json';
  static const String _routesKey = 'routes_list_json';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> _ensureDefaultUser(SharedPreferences prefs) async {
    if (!prefs.containsKey(_userKey)) {
      await prefs.setString(_userKey, jsonEncode(LocalUserProfile.guest().toMap()));
    }

    if (!prefs.containsKey(_petsKey)) {
      await prefs.setString(_petsKey, jsonEncode(<Map<String, Object?>>[]));
    }

    if (!prefs.containsKey(_routesKey)) {
      await prefs.setString(_routesKey, jsonEncode(<Map<String, Object?>>[]));

    }
  }

  Future<LocalUserProfile> getLocalUserProfile() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final String raw = prefs.getString(_userKey)!;
    final Map<String, Object?> map = (jsonDecode(raw) as Map<String, dynamic>).cast<String, Object?>();
    return LocalUserProfile.fromMap(map);
  }

  Future<void> saveLocalUserProfile(LocalUserProfile profile) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    await prefs.setString(_userKey, jsonEncode(profile.toMap()));
  }

  Future<List<PetRecord>> getPets() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final String raw = prefs.getString(_petsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map((dynamic row) => PetRecord.fromMap((row as Map<String, dynamic>).cast<String, Object?>()))
        .toList(growable: false);
  }

  Future<int> addPet({
    required String name,
    String? photoPath,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final List<PetRecord> currentPets = await getPets();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int nextId = currentPets.isEmpty
        ? 1
        : currentPets.map((PetRecord pet) => pet.id).reduce((int a, int b) => a > b ? a : b) + 1;

    final PetRecord newPet = PetRecord(
      id: nextId,
      name: name,
      photoPath: photoPath,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );

    final List<Map<String, Object?>> encodedPets = <Map<String, Object?>>[
      ...currentPets.map((PetRecord pet) => pet.toMap()),
      newPet.toMap(),
    ];

    await prefs.setString(_petsKey, jsonEncode(encodedPets));
    return nextId;
  }

  Future<int> getPetsCount() async {
    final List<PetRecord> pets = await getPets();
    return pets.length;
  }

  Future<void> updatePet({
    required int petId,
    required String name,
    String? photoPath,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final List<PetRecord> currentPets = await getPets();
    final int now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, Object?>> encodedPets = currentPets.map((PetRecord pet) {
      if (pet.id == petId) {
        return PetRecord(
          id: pet.id,
          name: name,
          photoPath: photoPath,
          createdAt: pet.createdAt,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
          needsSync: true,
        ).toMap();
      }
      return pet.toMap();
    }).toList();

    await prefs.setString(_petsKey, jsonEncode(encodedPets));
  }

  Future<void> deletePet({required int petId}) async {
    final SharedPreferences prefs = await _prefs;
    final List<PetRecord> currentPets = await getPets();

    final List<Map<String, Object?>> encodedPets = currentPets
        .where((PetRecord pet) => pet.id != petId)
        .map((PetRecord pet) => pet.toMap())
        .toList();

    await prefs.setString(_petsKey, jsonEncode(encodedPets));
  }

  Future<List<RouteRecord>> getRoutes() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_routesKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic row) => RouteRecord.fromMap(
              (row as Map<String, dynamic>).cast<String, Object?>(),
            ))
        .toList(growable: false);
  }

  Future<int> addRoute({
    required String name,
    required List<RoutePoint> points,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<RouteRecord> current = await getRoutes();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int nextId = current.isEmpty
        ? 1
        : current.map((RouteRecord r) => r.id).reduce((int a, int b) => a > b ? a : b) + 1;
    final RouteRecord newRoute = RouteRecord(
      id: nextId,
      name: name,
      points: points,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );
    final List<Map<String, Object?>> encoded = <Map<String, Object?>>[
      ...current.map((RouteRecord r) => r.toMap()),
      newRoute.toMap(),
    ];
    await prefs.setString(_routesKey, jsonEncode(encoded));
    return nextId;
  }

  Future<int> getRoutesCount() async {
    final List<RouteRecord> routes = await getRoutes();
    return routes.length;
  }

  Future<void> deleteRoute({required int routeId}) async {
    final SharedPreferences prefs = await _prefs;
    final List<RouteRecord> current = await getRoutes();
    final List<Map<String, Object?>> encoded = current
        .where((RouteRecord r) => r.id != routeId)
        .map((RouteRecord r) => r.toMap())
        .toList();
    await prefs.setString(_routesKey, jsonEncode(encoded));
  }

  Future<void> updateRoute({
    required int routeId,
    required String name,
    required List<RoutePoint> points,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final List<RouteRecord> current = await getRoutes();
    final int now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, Object?>> encoded = current.map((RouteRecord route) {
      if (route.id == routeId) {
        return RouteRecord(
          id: route.id,
          name: name,
          points: points,
          createdAt: route.createdAt,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
          needsSync: true,
        ).toMap();
      }
      return route.toMap();
    }).toList();

    await prefs.setString(_routesKey, jsonEncode(encoded));
  }

  Future<void> markUserDataForFutureSync() async {}
}
