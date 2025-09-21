import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/traffic_signal.dart';
import '../services/traffic_signal_service.dart';

final logger = Logger();

/// Traffic Signal Service Provider
final trafficSignalServiceProvider = Provider<TrafficSignalService>((ref) {
  return TrafficSignalService();
});

/// All Traffic Signals Provider
final trafficSignalsProvider = FutureProvider<List<TrafficSignal>>((ref) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getAllTrafficSignals();
  } catch (e) {
    logger.e('❌ Error in trafficSignalsProvider: $e');
    return [];
  }
});

/// Traffic Signal for Specific Region Provider
final trafficSignalForRegionProvider = FutureProvider.family<TrafficSignal?, String>((ref, regionId) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getTrafficSignalForRegion(regionId);
  } catch (e) {
    logger.e('❌ Error in trafficSignalForRegionProvider for $regionId: $e');
    return null;
  }
});

/// Traffic Signals by State Provider
final trafficSignalsByStateProvider = FutureProvider.family<List<TrafficSignal>, String>((ref, state) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getTrafficSignalsByState(state);
  } catch (e) {
    logger.e('❌ Error in trafficSignalsByStateProvider for $state: $e');
    return [];
  }
});

/// Critical Regions Provider
final criticalRegionsProvider = FutureProvider<List<TrafficSignal>>((ref) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getCriticalRegions();
  } catch (e) {
    logger.e('❌ Error in criticalRegionsProvider: $e');
    return [];
  }
});

/// Traffic Signals Sorted by Priority Provider
final trafficSignalsSortedByPriorityProvider = FutureProvider<List<TrafficSignal>>((ref) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getTrafficSignalsSortedByPriority();
  } catch (e) {
    logger.e('❌ Error in trafficSignalsSortedByPriorityProvider: $e');
    return [];
  }
});

/// Traffic Signals by Level Provider
final trafficSignalsByLevelProvider = FutureProvider.family<List<TrafficSignal>, TrafficSignalLevel>((ref, level) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getTrafficSignalsByLevel(level);
  } catch (e) {
    logger.e('❌ Error in trafficSignalsByLevelProvider for $level: $e');
    return [];
  }
});

/// Regions Requiring Monitoring Provider
final regionsRequiringMonitoringProvider = FutureProvider<List<TrafficSignal>>((ref) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getRegionsRequiringMonitoring();
  } catch (e) {
    logger.e('❌ Error in regionsRequiringMonitoringProvider: $e');
    return [];
  }
});

/// Regions Requiring Immediate Action Provider
final regionsRequiringImmediateActionProvider = FutureProvider<List<TrafficSignal>>((ref) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getRegionsRequiringImmediateAction();
  } catch (e) {
    logger.e('❌ Error in regionsRequiringImmediateActionProvider: $e');
    return [];
  }
});

/// Traffic Signal Statistics Provider
final trafficSignalStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getTrafficSignalStatistics();
  } catch (e) {
    logger.e('❌ Error in trafficSignalStatisticsProvider: $e');
    return {};
  }
});

/// State-wise Traffic Signal Summary Provider
final stateWiseTrafficSignalSummaryProvider = FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final service = ref.read(trafficSignalServiceProvider);
  try {
    return await service.getStateWiseSummary();
  } catch (e) {
    logger.e('❌ Error in stateWiseTrafficSignalSummaryProvider: $e');
    return {};
  }
});

/// Traffic Signal Filter State Provider
class TrafficSignalFilterState {
  final TrafficSignalLevel? level;
  final String? state;
  final String? district;
  final double? minRiskScore;
  final double? maxRiskScore;
  final bool? requiresAction;
  final bool? requiresMonitoring;

  const TrafficSignalFilterState({
    this.level,
    this.state,
    this.district,
    this.minRiskScore,
    this.maxRiskScore,
    this.requiresAction,
    this.requiresMonitoring,
  });

  TrafficSignalFilterState copyWith({
    TrafficSignalLevel? level,
    String? state,
    String? district,
    double? minRiskScore,
    double? maxRiskScore,
    bool? requiresAction,
    bool? requiresMonitoring,
  }) {
    return TrafficSignalFilterState(
      level: level ?? this.level,
      state: state ?? this.state,
      district: district ?? this.district,
      minRiskScore: minRiskScore ?? this.minRiskScore,
      maxRiskScore: maxRiskScore ?? this.maxRiskScore,
      requiresAction: requiresAction ?? this.requiresAction,
      requiresMonitoring: requiresMonitoring ?? this.requiresMonitoring,
    );
  }

  bool get hasActiveFilters {
    return level != null ||
        state != null ||
        district != null ||
        minRiskScore != null ||
        maxRiskScore != null ||
        requiresAction != null ||
        requiresMonitoring != null;
  }

