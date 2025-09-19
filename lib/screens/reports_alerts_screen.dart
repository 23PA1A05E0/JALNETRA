import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dwlr_provider.dart';
import '../models/dwlr_station.dart';

/// Reports and Alerts screen
class ReportsAlertsScreen extends ConsumerStatefulWidget {
  const ReportsAlertsScreen({super.key});

  @override
  ConsumerState<ReportsAlertsScreen> createState() => _ReportsAlertsScreenState();
}

class _ReportsAlertsScreenState extends ConsumerState<ReportsAlertsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load stations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dwlrStationsProvider.notifier).loadStations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationsState = ref.watch(dwlrStationsProvider);
    final stations = stationsState.stations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Alerts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: GoRouter.of(context).canPop()
          ? IconButton(
              icon: Icon(
                Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.arrow_back_ios
                  : Icons.arrow_back,
              ),
              onPressed: () {
                context.pop();
              },
              tooltip: 'Back',
            )
          : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dwlrStationsProvider.notifier).refreshStations();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
            Tab(icon: Icon(Icons.download), text: 'Export'),
            Tab(icon: Icon(Icons.analytics), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsTab(stations),
          _buildExportTab(stations),
          _buildReportsTab(stations),
        ],
      ),
    );
  }

  /// Build alerts tab
  Widget _buildAlertsTab(List<DWLRStation> stations) {
    final alerts = _generateMockAlerts(stations);

    return Column(
      children: [
        // Alert summary
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildAlertSummaryCard('Critical', alerts.where((a) => a['severity'] == 'Critical').length, Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAlertSummaryCard('High', alerts.where((a) => a['severity'] == 'High').length, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAlertSummaryCard('Medium', alerts.where((a) => a['severity'] == 'Medium').length, Colors.yellow),
              ),
            ],
          ),
        ),
        
        // Alerts list
        Expanded(
          child: alerts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('No alerts'),
                      Text('All stations are operating normally'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getSeverityColor(alert['severity']),
                          child: Icon(
                            _getAlertIcon(alert['type']),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(alert['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert['message']),
                            const SizedBox(height: 4),
                            Text(
                              '${alert['station']} • ${alert['time']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View Station'),
                            ),
                            const PopupMenuItem(
                              value: 'dismiss',
                              child: Text('Dismiss'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'view') {
                              context.go('/station/${alert['stationId']}');
                            } else if (value == 'dismiss') {
                              _dismissAlert(alert['id']);
                            }
                          },
                        ),
                        onTap: () => context.go('/station/${alert['stationId']}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Build export tab
  Widget _buildExportTab(List<DWLRStation> stations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Export options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildExportOption(
                    'All Stations Data',
                    'Export complete dataset for all stations',
                    Icons.download,
                    () => _exportAllStations(stations),
                  ),
                  const SizedBox(height: 12),
                  _buildExportOption(
                    'Active Stations Only',
                    'Export data for active stations only',
                    Icons.check_circle,
                    () => _exportActiveStations(stations),
                  ),
                  const SizedBox(height: 12),
                  _buildExportOption(
                    'Custom Selection',
                    'Select specific stations to export',
                    Icons.checklist,
                    () => _showCustomExportDialog(stations),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Export formats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Formats',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormatCard('CSV', 'Comma-separated values', Icons.table_chart, Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormatCard('Excel', 'Microsoft Excel format', Icons.description, Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormatCard('JSON', 'JavaScript Object Notation', Icons.code, Colors.orange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormatCard('PDF', 'Portable Document Format', Icons.picture_as_pdf, Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build reports tab
  Widget _buildReportsTab(List<DWLRStation> stations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generated Reports',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Reports',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildReportCard(
                    'Monthly Summary',
                    'Water level trends and statistics for the current month',
                    Icons.calendar_month,
                    Colors.blue,
                    () => _generateMonthlyReport(stations),
                  ),
                  const SizedBox(height: 12),
                  _buildReportCard(
                    'Station Health',
                    'Overall health status and data quality assessment',
                    Icons.health_and_safety,
                    Colors.green,
                    () => _generateHealthReport(stations),
                  ),
                  const SizedBox(height: 12),
                  _buildReportCard(
                    'Alert Summary',
                    'Summary of all alerts and notifications',
                    Icons.warning,
                    Colors.orange,
                    () => _generateAlertReport(stations),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Recent reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Reports',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._getRecentReports().map((report) => ListTile(
                    leading: Icon(report['icon'], color: report['color']),
                    title: Text(report['title']),
                    subtitle: Text(report['subtitle']),
                    trailing: Text(report['date']),
                    onTap: () => _viewReport(report['id']),
                  )).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build alert summary card
  Widget _buildAlertSummaryCard(String severity, int count, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              severity,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build export option
  Widget _buildExportOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  /// Build format card
  Widget _buildFormatCard(String title, String subtitle, IconData icon, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build report card
  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  /// Generate mock alerts
  List<Map<String, dynamic>> _generateMockAlerts(List<DWLRStation> stations) {
    final alerts = <Map<String, dynamic>>[];
    
    for (int i = 0; i < stations.length && i < 5; i++) {
      final station = stations[i];
      final alertTypes = ['Water Level Decline', 'Data Gap', 'Maintenance Required', 'Quality Issue'];
      final severities = ['Critical', 'High', 'Medium'];
      
      alerts.add({
        'id': 'alert_${i + 1}',
        'stationId': station.stationId,
        'station': station.stationName,
        'type': alertTypes[i % alertTypes.length],
        'severity': severities[i % severities.length],
        'title': '${alertTypes[i % alertTypes.length]} - ${station.stationName}',
        'message': 'Water level has declined by 15% in the last 7 days',
        'time': '2 hours ago',
      });
    }
    
    return alerts;
  }

  /// Get recent reports
  List<Map<String, dynamic>> _getRecentReports() {
    return [
      {
        'id': 'report_1',
        'title': 'Monthly Summary - December 2024',
        'subtitle': 'Water level trends and statistics',
        'date': '2 days ago',
        'icon': Icons.calendar_month,
        'color': Colors.blue,
      },
      {
        'id': 'report_2',
        'title': 'Station Health Report',
        'subtitle': 'Overall health assessment',
        'date': '1 week ago',
        'icon': Icons.health_and_safety,
        'color': Colors.green,
      },
      {
        'id': 'report_3',
        'title': 'Alert Summary - November 2024',
        'subtitle': 'All alerts and notifications',
        'date': '2 weeks ago',
        'icon': Icons.warning,
        'color': Colors.orange,
      },
    ];
  }

  /// Export all stations
  void _exportAllStations(List<DWLRStation> stations) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data for ${stations.length} stations...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Export active stations
  void _exportActiveStations(List<DWLRStation> stations) {
    final activeStations = stations.where((s) => s.status == 'Active').toList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data for ${activeStations.length} active stations...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show custom export dialog
  void _showCustomExportDialog(List<DWLRStation> stations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Export'),
        content: const Text('Custom station selection will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Generate monthly report
  void _generateMonthlyReport(List<DWLRStation> stations) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating monthly report...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Generate health report
  void _generateHealthReport(List<DWLRStation> stations) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating health report...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Generate alert report
  void _generateAlertReport(List<DWLRStation> stations) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating alert report...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// View report
  void _viewReport(String reportId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening report $reportId...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Dismiss alert
  void _dismissAlert(String alertId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert $alertId dismissed'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Show settings dialog
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Settings'),
        content: const Text('Report and alert settings will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get severity color
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  /// Get alert icon
  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'water level decline':
        return Icons.trending_down;
      case 'data gap':
        return Icons.error_outline;
      case 'maintenance required':
        return Icons.build;
      case 'quality issue':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }
}
