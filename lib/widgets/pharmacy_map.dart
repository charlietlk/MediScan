import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/pharmacy.dart';

class PharmacyMap extends StatefulWidget {
  const PharmacyMap({
    super.key,
    required this.userLatLng,
    required this.items,
    this.onMarkerTap,
  });

  final LatLng userLatLng;
  final List<Pharmacy> items;
  final ValueChanged<Pharmacy>? onMarkerTap;

  @override
  PharmacyMapState createState() => PharmacyMapState();
}

class PharmacyMapState extends State<PharmacyMap> {
  GoogleMapController? _controller;
  Pharmacy? _pendingFocus;

  @override
  Widget build(BuildContext context) {
    final markers = widget.items
        .where((p) => p.lat != 0 || p.lng != 0)
        .map(
          (p) => Marker(
            markerId: MarkerId('${p.lat}_${p.lng}_${p.name}'),
            position: LatLng(p.lat, p.lng),
            infoWindow: InfoWindow(title: p.name, snippet: p.address),
            onTap: () {
              widget.onMarkerTap?.call(p);
            },
          ),
        )
        .toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.userLatLng,
        zoom: 14,
      ),
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      markers: markers,
      onMapCreated: (controller) {
        _controller = controller;
        final pending = _pendingFocus;
        if (pending != null) {
          _pendingFocus = null;
          animateTo(pending);
        }
      },
    );
  }

  Future<void> animateTo(Pharmacy pharmacy) async {
    if (pharmacy.lat == 0 && pharmacy.lng == 0) {
      return;
    }
    final controller = _controller;
    if (controller == null) {
      _pendingFocus = pharmacy;
      return;
    }

    final target = LatLng(pharmacy.lat, pharmacy.lng);
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, 16),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
