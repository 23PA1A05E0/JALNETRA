import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/groundwater_data_service.dart';

/// Provider for GroundwaterDataService
final groundwaterDataServiceProvider = Provider<GroundwaterDataService>((ref) {
  return GroundwaterDataService();
});

/// Provider for available locations (for dropdown)
final availableLocationsProvider = Provider<List<String>>((ref) {
  final service = ref.read(groundwaterDataServiceProvider);
  return service.getAvailableLocations();
});

/// Provider for selected location
final selectedLocationProvider = StateProvider<String?>((ref) => null);

/// Provider for groundwater data of selected location
final groundwaterDataProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, location) async {
  final service = ref.read(groundwaterDataServiceProvider);
  return await service.getGroundwaterDataForLocation(location);
});

/// Provider for all locations data
final allLocationsDataProvider = FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final service = ref.read(groundwaterDataServiceProvider);
  return await service.getAllLocationsData();
});

/// Provider for monthly trend data
final monthlyTrendDataProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, location) {
  final service = ref.read(groundwaterDataServiceProvider);
  return service.getMonthlyTrendData(location);
});

/// Provider for daily data
final dailyDataProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, location) {
  final service = ref.read(groundwaterDataServiceProvider);
  return service.getDailyData(location);
});

/// Provider for location summary
final locationSummaryProvider = Provider.family<Map<String, dynamic>, String>((ref, location) {
  final service = ref.read(groundwaterDataServiceProvider);
  return service.getLocationSummary(location);
});

/// Provider for searched locations
final searchedLocationsProvider = StateProvider.family<List<String>, String>((ref, query) {
  final service = ref.read(groundwaterDataServiceProvider);
  return service.searchLocations(query);
});

/// Provider for locations by risk level
final locationsByRiskLevelProvider = Provider<Map<String, List<String>>>((ref) {
  final service = ref.read(groundwaterDataServiceProvider);
  return service.getLocationsByRiskLevel();
});

/// Provider for current selected location data (combines multiple providers)
final currentLocationDataProvider = Provider<AsyncValue<Map<String, dynamic>?>>((ref) {
  final selectedLocation = ref.watch(selectedLocationProvider);
  
  if (selectedLocation == null) {
    return const AsyncValue.data(null);
  }
  
  return ref.watch(groundwaterDataProvider(selectedLocation));
});

/// Provider for location statistics
final locationStatisticsProvider = Provider.family<Map<String, dynamic>, String>((ref, location) {
  final data = ref.watch(groundwaterDataProvider(location));
  
  return data.when(
    data: (data) {
      if (data == null) return {'error': 'No data available'};
      
      return {
        'locationName': data['locationName'],
        'stationCode': data['stationCode'],
        'averageDepth': data['averageDepth'],
        'maxDepth': data['maxDepth'],
        'minDepth': data['minDepth'],
        'depthRange': data['depthRange'],
        'currentStatus': data['currentStatus'],
        'trendDirection': data['trendDirection'],
        'riskLevel': data['riskLevel'],
        'lastUpdated': data['lastUpdated'],
      };
    },
    loading: () => {'loading': true},
    error: (error, stack) => {'error': error.toString()},
  );
});

/// Provider for location alerts
final locationAlertsProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, location) {
  final statistics = ref.watch(locationStatisticsProvider(location));
  
  final List<Map<String, dynamic>> alerts = [];
  
  if (statistics['error'] != null) return alerts;
  
  // Check for critical conditions
  if (statistics['riskLevel'] == 'High') {
    alerts.add({
      'type': 'critical',
      'message': 'High risk level detected for ${statistics['locationName']}',
      'severity': 'high',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  if (statistics['trendDirection'] == 'Declining') {
    alerts.add({
      'type': 'trend',
      'message': 'Declining groundwater trend detected',
      'severity': 'medium',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  return alerts;
});

/// Provider for export data
final exportDataProvider = Provider.family<Map<String, dynamic>, String>((ref, location) {
  final service = ref.read(groundwaterDataServiceProvider);
  return service.exportLocationData(location);
});
