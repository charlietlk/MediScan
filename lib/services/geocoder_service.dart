import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/constants.dart';

class GeocoderService {
  const GeocoderService();

  Future<({String city, String? district})> reverse({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(
      '${AppConsts.nominatimBase}?lat=$lat&lon=$lng&format=json&addressdetails=1&accept-language=tr',
    );

    final response = await http.get(uri, headers: const <String, String>{
      'User-Agent': 'pharmacy-app/1.0',
    });

    if (response.statusCode != 200) {
      throw Exception('Reverse geocoding failed (${response.statusCode})');
    }

    final dynamic data = json.decode(response.body);
    final Map<String, dynamic> address =
        (data['address'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final city =
        (address['city'] ?? address['province'] ?? address['state'] ?? '')
            .toString();
    final district = (address['town'] ??
            address['county'] ??
            address['suburb'] ??
            address['city_district'] ??
            '')
        .toString();

    if (city.isEmpty) {
      throw Exception('City not resolved');
    }

    return (
      city: city,
      district: district.isEmpty ? null : district,
    );
  }
}
