import 'package:equatable/equatable.dart';

/// Station model representing a groundwater monitoring station
class Station extends Equatable {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double elevation;
  final String status; // active, inactive, maintenance
  final DateTime lastUpdated;
  final String region;
  final String district;
  final String state;
  final String country;
  final List<String> parameters; // water_level, temperature, ph, etc.
  final double currentWaterLevel;
  final double currentTemperature;
  final double currentPh;
  final double rechargeRate; // liters per hour
  final bool isRechargeActive;
  final double targetYield; // target recharge yield in liters/hour

  const Station({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.status,
    required this.lastUpdated,
    required this.region,
    required this.district,
    required this.state,
    required this.country,
    this.parameters = const [],
    this.currentWaterLevel = 0.0,
    this.currentTemperature = 0.0,
    this.currentPh = 7.0,
    this.rechargeRate = 0.0,
    this.isRechargeActive = false,
    this.targetYield = 0.0,
  });

  Station copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    double? elevation,
    String? status,
    DateTime? lastUpdated,
    String? region,
    String? district,
    String? state,
    String? country,
    List<String>? parameters,
    double? currentWaterLevel,
    double? currentTemperature,
    double? currentPh,
    double? rechargeRate,
    bool? isRechargeActive,
    double? targetYield,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      region: region ?? this.region,
      district: district ?? this.district,
      state: state ?? this.state,
      country: country ?? this.country,
      parameters: parameters ?? this.parameters,
      currentWaterLevel: currentWaterLevel ?? this.currentWaterLevel,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      currentPh: currentPh ?? this.currentPh,
      rechargeRate: rechargeRate ?? this.rechargeRate,
      isRechargeActive: isRechargeActive ?? this.isRechargeActive,
      targetYield: targetYield ?? this.targetYield,
    );
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      elevation: (json['elevation'] as num).toDouble(),
      status: json['status'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      region: json['region'] as String,
      district: json['district'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      parameters: (json['parameters'] as List<dynamic>?)?.cast<String>() ?? [],
      currentWaterLevel: (json['currentWaterLevel'] as num?)?.toDouble() ?? 0.0,
      currentTemperature: (json['currentTemperature'] as num?)?.toDouble() ?? 0.0,
      currentPh: (json['currentPh'] as num?)?.toDouble() ?? 7.0,
      rechargeRate: (json['rechargeRate'] as num?)?.toDouble() ?? 0.0,
      isRechargeActive: json['isRechargeActive'] as bool? ?? false,
      targetYield: (json['targetYield'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'status': status,
      'lastUpdated': lastUpdated.toIso8601String(),
      'region': region,
      'district': district,
      'state': state,
      'country': country,
      'parameters': parameters,
      'currentWaterLevel': currentWaterLevel,
      'currentTemperature': currentTemperature,
      'currentPh': currentPh,
      'rechargeRate': rechargeRate,
      'isRechargeActive': isRechargeActive,
      'targetYield': targetYield,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        latitude,
        longitude,
        elevation,
        status,
        lastUpdated,
        region,
        district,
        state,
        country,
        parameters,
        currentWaterLevel,
        currentTemperature,
        currentPh,
        rechargeRate,
        isRechargeActive,
        targetYield,
      ];
}

/// Station status enumeration
enum StationStatus {
  active,
  inactive,
  maintenance,
}

/// Station parameter types
enum StationParameter {
  waterLevel,
  temperature,
  ph,
  conductivity,
  turbidity,
  dissolvedOxygen,
}