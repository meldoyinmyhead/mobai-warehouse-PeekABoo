import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/features/logistics/data/models/task_product_model.dart';
import 'package:wms/features/supervisor/data/models/location_point_model.dart';
import 'package:wms/core/data/repositories/base_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wms/core/app_config.dart';

class TaskRepository extends BaseRepositoryImpl<TaskModel> {
  TaskRepository() : super('tasks');

  @override
  TaskModel fromMap(Map<String, dynamic> map) {
    return TaskModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(TaskModel item) {
    return item.toMap();
  }
  
  // Custom queries for Supervisor
  Future<List<TaskModel>> getPendingTasks() async {
    // Placeholder implementation
    return []; 
  }
  
  Future<List<TaskModel>> getEmployeeTasks(String userId) async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.backendUrl}/employee/tasks/$userId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          // Map OptimizedRoute to TaskModel
          return TaskModel(
            id: item['id'] ?? 'unknown',
            title: 'Preparation: ${item['reference'] ?? "Ref"}',
            description: 'Picking Order',
            status: TaskStatus.pending,
            type: TaskType.picking,
            priority: TaskPriority.high,
            assignedTo: userId,
            locationData: {}, // Could put start point here
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
                productId: 'unknown', // Backend doesn't send prod ID in stop, maybe add?
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
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print("Error fetching employee tasks: $e");
      // Fallback to mock if failed (or rethrow)
      return getAll();
    }
  }

  Future<bool> completeTask(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/employee/tasks/$taskId/complete'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error completing task: $e");
      return false;
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
        aiPathData: [],
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
