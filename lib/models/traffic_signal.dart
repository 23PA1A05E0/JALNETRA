import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Traffic signal status levels for groundwater monitoring
enum TrafficSignalLevel {
  good('good', 'GOOD', 'Water levels are healthy and sustainable'),
  warning('warning', 'CAUTION', 'Water levels are declining, monitor closely'),
  critical('critical', 'CRITICAL', 'Water levels critically low, immediate action needed');

  const TrafficSignalLevel(this.level, this.status, this.description);
  
  final String level;
  final String status;
  final String description;

  /// Get color for the traffic signal level
  Color get color {
    switch (this) {
      case TrafficSignalLevel.good:
        return const Color(0xFF33B864); // Green
      case TrafficSignalLevel.warning:
        return Colors.orange;
      case TrafficSignalLevel.critical:
        return Colors.red;
    }
  }
}

/// Traffic signal model for regional groundwater status monitoring
class TrafficSignal extends Equatable {
  final String regionId;
  final String regionName;
  final String district;
  final String state;
  final TrafficSignalLevel level;
  final double averageDepth;
  final double minDepth;
  final double maxDepth;
  final double yearlyChange;
  final int stationCount;
  final int activeStations;
  final DateTime lastUpdated;
  final String dataSource;
  final Map<String, dynamic> additionalMetrics;
  final List<String> recommendations;
  final double riskScore; // 0.0 to 1.0

  const TrafficSignal({
    required this.regionId,
    required this.regionName,
    required this.district,
    required this.state,
    required this.level,
    required this.averageDepth,
    required this.minDepth,
    required this.maxDepth,
    required this.yearlyChange,
    required this.stationCount,
    required this.activeStations,
    required this.lastUpdated,
    required this.dataSource,
    this.additionalMetrics = const {},
    this.recommendations = const [],
    required this.riskScore,
  });

  /// Create TrafficSignal from API data
  factory TrafficSignal.fromApiData(Map<String, dynamic> data) {
    final avgDepth = (data['averageDepth'] as num?)?.toDouble() ?? 0.0;
    final level = _determineTrafficLevel(avgDepth);
    
    return TrafficSignal(
      regionId: data['regionId'] ?? data['region_id'] ?? '',
      regionName: data['regionName'] ?? data['region_name'] ?? '',
      district: data['district'] ?? '',
      state: data['state'] ?? '',
      level: level,
      averageDepth: avgDepth,
      minDepth: (data['minDepth'] as num?)?.toDouble() ?? 0.0,
      maxDepth: (data['maxDepth'] as num?)?.toDouble() ?? 0.0,
      yearlyChange: (data['yearlyChange'] as num?)?.toDouble() ?? 0.0,
      stationCount: data['stationCount'] ?? data['station_count'] ?? 0,
      activeStations: data['activeStations'] ?? data['active_stations'] ?? 0,
      lastUpdated: DateTime.tryParse(data['lastUpdated'] ?? data['last_updated'] ?? '') ?? DateTime.now(),
      dataSource: data['dataSource'] ?? data['data_source'] ?? 'API',
      additionalMetrics: data['additionalMetrics'] ?? data['additional_metrics'] ?? {},
      recommendations: List<String>.from(data['recommendations'] ?? []),
      riskScore: _calculateRiskScore(avgDepth, data),
    );
  }

  /// Determine traffic signal level based on average depth
  static TrafficSignalLevel _determineTrafficLevel(double averageDepth) {
    final depthValue = averageDepth.abs();
    
    if (depthValue >= 0 && depthValue <= 5) {
      return TrafficSignalLevel.good; // Green: 0 to -5 meters
    } else if (depthValue >= 6 && depthValue <= 16) {
      return TrafficSignalLevel.warning; // Orange: -6 to -16 meters
    } else {
      return TrafficSignalLevel.critical; // Red: beyond -16 meters
    }
  }

