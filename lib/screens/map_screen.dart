import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dwlr_provider.dart';
import '../models/dwlr_station.dart';

/// Map screen showing all DWLR stations plotted
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String _selectedState = 'All';
  String _selectedStatus = 'All';
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    // Load stations when screen initializes
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
        title: const Text('Station Map'),
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
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dwlrStationsProvider.notifier).refreshStations();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          _buildFilterBar(),
          
          // Map placeholder
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? _buildErrorState(error)
                    : _buildMapPlaceholder(stations),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/stations'),
        tooltip: 'View List',
        child: const Icon(Icons.list),
      ),
    );
  }

  /// Build filter bar
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: const InputDecoration(
                labelText: 'State',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['All', 'Delhi', 'Haryana', 'Punjab', 'Rajasthan'].map((state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedState = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['All', 'Active', 'Inactive', 'Maintenance'].map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _showOnlyActive,
            onChanged: (value) {
              setState(() {
                _showOnlyActive = value;
              });
            },
          ),
          const SizedBox(width: 4),
          const Text('Active Only'),
        ],
      ),
    );
  }

  /// Build map placeholder
  Widget _buildMapPlaceholder(List<DWLRStation> stations) {
    final filteredStations = _applyFilters(stations);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Map header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Google Maps Integration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredStations.length} Stations',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Map content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map View Coming Soon',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Google Maps integration will be implemented here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showStationsList(filteredStations),
                    icon: const Icon(Icons.list),
                    label: const Text('View Stations List'),
                  ),
                ],
              ),
            ),
          ),
          
          // Station markers preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Station Markers Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: filteredStations.take(10).map((station) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(station.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        station.stationId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (filteredStations.length > 10)
                  Text(
                    '... and ${filteredStations.length - 10} more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
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
            'Failed to load stations',
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

  /// Apply filters to stations
  List<DWLRStation> _applyFilters(List<DWLRStation> stations) {
    var filtered = stations;

    if (_selectedState != 'All') {
      filtered = filtered.where((s) => s.state == _selectedState).toList();
    }

    if (_selectedStatus != 'All') {
      filtered = filtered.where((s) => s.status == _selectedStatus).toList();
    }

    if (_showOnlyActive) {
      filtered = filtered.where((s) => s.status == 'Active').toList();
    }

    return filtered;
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Additional filter options will be available here when Google Maps is integrated.'),
            const SizedBox(height: 16),
            const Text('Current filters:'),
            Text('State: $_selectedState'),
            Text('Status: $_selectedStatus'),
            Text('Active Only: $_showOnlyActive'),
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

  /// Show stations list
  void _showStationsList(List<DWLRStation> stations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stations (${stations.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return ListTile(
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
                trailing: Text(
                  '${station.currentWaterLevel.toStringAsFixed(1)}m',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/station/${station.stationId}');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/stations');
            },
            child: const Text('View All'),
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
}
