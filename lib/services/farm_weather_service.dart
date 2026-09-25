import 'dart:convert';

import 'package:http/http.dart' as http;

class FarmWeatherService {
  Future<Map<String, dynamic>> forecastFor(String place) async {
    final name = place.trim().isEmpty ? 'Colombo' : place.trim();
    final geocodeUri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': name, 'count': '1', 'language': 'en', 'format': 'json',
    });
    final geocode = await http.get(geocodeUri).timeout(const Duration(seconds: 12));
    if (geocode.statusCode != 200) throw Exception('Weather location lookup failed.');
    final results = (jsonDecode(geocode.body)['results'] as List?) ?? const [];
    if (results.isEmpty) throw Exception('No forecast location found for $name.');
    final location = Map<String, dynamic>.from(results.first as Map);
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${location['latitude']}',
      'longitude': '${location['longitude']}',
      'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum',
      'timezone': 'auto', 'forecast_days': '7',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw Exception('Weather forecast is unavailable.');
    return {'location': location, ...Map<String, dynamic>.from(jsonDecode(response.body) as Map)};
  }
}
