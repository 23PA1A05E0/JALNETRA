import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/groundwater_data_provider.dart';
import '../providers/prediction_forecast_provider.dart';

/// Real-time Line Chart Widget for Groundwater Data
class RealtimeLineChart extends ConsumerStatefulWidget {
  final String? selectedLocation;
  final String chartTitle;
  final bool showPredictions;
  final bool showForecasts;
  final bool showHistorical;
  final String timeRange;
  
  const RealtimeLineChart({
    super.key,
    this.selectedLocation,
    this.chartTitle = 'Real-time Groundwater Trends',
    this.showPredictions = true,
    this.showForecasts = true,
    this.showHistorical = true,
    this.timeRange = '30 Days',
  });

  @override
  ConsumerState<RealtimeLineChart> createState() => _RealtimeLineChartState();
}

class _RealtimeLineChartState extends ConsumerState<RealtimeLineChart> {
  String? _selectedLocation;
  String _selectedTimeRange = '30 Days';
  bool _showHistorical = true;
  bool _showPredictions = true;
  bool _showForecasts = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.selectedLocation;
    _selectedTimeRange = widget.timeRange;
    _showHistorical = widget.showHistorical;
    _showPredictions = widget.showPredictions;
    _showForecasts = widget.showForecasts;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with controls
            _buildHeader(),
            const SizedBox(height: 16),
            
