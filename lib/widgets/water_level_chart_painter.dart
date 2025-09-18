import 'package:flutter/material.dart';

/// Custom painter for water level chart
class WaterLevelChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  WaterLevelChartPainter(
    this.data, {
    this.lineColor = Colors.blue,
    this.fillColor = Colors.blue,
    this.gridColor = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Calculate data bounds
    double minValue = double.infinity;
    double maxValue = -double.infinity;
    
    for (final point in data) {
      final value = (point['waterLevel'] as num?)?.toDouble() ?? 0.0;
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }

    // Add some padding
    final valueRange = maxValue - minValue;
    minValue -= valueRange * 0.1;
    maxValue += valueRange * 0.1;

    // Draw grid lines
    _drawGridLines(canvas, size, gridPaint, minValue, maxValue);

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final value = (data[i]['waterLevel'] as num?)?.toDouble() ?? 0.0;
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((value - minValue) / (maxValue - minValue)) * size.height;
      points.add(Offset(x, y));
    }

    // Draw filled area
    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points.first.dx, size.height);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw data points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3.0, pointPaint);
    }

    // Draw labels
    _drawLabels(canvas, size, minValue, maxValue);
  }

  void _drawGridLines(Canvas canvas, Size size, Paint paint, double minValue, double maxValue) {
    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = (i / 5) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Vertical grid lines
    for (int i = 0; i <= 5; i++) {
      final x = (i / 5) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double minValue, double maxValue) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Y-axis labels
    for (int i = 0; i <= 5; i++) {
      final value = minValue + (maxValue - minValue) * (1 - i / 5);
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(5, (i / 5) * size.height - textPainter.height / 2),
      );
    }

    // X-axis labels (dates)
    if (data.isNotEmpty) {
      final firstDate = data.first['date']?.toString() ?? '';
      final lastDate = data.last['date']?.toString() ?? '';
      
      // First date
      textPainter.text = TextSpan(
        text: firstDate,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, size.height + 5));

      // Last date
      textPainter.text = TextSpan(
        text: lastDate,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width - textPainter.width, size.height + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
