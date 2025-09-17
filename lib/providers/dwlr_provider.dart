import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/dwlr_station.dart';
import '../services/india_wris_service.dart';

/// Provider for the India-WRIS service
final indiaWRISServiceProvider = Provider<IndiaWRISService>((ref) {
  return IndiaWRISService();
});

/// Provider for the logger
final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

/// State class for DWLR stations
class DWLRStationsState {
  final List<DWLRStation> stations;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final String? searchQuery;
  final String? selectedState;
  final String? selectedDistrict;

  const DWLRStationsState({
    this.stations = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.searchQuery,
    this.selectedState,
    this.selectedDistrict,
  });

  DWLRStationsState copyWith({
    List<DWLRStation>? stations,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    String? searchQuery,
    String? selectedState,
    String? selectedDistrict,
  }) {
    return DWLRStationsState(
      stations: stations ?? this.stations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedState: selectedState ?? this.selectedState,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
    );
  }
}

/// Notifier for managing DWLR stations state
class DWLRStationsNotifier extends StateNotifier<DWLRStationsState> {
  final IndiaWRISService _indiaWRISService;
  final Logger _logger;

  DWLRStationsNotifier(this._indiaWRISService, this._logger) : super(const DWLRStationsState());

  /// Load all DWLR stations
  Future<void> loadStations() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      _logger.i('Loading DWLR stations...');
      final stations = await _indiaWRISService.getDWLRStations();
      state = state.copyWith(
        stations: stations,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      _logger.i('Loaded ${stations.length} DWLR stations');
    } catch (e) {
      _logger.e('Error loading DWLR stations: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search stations
  Future<void> searchStations(String query) async {
    if (query.isEmpty) {
      await loadStations();
      return;
    }

    state = state.copyWith(isLoading: true, searchQuery: query);
    
    try {
      _logger.i('Searching stations with query: $query');
      final stations = await _indiaWRISService.searchStations(query);
      state = state.copyWith(
        stations: stations,
        isLoading: false,
      );
      _logger.i('Found ${stations.length} stations');
    } catch (e) {
      _logger.e('Error searching stations: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Filter stations by state
  void filterByState(String? stateName) {
    state = state.copyWith(selectedState: stateName);
    _applyFilters();
  }

  /// Filter stations by district
  void filterByDistrict(String? district) {
    state = state.copyWith(selectedDistrict: district);
    _applyFilters();
  }

  /// Apply current filters
  void _applyFilters() {
    var filteredStations = state.stations;

    if (state.selectedState != null) {
      filteredStations = filteredStations
          .where((station) => station.state == state.selectedState)
          .toList();
    }

    if (state.selectedDistrict != null) {
      filteredStations = filteredStations
          .where((station) => station.district == state.selectedDistrict)
          .toList();
    }

    state = state.copyWith(stations: filteredStations);
  }

  /// Refresh stations data
  Future<void> refreshStations() async {
    _logger.i('Refreshing DWLR stations...');
    await loadStations();
  }

  /// Get station by ID
  DWLRStation? getStationById(String id) {
    try {
      return state.stations.firstWhere((station) => station.stationId == id);
    } catch (e) {
      return null;
    }
  }

  /// Get active stations
  List<DWLRStation> get activeStations {
    return state.stations.where((station) => station.status == 'Active').toList();
  }

  /// Get stations by state
  List<DWLRStation> getStationsByState(String stateName) {
    return state.stations.where((station) => station.state == stateName).toList();
  }

  /// Get stations by status
  List<DWLRStation> getStationsByStatus(String status) {
    return state.stations.where((station) => station.status == status).toList();
  }

  /// Get unique states
  List<String> get uniqueStates {
    return state.stations.map((s) => s.state).toSet().toList()..sort();
  }

  /// Get unique districts for a state
  List<String> getDistrictsForState(String stateName) {
    return state.stations
        .where((s) => s.state == stateName)
        .map((s) => s.district)
        .toSet()
        .toList()
      ..sort();
  }
}

/// Provider for DWLR stations state
final dwlrStationsProvider = StateNotifierProvider<DWLRStationsNotifier, DWLRStationsState>((ref) {
  final indiaWRISService = ref.watch(indiaWRISServiceProvider);
  final logger = ref.watch(loggerProvider);
  return DWLRStationsNotifier(indiaWRISService, logger);
});

/// Provider for active stations
final activeDWLRStationsProvider = Provider<List<DWLRStation>>((ref) {
  final stationsState = ref.watch(dwlrStationsProvider);
  return stationsState.stations.where((station) => station.status == 'Active').toList();
});

/// Provider for a specific station by ID
final dwlrStationProvider = Provider.family<DWLRStation?, String>((ref, stationId) {
  final stationsState = ref.watch(dwlrStationsProvider);
  try {
    return stationsState.stations.firstWhere((station) => station.stationId == stationId);
  } catch (e) {
    return null;
  }
});

/// Provider for stations grouped by state
final dwlrStationsByStateProvider = Provider<Map<String, List<DWLRStation>>>((ref) {
  final stationsState = ref.watch(dwlrStationsProvider);
  final Map<String, List<DWLRStation>> groupedStations = {};
  
  for (final station in stationsState.stations) {
    if (!groupedStations.containsKey(station.state)) {
      groupedStations[station.state] = [];
    }
    groupedStations[station.state]!.add(station);
  }
  
  return groupedStations;
});

/// Provider for station statistics
final dwlrStationStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final stationsState = ref.watch(dwlrStationsProvider);
  final stations = stationsState.stations;
  
  if (stations.isEmpty) {
    return {
      'total': 0,
      'active': 0,
      'inactive': 0,
      'maintenance': 0,
      'avgWaterLevel': 0.0,
      'avgDataAvailability': 0.0,
      'states': 0,
      'districts': 0,
    };
  }
  
  final activeCount = stations.where((s) => s.status == 'Active').length;
  final inactiveCount = stations.where((s) => s.status == 'Inactive').length;
  final maintenanceCount = stations.where((s) => s.status == 'Maintenance').length;
  
  final avgWaterLevel = stations.map((s) => s.currentWaterLevel).reduce((a, b) => a + b) / stations.length;
  final avgDataAvailability = stations.map((s) => s.dataAvailability).reduce((a, b) => a + b) / stations.length;
  
  final uniqueStates = stations.map((s) => s.state).toSet().length;
  final uniqueDistricts = stations.map((s) => s.district).toSet().length;
  
  return {
    'total': stations.length,
    'active': activeCount,
    'inactive': inactiveCount,
    'maintenance': maintenanceCount,
    'avgWaterLevel': avgWaterLevel,
    'avgDataAvailability': avgDataAvailability,
    'states': uniqueStates,
    'districts': uniqueDistricts,
  };
});

/// State class for water level data
class WaterLevelDataState {
  final Map<String, List<WaterLevelData>> data; // stationId -> data
  final Map<String, bool> isLoading; // stationId -> loading state
  final Map<String, String?> errors; // stationId -> error message
  final Map<String, DateTime?> lastUpdated; // stationId -> last update time

  const WaterLevelDataState({
    this.data = const {},
    this.isLoading = const {},
    this.errors = const {},
    this.lastUpdated = const {},
  });

  WaterLevelDataState copyWith({
    Map<String, List<WaterLevelData>>? data,
    Map<String, bool>? isLoading,
    Map<String, String?>? errors,
    Map<String, DateTime?>? lastUpdated,
  }) {
    return WaterLevelDataState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errors: errors ?? this.errors,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for managing water level data state
class WaterLevelDataNotifier extends StateNotifier<WaterLevelDataState> {
  final IndiaWRISService _indiaWRISService;
  final Logger _logger;

  WaterLevelDataNotifier(this._indiaWRISService, this._logger) : super(const WaterLevelDataState());

  /// Load water level data for a specific station
  Future<void> loadWaterLevelData({
    required String stationId,
    required DateTime startDate,
    required DateTime endDate,
    String interval = 'daily',
  }) async {
    if (state.isLoading[stationId] == true) return;

    final newIsLoading = Map<String, bool>.from(state.isLoading);
    final newErrors = Map<String, String?>.from(state.errors);
    
    newIsLoading[stationId] = true;
    newErrors[stationId] = null;
    
    state = state.copyWith(isLoading: newIsLoading, errors: newErrors);
    
    try {
      _logger.i('Loading water level data for station $stationId');
      final data = await _indiaWRISService.getWaterLevelData(
        stationId: stationId,
        startDate: startDate,
        endDate: endDate,
        interval: interval,
      );
      
      final newData = Map<String, List<WaterLevelData>>.from(state.data);
      final newLastUpdated = Map<String, DateTime?>.from(state.lastUpdated);
      
      newData[stationId] = data;
      newLastUpdated[stationId] = DateTime.now();
      newIsLoading[stationId] = false;
      
      state = state.copyWith(
        data: newData,
        isLoading: newIsLoading,
        lastUpdated: newLastUpdated,
      );
      
      _logger.i('Loaded ${data.length} water level records for station $stationId');
    } catch (e) {
      _logger.e('Error loading water level data for station $stationId: $e');
      newIsLoading[stationId] = false;
      newErrors[stationId] = e.toString();
      
      state = state.copyWith(
        isLoading: newIsLoading,
        errors: newErrors,
      );
    }
  }

  /// Get water level data for a station
  List<WaterLevelData> getWaterLevelData(String stationId) {
    return state.data[stationId] ?? [];
  }

  /// Get latest water level data for a station
  WaterLevelData? getLatestWaterLevelData(String stationId) {
    final data = getWaterLevelData(stationId);
    if (data.isEmpty) return null;
    
    data.sort((a, b) => b.date.compareTo(a.date));
    return data.first;
  }

  /// Clear water level data for a station
  void clearWaterLevelData(String stationId) {
    final newData = Map<String, List<WaterLevelData>>.from(state.data);
    newData.remove(stationId);
    
    state = state.copyWith(data: newData);
    _logger.i('Cleared water level data for station $stationId');
  }
}

/// Provider for water level data state
final waterLevelDataProvider = StateNotifierProvider<WaterLevelDataNotifier, WaterLevelDataState>((ref) {
  final indiaWRISService = ref.watch(indiaWRISServiceProvider);
  final logger = ref.watch(loggerProvider);
  return WaterLevelDataNotifier(indiaWRISService, logger);
});

/// Provider for water level data of a specific station
final stationWaterLevelDataProvider = Provider.family<List<WaterLevelData>, String>((ref, stationId) {
  final dataState = ref.watch(waterLevelDataProvider);
  return dataState.data[stationId] ?? [];
});

/// Provider for latest water level data of a specific station
final latestWaterLevelDataProvider = Provider.family<WaterLevelData?, String>((ref, stationId) {
  final dataState = ref.watch(waterLevelDataProvider);
  final data = dataState.data[stationId] ?? [];
  
  if (data.isEmpty) return null;
  
  data.sort((a, b) => b.date.compareTo(a.date));
  return data.first;
});

/// Provider for loading state of water level data for a specific station
final waterLevelDataLoadingProvider = Provider.family<bool, String>((ref, stationId) {
  final dataState = ref.watch(waterLevelDataProvider);
  return dataState.isLoading[stationId] ?? false;
});

/// Provider for error state of water level data for a specific station
final waterLevelDataErrorProvider = Provider.family<String?, String>((ref, stationId) {
  final dataState = ref.watch(waterLevelDataProvider);
  return dataState.errors[stationId];
});
