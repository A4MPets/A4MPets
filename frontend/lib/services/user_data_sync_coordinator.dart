import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../models/hazard_report_record.dart';
import '../models/local_user_profile.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';
import 'backend_api_client.dart';
import 'local_database_manager.dart';
import 'sync_api_gateway.dart';
import 'sync_datetime_and_codes.dart';
import 'sync_media_resolver.dart';

class UserDataSyncCoordinator {
  UserDataSyncCoordinator({
    required LocalDatabaseManager databaseManager,
    http.Client? httpClient,
  }) : _databaseManager = databaseManager,
       _apiGateway = SyncApiGateway(
         apiClient: BackendApiClient(httpClient: httpClient ?? http.Client()),
       ) {
    _mediaResolver = SyncMediaResolver(postRequest: _postWithFallback);
  }

  final LocalDatabaseManager _databaseManager;
  final SyncApiGateway _apiGateway;
  late final SyncMediaResolver _mediaResolver;

  bool _syncInProgress = false;
  bool _syncQueued = false;
  Timer? _autoSyncTimer;

  void _log(String message) {
    debugPrint('[HazardSync] $message');
  }

  void startAutoSync({Duration interval = const Duration(seconds: 10)}) {
    if (_autoSyncTimer != null) {
      _log('auto-sync ya estaba activo.');
      return;
    }

    _log('auto-sync iniciado cada ${interval.inSeconds}s.');
    _autoSyncTimer = Timer.periodic(interval, (_) {
      _log('auto-sync tick');
      syncNow();
    });

    // Primer intento inmediato al iniciar la app.
    syncNow();
  }

  void stopAutoSync() {
    if (_autoSyncTimer == null) {
      return;
    }

    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _log('auto-sync detenido.');
  }

  void discardQueuedSyncWork() {
    _syncQueued = false;
    _log('cola de sincronizacion descartada manualmente.');
  }

  List<String> get _apiBaseUrls {
    return _apiGateway.baseUrls;
  }

