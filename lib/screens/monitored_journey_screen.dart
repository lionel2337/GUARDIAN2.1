/// Monitored journey screen — active journey tracking with deviation alerts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../providers/tracking_provider.dart';
import '../providers/alert_provider.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class MonitoredJourneyScreen extends ConsumerWidget {
  const MonitoredJourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingProvider);
    final journey = tracking.activeJourney;

    if (journey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Journey')),
        body: const Center(child: Text('No active journey')),
      );
    }

    final elapsed = tracking.elapsed;
    final dest = LatLng(journey.destLat, journey.destLng);
    final origin = LatLng(journey.originLat, journey.originLng);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    const Text('Active Journey',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Deviation banner ────────────────────────────────────────
              if (tracking.isDeviated)
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppDimens.paddingM),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Route deviation detected! (${tracking.deviationCount} times)',
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Map ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingM),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: tracking.currentPosition ??
                            origin,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapTiles.darkUrl,
                          userAgentPackageName: 'com.guardians.ai',
                        ),
                        // Route line
                        PolylineLayer(polylines: [
                          Polyline(
                            points: [origin, dest],
                            strokeWidth: 3,
                            color: AppColors.accent.withOpacity(0.5),
                          ),
                        ]),
                        // Origin + destination markers
                        MarkerLayer(markers: [
                          Marker(
                            point: origin,
                            child: const Icon(Icons.trip_origin,
                                color: AppColors.success, size: 24),
                          ),
                          Marker(
                            point: dest,
                            child: const Icon(Icons.flag_rounded,
                                color: AppColors.danger, size: 28),
                          ),
                          if (tracking.currentPosition != null)
                            Marker(
                              point: tracking.currentPosition!,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.info,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Stats ───────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingM),
                padding: const EdgeInsets.all(AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat(
                      Icons.timer_outlined,
                      LocationService.formatDuration(elapsed),
                      'Elapsed',
                    ),
                    _stat(
                      Icons.schedule_rounded,
                      journey.expectedArrival != null
                          ? '${journey.expectedArrival!.hour}:${journey.expectedArrival!.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                      'ETA',
                      isLate: journey.isLate,
                    ),
                    _stat(
                      Icons.alt_route_rounded,
                      '${tracking.deviationCount}',
                      'Deviations',
                      isAlert: tracking.deviationCount > 0,
                    ),
                  ],
                ),
              ),

              // ── Action buttons ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: Row(
                  children: [
                    // SOS
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(alertProvider.notifier).triggerSOS(),
                        icon: const Icon(Icons.sos_rounded),
                        label: const Text('SOS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cancel journey
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(trackingProvider.notifier)
                              .endJourney();
                          if (context.mounted) context.go('/home');
                        },
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('End Journey'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label,
      {bool isLate = false, bool isAlert = false}) {
    final color = isLate || isAlert ? AppColors.danger : AppColors.textPrimary;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
