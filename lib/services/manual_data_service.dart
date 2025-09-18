import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Service for managing manual groundwater data storage
class ManualDataService {
  final Logger _logger = Logger();
  
  // Keys for SharedPreferences storage
  static const String _stationDataKey = 'station_data';
  static const String _historicalDataKey = 'historical_data';
  static const String _lastUpdatedKey = 'last_updated';
  
  /// Save station data to SharedPreferences
  Future<void> saveStationData(Map<String, dynamic> stationData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = _mapToJsonString(stationData);
      await prefs.setString(_stationDataKey, jsonString);
      await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
      _logger.i('✅ Station data saved successfully');
    } catch (e) {
      _logger.e('❌ Error saving station data: $e');
      rethrow;
    }
  }
  
  /// Load station data from SharedPreferences
  Future<Map<String, dynamic>?> loadStationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_stationDataKey);
      if (jsonString != null) {
        final data = _jsonStringToMap(jsonString);
        _logger.i('✅ Station data loaded successfully');
        return data;
      }
      _logger.w('⚠️ No station data found');
      return null;
    } catch (e) {
      _logger.e('❌ Error loading station data: $e');
      return null;
    }
  }
  
  /// Save historical data to SharedPreferences
  Future<void> saveHistoricalData(List<Map<String, dynamic>> historicalData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = _listToJsonString(historicalData);
      await prefs.setString(_historicalDataKey, jsonString);
      _logger.i('✅ Historical data saved successfully (${historicalData.length} records)');
    } catch (e) {
      _logger.e('❌ Error saving historical data: $e');
      rethrow;
    }
  }
  
  /// Load historical data from SharedPreferences
  Future<List<Map<String, dynamic>>> loadHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historicalDataKey);
      if (jsonString != null) {
        final data = _jsonStringToList(jsonString);
        _logger.i('✅ Historical data loaded successfully (${data.length} records)');
        return data;
      }
      _logger.w('⚠️ No historical data found');
      return [];
    } catch (e) {
      _logger.e('❌ Error loading historical data: $e');
      return [];
    }
  }
  
  /// Get last updated timestamp
  Future<DateTime?> getLastUpdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_lastUpdatedKey);
      if (timestampString != null) {
        return DateTime.parse(timestampString);
      }
      return null;
    } catch (e) {
      _logger.e('❌ Error getting last updated timestamp: $e');
      return null;
    }
  }
  
  /// Clear all stored data
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stationDataKey);
      await prefs.remove(_historicalDataKey);
      await prefs.remove(_lastUpdatedKey);
      _logger.i('✅ All data cleared successfully');
    } catch (e) {
      _logger.e('❌ Error clearing data: $e');
      rethrow;
    }
  }
  
  /// Check if data exists
  Future<bool> hasData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_stationDataKey) || prefs.containsKey(_historicalDataKey);
    } catch (e) {
      _logger.e('❌ Error checking data existence: $e');
      return false;
    }
  }
  
  /// Get data statistics
  Future<Map<String, dynamic>> getDataStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stationData = prefs.getString(_stationDataKey);
      final historicalData = prefs.getString(_historicalDataKey);
      final lastUpdated = prefs.getString(_lastUpdatedKey);
      
      return {
        'hasStationData': stationData != null,
        'hasHistoricalData': historicalData != null,
        'lastUpdated': lastUpdated,
        'dataSize': (stationData?.length ?? 0) + (historicalData?.length ?? 0),
      };
    } catch (e) {
      _logger.e('❌ Error getting data stats: $e');
      return {
        'hasStationData': false,
        'hasHistoricalData': false,
        'lastUpdated': null,
        'dataSize': 0,
      };
    }
  }
  
  /// Convert Map to JSON string (simple implementation)
  String _mapToJsonString(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    buffer.write('{');
    final entries = map.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":"${entry.value}"');
      if (i < entries.length - 1) buffer.write(',');
    }
    buffer.write('}');
    return buffer.toString();
  }
  
  /// Convert JSON string to Map (simple implementation)
  Map<String, dynamic> _jsonStringToMap(String jsonString) {
    final map = <String, dynamic>{};
    // Remove braces and split by comma
    final content = jsonString.substring(1, jsonString.length - 1);
    if (content.isNotEmpty) {
      final pairs = content.split(',');
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].replaceAll('"', '');
          final value = keyValue[1].replaceAll('"', '');
          map[key] = value;
        }
      }
    }
    return map;
  }
  
  /// Convert List to JSON string (simple implementation)
  String _listToJsonString(List<Map<String, dynamic>> list) {
    final buffer = StringBuffer();
    buffer.write('[');
    for (int i = 0; i < list.length; i++) {
      buffer.write(_mapToJsonString(list[i]));
      if (i < list.length - 1) buffer.write(',');
    }
    buffer.write(']');
    return buffer.toString();
  }
  
  /// Convert JSON string to List (simple implementation)
  List<Map<String, dynamic>> _jsonStringToList(String jsonString) {
    final list = <Map<String, dynamic>>[];
    // Remove brackets and split by comma
    final content = jsonString.substring(1, jsonString.length - 1);
    if (content.isNotEmpty) {
      final items = content.split('},{');
      for (final item in items) {
        final cleanItem = item.startsWith('{') ? item : '{$item}';
        if (!cleanItem.endsWith('}')) cleanItem + '}';
        list.add(_jsonStringToMap(cleanItem));
      }
    }
    return list;
  }
  
  /// Create sample data for testing
  Future<void> createSampleData() async {
    try {
      // Sample station data
      final stationData = {
        'stationCode': 'CGWHYD0514',
        'stationName': 'Tadepalligudem - pz',
        'district': 'West Godavari',
        'state': 'Andhra Pradesh',
        'latitude': 16.8212,
        'longitude': 81.5187,
        'latestWaterLevel': 15.5,
        'waterLevelUnit': 'm',
        'lastUpdated': '2025-01-16',
        'dataPoints': 0,
        'wellDepth': 200.76,
        'aquiferType': 'Alluvial',
        'wellType': 'Bore Well',
        'dataSource': 'Manual Entry',
      };
      
      // Sample historical data
      final historicalData = <Map<String, dynamic>>[];
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        historicalData.add({
          'date': date.toIso8601String().split('T')[0],
          'waterLevel': 15.0 + (i * 0.1),
          'waterLevelUnit': 'm',
          'stationCode': 'CGWHYD0514',
        });
      }
      
      await saveStationData(stationData);
      await saveHistoricalData(historicalData);
      
      _logger.i('✅ Sample data created successfully');
    } catch (e) {
      _logger.e('❌ Error creating sample data: $e');
      rethrow;
    }
  }
}
