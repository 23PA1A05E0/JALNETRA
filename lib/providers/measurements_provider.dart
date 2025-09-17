import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/measurement.dart';
import '../models/recharge_estimate.dart';
import '../services/api_service.dart';

/// State class for measurements
class MeasurementsState {
  final Map<String, List<Measurement>> measurements; // stationId -> measurements
  final Map<String, bool> isLoading; // stationId -> loading state
  final Map<String, String?> errors; // stationId -> error message
  final Map<String, DateTime?> lastUpdated; // stationId -> last update time
  final Map<String, Stream<Measurement>?> realtimeStreams; // stationId -> realtime stream

  const MeasurementsState({
    this.measurements = const {},
    this.isLoading = const {},
    this.errors = const {},
    this.lastUpdated = const {},
    this.realtimeStreams = const {},
  });

  MeasurementsState copyWith({
    Map<String, List<Measurement>>? measurements,
    Map<String, bool>? isLoading,
    Map<String, String?>? errors,
    Map<String, DateTime?>? lastUpdated,
    Map<String, Stream<Measurement>?>? realtimeStreams,
  }) {
    return MeasurementsState(
      measurements: measurements ?? this.measurements,
      isLoading: isLoading ?? this.isLoading,
      errors: errors ?? this.errors,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      realtimeStreams: realtimeStreams ?? this.realtimeStreams,
    );
  }
}

/// Notifier for managing measurements state
class MeasurementsNotifier extends StateNotifier<MeasurementsState> {
  final ApiService _apiService;
  final Logger _logger;

  MeasurementsNotifier(this._apiService, this._logger) : super(const MeasurementsState());

  /// Load measurements for a specific station
  Future<void> loadMeasurements({
    required String stationId,
    required DateTime startTime,
    required DateTime endTime,
    required TimeInterval interval,
  }) async {
    if (state.isLoading[stationId] == true) return;

    final newIsLoading = Map<String, bool>.from(state.isLoading);
    final newErrors = Map<String, String?>.from(state.errors);
    
    newIsLoading[stationId] = true;
    newErrors[stationId] = null;
    
    state = state.copyWith(isLoading: newIsLoading, errors: newErrors);
    
    try {
      _logger.i('Loading measurements for station $stationId');
      final measurements = await _apiService.getMeasurements(
        stationId: stationId,
        startTime: startTime,
        endTime: endTime,
        interval: interval,
      );
      
      final newMeasurements = Map<String, List<Measurement>>.from(state.measurements);
      final newLastUpdated = Map<String, DateTime?>.from(state.lastUpdated);
      
      newMeasurements[stationId] = measurements;
      newLastUpdated[stationId] = DateTime.now();
      newIsLoading[stationId] = false;
      
      state = state.copyWith(
        measurements: newMeasurements,
        isLoading: newIsLoading,
        lastUpdated: newLastUpdated,
      );
      
      _logger.i('Loaded ${measurements.length} measurements for station $stationId');
    } catch (e) {
      _logger.e('Error loading measurements for station $stationId: $e');
      newIsLoading[stationId] = false;
      newErrors[stationId] = e.toString();
      
      state = state.copyWith(
        isLoading: newIsLoading,
        errors: newErrors,
      );
    }
  }

  /// Start real-time monitoring for a station
  void startRealtimeMonitoring(String stationId) {
    if (state.realtimeStreams.containsKey(stationId)) return;

    _logger.i('Starting real-time monitoring for station $stationId');
    
    final stream = _apiService.subscribeRealtime(stationId);
    final newRealtimeStreams = Map<String, Stream<Measurement>?>.from(state.realtimeStreams);
    newRealtimeStreams[stationId] = stream;
    
    state = state.copyWith(realtimeStreams: newRealtimeStreams);
    
    // Listen to the stream and update measurements
    stream.listen((measurement) {
      _addRealtimeMeasurement(measurement);
    }, onError: (error) {
      _logger.e('Error in real-time stream for station $stationId: $error');
    });
  }

  /// Stop real-time monitoring for a station
  void stopRealtimeMonitoring(String stationId) {
    _logger.i('Stopping real-time monitoring for station $stationId');
    
    final newRealtimeStreams = Map<String, Stream<Measurement>?>.from(state.realtimeStreams);
    newRealtimeStreams.remove(stationId);
    
    state = state.copyWith(realtimeStreams: newRealtimeStreams);
  }

