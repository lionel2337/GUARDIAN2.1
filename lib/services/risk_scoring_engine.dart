/// Risk Scoring Engine — GPS-based safety scoring with zone awareness.
///
/// Combines predefined Yaoundé risk zones, time-of-day multipliers,
/// community reports, and user habit learning to produce a 0.0–1.0
/// risk score for any GPS position.
///
/// Runs entirely offline using the local SQLite database.
library;

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';


import '../models/risk_zone.dart';
import 'local_database_service.dart';

/// Complete risk assessment for a location.
class RiskAssessment {
  final double score; // 0.0 (safe) to 1.0 (dangerous)
  final String level; // 'Low', 'Medium', 'High', 'Critical'
  final List<String> factors;
  final DateTime timestamp;
  final LatLng position;

  const RiskAssessment({
    required this.score,
    required this.level,
    required this.factors,
    required this.timestamp,
    required this.position,
  });
}

class RiskScoringEngine {
  final LocalDatabaseService _db;

  RiskScoringEngine(this._db);

  // ══════════════════════════════════════════════════════════════════════════
  // Predefined Risk Zones — Yaoundé, Cameroon
  // ══════════════════════════════════════════════════════════════════════════

  static final List<RiskZone> predefinedZones = [
    // ── Higher risk areas ────────────────────────────────────────────────
    RiskZone(
      id: 'zone_briqueterie',
      zoneName: 'Briqueterie',
      centerLat: 3.8750,
      centerLng: 11.5150,
      radiusKm: 0.8,
      riskScore: 0.7,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_mokolo',
      zoneName: 'Marché Mokolo',
      centerLat: 3.8700,
      centerLng: 11.5050,
      radiusKm: 0.5,
      riskScore: 0.65,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_nkol_eton',
      zoneName: 'Nkol-Eton',
      centerLat: 3.8900,
      centerLng: 11.5200,
      radiusKm: 0.6,
      riskScore: 0.6,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_mvog_ada',
      zoneName: 'Mvog-Ada',
      centerLat: 3.8550,
      centerLng: 11.5200,
      radiusKm: 0.5,
      riskScore: 0.55,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_nkomkana',
      zoneName: 'Nkomkana',
      centerLat: 3.8300,
      centerLng: 11.4800,
      radiusKm: 0.7,
      riskScore: 0.50,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_melen',
      zoneName: 'Melen',
      centerLat: 3.8600,
      centerLng: 11.4900,
      radiusKm: 0.6,
      riskScore: 0.50,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_carriere',
      zoneName: 'Carrière',
      centerLat: 3.8400,
      centerLng: 11.5300,
      radiusKm: 0.5,
      riskScore: 0.55,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_essos',
      zoneName: 'Essos',
      centerLat: 3.8700,
      centerLng: 11.5350,
      radiusKm: 0.6,
      riskScore: 0.45,
      updatedAt: DateTime.now(),
    ),

    // ── Lower risk areas ─────────────────────────────────────────────────
    RiskZone(
      id: 'zone_bastos',
      zoneName: 'Bastos (Ambassades)',
      centerLat: 3.8900,
      centerLng: 11.5000,
      radiusKm: 0.8,
      riskScore: 0.15,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_centre_admin',
      zoneName: 'Centre Administratif',
      centerLat: 3.8660,
      centerLng: 11.5180,
      radiusKm: 0.4,
      riskScore: 0.20,
      updatedAt: DateTime.now(),
    ),
    RiskZone(
      id: 'zone_hilton',
      zoneName: 'Quartier Hilton',
      centerLat: 3.8620,
      centerLng: 11.5100,
      radiusKm: 0.3,
      riskScore: 0.10,
      updatedAt: DateTime.now(),
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════
  // Main scoring method
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculate the risk score for a given position.
  Future<RiskAssessment> calculateRisk(LatLng position) async {
    double score = 0.0;
    final factors = <String>[];

    // 1 ── Predefined zone risk
    final zoneScore = _calculateZoneRisk(position);
    if (zoneScore > 0) {
      score += zoneScore * 0.40; // 40% weight
      factors.add('Zone risk: ${(zoneScore * 100).round()}%');
    }

    // 2 ── Custom zones from Supabase (cached locally)
    final customZoneScore = await _calculateCustomZoneRisk(position);
    if (customZoneScore > 0) {
      score += customZoneScore * 0.15; // 15% weight
      factors.add('Custom zone: ${(customZoneScore * 100).round()}%');
    }

    // 3 ── Time-of-day multiplier
    final timeMultiplier = _calculateTimeMultiplier();
    score *= timeMultiplier;
    if (timeMultiplier > 1.2) {
      factors.add('Night-time risk (×${timeMultiplier.toStringAsFixed(1)})');
    }

    // 4 ── Community reports nearby
    final reportScore = await _calculateCommunityReportRisk(position);
    if (reportScore > 0) {
      score += reportScore * 0.25; // 25% weight
      factors.add('Community reports nearby');
    }

    // 5 ── Habit/familiarity bonus (reduces risk for known routes)
    final habitBonus = await _calculateHabitBonus(position);
    if (habitBonus > 0) {
      score -= habitBonus * 0.10; // Up to 10% reduction
      factors.add('Familiar area (-${(habitBonus * 10).round()}%)');
    }

    // Clamp to 0.0 – 1.0
    score = score.clamp(0.0, 1.0);

    final level = _scoreToLevel(score);

    return RiskAssessment(
      score: score,
      level: level,
      factors: factors,
      timestamp: DateTime.now(),
      position: position,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Component Scores
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns the highest risk score from predefined zones that contain this point.
  double _calculateZoneRisk(LatLng position) {
    double maxRisk = 0.0;

    for (final zone in predefinedZones) {
      final center = LatLng(zone.centerLat, zone.centerLng);
      final distance = _haversineMeters(position, center);

      if (distance <= zone.radiusMeters) {
        // Risk decreases linearly from center to edge.
        final proximity = 1.0 - (distance / zone.radiusMeters);
        final effectiveRisk = zone.riskScore * proximity;
        if (effectiveRisk > maxRisk) {
          maxRisk = effectiveRisk;
        }
      }
    }

    return maxRisk;
  }

  /// Check custom risk zones stored locally (fetched from Supabase).
  Future<double> _calculateCustomZoneRisk(LatLng position) async {
    final zones = await _db.getAllRiskZones();
    double maxRisk = 0.0;

    for (final zone in zones) {
      final center = LatLng(zone.centerLat, zone.centerLng);
      final distance = _haversineMeters(position, center);

      if (distance <= zone.radiusMeters) {
        final proximity = 1.0 - (distance / zone.radiusMeters);
        final effectiveRisk = zone.riskScore * proximity;
        if (effectiveRisk > maxRisk) {
          maxRisk = effectiveRisk;
        }
      }
    }

    return maxRisk;
  }

  /// Time-of-day multiplier.
  /// Night (21:00 – 05:00) is more dangerous.
  double _calculateTimeMultiplier() {
    final hour = DateTime.now().hour;

    if (hour >= 22 || hour < 4) return 1.6; // Late night
    if (hour >= 21 || hour < 5) return 1.4; // Night
    if (hour >= 20 || hour < 6) return 1.2; // Dusk / dawn
    return 1.0; // Daytime
  }

  /// Calculate risk boost from nearby community reports.
  Future<double> _calculateCommunityReportRisk(LatLng position) async {
    final reports = await _db.getActiveCommunityReports();
    if (reports.isEmpty) return 0.0;

    double totalInfluence = 0.0;

    for (final report in reports) {
      final reportPos = LatLng(report.lat, report.lng);
      final distance = _haversineMeters(position, reportPos);

      // Reports influence within 500 meters.
      if (distance <= 500) {
        final proximity = 1.0 - (distance / 500);

        // Weight by report type severity.
        final severity = _reportTypeSeverity(report.reportType);
        totalInfluence += proximity * severity;
      }
    }

    return totalInfluence.clamp(0.0, 1.0);
  }

  /// Calculate a familiarity bonus — places the user visits often are less risky
  /// (because they know the area and can avoid danger).
  Future<double> _calculateHabitBonus(LatLng position) async {
    // This would query the user's historical positions to determine
    // how often they visit this area at this time of day/week.
    // For now, return 0 (no bonus) until enough data is collected.
    return 0.0;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Route Safety Scoring
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculate an average safety score for a list of waypoints.
  Future<double> calculateRouteSafety(List<LatLng> waypoints) async {
    if (waypoints.isEmpty) return 0.5;

    double totalRisk = 0.0;
    for (final point in waypoints) {
      final assessment = await calculateRisk(point);
      totalRisk += assessment.score;
    }

    final avgRisk = totalRisk / waypoints.length;
    return 1.0 - avgRisk; // Invert: 1.0 = safest, 0.0 = most dangerous
  }

  /// Score a specific route by sampling points along it.
  Future<double> scoreRoute(
      LatLng origin, LatLng destination, List<LatLng> routePoints) async {
    // Sample up to 20 points along the route.
    final sampleCount = math.min(routePoints.length, 20);
    final step = routePoints.length ~/ sampleCount;
    final samples = <LatLng>[];

    for (int i = 0; i < routePoints.length; i += step) {
      samples.add(routePoints[i]);
    }
    samples.add(destination);

    return calculateRouteSafety(samples);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// Haversine distance in meters between two LatLng points.
  double _haversineMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
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

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  /// Maps report types to severity values (0.0 – 1.0).
  double _reportTypeSeverity(String reportType) => switch (reportType) {
        'assault' => 1.0,
        'harassment' => 0.8,
        'theft' => 0.7,
        'suspicious_activity' => 0.5,
        'poor_lighting' => 0.3,
        'road_block' => 0.4,
        _ => 0.3,
      };

  String _scoreToLevel(double score) {
    if (score >= 0.75) return 'Critical';
    if (score >= 0.50) return 'High';
    if (score >= 0.25) return 'Medium';
    return 'Low';
  }

  /// Get all zones for map display (predefined + custom).
  Future<List<RiskZone>> getAllZones() async {
    final customZones = await _db.getAllRiskZones();
    return [...predefinedZones, ...customZones];
  }
}
