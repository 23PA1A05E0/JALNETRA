import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dwlr_provider.dart';
import '../models/dwlr_station.dart';
import '../widgets/dwlr_station_card.dart';

/// Stations List page with filter and search functionality
class StationsListScreen extends ConsumerStatefulWidget {
  const StationsListScreen({super.key});

  @override
  ConsumerState<StationsListScreen> createState() => _StationsListScreenState();
}

class _StationsListScreenState extends ConsumerState<StationsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedState = 'All';
  String _selectedDistrict = 'All';
  String _selectedStatus = 'All';
  String _sortBy = 'Name';
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    // Load stations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dwlrStationsProvider.notifier).loadStations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationsState = ref.watch(dwlrStationsProvider);
    final stations = stationsState.stations;
    final isLoading = stationsState.isLoading;
    final error = stationsState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DWLR Stations'),
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dwlrStationsProvider.notifier).refreshStations();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          _buildSearchAndFilterBar(),
          
          // Stations list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? _buildErrorState(error)
                    : _buildStationsList(stations),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/map'),
        tooltip: 'View Map',
        child: const Icon(Icons.map),
      ),
    );
  }

  /// Build search and filter bar
  Widget _buildSearchAndFilterBar() {
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
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search stations by name, district, or state...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(dwlrStationsProvider.notifier).loadStations();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                ref.read(dwlrStationsProvider.notifier).loadStations();
              } else {
                ref.read(dwlrStationsProvider.notifier).searchStations(value);
              }
            },
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('State', _selectedState),
                const SizedBox(width: 8),
                _buildFilterChip('District', _selectedDistrict),
                const SizedBox(width: 8),
                _buildFilterChip('Status', _selectedStatus),
                const SizedBox(width: 8),
                _buildSortChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text('$label: $value'),
      selected: value != 'All',
      onSelected: (selected) {
        if (selected) {
          _showFilterDialog();
        } else {
          _clearFilter(label);
        }
      },
    );
  }

  /// Build sort chip
  Widget _buildSortChip() {
    return FilterChip(
      label: Text('Sort: $_sortBy ${_isAscending ? '↑' : '↓'}'),
      selected: true,
      onSelected: (selected) {
        _showSortDialog();
      },
    );
  }

  /// Build stations list
  Widget _buildStationsList(List<DWLRStation> stations) {
    final filteredStations = _applyFilters(stations);
    final sortedStations = _applySorting(filteredStations);

    if (sortedStations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No stations found'),
            Text('Try adjusting your search or filters'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dwlrStationsProvider.notifier).refreshStations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedStations.length,
        itemBuilder: (context, index) {
          final station = sortedStations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DWLRStationCard(
              station: station,
              onTap: () => context.go('/station/${station.stationId}'),
            ),
          );
        },
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

  /// Apply filters to stations list
  List<DWLRStation> _applyFilters(List<DWLRStation> stations) {
    var filtered = stations;

    if (_selectedState != 'All') {
      filtered = filtered.where((s) => s.state == _selectedState).toList();
    }

    if (_selectedDistrict != 'All') {
      filtered = filtered.where((s) => s.district == _selectedDistrict).toList();
    }

    if (_selectedStatus != 'All') {
      filtered = filtered.where((s) => s.status == _selectedStatus).toList();
    }

    return filtered;
  }

  /// Apply sorting to stations list
  List<DWLRStation> _applySorting(List<DWLRStation> stations) {
    final sorted = List<DWLRStation>.from(stations);

    switch (_sortBy) {
      case 'Name':
        sorted.sort((a, b) => _isAscending
            ? a.stationName.compareTo(b.stationName)
            : b.stationName.compareTo(a.stationName));
        break;
      case 'Water Level':
        sorted.sort((a, b) => _isAscending
            ? a.currentWaterLevel.compareTo(b.currentWaterLevel)
            : b.currentWaterLevel.compareTo(a.currentWaterLevel));
        break;
      case 'Status':
        sorted.sort((a, b) => _isAscending
            ? a.status.compareTo(b.status)
            : b.status.compareTo(a.status));
        break;
      case 'Last Updated':
        sorted.sort((a, b) => _isAscending
            ? a.lastUpdated.compareTo(b.lastUpdated)
            : b.lastUpdated.compareTo(a.lastUpdated));
        break;
    }

    return sorted;
  }

  /// Show filter dialog
  void _showFilterDialog() {
    final notifier = ref.read(dwlrStationsProvider.notifier);
    final uniqueStates = notifier.uniqueStates;
    final districts = _selectedState != 'All'
        ? notifier.getDistrictsForState(_selectedState)
        : <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Stations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // State filter
              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(labelText: 'State'),
                items: ['All', ...uniqueStates].map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    _selectedState = value!;
                    _selectedDistrict = 'All'; // Reset district when state changes
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // District filter
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(labelText: 'District'),
                items: ['All', ...districts].map((district) {
                  return DropdownMenuItem(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
                onChanged: districts.isNotEmpty ? (value) {
                  setDialogState(() {
                    _selectedDistrict = value!;
                  });
                } : null,
              ),
              const SizedBox(height: 16),
              
              // Status filter
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['All', 'Active', 'Inactive', 'Maintenance'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show sort dialog
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sort Stations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Name'),
                value: 'Name',
                groupValue: _sortBy,
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Water Level'),
                value: 'Water Level',
                groupValue: _sortBy,
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Status'),
                value: 'Status',
                groupValue: _sortBy,
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Last Updated'),
                value: 'Last Updated',
                groupValue: _sortBy,
                onChanged: (value) {
                  setDialogState(() {
                    _sortBy = value!;
                  });
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Ascending'),
                value: _isAscending,
                onChanged: (value) {
                  setDialogState(() {
                    _isAscending = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  /// Clear specific filter
  void _clearFilter(String filterType) {
    setState(() {
      switch (filterType) {
        case 'State':
          _selectedState = 'All';
          _selectedDistrict = 'All';
          break;
        case 'District':
          _selectedDistrict = 'All';
          break;
        case 'Status':
          _selectedStatus = 'All';
          break;
      }
    });
  }
}
