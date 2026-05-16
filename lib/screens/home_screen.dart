/// Home screen — main map view with risk heatmap, device markers, SOS button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';
import '../providers/alert_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/device_provider.dart';
import '../providers/map_provider.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../widgets/alert_banner.dart';
import '../widgets/community_report_button.dart';
import '../widgets/device_marker.dart';
import '../widgets/offline_banner.dart';
import '../widgets/pin_validation_dialog.dart';
import '../widgets/risk_heatmap_layer.dart';
import '../widgets/sos_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _mapController = MapController();
  int _currentNavIndex = 0;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    // Set the map controller in the provider.
    ref.read(mapProvider.notifier).setMapController(_mapController);

    // Load map data (risk zones, community reports).
    await ref.read(mapProvider.notifier).loadMapData();

    // Load paired devices.
    await ref.read(deviceProvider.notifier).loadDevices();

    // Start AI detection services.
    ref.read(alertProvider.notifier).startMovementDetection();
    ref.read(alertProvider.notifier).startAudioDetection();

    // Get current location.
    final pos = await LocationService.instance.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _currentPosition = pos);
      ref.read(mapProvider.notifier).updateCurrentPosition(pos);
    }

    // Start continuous location tracking.
    LocationService.instance.startBackgroundLocation((geoPos) {
      final newPos = LatLng(geoPos.latitude, geoPos.longitude);
      if (mounted) {
        setState(() => _currentPosition = newPos);
        ref.read(mapProvider.notifier).updateCurrentPosition(newPos);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final connectivity = ref.watch(connectivityProvider);
    final alertState = ref.watch(alertProvider);
    final deviceState = ref.watch(deviceProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? AppGeo.yaoundeCenter,
              initialZoom: AppGeo.defaultZoom,
              maxZoom: 18,
              minZoom: 5,
            ),
            children: [
              // Tile layer (CartoDB Dark for dark theme)
              TileLayer(
                urlTemplate: MapTiles.darkUrl,
                userAgentPackageName: 'com.guardians.ai',
                maxZoom: 19,
              ),

              // Risk heatmap overlay
              RiskHeatmapLayer(zones: mapState.riskZones),

              // Community report markers
              MarkerLayer(
                markers: mapState.communityReports.map((report) {
                  return Marker(
                    point: LatLng(report.lat, report.lng),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.white),
                    ),
                  );
                }).toList(),
              ),

              // Device markers (traceurs and family members)
              MarkerLayer(
                markers: _buildDeviceMarkers(mapState, deviceState),
              ),

              // Current position blue dot
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.info.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Offline banner ──────────────────────────────────────────────
          if (!connectivity.isOnline)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: OfflineBanner()),
            ),

          // ── Alert banner ────────────────────────────────────────────────
          if (alertState.activeAlerts.isNotEmpty)
            Positioned(
              top: connectivity.isOnline ? 0 : 48,
              left: 0,
              right: 0,
              child: SafeArea(
                child: AlertBanner(
                  alert: alertState.activeAlerts.first,
                  countdown: alertState.countdown,
                  onDismiss: () => ref
                      .read(alertProvider.notifier)
                      .acknowledgeAlert(alertState.activeAlerts.first.id),
                  onCancel: () async {
                    final level = await PinValidationDialog.show(context);
                    if (level != null && mounted) {
                      if (level == 2) {
                        ref.read(alertProvider.notifier).triggerWarning();
                      } else if (level == 3) {
                        ref.read(alertProvider.notifier).triggerDuress();
                      }
                      // In all cases, if a valid PIN was entered, visually cancel the alert
                      ref.read(alertProvider.notifier).cancelFallAlert();
                    }
                  },
                ),
              ),
            ),

          // ── PIN Lock button (Discreet) ──────────────────────────────────
          Positioned(
            top: connectivity.isOnline ? 16 : 64,
            left: 16,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'pin_lock',
                backgroundColor: AppColors.surface.withValues(alpha: 0.8),
                elevation: 0,
                onPressed: () => context.push('/pin-lock'),
                child: const Icon(Icons.dialpad_rounded, color: AppColors.textHint),
              ),
            ),
          ),

          // ── My location button ──────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              backgroundColor: AppColors.surface,
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(_currentPosition!, 15);
                }
              },
              child: const Icon(Icons.my_location, color: AppColors.accent),
            ),
          ),

          // ── Community report FAB ────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 144,
            child: CommunityReportButton(
              currentPosition: _currentPosition,
            ),
          ),

          // ── SOS button ──────────────────────────────────────────────────
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SosButton(
                onSosTriggered: () =>
                    ref.read(alertProvider.notifier).triggerSOS(),
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: _onNavTap,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_rounded),
              label: AppLocalizations.of(context)?.map ?? 'Map',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.route_rounded),
              label: AppLocalizations.of(context)?.journey ?? 'Journey',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.contacts_rounded),
              label: AppLocalizations.of(context)?.contacts ?? 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded),
              label: AppLocalizations.of(context)?.history ?? 'History',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: AppLocalizations.of(context)?.settings ?? 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildDeviceMarkers(MapState mapState, DeviceState deviceState) {
    final markers = <Marker>[];

    for (final info in mapState.deviceMarkers.values) {
      markers.add(
        Marker(
          point: info.position,
          width: 48,
          height: 56,
          child: DeviceMarkerWidget(info: info),
        ),
      );
    }

    return markers;
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        break; // Already on map
      case 1:
        context.push('/journey-planner');
        break;
      case 2:
        context.push('/contacts');
        break;
      case 3:
        context.push('/alert-history');
        break;
      case 4:
        context.push('/settings');
        break;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    LocationService.instance.stopBackgroundLocation();
    super.dispose();
  }
}
