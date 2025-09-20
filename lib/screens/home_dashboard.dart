import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../providers/dwlr_provider.dart';
import '../models/dwlr_station.dart';
import '../widgets/overview_card.dart';
import '../widgets/mini_chart.dart';

/// Home Dashboard with overview cards and mini charts
class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  @override
  void initState() {
    super.initState();
    // Load DWLR stations when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dwlrStationsProvider.notifier).loadStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationsState = ref.watch(dwlrStationsProvider);
    final stations = stationsState.stations;
    final isLoading = stationsState.isLoading;
    final error = stationsState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groundwater Monitoring Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: GoRouter.of(context).canPop()
          ? IconButton(
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.arrow_back_ios
                  : Icons.arrow_back,
              ),
              onPressed: () {
                context.pop();
              },
              tooltip: 'Back',
            )
          : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/citizen-features'),
            tooltip: 'Citizen Features',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.go('/advanced-analytics'),
            tooltip: 'Advanced Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () => context.go('/prediction-forecast'),
            tooltip: 'Predictions & Forecasts',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () => context.go('/notification-settings'),
            tooltip: 'Notification Settings',
          ),
          IconButton(
            icon: const Icon(Icons.water_drop),
            onPressed: () => context.go('/groundwater-data'),
            tooltip: 'Groundwater Data',
          ),
          IconButton(
            icon: const Icon(Icons.api),
            onPressed: () => context.go('/api-test'),
            tooltip: 'Test API Connection',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => context.go('/groundwater-test'),
            tooltip: 'Test Groundwater API',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/stations'),
            tooltip: 'Search Stations',
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.go('/map'),
            tooltip: 'View Map',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.go('/alerts'),
            tooltip: 'View Alerts',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState(error)
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(dwlrStationsProvider.notifier).loadStations();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Overview
                        _buildQuickStats(stations),
                        const SizedBox(height: 20),
                        
                        // Recent Trends Chart
                        _buildTrendsChart(stations),
                        const SizedBox(height: 20),
                        
                        // State-wise Distribution
                        _buildStateDistribution(stations),
                        const SizedBox(height: 20),
                        
                        // Recent Stations
                        _buildRecentStations(stations),
                        const SizedBox(height: 20),
                        
                        // Quick Actions
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Build quick stats overview cards
  Widget _buildQuickStats(List<DWLRStation> stations) {
    final activeStations = stations.where((s) => s.status == 'Active').length;
    final totalStations = stations.length;
    final avgWaterLevel = stations.isNotEmpty
        ? stations.map((s) => s.currentWaterLevel).reduce((a, b) => a + b) / stations.length
        : 0.0;
    final dataAvailability = stations.isNotEmpty
        ? stations.map((s) => s.dataAvailability).reduce((a, b) => a + b) / stations.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OverviewCard(
                title: 'Total Stations',
                value: totalStations.toString(),
                icon: Icons.water_drop,
                color: Colors.blue,
                subtitle: 'DWLR Stations',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OverviewCard(
                title: 'Active Stations',
                value: activeStations.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
                subtitle: '${((activeStations / totalStations) * 100).toStringAsFixed(1)}% active',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OverviewCard(
                title: 'Avg Water Level',
                value: '${avgWaterLevel.toStringAsFixed(1)}m',
                icon: Icons.trending_down,
                color: Colors.orange,
                subtitle: 'Below ground level',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OverviewCard(
                title: 'Data Quality',
                value: '${dataAvailability.toStringAsFixed(1)}%',
                icon: Icons.analytics,
                color: Colors.purple,
                subtitle: 'Availability',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build trends chart
  Widget _buildTrendsChart(List<DWLRStation> stations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Water Level Trends (Last 30 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: MiniChart(
                data: _generateTrendData(),
                title: 'Average Water Level',
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build state-wise distribution
  Widget _buildStateDistribution(List<DWLRStation> stations) {
    final stateCounts = <String, int>{};
    for (final station in stations) {
      stateCounts[station.state] = (stateCounts[station.state] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stations by State',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stateCounts.entries.map((entry) {
              final percentage = (entry.value / stations.length) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStateColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Build recent stations list
  Widget _buildRecentStations(List<DWLRStation> stations) {
    final recentStations = stations.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Stations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/stations'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentStations.map((station) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(station.status),
                child: Text(
                  station.stationId.substring(station.stationId.length - 2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(station.stationName),
              subtitle: Text('${station.district}, ${station.state}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${station.currentWaterLevel.toStringAsFixed(1)}m',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    station.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(station.status),
                    ),
                  ),
                ],
              ),
              onTap: () => context.go('/station/${station.stationId}'),
            )).toList(),
          ],
        ),
      ),
    );
  }

  /// Build quick actions
  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/stations'),
                    icon: const Icon(Icons.search),
                    label: const Text('Search Stations'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/map'),
                    icon: const Icon(Icons.map),
                    label: const Text('View Map'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/reports'),
                    icon: const Icon(Icons.download),
                    label: const Text('Export Data'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/alerts'),
                    icon: const Icon(Icons.notifications),
                    label: const Text('View Alerts'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(dwlrStationsProvider.notifier).loadStations();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Generate mock trend data
  List<FlSpot> _generateTrendData() {
    final spots = <FlSpot>[];
    for (int i = 0; i < 30; i++) {
      final value = 15.0 + (i * 0.1) + (i % 7) * 0.5;
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
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

  /// Get state color
  Color _getStateColor(String state) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[state.hashCode % colors.length];
  }
}
