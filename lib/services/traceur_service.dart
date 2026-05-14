/// Traceur service — manages ESP32 GPS traceur devices.
///
/// Traceurs are physical devices that send GPS positions to Supabase.
/// This service handles pairing, battery monitoring, and realtime
/// position streaming.
library;

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/device.dart';
import '../models/position.dart';
import '../utils/constants.dart';
import 'local_database_service.dart';

class TraceurService {
  TraceurService._();
  static final TraceurService instance = TraceurService._();

  SupabaseClient get _supabase => Supabase.instance.client;
  final _db = LocalDatabaseService.instance;

  final Map<String, RealtimeChannel> _channels = {};

  // ══════════════════════════════════════════════════════════════════════════
  // Device Management
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch all traceur devices paired to the current user.
  Future<List<Device>> fetchUserDevices() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _supabase
          .from(Tables.devices)
          .select()
          .eq('owner_id', userId)
          .eq('device_type', 'traceur')
          .order('created_at');

      final devices = (data as List).map((e) => Device.fromJson(e)).toList();

      // Cache locally.
      for (final device in devices) {
        await _db.upsertDevice(device);
      }

      return devices;
    } catch (e) {
      // Offline — return cached devices.
      return _db.getDevicesByOwner(userId);
    }
  }

  /// Pair a new traceur device using its unique pairing code.
  ///
  /// The pairing code is printed on the device or shown in its setup screen.
  /// It maps to the device's IMEI field in the database.
  Future<Device?> pairNewDevice(String pairingCode) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // Look for an unclaimed device with this pairing code.
      final data = await _supabase
          .from(Tables.devices)
          .select()
          .eq('imei', pairingCode.toUpperCase())
          .maybeSingle();

      if (data == null) return null; // Device not found.

      // Claim the device for this user.
      await _supabase.from(Tables.devices).update({
        'owner_id': userId,
        'is_active': true,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', data['id']);

      final device = Device.fromJson({
        ...data,
        'owner_id': userId,
        'is_active': true,
      });

      // Cache locally.
      await _db.upsertDevice(device);
      return device;
    } catch (e) {
      return null;
    }
  }

  /// Rename a paired traceur.
  Future<bool> renameDevice(String deviceId, String newName) async {
    try {
      await _supabase.from(Tables.devices).update({
        'device_name': newName,
      }).eq('id', deviceId);

      final existing = await _db.getDevice(deviceId);
      if (existing != null) {
        await _db.upsertDevice(existing.copyWith(deviceName: newName));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unpair a traceur device.
  Future<bool> removeDevice(String deviceId) async {
    try {
      await _supabase.from(Tables.devices).update({
        'owner_id': null,
        'is_active': false,
      }).eq('id', deviceId);

      await _db.deleteDevice(deviceId);
      unsubscribeFromDevice(deviceId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update the battery level reported by a traceur.
  Future<void> updateDeviceBattery(String deviceId, int batteryLevel) async {
    try {
      await _supabase.from(Tables.devices).update({
        'last_battery': batteryLevel,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', deviceId);

      final existing = await _db.getDevice(deviceId);
      if (existing != null) {
        await _db.upsertDevice(existing.copyWith(
          lastBattery: batteryLevel,
          lastSeen: DateTime.now(),
        ));
      }
    } catch (e) {
      // Silent failure.
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Realtime Position Subscriptions
  // ══════════════════════════════════════════════════════════════════════════

  /// Subscribe to realtime GPS positions from a traceur device.
  ///
  /// The ESP32 traceur inserts positions into the Supabase `positions` table.
  /// This method listens for those inserts filtered by device_id.
  void subscribeToDevicePositions(
    String deviceId,
    void Function(Position) onPosition,
  ) {
    // Unsubscribe from any existing channel for this device.
    unsubscribeFromDevice(deviceId);

    final channel = _supabase
        .channel('traceur_positions:$deviceId')
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
            try {
              final position = Position.fromJson(payload.newRecord);
              // Cache locally.
              _db.insertPosition(position);
              onPosition(position);
            } catch (e) {
              // Skip malformed payloads.
            }
          },
        )
        .subscribe();

    _channels[deviceId] = channel;
  }

  /// Unsubscribe from a device's position stream.
  void unsubscribeFromDevice(String deviceId) {
    final existing = _channels.remove(deviceId);
    if (existing != null) {
      _supabase.removeChannel(existing);
    }
  }

  /// Unsubscribe from all device streams.
  void unsubscribeAll() {
    for (final channel in _channels.values) {
      _supabase.removeChannel(channel);
    }
    _channels.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Device Commands
  // ══════════════════════════════════════════════════════════════════════════

  /// Send a command to the traceur via Supabase Realtime broadcast.
  ///
  /// Supported commands:
  /// - 'activate_sos': trigger the traceur's SOS alarm
  /// - 'beep': make the traceur beep (for locating)
  /// - 'sleep': put the traceur into low-power mode
  /// - 'wake': wake the traceur from sleep
  Future<void> sendCommandToDevice(String deviceId, String command) async {
    final channel = _supabase.channel('device_commands:$deviceId');
    channel.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        channel.sendBroadcastMessage(
          event: 'command',
          payload: {
            'device_id': deviceId,
            'command': command,
            'timestamp': DateTime.now().toIso8601String(),
            'sender': _supabase.auth.currentUser?.id,
          },
        );
        // Clean up after sending.
        Future.delayed(const Duration(seconds: 2), () {
          _supabase.removeChannel(channel);
        });
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Latest Position
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetch the latest known position for a traceur.
  Future<Position?> getLatestPosition(String deviceId) async {
    try {
      final data = await _supabase
          .from(Tables.positions)
          .select()
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      final pos = Position.fromJson(data);
      await _db.insertPosition(pos);
      return pos;
    } catch (e) {
      return _db.getLatestPosition(deviceId);
    }
  }
}