  /// Add real-time measurement to the state
  void _addRealtimeMeasurement(Measurement measurement) {
    final newMeasurements = Map<String, List<Measurement>>.from(state.measurements);
    final stationId = measurement.stationId;
    
    if (!newMeasurements.containsKey(stationId)) {
      newMeasurements[stationId] = [];
    }
    
    // Add new measurement and keep only last 100 measurements
    newMeasurements[stationId]!.add(measurement);
    if (newMeasurements[stationId]!.length > 100) {
      newMeasurements[stationId]!.removeAt(0);
    }
    
    state = state.copyWith(measurements: newMeasurements);
  }

  /// Get measurements for a station
  List<Measurement> getMeasurements(String stationId) {
    return state.measurements[stationId] ?? [];
  }

  /// Get latest measurement for a station
  Measurement? getLatestMeasurement(String stationId) {
    final measurements = getMeasurements(stationId);
    if (measurements.isEmpty) return null;
    
    measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return measurements.first;
  }

  /// Get measurements within a time range
  List<Measurement> getMeasurementsInRange({
    required String stationId,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final measurements = getMeasurements(stationId);
    return measurements.where((measurement) {
      return measurement.timestamp.isAfter(startTime) && 
             measurement.timestamp.isBefore(endTime);
    }).toList();
  }

  /// Clear measurements for a station
  void clearMeasurements(String stationId) {
    final newMeasurements = Map<String, List<Measurement>>.from(state.measurements);
    newMeasurements.remove(stationId);
    
    state = state.copyWith(measurements: newMeasurements);
    _logger.i('Cleared measurements for station $stationId');
  }
}

/// Provider for measurements state
final measurementsProvider = StateNotifierProvider<MeasurementsNotifier, MeasurementsState>((ref) {
  final apiService = ApiService();
  final logger = Logger();
  return MeasurementsNotifier(apiService, logger);
});

/// Provider for measurements of a specific station
final stationMeasurementsProvider = Provider.family<List<Measurement>, String>((ref, stationId) {
  final measurementsState = ref.watch(measurementsProvider);
  return measurementsState.measurements[stationId] ?? [];
});

/// Provider for latest measurement of a specific station
final latestMeasurementProvider = Provider.family<Measurement?, String>((ref, stationId) {
  final measurementsState = ref.watch(measurementsProvider);
  final measurements = measurementsState.measurements[stationId] ?? [];
  
  if (measurements.isEmpty) return null;
  
  measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return measurements.first;
});

/// Provider for loading state of measurements for a specific station
final measurementsLoadingProvider = Provider.family<bool, String>((ref, stationId) {
  final measurementsState = ref.watch(measurementsProvider);
  return measurementsState.isLoading[stationId] ?? false;
});

/// Provider for error state of measurements for a specific station
final measurementsErrorProvider = Provider.family<String?, String>((ref, stationId) {
  final measurementsState = ref.watch(measurementsProvider);
  return measurementsState.errors[stationId];
});

/// Provider for real-time stream of a specific station
final realtimeStreamProvider = Provider.family<Stream<Measurement>?, String>((ref, stationId) {
  final measurementsState = ref.watch(measurementsProvider);
  return measurementsState.realtimeStreams[stationId];
});

/// State class for recharge estimates
class RechargeEstimatesState {
  final Map<String, List<RechargeEstimate>> estimates; // stationId -> estimates
  final Map<String, bool> isLoading; // stationId -> loading state
  final Map<String, String?> errors; // stationId -> error message
  final Map<String, DateTime?> lastUpdated; // stationId -> last update time

  const RechargeEstimatesState({
    this.estimates = const {},
    this.isLoading = const {},
    this.errors = const {},
    this.lastUpdated = const {},
  });

