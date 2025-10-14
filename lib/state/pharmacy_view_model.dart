import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pharmacy.dart';
import '../services/collect_pharmacy_service.dart';
import '../services/geocoder_service.dart';
import '../services/nosy_pharmacy_service.dart';
import '../utils/geo.dart';

enum PharmacyScope { onDuty, regular }

class PharmacyViewModel extends ChangeNotifier {
  PharmacyViewModel();

  final NosyPharmacyService _service = const NosyPharmacyService();
  final GeocoderService _geo = const GeocoderService();
  final CollectPharmacyService _collect = const CollectPharmacyService();

  Position? current;
  bool isLoading = false;
  String? error;
  List<Pharmacy> all = <Pharmacy>[];
  List<Pharmacy> items = <Pharmacy>[];

  Timer? _debounce;
  bool _disposed = false;
  DateTime? _cacheTime;
  DateTime? _cacheRegularAt;
  List<Pharmacy>? _cacheOnDuty;
  List<Pharmacy>? _cacheRegular;
  String _query = '';
  static const double _defaultLat = 41.0369;
  static const double _defaultLng = 28.9853;
  Pharmacy? selected;
  PharmacyScope _scope = PharmacyScope.onDuty;
  bool regularLoading = false;
  bool _permissionDenied = false;

  bool get permissionDenied => _permissionDenied;

  Future<void> init() async {
    if (isLoading) {
      return;
    }
    await loadOnDuty();
  }

