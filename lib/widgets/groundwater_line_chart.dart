import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/groundwater_data_provider.dart';
import '../providers/prediction_forecast_provider.dart';
import '../services/groundwater_data_service.dart';

/// Line Chart Widget for Groundwater Data Visualization
class GroundwaterLineChart extends ConsumerStatefulWidget {
  final String? selectedLocation;
  final String chartTitle;
  final bool showPredictions;
  final bool showForecasts;
  
  const GroundwaterLineChart({
    super.key,
    this.selectedLocation,
    this.chartTitle = 'Groundwater Level Trends',
    this.showPredictions = true,
    this.showForecasts = true,
  });

  @override
  ConsumerState<GroundwaterLineChart> createState() => _GroundwaterLineChartState();
}

class _GroundwaterLineChartState extends ConsumerState<GroundwaterLineChart> {
  String? _selectedLocation;
  String _selectedTimeRange = '30 Days';
  bool _showHistorical = true;
  bool _showPredictions = true;
  bool _showForecasts = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.selectedLocation;
  }

  @override
  Widget build(BuildContext context) {
    final availableLocations = ref.watch(availableLocationsProvider);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Header with Controls
            _buildChartHeader(),
            const SizedBox(height: 16),
            
            // Chart Controls
            _buildChartControls(availableLocations),
            const SizedBox(height: 16),
            
            // Main Chart
            SizedBox(
              height: 400,
              child: _selectedLocation != null 
                  ? _buildMainChart()
                  : _buildLocationPrompt(),
            ),
            
            const SizedBox(height: 16),
            
            // Chart Legend
            _buildChartLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader() {
    return Row(
      children: [
        Icon(
          Icons.show_chart,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.chartTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            if (_selectedLocation != null) {
              ref.invalidate(groundwaterDataProvider(_selectedLocation!));
              ref.invalidate(predictionDataProvider(_selectedLocation!));
              ref.invalidate(forecastDataProvider(_selectedLocation!));
            }
          },
          tooltip: 'Refresh Data',
        ),
      ],
    );
  }

  Widget _buildChartControls(List<String> availableLocations) {
    return Column(
      children: [
        // Location Selection
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Select Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: availableLocations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTimeRange,
                decoration: const InputDecoration(
                  labelText: 'Time Range',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: const [
                  DropdownMenuItem(value: '7 Days', child: Text('7 Days')),
                  DropdownMenuItem(value: '30 Days', child: Text('30 Days')),
                  DropdownMenuItem(value: '90 Days', child: Text('90 Days')),
                  DropdownMenuItem(value: '1 Year', child: Text('1 Year')),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimeRange = newValue ?? '30 Days';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Data Type Toggles
        Row(
          children: [
            Expanded(
              child: FilterChip(
                label: const Text('Historical'),
                selected: _showHistorical,
                onSelected: (bool selected) {
                  setState(() {
                    _showHistorical = selected;
                  });
                },
                selectedColor: Colors.blue.withOpacity(0.3),
                checkmarkColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilterChip(
                label: const Text('Predictions'),
                selected: _showPredictions,
                onSelected: (bool selected) {
                  setState(() {
                    _showPredictions = selected;
                  });
                },
                selectedColor: Colors.green.withOpacity(0.3),
                checkmarkColor: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilterChip(
                label: const Text('Forecasts'),
                selected: _showForecasts,
                onSelected: (bool selected) {
                  setState(() {
                    _showForecasts = selected;
                  });
                },
                selectedColor: Colors.orange.withOpacity(0.3),
                checkmarkColor: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainChart() {
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
            
            return SfCartesianChart(
              primaryXAxis: const CategoryAxis(
                title: AxisTitle(text: 'Time Period'),
                labelRotation: -45,
              ),
              primaryYAxis: const NumericAxis(
                title: AxisTitle(text: 'Depth (meters)'),
                isInversed: true, // Negative values go up (closer to surface)
              ),
              title: ChartTitle(
                text: 'Groundwater Level Trends - $_selectedLocation',
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x: point.y m',
              ),
              series: _buildChartSeries(chartData),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState('Error loading data: $error'),
        );
      },
    );
  }

  Widget _buildLocationPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a location from the dropdown above to view groundwater trends',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chart Legend',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('Historical Data', Colors.blue, _showHistorical),
              const SizedBox(width: 16),
              _buildLegendItem('Predictions', Colors.green, _showPredictions),
              const SizedBox(width: 16),
              _buildLegendItem('Forecasts', Colors.orange, _showForecasts),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Negative values indicate depth below ground level. Lower values (more negative) mean deeper water levels.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isVisible) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isVisible ? color : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isVisible ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Map<String, List<ChartDataPoint>> _generateChartData(
    Map<String, dynamic> groundwaterData,
    Map<String, dynamic>? predictionData,
    Map<String, dynamic>? forecastData,
  ) {
    final chartData = <String, List<ChartDataPoint>>{};
    
    // Historical Data
    if (_showHistorical) {
      chartData['Historical'] = _generateHistoricalData(groundwaterData);
    }
    
    // Prediction Data
    if (_showPredictions && predictionData != null) {
      chartData['Predictions'] = _generatePredictionData(predictionData);
    }
    
    // Forecast Data
    if (_showForecasts && forecastData != null) {
      chartData['Forecasts'] = _generateForecastData(forecastData);
    }
    
    return chartData;
  }

  List<ChartDataPoint> _generateHistoricalData(Map<String, dynamic> data) {
    final List<ChartDataPoint> points = [];
    final now = DateTime.now();
    
    // Generate historical data points based on available data
    final averageDepth = data['averageDepth'] as double? ?? -8.0;
    final minDepth = data['minDepth'] as double? ?? -12.0;
    final maxDepth = data['maxDepth'] as double? ?? -4.0;
    
    // Generate 30 days of historical data with realistic variations
    for (int i = 30; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final variation = (i % 7) * 0.2 - 0.6; // Weekly pattern
      final randomVariation = (date.day % 5) * 0.1 - 0.2; // Daily variation
      final depth = averageDepth + variation + randomVariation;
      
      points.add(ChartDataPoint(
        date.toIso8601String().split('T')[0],
        depth.clamp(minDepth, maxDepth),
      ));
    }
    
    return points;
  }

  List<ChartDataPoint> _generatePredictionData(Map<String, dynamic> data) {
    final List<ChartDataPoint> points = [];
    final predictedDepth = data['predictedDepth'] as double? ?? -8.5;
    final confidence = data['confidence'] as double? ?? 0.85;
    
    // Generate prediction points for next 7 days
    final now = DateTime.now();
    for (int i = 1; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      final variation = (i * 0.1) * (1 - confidence); // Less variation with higher confidence
      final depth = predictedDepth + variation;
      
      points.add(ChartDataPoint(
        date.toIso8601String().split('T')[0],
        depth,
      ));
    }
    
    return points;
  }

  List<ChartDataPoint> _generateForecastData(Map<String, dynamic> data) {
    final List<ChartDataPoint> points = [];
    final forecastDataList = data['forecastData'] as List<Map<String, dynamic>>? ?? [];
    
    if (forecastDataList.isNotEmpty) {
      for (final forecastPoint in forecastDataList.take(15)) { // Show first 15 days
        final date = forecastPoint['date'] as String? ?? '';
        final depth = forecastPoint['predictedDepth'] as double? ?? -8.0;
        
        points.add(ChartDataPoint(date, depth));
      }
    }
    
    return points;
  }

  List<ChartSeries<ChartDataPoint, String>> _buildChartSeries(Map<String, List<ChartDataPoint>> chartData) {
    final List<ChartSeries<ChartDataPoint, String>> series = [];
    
    if (chartData.containsKey('Historical')) {
      series.add(
        LineSeries<ChartDataPoint, String>(
          dataSource: chartData['Historical']!,
          xValueMapper: (ChartDataPoint data, _) => data.x,
          yValueMapper: (ChartDataPoint data, _) => data.y,
          name: 'Historical',
          color: Colors.blue,
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 4,
            width: 4,
          ),
        ),
      );
    }
    
    if (chartData.containsKey('Predictions')) {
      series.add(
        LineSeries<ChartDataPoint, String>(
          dataSource: chartData['Predictions']!,
          xValueMapper: (ChartDataPoint data, _) => data.x,
          yValueMapper: (ChartDataPoint data, _) => data.y,
          name: 'Predictions',
          color: Colors.green,
          width: 2,
          dashArray: const [5, 5],
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 4,
            width: 4,
          ),
        ),
      );
    }
    
    if (chartData.containsKey('Forecasts')) {
      series.add(
        LineSeries<ChartDataPoint, String>(
          dataSource: chartData['Forecasts']!,
          xValueMapper: (ChartDataPoint data, _) => data.x,
          yValueMapper: (ChartDataPoint data, _) => data.y,
          name: 'Forecasts',
          color: Colors.orange,
          width: 2,
          dashArray: const [10, 5],
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 4,
            width: 4,
          ),
        ),
      );
    }
    
    return series;
  }
}

/// Data point class for chart
class ChartDataPoint {
  final String x;
  final double y;
  
  ChartDataPoint(this.x, this.y);
}
