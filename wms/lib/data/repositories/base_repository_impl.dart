import 'package:sqflite/sqflite.dart';
import 'package:wms/data/database/database_helper.dart';
import 'package:wms/domain/interfaces/base_repository.dart';

abstract class BaseRepositoryImpl<T> implements BaseRepository<T> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String tableName;

  BaseRepositoryImpl(this.tableName);

  // Abstract method to map Map<String, dynamic> to T
  T fromMap(Map<String, dynamic> map);

  // Abstract method to map T to Map<String, dynamic>
  Map<String, dynamic> toMap(T item);

  @override
  Future<List<T>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => fromMap(maps[i]));
  }

  @override
  Future<T?> getById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> insert(T item) async {
    final db = await _dbHelper.database;
    await db.insert(
      tableName,
      toMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(T item) async {
    final db = await _dbHelper.database;
    final map = toMap(item);
    await db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [map['id']],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
