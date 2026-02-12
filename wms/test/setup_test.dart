import 'package:flutter_test/flutter_test.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Needed for desktop/unit testing sqflite
import 'package:wms/data/models/task_model.dart';
import 'package:wms/data/models/location_point_model.dart';
import 'dart:convert';

void main() {
  test('TaskModel Serialization', () {
    final now = DateTime.now();
    final point = LocationPointModel(x: 10, y: 20, sequenceOrder: 1, locId: 'A1');
    final task = TaskModel(
      id: '1',
      title: 'Test Task',
      description: 'Test Desc',
      status: TaskStatus.pending,
      assignedTo: 'User1',
      locationData: {'area': 'Zone A'},
      aiPathData: [point],
      createdAt: now,
      updatedAt: now,
    );

    final map = task.toMap();
    expect(map['id'], '1');
    expect(map['status'], 'pending');

    final newTask = TaskModel.fromMap(map);
    expect(newTask.id, task.id);
    expect(newTask.aiPathData.first.locId, 'A1');
  });

  // Note: Testing DatabaseHelper requires sqflite_common_ffi setup or integration test
  // We will assume basic compilation correctness for now and verifying serialization logic.
}