  TrafficSignalFilterState clearFilters() {
    return const TrafficSignalFilterState();
  }
}

/// Traffic Signal Filter State Provider
final trafficSignalFilterStateProvider = StateProvider<TrafficSignalFilterState>((ref) {
  return const TrafficSignalFilterState();
});

/// Filtered Traffic Signals Provider
final filteredTrafficSignalsProvider = FutureProvider<List<TrafficSignal>>((ref) async {
  final service = ref.read(trafficSignalServiceProvider);
  final filterState = ref.watch(trafficSignalFilterStateProvider);
  
  try {
    final allSignals = await service.getAllTrafficSignals();
    
    if (!filterState.hasActiveFilters) {
      return allSignals;
    }
    
    return service.filterTrafficSignals(
      allSignals,
      level: filterState.level,
      state: filterState.state,
      district: filterState.district,
      minRiskScore: filterState.minRiskScore,
      maxRiskScore: filterState.maxRiskScore,
      requiresAction: filterState.requiresAction,
      requiresMonitoring: filterState.requiresMonitoring,
    );
  } catch (e) {
    logger.e('❌ Error in filteredTrafficSignalsProvider: $e');
    return [];
  }
});

/// Traffic Signal Refresh Provider
final trafficSignalRefreshProvider = StateProvider<bool>((ref) => false);

/// Refresh Traffic Signals Provider
final refreshTrafficSignalsProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(trafficSignalsProvider);
    ref.invalidate(criticalRegionsProvider);
    ref.invalidate(trafficSignalsSortedByPriorityProvider);
    ref.invalidate(regionsRequiringMonitoringProvider);
    ref.invalidate(regionsRequiringImmediateActionProvider);
    ref.invalidate(trafficSignalStatisticsProvider);
    ref.invalidate(stateWiseTrafficSignalSummaryProvider);
    ref.invalidate(filteredTrafficSignalsProvider);
    
    // Update refresh state
    ref.read(trafficSignalRefreshProvider.notifier).state = !ref.read(trafficSignalRefreshProvider);
  };
});

/// Traffic Signal Loading State Provider
final trafficSignalLoadingProvider = Provider<bool>((ref) {
  final trafficSignalsAsync = ref.watch(trafficSignalsProvider);
  final criticalRegionsAsync = ref.watch(criticalRegionsProvider);
  final statisticsAsync = ref.watch(trafficSignalStatisticsProvider);
  
  return trafficSignalsAsync.isLoading ||
         criticalRegionsAsync.isLoading ||
         statisticsAsync.isLoading;
});

/// Traffic Signal Error State Provider
final trafficSignalErrorProvider = Provider<String?>((ref) {
  final trafficSignalsAsync = ref.watch(trafficSignalsProvider);
  final criticalRegionsAsync = ref.watch(criticalRegionsProvider);
  final statisticsAsync = ref.watch(trafficSignalStatisticsProvider);
  
  if (trafficSignalsAsync.hasError) {
    return trafficSignalsAsync.error.toString();
  }
  if (criticalRegionsAsync.hasError) {
    return criticalRegionsAsync.error.toString();
  }
  if (statisticsAsync.hasError) {
    return statisticsAsync.error.toString();
  }
  
  return null;
});

/// Traffic Signal Summary Provider (for dashboard widgets)
final trafficSignalSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final statisticsAsync = ref.watch(trafficSignalStatisticsProvider);
  final criticalRegionsAsync = ref.watch(criticalRegionsProvider);
  final monitoringRegionsAsync = ref.watch(regionsRequiringMonitoringProvider);
  
  if (statisticsAsync.hasValue && criticalRegionsAsync.hasValue && monitoringRegionsAsync.hasValue) {
    return {
      'totalRegions': statisticsAsync.value!['totalRegions'] ?? 0,
      'criticalRegions': criticalRegionsAsync.value!.length,
      'monitoringRegions': monitoringRegionsAsync.value!.length,
      'goodRegions': statisticsAsync.value!['goodRegions'] ?? 0,
      'warningRegions': statisticsAsync.value!['warningRegions'] ?? 0,
      'averageRiskScore': statisticsAsync.value!['averageRiskScore'] ?? 0.0,
      'totalStations': statisticsAsync.value!['totalStations'] ?? 0,
      'activeStations': statisticsAsync.value!['activeStations'] ?? 0,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
  
  return {
    'totalRegions': 0,
    'criticalRegions': 0,
    'monitoringRegions': 0,
    'goodRegions': 0,
    'warningRegions': 0,
    'averageRiskScore': 0.0,
    'totalStations': 0,
    'activeStations': 0,
    'lastUpdated': DateTime.now().toIso8601String(),
  };
});
