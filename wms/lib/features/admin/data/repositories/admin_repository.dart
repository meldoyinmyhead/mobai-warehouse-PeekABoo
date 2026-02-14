import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wms/features/admin/data/models/warehouse_model.dart';
import 'package:wms/features/auth/data/user_model.dart';

class AdminRepository {
  final String baseUrl;

  AdminRepository(this.baseUrl);

  Future<List<WarehouseModel>> getWarehouses() async {
    final response = await http.get(Uri.parse('$baseUrl/entrepots/'));
    if (response.statusCode == 200) {
      List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => WarehouseModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load warehouses');
    }
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
    final response = await http.get(Uri.parse('$baseUrl/users/'));
    if (response.statusCode == 200) {
      List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => UserModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load users');
    }
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
