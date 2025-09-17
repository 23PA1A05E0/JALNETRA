import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stations_provider.dart';
import '../providers/measurements_provider.dart';
import '../models/station.dart';
import '../models/measurement.dart';

/// Station detail screen showing measurements and settings
class StationDetailScreen extends ConsumerStatefulWidget {
  final String stationId;

  const StationDetailScreen({
    super.key,
    required this.stationId,
  });

  @override
  ConsumerState<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends ConsumerState<StationDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRealtimeEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    // Load measurements for the last 7 days
    final endTime = DateTime.now();
    final startTime = endTime.subtract(const Duration(days: 7));
    
    ref.read(measurementsProvider.notifier).loadMeasurements(
      stationId: widget.stationId,
      startTime: startTime,
      endTime: endTime,
      interval: TimeInterval.hour,
    );
  }

  @override
  Widget build(BuildContext context) {
    final station = ref.watch(stationProvider(widget.stationId));
    final measurements = ref.watch(stationMeasurementsProvider(widget.stationId));
    final latestMeasurement = ref.watch(latestMeasurementProvider(widget.stationId));
    final isLoading = ref.watch(measurementsLoadingProvider(widget.stationId));
    final error = ref.watch(measurementsErrorProvider(widget.stationId));

    if (station == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isRealtimeEnabled ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleRealtime,
            tooltip: _isRealtimeEnabled ? 'Stop Real-time' : 'Start Real-time',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, station),
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.water_drop), text: 'Overview'),
            Tab(icon: Icon(Icons.timeline), text: 'Charts'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(station, latestMeasurement),
          _buildChartsTab(station, measurements, isLoading, error),
          _buildHistoryTab(station, measurements),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// Build overview tab
  Widget _buildOverviewTab(Station station, Measurement? latestMeasurement) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Station Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Status', station.status, _getStatusColor(station.status)),
                  _buildInfoRow('Region', station.region),
                  _buildInfoRow('District', station.district),
                  _buildInfoRow('Elevation', '${station.elevation.toStringAsFixed(1)} m'),
                  _buildInfoRow('Last Updated', _formatDateTime(station.lastUpdated)),
                ],
              ),
            ),
          ),
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
                  if (latestMeasurement != null) ...[
                    _buildMeasurementRow('Water Level', '${latestMeasurement.waterLevel.toStringAsFixed(2)} m', Icons.water_drop),
                    _buildMeasurementRow('Temperature', '${latestMeasurement.temperature.toStringAsFixed(1)} °C', Icons.thermostat),
                    _buildMeasurementRow('pH', latestMeasurement.ph.toStringAsFixed(2), Icons.science),
                    _buildMeasurementRow('Recharge Rate', '${latestMeasurement.rechargeRate.toStringAsFixed(1)} L/h', Icons.water),
                    _buildMeasurementRow('Battery', '${latestMeasurement.batteryLevel.toStringAsFixed(0)}%', Icons.battery_std),
                    _buildMeasurementRow('Signal', '${latestMeasurement.signalStrength.toStringAsFixed(0)}%', Icons.signal_cellular_alt),
                  ] else ...[
                    const Text('No recent measurements available'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Recharge status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recharge Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildRechargeStatus(station),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build charts tab
  Widget _buildChartsTab(Station station, List<Measurement> measurements, bool isLoading, String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timeline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Charts will be implemented here'),
          const SizedBox(height: 8),
          Text(
            'Using FL Chart for data visualization',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build history tab
  Widget _buildHistoryTab(Station station, List<Measurement> measurements) {
    if (measurements.isEmpty) {
      return const Center(
        child: Text('No historical data available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final measurement = measurements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getQualityColor(measurement.quality),
              child: Text(
                measurement.quality[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(_formatDateTime(measurement.timestamp)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Water Level: ${measurement.waterLevel.toStringAsFixed(2)} m'),
                Text('Temperature: ${measurement.temperature.toStringAsFixed(1)} °C'),
                Text('Recharge Rate: ${measurement.rechargeRate.toStringAsFixed(1)} L/h'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showMeasurementDetails(measurement),
            ),
          ),
        );
      },
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value, [Color? color]) {
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

  /// Build measurement row
  Widget _buildMeasurementRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Build recharge status
  Widget _buildRechargeStatus(Station station) {
    final isActive = station.isRechargeActive;
    final currentRate = station.rechargeRate;
    final targetRate = station.targetYield;
    final efficiency = targetRate > 0 ? (currentRate / targetRate * 100) : 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Status:'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'ACTIVE' : 'INACTIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Current Rate:'),
            Text('${currentRate.toStringAsFixed(1)} L/h'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Target Rate:'),
            Text('${targetRate.toStringAsFixed(1)} L/h'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Efficiency:'),
            Text('${efficiency.toStringAsFixed(1)}%'),
          ],
        ),
      ],
    );
  }

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status) {
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
    switch (quality) {
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

  /// Format datetime
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Toggle real-time monitoring
  void _toggleRealtime() {
    setState(() {
      _isRealtimeEnabled = !_isRealtimeEnabled;
    });

    if (_isRealtimeEnabled) {
      ref.read(measurementsProvider.notifier).startRealtimeMonitoring(widget.stationId);
    } else {
      ref.read(measurementsProvider.notifier).stopRealtimeMonitoring(widget.stationId);
    }
  }

  /// Show settings dialog
  void _showSettingsDialog(BuildContext context, Station station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings for ${station.name}'),
        content: const Text('Settings dialog will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show measurement details
  void _showMeasurementDetails(Measurement measurement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Measurement Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timestamp: ${_formatDateTime(measurement.timestamp)}'),
            Text('Water Level: ${measurement.waterLevel.toStringAsFixed(2)} m'),
            Text('Temperature: ${measurement.temperature.toStringAsFixed(1)} °C'),
            Text('pH: ${measurement.ph.toStringAsFixed(2)}'),
            Text('Conductivity: ${measurement.conductivity.toStringAsFixed(1)} μS/cm'),
            Text('Turbidity: ${measurement.turbidity.toStringAsFixed(1)} NTU'),
            Text('Dissolved Oxygen: ${measurement.dissolvedOxygen.toStringAsFixed(1)} mg/L'),
            Text('Recharge Rate: ${measurement.rechargeRate.toStringAsFixed(1)} L/h'),
            Text('Battery Level: ${measurement.batteryLevel.toStringAsFixed(0)}%'),
            Text('Signal Strength: ${measurement.signalStrength.toStringAsFixed(0)}%'),
            Text('Quality: ${measurement.quality}'),
            if (measurement.notes.isNotEmpty)
              Text('Notes: ${measurement.notes}'),
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
}