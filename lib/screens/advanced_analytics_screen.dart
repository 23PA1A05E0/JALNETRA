import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../providers/groundwater_data_provider.dart';
import '../services/groundwater_data_service.dart';

/// Advanced Analytics Screen with comprehensive data visualization
class AdvancedAnalyticsScreen extends ConsumerStatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  ConsumerState<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends ConsumerState<AdvancedAnalyticsScreen> {
  String _selectedTimeRange = '30 Days';
  String _selectedChartType = 'Line Chart';
  String? _selectedLocation;

  final List<String> _timeRanges = ['7 Days', '30 Days', '90 Days', '1 Year'];
  final List<String> _chartTypes = ['Line Chart', 'Bar Chart', 'Area Chart', 'Scatter Plot'];

  @override
  Widget build(BuildContext context) {
    final availableLocations = ref.watch(availableLocationsProvider);
    final allLocationsData = ref.watch(allLocationsDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allLocationsDataProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Control Panel
            _buildControlPanel(availableLocations),
            const SizedBox(height: 24),
            
            // Key Metrics Cards
            _buildKeyMetricsCards(allLocationsData),
            const SizedBox(height: 24),
            
            // Interactive Charts
            _buildInteractiveCharts(allLocationsData),
            const SizedBox(height: 24),
            
            // Location Comparison
            _buildLocationComparison(allLocationsData),
            const SizedBox(height: 24),
            
            // Trend Analysis
            _buildTrendAnalysis(allLocationsData),
            const SizedBox(height: 24),
            
            // Export Options
            _buildExportOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(List<String> availableLocations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Controls',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Locations'),
                      ),
                      ...availableLocations.map((location) => DropdownMenuItem<String>(
                        value: location,
                        child: Text(location),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
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
                    ),
                    items: _timeRanges.map((range) => DropdownMenuItem<String>(
                      value: range,
                      child: Text(range),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeRange = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedChartType,
                    decoration: const InputDecoration(
                      labelText: 'Chart Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _chartTypes.map((type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedChartType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCards(AsyncValue<Map<String, Map<String, dynamic>>> allLocationsData) {
    return allLocationsData.when(
      data: (data) {
        if (data.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No data available'),
            ),
          );
        }

        // Calculate aggregate metrics
        double totalLocations = data.length.toDouble();
        double avgDepth = data.values.map((d) => d['averageDepth'] as double).reduce((a, b) => a + b) / totalLocations;
        int criticalLocations = data.values.where((d) => d['riskLevel'] == 'High').length;
        int goodLocations = data.values.where((d) => d['riskLevel'] == 'Low').length;

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Locations',
                totalLocations.toInt().toString(),
                Icons.location_on,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Depth',
                '${avgDepth.toStringAsFixed(1)}m',
                Icons.water_drop,
                Colors.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Critical',
                criticalLocations.toString(),
                Icons.warning,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Good Status',
                goodLocations.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading metrics: $error'),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
      ),
    );
  }

  Widget _buildInteractiveCharts(AsyncValue<Map<String, Map<String, dynamic>>> allLocationsData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interactive Charts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: allLocationsData.when(
                data: (data) => _buildChart(data),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Chart Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, Map<String, dynamic>> data) {
    final chartData = data.entries.map((entry) {
      return ChartData(
        entry.key,
        entry.value['averageDepth'] as double,
        entry.value['maxDepth'] as double,
        entry.value['minDepth'] as double,
      );
    }).toList();

    switch (_selectedChartType) {
      case 'Bar Chart':
        return SfCartesianChart(
          primaryXAxis: const CategoryAxis(),
          series: <CartesianSeries<ChartData, String>>[
            ColumnSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.location,
              yValueMapper: (ChartData data, _) => data.averageDepth,
              name: 'Average Depth',
              color: Colors.blue,
            ),
          ],
        );
      case 'Area Chart':
        return SfCartesianChart(
          primaryXAxis: const CategoryAxis(),
          series: <CartesianSeries<ChartData, String>>[
            AreaSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.location,
              yValueMapper: (ChartData data, _) => data.averageDepth,
              name: 'Average Depth',
              color: Colors.cyan,
            ),
          ],
        );
      default:
        return SfCartesianChart(
          primaryXAxis: const CategoryAxis(),
          series: <CartesianSeries<ChartData, String>>[
            LineSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.location,
              yValueMapper: (ChartData data, _) => data.averageDepth,
              name: 'Average Depth',
              color: Colors.blue,
            ),
          ],
        );
    }
  }

  Widget _buildLocationComparison(AsyncValue<Map<String, Map<String, dynamic>>> allLocationsData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Comparison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            allLocationsData.when(
              data: (data) => Column(
                children: data.entries.map((entry) {
                  final locationData = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRiskColor(locationData['riskLevel'] as String),
                      child: Text(
                        entry.key.substring(0, 1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(entry.key),
                    subtitle: Text('Depth: ${locationData['averageDepth']}m | Status: ${locationData['currentStatus']}'),
                    trailing: Chip(
                      label: Text(locationData['riskLevel'] as String),
                      backgroundColor: _getRiskColor(locationData['riskLevel'] as String).withOpacity(0.2),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis(AsyncValue<Map<String, Map<String, dynamic>>> allLocationsData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Analysis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            allLocationsData.when(
              data: (data) {
                int declining = data.values.where((d) => d['trendDirection'] == 'Declining').length;
                int rising = data.values.where((d) => d['trendDirection'] == 'Rising').length;
                
                return Row(
                  children: [
                    Expanded(
                      child: _buildTrendCard('Declining', declining, Icons.trending_down, Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTrendCard('Rising', rising, Icons.trending_up, Colors.green),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(String title, int count, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement PDF export
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF Export - Coming Soon!')),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement Excel export
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Excel Export - Coming Soon!')),
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement CSV export
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV Export - Coming Soon!')),
                      );
                    },
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class ChartData {
  final String location;
  final double averageDepth;
  final double maxDepth;
  final double minDepth;

  ChartData(this.location, this.averageDepth, this.maxDepth, this.minDepth);
}