  Future<String?> _currentAccessToken() async {
    try {
      final LocalUserProfile profile = await _databaseManager
          .getLocalUserProfile();
      return profile.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _hasAuthenticatedUser() async {
    try {
      final LocalUserProfile profile = await _databaseManager
          .getLocalUserProfile();
      return profile.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  Future<void> scheduleSync() async {
    _syncQueued = true;
    _log(
      'scheduleSync solicitado. queued=$_syncQueued inProgress=$_syncInProgress',
    );
    if (_syncInProgress) {
      _log(
        'scheduleSync en cola: se ejecutará al finalizar la sincronización actual.',
      );
      return;
    }
    await _drainSyncQueue();
  }

  Future<void> syncNow() async {
    _syncQueued = true;
    _log('syncNow solicitado. queued=$_syncQueued inProgress=$_syncInProgress');
    if (_syncInProgress) {
      _log(
        'syncNow en cola: se ejecutará al finalizar la sincronización actual.',
      );
      return;
    }
    await _drainSyncQueue();
  }

  Future<void> _drainSyncQueue() async {
    if (_syncInProgress) {
      return;
    }

    _syncInProgress = true;
    try {
      while (_syncQueued) {
        _syncQueued = false;
        _log(
          'sync cycle start: push local + pull remoto. URLs: ${_apiBaseUrls.join(', ')}',
        );
        try {
          await _pushLocalUserProfile();
          await _pushLocalPets();
          await _pushLocalRoutes();
          await _pushLocalHazards();
          await _pullRemoteUserProfile();
          await _pullRemotePets();
          await _pullRemoteRoutes();
          await _pullRemoteHazards();
          _log('sync cycle end: completado.');
        } catch (error) {
          _log('sync cycle error: $error');
          // Offline/falla de backend: mantener datos locales y reintentar luego.
        }
      }
    } finally {
      _syncInProgress = false;
      _log('sync drain finalizado. queued=$_syncQueued');
    }
  }

  Future<void> _pushLocalHazards() async {
    final List<HazardReportRecord> pending = await _databaseManager
        .getHazardReportsNeedingSync();

    _log('push: hazards pendientes=${pending.length}');

    if (pending.isEmpty) {
      _log('push: sin cambios locales por enviar.');
      return;
    }

    final String? token = await _currentAccessToken();
    final List<HazardReportRecord> transferableHazards = <HazardReportRecord>[];
    final List<Map<String, Object?>> hazardPayload = <Map<String, Object?>>[];

    for (final HazardReportRecord hazard in pending) {
      String? evidencePhotoUrl = hazard.evidencePhotoUrl;
      if (evidencePhotoUrl != null && evidencePhotoUrl.isNotEmpty) {
        final String? resolvedUrl = await _resolveImageUrlForSync(
          source: evidencePhotoUrl,
          bucket: 'hazards',
          bearerToken: token,
        );

        if (resolvedUrl == null) {
          _log(
            'push: hazard diferido por foto no sincronizable local_id=${hazard.localUuid}',
          );
          continue;
        }

        evidencePhotoUrl = resolvedUrl;
      }

      transferableHazards.add(hazard);
      hazardPayload.add(<String, Object?>{
        'local_id': hazard.localUuid,
        'remote_id': hazard.remoteId,
        'incident_latitude': hazard.incidentLatitude,
        'incident_longitude': hazard.incidentLongitude,
        'impact_radius_meters': hazard.impactRadiusMeters,
        'risk_level_code': _normalizeRiskLevelCode(hazard.riskLevelCode),
        'category_code': _normalizeCategoryCode(hazard.categoryCode),
        'narrative_description': hazard.narrativeDescription,
        'description': hazard.narrativeDescription,
        'estimated_duration_code': _normalizeDurationCode(
          hazard.estimatedDurationCode,
        ),
        'reported_at': _toBackendDateTime(hazard.reportedAt),
        'evidence_photo_url': evidencePhotoUrl,
        'reported_by_username': hazard.reportedByUsername,
        'comments': hazard.comments
            .map((HazardCommentRecord comment) => comment.toMap())
            .toList(growable: false),
        'last_modified_at': _toBackendDateTime(hazard.lastModifiedAt),
      });
    }

    if (hazardPayload.isEmpty) {
      _log('push: hazards diferidos hasta poder subir imagenes.');
      return;
    }

    final Map<String, Object?> payload = <String, Object?>{
      'hazards': hazardPayload,
    };

    _log(
      'push payload local_ids=${pending.map((HazardReportRecord h) => h.localUuid).join(', ')}',
    );

    final http.Response? response = await _postWithFallback(
      path: '/hazards/sync',
      body: payload,
      bearerToken: token,
    );

    if (response == null) {
      _log('push: backend inalcanzable en todas las URLs configuradas.');
      return;
    }

    _log('push: HTTP ${response.statusCode}, body=${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _log('push failed [${response.statusCode}]');
      return;
    }

    final Map<String, dynamic> responseMap =
        jsonDecode(response.body) as Map<String, dynamic>;

    final Map<String, dynamic> syncResults =
        (responseMap['sync_results'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final List<dynamic> details =
        (syncResults['details'] as List<dynamic>?) ?? <dynamic>[];

    final Set<String> failedLocalIds = details
        .map(
          (dynamic item) =>
              (item as Map<String, dynamic>)['local_id']?.toString(),
        )
        .whereType<String>()
        .toSet();

    for (final HazardReportRecord hazard in transferableHazards) {
      if (failedLocalIds.contains(hazard.localUuid)) {
        _log('push: hazard en conflicto/error, local_id=${hazard.localUuid}');
        continue;
      }

      await _databaseManager.markHazardAsSynced(
        localUuid: hazard.localUuid,
        remoteId: hazard.remoteId,
        syncStatus: 'synced',
        lastModifiedAt: hazard.lastModifiedAt,
      );
      _log('push: hazard marcado synced, local_id=${hazard.localUuid}');
    }
  }

  Future<void> _pullRemoteHazards() async {
    int page = 1;

    _log('pull: inicio.');

    while (true) {
      final http.Response? response = await _getWithFallback(
        path: '/hazards?include_archived=1&per_page=100&page=$page',
        bearerToken: await _currentAccessToken(),
      );

      if (response == null) {
        _log('pull: backend inalcanzable.');
        return;
      }

      _log('pull: page=$page HTTP ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _log('pull failed [${response.statusCode}], body=${response.body}');
        return;
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> data =
          (payload['data'] as List<dynamic>? ?? <dynamic>[]);

      _log('pull: page=$page recibió ${data.length} hazards remotos.');

      for (final dynamic item in data) {
        final Map<String, dynamic> hazard = item as Map<String, dynamic>;
        final String localUuid =
            hazard['local_id']?.toString() ?? 'remote-${hazard['id']}';
        final String? remoteId =
            hazard['remote_id']?.toString() ?? hazard['id']?.toString();
        final String syncStatus = hazard['status']?.toString() ?? 'synced';

        await _databaseManager.upsertHazardFromRemote(
          localUuid: localUuid,
          remoteId: remoteId,
          syncStatus: syncStatus,
          remoteLastModifiedAt: _parseBackendDateTime(
            hazard['last_modified_at'],
          ),
          incidentLatitude:
              (hazard['incident_latitude'] as num?)?.toDouble() ?? 0,
          incidentLongitude:
              (hazard['incident_longitude'] as num?)?.toDouble() ?? 0,
          impactRadiusMeters:
              (hazard['impact_radius_meters'] as num?)?.round() ?? 100,
          categoryCode: _normalizeCategoryCode(
            hazard['category_code']?.toString(),
          ),
          riskLevelCode: _normalizeRiskLevelCode(
            hazard['risk_level_code']?.toString(),
          ),
          narrativeDescription:
              hazard['narrative_description']?.toString() ??
              hazard['description']?.toString() ??
              '',
          estimatedDurationCode: _normalizeDurationCode(
            hazard['estimated_duration_code']?.toString(),
          ),
          reportedAt: _parseBackendDateTime(hazard['reported_at']),
          evidencePhotoUrl: hazard['evidence_photo_url']?.toString(),
          reportedByUsername:
              hazard['reported_by_username']?.toString() ?? 'Anónimo',
          commentsJson:
              hazard['comments_json']?.toString() ??
              jsonEncode(hazard['comments'] ?? <dynamic>[]),
        );

        _log(
          'pull: upsert local_uuid=$localUuid remote_id=$remoteId status=$syncStatus',
        );
      }

      final Map<String, dynamic> pagination =
          (payload['pagination'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final int currentPage =
          (pagination['current_page'] as num?)?.toInt() ?? page;
      final int lastPage =
          (pagination['last_page'] as num?)?.toInt() ?? currentPage;

      if (currentPage >= lastPage) {
        _log('pull: fin en page=$currentPage/$lastPage');
        break;
      }

      page += 1;
    }
  }

  Future<void> _pushLocalPets() async {
    if (!await _hasAuthenticatedUser()) {
      _log('push pets omitido: usuario guest.');
      return;
    }

    final List<PetRecord> pending = await _databaseManager.getPetsNeedingSync();
    _log('push pets: pendientes=${pending.length}');

    if (pending.isEmpty) {
      return;
    }

    final String? token = await _currentAccessToken();
    final List<PetRecord> transferablePets = <PetRecord>[];
    final List<Map<String, Object?>> petPayload = <Map<String, Object?>>[];

    for (final PetRecord pet in pending) {
      String? photoPath = pet.photoPath;
      if (photoPath != null && photoPath.isNotEmpty) {
        final String? resolvedUrl = await _resolveImageUrlForSync(
          source: photoPath,
          bucket: 'pets',
          bearerToken: token,
        );

        if (resolvedUrl == null) {
          _log(
            'push pets: mascota diferida por foto no sincronizable id=${pet.id}',
          );
          continue;
        }

        photoPath = resolvedUrl;
      }

      transferablePets.add(pet);
      petPayload.add(<String, Object?>{
        'local_id': 'pt_${pet.id}_${pet.createdAt.millisecondsSinceEpoch}',
        'remote_id': pet.remoteId,
        'name': pet.name,
        'photo_path': photoPath,
        'sync_status': pet.syncStatus,
        'last_modified_at': _toBackendDateTime(pet.lastModifiedAt),
      });
    }

    if (petPayload.isEmpty) {
      _log('push pets: todos diferidos hasta poder subir imagenes.');
      return;
    }

    final http.Response? response = await _postWithFallback(
      path: '/pets/sync',
      body: <String, Object?>{'pets': petPayload},
      bearerToken: token,
    );

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      _log('push pets: backend inalcanzable o error.');
      return;
    }

    final Map<String, dynamic> responseMap =
        jsonDecode(response.body) as Map<String, dynamic>;

    final Map<String, dynamic> syncResults =
        (responseMap['sync_results'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final List<dynamic> details =
        (syncResults['details'] as List<dynamic>?) ?? <dynamic>[];

    final Map<String, String> remoteIdMap = <String, String>{};
    for (final dynamic item in details) {
      final Map<String, dynamic> detail = item as Map<String, dynamic>;
      final String? locId = detail['local_id']?.toString();
      final String? remId = detail['remote_id']?.toString();
      if (locId != null && remId != null) {
        remoteIdMap[locId] = remId;
      }
    }

    for (final PetRecord pet in transferablePets) {
      final String pseudoLocalId =
          'pt_${pet.id}_${pet.createdAt.millisecondsSinceEpoch}';
      final String? newlyAssignedRemoteId = remoteIdMap[pseudoLocalId];
      final String? finalRemoteId = pet.remoteId ?? newlyAssignedRemoteId;

      await _databaseManager.markPetAsSynced(
        petId: pet.id,
        remoteId: finalRemoteId,
        syncStatus: pet.syncStatus,
        lastModifiedAt: pet.lastModifiedAt,
      );
    }
  }

  Future<void> _pushLocalRoutes() async {
    if (!await _hasAuthenticatedUser()) {
      _log('push routes omitido: usuario guest.');
      return;
    }

    final List<RouteRecord> pending = await _databaseManager
        .getRoutesNeedingSync();
    _log('push routes: pendientes=${pending.length}');

    if (pending.isEmpty) {
      return;
    }

    final http.Response? response = await _postWithFallback(
      path: '/routes/sync',
      body: <String, Object?>{
        'routes': pending
            .map(
              (RouteRecord route) => <String, Object?>{
                'local_id':
                    'rt_${route.id}_${route.createdAt.millisecondsSinceEpoch}',
                'remote_id': route.remoteId,
                'name': route.name,
                'points_json': jsonEncode(
                  route.points.map((RoutePoint p) => p.toMap()).toList(),
                ),
                'sync_status': route.syncStatus,
                'last_modified_at': _toBackendDateTime(route.lastModifiedAt),
              },
            )
            .toList(growable: false),
      },
      bearerToken: await _currentAccessToken(),
    );

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      _log('push routes: backend inalcanzable o error.');
      return;
    }

    final Map<String, dynamic> responseMap =
        jsonDecode(response.body) as Map<String, dynamic>;

    final Map<String, dynamic> syncResults =
        (responseMap['sync_results'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final List<dynamic> details =
        (syncResults['details'] as List<dynamic>?) ?? <dynamic>[];

    final Map<String, String> remoteIdMap = <String, String>{};
    for (final dynamic item in details) {
      final Map<String, dynamic> detail = item as Map<String, dynamic>;
      final String? locId = detail['local_id']?.toString();
      final String? remId = detail['remote_id']?.toString();
      if (locId != null && remId != null) {
        remoteIdMap[locId] = remId;
      }
    }

    for (final RouteRecord route in pending) {
      final String pseudoLocalId =
          'rt_${route.id}_${route.createdAt.millisecondsSinceEpoch}';
      final String? newlyAssignedRemoteId = remoteIdMap[pseudoLocalId];
      final String? finalRemoteId = route.remoteId ?? newlyAssignedRemoteId;

      await _databaseManager.markRouteAsSynced(
        routeId: route.id,
        remoteId: finalRemoteId,
        syncStatus: route.syncStatus,
        lastModifiedAt: route.lastModifiedAt,
      );
    }
  }

  Future<void> _pullRemotePets() async {
    if (!await _hasAuthenticatedUser()) {
      _log('pull pets omitido: usuario guest.');
      return;
    }

    int page = 1;

    while (true) {
      final http.Response? response = await _getWithFallback(
        path: '/pets?include_archived=1&per_page=100&page=$page',
        bearerToken: await _currentAccessToken(),
      );

      if (response == null) {
        _log('pull pets: backend inalcanzable.');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _log(
          'pull pets failed [${response.statusCode}], body=${response.body}',
        );
        return;
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> data =
          (payload['data'] as List<dynamic>? ?? <dynamic>[]);

      for (final dynamic item in data) {
        final Map<String, dynamic> pet = item as Map<String, dynamic>;
        await _databaseManager.upsertPetFromRemote(
          localIdString: pet['local_id']?.toString() ?? '',
          remoteId: pet['remote_id']?.toString() ?? pet['id']?.toString(),
          syncStatus: pet['sync_status']?.toString() ?? 'synced',
          remoteLastModifiedAt: _parseBackendDateTime(pet['last_modified_at']),
          name: pet['name']?.toString() ?? '',
          photoPath: pet['photo_path']?.toString(),
        );
      }

      final Map<String, dynamic> pagination =
          (payload['pagination'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final int currentPage =
          (pagination['current_page'] as num?)?.toInt() ?? page;
      final int lastPage =
          (pagination['last_page'] as num?)?.toInt() ?? currentPage;
      if (currentPage >= lastPage) {
        break;
      }
      page += 1;
    }
  }

  Future<void> _pullRemoteRoutes() async {
    if (!await _hasAuthenticatedUser()) {
      _log('pull routes omitido: usuario guest.');
      return;
    }

    int page = 1;

    while (true) {
      final http.Response? response = await _getWithFallback(
        path: '/routes?include_archived=1&per_page=100&page=$page',
        bearerToken: await _currentAccessToken(),
      );

      if (response == null) {
        _log('pull routes: backend inalcanzable.');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _log(
          'pull routes failed [${response.statusCode}], body=${response.body}',
        );
        return;
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> data =
          (payload['data'] as List<dynamic>? ?? <dynamic>[]);

      for (final dynamic item in data) {
        final Map<String, dynamic> route = item as Map<String, dynamic>;
        final String pointsJson = route['points_json']?.toString() ?? '[]';
        final List<dynamic> rawPoints = jsonDecode(pointsJson) as List<dynamic>;
        final List<RoutePoint> points = rawPoints
            .map(
              (dynamic point) =>
                  RoutePoint.fromMap((point as Map<String, dynamic>)),
            )
            .toList(growable: false);

        await _databaseManager.upsertRouteFromRemote(
          localIdString: route['local_id']?.toString() ?? '',
          remoteId: route['remote_id']?.toString() ?? route['id']?.toString(),
          syncStatus: route['sync_status']?.toString() ?? 'synced',
          remoteLastModifiedAt: _parseBackendDateTime(
            route['last_modified_at'],
          ),
          name: route['name']?.toString() ?? '',
          points: points,
        );
      }

      final Map<String, dynamic> pagination =
          (payload['pagination'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final int currentPage =
          (pagination['current_page'] as num?)?.toInt() ?? page;
      final int lastPage =
          (pagination['last_page'] as num?)?.toInt() ?? currentPage;
      if (currentPage >= lastPage) {
        break;
      }
      page += 1;
    }
  }

  Future<void> _pushLocalUserProfile() async {
    final LocalUserProfile profile = await _databaseManager
        .getLocalUserProfile();
    if (!profile.isAuthenticated) {
      return;
    }

    final String? token = await _currentAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    String? avatarPath = profile.avatarPath?.trim();
    if (avatarPath != null && avatarPath.isEmpty) {
      avatarPath = null;
    }

    final bool hasPendingLocalAvatar =
        avatarPath != null &&
        avatarPath.isNotEmpty &&
        !_isRemoteImageUrl(avatarPath) &&
        profile.lastSyncedAt == null;

    if (!hasPendingLocalAvatar && profile.lastSyncedAt != null) {
      return;
    }

    String? avatarUrlForBackend = avatarPath;
    if (hasPendingLocalAvatar) {
      final String localAvatarPath = avatarPath;
      final String? resolvedAvatarUrl = await _resolveImageUrlForSync(
        source: localAvatarPath,
        bucket: 'profiles',
        bearerToken: token,
      );

      if (resolvedAvatarUrl == null) {
        _log('push profile: diferido por foto no sincronizable.');
        return;
      }

      avatarUrlForBackend = resolvedAvatarUrl;
    }

    final http.Response? response = await _putWithFallback(
      path: '/auth/profile',
      body: <String, Object?>{
        'name': profile.username,
        'profile_photo_url': avatarUrlForBackend,
      },
      bearerToken: token,
    );

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      _log('push profile: backend inalcanzable o error.');
      return;
    }

    await _databaseManager.saveLocalUserProfile(
      LocalUserProfile(
        id: profile.id,
        username: profile.username,
        avatarPath: avatarPath,
        isAuthenticated: profile.isAuthenticated,
        backendUserId: profile.backendUserId,
        email: profile.email,
        accessToken: profile.accessToken,
        lastSyncedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _pullRemoteUserProfile() async {
    final LocalUserProfile current = await _databaseManager
        .getLocalUserProfile();
    if (!current.isAuthenticated) {
      return;
    }

    final String? token = await _currentAccessToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final http.Response? response = await _getWithFallback(
      path: '/auth/me',
      bearerToken: token,
    );

    if (response == null ||
        response.statusCode < 200 ||
        response.statusCode >= 300) {
      _log('pull profile: backend inalcanzable o error.');
      return;
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> user =
        (payload['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final String? remoteAvatar = user['profile_photo_url']?.toString();
    final String? resolvedAvatar = _preferProfileAvatarForPull(
      currentAvatar: current.avatarPath,
      remoteAvatar: remoteAvatar,
    );

    final bool pendingLocalAvatar =
        current.lastSyncedAt == null &&
        current.avatarPath != null &&
        current.avatarPath!.isNotEmpty &&
        !_isRemoteImageUrl(current.avatarPath!);

    await _databaseManager.saveLocalUserProfile(
      LocalUserProfile(
        id: current.id,
        username: user['name']?.toString() ?? current.username,
        avatarPath: resolvedAvatar,
        isAuthenticated: true,
        backendUserId: (user['id'] as num?)?.toInt() ?? current.backendUserId,
        email: user['email']?.toString() ?? current.email,
        accessToken: current.accessToken,
        lastSyncedAt: pendingLocalAvatar ? null : DateTime.now(),
      ),
    );
  }

  DateTime _parseBackendDateTime(Object? value) {
    return SyncDateTimeAndCodes.parseBackendDateTime(value);
  }

  String _toBackendDateTime(DateTime dateTime) {
    return SyncDateTimeAndCodes.toBackendDateTime(dateTime);
  }

  String _normalizeRiskLevelCode(String? value) {
    return SyncDateTimeAndCodes.normalizeRiskLevelCode(value);
  }

  String _normalizeCategoryCode(String? value) {
    return SyncDateTimeAndCodes.normalizeCategoryCode(value);
  }

  String _normalizeDurationCode(String? value) {
    return SyncDateTimeAndCodes.normalizeDurationCode(value);
  }

  Future<http.Response?> _postWithFallback({
    required String path,
    required Object body,
    String? bearerToken,
  }) async {
    return _apiGateway.post(path: path, body: body, bearerToken: bearerToken);
  }

  Future<http.Response?> _getWithFallback({
    required String path,
    String? bearerToken,
  }) async {
    return _apiGateway.get(path: path, bearerToken: bearerToken);
  }

  Future<http.Response?> _putWithFallback({
    required String path,
    required Object body,
    String? bearerToken,
  }) async {
    return _apiGateway.put(path: path, body: body, bearerToken: bearerToken);
  }

  bool _isRemoteImageUrl(String source) {
    return _mediaResolver.isRemoteImageUrl(source);
  }

  String? _preferProfileAvatarForPull({
    required String? currentAvatar,
    required String? remoteAvatar,
  }) {
    return _mediaResolver.preferProfileAvatarForPull(
      currentAvatar: currentAvatar,
      remoteAvatar: remoteAvatar,
    );
  }

  Future<String?> _resolveImageUrlForSync({
    required String source,
    required String bucket,
    String? bearerToken,
  }) async {
    return _mediaResolver.resolveImageUrlForSync(
      source: source,
      bucket: bucket,
      bearerToken: bearerToken,
    );
  }
}
