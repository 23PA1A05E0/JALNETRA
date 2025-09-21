import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../providers/prediction_forecast_provider.dart';
import '../providers/groundwater_data_provider.dart' as groundwater;
import '../services/api_service.dart';

/// Comprehensive Prediction and Forecast Screen
class PredictionForecastScreen extends ConsumerStatefulWidget {
  const PredictionForecastScreen({super.key});

  @override
  ConsumerState<PredictionForecastScreen> createState() => _PredictionForecastScreenState();
}

class _PredictionForecastScreenState extends ConsumerState<PredictionForecastScreen> {
  String? _selectedLocation;
  String _selectedTab = 'Prediction';

  @override
  Widget build(BuildContext context) {
    final availableLocations = ref.watch(groundwater.availableLocationsProvider);
    final predictionData = _selectedLocation != null 
        ? ref.watch(predictionDataProvider(_selectedLocation!))
        : const AsyncValue.data(null);
    final forecastDataRaw = _selectedLocation != null 
        ? ref.watch(groundwater.forecast30DaysProvider(_selectedLocation!))
        : const AsyncValue.data(<Map<String, dynamic>>[]);
    final AsyncValue<Map<String, dynamic>?> forecastData = forecastDataRaw.when(
      data: (data) => AsyncValue.data(data.isNotEmpty ? {'forecastData': data} : null),
      loading: () => const AsyncValue.loading(),
      error: (error, stack) => AsyncValue.error(error, stack),
    );
    final AsyncValue<Map<String, dynamic>> combinedData = _selectedLocation != null 
        ? ref.watch(combinedPredictionForecastProvider(_selectedLocation!))
        : const AsyncValue.data(<String, dynamic>{});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Predictions & Forecasts'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedLocation != null) {
                ref.invalidate(predictionDataProvider(_selectedLocation!));
                ref.invalidate(groundwater.forecast30DaysProvider(_selectedLocation!));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Location Selection
          _buildLocationSelector(availableLocations),
          
          // Tab Selection
          _buildTabSelector(),
          
          // Content based on selected tab
          Expanded(
            child: _selectedLocation == null
                ? _buildLocationPrompt()
                : _buildContent(_selectedTab, predictionData, forecastData, combinedData),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector(List<String> availableLocations) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Location for Predictions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a location',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Prediction', Icons.trending_up),
          ),
          Expanded(
            child: _buildTabButton('Forecast', Icons.timeline),
          ),
          Expanded(
            child: _buildTabButton('Combined', Icons.analytics),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
            'Choose a location from the dropdown above to view predictions and forecasts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    String tab,
    AsyncValue<Map<String, dynamic>?> predictionData,
    AsyncValue<Map<String, dynamic>?> forecastData,
    AsyncValue<Map<String, dynamic>> combinedData,
  ) {
    switch (tab) {
      case 'Prediction':
        return _buildPredictionContent(predictionData);
      case 'Forecast':
        return _buildForecastContent(forecastData);
      case 'Combined':
        return _buildCombinedContent(combinedData);
      default:
        return _buildPredictionContent(predictionData);
    }
  }