  /// Calculate risk score based on depth and other factors
  static double _calculateRiskScore(double averageDepth, Map<String, dynamic> data) {
    final depthValue = averageDepth.abs();
    double score = 0.0;
    
    // Depth factor (0-0.6)
    if (depthValue <= 5) {
      score += 0.0; // Low risk
    } else if (depthValue <= 10) {
      score += 0.2; // Medium-low risk
    } else if (depthValue <= 16) {
      score += 0.4; // Medium risk
    } else {
      score += 0.6; // High risk
    }
    
    // Yearly change factor (0-0.2)
    final yearlyChange = (data['yearlyChange'] as num?)?.toDouble() ?? 0.0;
    if (yearlyChange < -1.0) {
      score += 0.2; // Declining trend
    } else if (yearlyChange < -0.5) {
      score += 0.1; // Slight decline
    }
    
    // Station coverage factor (0-0.2)
    final stationCount = data['stationCount'] ?? data['station_count'] ?? 0;
    final activeStations = data['activeStations'] ?? data['active_stations'] ?? 0;
    if (stationCount > 0) {
      final coverageRatio = activeStations / stationCount;
      if (coverageRatio < 0.5) {
        score += 0.2; // Poor coverage
      } else if (coverageRatio < 0.8) {
        score += 0.1; // Moderate coverage
      }
    }
    
    return score.clamp(0.0, 1.0);
  }


  /// Get priority level (1 = highest priority)
  int get priority {
    switch (level) {
      case TrafficSignalLevel.critical:
        return 1;
      case TrafficSignalLevel.warning:
        return 2;
      case TrafficSignalLevel.good:
        return 3;
    }
  }

  /// Check if immediate action is required
  bool get requiresImmediateAction => level == TrafficSignalLevel.critical;

  /// Check if monitoring is recommended
  bool get requiresMonitoring => level == TrafficSignalLevel.warning || level == TrafficSignalLevel.critical;

  /// Get formatted depth string
  String get formattedDepth => '${averageDepth.toStringAsFixed(1)} m';

  /// Get formatted yearly change string
  String get formattedYearlyChange {
    if (yearlyChange > 0) {
      return '+${yearlyChange.toStringAsFixed(1)} m/year';
    } else {
      return '${yearlyChange.toStringAsFixed(1)} m/year';
    }
  }

  /// Get station coverage percentage
  double get stationCoverage {
    if (stationCount == 0) return 0.0;
    return (activeStations / stationCount) * 100;
  }

  /// Get formatted station coverage
  String get formattedStationCoverage => '${stationCoverage.toStringAsFixed(1)}%';

  /// Copy with method for updating properties
  TrafficSignal copyWith({
    String? regionId,
    String? regionName,
    String? district,
    String? state,
    TrafficSignalLevel? level,
    double? averageDepth,
    double? minDepth,
    double? maxDepth,
    double? yearlyChange,
    int? stationCount,
    int? activeStations,
    DateTime? lastUpdated,
    String? dataSource,
    Map<String, dynamic>? additionalMetrics,
    List<String>? recommendations,
    double? riskScore,
  }) {
    return TrafficSignal(
      regionId: regionId ?? this.regionId,
      regionName: regionName ?? this.regionName,
      district: district ?? this.district,
      state: state ?? this.state,
      level: level ?? this.level,
      averageDepth: averageDepth ?? this.averageDepth,
      minDepth: minDepth ?? this.minDepth,
      maxDepth: maxDepth ?? this.maxDepth,
      yearlyChange: yearlyChange ?? this.yearlyChange,
      stationCount: stationCount ?? this.stationCount,
      activeStations: activeStations ?? this.activeStations,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      dataSource: dataSource ?? this.dataSource,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
      recommendations: recommendations ?? this.recommendations,
      riskScore: riskScore ?? this.riskScore,
    );
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'regionId': regionId,
      'regionName': regionName,
      'district': district,
      'state': state,
      'level': level.level,
      'averageDepth': averageDepth,
      'minDepth': minDepth,
      'maxDepth': maxDepth,
      'yearlyChange': yearlyChange,
      'stationCount': stationCount,
      'activeStations': activeStations,
      'lastUpdated': lastUpdated.toIso8601String(),
      'dataSource': dataSource,
      'additionalMetrics': additionalMetrics,
      'recommendations': recommendations,
      'riskScore': riskScore,
    };
  }

  @override
  List<Object?> get props => [
    regionId,
    regionName,
    district,
    state,
    level,
    averageDepth,
    minDepth,
    maxDepth,
    yearlyChange,
    stationCount,
    activeStations,
    lastUpdated,
    dataSource,
    additionalMetrics,
    recommendations,
    riskScore,
  ];

  @override
  String toString() {
    return 'TrafficSignal(regionId: $regionId, regionName: $regionName, level: $level, averageDepth: $averageDepth, riskScore: $riskScore)';
  }
}
