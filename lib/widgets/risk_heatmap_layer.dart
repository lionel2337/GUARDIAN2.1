/// Risk heatmap layer — renders colored polygons on the map for risk zones.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/risk_zone.dart';
import '../utils/constants.dart';

class RiskHeatmapLayer extends StatelessWidget {
  final List<RiskZone> zones;

  const RiskHeatmapLayer({super.key, required this.zones});

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) return const SizedBox.shrink();

    return PolygonLayer(
      polygons: zones.map(_buildPolygon).toList(),
    );
  }

  Polygon _buildPolygon(RiskZone zone) {
    // Apply time-of-day multiplier for live risk coloring.
    final hour = DateTime.now().hour;
    double timeMultiplier = 1.0;
    if (hour >= 22 || hour < 4) {
      timeMultiplier = 1.6;
    } else if (hour >= 21 || hour < 5) {
      timeMultiplier = 1.4;
    } else if (hour >= 20 || hour < 6) {
      timeMultiplier = 1.2;
    }

    final effectiveRisk = (zone.riskScore * timeMultiplier).clamp(0.0, 1.0);

    return Polygon(
      points: _circlePoints(
        LatLng(zone.centerLat, zone.centerLng),
        zone.radiusMeters,
      ),
      color: _riskColor(effectiveRisk),
      borderColor: _riskBorderColor(effectiveRisk),
      borderStrokeWidth: 1.5,
      isFilled: true,
      label: zone.zoneName,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Generate circle points as a polygon approximation.
  List<LatLng> _circlePoints(LatLng center, double radiusMeters,
      {int segments = 36}) {
    final points = <LatLng>[];
    const earthRadius = 6371000.0;

    for (int i = 0; i <= segments; i++) {
      final angle = (2 * math.pi * i) / segments;
      final dLat = (radiusMeters / earthRadius) * math.cos(angle);
      final dLng = (radiusMeters /
              (earthRadius * math.cos(center.latitude * math.pi / 180))) *
          math.sin(angle);

      points.add(LatLng(
        center.latitude + (dLat * 180 / math.pi),
        center.longitude + (dLng * 180 / math.pi),
      ));
    }

    return points;
  }

  /// Map risk score to a fill color with transparency.
  Color _riskColor(double score) {
    if (score >= 0.75) return AppColors.riskCritical;
    if (score >= 0.50) return AppColors.riskHigh;
    if (score >= 0.25) return AppColors.riskMedium;
    return AppColors.riskLow;
  }

  /// Map risk score to a border color.
  Color _riskBorderColor(double score) {
    if (score >= 0.75) return AppColors.dangerDark.withOpacity(0.6);
    if (score >= 0.50) return AppColors.danger.withOpacity(0.5);
    if (score >= 0.25) return AppColors.warning.withOpacity(0.4);
    return AppColors.success.withOpacity(0.3);
  }
}
