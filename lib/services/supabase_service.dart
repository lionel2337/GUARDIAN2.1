/// Supabase service — cloud synchronization, authentication, and realtime.
///
/// This is the SECONDARY data store. All writes go to SQLite first,
/// then are synced here. Reads prefer local data with background refresh.
library;

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../models/alert.dart';
import '../models/community_report.dart';
import '../models/device.dart';
import '../models/emergency_contact.dart';
import '../models/monitored_journey.dart';
import '../models/position.dart';
import '../models/risk_zone.dart';
import '../utils/constants.dart';
import '../utils/supabase_config.dart';
import 'local_database_service.dart';



class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;
  final _localDb = LocalDatabaseService.instance;

  // ══════════════════════════════════════════════════════════════════════════
  // Authentication
  // ══════════════════════════════════════════════════════════════════════════

  /// Current Supabase user (may be null if not authenticated).
  User? get currentUser => _client.auth.currentUser;

  /// Whether a user is currently signed in.
  bool get isAuthenticated => currentUser != null;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in anonymously for quick access without registration.
  Future<AuthResponse> signInAnonymously() async {
    return _client.auth.signInAnonymously();
  }

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Create a new account with email, password, full name, and phone.
  Future<AuthResponse> signUp(
      String email, String password, String fullName, String phone) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );

    // NE PAS insérer manuellement dans public.users —
    // le trigger handle_new_user() s'en charge automatiquement
    // côté Supabase dès que auth.signUp() réussit.
    return response;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Positions
  // ══════════════════════════════════════════════════════════════════════════

  /// Insert a position into Supabase. Falls back to the offline queue.
  Future<void> insertPosition(Position position) async {
    try {
      await _client.from(Tables.positions).insert(position.toJson());
    } catch (e) {
      // Queue for later sync.
      await _localDb.addToPendingSync(
        tableName: Tables.positions,
        recordId: position.id,
        operation: 'INSERT',
        data: position.toJson(),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Alerts
  // ══════════════════════════════════════════════════════════════════════════

  /// Insert an alert into Supabase. Falls back to the offline queue.
  Future<void> insertAlert(Alert alert) async {
    try {
      await _client.from(Tables.alerts).insert(alert.toJson());
    } catch (e) {
      await _localDb.addToPendingSync(
        tableName: Tables.alerts,
        recordId: alert.id,
        operation: 'INSERT',
        data: alert.toJson(),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Devices
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch all devices owned by the current user.
  Future<List<Device>> fetchUserDevices() async {
    if (currentUser == null) return [];
    final data = await _client
        .from(Tables.devices)
        .select()
        .eq('owner_id', currentUser!.id)
        .order('created_at');
    return (data as List).map((e) => Device.fromJson(e)).toList();
  }

  /// Pair a new traceur device using a pairing code.
  Future<Device?> pairDevice(String pairingCode) async {
    if (currentUser == null) return null;

    // Look for an unclaimed device with this code.
    final data = await _client
        .from(Tables.devices)
        .select()
        .eq('imei', pairingCode)
        .maybeSingle();

    if (data == null) return null;

    // Claim it.
    await _client.from(Tables.devices).update({
      'owner_id': currentUser!.id,
      'is_active': true,
    }).eq('id', data['id']);

    return Device.fromJson({...data, 'owner_id': currentUser!.id});
  }

  /// Update the battery level of a device.
  Future<void> updateDeviceBattery(String deviceId, int batteryLevel) async {
    await _client.from(Tables.devices).update({
      'last_battery': batteryLevel,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', deviceId);
  }

  /// Remove (unpair) a device.
  Future<void> removeDevice(String deviceId) async {
    await _client.from(Tables.devices).update({
      'owner_id': null,
      'is_active': false,
    }).eq('id', deviceId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Risk Zones
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch all risk zones from the server for local caching.
  Future<List<RiskZone>> fetchRiskZones() async {
    final data = await _client.from(Tables.riskZones).select();
    return (data as List).map((e) => RiskZone.fromJson(e)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Community Reports
  // ══════════════════════════════════════════════════════════════════════════

  /// Insert a community report.
  Future<void> insertCommunityReport(CommunityReport report) async {
    try {
      await _client.from(Tables.communityReports).insert(report.toJson());
    } catch (e) {
      await _localDb.addToPendingSync(
        tableName: Tables.communityReports,
        recordId: report.id,
        operation: 'INSERT',
        data: report.toJson(),
      );
    }
  }

  /// Fetch active community reports (less than 2 hours old).
  Future<List<CommunityReport>> fetchActiveCommunityReports() async {
    final cutoff =
    DateTime.now().subtract(AppGeo.reportExpiry).toIso8601String();
    final data = await _client
        .from(Tables.communityReports)
        .select()
        .gt('expires_at', DateTime.now().toIso8601String())
        .gt('created_at', cutoff)
        .order('created_at', ascending: false);
    return (data as List).map((e) => CommunityReport.fromJson(e)).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Monitored Journeys
  // ══════════════════════════════════════════════════════════════════════════

  /// Create or update a monitored journey.
  Future<void> updateMonitoredJourney(MonitoredJourney journey) async {
    try {
      await _client
          .from(Tables.monitoredJourneys)
          .upsert(journey.toJson());
    } catch (e) {
      await _localDb.addToPendingSync(
        tableName: Tables.monitoredJourneys,
        recordId: journey.id,
        operation: 'UPSERT',
        data: journey.toJson(),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Emergency Contacts
  // ══════════════════════════════════════════════════════════════════════════

  /// Add or update an emergency contact.
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    await _client
        .from(Tables.emergencyContacts)
        .upsert(contact.toJson());
  }

  /// Fetch all emergency contacts for the current user.
  Future<List<EmergencyContact>> fetchEmergencyContacts() async {
    if (currentUser == null) return [];
    final data = await _client
        .from(Tables.emergencyContacts)
        .select()
        .eq('user_id', currentUser!.id);
    return (data as List).map((e) => EmergencyContact.fromJson(e)).toList();
  }

  /// Delete an emergency contact.
  Future<void> deleteEmergencyContact(String id) async {
    await _client.from(Tables.emergencyContacts).delete().eq('id', id);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Realtime Subscriptions
  // ══════════════════════════════════════════════════════════════════════════

  /// Subscribe to realtime position updates for a specific device.
  RealtimeChannel subscribeToDevicePositions(
      String deviceId,
      void Function(Position) onPosition,
      ) {
    return _client
        .channel('positions:$deviceId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: Tables.positions,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'device_id',
        value: deviceId,
      ),
      callback: (payload) {
        final pos = Position.fromJson(payload.newRecord);
        onPosition(pos);
      },
    )
        .subscribe();
  }

  /// Subscribe to realtime alert events for a specific device.
  RealtimeChannel subscribeToAlerts(
      String deviceId,
      void Function(Alert) onAlert,
      ) {
    return _client
        .channel('alerts:$deviceId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: Tables.alerts,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'device_id',
        value: deviceId,
      ),
      callback: (payload) {
        final alert = Alert.fromJson(payload.newRecord);
        onAlert(alert);
      },
    )
        .subscribe();
  }

  /// Subscribe to realtime community reports.
  RealtimeChannel subscribeToCommunityReports(
      void Function(CommunityReport) onReport,
      ) {
    return _client
        .channel('community_reports')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: Tables.communityReports,
      callback: (payload) {
        final report = CommunityReport.fromJson(payload.newRecord);
        onReport(report);
      },
    )
        .subscribe();
  }

  /// Unsubscribe from a realtime channel.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Storage (Evidence)
  // ══════════════════════════════════════════════════════════════════════════

  /// Upload evidence (audio recording, screenshot) to the evidence bucket.
  Future<String?> uploadEvidence(String path, Uint8List data) async {
    try {
      await _client.storage
          .from(SupabaseConfig.storageBucket)
          .uploadBinary(path, data);
      return getEvidenceUrl(path);
    } catch (e) {
      return null;
    }
  }

  /// Get the public URL for an evidence file.
  String getEvidenceUrl(String path) {
    return _client.storage
        .from(SupabaseConfig.storageBucket)
        .getPublicUrl(path);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Heartbeat (Dead Man Switch)
  // ══════════════════════════════════════════════════════════════════════════

  /// Send a heartbeat to Supabase for Dead Man Switch monitoring.
  Future<void> sendHeartbeat(String journeyId) async {
    await _client.from(Tables.monitoredJourneys).update({
      'last_position_at': DateTime.now().toIso8601String(),
    }).eq('id', journeyId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Traceur Commands
  // ══════════════════════════════════════════════════════════════════════════

  /// Send a command to a traceur device via Supabase Realtime.
  Future<void> sendCommandToDevice(String deviceId, String command) async {
    final channel = _client.channel('device_commands:$deviceId');
    channel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        channel.sendBroadcastMessage(
          event: 'command',
          payload: {
            'device_id': deviceId,
            'command': command,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        // Unsubscribe after sending.
        Future.delayed(const Duration(seconds: 2), () {
          _client.removeChannel(channel);
        });
      }
    });
  }
}