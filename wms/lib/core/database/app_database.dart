import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get type => text()();
  TextColumn get status => text()();
  TextColumn get priority => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get locationData => text()(); // JSON string
  TextColumn get details => text()(); // JSON string
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get quantity => integer()();
  TextColumn get category => text()();
  TextColumn get sku => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Inventory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productId => text()();
  TextColumn get zone => text()();
  TextColumn get floor => text()();
  TextColumn get slot => text()();
  IntColumn get stockQuantity => integer()();
  DateTimeColumn get lastUpdated => dateTime()();
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()(); // 'CREATE', 'UPDATE', 'DELETE'
  TextColumn get payload => text()(); // JSON string
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get processed => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Tasks, Products, Inventory, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
