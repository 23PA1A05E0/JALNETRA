import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/prediction_forecast_provider.dart';
import '../providers/groundwater_data_provider.dart';

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
    final availableLocations = ref.watch(availableLocationsProvider);
    final predictionData = _selectedLocation != null 
        ? ref.watch(predictionDataProvider(_selectedLocation!))
        : const AsyncValue.data(null);
    final forecastData = _selectedLocation != null 
        ? ref.watch(forecastDataProvider(_selectedLocation!))
        : const AsyncValue.data(null);
    final combinedData = _selectedLocation != null 
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
                ref.invalidate(forecastDataProvider(_selectedLocation!));
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
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
      loading: () => const Center(child: CircularProgressIndicator()),
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
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                series: <CartesianSeries<Map<String, dynamic>, String>>[
                  LineSeries<Map<String, dynamic>, String>(
                    dataSource: forecastDataList.take(15).toList(), // Show first 15 days
                    xValueMapper: (data, _) => data['date'].toString().substring(5), // Show MM-DD
                    yValueMapper: (data, _) => data['predictedDepth'] as double,
                    name: 'Predicted Depth',
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
