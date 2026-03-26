import 'dart:async';

import '../models/local_user_profile.dart';
import '../models/hazard_report_record.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';
import '../services/local_database_manager.dart';
import '../services/user_data_sync_coordinator.dart';

class UserLocalRepository {
  final LocalDatabaseManager databaseManager;
  final UserDataSyncCoordinator syncCoordinator;

  UserLocalRepository({
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
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> updatePet({
    required int petId,
    required String name,
    String? photoPath,
  }) async {
    await databaseManager.updatePet(petId: petId, name: name, photoPath: photoPath);
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> deletePet({required int petId}) async {
    await databaseManager.deletePet(petId: petId);
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
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
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> deleteRoute({required int routeId}) async {
    await databaseManager.deleteRoute(routeId: routeId);
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> updateRoute({
    required int routeId,
    required String name,
    required List<RoutePoint> points,
  }) async {
    await databaseManager.updateRoute(routeId: routeId, name: name, points: points);
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<List<HazardReportRecord>> getHazardReports() {
    return databaseManager.getHazardReports();
  }

  Future<void> addHazardReport({
    required double incidentLatitude,
    required double incidentLongitude,
    required int impactRadiusMeters,
    required String categoryCode,
    required String narrativeDescription,
    required DateTime reportedAt,
    required String estimatedDurationCode,
    required String riskLevelCode,
    String? evidencePhotoUrl,
    required String reportedByUsername,
  }) async {
    await databaseManager.addHazardReport(
      incidentLatitude: incidentLatitude,
      incidentLongitude: incidentLongitude,
      impactRadiusMeters: impactRadiusMeters,
      categoryCode: categoryCode,
      narrativeDescription: narrativeDescription,
      reportedAt: reportedAt,
      estimatedDurationCode: estimatedDurationCode,
      riskLevelCode: riskLevelCode,
      evidencePhotoUrl: evidencePhotoUrl,
      reportedByUsername: reportedByUsername,
    );
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> addCommentToHazard({
    required int hazardId,
    required HazardCommentRecord comment,
  }) async {
    await databaseManager.addCommentToHazard(
      hazardId: hazardId,
      comment: comment,
    );
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> syncHazardsNow() {
    return syncCoordinator.syncNow();
  }
}
