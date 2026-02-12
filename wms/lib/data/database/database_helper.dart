import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the directory where the app supports storing data
    // Usually standard for mobile apps (Documents directory)
    // We are placing the DB file here.
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'wms_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  // Create tables
  Future<void> _createDb(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        role TEXT,
        token TEXT
      )
    ''');

    // Tasks/Instructions Table
    // instructions: Text description of what to do
    // location: JSON or string representation of the target location
    // status: pending, in_progress, completed, approved
    // ai_path: JSON string for the optimized path points
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        status TEXT,
        assigned_to TEXT,
        location_data TEXT,
        ai_path_data TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    
    // Offline Queue / Sync Table (Optional, or can be part of tasks)
    await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT, -- 'CREATE', 'UPDATE', 'DELETE'
        table_name TEXT,
        data TEXT,
        created_at TEXT
      )
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    // Handle migration logic here
    if (oldVersion < 2) {
      // await db.execute("ALTER TABLE ...");
    }
  }
}
