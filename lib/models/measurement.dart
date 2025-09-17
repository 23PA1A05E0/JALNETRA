import 'package:equatable/equatable.dart';

/// Measurement model representing sensor data from a station
class Measurement extends Equatable {
  final String id;
  final String stationId;
  final DateTime timestamp;
  final double waterLevel; // in meters
  final double temperature; // in Celsius
  final double ph;
  final double conductivity; // in μS/cm
  final double turbidity; // in NTU
  final double dissolvedOxygen; // in mg/L
  final double rechargeRate; // liters per hour
  final double batteryLevel; // percentage
  final double signalStrength; // percentage
  final String quality; // good, fair, poor
  final String notes;

  const Measurement({
    required this.id,
    required this.stationId,
    required this.timestamp,
    required this.waterLevel,
    required this.temperature,
    required this.ph,
    this.conductivity = 0.0,
    this.turbidity = 0.0,
    this.dissolvedOxygen = 0.0,
    this.rechargeRate = 0.0,
    this.batteryLevel = 0.0,
    this.signalStrength = 0.0,
    required this.quality,
    this.notes = '',
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as String,
      stationId: json['stationId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      waterLevel: (json['waterLevel'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      ph: (json['ph'] as num).toDouble(),
      conductivity: (json['conductivity'] as num?)?.toDouble() ?? 0.0,
      turbidity: (json['turbidity'] as num?)?.toDouble() ?? 0.0,
      dissolvedOxygen: (json['dissolvedOxygen'] as num?)?.toDouble() ?? 0.0,
      rechargeRate: (json['rechargeRate'] as num?)?.toDouble() ?? 0.0,
      batteryLevel: (json['batteryLevel'] as num?)?.toDouble() ?? 0.0,
      signalStrength: (json['signalStrength'] as num?)?.toDouble() ?? 0.0,
      quality: json['quality'] as String,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationId': stationId,
      'timestamp': timestamp.toIso8601String(),
      'waterLevel': waterLevel,
      'temperature': temperature,
      'ph': ph,
      'conductivity': conductivity,
      'turbidity': turbidity,
      'dissolvedOxygen': dissolvedOxygen,
      'rechargeRate': rechargeRate,
      'batteryLevel': batteryLevel,
      'signalStrength': signalStrength,
      'quality': quality,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        id,
        stationId,
        timestamp,
        waterLevel,
        temperature,
        ph,
        conductivity,
        turbidity,
        dissolvedOxygen,
        rechargeRate,
        batteryLevel,
        signalStrength,
        quality,
        notes,
      ];
}

/// Measurement quality enumeration
enum MeasurementQuality {
  good,
  fair,
  poor,
}

/// Time interval for data aggregation
enum TimeInterval {
  minute,
  hour,
  day,
  week,
  month,
}

/// Measurement aggregation model for chart data
class MeasurementAggregate extends Equatable {
  final DateTime timestamp;
  final double avgWaterLevel;
  final double minWaterLevel;
  final double maxWaterLevel;
  final double avgTemperature;
  final double avgPh;
  final double avgRechargeRate;
  final int measurementCount;

  const MeasurementAggregate({
    required this.timestamp,
    required this.avgWaterLevel,
    required this.minWaterLevel,
    required this.maxWaterLevel,
    required this.avgTemperature,
    required this.avgPh,
    required this.avgRechargeRate,
    required this.measurementCount,
  });

  factory MeasurementAggregate.fromJson(Map<String, dynamic> json) {
    return MeasurementAggregate(
      timestamp: DateTime.parse(json['timestamp'] as String),
      avgWaterLevel: (json['avgWaterLevel'] as num).toDouble(),
      minWaterLevel: (json['minWaterLevel'] as num).toDouble(),
      maxWaterLevel: (json['maxWaterLevel'] as num).toDouble(),
      avgTemperature: (json['avgTemperature'] as num).toDouble(),
      avgPh: (json['avgPh'] as num).toDouble(),
      avgRechargeRate: (json['avgRechargeRate'] as num).toDouble(),
      measurementCount: json['measurementCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'avgWaterLevel': avgWaterLevel,
      'minWaterLevel': minWaterLevel,
      'maxWaterLevel': maxWaterLevel,
      'avgTemperature': avgTemperature,
      'avgPh': avgPh,
      'avgRechargeRate': avgRechargeRate,
      'measurementCount': measurementCount,
    };
  }

  @override
  List<Object?> get props => [
        timestamp,
        avgWaterLevel,
        minWaterLevel,
        maxWaterLevel,
        avgTemperature,
        avgPh,
        avgRechargeRate,
        measurementCount,
      ];
}