  RechargeEstimatesState copyWith({
    Map<String, List<RechargeEstimate>>? estimates,
    Map<String, bool>? isLoading,
    Map<String, String?>? errors,
    Map<String, DateTime?>? lastUpdated,
  }) {
    return RechargeEstimatesState(
      estimates: estimates ?? this.estimates,
      isLoading: isLoading ?? this.isLoading,
      errors: errors ?? this.errors,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notifier for managing recharge estimates state
class RechargeEstimatesNotifier extends StateNotifier<RechargeEstimatesState> {
  final ApiService _apiService;
  final Logger _logger;

  RechargeEstimatesNotifier(this._apiService, this._logger) : super(const RechargeEstimatesState());

  /// Load recharge estimates for a specific station
  Future<void> loadRechargeEstimates({
    required String stationId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (state.isLoading[stationId] == true) return;

    final newIsLoading = Map<String, bool>.from(state.isLoading);
    final newErrors = Map<String, String?>.from(state.errors);
    
    newIsLoading[stationId] = true;
    newErrors[stationId] = null;
    
    state = state.copyWith(isLoading: newIsLoading, errors: newErrors);
    
    try {
      _logger.i('Loading recharge estimates for station $stationId');
      final estimates = await _apiService.getRechargeEstimates(
        stationId: stationId,
        startTime: startTime,
        endTime: endTime,
      );
      
      final newEstimates = Map<String, List<RechargeEstimate>>.from(state.estimates);
      final newLastUpdated = Map<String, DateTime?>.from(state.lastUpdated);
      
      newEstimates[stationId] = estimates;
      newLastUpdated[stationId] = DateTime.now();
      newIsLoading[stationId] = false;
      
      state = state.copyWith(
        estimates: newEstimates,
        isLoading: newIsLoading,
        lastUpdated: newLastUpdated,
      );
      
      _logger.i('Loaded ${estimates.length} recharge estimates for station $stationId');
    } catch (e) {
      _logger.e('Error loading recharge estimates for station $stationId: $e');
      newIsLoading[stationId] = false;
      newErrors[stationId] = e.toString();
      
      state = state.copyWith(
        isLoading: newIsLoading,
        errors: newErrors,
      );
    }
  }

  /// Get recharge estimates for a station
  List<RechargeEstimate> getRechargeEstimates(String stationId) {
    return state.estimates[stationId] ?? [];
  }

  /// Get latest recharge estimate for a station
  RechargeEstimate? getLatestRechargeEstimate(String stationId) {
    final estimates = getRechargeEstimates(stationId);
    if (estimates.isEmpty) return null;
    
    estimates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return estimates.first;
  }

  /// Get average recharge rate for a station
  double getAverageRechargeRate(String stationId) {
    final estimates = getRechargeEstimates(stationId);
    if (estimates.isEmpty) return 0.0;
    
    final totalRate = estimates.map((e) => e.estimatedRechargeRate).reduce((a, b) => a + b);
    return totalRate / estimates.length;
  }

  /// Get recharge estimates within a time range
  List<RechargeEstimate> getRechargeEstimatesInRange({
    required String stationId,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final estimates = getRechargeEstimates(stationId);
    return estimates.where((estimate) {
      return estimate.timestamp.isAfter(startTime) && 
             estimate.timestamp.isBefore(endTime);
    }).toList();
  }
}

/// Provider for recharge estimates state
final rechargeEstimatesProvider = StateNotifierProvider<RechargeEstimatesNotifier, RechargeEstimatesState>((ref) {
  final apiService = ApiService();
  final logger = Logger();
  return RechargeEstimatesNotifier(apiService, logger);
});

/// Provider for recharge estimates of a specific station
final stationRechargeEstimatesProvider = Provider.family<List<RechargeEstimate>, String>((ref, stationId) {
  final estimatesState = ref.watch(rechargeEstimatesProvider);
  return estimatesState.estimates[stationId] ?? [];
});

/// Provider for latest recharge estimate of a specific station
final latestRechargeEstimateProvider = Provider.family<RechargeEstimate?, String>((ref, stationId) {
  final estimatesState = ref.watch(rechargeEstimatesProvider);
  final estimates = estimatesState.estimates[stationId] ?? [];
  
  if (estimates.isEmpty) return null;
  
  estimates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return estimates.first;
});

/// Provider for average recharge rate of a specific station
final averageRechargeRateProvider = Provider.family<double, String>((ref, stationId) {
  final estimatesState = ref.watch(rechargeEstimatesProvider);
  final estimates = estimatesState.estimates[stationId] ?? [];
  
  if (estimates.isEmpty) return 0.0;
  
  final totalRate = estimates.map((e) => e.estimatedRechargeRate).reduce((a, b) => a + b);
  return totalRate / estimates.length;
});
