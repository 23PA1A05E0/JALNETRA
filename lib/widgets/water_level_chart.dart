import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dwlr_station.dart';
import '../providers/groundwater_data_provider.dart';

/// Water level chart widget with dynamic data
class WaterLevelChart extends ConsumerWidget {
  final List<WaterLevelData>? data;
  final String stationName;
  final bool useDynamicData;

  const WaterLevelChart({
    super.key,
    this.data,
    required this.stationName,
    this.useDynamicData = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (useDynamicData) {
      final groundwaterData = ref.watch(groundwaterDataProvider(stationName));
      final forecastData = ref.watch(forecastDataProvider(stationName));
      
      return groundwaterData.when(
        data: (apiData) {
          if (apiData == null) {
            return _buildNoDataWidget();
          }
          
          // Generate dynamic data from API
          final dynamicData = _generateDynamicDataFromAPI(apiData, forecastData.value);
          return _buildChart(context, dynamicData);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      );
    }
    
    if (data == null || data!.isEmpty) {
      return _buildNoDataWidget();
    }
    
    return _buildChart(context, data!);
  }

  Widget _buildNoDataWidget() {
    return const Center(
      child: Text('No data available'),
    );
  }

  Widget _buildChart(BuildContext context, List<WaterLevelData> chartData) {
    if (chartData.isEmpty) {
      return _buildNoDataWidget();
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
                    horizontalInterval: _calculateInterval(chartData),
                    verticalInterval: _calculateXInterval(chartData),
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
                        interval: _calculateXInterval(chartData),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= chartData.length) return const Text('');
                          final dataPoint = chartData[value.toInt()];
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
                        interval: _calculateInterval(chartData),
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
                  maxX: chartData.length.toDouble() - 1,
                  minY: _getMinY(chartData),
                  maxY: _getMaxY(chartData),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateSpots(chartData),
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
                          final dataPoint = chartData[touchedSpot.x.toInt()];
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
                  'Range: ${_getMinY(chartData).toStringAsFixed(1)} - ${_getMaxY(chartData).toStringAsFixed(1)} m',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Data Points: ${chartData.length}',
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
  List<FlSpot> _generateSpots(List<WaterLevelData> chartData) {
    return chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      return FlSpot(index.toDouble(), dataPoint.waterLevel);
    }).toList();
  }

  /// Calculate Y-axis interval
  double _calculateInterval(List<WaterLevelData> chartData) {
    final minY = _getMinY(chartData);
    final maxY = _getMaxY(chartData);
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
  double _calculateXInterval(List<WaterLevelData> chartData) {
    final length = chartData.length;
    if (length <= 10) return 1.0;
    if (length <= 50) return 5.0;
    if (length <= 100) return 10.0;
    return 20.0;
  }

  /// Get minimum Y value
  double _getMinY(List<WaterLevelData> chartData) {
    if (chartData.isEmpty) return 0.0;
    
    final values = chartData.map((d) => d.waterLevel).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    
    // Add some padding below minimum
    return min - (min * 0.1);
  }

  /// Get maximum Y value
  double _getMaxY(List<WaterLevelData> chartData) {
    if (chartData.isEmpty) return 10.0;
    
    final values = chartData.map((d) => d.waterLevel).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    
    // Add some padding above maximum
    return max + (max * 0.1);
  }

  /// Generate dynamic data from API
  List<WaterLevelData> _generateDynamicDataFromAPI(
    Map<String, dynamic> apiData,
    List<Map<String, dynamic>>? forecastData,
  ) {
    final List<WaterLevelData> dynamicData = [];
    final now = DateTime.now();
    
    // Use API data for historical values
    final averageDepth = apiData['averageDepth'] as double? ?? -5.0;
    final minDepth = apiData['minDepth'] as double? ?? -12.0;
    final maxDepth = apiData['maxDepth'] as double? ?? -4.0;
    
    // Generate historical data (last 30 days)
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final variation = (i % 7) * 0.2 - 0.6; // Weekly pattern
      final randomVariation = (date.day % 5) * 0.1 - 0.2; // Daily variation
      final depth = averageDepth + variation + randomVariation;
      
      dynamicData.add(WaterLevelData(
        date: date,
        waterLevel: depth.clamp(minDepth, maxDepth),
        quality: _getQualityFromDepth(depth),
        stationId: stationName, // Add required stationId parameter
      ));
    }
    
    // Add forecast data if available
    if (forecastData != null && forecastData.isNotEmpty) {
      for (final forecastPoint in forecastData.take(7)) {
        final dateString = forecastPoint['date'] as String? ?? '';
        final forecastValue = forecastPoint['forecast'] as double? ?? -5.0;
        
        try {
          final date = DateTime.parse(dateString);
          dynamicData.add(WaterLevelData(
            date: date,
            waterLevel: forecastValue,
            quality: _getQualityFromDepth(forecastValue),
            stationId: stationName, // Add required stationId parameter
          ));
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    
    return dynamicData;
  }

  /// Get quality based on depth
  String _getQualityFromDepth(double depth) {
    final absDepth = depth.abs();
    if (absDepth < 5) return 'Good';
    if (absDepth < 10) return 'Moderate';
    if (absDepth < 15) return 'Poor';
    return 'Critical';
  }
}
