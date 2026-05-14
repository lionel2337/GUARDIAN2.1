/// Position model — a single GPS reading from a device or traceur.
library;

class Position {
  final String id;
  final String deviceId;
  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final int? battery;
  final double? altitude;
  final double? accuracy;
  final DateTime timestamp;
  final bool isSynced;

  const Position({
    required this.id,
    required this.deviceId,
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    this.battery,
    this.altitude,
    this.accuracy,
    required this.timestamp,
    this.isSynced = false,
  });

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        id: json['id'] as String,
        deviceId: json['device_id'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        speed: (json['speed'] as num?)?.toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        battery: json['battery'] as int?,
        altitude: (json['altitude'] as num?)?.toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        isSynced: true, // came from Supabase so already synced
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'heading': heading,
        'battery': battery,
        'altitude': altitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory Position.fromMap(Map<String, dynamic> map) => Position(
        id: map['id'] as String,
        deviceId: map['device_id'] as String,
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        speed: (map['speed'] as num?)?.toDouble(),
        heading: (map['heading'] as num?)?.toDouble(),
        battery: map['battery'] as int?,
        altitude: (map['altitude'] as num?)?.toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        isSynced: (map['is_synced'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'device_id': deviceId,
        'lat': lat,
        'lng': lng,
        'speed': speed,
        'heading': heading,
        'battery': battery,
        'altitude': altitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  // ── Copy ──────────────────────────────────────────────────────────────────

  Position copyWith({
    String? id,
    String? deviceId,
    double? lat,
    double? lng,
    double? speed,
    double? heading,
    int? battery,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
    bool? isSynced,
  }) =>
      Position(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        speed: speed ?? this.speed,
        heading: heading ?? this.heading,
        battery: battery ?? this.battery,
        altitude: altitude ?? this.altitude,
        accuracy: accuracy ?? this.accuracy,
        timestamp: timestamp ?? this.timestamp,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  String toString() =>
      'Position($lat, $lng @ ${timestamp.toIso8601String()})';
}
