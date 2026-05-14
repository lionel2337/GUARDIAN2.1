/// Notification service — handles local push notifications.
///
/// Uses flutter_local_notifications for all alerts (no Firebase required).
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _sosChannelId = 'sos_alerts';
  static const String _fallChannelId = 'fall_alerts';
  static const String _journeyChannelId = 'journey_alerts';
  static const String _generalChannelId = 'general';

  // Notification IDs
  static const int sosNotificationId = 1000;
  static const int fallNotificationId = 1001;
  static const int screamNotificationId = 1002;
  static const int deviationNotificationId = 1003;
  static const int journeyReminderNotificationId = 1004;
  static const int offlineSyncNotificationId = 1005;
  static const int batteryNotificationId = 1006;

  // ══════════════════════════════════════════════════════════════════════════
  // Initialization
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    // Initialize timezone data for scheduled notifications.
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android.
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _sosChannelId,
      'SOS Alerts',
      description: 'Critical emergency SOS alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _fallChannelId,
      'Fall Detection',
      description: 'Fall and movement detection alerts',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _journeyChannelId,
      'Journey Monitoring',
      description: 'Journey status and deviation alerts',
      importance: Importance.high,
      playSound: true,
    ));

    await android.createNotificationChannel(const AndroidNotificationChannel(
      _generalChannelId,
      'General',
      description: 'General notifications',
      importance: Importance.defaultImportance,
    ));
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — navigate to relevant screen.
    // This can be expanded with GoRouter deep linking.
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Show Notifications
  // ══════════════════════════════════════════════════════════════════════════

  /// Show a general local notification.
  Future<void> showLocalNotification(String title, String body) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannelId,
          'General',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  /// Show a critical SOS notification.
  Future<void> showSosNotification(
      String message, double lat, double lng) async {
    await _plugin.show(
      sosNotificationId,
      '🚨 SOS ALERT',
      '$message\nLocation: $lat, $lng',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _sosChannelId,
          'SOS Alerts',
          importance: Importance.max,
          priority: Priority.max,
          ongoing: true,
          autoCancel: false,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }

  /// Show fall detection notification with countdown.
  Future<void> showFallDetectionNotification(int countdown) async {
    await _plugin.show(
      fallNotificationId,
      '⚠️ Fall Detected',
      'Emergency alert in $countdown seconds. Tap to cancel.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _fallChannelId,
          'Fall Detection',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }

  /// Show a scream detection notification.
  Future<void> showScreamNotification() async {
    await _plugin.show(
      screamNotificationId,
      '🔊 Scream Detected',
      'A scream has been detected. Emergency contacts notified.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _sosChannelId,
          'SOS Alerts',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }

  /// Show route deviation notification.
  Future<void> showDeviationNotification() async {
    await _plugin.show(
      deviationNotificationId,
      '📍 Route Deviation',
      'You have deviated from your planned route. Emergency contacts have been notified.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _journeyChannelId,
          'Journey Monitoring',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Schedule a journey reminder notification.
  Future<void> scheduleJourneyReminder(int minutes) async {
    await _plugin.zonedSchedule(
      journeyReminderNotificationId,
      '⏰ Journey Check-In',
      'Your monitored journey has been running for $minutes minutes. Are you okay?',
      _nextInstanceOfTZ(minutes),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _journeyChannelId,
          'Journey Monitoring',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel a specific notification.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Compute a TZDateTime for scheduling.
  tz.TZDateTime _nextInstanceOfTZ(int minutesFromNow) {
    final now = tz.TZDateTime.now(tz.local);
    return now.add(Duration(minutes: minutesFromNow));
  }
}
