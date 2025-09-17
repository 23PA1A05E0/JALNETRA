import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/measurement.dart';

/// Chart widget for displaying measurement data
class MeasurementChart extends StatelessWidget {
  final List<Measurement> measurements;
  final String title;
  final String yAxisLabel;
  final double Function(Measurement) getYValue;
  final Color color;

  const MeasurementChart({
    super.key,
    required this.measurements,
    required this.title,
    required this.yAxisLabel,
    required this.getYValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('No data available for $title'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _calculateInterval(),
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
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
                        reservedSize: 30,
                        interval: _calculateXInterval(),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= measurements.length) return const Text('');
                          final measurement = measurements[value.toInt()];
                          return Text(
                            DateFormat('MM/dd HH:mm').format(measurement.timestamp),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  minX: 0,
                  maxX: measurements.length.toDouble() - 1,
                  minY: _getMinY(),
                  maxY: _getMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateSpots(),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final measurement = measurements[touchedSpot.x.toInt()];
                          return LineTooltipItem(
                            '${DateFormat('MM/dd HH:mm').format(measurement.timestamp)}\n$yAxisLabel: ${getYValue(measurement).toStringAsFixed(2)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Range: ${_getMinY().toStringAsFixed(1)} - ${_getMaxY().toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Points: ${measurements.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Generate spots for the chart
  List<FlSpot> _generateSpots() {
    return measurements.asMap().entries.map((entry) {
      final index = entry.key;
      final measurement = entry.value;
      return FlSpot(index.toDouble(), getYValue(measurement));
    }).toList();
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
    final length = measurements.length;
    if (length <= 10) return 1.0;
    if (length <= 50) return 5.0;
    if (length <= 100) return 10.0;
    return 20.0;
  }

  /// Get minimum Y value
  double _getMinY() {
    if (measurements.isEmpty) return 0.0;
    
    final values = measurements.map(getYValue).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    
    // Add some padding below minimum
    return min - (min * 0.1);
  }

  /// Get maximum Y value
  double _getMaxY() {
    if (measurements.isEmpty) return 10.0;
    
    final values = measurements.map(getYValue).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Add some padding above maximum
    return max + (max * 0.1);
  }
}
