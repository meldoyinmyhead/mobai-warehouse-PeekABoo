import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:wms/core/theme/app_theme.dart';

class IsometricWarehousePainter extends CustomPainter {
  final List<List<int>> layout;
  final List<Map<String, dynamic>> entities; // Employees/Chariots
  final List<Offset> aiPath;

  IsometricWarehousePainter({
    required this.layout,
    this.entities = const [],
    this.aiPath = const [], required String floor,
  });

  static const double tileSize = 32.0;
  static const double tileHeight = tileSize / 2;

  @override
  void paint(Canvas canvas, Size size) {
    // Center the map with some padding
    canvas.translate(size.width / 2, size.height / 5);

    final Paint tilePaint = Paint()..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Background Shadow/Glow for the floor
    _drawFloorGlow(canvas, size);

    if (layout.isEmpty) return;

    // Draw Grid based on floor
    int rows = layout.length;
    int cols = layout[0].length;

    // Draw Floor Tiles
    for (int q = 0; q < rows; q++) {
      for (int p = 0; p < cols; p++) {
        // Ensure we don't go out of bounds if rows have different lengths
        if (p >= layout[q].length) continue;
        
        _drawTile(canvas, p, q, layout, tilePaint, borderPaint);
      }
    }

    // Draw AI Path with Glow
    if (aiPath.isNotEmpty) {
      _drawPath(canvas, aiPath);
    }

    // Draw Entities (Employees/Chariots)
    for (var entity in entities) {
      _drawEntity(canvas, entity);
    }
  }

  void _drawFloorGlow(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = AppTheme.darkBlue.withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    Path floorPath = Path();
    Offset p1 = _toIsometric(0, 0);
    Offset p2 = _toIsometric(20, 0);
    Offset p3 = _toIsometric(20, 20);
    Offset p4 = _toIsometric(0, 20);
    
    floorPath.moveTo(p1.dx, p1.dy);
    floorPath.lineTo(p2.dx, p2.dy);
    floorPath.lineTo(p3.dx, p3.dy);
    floorPath.lineTo(p4.dx, p4.dy);
    floorPath.close();
    
    canvas.drawPath(floorPath, shadowPaint);
  }

  void _drawTile(Canvas canvas, int p, int q, List<List<int>> layout, Paint tilePaint, Paint borderPaint) {
    Color color = _getTileColor(p, q, layout);
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
    
    // Draw 3D sides if it's a "block" (e.g. Rack or Obstacle)
    // 1: Storage, 4: Obstacle
    int type = layout[q][p];
    if (type == 1 || type == 4) {
       _drawBlockSides(canvas, p, q, tilePaint);
    }
  }

  void _drawBlockSides(Canvas canvas, int p, int q, Paint paint) {
    double height = 15.0; // Dynamic height for racks
    Offset p1 = _toIsometric(p.toDouble(), q + 1.0);
    Offset p2 = _toIsometric(p + 1.0, q + 1.0);
    Offset p3 = _toIsometric(p + 1.0, q.toDouble());

    // Front left side (Darker)
    Path leftSide = Path();
    leftSide.moveTo(p1.dx, p1.dy);
    leftSide.lineTo(p1.dx, p1.dy - height);
    leftSide.lineTo(p2.dx, p2.dy - height);
    leftSide.lineTo(p2.dx, p2.dy);
    leftSide.close();
    
    Paint sidePaint = Paint()..style = PaintingStyle.fill;
    sidePaint.color = paint.color.withOpacity(0.9);
    canvas.drawPath(leftSide, sidePaint);

    // Front right side (Medium)
    Path rightSide = Path();
    rightSide.moveTo(p2.dx, p2.dy);
    rightSide.lineTo(p2.dx, p2.dy - height);
    rightSide.lineTo(p3.dx, p3.dy - height);
    rightSide.lineTo(p3.dx, p3.dy);
    rightSide.close();
    
    sidePaint.color = paint.color.withOpacity(0.7);
    canvas.drawPath(rightSide, sidePaint);
    
    // Top face highlight
    Offset t1 = _toIsometric(p.toDouble(), q.toDouble()).translate(0, -height);
    Offset t2 = _toIsometric(p + 1.0, q.toDouble()).translate(0, -height);
    Offset t3 = _toIsometric(p + 1.0, q + 1.0).translate(0, -height);
    Offset t4 = _toIsometric(p.toDouble(), q + 1.0).translate(0, -height);
    
    Path topFace = Path()
      ..moveTo(t1.dx, t1.dy)
      ..lineTo(t2.dx, t2.dy)
      ..lineTo(t3.dx, t3.dy)
      ..lineTo(t4.dx, t4.dy)
      ..close();
    
    sidePaint.color = paint.color.withOpacity(1.0);
    canvas.drawPath(topFace, sidePaint);
    
    // Subtle detail line on top
    canvas.drawPath(topFace, Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  void _drawEntity(Canvas canvas, Map<String, dynamic> entity) {
    double x = (entity['x'] as num).toDouble();
    double y = (entity['y'] as num).toDouble();
    Color color = entity['color'] ?? AppTheme.lightBlue;
    String label = entity['label'] ?? '';
    bool isChariot = entity['type'] == 'chariot';

    // Center the entity in the tile
    Offset pos = _toIsometric(x + 0.5, y + 0.5);
    
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 2), width: 14, height: 6),
      Paint()..color = Colors.black12..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
    );

