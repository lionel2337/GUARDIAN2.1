import 'package:flutter_test/flutter_test.dart';
import 'package:guardians_ai/services/location_service.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('LocationService', () {
    final service = LocationService.instance;

    test('calculateDistance returns correct distance between two points', () {
      // Yaoundé center to Briqueterie (approx 3 km)
      final center = LatLng(3.8480, 11.5021);
      final briqueterie = LatLng(3.8750, 11.5150);

      final distance = service.calculateDistance(center, briqueterie);

      // Should be roughly 3200 meters (±200m tolerance)
      expect(distance, greaterThan(3000));
      expect(distance, lessThan(3500));
    });

    test('calculateDistance returns 0 for same point', () {
      final point = LatLng(3.8480, 11.5021);
      expect(service.calculateDistance(point, point), 0.0);
    });

    test('isWithinGeofence returns true when inside radius', () {
      final center = LatLng(3.8480, 11.5021);
      final nearby = LatLng(3.8485, 11.5025); // ~50 meters away

      expect(service.isWithinGeofence(nearby, center, 500), true);
    });

    test('isWithinGeofence returns false when outside radius', () {
      final center = LatLng(3.8480, 11.5021);
      final farAway = LatLng(3.88, 11.53); // ~4 km away

      expect(service.isWithinGeofence(farAway, center, 500), false);
    });

    test('calculateBearing returns valid bearing (0-360)', () {
      final a = LatLng(3.8480, 11.5021);
      final b = LatLng(3.8750, 11.5150);

      final bearing = service.calculateBearing(a, b);

      expect(bearing, greaterThanOrEqualTo(0));
      expect(bearing, lessThan(360));
    });

    test('formatDistance formats meters correctly', () {
      expect(LocationService.formatDistance(500), '500 m');
      expect(LocationService.formatDistance(1500), '1.5 km');
      expect(LocationService.formatDistance(100), '100 m');
    });

    test('formatDuration formats duration correctly', () {
      expect(LocationService.formatDuration(Duration(minutes: 30)), '30 min');
      expect(
          LocationService.formatDuration(Duration(hours: 1, minutes: 15)),
          '1h 15min');
    });
  });
}
