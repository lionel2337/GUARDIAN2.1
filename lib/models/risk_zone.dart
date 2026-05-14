/// RiskZone model — a geographic zone with an associated risk score.
library;

class RiskZone {
  final String id;
  final String zoneName;
  final double centerLat;
  final double centerLng;
  final double radiusKm;
  final double riskScore; // 0.0 to 1.0
  final DateTime updatedAt;

  const RiskZone({
    required this.id,
    required this.zoneName,
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
    required this.riskScore,
    required this.updatedAt,
  });

  /// Risk level label.
  String get riskLevel {
    if (riskScore >= 0.75) return 'Critical';
    if (riskScore >= 0.5) return 'High';
    if (riskScore >= 0.25) return 'Medium';
    return 'Low';
  }

  /// Radius in meters.
  double get radiusMeters => radiusKm * 1000;

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory RiskZone.fromJson(Map<String, dynamic> json) => RiskZone(
        id: json['id'] as String,
        zoneName: json['zone_name'] as String,
        centerLat: (json['center_lat'] as num).toDouble(),
        centerLng: (json['center_lng'] as num).toDouble(),
        radiusKm: (json['radius_km'] as num).toDouble(),
        riskScore: (json['risk_score'] as num).toDouble(),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'zone_name': zoneName,
        'center_lat': centerLat,
        'center_lng': centerLng,
        'radius_km': radiusKm,
        'risk_score': riskScore,
        'updated_at': updatedAt.toIso8601String(),
      };

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory RiskZone.fromMap(Map<String, dynamic> map) => RiskZone(
        id: map['id'] as String,
        zoneName: map['zone_name'] as String,
        centerLat: (map['center_lat'] as num).toDouble(),
        centerLng: (map['center_lng'] as num).toDouble(),
        radiusKm: (map['radius_km'] as num).toDouble(),
        riskScore: (map['risk_score'] as num).toDouble(),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => toJson();

  // ── Copy ──────────────────────────────────────────────────────────────────

  RiskZone copyWith({
    String? id,
    String? zoneName,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    double? riskScore,
    DateTime? updatedAt,
  }) =>
      RiskZone(
        id: id ?? this.id,
        zoneName: zoneName ?? this.zoneName,
        centerLat: centerLat ?? this.centerLat,
        centerLng: centerLng ?? this.centerLng,
        radiusKm: radiusKm ?? this.radiusKm,
        riskScore: riskScore ?? this.riskScore,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() => 'RiskZone($zoneName, score=$riskScore)';
}
