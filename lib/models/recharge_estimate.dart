import 'package:equatable/equatable.dart';

/// Recharge estimate model for groundwater recharge calculations
class RechargeEstimate extends Equatable {
  final String id;
  final String stationId;
  final DateTime timestamp;
  final double estimatedRechargeRate; // liters per hour
  final double confidence; // 0.0 to 1.0
  final RechargeMethod method;
  final Map<String, double> parameters; // method-specific parameters
  final String status; // calculated, pending, failed
  final String notes;
  final double actualRechargeRate; // measured actual rate
  final double accuracy; // accuracy percentage

  const RechargeEstimate({
    required this.id,
    required this.stationId,
    required this.timestamp,
    required this.estimatedRechargeRate,
    required this.confidence,
    required this.method,
    required this.parameters,
    required this.status,
    this.notes = '',
    this.actualRechargeRate = 0.0,
    this.accuracy = 0.0,
  });

  factory RechargeEstimate.fromJson(Map<String, dynamic> json) {
    return RechargeEstimate(
      id: json['id'] as String,
      stationId: json['stationId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      estimatedRechargeRate: (json['estimatedRechargeRate'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      method: RechargeMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => RechargeMethod.waterLevelChange,
      ),
      parameters: Map<String, double>.from(json['parameters'] as Map),
      status: json['status'] as String,
      notes: json['notes'] as String? ?? '',
      actualRechargeRate: (json['actualRechargeRate'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationId': stationId,
      'timestamp': timestamp.toIso8601String(),
      'estimatedRechargeRate': estimatedRechargeRate,
      'confidence': confidence,
      'method': method.name,
      'parameters': parameters,
      'status': status,
      'notes': notes,
      'actualRechargeRate': actualRechargeRate,
      'accuracy': accuracy,
    };
  }

  @override
  List<Object?> get props => [
        id,
        stationId,
        timestamp,
        estimatedRechargeRate,
        confidence,
        method,
        parameters,
        status,
        notes,
        actualRechargeRate,
        accuracy,
      ];
}

/// Recharge calculation methods
enum RechargeMethod {
  waterLevelChange,
  temperatureCorrelation,
  phVariation,
  machineLearning,
  manualInput,
}

/// Recharge estimate status
enum RechargeStatus {
  calculated,
  pending,
  failed,
}

/// Recharge configuration for a station
class RechargeConfig extends Equatable {
  final String stationId;
  final double targetYield; // liters per hour
  final RechargeMethod preferredMethod;
  final Map<String, double> thresholds; // alert thresholds
  final bool autoAdjust; // auto-adjust based on conditions
  final bool notificationsEnabled;
  final double minYieldThreshold;
  final double maxYieldThreshold;
  final double temperatureThreshold;
  final double phThreshold;
  final String notes;

  const RechargeConfig({
    required this.stationId,
    required this.targetYield,
    required this.preferredMethod,
    required this.thresholds,
    required this.autoAdjust,
    required this.notificationsEnabled,
    this.minYieldThreshold = 0.0,
    this.maxYieldThreshold = 0.0,
    this.temperatureThreshold = 0.0,
    this.phThreshold = 0.0,
    this.notes = '',
  });

  factory RechargeConfig.fromJson(Map<String, dynamic> json) {
    return RechargeConfig(
      stationId: json['stationId'] as String,
      targetYield: (json['targetYield'] as num).toDouble(),
      preferredMethod: RechargeMethod.values.firstWhere(
        (e) => e.name == json['preferredMethod'],
        orElse: () => RechargeMethod.waterLevelChange,
      ),
      thresholds: Map<String, double>.from(json['thresholds'] as Map),
      autoAdjust: json['autoAdjust'] as bool,
      notificationsEnabled: json['notificationsEnabled'] as bool,
      minYieldThreshold: (json['minYieldThreshold'] as num?)?.toDouble() ?? 0.0,
      maxYieldThreshold: (json['maxYieldThreshold'] as num?)?.toDouble() ?? 0.0,
      temperatureThreshold: (json['temperatureThreshold'] as num?)?.toDouble() ?? 0.0,
      phThreshold: (json['phThreshold'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'targetYield': targetYield,
      'preferredMethod': preferredMethod.name,
      'thresholds': thresholds,
      'autoAdjust': autoAdjust,
      'notificationsEnabled': notificationsEnabled,
      'minYieldThreshold': minYieldThreshold,
      'maxYieldThreshold': maxYieldThreshold,
      'temperatureThreshold': temperatureThreshold,
      'phThreshold': phThreshold,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [
        stationId,
        targetYield,
        preferredMethod,
        thresholds,
        autoAdjust,
        notificationsEnabled,
        minYieldThreshold,
        maxYieldThreshold,
        temperatureThreshold,
        phThreshold,
        notes,
      ];
}

/// Recharge alert model
class RechargeAlert extends Equatable {
  final String id;
  final String stationId;
  final DateTime timestamp;
  final AlertType type;
  final String message;
  final AlertSeverity severity;
  final bool isRead;
  final String actionRequired;
  final Map<String, dynamic> metadata;

  const RechargeAlert({
    required this.id,
    required this.stationId,
    required this.timestamp,
    required this.type,
    required this.message,
    required this.severity,
    required this.isRead,
    this.actionRequired = '',
    this.metadata = const {},
  });

  factory RechargeAlert.fromJson(Map<String, dynamic> json) {
    return RechargeAlert(
      id: json['id'] as String,
      stationId: json['stationId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.lowYield,
      ),
      message: json['message'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.medium,
      ),
      isRead: json['isRead'] as bool,
      actionRequired: json['actionRequired'] as String? ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationId': stationId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'message': message,
      'severity': severity.name,
      'isRead': isRead,
      'actionRequired': actionRequired,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        stationId,
        timestamp,
        type,
        message,
        severity,
        isRead,
        actionRequired,
        metadata,
      ];
}

/// Alert types
enum AlertType {
  lowYield,
  highYield,
  sensorFailure,
  communicationLoss,
  maintenanceRequired,
  thresholdExceeded,
}

/// Alert severity levels
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}