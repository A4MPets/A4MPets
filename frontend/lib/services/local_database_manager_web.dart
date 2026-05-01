import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user_profile.dart';
import '../models/lost_pet_report_record.dart';
import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/pet_record.dart';
import '../models/report_comment_record.dart';
import '../models/route_record.dart';

class LocalDatabaseManager {
  LocalDatabaseManager();

  static const String _userKey = 'local_user_profile_json';
  static const String _petsKey = 'pets_list_json';
  static const String _routesKey = 'routes_list_json';
  static const String _hazardsKey = 'hazard_reports_list_json';
  static const String _lostPetReportsKey = 'lost_pet_reports_list_json';
  static const String _foundPetReportsKey = 'found_pet_reports_list_json';
  static const String _genericReportsKey = 'generic_reports_list_json';

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

    if (!prefs.containsKey(_lostPetReportsKey)) {
      await prefs.setString(
        _lostPetReportsKey,
        jsonEncode(<Map<String, Object?>>[]),
      );
    }

    if (!prefs.containsKey(_foundPetReportsKey)) {
      await prefs.setString(
        _foundPetReportsKey,
        jsonEncode(<Map<String, Object?>>[]),
      );
    }

    if (!prefs.containsKey(_genericReportsKey)) {
      await prefs.setString(
        _genericReportsKey,
        jsonEncode(<Map<String, Object?>>[]),
      );
    }

    await _migrateLegacyHazardCategories(prefs);
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
        .where((dynamic row) {
          final String syncStatus =
              (row as Map<String, dynamic>)['sync_status']?.toString() ?? '';
          return syncStatus != 'deleted' && syncStatus != 'archived';
        })
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

  Future<void> deleteHazardReport({required int hazardId}) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<HazardReportRecord> current = await getHazardReports();
    final List<Map<String, Object?>> encoded = current
        .where((HazardReportRecord report) => report.id != hazardId)
        .map((HazardReportRecord report) => report.toMap())
        .toList(growable: false);