  Widget _buildPredictionContent(AsyncValue<Map<String, dynamic>?> predictionData) {
    return predictionData.when(
      data: (data) {
        if (data == null) {
          return _buildErrorState('No prediction data available');
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prediction Overview
              _buildPredictionOverview(data),
              const SizedBox(height: 24),
              
              // Prediction Details
              _buildPredictionDetails(data),
              const SizedBox(height: 24),
              
              // Confidence Chart
              _buildConfidenceChart(data),
              const SizedBox(height: 24),
              
              // Prediction Alerts
              _buildPredictionAlerts(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState('Error loading prediction data: $error'),
    );
  }

  Widget _buildForecastContent(AsyncValue<Map<String, dynamic>?> forecastData) {
    return forecastData.when(
      data: (data) {
        if (data == null) {
          return _buildErrorState('No forecast data available');
        }
        
        // Debug: Print the actual data being used
        print('=== FORECAST DATA DEBUG ===');
        print('Data keys: ${data.keys}');
        if (data['forecastData'] != null) {
          final forecastList = data['forecastData'] as List;
          print('Forecast list length: ${forecastList.length}');
          if (forecastList.isNotEmpty) {
            print('First forecast point: ${forecastList.first}');
            print('Last forecast point: ${forecastList.last}');
          }
        }
        print('=== END DEBUG ===');
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test API Button
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'API Test',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _testForecastAPI();
                        },
                        child: const Text('Test Forecast API Directly'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Forecast Overview
              _buildForecastOverview(data),
              const SizedBox(height: 24),
              
              // Forecast Chart
              _buildForecastChart(data),
              const SizedBox(height: 24),
              
              // Forecast Statistics
              _buildForecastStatistics(data),
              const SizedBox(height: 24),
              
              // Forecast Alerts
              _buildForecastAlerts(),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState('Loading forecast data...'),
      error: (error, stack) => _buildErrorState('Error loading forecast data: $error'),
    );
  }

  Widget _buildCombinedContent(AsyncValue<Map<String, dynamic>> combinedData) {
    return combinedData.when(
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Combined Overview
              _buildCombinedOverview(data),
              const SizedBox(height: 24),
              
              // Comparison Chart
              _buildComparisonChart(data),
              const SizedBox(height: 24),
              
              // Summary Statistics
              _buildSummaryStatistics(data),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState('Error loading combined data: $error'),
    );
  }

  Widget _buildPredictionOverview(Map<String, dynamic> data) {
    final predictedDepth = data['predictedDepth'] as double? ?? 0.0;
    final confidence = data['confidence'] as double? ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prediction Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Predicted Depth',
                    '${predictedDepth.toStringAsFixed(2)}m',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Confidence',
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    Icons.analytics,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Model Version',
                    data['modelVersion'] ?? 'Unknown',
                    Icons.science,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Accuracy',
                    '${((data['accuracy'] as double? ?? 0.0) * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastOverview(Map<String, dynamic> data) {
    final forecastDataList = data['forecastData'] as List<Map<String, dynamic>>? ?? [];
    final reliability = data['reliability'] as double? ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Forecast Period',
                    data['forecastPeriod'] ?? '30 days',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Reliability',
                    '${(reliability * 100).toStringAsFixed(1)}%',
                    Icons.verified,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Data Points',
                    '${forecastDataList.length}',
                    Icons.data_usage,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Model Version',
                    data['modelVersion'] ?? 'Unknown',
                    Icons.science,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedOverview(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Combined Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Location: ${data['location']}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${_formatDateTime(data['lastUpdated'])}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChart(Map<String, dynamic> data) {
    final confidence = data['confidence'] as double? ?? 0.0;
    final accuracy = data['accuracy'] as double? ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                series: <CartesianSeries<Map<String, dynamic>, String>>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: [
                      {'metric': 'Confidence', 'value': confidence * 100},
                      {'metric': 'Accuracy', 'value': accuracy * 100},
                    ],
                    xValueMapper: (data, _) => data['metric'],
                    yValueMapper: (data, _) => data['value'],
                    name: 'Performance',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastChart(Map<String, dynamic> data) {
    final forecastDataList = data['forecastData'] as List<Map<String, dynamic>>? ?? [];
    
    // Debug print to see what data we're receiving
    print('=== CHART DEBUG ===');
    print('Forecast Chart Data: ${forecastDataList.length} points');
    if (forecastDataList.isNotEmpty) {
      print('First point: ${forecastDataList.first}');
      print('Last point: ${forecastDataList.last}');
      
      // Check if we have the right data structure
      final firstPoint = forecastDataList.first;
      print('First point keys: ${firstPoint.keys}');
      print('First point forecast value: ${firstPoint['forecast']}');
    }
    print('=== END CHART DEBUG ===');
    
    if (forecastDataList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Groundwater Forecast Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('No forecast data available from API'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Calculate data range for proper Y-axis scaling
    final forecastValues = forecastDataList.map((item) => item['forecast'] as double).toList();
    final minValue = forecastValues.reduce((a, b) => a < b ? a : b);
    final maxValue = forecastValues.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final yAxisMin = minValue - (range * 0.05); // Add 5% padding
    final yAxisMax = maxValue + (range * 0.05);
    
    // Debug print to verify data range
    print('Chart Data Range: Min=${minValue.toStringAsFixed(2)}, Max=${maxValue.toStringAsFixed(2)}');
    print('Y-Axis Range: ${yAxisMin.toStringAsFixed(2)} to ${yAxisMax.toStringAsFixed(2)}');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Groundwater Forecast Trend (30 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Station: CGWHYD0500 (Addanki)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  title: const AxisTitle(text: 'Date'),
                  labelRotation: -45, // Rotate labels for better readability
                ),
                primaryYAxis: NumericAxis(
                  title: const AxisTitle(text: 'Depth (m)'),
                  isInversed: true, // Invert Y-axis so negative values appear lower
                  minimum: yAxisMin,
                  maximum: yAxisMax,
                  numberFormat: NumberFormat('#,##0.00'),
                  interval: range / 10, // Show 10 intervals for better readability
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x : point.y m',
                  color: Colors.black87,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  borderColor: Colors.blue,
                  borderWidth: 1,
                ),
                series: <CartesianSeries<Map<String, dynamic>, String>>[
                  LineSeries<Map<String, dynamic>, String>(
                    dataSource: forecastDataList,
                    xValueMapper: (data, _) {
                      // Parse ISO date and format as DD-MMM
                      final dateValue = data['date'] as String?;
                      if (dateValue != null) {
                        try {
                          final date = DateTime.parse(dateValue);
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}';
                        } catch (e) {
                          return dateValue.substring(5, 10); // Fallback
                        }
                      }
                      return 'Unknown';
                    },
                    yValueMapper: (data, _) {
                      // Use the exact 'forecast' field from API response
                      final value = data['forecast'] as double;
                      print('Chart Point: ${data['date']} -> ${value.toStringAsFixed(2)}');
                      return value;
                    },
                    name: 'Forecast Depth',
                    color: Colors.blue,
                    width: 3,
                    markerSettings: const MarkerSettings(
                      isVisible: true,
                      height: 8,
                      width: 8,
                      color: Colors.blue,
                      borderColor: Colors.white,
                      borderWidth: 2,
                    ),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: false,
                    ),
                    enableTooltip: true,
                    animationDuration: 1500,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Data summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Data Points',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${forecastDataList.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Min Depth',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${maxValue.toStringAsFixed(2)} m',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Max Depth',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${minValue.toStringAsFixed(2)} m',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonChart(Map<String, dynamic> data) {
    // This would show comparison between prediction and forecast
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prediction vs Forecast Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Comparison chart would be implemented here'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionDetails(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prediction Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Station Code', data['stationCode'] ?? 'Unknown'),
            _buildDetailRow('Prediction Date', _formatDateTime(data['predictionDate'])),
            _buildDetailRow('Data Source', data['dataSource'] ?? 'API'),
            _buildDetailRow('Model Version', data['modelVersion'] ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastStatistics(Map<String, dynamic> data) {
    final forecastDataList = data['forecastData'] as List<Map<String, dynamic>>? ?? [];
    
    if (forecastDataList.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final depths = forecastDataList.map((d) => d['predictedDepth'] as double).toList();
    final minDepth = depths.reduce((a, b) => a < b ? a : b);
    final maxDepth = depths.reduce((a, b) => a > b ? a : b);
    final avgDepth = depths.reduce((a, b) => a + b) / depths.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Min Depth', '${minDepth.toStringAsFixed(2)}m', Icons.trending_down, Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard('Max Depth', '${maxDepth.toStringAsFixed(2)}m', Icons.trending_up, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('Avg Depth', '${avgDepth.toStringAsFixed(2)}m', Icons.water_drop, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard('Range', '${(maxDepth - minDepth).toStringAsFixed(2)}m', Icons.straighten, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatistics(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Summary statistics would be calculated and displayed here'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionAlerts() {
    final alerts = ref.watch(predictionAlertsProvider(_selectedLocation!));
    
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prediction Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...alerts.map((alert) => _buildAlertItem(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastAlerts() {
    // Similar to prediction alerts but for forecast data
    return const SizedBox.shrink();
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String? ?? 'medium';
    Color color;
    IconData icon;
    
    switch (severity) {
      case 'high':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.info;
        break;
      default:
        color = Colors.blue;
        icon = Icons.info_outline;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert['message'] ?? 'Alert',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testForecastAPI() async {
    try {
      print('=== TESTING FORECAST API DIRECTLY ===');
      
      final apiService = ApiService();
      final result = await apiService.fetchForecast('CGWHYD0500', 30);
      
      print('API Response: $result');
      print('Response keys: ${result.keys}');
      
      if (result['status'] == 'success' && result['forecast'] != null) {
        final forecastList = result['forecast'] as List;
        print('Forecast data points: ${forecastList.length}');
        
        if (forecastList.isNotEmpty) {
          print('First point: ${forecastList.first}');
          print('Last point: ${forecastList.last}');
          
          // Check the actual values
          final firstPoint = forecastList.first;
          print('First forecast value: ${firstPoint['forecast']}');
          print('First date: ${firstPoint['date']}');
        }
      } else {
        print('API returned no forecast data');
      }
      
      print('=== END API TEST ===');
    } catch (e) {
      print('API Test Error: $e');
    }
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.blue.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching 30-day groundwater forecast...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
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

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
