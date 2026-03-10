import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/local_user_profile.dart';
import '../models/pet_record.dart';

class LocalDatabaseManager {
  LocalDatabaseManager();

  static const String _databaseName = 'a4mpets_local.db';
  static const String _userTable = 'local_user_profile';
  static const String _petsTable = 'pets';

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
      version: 1,
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

  Future<void> markUserDataForFutureSync() async {
    await database;
  }
}
