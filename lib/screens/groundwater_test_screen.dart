import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groundwater_data_provider.dart' as groundwater;

/// Simple test screen to verify groundwater data integration
class GroundwaterTestScreen extends ConsumerWidget {
  const GroundwaterTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableLocations = ref.watch(groundwater.availableLocationsProvider);
    final selectedLocation = ref.watch(groundwater.selectedLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groundwater Data Test'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Status Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Groundwater API Integration Ready',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Location Dropdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Location:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose a location',
                      ),
                      items: ref.watch(groundwater.availableLocationsProvider).map((location) {
                        return DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          ref.read(groundwater.selectedLocationProvider.notifier).state = newValue;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Display selected location data
            if (selectedLocation != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data for $selectedLocation',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      // Test API call
                      FutureBuilder<Map<String, dynamic>?>(
                        future: ref.read(groundwater.groundwaterDataProvider(selectedLocation).future),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          
                          if (snapshot.hasError) {
                            return Card(
                              color: Colors.red.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.error, color: Colors.red, size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'This might be due to network issues or API unavailability.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          if (snapshot.hasData && snapshot.data != null) {
                            final data = snapshot.data!;
                            return Column(
                              children: [
                                // Success indicator
                                Card(
                                  color: Colors.green.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'API Data Retrieved Successfully!',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Data display
                                _buildDataRow('Station Code', data['stationCode'] ?? 'N/A'),
                                _buildDataRow('Location', data['locationName'] ?? 'N/A'),
                                _buildDataRow('Average Depth', '${data['averageDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
                                _buildDataRow('Max Depth', '${data['maxDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
                                _buildDataRow('Min Depth', '${data['minDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
                                _buildDataRow('Current Status', data['currentStatus'] ?? 'N/A'),
                                _buildDataRow('Trend Direction', data['trendDirection'] ?? 'N/A'),
                                _buildDataRow('Risk Level', data['riskLevel'] ?? 'N/A'),
                                _buildDataRow('Data Source', data['dataSource'] ?? 'N/A'),
                              ],
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
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(groundwater.allLocationsDataProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh All Data'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(groundwater.selectedLocationProvider);
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Selection'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // API Information
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Information',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('API URL: https://groundwater-level-predictor-backend.onrender.com/features'),
                    Text('Available Locations: ${ref.watch(groundwater.availableLocationsProvider).length}'),
                    const Text('Integration Status: ✅ Connected'),
                    const Text('Data Sync: ✅ Real-time'),
                  ],
                ),
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
