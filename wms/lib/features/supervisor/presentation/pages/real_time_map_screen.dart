import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/supervisor/presentation/cubits/map_cubit.dart';
import 'package:wms/features/supervisor/presentation/widgets/isometric_warehouse_painter.dart';

class RealTimeMapScreen extends StatelessWidget {
  const RealTimeMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapCubit, MapState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Live Operations Map', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              DropdownButton<String>(
                value: state.selectedFloor,
                underline: const SizedBox(),
                items: ['0A', 'N1', 'N2', 'N3', 'N4'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  context.read<MapCubit>().changeFloor(newValue!);
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: InteractiveViewer(
            maxScale: 5.0,
            minScale: 0.1,
            boundaryMargin: const EdgeInsets.all(1000),
            child: Center(
              child: CustomPaint(
                size: const Size(1200, 1000),
                painter: IsometricWarehousePainter(
                  floor: state.selectedFloor,
                  entities: state.entities,
                  aiPath: state.aiPath,
                ),
              ),
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'legend',
                onPressed: () => _showLegend(context),
                child: const Icon(Icons.info_outline),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'center',
                onPressed: () {
                  // Center view logic
                },
                child: const Icon(Icons.center_focus_strong),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(Colors.green, 'Active Employee'),
            _legendItem(Colors.orange, 'Chariot (Cart)'),
            _legendItem(Colors.yellow, 'AI Optimized Path'),
            _legendItem(Colors.blueGrey.shade200, 'Storage Rack / Block'),
            _legendItem(Colors.teal.shade200, 'Elevator (Montre de charge)'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 20, height: 20, color: color),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}


