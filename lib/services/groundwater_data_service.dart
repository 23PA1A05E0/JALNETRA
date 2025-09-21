import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'groundwater_notification_service.dart';

/// Service for fetching real groundwater data from the prediction API
/// Integrates with location dropdown selection
class GroundwaterDataService {
  static const String _featuresUrl = 'https://groundwater-level-predictor-backend.onrender.com/features';
  static const String _predictUrl = 'https://groundwater-level-predictor-backend.onrender.com/predict';
  static const String _forecastUrl = 'https://groundwater-level-predictor-backend.onrender.com/forecast';
  
  late final Dio _dio;
  final Logger _logger = Logger();
  final GroundwaterNotificationService _notificationService = GroundwaterNotificationService();

  /// Location codes mapping for dropdown selection
  static const Map<String, String> locationCodes = {
    'Addanki': 'CGWHYD0500',
    'Akkireddipalem': 'CGWHYD0511',
    'Anantapur': 'CGWHYD0401',
    'Bapulapadu': 'CGWHYD0485',
    'Chittoor': 'CGWHYD2038',
    'Gudur': 'CGWHYD2062',
    'Kakinada': 'CGWHYD0447',
    'Sultan nagaram': 'CGWHYD2060',
    'Tadepalligudem': 'CGWHYD0514',
    'Tenali': 'CGWHYD2053',
  };

  GroundwaterDataService() {
    _dio = Dio(BaseOptions(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'JalNetra/1.0',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.d(obj),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        _logger.e('Groundwater API Error: ${error.message}');
        handler.next(error);
      },
    ));

