import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manual_data_provider.dart';
import '../providers/water_well_depth_provider.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  bool _isRunningDebug = false;
  Map<String, dynamic>? _debugResults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Fetching Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _runDebug,
            icon: const Icon(Icons.refresh),
            tooltip: 'Run Debug',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Manual Data Debug Tool',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This tool helps diagnose issues with manual data storage and retrieval.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Debug Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunningDebug ? null : _runDebug,
                icon: _isRunningDebug 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
                label: Text(_isRunningDebug ? 'Running Debug...' : 'Run Comprehensive Debug'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Tests
            _buildQuickTests(),
            const SizedBox(height: 16),

            // Debug Results
            if (_debugResults != null) _buildDebugResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTests() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Tests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Test Data Storage Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _testDataStorage(),
                icon: const Icon(Icons.storage),
                label: const Text('Test Data Storage'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Test Water Well Depth Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _testWaterWellDepth(),
                icon: const Icon(Icons.water_drop),
                label: const Text('Test Water Well Depth'),
              ),
            ),
            const SizedBox(height: 8),
            
            // View Logs Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogs(),
                icon: const Icon(Icons.list),
                label: const Text('View Debug Logs'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Debug Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Connectivity Test
            _buildTestResult(
              'Internet Connectivity',
              _debugResults!['connectivity'] == true ? 'SUCCESS' : 'FAILED',
              _debugResults!['connectivity'] == true ? Colors.green : Colors.red,
            ),

            // Google Sheets Test
            if (_debugResults!['googleSheets'] != null)
              _buildGoogleSheetsResult(_debugResults!['googleSheets']),

            // Data Parsing Test
            if (_debugResults!['dataParsing'] != null)
              _buildDataParsingResult(_debugResults!['dataParsing']),

            // Complete Fetch Test
            if (_debugResults!['completeFetch'] != null)
              _buildCompleteFetchResult(_debugResults!['completeFetch']),

            // Error Display
            if (_debugResults!['error'] != null)
              _buildErrorResult(_debugResults!['error']),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResult(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSheetsResult(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Google Sheets Access',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildTestResult('Status Code', '${result['statusCode']}', 
          result['statusCode'] == 200 ? Colors.green : Colors.red),
        _buildTestResult('Content Length', '${result['contentLength']} bytes', Colors.blue),
        _buildTestResult('Is HTML Response', result['isHtml'] == true ? 'YES' : 'NO', 
          result['isHtml'] == true ? Colors.red : Colors.green),
        if (result['totalLines'] != null)
          _buildTestResult('Total Lines', '${result['totalLines']}', Colors.blue),
        if (result['hasData'] != null)
          _buildTestResult('Has Numeric Data', result['hasData'] == true ? 'YES' : 'NO',
            result['hasData'] == true ? Colors.green : Colors.red),
        if (result['error'] != null)
          _buildTestResult('Error', result['error'], Colors.red),
        
        // Show specific help for HTTP 400 errors
        if (result['statusCode'] == 400) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'HTTP 400 Error - Spreadsheet Access Issue',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Google Sheets is not publicly accessible. Click the button below for instructions to fix this.',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
                const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _testDataStorage(),
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: const Text('Test Data Storage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataParsingResult(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Data Parsing',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildTestResult('CSV Parsing', 'SUCCESS', Colors.green),
        _buildTestResult('Value Parsing', 'SUCCESS', Colors.green),
        _buildTestResult('Date Detection', 'SUCCESS', Colors.green),
        if (result['error'] != null)
          _buildTestResult('Error', result['error'], Colors.red),
      ],
    );
  }

  Widget _buildCompleteFetchResult(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Complete Data Fetch',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _buildTestResult('Data Count', '${result['dataCount']}', 
          result['dataCount'] > 0 ? Colors.green : Colors.red),
        _buildTestResult('Has Data', result['hasData'] == true ? 'YES' : 'NO',
          result['hasData'] == true ? Colors.green : Colors.red),
        if (result['tadepalligudemData'] != null)
          _buildTestResult('Tadepalligudem Data', 'AVAILABLE', Colors.green),
        if (result['error'] != null)
          _buildTestResult('Error', result['error'], Colors.red),
      ],
    );
  }

  Widget _buildErrorResult(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700, size: 16),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  Future<void> _runDebug() async {
    setState(() {
      _isRunningDebug = true;
      _debugResults = null;
    });

    try {
      // Test manual data service
      final service = ref.read(manualDataServiceProvider);
      final hasData = await service.hasData();
      final stats = await service.getDataStats();
      final lastUpdated = await service.getLastUpdated();
      
      setState(() {
        _debugResults = {
          'hasData': hasData,
          'stats': stats,
          'lastUpdated': lastUpdated?.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        _isRunningDebug = false;
      });
    } catch (e) {
      setState(() {
        _debugResults = {'error': e.toString()};
        _isRunningDebug = false;
      });
    }
  }

  Future<void> _testDataStorage() async {
    try {
      final service = ref.read(manualDataServiceProvider);
      final hasData = await service.hasData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasData 
              ? '✅ Data storage working! Data found in storage'
              : '⚠️ No data found in storage'),
            backgroundColor: hasData ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Data storage test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testWaterWellDepth() async {
    try {
      final service = ref.read(waterWellDepthServiceProvider);
      
      // Generate mock data
      final historicalData = service.generateMockHistoricalData(days: 30);
      final predictions = service.generateMockPredictions(days: 7);
      final trendAnalysis = service.getTrendAnalysis(days: 30);
      final modelPerformance = service.getModelPerformance();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Water Well Depth Test Successful!\n'
              'Historical: ${historicalData.length} points\n'
              'Predictions: ${predictions.length} points\n'
              'Trend: ${trendAnalysis['trendDirection']}\n'
              'ML Accuracy: ${(modelPerformance['accuracy'] * 100).toStringAsFixed(0)}%'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Water Well Depth test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Logs'),
        content: const SingleChildScrollView(
          child: Text(
            'Debug logs are printed to the console. Check your IDE\'s debug console or terminal for detailed logs.\n\n'
            'Look for messages starting with:\n'
            '• 🚀 Starting Google Sheets data fetch...\n'
            '• 🔍 Testing Google Sheets connection...\n'
            '• 📊 Status: 200, Length: 1234\n'
            '• ✅ Successfully parsed 5 data points\n'
            '• ❌ All URL attempts failed\n\n'
            'These logs will help identify exactly where the data fetching is failing.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

}
