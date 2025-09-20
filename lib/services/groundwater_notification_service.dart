import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;

/// Enhanced notification service for critical groundwater alerts
class GroundwaterNotificationService {
  static final GroundwaterNotificationService _instance = GroundwaterNotificationService._internal();
  factory GroundwaterNotificationService() => _instance;
  GroundwaterNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      _isInitialized = true;
      _logger.i('🔔 Groundwater notification service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize notification service: $e');
    }
  }

  /// Request Android notification permissions
  Future<void> _requestAndroidPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('🔔 Notification tapped: ${response.payload}');
    // TODO: Navigate to specific screen based on payload
  }

  /// Show critical groundwater alert
  Future<void> showCriticalAlert({
    required String location,
    required double currentDepth,
    required double criticalThreshold,
    required String alertType,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'critical_alerts',
        'Critical Groundwater Alerts',
        channelDescription: 'Notifications for critical groundwater levels',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFD32F2F), // Red color for critical alerts
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.critical,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final String title = _getAlertTitle(alertType);
      final String body = _getAlertBody(location, currentDepth, criticalThreshold, alertType);

      await _notifications.show(
        _generateNotificationId(location),
        title,
        body,
        notificationDetails,
        payload: 'critical_alert:$location:$alertType',
      );

      _logger.i('🚨 Critical alert sent for $location: $alertType');
    } catch (e) {
      _logger.e('❌ Failed to show critical alert: $e');
    }
  }

  /// Show trend alert
  Future<void> showTrendAlert({
    required String location,
    required String trendDirection,
    required double changeRate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'trend_alerts',
        'Groundwater Trend Alerts',
        channelDescription: 'Notifications for groundwater level trends',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF9800), // Orange color for trend alerts
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final String title = 'Groundwater Trend Alert';
      final String body = '$location: Water level is $trendDirection by ${changeRate.toStringAsFixed(1)}m/month';

      await _notifications.show(
        _generateNotificationId(location),
        title,
        body,
        notificationDetails,
        payload: 'trend_alert:$location:$trendDirection',
      );

      _logger.i('📈 Trend alert sent for $location: $trendDirection');
    } catch (e) {
      _logger.e('❌ Failed to show trend alert: $e');
    }
  }

  /// Show recharge opportunity alert
  Future<void> showRechargeOpportunityAlert({
    required String location,
    required double currentDepth,
    required double optimalDepth,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'recharge_alerts',
        'Recharge Opportunity Alerts',
        channelDescription: 'Notifications for groundwater recharge opportunities',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50), // Green color for recharge alerts
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final String title = 'Recharge Opportunity';
      final String body = '$location: Optimal conditions for groundwater recharge (Current: ${currentDepth.toStringAsFixed(1)}m, Optimal: ${optimalDepth.toStringAsFixed(1)}m)';

      await _notifications.show(
        _generateNotificationId(location),
        title,
        body,
        notificationDetails,
        payload: 'recharge_alert:$location',
      );

      _logger.i('💧 Recharge opportunity alert sent for $location');
    } catch (e) {
      _logger.e('❌ Failed to show recharge alert: $e');
    }
  }

  /// Show data quality alert
  Future<void> showDataQualityAlert({
    required String location,
    required String issue,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'data_quality_alerts',
        'Data Quality Alerts',
        channelDescription: 'Notifications for data quality issues',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF9C27B0), // Purple color for data quality alerts
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.passive,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final String title = 'Data Quality Issue';
      final String body = '$location: $issue';

      await _notifications.show(
        _generateNotificationId(location),
        title,
        body,
        notificationDetails,
        payload: 'data_quality_alert:$location',
      );

      _logger.i('📊 Data quality alert sent for $location: $issue');
    } catch (e) {
      _logger.e('❌ Failed to show data quality alert: $e');
    }
  }

  /// Schedule recurring groundwater check
  Future<void> scheduleRecurringCheck({
    required String location,
    required DateTime scheduledTime,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'scheduled_checks',
        'Scheduled Groundwater Checks',
        channelDescription: 'Scheduled notifications for groundwater monitoring',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3), // Blue color for scheduled checks
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.passive,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final String title = 'Scheduled Groundwater Check';
      final String body = 'Time to check groundwater levels for $location';

      await _notifications.zonedSchedule(
        _generateNotificationId(location),
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: 'scheduled_check:$location',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      _logger.i('⏰ Scheduled check for $location at $scheduledTime');
    } catch (e) {
      _logger.e('❌ Failed to schedule recurring check: $e');
    }
  }

  /// Cancel all notifications for a specific location
  Future<void> cancelLocationNotifications(String location) async {
    try {
      await _notifications.cancel(_generateNotificationId(location));
      _logger.i('🗑️ Cancelled notifications for $location');
    } catch (e) {
      _logger.e('❌ Failed to cancel notifications for $location: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.i('🗑️ Cancelled all notifications');
    } catch (e) {
      _logger.e('❌ Failed to cancel all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      _logger.e('❌ Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Helper methods
  String _getAlertTitle(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'critical_low':
        return '🚨 Critical Water Level';
      case 'critical_high':
        return '⚠️ High Water Level';
      case 'quality_issue':
        return '📊 Data Quality Issue';
      case 'sensor_failure':
        return '🔧 Sensor Failure';
      default:
        return '🌊 Groundwater Alert';
    }
  }

  String _getAlertBody(String location, double currentDepth, double threshold, String alertType) {
    switch (alertType.toLowerCase()) {
      case 'critical_low':
        return '$location: Water level critically low at ${currentDepth.toStringAsFixed(1)}m (Threshold: ${threshold.toStringAsFixed(1)}m)';
      case 'critical_high':
        return '$location: Water level critically high at ${currentDepth.toStringAsFixed(1)}m (Threshold: ${threshold.toStringAsFixed(1)}m)';
      case 'quality_issue':
        return '$location: Data quality issue detected - please verify sensor readings';
      case 'sensor_failure':
        return '$location: Sensor failure detected - immediate attention required';
      default:
        return '$location: Groundwater level alert at ${currentDepth.toStringAsFixed(1)}m';
    }
  }

  int _generateNotificationId(String location) {
    // Generate unique ID based on location name
    return location.hashCode.abs();
  }
}

/// Provider for the notification service
final notificationServiceProvider = Provider<GroundwaterNotificationService>((ref) {
  return GroundwaterNotificationService();
});

/// Provider for notification settings
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

/// Notification settings state
class NotificationSettings {
  final bool criticalAlertsEnabled;
  final bool trendAlertsEnabled;
  final bool rechargeAlertsEnabled;
  final bool dataQualityAlertsEnabled;
  final bool scheduledChecksEnabled;
  final double criticalThreshold;
  final int checkIntervalHours;

  const NotificationSettings({
    this.criticalAlertsEnabled = true,
    this.trendAlertsEnabled = true,
    this.rechargeAlertsEnabled = true,
    this.dataQualityAlertsEnabled = true,
    this.scheduledChecksEnabled = false,
    this.criticalThreshold = -8.0,
    this.checkIntervalHours = 24,
  });

  NotificationSettings copyWith({
    bool? criticalAlertsEnabled,
    bool? trendAlertsEnabled,
    bool? rechargeAlertsEnabled,
    bool? dataQualityAlertsEnabled,
    bool? scheduledChecksEnabled,
    double? criticalThreshold,
    int? checkIntervalHours,
  }) {
    return NotificationSettings(
      criticalAlertsEnabled: criticalAlertsEnabled ?? this.criticalAlertsEnabled,
      trendAlertsEnabled: trendAlertsEnabled ?? this.trendAlertsEnabled,
      rechargeAlertsEnabled: rechargeAlertsEnabled ?? this.rechargeAlertsEnabled,
      dataQualityAlertsEnabled: dataQualityAlertsEnabled ?? this.dataQualityAlertsEnabled,
      scheduledChecksEnabled: scheduledChecksEnabled ?? this.scheduledChecksEnabled,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      checkIntervalHours: checkIntervalHours ?? this.checkIntervalHours,
    );
  }
}

/// Notification settings notifier
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  void updateCriticalAlerts(bool enabled) {
    state = state.copyWith(criticalAlertsEnabled: enabled);
  }

  void updateTrendAlerts(bool enabled) {
    state = state.copyWith(trendAlertsEnabled: enabled);
  }

  void updateRechargeAlerts(bool enabled) {
    state = state.copyWith(rechargeAlertsEnabled: enabled);
  }

  void updateDataQualityAlerts(bool enabled) {
    state = state.copyWith(dataQualityAlertsEnabled: enabled);
  }

  void updateScheduledChecks(bool enabled) {
    state = state.copyWith(scheduledChecksEnabled: enabled);
  }

  void updateCriticalThreshold(double threshold) {
    state = state.copyWith(criticalThreshold: threshold);
  }

  void updateCheckInterval(int hours) {
    state = state.copyWith(checkIntervalHours: hours);
  }
}
