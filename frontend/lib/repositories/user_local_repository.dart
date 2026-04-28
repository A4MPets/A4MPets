import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/local_user_profile.dart';
import '../models/lost_pet_report_record.dart';
import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/pet_record.dart';
import '../models/report_comment_record.dart';
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
      throw Exception(
        'No pudimos conectarnos al servidor. Verifica tu conexión e intenta de nuevo.',
      );
    }

    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
      throw Exception(_mapRegisterError(httpResponse));
    }

    final Map<String, dynamic> payload =
        jsonDecode(httpResponse.body) as Map<String, dynamic>;
    final Map<String, dynamic> data =
        (payload['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> user =
        (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final LocalUserProfile profile = LocalUserProfile(
      id: user['id'] as int,
      username: user['name'] as String,
      avatarPath: user['profile_photo_url']?.toString(),
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
      body: <String, Object?>{'login': login, 'password': password},
    );

    if (httpResponse == null) {
      throw Exception(
        'No pudimos conectarnos al servidor. Revisa tu conexión e intenta nuevamente.',
      );
    }

    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
      throw Exception(_mapLoginError(httpResponse));
    }

    final Map<String, dynamic> payload =
        jsonDecode(httpResponse.body) as Map<String, dynamic>;
    final Map<String, dynamic> data =
        (payload['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> user =
        (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final LocalUserProfile profile = LocalUserProfile(
      id: user['id'] as int,
      username: user['name'] as String,
      avatarPath: user['profile_photo_url']?.toString(),
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
    final LocalUserProfile profile = await databaseManager
        .getLocalUserProfile();
    final String? token = profile.accessToken;

    syncCoordinator.discardQueuedSyncWork();

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

  Future<void> updateProfileAvatar({required String? avatarPath}) async {
    final LocalUserProfile current = await databaseManager
        .getLocalUserProfile();
    final LocalUserProfile updated = LocalUserProfile(
      id: current.id,
      username: current.username,
      avatarPath: avatarPath,
      isAuthenticated: current.isAuthenticated,
      backendUserId: current.backendUserId,
      email: current.email,
      accessToken: current.accessToken,
      lastSyncedAt: null,
    );

    await databaseManager.saveLocalUserProfile(updated);
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<List<PetRecord>> getPets() {
    return databaseManager.getPets();
  }

  Future<int> getPetsCount() {
    return databaseManager.getPetsCount();
  }

  Future<void> addPet({required String name, String? photoPath}) async {
    await databaseManager.addPet(name: name, photoPath: photoPath);
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> updatePet({
    required int petId,
    required String name,
    String? photoPath,
  }) async {
    await databaseManager.updatePet(
      petId: petId,
      name: name,
      photoPath: photoPath,
    );
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
    await databaseManager.updateRoute(
      routeId: routeId,
      name: name,
      points: points,
    );
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

  Future<void> addCommentToLostPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await databaseManager.addCommentToLostPetReport(
      reportId: reportId,
      comment: comment,
    );
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> syncHazardsNow() {
    return syncCoordinator.syncNow();
  }

  Future<List<LostPetReportRecord>> getLostPetReports() {
    return databaseManager.getLostPetReports();
  }

  Future<void> addLostPetReport({
    required double lastSeenLatitude,
    required double lastSeenLongitude,
    required String name,
    required String details,
    required DateTime disappearanceDate,
    required String photoUrl,
    required String phone,
  }) async {
    await databaseManager.addLostPetReport(
      lastSeenLatitude: lastSeenLatitude,
      lastSeenLongitude: lastSeenLongitude,
      name: name,
      details: details,
      disappearanceDate: disappearanceDate,
      photoUrl: photoUrl,
      phone: phone,
    );
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> syncLostPetReportsNow() {
    return syncCoordinator.syncNow();
  }

  Future<void> addCommentToFoundPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await databaseManager.addCommentToFoundPetReport(
      reportId: reportId,
      comment: comment,
    );
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<List<FoundPetReportRecord>> getFoundPetReports() {
    return databaseManager.getFoundPetReports();
  }

  Future<void> addFoundPetReport({
    required double latitude,
    required double longitude,
    required String details,
    required DateTime foundDate,
    String? photoUrl,
    String? phone,
  }) async {
    await databaseManager.addFoundPetReport(
      latitude: latitude,
      longitude: longitude,
      details: details,
      foundDate: foundDate,
      photoUrl: photoUrl,
      phone: phone,
    );
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> syncFoundPetReportsNow() {
    return syncCoordinator.syncNow();
  }

  Future<List<GenericReportRecord>> getGenericReports() {
    return databaseManager.getGenericReports();
  }

  Future<void> addGenericReport({
    required double latitude,
    required double longitude,
    required String description,
    required DateTime reportedDate,
    required String riskLevelCode,
    required int impactRadiusMeters,
    String? photoUrl,
  }) async {
    await databaseManager.addGenericReport(
      latitude: latitude,
      longitude: longitude,
      description: description,
      reportedDate: reportedDate,
      riskLevelCode: riskLevelCode,
      impactRadiusMeters: impactRadiusMeters,
      photoUrl: photoUrl,
    );
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> addCommentToGenericReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await databaseManager.addCommentToGenericReport(
      reportId: reportId,
      comment: comment,
    );
    await databaseManager.markUserDataForFutureSync();
    unawaited(syncCoordinator.scheduleSync());
  }

  Future<void> syncGenericReportsNow() {
    return syncCoordinator.syncNow();
  }

  String _mapLoginError(http.Response response) {
    final int status = response.statusCode;
    final Map<String, dynamic> body = _tryParseJson(response.body);
    final Map<String, dynamic> errors =
        (body['errors'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    if (status == 401) {
      return 'Tu usuario/correo o contraseña no son correctos.';
    }

    if (status == 422) {
      final String? loginError = _firstError(errors, 'login');
      final String? passwordError = _firstError(errors, 'password');

      if (loginError != null && loginError.isNotEmpty) {
        return 'Tu usuario/correo o contraseña no son correctos.';
      }

      if (passwordError != null &&
          passwordError.toLowerCase().contains('required')) {
        return 'Debes ingresar tu contraseña para iniciar sesión.';
      }

      return 'Revisa los datos ingresados e intenta nuevamente.';
    }

    if (status == 429) {
      return 'Has intentado demasiadas veces. Espera un momento y vuelve a intentarlo.';
    }

    if (status >= 500) {
      return 'En este momento el servidor no está disponible. Intenta nuevamente en unos minutos.';
    }

    return _fallbackMessage(
      body,
      'No fue posible iniciar sesión en este momento.',
    );
  }

  String _mapRegisterError(http.Response response) {
    final int status = response.statusCode;
    final Map<String, dynamic> body = _tryParseJson(response.body);
    final Map<String, dynamic> errors =
        (body['errors'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    if (status == 422) {
      final String? emailError = _firstError(errors, 'email');
      final String? nameError = _firstError(errors, 'name');
      final String? passwordError = _firstError(errors, 'password');

      if (emailError != null && emailError.toLowerCase().contains('taken')) {
        return 'Ya existe una cuenta registrada con ese correo.';
      }

      if (emailError != null &&
          emailError.toLowerCase().contains('valid email')) {
        return 'El correo electrónico no es válido.';
      }

      if (nameError != null && nameError.toLowerCase().contains('required')) {
        return 'Escribe un nombre de usuario para crear tu cuenta.';
      }

      if (passwordError != null &&
          passwordError.toLowerCase().contains('confirmed')) {
        return 'Las contraseñas no coinciden. Revisa ambos campos.';
      }

      if (passwordError != null &&
          passwordError.toLowerCase().contains('min')) {
        return 'La contraseña debe tener al menos 8 caracteres.';
      }

      return 'Revisa los datos del registro e intenta nuevamente.';
    }

    if (status == 429) {
      return 'Has realizado demasiados intentos. Espera un momento e intenta otra vez.';
    }

    if (status >= 500) {
      return 'No pudimos crear tu cuenta por un problema del servidor. Intenta nuevamente más tarde.';
    }

    return _fallbackMessage(
      body,
      'No fue posible crear la cuenta en este momento.',
    );
  }

  Map<String, dynamic> _tryParseJson(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String? _firstError(Map<String, dynamic> errors, String key) {
    final dynamic value = errors[key];
    if (value is List && value.isNotEmpty) {
      return value.first?.toString();
    }
    if (value is String) {
      return value;
    }
    return null;
  }

  String _fallbackMessage(Map<String, dynamic> body, String fallback) {
    final String? message = body['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return fallback;
  }
}
