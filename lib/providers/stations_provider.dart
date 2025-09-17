import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/station.dart';
import '../services/api_service.dart';

/// Provider for the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Provider for the logger
final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

/// State class for stations
class StationsState {
  final List<Station> stations;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const StationsState({
    this.stations = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  StationsState copyWith({
    List<Station>? stations,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return StationsState(
      stations: stations ?? this.stations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for managing stations state
class StationsNotifier extends StateNotifier<StationsState> {
  final ApiService _apiService;
  final Logger _logger;

  StationsNotifier(this._apiService, this._logger) : super(const StationsState());

  /// Load all stations
  Future<void> loadStations() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      _logger.i('Loading stations...');
      final stations = await _apiService.getStations();
      state = state.copyWith(
        stations: stations,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      _logger.i('Loaded ${stations.length} stations');
    } catch (e) {
      _logger.e('Error loading stations: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh stations data
  Future<void> refreshStations() async {
    _logger.i('Refreshing stations...');
    await loadStations();
  }

  /// Get station by ID
  Station? getStationById(String id) {
    try {
      return state.stations.firstWhere((station) => station.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update station status
  void updateStationStatus(String stationId, String status) {
    final stations = state.stations.map((station) {
      if (station.id == stationId) {
        return station.copyWith(status: status);
      }
      return station;
    }).toList();

    state = state.copyWith(stations: stations);
    _logger.i('Updated station $stationId status to $status');
  }

  /// Update station recharge rate
  void updateStationRechargeRate(String stationId, double rechargeRate) {
    final stations = state.stations.map((station) {
      if (station.id == stationId) {
        return station.copyWith(rechargeRate: rechargeRate);
      }
      return station;
    }).toList();

    state = state.copyWith(stations: stations);
    _logger.i('Updated station $stationId recharge rate to $rechargeRate');
  }

  /// Get active stations
  List<Station> get activeStations {
    return state.stations.where((station) => station.status == 'active').toList();
  }

  /// Get stations with active recharge
  List<Station> get rechargeActiveStations {
    return state.stations.where((station) => station.isRechargeActive).toList();
  }

  /// Get stations by region
  List<Station> getStationsByRegion(String region) {
    return state.stations.where((station) => station.region == region).toList();
  }

  /// Get stations by status
  List<Station> getStationsByStatus(String status) {
    return state.stations.where((station) => station.status == status).toList();
  }
}

/// Provider for stations state
final stationsProvider = StateNotifierProvider<StationsNotifier, StationsState>((ref) {
  final apiService = ApiService();
  final logger = Logger();
  return StationsNotifier(apiService, logger);
});

/// Provider for active stations
final activeStationsProvider = Provider<List<Station>>((ref) {
  final stationsState = ref.watch(stationsProvider);
  return stationsState.stations.where((station) => station.status == 'active').toList();
});

/// Provider for recharge active stations
final rechargeActiveStationsProvider = Provider<List<Station>>((ref) {
  final stationsState = ref.watch(stationsProvider);
  return stationsState.stations.where((station) => station.isRechargeActive).toList();
});

/// Provider for a specific station by ID
final stationProvider = Provider.family<Station?, String>((ref, stationId) {
  final stationsState = ref.watch(stationsProvider);
  try {
    return stationsState.stations.firstWhere((station) => station.id == stationId);
  } catch (e) {
    return null;
  }
});

/// Provider for stations grouped by region
final stationsByRegionProvider = Provider<Map<String, List<Station>>>((ref) {
  final stationsState = ref.watch(stationsProvider);
  final Map<String, List<Station>> groupedStations = {};
  
  for (final station in stationsState.stations) {
    if (!groupedStations.containsKey(station.region)) {
      groupedStations[station.region] = [];
    }
    groupedStations[station.region]!.add(station);
  }
  
  return groupedStations;
});

/// Provider for station statistics
final stationStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final stationsState = ref.watch(stationsProvider);
  final stations = stationsState.stations;
  
  if (stations.isEmpty) {
    return {
      'total': 0,
      'active': 0,
      'inactive': 0,
      'maintenance': 0,
      'rechargeActive': 0,
      'avgWaterLevel': 0.0,
      'avgTemperature': 0.0,
      'avgRechargeRate': 0.0,
    };
  }
  
  final activeCount = stations.where((s) => s.status == 'active').length;
  final inactiveCount = stations.where((s) => s.status == 'inactive').length;
  final maintenanceCount = stations.where((s) => s.status == 'maintenance').length;
  final rechargeActiveCount = stations.where((s) => s.isRechargeActive).length;
  
  final avgWaterLevel = stations.map((s) => s.currentWaterLevel).reduce((a, b) => a + b) / stations.length;
  final avgTemperature = stations.map((s) => s.currentTemperature).reduce((a, b) => a + b) / stations.length;
  final avgRechargeRate = stations.map((s) => s.rechargeRate).reduce((a, b) => a + b) / stations.length;
  
  return {
    'total': stations.length,
    'active': activeCount,
    'inactive': inactiveCount,
    'maintenance': maintenanceCount,
    'rechargeActive': rechargeActiveCount,
    'avgWaterLevel': avgWaterLevel,
    'avgTemperature': avgTemperature,
    'avgRechargeRate': avgRechargeRate,
  };
});
