import 'dart:convert';
import 'package:wms/data/models/location_point_model.dart';

enum TaskStatus { pending, inProgress, completed, approved }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final String assignedTo;
  final Map<String, dynamic> locationData;
  final List<LocationPointModel> aiPathData;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.locationData,
    required this.aiPathData,
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
      'assigned_to': assignedTo,
      'location_data': jsonEncode(locationData),
      'ai_path_data': jsonEncode(aiPathData.map((e) => e.toMap()).toList()),
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
      assignedTo: map['assigned_to'],
      locationData: jsonDecode(map['location_data']),
      aiPathData: (jsonDecode(map['ai_path_data']) as List)
          .map((e) => LocationPointModel.fromMap(e))
          .toList(),
      isSynced: map['is_synced'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
