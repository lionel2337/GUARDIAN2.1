/// Guardians AI — Application entry point.
///
/// Initialises Supabase, the local SQLite database, background sync,
/// and the notification channel before handing off to [GuardiansApp].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'services/local_database_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'utils/supabase_config.dart';

// ── Background task dispatcher (top-level function for WorkManager) ──────────

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final syncService = SyncService();
    switch (taskName) {
      case SyncService.syncPositionsTask:
        await syncService.syncPendingPositions();
        break;
      case SyncService.syncAlertsTask:
        await syncService.syncPendingAlerts();
        break;
      case SyncService.syncReportsTask:
        await syncService.syncPendingReports();
        break;
      case SyncService.fetchRemoteTask:
        await syncService.fetchRemoteData();
        break;
      case SyncService.heartbeatTask:
        await syncService.sendHeartbeat();
        break;
      default:
        // Run all sync tasks as a periodic catchall.
        await syncService.runFullSync();
    }
    return true;
  });
}

// ── Main ─────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation on mobile.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark status bar for the dark theme.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E21),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 1 ── Supabase
  await Supabase.initialize(
    url: SupabaseConfig.projectUrl,
    anonKey: SupabaseConfig.anonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // 2 ── Local SQLite database
  await LocalDatabaseService.instance.initialize();

  // 3 ── Notification channel
  await NotificationService.instance.initialize();

  // 4 ── Background sync (WorkManager)
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'guardians-sync',
    SyncService.periodicSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  // 5 ── Run the app inside a ProviderScope (Riverpod root).
  runApp(const ProviderScope(child: GuardiansApp()));
}
