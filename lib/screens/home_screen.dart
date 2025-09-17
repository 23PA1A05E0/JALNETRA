import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/stations_provider.dart';
import '../models/station.dart';
import '../widgets/station_card.dart';

/// Home screen displaying station list and statistics
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedRegion = 'All';

  @override
  void initState() {
    super.initState();
    // Load stations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stationsProvider.notifier).loadStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationsState = ref.watch(stationsProvider);
    final stations = stationsState.stations;
    final isLoading = stationsState.isLoading;
    final error = stationsState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('JALNETRA'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and stats section
          _buildFilterSection(stations),
          
          // Main content area
          Expanded(
            child: _buildListView(stations, isLoading, error),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(stationsProvider.notifier).refreshStations();
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// Build filter and statistics section
  Widget _buildFilterSection(List<Station> stations) {
    final stats = ref.watch(stationStatsProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Statistics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', stats['total'].toString(), Icons.water_drop),
              _buildStatCard('Active', stats['active'].toString(), Icons.check_circle),
              _buildStatCard('Recharge', stats['rechargeActive'].toString(), Icons.water),
              _buildStatCard('Maintenance', stats['maintenance'].toString(), Icons.build),
            ],
          ),
          const SizedBox(height: 12),
          // Region filter
          Row(
            children: [
              const Text('Region: '),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedRegion,
                  isExpanded: true,
                  items: ['All', 'North', 'South', 'East', 'West'].map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRegion = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build statistics card
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Build list view
  Widget _buildListView(List<Station> stations, bool isLoading, String? error) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading stations...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(stationsProvider.notifier).loadStations();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredStations = _getFilteredStations(stations);

    if (filteredStations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No stations available'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStations.length,
      itemBuilder: (context, index) {
        final station = filteredStations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StationCard(
            station: station,
            onTap: () => context.go('/station/${station.id}'),
          ),
        );
      },
    );
  }

  /// Get filtered stations based on selected region
  List<Station> _getFilteredStations(List<Station> stations) {
    if (_selectedRegion == 'All') {
      return stations;
    }
    return stations.where((station) => station.region == _selectedRegion).toList();
  }
}