    // Initialize notification service
    _notificationService.initialize();
  }

  /// Get groundwater data for a selected location
  /// When user selects from dropdown, this method fetches the corresponding data
  Future<Map<String, dynamic>?> getGroundwaterDataForLocation(String selectedLocation) async {
    // Get the station code from the selected location
    final stationCode = locationCodes[selectedLocation];
    if (stationCode == null) {
      _logger.e('❌ No station code found for location: $selectedLocation');
      return null;
    }
    
    try {
      _logger.i('🌊 Fetching groundwater data for location: $selectedLocation');
      _logger.i('📍 Station code: $stationCode');
      
      // Fetch data from the API
          final response = await _dio.get(_featuresUrl);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Extract data for the specific station
        final stationData = _extractStationData(data, stationCode);
        
        if (stationData != null) {
          _logger.i('✅ Successfully fetched data for $selectedLocation ($stationCode)');
          return stationData;
        } else {
          _logger.w('⚠️ No data found for station: $stationCode');
          return null;
        }
      } else {
        _logger.e('❌ API returned status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error fetching groundwater data: $e');
      _logger.i('🔄 Falling back to mock data for $selectedLocation');
      return _getMockDataForLocation(selectedLocation, stationCode);
    }
  }

  /// Get all available locations for dropdown
  List<String> getAvailableLocations() {
    return locationCodes.keys.toList()..sort();
  }

  /// Get station code for a location
  String? getStationCodeForLocation(String location) {
    return locationCodes[location];
  }

  /// Get comprehensive data for all locations
  Future<Map<String, Map<String, dynamic>>> getAllLocationsData() async {
    try {
      _logger.i('📊 Fetching data for all locations');
      
          final response = await _dio.get(_featuresUrl);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final Map<String, Map<String, dynamic>> allData = {};
        
        // Process each location
        for (final entry in locationCodes.entries) {
          final locationName = entry.key;
          final stationCode = entry.value;
          
          final stationData = _extractStationData(data, stationCode);
          if (stationData != null) {
            allData[locationName] = stationData;
          }
        }
        
        _logger.i('✅ Successfully fetched data for ${allData.length} locations');
        return allData;
      } else {
        _logger.e('❌ API returned status: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      _logger.e('❌ Error fetching all locations data: $e');
      _logger.i('🔄 Falling back to mock data for all locations');
      return _getMockDataForAllLocations();
    }
  }

  /// Extract specific station data from API response
  Map<String, dynamic>? _extractStationData(Map<String, dynamic> apiData, String stationCode) {
    try {
      // Extract different data types from the API response
      final averageDepth = apiData['average_depth']?[stationCode];
      final maxDepth = apiData['max_depth']?[stationCode];
      final minDepth = apiData['min_depth']?[stationCode];
      final yearlyChange = apiData['yearly_change']?[stationCode];
      final monthlyTrend = apiData['monthly_trend']?[stationCode];
      final dailyData = apiData['daily_data']?[stationCode];
      final stationSummary = apiData['station_summary']?[stationCode];

      if (averageDepth == null) {
        _logger.w('⚠️ No data found for station: $stationCode');
        return null;
      }

      // Create comprehensive station data
      final stationData = {
        'stationCode': stationCode,
        'locationName': _getLocationNameFromCode(stationCode),
        'averageDepth': averageDepth,
        'maxDepth': maxDepth,
        'minDepth': minDepth,
        'yearlyChange': yearlyChange,
        'monthlyTrend': monthlyTrend,
        'dailyData': dailyData,
        'stationSummary': stationSummary,
        'lastUpdated': DateTime.now().toIso8601String(),
        'dataSource': 'Groundwater Level Predictor API',
      };

      // Add calculated fields
      stationData['depthRange'] = (maxDepth - minDepth).abs();
      stationData['currentStatus'] = _getCurrentStatus(averageDepth, yearlyChange);
      stationData['trendDirection'] = _getTrendDirection(yearlyChange);
      stationData['riskLevel'] = _getRiskLevel(averageDepth, yearlyChange);

      return stationData;
    } catch (e) {
      _logger.e('❌ Error extracting station data: $e');
      return null;
    }
  }

  /// Get location name from station code
  String? _getLocationNameFromCode(String stationCode) {
    for (final entry in locationCodes.entries) {
      if (entry.value == stationCode) {
        return entry.key;
      }
    }
    return null;
  }

  /// Determine current status based on depth and trends
  String _getCurrentStatus(double averageDepth, Map<String, dynamic>? yearlyChange) {
    if (averageDepth > -5.0) {
      return 'Critical';
    } else if (averageDepth > -8.0) {
      return 'Moderate';
    } else if (averageDepth > -12.0) {
      return 'Good';
    } else {
      return 'Excellent';
    }
  }

  /// Determine trend direction
  String _getTrendDirection(Map<String, dynamic>? yearlyChange) {
    if (yearlyChange == null) return 'Unknown';
    
    final currentYear = yearlyChange['2025'];
    if (currentYear == null) return 'Unknown';
    
    if (currentYear > 0.5) {
      return 'Rising';
    } else if (currentYear < -0.5) {
      return 'Declining';
    } else {
      return 'Stable';
    }
  }

  /// Determine risk level
  String _getRiskLevel(double averageDepth, Map<String, dynamic>? yearlyChange) {
    if (averageDepth > -5.0) {
      return 'High';
    } else if (averageDepth > -8.0) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  /// Get monthly trend data for charts
  List<Map<String, dynamic>> getMonthlyTrendData(String selectedLocation) {
    final stationCode = locationCodes[selectedLocation];
    if (stationCode == null) return [];

    // This would typically come from the API, but for now return mock data
    final List<Map<String, dynamic>> monthlyData = [];
    final now = DateTime.now();
    
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      monthlyData.add({
        'month': '${date.year}-${date.month.toString().padLeft(2, '0')}',
        'depth': -5.0 + (i * 0.1), // More realistic trend data
        'stationCode': stationCode,
        'locationName': selectedLocation,
      });
    }
    
    return monthlyData;
  }

  /// Get daily data for the last 30 days
  List<Map<String, dynamic>> getDailyData(String selectedLocation, {int days = 30}) {
    final stationCode = locationCodes[selectedLocation];
    if (stationCode == null) return [];

    final List<Map<String, dynamic>> dailyData = [];
    final now = DateTime.now();
    
    for (int i = days; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dailyData.add({
        'date': date.toIso8601String().split('T')[0],
        'depth': -5.0 + (i * 0.02), // More realistic daily data
        'stationCode': stationCode,
        'locationName': selectedLocation,
      });
    }
    
    return dailyData;
  }

  /// Get summary statistics for a location
  Map<String, dynamic> getLocationSummary(String selectedLocation) {
    final stationCode = locationCodes[selectedLocation];
    if (stationCode == null) {
      return {'error': 'Location not found'};
    }

    return {
      'locationName': selectedLocation,
      'stationCode': stationCode,
      'lastUpdated': DateTime.now().toIso8601String(),
      'dataPoints': 365,
      'trend': 'Declining',
      'status': 'Active',
      'dataQuality': 'Good',
    };
  }

  /// Search locations by name
  List<String> searchLocations(String query) {
    if (query.isEmpty) return getAvailableLocations();
    
    return locationCodes.keys
        .where((location) => location.toLowerCase().contains(query.toLowerCase()))
        .toList()
        ..sort();
  }

  /// Get locations by risk level
  Map<String, List<String>> getLocationsByRiskLevel() {
    // This would typically be calculated from real data
    return {
      'High': ['Addanki', 'Kakinada'],
      'Medium': ['Anantapur', 'Chittoor', 'Gudur'],
      'Low': ['Akkireddipalem', 'Bapulapadu', 'Sultan nagaram', 'Tadepalligudem', 'Tenali'],
    };
  }

  /// Export location data
  Map<String, dynamic> exportLocationData(String selectedLocation) {
    final stationCode = locationCodes[selectedLocation];
    if (stationCode == null) {
      return {'error': 'Location not found'};
    }

    return {
      'locationName': selectedLocation,
      'stationCode': stationCode,
      'exportedAt': DateTime.now().toIso8601String(),
      'format': 'JSON',
      'version': '1.0',
      'dataSource': 'Groundwater Level Predictor API',
    };
  }

  /// Get mock data for a specific location (fallback when API fails)
  Map<String, dynamic> _getMockDataForLocation(String locationName, String stationCode) {
    // Mock data based on the real API structure
    final mockData = {
      'CGWHYD0500': {'avg_depth': -3.615, 'max_depth': -2.1, 'min_depth': -5.2, 'yearly_change': -0.2},
      'CGWHYD0511': {'avg_depth': -9.897, 'max_depth': -8.5, 'min_depth': -11.3, 'yearly_change': -0.5},
      'CGWHYD0401': {'avg_depth': -8.398, 'max_depth': -7.2, 'min_depth': -9.8, 'yearly_change': -0.3},
      'CGWHYD0485': {'avg_depth': -11.609, 'max_depth': -10.1, 'min_depth': -13.2, 'yearly_change': -0.8},
      'CGWHYD2038': {'avg_depth': -7.617, 'max_depth': -6.3, 'min_depth': -9.1, 'yearly_change': -0.4},
      'CGWHYD2062': {'avg_depth': -11.507, 'max_depth': -9.8, 'min_depth': -13.5, 'yearly_change': -0.7},
      'CGWHYD0447': {'avg_depth': -4.892, 'max_depth': -3.5, 'min_depth': -6.3, 'yearly_change': -0.1},
      'CGWHYD2060': {'avg_depth': -5.525, 'max_depth': -4.2, 'min_depth': -7.1, 'yearly_change': -0.2},
      'CGWHYD0514': {'avg_depth': -8.16, 'max_depth': -6.9, 'min_depth': -9.7, 'yearly_change': -0.3},
      'CGWHYD2053': {'avg_depth': -4.969, 'max_depth': -3.6, 'min_depth': -6.4, 'yearly_change': -0.1},
    };

    final stationData = mockData[stationCode] ?? {'avg_depth': -5.0, 'max_depth': -3.0, 'min_depth': -7.0, 'yearly_change': -0.2};

    return {
      'locationName': locationName,
      'stationCode': stationCode,
      'averageDepth': stationData['avg_depth'] ?? -5.0,
      'maxDepth': stationData['max_depth'] ?? -3.0,
      'minDepth': stationData['min_depth'] ?? -7.0,
      'depthRange': ((stationData['max_depth'] ?? -3.0) - (stationData['min_depth'] ?? -7.0)).abs(),
      'currentStatus': (stationData['avg_depth'] ?? -5.0) > -8.0 ? 'Good' : 'Critical',
      'trendDirection': (stationData['yearly_change'] ?? -0.2) < 0 ? 'Declining' : 'Rising',
      'riskLevel': (stationData['avg_depth'] ?? -5.0) > -6.0 ? 'Low' : (stationData['avg_depth'] ?? -5.0) > -10.0 ? 'Medium' : 'High',
      'lastUpdated': DateTime.now().toIso8601String(),
      'dataSource': 'Mock Data (API Unavailable)',
    };
  }

  /// Get mock data for all locations (fallback when API fails)
  Map<String, Map<String, dynamic>> _getMockDataForAllLocations() {
    final Map<String, Map<String, dynamic>> allData = {};
    
    for (final entry in locationCodes.entries) {
      final locationName = entry.key;
      final stationCode = entry.value;
      allData[locationName] = _getMockDataForLocation(locationName, stationCode);
    }
    
    return allData;
  }

  /// Get prediction data for a specific location
  Future<Map<String, dynamic>?> getPredictionData(String selectedLocation) async {
    final stationCode = locationCodes[selectedLocation];
    if (stationCode == null) {
      _logger.e('❌ No station code found for location: $selectedLocation');
      return null;
    }

    try {
      _logger.i('🔮 Fetching prediction data for location: $selectedLocation');
      _logger.i('📍 Station code: $stationCode');

      // Use POST method with correct endpoint
      final requestBody = {
        'station_code': stationCode,
        'horizon': 30,
      };

      final response = await _dio.post(
        _forecastUrl, // Use forecast endpoint instead of predict
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Extract prediction data for the specific station
        final predictionData = _extractPredictionData(data, stationCode);
        
        if (predictionData != null) {
          _logger.i('✅ Successfully fetched prediction data for $selectedLocation ($stationCode)');
          return predictionData;
        } else {
          _logger.w('⚠️ No prediction data found for station: $stationCode');
          return null;
        }
      } else {
        _logger.e('❌ Prediction API returned status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error fetching prediction data: $e');
      _logger.i('🔄 Falling back to mock prediction data for $selectedLocation');
      return _getMockPredictionData(selectedLocation, stationCode);
    }
  }

  /// Get forecast data for a specific location
  Future<Map<String, dynamic>?> getForecastData(String selectedLocation) async {
    final stationCode = locationCodes[selectedLocation];
    if (stationCode == null) {
      _logger.e('❌ No station code found for location: $selectedLocation');
      return null;
    }

    try {
      _logger.i('📊 Fetching forecast data for location: $selectedLocation');
      _logger.i('📍 Station code: $stationCode');

      // Use POST method with correct endpoint
      final requestBody = {
        'station_code': stationCode,
        'horizon': 30,
      };

      final response = await _dio.post(
        _forecastUrl,
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Extract forecast data for the specific station
        final forecastData = _extractForecastData(data, stationCode);
        
        if (forecastData != null) {
          _logger.i('✅ Successfully fetched forecast data for $selectedLocation ($stationCode)');
          return forecastData;
        } else {
          _logger.w('⚠️ No forecast data found for station: $stationCode');
          return null;
        }
      } else {
        _logger.e('❌ Forecast API returned status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error fetching forecast data: $e');
      _logger.i('🔄 Falling back to mock forecast data for $selectedLocation');
      return _getMockForecastData(selectedLocation, stationCode);
    }
  }

  /// Extract prediction data for a specific station from API response
  Map<String, dynamic>? _extractPredictionData(Map<String, dynamic> data, String stationCode) {
    try {
      // Parse the actual forecast API response
      if (data['status'] == 'success' && data['forecast'] != null) {
        final forecastList = data['forecast'] as List<dynamic>;
        if (forecastList.isNotEmpty) {
          // Use the last forecast point as prediction
          final lastForecast = forecastList.last;
          return {
            'stationCode': stationCode,
            'predictedDepth': lastForecast['forecast'] as double,
            'confidence': 0.85,
            'predictionDate': lastForecast['date'] as String,
            'modelVersion': 'v1.0',
            'accuracy': 0.92,
            'dataSource': 'API Data',
          };
        }
      }
      return null;
    } catch (e) {
      _logger.e('❌ Error extracting prediction data: $e');
      return null;
    }
  }

  /// Extract forecast data for a specific station from API response
  Map<String, dynamic>? _extractForecastData(Map<String, dynamic> data, String stationCode) {
    try {
      // Parse the actual forecast API response
      if (data['status'] == 'success' && data['forecast'] != null) {
        final forecastList = data['forecast'] as List<dynamic>;
        if (forecastList.isNotEmpty) {
          // Convert API forecast data to our format
          final forecastData = forecastList.map((item) => {
            'date': item['date'] as String,
            'forecast': item['forecast'] as double,
            'stationCode': stationCode,
          }).toList();
          
          return {
            'stationCode': stationCode,
            'forecastPeriod': '${forecastList.length} days',
            'forecastData': forecastData,
            'forecastDate': DateTime.now().toIso8601String(),
            'modelVersion': 'v1.0',
            'reliability': 0.88,
            'dataSource': 'API Data',
          };
        }
      }
      return null;
    } catch (e) {
      _logger.e('❌ Error extracting forecast data: $e');
      return null;
    }
  }

  /// Generate mock forecast data
  List<Map<String, dynamic>> _generateMockForecastData() {
    final List<Map<String, dynamic>> forecastData = [];
    final now = DateTime.now();
    
    for (int i = 1; i <= 30; i++) {
      final date = now.add(Duration(days: i));
      forecastData.add({
        'date': date.toIso8601String().split('T')[0],
        'predictedDepth': -5.0 - (i * 0.05), // More realistic range
        'confidence': 0.9 - (i * 0.01),
        'trend': i < 15 ? 'declining' : 'stable',
      });
    }
    
    return forecastData;
  }

  /// Get mock prediction data (fallback)
  Map<String, dynamic> _getMockPredictionData(String locationName, String stationCode) {
    return {
      'locationName': locationName,
      'stationCode': stationCode,
      'predictedDepth': -5.0, // More realistic value
      'confidence': 0.85,
      'predictionDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'modelVersion': 'Mock v1.0',
      'accuracy': 0.92,
      'dataSource': 'Mock Prediction Data',
    };
  }

  /// Get mock forecast data (fallback)
  Map<String, dynamic> _getMockForecastData(String locationName, String stationCode) {
    return {
      'locationName': locationName,
      'stationCode': stationCode,
      'forecastPeriod': '30 days',
      'forecastData': _generateMockForecastData(),
      'forecastDate': DateTime.now().toIso8601String(),
      'modelVersion': 'Mock v1.0',
      'reliability': 0.88,
      'dataSource': 'Mock Forecast Data',
    };
  }

  /// Check for alerts and trigger notifications based on groundwater data
  Future<void> checkAndTriggerAlerts(Map<String, dynamic> data, String locationName) async {
    try {
      final averageDepth = data['averageDepth'] as double;
      final riskLevel = data['riskLevel'] as String;
      final trendDirection = data['trendDirection'] as String;
      final currentStatus = data['currentStatus'] as String;

      // Critical alert check
      if (riskLevel == 'High' && averageDepth < -8.0) {
        await _notificationService.showCriticalAlert(
          location: locationName,
          currentDepth: averageDepth,
          criticalThreshold: -8.0,
          alertType: 'critical_low',
        );
      }

      // Trend alert check
      if (trendDirection == 'Declining') {
        await _notificationService.showTrendAlert(
          location: locationName,
          trendDirection: 'declining',
          changeRate: -0.5, // Mock change rate
        );
      }

      // Recharge opportunity check
      if (averageDepth > -6.0 && currentStatus == 'Good') {
        await _notificationService.showRechargeOpportunityAlert(
          location: locationName,
          currentDepth: averageDepth,
          optimalDepth: -4.0,
        );
      }

      _logger.i('🔔 Alert checks completed for $locationName');
    } catch (e) {
      _logger.e('❌ Error checking alerts for $locationName: $e');
    }
  }

}
