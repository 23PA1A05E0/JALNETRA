import 'package:equatable/equatable.dart';
import 'dwlr_station.dart';

/// Model for India-WRIS Ground Water Level API response
class IndiaWRISResponse extends Equatable {
  final List<dynamic> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final int numberOfElements;

  const IndiaWRISResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.numberOfElements,
  });

  factory IndiaWRISResponse.fromJson(Map<String, dynamic> json) {
    return IndiaWRISResponse(
      content: json['content'] ?? [],
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
      numberOfElements: json['numberOfElements'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        content,
        totalElements,
        totalPages,
        size,
        number,
        first,
        last,
        numberOfElements,
      ];
}

/// Model for individual groundwater level record from India-WRIS
class GroundWaterLevelRecord extends Equatable {
  final String? stationId;
  final String? stationName;
  final String? stateName;
  final String? districtName;
  final String? blockName;
  final String? villageName;
  final double? latitude;
  final double? longitude;
  final String? agencyName;
  final DateTime? dateOfReading;
  final double? waterLevelBelowGroundLevel;
  final String? season;
  final String? year;
  final String? month;
  final String? aquiferType;
  final String? wellType;
  final String? wellDepth;
  final String? casingDepth;
  final String? screenDepth;
  final String? screenLength;
  final String? wellDiameter;
  final String? casingDiameter;
  final String? screenDiameter;
  final String? wellStatus;
  final String? dataQuality;
  final String? remarks;

  const GroundWaterLevelRecord({
    this.stationId,
    this.stationName,
    this.stateName,
    this.districtName,
    this.blockName,
    this.villageName,
    this.latitude,
    this.longitude,
    this.agencyName,
    this.dateOfReading,
    this.waterLevelBelowGroundLevel,
    this.season,
    this.year,
    this.month,
    this.aquiferType,
    this.wellType,
    this.wellDepth,
    this.casingDepth,
    this.screenDepth,
    this.screenLength,
    this.wellDiameter,
    this.casingDiameter,
    this.screenDiameter,
    this.wellStatus,
    this.dataQuality,
    this.remarks,
  });

  factory GroundWaterLevelRecord.fromJson(Map<String, dynamic> json) {
    return GroundWaterLevelRecord(
      stationId: json['stationId']?.toString(),
      stationName: json['stationName']?.toString(),
      stateName: json['stateName']?.toString(),
      districtName: json['districtName']?.toString(),
      blockName: json['blockName']?.toString(),
      villageName: json['villageName']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      agencyName: json['agencyName']?.toString(),
      dateOfReading: _parseDateTime(json['dateOfReading']),
      waterLevelBelowGroundLevel: _parseDouble(json['waterLevelBelowGroundLevel']),
      season: json['season']?.toString(),
      year: json['year']?.toString(),
      month: json['month']?.toString(),
      aquiferType: json['aquiferType']?.toString(),
      wellType: json['wellType']?.toString(),
      wellDepth: json['wellDepth']?.toString(),
      casingDepth: json['casingDepth']?.toString(),
      screenDepth: json['screenDepth']?.toString(),
      screenLength: json['screenLength']?.toString(),
      wellDiameter: json['wellDiameter']?.toString(),
      casingDiameter: json['casingDiameter']?.toString(),
      screenDiameter: json['screenDiameter']?.toString(),
      wellStatus: json['wellStatus']?.toString(),
      dataQuality: json['dataQuality']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Convert to DWLRStation for compatibility with existing UI
  DWLRStation toDWLRStation() {
    return DWLRStation(
      stationId: stationId ?? 'UNKNOWN',
      stationName: stationName ?? 'Unknown Station',
      latitude: latitude ?? 0.0,
      longitude: longitude ?? 0.0,
      state: stateName ?? 'Unknown State',
      district: districtName ?? 'Unknown District',
      basin: 'Unknown Basin',
      aquiferType: aquiferType ?? 'Unknown',
      depth: _parseDouble(wellDepth) ?? 0.0,
      currentWaterLevel: waterLevelBelowGroundLevel ?? 0.0,
      lastUpdated: dateOfReading ?? DateTime.now(),
      status: wellStatus == 'Active' ? 'Active' : 'Inactive',
      installationDate: dateOfReading ?? DateTime.now(),
      dataAvailability: dataQuality == 'Good' ? 95.0 : 75.0,
    );
  }

  @override
  List<Object?> get props => [
        stationId,
        stationName,
        stateName,
        districtName,
        blockName,
        villageName,
        latitude,
        longitude,
        agencyName,
        dateOfReading,
        waterLevelBelowGroundLevel,
        season,
        year,
        month,
        aquiferType,
        wellType,
        wellDepth,
        casingDepth,
        screenDepth,
        screenLength,
        wellDiameter,
        casingDiameter,
        screenDiameter,
        wellStatus,
        dataQuality,
        remarks,
      ];
}
