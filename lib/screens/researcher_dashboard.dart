import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dwlr_provider.dart';
import '../models/dwlr_station.dart';
import '../widgets/researcher_card.dart';
import '../widgets/data_access_card.dart';

/// Researcher Dashboard - Advanced analytics and data access
class ResearcherDashboard extends ConsumerStatefulWidget {
  const ResearcherDashboard({super.key});

  @override
  ConsumerState<ResearcherDashboard> createState() => _ResearcherDashboardState();
}

class _ResearcherDashboardState extends ConsumerState<ResearcherDashboard> {
  String _selectedRegion = 'All';
  String _selectedTimeRange = 'Last 30 Days';

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
        title: const Text('Researcher Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => context.go('/reports'),
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalyticsDialog(),
            tooltip: 'Advanced Analytics',
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
                        // Quick stats
                        _buildQuickStats(stations),
                        const SizedBox(height: 20),
                        
                        // Data access tools
                        _buildDataAccessTools(stations),
                        const SizedBox(height: 20),
                        
                        // Visualization tools
                        _buildVisualizationTools(),
                        const SizedBox(height: 20),
                        
                        // Analysis tools
                        _buildAnalysisTools(),
                        const SizedBox(height: 20),
                        
                        // Recent exports
                        _buildRecentExports(),
                        const SizedBox(height: 20), // Extra padding at bottom
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Build quick stats
  Widget _buildQuickStats(List<DWLRStation> stations) {
    final totalStations = stations.length;
    final activeStations = stations.where((s) => s.status == 'Active').length;
    final avgDataQuality = stations.isNotEmpty
        ? stations.map((s) => s.dataAvailability).reduce((a, b) => a + b) / stations.length
        : 0.0;
    final uniqueStates = stations.map((s) => s.state).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Research Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ResearcherCard(
                title: 'Total Stations',
                value: totalStations.toString(),
                subtitle: 'DWLR Stations Available',
                icon: Icons.water_drop,
                color: Colors.blue,
                onTap: () => context.go('/stations'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResearcherCard(
                title: 'Active Stations',
                value: activeStations.toString(),
                subtitle: 'Currently Monitoring',
                icon: Icons.check_circle,
                color: Colors.green,
                onTap: () => _filterActiveStations(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ResearcherCard(
                title: 'Data Quality',
                value: '${avgDataQuality.toStringAsFixed(1)}%',
                subtitle: 'Average Availability',
                icon: Icons.analytics,
                color: Colors.purple,
                onTap: () => _showDataQualityReport(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResearcherCard(
                title: 'States Covered',
                value: uniqueStates.toString(),
                subtitle: 'Geographic Coverage',
                icon: Icons.map,
                color: Colors.orange,
                onTap: () => context.go('/map'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build data access tools
  Widget _buildDataAccessTools(List<DWLRStation> stations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Access Tools',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        DataAccessCard(
          title: 'Download Raw DWLR Data',
          subtitle: 'Access real-time station datasets',
          icon: Icons.download,
          color: Colors.blue,
          features: const [
            'Real-time data streams',
            'Historical datasets',
            'Multiple export formats',
            'API access available',
          ],
          onTap: () => _showDownloadDialog(stations),
        ),
        const SizedBox(height: 12),
        DataAccessCard(
          title: 'Filter & Search',
          subtitle: 'Find specific stations and data',
          icon: Icons.search,
          color: Colors.green,
          features: const [
            'Filter by state/district',
            'Search by aquifer type',
            'Date range selection',
            'Quality filters',
          ],
          onTap: () => context.go('/stations'),
        ),
        const SizedBox(height: 12),
        DataAccessCard(
          title: 'Bulk Export',
          subtitle: 'Export large datasets efficiently',
          icon: Icons.file_download,
          color: Colors.orange,
          features: const [
            'CSV, Excel, JSON formats',
            'Custom data selection',
            'Batch processing',
            'Scheduled exports',
          ],
          onTap: () => _showBulkExportDialog(),
        ),
      ],
    );
  }

  /// Build visualization tools
  Widget _buildVisualizationTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visualization & Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ResearcherCard(
                title: 'Time Series Charts',
                value: 'Charts',
                subtitle: 'Compare trends over time',
                icon: Icons.timeline,
                color: Colors.blue,
                onTap: () => _showTimeSeriesAnalysis(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResearcherCard(
                title: 'Heatmaps',
                value: 'Maps',
                subtitle: 'Visualize spatial patterns',
                icon: Icons.grid_on,
                color: Colors.red,
                onTap: () => _showHeatmapAnalysis(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ResearcherCard(
                title: 'Comparative Analysis',
                value: 'Compare',
                subtitle: 'Compare multiple stations',
                icon: Icons.compare,
                color: Colors.purple,
                onTap: () => _showComparativeAnalysis(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ResearcherCard(
                title: 'Seasonal Patterns',
                value: 'Seasons',
                subtitle: 'Analyze seasonal variations',
                icon: Icons.calendar_month,
                color: Colors.green,
                onTap: () => _showSeasonalAnalysis(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build analysis tools
  Widget _buildAnalysisTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.purple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI/ML Forecasting',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Predict groundwater availability using machine learning models',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showForecastingDialog(),
                      child: const Text('Run Model'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalysisOption(
                        'Recharge Analysis',
                        'Calculate recharge potential',
                        Icons.water,
                        Colors.blue,
                        () => _showRechargeAnalysis(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalysisOption(
                        'What-if Scenarios',
                        'Simulate different conditions',
                        Icons.science,
                        Colors.orange,
                        () => _showScenarioAnalysis(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build recent exports
  Widget _buildRecentExports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Exports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/reports'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._getRecentExports().map((export) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getExportColor(export['format']),
              child: Text(
                export['format'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            title: Text(export['title']),
            subtitle: Text('${export['stations']} stations • ${export['date']}'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadExport(export['id']),
            ),
          ),
        )).toList(),
      ],
    );
  }

  /// Build analysis option
  Widget _buildAnalysisOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

  /// Get recent exports (mock data)
  List<Map<String, dynamic>> _getRecentExports() {
    return [
      {
        'id': 'export_1',
        'title': 'Delhi Stations Data',
        'stations': '15',
        'format': 'CSV',
        'date': '2 hours ago',
      },
      {
        'id': 'export_2',
        'title': 'Monthly Summary',
        'stations': '45',
        'format': 'Excel',
        'date': '1 day ago',
      },
      {
        'id': 'export_3',
        'title': 'Quality Analysis',
        'stations': '23',
        'format': 'JSON',
        'date': '3 days ago',
      },
    ];
  }

  /// Get export color
  Color _getExportColor(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return Colors.green;
      case 'excel':
        return Colors.blue;
      case 'json':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Filter active stations
  void _filterActiveStations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtering active stations...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show data quality report
  void _showDataQualityReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Quality Report'),
        content: const Text('Data quality analysis will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show download dialog
  void _showDownloadDialog(List<DWLRStation> stations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download DWLR Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select data to download:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: const InputDecoration(labelText: 'Region'),
              items: ['All', 'Delhi', 'Haryana', 'Punjab'].map((region) {
                return DropdownMenuItem(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRegion = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTimeRange,
              decoration: const InputDecoration(labelText: 'Time Range'),
              items: ['Last 30 Days', 'Last 3 Months', 'Last Year', 'All Data'].map((range) {
                return DropdownMenuItem(
                  value: range,
                  child: Text(range),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTimeRange = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download started...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  /// Show bulk export dialog
  void _showBulkExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Export'),
        content: const Text('Bulk export options will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show analytics dialog
  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Analytics'),
        content: const Text('Advanced analytics tools will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show time series analysis
  void _showTimeSeriesAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening time series analysis...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Show heatmap analysis
  void _showHeatmapAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening heatmap analysis...'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show comparative analysis
  void _showComparativeAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening comparative analysis...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  /// Show seasonal analysis
  void _showSeasonalAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening seasonal analysis...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show forecasting dialog
  void _showForecastingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI/ML Forecasting'),
        content: const Text('Machine learning forecasting models will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show recharge analysis
  void _showRechargeAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening recharge analysis...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Show scenario analysis
  void _showScenarioAnalysis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening scenario analysis...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Download export
  void _downloadExport(String exportId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading export $exportId...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
