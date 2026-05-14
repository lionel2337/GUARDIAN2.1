/// Map provider — manages OpenStreetMap state, markers, and overlays.
library;


import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/community_report.dart';
import '../models/device.dart';
import '../models/position.dart';
import '../models/risk_zone.dart';
import '../services/local_database_service.dart';
import '../services/risk_scoring_engine.dart';


// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class MapState {
  final LatLng center;
  final double zoom;
  final LatLng? currentPosition;
  final List<RiskZone> riskZones;
  final List<CommunityReport> communityReports;
  final Map<String, LatLng> devicePositions; // deviceId -> position
  final Map<String, DeviceMarkerInfo> deviceMarkers; // deviceId -> info

  const MapState({
    this.center = const LatLng(3.8480, 11.5021),
    this.zoom = 13.0,
    this.currentPosition,
    this.riskZones = const [],
    this.communityReports = const [],
    this.devicePositions = const {},
    this.deviceMarkers = const {},
  });

  MapState copyWith({
    LatLng? center,
    double? zoom,
    LatLng? currentPosition,
    List<RiskZone>? riskZones,
    List<CommunityReport>? communityReports,
    Map<String, LatLng>? devicePositions,
    Map<String, DeviceMarkerInfo>? deviceMarkers,
  }) =>
      MapState(
        center: center ?? this.center,
        zoom: zoom ?? this.zoom,
        currentPosition: currentPosition ?? this.currentPosition,
        riskZones: riskZones ?? this.riskZones,
        communityReports: communityReports ?? this.communityReports,
        devicePositions: devicePositions ?? this.devicePositions,
        deviceMarkers: deviceMarkers ?? this.deviceMarkers,
      );
}

/// Marker info for devices displayed on the map.
class DeviceMarkerInfo {
  final String deviceId;
  final String deviceName;
  final DeviceType deviceType;
  final int? battery;
  final LatLng position;

  const DeviceMarkerInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.battery,
    required this.position,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(const MapState());

  final _db = LocalDatabaseService.instance;
  late final RiskScoringEngine _riskEngine = RiskScoringEngine(_db);

  MapController? _mapController;

  void setMapController(MapController controller) {
    _mapController = controller;
  }

  /// Load risk zones and community reports for the map.
  Future<void> loadMapData() async {
    // Load predefined + custom risk zones.
    final allZones = await _riskEngine.getAllZones();

    // Load active community reports.
    final reports = await _db.getActiveCommunityReports();

    state = state.copyWith(
      riskZones: allZones,
      communityReports: reports,
    );
  }

  /// Update the user's current position on the map.
  void updateCurrentPosition(LatLng position) {
    state = state.copyWith(currentPosition: position);
  }

  /// Center the map on a specific point.
  void centerOn(LatLng position, {double? zoom}) {
    state = state.copyWith(center: position, zoom: zoom ?? state.zoom);
    _mapController?.move(position, zoom ?? state.zoom);
  }

  /// Add or update a device marker on the map.
  void updateDeviceMarker(Device device, Position position) {
    final pos = LatLng(position.lat, position.lng);
    final positions = Map<String, LatLng>.from(state.devicePositions);
    positions[device.id] = pos;

    final markers = Map<String, DeviceMarkerInfo>.from(state.deviceMarkers);
    markers[device.id] = DeviceMarkerInfo(
      deviceId: device.id,
      deviceName: device.deviceName,
      deviceType: device.deviceType,
      battery: position.battery ?? device.lastBattery,
      position: pos,
    );

    state = state.copyWith(
      devicePositions: positions,
      deviceMarkers: markers,
    );
  }

  /// Remove a device marker from the map.
  void removeDeviceMarker(String deviceId) {
    final positions = Map<String, LatLng>.from(state.devicePositions)
      ..remove(deviceId);
    final markers = Map<String, DeviceMarkerInfo>.from(state.deviceMarkers)
      ..remove(deviceId);
    state = state.copyWith(
      devicePositions: positions,
      deviceMarkers: markers,
    );
  }

  /// Add a community report to the map.
  void addCommunityReport(CommunityReport report) {
    state = state.copyWith(
      communityReports: [...state.communityReports, report],
    );
  }

  /// Update risk zones on the map.
  void updateRiskZones(List<RiskZone> zones) {
    state = state.copyWith(riskZones: zones);
  }

  /// Get the risk engine for route scoring.
  RiskScoringEngine get riskEngine => _riskEngine;
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final mapProvider = StateNotifierProvider<MapNotifier, MapState>(
  (ref) => MapNotifier(),
);
