import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:frontend/services/local_database_schema.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('ensureCurrentSchema repairs partial v11 tables', () async {
    final Database db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
    );
    addTearDown(db.close);

    await db.execute('''
      CREATE TABLE pets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        name TEXT,
        photo_path TEXT,
        sync_status TEXT NOT NULL DEFAULT 'created',
        last_modified_at INTEGER,
        synced_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        needs_sync INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE lost_pet_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_uuid TEXT NOT NULL UNIQUE,
        remote_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'created',
        last_modified_at INTEGER NOT NULL,
        last_seen_latitude REAL NOT NULL,
        last_seen_longitude REAL NOT NULL,
        details TEXT NOT NULL,
        disappearance_date INTEGER NOT NULL,
        photo_url TEXT,
        phone TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        needs_sync INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE found_pet_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_uuid TEXT NOT NULL UNIQUE,
        remote_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'created',
        last_modified_at INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        details TEXT NOT NULL,
        found_date INTEGER NOT NULL,
        photo_url TEXT,
        phone TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        needs_sync INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE generic_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_uuid TEXT NOT NULL UNIQUE,
        remote_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'created',
        last_modified_at INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT NOT NULL,
        reported_date INTEGER NOT NULL,
        risk_level_code TEXT NOT NULL,
        photo_url TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        needs_sync INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await LocalDatabaseSchema.ensureCurrentSchema(
      db: db,
      petsTable: 'pets',
      lostPetReportsTable: 'lost_pet_reports',
      foundPetReportsTable: 'found_pet_reports',
      genericReportsTable: 'generic_reports',
    );

    Future<Set<String>> columns(String table) async {
      final rows = await db.rawQuery('PRAGMA table_info($table)');
      return rows.map((row) => row['name']!.toString()).toSet();
    }

    expect(
      await columns('pets'),
      containsAll(<String>[
        'local_uuid',
        'total_walks',
        'registered_at',
        'adoption_date',
        'birth_date',
        'status',
        'is_ownerless',
      ]),
    );
    expect(
      await columns('lost_pet_reports'),
      containsAll(<String>['comments_json', 'pet_id', 'pet_local_uuid']),
    );
    expect(
      await columns('found_pet_reports'),
      containsAll(<String>[
        'comments_json',
        'pet_id',
        'pet_local_uuid',
        'matched_lost_pet_report_id',
      ]),
    );
    expect(
      await columns('generic_reports'),
      containsAll(<String>['comments_json', 'impact_radius_meters']),
    );
  });
}
