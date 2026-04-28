import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/local_user_profile.dart';
import '../models/lost_pet_report_record.dart';
import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/pet_record.dart';
import '../models/report_comment_record.dart';
import '../models/route_record.dart';
import 'local_database_schema.dart';

class LocalDatabaseManager {
  LocalDatabaseManager();

  static const String _databaseName = 'a4mpets_local.db';
  static const String _userTable = 'local_user_profile';
  static const String _petsTable = 'pets';
  static const String _routesTable = 'routes';
  static const String _hazardsTable = 'hazard_reports';
  static const String _lostPetReportsTable = 'lost_pet_reports';
  static const String _foundPetReportsTable = 'found_pet_reports';
  static const String _genericReportsTable = 'generic_reports';

  Database? _database;
  Future<Database>? _databaseFuture;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    if (_databaseFuture != null) {
      return _databaseFuture!;
    }

    _databaseFuture = _initializeDatabase();
    final Database db = await _databaseFuture!;
    _database = db;
    _databaseFuture = null;
    return db;
  }

  Future<Database> _initializeDatabase() async {
    final Database db = await _openDatabase();
    await _ensureDefaultUser(db);
    return db;
  }

  Future<Database> _openDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final String databasePath = p.join(appDirectory.path, _databaseName);

    return openDatabase(
      databasePath,
      version: 10,
      onCreate: (Database db, int version) async {
        await LocalDatabaseSchema.createTables(
          db: db,
          userTable: _userTable,
          petsTable: _petsTable,
          routesTable: _routesTable,
          hazardsTable: _hazardsTable,
          lostPetReportsTable: _lostPetReportsTable,
          foundPetReportsTable: _foundPetReportsTable,
          genericReportsTable: _genericReportsTable,
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await LocalDatabaseSchema.applyMigrations(
          db: db,
          oldVersion: oldVersion,
          userTable: _userTable,
          petsTable: _petsTable,
          routesTable: _routesTable,
          hazardsTable: _hazardsTable,
          lostPetReportsTable: _lostPetReportsTable,
          foundPetReportsTable: _foundPetReportsTable,
          genericReportsTable: _genericReportsTable,
        );
      },
    );
  }

  Future<void> _ensureDefaultUser(Database db) async {
    final List<Map<String, Object?>> rows = await db.query(
      _userTable,
      limit: 1,
    );

    if (rows.isEmpty) {
      await db.insert(_userTable, LocalUserProfile.guest().toMap());
    }
  }

  Future<LocalUserProfile> getLocalUserProfile() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(_userTable);
    if (rows.isEmpty) {
      await db.insert(_userTable, LocalUserProfile.guest().toMap());
      return LocalUserProfile.guest();
    }

    if (rows.length > 1) {
      await db.delete(_userTable);
      final LocalUserProfile normalized = LocalUserProfile.fromMap(rows.last);
      await db.insert(_userTable, normalized.toMap());
      return normalized;
    }

    return LocalUserProfile.fromMap(rows.first);
  }

  Future<void> saveLocalUserProfile(LocalUserProfile profile) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      await txn.delete(_userTable);
      await txn.insert(
        _userTable,
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> clearUserSessionData() async {
    final Database db = await database;
    await db.delete(_petsTable);
    await db.delete(_routesTable);
    await db.delete('route_cache');
    await db.transaction((Transaction txn) async {
      await txn.delete(_userTable);
      await txn.insert(
        _userTable,
        LocalUserProfile.guest().toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<PetRecord>> getPets() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _petsTable,
      where: 'sync_status != ?',
      whereArgs: <Object?>['deleted'],
      orderBy: 'created_at ASC',
    );

    return rows.map(PetRecord.fromMap).toList(growable: false);
  }

  Future<int> addPet({required String name, String? photoPath}) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;

    return db.insert(_petsTable, <String, Object?>{
      'remote_id': null,
      'name': name,
      'photo_path': photoPath,
      'sync_status': 'created',
      'last_modified_at': now,
      'synced_at': null,
      'created_at': now,
      'updated_at': now,
      'needs_sync': 1,
    });
  }

  Future<int> getPetsCount() async {
    final Database db = await database;
    final int? result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $_petsTable WHERE sync_status != ?',
        <Object?>['deleted'],
      ),
    );
    return result ?? 0;
  }

  Future<void> updatePet({
    required int petId,
    required String name,
    String? photoPath,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, Object?>> currentRows = await db.query(
      _petsTable,
      where: 'id = ?',
      whereArgs: <Object?>[petId],
      limit: 1,
    );

    if (currentRows.isEmpty) {
      return;
    }

    final PetRecord current = PetRecord.fromMap(currentRows.first);

    await db.update(
      _petsTable,
      <String, Object?>{
        'name': name,
        'photo_path': photoPath,
        'sync_status': current.syncStatus == 'synced' ? 'synced' : 'created',
        'last_modified_at': now,
        'remote_id': current.remoteId,
        'updated_at': now,
        'needs_sync': 1,
      },
      where: 'id = ?',
      whereArgs: <Object?>[petId],
    );
  }

  Future<void> deletePet({required int petId}) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      _petsTable,
      <String, Object?>{
        'sync_status': 'deleted',
        'last_modified_at': now,
        'updated_at': now,
        'needs_sync': 1,
      },
      where: 'id = ?',
      whereArgs: <Object?>[petId],
    );
  }

  Future<List<RouteRecord>> getRoutes() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _routesTable,
      where: 'sync_status != ?',
      whereArgs: <Object?>['deleted'],
      orderBy: 'created_at ASC',
    );
    return rows.map(RouteRecord.fromMap).toList(growable: false);
  }

  Future<int> addRoute({
    required String name,
    required List<RoutePoint> points,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final RouteRecord dummy = RouteRecord(
      id: 0,
      remoteId: null,
      name: name,
      points: points,
      syncStatus: 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );
    final Map<String, Object?> data = dummy.toMap()..remove('id');
    return db.insert(_routesTable, data);
  }

  Future<int> getRoutesCount() async {
    final Database db = await database;
    final int? result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $_routesTable WHERE sync_status != ?',
        <Object?>['deleted'],
      ),
    );
    return result ?? 0;
  }

  Future<void> deleteRoute({required int routeId}) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      _routesTable,
      <String, Object?>{
        'sync_status': 'deleted',
        'last_modified_at': now,
        'updated_at': now,
        'needs_sync': 1,
      },
      where: 'id = ?',
      whereArgs: <Object?>[routeId],
    );
  }

  Future<void> updateRoute({
    required int routeId,
    required String name,
    required List<RoutePoint> points,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, Object?>> currentRows = await db.query(
      _routesTable,
      where: 'id = ?',
      whereArgs: <Object?>[routeId],
      limit: 1,
    );

    if (currentRows.isEmpty) {
      return;
    }

    final RouteRecord current = RouteRecord.fromMap(currentRows.first);
    final RouteRecord updated = RouteRecord(
      id: routeId,
      remoteId: current.remoteId,
      name: name,
      points: points,
      syncStatus: current.syncStatus == 'synced' ? 'synced' : 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(now),
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );
    final Map<String, Object?> map = updated.toMap();
    await db.update(
      _routesTable,
      <String, Object?>{
        'name': map['name'],
        'points_json': map['points_json'],
        'sync_status': map['sync_status'],
        'last_modified_at': map['last_modified_at'],
        'updated_at': map['updated_at'],
        'needs_sync': 1,
      },
      where: 'id = ?',
      whereArgs: <Object?>[routeId],
    );
  }

  Future<List<HazardReportRecord>> getHazardReports() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _hazardsTable,
      orderBy: 'reported_at DESC',
    );
    return rows.map(HazardReportRecord.fromMap).toList(growable: false);
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
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final String localUuid = _generateLocalUuid();

    final HazardReportRecord draft = HazardReportRecord(
      id: 0,
      localUuid: localUuid,
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

    final Map<String, Object?> map = draft.toMap()..remove('id');
    return db.insert(_hazardsTable, map);
  }

  Future<void> addCommentToHazard({
    required int hazardId,
    required HazardCommentRecord comment,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _hazardsTable,
      where: 'id = ?',
      whereArgs: <Object?>[hazardId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return;
    }

    final HazardReportRecord current = HazardReportRecord.fromMap(rows.first);
    final List<HazardCommentRecord> updatedComments = <HazardCommentRecord>[
      ...current.comments,
      comment,
    ];
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      _hazardsTable,
      <String, Object?>{
        'comments_json': jsonEncode(
          updatedComments.map((HazardCommentRecord c) => c.toMap()).toList(),
        ),
        'updated_at': now,
        'last_modified_at': now,
        'needs_sync': 1,
      },
      where: 'id = ?',
      whereArgs: <Object?>[hazardId],
    );
  }

  Future<void> addCommentToLostPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _appendCommentToReportTable(
      tableName: _lostPetReportsTable,
      reportId: reportId,
      currentComments: (Map<String, Object?> row) =>
          LostPetReportRecord.fromMap(row).comments,
      comment: comment,
    );
  }

  Future<void> addCommentToFoundPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _appendCommentToReportTable(
      tableName: _foundPetReportsTable,
      reportId: reportId,
      currentComments: (Map<String, Object?> row) =>
          FoundPetReportRecord.fromMap(row).comments,
      comment: comment,
    );
  }

  Future<void> addCommentToGenericReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _appendCommentToReportTable(
      tableName: _genericReportsTable,
      reportId: reportId,
      currentComments: (Map<String, Object?> row) =>
          GenericReportRecord.fromMap(row).comments,
      comment: comment,
    );
  }

  Future<List<HazardReportRecord>> getHazardReportsNeedingSync() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _hazardsTable,
      where: 'needs_sync = ?',
      whereArgs: <Object?>[1],
      orderBy: 'last_modified_at ASC',
    );
    return rows.map(HazardReportRecord.fromMap).toList(growable: false);
  }

  Future<void> markHazardAsSynced({
    required String localUuid,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _hazardsTable,
      <String, Object?>{
        'needs_sync': 0,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at':
            (lastModifiedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'updated_at': now,
      },
      where: 'local_uuid = ?',
      whereArgs: <Object?>[localUuid],
    );
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
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _hazardsTable,
      where: 'local_uuid = ? OR remote_id = ?',
      whereArgs: <Object?>[localUuid, remoteId],
      limit: 1,
    );

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int remoteMs = remoteLastModifiedAt.millisecondsSinceEpoch;

    if (rows.isEmpty) {
      await db.insert(_hazardsTable, <String, Object?>{
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'incident_latitude': incidentLatitude,
        'incident_longitude': incidentLongitude,
        'impact_radius_meters': impactRadiusMeters,
        'category_code': categoryCode,
        'narrative_description': narrativeDescription,
        'reported_at': reportedAt.millisecondsSinceEpoch,
        'estimated_duration_code': estimatedDurationCode,
        'risk_level_code': riskLevelCode,
        'evidence_photo_url': evidencePhotoUrl,
        'reported_by_username': reportedByUsername,
        'comments_json': commentsJson ?? '[]',
        'created_at': remoteMs,
        'updated_at': remoteMs,
        'needs_sync': 0,
      });
      return;
    }

    final HazardReportRecord local = HazardReportRecord.fromMap(rows.first);

    if (local.needsSync && local.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    final String? resolvedEvidencePhoto = _preferOfflineImageSource(
      currentSource: local.evidencePhotoUrl,
      remoteSource: evidencePhotoUrl,
    );

    await db.update(
      _hazardsTable,
      <String, Object?>{
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'incident_latitude': incidentLatitude,
        'incident_longitude': incidentLongitude,
        'impact_radius_meters': impactRadiusMeters,
        'category_code': categoryCode,
        'narrative_description': narrativeDescription,
        'reported_at': reportedAt.millisecondsSinceEpoch,
        'estimated_duration_code': estimatedDurationCode,
        'risk_level_code': riskLevelCode,
        'evidence_photo_url': resolvedEvidencePhoto,
        'reported_by_username': reportedByUsername,
        'comments_json': commentsJson ?? local.toMap()['comments_json'],
        'updated_at': now,
        'needs_sync': 0,
      },
      where: 'id = ?',
      whereArgs: <Object?>[local.id],
    );
  }

  Future<List<LostPetReportRecord>> getLostPetReports() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _lostPetReportsTable,
      orderBy: 'disappearance_date DESC',
    );
    return rows.map(LostPetReportRecord.fromMap).toList(growable: false);
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
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final LostPetReportRecord draft = LostPetReportRecord(
      id: 0,
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
    final Map<String, Object?> map = draft.toMap()..remove('id');
    return db.insert(_lostPetReportsTable, map);
  }

  Future<List<LostPetReportRecord>> getLostPetReportsNeedingSync() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _lostPetReportsTable,
      where: 'needs_sync = ?',
      whereArgs: <Object?>[1],
      orderBy: 'last_modified_at ASC',
    );
    return rows.map(LostPetReportRecord.fromMap).toList(growable: false);
  }

  Future<void> markLostPetReportAsSynced({
    required String localUuid,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _lostPetReportsTable,
      <String, Object?>{
        'needs_sync': 0,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at':
            (lastModifiedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'updated_at': now,
      },
      where: 'local_uuid = ?',
      whereArgs: <Object?>[localUuid],
    );
  }

  Future<void> upsertLostPetReportFromRemote({
    required String localUuid,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required double lastSeenLatitude,
    required double lastSeenLongitude,
    required String name,
    required String details,
    required DateTime disappearanceDate,
    required String? photoUrl,
    required String? phone,
    String? commentsJson,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _lostPetReportsTable,
      where: 'local_uuid = ? OR remote_id = ?',
      whereArgs: <Object?>[localUuid, remoteId],
      limit: 1,
    );
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int remoteMs = remoteLastModifiedAt.millisecondsSinceEpoch;

    if (rows.isEmpty) {
      await db.insert(_lostPetReportsTable, <String, Object?>{
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'last_seen_latitude': lastSeenLatitude,
        'last_seen_longitude': lastSeenLongitude,
        'name': name,
        'details': details,
        'disappearance_date': disappearanceDate.millisecondsSinceEpoch,
        'photo_url': photoUrl,
        'phone': phone,
        'comments_json': commentsJson ?? '[]',
        'created_at': remoteMs,
        'updated_at': remoteMs,
        'needs_sync': 0,
      });
      return;
    }

    final LostPetReportRecord local = LostPetReportRecord.fromMap(rows.first);
    if (local.needsSync && local.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    await db.update(
      _lostPetReportsTable,
      <String, Object?>{
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'last_seen_latitude': lastSeenLatitude,
        'last_seen_longitude': lastSeenLongitude,
        'name': name,
        'details': details,
        'disappearance_date': disappearanceDate.millisecondsSinceEpoch,
        'photo_url': _preferOfflineImageSource(
          currentSource: local.photoUrl,
          remoteSource: photoUrl,
        ),
        'phone': phone,
        'comments_json': commentsJson ?? local.toMap()['comments_json'],
        'updated_at': now,
        'needs_sync': 0,
      },
      where: 'id = ?',
      whereArgs: <Object?>[local.id],
    );
  }

  Future<List<FoundPetReportRecord>> getFoundPetReports() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _foundPetReportsTable,
      orderBy: 'found_date DESC',
    );
    return rows.map(FoundPetReportRecord.fromMap).toList(growable: false);
  }

  Future<int> addFoundPetReport({
    required double latitude,
    required double longitude,
    required String details,
    required DateTime foundDate,
    String? photoUrl,
    String? phone,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final FoundPetReportRecord draft = FoundPetReportRecord(
      id: 0,
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
    final Map<String, Object?> map = draft.toMap()..remove('id');
    return db.insert(_foundPetReportsTable, map);
  }

  Future<List<FoundPetReportRecord>> getFoundPetReportsNeedingSync() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _foundPetReportsTable,
      where: 'needs_sync = ?',
      whereArgs: <Object?>[1],
      orderBy: 'last_modified_at ASC',
    );
    return rows.map(FoundPetReportRecord.fromMap).toList(growable: false);
  }

  Future<void> markFoundPetReportAsSynced({
    required String localUuid,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _foundPetReportsTable,
      <String, Object?>{
        'needs_sync': 0,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at':
            (lastModifiedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'updated_at': now,
      },
      where: 'local_uuid = ?',
      whereArgs: <Object?>[localUuid],
    );
  }

  Future<void> upsertFoundPetReportFromRemote({
    required String localUuid,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required double latitude,
    required double longitude,
    required String details,
    required DateTime foundDate,
    required String? photoUrl,
    required String? phone,
    String? commentsJson,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _foundPetReportsTable,
      where: 'local_uuid = ? OR remote_id = ?',
      whereArgs: <Object?>[localUuid, remoteId],
      limit: 1,
    );
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int remoteMs = remoteLastModifiedAt.millisecondsSinceEpoch;

    if (rows.isEmpty) {
      await db.insert(_foundPetReportsTable, <String, Object?>{
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'latitude': latitude,
        'longitude': longitude,
        'details': details,
        'found_date': foundDate.millisecondsSinceEpoch,
        'photo_url': photoUrl,
        'phone': phone,
        'comments_json': commentsJson ?? '[]',
        'created_at': remoteMs,
        'updated_at': remoteMs,
        'needs_sync': 0,
      });
      return;
    }

    final FoundPetReportRecord local = FoundPetReportRecord.fromMap(rows.first);
    if (local.needsSync && local.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    await db.update(
      _foundPetReportsTable,
      <String, Object?>{
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'latitude': latitude,
        'longitude': longitude,
        'details': details,
        'found_date': foundDate.millisecondsSinceEpoch,
        'photo_url': _preferOfflineImageSource(
          currentSource: local.photoUrl,
          remoteSource: photoUrl,
        ),
        'phone': phone,
        'comments_json': commentsJson ?? local.toMap()['comments_json'],
        'updated_at': now,
        'needs_sync': 0,
      },
      where: 'id = ?',
      whereArgs: <Object?>[local.id],
    );
  }

  Future<List<GenericReportRecord>> getGenericReports() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _genericReportsTable,
      orderBy: 'reported_date DESC',
    );
    return rows.map(GenericReportRecord.fromMap).toList(growable: false);
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
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final GenericReportRecord draft = GenericReportRecord(
      id: 0,
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
    final Map<String, Object?> map = draft.toMap()..remove('id');
    return db.insert(_genericReportsTable, map);
  }

  Future<List<GenericReportRecord>> getGenericReportsNeedingSync() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _genericReportsTable,
      where: 'needs_sync = ?',
      whereArgs: <Object?>[1],
      orderBy: 'last_modified_at ASC',
    );
    return rows.map(GenericReportRecord.fromMap).toList(growable: false);
  }

  Future<void> markGenericReportAsSynced({
    required String localUuid,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _genericReportsTable,
      <String, Object?>{
        'needs_sync': 0,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at':
            (lastModifiedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'updated_at': now,
      },
      where: 'local_uuid = ?',
      whereArgs: <Object?>[localUuid],
    );
  }

  Future<void> upsertGenericReportFromRemote({
    required String localUuid,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required double latitude,
    required double longitude,
    required String description,
    required DateTime reportedDate,
    required String riskLevelCode,
    required int impactRadiusMeters,
    required String? photoUrl,
    String? commentsJson,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _genericReportsTable,
      where: 'local_uuid = ? OR remote_id = ?',
      whereArgs: <Object?>[localUuid, remoteId],
      limit: 1,
    );
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int remoteMs = remoteLastModifiedAt.millisecondsSinceEpoch;

    if (rows.isEmpty) {
      await db.insert(_genericReportsTable, <String, Object?>{
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'reported_date': reportedDate.millisecondsSinceEpoch,
        'risk_level_code': riskLevelCode,
        'impact_radius_meters': impactRadiusMeters,
        'photo_url': photoUrl,
        'comments_json': commentsJson ?? '[]',
        'created_at': remoteMs,
        'updated_at': remoteMs,
        'needs_sync': 0,
      });
      return;
    }

    final GenericReportRecord local = GenericReportRecord.fromMap(rows.first);
    if (local.needsSync && local.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    await db.update(
      _genericReportsTable,
      <String, Object?>{
        'local_uuid': localUuid,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'reported_date': reportedDate.millisecondsSinceEpoch,
        'risk_level_code': riskLevelCode,
        'impact_radius_meters': impactRadiusMeters,
        'photo_url': _preferOfflineImageSource(
          currentSource: local.photoUrl,
          remoteSource: photoUrl,
        ),
        'comments_json': commentsJson ?? local.toMap()['comments_json'],
        'updated_at': now,
        'needs_sync': 0,
      },
      where: 'id = ?',
      whereArgs: <Object?>[local.id],
    );
  }

  Future<List<PetRecord>> getPetsNeedingSync() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _petsTable,
      where: 'needs_sync = ?',
      whereArgs: <Object?>[1],
      orderBy: 'last_modified_at ASC',
    );
    return rows.map(PetRecord.fromMap).toList(growable: false);
  }

  Future<void> markPetAsSynced({
    required int petId,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _petsTable,
      <String, Object?>{
        'needs_sync': 0,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at':
            (lastModifiedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object?>[petId],
    );
  }

  Future<void> upsertPetFromRemote({
    required String localIdString,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required String name,
    required String? photoPath,
  }) async {
    final Database db = await database;
    List<Map<String, Object?>> rows = await db.query(
      _petsTable,
      where: 'remote_id = ?',
      whereArgs: <Object?>[remoteId],
      limit: 1,
    );

    if (rows.isEmpty && localIdString.startsWith('pt_')) {
      final List<String> parts = localIdString.split('_');
      if (parts.length >= 3) {
        final int? parsedId = int.tryParse(parts[1]);
        final int? parsedCreatedAt = int.tryParse(parts[2]);
        if (parsedId != null && parsedCreatedAt != null) {
          rows = await db.query(
            _petsTable,
            where: 'id = ? AND created_at = ?',
            whereArgs: <Object?>[parsedId, parsedCreatedAt],
            limit: 1,
          );
        }
      }
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int remoteMs = remoteLastModifiedAt.millisecondsSinceEpoch;

    if (rows.isEmpty) {
      await db.insert(_petsTable, <String, Object?>{
        'remote_id': remoteId,
        'name': name,
        'photo_path': photoPath,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'synced_at': remoteMs,
        'created_at': remoteMs,
        'updated_at': remoteMs,
        'needs_sync': 0,
      });
      return;
    }

    final PetRecord local = PetRecord.fromMap(rows.first);
    if (local.needsSync && local.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    final String? resolvedPhotoPath = _preferOfflineImageSource(
      currentSource: local.photoPath,
      remoteSource: photoPath,
    );

    await db.update(
      _petsTable,
      <String, Object?>{
        'remote_id': remoteId,
        'name': name,
        'photo_path': resolvedPhotoPath,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'synced_at': now,
        'updated_at': now,
        'needs_sync': 0,
      },
      where: 'id = ?',
      whereArgs: <Object?>[local.id],
    );
  }

  Future<List<RouteRecord>> getRoutesNeedingSync() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _routesTable,
      where: 'needs_sync = ?',
      whereArgs: <Object?>[1],
      orderBy: 'last_modified_at ASC',
    );
    return rows.map(RouteRecord.fromMap).toList(growable: false);
  }

  Future<void> markRouteAsSynced({
    required int routeId,
    String? remoteId,
    String syncStatus = 'synced',
    DateTime? lastModifiedAt,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      _routesTable,
      <String, Object?>{
        'needs_sync': 0,
        'remote_id': remoteId,
        'sync_status': syncStatus,
        'last_modified_at':
            (lastModifiedAt ?? DateTime.now()).millisecondsSinceEpoch,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object?>[routeId],
    );
  }

  Future<void> upsertRouteFromRemote({
    required String localIdString,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required String name,
    required List<RoutePoint> points,
  }) async {
    final Database db = await database;
    List<Map<String, Object?>> rows = await db.query(
      _routesTable,
      where: 'remote_id = ?',
      whereArgs: <Object?>[remoteId],
      limit: 1,
    );

    if (rows.isEmpty && localIdString.startsWith('rt_')) {
      final List<String> parts = localIdString.split('_');
      if (parts.length >= 3) {
        final int? parsedId = int.tryParse(parts[1]);
        final int? parsedCreatedAt = int.tryParse(parts[2]);
        if (parsedId != null && parsedCreatedAt != null) {
          rows = await db.query(
            _routesTable,
            where: 'id = ? AND created_at = ?',
            whereArgs: <Object?>[parsedId, parsedCreatedAt],
            limit: 1,
          );
        }
      }
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int remoteMs = remoteLastModifiedAt.millisecondsSinceEpoch;
    final String pointsJson = jsonEncode(
      points.map((RoutePoint p) => p.toMap()).toList(),
    );

    if (rows.isEmpty) {
      await db.insert(_routesTable, <String, Object?>{
        'remote_id': remoteId,
        'name': name,
        'points_json': pointsJson,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'synced_at': remoteMs,
        'created_at': remoteMs,
        'updated_at': remoteMs,
        'needs_sync': 0,
      });
      return;
    }

    final RouteRecord local = RouteRecord.fromMap(rows.first);
    if (local.needsSync && local.lastModifiedAt.isAfter(remoteLastModifiedAt)) {
      return;
    }

    await db.update(
      _routesTable,
      <String, Object?>{
        'remote_id': remoteId,
        'name': name,
        'points_json': pointsJson,
        'sync_status': syncStatus,
        'last_modified_at': remoteMs,
        'synced_at': now,
        'updated_at': now,
        'needs_sync': 0,
      },
      where: 'id = ?',
      whereArgs: <Object?>[local.id],
    );
  }

  String _generateLocalUuid([String prefix = 'hz']) {
    final int now = DateTime.now().microsecondsSinceEpoch;
    final int randomPart = (Random().nextDouble() * 0xFFFFFFFF).floor();
    return '$prefix-$now-${randomPart.toRadixString(16)}';
  }

  Future<void> markUserDataForFutureSync() async {
    await database;
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

    if (_isRemoteUrl(currentSource)) {
      return remoteSource;
    }

    // Keep local/base64 source if still available so the app keeps rendering images offline.
    if (currentSource.startsWith('data:image')) {
      return currentSource;
    }

    final File localFile = File(currentSource);
    if (localFile.existsSync()) {
      return currentSource;
    }

    return remoteSource;
  }

  bool _isRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Future<void> _appendCommentToReportTable({
    required String tableName,
    required int reportId,
    required List<ReportCommentRecord> Function(Map<String, Object?> row)
    currentComments,
    required ReportCommentRecord comment,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: <Object?>[reportId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return;
    }

    final List<ReportCommentRecord> updatedComments = <ReportCommentRecord>[
      ...currentComments(rows.first),
      comment,
    ];
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      tableName,
      <String, Object?>{
        'comments_json': jsonEncode(
          updatedComments.map((ReportCommentRecord c) => c.toMap()).toList(),
        ),
        'updated_at': now,
        'last_modified_at': now,
        'needs_sync': 1,
      },
      where: 'id = ?',
      whereArgs: <Object?>[reportId],
    );
  }
}
