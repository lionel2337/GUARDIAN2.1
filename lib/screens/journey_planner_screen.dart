/// Journey planner screen — plan safe routes with risk scoring.
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

import '../l10n/app_localizations.dart';
import '../models/safe_location.dart';
import '../providers/map_provider.dart';
import '../providers/tracking_provider.dart';
import '../services/location_service.dart';
import '../services/safe_routing_service.dart';
import '../utils/constants.dart';
import '../widgets/route_card.dart';

class JourneyPlannerScreen extends ConsumerStatefulWidget {
  const JourneyPlannerScreen({super.key});

  @override
  ConsumerState<JourneyPlannerScreen> createState() =>
      _JourneyPlannerScreenState();
}

class _JourneyPlannerScreenState extends ConsumerState<JourneyPlannerScreen> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _mapController = MapController();

  LatLng? _origin;
  LatLng? _destination;
  List<_RouteOption>? _routes;
  List<SafeLocation> _safeWaypoints = [];
  int _selectedRoute = 0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    final pos = await LocationService.instance.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _origin = pos);
      if (_originController.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _originController.text =
                AppLocalizations.of(context)?.currentLocation ?? 'Current Location';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.planYourJourney ?? 'Plan Your Journey'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Column(
          children: [
            // ── Search fields ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppDimens.radiusL),
                ),
              ),
              child: Column(
                children: [
                  // Origin
                  TextField(
                    controller: _originController,
                    decoration: InputDecoration(
                      hintText: localizations?.startingPoint ?? 'Starting point',
                      prefixIcon: const Icon(Icons.trip_origin,
                          color: AppColors.success),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location,
                            color: AppColors.accent),
                        onPressed: _loadCurrentPosition,
                      ),
                    ),
                    onSubmitted: (_) => _searchRoutes(),
                  ),
                  const SizedBox(height: 8),
                  // Destination
                  TextField(
                    controller: _destController,
                    decoration: InputDecoration(
                      hintText: localizations?.destination ?? 'Destination',
                      prefixIcon:
                      const Icon(Icons.location_on, color: AppColors.danger),
                    ),
                    onSubmitted: (_) => _searchRoutes(),
                  ),
                  const SizedBox(height: 12),
                  // Search button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSearching ? null : _searchRoutes,
                      icon: _isSearching
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.search_rounded),
                      label: Text(localizations?.findSafeRoutes ?? 'Find Safe Routes'),
                    ),
                  ),
                ],
              ),
            ),

            // ── Map preview ─────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _origin ?? AppGeo.yaoundeCenter,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapTiles.darkUrl,
                        userAgentPackageName: 'com.guardians.ai',
                      ),
                      // Origin marker
                      if (_origin != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: _origin!,
                            child: const Icon(Icons.trip_origin,
                                color: AppColors.success, size: 28),
                          ),
                        ]),
                      // Destination marker
                      if (_destination != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: _destination!,
                            child: const Icon(Icons.location_on,
                                color: AppColors.danger, size: 32),
                          ),
                        ]),
                      // Safe Waypoints markers
                      if (_safeWaypoints.isNotEmpty)
                        MarkerLayer(
                          markers: _safeWaypoints.map((wp) {
                            return Marker(
                              point: wp.position,
                              child: Icon(
                                wp.type == SafeLocationType.police ? Icons.local_police : Icons.groups,
                                color: wp.type == SafeLocationType.police ? Colors.blue : Colors.green,
                                size: 28,
                              ),
                            );
                          }).toList(),
                        ),
                      // Route polylines
                      if (_routes != null)
                        PolylineLayer(
                          polylines: _routes!.asMap().entries.map((entry) {
                            final isSelected = entry.key == _selectedRoute;
                            final route = entry.value;
                            return Polyline(
                              points: route.points,
                              strokeWidth: isSelected ? 5.0 : 3.0,
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textHint.withValues(alpha: 0.5), // ✅ corrigé
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Route cards ─────────────────────────────────────────────
            if (_routes != null)
              Expanded(
                flex: 2,
                child: ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
                  itemCount: _routes!.length,
                  itemBuilder: (context, index) {
                    final route = _routes![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RouteCard(
                        routeName: route.name,
                        durationMinutes: route.durationMinutes,
                        distanceKm: route.distanceKm,
                        safetyScore: route.safetyScore,
                        isSelected: index == _selectedRoute,
                        isSafest: index == _safestRouteIndex,
                        onTap: () {
                          setState(() => _selectedRoute = index);
                        },
                      ),
                    );
                  },
                ),
              ),

            // ── Start journey button ────────────────────────────────────
            if (_routes != null)
              Padding(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startMonitoredJourney,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(localizations?.startMonitoredJourney ?? 'Start Monitored Journey'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int get _safestRouteIndex {
    if (_routes == null || _routes!.isEmpty) return 0;
    int best = 0;
    for (int i = 1; i < _routes!.length; i++) {
      if (_routes![i].safetyScore > _routes![best].safetyScore) {
        best = i;
      }
    }
    return best;
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      debugPrint('Geocoding failed for "$address": $e');
    }
    return null;
  }

  // Fallback simulation (conservée)
  LatLng? _simulateGeocode(String text) {
    final knownPlaces = {
      'bastos': const LatLng(3.8900, 11.5000),
      'mokolo': const LatLng(3.8700, 11.5050),
      'melen': const LatLng(3.8600, 11.4900),
      'briqueterie': const LatLng(3.8750, 11.5150),
      'essos': const LatLng(3.8700, 11.5350),
      'centre': const LatLng(3.8660, 11.5180),
      'nlongkak': const LatLng(3.8800, 11.5100),
      'mvog-ada': const LatLng(3.8550, 11.5200),
      'nkol-eton': const LatLng(3.8900, 11.5200),
      'omnisport': const LatLng(3.8550, 11.5050),
      'nsimeyong': const LatLng(3.8350, 11.5000),
      'biyem-assi': const LatLng(3.8400, 11.4850),
    };
    for (final entry in knownPlaces.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return LatLng(
      3.8480 + (text.length % 10 - 5) * 0.005,
      11.5021 + (text.length % 7 - 3) * 0.005,
    );
  }

  Future<void> _searchRoutes() async {
    setState(() => _isSearching = true);

    // Géocodage départ
    if (_origin == null && _originController.text.trim().isNotEmpty) {
      final address = _originController.text.trim();
      LatLng? coords = await _geocodeAddress(address);
      if (coords == null) {
        coords = _simulateGeocode(address.toLowerCase());
        if (coords != null) debugPrint('⚠️ Using simulated coordinates for "$address"');
      }
      if (coords != null) setState(() => _origin = coords);
    }

    // Géocodage destination
    final destText = _destController.text.trim();
    if (destText.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    LatLng? destination = await _geocodeAddress(destText);
    if (destination == null) {
      destination = _simulateGeocode(destText.toLowerCase());
      if (destination != null) debugPrint('⚠️ Using simulated coordinates for "$destText"');
    }

    if (_origin == null || destination == null) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find location. Please try again.'), // ✅ texte statique
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    setState(() => _destination = destination);

    // Recherche des waypoints de sécurité
    final safeWaypoints = SafeRoutingService.instance.getOptimalSafeWaypoints(_origin!, _destination!);

    // Génération des routes
    final riskEngine = ref.read(mapProvider.notifier).riskEngine;
    final routes = <_RouteOption>[];
    for (int i = 0; i < 3; i++) {
      final isSafest = (i == 2);
      final points = _generateRoutePoints(_origin!, _destination!, variation: i, waypoints: isSafest ? safeWaypoints : []);
      final safetyScore = await riskEngine.calculateRouteSafety(points);
      final distance = _calculateRouteDistance(points);
      final duration = (distance / 40 * 60).round();
      
      String routeName = 'Direct Route';
      if (i == 1) routeName = 'Via Main Roads';
      if (i == 2) routeName = safeWaypoints.isNotEmpty ? 'Via ${safeWaypoints.first.name}' : 'Safest Route';

      routes.add(_RouteOption(
        name: routeName,
        points: points,
        safetyScore: safetyScore,
        distanceKm: distance,
        durationMinutes: duration,
      ));
    }

    routes.sort((a, b) => b.safetyScore.compareTo(a.safetyScore));

    setState(() {
      _routes = routes;
      _safeWaypoints = safeWaypoints;
      _selectedRoute = 0;
      _isSearching = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(_origin!, _destination!),
            padding: const EdgeInsets.all(50),
          ),
        );
      } catch (_) {
        _mapController.move(_destination!, 14);
      }
    });
  }

  // ✅ Suppression de _parseCoordinates (inutilisé)

  List<LatLng> _generateRoutePoints(LatLng start, LatLng end,
      {int variation = 0, List<SafeLocation> waypoints = const []}) {
    if (waypoints.isNotEmpty) {
      final points = <LatLng>[];
      points.add(start);
      for (final wp in waypoints) {
        points.addAll(_interpolateSegment(points.last, wp.position));
      }
      points.addAll(_interpolateSegment(points.last, end));
      return points;
    }

    final points = <LatLng>[];
    const steps = 15;
    final offsetFactor = variation * 0.003;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t +
          (variation > 0 ? offsetFactor * (1 - (2 * t - 1).abs()) : 0);
      final lng = start.longitude + (end.longitude - start.longitude) * t +
          (variation > 0 ? -offsetFactor * 0.5 * (1 - (2 * t - 1).abs()) : 0);
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  List<LatLng> _interpolateSegment(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const steps = 10;
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  double _calculateRouteDistance(List<LatLng> points) {
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += LocationService.instance.calculateDistance(points[i - 1], points[i]);
    }
    return total / 1000;
  }

  Future<void> _startMonitoredJourney() async {
    if (_origin == null || _destination == null || _routes == null) return;
    final route = _routes![_selectedRoute];
    final userId = ref.read(mapProvider).currentPosition != null ? 'local' : 'local';
    await ref.read(trackingProvider.notifier).startJourney(
      origin: _origin!,
      destination: _destination!,
      plannedDurationMinutes: route.durationMinutes,
      routePoints: route.points,
      deviceId: 'mobile_$userId',
    );
    if (mounted) context.go('/journey-active');
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}

class _RouteOption {
  final String name;
  final List<LatLng> points;
  final double safetyScore;
  final double distanceKm;
  final int durationMinutes;

  const _RouteOption({
    required this.name,
    required this.points,
    required this.safetyScore,
    required this.distanceKm,
    required this.durationMinutes,
  });
}