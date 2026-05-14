/// CommunityReport model — a geolocated safety report from a user.
///
/// Reports expire after [AppGeo.reportExpiry] (2 hours) and are shown
/// on the map as warning markers.
library;

class CommunityReport {
  final String id;
  final String userId;
  final double lat;
  final double lng;
  final String reportType;
  final String? description;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool isSynced;

  const CommunityReport({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.reportType,
    this.description,
    required this.expiresAt,
    required this.createdAt,
    this.isSynced = false,
  });

  /// Whether this report has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory CommunityReport.fromJson(Map<String, dynamic> json) =>
      CommunityReport(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        reportType: json['report_type'] as String,
        description: json['description'] as String?,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        isSynced: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'lat': lat,
        'lng': lng,
        'report_type': reportType,
        'description': description,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory CommunityReport.fromMap(Map<String, dynamic> map) =>
      CommunityReport(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        reportType: map['report_type'] as String,
        description: map['description'] as String?,
        expiresAt: DateTime.parse(map['expires_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        isSynced: (map['is_synced'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'lat': lat,
        'lng': lng,
        'report_type': reportType,
        'description': description,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  // ── Copy ──────────────────────────────────────────────────────────────────

  CommunityReport copyWith({
    String? id,
    String? userId,
    double? lat,
    double? lng,
    String? reportType,
    String? description,
    DateTime? expiresAt,
    DateTime? createdAt,
    bool? isSynced,
  }) =>
      CommunityReport(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        reportType: reportType ?? this.reportType,
        description: description ?? this.description,
        expiresAt: expiresAt ?? this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  String toString() => 'CommunityReport($reportType @ $lat,$lng)';
}
