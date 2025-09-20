import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

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
          logger.i('📋 Available keys: ${jsonData.keys.toList()}');
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
}