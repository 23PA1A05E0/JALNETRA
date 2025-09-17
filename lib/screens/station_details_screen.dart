import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/dwlr_provider.dart';
import '../models/dwlr_station.dart';
import '../widgets/water_level_chart.dart';
import '../widgets/station_info_card.dart';

/// Station Details screen with real-time graphs and trends
class StationDetailsScreen extends ConsumerStatefulWidget {
  final String stationId;

  const StationDetailsScreen({
    super.key,
    required this.stationId,
  });

  @override
  ConsumerState<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends ConsumerState<StationDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '30 Days';
  String _selectedInterval = 'Daily';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWaterLevelData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadWaterLevelData() {
    final endTime = DateTime.now();
    DateTime startTime;
    
    switch (_selectedTimeRange) {
      case '7 Days':
        startTime = endTime.subtract(const Duration(days: 7));
        break;
      case '30 Days':
        startTime = endTime.subtract(const Duration(days: 30));
        break;
      case '90 Days':
        startTime = endTime.subtract(const Duration(days: 90));
        break;
      case '1 Year':
        startTime = endTime.subtract(const Duration(days: 365));
        break;
      default:
        startTime = endTime.subtract(const Duration(days: 30));
    }

    ref.read(waterLevelDataProvider.notifier).loadWaterLevelData(
      stationId: widget.stationId,
      startDate: startTime,
      endDate: endTime,
      interval: _selectedInterval.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final station = ref.watch(dwlrStationProvider(widget.stationId));
    final waterLevelData = ref.watch(stationWaterLevelDataProvider(widget.stationId));
    final isLoading = ref.watch(waterLevelDataLoadingProvider(widget.stationId));
    final error = ref.watch(waterLevelDataErrorProvider(widget.stationId));

    if (station == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(station.stationName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWaterLevelData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportData(station),
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareStation(station),
            tooltip: 'Share Station',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.timeline), text: 'Charts'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(station, waterLevelData),
          _buildChartsTab(station, waterLevelData, isLoading, error),
          _buildStatisticsTab(station, waterLevelData),
          _buildHistoryTab(station, waterLevelData),
        ],
      ),
    );
  }

  /// Build overview tab
  Widget _buildOverviewTab(DWLRStation station, List<WaterLevelData> waterLevelData) {
    final latestData = waterLevelData.isNotEmpty ? waterLevelData.first : null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station info card
          StationInfoCard(station: station),
          const SizedBox(height: 16),
          
          // Current measurements card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Measurements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (latestData != null) ...[
                    _buildMeasurementRow('Water Level', '${latestData.waterLevel.toStringAsFixed(2)} m', Icons.water_drop, Colors.blue),
                    _buildMeasurementRow('Data Quality', latestData.quality, Icons.analytics, _getQualityColor(latestData.quality)),
                    if (latestData.remarks.isNotEmpty)
                      _buildMeasurementRow('Remarks', latestData.remarks, Icons.note, Colors.grey),
                  ] else ...[
                    const Text('No recent measurements available'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Station status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Station Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow('Status', station.status, _getStatusColor(station.status)),
                  _buildStatusRow('Data Availability', '${station.dataAvailability.toStringAsFixed(1)}%', _getDataQualityColor(station.dataAvailability)),
                  _buildStatusRow('Installation Date', _formatDate(station.installationDate), Colors.grey),
                  _buildStatusRow('Last Updated', _formatDateTime(station.lastUpdated), Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build charts tab
  Widget _buildChartsTab(DWLRStation station, List<WaterLevelData> waterLevelData, bool isLoading, String? error) {
    return Column(
      children: [
        // Time range and interval selector
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeRange,
                  decoration: const InputDecoration(labelText: 'Time Range'),
                  items: ['7 Days', '30 Days', '90 Days', '1 Year'].map((range) {
                    return DropdownMenuItem(
                      value: range,
                      child: Text(range),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeRange = value!;
                    });
                    _loadWaterLevelData();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedInterval,
                  decoration: const InputDecoration(labelText: 'Interval'),
                  items: ['Daily', 'Weekly', 'Monthly'].map((interval) {
                    return DropdownMenuItem(
                      value: interval,
                      child: Text(interval),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInterval = value!;
                    });
                    _loadWaterLevelData();
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Charts
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadWaterLevelData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : waterLevelData.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timeline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No data available for the selected period'),
                            ],
                          ),
                        )
                      : WaterLevelChart(
                          data: waterLevelData,
                          stationName: station.stationName,
                        ),
        ),
      ],
    );
  }

  /// Build statistics tab
  Widget _buildStatisticsTab(DWLRStation station, List<WaterLevelData> waterLevelData) {
    if (waterLevelData.isEmpty) {
      return const Center(
        child: Text('No data available for statistics'),
      );
    }

    final stats = _calculateStatistics(waterLevelData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Average', '${stats['average'].toStringAsFixed(2)}m', Icons.trending_flat, Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Minimum', '${stats['min'].toStringAsFixed(2)}m', Icons.trending_down, Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Maximum', '${stats['max'].toStringAsFixed(2)}m', Icons.trending_up, Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Range', '${stats['range'].toStringAsFixed(2)}m', Icons.straighten, Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Trend analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trend Analysis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildTrendAnalysis(stats),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build history tab
  Widget _buildHistoryTab(DWLRStation station, List<WaterLevelData> waterLevelData) {
    if (waterLevelData.isEmpty) {
      return const Center(
        child: Text('No historical data available'),
      );
    }

    // Sort by date descending
    final sortedData = List<WaterLevelData>.from(waterLevelData)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedData.length,
      itemBuilder: (context, index) {
        final data = sortedData[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getQualityColor(data.quality),
              child: Text(
                data.quality[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(_formatDateTime(data.date)),
            subtitle: Text('Water Level: ${data.waterLevel.toStringAsFixed(2)} m'),
            trailing: Text(
              '${data.waterLevel.toStringAsFixed(1)}m',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => _showDataDetails(data),
          ),
        );
      },
    );
  }

  /// Build measurement row
  Widget _buildMeasurementRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build status row
  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build stat card
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Build trend analysis
  Widget _buildTrendAnalysis(Map<String, dynamic> stats) {
    final trend = stats['trend'] as String;
    final trendPercentage = stats['trendPercentage'] as double;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Overall Trend:'),
            Row(
              children: [
                Icon(
                  trend == 'Rising' ? Icons.trending_up : 
                  trend == 'Declining' ? Icons.trending_down : Icons.trending_flat,
                  color: trend == 'Rising' ? Colors.red : 
                         trend == 'Declining' ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: trend == 'Rising' ? Colors.red : 
                           trend == 'Declining' ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Change Rate:'),
            Text(
              '${trendPercentage.abs().toStringAsFixed(1)}% ${trend == 'Rising' ? 'increase' : trend == 'Declining' ? 'decrease' : 'stable'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: trend == 'Rising' ? Colors.red : 
                       trend == 'Declining' ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Calculate statistics from water level data
  Map<String, dynamic> _calculateStatistics(List<WaterLevelData> data) {
    if (data.isEmpty) {
      return {
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'range': 0.0,
        'trend': 'Stable',
        'trendPercentage': 0.0,
      };
    }

    final values = data.map((d) => d.waterLevel).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    // Calculate trend
    final firstValue = values.first;
    final lastValue = values.last;
    final trendPercentage = ((lastValue - firstValue) / firstValue) * 100;
    
    String trend;
    if (trendPercentage > 2) {
      trend = 'Rising';
    } else if (trendPercentage < -2) {
      trend = 'Declining';
    } else {
      trend = 'Stable';
    }

    return {
      'average': average,
      'min': min,
      'max': max,
      'range': range,
      'trend': trend,
      'trendPercentage': trendPercentage,
    };
  }

  /// Export data
  void _exportData(DWLRStation station) {
    // TODO: Implement data export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data for ${station.stationName}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Share station
  void _shareStation(DWLRStation station) {
    // TODO: Implement station sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${station.stationName}...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show data details
  void _showDataDetails(WaterLevelData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Measurement Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDateTime(data.date)}'),
            Text('Water Level: ${data.waterLevel.toStringAsFixed(2)} m'),
            Text('Quality: ${data.quality}'),
            if (data.remarks.isNotEmpty)
              Text('Remarks: ${data.remarks}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get quality color
  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get data quality color
  Color _getDataQualityColor(double quality) {
    if (quality >= 90) return Colors.green;
    if (quality >= 70) return Colors.orange;
    return Colors.red;
  }

  /// Format datetime
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  /// Format date
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
