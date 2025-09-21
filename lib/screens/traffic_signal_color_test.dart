import 'package:flutter/material.dart';
import '../models/traffic_signal.dart';
import '../services/api_service.dart';

/// Test widget to demonstrate traffic signal color logic based on API data
class TrafficSignalColorTest extends StatelessWidget {
  const TrafficSignalColorTest({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    
    // Test data with different average depths
    final testData = [
      {'name': 'Good Region', 'avg_depth': -3.5, 'yearly_change': 0.2},
      {'name': 'Warning Region', 'avg_depth': -8.2, 'yearly_change': -0.5},
      {'name': 'Critical Region', 'avg_depth': -18.7, 'yearly_change': -1.2},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Signal Color Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Traffic Signal Colors Based on Average Depth from API',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Color Logic:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildColorRule('🟢 GOOD', '0 to -5 meters', 'Healthy and sustainable', const Color(0xFF33B864)),
            _buildColorRule('🟠 CAUTION', '-6 to -16 meters', 'Declining, monitor closely', Colors.orange),
            _buildColorRule('🔴 CRITICAL', 'Beyond -16 meters', 'Immediate action needed', Colors.red),
            const SizedBox(height: 24),
            Text(
              'Test Results:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...testData.map((data) => _buildTestResult(context, apiService, data)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRule(String emoji, String range, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  range,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResult(BuildContext context, ApiService apiService, Map<String, dynamic> data) {
    final avgDepth = data['avg_depth'] as double;
    final trafficSignal = apiService.generateTrafficSignalFromData(data, data['name']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: trafficSignal.level.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  trafficSignal.level.status.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Average Depth: ${avgDepth.toStringAsFixed(1)} m',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Status: ${trafficSignal.level.status}',
                    style: TextStyle(
                      color: trafficSignal.level.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
