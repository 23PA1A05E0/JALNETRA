import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Mini chart widget for displaying small trend charts
class MiniChart extends StatelessWidget {
  final List<FlSpot> data;
  final String title;
  final Color color;
  final double? minY;
  final double? maxY;

  const MiniChart({
    super.key,
    required this.data,
    required this.title,
    required this.color,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              interval: _calculateXInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateInterval(),
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: minY ?? _getMinY(),
        maxY: maxY ?? _getMaxY(),
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(1)}',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Calculate Y-axis interval
  double _calculateInterval() {
    final minY = _getMinY();
    final maxY = _getMaxY();
    final range = maxY - minY;
    
    if (range <= 0) return 1.0;
    
    // Calculate appropriate interval based on range
    if (range <= 1) return 0.1;
    if (range <= 5) return 0.5;
    if (range <= 10) return 1.0;
    if (range <= 50) return 5.0;
    if (range <= 100) return 10.0;
    return 20.0;
  }

  /// Calculate X-axis interval
  double _calculateXInterval() {
    final length = data.length;
    if (length <= 10) return 1.0;
    if (length <= 50) return 5.0;
    if (length <= 100) return 10.0;
    return 20.0;
  }

  /// Get minimum Y value
  double _getMinY() {
    if (data.isEmpty) return 0.0;
    
    final values = data.map((spot) => spot.y).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    
    // Add some padding below minimum
    return min - (min * 0.1);
  }

  /// Get maximum Y value
  double _getMaxY() {
    if (data.isEmpty) return 10.0;
    
    final values = data.map((spot) => spot.y).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Add some padding above maximum
    return max + (max * 0.1);
  }
}
