/// Connectivity provider — exposes network status.
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class ConnectivityState {
  final bool isOnline;
  final DateTime? lastOnlineAt;
  final int pendingSyncCount;

  const ConnectivityState({
    this.isOnline = true,
    this.lastOnlineAt,
    this.pendingSyncCount = 0,
  });

  ConnectivityState copyWith({
    bool? isOnline,
    DateTime? lastOnlineAt,
    int? pendingSyncCount,
  }) =>
      ConnectivityState(
        isOnline: isOnline ?? this.isOnline,
        lastOnlineAt: lastOnlineAt ?? this.lastOnlineAt,
        pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      );

  String get lastSyncLabel {
    if (lastOnlineAt == null) return 'Never';
    final diff = DateTime.now().difference(lastOnlineAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier() : super(const ConnectivityState()) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;
  final _connectivity = Connectivity();

  void _init() {
    // Check current status.
    _connectivity.checkConnectivity().then((results) {
      _update(results);
    });

    // Listen for changes.
    _sub = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = !results.contains(ConnectivityResult.none);

    if (online && !state.isOnline) {
      // Just came back online — trigger immediate sync.
      state = state.copyWith(
        isOnline: true,
        lastOnlineAt: DateTime.now(),
      );
      _triggerImmediateSync();
    } else {
      state = state.copyWith(
        isOnline: online,
        lastOnlineAt: online ? DateTime.now() : state.lastOnlineAt,
      );
    }
  }

  void _triggerImmediateSync() {
    SyncService().runFullSync();
  }

  void updatePendingCount(int count) {
    state = state.copyWith(pendingSyncCount: count);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(),
);

/// Convenience: is the device currently online?
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isOnline;
});
