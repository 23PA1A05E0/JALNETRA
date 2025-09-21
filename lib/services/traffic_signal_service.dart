import 'package:logger/logger.dart';
import '../models/traffic_signal.dart';
import 'api_service.dart';

/// Service for managing traffic signals for regional groundwater monitoring
class TrafficSignalService {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  /// Fetch all traffic signals
  Future<List<TrafficSignal>> getAllTrafficSignals() async {
    try {
      _logger.i('🚦 Fetching all traffic signals...');
      return await _apiService.fetchTrafficSignals();
    } catch (e) {
      _logger.e('❌ Error fetching all traffic signals: $e');
      rethrow;
    }
  }

  /// Fetch traffic signal for a specific region
  Future<TrafficSignal?> getTrafficSignalForRegion(String regionId) async {
    try {
      _logger.i('🚦 Fetching traffic signal for region: $regionId');
      return await _apiService.fetchTrafficSignalForRegion(regionId);
    } catch (e) {
      _logger.e('❌ Error fetching traffic signal for region $regionId: $e');
      return null;
    }
  }

  /// Fetch traffic signals by state
  Future<List<TrafficSignal>> getTrafficSignalsByState(String state) async {
    try {
      _logger.i('🚦 Fetching traffic signals for state: $state');
      return await _apiService.fetchTrafficSignalsByState(state);
    } catch (e) {
      _logger.e('❌ Error fetching traffic signals for state $state: $e');
      return [];
    }
  }

  /// Get critical regions requiring immediate attention
  Future<List<TrafficSignal>> getCriticalRegions() async {
    try {
      _logger.i('🚨 Fetching critical regions...');
      return await _apiService.fetchCriticalRegions();
    } catch (e) {
      _logger.e('❌ Error fetching critical regions: $e');
      return [];
    }
  }

  /// Generate traffic signal from groundwater data
  TrafficSignal generateTrafficSignalFromGroundwaterData(Map<String, dynamic> data, String regionName) {
    try {
      _logger.i('🚦 Generating traffic signal for region: $regionName');
      return _apiService.generateTrafficSignalFromData(data, regionName);
    } catch (e) {
      _logger.e('❌ Error generating traffic signal for $regionName: $e');
      rethrow;
    }
  }

  /// Get traffic signals sorted by priority (critical first)
  Future<List<TrafficSignal>> getTrafficSignalsSortedByPriority() async {
    try {
      final signals = await getAllTrafficSignals();
      signals.sort((a, b) => a.priority.compareTo(b.priority));
      return signals;
    } catch (e) {
      _logger.e('❌ Error sorting traffic signals by priority: $e');
      return [];
    }
  }

  /// Get traffic signals filtered by level
  Future<List<TrafficSignal>> getTrafficSignalsByLevel(TrafficSignalLevel level) async {
    try {
      final signals = await getAllTrafficSignals();
      return signals.where((signal) => signal.level == level).toList();
    } catch (e) {
      _logger.e('❌ Error filtering traffic signals by level: $e');
      return [];
    }
  }

  /// Get regions requiring monitoring
  Future<List<TrafficSignal>> getRegionsRequiringMonitoring() async {
    try {
      final signals = await getAllTrafficSignals();
      return signals.where((signal) => signal.requiresMonitoring).toList();
    } catch (e) {
      _logger.e('❌ Error getting regions requiring monitoring: $e');
      return [];
    }
  }

  /// Get regions requiring immediate action
  Future<List<TrafficSignal>> getRegionsRequiringImmediateAction() async {
    try {
      final signals = await getAllTrafficSignals();
      return signals.where((signal) => signal.requiresImmediateAction).toList();
    } catch (e) {
      _logger.e('❌ Error getting regions requiring immediate action: $e');
      return [];
    }
  }

  /// Get traffic signal statistics
  Future<Map<String, dynamic>> getTrafficSignalStatistics() async {
    try {
      final signals = await getAllTrafficSignals();
      
      final stats = {
        'totalRegions': signals.length,
        'goodRegions': signals.where((s) => s.level == TrafficSignalLevel.good).length,
        'warningRegions': signals.where((s) => s.level == TrafficSignalLevel.warning).length,
        'criticalRegions': signals.where((s) => s.level == TrafficSignalLevel.critical).length,
        'averageRiskScore': signals.isNotEmpty 
            ? signals.map((s) => s.riskScore).reduce((a, b) => a + b) / signals.length 
            : 0.0,
        'totalStations': signals.fold(0, (sum, signal) => sum + signal.stationCount),
        'activeStations': signals.fold(0, (sum, signal) => sum + signal.activeStations),
        'averageDepth': signals.isNotEmpty 
            ? signals.map((s) => s.averageDepth).reduce((a, b) => a + b) / signals.length 
            : 0.0,
        'regionsRequiringAction': signals.where((s) => s.requiresImmediateAction).length,
        'regionsRequiringMonitoring': signals.where((s) => s.requiresMonitoring).length,
      };
      
      _logger.i('📊 Traffic signal statistics: $stats');
      return stats;
    } catch (e) {
      _logger.e('❌ Error getting traffic signal statistics: $e');
      return {};
    }
  }