    await prefs.setString(_hazardsKey, jsonEncode(encoded));
  }

  Future<void> removeHazardReportBySyncIdentity({
    required String localUuid,
    String? remoteId,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_hazardsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final List<Map<String, Object?>> encoded = decoded
        .where((dynamic row) {
          final Map<String, Object?> map = (row as Map<String, dynamic>)
              .cast<String, Object?>();
          final String storedLocalUuid = map['local_uuid']?.toString() ?? '';
          final String? storedRemoteId = map['remote_id']?.toString();
          final bool matchesRemote =
              remoteId != null &&
              remoteId.isNotEmpty &&
              storedRemoteId != null &&
              storedRemoteId == remoteId;
          return storedLocalUuid != localUuid && !matchesRemote;
        })
        .map(
          (dynamic row) =>
              (row as Map<String, dynamic>).cast<String, Object?>(),
        )
        .toList(growable: false);

    await prefs.setString(_hazardsKey, jsonEncode(encoded));
  }

  Future<void> addCommentToLostPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _appendCommentToStoredReports<LostPetReportRecord>(
      storageKey: _lostPetReportsKey,
      getReports: getLostPetReports,
      reportId: reportId,
      comment: comment,
      rebuild:
          (LostPetReportRecord report, List<ReportCommentRecord> comments) {
            final int now = DateTime.now().millisecondsSinceEpoch;
            return LostPetReportRecord(
              id: report.id,
              localUuid: report.localUuid,
              remoteId: report.remoteId,
              syncStatus: report.syncStatus,
              lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
              lastSeenLatitude: report.lastSeenLatitude,
              lastSeenLongitude: report.lastSeenLongitude,
              name: report.name,
              details: report.details,
              disappearanceDate: report.disappearanceDate,
              photoUrl: report.photoUrl,
              phone: report.phone,
              comments: comments,
              createdAt: report.createdAt,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
              needsSync: true,
            );
          },
      commentsOf: (LostPetReportRecord report) => report.comments,
    );
  }

  Future<void> addCommentToFoundPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _appendCommentToStoredReports<FoundPetReportRecord>(
      storageKey: _foundPetReportsKey,
      getReports: getFoundPetReports,
      reportId: reportId,
      comment: comment,
      rebuild:
          (FoundPetReportRecord report, List<ReportCommentRecord> comments) {
            final int now = DateTime.now().millisecondsSinceEpoch;
            return FoundPetReportRecord(
              id: report.id,
              localUuid: report.localUuid,
              remoteId: report.remoteId,
              syncStatus: report.syncStatus,
              lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
              latitude: report.latitude,
              longitude: report.longitude,
              details: report.details,
              foundDate: report.foundDate,
              photoUrl: report.photoUrl,
              phone: report.phone,
              comments: comments,
              createdAt: report.createdAt,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
              needsSync: true,
            );
          },
      commentsOf: (FoundPetReportRecord report) => report.comments,
    );
  }

  Future<void> addCommentToGenericReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _appendCommentToStoredReports<GenericReportRecord>(
      storageKey: _genericReportsKey,
      getReports: getGenericReports,
      reportId: reportId,
      comment: comment,
      rebuild:
          (GenericReportRecord report, List<ReportCommentRecord> comments) {
            final int now = DateTime.now().millisecondsSinceEpoch;
            return GenericReportRecord(
              id: report.id,
              localUuid: report.localUuid,
              remoteId: report.remoteId,
              syncStatus: report.syncStatus,
              lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
              latitude: report.latitude,
              longitude: report.longitude,
              description: report.description,
              reportedDate: report.reportedDate,
              riskLevelCode: report.riskLevelCode,
              impactRadiusMeters: report.impactRadiusMeters,
              photoUrl: report.photoUrl,
              comments: comments,
              createdAt: report.createdAt,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
              needsSync: true,
            );
          },
      commentsOf: (GenericReportRecord report) => report.comments,
    );
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

  Future<void> upsertPetsFromRemoteBatch(List<PetRecord> batch) async {
    if (batch.isEmpty) return;
    final SharedPreferences prefs = await _prefs;
    final List<PetRecord> current = (await getPets()).toList();
    
    int nextId = current.isEmpty
        ? 1
        : current.map((PetRecord p) => p.id).reduce((int a, int b) => a > b ? a : b) + 1;

    for (final PetRecord incoming in batch) {
      PetRecord? existing;
      for (final PetRecord pet in current) {
        if (incoming.remoteId != null && pet.remoteId == incoming.remoteId) {
          existing = pet;
          break;
        }
      }

      if (existing == null && incoming.id > 0) {
          for (final PetRecord pet in current) {
              if (pet.id == incoming.id && pet.createdAt.millisecondsSinceEpoch == incoming.createdAt.millisecondsSinceEpoch) {
                  existing = pet;
                  break;
              }
          }
      }
      
      if (existing == null) {
        current.add(PetRecord(
          id: nextId++,
          remoteId: incoming.remoteId,
          name: incoming.name,
          photoPath: incoming.photoPath,
          syncStatus: incoming.syncStatus,
          lastModifiedAt: incoming.lastModifiedAt,
          createdAt: incoming.createdAt,
          updatedAt: incoming.updatedAt,
          needsSync: false,
        ));
      } else {
        if (existing.needsSync && existing.lastModifiedAt.isAfter(incoming.lastModifiedAt)) {
          continue;
        }
        
        final int index = current.indexOf(existing);
        current[index] = PetRecord(
            id: existing.id,
            remoteId: incoming.remoteId ?? existing.remoteId,
            name: incoming.name,
            photoPath: _preferOfflineImageSource(
              currentSource: existing.photoPath,
              remoteSource: incoming.photoPath,
            ),
            syncStatus: incoming.syncStatus,
            lastModifiedAt: incoming.lastModifiedAt,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
        );
      }
    }

    final List<Map<String, Object?>> encoded = current.map((PetRecord p) => p.toMap()).toList(growable: false);
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

  Future<void> upsertRoutesFromRemoteBatch(List<RouteRecord> batch) async {
    if (batch.isEmpty) return;
    final SharedPreferences prefs = await _prefs;
    final List<RouteRecord> current = (await getRoutes()).toList();
    
    int nextId = current.isEmpty
        ? 1
        : current.map((RouteRecord r) => r.id).reduce((int a, int b) => a > b ? a : b) + 1;

    for (final RouteRecord incoming in batch) {
      RouteRecord? existing;
      for (final RouteRecord route in current) {
        if (incoming.remoteId != null && route.remoteId == incoming.remoteId) {
          existing = route;
          break;
        }
      }

      if (existing == null && incoming.id > 0) {
          for (final RouteRecord route in current) {
              if (route.id == incoming.id && route.createdAt.millisecondsSinceEpoch == incoming.createdAt.millisecondsSinceEpoch) {
                  existing = route;
                  break;
              }
          }
      }
      
      if (existing == null) {
        current.add(RouteRecord(
          id: nextId++,
          remoteId: incoming.remoteId,
          name: incoming.name,
          points: incoming.points,
          syncStatus: incoming.syncStatus,
          lastModifiedAt: incoming.lastModifiedAt,
          createdAt: incoming.createdAt,
          updatedAt: incoming.updatedAt,
          needsSync: false,
        ));
      } else {
        if (existing.needsSync && existing.lastModifiedAt.isAfter(incoming.lastModifiedAt)) {
          continue;
        }
        
        final int index = current.indexOf(existing);
        current[index] = RouteRecord(
            id: existing.id,
            remoteId: incoming.remoteId ?? existing.remoteId,
            name: incoming.name,
            points: incoming.points,
            syncStatus: incoming.syncStatus,
            lastModifiedAt: incoming.lastModifiedAt,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
        );
      }
    }

    final List<Map<String, Object?>> encoded = current.map((RouteRecord r) => r.toMap()).toList(growable: false);
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

  Future<void> upsertHazardsFromRemoteBatch(List<HazardReportRecord> batch) async {
    if (batch.isEmpty) return;
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<HazardReportRecord> current = (await getHazardReports()).toList();
    
    int nextId = current.isEmpty
        ? 1
        : current.map((HazardReportRecord h) => h.id).reduce((int a, int b) => a > b ? a : b) + 1;

    for (final HazardReportRecord incoming in batch) {
      HazardReportRecord? existing;
      for (final HazardReportRecord report in current) {
        if (report.localUuid == incoming.localUuid || (incoming.remoteId != null && report.remoteId == incoming.remoteId)) {
          existing = report;
          break;
        }
      }

      if (existing == null) {
        current.add(HazardReportRecord(
          id: nextId++,
          localUuid: incoming.localUuid,
          remoteId: incoming.remoteId,
          syncStatus: incoming.syncStatus,
          lastModifiedAt: incoming.lastModifiedAt,
          incidentLatitude: incoming.incidentLatitude,
          incidentLongitude: incoming.incidentLongitude,
          impactRadiusMeters: incoming.impactRadiusMeters,
          categoryCode: incoming.categoryCode,
          narrativeDescription: incoming.narrativeDescription,
          reportedAt: incoming.reportedAt,
          estimatedDurationCode: incoming.estimatedDurationCode,
          riskLevelCode: incoming.riskLevelCode,
          evidencePhotoUrl: incoming.evidencePhotoUrl,
          reportedByUsername: incoming.reportedByUsername,
          comments: incoming.comments,
          createdAt: incoming.createdAt,
          updatedAt: incoming.updatedAt,
          needsSync: false,
        ));
      } else {
        if (existing.needsSync && existing.lastModifiedAt.isAfter(incoming.lastModifiedAt)) {
          continue;
        }
        
        final int index = current.indexOf(existing);
        current[index] = HazardReportRecord(
            id: existing.id,
            localUuid: incoming.localUuid,
            remoteId: incoming.remoteId ?? existing.remoteId,
            syncStatus: incoming.syncStatus,
            lastModifiedAt: incoming.lastModifiedAt,
            incidentLatitude: incoming.incidentLatitude,
            incidentLongitude: incoming.incidentLongitude,
            impactRadiusMeters: incoming.impactRadiusMeters,
            categoryCode: incoming.categoryCode,
            narrativeDescription: incoming.narrativeDescription,
            reportedAt: incoming.reportedAt,
            estimatedDurationCode: incoming.estimatedDurationCode,
            riskLevelCode: incoming.riskLevelCode,
            evidencePhotoUrl: _preferOfflineImageSource(
              currentSource: existing.evidencePhotoUrl,
              remoteSource: incoming.evidencePhotoUrl,
            ),
            reportedByUsername: incoming.reportedByUsername,
            comments: incoming.comments,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
        );
      }
    }

    final List<Map<String, Object?>> encoded = current.map((HazardReportRecord h) => h.toMap()).toList(growable: false);
    await prefs.setString(_hazardsKey, jsonEncode(encoded));
  }

  Future<List<LostPetReportRecord>> getLostPetReports() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_lostPetReportsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .where(
          (dynamic row) =>
              (row as Map<String, dynamic>)['sync_status'] != 'deleted',
        )
        .map(
          (dynamic row) => LostPetReportRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
  }

  Future<int> addLostPetReport({
    required double lastSeenLatitude,
    required double lastSeenLongitude,
    required String name,
    required String details,
    required DateTime disappearanceDate,
    required String photoUrl,
    required String phone,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<LostPetReportRecord> current = await getLostPetReports();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int nextId = current.isEmpty
        ? 1
        : current
                  .map((LostPetReportRecord report) => report.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;

    final LostPetReportRecord newReport = LostPetReportRecord(
      id: nextId,
      localUuid: _generateLocalUuid('lost'),
      remoteId: null,
      syncStatus: 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
      lastSeenLatitude: lastSeenLatitude,
      lastSeenLongitude: lastSeenLongitude,
      name: name,
      details: details,
      disappearanceDate: disappearanceDate,
      photoUrl: photoUrl,
      phone: phone,
      comments: const <ReportCommentRecord>[],
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );

    final List<Map<String, Object?>> encoded = <Map<String, Object?>>[
      ...current.map((LostPetReportRecord report) => report.toMap()),
      newReport.toMap(),
    ];

    await prefs.setString(_lostPetReportsKey, jsonEncode(encoded));
    return nextId;
  }

  Future<List<LostPetReportRecord>> getLostPetReportsNeedingSync() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_lostPetReportsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic row) => LostPetReportRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .where((LostPetReportRecord report) => report.needsSync)
        .toList(growable: false);
  }

  Future<void> deleteLostPetReport({required int reportId}) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<LostPetReportRecord> current = await getLostPetReports();
    final int now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, Object?>> encoded = current
        .map((LostPetReportRecord report) {
          if (report.id != reportId) {
            return report.toMap();
          }

          return LostPetReportRecord(
            id: report.id,
            localUuid: report.localUuid,
            remoteId: report.remoteId,
            syncStatus: 'deleted',
            lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
            lastSeenLatitude: report.lastSeenLatitude,
            lastSeenLongitude: report.lastSeenLongitude,
            name: report.name,
            details: report.details,
            disappearanceDate: report.disappearanceDate,
            photoUrl: report.photoUrl,
            phone: report.phone,
            comments: report.comments,
            createdAt: report.createdAt,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
            needsSync: true,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_lostPetReportsKey, jsonEncode(encoded));
  }

  Future<void> markLostPetReportAsSynced({
    required String localUuid,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<LostPetReportRecord> current = await getLostPetReports();

    final List<Map<String, Object?>> encoded = current
        .map((LostPetReportRecord report) {
          if (report.localUuid != localUuid) {
            return report.toMap();
          }
          return LostPetReportRecord(
            id: report.id,
            localUuid: report.localUuid,
            remoteId: remoteId ?? report.remoteId,
            syncStatus: syncStatus,
            lastModifiedAt: lastModifiedAt ?? DateTime.now(),
            lastSeenLatitude: report.lastSeenLatitude,
            lastSeenLongitude: report.lastSeenLongitude,
            name: report.name,
            details: report.details,
            disappearanceDate: report.disappearanceDate,
            photoUrl: report.photoUrl,
            phone: report.phone,
            comments: report.comments,
            createdAt: report.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_lostPetReportsKey, jsonEncode(encoded));
  }

  Future<void> upsertLostPetReportsFromRemoteBatch(List<LostPetReportRecord> batch) async {
    if (batch.isEmpty) return;
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<LostPetReportRecord> current = (await getLostPetReports()).toList();
    
    int nextId = current.isEmpty
        ? 1
        : current.map((LostPetReportRecord r) => r.id).reduce((int a, int b) => a > b ? a : b) + 1;

    for (final LostPetReportRecord incoming in batch) {
      LostPetReportRecord? existing;
      for (final LostPetReportRecord report in current) {
        if (report.localUuid == incoming.localUuid || (incoming.remoteId != null && report.remoteId == incoming.remoteId)) {
          existing = report;
          break;
        }
      }

      if (existing == null) {
        current.add(LostPetReportRecord(
          id: nextId++,
          localUuid: incoming.localUuid,
          remoteId: incoming.remoteId,
          syncStatus: incoming.syncStatus,
          lastModifiedAt: incoming.lastModifiedAt,
          lastSeenLatitude: incoming.lastSeenLatitude,
          lastSeenLongitude: incoming.lastSeenLongitude,
          name: incoming.name,
          details: incoming.details,
          disappearanceDate: incoming.disappearanceDate,
          photoUrl: incoming.photoUrl,
          phone: incoming.phone,
          comments: incoming.comments,
          createdAt: incoming.createdAt,
          updatedAt: incoming.updatedAt,
          needsSync: false,
        ));
      } else {
        if (existing.needsSync && existing.lastModifiedAt.isAfter(incoming.lastModifiedAt)) {
          continue;
        }
        
        final int index = current.indexOf(existing);
        current[index] = LostPetReportRecord(
            id: existing.id,
            localUuid: incoming.localUuid,
            remoteId: incoming.remoteId ?? existing.remoteId,
            syncStatus: incoming.syncStatus,
            lastModifiedAt: incoming.lastModifiedAt,
            lastSeenLatitude: incoming.lastSeenLatitude,
            lastSeenLongitude: incoming.lastSeenLongitude,
            name: incoming.name,
            details: incoming.details,
            disappearanceDate: incoming.disappearanceDate,
            photoUrl: _preferOfflineImageSource(
              currentSource: existing.photoUrl,
              remoteSource: incoming.photoUrl,
            ),
            phone: incoming.phone,
            comments: incoming.comments,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
        );
      }
    }

    final List<Map<String, Object?>> encoded = current.map((LostPetReportRecord r) => r.toMap()).toList(growable: false);
    await prefs.setString(_lostPetReportsKey, jsonEncode(encoded));
  }

  Future<List<FoundPetReportRecord>> getFoundPetReports() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_foundPetReportsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .where(
          (dynamic row) =>
              (row as Map<String, dynamic>)['sync_status'] != 'deleted',
        )
        .map(
          (dynamic row) => FoundPetReportRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
  }

  Future<int> addFoundPetReport({
    required double latitude,
    required double longitude,
    required String details,
    required DateTime foundDate,
    String? photoUrl,
    String? phone,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<FoundPetReportRecord> current = await getFoundPetReports();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int nextId = current.isEmpty
        ? 1
        : current
                  .map((FoundPetReportRecord report) => report.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;

    final FoundPetReportRecord newReport = FoundPetReportRecord(
      id: nextId,
      localUuid: _generateLocalUuid('found'),
      remoteId: null,
      syncStatus: 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
      latitude: latitude,
      longitude: longitude,
      details: details,
      foundDate: foundDate,
      photoUrl: photoUrl,
      phone: phone,
      comments: const <ReportCommentRecord>[],
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );

    final List<Map<String, Object?>> encoded = <Map<String, Object?>>[
      ...current.map((FoundPetReportRecord report) => report.toMap()),
      newReport.toMap(),
    ];

    await prefs.setString(_foundPetReportsKey, jsonEncode(encoded));
    return nextId;
  }

  Future<List<FoundPetReportRecord>> getFoundPetReportsNeedingSync() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_foundPetReportsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic row) => FoundPetReportRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .where((FoundPetReportRecord report) => report.needsSync)
        .toList(growable: false);
  }

  Future<void> deleteFoundPetReport({required int reportId}) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<FoundPetReportRecord> current = await getFoundPetReports();
    final int now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, Object?>> encoded = current
        .map((FoundPetReportRecord report) {
          if (report.id != reportId) {
            return report.toMap();
          }

          return FoundPetReportRecord(
            id: report.id,
            localUuid: report.localUuid,
            remoteId: report.remoteId,
            syncStatus: 'deleted',
            lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
            latitude: report.latitude,
            longitude: report.longitude,
            details: report.details,
            foundDate: report.foundDate,
            photoUrl: report.photoUrl,
            phone: report.phone,
            comments: report.comments,
            createdAt: report.createdAt,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
            needsSync: true,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_foundPetReportsKey, jsonEncode(encoded));
  }

  Future<void> markFoundPetReportAsSynced({
    required String localUuid,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<FoundPetReportRecord> current = await getFoundPetReports();

    final List<Map<String, Object?>> encoded = current
        .map((FoundPetReportRecord report) {
          if (report.localUuid != localUuid) {
            return report.toMap();
          }
          return FoundPetReportRecord(
            id: report.id,
            localUuid: report.localUuid,
            remoteId: remoteId ?? report.remoteId,
            syncStatus: syncStatus,
            lastModifiedAt: lastModifiedAt ?? DateTime.now(),
            latitude: report.latitude,
            longitude: report.longitude,
            details: report.details,
            foundDate: report.foundDate,
            photoUrl: report.photoUrl,
            phone: report.phone,
            comments: report.comments,
            createdAt: report.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_foundPetReportsKey, jsonEncode(encoded));
  }

  Future<void> upsertFoundPetReportsFromRemoteBatch(List<FoundPetReportRecord> batch) async {
    if (batch.isEmpty) return;
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<FoundPetReportRecord> current = (await getFoundPetReports()).toList();
    
    int nextId = current.isEmpty
        ? 1
        : current.map((FoundPetReportRecord r) => r.id).reduce((int a, int b) => a > b ? a : b) + 1;

    for (final FoundPetReportRecord incoming in batch) {
      FoundPetReportRecord? existing;
      for (final FoundPetReportRecord report in current) {
        if (report.localUuid == incoming.localUuid || (incoming.remoteId != null && report.remoteId == incoming.remoteId)) {
          existing = report;
          break;
        }
      }

      if (existing == null) {
        current.add(FoundPetReportRecord(
          id: nextId++,
          localUuid: incoming.localUuid,
          remoteId: incoming.remoteId,
          syncStatus: incoming.syncStatus,
          lastModifiedAt: incoming.lastModifiedAt,
          latitude: incoming.latitude,
          longitude: incoming.longitude,
          details: incoming.details,
          foundDate: incoming.foundDate,
          photoUrl: incoming.photoUrl,
          phone: incoming.phone,
          comments: incoming.comments,
          createdAt: incoming.createdAt,
          updatedAt: incoming.updatedAt,
          needsSync: false,
        ));
      } else {
        if (existing.needsSync && existing.lastModifiedAt.isAfter(incoming.lastModifiedAt)) {
          continue;
        }
        
        final int index = current.indexOf(existing);
        current[index] = FoundPetReportRecord(
            id: existing.id,
            localUuid: incoming.localUuid,
            remoteId: incoming.remoteId ?? existing.remoteId,
            syncStatus: incoming.syncStatus,
            lastModifiedAt: incoming.lastModifiedAt,
            latitude: incoming.latitude,
            longitude: incoming.longitude,
            details: incoming.details,
            foundDate: incoming.foundDate,
            photoUrl: _preferOfflineImageSource(
              currentSource: existing.photoUrl,
              remoteSource: incoming.photoUrl,
            ),
            phone: incoming.phone,
            comments: incoming.comments,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
        );
      }
    }

    final List<Map<String, Object?>> encoded = current.map((FoundPetReportRecord r) => r.toMap()).toList(growable: false);
    await prefs.setString(_foundPetReportsKey, jsonEncode(encoded));
  }

  Future<List<GenericReportRecord>> getGenericReports() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_genericReportsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .where(
          (dynamic row) =>
              (row as Map<String, dynamic>)['sync_status'] != 'deleted',
        )
        .map(
          (dynamic row) => GenericReportRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .toList(growable: false);
  }

  Future<int> addGenericReport({
    required double latitude,
    required double longitude,
    required String description,
    required DateTime reportedDate,
    required String riskLevelCode,
    required int impactRadiusMeters,
    String? photoUrl,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<GenericReportRecord> current = await getGenericReports();
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int nextId = current.isEmpty
        ? 1
        : current
                  .map((GenericReportRecord report) => report.id)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;

    final GenericReportRecord newReport = GenericReportRecord(
      id: nextId,
      localUuid: _generateLocalUuid('generic'),
      remoteId: null,
      syncStatus: 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
      latitude: latitude,
      longitude: longitude,
      description: description,
      reportedDate: reportedDate,
      riskLevelCode: riskLevelCode,
      impactRadiusMeters: impactRadiusMeters,
      photoUrl: photoUrl,
      comments: const <ReportCommentRecord>[],
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );

    final List<Map<String, Object?>> encoded = <Map<String, Object?>>[
      ...current.map((GenericReportRecord report) => report.toMap()),
      newReport.toMap(),
    ];

    await prefs.setString(_genericReportsKey, jsonEncode(encoded));
    return nextId;
  }

  Future<List<GenericReportRecord>> getGenericReportsNeedingSync() async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final String raw = prefs.getString(_genericReportsKey)!;
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic row) => GenericReportRecord.fromMap(
            (row as Map<String, dynamic>).cast<String, Object?>(),
          ),
        )
        .where((GenericReportRecord report) => report.needsSync)
        .toList(growable: false);
  }

  Future<void> deleteGenericReport({required int reportId}) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<GenericReportRecord> current = await getGenericReports();
    final int now = DateTime.now().millisecondsSinceEpoch;

    final List<Map<String, Object?>> encoded = current
        .map((GenericReportRecord report) {
          if (report.id != reportId) {
            return report.toMap();
          }

          return GenericReportRecord(
            id: report.id,
            localUuid: report.localUuid,
            remoteId: report.remoteId,
            syncStatus: 'deleted',
            lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
            latitude: report.latitude,
            longitude: report.longitude,
            description: report.description,
            reportedDate: report.reportedDate,
            riskLevelCode: report.riskLevelCode,
            impactRadiusMeters: report.impactRadiusMeters,
            photoUrl: report.photoUrl,
            comments: report.comments,
            createdAt: report.createdAt,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
            needsSync: true,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_genericReportsKey, jsonEncode(encoded));
  }

  Future<void> markGenericReportAsSynced({
    required String localUuid,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<GenericReportRecord> current = await getGenericReports();

    final List<Map<String, Object?>> encoded = current
        .map((GenericReportRecord report) {
          if (report.localUuid != localUuid) {
            return report.toMap();
          }
          return GenericReportRecord(
            id: report.id,
            localUuid: report.localUuid,
            remoteId: remoteId ?? report.remoteId,
            syncStatus: syncStatus,
            lastModifiedAt: lastModifiedAt ?? DateTime.now(),
            latitude: report.latitude,
            longitude: report.longitude,
            description: report.description,
            reportedDate: report.reportedDate,
            riskLevelCode: report.riskLevelCode,
            impactRadiusMeters: report.impactRadiusMeters,
            photoUrl: report.photoUrl,
            comments: report.comments,
            createdAt: report.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
          ).toMap();
        })
        .toList(growable: false);

    await prefs.setString(_genericReportsKey, jsonEncode(encoded));
  }

  Future<void> upsertGenericReportsFromRemoteBatch(List<GenericReportRecord> batch) async {
    if (batch.isEmpty) return;
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<GenericReportRecord> current = (await getGenericReports()).toList();
    
    int nextId = current.isEmpty
        ? 1
        : current.map((GenericReportRecord r) => r.id).reduce((int a, int b) => a > b ? a : b) + 1;

    for (final GenericReportRecord incoming in batch) {
      GenericReportRecord? existing;
      for (final GenericReportRecord report in current) {
        if (report.localUuid == incoming.localUuid || (incoming.remoteId != null && report.remoteId == incoming.remoteId)) {
          existing = report;
          break;
        }
      }

      if (existing == null) {
        current.add(GenericReportRecord(
          id: nextId++,
          localUuid: incoming.localUuid,
          remoteId: incoming.remoteId,
          syncStatus: incoming.syncStatus,
          lastModifiedAt: incoming.lastModifiedAt,
          latitude: incoming.latitude,
          longitude: incoming.longitude,
          description: incoming.description,
          reportedDate: incoming.reportedDate,
          riskLevelCode: incoming.riskLevelCode,
          impactRadiusMeters: incoming.impactRadiusMeters,
          photoUrl: incoming.photoUrl,
          comments: incoming.comments,
          createdAt: incoming.createdAt,
          updatedAt: incoming.updatedAt,
          needsSync: false,
        ));
      } else {
        if (existing.needsSync && existing.lastModifiedAt.isAfter(incoming.lastModifiedAt)) {
          continue;
        }
        
        final int index = current.indexOf(existing);
        current[index] = GenericReportRecord(
            id: existing.id,
            localUuid: incoming.localUuid,
            remoteId: incoming.remoteId ?? existing.remoteId,
            syncStatus: incoming.syncStatus,
            lastModifiedAt: incoming.lastModifiedAt,
            latitude: incoming.latitude,
            longitude: incoming.longitude,
            description: incoming.description,
            reportedDate: incoming.reportedDate,
            riskLevelCode: incoming.riskLevelCode,
            impactRadiusMeters: incoming.impactRadiusMeters,
            photoUrl: _preferOfflineImageSource(
              currentSource: existing.photoUrl,
              remoteSource: incoming.photoUrl,
            ),
            comments: incoming.comments,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
            needsSync: false,
        );
      }
    }

    final List<Map<String, Object?>> encoded = current.map((GenericReportRecord r) => r.toMap()).toList(growable: false);
    await prefs.setString(_genericReportsKey, jsonEncode(encoded));
  }



  Future<void> _appendCommentToStoredReports<T>({
    required String storageKey,
    required Future<List<T>> Function() getReports,
    required int reportId,
    required ReportCommentRecord comment,
    required T Function(T report, List<ReportCommentRecord> comments) rebuild,
    required List<ReportCommentRecord> Function(T report) commentsOf,
  }) async {
    final SharedPreferences prefs = await _prefs;
    await _ensureDefaultUser(prefs);
    final List<T> current = await getReports();

    final List<Map<String, Object?>> encoded = current
        .map((T report) {
          final dynamic dynamicReport = report;
          if (dynamicReport.id != reportId) {
            return dynamicReport.toMap() as Map<String, Object?>;
          }

          final List<ReportCommentRecord> updatedComments =
              <ReportCommentRecord>[...commentsOf(report), comment];
          final dynamic updated = rebuild(report, updatedComments);
          return updated.toMap() as Map<String, Object?>;
        })
        .toList(growable: false);

    await prefs.setString(storageKey, jsonEncode(encoded));
  }

  String _generateLocalUuid([String prefix = 'hz']) {
    final int now = DateTime.now().microsecondsSinceEpoch;
    final int randomPart = (Random().nextDouble() * 0xFFFFFFFF).floor();
    return '$prefix-$now-${randomPart.toRadixString(16)}';
  }

  Future<void> _migrateLegacyHazardCategories(SharedPreferences prefs) async {
    final String raw = prefs.getString(_hazardsKey) ?? '[]';
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    bool changed = false;
    final List<Map<String, Object?>> migrated = decoded
        .map((dynamic row) {
          final Map<String, Object?> map = (row as Map<String, dynamic>)
              .cast<String, Object?>();
          final String currentCode =
              map['category_code']?.toString().trim().toLowerCase() ?? '';
          String nextCode = currentCode;
          if (currentCode == 'aggressive_animals') {
            nextCode = 'possible_rabies_vectors';
          } else if (currentCode.isEmpty ||
              currentCode == 'undefined' ||
              currentCode == 'unknown' ||
              currentCode == 'unspecified') {
            nextCode = 'pest_presence';
          }
          if (nextCode != currentCode) {
            changed = true;
            map['category_code'] = nextCode;
          }
          return map;
        })
        .toList(growable: false);

    if (changed) {
      await prefs.setString(_hazardsKey, jsonEncode(migrated));
    }
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
