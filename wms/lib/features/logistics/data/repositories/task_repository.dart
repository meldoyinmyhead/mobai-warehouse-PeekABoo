import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/features/logistics/data/models/task_product_model.dart';
import 'package:wms/features/supervisor/data/models/location_point_model.dart';
import 'package:wms/core/data/repositories/base_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wms/core/app_config.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:drift/drift.dart';

class TaskRepository extends BaseRepositoryImpl<TaskModel> {
  final AppDatabase _db;

  TaskRepository(this._db) : super('tasks');

  @override
  TaskModel fromMap(Map<String, dynamic> map) {
    return TaskModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(TaskModel item) {
    return item.toMap();
  }

  // ... (fromMap, toMap remain same)

  Future<List<TaskModel>> getEmployeeTasks(String userId) async {
    // 1. Try Network
    try {
      final response = await http.get(Uri.parse('${AppConfig.backendUrl}/employee/tasks/$userId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final tasks = data.map((item) {
           // ... (Mapping logic same as before) ...
           return TaskModel(
            id: item['id'] ?? 'unknown',
            title: 'Preparation: ${item['reference'] ?? "Ref"}',
            description: 'Order Ref: ${item['reference'] ?? "N/A"}',
            status: TaskStatus.pending,
            type: _mapBackendType(item['order_type']),
            priority: TaskPriority.high,
            assignedTo: userId,
            locationData: {}, 
            aiPathData: (item['stops'] as List).map((s) {
              return LocationPointModel(
                x: (s['colonne'] as num).toDouble(),
                y: (s['rangee'] as num).toDouble(),
                z: (s['niveau'] as num).toDouble(),
                sequenceOrder: s['sequence'] as int,
                locId: s['location_code'] as String
              );
            }).toList(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            products: (item['stops'] as List).map((s) {
              return TaskProductModel(
                productId: 'unknown',
                name: s['product_name'],
                expectedQuantity: s['quantity'],
                actualQuantity: 0
              );
            }).toList(),
            details: {
              'distance': item['total_distance_m'],
              'stops_count': (item['stops'] as List).length
            }
          );
        }).toList();

        // 2. Cache to Local DB
        await _db.batch((batch) {
          // Optional: clear old tasks for this user?
          // batch.deleteWhere(...);
          
          for (var task in tasks) {
            batch.insert(_db.localTasks, LocalTasksCompanion.insert(
              id: task.id,
              type: task.type.toString(),
              status: task.status.toString(),
              data: jsonEncode(task.toMap()), // Serialize full task
              createdAt: DateTime.now(),
              lastUpdated: DateTime.now(),
              syncStatus: const Value('synced')
            ), mode: InsertMode.insertOrReplace);
          }
        });
        
        return tasks;
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print("Network failed, checking local cache: $e");
      // 3. Fallback to Local DB
      // Note: We store status as 'TaskStatus.pending' string in the cache above
      final localTasks = await (_db.select(_db.localTasks)
        ..where((t) => t.status.equals(TaskStatus.pending.toString()))
      ).get();
      
      if (localTasks.isNotEmpty) {
        return localTasks.map((t) => TaskModel.fromMap(jsonDecode(t.data))).toList();
      }
      
      // If no local data, fallback to mock (or empty)
      return getAll(); 
    }
  }

  TaskType _mapBackendType(String? backendType) {
    switch (backendType) {
      case 'RECEIPT':
        return TaskType.receipt;
      case 'TRANSFER':
        return TaskType.storage;
      case 'PICKING':
        return TaskType.picking;
      case 'DELIVERY':
        return TaskType.delivery;
      default:
        return TaskType.general;
    }
  }

  Future<bool> completeTask(String taskId) async {
    // 1. Always attempt Network first
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/employee/tasks/$taskId/complete'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Mark local cache as completed too
        await (_db.update(_db.localTasks)..where((t) => t.id.equals(taskId))).write(
          LocalTasksCompanion(
            status: Value(TaskStatus.completed.toString()),
            syncStatus: const Value('synced'),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      print("Network completion failed, queuing offline: $e");
      
      // 2. Queue for Sync
      await _db.into(_db.syncQueue).insert(
        SyncQueueCompanion.insert(
          actionType: 'COMPLETE_TASK',
          payload: jsonEncode({'task_id': taskId}),
          timestamp: DateTime.now(),
          status: const Value('pending'),
        ),
      );

      // 3. Update local state so it disappears from 'Pending' list
      await (_db.update(_db.localTasks)..where((t) => t.id.equals(taskId))).write(
        LocalTasksCompanion(
          status: Value(TaskStatus.completed.toString()),
          syncStatus: const Value('pending_update'),
        ),
      );

      return true; // Return true because it's "successfully" queued
    }
  }

  @override
  Future<List<TaskModel>> getAll() async {
    // Mock data for development
    return [
      TaskModel(
        id: '1',
        title: 'Receipt Task',
        description: 'Order: RCP-2026-001',
        status: TaskStatus.pending,
        type: TaskType.receipt,
        priority: TaskPriority.medium,
        assignedTo: 'Emp001',
        locationData: {},
        aiPathData: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        details: {'supplier': 'Samsung Electronics', 'expected_arrival': 'Feb 12, 2026'},
        products: [
          TaskProductModel(productId: 'p1', name: 'Samsung Galaxy S24', expectedQuantity: 50),
          TaskProductModel(productId: 'p2', name: 'Samsung Galaxy S24+', expectedQuantity: 30),
          TaskProductModel(productId: 'p3', name: 'Samsung Galaxy S24 Ultra', expectedQuantity: 20),
        ],
      ),
      TaskModel(
        id: '2',
        title: 'Storage Task',
        description: 'Order: STR-2026-002',
        status: TaskStatus.pending,
        type: TaskType.storage,
        priority: TaskPriority.medium,
        assignedTo: 'Emp001',
        locationData: {'floor': 'N2', 'slot': 'C5', 'zone': 'B7'},
        aiPathData: [
           LocationPointModel(x: 2.0, y: 5.0, z: 2.0, sequenceOrder: 1, locId: "RECEPTION"),
           LocationPointModel(x: 10.0, y: 5.0, z: 2.0, sequenceOrder: 2, locId: "AISLE"),
           LocationPointModel(x: 20.0, y: 10.0, z: 2.0, sequenceOrder: 3, locId: "C5"),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        details: {
          'product': 'Electronic Devices - Mobile Phones',
          'quantity': 50,
          'weight': '25kg',
          'dimensions': '40x30x25cm',
          'current_location': 'Receiving Area'
        },
      ),
      TaskModel(
        id: '3',
        title: 'Picking Task',
        description: 'Order: PCK-2026-003',
        status: TaskStatus.pending,
        type: TaskType.picking,
        priority: TaskPriority.high,
        assignedTo: 'Emp001',
        locationData: {'start_location': 'Packing Area'},
        aiPathData: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        details: {'order_type': 'Customer Order', 'priority': 'High', 'zone': 'Zone A3-N1'},
        products: [
          TaskProductModel(productId: 'p4', name: 'Laptop Charger', expectedQuantity: 10),
          TaskProductModel(productId: 'p5', name: 'USB-C Cable', expectedQuantity: 25),
          TaskProductModel(productId: 'p6', name: 'Laptop Stand', expectedQuantity: 5),
        ],
      ),
      TaskModel(
        id: '4',
        title: 'Delivery Task',
        description: 'Order: DLV-2026-004',
        status: TaskStatus.pending,
        type: TaskType.delivery,
        priority: TaskPriority.medium,
        assignedTo: 'Emp001',
        locationData: {},
        aiPathData: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        details: {
          'delivery_type': 'Local Delivery',
          'loading_bay': 'Loading Bay 2',
          'destination': 'Dubai Office - Building A',
          'address': 'Sheikh Zayed Road, Dubai, UAE',
          'contact_person': 'Ahmed Al-Mansouri',
          'contact_number': '+971 50 123 4567',
          'estimated_time': '2:30 PM'
        },
        products: [
          TaskProductModel(productId: 'p7', name: 'Office Supplies', expectedQuantity: 50),
          TaskProductModel(productId: 'p8', name: 'Printer Paper', expectedQuantity: 20),
          TaskProductModel(productId: 'p9', name: 'Stationery Set', expectedQuantity: 15),
        ],
      ),
    ];
  }
}
