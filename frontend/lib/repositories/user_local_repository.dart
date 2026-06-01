import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/local_user_profile.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../models/report_comment_record.dart';
import '../models/route_record.dart';
import '../services/backend_api_client.dart';
import '../services/guest_data_store.dart';
import '../services/media_source_encoder.dart';
import '../services/session_store.dart';

class UserLocalRepository {
  final SessionStore sessionStore;
  final GuestDataStore guestDataStore;
  final BackendApiClient _apiClient = BackendApiClient();

  UserLocalRepository({
    required this.sessionStore,
    required this.guestDataStore,
  });

  Future<LocalUserProfile> getUserProfile() async {
    final LocalUserProfile cached = await sessionStore.getLocalUserProfile();
    final String? token = cached.accessToken;
    if (!cached.isAuthenticated || token == null || token.isEmpty) {
      return cached;
    }

    try {
      final http.Response response = await _send(
        () => _apiClient.getWithFallback('/auth/me', bearerToken: token),
      );
      final Map<String, dynamic> user = _recordData(response);
      final LocalUserProfile refreshed = _profileFromUserData(
        user,
        accessToken: token,
      );
      await sessionStore.saveLocalUserProfile(refreshed);
      return refreshed;
    } catch (_) {
      return cached;
    }
  }

  Future<LocalUserProfile> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final List<PetRecord> guestPets = await guestDataStore.getPets();
    final List<RouteRecord> guestRoutes = await guestDataStore.getRoutes();

    final http.Response response = await _send(
      () => _apiClient.postWithFallback(
        '/auth/register',
        body: <String, Object?>{
          'name': username,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      ),
      errorMapper: _mapRegisterError,
    );

    final LocalUserProfile profile = _profileFromAuthResponse(response);
    await sessionStore.saveLocalUserProfile(profile);
    await _migrateGuestDataToAccount(
      accessToken: profile.accessToken,
      pets: guestPets,
      routes: guestRoutes,
    );
    await guestDataStore.clear();
    return profile;
  }

  Future<LocalUserProfile> login({
    required String login,
    required String password,
  }) async {
    final http.Response response = await _send(
      () => _apiClient.postWithFallback(
        '/auth/login',
        body: <String, Object?>{'login': login, 'password': password},
      ),
      errorMapper: _mapLoginError,
    );

    final LocalUserProfile profile = _profileFromAuthResponse(response);
    await guestDataStore.clear();
    await sessionStore.clearUserSessionData();
    await sessionStore.saveLocalUserProfile(profile);
    return profile;
  }

  Future<void> logout() async {
    final LocalUserProfile profile = await sessionStore.getLocalUserProfile();
    final String? token = profile.accessToken;

    if (token != null && token.isNotEmpty) {
      await _apiClient.postWithFallback(
        '/auth/logout',
        body: <String, Object?>{},
        bearerToken: token,
      );
    }

    await guestDataStore.clear();
    await sessionStore.clearUserSessionData();
    await sessionStore.saveLocalUserProfile(LocalUserProfile.guest());
  }

