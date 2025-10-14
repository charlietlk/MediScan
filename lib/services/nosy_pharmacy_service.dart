import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/pharmacy.dart';

class NosyPharmacyService {
  const NosyPharmacyService();

  Future<List<Pharmacy>> getOnDutyByLocation({
    required double lat,
    required double lng,
    String? query,
  }) async {
    final uri = Uri.parse(
      '${AppConsts.nosyBase}/pharmacies-on-duty/locations?latitude=$lat&longitude=$lng',
    );

    final response = await http.get(uri, headers: <String, String>{
      'Authorization': 'Bearer ${AppConsts.nosyKey}',
    });

    if (response.statusCode != 200) {
      throw Exception('NosyAPI error ${response.statusCode}');
    }

    final dynamic jsonBody = json.decode(response.body);
    final list = (jsonBody['data'] as List?) ?? <dynamic>[];
    final items = list
        .map(
          (dynamic e) => Pharmacy(
            name: (e['pharmacyName'] ?? e['name'] ?? '').toString(),
            address: (e['address'] ?? '').toString(),
            lat: (e['latitude'] as num?)?.toDouble() ?? 0.0,
            lng: (e['longitude'] as num?)?.toDouble() ?? 0.0,
            phone: (e['phone'] ?? '').toString(),
          ),
        )
        .toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      return items
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.address.toLowerCase().contains(q),
          )
          .toList();
    }

    return items;
  }
}
