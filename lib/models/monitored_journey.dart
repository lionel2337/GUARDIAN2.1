/// MonitoredJourney model — a trip being actively tracked for safety.
library;

enum JourneyStatus { pending, active, completed, cancelled, alerted }

class MonitoredJourney {
  final String id;
  final String userId;
  final String deviceId;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final int plannedDurationMinutes;
  final DateTime? startedAt;
  final DateTime? expectedArrival;
  final DateTime? lastPositionAt;
  final JourneyStatus status;
  final int deviationCount;
  final bool isSynced;

  const MonitoredJourney({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.plannedDurationMinutes,
    this.startedAt,
    this.expectedArrival,
    this.lastPositionAt,
    this.status = JourneyStatus.pending,
    this.deviationCount = 0,
    this.isSynced = false,
  });

  /// Whether the journey is actively being tracked.
  bool get isOngoing =>
      status == JourneyStatus.active || status == JourneyStatus.pending;

  /// Duration since the journey started.
  Duration get elapsed =>
      startedAt != null ? DateTime.now().difference(startedAt!) : Duration.zero;

  /// Whether the user is late.
  bool get isLate =>
      expectedArrival != null && DateTime.now().isAfter(expectedArrival!);

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory MonitoredJourney.fromJson(Map<String, dynamic> json) =>
      MonitoredJourney(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        deviceId: json['device_id'] as String,
        originLat: (json['origin_lat'] as num).toDouble(),
        originLng: (json['origin_lng'] as num).toDouble(),
        destLat: (json['dest_lat'] as num).toDouble(),
        destLng: (json['dest_lng'] as num).toDouble(),
        plannedDurationMinutes: json['planned_duration'] as int,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        expectedArrival: json['expected_arrival'] != null
            ? DateTime.parse(json['expected_arrival'] as String)
            : null,
        lastPositionAt: json['last_position_at'] != null
            ? DateTime.parse(json['last_position_at'] as String)
            : null,
        status: _parseStatus(json['status'] as String?),
        deviationCount: json['deviation_count'] as int? ?? 0,
        isSynced: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'device_id': deviceId,
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
        'planned_duration': plannedDurationMinutes,
        'started_at': startedAt?.toIso8601String(),
        'expected_arrival': expectedArrival?.toIso8601String(),
        'last_position_at': lastPositionAt?.toIso8601String(),
        'status': status.name,
        'deviation_count': deviationCount,
      };

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory MonitoredJourney.fromMap(Map<String, dynamic> map) =>
      MonitoredJourney(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        deviceId: map['device_id'] as String,
        originLat: (map['origin_lat'] as num).toDouble(),
        originLng: (map['origin_lng'] as num).toDouble(),
        destLat: (map['dest_lat'] as num).toDouble(),
        destLng: (map['dest_lng'] as num).toDouble(),
        plannedDurationMinutes: map['planned_duration'] as int,
        startedAt: map['started_at'] != null
            ? DateTime.parse(map['started_at'] as String)
            : null,
        expectedArrival: map['expected_arrival'] != null
            ? DateTime.parse(map['expected_arrival'] as String)
            : null,
        lastPositionAt: map['last_position_at'] != null
            ? DateTime.parse(map['last_position_at'] as String)
            : null,
        status: _parseStatus(map['status'] as String?),
        deviationCount: map['deviation_count'] as int? ?? 0,
        isSynced: (map['is_synced'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'device_id': deviceId,
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
        'planned_duration': plannedDurationMinutes,
        'started_at': startedAt?.toIso8601String(),
        'expected_arrival': expectedArrival?.toIso8601String(),
        'last_position_at': lastPositionAt?.toIso8601String(),
        'status': status.name,
        'deviation_count': deviationCount,
        'is_synced': isSynced ? 1 : 0,
      };

  // ── Copy ──────────────────────────────────────────────────────────────────

  MonitoredJourney copyWith({
    String? id,
    String? userId,
    String? deviceId,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    int? plannedDurationMinutes,
    DateTime? startedAt,
    DateTime? expectedArrival,
    DateTime? lastPositionAt,
    JourneyStatus? status,
    int? deviationCount,
    bool? isSynced,
  }) =>
      MonitoredJourney(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        deviceId: deviceId ?? this.deviceId,
        originLat: originLat ?? this.originLat,
        originLng: originLng ?? this.originLng,
        destLat: destLat ?? this.destLat,
        destLng: destLng ?? this.destLng,
        plannedDurationMinutes:
            plannedDurationMinutes ?? this.plannedDurationMinutes,
        startedAt: startedAt ?? this.startedAt,
        expectedArrival: expectedArrival ?? this.expectedArrival,
        lastPositionAt: lastPositionAt ?? this.lastPositionAt,
        status: status ?? this.status,
        deviationCount: deviationCount ?? this.deviationCount,
        isSynced: isSynced ?? this.isSynced,
      );

  static JourneyStatus _parseStatus(String? raw) => switch (raw) {
        'active' => JourneyStatus.active,
        'completed' => JourneyStatus.completed,
        'cancelled' => JourneyStatus.cancelled,
        'alerted' => JourneyStatus.alerted,
        _ => JourneyStatus.pending,
      };

  @override
  String toString() => 'MonitoredJourney($id, $status)';
}
