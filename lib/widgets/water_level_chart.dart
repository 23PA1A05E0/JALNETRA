import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/dwlr_station.dart';

/// Water level chart widget
class WaterLevelChart extends StatelessWidget {
  final List<WaterLevelData> data;
  final String stationName;

  const WaterLevelChart({
    super.key,
    required this.data,
    required this.stationName,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Water Level Trend - $stationName',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _calculateInterval(),
                    verticalInterval: _calculateXInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.3),
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
                          if (value.toInt() >= data.length) return const Text('');
                          final dataPoint = data[value.toInt()];
                          return Text(
                            DateFormat('MM/dd').format(dataPoint.date),
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
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  minX: 0,
                  maxX: data.length.toDouble() - 1,
                  minY: _getMinY(),
                  maxY: _getMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateSpots(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final dataPoint = data[touchedSpot.x.toInt()];
                          return LineTooltipItem(
                            '${DateFormat('MM/dd HH:mm').format(dataPoint.date)}\nWater Level: ${dataPoint.waterLevel.toStringAsFixed(2)}m\nQuality: ${dataPoint.quality}',
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
                  'Range: ${_getMinY().toStringAsFixed(1)} - ${_getMaxY().toStringAsFixed(1)} m',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Data Points: ${data.length}',
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
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      return FlSpot(index.toDouble(), dataPoint.waterLevel);
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
    final length = data.length;
    if (length <= 10) return 1.0;
    if (length <= 50) return 5.0;
    if (length <= 100) return 10.0;
    return 20.0;
  }

  /// Get minimum Y value
  double _getMinY() {
    if (data.isEmpty) return 0.0;
    
    final values = data.map((d) => d.waterLevel).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    
    // Add some padding below minimum
    return min - (min * 0.1);
  }

  /// Get maximum Y value
  double _getMaxY() {
    if (data.isEmpty) return 10.0;
    
    final values = data.map((d) => d.waterLevel).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Add some padding above maximum
    return max + (max * 0.1);
  }
}
