import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/manual_data_service.dart';

/// Provider for manual data service
final manualDataServiceProvider = Provider<ManualDataService>((ref) {
  return ManualDataService();
});

/// Provider for station data
final stationDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.read(manualDataServiceProvider);
  return await service.loadStationData();
});

/// Provider for historical data
final historicalDataProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(manualDataServiceProvider);
  final allData = await service.loadHistoricalData();
  
  // Apply filters if provided
  int limit = params['limit'] as int? ?? allData.length;
  DateTime? startDate = params['startDate'] as DateTime?;
  DateTime? endDate = params['endDate'] as DateTime?;
  
  var filteredData = allData;
  
  // Filter by date range if provided
  if (startDate != null || endDate != null) {
    filteredData = allData.where((data) {
      final dateStr = data['date'] as String?;
      if (dateStr == null) return false;
      
      try {
        final date = DateTime.parse(dateStr);
        if (startDate != null && date.isBefore(startDate)) return false;
        if (endDate != null && date.isAfter(endDate)) return false;
        return true;
      } catch (e) {
        return false;
      }
    }).toList();
  }
  
  // Apply limit
  if (limit > 0 && filteredData.length > limit) {
    filteredData = filteredData.take(limit).toList();
  }
  
  return filteredData;
});

/// Provider for data refresh trigger
final dataRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider to trigger data refresh
final refreshDataProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(stationDataProvider);
    ref.invalidate(historicalDataProvider);
    ref.read(dataRefreshProvider.notifier).state++;
  };
});

/// Provider for data statistics
final dataStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(manualDataServiceProvider);
  return await service.getDataStats();
});

/// Provider for last updated timestamp
final lastUpdatedProvider = FutureProvider<DateTime?>((ref) async {
  final service = ref.read(manualDataServiceProvider);
  return await service.getLastUpdated();
});

/// Provider to check if data exists
final hasDataProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(manualDataServiceProvider);
  return await service.hasData();
});