  Future<void> updateProfileAvatar({required String? avatarPath}) async {
    final LocalUserProfile current = await sessionStore.getLocalUserProfile();
    final String token = await _requireToken();
    final String? remoteAvatar = await _uploadImageIfNeeded(
      avatarPath,
      bucket: 'profiles',
      bearerToken: token,
    );

    final http.Response response = await _send(
      () => _apiClient.putWithFallback(
        '/auth/profile',
        body: <String, Object?>{
          'name': current.username,
          'profile_photo_url': remoteAvatar,
        },
        bearerToken: token,
      ),
    );

    final Map<String, dynamic> payload = _json(response);
    final Map<String, dynamic> data =
        (payload['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> user =
        (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    await sessionStore.saveLocalUserProfile(
      current.copyWith(avatarPath: user['profile_photo_url']?.toString()),
    );
  }

  Future<List<PetRecord>> getPets() async {
    if (!await _isAuthenticated()) {
      return guestDataStore.getPets();
    }
    final String token = await _requireToken();
    return _getList(
      '/pets?include_archived=1&per_page=100',
      PetRecord.fromMap,
      bearerToken: token,
    );
  }

  Future<List<PetRecord>> getMyPets() async {
    if (!await _isAuthenticated()) {
      return guestDataStore.getPets();
    }
    final String token = await _requireToken();
    final List<PetRecord> pets = await _getList(
      '/pets?scope=mine&per_page=100',
      PetRecord.fromMap,
      bearerToken: token,
    );
    return pets
        .where((PetRecord pet) => !pet.isOwnerless)
        .toList(growable: false);
  }

  Future<int> getPetsCount() async => (await getPets()).length;

  Future<int> getMyPetsCount() async => (await getMyPets()).length;

  Future<int> addPet({
    String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
    bool isOwnerless = false,
  }) async {
    if (!await _isAuthenticated()) {
      return guestDataStore.addPet(
        name: name,
        photoPath: photoPath,
        adoptionDate: adoptionDate,
        birthDate: birthDate,
        isOwnerless: isOwnerless,
      );
    }
    final String token = await _requireToken();
    final String? remotePhoto = await _uploadImageIfNeeded(
      photoPath,
      bucket: 'pets',
      bearerToken: token,
    );
    final http.Response response = await _send(
      () => _apiClient.postWithFallback(
        '/pets',
        body: <String, Object?>{
          'name': name,
          'photo_path': remotePhoto,
          'adoption_date': _date(adoptionDate),
          'birth_date': _date(birthDate),
          'is_ownerless': isOwnerless,
        },
        bearerToken: token,
      ),
    );
    return (_recordData(response)['id'] as num).toInt();
  }

  Future<void> updatePet({
    required int petId,
    required String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
  }) async {
    if (!await _isAuthenticated()) {
      await guestDataStore.updatePet(
        petId: petId,
        name: name,
        photoPath: photoPath,
        adoptionDate: adoptionDate,
        birthDate: birthDate,
      );
      return;
    }
    final String token = await _requireToken();
    final String? remotePhoto = await _uploadImageIfNeeded(
      photoPath,
      bucket: 'pets',
      bearerToken: token,
    );
    await _send(
      () => _apiClient.putWithFallback(
        '/pets/$petId',
        body: <String, Object?>{
          'name': name,
          'photo_path': remotePhoto,
          'adoption_date': _date(adoptionDate),
          'birth_date': _date(birthDate),
        },
        bearerToken: token,
      ),
    );
  }

  Future<void> deletePet({required int petId}) async {
    if (!await _isAuthenticated()) {
      await guestDataStore.deletePet(petId: petId);
      return;
    }
    await _delete('/pets/$petId');
  }

  Future<void> incrementPetWalks({required Iterable<int> petIds}) async {
    if (!await _isAuthenticated()) {
      await guestDataStore.incrementPetWalks(petIds: petIds);
      return;
    }
    final List<PetRecord> pets = await getPets();
    final Map<int, PetRecord> byId = <int, PetRecord>{
      for (final PetRecord pet in pets) pet.id: pet,
    };

    for (final int petId in petIds.toSet()) {
      final PetRecord? pet = byId[petId];
      if (pet == null) {
        continue;
      }
      await _updatePetWalks(pet, pet.totalWalks + 1);
    }
  }

  Future<void> markPetFound({required int petId}) async {
    if (!await _isAuthenticated()) {
      await guestDataStore.markPetFound(petId: petId);
      return;
    }
    final String token = await _requireToken();
    await _send(
      () => _apiClient.postWithFallback(
        '/pets/$petId/mark-found',
        body: <String, Object?>{},
        bearerToken: token,
      ),
    );
  }

  Future<List<RouteRecord>> getRoutes() async {
    if (!await _isAuthenticated()) {
      return guestDataStore.getRoutes();
    }
    final String token = await _requireToken();
    return _getList(
      '/routes?include_archived=1&per_page=100',
      RouteRecord.fromMap,
      bearerToken: token,
    );
  }

  Future<int> getRoutesCount() async => (await getRoutes()).length;

  Future<int> addRoute({
    required String name,
    required List<RoutePoint> points,
  }) async {
    if (!await _isAuthenticated()) {
      return guestDataStore.addRoute(name: name, points: points);
    }
    final String token = await _requireToken();
    final http.Response response = await _send(
      () => _apiClient.postWithFallback(
        '/routes',
        body: <String, Object?>{
          'name': name,
          'points_json': jsonEncode(points.map((p) => p.toMap()).toList()),
        },
        bearerToken: token,
      ),
    );
    return (_recordData(response)['id'] as num).toInt();
  }

  Future<void> deleteRoute({required int routeId}) async {
    if (!await _isAuthenticated()) {
      await guestDataStore.deleteRoute(routeId: routeId);
      return;
    }
    await _delete('/routes/$routeId');
  }

  Future<void> updateRoute({
    required int routeId,
    required String name,
    required List<RoutePoint> points,
  }) async {
    if (!await _isAuthenticated()) {
      await guestDataStore.updateRoute(
        routeId: routeId,
        name: name,
        points: points,
      );
      return;
    }
    final String token = await _requireToken();
    await _send(
      () => _apiClient.putWithFallback(
        '/routes/$routeId',
        body: <String, Object?>{
          'name': name,
          'points_json': jsonEncode(points.map((p) => p.toMap()).toList()),
        },
        bearerToken: token,
      ),
    );
  }

  Future<List<HazardReportRecord>> getHazardReports() async {
    return _getList(
      '/hazards?include_archived=1&per_page=100',
      HazardReportRecord.fromMap,
    );
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
    final LocalUserProfile profile = await sessionStore.getLocalUserProfile();
    final String? token =
        profile.isAuthenticated &&
            profile.accessToken != null &&
            profile.accessToken!.isNotEmpty
        ? profile.accessToken
        : null;
    final String? remotePhoto = await _uploadImageIfNeeded(
      evidencePhotoUrl,
      bucket: 'hazards',
      bearerToken: token,
    );
    await _send(
      () => _apiClient.postWithFallback(
        '/hazards',
        body: <String, Object?>{
          'incident_latitude': incidentLatitude,
          'incident_longitude': incidentLongitude,
          'impact_radius_meters': impactRadiusMeters,
          'category_code': categoryCode,
          'narrative_description': narrativeDescription,
          'reported_at': _dateTime(reportedAt),
          'estimated_duration_code': estimatedDurationCode,
          'risk_level_code': riskLevelCode,
          'evidence_photo_url': remotePhoto,
          'reported_by_username': reportedByUsername,
        },
        bearerToken: token,
      ),
    );
  }

  Future<void> addCommentToHazard({
    required int hazardId,
    required HazardCommentRecord comment,
  }) async {
    final LocalUserProfile profile = await sessionStore.getLocalUserProfile();
    final String? token =
        profile.isAuthenticated &&
            profile.accessToken != null &&
            profile.accessToken!.isNotEmpty
        ? profile.accessToken
        : null;
    await _postComment(
      '/hazards/$hazardId/comments',
      comment,
      bearerToken: token,
      requireToken: false,
    );
  }

  Future<List<HazardCommentRecord>> getHazardComments(int hazardId) {
    return _getList(
      '/hazards/$hazardId/comments',
      (Map<String, Object?> map) =>
          HazardCommentRecord.fromMap(Map<String, dynamic>.from(map)),
    );
  }

  Future<void> deleteHazardReport({
    required int hazardId,
    String? remoteId,
  }) async {
    await _delete('/hazards/$hazardId');
  }

  Future<List<LostPetReportRecord>> getLostPetReports() async {
    return _getList(
      '/lost-pet-reports?include_archived=1&per_page=100',
      LostPetReportRecord.fromMap,
    );
  }

  Future<void> addLostPetReport({
    required int petId,
    required String petLocalUuid,
    required double lastSeenLatitude,
    required double lastSeenLongitude,
    required String details,
    required DateTime disappearanceDate,
    String? photoUrl,
    required String phone,
  }) async {
    final String token = await _requireToken();
    await _send(
      () => _apiClient.postWithFallback(
        '/lost-pet-reports',
        body: <String, Object?>{
          'pet_id': petId,
          'last_seen_latitude': lastSeenLatitude,
          'last_seen_longitude': lastSeenLongitude,
          'details': details,
          'disappearance_date': _date(disappearanceDate),
          'photo_url': null,
          'phone': phone,
        },
        bearerToken: token,
      ),
    );
  }

  Future<void> deleteLostPetReport({
    required int reportId,
    String? remoteId,
  }) async {
    await _delete('/lost-pet-reports/$reportId');
  }

  Future<void> addCommentToLostPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _postComment('/lost-pet-reports/$reportId/comments', comment);
  }

  Future<List<FoundPetReportRecord>> getFoundPetReports() async {
    return _getList(
      '/found-pet-reports?include_archived=1&per_page=100',
      FoundPetReportRecord.fromMap,
    );
  }

  Future<void> addFoundPetReport({
    int? petId,
    String? petLocalUuid,
    int? matchedLostPetReportId,
    required double latitude,
    required double longitude,
    required String details,
    required DateTime foundDate,
    String? photoUrl,
    String? phone,
  }) async {
    final String token = await _requireToken();
    final String? remotePhoto = await _uploadImageIfNeeded(
      photoUrl,
      bucket: 'found_pets',
      bearerToken: token,
    );
    await _send(
      () => _apiClient.postWithFallback(
        '/found-pet-reports',
        body: <String, Object?>{
          'pet_id': petId,
          'matched_lost_pet_report_id': matchedLostPetReportId,
          'latitude': latitude,
          'longitude': longitude,
          'details': details,
          'found_date': _date(foundDate),
          'photo_url': remotePhoto,
          'phone': phone,
        },
        bearerToken: token,
      ),
    );
  }

  Future<void> deleteFoundPetReport({
    required int reportId,
    String? remoteId,
  }) async {
    await _delete('/found-pet-reports/$reportId');
  }

  Future<void> addCommentToFoundPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _postComment('/found-pet-reports/$reportId/comments', comment);
  }

  Future<List<GenericReportRecord>> getGenericReports() async {
    return _getList(
      '/generic-reports?include_archived=1&per_page=100',
      GenericReportRecord.fromMap,
    );
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
    final LocalUserProfile profile = await sessionStore.getLocalUserProfile();
    final String? token =
        profile.isAuthenticated &&
            profile.accessToken != null &&
            profile.accessToken!.isNotEmpty
        ? profile.accessToken
        : null;
    final String? remotePhoto = await _uploadImageIfNeeded(
      photoUrl,
      bucket: 'generic_reports',
      bearerToken: token,
    );
    await _send(
      () => _apiClient.postWithFallback(
        '/generic-reports',
        body: <String, Object?>{
          'latitude': latitude,
          'longitude': longitude,
          'description': description,
          'reported_date': _date(reportedDate),
          'risk_level_code': riskLevelCode,
          'impact_radius_meters': impactRadiusMeters,
          'photo_url': remotePhoto,
        },
        bearerToken: token,
      ),
    );
  }

  Future<void> deleteGenericReport({
    required int reportId,
    String? remoteId,
  }) async {
    await _delete('/generic-reports/$reportId');
  }

  Future<void> addCommentToGenericReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _postComment('/generic-reports/$reportId/comments', comment);
  }