            // Chart content
            _buildChartContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.chartTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Time range selector
        DropdownButton<String>(
          value: _selectedTimeRange,
          items: const [
            DropdownMenuItem(value: '7 Days', child: Text('7 Days')),
            DropdownMenuItem(value: '30 Days', child: Text('30 Days')),
            DropdownMenuItem(value: '90 Days', child: Text('90 Days')),
            DropdownMenuItem(value: '1 Year', child: Text('1 Year')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTimeRange = value;
              });
            }
          },
        ),
        const SizedBox(width: 8),
        // Toggle switches
        _buildToggleSwitch('Historical', _showHistorical, (value) {
          setState(() {
            _showHistorical = value;
          });
        }),
        const SizedBox(width: 8),
        _buildToggleSwitch('Predictions', _showPredictions, (value) {
          setState(() {
            _showPredictions = value;
          });
        }),
        const SizedBox(width: 8),
        _buildToggleSwitch('Forecasts', _showForecasts, (value) {
          setState(() {
            _showForecasts = value;
          });
        }),
      ],
    );
  }

  Widget _buildToggleSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 4),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildChartContent() {
    if (_selectedLocation == null) {
      return _buildLocationPrompt();
    }

    return Consumer(
      builder: (context, ref, child) {
        final groundwaterData = ref.watch(groundwaterDataProvider(_selectedLocation!));
        final predictionData = ref.watch(predictionDataProvider(_selectedLocation!));
        final forecastData = ref.watch(forecastDataProvider(_selectedLocation!));

        return groundwaterData.when(
          data: (data) {
            if (data == null) {
              return _buildErrorState('No groundwater data available');
            }
            
            // Generate chart data
            final chartData = _generateChartData(data, predictionData.value, forecastData.value);
            
            return SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _calculateYInterval(chartData),
                    verticalInterval: _calculateXInterval(chartData),
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
                        interval: _calculateXInterval(chartData),
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Text(
                              chartData[value.toInt()].xLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _calculateYInterval(chartData),
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(1)}m',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: chartData.length.toDouble() - 1,
                  minY: _getMinY(chartData),
                  maxY: _getMaxY(chartData),
                  lineBarsData: _buildLineBarsData(chartData),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final data = chartData[touchedSpot.x.toInt()];
                          return LineTooltipItem(
                            '${data.xLabel}\n${data.y.toStringAsFixed(2)}m',
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
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => _buildErrorState('Error loading data: $error'),
        );
      },
    );
  }

  Widget _buildLocationPrompt() {
    return Consumer(
      builder: (context, ref, child) {
        final availableLocations = ref.watch(availableLocationsProvider);
        
        if (availableLocations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No locations available'),
            ),
          );
        }
        
        return Center(
          child: Column(
            children: [
              const Icon(
                Icons.location_on,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a location to view real-time data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                hint: const Text('Choose Location'),
                value: _selectedLocation,
                items: availableLocations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<ChartDataPoint> _generateChartData(
    Map<String, dynamic> groundwaterData,
    Map<String, dynamic>? predictionData,
    Map<String, dynamic>? forecastData,
  ) {
    final List<ChartDataPoint> dataPoints = [];
    final now = DateTime.now();
    
    // Historical data (last 30 days)
    if (_showHistorical) {
      final historicalData = groundwaterData['historical'] as List<dynamic>? ?? [];
      for (int i = 0; i < historicalData.length; i++) {
        final data = historicalData[i];
        final date = now.subtract(Duration(days: historicalData.length - i - 1));
        dataPoints.add(ChartDataPoint(
          x: i.toDouble(),
          y: (data['depth'] as num?)?.toDouble() ?? 0.0,
          xLabel: DateFormat('MMM dd').format(date),
          color: Colors.blue,
          label: 'Historical',
        ));
      }
    }
    
    // Current data point
    final currentDepth = (groundwaterData['current_depth'] as num?)?.toDouble() ?? 0.0;
    final currentIndex = dataPoints.length;
    dataPoints.add(ChartDataPoint(
      x: currentIndex.toDouble(),
      y: currentDepth,
      xLabel: 'Now',
      color: Colors.green,
      label: 'Current',
    ));
    
    // Prediction data
    if (_showPredictions && predictionData != null) {
      final predictions = predictionData['predictions'] as List<dynamic>? ?? [];
      for (int i = 0; i < predictions.length; i++) {
        final prediction = predictions[i];
        final date = now.add(Duration(days: i + 1));
        dataPoints.add(ChartDataPoint(
          x: (currentIndex + i + 1).toDouble(),
          y: (prediction['predicted_depth'] as num?)?.toDouble() ?? 0.0,
          xLabel: DateFormat('MMM dd').format(date),
          color: Colors.orange,
          label: 'Prediction',
        ));
      }
    }
    
    // Forecast data
    if (_showForecasts && forecastData != null) {
      final forecasts = forecastData['forecasts'] as List<dynamic>? ?? [];
      for (int i = 0; i < forecasts.length; i++) {
        final forecast = forecasts[i];
        final date = now.add(Duration(days: i + 1));
        dataPoints.add(ChartDataPoint(
          x: (currentIndex + i + 1).toDouble(),
          y: (forecast['forecasted_depth'] as num?)?.toDouble() ?? 0.0,
          xLabel: DateFormat('MMM dd').format(date),
          color: Colors.purple,
          label: 'Forecast',
        ));
      }
    }
    
    return dataPoints;
  }

  List<LineChartBarData> _buildLineBarsData(List<ChartDataPoint> chartData) {
    final List<LineChartBarData> lineBars = [];
    
    // Group data by type
    final historicalData = chartData.where((d) => d.label == 'Historical').toList();
    final currentData = chartData.where((d) => d.label == 'Current').toList();
    final predictionData = chartData.where((d) => d.label == 'Prediction').toList();
    final forecastData = chartData.where((d) => d.label == 'Forecast').toList();
    
    // Historical line
    if (historicalData.isNotEmpty && _showHistorical) {
      lineBars.add(LineChartBarData(
        spots: historicalData.map((d) => FlSpot(d.x, d.y)).toList(),
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withOpacity(0.1),
        ),
      ));
    }
    
    // Current point
    if (currentData.isNotEmpty) {
      lineBars.add(LineChartBarData(
        spots: currentData.map((d) => FlSpot(d.x, d.y)).toList(),
        isCurved: false,
        color: Colors.green,
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 6,
              color: Colors.green,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
      ));
    }
    
    // Prediction line
    if (predictionData.isNotEmpty && _showPredictions) {
      lineBars.add(LineChartBarData(
        spots: predictionData.map((d) => FlSpot(d.x, d.y)).toList(),
        isCurved: true,
        color: Colors.orange,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        dashArray: [5, 5],
      ));
    }
    
    // Forecast line
    if (forecastData.isNotEmpty && _showForecasts) {
      lineBars.add(LineChartBarData(
        spots: forecastData.map((d) => FlSpot(d.x, d.y)).toList(),
        isCurved: true,
        color: Colors.purple,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        dashArray: [3, 3],
      ));
    }
    
    return lineBars;
  }

  double _calculateYInterval(List<ChartDataPoint> data) {
    if (data.isEmpty) return 1.0;
    final minY = _getMinY(data);
    final maxY = _getMaxY(data);
    final range = maxY - minY;
    return range / 5; // 5 intervals
  }

  double _calculateXInterval(List<ChartDataPoint> data) {
    if (data.isEmpty) return 1.0;
    return (data.length / 6).ceilToDouble(); // 6 intervals
  }

  double _getMinY(List<ChartDataPoint> data) {
    if (data.isEmpty) return 0.0;
    final minY = data.map((d) => d.y).reduce((a, b) => a < b ? a : b);
    return minY - 1.0; // Add some padding
  }

  double _getMaxY(List<ChartDataPoint> data) {
    if (data.isEmpty) return 10.0;
    final maxY = data.map((d) => d.y).reduce((a, b) => a > b ? a : b);
    return maxY + 1.0; // Add some padding
  }
}

/// Data point for chart
class ChartDataPoint {
  final double x;
  final double y;
  final String xLabel;
  final Color color;
  final String label;

  ChartDataPoint({
    required this.x,
    required this.y,
    required this.xLabel,
    required this.color,
    required this.label,
  });
}
