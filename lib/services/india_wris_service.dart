import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/dwlr_station.dart';
import '../models/india_wris_models.dart';

/// Service for fetching DWLR data from India-WRIS API
class IndiaWRISService {
  static const String _baseUrl = 'https://indiawris.gov.in';
  // static const String _apiKey = 'your-india-wris-api-key'; // TODO: Get from India-WRIS
  
  late final Dio _dio;
  final Logger _logger = Logger();

  IndiaWRISService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        // 'Authorization': 'Bearer $_apiKey', // Uncomment when you have API key
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) {
        return status != null && status < 500; // Accept all status codes below 500
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.d(obj),
    ));

    // Add CORS handling interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add CORS headers for web requests
        options.headers['Access-Control-Allow-Origin'] = '*';
        options.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
        options.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
        handler.next(options);
      },
      onError: (error, handler) {
        _logger.e('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// Fetch DWLR stations from India-WRIS API
  /// TODO: Implement actual API call to India-WRIS
  Future<List<DWLRStation>> getDWLRStations({
    String? state,
    String? district,
    String? basin,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
  }) async {
    try {
      _logger.i('Fetching DWLR stations from India-WRIS...');
      
      // TODO: Replace with actual India-WRIS API call
      // final response = await _dio.get('/dwlr/stations', queryParameters: {
      //   'state': state,
      //   'district': district,
      //   'basin': basin,
      //   'min_lat': minLat,
      //   'max_lat': maxLat,
      //   'min_lng': minLng,
      //   'max_lng': maxLng,
      // });
      // return (response.data as List)
      //     .map((json) => DWLRStation.fromJson(json))
      //     .toList();
      
      // Mock data based on real Indian groundwater stations
      await Future.delayed(const Duration(seconds: 1));
      return _getMockDWLRStations();
    } catch (e) {
      _logger.e('Error fetching DWLR stations: $e');
      rethrow;
    }
  }

  /// Fetch water level data for a specific DWLR station
  /// TODO: Implement actual API call
  Future<List<WaterLevelData>> getWaterLevelData({
    required String stationId,
    required DateTime startDate,
    required DateTime endDate,
    String interval = 'daily', // daily, weekly, monthly
  }) async {
    try {
      _logger.i('Fetching water level data for station $stationId');
      
      // TODO: Replace with actual API call
      // final response = await _dio.get('/dwlr/stations/$stationId/data', queryParameters: {
      //   'start_date': startDate.toIso8601String().split('T')[0],
      //   'end_date': endDate.toIso8601String().split('T')[0],
      //   'interval': interval,
      // });
      // return (response.data as List)
      //     .map((json) => WaterLevelData.fromJson(json))
      //     .toList();
      
      // Mock data with realistic groundwater level patterns
      await Future.delayed(const Duration(seconds: 1));
      return _generateMockWaterLevelData(stationId, startDate, endDate, interval);
    } catch (e) {
      _logger.e('Error fetching water level data: $e');
      rethrow;
    }
  }

  /// Get station statistics and trends
  /// TODO: Implement actual API call
  Future<StationStatistics> getStationStatistics(String stationId) async {
    try {
      _logger.i('Fetching statistics for station $stationId');
      
      // TODO: Replace with actual API call
      // final response = await _dio.get('/dwlr/stations/$stationId/statistics');
      // return StationStatistics.fromJson(response.data);
      
      // Mock statistics
      await Future.delayed(const Duration(seconds: 1));
      return _generateMockStatistics(stationId);
    } catch (e) {
      _logger.e('Error fetching station statistics: $e');
      rethrow;
    }
  }

  /// Search stations by name or location
  /// TODO: Implement actual API call
  Future<List<DWLRStation>> searchStations(String query) async {
    try {
      _logger.i('Searching stations with query: $query');
      
      // TODO: Replace with actual API call
      // final response = await _dio.get('/dwlr/stations/search', queryParameters: {
      //   'q': query,
      // });
      // return (response.data as List)
      //     .map((json) => DWLRStation.fromJson(json))
      //     .toList();
      
      // Mock search results
      await Future.delayed(const Duration(seconds: 1));
      final allStations = await getDWLRStations();
      return allStations.where((station) =>
        station.stationName.toLowerCase().contains(query.toLowerCase()) ||
        station.district.toLowerCase().contains(query.toLowerCase()) ||
        station.state.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      _logger.e('Error searching stations: $e');
      rethrow;
    }
  }

  /// Search groundwater stations by location (state, district)
  /// This method integrates with the real India-WRIS API
  Future<List<DWLRStation>> searchStationsByLocation({
    String? state,
    String? district,
  }) async {
    try {
      _logger.i('Searching stations by location - State: $state, District: $district');

      // Build query parameters for India-WRIS API
      Map<String, dynamic> queryParams = {
        'agencyName': 'CGWB', // Central Ground Water Board
        'startdate': '2005-09-15', // Historical data start
        'enddate': '2025-09-15', // Future data end
        'page': 0,
        'size': 1000, // Maximum results per page
      };
      
      if (state != null && state.isNotEmpty) {
        queryParams['stateName'] = state;
      }
      if (district != null && district.isNotEmpty) {
        queryParams['districtName'] = district;
      }

      _logger.i('Making API request to: $_baseUrl/Dataset/Ground Water Level');
      _logger.i('Query parameters: $queryParams');

      // Call the real India-WRIS API endpoint
      final response = await _dio.get(
        '/Dataset/Ground Water Level',
        queryParameters: queryParams,
      );

      _logger.i('API Response Status: ${response.statusCode}');
      _logger.i('API Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          // Parse the response using our new model
          final apiResponse = IndiaWRISResponse.fromJson(response.data);
          _logger.i('Found ${apiResponse.content.length} records from India-WRIS API');
          
          // Convert GroundWaterLevelRecord to DWLRStation
          final List<DWLRStation> stations = apiResponse.content
              .map((record) {
                try {
                  final gwRecord = GroundWaterLevelRecord.fromJson(record);
                  return gwRecord.toDWLRStation();
                } catch (e) {
                  _logger.w('Error parsing record: $e');
                  return null;
                }
              })
              .where((station) => station != null)
              .cast<DWLRStation>()
              .toList();
          
          _logger.i('Successfully converted ${stations.length} stations');
          return stations;
        } catch (e) {
          _logger.e('Error parsing API response: $e');
          _logger.e('Response data: ${response.data}');
          throw Exception('Failed to parse API response: $e');
        }
      } else {
        _logger.e('India-WRIS API returned status code: ${response.statusCode}');
        _logger.e('Response data: ${response.data}');
        throw Exception('Failed to fetch stations from India-WRIS: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching stations from India-WRIS API: $e');
      
      // Fallback to mock data for development
      _logger.i('Falling back to mock data for development');
      return _getMockStationsByLocation(state, district);
    }
  }

  /// Get available states from India-WRIS API
  /// Returns all 28 states of India with Union Territories
  Future<List<String>> getAvailableStates() async {
    try {
      _logger.i('Fetching available states from India-WRIS API');

      // Try to fetch from API first
      final response = await _dio.get('/Dataset/Ground Water Level', queryParameters: {
        'agencyName': 'CGWB',
        'page': 0,
        'size': 10000, // Get more data to extract states
      });

      if (response.statusCode == 200) {
        try {
          final apiResponse = IndiaWRISResponse.fromJson(response.data);
          final Set<String> uniqueStates = apiResponse.content
              .map((record) {
                try {
                  final gwRecord = GroundWaterLevelRecord.fromJson(record);
                  return gwRecord.stateName;
                } catch (e) {
                  return null;
                }
              })
              .where((state) => state != null && state.isNotEmpty)
              .cast<String>()
              .toSet();
          
          final statesList = uniqueStates.toList()..sort();
          _logger.i('Found ${statesList.length} unique states from API');
          return statesList;
        } catch (e) {
          _logger.e('Error parsing states from API: $e');
          return _getAllIndianStates();
        }
      }
      
      // Fallback to predefined list if API fails
      _logger.i('Using predefined list of Indian states');
      return _getAllIndianStates();
    } catch (e) {
      _logger.e('Error fetching states from India-WRIS API: $e');
      return _getAllIndianStates();
    }
  }

  /// Get districts for a specific state
  Future<List<String>> getDistrictsByState(String state) async {
    try {
      _logger.i('Fetching districts for state: $state');

      // Call the India-WRIS API to get districts for the specific state
      final response = await _dio.get('/Dataset/Ground Water Level', queryParameters: {
        'stateName': state,
        'agencyName': 'CGWB',
        'page': 0,
        'size': 10000, // Get more data to extract districts
      });

      if (response.statusCode == 200) {
        try {
          final apiResponse = IndiaWRISResponse.fromJson(response.data);
          final Set<String> uniqueDistricts = apiResponse.content
              .map((record) {
                try {
                  final gwRecord = GroundWaterLevelRecord.fromJson(record);
                  return gwRecord.districtName;
                } catch (e) {
                  return null;
                }
              })
              .where((district) => district != null && district.isNotEmpty)
              .cast<String>()
              .toSet();
          
          final districtsList = uniqueDistricts.toList()..sort();
          _logger.i('Found ${districtsList.length} districts for $state');
          return districtsList;
        } catch (e) {
          _logger.e('Error parsing districts from API: $e');
          return _getMockDistrictsByState(state);
        }
      } else {
        throw Exception('Failed to fetch districts: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching districts from India-WRIS API: $e');
      return _getMockDistrictsByState(state);
    }
  }


  /// Export data for a station
  /// TODO: Implement actual API call
  Future<String> exportStationData({
    required String stationId,
    required DateTime startDate,
    required DateTime endDate,
    String format = 'csv', // csv, json, excel
  }) async {
    try {
      _logger.i('Exporting data for station $stationId');
      
      // TODO: Replace with actual API call
      // final response = await _dio.get('/dwlr/stations/$stationId/export', queryParameters: {
      //   'start_date': startDate.toIso8601String().split('T')[0],
      //   'end_date': endDate.toIso8601String().split('T')[0],
      //   'format': format,
      // });
      // return response.data['download_url'];
      
      // Mock export
      await Future.delayed(const Duration(seconds: 2));
      return 'https://mock-export-url.com/data_$stationId.$format';
    } catch (e) {
      _logger.e('Error exporting data: $e');
      rethrow;
    }
  }

  // Mock data generators
  List<DWLRStation> _getMockDWLRStations() {
    return [
      DWLRStation(
        stationId: 'GW001',
        stationName: 'Central Groundwater Station',
        latitude: 28.6139,
        longitude: 77.2090,
        state: 'Delhi',
        district: 'Central Delhi',
        basin: 'Yamuna',
        aquiferType: 'Unconfined',
        depth: 45.2,
        currentWaterLevel: 12.5,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'Active',
        installationDate: DateTime(2020, 1, 15),
        dataAvailability: 95.5,
      ),
      DWLRStation(
        stationId: 'GW002',
        stationName: 'Industrial Zone Monitoring',
        latitude: 28.6200,
        longitude: 77.2200,
        state: 'Delhi',
        district: 'East Delhi',
        basin: 'Yamuna',
        aquiferType: 'Semi-confined',
        depth: 52.8,
        currentWaterLevel: 18.7,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'Active',
        installationDate: DateTime(2019, 6, 10),
        dataAvailability: 88.2,
      ),
      DWLRStation(
        stationId: 'GW003',
        stationName: 'Residential Area Station',
        latitude: 28.6000,
        longitude: 77.1900,
        state: 'Delhi',
        district: 'South Delhi',
        basin: 'Yamuna',
        aquiferType: 'Unconfined',
        depth: 38.5,
        currentWaterLevel: 8.2,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'Maintenance',
        installationDate: DateTime(2021, 3, 20),
        dataAvailability: 92.1,
      ),
      DWLRStation(
        stationId: 'GW004',
        stationName: 'Agricultural Zone DWLR',
        latitude: 28.5800,
        longitude: 77.1500,
        state: 'Delhi',
        district: 'South West Delhi',
        basin: 'Yamuna',
        aquiferType: 'Confined',
        depth: 65.0,
        currentWaterLevel: 25.3,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
        status: 'Active',
        installationDate: DateTime(2018, 11, 5),
        dataAvailability: 78.9,
      ),
      DWLRStation(
        stationId: 'GW005',
        stationName: 'Urban Monitoring Point',
        latitude: 28.6400,
        longitude: 77.2400,
        state: 'Delhi',
        district: 'North Delhi',
        basin: 'Yamuna',
        aquiferType: 'Unconfined',
        depth: 42.1,
        currentWaterLevel: 15.8,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 45)),
        status: 'Active',
        installationDate: DateTime(2020, 8, 12),
        dataAvailability: 96.3,
      ),
    ];
  }

  List<WaterLevelData> _generateMockWaterLevelData(
    String stationId,
    DateTime startDate,
    DateTime endDate,
    String interval,
  ) {
    final data = <WaterLevelData>[];
    final days = endDate.difference(startDate).inDays;
    
    for (int i = 0; i <= days; i++) {
      final date = startDate.add(Duration(days: i));
      
      // Generate realistic groundwater level patterns
      final baseLevel = 15.0 + (stationId.hashCode % 20);
      final seasonalVariation = 3.0 * (1 + (date.month - 6) / 6).abs();
      final randomVariation = (i % 7) * 0.5;
      
      final waterLevel = baseLevel + seasonalVariation + randomVariation;
      
      data.add(WaterLevelData(
        stationId: stationId,
        date: date,
        waterLevel: waterLevel,
        quality: i % 10 == 0 ? 'Poor' : (i % 5 == 0 ? 'Fair' : 'Good'),
        remarks: i % 15 == 0 ? 'Maintenance check' : '',
      ));
    }
    
    return data;
  }

  StationStatistics _generateMockStatistics(String stationId) {
    return StationStatistics(
      stationId: stationId,
      totalReadings: 365,
      averageLevel: 15.2,
      minLevel: 8.5,
      maxLevel: 22.1,
      trend: 'Declining',
      trendPercentage: -2.3,
      lastYearAverage: 15.6,
      seasonalVariation: 4.2,
      dataQuality: 'Good',
      lastMaintenance: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  /// Mock data fallback methods for location-based search
  List<DWLRStation> _getMockStationsByLocation(String? state, String? district) {
    final List<Map<String, dynamic>> mockData = [
      {
        'stationId': 'STN001',
        'stationName': 'Yamuna Nagar',
        'state': 'Haryana',
        'district': 'Yamunanagar',
        'latitude': 30.1769,
        'longitude': 77.2680,
        'status': 'Active',
        'lastUpdated': '2023-10-26T10:00:00Z',
        'currentWaterLevel': 15.2,
        'waterLevelChange24h': -0.1,
        'alertStatus': 'Normal',
        'alertSeverity': 'low',
        'description': 'Monitoring station near Yamuna river.',
        'type': 'Groundwater',
        'installationDate': '2020-01-15',
        'sensorType': 'Pressure Transducer',
        'dataFrequency': 'Hourly',
        'contactPerson': 'Dr. R. Sharma',
        'contactEmail': 'r.sharma@example.com',
        'metadata': {'basin': 'Ganga', 'aquiferType': 'Alluvial'},
        'basin': 'Ganga',
        'aquiferType': 'Alluvial',
        'depth': 45.0,
        'dataAvailability': 95.5,
        'remarks': 'Good data quality',
      },
      {
        'stationId': 'STN002',
        'stationName': 'Delhi Central',
        'state': 'Delhi',
        'district': 'Central Delhi',
        'latitude': 28.6139,
        'longitude': 77.2090,
        'status': 'Active',
        'lastUpdated': '2023-10-26T09:30:00Z',
        'currentWaterLevel': 12.8,
        'waterLevelChange24h': 0.2,
        'alertStatus': 'Normal',
        'alertSeverity': 'low',
        'description': 'Urban groundwater monitoring station.',
        'type': 'Groundwater',
        'installationDate': '2019-03-20',
        'sensorType': 'Digital Water Level Recorder',
        'dataFrequency': 'Daily',
        'contactPerson': 'Dr. A. Kumar',
        'contactEmail': 'a.kumar@example.com',
        'metadata': {'basin': 'Yamuna', 'aquiferType': 'Alluvial'},
        'basin': 'Yamuna',
        'aquiferType': 'Alluvial',
        'depth': 38.0,
        'dataAvailability': 88.2,
        'remarks': 'Moderate data quality',
      },
      {
        'stationId': 'STN003',
        'stationName': 'Punjab Agricultural',
        'state': 'Punjab',
        'district': 'Ludhiana',
        'latitude': 30.9010,
        'longitude': 75.8573,
        'status': 'Active',
        'lastUpdated': '2023-10-26T11:15:00Z',
        'currentWaterLevel': 8.5,
        'waterLevelChange24h': -0.3,
        'alertStatus': 'Critical',
        'alertSeverity': 'high',
        'description': 'Agricultural area groundwater monitoring.',
        'type': 'Groundwater',
        'installationDate': '2021-07-10',
        'sensorType': 'Pressure Transducer',
        'dataFrequency': 'Hourly',
        'contactPerson': 'Dr. S. Singh',
        'contactEmail': 's.singh@example.com',
        'metadata': {'basin': 'Sutlej', 'aquiferType': 'Alluvial'},
        'basin': 'Sutlej',
        'aquiferType': 'Alluvial',
        'depth': 52.0,
        'dataAvailability': 92.1,
        'remarks': 'Critical water level - immediate attention required',
      },
    ];

    // Filter mock data based on search criteria
    List<Map<String, dynamic>> filteredData = mockData;
    
    if (state != null && state.isNotEmpty) {
      filteredData = filteredData.where((station) => 
        station['state'].toString().toLowerCase().contains(state.toLowerCase())).toList();
    }
    
    if (district != null && district.isNotEmpty) {
      filteredData = filteredData.where((station) => 
        station['district'].toString().toLowerCase().contains(district.toLowerCase())).toList();
    }
    

    return filteredData.map((json) => DWLRStation.fromJson(json)).toList();
  }

  /// Get all 28 states of India plus Union Territories
  List<String> _getAllIndianStates() {
    return [
      // States
      'Andhra Pradesh',
      'Arunachal Pradesh',
      'Assam',
      'Bihar',
      'Chhattisgarh',
      'Goa',
      'Gujarat',
      'Haryana',
      'Himachal Pradesh',
      'Jharkhand',
      'Karnataka',
      'Kerala',
      'Madhya Pradesh',
      'Maharashtra',
      'Manipur',
      'Meghalaya',
      'Mizoram',
      'Nagaland',
      'Odisha',
      'Punjab',
      'Rajasthan',
      'Sikkim',
      'Tamil Nadu',
      'Telangana',
      'Tripura',
      'Uttar Pradesh',
      'Uttarakhand',
      'West Bengal',
      // Union Territories
      'Andaman and Nicobar Islands',
      'Chandigarh',
      'Dadra and Nagar Haveli and Daman and Diu',
      'Delhi',
      'Jammu and Kashmir',
      'Ladakh',
      'Lakshadweep',
      'Puducherry',
    ];
  }

  List<String> _getMockDistrictsByState(String state) {
    switch (state.toLowerCase()) {
      case 'andhra pradesh':
        return ['West Godavari', 'East Godavari', 'Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Anantapur'];
      case 'delhi':
        return ['Central Delhi', 'New Delhi', 'East Delhi', 'West Delhi', 'North Delhi', 'South Delhi'];
      case 'haryana':
        return ['Yamunanagar', 'Gurgaon', 'Faridabad', 'Panipat', 'Karnal', 'Hisar', 'Rohtak', 'Sonipat'];
      case 'punjab':
        return ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Firozpur', 'Sangrur'];
      case 'rajasthan':
        return ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer', 'Bikaner', 'Alwar', 'Bharatpur'];
      case 'uttar pradesh':
        return ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Meerut', 'Allahabad', 'Bareilly', 'Ghaziabad'];
      case 'maharashtra':
        return ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad', 'Solapur', 'Amravati', 'Kolhapur'];
      case 'karnataka':
        return ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum', 'Gulbarga', 'Davanagere', 'Bellary'];
      case 'tamil nadu':
        return ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tirunelveli', 'Erode', 'Vellore'];
      case 'gujarat':
        return ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Junagadh', 'Gandhinagar'];
      case 'west bengal':
        return ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri', 'Bardhaman', 'Malda', 'Nadia'];
      case 'bihar':
        return ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga', 'Purnia', 'Sitamarhi', 'Saran'];
      case 'madhya pradesh':
        return ['Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain', 'Sagar', 'Dewas', 'Satna'];
      case 'kerala':
        return ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam', 'Palakkad', 'Malappuram', 'Kannur'];
      case 'odisha':
        return ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur', 'Puri', 'Balasore', 'Bhadrak'];
      case 'assam':
        return ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Tezpur', 'Nagaon', 'Tinsukia', 'Goalpara'];
      case 'jharkhand':
        return ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh', 'Giridih', 'Palamu'];
      case 'chhattisgarh':
        return ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Rajnandgaon', 'Durg', 'Raigarh', 'Jagdalpur'];
      case 'himachal pradesh':
        return ['Shimla', 'Kangra', 'Mandi', 'Solan', 'Una', 'Chamba', 'Sirmaur', 'Bilaspur'];
      case 'uttarakhand':
        return ['Dehradun', 'Haridwar', 'Roorkee', 'Rudrapur', 'Kashipur', 'Haldwani', 'Rishikesh', 'Nainital'];
      case 'telangana':
        return ['Hyderabad', 'Warangal', 'Nizamabad', 'Khammam', 'Karimnagar', 'Ramagundam', 'Mahbubnagar', 'Nalgonda'];
      case 'goa':
        return ['North Goa', 'South Goa'];
      case 'manipur':
        return ['Imphal East', 'Imphal West', 'Thoubal', 'Bishnupur', 'Churachandpur', 'Senapati', 'Ukhrul', 'Chandel'];
      case 'meghalaya':
        return ['East Khasi Hills', 'West Khasi Hills', 'Jaintia Hills', 'Ri Bhoi', 'East Garo Hills', 'West Garo Hills', 'South Garo Hills'];
      case 'mizoram':
        return ['Aizawl', 'Lunglei', 'Champhai', 'Serchhip', 'Kolasib', 'Mamit', 'Lawngtlai', 'Saiha'];
      case 'nagaland':
        return ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha', 'Zunheboto', 'Phek', 'Mon'];
      case 'tripura':
        return ['West Tripura', 'South Tripura', 'Dhalai', 'North Tripura', 'Unakoti', 'Khowai', 'Sepahijala', 'Gomati'];
      case 'sikkim':
        return ['East Sikkim', 'West Sikkim', 'North Sikkim', 'South Sikkim'];
      case 'arunachal pradesh':
        return ['Papum Pare', 'Changlang', 'Lohit', 'Tirap', 'West Siang', 'East Siang', 'Upper Siang', 'Lower Siang'];
      default:
        return ['District 1', 'District 2', 'District 3'];
    }
  }
}