  Future<void> _updatePetWalks(PetRecord pet, int totalWalks) async {
    final String token = await _requireToken();
    await _send(
      () => _apiClient.putWithFallback(
        '/pets/${pet.id}',
        body: <String, Object?>{
          'name': pet.name,
          'photo_path': pet.photoPath,
          'total_walks': totalWalks,
          'registered_at': _dateTime(pet.registeredAt),
          'adoption_date': _date(pet.adoptionDate),
          'birth_date': _date(pet.birthDate),
          'status': pet.status,
          'is_ownerless': pet.isOwnerless,
        },
        bearerToken: token,
      ),
    );
  }

  Future<void> _postComment(
    String path,
    ReportCommentRecord comment, {
    String? bearerToken,
    bool requireToken = true,
  }) async {
    final String? token =
        bearerToken ?? (requireToken ? await _requireToken() : null);
    await _send(
      () => _apiClient.postWithFallback(
        path,
        body: <String, Object?>{
          'comment_text': comment.commentText,
          'is_anonymous': comment.isAnonymous,
          'author_name': comment.authorUsername,
          'author_avatar_url': comment.authorAvatarUrl,
        },
        bearerToken: token,
      ),
    );
  }

  Future<void> _delete(String path) async {
    final String token = await _requireToken();
    await _send(() => _apiClient.deleteWithFallback(path, bearerToken: token));
  }

