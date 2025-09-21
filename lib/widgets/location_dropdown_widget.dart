import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groundwater_data_provider.dart' as groundwater;

/// Widget that demonstrates location dropdown with real API data integration
class LocationDropdownWidget extends ConsumerWidget {
  const LocationDropdownWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocation = ref.watch(groundwater.selectedLocationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Dropdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Location',
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
                    'Groundwater Data for $selectedLocation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Data display
                  Text(
                    'Selected: $selectedLocation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Station Code: ${_getStationCode(selectedLocation)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  // Display groundwater data
                  ref.watch(groundwater.groundwaterDataProvider(selectedLocation)).when(
                    data: (data) => data != null ? _buildDataDisplay(context, data) : const Text('No data available'),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No location selected',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataDisplay(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Station Information
        _buildInfoRow('Station Code', data['stationCode'] ?? 'N/A'),
        _buildInfoRow('Location', data['locationName'] ?? 'N/A'),
        _buildInfoRow('Data Source', data['dataSource'] ?? 'N/A'),
        
        const Divider(),
        
        // Depth Information
        _buildInfoRow('Average Depth', '${data['averageDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
        _buildInfoRow('Max Depth', '${data['maxDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
        _buildInfoRow('Min Depth', '${data['minDepth']?.toStringAsFixed(2) ?? 'N/A'} m'),
        _buildInfoRow('Depth Range', '${data['depthRange']?.toStringAsFixed(2) ?? 'N/A'} m'),
        
        const Divider(),
        
        // Status Information
        _buildInfoRow('Current Status', data['currentStatus'] ?? 'N/A'),
        _buildInfoRow('Trend Direction', data['trendDirection'] ?? 'N/A'),
        _buildInfoRow('Risk Level', data['riskLevel'] ?? 'N/A'),
        
        const Divider(),
        
        // Yearly Change Information
        if (data['yearlyChange'] != null) ...[
          Text(
            'Yearly Change',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...(data['yearlyChange'] as Map<String, dynamic>).entries.map(
            (entry) => _buildInfoRow('${entry.key}', '${entry.value?.toStringAsFixed(2) ?? 'N/A'} m'),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Action Buttons
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showMonthlyTrend(context, data),
              icon: const Icon(Icons.trending_up),
              label: const Text('Monthly Trend'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showDailyData(context, data),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Daily Data'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _exportData(context, data),
              icon: const Icon(Icons.download),
              label: const Text('Export'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  void _showMonthlyTrend(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Monthly Trend - ${data['locationName']}'),
        content: const Text('Monthly trend chart would be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDailyData(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Daily Data - ${data['locationName']}'),
        content: const Text('Daily data chart would be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Text('Exporting data for ${data['locationName']}...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getStationCode(String location) {
    const stationCodes = {
      'Addanki': 'CGWHYD0500',
      'Akkireddipalem': 'CGWHYD0511',
      'Anantapur': 'CGWHYD0401',
      'Bapulapadu': 'CGWHYD0485',
      'Chittoor': 'CGWHYD2038',
      'Gudur': 'CGWHYD2062',
      'Kakinada': 'CGWHYD0447',
      'Sultan nagaram': 'CGWHYD2060',
      'Tadepalligudem': 'CGWHYD0514',
      'Tenali': 'CGWHYD2053',
    };
    return stationCodes[location] ?? 'Unknown';
  }
}

/// Widget for displaying location statistics
class LocationStatisticsWidget extends ConsumerWidget {
  final String location;
  
  const LocationStatisticsWidget({
    super.key,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for demonstration
    final statistics = {
      'averageDepth': -5.0,
      'maxDepth': -12.0,
      'minDepth': -4.0,
      'currentStatus': 'Normal',
      'trendDirection': 'Stable',
      'riskLevel': 'Low',
    };
    final alerts = <Map<String, dynamic>>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics for $location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            if (statistics['error'] != null) ...[
              Text(
                'Error: ${statistics['error']}',
                style: const TextStyle(color: Colors.red),
              ),
            ] else ...[
              // Display statistics
              _buildInfoRow('Average Depth', '${(statistics['averageDepth'] as double?)?.toStringAsFixed(2) ?? 'N/A'} m'),
              _buildInfoRow('Max Depth', '${(statistics['maxDepth'] as double?)?.toStringAsFixed(2) ?? 'N/A'} m'),
              _buildInfoRow('Min Depth', '${(statistics['minDepth'] as double?)?.toStringAsFixed(2) ?? 'N/A'} m'),
              _buildInfoRow('Current Status', (statistics['currentStatus'] as String?) ?? 'N/A'),
              _buildInfoRow('Trend Direction', (statistics['trendDirection'] as String?) ?? 'N/A'),
              _buildInfoRow('Risk Level', (statistics['riskLevel'] as String?) ?? 'N/A'),
              
              // Display alerts
              if (alerts.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Alerts',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...alerts.map((alert) => Card(
                  color: alert['severity'] == 'high' ? Colors.red.shade50 : Colors.orange.shade50,
                  child: ListTile(
                    leading: Icon(
                      alert['severity'] == 'high' ? Icons.warning : Icons.info,
                      color: alert['severity'] == 'high' ? Colors.red : Colors.orange,
                    ),
                    title: Text(alert['message']),
                    subtitle: Text(alert['timestamp']),
                  ),
                )),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

/// Widget for searching locations
class LocationSearchWidget extends ConsumerWidget {
  const LocationSearchWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = TextEditingController();
    final availableLocations = ref.watch(groundwater.availableLocationsProvider);
    final filteredLocations = <String>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Locations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search for a location...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                // Simple search functionality
                filteredLocations.clear();
                if (query.isNotEmpty) {
                  filteredLocations.addAll(
                    availableLocations.where((location) => 
                      location.toLowerCase().contains(query.toLowerCase())
                    ).toList()
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            if (filteredLocations.isNotEmpty) ...[
              Text(
                'Search Results',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...filteredLocations.map((location) => ListTile(
                title: Text(location),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ref.read(groundwater.selectedLocationProvider.notifier).state = location;
                  searchController.clear();
                },
              )),
            ],
          ],
        ),
      ),
    );
  }
}
