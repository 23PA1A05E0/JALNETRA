import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/traffic_signal.dart';

final logger = Logger();

class ApiService {
  static const String _baseUrl = 'https://groundwater-level-predictor-backend.onrender.com';
  
  /// Location codes mapping for API data matching
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

  /// Fetch features data from the API
  Future<Map<String, dynamic>> fetchFeatures() async {
    try {
      logger.i('🌊 Fetching features from API...');
      
      final res = await http.get(
        Uri.parse("$_baseUrl/features"),
      headers: {
        'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      logger.i('📡 API Response Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final dynamic jsonData = jsonDecode(res.body);
        logger.i('📊 JSON Data Type: ${jsonData.runtimeType}');

        if (jsonData is Map<String, dynamic>) {
          logger.i('✅ Successfully fetched features data');
          return jsonData;
        } else {
          logger.e('❌ Unexpected JSON structure: ${jsonData.runtimeType}');
          throw Exception("Unexpected JSON structure - expected Map");
        }
      } else {
        logger.e('❌ Failed to fetch data: ${res.statusCode}');
        throw Exception("Failed to fetch data: ${res.statusCode}");
      }
    } catch (e) {
      logger.e('❌ Error fetching features: $e');
      rethrow;
    }
  }

  /// Get features data for a specific location
  Future<Map<String, dynamic>?> getFeaturesForLocation(String locationName) async {
    try {
      final stationCode = locationCodes[locationName];
      if (stationCode == null) {
        logger.e('❌ No station code found for location: $locationName');
        return null;
      }

      logger.i('🔍 Looking for data for $locationName (Code: $stationCode)');
      
      final featuresData = await fetchFeatures();
      
      // Extract station summary data for the specific station code
      final stationSummary = featuresData['station_summary'] as Map<String, dynamic>?;
      if (stationSummary != null && stationSummary.containsKey(stationCode)) {
        final stationData = stationSummary[stationCode] as Map<String, dynamic>;
        logger.i('✅ Found data for $locationName');
        
        // Return the station data with additional context
        return {
          'stationCode': stationCode,
          'stationName': locationName,
          'stationData': stationData,
          'averageDepth': stationData['avg_depth'],
          'maxDepth': stationData['max_depth'],
          'minDepth': stationData['min_depth'],
          'yearlyChange': stationData['yearly_change'],
          'dataSource': 'API Data',
        };
      }
      
      logger.w('⚠️ No data found for $locationName ($stationCode)');
      return null;
    } catch (e) {
      logger.e('❌ Error getting features for $locationName: $e');
      return null;
    }
  }

  /// Get all available locations from the API
  Future<List<String>> getAvailableLocations() async {
    try {
      final featuresData = await fetchFeatures();
      final locations = <String>[];
      
      // Extract station codes from station_summary
      final stationSummary = featuresData['station_summary'] as Map<String, dynamic>?;
      if (stationSummary != null) {
        for (final stationCode in stationSummary.keys) {
          // Find location name from station code
          final locationName = locationCodes.entries
              .where((entry) => entry.value == stationCode)
              .map((entry) => entry.key)
              .firstOrNull;
          
          if (locationName != null && !locations.contains(locationName)) {
            locations.add(locationName);
          }
        }
      }
      
      logger.i('📍 Available locations: $locations');
      return locations;
    } catch (e) {
      logger.e('❌ Error getting available locations: $e');
      return locationCodes.keys.toList(); // Fallback to all known locations
    }
  }

  /// Extract analytics data from API response
  Map<String, dynamic> extractAnalyticsData(Map<String, dynamic> apiData) {
    try {
      // Handle the new API structure where data is already extracted
      if (apiData.containsKey('stationCode') && apiData.containsKey('averageDepth')) {
        return {
          'stationCode': apiData['stationCode'],
          'stationName': apiData['stationName'],
          'averageDepth': apiData['averageDepth'] as double? ?? 0.0,
          'minDepth': apiData['minDepth'] as double? ?? 0.0,
          'maxDepth': apiData['maxDepth'] as double? ?? 0.0,
          'currentLevel': apiData['averageDepth'] as double? ?? 0.0, // Use average as current
          'yearlyChange': _extractYearlyChange(apiData['yearlyChange']),
          'lastUpdated': DateTime.now().toIso8601String(),
          'dataPoints': 365, // Default value
          'aquiferType': 'Unknown',
          'wellType': 'Bore Well',
          'dataSource': 'API Data',
        };
      }
      
      // Fallback for old structure
      return {
        'stationCode': apiData['station_code'] ?? apiData['stationCode'] ?? apiData['station_id'],
        'stationName': apiData['station_name'] ?? apiData['stationName'] ?? apiData['name'],
        'averageDepth': _extractNumericValue(apiData, ['average_depth', 'avg_depth', 'mean_depth']),
        'minDepth': _extractNumericValue(apiData, ['min_depth', 'minimum_depth']),
        'maxDepth': _extractNumericValue(apiData, ['max_depth', 'maximum_depth']),
        'currentLevel': _extractNumericValue(apiData, ['current_level', 'currentLevel', 'water_level']),
        'yearlyChange': _extractNumericValue(apiData, ['yearly_change', 'annual_change', 'trend']),
        'lastUpdated': apiData['last_updated'] ?? apiData['lastUpdated'] ?? apiData['timestamp'],
        'dataPoints': apiData['data_points'] ?? apiData['dataPoints'] ?? apiData['count'],
        'aquiferType': apiData['aquifer_type'] ?? apiData['aquiferType'] ?? apiData['aquifer'],
        'wellType': apiData['well_type'] ?? apiData['wellType'] ?? apiData['type'],
        'dataSource': 'API Data',
      };
    } catch (e) {
      logger.e('❌ Error extracting analytics data: $e');
      return {};
    }
  }

  /// Extract yearly change value from API data
  double _extractYearlyChange(dynamic yearlyChangeData) {
    if (yearlyChangeData is Map<String, dynamic>) {
      // Get the latest year's change
      final years = yearlyChangeData.keys.toList()..sort();
      if (years.isNotEmpty) {
        final latestYear = years.last;
        final change = yearlyChangeData[latestYear];
        if (change is num) {
          return change.toDouble();
        }
      }
    } else if (yearlyChangeData is num) {
      return yearlyChangeData.toDouble();
    }
    return 0.0;
  }

  /// Extract numeric value from API data with multiple possible keys
  double _extractNumericValue(Map<String, dynamic> data, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      final value = data[key];
      if (value != null) {
        if (value is num) {
          return value.toDouble();
        } else if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0.0; // Default value if not found
  }

  /// Fetch traffic signals for all regions
  Future<List<TrafficSignal>> fetchTrafficSignals() async {
    try {
      logger.i('🚦 Fetching traffic signals for all regions...');
      
      final res = await http.get(
        Uri.parse("$_baseUrl/traffic-signals"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      logger.i('📡 Traffic Signals API Response Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final dynamic jsonData = jsonDecode(res.body);
        
        if (jsonData is List) {
          final trafficSignals = jsonData
              .map((data) => TrafficSignal.fromApiData(data as Map<String, dynamic>))
              .toList();
          
          logger.i('✅ Successfully fetched ${trafficSignals.length} traffic signals');
          return trafficSignals;
        } else if (jsonData is Map<String, dynamic>) {
          // Handle single region response
          final trafficSignal = TrafficSignal.fromApiData(jsonData);
          logger.i('✅ Successfully fetched traffic signal for single region');
          return [trafficSignal];
        } else {
          logger.e('❌ Unexpected JSON structure: ${jsonData.runtimeType}');
          throw Exception("Unexpected JSON structure - expected List or Map");
        }
      } else {
        logger.e('❌ Failed to fetch traffic signals: ${res.statusCode}');
        throw Exception("Failed to fetch traffic signals: ${res.statusCode}");
      }
    } catch (e) {
      logger.e('❌ Error fetching traffic signals: $e');
      // Return mock data as fallback
      return _getMockTrafficSignals();
    }
  }

  /// Fetch traffic signal for a specific region
  Future<TrafficSignal?> fetchTrafficSignalForRegion(String regionId) async {
    try {
      logger.i('🚦 Fetching traffic signal for region: $regionId');
      
      final res = await http.get(
        Uri.parse("$_baseUrl/traffic-signals/$regionId"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      logger.i('📡 Traffic Signal API Response Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final dynamic jsonData = jsonDecode(res.body);
        
        if (jsonData is Map<String, dynamic>) {
          final trafficSignal = TrafficSignal.fromApiData(jsonData);
          logger.i('✅ Successfully fetched traffic signal for $regionId');
          return trafficSignal;
        } else {
          logger.e('❌ Unexpected JSON structure: ${jsonData.runtimeType}');
          throw Exception("Unexpected JSON structure - expected Map");
        }
      } else if (res.statusCode == 404) {
        logger.w('⚠️ Traffic signal not found for region: $regionId');
        return null;
      } else {
        logger.e('❌ Failed to fetch traffic signal: ${res.statusCode}');
        throw Exception("Failed to fetch traffic signal: ${res.statusCode}");
      }
    } catch (e) {
      logger.e('❌ Error fetching traffic signal for $regionId: $e');
      // Return mock data as fallback
      return _getMockTrafficSignalForRegion(regionId);
    }
  }

  /// Fetch traffic signals by state
  Future<List<TrafficSignal>> fetchTrafficSignalsByState(String state) async {
    try {
      logger.i('🚦 Fetching traffic signals for state: $state');
      
      final res = await http.get(
        Uri.parse("$_baseUrl/traffic-signals/state/$state"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      logger.i('📡 Traffic Signals by State API Response Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final dynamic jsonData = jsonDecode(res.body);
        
        if (jsonData is List) {
          final trafficSignals = jsonData
              .map((data) => TrafficSignal.fromApiData(data as Map<String, dynamic>))
              .toList();
          
          logger.i('✅ Successfully fetched ${trafficSignals.length} traffic signals for $state');
          return trafficSignals;
        } else {
          logger.e('❌ Unexpected JSON structure: ${jsonData.runtimeType}');
          throw Exception("Unexpected JSON structure - expected List");
        }
      } else {
        logger.e('❌ Failed to fetch traffic signals for state: ${res.statusCode}');
        throw Exception("Failed to fetch traffic signals for state: ${res.statusCode}");
      }
    } catch (e) {
      logger.e('❌ Error fetching traffic signals for state $state: $e');
      // Return mock data as fallback
      return _getMockTrafficSignalsByState(state);
    }
  }

  /// Get critical regions requiring immediate attention
  Future<List<TrafficSignal>> fetchCriticalRegions() async {
    try {
      logger.i('🚨 Fetching critical regions...');
      
      final res = await http.get(
        Uri.parse("$_baseUrl/traffic-signals/critical"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      logger.i('📡 Critical Regions API Response Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final dynamic jsonData = jsonDecode(res.body);
        
        if (jsonData is List) {
          final trafficSignals = jsonData
              .map((data) => TrafficSignal.fromApiData(data as Map<String, dynamic>))
              .toList();
          
          logger.i('✅ Successfully fetched ${trafficSignals.length} critical regions');
          return trafficSignals;
        } else {
          logger.e('❌ Unexpected JSON structure: ${jsonData.runtimeType}');
          throw Exception("Unexpected JSON structure - expected List");
        }
      } else {
        logger.e('❌ Failed to fetch critical regions: ${res.statusCode}');
        throw Exception("Failed to fetch critical regions: ${res.statusCode}");
      }
    } catch (e) {
      logger.e('❌ Error fetching critical regions: $e');
      // Return mock data as fallback
      return _getMockCriticalRegions();
    }
  }

  /// Generate traffic signal from existing groundwater data
  TrafficSignal generateTrafficSignalFromData(Map<String, dynamic> data, String regionName) {
    try {
      final avgDepth = _extractNumericValue(data, ['averageDepth', 'avg_depth', 'mean_depth']);
      final minDepth = _extractNumericValue(data, ['minDepth', 'min_depth', 'minimum_depth']);
      final maxDepth = _extractNumericValue(data, ['maxDepth', 'max_depth', 'maximum_depth']);
      final yearlyChange = _extractYearlyChange(data['yearlyChange'] ?? data['yearly_change'] ?? 0.0);
      
      return TrafficSignal.fromApiData({
        'regionId': data['stationCode'] ?? data['station_code'] ?? regionName.toLowerCase().replaceAll(' ', '_'),
        'regionName': regionName,
        'district': data['district'] ?? 'Unknown',
        'state': data['state'] ?? 'Andhra Pradesh',
        'averageDepth': avgDepth,
        'minDepth': minDepth,
        'maxDepth': maxDepth,
        'yearlyChange': yearlyChange,
        'stationCount': 1,
        'activeStations': 1,
        'lastUpdated': DateTime.now().toIso8601String(),
        'dataSource': 'Generated from Groundwater Data',
        'additionalMetrics': {
          'trendDirection': yearlyChange > 0 ? 'Rising' : 'Declining',
          'dataQuality': 'Good',
          'lastMeasurement': DateTime.now().toIso8601String(),
        },
        'recommendations': _generateRecommendations(avgDepth, yearlyChange),
      });
    } catch (e) {
      logger.e('❌ Error generating traffic signal: $e');
      return _getMockTrafficSignalForRegion(regionName);
    }
  }

  /// Generate recommendations based on groundwater data
  List<String> _generateRecommendations(double avgDepth, double yearlyChange) {
    final recommendations = <String>[];
    final depthValue = avgDepth.abs();
    
    if (depthValue > 16) {
      recommendations.addAll([
        'Immediate water conservation measures required',
        'Implement rainwater harvesting systems',
        'Consider artificial recharge techniques',
        'Monitor water usage patterns',
      ]);
    } else if (depthValue > 10) {
      recommendations.addAll([
        'Implement water conservation practices',
        'Promote rainwater harvesting',
        'Monitor groundwater levels regularly',
      ]);
    } else if (yearlyChange < -0.5) {
      recommendations.addAll([
        'Monitor declining trend closely',
        'Implement preventive conservation measures',
        'Consider recharge initiatives',
      ]);
    } else {
      recommendations.addAll([
        'Maintain current water management practices',
        'Continue regular monitoring',
        'Promote sustainable water usage',
      ]);
    }
    
    return recommendations;
  }

  /// Mock traffic signals data for fallback
  List<TrafficSignal> _getMockTrafficSignals() {
    return [
      TrafficSignal.fromApiData({
        'regionId': 'addanki',
        'regionName': 'Addanki',
        'district': 'Prakasam',
        'state': 'Andhra Pradesh',
        'averageDepth': -8.5,
        'minDepth': -12.0,
        'maxDepth': -5.0,
        'yearlyChange': -0.8,
        'stationCount': 3,
        'activeStations': 3,
        'lastUpdated': DateTime.now().toIso8601String(),
        'dataSource': 'Mock Data',
        'recommendations': ['Monitor closely', 'Implement conservation measures'],
      }),
      TrafficSignal.fromApiData({
        'regionId': 'anantapur',
        'regionName': 'Anantapur',
        'district': 'Anantapur',
        'state': 'Andhra Pradesh',
        'averageDepth': -15.2,
        'minDepth': -20.0,
        'maxDepth': -10.0,
        'yearlyChange': -1.2,
        'stationCount': 5,
        'activeStations': 4,
        'lastUpdated': DateTime.now().toIso8601String(),
        'dataSource': 'Mock Data',
        'recommendations': ['Critical situation', 'Immediate action required'],
      }),
    ];
  }

  /// Mock traffic signal for specific region
  TrafficSignal _getMockTrafficSignalForRegion(String regionId) {
    return TrafficSignal.fromApiData({
      'regionId': regionId,
      'regionName': regionId.replaceAll('_', ' ').toUpperCase(),
      'district': 'Unknown',
      'state': 'Andhra Pradesh',
      'averageDepth': -7.5,
      'minDepth': -10.0,
      'maxDepth': -5.0,
      'yearlyChange': -0.5,
      'stationCount': 2,
      'activeStations': 2,
      'lastUpdated': DateTime.now().toIso8601String(),
      'dataSource': 'Mock Data',
      'recommendations': ['Monitor groundwater levels', 'Implement conservation'],
    });
  }

  /// Mock traffic signals by state
  List<TrafficSignal> _getMockTrafficSignalsByState(String state) {
    return _getMockTrafficSignals().where((signal) => signal.state == state).toList();
  }

  /// Mock critical regions
  List<TrafficSignal> _getMockCriticalRegions() {
    return _getMockTrafficSignals().where((signal) => signal.level == TrafficSignalLevel.critical).toList();
  }

  /// Fetch forecast data from the API
  Future<Map<String, dynamic>> fetchForecast(String stationCode, int horizonDays) async {
    try {
      logger.i('🔮 Fetching forecast for station: $stationCode, horizon: $horizonDays days');
      
      final requestBody = {
        'station_code': stationCode,
        'horizon': horizonDays,
      };

      final res = await http.post(
        Uri.parse("$_baseUrl/forecast"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      logger.i('📡 Forecast API Response Status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final dynamic jsonData = jsonDecode(res.body);
        
        if (jsonData is Map<String, dynamic>) {
          logger.i('✅ Successfully fetched forecast data');
          return jsonData;
        } else {
          logger.e('❌ Unexpected JSON structure: ${jsonData.runtimeType}');
          throw Exception("Unexpected JSON structure - expected Map");
        }
      } else {
        logger.e('❌ Failed to fetch forecast: ${res.statusCode}');
        throw Exception("Failed to fetch forecast: ${res.statusCode}");
      }
    } catch (e) {
      logger.e('❌ Error fetching forecast: $e');
      rethrow;
    }
  }

  /// Get forecast data for a specific location
  Future<List<Map<String, dynamic>>> getForecastForLocation(String locationName, int horizonDays) async {
    try {
      final stationCode = locationCodes[locationName];
      if (stationCode == null) {
        logger.e('❌ No station code found for location: $locationName');
        return [];
      }

      logger.i('🔮 Getting forecast for $locationName (Code: $stationCode)');
      
      final forecastData = await fetchForecast(stationCode, horizonDays);
      
      if (forecastData['status'] == 'success' && forecastData['forecast'] != null) {
        final forecastList = forecastData['forecast'] as List<dynamic>;
        logger.i('✅ Found ${forecastList.length} forecast points for $locationName');
        
        return forecastList.map((item) => {
          'date': item['date'],
          'forecast': item['forecast'],
          'stationCode': stationCode,
          'stationName': locationName,
        }).toList();
      }
      
      logger.w('⚠️ No forecast data found for $locationName ($stationCode)');
      return [];
    } catch (e) {
      logger.e('❌ Error getting forecast for $locationName: $e');
      return [];
    }
  }
}