import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../models/hazard_report_record.dart';
import 'local_database_manager.dart';

class UserDataSyncCoordinator {
  UserDataSyncCoordinator({
    required LocalDatabaseManager databaseManager,
    http.Client? httpClient,
  })  : _databaseManager = databaseManager,
        _httpClient = httpClient ?? http.Client();

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'A4M_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  final LocalDatabaseManager _databaseManager;
  final http.Client _httpClient;

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
    final List<String> urls = <String>[
      _configuredApiBaseUrl,
      'http://127.0.0.1:8000/api',
      if (!kIsWeb) 'http://10.0.2.2:8000/api',
    ];

    final Set<String> seen = <String>{};
    return urls.where((String url) => seen.add(url)).toList(growable: false);
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
          await _pushLocalHazards();
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
      body: jsonEncode(payload),
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
    required String body,
  }) async {
    for (final String baseUrl in _apiBaseUrls) {
      try {
        final http.Response response = await _httpClient
            .post(
              Uri.parse('$baseUrl$path'),
              headers: <String, String>{'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode < 500) {
          return response;
        }
      } catch (error) {
        _log('POST failed for $baseUrl$path: $error');
      }
    }

    return null;
  }

  Future<http.Response?> _getWithFallback({
    required String path,
  }) async {
    for (final String baseUrl in _apiBaseUrls) {
      try {
        final http.Response response = await _httpClient
            .get(Uri.parse('$baseUrl$path'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode < 500) {
          return response;
        }
      } catch (error) {
        _log('GET failed for $baseUrl$path: $error');
      }
    }

    return null;
  }
}
