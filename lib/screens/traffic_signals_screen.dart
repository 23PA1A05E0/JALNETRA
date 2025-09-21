import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/traffic_signal.dart';
import '../providers/traffic_signal_provider.dart';
import '../widgets/traffic_signal_widget.dart';

/// Traffic Signals Screen for regional groundwater monitoring
class TrafficSignalsScreen extends ConsumerStatefulWidget {
  const TrafficSignalsScreen({super.key});

  @override
  ConsumerState<TrafficSignalsScreen> createState() => _TrafficSignalsScreenState();
}

class _TrafficSignalsScreenState extends ConsumerState<TrafficSignalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regional Traffic Signals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.warning), text: 'Critical'),
            Tab(icon: Icon(Icons.trending_up), text: 'Monitoring'),
            Tab(icon: Icon(Icons.list), text: 'All Regions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(refreshTrafficSignalsProvider)();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCriticalTab(),
          _buildMonitoringTab(),
          _buildAllRegionsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statisticsAsync = ref.watch(trafficSignalStatisticsProvider);
        final stateWiseSummaryAsync = ref.watch(stateWiseTrafficSignalSummaryProvider);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Status Card
              TrafficSignalWidget(
                showDetails: false,
                showRecommendations: false,
              ),
              const SizedBox(height: 16),
              
              // Statistics Cards
              _buildStatisticsCards(statisticsAsync),
              const SizedBox(height: 16),
              
              // State-wise Summary
              _buildStateWiseSummary(stateWiseSummaryAsync),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCriticalTab() {
    return Consumer(
      builder: (context, ref, child) {
        final criticalRegionsAsync = ref.watch(criticalRegionsProvider);

        return criticalRegionsAsync.when(
          data: (criticalRegions) {
            if (criticalRegions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Critical Regions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All regions are within acceptable groundwater levels.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: criticalRegions.length,
              itemBuilder: (context, index) {
                final signal = criticalRegions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TrafficSignalWidget(
                    regionId: signal.regionId,
                    showDetails: true,
                    showRecommendations: true,
                    onTap: () => _showSignalDetails(context, signal),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString()),
        );
      },
    );
  }

  Widget _buildMonitoringTab() {
    return Consumer(
      builder: (context, ref, child) {
        final monitoringRegionsAsync = ref.watch(regionsRequiringMonitoringProvider);

        return monitoringRegionsAsync.when(
          data: (monitoringRegions) {
            if (monitoringRegions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monitor_outlined,
                      size: 64,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Regions Requiring Monitoring',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All regions are stable and do not require special monitoring.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: monitoringRegions.length,
              itemBuilder: (context, index) {
                final signal = monitoringRegions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TrafficSignalWidget(
                    regionId: signal.regionId,
                    showDetails: true,
                    showRecommendations: true,
                    onTap: () => _showSignalDetails(context, signal),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString()),
        );
      },
    );
  }

  Widget _buildAllRegionsTab() {
    return const TrafficSignalListWidget(
      showFilters: true,
    );
  }

  Widget _buildStatisticsCards(AsyncValue<Map<String, dynamic>> statisticsAsync) {
    return statisticsAsync.when(
      data: (statistics) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Regions',
                    '${statistics['totalRegions'] ?? 0}',
                    Icons.location_city,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Stations',
                    '${statistics['activeStations'] ?? 0}',
                    Icons.sensors,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Critical Regions',
                    '${statistics['criticalRegions'] ?? 0}',
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avg Risk Score',
                    '${((statistics['averageRiskScore'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    Icons.analytics,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateWiseSummary(AsyncValue<Map<String, Map<String, dynamic>>> stateWiseSummaryAsync) {
    return stateWiseSummaryAsync.when(
      data: (stateSummary) {
        if (stateSummary.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'State-wise Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...stateSummary.entries.map((entry) {
                  final state = entry.key;
                  final summary = entry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            state,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStateSummaryChip('Total', '${summary['totalRegions']}', Colors.blue),
                        const SizedBox(width: 8),
                        _buildStateSummaryChip('Good', '${summary['goodRegions']}', Colors.green),
                        const SizedBox(width: 8),
                        _buildStateSummaryChip('Warning', '${summary['warningRegions']}', Colors.orange),
                        const SizedBox(width: 8),
                        _buildStateSummaryChip('Critical', '${summary['criticalRegions']}', Colors.red),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildStateSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(refreshTrafficSignalsProvider)();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSignalDetails(BuildContext context, TrafficSignal signal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${signal.regionName} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TrafficSignalWidget(
                regionId: signal.regionId,
                showDetails: true,
                showRecommendations: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
