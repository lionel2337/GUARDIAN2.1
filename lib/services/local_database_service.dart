/// Local SQLite database service — the PRIMARY data store.
///
/// Every write goes here first, then is queued for Supabase sync.
/// The pending_sync table acts as an outbox for offline operations.
library;

import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/alert.dart';
import '../models/community_report.dart';
import '../models/device.dart';
import '../models/emergency_contact.dart';
import '../models/monitored_journey.dart';
import '../models/position.dart';
import '../models/risk_zone.dart';
import '../models/user.dart';

const _dbName = 'guardians_ai.db';
const _dbVersion = 1;
const _uuid = Uuid();

class LocalDatabaseService {
  LocalDatabaseService._();
  static final LocalDatabaseService instance = LocalDatabaseService._();

  Database? _db;

  Database get db {
    if (_db == null) throw StateError('Database not initialised. Call initialize() first.');
    return _db!;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Initialisation
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    final dbPath = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT,
        phone TEXT,
        full_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        device_name TEXT NOT NULL,
        device_type TEXT NOT NULL DEFAULT 'mobile',
        imei TEXT,
        last_battery INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        last_seen TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE positions (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        speed REAL,
        heading REAL,
        battery INTEGER,
        altitude REAL,
        accuracy REAL,
        timestamp TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE alerts (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        alert_type TEXT NOT NULL,
        lat REAL,
        lng REAL,
        triggered_at TEXT NOT NULL,
        acknowledged INTEGER NOT NULL DEFAULT 0,
        resolved_at TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE emergency_contacts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        is_sms_enabled INTEGER NOT NULL DEFAULT 1,
        is_push_enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    batch.execute('''
      CREATE TABLE risk_zones (
        id TEXT PRIMARY KEY,
        zone_name TEXT NOT NULL,
        center_lat REAL NOT NULL,
        center_lng REAL NOT NULL,
        radius_km REAL NOT NULL,
        risk_score REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE community_reports (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        report_type TEXT NOT NULL,
        description TEXT,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE monitored_journeys (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        origin_lat REAL NOT NULL,
        origin_lng REAL NOT NULL,
        dest_lat REAL NOT NULL,
        dest_lng REAL NOT NULL,
        planned_duration INTEGER NOT NULL,
        started_at TEXT,
        expected_arrival TEXT,
        last_position_at TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        deviation_count INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE pending_sync (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Indexes for performance
    batch.execute('CREATE INDEX idx_positions_device ON positions(device_id)');
    batch.execute('CREATE INDEX idx_positions_synced ON positions(is_synced)');
    batch.execute('CREATE INDEX idx_alerts_device ON alerts(device_id)');
    batch.execute('CREATE INDEX idx_alerts_synced ON alerts(is_synced)');
    batch.execute('CREATE INDEX idx_pending_sync_table ON pending_sync(table_name)');
    batch.execute('CREATE INDEX idx_community_reports_expires ON community_reports(expires_at)');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here.
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Generic helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// Generate a new UUID v4.
  String newId() => _uuid.v4();

  // ══════════════════════════════════════════════════════════════════════════
  // Users
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> upsertUser(AppUser user) async {
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AppUser?> getUser(String id) async {
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Devices
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> upsertDevice(Device device) async {
    await db.insert('devices', device.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Device>> getDevicesByOwner(String ownerId) async {
    final rows = await db.query('devices',
        where: 'owner_id = ?', whereArgs: [ownerId]);
    return rows.map(Device.fromMap).toList();
  }

  Future<Device?> getDevice(String id) async {
    final rows = await db.query('devices', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Device.fromMap(rows.first);
  }

  Future<void> deleteDevice(String id) async {
    await db.delete('devices', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Positions
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> insertPosition(Position position) async {
    await db.insert('positions', position.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Position>> getPositionsByDevice(String deviceId,
      {int limit = 100}) async {
    final rows = await db.query('positions',
        where: 'device_id = ?',
        whereArgs: [deviceId],
        orderBy: 'timestamp DESC',
        limit: limit);
    return rows.map(Position.fromMap).toList();
  }

  Future<Position?> getLatestPosition(String deviceId) async {
    final rows = await db.query('positions',
        where: 'device_id = ?',
        whereArgs: [deviceId],
        orderBy: 'timestamp DESC',
        limit: 1);
    if (rows.isEmpty) return null;
    return Position.fromMap(rows.first);
  }

  Future<List<Position>> getUnsyncedPositions({int limit = 50}) async {
    final rows = await db.query('positions',
        where: 'is_synced = 0', orderBy: 'timestamp ASC', limit: limit);
    return rows.map(Position.fromMap).toList();
  }

  Future<void> markPositionSynced(String id) async {
    await db.update('positions', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Alerts
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> insertAlert(Alert alert) async {
    await db.insert('alerts', alert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Alert>> getAlerts({int limit = 100}) async {
    final rows = await db.query('alerts',
        orderBy: 'triggered_at DESC', limit: limit);
    return rows.map(Alert.fromMap).toList();
  }

  Future<List<Alert>> getActiveAlerts() async {
    final rows = await db.query('alerts',
        where: 'acknowledged = 0 AND resolved_at IS NULL',
        orderBy: 'triggered_at DESC');
    return rows.map(Alert.fromMap).toList();
  }

  Future<List<Alert>> getUnsyncedAlerts({int limit = 50}) async {
    final rows = await db.query('alerts',
        where: 'is_synced = 0', orderBy: 'triggered_at ASC', limit: limit);
    return rows.map(Alert.fromMap).toList();
  }

  Future<void> acknowledgeAlert(String id) async {
    await db.update('alerts', {'acknowledged': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resolveAlert(String id) async {
    await db.update(
        'alerts',
        {
          'acknowledged': 1,
          'resolved_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<void> markAlertSynced(String id) async {
    await db.update('alerts', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Emergency Contacts
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> upsertEmergencyContact(EmergencyContact contact) async {
    await db.insert('emergency_contacts', contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EmergencyContact>> getEmergencyContacts(String userId) async {
    final rows = await db.query('emergency_contacts',
        where: 'user_id = ?', whereArgs: [userId]);
    return rows.map(EmergencyContact.fromMap).toList();
  }

  Future<void> deleteEmergencyContact(String id) async {
    await db.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Risk Zones
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> upsertRiskZone(RiskZone zone) async {
    await db.insert('risk_zones', zone.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RiskZone>> getAllRiskZones() async {
    final rows = await db.query('risk_zones');
    return rows.map(RiskZone.fromMap).toList();
  }

  Future<void> replaceAllRiskZones(List<RiskZone> zones) async {
    await db.transaction((txn) async {
      await txn.delete('risk_zones');
      for (final zone in zones) {
        await txn.insert('risk_zones', zone.toMap());
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Community Reports
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> insertCommunityReport(CommunityReport report) async {
    await db.insert('community_reports', report.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CommunityReport>> getActiveCommunityReports() async {
    final now = DateTime.now().toIso8601String();
    final rows = await db.query('community_reports',
        where: 'expires_at > ?', whereArgs: [now],
        orderBy: 'created_at DESC');
    return rows.map(CommunityReport.fromMap).toList();
  }

  Future<List<CommunityReport>> getUnsyncedReports({int limit = 50}) async {
    final rows = await db.query('community_reports',
        where: 'is_synced = 0', orderBy: 'created_at ASC', limit: limit);
    return rows.map(CommunityReport.fromMap).toList();
  }

  Future<void> markReportSynced(String id) async {
    await db.update('community_reports', {'is_synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Monitored Journeys
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> upsertMonitoredJourney(MonitoredJourney journey) async {
    await db.insert('monitored_journeys', journey.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<MonitoredJourney?> getActiveJourney(String userId) async {
    final rows = await db.query('monitored_journeys',
        where: "user_id = ? AND status IN ('pending', 'active')",
        whereArgs: [userId],
        limit: 1);
    if (rows.isEmpty) return null;
    return MonitoredJourney.fromMap(rows.first);
  }

  Future<List<MonitoredJourney>> getJourneyHistory(String userId,
      {int limit = 50}) async {
    final rows = await db.query('monitored_journeys',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'started_at DESC',
        limit: limit);
    return rows.map(MonitoredJourney.fromMap).toList();
  }

  Future<void> updateJourneyStatus(String id, JourneyStatus status) async {
    await db.update('monitored_journeys', {'status': status.name},
        where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Pending Sync Queue (offline outbox)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> addToPendingSync({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    await db.insert('pending_sync', {
      'id': newId(),
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': jsonEncode(data),
      'created_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems(String tableName,
      {int limit = 50}) async {
    return db.query('pending_sync',
        where: 'table_name = ? AND attempts < 10',
        whereArgs: [tableName],
        orderBy: 'created_at ASC',
        limit: limit);
  }

  Future<List<Map<String, dynamic>>> getAllPendingSyncItems(
      {int limit = 200}) async {
    return db.query('pending_sync',
        where: 'attempts < 10',
        orderBy: 'created_at ASC',
        limit: limit);
  }

  Future<void> incrementSyncAttempt(String id) async {
    await db.rawUpdate(
        'UPDATE pending_sync SET attempts = attempts + 1 WHERE id = ?', [id]);
  }

  Future<void> removePendingSync(String id) async {
    await db.delete('pending_sync', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPendingSyncCount() async {
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM pending_sync WHERE attempts < 10');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Habit learning (for RiskScoringEngine)
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns all positions for a device on a specific day-of-week + hour range
  /// to help the risk scoring engine learn habitual routes.
  Future<List<Position>> getHabitualPositions(
      String deviceId, int dayOfWeek, int hourStart, int hourEnd) async {
    final rows = await db.rawQuery('''
      SELECT * FROM positions
      WHERE device_id = ?
        AND CAST(strftime('%w', timestamp) AS INTEGER) = ?
        AND CAST(strftime('%H', timestamp) AS INTEGER) >= ?
        AND CAST(strftime('%H', timestamp) AS INTEGER) < ?
      ORDER BY timestamp DESC
      LIMIT 500
    ''', [deviceId, dayOfWeek, hourStart, hourEnd]);
    return rows.map(Position.fromMap).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Cleanup
  // ══════════════════════════════════════════════════════════════════════════

  /// Purge positions older than [days] that have been synced.
  Future<int> purgeOldPositions({int days = 30}) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return db.delete('positions',
        where: 'timestamp < ? AND is_synced = 1', whereArgs: [cutoff]);
  }

  /// Purge expired community reports.
  Future<int> purgeExpiredReports() async {
    final now = DateTime.now().toIso8601String();
    return db.delete('community_reports',
        where: 'expires_at < ? AND is_synced = 1', whereArgs: [now]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
