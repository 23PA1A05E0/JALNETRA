import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/groundwater_notification_service.dart';

/// Notification Settings Screen for managing groundwater alerts
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final notificationService = ref.watch(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () => _showTestNotificationDialog(context, notificationService),
            tooltip: 'Test Notification',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.blue.shade600, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Groundwater Alert Settings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure notifications for critical groundwater conditions',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Critical Alerts Section
            _buildAlertSection(
              context,
              '🚨 Critical Alerts',
              'Get notified when groundwater levels reach critical thresholds',
              [
                _buildSwitchTile(
                  'Critical Level Alerts',
                  'Alert when water levels are critically low or high',
                  notificationSettings.criticalAlertsEnabled,
                  (value) => ref.read(notificationSettingsProvider.notifier).updateCriticalAlerts(value),
                  Colors.red,
                ),
                _buildSliderTile(
                  'Critical Threshold',
                  'Water level threshold for critical alerts (meters)',
                  notificationSettings.criticalThreshold,
                  -15.0,
                  -2.0,
                  (value) => ref.read(notificationSettingsProvider.notifier).updateCriticalThreshold(value),
                  Colors.red,
                  '${notificationSettings.criticalThreshold.toStringAsFixed(1)}m',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Trend Alerts Section
            _buildAlertSection(
              context,
              '📈 Trend Alerts',
              'Monitor groundwater level trends and changes',
              [
                _buildSwitchTile(
                  'Trend Change Alerts',
                  'Alert when groundwater levels show significant trends',
                  notificationSettings.trendAlertsEnabled,
                  (value) => ref.read(notificationSettingsProvider.notifier).updateTrendAlerts(value),
                  Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recharge Alerts Section
            _buildAlertSection(
              context,
              '💧 Recharge Alerts',
              'Notifications for groundwater recharge opportunities',
              [
                _buildSwitchTile(
                  'Recharge Opportunity Alerts',
                  'Alert when conditions are optimal for groundwater recharge',
                  notificationSettings.rechargeAlertsEnabled,
                  (value) => ref.read(notificationSettingsProvider.notifier).updateRechargeAlerts(value),
                  Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Data Quality Alerts Section
            _buildAlertSection(
              context,
              '📊 Data Quality Alerts',
              'Monitor data quality and sensor health',
              [
                _buildSwitchTile(
                  'Data Quality Issues',
                  'Alert when data quality issues are detected',
                  notificationSettings.dataQualityAlertsEnabled,
                  (value) => ref.read(notificationSettingsProvider.notifier).updateDataQualityAlerts(value),
                  Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Scheduled Checks Section
            _buildAlertSection(
              context,
              '⏰ Scheduled Checks',
              'Regular groundwater monitoring reminders',
              [
                _buildSwitchTile(
                  'Scheduled Monitoring',
                  'Receive regular reminders to check groundwater levels',
                  notificationSettings.scheduledChecksEnabled,
                  (value) => ref.read(notificationSettingsProvider.notifier).updateScheduledChecks(value),
                  Colors.blue,
                ),
                if (notificationSettings.scheduledChecksEnabled)
                  _buildSliderTile(
                    'Check Interval',
                    'How often to receive monitoring reminders',
                    notificationSettings.checkIntervalHours.toDouble(),
                    1.0,
                    168.0, // 1 hour to 1 week
                    (value) => ref.read(notificationSettingsProvider.notifier).updateCheckInterval(value.toInt()),
                    Colors.blue,
                    _formatInterval(notificationSettings.checkIntervalHours),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Notification Management
            _buildNotificationManagement(context, notificationService),
            
            const SizedBox(height: 24),
            
            // Alert Types Information
            _buildAlertTypesInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSection(
    BuildContext context,
    String title,
    String subtitle,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: color,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Color color,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
                activeColor: color,
                divisions: ((max - min) / 0.5).round(),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationManagement(BuildContext context, GroundwaterNotificationService notificationService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final pending = await notificationService.getPendingNotifications();
                      _showPendingNotificationsDialog(context, pending);
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('View Pending'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await notificationService.cancelAllNotifications();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All notifications cancelled')),
                        );
                      }
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Cancel All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTypesInfo(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Types Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _buildAlertTypeInfo(
              '🚨 Critical Alerts',
              'High priority alerts for immediate attention',
              'Red notifications with sound and vibration',
            ),
            _buildAlertTypeInfo(
              '📈 Trend Alerts',
              'Medium priority alerts for trend monitoring',
              'Orange notifications with sound',
            ),
            _buildAlertTypeInfo(
              '💧 Recharge Alerts',
              'Informational alerts for recharge opportunities',
              'Green notifications with sound',
            ),
            _buildAlertTypeInfo(
              '📊 Data Quality Alerts',
              'Technical alerts for data quality issues',
              'Purple notifications with sound',
            ),
            _buildAlertTypeInfo(
              '⏰ Scheduled Checks',
              'Reminder notifications for regular monitoring',
              'Blue notifications with sound',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTypeInfo(String title, String description, String details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatInterval(int hours) {
    if (hours < 24) {
      return '${hours}h';
    } else if (hours < 168) {
      return '${(hours / 24).toStringAsFixed(1)}d';
    } else {
      return '${(hours / 168).toStringAsFixed(1)}w';
    }
  }

  void _showTestNotificationDialog(BuildContext context, GroundwaterNotificationService notificationService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notification'),
        content: const Text('Choose a notification type to test:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notificationService.showCriticalAlert(
                location: 'Test Location',
                currentDepth: -9.5,
                criticalThreshold: -8.0,
                alertType: 'critical_low',
              );
            },
            child: const Text('Critical Alert'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notificationService.showTrendAlert(
                location: 'Test Location',
                trendDirection: 'declining',
                changeRate: -0.5,
              );
            },
            child: const Text('Trend Alert'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notificationService.showRechargeOpportunityAlert(
                location: 'Test Location',
                currentDepth: -5.0,
                optimalDepth: -4.0,
              );
            },
            child: const Text('Recharge Alert'),
          ),
        ],
      ),
    );
  }

  void _showPendingNotificationsDialog(BuildContext context, List<PendingNotificationRequest> pending) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: pending.isEmpty
              ? const Text('No pending notifications')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final notification = pending[index];
                    return ListTile(
                      title: Text(notification.title ?? 'No title'),
                      subtitle: Text(notification.body ?? 'No body'),
                      trailing: Text('ID: ${notification.id}'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
