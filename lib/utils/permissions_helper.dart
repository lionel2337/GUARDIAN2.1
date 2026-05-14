/// Permissions helper — unified permission request flow.
library;

import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  PermissionsHelper._();

  /// Request all required permissions at once.
  static Future<Map<Permission, PermissionStatus>> requestAll() async {
    return [
      Permission.location,
      Permission.locationAlways,
      Permission.microphone,
      Permission.activityRecognition,
      Permission.notification,
      Permission.phone,
      Permission.sms,
    ].request();
  }

  /// Check if location is granted.
  static Future<bool> isLocationGranted() async {
    return (await Permission.location.status).isGranted;
  }

  /// Check if microphone is granted.
  static Future<bool> isMicrophoneGranted() async {
    return (await Permission.microphone.status).isGranted;
  }

  /// Check if activity recognition is granted.
  static Future<bool> isActivityGranted() async {
    return (await Permission.activityRecognition.status).isGranted;
  }

  /// Check if notification is granted.
  static Future<bool> isNotificationGranted() async {
    return (await Permission.notification.status).isGranted;
  }

  /// Request location only.
  static Future<bool> requestLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request background location (needs foreground first).
  static Future<bool> requestBackgroundLocation() async {
    if (!await isLocationGranted()) {
      await requestLocation();
    }
    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  /// Request microphone only.
  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Open app settings (for permanently denied permissions).
  static Future<bool> openSettings() async {
    return openAppSettings();
  }
}