  Future<void> loadOnDuty() async {
    if (isLoading) {
      return;
    }

    isLoading = true;
    error = null;
    _notify();

    try {
      final now = DateTime.now();
      if (_cacheOnDuty != null &&
          _cacheTime != null &&
          now.difference(_cacheTime!) < const Duration(minutes: 5)) {
        _useAndSort(_cacheOnDuty!);
        return;
      }

      await _ensureLocationPermission();
      current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _permissionDenied = false;

      final anchor = current!;
      final results = await _service.getOnDutyByLocation(
        lat: anchor.latitude,
        lng: anchor.longitude,
        query: _query.isEmpty ? null : _query,
      );

      final withDistance =
          _withDistances(results, anchor.latitude, anchor.longitude);

      _cacheOnDuty = withDistance;
      _cacheTime = DateTime.now();
      _useAndSort(withDistance);

      if (withDistance.isEmpty) {
        error = 'Yakınlarda nöbetçi eczane bulunamadı.';
      }
    } on _LocationAccessException catch (ex) {
      _permissionDenied = true;
      error = ex.message;
      all = <Pharmacy>[];
      items = <Pharmacy>[];
    } on Exception catch (ex, stackTrace) {
      debugPrint('Nöbetçi eczaneler alınamadı: $ex\n$stackTrace');
      error = 'Nöbetçi eczaneler yüklenemedi. Lütfen tekrar deneyin.';
      if (_cacheOnDuty == null || _cacheOnDuty!.isEmpty) {
        final fallback = _withDistances(
          _mockPharmacies(),
          current?.latitude ?? _defaultLat,
          current?.longitude ?? _defaultLng,
        );
        _cacheOnDuty = fallback;
        _cacheTime = null;
        _useAndSort(fallback);
      }
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> loadRegular() async {
    if (regularLoading) {
      return;
    }

    regularLoading = true;
    error = null;
    _notify();

    try {
      final now = DateTime.now();
      if (_cacheRegular != null &&
          _cacheRegularAt != null &&
          now.difference(_cacheRegularAt!) < const Duration(minutes: 5)) {
        _useAndSort(_cacheRegular!);
        return;
      }

      await _ensureLocationPermission();
      current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _permissionDenied = false;

      final anchor = current!;
      final region = await _geo.reverse(
        lat: anchor.latitude,
        lng: anchor.longitude,
      );

      final results = await _collect.getRegularByRegion(
        city: region.city,
        district: region.district,
        query: _query.isEmpty ? null : _query,
      );

      final withDistance = _withDistances(
        results,
        anchor.latitude,
        anchor.longitude,
      );

      _cacheRegular = withDistance;
      _cacheRegularAt = DateTime.now();
      _useAndSort(withDistance);

      if (withDistance.isEmpty) {
        error = 'Yakınlarda eczane bulunamadı.';
      }
    } on _LocationAccessException catch (ex) {
      _permissionDenied = true;
      error = ex.message;
      all = <Pharmacy>[];
      items = <Pharmacy>[];
    } on Exception catch (ex, stackTrace) {
      debugPrint(
          'Gündüz eczaneleri alınamadı: ${_shortError(ex.toString())}\n$stackTrace');
      error = 'Gündüz eczaneleri yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      regularLoading = false;
      _notify();
    }
  }

  Future<void> loadRegularManual({
    required String city,
    String? district,
  }) async {
    final trimmedCity = city.trim();
    final trimmedDistrict = district?.trim();
    if (trimmedCity.isEmpty) {
      error = 'Şehir adı gerekli.';
      _notify();
      return;
    }

    regularLoading = true;
    error = null;
    _notify();

    try {
      Position? anchor = current;
      if (anchor == null) {
        try {
          await _ensureLocationPermission();
          anchor = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          current = anchor;
          _permissionDenied = false;
        } on _LocationAccessException catch (ex) {
          _permissionDenied = true;
          debugPrint('Konum izni alınamadı (manuel arama): ${ex.message}');
        }
      }

      final results = await _collect.getRegularByRegion(
        city: trimmedCity,
        district: (trimmedDistrict?.isEmpty ?? true) ? null : trimmedDistrict,
        query: _query.isEmpty ? null : _query,
      );

      List<Pharmacy> processed;
      if (anchor != null) {
        processed = _withDistances(
          results,
          anchor.latitude,
          anchor.longitude,
        );
      } else {
        processed = List<Pharmacy>.from(results)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
      }

      if (_scope != PharmacyScope.regular) {
        _scope = PharmacyScope.regular;
      }

      _cacheRegular = processed;
      _cacheRegularAt = DateTime.now();
      _useAndSort(processed);
    } on Exception catch (ex, stackTrace) {
      debugPrint(
          'Manuel gündüz eczane araması başarısız: ${_shortError(ex.toString())}\n$stackTrace');
      error = 'Gündüz eczaneleri yüklenemedi. Lütfen tekrar deneyin.';
    } finally {
      regularLoading = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    if (_scope == PharmacyScope.onDuty) {
      _cacheOnDuty = null;
      _cacheTime = null;
      await loadOnDuty();
    } else {
      _cacheRegular = null;
      _cacheRegularAt = null;
      await loadRegular();
    }
  }

  void clearError() {
    if (error == null) {
      return;
    }
    error = null;
    _notify();
  }

  void select(Pharmacy pharmacy) {
    if (identical(selected, pharmacy)) {
      return;
    }
    selected = pharmacy;
    _notify();
  }

  void applySearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = query.trim().toLowerCase();
      final source = _currentCache ?? items;
      _useAndSort(source);
      _notify();
    });
  }

  void setScope(PharmacyScope scope) {
    if (_scope == scope) {
      return;
    }

    _scope = scope;
    selected = null;
    error = null;

    if (scope == PharmacyScope.onDuty) {
      if (_cacheOnDuty != null) {
        _useAndSort(_cacheOnDuty!);
        _notify();
      } else {
        all = <Pharmacy>[];
        items = <Pharmacy>[];
        scheduleMicrotask(loadOnDuty);
      }
    } else {
      if (_cacheRegular != null) {
        _useAndSort(_cacheRegular!);
        _notify();
      } else {
        all = <Pharmacy>[];
        items = <Pharmacy>[];
        scheduleMicrotask(loadRegular);
      }
    }
  }

  Future<void> requestPermission() async {
    try {
      await _ensureLocationPermission();
      _permissionDenied = false;
      error = null;
      await refresh();
    } on _LocationAccessException catch (ex) {
      _permissionDenied = true;
      error = ex.message;
      _notify();
    } catch (ex, stackTrace) {
      debugPrint('Konum izni talebi başarısız: $ex\n$stackTrace');
      error = 'Konum izni alınamadı. Lütfen tekrar deneyin.';
      _notify();
    }
  }

  int get tabIndex => _scope.index;

  bool get isActiveLoading =>
      _scope == PharmacyScope.onDuty ? isLoading : regularLoading;

