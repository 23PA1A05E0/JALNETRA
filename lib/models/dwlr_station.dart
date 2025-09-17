import 'package:equatable/equatable.dart';

/// DWLR Station model representing groundwater monitoring stations from India-WRIS
class DWLRStation extends Equatable {
  final String stationId;
  final String stationName;
  final double latitude;
  final double longitude;
  final String state;
  final String district;
  final String basin;
  final String aquiferType; // Unconfined, Semi-confined, Confined
  final double depth; // Total depth in meters
  final double currentWaterLevel; // Current water level in meters
  final DateTime lastUpdated;
  final String status; // Active, Inactive, Maintenance
  final DateTime installationDate;
  final double dataAvailability; // Percentage of data availability
  final String? remarks;

  const DWLRStation({
    required this.stationId,
    required this.stationName,
    required this.latitude,
    required this.longitude,
    required this.state,
    required this.district,
    required this.basin,
    required this.aquiferType,
    required this.depth,
    required this.currentWaterLevel,
    required this.lastUpdated,
    required this.status,
    required this.installationDate,
    required this.dataAvailability,
    this.remarks,
  });

  factory DWLRStation.fromJson(Map<String, dynamic> json) {
    return DWLRStation(
      stationId: json['station_id'] as String,
      stationName: json['station_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      state: json['state'] as String,
      district: json['district'] as String,
      basin: json['basin'] as String,
      aquiferType: json['aquifer_type'] as String,
      depth: (json['depth'] as num).toDouble(),
      currentWaterLevel: (json['current_water_level'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      status: json['status'] as String,
      installationDate: DateTime.parse(json['installation_date'] as String),
      dataAvailability: (json['data_availability'] as num).toDouble(),
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'station_name': stationName,
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'district': district,
      'basin': basin,
      'aquifer_type': aquiferType,
      'depth': depth,
      'current_water_level': currentWaterLevel,
      'last_updated': lastUpdated.toIso8601String(),
      'status': status,
      'installation_date': installationDate.toIso8601String(),
      'data_availability': dataAvailability,
      'remarks': remarks,
    };
  }

  @override
  List<Object?> get props => [
        stationId,
        stationName,
        latitude,
        longitude,
        state,
        district,
        basin,
        aquiferType,
        depth,
        currentWaterLevel,
        lastUpdated,
        status,
        installationDate,
        dataAvailability,
        remarks,
      ];
}

/// Water Level Data model for time series data
class WaterLevelData extends Equatable {
  final String stationId;
  final DateTime date;
  final double waterLevel; // Water level in meters below ground level
  final String quality; // Good, Fair, Poor
  final String remarks;

  const WaterLevelData({
    required this.stationId,
    required this.date,
    required this.waterLevel,
    required this.quality,
    this.remarks = '',
  });

  factory WaterLevelData.fromJson(Map<String, dynamic> json) {
    return WaterLevelData(
      stationId: json['station_id'] as String,
      date: DateTime.parse(json['date'] as String),
      waterLevel: (json['water_level'] as num).toDouble(),
      quality: json['quality'] as String,
      remarks: json['remarks'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'date': date.toIso8601String(),
      'water_level': waterLevel,
      'quality': quality,
      'remarks': remarks,
    };
  }

  @override
  List<Object?> get props => [stationId, date, waterLevel, quality, remarks];
}

/// Station Statistics model
class StationStatistics extends Equatable {
  final String stationId;
  final int totalReadings;
  final double averageLevel;
  final double minLevel;
  final double maxLevel;
  final String trend; // Rising, Declining, Stable
  final double trendPercentage; // Percentage change
  final double lastYearAverage;
  final double seasonalVariation;
  final String dataQuality; // Good, Fair, Poor
  final DateTime lastMaintenance;

  const StationStatistics({
    required this.stationId,
    required this.totalReadings,
    required this.averageLevel,
    required this.minLevel,
    required this.maxLevel,
    required this.trend,
    required this.trendPercentage,
    required this.lastYearAverage,
    required this.seasonalVariation,
    required this.dataQuality,
    required this.lastMaintenance,
  });

  factory StationStatistics.fromJson(Map<String, dynamic> json) {
    return StationStatistics(
      stationId: json['station_id'] as String,
      totalReadings: json['total_readings'] as int,
      averageLevel: (json['average_level'] as num).toDouble(),
      minLevel: (json['min_level'] as num).toDouble(),
      maxLevel: (json['max_level'] as num).toDouble(),
      trend: json['trend'] as String,
      trendPercentage: (json['trend_percentage'] as num).toDouble(),
      lastYearAverage: (json['last_year_average'] as num).toDouble(),
      seasonalVariation: (json['seasonal_variation'] as num).toDouble(),
      dataQuality: json['data_quality'] as String,
      lastMaintenance: DateTime.parse(json['last_maintenance'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'station_id': stationId,
      'total_readings': totalReadings,
      'average_level': averageLevel,
      'min_level': minLevel,
      'max_level': maxLevel,
      'trend': trend,
      'trend_percentage': trendPercentage,
      'last_year_average': lastYearAverage,
      'seasonal_variation': seasonalVariation,
      'data_quality': dataQuality,
      'last_maintenance': lastMaintenance.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        stationId,
        totalReadings,
        averageLevel,
        minLevel,
        maxLevel,
        trend,
        trendPercentage,
        lastYearAverage,
        seasonalVariation,
        dataQuality,
        lastMaintenance,
      ];
}

/// Groundwater Alert model
class GroundwaterAlert extends Equatable {
  final String id;
  final String stationId;
  final String stationName;
  final AlertType type;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic> metadata;

  const GroundwaterAlert({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.isRead,
    this.metadata = const {},
  });

  factory GroundwaterAlert.fromJson(Map<String, dynamic> json) {
    return GroundwaterAlert(
      id: json['id'] as String,
      stationId: json['station_id'] as String,
      stationName: json['station_name'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.waterLevelDecline,
      ),
      message: json['message'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.medium,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_id': stationId,
      'station_name': stationName,
      'type': type.name,
      'message': message,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        stationId,
        stationName,
        type,
        message,
        severity,
        timestamp,
        isRead,
        metadata,
      ];
}

/// Alert types for groundwater monitoring
enum AlertType {
  waterLevelDecline,
  waterLevelRise,
  dataGap,
  maintenanceRequired,
  qualityIssue,
  thresholdExceeded,
}

/// Alert severity levels
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}
