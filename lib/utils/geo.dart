import 'dart:math' as math;

/// Calculates the haversine distance (great-circle) in kilometres between two
/// latitude/longitude pairs.
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final originLat = _toRadians(lat1);
  final destLat = _toRadians(lat2);

  final a = math.pow(math.sin(dLat / 2), 2) +
      math.pow(math.sin(dLon / 2), 2) * math.cos(originLat) * math.cos(destLat);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * (math.pi / 180.0);