  Future<void> callPharmacy(Pharmacy pharmacy) async {
    final phone = pharmacy.phone?.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone == null || phone.isEmpty) {
      error = 'Aranacak telefon numarası bulunamadı.';
      _notify();
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        error = 'Arama başlatılamadı.';
        _notify();
      }
    } on Exception catch (ex, stackTrace) {
      debugPrint('Telefon araması başlatılamadı: $ex\n$stackTrace');
      error = 'Arama başlatılamadı.';
      _notify();
    }
  }

  Future<void> openInMaps(Pharmacy pharmacy) async {
    final lat = pharmacy.lat;
    final lng = pharmacy.lng;
    final encodedLabel = Uri.encodeComponent(pharmacy.name);

    Uri uri;
    if (Platform.isIOS) {
      uri = Uri.parse('https://maps.apple.com/?q=$encodedLabel&ll=$lat,$lng');
    } else if (Platform.isAndroid) {
      uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedLabel)');
    } else {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        error = 'Harita açılamadı.';
        _notify();
      }
    } on Exception catch (ex, stackTrace) {
      debugPrint('Harita açılamadı: $ex\n$stackTrace');
      error = 'Harita açılamadı.';
      _notify();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _disposed = true;
    super.dispose();
  }

  List<Pharmacy> _withDistances(
    List<Pharmacy> list,
    double anchorLat,
    double anchorLng,
  ) {
    return list
        .map(
          (p) => p.copyWith(
            distanceKm: double.parse(
              haversineKm(anchorLat, anchorLng, p.lat, p.lng)
                  .toStringAsFixed(1),
            ),
          ),
        )
        .toList()
      ..sort(
        (a, b) => (a.distanceKm ?? double.infinity)
            .compareTo(b.distanceKm ?? double.infinity),
      );
  }

  void _useAndSort(List<Pharmacy> list) {
    if (_query.isEmpty) {
      all = List<Pharmacy>.from(list);
    } else {
      all = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(_query) ||
                p.address.toLowerCase().contains(_query),
          )
          .toList();
    }
    items = List<Pharmacy>.from(all);
    if (selected != null && !items.contains(selected)) {
      selected = null;
    }
  }

  List<Pharmacy>? get _currentCache =>
      _scope == PharmacyScope.onDuty ? _cacheOnDuty : _cacheRegular;

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw _LocationAccessException('Konum servisleri kapalı.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw _LocationAccessException('Konum izni verilmedi.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw _LocationAccessException('Konum izni kalıcı reddedildi.');
    }
  }

  List<Pharmacy> _mockPharmacies() {
    return const <Pharmacy>[
      Pharmacy(
        name: 'Taksim Şifa Eczanesi',
        address: 'Gümüşsuyu Mah. İnönü Cad. No:28 Beyoğlu/İstanbul',
        lat: 41.0378,
        lng: 28.9862,
        phone: '+90 212 123 45 01',
      ),
      Pharmacy(
        name: 'Cumhuriyet Eczanesi',
        address: 'Kocatepe Mah. Aşıklar Sok. No:6 Beyoğlu/İstanbul',
        lat: 41.0354,
        lng: 28.9879,
        phone: '+90 212 123 45 02',
      ),
      Pharmacy(
        name: 'Talimhane Eczanesi',
        address: 'Şehit Muhtar Mah. Kurabiye Sok. No:10 Beyoğlu/İstanbul',
        lat: 41.0389,
        lng: 28.984,
        phone: '+90 212 123 45 03',
      ),
      Pharmacy(
        name: 'Cihangir Eczanesi',
        address: 'Cihangir Mah. Defterdar Yokuşu No:18 Beyoğlu/İstanbul',
        lat: 41.0315,
        lng: 28.9868,
        phone: '+90 212 123 45 04',
      ),
      Pharmacy(
        name: 'Sıraselviler Eczanesi',
        address: 'Sıraselviler Cad. No:80 Beyoğlu/İstanbul',
        lat: 41.0347,
        lng: 28.9871,
        phone: '+90 212 123 45 05',
      ),
    ];
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  String _shortError(String message) {
    if (message.length <= 160) {
      return message;
    }
    return '${message.substring(0, 157)}...';
  }
}

class _LocationAccessException implements Exception {
  _LocationAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}
