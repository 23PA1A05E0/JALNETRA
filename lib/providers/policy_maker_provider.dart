import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Policy Maker Provider for real API data integration
class PolicyMakerProvider {
  static final ApiService _apiService = ApiService();

  /// Fetch all features data from API
  static final featuresDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
    return await _apiService.fetchFeatures();
  });

  /// Get categorized zones based on real API data
  static final categorizedZonesProvider = Provider<Map<String, Map<String, dynamic>>>((ref) {
    final featuresData = ref.watch(featuresDataProvider);
    
    return featuresData.when(
      data: (data) => _categorizeZonesByDepth(data),
      loading: () => <String, Map<String, dynamic>>{},
      error: (error, stack) => <String, Map<String, dynamic>>{},
    );
  });

  /// Categorize zones based on average depth values
  static Map<String, Map<String, dynamic>> _categorizeZonesByDepth(Map<String, dynamic> featuresData) {
    final averageDepths = featuresData['average_depth'] as Map<String, dynamic>? ?? {};
    
    // Create reverse mapping from station codes to location names
    final Map<String, String> stationToLocation = {};
    ApiService.locationCodes.forEach((location, stationCode) {
      stationToLocation[stationCode] = location;
    });

    List<String> redZones = [];
    List<String> orangeZones = [];
    List<String> greenZones = [];

    // Categorize each station based on average depth
    print('🔍 DEBUG: Processing ${averageDepths.length} stations from API');
    print('🔍 DEBUG: Available station codes: ${averageDepths.keys.toList()}');
    print('🔍 DEBUG: Mapped locations: ${stationToLocation.keys.toList()}');
    
    averageDepths.forEach((stationCode, avgDepth) {
      final locationName = stationToLocation[stationCode];
      if (locationName != null) {
        final depth = (avgDepth as num).toDouble();
        print('🔍 DEBUG: Processing $locationName ($stationCode): $depth m');
        
        // Apply traffic signal logic
        if (depth >= -5.0) {
          // Green zone: 0 to -5 meters (safe)
          greenZones.add(locationName);
          print('🔍 DEBUG: $locationName -> GREEN ZONE');
        } else if (depth < -5.0 && depth >= -15.0) {
          // Orange zone: -5 to -15 meters (moderate)
          orangeZones.add(locationName);
          print('🔍 DEBUG: $locationName -> ORANGE ZONE');
        } else {
          // Red zone: -15 and above (danger)
          redZones.add(locationName);
          print('🔍 DEBUG: $locationName -> RED ZONE');
        }
      } else {
        print('🔍 DEBUG: Station $stationCode not found in location mapping');
      }
    });
    
    print('🔍 DEBUG: Final categorization - Green: ${greenZones.length}, Orange: ${orangeZones.length}, Red: ${redZones.length}');
    print('🔍 DEBUG: Green zones: $greenZones');
    print('🔍 DEBUG: Orange zones: $orangeZones');
    print('🔍 DEBUG: Red zones: $redZones');

    // Create categorized data structure
    return {
      'Andhra Pradesh': {
        'red': redZones.length,
        'orange': orangeZones.length,
        'green': greenZones.length,
        'total': redZones.length + orangeZones.length + greenZones.length,
        'redZones': redZones,
        'orangeZones': orangeZones,
        'greenZones': greenZones,
        'notes': _generatePolicyNotes(redZones.length, orangeZones.length, greenZones.length),
      }
    };
  }

  /// Generate policy notes based on zone distribution
  static String _generatePolicyNotes(int redCount, int orangeCount, int greenCount) {
    if (redCount > orangeCount + greenCount) {
      return 'Critical groundwater depletion detected. Immediate policy intervention required for water conservation and recharge programs.';
    } else if (orangeCount > redCount + greenCount) {
      return 'Moderate groundwater stress observed. Implement monitoring programs and preventive conservation measures.';
    } else if (greenCount > redCount + orangeCount) {
      return 'Groundwater levels are stable. Continue current management practices and maintain monitoring systems.';
    } else {
      return 'Mixed groundwater conditions across the region. Targeted interventions needed for critical zones.';
    }
  }

  /// Get detailed zone information for a specific location
  static final zoneDetailsProvider = Provider.family<Map<String, dynamic>?, String>((ref, locationName) {
    final featuresData = ref.watch(featuresDataProvider);
    
    return featuresData.when(
      data: (data) => _getZoneDetailsForLocation(data, locationName),
      loading: () => null,
      error: (error, stack) => null,
    );
  });

  /// Get detailed information for a specific location
  static Map<String, dynamic>? _getZoneDetailsForLocation(Map<String, dynamic> featuresData, String locationName) {
    // Find station code for the location
    final stationCode = ApiService.locationCodes[locationName];
    if (stationCode == null) return null;

    final averageDepths = featuresData['average_depth'] as Map<String, dynamic>? ?? {};
    final stationSummary = featuresData['station_summary'] as Map<String, dynamic>? ?? {};
    
    final avgDepth = (averageDepths[stationCode] as num?)?.toDouble() ?? 0.0;
    final summary = stationSummary[stationCode] as Map<String, dynamic>? ?? {};
    
    // Determine zone type
    String zoneType;
    String status;
    String priority;
    Color zoneColor;
    
    if (avgDepth >= -5.0) {
      zoneType = 'Safe (Green Zone)';
      status = 'Continue current management practices';
      priority = 'Low Priority';
      zoneColor = Colors.green;
    } else if (avgDepth < -5.0 && avgDepth >= -15.0) {
      zoneType = 'Moderate (Orange Zone)';
      status = 'Monitoring and preventive measures needed';
      priority = 'Medium Priority';
      zoneColor = Colors.orange;
    } else {
      zoneType = 'Critical (Red Zone)';
      status = 'Immediate intervention required';
      priority = 'High Priority';
      zoneColor = Colors.red;
    }

    return {
      'locationName': locationName,
      'stationCode': stationCode,
      'averageDepth': avgDepth,
      'maxDepth': (summary['max_depth'] as num?)?.toDouble() ?? 0.0,
      'minDepth': (summary['min_depth'] as num?)?.toDouble() ?? 0.0,
      'yearlyChange': summary['yearly_change'] as Map<String, dynamic>? ?? {},
      'zoneType': zoneType,
      'status': status,
      'priority': priority,
      'zoneColor': zoneColor,
    };
  }
}
