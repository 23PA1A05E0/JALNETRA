import 'package:flutter_test/flutter_test.dart';
import 'package:jalnetra/services/india_wris_service.dart';
import 'package:jalnetra/models/india_wris_models.dart';

void main() {
  group('India-WRIS API Tests', () {
    late IndiaWRISService service;

    setUp(() {
      service = IndiaWRISService();
    });

    test('should fetch available states', () async {
      final states = await service.getAvailableStates();
      expect(states, isNotEmpty);
      expect(states, contains('Andhra Pradesh'));
      expect(states, contains('Delhi'));
    });

    test('should fetch districts for Andhra Pradesh', () async {
      final districts = await service.getDistrictsByState('Andhra Pradesh');
      expect(districts, isNotEmpty);
      expect(districts, contains('West Godavari'));
    });

    test('should search stations by location', () async {
      final stations = await service.searchStationsByLocation(
        state: 'Andhra Pradesh',
        district: 'West Godavari',
      );
      expect(stations, isNotEmpty);
      expect(stations.first.state, equals('Andhra Pradesh'));
      expect(stations.first.district, equals('West Godavari'));
    });

    test('should parse GroundWaterLevelRecord correctly', () {
      final json = {
        'stationId': 'TEST001',
        'stationName': 'Test Station',
        'stateName': 'Test State',
        'districtName': 'Test District',
        'latitude': 28.6139,
        'longitude': 77.2090,
        'waterLevelBelowGroundLevel': 15.5,
        'dateOfReading': '2023-10-26T10:00:00Z',
        'wellStatus': 'Active',
        'dataQuality': 'Good',
      };

      final record = GroundWaterLevelRecord.fromJson(json);
      expect(record.stationId, equals('TEST001'));
      expect(record.stationName, equals('Test Station'));
      expect(record.stateName, equals('Test State'));
      expect(record.districtName, equals('Test District'));
      expect(record.latitude, equals(28.6139));
      expect(record.longitude, equals(77.2090));
      expect(record.waterLevelBelowGroundLevel, equals(15.5));
    });

    test('should convert GroundWaterLevelRecord to DWLRStation', () {
      final json = {
        'stationId': 'TEST001',
        'stationName': 'Test Station',
        'stateName': 'Test State',
        'districtName': 'Test District',
        'latitude': 28.6139,
        'longitude': 77.2090,
        'waterLevelBelowGroundLevel': 15.5,
        'dateOfReading': '2023-10-26T10:00:00Z',
        'wellStatus': 'Active',
        'dataQuality': 'Good',
      };

      final record = GroundWaterLevelRecord.fromJson(json);
      final station = record.toDWLRStation();
      
      expect(station.stationId, equals('TEST001'));
      expect(station.stationName, equals('Test Station'));
      expect(station.state, equals('Test State'));
      expect(station.district, equals('Test District'));
      expect(station.latitude, equals(28.6139));
      expect(station.longitude, equals(77.2090));
      expect(station.currentWaterLevel, equals(15.5));
      expect(station.status, equals('Active'));
    });
  });
}
