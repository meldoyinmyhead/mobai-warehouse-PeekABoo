import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wms/features/supervisor/data/models/flag_model.dart';
import 'package:wms/features/supervisor/data/repositories/flag_repository.dart';

abstract class FlagState extends Equatable {
  const FlagState();
  @override
  List<Object?> get props => [];
}

class FlagInitial extends FlagState {}
class FlagLoading extends FlagState {}
class FlagLoaded extends FlagState {
  final List<FlagModel> flags;
  const FlagLoaded(this.flags);
  @override
  List<Object?> get props => [flags];
}
class FlagError extends FlagState {
  final String message;
  const FlagError(this.message);
  @override
  List<Object?> get props => [message];
}

class FlagCubit extends Cubit<FlagState> {
  final FlagRepository _repository;

  FlagCubit(this._repository) : super(FlagInitial());

  Future<void> loadFlags() async {
    emit(FlagLoading());
    try {
      final flags = await _repository.getAllFlags();
      emit(FlagLoaded(flags));
    } catch (e) {
      emit(FlagError(e.toString()));
    }
  }

  Future<void> resolveFlag(String id) async {
    try {
      await _repository.updateFlagStatus(id, FlagStatus.RESOLVED);
      await loadFlags(); // Refresh
    } catch (e) {
      emit(FlagError(e.toString()));
    }
  }

  Future<void> setFlagInProgress(String id) async {
    try {
      await _repository.updateFlagStatus(id, FlagStatus.IN_PROGRESS);
      await loadFlags(); // Refresh
    } catch (e) {
      emit(FlagError(e.toString()));
    }
  }
}
