import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wms/features/warehouse/data/repositories/receipt_repository.dart';

abstract class ReceiptState extends Equatable {
  const ReceiptState();
  @override
  List<Object?> get props => [];
}

class ReceiptInitial extends ReceiptState {}
class ReceiptLoading extends ReceiptState {}
class ReceiptLoaded extends ReceiptState {
  final List<Map<String, dynamic>> orders;
  const ReceiptLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}
class ReceiptSuccess extends ReceiptState {}
class ReceiptError extends ReceiptState {
  final String message;
  const ReceiptError(this.message);
  @override
  List<Object?> get props => [message];
}

class ReceiptCubit extends Cubit<ReceiptState> {
  final ReceiptRepository _repository;

  ReceiptCubit(this._repository) : super(ReceiptInitial());

  Future<void> loadIncomingOrders() async {
    emit(ReceiptLoading());
    try {
      final orders = await _repository.getIncomingOrders();
      emit(ReceiptLoaded(orders));
    } catch (e) {
      emit(ReceiptError(e.toString()));
    }
  }

  Future<void> confirmOrderReception({
    required String orderId,
    required List<Map<String, dynamic>> receivedItems,
  }) async {
    emit(ReceiptLoading());
    try {
      await _repository.confirmReceipt(
        orderId: orderId,
        receivedItems: receivedItems,
      );
      emit(ReceiptSuccess());
    } catch (e) {
      emit(ReceiptError(e.toString()));
    }
  }
}
