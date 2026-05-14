/// Location utilities — coordinate helpers and formatters.
library;

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class LocationUtils {
  LocationUtils._();

  /// Format a LatLng to a human-readable string.
  static String formatLatLng(LatLng point, {int decimals = 5}) {
    return '${point.latitude.toStringAsFixed(decimals)}, '
        '${point.longitude.toStringAsFixed(decimals)}';
  }

  /// Convert degrees to radians.
  static double toRadians(double degrees) => degrees * (math.pi / 180.0);

  /// Convert radians to degrees.
  static double toDegrees(double radians) => radians * (180.0 / math.pi);

  /// Haversine distance between two points (meters).
  static double haversineMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = toRadians(b.latitude - a.latitude);
    final dLng = toRadians(b.longitude - a.longitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final h = sinDLat * sinDLat +
        math.cos(toRadians(a.latitude)) *
            math.cos(toRadians(b.latitude)) *
            sinDLng *
            sinDLng;
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  /// Midpoint between two LatLng points.
  static LatLng midpoint(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }

  /// Generate a bounding box around a center point with a given radius (meters).
  static (LatLng sw, LatLng ne) boundingBox(LatLng center, double radiusMeters) {
    const earthRadius = 6371000.0;
    final latDelta = toDegrees(radiusMeters / earthRadius);
    final lngDelta = toDegrees(
        radiusMeters / (earthRadius * math.cos(toRadians(center.latitude))));

    return (
      LatLng(center.latitude - latDelta, center.longitude - lngDelta),
      LatLng(center.latitude + latDelta, center.longitude + lngDelta),
    );
  }

  /// Format distance for human display.
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Format duration for human display.
  static String formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    }
    if (d.inMinutes > 0) return '${d.inMinutes} min';
    return '${d.inSeconds} sec';
  }
}
