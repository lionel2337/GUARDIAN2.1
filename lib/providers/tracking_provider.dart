/// Tracking provider — monitors active journeys with deviation detection.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../models/alert.dart';
import '../models/monitored_journey.dart';
import '../services/local_database_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

const _uuid = Uuid();

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class TrackingState {
  final MonitoredJourney? activeJourney;
  final LatLng? currentPosition;
  final bool isDeviated;
  final int deviationCount;
  final Duration elapsed;
  final bool isTracking;

  const TrackingState({
    this.activeJourney,
    this.currentPosition,
    this.isDeviated = false,
    this.deviationCount = 0,
    this.elapsed = Duration.zero,
    this.isTracking = false,
  });

  TrackingState copyWith({
    MonitoredJourney? activeJourney,
    LatLng? currentPosition,
    bool? isDeviated,
    int? deviationCount,
    Duration? elapsed,
    bool? isTracking,
  }) =>
      TrackingState(
        activeJourney: activeJourney ?? this.activeJourney,
        currentPosition: currentPosition ?? this.currentPosition,
        isDeviated: isDeviated ?? this.isDeviated,
        deviationCount: deviationCount ?? this.deviationCount,
        elapsed: elapsed ?? this.elapsed,
        isTracking: isTracking ?? this.isTracking,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier() : super(const TrackingState());

  final _db = LocalDatabaseService.instance;
  final _supabase = SupabaseService.instance;
  final _location = LocationService.instance;
  final _notifications = NotificationService.instance;

  StreamSubscription? _positionSub;
  Timer? _elapsedTimer;
  Timer? _heartbeatTimer;

  // Route points for deviation checking.
  List<LatLng> _routePoints = [];

  /// Start monitoring a journey.
  Future<void> startJourney({
    required LatLng origin,
    required LatLng destination,
    required int plannedDurationMinutes,
    required List<LatLng> routePoints,
    required String deviceId,
  }) async {
    final userId = _supabase.currentUser?.id ?? 'local';
    final now = DateTime.now();
    final journey = MonitoredJourney(
      id: _uuid.v4(),
      userId: userId,
      deviceId: deviceId,
      originLat: origin.latitude,
      originLng: origin.longitude,
      destLat: destination.latitude,
      destLng: destination.longitude,
      plannedDurationMinutes: plannedDurationMinutes,
      startedAt: now,
      expectedArrival: now.add(Duration(minutes: plannedDurationMinutes)),
      status: JourneyStatus.active,
    );

    _routePoints = routePoints;

    // Save locally + sync.
    await _db.upsertMonitoredJourney(journey);
    await _supabase.updateMonitoredJourney(journey);

    state = state.copyWith(
      activeJourney: journey,
      isTracking: true,
      deviationCount: 0,
      isDeviated: false,
    );

    // Start position tracking.
    _positionSub = _location
        .getLocationStream(distanceFilterMeters: 20)
        .listen(_onPositionUpdate);

    // Start elapsed timer.
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.activeJourney?.startedAt != null) {
        state = state.copyWith(
          elapsed: DateTime.now().difference(state.activeJourney!.startedAt!),
        );
      }
    });

    // Start heartbeat for Dead Man Switch.
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: SyncConfig.heartbeatIntervalSeconds),
      (_) => _sendHeartbeat(),
    );
  }

  void _onPositionUpdate(dynamic geoPosition) {
    // geoPosition is a geolocator Position object.
    final lat = (geoPosition as dynamic).latitude as double;
    final lng = (geoPosition as dynamic).longitude as double;
    final pos = LatLng(lat, lng);

    state = state.copyWith(currentPosition: pos);

    // Check for route deviation.
    _checkDeviation(pos);

    // Check if arrived at destination.
    _checkArrival(pos);
  }

  void _checkDeviation(LatLng currentPos) {
    if (_routePoints.isEmpty) return;

    // Find the minimum distance to any route point.
    double minDistance = double.infinity;
    for (final point in _routePoints) {
      final d = _location.calculateDistance(currentPos, point);
      if (d < minDistance) minDistance = d;
    }

    if (minDistance > AppGeo.maxDeviationMeters) {
      if (!state.isDeviated) {
        final newCount = state.deviationCount + 1;
        state = state.copyWith(isDeviated: true, deviationCount: newCount);

        // Update journey.
        if (state.activeJourney != null) {
          final updated = state.activeJourney!.copyWith(
            deviationCount: newCount,
            lastPositionAt: DateTime.now(),
          );
          _db.upsertMonitoredJourney(updated);
          state = state.copyWith(activeJourney: updated);
        }

        // Notify.
        _notifications.showDeviationNotification();

        // Create deviation alert.
        _createDeviationAlert(currentPos);
      }
    } else {
      state = state.copyWith(isDeviated: false);
    }
  }

  void _checkArrival(LatLng currentPos) {
    if (state.activeJourney == null) return;
    final dest = LatLng(
        state.activeJourney!.destLat, state.activeJourney!.destLng);
    final distance = _location.calculateDistance(currentPos, dest);

    if (distance < 100) {
      // Arrived!
      endJourney(completed: true);
    }
  }

  Future<void> _createDeviationAlert(LatLng pos) async {
    final alert = Alert(
      id: _uuid.v4(),
      deviceId: state.activeJourney?.deviceId ?? 'local',
      alertType: AlertType.deviation,
      lat: pos.latitude,
      lng: pos.longitude,
      triggeredAt: DateTime.now(),
    );

    await _db.insertAlert(alert);
    await _supabase.insertAlert(alert);
  }

  Future<void> _sendHeartbeat() async {
    if (state.activeJourney == null) return;
    try {
      await _supabase.sendHeartbeat(state.activeJourney!.id);
    } catch (_) {
      // Offline — Dead Man Switch will fire server-side.
    }
  }

  /// End the current journey.
  Future<void> endJourney({bool completed = false}) async {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (state.activeJourney != null) {
      final status =
          completed ? JourneyStatus.completed : JourneyStatus.cancelled;
      final updated = state.activeJourney!.copyWith(status: status);
      await _db.upsertMonitoredJourney(updated);
      await _supabase.updateMonitoredJourney(updated);
    }

    state = const TrackingState();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) => TrackingNotifier(),
);
