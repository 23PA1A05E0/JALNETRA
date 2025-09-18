import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/water_well_depth_service.dart';

/// Provider for water well depth service
final waterWellDepthServiceProvider = Provider<WaterWellDepthService>((ref) {
  return WaterWellDepthService();
});

/// Provider for well depth data (historical + predictions)
final wellDepthDataProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(waterWellDepthServiceProvider);
  
  final historicalDays = params['historicalDays'] as int? ?? 30;
  final predictionDays = params['predictionDays'] as int? ?? 7;
  
  return service.getCombinedData(
    historicalDays: historicalDays,
    predictionDays: predictionDays,
  );
});

/// Provider for real historical data
final realHistoricalWellDepthProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(waterWellDepthServiceProvider);
  return service.parseRealGroundwaterData();
});

/// Provider for historical data only (mock)
final historicalWellDepthProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final service = ref.read(waterWellDepthServiceProvider);
  return service.generateMockHistoricalData(days: days);
});

/// Provider for ML predictions based on real data
final realWellDepthPredictionsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final service = ref.read(waterWellDepthServiceProvider);
  return service.generateRealDataPredictions(days: days);
});

/// Provider for ML predictions only (mock)
final wellDepthPredictionsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final service = ref.read(waterWellDepthServiceProvider);
  return service.generateMockPredictions(days: days);
});

/// Provider for trend analysis
final wellDepthTrendProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, days) async {
  final service = ref.read(waterWellDepthServiceProvider);
  return service.getTrendAnalysis(days: days);
});

/// Provider for ML model performance
final mlModelPerformanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(waterWellDepthServiceProvider);
  return service.getModelPerformance();
});

/// Provider for data refresh trigger
final wellDepthRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider to trigger data refresh
final refreshWellDepthProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(wellDepthDataProvider);
    ref.invalidate(historicalWellDepthProvider);
    ref.invalidate(wellDepthPredictionsProvider);
    ref.invalidate(wellDepthTrendProvider);
    ref.invalidate(mlModelPerformanceProvider);
    ref.read(wellDepthRefreshProvider.notifier).state++;
  };
});

/// Provider for data statistics
final wellDepthStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(waterWellDepthServiceProvider);
  return await service.getDataStats();
});

/// Provider to check if data exists
final hasWellDepthDataProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(waterWellDepthServiceProvider);
  return await service.hasData();
});
