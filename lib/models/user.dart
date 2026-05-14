/// User model — represents a registered or anonymous Guardians AI user.
library;

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    this.email,
    this.phone,
    required this.fullName,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        fullName: json['full_name'] as String? ?? 'Anonymous',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as String,
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        fullName: map['full_name'] as String? ?? 'Anonymous',
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => toJson();

  // ── Copy ──────────────────────────────────────────────────────────────────

  AppUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AppUser(
        id: id ?? this.id,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        fullName: fullName ?? this.fullName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() => 'AppUser(id: $id, fullName: $fullName)';
}
