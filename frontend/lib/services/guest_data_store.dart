import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet_record.dart';
import '../models/route_record.dart';

class GuestDataStore {
  static const String _petsKey = 'a4m_guest_pets';
  static const String _routesKey = 'a4m_guest_routes';
  static const String _nextPetIdKey = 'a4m_guest_next_pet_id';
  static const String _nextRouteIdKey = 'a4m_guest_next_route_id';

  Future<List<PetRecord>> getPets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<dynamic> raw = _decodeList(prefs.getString(_petsKey));
    return raw
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> item) => PetRecord.fromMap(item))
        .toList(growable: false);
  }

  Future<List<RouteRecord>> getRoutes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<dynamic> raw = _decodeList(prefs.getString(_routesKey));
    return raw
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> item) => RouteRecord.fromMap(item))
        .toList(growable: false);
  }

  Future<int> addPet({
    String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
    bool isOwnerless = false,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int id = await _nextId(prefs, _nextPetIdKey);
    final DateTime now = DateTime.now();
    final PetRecord pet = PetRecord(
      id: id,
      localUuid: 'guest_pet_${now.microsecondsSinceEpoch}_$id',
      remoteId: null,
      name: name,
      photoPath: photoPath,
      totalWalks: 0,
      registeredAt: now,
      adoptionDate: adoptionDate,
      birthDate: birthDate,
      status: 'normal',
      isOwnerless: isOwnerless,
      syncStatus: 'local',
      lastModifiedAt: now,
      createdAt: now,
      updatedAt: now,
      needsSync: false,
    );

    final List<PetRecord> pets = <PetRecord>[...await getPets(), pet];
    await _savePets(pets);
    return id;
  }

  Future<void> updatePet({
    required int petId,
    required String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
  }) async {
    final DateTime now = DateTime.now();
    final List<PetRecord> pets = (await getPets())
        .map((PetRecord pet) {
          if (pet.id != petId) {
            return pet;
          }
          return PetRecord(
            id: pet.id,
            localUuid: pet.localUuid,
            remoteId: pet.remoteId,
            name: name,
            photoPath: photoPath,
            totalWalks: pet.totalWalks,
            registeredAt: pet.registeredAt,
            adoptionDate: adoptionDate,
            birthDate: birthDate,
            status: pet.status,
            isOwnerless: pet.isOwnerless,
            syncStatus: 'local',
            lastModifiedAt: now,
            createdAt: pet.createdAt,
            updatedAt: now,
            needsSync: false,
          );
        })
        .toList(growable: false);
    await _savePets(pets);
  }

  Future<void> deletePet({required int petId}) async {
    final List<PetRecord> pets = (await getPets())
        .where((PetRecord pet) => pet.id != petId)
        .toList(growable: false);
    await _savePets(pets);
  }

  Future<void> incrementPetWalks({required Iterable<int> petIds}) async {
    final Set<int> selectedIds = petIds.toSet();
    final DateTime now = DateTime.now();
    final List<PetRecord> pets = (await getPets())
        .map((PetRecord pet) {
          if (!selectedIds.contains(pet.id)) {
            return pet;
          }
          return PetRecord(
            id: pet.id,
            localUuid: pet.localUuid,
            remoteId: pet.remoteId,
            name: pet.name,
            photoPath: pet.photoPath,
            totalWalks: pet.totalWalks + 1,
            registeredAt: pet.registeredAt,
            adoptionDate: pet.adoptionDate,
            birthDate: pet.birthDate,
            status: pet.status,
            isOwnerless: pet.isOwnerless,
            syncStatus: 'local',
            lastModifiedAt: now,
            createdAt: pet.createdAt,
            updatedAt: now,
            needsSync: false,
          );
        })
        .toList(growable: false);
    await _savePets(pets);
  }

  Future<void> markPetFound({required int petId}) async {
    final DateTime now = DateTime.now();
    final List<PetRecord> pets = (await getPets())
        .map((PetRecord pet) {
          if (pet.id != petId) {
            return pet;
          }
          return PetRecord(
            id: pet.id,
            localUuid: pet.localUuid,
            remoteId: pet.remoteId,
            name: pet.name,
            photoPath: pet.photoPath,
            totalWalks: pet.totalWalks,
            registeredAt: pet.registeredAt,
            adoptionDate: pet.adoptionDate,
            birthDate: pet.birthDate,
            status: 'normal',
            isOwnerless: pet.isOwnerless,
            syncStatus: 'local',
            lastModifiedAt: now,
            createdAt: pet.createdAt,
            updatedAt: now,
            needsSync: false,
          );
        })
        .toList(growable: false);
    await _savePets(pets);
  }

  Future<int> addRoute({
    required String name,
    required List<RoutePoint> points,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int id = await _nextId(prefs, _nextRouteIdKey);
    final DateTime now = DateTime.now();
    final RouteRecord route = RouteRecord(
      id: id,
      remoteId: null,
      name: name,
      points: points,
      syncStatus: 'local',
      lastModifiedAt: now,
      createdAt: now,
      updatedAt: now,
      needsSync: false,
    );

    final List<RouteRecord> routes = <RouteRecord>[...await getRoutes(), route];
    await _saveRoutes(routes);
    return id;
  }

  Future<void> updateRoute({
    required int routeId,
    required String name,
    required List<RoutePoint> points,
  }) async {
    final DateTime now = DateTime.now();
    final List<RouteRecord> routes = (await getRoutes())
        .map((RouteRecord route) {
          if (route.id != routeId) {
            return route;
          }
          return RouteRecord(
            id: route.id,
            remoteId: route.remoteId,
            name: name,
            points: points,
            syncStatus: 'local',
            lastModifiedAt: now,
            createdAt: route.createdAt,
            updatedAt: now,
            needsSync: false,
          );
        })
        .toList(growable: false);
    await _saveRoutes(routes);
  }

  Future<void> deleteRoute({required int routeId}) async {
    final List<RouteRecord> routes = (await getRoutes())
        .where((RouteRecord route) => route.id != routeId)
        .toList(growable: false);
    await _saveRoutes(routes);
  }

  Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_petsKey);
    await prefs.remove(_routesKey);
    await prefs.remove(_nextPetIdKey);
    await prefs.remove(_nextRouteIdKey);
  }

  Future<void> _savePets(List<PetRecord> pets) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _petsKey,
      jsonEncode(pets.map((PetRecord pet) => pet.toMap()).toList()),
    );
  }

  Future<void> _saveRoutes(List<RouteRecord> routes) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _routesKey,
      jsonEncode(routes.map((RouteRecord route) => route.toMap()).toList()),
    );
  }

  Future<int> _nextId(SharedPreferences prefs, String key) async {
    final int id = prefs.getInt(key) ?? 1;
    await prefs.setInt(key, id + 1);
    return id;
  }

  List<dynamic> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <dynamic>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is List<dynamic> ? decoded : const <dynamic>[];
    } catch (_) {
      return const <dynamic>[];
    }
  }
}
