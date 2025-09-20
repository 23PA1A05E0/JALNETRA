import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Simple API test screen to debug groundwater data integration
class ApiTestScreen extends ConsumerStatefulWidget {
  const ApiTestScreen({super.key});

  @override
  ConsumerState<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends ConsumerState<ApiTestScreen> {
  String _status = 'Ready to test';
  String _response = '';
  bool _isLoading = false;

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing API...';
      _response = '';
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://groundwater-level-predictor-backend.onrender.com/features',
      );

      setState(() {
        _status = '✅ API Success!';
        _response = 'Status: ${response.statusCode}\n\nData: ${response.data}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ API Error';
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testLocationData() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing location data...';
      _response = '';
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://groundwater-level-predictor-backend.onrender.com/features',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Check if we have the expected data structure
        final hasStationSummary = data.containsKey('station_summary');
        final hasMonthlyTrend = data.containsKey('monthly_trend');
        final hasDailyData = data.containsKey('daily_data');
        
        // Get sample data for Addanki (CGWHYD0500)
        final stationSummary = data['station_summary'] as Map<String, dynamic>?;
        final addankiData = stationSummary?['CGWHYD0500'] as Map<String, dynamic>?;
        
        setState(() {
          _status = '✅ Data Structure Valid!';
          _response = '''
API Response Structure:
- station_summary: ${hasStationSummary ? '✅' : '❌'}
- monthly_trend: ${hasMonthlyTrend ? '✅' : '❌'}
- daily_data: ${hasDailyData ? '✅' : '❌'}

Sample Data for Addanki (CGWHYD0500):
${addankiData != null ? addankiData.toString() : 'No data found'}

Total Stations: ${stationSummary?.length ?? 0}
          ''';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = '❌ Unexpected Response';
          _response = 'Status: ${response.statusCode}\nData: ${response.data}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Location Data Error';
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test Screen'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _status.contains('✅') ? Colors.green.shade50 : 
                     _status.contains('❌') ? Colors.red.shade50 : Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('✅') ? Icons.check_circle : 
                      _status.contains('❌') ? Icons.error : Icons.info,
                      color: _status.contains('✅') ? Colors.green : 
                             _status.contains('❌') ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testApi,
                    icon: _isLoading ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ) : const Icon(Icons.api),
                    label: Text(_isLoading ? 'Testing...' : 'Test API Connection'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testLocationData,
                    icon: _isLoading ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ) : const Icon(Icons.location_on),
                    label: Text(_isLoading ? 'Testing...' : 'Test Location Data'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Response Display
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Response:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _response.isEmpty ? 'No response yet. Click a test button above.' : _response,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Debug Instructions',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Click "Test API Connection" to check if the API is reachable'),
                    const Text('2. Click "Test Location Data" to verify data structure'),
                    const Text('3. Check the response for any errors or missing data'),
                    const Text('4. If API fails, check your internet connection'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
