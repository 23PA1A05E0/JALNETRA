import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/station.dart';
import '../models/measurement.dart';
import '../models/recharge_estimate.dart';

/// API service for communicating with the JALNETRA backend
class ApiService {
  static const String _baseUrl = 'http://localhost:8080/api'; // Local Dart backend
  static const String _apiKey = 'your-api-key-here'; // TODO: Move to secure storage
  
  late final Dio _dio;
  final Logger _logger = Logger();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.d(obj),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        _logger.e('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// Get all monitoring stations
  Future<List<Station>> getStations() async {
    try {
      _logger.i('Fetching stations from Dart backend...');
      
      final response = await _dio.get('/stations');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final stationsList = data['data'] as List;
          return stationsList.map((json) => Station.fromJson(json)).toList();
        }
      }
      
      // Fallback to mock data if API fails
      _logger.w('API call failed, using mock data');
      return _getMockStations();
    } catch (e) {
      _logger.e('Error fetching stations: $e');
      _logger.i('Falling back to mock data');
      return _getMockStations();
    }
  }

  /// Get measurements for a specific station within a time range
  /// TODO: Implement actual API call with proper filtering
  Future<List<Measurement>> getMeasurements({
    required String stationId,
    required DateTime startTime,
    required DateTime endTime,
    required TimeInterval interval,
  }) async {
    try {
      _logger.i('Fetching measurements for station $stationId from $startTime to $endTime');
      
      // TODO: Replace with actual API call
      // final response = await _dio.get('/stations/$stationId/measurements', queryParameters: {
      //   'start_time': startTime.toIso8601String(),
      //   'end_time': endTime.toIso8601String(),
      //   'interval': interval.name,
      // });
      // return (response.data as List)
      //     .map((json) => Measurement.fromJson(json))
      //     .toList();
      
      // Mock data for development
      await Future.delayed(const Duration(seconds: 1));
      return _getMockMeasurements(stationId, startTime, endTime, interval);
    } catch (e) {
      _logger.e('Error fetching measurements: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time updates for a station
  /// TODO: Implement WebSocket connection
  Stream<Measurement> subscribeRealtime(String stationId) async* {
    _logger.i('Subscribing to real-time updates for station $stationId');
    
    // TODO: Implement WebSocket connection
    // final socket = WebSocketChannel.connect(Uri.parse('wss://api.jalnetra.com/ws/$stationId'));
    // await for (final data in socket.stream) {
    //   final measurement = Measurement.fromJson(jsonDecode(data));
    //   yield measurement;
    // }
    
    // Mock real-time data for development
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield _generateMockRealtimeMeasurement(stationId);
    }
  }

  /// Get recharge estimates for a station
  /// TODO: Implement actual API call
  Future<List<RechargeEstimate>> getRechargeEstimates({
    required String stationId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      _logger.i('Fetching recharge estimates for station $stationId');
      
      // TODO: Replace with actual API call
      // final response = await _dio.get('/stations/$stationId/recharge-estimates', queryParameters: {
      //   'start_time': startTime.toIso8601String(),
      //   'end_time': endTime.toIso8601String(),
      // });
      // return (response.data as List)
      //     .map((json) => RechargeEstimate.fromJson(json))
      //     .toList();
      
      // Mock data for development
      await Future.delayed(const Duration(seconds: 1));
      return _getMockRechargeEstimates(stationId, startTime, endTime);
    } catch (e) {
      _logger.e('Error fetching recharge estimates: $e');
      rethrow;
    }
  }

  /// Update station configuration
  /// TODO: Implement actual API call
  Future<void> updateStationConfig({
    required String stationId,
    required RechargeConfig config,
  }) async {
    try {
      _logger.i('Updating station config for $stationId');
      
      // TODO: Replace with actual API call
      // await _dio.put('/stations/$stationId/config', data: config.toJson());
      
      // Mock success for development
      await Future.delayed(const Duration(seconds: 1));
      _logger.i('Station config updated successfully');
    } catch (e) {
      _logger.e('Error updating station config: $e');
      rethrow;
    }
  }

  /// Get station alerts
  /// TODO: Implement actual API call
  Future<List<RechargeAlert>> getStationAlerts({
    required String stationId,
    required bool unreadOnly,
  }) async {
    try {
      _logger.i('Fetching alerts for station $stationId');
      
      // TODO: Replace with actual API call
      // final response = await _dio.get('/stations/$stationId/alerts', queryParameters: {
      //   'unread_only': unreadOnly,
      // });
      // return (response.data as List)
      //     .map((json) => RechargeAlert.fromJson(json))
      //     .toList();
      
      // Mock data for development
      await Future.delayed(const Duration(seconds: 1));
      return _getMockAlerts(stationId, unreadOnly);
    } catch (e) {
      _logger.e('Error fetching alerts: $e');
      rethrow;
    }
  }

  // Mock data generators for development
  List<Station> _getMockStations() {
    return [
      Station(
        id: 'station_001',
        name: 'Central Monitoring Station',
        description: 'Primary groundwater monitoring station in downtown area',
        latitude: 28.6139,
        longitude: 77.2090,
        elevation: 216.0,
        status: 'active',
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
        region: 'North',
        district: 'Central Delhi',
        state: 'Delhi',
        country: 'India',
        parameters: ['water_level', 'temperature', 'ph', 'conductivity'],
        currentWaterLevel: 15.2,
        currentTemperature: 25.5,
        currentPh: 7.1,
        rechargeRate: 120.5,
        isRechargeActive: true,
        targetYield: 150.0,
      ),
      Station(
        id: 'station_002',
        name: 'Industrial Zone Station',
        description: 'Monitoring station near industrial area',
        latitude: 28.6200,
        longitude: 77.2200,
        elevation: 220.0,
        status: 'active',
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 3)),
        region: 'East',
        district: 'East Delhi',
        state: 'Delhi',
        country: 'India',
        parameters: ['water_level', 'temperature', 'ph'],
        currentWaterLevel: 18.7,
        currentTemperature: 27.2,
        currentPh: 6.8,
        rechargeRate: 95.3,
        isRechargeActive: false,
        targetYield: 100.0,
      ),
      Station(
        id: 'station_003',
        name: 'Residential Area Station',
        description: 'Station monitoring residential groundwater',
        latitude: 28.6000,
        longitude: 77.1900,
        elevation: 210.0,
        status: 'maintenance',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        region: 'South',
        district: 'South Delhi',
        state: 'Delhi',
        country: 'India',
        parameters: ['water_level', 'temperature', 'ph', 'turbidity'],
        currentWaterLevel: 12.8,
        currentTemperature: 24.8,
        currentPh: 7.3,
        rechargeRate: 0.0,
        isRechargeActive: false,
        targetYield: 80.0,
      ),
    ];
  }

  List<Measurement> _getMockMeasurements(
    String stationId,
    DateTime startTime,
    DateTime endTime,
    TimeInterval interval,
  ) {
    final measurements = <Measurement>[];
    final stepDuration = _getStepDuration(interval);
    
    for (var current = startTime; current.isBefore(endTime); current = current.add(stepDuration)) {
      measurements.add(Measurement(
        id: '${stationId}_${current.millisecondsSinceEpoch}',
        stationId: stationId,
        timestamp: current,
        waterLevel: 15.0 + (current.hour % 24) * 0.1,
        temperature: 25.0 + (current.hour % 24) * 0.2,
        ph: 7.0 + (current.hour % 24) * 0.05,
        conductivity: 500.0 + (current.hour % 24) * 10.0,
        turbidity: 2.0 + (current.hour % 24) * 0.1,
        dissolvedOxygen: 8.0 + (current.hour % 24) * 0.1,
        rechargeRate: 100.0 + (current.hour % 24) * 2.0,
        batteryLevel: 85.0 - (current.hour % 24) * 0.5,
        signalStrength: 90.0 - (current.hour % 24) * 0.3,
        quality: 'good',
        notes: 'Automated measurement',
      ));
    }
    
    return measurements;
  }

  Duration _getStepDuration(TimeInterval interval) {
    switch (interval) {
      case TimeInterval.minute:
        return const Duration(minutes: 1);
      case TimeInterval.hour:
        return const Duration(hours: 1);
      case TimeInterval.day:
        return const Duration(days: 1);
      case TimeInterval.week:
        return const Duration(days: 7);
      case TimeInterval.month:
        return const Duration(days: 30);
    }
  }

  Measurement _generateMockRealtimeMeasurement(String stationId) {
    final now = DateTime.now();
    return Measurement(
      id: '${stationId}_realtime_${now.millisecondsSinceEpoch}',
      stationId: stationId,
      timestamp: now,
      waterLevel: 15.0 + (now.second % 60) * 0.01,
      temperature: 25.0 + (now.second % 60) * 0.02,
      ph: 7.0 + (now.second % 60) * 0.005,
      conductivity: 500.0 + (now.second % 60) * 1.0,
      turbidity: 2.0 + (now.second % 60) * 0.01,
      dissolvedOxygen: 8.0 + (now.second % 60) * 0.01,
      rechargeRate: 100.0 + (now.second % 60) * 0.2,
      batteryLevel: 85.0 - (now.second % 60) * 0.05,
      signalStrength: 90.0 - (now.second % 60) * 0.03,
      quality: 'good',
      notes: 'Real-time measurement',
    );
  }

  List<RechargeEstimate> _getMockRechargeEstimates(
    String stationId,
    DateTime startTime,
    DateTime endTime,
  ) {
    final estimates = <RechargeEstimate>[];
    final stepDuration = const Duration(hours: 1);
    
    for (var current = startTime; current.isBefore(endTime); current = current.add(stepDuration)) {
      estimates.add(RechargeEstimate(
        id: '${stationId}_estimate_${current.millisecondsSinceEpoch}',
        stationId: stationId,
        timestamp: current,
        estimatedRechargeRate: 100.0 + (current.hour % 24) * 2.0,
        confidence: 0.8 + (current.hour % 24) * 0.01,
        method: RechargeMethod.waterLevelChange,
        parameters: {
          'water_level_change': 0.1,
          'temperature_factor': 0.05,
          'ph_factor': 0.02,
        },
        status: 'calculated',
        notes: 'Automated calculation',
        actualRechargeRate: 100.0 + (current.hour % 24) * 1.8,
        accuracy: 85.0 + (current.hour % 24) * 0.5,
      ));
    }
    
    return estimates;
  }

  List<RechargeAlert> _getMockAlerts(String stationId, bool unreadOnly) {
    return [
      RechargeAlert(
        id: 'alert_001',
        stationId: stationId,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: AlertType.lowYield,
        message: 'Recharge rate below threshold',
        severity: AlertSeverity.medium,
        isRead: !unreadOnly,
        actionRequired: 'Check pump status',
        metadata: {'threshold': 100.0, 'current_rate': 85.0},
      ),
      RechargeAlert(
        id: 'alert_002',
        stationId: stationId,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: AlertType.sensorFailure,
        message: 'Temperature sensor offline',
        severity: AlertSeverity.high,
        isRead: false,
        actionRequired: 'Schedule maintenance',
        metadata: {'sensor_id': 'temp_001'},
      ),
    ];
  }
}
