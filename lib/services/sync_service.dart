/// Sync service — background synchronization between SQLite and Supabase.
///
/// Uses WorkManager to periodically upload pending data and download
/// fresh risk zones / community reports.
library;

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../models/community_report.dart';

import '../models/risk_zone.dart';
import '../utils/constants.dart';
import 'local_database_service.dart';

class SyncService {
  // Task names for WorkManager
  static const String periodicSyncTask = 'guardians_periodic_sync';
  static const String syncPositionsTask = 'sync_positions';
  static const String syncAlertsTask = 'sync_alerts';
  static const String syncReportsTask = 'sync_reports';
  static const String fetchRemoteTask = 'fetch_remote';
  static const String heartbeatTask = 'send_heartbeat';

  final _db = LocalDatabaseService.instance;
  SupabaseClient get _supabase => Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════════════════
  // Full sync (called periodically)
  // ══════════════════════════════════════════════════════════════════════════

  /// Run all sync tasks in sequence.
  Future<void> runFullSync() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    await syncPendingPositions();
    await syncPendingAlerts();
    await syncPendingReports();
    await fetchRemoteData();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Upload: Positions
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> syncPendingPositions() async {
    try {
      final positions = await _db.getUnsyncedPositions(limit: 50);
      if (positions.isEmpty) return;

      // Batch insert.
      final batch = positions.map((p) => p.toJson()).toList();
      await _supabase.from(Tables.positions).upsert(batch);

      // Mark as synced.
      for (final pos in positions) {
        await _db.markPositionSynced(pos.id);
      }
    } catch (e) {
      // Will retry on next cycle.
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Upload: Alerts
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> syncPendingAlerts() async {
    try {
      final alerts = await _db.getUnsyncedAlerts(limit: 50);
      if (alerts.isEmpty) return;

      final batch = alerts.map((a) => a.toJson()).toList();
      await _supabase.from(Tables.alerts).upsert(batch);

      for (final alert in alerts) {
        await _db.markAlertSynced(alert.id);
      }
    } catch (e) {
      // Will retry.
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Upload: Community Reports
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> syncPendingReports() async {
    try {
      final reports = await _db.getUnsyncedReports(limit: 50);
      if (reports.isEmpty) return;

      final batch = reports.map((r) => r.toJson()).toList();
      await _supabase.from(Tables.communityReports).upsert(batch);

      for (final report in reports) {
        await _db.markReportSynced(report.id);
      }
    } catch (e) {
      // Will retry.
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Upload: Generic pending sync queue
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> processPendingSyncQueue() async {
    try {
      final items = await _db.getAllPendingSyncItems(limit: 100);
      if (items.isEmpty) return;

      for (final item in items) {
        try {
          final tableName = item['table_name'] as String;
          final operation = item['operation'] as String;
          final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

          switch (operation) {
            case 'INSERT':
              await _supabase.from(tableName).insert(data);
              break;
            case 'UPSERT':
              await _supabase.from(tableName).upsert(data);
              break;
            case 'UPDATE':
              final recordId = item['record_id'] as String;
              await _supabase.from(tableName).update(data).eq('id', recordId);
              break;
            case 'DELETE':
              final recordId = item['record_id'] as String;
              await _supabase.from(tableName).delete().eq('id', recordId);
              break;
          }

          // Success — remove from queue.
          await _db.removePendingSync(item['id'] as String);
        } catch (e) {
          // Increment attempt counter.
          await _db.incrementSyncAttempt(item['id'] as String);
        }
      }
    } catch (e) {
      // Silent failure — will retry on next cycle.
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Download: Risk Zones & Community Reports
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchRemoteData() async {
    try {
      // Fetch risk zones and cache locally.
      final zoneData = await _supabase.from(Tables.riskZones).select();
      final zones =
          (zoneData as List).map((e) => RiskZone.fromJson(e)).toList();
      if (zones.isNotEmpty) {
        await _db.replaceAllRiskZones(zones);
      }

      // Fetch active community reports.
      final now = DateTime.now().toIso8601String();
      final reportData = await _supabase
          .from(Tables.communityReports)
          .select()
          .gt('expires_at', now)
          .order('created_at', ascending: false)
          .limit(100);
      for (final r in reportData as List) {
        final report = CommunityReport.fromJson(r);
        await _db.insertCommunityReport(report);
      }

      // Cleanup expired reports.
      await _db.purgeExpiredReports();
    } catch (e) {
      // Offline — use whatever is cached locally.
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Heartbeat (Dead Man Switch)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> sendHeartbeat() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Find active journey and update its heartbeat.
      final journey = await _db.getActiveJourney(userId);
      if (journey == null) return;

      await _supabase.from(Tables.monitoredJourneys).update({
        'last_position_at': DateTime.now().toIso8601String(),
      }).eq('id', journey.id);
    } catch (e) {
      // Best-effort — if offline, the Dead Man Switch will fire server-side.
    }
  }
}
