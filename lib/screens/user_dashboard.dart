import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dwlr_provider.dart';
import '../providers/user_provider.dart';
import '../models/dwlr_station.dart';
import '../widgets/water_status_card.dart';
import '../widgets/quick_action_card.dart';

/// User Dashboard - Quick insights with traffic light system
class UserDashboard extends ConsumerStatefulWidget {
  const UserDashboard({super.key});

  @override
  ConsumerState<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends ConsumerState<UserDashboard> {
  @override
  void initState() {
    super.initState();
    // Load stations when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dwlrStationsProvider.notifier).loadStations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationsState = ref.watch(dwlrStationsProvider);
    final stations = stationsState.stations;
    final isLoading = stationsState.isLoading;
    final error = stationsState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Water Status'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/location-search'),
            tooltip: 'Search by Location',
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _showLocationDialog,
            tooltip: 'Set Location',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.go('/alerts'),
            tooltip: 'View Alerts',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState(error)
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(dwlrStationsProvider.notifier).refreshStations();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location status
                        _buildLocationStatus(),
                        const SizedBox(height: 20),
                        
                        // Water status overview
                        _buildWaterStatusOverview(stations),
                        const SizedBox(height: 20),
                        
                        // Quick actions
                        _buildQuickActions(),
                        const SizedBox(height: 20),
                        
                        // Location Search Section
                        _buildLocationSearchSection(),
                        const SizedBox(height: 20),
                        
                        // Nearby stations
                        _buildNearbyStations(stations),
                        const SizedBox(height: 20),
                        
                        // Tips and recommendations
                        _buildTipsAndRecommendations(),
                        const SizedBox(height: 20), // Extra padding at bottom
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Build location status
  Widget _buildLocationStatus() {
    final userLocation = ref.watch(userLocationProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: userLocation != null ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userLocation ?? 'Location not set',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userLocation != null 
                        ? 'Monitoring your area' 
                        : 'Tap to set your location for personalized insights',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _showLocationDialog,
              child: Text(userLocation != null ? 'Change' : 'Set'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build water status overview
  Widget _buildWaterStatusOverview(List<DWLRStation> stations) {
    final nearbyStations = _getNearbyStations(stations);
    final overallStatus = _calculateOverallStatus(nearbyStations);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Water Status Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        WaterStatusCard(
          status: overallStatus,
          title: 'Overall Status',
          subtitle: _getStatusDescription(overallStatus),
          stations: nearbyStations,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: WaterStatusCard(
                status: WaterStatus.safe,
                title: 'Safe Areas',
                subtitle: '${nearbyStations.where((s) => _getStationStatus(s) == WaterStatus.safe).length} stations',
                stations: nearbyStations.where((s) => _getStationStatus(s) == WaterStatus.safe).toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WaterStatusCard(
                status: WaterStatus.moderate,
                title: 'Moderate Areas',
                subtitle: '${nearbyStations.where((s) => _getStationStatus(s) == WaterStatus.moderate).length} stations',
                stations: nearbyStations.where((s) => _getStationStatus(s) == WaterStatus.moderate).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WaterStatusCard(
          status: WaterStatus.critical,
          title: 'Critical Areas',
          subtitle: '${nearbyStations.where((s) => _getStationStatus(s) == WaterStatus.critical).length} stations',
          stations: nearbyStations.where((s) => _getStationStatus(s) == WaterStatus.critical).toList(),
        ),
      ],
    );
  }

  /// Build quick actions
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'Check Water Quality',
                subtitle: 'Latest quality reports',
                icon: Icons.science,
                color: Colors.blue,
                onTap: () => _showWaterQualityDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                title: 'Plan Storage',
                subtitle: 'Water storage calculator',
                icon: Icons.water_drop,
                color: Colors.green,
                onTap: () => _showStorageCalculator(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                title: 'Borewell Info',
                subtitle: 'Drilling recommendations',
                icon: Icons.build,
                color: Colors.orange,
                onTap: () => _showBorewellInfo(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                title: 'Conservation Tips',
                subtitle: 'Save water daily',
                icon: Icons.eco,
                color: Colors.teal,
                onTap: () => _showConservationTips(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build nearby stations
  Widget _buildNearbyStations(List<DWLRStation> stations) {
    final nearbyStations = _getNearbyStations(stations);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nearby Stations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/stations'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...nearbyStations.take(3).map((station) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(_getStationStatus(station)),
              child: Text(
                station.stationId.substring(station.stationId.length - 2),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(station.stationName),
            subtitle: Text('${station.district}, ${station.state}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${station.currentWaterLevel.toStringAsFixed(1)}m',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _getStationStatus(station).name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(_getStationStatus(station)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onTap: () => context.go('/station/${station.stationId}'),
          ),
        )).toList(),
      ],
    );
  }

  /// Build tips and recommendations
  Widget _buildTipsAndRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tips & Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              Icons.water_drop,
              'Water Storage',
              'Store 2-3 days worth of water for emergencies',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.eco,
              'Conservation',
              'Fix leaks immediately - they waste 20% of water',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.warning,
              'Quality Check',
              'Test water quality every 6 months',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  /// Build tip item
  Widget _buildTipItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(dwlrStationsProvider.notifier).loadStations();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Get nearby stations (mock implementation)
  List<DWLRStation> _getNearbyStations(List<DWLRStation> stations) {
    // In a real app, this would filter by user's location
    return stations.take(5).toList();
  }

  /// Calculate overall status
  WaterStatus _calculateOverallStatus(List<DWLRStation> stations) {
    if (stations.isEmpty) return WaterStatus.safe;
    
    final statuses = stations.map(_getStationStatus).toList();
    final criticalCount = statuses.where((s) => s == WaterStatus.critical).length;
    final moderateCount = statuses.where((s) => s == WaterStatus.moderate).length;
    
    if (criticalCount > stations.length * 0.3) return WaterStatus.critical;
    if (moderateCount > stations.length * 0.5) return WaterStatus.moderate;
    return WaterStatus.safe;
  }

  /// Get station status based on water level
  WaterStatus _getStationStatus(DWLRStation station) {
    if (station.currentWaterLevel < 10) return WaterStatus.critical;
    if (station.currentWaterLevel < 20) return WaterStatus.moderate;
    return WaterStatus.safe;
  }

  /// Get status description
  String _getStatusDescription(WaterStatus status) {
    switch (status) {
      case WaterStatus.safe:
        return 'Water levels are healthy in your area';
      case WaterStatus.moderate:
        return 'Water levels are moderate - monitor closely';
      case WaterStatus.critical:
        return 'Water levels are critical - take action';
    }
  }

  /// Get status color
  Color _getStatusColor(WaterStatus status) {
    switch (status) {
      case WaterStatus.safe:
        return Colors.green;
      case WaterStatus.moderate:
        return Colors.orange;
      case WaterStatus.critical:
        return Colors.red;
    }
  }

  /// Show location dialog
  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Your Location'),
        content: const Text('Location setting will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userProvider.notifier).setLocation('Delhi, India');
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  /// Show water quality dialog
  void _showWaterQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Water Quality Report'),
        content: const Text('Water quality information will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show storage calculator
  void _showStorageCalculator() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Water Storage Calculator'),
        content: const Text('Storage calculator will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show borewell info
  void _showBorewellInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borewell Information'),
        content: const Text('Borewell drilling recommendations will be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show conservation tips
  void _showConservationTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Water Conservation Tips'),
        content: const Text('Conservation tips and best practices will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build location search section
  Widget _buildLocationSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Search by Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Find groundwater monitoring stations in any state, district, or city across India.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/location-search'),
                icon: const Icon(Icons.location_searching),
                label: const Text('Search Stations'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
