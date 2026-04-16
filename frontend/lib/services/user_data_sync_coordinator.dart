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

class UserDataSyncCoordinator {
  UserDataSyncCoordinator({
    required LocalDatabaseManager databaseManager,
    http.Client? httpClient,
  })  : _databaseManager = databaseManager,
        _apiClient = BackendApiClient(httpClient: httpClient ?? http.Client());

  final LocalDatabaseManager _databaseManager;
  final BackendApiClient _apiClient;

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

  List<String> get _apiBaseUrls {
    return _apiClient.baseUrls;
  }

  Future<String?> _currentAccessToken() async {
    try {
      final LocalUserProfile profile = await _databaseManager.getLocalUserProfile();
      return profile.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> scheduleSync() async {
    _syncQueued = true;
    _log('scheduleSync solicitado. queued=$_syncQueued inProgress=$_syncInProgress');
    if (_syncInProgress) {
      _log('scheduleSync en cola: se ejecutará al finalizar la sincronización actual.');
      return;
    }
    await _drainSyncQueue();
  }

  Future<void> syncNow() async {
    _syncQueued = true;
    _log('syncNow solicitado. queued=$_syncQueued inProgress=$_syncInProgress');
    if (_syncInProgress) {
      _log('syncNow en cola: se ejecutará al finalizar la sincronización actual.');
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
        _log('sync cycle start: push local + pull remoto. URLs: ${_apiBaseUrls.join(', ')}');
        try {
          await _pushLocalPets();
          await _pushLocalRoutes();
          await _pushLocalHazards();
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
    final List<HazardReportRecord> pending =
        await _databaseManager.getHazardReportsNeedingSync();

    _log('push: hazards pendientes=${pending.length}');

    if (pending.isEmpty) {
      _log('push: sin cambios locales por enviar.');
      return;
    }

    final Map<String, Object?> payload = <String, Object?>{
      'hazards': pending
          .map((HazardReportRecord hazard) => <String, Object?>{
                'local_id': hazard.localUuid,
                'remote_id': hazard.remoteId,
                'incident_latitude': hazard.incidentLatitude,
                'incident_longitude': hazard.incidentLongitude,
                'impact_radius_meters': hazard.impactRadiusMeters,
                'risk_level_code': _normalizeRiskLevelCode(hazard.riskLevelCode),
            'category_code': _normalizeCategoryCode(hazard.categoryCode),
            'narrative_description': hazard.narrativeDescription,
            'description': hazard.narrativeDescription,
            'estimated_duration_code':
              _normalizeDurationCode(hazard.estimatedDurationCode),
            'reported_at': _toBackendDateTime(hazard.reportedAt),
            'evidence_photo_url': hazard.evidencePhotoUrl,
            'reported_by_username': hazard.reportedByUsername,
                'last_modified_at': _toBackendDateTime(hazard.lastModifiedAt),
              })
          .toList(growable: false),
    };

    _log('push payload local_ids=${pending.map((HazardReportRecord h) => h.localUuid).join(', ')}');

    final http.Response? response = await _postWithFallback(
      path: '/hazards/sync',
      body: payload,
      bearerToken: await _currentAccessToken(),
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
        .map((dynamic item) => (item as Map<String, dynamic>)['local_id']?.toString())
        .whereType<String>()
        .toSet();

    for (final HazardReportRecord hazard in pending) {
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
      final List<dynamic> data = (payload['data'] as List<dynamic>? ?? <dynamic>[]);

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
          remoteLastModifiedAt: _parseBackendDateTime(hazard['last_modified_at']),
          incidentLatitude:
              (hazard['incident_latitude'] as num?)?.toDouble() ?? 0,
          incidentLongitude:
              (hazard['incident_longitude'] as num?)?.toDouble() ?? 0,
          impactRadiusMeters:
              (hazard['impact_radius_meters'] as num?)?.round() ?? 100,
          categoryCode:
            _normalizeCategoryCode(hazard['category_code']?.toString()),
          riskLevelCode:
            _normalizeRiskLevelCode(hazard['risk_level_code']?.toString()),
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
        );

        _log('pull: upsert local_uuid=$localUuid remote_id=$remoteId status=$syncStatus');
      }

      final Map<String, dynamic> pagination =
          (payload['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final int currentPage = (pagination['current_page'] as num?)?.toInt() ?? page;
      final int lastPage = (pagination['last_page'] as num?)?.toInt() ?? currentPage;

      if (currentPage >= lastPage) {
        _log('pull: fin en page=$currentPage/$lastPage');
        break;
      }

      page += 1;
    }
  }

  Future<void> _pushLocalPets() async {
    final List<PetRecord> pending = await _databaseManager.getPetsNeedingSync();
    _log('push pets: pendientes=${pending.length}');

    if (pending.isEmpty) {
      return;
    }

    final http.Response? response = await _postWithFallback(
      path: '/pets/sync',
      body: <String, Object?>{
        'pets': pending
            .map((PetRecord pet) => <String, Object?>{
                  'local_id': pet.id.toString(),
                  'remote_id': pet.remoteId,
                  'name': pet.name,
                  'photo_path': pet.photoPath,
                  'sync_status': pet.syncStatus,
                  'last_modified_at': _toBackendDateTime(pet.lastModifiedAt),
                })
            .toList(growable: false),
      },
      bearerToken: await _currentAccessToken(),
    );

    if (response == null || response.statusCode < 200 || response.statusCode >= 300) {
      _log('push pets: backend inalcanzable o error.');
      return;
    }

    for (final PetRecord pet in pending) {
      await _databaseManager.markPetAsSynced(
        petId: pet.id,
        remoteId: pet.remoteId,
        syncStatus: pet.syncStatus,
        lastModifiedAt: pet.lastModifiedAt,
      );
    }
  }

  Future<void> _pushLocalRoutes() async {
    final List<RouteRecord> pending = await _databaseManager.getRoutesNeedingSync();
    _log('push routes: pendientes=${pending.length}');

    if (pending.isEmpty) {
      return;
    }

    final http.Response? response = await _postWithFallback(
      path: '/routes/sync',
      body: <String, Object?>{
        'routes': pending
            .map((RouteRecord route) => <String, Object?>{
                  'local_id': route.id.toString(),
                  'remote_id': route.remoteId,
                  'name': route.name,
                  'points_json': jsonEncode(route.points.map((RoutePoint p) => p.toMap()).toList()),
                  'sync_status': route.syncStatus,
                  'last_modified_at': _toBackendDateTime(route.lastModifiedAt),
                })
            .toList(growable: false),
      },
      bearerToken: await _currentAccessToken(),
    );

    if (response == null || response.statusCode < 200 || response.statusCode >= 300) {
      _log('push routes: backend inalcanzable o error.');
      return;
    }

    for (final RouteRecord route in pending) {
      await _databaseManager.markRouteAsSynced(
        routeId: route.id,
        remoteId: route.remoteId,
        syncStatus: route.syncStatus,
        lastModifiedAt: route.lastModifiedAt,
      );
    }
  }

  Future<void> _pullRemotePets() async {
    int page = 1;

    while (true) {
      final http.Response? response = await _getWithFallback(
        path: '/pets?per_page=100&page=$page',
        bearerToken: await _currentAccessToken(),
      );

      if (response == null) {
        _log('pull pets: backend inalcanzable.');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _log('pull pets failed [${response.statusCode}], body=${response.body}');
        return;
      }

      final Map<String, dynamic> payload = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> data = (payload['data'] as List<dynamic>? ?? <dynamic>[]);

      for (final dynamic item in data) {
        final Map<String, dynamic> pet = item as Map<String, dynamic>;
        await _databaseManager.upsertPetFromRemote(
          localId: int.tryParse(pet['local_id']?.toString() ?? '') ?? (pet['id'] as num?)?.toInt() ?? 0,
          remoteId: pet['remote_id']?.toString() ?? pet['id']?.toString(),
          syncStatus: pet['sync_status']?.toString() ?? 'synced',
          remoteLastModifiedAt: _parseBackendDateTime(pet['last_modified_at']),
          name: pet['name']?.toString() ?? '',
          photoPath: pet['photo_path']?.toString(),
        );
      }

      final Map<String, dynamic> pagination =
          (payload['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final int currentPage = (pagination['current_page'] as num?)?.toInt() ?? page;
      final int lastPage = (pagination['last_page'] as num?)?.toInt() ?? currentPage;
      if (currentPage >= lastPage) {
        break;
      }
      page += 1;
    }
  }

  Future<void> _pullRemoteRoutes() async {
    int page = 1;

    while (true) {
      final http.Response? response = await _getWithFallback(
        path: '/routes?per_page=100&page=$page',
        bearerToken: await _currentAccessToken(),
      );

      if (response == null) {
        _log('pull routes: backend inalcanzable.');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _log('pull routes failed [${response.statusCode}], body=${response.body}');
        return;
      }

      final Map<String, dynamic> payload = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> data = (payload['data'] as List<dynamic>? ?? <dynamic>[]);

      for (final dynamic item in data) {
        final Map<String, dynamic> route = item as Map<String, dynamic>;
        final String pointsJson = route['points_json']?.toString() ?? '[]';
        final List<dynamic> rawPoints = jsonDecode(pointsJson) as List<dynamic>;
        final List<RoutePoint> points = rawPoints
            .map((dynamic point) => RoutePoint.fromMap((point as Map<String, dynamic>)))
            .toList(growable: false);

        await _databaseManager.upsertRouteFromRemote(
          localId: int.tryParse(route['local_id']?.toString() ?? '') ?? (route['id'] as num?)?.toInt() ?? 0,
          remoteId: route['remote_id']?.toString() ?? route['id']?.toString(),
          syncStatus: route['sync_status']?.toString() ?? 'synced',
          remoteLastModifiedAt: _parseBackendDateTime(route['last_modified_at']),
          name: route['name']?.toString() ?? '',
          points: points,
        );
      }

      final Map<String, dynamic> pagination =
          (payload['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final int currentPage = (pagination['current_page'] as num?)?.toInt() ?? page;
      final int lastPage = (pagination['last_page'] as num?)?.toInt() ?? currentPage;
      if (currentPage >= lastPage) {
        break;
      }
      page += 1;
    }
  }

  DateTime _parseBackendDateTime(Object? value) {
    if (value == null) {
      return DateTime.now().toUtc();
    }

    final String raw = value.toString().trim();
    if (raw.isEmpty) {
      return DateTime.now().toUtc();
    }

    return DateTime.tryParse(raw)?.toUtc() ?? DateTime.now().toUtc();
  }

  String _toBackendDateTime(DateTime dateTime) {
    final DateTime utc = dateTime.toUtc();
    final String y = utc.year.toString().padLeft(4, '0');
    final String m = utc.month.toString().padLeft(2, '0');
    final String d = utc.day.toString().padLeft(2, '0');
    final String hh = utc.hour.toString().padLeft(2, '0');
    final String mm = utc.minute.toString().padLeft(2, '0');
    final String ss = utc.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  String _normalizeRiskLevelCode(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'low':
      case 'medium':
      case 'high':
      case 'undefined':
        return normalized;
      case 'unknown':
      case 'unspecified':
        return 'undefined';
      default:
        return 'undefined';
    }
  }

  String _normalizeCategoryCode(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'contagious_disease':
      case 'stagnant_water':
      case 'waste_accumulation':
      case 'aggressive_animals':
      case 'undefined':
        return normalized;
      case 'unknown':
      case 'unspecified':
      default:
        return 'undefined';
    }
  }

  String _normalizeDurationCode(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case '1_day':
      case '3_days':
      case '1_week':
      case '2_weeks':
      case '1_month':
      case '3_months':
      case '6_months':
      case '1_year':
      case 'undefined':
        return normalized;
      case 'unknown':
      case 'unspecified':
      default:
        return 'undefined';
    }
  }

  Future<http.Response?> _postWithFallback({
    required String path,
    required Object body,
    String? bearerToken,
  }) async {
    return _apiClient.postWithFallback(
      path,
      body: body,
      bearerToken: bearerToken,
      timeout: const Duration(seconds: 5),
    );
  }

  Future<http.Response?> _getWithFallback({
    required String path,
    String? bearerToken,
  }) async {
    return _apiClient.getWithFallback(
      path,
      bearerToken: bearerToken,
      timeout: const Duration(seconds: 5),
    );
  }
}
