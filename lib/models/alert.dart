/// Alert model — an emergency event triggered by AI or user.
library;

enum AlertType {
  sos,
  fall,
  fight,
  scream,
  keyword,
  deviation,
  deadManSwitch,
  traceurSos,
  lowBattery,
  emergencyRunning,
}

class Alert {
  final String id;
  final String deviceId;
  final AlertType alertType;
  final double? lat;
  final double? lng;
  final DateTime triggeredAt;
  final bool acknowledged;
  final DateTime? resolvedAt;
  final bool isSynced;

  const Alert({
    required this.id,
    required this.deviceId,
    required this.alertType,
    this.lat,
    this.lng,
    required this.triggeredAt,
    this.acknowledged = false,
    this.resolvedAt,
    this.isSynced = false,
  });

  /// Whether this alert is still active (not acknowledged/resolved).
  bool get isActive => !acknowledged && resolvedAt == null;

  /// Human-readable label.
  String get label => switch (alertType) {
        AlertType.sos => 'SOS',
        AlertType.fall => 'Fall Detected',
        AlertType.fight => 'Fight Detected',
        AlertType.scream => 'Scream Detected',
        AlertType.keyword => 'Emergency Keyword',
        AlertType.deviation => 'Route Deviation',
        AlertType.deadManSwitch => 'Dead Man Switch',
        AlertType.traceurSos => 'Traceur SOS',
        AlertType.lowBattery => 'Low Battery',
        AlertType.emergencyRunning => 'Emergency Running',
      };

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['id'] as String,
        deviceId: json['device_id'] as String,
        alertType: _parseAlertType(json['alert_type'] as String?),
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        triggeredAt: DateTime.parse(json['triggered_at'] as String),
        acknowledged: json['acknowledged'] as bool? ?? false,
        resolvedAt: json['resolved_at'] != null
            ? DateTime.parse(json['resolved_at'] as String)
            : null,
        isSynced: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'alert_type': alertType.name,
        'lat': lat,
        'lng': lng,
        'triggered_at': triggeredAt.toIso8601String(),
        'acknowledged': acknowledged,
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory Alert.fromMap(Map<String, dynamic> map) => Alert(
        id: map['id'] as String,
        deviceId: map['device_id'] as String,
        alertType: _parseAlertType(map['alert_type'] as String?),
        lat: (map['lat'] as num?)?.toDouble(),
        lng: (map['lng'] as num?)?.toDouble(),
        triggeredAt: DateTime.parse(map['triggered_at'] as String),
        acknowledged: (map['acknowledged'] as int?) == 1,
        resolvedAt: map['resolved_at'] != null
            ? DateTime.parse(map['resolved_at'] as String)
            : null,
        isSynced: (map['is_synced'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'device_id': deviceId,
        'alert_type': alertType.name,
        'lat': lat,
        'lng': lng,
        'triggered_at': triggeredAt.toIso8601String(),
        'acknowledged': acknowledged ? 1 : 0,
        'resolved_at': resolvedAt?.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  // ── Copy ──────────────────────────────────────────────────────────────────

  Alert copyWith({
    String? id,
    String? deviceId,
    AlertType? alertType,
    double? lat,
    double? lng,
    DateTime? triggeredAt,
    bool? acknowledged,
    DateTime? resolvedAt,
    bool? isSynced,
  }) =>
      Alert(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        alertType: alertType ?? this.alertType,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        triggeredAt: triggeredAt ?? this.triggeredAt,
        acknowledged: acknowledged ?? this.acknowledged,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        isSynced: isSynced ?? this.isSynced,
      );

  static AlertType _parseAlertType(String? raw) => switch (raw) {
        'sos' => AlertType.sos,
        'fall' => AlertType.fall,
        'fight' => AlertType.fight,
        'scream' => AlertType.scream,
        'keyword' => AlertType.keyword,
        'deviation' => AlertType.deviation,
        'deadManSwitch' => AlertType.deadManSwitch,
        'traceurSos' => AlertType.traceurSos,
        'lowBattery' => AlertType.lowBattery,
        'emergencyRunning' => AlertType.emergencyRunning,
        _ => AlertType.sos,
      };

  @override
  String toString() => 'Alert($alertType @ $triggeredAt)';
}
