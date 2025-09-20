import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groundwater_data_provider.dart';
import '../widgets/location_dropdown_widget.dart';

/// Example screen demonstrating the location dropdown with real API data
class GroundwaterDataScreen extends ConsumerWidget {
  const GroundwaterDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocation = ref.watch(selectedLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groundwater Data'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Dropdown Widget
            const LocationDropdownWidget(),
            
            const SizedBox(height: 24),
            
            // Location Statistics (if location is selected)
            if (selectedLocation != null) ...[
              LocationStatisticsWidget(location: selectedLocation),
              const SizedBox(height: 24),
            ],
            
            // Search Widget
            const LocationSearchWidget(),
            
            const SizedBox(height: 24),
            
            // API Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Integration Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Connected to Groundwater API'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text('${ref.watch(availableLocationsProvider).length} locations available'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.data_usage,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Real-time data synchronization'),
                      ],
                    ),
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

/// Simple test screen to verify the integration works
class TestGroundwaterScreen extends ConsumerWidget {
  const TestGroundwaterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableLocations = ref.watch(availableLocationsProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Groundwater Integration'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Locations:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Simple dropdown for testing
            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select Location',
              ),
              items: availableLocations.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  ref.read(selectedLocationProvider.notifier).state = newValue;
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // Show selected location data
            if (selectedLocation != null) ...[
              Text(
                'Selected: $selectedLocation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              
              // Test data fetching
              FutureBuilder<Map<String, dynamic>?>(
                future: ref.read(groundwaterDataProvider(selectedLocation).future),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'API Data for $selectedLocation',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            _buildDataRow('Station Code', data['stationCode'] ?? 'N/A'),
                            _buildDataRow('Average Depth', '${data['averageDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
                            _buildDataRow('Max Depth', '${data['maxDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
                            _buildDataRow('Min Depth', '${data['minDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
                            _buildDataRow('Current Status', data['currentStatus'] ?? 'N/A'),
                            _buildDataRow('Trend Direction', data['trendDirection'] ?? 'N/A'),
                            _buildDataRow('Risk Level', data['riskLevel'] ?? 'N/A'),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No data available'),
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Test button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Test API connection
                  ref.invalidate(allLocationsDataProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}
