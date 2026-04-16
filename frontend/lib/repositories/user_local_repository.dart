import 'dart:async';
import 'dart:convert';

import '../models/local_user_profile.dart';
import '../models/hazard_report_record.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';
import '../services/backend_api_client.dart';
import '../services/local_database_manager.dart';
import '../services/user_data_sync_coordinator.dart';

class UserLocalRepository {
  final LocalDatabaseManager databaseManager;
  final UserDataSyncCoordinator syncCoordinator;
  final BackendApiClient _apiClient = BackendApiClient();

  UserLocalRepository({
    required this.databaseManager,
    required this.syncCoordinator,
  });

  Future<LocalUserProfile> getUserProfile() {
    return databaseManager.getLocalUserProfile();
  }

  Future<LocalUserProfile> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final httpResponse = await _apiClient.postWithFallback(
      '/auth/register',
      body: <String, Object?>{
        'name': username,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    if (httpResponse == null) {
      throw Exception('No se pudo conectar con el backend para registrar la cuenta.');
    }

    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
      throw Exception(httpResponse.body);
    }

    final Map<String, dynamic> payload = jsonDecode(httpResponse.body) as Map<String, dynamic>;
    final Map<String, dynamic> data = (payload['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> user = (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final LocalUserProfile profile = LocalUserProfile(
      id: user['id'] as int,
      username: user['name'] as String,
      avatarPath: null,
      isAuthenticated: true,
      backendUserId: user['id'] as int,
      email: user['email'] as String?,
      accessToken: data['access_token'] as String?,
      lastSyncedAt: DateTime.now(),
    );

    await databaseManager.saveLocalUserProfile(profile);
    // Registro: conservar datos guest locales y migrarlos a la cuenta nueva.
    await syncCoordinator.syncNow();
    return profile;
  }

  Future<LocalUserProfile> login({
    required String login,
    required String password,
  }) async {
    final httpResponse = await _apiClient.postWithFallback(
      '/auth/login',
      body: <String, Object?>{
        'login': login,
        'password': password,
      },
    );

    if (httpResponse == null) {
      throw Exception('No se pudo conectar con el backend para iniciar sesión.');
    }

    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
      throw Exception(httpResponse.body);
    }

    final Map<String, dynamic> payload = jsonDecode(httpResponse.body) as Map<String, dynamic>;
    final Map<String, dynamic> data = (payload['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> user = (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final LocalUserProfile profile = LocalUserProfile(
      id: user['id'] as int,
      username: user['name'] as String,
      avatarPath: null,
      isAuthenticated: true,
      backendUserId: user['id'] as int,
      email: user['email'] as String?,
      accessToken: data['access_token'] as String?,
      lastSyncedAt: DateTime.now(),
    );

    // Login en cuenta existente: descartar datos guest locales antes de cargar remoto.
    await databaseManager.clearUserSessionData();
    await databaseManager.saveLocalUserProfile(profile);
    await syncCoordinator.syncNow();
    return profile;
  }

  Future<void> logout() async {
    final LocalUserProfile profile = await databaseManager.getLocalUserProfile();
    final String? token = profile.accessToken;

    if (token != null && token.isNotEmpty) {
      await _apiClient.postWithFallback(
        '/auth/logout',
        body: <String, Object?>{},
        bearerToken: token,
      );
    }

    await databaseManager.clearUserSessionData();
    await databaseManager.saveLocalUserProfile(LocalUserProfile.guest());
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
