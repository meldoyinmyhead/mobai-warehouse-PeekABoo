import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/admin/data/models/warehouse_model.dart';
import 'package:wms/features/admin/data/repositories/admin_repository.dart';

abstract class WarehouseState {}

class WarehouseInitial extends WarehouseState {}

class WarehouseLoading extends WarehouseState {}

class WarehouseLoaded extends WarehouseState {
  final List<WarehouseModel> warehouses;
  WarehouseLoaded(this.warehouses);
}

class WarehouseError extends WarehouseState {
  final String message;
  WarehouseError(this.message);
}

class WarehouseCubit extends Cubit<WarehouseState> {
  final AdminRepository repository;

  WarehouseCubit(this.repository) : super(WarehouseInitial());

  Future<void> loadWarehouses() async {
    emit(WarehouseLoading());
    try {
      final warehouses = await repository.getWarehouses();
      emit(WarehouseLoaded(warehouses));
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }

  Future<void> createWarehouse(WarehouseModel warehouse) async {
    try {
      await repository.createWarehouse(warehouse);
      loadWarehouses();
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }
}
