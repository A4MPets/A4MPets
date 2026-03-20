import 'dart:convert';
import 'dart:io';

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
      version: 5,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_userTable (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL,
            avatar_path TEXT,
            is_authenticated INTEGER NOT NULL DEFAULT 0,
            last_synced_at INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE $_petsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            photo_path TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            needs_sync INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE $_routesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            points_json TEXT NOT NULL DEFAULT '[]',
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            needs_sync INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE $_hazardsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
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

  Future<List<PetRecord>> getPets() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _petsTable,
      orderBy: 'created_at ASC',
    );

    return rows.map(PetRecord.fromMap).toList(growable: false);
  }

  Future<int> addPet({
    required String name,
    String? photoPath,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;

    return db.insert(
      _petsTable,
      <String, Object?>{
        'name': name,
        'photo_path': photoPath,
        'created_at': now,
        'updated_at': now,
        'needs_sync': 1,
      },
    );
  }

  Future<int> getPetsCount() async {
    final Database db = await database;
    final int? result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_petsTable'),
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

    await db.update(
      _petsTable,
      <String, Object?>{
        'name': name,
        'photo_path': photoPath,
        'updated_at': now,
        'needs_sync': 1,
      },
      where: 'id = ?',
      whereArgs: <Object?>[petId],
    );
  }

  Future<void> deletePet({required int petId}) async {
    final Database db = await database;
    await db.delete(
      _petsTable,
      where: 'id = ?',
      whereArgs: <Object?>[petId],
    );
  }

  Future<List<RouteRecord>> getRoutes() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      _routesTable,
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
      name: name,
      points: points,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      needsSync: true,
    );
    final Map<String, Object?> data = dummy.toMap()
      ..remove('id');
    return db.insert(_routesTable, data);
  }

  Future<int> getRoutesCount() async {
    final Database db = await database;
    final int? result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_routesTable'),
    );
    return result ?? 0;
  }

  Future<void> deleteRoute({required int routeId}) async {
    final Database db = await database;
    await db.delete(
      _routesTable,
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
    final RouteRecord updated = RouteRecord(
      id: routeId,
      name: name,
      points: points,
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

    final HazardReportRecord draft = HazardReportRecord(
      id: 0,
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
        'needs_sync': 1,
      },
      where: 'id = ?',
      whereArgs: <Object?>[hazardId],
    );
  }

  Future<void> markUserDataForFutureSync() async {
    await database;
  }
}
