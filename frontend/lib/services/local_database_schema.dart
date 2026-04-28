import 'package:sqflite/sqflite.dart';

class LocalDatabaseSchema {
  const LocalDatabaseSchema._();

  static Future<void> createTables({
    required Database db,
    required String userTable,
    required String petsTable,
    required String routesTable,
    required String hazardsTable,
    required String lostPetReportsTable,
    required String foundPetReportsTable,
    required String genericReportsTable,
  }) async {
    await db.execute('''
      CREATE TABLE $userTable (
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
      CREATE TABLE $petsTable (
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
      CREATE TABLE $routesTable (
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
      CREATE TABLE $hazardsTable (
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
        reported_by_username TEXT NOT NULL DEFAULT 'Anonimo',
        comments_json TEXT NOT NULL DEFAULT '[]',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        needs_sync INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute(_createLostPetReportsTableSql(lostPetReportsTable));
    await db.execute(_createFoundPetReportsTableSql(foundPetReportsTable));
    await db.execute(_createGenericReportsTableSql(genericReportsTable));

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
  }

  static Future<void> applyMigrations({
    required Database db,
    required int oldVersion,
    required String userTable,
    required String petsTable,
    required String routesTable,
    required String hazardsTable,
    required String lostPetReportsTable,
    required String foundPetReportsTable,
    required String genericReportsTable,
  }) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $routesTable (
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
        CREATE TABLE IF NOT EXISTS $hazardsTable (
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
          reported_by_username TEXT NOT NULL DEFAULT 'Anonimo',
          comments_json TEXT NOT NULL DEFAULT '[]',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          needs_sync INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE $hazardsTable ADD COLUMN reported_by_username TEXT NOT NULL DEFAULT "Anonimo"',
      );
      await db.execute(
        'ALTER TABLE $hazardsTable ADD COLUMN comments_json TEXT NOT NULL DEFAULT "[]"',
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
      await db.execute('ALTER TABLE $hazardsTable ADD COLUMN local_uuid TEXT');
      await db.execute('ALTER TABLE $hazardsTable ADD COLUMN remote_id TEXT');
      await db.execute(
        'ALTER TABLE $hazardsTable ADD COLUMN sync_status TEXT NOT NULL DEFAULT "created"',
      );
      await db.execute(
        'ALTER TABLE $hazardsTable ADD COLUMN last_modified_at INTEGER',
      );
      await db.execute(
        'UPDATE $hazardsTable SET local_uuid = COALESCE(local_uuid, "legacy-" || id)',
      );
      await db.execute(
        'UPDATE $hazardsTable SET last_modified_at = COALESCE(last_modified_at, updated_at, created_at)',
      );
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_hazards_local_uuid ON $hazardsTable(local_uuid)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_hazards_remote_id ON $hazardsTable(remote_id)',
      );
    }

    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE $userTable ADD COLUMN backend_user_id INTEGER',
      );
      await db.execute('ALTER TABLE $userTable ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE $userTable ADD COLUMN access_token TEXT');

      await db.execute('ALTER TABLE $petsTable ADD COLUMN remote_id TEXT');
      await db.execute(
        'ALTER TABLE $petsTable ADD COLUMN sync_status TEXT NOT NULL DEFAULT "created"',
      );
      await db.execute(
        'ALTER TABLE $petsTable ADD COLUMN last_modified_at INTEGER',
      );
      await db.execute('ALTER TABLE $petsTable ADD COLUMN synced_at INTEGER');

      await db.execute('ALTER TABLE $routesTable ADD COLUMN remote_id TEXT');
      await db.execute(
        'ALTER TABLE $routesTable ADD COLUMN sync_status TEXT NOT NULL DEFAULT "created"',
      );
      await db.execute(
        'ALTER TABLE $routesTable ADD COLUMN last_modified_at INTEGER',
      );
      await db.execute('ALTER TABLE $routesTable ADD COLUMN synced_at INTEGER');
    }

    if (oldVersion < 8) {
      await db.execute(
        'UPDATE $hazardsTable SET category_code = "possible_rabies_vectors" WHERE category_code = "aggressive_animals"',
      );
      await db.execute(
        'UPDATE $hazardsTable SET category_code = "pest_presence" WHERE category_code IN ("undefined", "unknown", "unspecified", "")',
      );
      await db.execute(
        _createLostPetReportsTableSql(lostPetReportsTable, ifNotExists: true),
      );
      await db.execute(
        _createFoundPetReportsTableSql(foundPetReportsTable, ifNotExists: true),
      );
      await db.execute(
        _createGenericReportsTableSql(genericReportsTable, ifNotExists: true),
      );
    }

    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE $genericReportsTable ADD COLUMN impact_radius_meters INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'UPDATE $genericReportsTable SET impact_radius_meters = 0 WHERE impact_radius_meters IS NULL',
      );
    }

    if (oldVersion < 10) {
      await db.execute(
        'ALTER TABLE $lostPetReportsTable ADD COLUMN comments_json TEXT NOT NULL DEFAULT "[]"',
      );
      await db.execute(
        'ALTER TABLE $foundPetReportsTable ADD COLUMN comments_json TEXT NOT NULL DEFAULT "[]"',
      );
      await db.execute(
        'ALTER TABLE $genericReportsTable ADD COLUMN comments_json TEXT NOT NULL DEFAULT "[]"',
      );
    }
  }

  static String _createLostPetReportsTableSql(
    String tableName, {
    bool ifNotExists = false,
  }) {
    final String createClause = ifNotExists
        ? 'CREATE TABLE IF NOT EXISTS'
        : 'CREATE TABLE';
    return '''
      $createClause $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_uuid TEXT NOT NULL UNIQUE,
        remote_id TEXT,
        sync_status TEXT NOT NULL DEFAULT 'created',
        last_modified_at INTEGER NOT NULL,
        last_seen_latitude REAL NOT NULL,
        last_seen_longitude REAL NOT NULL,
        name TEXT NOT NULL,
        details TEXT NOT NULL,
        disappearance_date INTEGER NOT NULL,
        photo_url TEXT,
        phone TEXT,
        comments_json TEXT NOT NULL DEFAULT '[]',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        needs_sync INTEGER NOT NULL DEFAULT 1
      )
    ''';
  }

  static String _createFoundPetReportsTableSql(
    String tableName, {
    bool ifNotExists = false,
  }) {
    final String createClause = ifNotExists
        ? 'CREATE TABLE IF NOT EXISTS'
        : 'CREATE TABLE';
    return '''
      $createClause $tableName (
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
        comments_json TEXT NOT NULL DEFAULT '[]',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        needs_sync INTEGER NOT NULL DEFAULT 1
      )
    ''';
  }

  static String _createGenericReportsTableSql(
    String tableName, {
    bool ifNotExists = false,
  }) {
    final String createClause = ifNotExists
        ? 'CREATE TABLE IF NOT EXISTS'
        : 'CREATE TABLE';
    return '''
      $createClause $tableName (
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
        impact_radius_meters INTEGER NOT NULL DEFAULT 0,
        photo_url TEXT,
        comments_json TEXT NOT NULL DEFAULT '[]',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        needs_sync INTEGER NOT NULL DEFAULT 1
      )
    ''';
  }
}
