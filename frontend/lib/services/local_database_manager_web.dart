import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user_profile.dart';
import '../models/hazard_report_record.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';

class LocalDatabaseManager {
  LocalDatabaseManager();

  static const String _userKey = 'local_user_profile_json';
  static const String _petsKey = 'pets_list_json';
  static const String _routesKey = 'routes_list_json';
  static const String _hazardsKey = 'hazard_reports_list_json';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> _ensureDefaultUser(SharedPreferences prefs) async {
    if (!prefs.containsKey(_userKey)) {
      await prefs.setString(
        _userKey,
        jsonEncode(LocalUserProfile.guest().toMap()),
      );
    }

    if (!prefs.containsKey(_petsKey)) {
      await prefs.setString(_petsKey, jsonEncode(<Map<String, Object?>>[]));
    }

    if (!prefs.containsKey(_routesKey)) {
      await prefs.setString(_routesKey, jsonEncode(<Map<String, Object?>>[]));
    }

    if (!prefs.containsKey(_hazardsKey)) {
      await prefs.setString(_hazardsKey, jsonEncode(<Map<String, Object?>>[]));
    }
  }

  Future<LocalUserProfile> getLocalUserProfile() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final String raw = prefs.getString(_userKey)!;
    final Map<String, Object?> map = (jsonDecode(raw) as Map<String, dynamic>)
        .cast<String, Object?>();
    return LocalUserProfile.fromMap(map);
  }

  Future<void> saveLocalUserProfile(LocalUserProfile profile) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    await prefs.setString(_userKey, jsonEncode(profile.toMap()));
  }

  Future<void> clearUserSessionData() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      _userKey,
      jsonEncode(LocalUserProfile.guest().toMap()),
    );
    await prefs.setString(_petsKey, jsonEncode(<Map<String, Object?>>[]));
    await prefs.setString(_routesKey, jsonEncode(<Map<String, Object?>>[]));
  }

  Future<List<PetRecord>> getPets() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final String raw = prefs.getString(_petsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .where(
          (dynamic row) =>
              (row as Map<String, dynamic>)['sync_status'] != 'deleted',
        )
        .map(
          (dynamic row) => PetRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
  }

  Future<int> addPet({required String name, String? photoPath}) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final List<PetRecord> currentPets = await getPets();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int nextId = currentPets.isEmpty
        ? 1
        : currentPets
                  .map((PetRecord pet) => pet.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;

    final PetRecord newPet = PetRecord(
      id: nextId,
      remoteId: null,
      name: name,
      photoPath: photoPath,
      syncStatus: 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
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

    final List<Map<String, Object?>> encodedPets = currentPets.map((
      PetRecord pet,
    ) {
      if (pet.id == petId) {
        return PetRecord(
          id: pet.id,
          remoteId: pet.remoteId,
          name: name,
          photoPath: photoPath,
          syncStatus: pet.syncStatus == 'synced' ? 'synced' : 'created',
          lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
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
    final int now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, Object?>> encodedPets = currentPets
        .map((PetRecord pet) {
          if (pet.id != petId) {
            return pet.toMap();
          }

          return PetRecord(
            id: pet.id,
            remoteId: pet.remoteId,
            name: pet.name,
            photoPath: pet.photoPath,
            syncStatus: 'deleted',
            lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
            createdAt: pet.createdAt,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
            needsSync: true,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_petsKey, jsonEncode(encodedPets));
  }

  Future<List<RouteRecord>> getRoutes() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_routesKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .where(
          (dynamic row) =>
              (row as Map<String, dynamic>)['sync_status'] != 'deleted',
        )
        .map(
          (dynamic row) => RouteRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
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
        : current
                  .map((RouteRecord r) => r.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;
    final RouteRecord newRoute = RouteRecord(
      id: nextId,
      remoteId: null,
      name: name,
      points: points,
      syncStatus: 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
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
    final int now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, Object?>> encoded = current
        .map((RouteRecord route) {
          if (route.id != routeId) {
            return route.toMap();
          }

          return RouteRecord(
            id: route.id,
            remoteId: route.remoteId,
            name: route.name,
            points: route.points,
            syncStatus: 'deleted',
            lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
            createdAt: route.createdAt,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
            needsSync: true,
          ).toMap();
        })
        .toList(growable: false);

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
          remoteId: route.remoteId,
          name: name,
          points: points,
          syncStatus: route.syncStatus == 'synced' ? 'synced' : 'created',
          lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
          createdAt: route.createdAt,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
          needsSync: true,
        ).toMap();
      }
      return route.toMap();
    }).toList();

    await prefs.setString(_routesKey, jsonEncode(encoded));
  }

  Future<List<HazardReportRecord>> getHazardReports() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_hazardsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic row) => HazardReportRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
  }

  Future<int> addHazardReport({
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
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final List<HazardReportRecord> current = await getHazardReports();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int nextId = current.isEmpty
        ? 1
        : current
                  .map((HazardReportRecord report) => report.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;

    final HazardReportRecord newReport = HazardReportRecord(
      id: nextId,
      localUuid: _generateLocalUuid(),
      remoteId: null,
      syncStatus: 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
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
      comments: const <HazardCommentRecord>[],
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );

    final List<Map<String, Object?>> encoded = <Map<String, Object?>>[
      ...current.map((HazardReportRecord report) => report.toMap()),
      newReport.toMap(),
    ];

    await prefs.setString(_hazardsKey, jsonEncode(encoded));
    return nextId;
  }

  Future<void> addCommentToHazard({
    required int hazardId,
    required HazardCommentRecord comment,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final List<HazardReportRecord> current = await getHazardReports();
    final int now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, Object?>> encoded = current
        .map((HazardReportRecord report) {
          if (report.id != hazardId) {
            return report.toMap();
          }

          return HazardReportRecord(
            id: report.id,
            localUuid: report.localUuid,
            remoteId: report.remoteId,
            syncStatus: report.syncStatus,
            lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
            incidentLatitude: report.incidentLatitude,
            incidentLongitude: report.incidentLongitude,
            impactRadiusMeters: report.impactRadiusMeters,
            categoryCode: report.categoryCode,
            narrativeDescription: report.narrativeDescription,
            reportedAt: report.reportedAt,
            estimatedDurationCode: report.estimatedDurationCode,
            riskLevelCode: report.riskLevelCode,
            evidencePhotoUrl: report.evidencePhotoUrl,
            reportedByUsername: report.reportedByUsername,
            comments: <HazardCommentRecord>[...report.comments, comment],
            createdAt: report.createdAt,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
            needsSync: true,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_hazardsKey, jsonEncode(encoded));
  }

  Future<List<PetRecord>> getPetsNeedingSync() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final String raw = prefs.getString(_petsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic row) => PetRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .where((PetRecord pet) => pet.needsSync)
        .toList(growable: false);
  }

  Future<void> markPetAsSynced({
    required int petId,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_petsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final List<PetRecord> current = decoded
        .map(
          (dynamic row) => PetRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);

    final List<Map<String, Object?>> encoded = current
        .map((PetRecord pet) {
          if (pet.id != petId) {
            return pet.toMap();
          }

          return PetRecord(
            id: pet.id,
            remoteId: remoteId ?? pet.remoteId,
            name: pet.name,
            photoPath: pet.photoPath,
            syncStatus: syncStatus,
            lastModifiedAt: lastModifiedAt ?? DateTime.now(),
            createdAt: pet.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_petsKey, jsonEncode(encoded));
  }

  Future<void> upsertPetFromRemote({
    required int localId,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required String name,
    required String? photoPath,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final List<PetRecord> current = await getPets();

    PetRecord? existing;
    for (final PetRecord pet in current) {
      if (pet.id == localId || (remoteId != null && pet.remoteId == remoteId)) {
        existing = pet;
        break;
      }
    }

    final int nextId = current.isEmpty
        ? 1
        : current
                  .map((PetRecord pet) => pet.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;

    if (existing == null) {
      final PetRecord inserted = PetRecord(
        id: nextId,
        remoteId: remoteId,
        name: name,
        photoPath: photoPath,
        syncStatus: syncStatus,
        lastModifiedAt: remoteLastModifiedAt,
        createdAt: remoteLastModifiedAt,
        updatedAt: remoteLastModifiedAt,
        needsSync: false,
      );

      final List<Map<String, Object?>> encoded = <Map<String, Object?>>[
        ...current.map((PetRecord pet) => pet.toMap()),
        inserted.toMap(),
      ];
      await prefs.setString(_petsKey, jsonEncode(encoded));
      return;
    }

    if (existing.needsSync &&
        existing.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    final String? resolvedPhotoPath = _preferOfflineImageSource(
      currentSource: existing.photoPath,
      remoteSource: photoPath,
    );

    final List<Map<String, Object?>> encoded = current
        .map((PetRecord pet) {
          if (pet.id != existing!.id) {
            return pet.toMap();
          }
          return PetRecord(
            id: pet.id,
            remoteId: remoteId ?? pet.remoteId,
            name: name,
            photoPath: resolvedPhotoPath,
            syncStatus: syncStatus,
            lastModifiedAt: remoteLastModifiedAt,
            createdAt: pet.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_petsKey, jsonEncode(encoded));
  }

  Future<List<RouteRecord>> getRoutesNeedingSync() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);

    final String raw = prefs.getString(_routesKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic row) => RouteRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .where((RouteRecord route) => route.needsSync)
        .toList(growable: false);
  }

  Future<void> markRouteAsSynced({
    required int routeId,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_routesKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final List<RouteRecord> current = decoded
        .map(
          (dynamic row) => RouteRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);

    final List<Map<String, Object?>> encoded = current
        .map((RouteRecord route) {
          if (route.id != routeId) {
            return route.toMap();
          }

          return RouteRecord(
            id: route.id,
            remoteId: remoteId ?? route.remoteId,
            name: route.name,
            points: route.points,
            syncStatus: syncStatus,
            lastModifiedAt: lastModifiedAt ?? DateTime.now(),
            createdAt: route.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_routesKey, jsonEncode(encoded));
  }

  Future<void> upsertRouteFromRemote({
    required int localId,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required String name,
    required List<RoutePoint> points,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final List<RouteRecord> current = await getRoutes();

    RouteRecord? existing;
    for (final RouteRecord route in current) {
      if (route.id == localId ||
          (remoteId != null && route.remoteId == remoteId)) {
        existing = route;
        break;
      }
    }

    final int nextId = current.isEmpty
        ? 1
        : current
                  .map((RouteRecord route) => route.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;

    if (existing == null) {
      final RouteRecord inserted = RouteRecord(
        id: nextId,
        remoteId: remoteId,
        name: name,
        points: points,
        syncStatus: syncStatus,
        lastModifiedAt: remoteLastModifiedAt,
        createdAt: remoteLastModifiedAt,
        updatedAt: remoteLastModifiedAt,
        needsSync: false,
      );

      final List<Map<String, Object?>> encoded = <Map<String, Object?>>[
        ...current.map((RouteRecord route) => route.toMap()),
        inserted.toMap(),
      ];
      await prefs.setString(_routesKey, jsonEncode(encoded));
      return;
    }

    if (existing.needsSync &&
        existing.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    final List<Map<String, Object?>> encoded = current
        .map((RouteRecord route) {
          if (route.id != existing!.id) {
            return route.toMap();
          }
          return RouteRecord(
            id: route.id,
            remoteId: remoteId ?? route.remoteId,
            name: name,
            points: points,
            syncStatus: syncStatus,
            lastModifiedAt: remoteLastModifiedAt,
            createdAt: route.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_routesKey, jsonEncode(encoded));
  }

  Future<void> markUserDataForFutureSync() async {}

  Future<List<HazardReportRecord>> getHazardReportsNeedingSync() async {
    final List<HazardReportRecord> hazards = await getHazardReports();
    return hazards
        .where((HazardReportRecord h) => h.needsSync)
        .toList(growable: false);
  }

  Future<void> markHazardAsSynced({
    required String localUuid,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<HazardReportRecord> current = await getHazardReports();

    final List<Map<String, Object?>> encoded = current
        .map((HazardReportRecord report) {
          if (report.localUuid != localUuid) {
            return report.toMap();
          }
          return HazardReportRecord(
            id: report.id,
            localUuid: report.localUuid,
            remoteId: remoteId ?? report.remoteId,
            syncStatus: syncStatus,
            lastModifiedAt: lastModifiedAt ?? DateTime.now(),
            incidentLatitude: report.incidentLatitude,
            incidentLongitude: report.incidentLongitude,
            impactRadiusMeters: report.impactRadiusMeters,
            categoryCode: report.categoryCode,
            narrativeDescription: report.narrativeDescription,
            reportedAt: report.reportedAt,
            estimatedDurationCode: report.estimatedDurationCode,
            riskLevelCode: report.riskLevelCode,
            evidencePhotoUrl: report.evidencePhotoUrl,
            reportedByUsername: report.reportedByUsername,
            comments: report.comments,
            createdAt: report.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_hazardsKey, jsonEncode(encoded));
  }

  Future<void> upsertHazardFromRemote({
    required String localUuid,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required double incidentLatitude,
    required double incidentLongitude,
    required int impactRadiusMeters,
    required String categoryCode,
    required String riskLevelCode,
    required String narrativeDescription,
    required String estimatedDurationCode,
    required DateTime reportedAt,
    required String? evidencePhotoUrl,
    required String reportedByUsername,
    String? commentsJson,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<HazardReportRecord> current = await getHazardReports();

    HazardReportRecord? existing;
    for (final HazardReportRecord report in current) {
      if (report.localUuid == localUuid ||
          (remoteId != null && report.remoteId == remoteId)) {
        existing = report;
        break;
      }
    }

    final int nextId = current.isEmpty
        ? 1
        : current
                  .map((HazardReportRecord report) => report.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;

    if (existing == null) {
      final List<HazardCommentRecord> parsedComments = commentsJson == null
          ? const <HazardCommentRecord>[]
          : _decodeHazardComments(commentsJson);

      final HazardReportRecord inserted = HazardReportRecord(
        id: nextId,
        localUuid: localUuid,
        remoteId: remoteId,
        syncStatus: syncStatus,
        lastModifiedAt: remoteLastModifiedAt,
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
        comments: parsedComments,
        createdAt: remoteLastModifiedAt,
        updatedAt: remoteLastModifiedAt,
        needsSync: false,
      );

      final List<Map<String, Object?>> encoded = <Map<String, Object?>>[
        ...current.map((HazardReportRecord report) => report.toMap()),
        inserted.toMap(),
      ];
      await prefs.setString(_hazardsKey, jsonEncode(encoded));
      return;
    }

    if (existing.needsSync &&
        existing.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    final String? resolvedEvidencePhoto = _preferOfflineImageSource(
      currentSource: existing.evidencePhotoUrl,
      remoteSource: evidencePhotoUrl,
    );

    final List<Map<String, Object?>> encoded = current
        .map((HazardReportRecord report) {
          if (report.id != existing!.id) {
            return report.toMap();
          }

          final List<HazardCommentRecord> resolvedComments =
              commentsJson == null
              ? report.comments
              : _decodeHazardComments(commentsJson);

          return HazardReportRecord(
            id: report.id,
            localUuid: localUuid,
            remoteId: remoteId ?? report.remoteId,
            syncStatus: syncStatus,
            lastModifiedAt: remoteLastModifiedAt,
            incidentLatitude: incidentLatitude,
            incidentLongitude: incidentLongitude,
            impactRadiusMeters: impactRadiusMeters,
            categoryCode: categoryCode,
            narrativeDescription: narrativeDescription,
            reportedAt: reportedAt,
            estimatedDurationCode: estimatedDurationCode,
            riskLevelCode: riskLevelCode,
            evidencePhotoUrl: resolvedEvidencePhoto,
            reportedByUsername: reportedByUsername,
            comments: resolvedComments,
            createdAt: report.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_hazardsKey, jsonEncode(encoded));
  }

  List<HazardCommentRecord> _decodeHazardComments(String commentsJson) {
    try {
      final List<dynamic> decoded = jsonDecode(commentsJson) as List<dynamic>;
      return decoded
          .map(
            (dynamic row) =>
                HazardCommentRecord.fromMap((row as Map<String, dynamic>)),
          )
          .toList(growable: false);
    } catch (_) {
      return const <HazardCommentRecord>[];
    }
  }

  String _generateLocalUuid() {
    final int now = DateTime.now().microsecondsSinceEpoch;
    final int randomPart = (Random().nextDouble() * 0xFFFFFFFF).floor();
    return 'hz-$now-${randomPart.toRadixString(16)}';
  }

  String? _preferOfflineImageSource({
    required String? currentSource,
    required String? remoteSource,
  }) {
    if (currentSource == null || currentSource.isEmpty) {
      return remoteSource;
    }

    if (remoteSource == null || remoteSource.isEmpty) {
      return currentSource;
    }

    if (!_isRemoteUrl(currentSource)) {
      return currentSource;
    }

    return remoteSource;
  }

  bool _isRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
