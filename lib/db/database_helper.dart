import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('haaah_sports.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // If upgrading,  drop all tables and recreate them
    // since this is just an offline cache that can be re-fetched.
    await db.execute('DROP TABLE IF EXISTS profiles');
    await db.execute('DROP TABLE IF EXISTS teams');
    await db.execute('DROP TABLE IF EXISTS fixtures');
    await db.execute('DROP TABLE IF EXISTS posts');
    await _createDB(db, newVersion);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intNullType = 'INTEGER';
    const realType = 'REAL NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE profiles (
  id $idType,
  name $textType,
  email $textType,
  avatar_url $textNullType,
  position $textType,
  goals $intType,
  assists $intType,
  appearances $intType,
  motm $intType,
  pace $intType,
  shooting $intType,
  dribbling $intType,
  physical $intType,
  created_at $textNullType
)
''');

    await db.execute('''
CREATE TABLE teams (
  id $idType,
  name $textType,
  logo_url $textNullType,
  manager_id $textNullType,
  played $intType,
  won $intType,
  drawn $intType,
  lost $intType,
  points $intType,
  created_at $textNullType
)
''');

    await db.execute('''
CREATE TABLE venues (
  id $idType,
  name $textType,
  address $textNullType,
  lat $realType,
  lng $realType,
  price_per_hour $realType,
  created_at $textNullType
)
''');

    await db.execute('''
CREATE TABLE fixtures (
  id $idType,
  venue_id $textNullType,
  home_team_id $textType,
  away_team_id $textType,
  home_score $intNullType,
  away_score $intNullType,
  date_time $textType,
  status $textType,
  is_live $boolType,
  created_at $textNullType,
  
  -- We cache serialized JSON for related objects so we don't have to do complex SQL joins offline
  home_team_json $textNullType,
  away_team_json $textNullType,
  venue_json $textNullType
)
''');

    await db.execute('''
CREATE TABLE posts (
  post_id $idType,
  author_id $textType,
  author_name $textType,
  image_url $textType,
  caption $textNullType,
  likes_count $intType,
  comments_count $intType,
  created_at $textType
)
''');
  }

  // ── PROFILES ──
  Future<void> cacheProfile(Map<String, dynamic> row) async {
    final db = await instance.database;
    await db.insert('profiles', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getProfile(String id) async {
    final db = await instance.database;
    final maps = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // ── TEAMS ──
  Future<void> cacheTeams(List<Map<String, dynamic>> teams) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var team in teams) {
      batch.insert('teams', team, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getTeams() async {
    final db = await instance.database;
    const orderBy = 'points DESC, won DESC';
    return await db.query('teams', orderBy: orderBy);
  }

  // ── FIXTURES ──
  Future<void> cacheFixtures(List<Map<String, dynamic>> fixtures) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (var fixture in fixtures) {
      batch.insert('fixtures', fixture, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getFixtures() async {
    final db = await instance.database;
    const orderBy = 'date_time ASC';
    return await db.query('fixtures', orderBy: orderBy);
  }

  // ── POSTS ──
  Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    final db = await instance.database;
    Batch batch = db.batch();
    // Optional: Delete old ones or just replace
    await db.delete('posts');
    for (var post in posts) {
      batch.insert('posts', post, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getPosts() async {
    final db = await instance.database;
    const orderBy = 'created_at DESC';
    return await db.query('posts', orderBy: orderBy);
  }

  // ── UTILITIES ──
  Future<void> clearAll() async {
    final db = await instance.database;
    await db.delete('profiles');
    await db.delete('teams');
    await db.delete('fixtures');
    await db.delete('venues');
    await db.delete('posts');
  }
}
