import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http;
import 'package:wms/core/database/app_database.dart';
import 'package:wms/features/admin/data/models/warehouse_model.dart';
import 'package:wms/features/auth/data/user_model.dart';

class AdminRepository {
  final String baseUrl;
  final AppDatabase? _db;

  AdminRepository(this.baseUrl, [this._db]);

  Future<bool> get _isOnline async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  Future<List<WarehouseModel>> getWarehouses() async {
    if (await _isOnline) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/entrepots/'));
        if (response.statusCode == 200) {
          List data = json.decode(utf8.decode(response.bodyBytes));
          final list = data.map((item) => WarehouseModel.fromJson(item)).toList();
          if (_db != null) {
            await _db!.into(_db!.localAdminCache).insertOnConflictUpdate(
              LocalAdminCacheCompanion(
                key: const drift.Value('warehouses'),
                data: drift.Value(json.encode(data)),
                updatedAt: drift.Value(DateTime.now()),
              ),
            );
          }
          return list;
        }
      } catch (_) {}
    }
    if (_db != null) {
      final row = await (_db!.select(_db!.localAdminCache)
            ..where((t) => t.key.equals('warehouses')))
          .getSingleOrNull();
      if (row != null) {
        final data = json.decode(row.data) as List;
        return data.map((item) => WarehouseModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    }
    throw Exception('Failed to load warehouses');
  }

  Future<WarehouseModel> createWarehouse(WarehouseModel warehouse) async {
    final response = await http.post(
      Uri.parse('$baseUrl/entrepots/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(warehouse.toJson()),
    );
    if (response.statusCode == 201) {
      return WarehouseModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create warehouse');
    }
  }

  Future<FloorModel> addFloor(String warehouseId, FloorModel floor) async {
    final response = await http.post(
      Uri.parse('$baseUrl/entrepots/$warehouseId/etages'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(floor.toJson()),
    );
    if (response.statusCode == 200) {
      return FloorModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to add floor');
    }
  }

  // --- User Management ---

  Future<List<UserModel>> getUsers() async {
    if (await _isOnline) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/users/'));
        if (response.statusCode == 200) {
          List data = json.decode(utf8.decode(response.bodyBytes));
          final list = data.map((item) => UserModel.fromJson(item)).toList();
          if (_db != null) {
            await _db!.into(_db!.localAdminCache).insertOnConflictUpdate(
              LocalAdminCacheCompanion(
                key: const drift.Value('users'),
                data: drift.Value(json.encode(data)),
                updatedAt: drift.Value(DateTime.now()),
              ),
            );
          }
          return list;
        }
      } catch (_) {}
    }
    if (_db != null) {
      final row = await (_db!.select(_db!.localAdminCache)
            ..where((t) => t.key.equals('users')))
          .getSingleOrNull();
      if (row != null) {
        final data = json.decode(row.data) as List;
        return data.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    }
    throw Exception('Failed to load users');
  }

  Future<UserModel> createUser(UserModel user, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        ...user.toJson(),
        'password': password,
      }),
    );
    if (response.statusCode == 201) {
      return UserModel.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<void> updateUser(String userId, UserModel user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}
