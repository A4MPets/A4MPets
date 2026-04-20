import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/local_user_profile.dart';
import '../models/hazard_report_record.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';

class LocalDatabaseManager {
  LocalDatabaseManager();

  static const String _databaseName = 'a4mpets_local.db';
  static const String _userTable = 'local_user_profile';
  static const String _petsTable = 'pets';
  static const String _routesTable = 'routes';
  static const String _hazardsTable = 'hazard_reports';

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
      version: 7,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_userTable (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL,
            avatar_path TEXT,
            is_authenticated INTEGER NOT NULL DEFAULT 0,
            backend_user_id INTEGER,
            email TEXT,
            access_token TEXT,
            last_synced_at INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE $_petsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id TEXT,
            name TEXT NOT NULL,
            photo_path TEXT,
            sync_status TEXT NOT NULL DEFAULT 'created',
            last_modified_at INTEGER NOT NULL,
            synced_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            needs_sync INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE $_routesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id TEXT,
            name TEXT NOT NULL,
            points_json TEXT NOT NULL DEFAULT '[]',
            sync_status TEXT NOT NULL DEFAULT 'created',
            last_modified_at INTEGER NOT NULL,
            synced_at INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            needs_sync INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE $_hazardsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            local_uuid TEXT NOT NULL UNIQUE,
            remote_id TEXT,
            sync_status TEXT NOT NULL DEFAULT 'created',
            last_modified_at INTEGER NOT NULL,
            incident_latitude REAL NOT NULL,
            incident_longitude REAL NOT NULL,
            impact_radius_meters INTEGER NOT NULL,
            category_code TEXT NOT NULL,
            narrative_description TEXT NOT NULL,
            reported_at INTEGER NOT NULL,
            estimated_duration_code TEXT NOT NULL,
            risk_level_code TEXT NOT NULL,
            evidence_photo_url TEXT,
            reported_by_username TEXT NOT NULL DEFAULT 'Anónimo',
            comments_json TEXT NOT NULL DEFAULT '[]',
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            needs_sync INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE route_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            waypoints_hash TEXT NOT NULL UNIQUE,
            polyline_json TEXT NOT NULL,
            distance_meters REAL NOT NULL,
            duration_seconds REAL NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_routesTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              points_json TEXT NOT NULL DEFAULT '[]',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              needs_sync INTEGER NOT NULL DEFAULT 1
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_hazardsTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              local_uuid TEXT NOT NULL UNIQUE,
              remote_id TEXT,
              sync_status TEXT NOT NULL DEFAULT 'created',
              last_modified_at INTEGER NOT NULL,
              incident_latitude REAL NOT NULL,
              incident_longitude REAL NOT NULL,
              impact_radius_meters INTEGER NOT NULL,
              category_code TEXT NOT NULL,
              narrative_description TEXT NOT NULL,
              reported_at INTEGER NOT NULL,
              estimated_duration_code TEXT NOT NULL,
              risk_level_code TEXT NOT NULL,
              evidence_photo_url TEXT,
              reported_by_username TEXT NOT NULL DEFAULT 'Anónimo',
              comments_json TEXT NOT NULL DEFAULT '[]',
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              needs_sync INTEGER NOT NULL DEFAULT 1
            )
          ''');
        }

        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE $_hazardsTable ADD COLUMN reported_by_username TEXT NOT NULL DEFAULT "Anónimo"',
          );
          await db.execute(
            'ALTER TABLE $_hazardsTable ADD COLUMN comments_json TEXT NOT NULL DEFAULT "[]"',
          );
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS route_cache (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              waypoints_hash TEXT NOT NULL UNIQUE,
              polyline_json TEXT NOT NULL,
              distance_meters REAL NOT NULL,
              duration_seconds REAL NOT NULL,
              cached_at INTEGER NOT NULL
            )
          ''');
        }

        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE $_hazardsTable ADD COLUMN local_uuid TEXT',
          );
          await db.execute(
            'ALTER TABLE $_hazardsTable ADD COLUMN remote_id TEXT',
          );
          await db.execute(
            'ALTER TABLE $_hazardsTable ADD COLUMN sync_status TEXT NOT NULL DEFAULT "created"',
          );
          await db.execute(
            'ALTER TABLE $_hazardsTable ADD COLUMN last_modified_at INTEGER',
          );
          await db.execute(
            'UPDATE $_hazardsTable SET local_uuid = COALESCE(local_uuid, "legacy-" || id)',
          );
          await db.execute(
            'UPDATE $_hazardsTable SET last_modified_at = COALESCE(last_modified_at, updated_at, created_at)',
          );
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_hazards_local_uuid ON $_hazardsTable(local_uuid)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_hazards_remote_id ON $_hazardsTable(remote_id)',
          );
        }

        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE $_userTable ADD COLUMN backend_user_id INTEGER',
          );
          await db.execute('ALTER TABLE $_userTable ADD COLUMN email TEXT');
          await db.execute(
            'ALTER TABLE $_userTable ADD COLUMN access_token TEXT',
          );

          await db.execute('ALTER TABLE $_petsTable ADD COLUMN remote_id TEXT');
          await db.execute(
            'ALTER TABLE $_petsTable ADD COLUMN sync_status TEXT NOT NULL DEFAULT "created"',
          );
          await db.execute(
            'ALTER TABLE $_petsTable ADD COLUMN last_modified_at INTEGER',
          );
          await db.execute(
            'ALTER TABLE $_petsTable ADD COLUMN synced_at INTEGER',
          );

          await db.execute(
            'ALTER TABLE $_routesTable ADD COLUMN remote_id TEXT',
          );
          await db.execute(
            'ALTER TABLE $_routesTable ADD COLUMN sync_status TEXT NOT NULL DEFAULT "created"',
          );
          await db.execute(
            'ALTER TABLE $_routesTable ADD COLUMN last_modified_at INTEGER',
          );
          await db.execute(
            'ALTER TABLE $_routesTable ADD COLUMN synced_at INTEGER',
          );
        }
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
    final List<Map<String, Object?>> rows = await db.query(
      _userTable,
      limit: 1,
    );

    return LocalUserProfile.fromMap(rows.first);
  }

  Future<void> saveLocalUserProfile(LocalUserProfile profile) async {
    final Database db = await database;
    await db.insert(
      _userTable,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearUserSessionData() async {
    final Database db = await database;
    await db.delete(_petsTable);
    await db.delete(_routesTable);
    await db.update(
      _userTable,
      LocalUserProfile.guest().toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[LocalUserProfile.guest().id],
    );
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
        'evidence_photo_url': evidencePhotoUrl,
        'reported_by_username': reportedByUsername,
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
    required int localId,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required String name,
    required String? photoPath,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _petsTable,
      where: 'remote_id = ? OR id = ?',
      whereArgs: <Object?>[remoteId, localId],
      limit: 1,
    );

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

    await db.update(
      _petsTable,
      <String, Object?>{
        'remote_id': remoteId,
        'name': name,
        'photo_path': photoPath,
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
    required int localId,
    required String? remoteId,
    required String syncStatus,
    required DateTime remoteLastModifiedAt,
    required String name,
    required List<RoutePoint> points,
  }) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _routesTable,
      where: 'remote_id = ? OR id = ?',
      whereArgs: <Object?>[remoteId, localId],
      limit: 1,
    );

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

  String _generateLocalUuid() {
    final int now = DateTime.now().microsecondsSinceEpoch;
    final int randomPart = (Random().nextDouble() * 0xFFFFFFFF).floor();
    return 'hz-$now-${randomPart.toRadixString(16)}';
  }

  Future<void> markUserDataForFutureSync() async {
    await database;
  }
}
