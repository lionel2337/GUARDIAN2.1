import 'package:flutter_test/flutter_test.dart';
import 'package:guardians_ai/models/alert.dart';

void main() {
  group('Alert Model', () {
    test('fromJson creates a valid Alert', () {
      final json = {
        'id': 'test-id-123',
        'device_id': 'device-001',
        'alert_type': 'sos',
        'lat': 3.8480,
        'lng': 11.5021,
        'triggered_at': '2026-04-24T12:00:00.000Z',
        'acknowledged': false,
        'resolved_at': null,
      };

      final alert = Alert.fromJson(json);

      expect(alert.id, 'test-id-123');
      expect(alert.deviceId, 'device-001');
      expect(alert.alertType, AlertType.sos);
      expect(alert.lat, 3.8480);
      expect(alert.lng, 11.5021);
      expect(alert.acknowledged, false);
      expect(alert.isSynced, true); // fromJson always sets synced = true
    });

    test('toJson produces correct map', () {
      final alert = Alert(
        id: 'abc',
        deviceId: 'dev-1',
        alertType: AlertType.fall,
        lat: 3.85,
        lng: 11.50,
        triggeredAt: DateTime.utc(2026, 4, 24, 12),
      );

      final json = alert.toJson();

      expect(json['id'], 'abc');
      expect(json['device_id'], 'dev-1');
      expect(json['alert_type'], 'fall');
      expect(json['lat'], 3.85);
      expect(json['acknowledged'], false);
    });

    test('fromMap / toMap round-trip', () {
      final original = Alert(
        id: 'round-trip',
        deviceId: 'dev-2',
        alertType: AlertType.scream,
        lat: 3.87,
        lng: 11.52,
        triggeredAt: DateTime.utc(2026, 1, 1),
        acknowledged: true,
        isSynced: false,
      );

      final map = original.toMap();
      final restored = Alert.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.alertType, AlertType.scream);
      expect(restored.acknowledged, true);
      expect(restored.isSynced, false);
    });

    test('isActive returns true for unacknowledged unresolved alerts', () {
      final alert = Alert(
        id: 'a1',
        deviceId: 'd1',
        alertType: AlertType.sos,
        triggeredAt: DateTime.now(),
      );
      expect(alert.isActive, true);
    });

    test('isActive returns false for acknowledged alerts', () {
      final alert = Alert(
        id: 'a2',
        deviceId: 'd1',
        alertType: AlertType.sos,
        triggeredAt: DateTime.now(),
        acknowledged: true,
      );
      expect(alert.isActive, false);
    });

    test('label returns human-readable string for all types', () {
      for (final type in AlertType.values) {
        final alert = Alert(
          id: 'x',
          deviceId: 'y',
          alertType: type,
          triggeredAt: DateTime.now(),
        );
        expect(alert.label, isNotEmpty);
      }
    });

    test('_parseAlertType handles unknown types gracefully', () {
      final json = {
        'id': 'x',
        'device_id': 'y',
        'alert_type': 'unknown_type',
        'triggered_at': '2026-01-01T00:00:00.000Z',
      };
      final alert = Alert.fromJson(json);
      expect(alert.alertType, AlertType.sos); // Falls back to SOS
    });

    test('copyWith creates a modified copy', () {
      final original = Alert(
        id: 'orig',
        deviceId: 'dev',
        alertType: AlertType.fall,
        triggeredAt: DateTime.now(),
      );
      final copy = original.copyWith(acknowledged: true);

      expect(copy.acknowledged, true);
      expect(copy.id, 'orig');
      expect(copy.alertType, AlertType.fall);
    });
  });
}
