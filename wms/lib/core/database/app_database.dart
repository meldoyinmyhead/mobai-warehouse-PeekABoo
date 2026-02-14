import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// 1. Local Tasks Table
class LocalTasks extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get type => text()(); // 'picking', 'storage'
  TextColumn get status => text()(); // 'pending', 'completed'
  TextColumn get data => text()(); // JSON blob of the full task
  DateTimeColumn get createdAt => dateTime()();
  
  // Sync metadata
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))(); // 'synced', 'pending_update'
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Local Inventory (Cache)
class LocalInventory extends Table {
  TextColumn get productId => text()();
  TextColumn get locationId => text()();
  IntColumn get quantity => integer()();
  
  @override
  Set<Column> get primaryKey => {productId, locationId};
}

// 3. Sync Queue (Actions to push)
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()(); // 'COMPLETE_STOP', 'CONFIRM_RECEIPT', 'AI_OVERRIDE', 'AI_APPROVE'
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

// 4. Local Pending AI Reviews (Supervisor offline: cache for review, store justification when overriding)
class LocalPendingReviews extends Table {
  TextColumn get id => text()(); // order UUID
  TextColumn get orderType => text()(); // 'preparation' | 'picking'
  TextColumn get reference => text()();
  TextColumn get data => text()(); // JSON full payload from server
  TextColumn get status => text()(); // 'pending' | 'approved' | 'overridden'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastUpdated => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 5. Local Admin Cache (Admin offline: cache users + warehouses for read; mutations queued to SyncQueue)
class LocalAdminCache extends Table {
  TextColumn get key => text()(); // 'users' | 'warehouses'
  TextColumn get data => text()(); // JSON array
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [LocalTasks, LocalInventory, SyncQueue, LocalPendingReviews, LocalAdminCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(localPendingReviews);
          }
          if (from < 3) {
            await migrator.createTable(localAdminCache);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mobai_wms.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
