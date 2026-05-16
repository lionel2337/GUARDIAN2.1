/// Safe Routing Service — provides logic to find safe waypoints for routes.
library;

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

import '../models/safe_location.dart';

class SafeRoutingService {
  SafeRoutingService._();
  static final SafeRoutingService instance = SafeRoutingService._();

  // ── Predefined Safe Locations (Yaoundé) ───────────────────────────────────
  static const List<SafeLocation> safeLocations = [
    // Gendarmeries & Police (Very Safe)
    SafeLocation(
      id: 'police_central',
      name: 'Commissariat Central No 1',
      type: SafeLocationType.police,
      lat: 3.8660,
      lng: 11.5160,
    ),
    SafeLocation(
      id: 'gendarmerie_hq',
      name: 'Camp SED (Gendarmerie Nationale)',
      type: SafeLocationType.police,
      lat: 3.8750,
      lng: 11.5120,
    ),
    SafeLocation(
      id: 'police_bastos',
      name: 'Commissariat Bastos',
      type: SafeLocationType.police,
      lat: 3.8880,
      lng: 11.5030,
    ),
    SafeLocation(
      id: 'police_mokolo',
      name: 'Commissariat Mokolo',
      type: SafeLocationType.police,
      lat: 3.8680,
      lng: 11.5020,
    ),
    SafeLocation(
      id: 'gendarmerie_melen',
      name: 'Brigade Melen',
      type: SafeLocationType.police,
      lat: 3.8610,
      lng: 11.4920,
    ),
    SafeLocation(
      id: 'police_biyem_assi',
      name: 'Commissariat 6eme',
      type: SafeLocationType.police,
      lat: 3.8420,
      lng: 11.4880,
    ),
    
    // Crowded Areas (Safe during daytime, but generally better than isolated roads)
    SafeLocation(
      id: 'crowd_warda',
      name: 'Carrefour Warda',
      type: SafeLocationType.crowdedArea,
      lat: 3.8720,
      lng: 11.5140,
    ),
    SafeLocation(
      id: 'crowd_poste',
      name: 'Poste Centrale',
      type: SafeLocationType.crowdedArea,
      lat: 3.8630,
      lng: 11.5180,
    ),
    SafeLocation(
      id: 'crowd_nlongkak',
      name: 'Rond-Point Nlongkak',
      type: SafeLocationType.crowdedArea,
      lat: 3.8820,
      lng: 11.5110,
    ),
    SafeLocation(
      id: 'crowd_omnisport',
      name: 'Stade Omnisport',
      type: SafeLocationType.crowdedArea,
      lat: 3.8560,
      lng: 11.5080,
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // Logic
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns 1 or 2 safe waypoints that lie roughly between origin and destination.
  List<SafeLocation> getOptimalSafeWaypoints(LatLng origin, LatLng destination) {
    final waypoints = <SafeLocation>[];
    
    // Calculate bounding box center and distance
    final midLat = (origin.latitude + destination.latitude) / 2;
    final midLng = (origin.longitude + destination.longitude) / 2;
    final midPoint = LatLng(midLat, midLng);
    
    final totalDistance = _haversineMeters(origin, destination);
    if (totalDistance < 1000) return waypoints; // Too short to need a detour

    // Find candidates
    final candidates = <SafeLocation>[];
    for (final loc in safeLocations) {
      final distToOrigin = _haversineMeters(origin, loc.position);
      final distToDest = _haversineMeters(loc.position, destination);
      
      // If the location is "between" origin and destination without a massive detour
      // An elliptical bound check: dist(A,C) + dist(C,B) < dist(A,B) * 1.5
      if ((distToOrigin + distToDest) < totalDistance * 1.5) {
        candidates.add(loc);
      }
    }

    if (candidates.isEmpty) return waypoints;

    // Sort by priority: Police first, then Crowded Areas.
    // If same type, sort by how little detour they add.
    candidates.sort((a, b) {
      if (a.type == SafeLocationType.police && b.type != SafeLocationType.police) return -1;
      if (a.type != SafeLocationType.police && b.type == SafeLocationType.police) return 1;
      
      final detourA = _haversineMeters(origin, a.position) + _haversineMeters(a.position, destination);
      final detourB = _haversineMeters(origin, b.position) + _haversineMeters(b.position, destination);
      return detourA.compareTo(detourB);
    });

    // Take the best one, or two if they are spaced out
    waypoints.add(candidates.first);
    if (candidates.length > 1 && totalDistance > 4000) {
      final secondBest = candidates[1];
      // Only add second if it's far enough from the first one
      if (_haversineMeters(waypoints.first.position, secondBest.position) > 1500) {
        waypoints.add(secondBest);
      }
    }

    // Ensure they are ordered from Origin to Destination
    waypoints.sort((a, b) {
      return _haversineMeters(origin, a.position).compareTo(_haversineMeters(origin, b.position));
    });

    return waypoints;
  }

  double _haversineMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);

    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);

    final h = sinDLat * sinDLat +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            sinDLng *
            sinDLng;

    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
