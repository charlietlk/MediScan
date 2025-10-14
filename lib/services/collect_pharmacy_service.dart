import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/pharmacy.dart';

class CollectPharmacyService {
  const CollectPharmacyService();

  Future<List<Pharmacy>> getRegularByRegion({
    required String city,
    String? district,
    String? query,
  }) async {
    final params = <String, String>{
      'il': city,
      if (district != null && district.trim().isNotEmpty) 'ilce': district,
    };

    final uri = Uri.parse('${AppConsts.collectBase}/health/pharmacy')
        .replace(queryParameters: params);

    final headers = <String, String>{
      'authorization': 'apikey ${AppConsts.collectKey}',
      'content-type': 'application/json',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'CollectAPI error ${response.statusCode}: '
        '${response.body.length > 160 ? '${response.body.substring(0, 157)}...' : response.body}',
      );
    }

    final dynamic body = json.decode(response.body);
    final List<dynamic> list =
        (body['result'] as List?) ?? (body['data'] as List?) ?? <dynamic>[];

    final items = list
        .map(
          (dynamic e) => Pharmacy(
            name: (e['name'] ?? e['pharmacyName'] ?? '').toString(),
            address: (e['address'] ?? '').toString(),
            lat: _toDouble(e['latitude'] ?? e['lat']),
            lng: _toDouble(e['longitude'] ?? e['lng']),
            phone: (e['phone'] ?? '').toString(),
          ),
        )
        .where((p) => p.lat != 0 && p.lng != 0)
        .toList();

    if (query != null && query.trim().isNotEmpty) {
      final normalised = _normalise(query);
      return items
          .where(
            (p) =>
                _normalise(p.name).contains(normalised) ||
                _normalise(p.address).contains(normalised),
          )
          .toList();
    }

    return items;
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String _normalise(String value) => value.trim().toLowerCase();
}
