/// Location service — handles all GPS operations for the mobile device.
///
/// Uses the Geolocator package for position tracking and provides
/// utility methods for distance calculation and geofencing.
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  StreamSubscription<geo.Position>? _positionSubscription;

  // ══════════════════════════════════════════════════════════════════════════
  // Permission checks
  // ══════════════════════════════════════════════════════════════════════════

  /// Checks and requests location permissions, returning true if granted.
  Future<bool> ensurePermission() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return false;
    }
    if (permission == geo.LocationPermission.deniedForever) return false;
    return true;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Current position
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns the current device position with high accuracy.
  Future<LatLng?> getCurrentLocation() async {
    try {
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Returns a full Geolocator Position (includes speed, heading, etc.).
  Future<geo.Position?> getCurrentPositionFull() async {
    try {
      return await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Continuous tracking
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns a stream of position updates suitable for journey monitoring.
  Stream<geo.Position> getLocationStream({
    int distanceFilterMeters = 10,
    geo.LocationAccuracy accuracy = geo.LocationAccuracy.high,
  }) {
    return geo.Geolocator.getPositionStream(
      locationSettings: geo.LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  /// Starts background location tracking with a callback.
  void startBackgroundLocation(
    void Function(geo.Position) onPosition, {
    int distanceFilterMeters = 20,
  }) {
    _positionSubscription?.cancel();
    _positionSubscription = getLocationStream(
      distanceFilterMeters: distanceFilterMeters,
    ).listen(onPosition);
  }

  /// Stops background location tracking.
  void stopBackgroundLocation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Distance & Geofence
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates the distance in meters between two points using Haversine.
  double calculateDistance(LatLng a, LatLng b) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);

    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);

    final h = sinDLat * sinDLat +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            sinDLng *
            sinDLng;

    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  /// Returns true when [point] is within [radiusMeters] of [center].
  bool isWithinGeofence(LatLng point, LatLng center, double radiusMeters) {
    return calculateDistance(point, center) <= radiusMeters;
  }

  /// Calculates bearing from point A to point B in degrees.
  double calculateBearing(LatLng a, LatLng b) {
    final dLng = _toRadians(b.longitude - a.longitude);
    final y = math.sin(dLng) * math.cos(_toRadians(b.latitude));
    final x = math.cos(_toRadians(a.latitude)) *
            math.sin(_toRadians(b.latitude)) -
        math.sin(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            math.cos(dLng);
    final bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════════

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
  double _toDegrees(double radians) => radians * (180.0 / math.pi);

  /// Formats a distance for display.
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Formats a duration for display.
  static String formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    }
    return '${d.inMinutes} min';
  }
}