    if (isChariot) {
      // Draw a sleek robot "pod"
      _drawChariot(canvas, pos, color);
    } else {
      // Draw a sleek "pawn" for employees
      _drawEmployee(canvas, pos, color);
    }

    // Label with background
    if (label.isNotEmpty) {
      _drawLabel(canvas, pos, label);
    }
  }

  void _drawChariot(Canvas canvas, Offset pos, Color color) {
    final basePaint = Paint()..color = color;
    final topPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    
    // Main Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: pos.translate(0, -5), width: 12, height: 8), const Radius.circular(2)),
      basePaint
    );
    // Scanning Light
    canvas.drawCircle(pos.translate(0, -6), 2, topPaint..color = AppTheme.yellow);
  }

  void _drawEmployee(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(pos.translate(0, -15), 4, Paint()..color = color); // Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - 5, pos.dy - 11, 10, 10), const Radius.circular(4)), // Body
      Paint()..color = color
    );
  }

  void _drawLabel(Canvas canvas, Offset pos, String label) {
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(
      center: pos.translate(0, -28),
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), Paint()..color = Colors.black87);
    textPainter.paint(canvas, pos.translate(-textPainter.width / 2, -28 - textPainter.height / 2));
  }

  void _drawPath(Canvas canvas, List<Offset> path) {
    // Outer Glow
    Paint glowPaint = Paint()
      ..color = AppTheme.yellow.withOpacity(0.2)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Inner Path
    Paint corePaint = Paint()
      ..color = AppTheme.yellow
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Path drawPath = Path();
    // +0.5 to center in the tile
    Offset start = _toIsometric(path[0].dx + 0.5, path[0].dy + 0.5);
    drawPath.moveTo(start.dx, start.dy);
    
    for (int i = 1; i < path.length; i++) {
      Offset next = _toIsometric(path[i].dx + 0.5, path[i].dy + 0.5);
      drawPath.lineTo(next.dx, next.dy);
    }
    
    canvas.drawPath(drawPath, glowPaint);
    canvas.drawPath(drawPath, corePaint);
    
    // Draw destination dot
    Offset end = _toIsometric(path.last.dx + 0.5, path.last.dy + 0.5);
    canvas.drawCircle(end, 4, corePaint..style = PaintingStyle.fill);
  }

  Offset _toIsometric(double p, double q) {
    return Offset(
      (p - q) * tileSize,
      (p + q) * tileHeight,
    );
  }

  Color _getTileColor(int p, int q, List<List<int>> layout) {
     if (q >= layout.length || p >= layout[q].length) return Colors.black; // Out of bounds

     int type = layout[q][p];

     switch (type) {
       case 0: // Aisle
         return Colors.white;
       case 1: // Storage Slot
         return AppTheme.mediumGrey; // Rack color
       case 2: // Elevator
         return AppTheme.lightBlue.withOpacity(0.3);
       case 3: // Chariot Elevator
         return AppTheme.yellow.withOpacity(0.3);
       case 4: // Obstacle
         return Colors.red.withOpacity(0.2); // Or a wall color
       default:
         return Colors.white;
     }
  }

  @override
  bool shouldRepaint(covariant IsometricWarehousePainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.entities != entities || oldDelegate.aiPath != aiPath;
  }
}
