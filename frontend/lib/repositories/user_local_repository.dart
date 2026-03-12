import '../models/local_user_profile.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';
import '../services/local_database_manager.dart';
import '../services/user_data_sync_coordinator.dart';

class UserLocalRepository {
  final LocalDatabaseManager databaseManager;
  final UserDataSyncCoordinator syncCoordinator;

  const UserLocalRepository({
    required this.databaseManager,
    required this.syncCoordinator,
  });

  Future<LocalUserProfile> getUserProfile() {
    return databaseManager.getLocalUserProfile();
  }

  Future<List<PetRecord>> getPets() {
    return databaseManager.getPets();
  }

  Future<int> getPetsCount() {
    return databaseManager.getPetsCount();
  }

  Future<void> addPet({
    required String name,
    String? photoPath,
  }) async {
    await databaseManager.addPet(name: name, photoPath: photoPath);
    await databaseManager.markUserDataForFutureSync();
    await syncCoordinator.scheduleSync();
  }

  Future<void> updatePet({
    required int petId,
    required String name,
    String? photoPath,
  }) async {
    await databaseManager.updatePet(petId: petId, name: name, photoPath: photoPath);
    await databaseManager.markUserDataForFutureSync();
    await syncCoordinator.scheduleSync();
  }

  Future<void> deletePet({required int petId}) async {
    await databaseManager.deletePet(petId: petId);
    await databaseManager.markUserDataForFutureSync();
    await syncCoordinator.scheduleSync();
  }

  Future<List<RouteRecord>> getRoutes() {
    return databaseManager.getRoutes();
  }

  Future<int> getRoutesCount() {
    return databaseManager.getRoutesCount();
  }

  Future<void> addRoute({
    required String name,
    required List<RoutePoint> points,
  }) async {
    await databaseManager.addRoute(name: name, points: points);
    await databaseManager.markUserDataForFutureSync();
    await syncCoordinator.scheduleSync();
  }

  Future<void> deleteRoute({required int routeId}) async {
    await databaseManager.deleteRoute(routeId: routeId);
    await databaseManager.markUserDataForFutureSync();
    await syncCoordinator.scheduleSync();
  }

  Future<void> updateRoute({
    required int routeId,
    required String name,
    required List<RoutePoint> points,
  }) async {
    await databaseManager.updateRoute(routeId: routeId, name: name, points: points);
    await databaseManager.markUserDataForFutureSync();
    await syncCoordinator.scheduleSync();
  }
}
