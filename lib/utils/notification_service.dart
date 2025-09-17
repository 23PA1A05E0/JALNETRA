import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Service for managing notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  static NotificationService get instance => _instance;
  
  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  /// Initialize the notification service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }
  
  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      _logger.i('Local notifications initialized successfully');
    } catch (e) {
      _logger.e('Error initializing local notifications: $e');
    }
  }
  
  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for notifications
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('Firebase messaging permission granted');
        
        // Configure foreground notification presentation
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Handle notification tap when app is terminated
        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
        
        // Get FCM token
        final token = await _firebaseMessaging.getToken();
        _logger.i('FCM Token: $token');
        
        // TODO: Send token to server for push notifications
        
      } else {
        _logger.w('Firebase messaging permission denied');
      }
    } catch (e) {
      _logger.e('Error initializing Firebase messaging: $e');
    }
  }
  
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Received foreground message: ${message.messageId}');
    
    // Show local notification for foreground messages
    _showLocalNotification(
      title: message.notification?.title ?? 'JALNETRA',
      body: message.notification?.body ?? 'New notification',
      payload: message.data.toString(),
    );
  }
  
  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.messageId}');
    
    // TODO: Navigate to appropriate screen based on message data
    // Example: Navigate to station detail if stationId is provided
    final stationId = message.data['stationId'];
    if (stationId != null) {
      // Navigate to station detail screen
      // context.go('/station/$stationId');
    }
  }
  
  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('Local notification tapped: ${response.payload}');
    
    // TODO: Handle local notification tap
    // Parse payload and navigate accordingly
  }
  
  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'jalnetra_channel',
        'JALNETRA Notifications',
        channelDescription: 'Notifications for JALNETRA app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );
      
      _logger.d('Local notification shown: $title');
    } catch (e) {
      _logger.e('Error showing local notification: $e');
    }
  }
  
  /// Show station alert notification
  Future<void> showStationAlert({
    required String stationId,
    required String stationName,
    required String message,
    required String severity,
  }) async {
    await _showLocalNotification(
      title: 'Alert: $stationName',
      body: message,
      payload: 'station_alert:$stationId',
    );
  }
  
  /// Show recharge rate notification
  Future<void> showRechargeRateAlert({
    required String stationId,
    required String stationName,
    required double currentRate,
    required double targetRate,
  }) async {
    final message = currentRate < targetRate
        ? 'Recharge rate is below target (${currentRate.toStringAsFixed(1)} L/h)'
        : 'Recharge rate is above target (${currentRate.toStringAsFixed(1)} L/h)';
    
    await _showLocalNotification(
      title: 'Recharge Alert: $stationName',
      body: message,
      payload: 'recharge_alert:$stationId',
    );
  }
  
  /// Show maintenance notification
  Future<void> showMaintenanceNotification({
    required String stationId,
    required String stationName,
    required String message,
  }) async {
    await _showLocalNotification(
      title: 'Maintenance: $stationName',
      body: message,
      payload: 'maintenance:$stationId',
    );
  }
  
  /// Schedule periodic notification
  Future<void> schedulePeriodicNotification({
    required String title,
    required String body,
    required Duration interval,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'jalnetra_periodic',
        'JALNETRA Periodic',
        channelDescription: 'Periodic notifications for JALNETRA app',
        importance: Importance.low,
        priority: Priority.low,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.periodicallyShow(
        0,
        title,
        body,
        RepeatInterval.everyMinute, // Adjust as needed
        details,
      );
      
      _logger.d('Periodic notification scheduled');
    } catch (e) {
      _logger.e('Error scheduling periodic notification: $e');
    }
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      _logger.d('All notifications cancelled');
    } catch (e) {
      _logger.e('Error cancelling all notifications: $e');
    }
  }
  
  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      _logger.e('Error getting FCM token: $e');
      return null;
    }
  }
  
  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Error subscribing to topic $topic: $e');
    }
  }
  
  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Error unsubscribing from topic $topic: $e');
    }
  }
}
