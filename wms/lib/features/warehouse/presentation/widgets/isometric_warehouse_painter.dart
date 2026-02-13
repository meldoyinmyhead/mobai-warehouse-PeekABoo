import 'package:flutter/material.dart';
import 'dart:math' as math;

class IsometricWarehousePainter extends CustomPainter {
  final String floor;
  final List<Map<String, dynamic>> entities; // Employees/Chariots
  final List<Offset> aiPath;

  IsometricWarehousePainter({
    required this.floor,
    this.entities = const [],
    this.aiPath = const [],
  });

  static const double tileSize = 40.0;
  static const double tileHeight = tileSize / 2;

  @override
  void paint(Canvas canvas, Size size) {
    // Center the map
    canvas.translate(size.width / 2, size.height / 4);

    final Paint tilePaint = Paint()
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw Grid based on floor
    int rows = 15;
    int cols = 15;

    if (floor == '0A') {
      rows = 18;
      cols = 12;
    } else {
      rows = 12;
      cols = 10;
    }

    for (int q = 0; q < rows; q++) {
      for (int p = 0; p < cols; p++) {
        _drawTile(canvas, p, q, _getTileColor(p, q, floor), tilePaint, borderPaint);
      }
    }

    // Draw Entities
    for (var entity in entities) {
      _drawEntity(canvas, entity['x'], entity['y'], entity['color'] ?? Colors.blue, entity['label']);
    }

    // Draw AI Path
    if (aiPath.isNotEmpty) {
      _drawPath(canvas, aiPath);
    }
  }

  void _drawTile(Canvas canvas, int p, int q, Color color, Paint tilePaint, Paint borderPaint) {
    tilePaint.color = color;
    
    Path path = Path();
    Offset top = _toIsometric(p.toDouble(), q.toDouble());
    Offset right = _toIsometric(p + 1.0, q.toDouble());
    Offset bottom = _toIsometric(p + 1.0, q + 1.0);
    Offset left = _toIsometric(p.toDouble(), q + 1.0);

    path.moveTo(top.dx, top.dy);
    path.lineTo(right.dx, right.dy);
    path.lineTo(bottom.dx, bottom.dy);
    path.lineTo(left.dx, left.dy);
    path.close();

    canvas.drawPath(path, tilePaint);
    canvas.drawPath(path, borderPaint);
    
    // Draw 3D sides if it's a "block" (e.g. Rack)
    if (color == Colors.blueGrey.shade200) {
       _drawBlockSides(canvas, p, q, tilePaint);
    }
  }

  void _drawBlockSides(Canvas canvas, int p, int q, Paint paint) {
    double height = 20.0;
    Offset p1 = _toIsometric(p.toDouble(), q + 1.0);
    Offset p2 = _toIsometric(p + 1.0, q + 1.0);
    Offset p3 = _toIsometric(p + 1.0, q.toDouble());

    // Front left side
    Path leftSide = Path();
    leftSide.moveTo(p1.dx, p1.dy);
    leftSide.lineTo(p1.dx, p1.dy - height);
    leftSide.lineTo(p2.dx, p2.dy - height);
    leftSide.lineTo(p2.dx, p2.dy);
    leftSide.close();
    paint.color = paint.color.withOpacity(0.8);
    canvas.drawPath(leftSide, paint);

    // Front right side
    Path rightSide = Path();
    rightSide.moveTo(p2.dx, p2.dy);
    rightSide.lineTo(p2.dx, p2.dy - height);
    rightSide.lineTo(p3.dx, p3.dy - height);
    rightSide.lineTo(p3.dx, p3.dy);
    rightSide.close();
    paint.color = paint.color.withOpacity(0.6);
    canvas.drawPath(rightSide, paint);
  }

  void _drawEntity(Canvas canvas, double x, double y, Color color, String label) {
    Offset pos = _toIsometric(x, y);
    // Draw shadow
    canvas.drawCircle(pos, 8, Paint()..color = Colors.black26);
    // Draw "person" block
    canvas.drawRect(Rect.fromCenter(center: pos.translate(0, -10), width: 10, height: 20), Paint()..color = color);
    // Draw label
    TextSpan span = TextSpan(style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold), text: label);
    TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, pos.translate(-tp.width / 2, -35));
  }

  void _drawPath(Canvas canvas, List<Offset> path) {
    Paint pathPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Path drawPath = Path();
    Offset start = _toIsometric(path[0].dx, path[0].dy);
    drawPath.moveTo(start.dx, start.dy);
    
    for (int i = 1; i < path.length; i++) {
      Offset next = _toIsometric(path[i].dx, path[i].dy);
      drawPath.lineTo(next.dx, next.dy);
    }
    canvas.drawPath(drawPath, pathPaint);
  }

  Offset _toIsometric(double p, double q) {
    return Offset(
      (p - q) * tileSize,
      (p + q) * tileHeight,
    );
  }

  Color _getTileColor(int p, int q, String floor) {
    if (floor == '0A') {
       // Mock Zones for Picking Floor
       if (q < 3) return Colors.lightBlue.shade50; // Reception
       if (q > 14) return Colors.purple.shade50; // Expedition
       if (p % 3 == 0) return Colors.blueGrey.shade200; // Racks
       return Colors.white;
    } else {
       // Storage Floor
       if (p == 0 || p == 9 || q == 0 || q == 11) return Colors.grey.shade300; // Walls
       if (p == 4 && q == 0) return Colors.teal.shade200; // Elevator
       return Colors.white;
    }
  }

  @override
  bool shouldRepaint(covariant IsometricWarehousePainter oldDelegate) {
    return oldDelegate.floor != floor || oldDelegate.entities != entities;
  }
}
