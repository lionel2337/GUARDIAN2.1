import 'package:flutter_test/flutter_test.dart';
import 'package:guardians_ai/models/risk_zone.dart';

void main() {
  group('RiskZone Model', () {
    test('fromJson creates a valid RiskZone', () {
      final json = {
        'id': 'zone-1',
        'zone_name': 'Briqueterie',
        'center_lat': 3.8750,
        'center_lng': 11.5150,
        'radius_km': 0.8,
        'risk_score': 0.7,
        'updated_at': '2026-04-24T12:00:00.000Z',
      };

      final zone = RiskZone.fromJson(json);

      expect(zone.id, 'zone-1');
      expect(zone.zoneName, 'Briqueterie');
      expect(zone.riskScore, 0.7);
      expect(zone.radiusKm, 0.8);
    });

    test('radiusMeters converts km to meters', () {
      final zone = RiskZone(
        id: 'z',
        zoneName: 'Test',
        centerLat: 0,
        centerLng: 0,
        radiusKm: 1.5,
        riskScore: 0.5,
        updatedAt: DateTime.now(),
      );
      expect(zone.radiusMeters, 1500.0);
    });

    test('riskLevel returns correct label', () {
      final testCases = {
        0.80: 'Critical',
        0.75: 'Critical',
        0.60: 'High',
        0.50: 'High',
        0.30: 'Medium',
        0.25: 'Medium',
        0.10: 'Low',
        0.00: 'Low',
      };

      for (final entry in testCases.entries) {
        final zone = RiskZone(
          id: 'z',
          zoneName: 'Test',
          centerLat: 0,
          centerLng: 0,
          radiusKm: 1.0,
          riskScore: entry.key,
          updatedAt: DateTime.now(),
        );
        expect(zone.riskLevel, entry.value,
            reason: 'Score ${entry.key} should be ${entry.value}');
      }
    });

    test('toJson / fromJson round-trip', () {
      final original = RiskZone(
        id: 'rt-zone',
        zoneName: 'Round Trip Zone',
        centerLat: 3.85,
        centerLng: 11.50,
        radiusKm: 0.5,
        riskScore: 0.65,
        updatedAt: DateTime.utc(2026, 4, 1),
      );

      final json = original.toJson();
      final restored = RiskZone.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.zoneName, original.zoneName);
      expect(restored.centerLat, original.centerLat);
      expect(restored.centerLng, original.centerLng);
      expect(restored.radiusKm, original.radiusKm);
      expect(restored.riskScore, original.riskScore);
    });

    test('copyWith creates a modified copy', () {
      final zone = RiskZone(
        id: 'z1',
        zoneName: 'Original',
        centerLat: 3.0,
        centerLng: 11.0,
        radiusKm: 1.0,
        riskScore: 0.5,
        updatedAt: DateTime.now(),
      );
      final updated = zone.copyWith(zoneName: 'Updated', riskScore: 0.9);

      expect(updated.zoneName, 'Updated');
      expect(updated.riskScore, 0.9);
      expect(updated.id, 'z1');
      expect(updated.centerLat, 3.0);
    });
  });
}
