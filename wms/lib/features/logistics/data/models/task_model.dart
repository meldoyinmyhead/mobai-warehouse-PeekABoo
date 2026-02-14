import 'dart:convert';
import 'package:wms/features/supervisor/data/models/location_point_model.dart';
import 'package:wms/features/logistics/data/models/task_product_model.dart';

enum TaskStatus { pending, inProgress, completed, approved }
enum TaskPriority { low, medium, high }
enum TaskType { receipt, storage, picking, delivery, general }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskType type;
  final String assignedTo;
  final Map<String, dynamic> locationData; // Flexible for start/end points
  final List<LocationPointModel> aiPathData;
  final List<TaskProductModel> products;
  final Map<String, dynamic> details; // For specific fields like Supplier, Weight, Dimensions
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.priority = TaskPriority.medium,
    this.type = TaskType.general,
    required this.assignedTo,
    required this.locationData,
    required this.aiPathData,
    this.products = const [],
    this.details = const {},
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'type': type.toString().split('.').last,
      'assigned_to': assignedTo,
      'location_data': jsonEncode(locationData),
      'ai_path_data': jsonEncode(aiPathData.map((e) => e.toMap()).toList()),
      'products': jsonEncode(products.map((e) => e.toMap()).toList()),
      'details': jsonEncode(details),
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      type: TaskType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => TaskType.general,
      ),
      assignedTo: map['assigned_to'],
      locationData: map['location_data'] is String 
          ? jsonDecode(map['location_data']) 
          : map['location_data'] ?? {},
      aiPathData: map['ai_path_data'] != null
          ? (jsonDecode(map['ai_path_data']) as List).map((e) => LocationPointModel.fromMap(e)).toList()
          : [],
      products: map['products'] != null
          ? (jsonDecode(map['products']) as List).map((e) => TaskProductModel.fromMap(e)).toList()
          : [],
      details: map['details'] is String 
          ? jsonDecode(map['details']) 
          : map['details'] ?? {},
      isSynced: map['is_synced'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
