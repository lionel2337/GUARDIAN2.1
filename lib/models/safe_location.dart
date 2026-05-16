/// Safe Location model — defines secure waypoints for anti-kidnapping routes.
library;

import 'package:latlong2/latlong.dart';

enum SafeLocationType {
  police, // Gendarmerie, Commissariat
  crowdedArea, // Marché, Carrefour très fréquenté
}

class SafeLocation {
  final String id;
  final String name;
  final SafeLocationType type;
  final double lat;
  final double lng;

  const SafeLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
  });

  LatLng get position => LatLng(lat, lng);
}