  Future<bool> _isAuthenticated() async {
    final LocalUserProfile profile = await sessionStore.getLocalUserProfile();
    final String? token = profile.accessToken;
    return profile.isAuthenticated && token != null && token.isNotEmpty;
  }

  Future<void> _migrateGuestDataToAccount({
    required String? accessToken,
    required List<PetRecord> pets,
    required List<RouteRecord> routes,
  }) async {
    final String? token = accessToken;
    if (token == null || token.isEmpty || (pets.isEmpty && routes.isEmpty)) {
      return;
    }

    for (final PetRecord pet in pets.where(
      (PetRecord item) => !item.isOwnerless,
    )) {
      final String? remotePhoto = await _uploadImageIfNeeded(
        pet.photoPath,
        bucket: 'pets',
        bearerToken: token,
      );
      await _send(
        () => _apiClient.postWithFallback(
          '/pets',
          body: <String, Object?>{
            'name': pet.name,
            'photo_path': remotePhoto,
            'total_walks': pet.totalWalks,
            'registered_at': _dateTime(pet.registeredAt),
            'adoption_date': _date(pet.adoptionDate),
            'birth_date': _date(pet.birthDate),
            'status': pet.status,
            'is_ownerless': false,
          },
          bearerToken: token,
        ),
      );
    }

    for (final RouteRecord route in routes) {
      await _send(
        () => _apiClient.postWithFallback(
          '/routes',
          body: <String, Object?>{
            'name': route.name,
            'points_json': jsonEncode(
              route.points.map((RoutePoint p) => p.toMap()).toList(),
            ),
          },
          bearerToken: token,
        ),
      );
    }
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, Object?> map) parser, {
    String? bearerToken,
  }) async {
    final http.Response response = await _send(
      () => _apiClient.getWithFallback(path, bearerToken: bearerToken),
    );
    final Map<String, dynamic> payload = _json(response);
    final List<dynamic> data =
        (payload['data'] as List<dynamic>?) ?? <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> item) => parser(_normalizeMap(item)))
        .toList(growable: false);
  }

  Future<String> _requireToken() async {
    final LocalUserProfile profile = await sessionStore.getLocalUserProfile();
    final String? token = profile.accessToken;
    if (!profile.isAuthenticated || token == null || token.isEmpty) {
      throw Exception('Debes iniciar sesion para realizar esta accion.');
    }
    return token;
  }

  Future<String?> _uploadImageIfNeeded(
    String? source, {
    required String bucket,
    required String? bearerToken,
  }) async {
    final String? value = source?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final String? imageData = await encodeImageSourceToDataUri(value);
    if (imageData == null || imageData.isEmpty) {
      return value;
    }

    final http.Response response = await _send(
      () => _apiClient.postWithFallback(
        '/media/upload',
        body: <String, Object?>{'bucket': bucket, 'image_data': imageData},
        bearerToken: bearerToken,
      ),
    );

    final Map<String, dynamic> data = _recordData(response);
    return data['url']?.toString();
  }

  Future<http.Response> _send(
    Future<http.Response?> Function() request, {
    String Function(http.Response response)? errorMapper,
  }) async {
    final http.Response? response = await request();
    if (response == null) {
      throw Exception(
        'No pudimos conectarnos al servidor. Revisa tu conexion e intenta nuevamente.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(errorMapper?.call(response) ?? _backendError(response));
    }
    return response;
  }

  LocalUserProfile _profileFromAuthResponse(http.Response response) {
    final Map<String, dynamic> payload = _json(response);
    final Map<String, dynamic> data =
        (payload['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> user =
        (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return _profileFromUserData(
      user,
      accessToken: data['access_token'] as String?,
    );
  }

  LocalUserProfile _profileFromUserData(
    Map<String, dynamic> user, {
    required String? accessToken,
  }) {
    return LocalUserProfile(
      id: (user['id'] as num).toInt(),
      username: user['name'] as String,
      avatarPath: user['profile_photo_url']?.toString(),
      isAuthenticated: true,
      backendUserId: (user['id'] as num).toInt(),
      email: user['email'] as String?,
      accessToken: accessToken,
      lastSyncedAt: null,
    );
  }

  Map<String, dynamic> _recordData(http.Response response) {
    final Map<String, dynamic> payload = _json(response);
    return (payload['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Map<String, dynamic> _json(http.Response response) {
    return _tryParseJson(response.body);
  }

  Map<String, Object?> _normalizeMap(Map<String, dynamic> input) {
    final Map<String, Object?> result = <String, Object?>{};
    input.forEach((String key, Object? value) {
      if (value is bool) {
        result[key] = value ? 1 : 0;
      } else if (_looksLikeDateKey(key) && value is String) {
        result[key] = DateTime.tryParse(value)?.millisecondsSinceEpoch;
      } else if (key == 'comments' &&
          value is List &&
          !input.containsKey('comments_json')) {
        result['comments_json'] = jsonEncode(value);
      } else {
        result[key] = value;
      }
    });
    result.putIfAbsent('sync_status', () => 'synced');
    result.putIfAbsent('needs_sync', () => 0);
    result.putIfAbsent('last_modified_at', () => result['updated_at']);
    return result;
  }

  bool _looksLikeDateKey(String key) {
    return key.endsWith('_at') || key.endsWith('_date');
  }

  String? _date(DateTime? value) => value?.toIso8601String().split('T').first;

  String _dateTime(DateTime value) => value.toIso8601String();

  String _mapLoginError(http.Response response) {
    final int status = response.statusCode;
    final Map<String, dynamic> body = _tryParseJson(response.body);
    final Map<String, dynamic> errors =
        (body['errors'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    if (status == 401) {
      return 'Tu usuario/correo o contrasena no son correctos.';
    }

    if (status == 422) {
      final String? loginError = _firstError(errors, 'login');
      final String? passwordError = _firstError(errors, 'password');

      if (loginError != null && loginError.isNotEmpty) {
        return 'Tu usuario/correo o contrasena no son correctos.';
      }

      if (passwordError != null &&
          passwordError.toLowerCase().contains('required')) {
        return 'Debes ingresar tu contrasena para iniciar sesion.';
      }

      return 'Revisa los datos ingresados e intenta nuevamente.';
    }

    if (status == 429) {
      return 'Has intentado demasiadas veces. Espera un momento y vuelve a intentarlo.';
    }

    if (status >= 500) {
      return 'En este momento el servidor no esta disponible. Intenta nuevamente en unos minutos.';
    }

    return _fallbackMessage(
      body,
      'No fue posible iniciar sesion en este momento.',
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
        return 'El correo electronico no es valido.';
      }
      if (nameError != null && nameError.toLowerCase().contains('required')) {
        return 'Escribe un nombre de usuario para crear tu cuenta.';
      }
      if (passwordError != null &&
          passwordError.toLowerCase().contains('confirmed')) {
        return 'Las contrasenas no coinciden. Revisa ambos campos.';
      }
      if (passwordError != null &&
          passwordError.toLowerCase().contains('min')) {
        return 'La contrasena debe tener al menos 8 caracteres.';
      }
      return 'Revisa los datos del registro e intenta nuevamente.';
    }

    if (status == 429) {
      return 'Has realizado demasiados intentos. Espera un momento e intenta otra vez.';
    }
    if (status >= 500) {
      return 'No pudimos crear tu cuenta por un problema del servidor. Intenta nuevamente mas tarde.';
    }

    return _fallbackMessage(
      body,
      'No fue posible crear la cuenta en este momento.',
    );
  }

  String _backendError(http.Response response) {
    final Map<String, dynamic> body = _tryParseJson(response.body);
    return _fallbackMessage(
      body,
      'El servidor no pudo completar la operacion.',
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
