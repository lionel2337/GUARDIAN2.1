/// Application-wide constants for Guardians AI.
library;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Branding Colors
// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary gradient
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color primaryDark = Color(0xFF002171);

  // Accent / Cyan
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentLight = Color(0xFF62EFFF);
  static const Color accentDark = Color(0xFF008BA3);

  // Semantic
  static const Color danger = Color(0xFFE53935);
  static const Color dangerDark = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningDark = Color(0xFFE65100);
  static const Color success = Color(0xFF43A047);
  static const Color successDark = Color(0xFF1B5E20);
  static const Color info = Color(0xFF29B6F6);

  // Surface
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF1A1F36);
  static const Color surfaceLight = Color(0xFF252B48);
  static const Color card = Color(0xFF1E2340);
  static const Color divider = Color(0xFF2C3154);

  // Text
  static const Color textPrimary = Color(0xFFECEFF1);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color textHint = Color(0xFF546E7A);

  // Risk zone colors (with alpha for map overlays)
  static const Color riskLow = Color(0x3343A047);
  static const Color riskMedium = Color(0x33FFA726);
  static const Color riskHigh = Color(0x33E53935);
  static const Color riskCritical = Color(0x55B71C1C);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [danger, Color(0xFFFF7043)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, surface],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dimensions
// ─────────────────────────────────────────────────────────────────────────────

class AppDimens {
  AppDimens._();

  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 999.0;

  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  static const double sosButtonSize = 72.0;
  static const double bottomNavHeight = 64.0;
  static const double mapZoomDefault = 13.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Geography — Yaoundé defaults
// ─────────────────────────────────────────────────────────────────────────────

class AppGeo {
  AppGeo._();

  /// Default map center — Yaoundé, Cameroon.
  static const LatLng yaoundeCenter = LatLng(3.8480, 11.5021);

  /// Default zoom level for the map.
  static const double defaultZoom = 13.0;

  /// Maximum deviation radius (meters) before journey alert fires.
  static const double maxDeviationMeters = 300.0;

  /// Geofence radius for risk zones (meters).
  static const double defaultGeofenceRadius = 500.0;

  /// Community report expiry duration.
  static const Duration reportExpiry = Duration(hours: 2);
}

// ─────────────────────────────────────────────────────────────────────────────
// Supabase Table Names
// ─────────────────────────────────────────────────────────────────────────────

class Tables {
  Tables._();

  static const String users = 'users';
  static const String devices = 'devices';
  static const String positions = 'positions';
  static const String alerts = 'alerts';
  static const String emergencyContacts = 'emergency_contacts';
  static const String riskZones = 'risk_zones';
  static const String communityReports = 'community_reports';
  static const String monitoredJourneys = 'monitored_journeys';
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Types
// ─────────────────────────────────────────────────────────────────────────────

class AlertTypes {
  AlertTypes._();

  static const String sos = 'SOS';
  static const String fall = 'FALL';
  static const String fight = 'FIGHT';
  static const String scream = 'SCREAM';
  static const String keyword = 'KEYWORD';
  static const String deviation = 'DEVIATION';
  static const String deadManSwitch = 'DEAD_MAN_SWITCH';
  static const String traceurSos = 'TRACEUR_SOS';
  static const String lowBattery = 'LOW_BATTERY';
  static const String running = 'EMERGENCY_RUNNING';
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Types (Community)
// ─────────────────────────────────────────────────────────────────────────────

class ReportTypes {
  ReportTypes._();

  static const String harassment = 'harassment';
  static const String assault = 'assault';
  static const String theft = 'theft';
  static const String poorLighting = 'poor_lighting';
  static const String suspiciousActivity = 'suspicious_activity';
  static const String roadBlock = 'road_block';
  static const String other = 'other';

  static const List<String> all = [
    harassment,
    assault,
    theft,
    poorLighting,
    suspiciousActivity,
    roadBlock,
    other,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync Configuration
// ─────────────────────────────────────────────────────────────────────────────

class SyncConfig {
  SyncConfig._();

  /// How often the background sync runs (minutes).
  static const int syncIntervalMinutes = 15;

  /// Maximum retry attempts before giving up on a sync item.
  static const int maxRetryAttempts = 10;

  /// Heartbeat interval for Dead Man Switch (seconds).
  static const int heartbeatIntervalSeconds = 30;

  /// Dead Man Switch timeout (seconds).
  static const int deadManSwitchTimeoutSeconds = 120;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation Durations
// ─────────────────────────────────────────────────────────────────────────────

class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration splash = Duration(seconds: 3);
  static const Duration pulseInterval = Duration(milliseconds: 1500);
}

// ─────────────────────────────────────────────────────────────────────────────
// OpenStreetMap Tile Server (free, no key)
// ─────────────────────────────────────────────────────────────────────────────

class MapTiles {
  MapTiles._();

  /// Standard OSM tile URL.
  static const String osmUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Dark-themed tiles (CartoDB Dark Matter — free).
  static const String darkUrl =
      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png';

  /// Attribution required by OSM.
  static const String osmAttribution =
      '© OpenStreetMap contributors';

  /// Attribution for CartoDB.
  static const String cartoAttribution =
      '© OpenStreetMap contributors © CARTO';
}