  /// Get state-wise traffic signal summary
  Future<Map<String, Map<String, dynamic>>> getStateWiseSummary() async {
    try {
      final signals = await getAllTrafficSignals();
      final stateSummary = <String, Map<String, dynamic>>{};
      
      for (final signal in signals) {
        final state = signal.state;
        if (!stateSummary.containsKey(state)) {
          stateSummary[state] = {
            'totalRegions': 0,
            'goodRegions': 0,
            'warningRegions': 0,
            'criticalRegions': 0,
            'averageRiskScore': 0.0,
            'totalStations': 0,
            'activeStations': 0,
            'regionsRequiringAction': 0,
          };
        }
        
        final summary = stateSummary[state]!;
        summary['totalRegions'] = (summary['totalRegions'] as int) + 1;
        
        switch (signal.level) {
          case TrafficSignalLevel.good:
            summary['goodRegions'] = (summary['goodRegions'] as int) + 1;
            break;
          case TrafficSignalLevel.warning:
            summary['warningRegions'] = (summary['warningRegions'] as int) + 1;
            break;
          case TrafficSignalLevel.critical:
            summary['criticalRegions'] = (summary['criticalRegions'] as int) + 1;
            break;
        }
        
        summary['totalStations'] = (summary['totalStations'] as int) + signal.stationCount;
        summary['activeStations'] = (summary['activeStations'] as int) + signal.activeStations;
        
        if (signal.requiresImmediateAction) {
          summary['regionsRequiringAction'] = (summary['regionsRequiringAction'] as int) + 1;
        }
      }
      
      // Calculate average risk scores
      for (final state in stateSummary.keys) {
        final stateSignals = signals.where((s) => s.state == state).toList();
        if (stateSignals.isNotEmpty) {
          final avgRiskScore = stateSignals.map((s) => s.riskScore).reduce((a, b) => a + b) / stateSignals.length;
          stateSummary[state]!['averageRiskScore'] = avgRiskScore;
        }
      }
      
      _logger.i('📊 State-wise summary generated for ${stateSummary.length} states');
      return stateSummary;
    } catch (e) {
      _logger.e('❌ Error getting state-wise summary: $e');
      return {};
    }
  }

  /// Validate traffic signal data
  bool validateTrafficSignal(TrafficSignal signal) {
    try {
      // Check required fields
      if (signal.regionId.isEmpty || signal.regionName.isEmpty) {
        return false;
      }
      
      // Check depth values
      if (signal.averageDepth.isNaN || signal.minDepth.isNaN || signal.maxDepth.isNaN) {
        return false;
      }
      
      // Check station counts
      if (signal.stationCount < 0 || signal.activeStations < 0 || signal.activeStations > signal.stationCount) {
        return false;
      }
      
      // Check risk score
      if (signal.riskScore < 0.0 || signal.riskScore > 1.0) {
        return false;
      }
      
      return true;
    } catch (e) {
      _logger.e('❌ Error validating traffic signal: $e');
      return false;
    }
  }

  /// Filter traffic signals by criteria
  List<TrafficSignal> filterTrafficSignals(
    List<TrafficSignal> signals, {
    TrafficSignalLevel? level,
    String? state,
    String? district,
    double? minRiskScore,
    double? maxRiskScore,
    bool? requiresAction,
    bool? requiresMonitoring,
  }) {
    try {
      var filteredSignals = signals;
      
      if (level != null) {
        filteredSignals = filteredSignals.where((s) => s.level == level).toList();
      }
      
      if (state != null) {
        filteredSignals = filteredSignals.where((s) => s.state.toLowerCase().contains(state.toLowerCase())).toList();
      }
      
      if (district != null) {
        filteredSignals = filteredSignals.where((s) => s.district.toLowerCase().contains(district.toLowerCase())).toList();
      }
      
      if (minRiskScore != null) {
        filteredSignals = filteredSignals.where((s) => s.riskScore >= minRiskScore).toList();
      }
      
      if (maxRiskScore != null) {
        filteredSignals = filteredSignals.where((s) => s.riskScore <= maxRiskScore).toList();
      }
      
      if (requiresAction == true) {
        filteredSignals = filteredSignals.where((s) => s.requiresImmediateAction).toList();
      }
      
      if (requiresMonitoring == true) {
        filteredSignals = filteredSignals.where((s) => s.requiresMonitoring).toList();
      }
      
      return filteredSignals;
    } catch (e) {
      _logger.e('❌ Error filtering traffic signals: $e');
      return signals;
    }
  }
}
