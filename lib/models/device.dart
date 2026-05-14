/// Device model — represents a traceur ESP32 or mobile phone device.
library;

enum DeviceType { mobile, traceur, watch }

class Device {
  final String id;
  final String ownerId;
  final String deviceName;
  final DeviceType deviceType;
  final String? imei;
  final int? lastBattery;
  final bool isActive;
  final DateTime? lastSeen;
  final DateTime createdAt;

  const Device({
    required this.id,
    required this.ownerId,
    required this.deviceName,
    required this.deviceType,
    this.imei,
    this.lastBattery,
    this.isActive = true,
    this.lastSeen,
    required this.createdAt,
  });

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        deviceName: json['device_name'] as String,
        deviceType: _parseDeviceType(json['device_type'] as String?),
        imei: json['imei'] as String?,
        lastBattery: json['last_battery'] as int?,
        isActive: json['is_active'] as bool? ?? true,
        lastSeen: json['last_seen'] != null
            ? DateTime.parse(json['last_seen'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'device_name': deviceName,
        'device_type': deviceType.name,
        'imei': imei,
        'last_battery': lastBattery,
        'is_active': isActive,
        'last_seen': lastSeen?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory Device.fromMap(Map<String, dynamic> map) => Device(
        id: map['id'] as String,
        ownerId: map['owner_id'] as String,
        deviceName: map['device_name'] as String,
        deviceType: _parseDeviceType(map['device_type'] as String?),
        imei: map['imei'] as String?,
        lastBattery: map['last_battery'] as int?,
        isActive: (map['is_active'] as int?) == 1,
        lastSeen: map['last_seen'] != null
            ? DateTime.parse(map['last_seen'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'owner_id': ownerId,
        'device_name': deviceName,
        'device_type': deviceType.name,
        'imei': imei,
        'last_battery': lastBattery,
        'is_active': isActive ? 1 : 0,
        'last_seen': lastSeen?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  // ── Copy ──────────────────────────────────────────────────────────────────

  Device copyWith({
    String? id,
    String? ownerId,
    String? deviceName,
    DeviceType? deviceType,
    String? imei,
    int? lastBattery,
    bool? isActive,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) =>
      Device(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        deviceName: deviceName ?? this.deviceName,
        deviceType: deviceType ?? this.deviceType,
        imei: imei ?? this.imei,
        lastBattery: lastBattery ?? this.lastBattery,
        isActive: isActive ?? this.isActive,
        lastSeen: lastSeen ?? this.lastSeen,
        createdAt: createdAt ?? this.createdAt,
      );

  static DeviceType _parseDeviceType(String? raw) => switch (raw) {
        'traceur' => DeviceType.traceur,
        'watch' => DeviceType.watch,
        _ => DeviceType.mobile,
      };

  /// Battery icon color helper.
  String get batteryLabel {
    if (lastBattery == null) return '??%';
    return '$lastBattery%';
  }

  @override
  String toString() => 'Device($deviceName, $deviceType)';
}
