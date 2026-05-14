/// Alert provider — aggregates all emergency alerts from AI services and user SOS.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/alert.dart';
import '../services/audio_detection_service.dart';
import '../services/local_database_service.dart';
import '../services/location_service.dart';
import '../services/movement_detection_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

const _uuid = Uuid();

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class AlertStateData {
  final List<Alert> activeAlerts;
  final List<Alert> history;
  final int? countdown; // Fall detection countdown
  final bool movementDetectionActive;
  final bool audioDetectionActive;

  const AlertStateData({
    this.activeAlerts = const [],
    this.history = const [],
    this.countdown,
    this.movementDetectionActive = false,
    this.audioDetectionActive = false,
  });

  AlertStateData copyWith({
    List<Alert>? activeAlerts,
    List<Alert>? history,
    int? countdown,
    bool? movementDetectionActive,
    bool? audioDetectionActive,
  }) =>
      AlertStateData(
        activeAlerts: activeAlerts ?? this.activeAlerts,
        history: history ?? this.history,
        countdown: countdown,
        movementDetectionActive:
            movementDetectionActive ?? this.movementDetectionActive,
        audioDetectionActive:
            audioDetectionActive ?? this.audioDetectionActive,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class AlertNotifier extends StateNotifier<AlertStateData> {
  AlertNotifier() : super(const AlertStateData()) {
    _loadHistory();
  }

  final _db = LocalDatabaseService.instance;
  final _supabase = SupabaseService.instance;
  final _location = LocationService.instance;
  final _notifications = NotificationService.instance;
  final _movement = MovementDetectionService();
  final _audio = AudioDetectionService();

  StreamSubscription? _movementAlertSub;
  StreamSubscription? _movementCountdownSub;
  StreamSubscription? _audioAlertSub;

  Future<void> _loadHistory() async {
    final alerts = await _db.getAlerts(limit: 100);
    final active = await _db.getActiveAlerts();
    state = state.copyWith(history: alerts, activeAlerts: active);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Movement Detection
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> startMovementDetection() async {
    await _movement.initialize();
    _movement.startDetection();

    _movementAlertSub = _movement.alerts.listen(_onMovementAlert);
    _movementCountdownSub = _movement.countdown.listen((seconds) {
      state = state.copyWith(countdown: seconds);
      if (seconds > 0) {
        _notifications.showFallDetectionNotification(seconds);
      }
    });

    state = state.copyWith(movementDetectionActive: true);
  }

  void stopMovementDetection() {
    _movement.stopDetection();
    _movementAlertSub?.cancel();
    _movementCountdownSub?.cancel();
    state = state.copyWith(movementDetectionActive: false, countdown: null);
  }

  void cancelFallAlert() {
    _movement.cancelFallAlert();
    _notifications.cancelNotification(NotificationService.fallNotificationId);
    state = state.copyWith(countdown: null);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Audio Detection
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> startAudioDetection() async {
    await _audio.initialize();
    await _audio.startListening();

    _audioAlertSub = _audio.alerts.listen(_onAudioAlert);
    state = state.copyWith(audioDetectionActive: true);
  }

  void stopAudioDetection() {
    _audio.stopListening();
    _audioAlertSub?.cancel();
    state = state.copyWith(audioDetectionActive: false);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Alert Handlers
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _onMovementAlert(MovementAlert movementAlert) async {
    final pos = await _location.getCurrentLocation();
    final alert = Alert(
      id: _uuid.v4(),
      deviceId: _supabase.currentUser?.id ?? 'local',
      alertType: _mapMovementType(movementAlert.type),
      lat: pos?.latitude,
      lng: pos?.longitude,
      triggeredAt: DateTime.now(),
    );

    await _saveAndNotifyAlert(alert);
  }

  Future<void> _onAudioAlert(AudioAlert audioAlert) async {
    final pos = await _location.getCurrentLocation();
    final isScream = audioAlert.type == 'scream';
    final alert = Alert(
      id: _uuid.v4(),
      deviceId: _supabase.currentUser?.id ?? 'local',
      alertType: isScream ? AlertType.scream : AlertType.keyword,
      lat: pos?.latitude,
      lng: pos?.longitude,
      triggeredAt: DateTime.now(),
    );

    await _saveAndNotifyAlert(alert);

    // Show specific notification.
    if (isScream) {
      _notifications.showScreamNotification();
    } else if (audioAlert.detectedWord != null) {
      _notifications.showLocalNotification(
        '🔊 Emergency Keyword Detected',
        'Detected: "${audioAlert.detectedWord}" — Emergency contacts notified.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Manual SOS
  // ═══════════════════════════════════════════════════════════════════════

  /// Trigger a manual SOS alert.
  Future<void> triggerSOS() async {
    final pos = await _location.getCurrentLocation();
    final alert = Alert(
      id: _uuid.v4(),
      deviceId: _supabase.currentUser?.id ?? 'local',
      alertType: AlertType.sos,
      lat: pos?.latitude,
      lng: pos?.longitude,
      triggeredAt: DateTime.now(),
    );

    await _saveAndNotifyAlert(alert);
    _notifications.showSosNotification(
      'SOS Alert triggered!',
      pos?.latitude ?? 0,
      pos?.longitude ?? 0,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Acknowledge / Resolve
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> acknowledgeAlert(String alertId) async {
    await _db.acknowledgeAlert(alertId);
    _refreshAlerts();
  }

  Future<void> resolveAlert(String alertId) async {
    await _db.resolveAlert(alertId);
    _refreshAlerts();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Internal
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _saveAndNotifyAlert(Alert alert) async {
    // 1. Save to local database.
    await _db.insertAlert(alert);

    // 2. Queue for Supabase sync.
    await _supabase.insertAlert(alert);

    // 3. Update state.
    _refreshAlerts();
  }

  Future<void> _refreshAlerts() async {
    final active = await _db.getActiveAlerts();
    final history = await _db.getAlerts(limit: 100);
    state = state.copyWith(activeAlerts: active, history: history);
  }

  AlertType _mapMovementType(String type) => switch (type) {
        'fall' => AlertType.fall,
        'fight' => AlertType.fight,
        'running' => AlertType.emergencyRunning,
        _ => AlertType.sos,
      };

  // ═══════════════════════════════════════════════════════════════════════
  // Diagnostics & Testing
  // ═══════════════════════════════════════════════════════════════════════

  Map<String, dynamic> get audioDiagnostics => _audio.diagnostics;
  Map<String, dynamic> get movementDiagnostics => _movement.diagnostics;

  void simulateMovementFall() => _movement.simulateFall();
  void simulateMovementFight() => _movement.simulateFight();
  void simulateMovementRunning() => _movement.simulateRunning();

  @override
  void dispose() {
    _movementAlertSub?.cancel();
    _movementCountdownSub?.cancel();
    _audioAlertSub?.cancel();
    _movement.dispose();
    _audio.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final alertProvider =
    StateNotifierProvider<AlertNotifier, AlertStateData>(
  (ref) => AlertNotifier(),
);
