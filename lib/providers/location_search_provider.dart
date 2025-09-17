import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../services/india_wris_service.dart';
import '../models/dwlr_station.dart';

/// State for location-based search
class LocationSearchState {
  final List<DWLRStation> stations;
  final List<String> states;
  final List<String> districts;
  final bool isLoading;
  final String? error;
  final String? selectedState;
  final String? selectedDistrict;

  const LocationSearchState({
    this.stations = const [],
    this.states = const [],
    this.districts = const [],
    this.isLoading = false,
    this.error,
    this.selectedState,
    this.selectedDistrict,
  });

  LocationSearchState copyWith({
    List<DWLRStation>? stations,
    List<String>? states,
    List<String>? districts,
    bool? isLoading,
    String? error,
    String? selectedState,
    String? selectedDistrict,
  }) {
    return LocationSearchState(
      stations: stations ?? this.stations,
      states: states ?? this.states,
      districts: districts ?? this.districts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedState: selectedState ?? this.selectedState,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
    );
  }
}

/// Notifier for location-based search functionality
class LocationSearchNotifier extends StateNotifier<LocationSearchState> {
  final IndiaWRISService _indiaWRISService;
  final Logger _logger;

  LocationSearchNotifier(this._indiaWRISService, this._logger)
      : super(const LocationSearchState());

  /// Load available states
  Future<void> loadStates() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      _logger.i('Loading available states...');
      final states = await _indiaWRISService.getAvailableStates();
      state = state.copyWith(
        states: states,
        isLoading: false,
      );
      _logger.i('Loaded ${states.length} states');
    } catch (e) {
      _logger.e('Error loading states: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load states: $e',
      );
    }
  }

  /// Load districts for selected state
  Future<void> loadDistricts(String stateName) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedState: stateName,
      districts: [],
      selectedDistrict: null,
    );
    
    try {
      _logger.i('Loading districts for state: $stateName');
      final districts = await _indiaWRISService.getDistrictsByState(stateName);
      state = state.copyWith(
        districts: districts,
        isLoading: false,
      );
      _logger.i('Loaded ${districts.length} districts');
    } catch (e) {
      _logger.e('Error loading districts: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load districts: $e',
      );
    }
  }

  /// Load cities for selected district

  /// Search stations by location
  Future<void> searchStationsByLocation({
    String? stateName,
    String? districtName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedState: stateName,
      selectedDistrict: districtName,
    );
    
    try {
      _logger.i('Searching stations by location - State: $stateName, District: $districtName');
      final stations = await _indiaWRISService.searchStationsByLocation(
        state: stateName,
        district: districtName,
      );
      
      state = state.copyWith(
        stations: stations,
        isLoading: false,
      );
      _logger.i('Found ${stations.length} stations');
    } catch (e) {
      _logger.e('Error searching stations: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search stations: $e',
      );
    }
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(
      stations: [],
      error: null,
    );
  }

  /// Clear all selections
  void clearSelections() {
    state = state.copyWith(
      selectedState: null,
      selectedDistrict: null,
      districts: [],
      stations: [],
      error: null,
    );
  }

  /// Get water status based on current water level
  String getWaterStatus(double waterLevel) {
    if (waterLevel > 20) return 'Critical';
    if (waterLevel > 15) return 'Moderate';
    return 'Safe';
  }

  /// Get water status color
  int getWaterStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return 0xFFFF5252; // Red
      case 'moderate':
        return 0xFFFF9800; // Orange
      case 'safe':
        return 0xFF4CAF50; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}

/// Provider for location search notifier
final locationSearchProvider = StateNotifierProvider<LocationSearchNotifier, LocationSearchState>((ref) {
  return LocationSearchNotifier(IndiaWRISService(), Logger());
});
