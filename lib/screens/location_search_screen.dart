import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/location_search_provider.dart';
import '../widgets/water_status_card.dart';

/// Screen for users to search groundwater stations by location
class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load states when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationSearchProvider.notifier).loadStates();
    });
  }

  @override
  void dispose() {
    _stateController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(locationSearchProvider);
    final searchNotifier = ref.read(locationSearchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search by Location'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              searchNotifier.clearSelections();
              _stateController.clear();
              _districtController.clear();
            },
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Location Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // State Dropdown
                DropdownButtonFormField<String>(
                  value: searchState.selectedState,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: searchState.states.map((state) {
                    return DropdownMenuItem(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (state) {
                    if (state != null) {
                      _stateController.text = state;
                      searchNotifier.loadDistricts(state);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // District Dropdown
                DropdownButtonFormField<String>(
                  value: searchState.selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  items: searchState.districts.map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: searchState.selectedState != null ? (district) {
                    if (district != null) {
                      _districtController.text = district;
                    }
                  } : null,
                ),
                const SizedBox(height: 16),
                
                const SizedBox(height: 20),
                
                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: searchState.isLoading ? null : () {
                      searchNotifier.searchStationsByLocation(
                        stateName: searchState.selectedState,
                        districtName: searchState.selectedDistrict,
                      );
                    },
                    icon: searchState.isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(searchState.isLoading ? 'Searching...' : 'Search Stations'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: _buildResultsSection(searchState, searchNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(LocationSearchState searchState, LocationSearchNotifier searchNotifier) {
    if (searchState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching for stations...'),
          ],
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${searchState.error}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                searchNotifier.searchStationsByLocation(
                  stateName: searchState.selectedState,
                  districtName: searchState.selectedDistrict,
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (searchState.stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No stations found for the selected location.\nTry selecting a different state, district, or city.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                searchNotifier.clearSelections();
                _stateController.clear();
                _districtController.clear();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Start New Search'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.water_drop,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Found ${searchState.stations.length} station(s)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.go('/map'),
                icon: const Icon(Icons.map),
                label: const Text('View on Map'),
              ),
            ],
          ),
        ),
        
        // Stations List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: searchState.stations.length,
            itemBuilder: (context, index) {
              final station = searchState.stations[index];
              final waterStatus = searchNotifier.getWaterStatus(station.currentWaterLevel);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => context.go('/station/${station.stationId}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Station Header
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.stationName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${station.district}, ${station.state}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            WaterStatusCard(
                              status: WaterStatus.values.firstWhere(
                                (s) => s.name.toLowerCase() == waterStatus.toLowerCase(),
                                orElse: () => WaterStatus.safe,
                              ),
                              title: waterStatus,
                              subtitle: '${station.currentWaterLevel.toStringAsFixed(1)}m',
                              stations: [station],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Station Details
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                Icons.water_drop,
                                'Water Level',
                                '${station.currentWaterLevel.toStringAsFixed(1)} m',
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                Icons.trending_down,
                                '24h Change',
                                '${(station.currentWaterLevel * 0.1).toStringAsFixed(1)} m',
                                color: station.currentWaterLevel > 15 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                Icons.access_time,
                                'Last Updated',
                                _formatDateTime(station.lastUpdated),
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItem(
                                Icons.info_outline,
                                'Status',
                                station.status,
                                color: station.status == 'Active' ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
