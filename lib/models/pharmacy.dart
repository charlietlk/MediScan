import 'package:flutter/foundation.dart';

/// Simple data holder describing a pharmacy that can optionally carry a
/// calculated distance from the user's current position.
@immutable
class Pharmacy {
  const Pharmacy({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
    this.distanceKm,
  });

  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? phone;
  final double? distanceKm;

  Pharmacy copyWith({
    String? name,
    String? address,
    double? lat,
    double? lng,
    String? phone,
    double? distanceKm,
  }) {
    return Pharmacy(
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phone: phone ?? this.phone,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
