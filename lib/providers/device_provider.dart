/// Device provider — manages paired traceur devices.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import '../models/position.dart';
import '../services/traceur_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class DeviceState {
  final List<Device> devices;
  final String? selectedDeviceId;
  final Map<String, Position?> lastPositions;
  final bool isLoading;
  final String? error;

  const DeviceState({
    this.devices = const [],
    this.selectedDeviceId,
    this.lastPositions = const {},
    this.isLoading = false,
    this.error,
  });

  Device? get selectedDevice {
    if (selectedDeviceId == null) return null;
    try {
      return devices.firstWhere((d) => d.id == selectedDeviceId);
    } catch (_) {
      return null;
    }
  }

  DeviceState copyWith({
    List<Device>? devices,
    String? selectedDeviceId,
    Map<String, Position?>? lastPositions,
    bool? isLoading,
    String? error,
  }) =>
      DeviceState(
        devices: devices ?? this.devices,
        selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
        lastPositions: lastPositions ?? this.lastPositions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class DeviceNotifier extends StateNotifier<DeviceState> {
  DeviceNotifier() : super(const DeviceState());

  final _traceur = TraceurService.instance;

  /// Load all devices for the current user.
  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final devices = await _traceur.fetchUserDevices();
      state = state.copyWith(devices: devices, isLoading: false);

      // Subscribe to position updates for each device.
      for (final device in devices) {
        _subscribeToDevice(device.id);
        // Fetch latest known position.
        final pos = await _traceur.getLatestPosition(device.id);
        if (pos != null) {
          _updateLastPosition(device.id, pos);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Pair a new traceur with a pairing code.
  Future<bool> pairDevice(String pairingCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final device = await _traceur.pairNewDevice(pairingCode);
      if (device == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Device not found. Check your pairing code.',
        );
        return false;
      }

      state = state.copyWith(
        devices: [...state.devices, device],
        isLoading: false,
      );

      _subscribeToDevice(device.id);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Rename a paired device.
  Future<void> renameDevice(String deviceId, String newName) async {
    await _traceur.renameDevice(deviceId, newName);
    final updated = state.devices.map((d) {
      if (d.id == deviceId) return d.copyWith(deviceName: newName);
      return d;
    }).toList();
    state = state.copyWith(devices: updated);
  }

  /// Unpair a device.
  Future<void> removeDevice(String deviceId) async {
    await _traceur.removeDevice(deviceId);
    final updated = state.devices.where((d) => d.id != deviceId).toList();
    final positions = Map<String, Position?>.from(state.lastPositions)
      ..remove(deviceId);
    state = state.copyWith(devices: updated, lastPositions: positions);
  }

  /// Select a device.
  void selectDevice(String? deviceId) {
    state = state.copyWith(selectedDeviceId: deviceId);
  }

  /// Send a command to a traceur.
  Future<void> sendCommand(String deviceId, String command) async {
    await _traceur.sendCommandToDevice(deviceId, command);
  }

  void _subscribeToDevice(String deviceId) {
    _traceur.subscribeToDevicePositions(deviceId, (position) {
      _updateLastPosition(deviceId, position);
    });
  }

  void _updateLastPosition(String deviceId, Position position) {
    final positions = Map<String, Position?>.from(state.lastPositions);
    positions[deviceId] = position;
    state = state.copyWith(lastPositions: positions);

    // Update device battery if available.
    if (position.battery != null) {
      final updated = state.devices.map((d) {
        if (d.id == deviceId) {
          return d.copyWith(
            lastBattery: position.battery,
            lastSeen: position.timestamp,
          );
        }
        return d;
      }).toList();
      state = state.copyWith(devices: updated);
    }
  }

  @override
  void dispose() {
    _traceur.unsubscribeAll();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>(
  (ref) => DeviceNotifier(),
);
