import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class MapState extends Equatable {
  final String selectedFloor;
  final List<Map<String, dynamic>> entities;
  final List<Offset> aiPath;

  const MapState({
    this.selectedFloor = '0A',
    this.entities = const [],
    this.aiPath = const [],
  });

  MapState copyWith({
    String? selectedFloor,
    List<Map<String, dynamic>>? entities,
    List<Offset>? aiPath,
  }) {
    return MapState(
      selectedFloor: selectedFloor ?? this.selectedFloor,
      entities: entities ?? this.entities,
      aiPath: aiPath ?? this.aiPath,
    );
  }

  @override
  List<Object> get props => [selectedFloor, entities, aiPath];
}

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(const MapState()) {
    loadMockData('0A');
  }

  void changeFloor(String floor) {
    loadMockData(floor);
  }

  void loadMockData(String floor) {
    List<Map<String, dynamic>> entities = [];
    List<Offset> path = [];

    if (floor == '0A') {
      entities = [
        {'id': 'E1', 'label': 'Aman', 'x': 5.0, 'y': 4.0, 'color': Colors.green},
        {'id': 'E2', 'label': 'Sarah', 'x': 8.0, 'y': 10.0, 'color': Colors.blue},
        {'id': 'C1', 'label': 'CHR-01', 'x': 2.0, 'y': 8.0, 'color': Colors.orange},
      ];
      path = [
        const Offset(2.0, 8.0),
        const Offset(2.0, 5.0),
        const Offset(5.0, 5.0),
        const Offset(5.0, 15.0),
      ];
    } else {
       entities = [
        {'id': 'E1', 'label': 'Aman', 'x': 4.0, 'y': 2.0, 'color': Colors.green},
      ];
    }

    emit(state.copyWith(selectedFloor: floor, entities: entities, aiPath: path));
  }
}
