/// EmergencyContact model — a person to notify during an alert.
library;

class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final bool isSmsEnabled;
  final bool isPushEnabled;

  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.isSmsEnabled = true,
    this.isPushEnabled = true,
  });

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        isSmsEnabled: json['is_sms_enabled'] as bool? ?? true,
        isPushEnabled: json['is_push_enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'is_sms_enabled': isSmsEnabled,
        'is_push_enabled': isPushEnabled,
      };

  // ── SQLite Map ────────────────────────────────────────────────────────────

  factory EmergencyContact.fromMap(Map<String, dynamic> map) =>
      EmergencyContact(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String,
        email: map['email'] as String?,
        isSmsEnabled: (map['is_sms_enabled'] as int?) == 1,
        isPushEnabled: (map['is_push_enabled'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'email': email,
        'is_sms_enabled': isSmsEnabled ? 1 : 0,
        'is_push_enabled': isPushEnabled ? 1 : 0,
      };

  // ── Copy ──────────────────────────────────────────────────────────────────

  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    bool? isSmsEnabled,
    bool? isPushEnabled,
  }) =>
      EmergencyContact(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        isSmsEnabled: isSmsEnabled ?? this.isSmsEnabled,
        isPushEnabled: isPushEnabled ?? this.isPushEnabled,
      );

  @override
  String toString() => 'EmergencyContact($name, $phone)';
}
