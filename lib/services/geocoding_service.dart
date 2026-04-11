import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoCoordinate {
  const GeoCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, GeoCoordinate> _cache = <String, GeoCoordinate>{};
  DateTime? _lastRequestAt;

  Future<GeoCoordinate> geocodeDistrictThana({
    required String district,
    required String thana,
  }) {
    // Normalize user selection into a Nominatim-friendly address query.
    final query = '$thana, $district, Bangladesh';
    return geocodeQuery(query);
  }

  Future<GeoCoordinate> geocodeQuery(String query) async {
    final normalizedKey = query.trim().toLowerCase();
    final cached = _cache[normalizedKey];
    if (cached != null) {
      // In-memory cache avoids repeated API calls for the same place.
      return cached;
    }

    // Nominatim free tier requires low request rate (~1 req/sec).
    await _respectNominatimRateLimit();

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'bd',
      'addressdetails': '0',
    });

    final response = await _client.get(
      uri,
      headers: const {
        'User-Agent': 'AquaWatch/1.0 (Flutter App)',
        'Accept': 'application/json',
      },
    );

    _lastRequestAt = DateTime.now();

    if (response.statusCode != 200) {
      throw GeocodingException(
        'Geocoding API failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty || decoded.first is! Map) {
      throw GeocodingException('No geocoding result found for "$query"');
    }

    final first = decoded.first as Map;
    final lat = double.tryParse((first['lat'] ?? '').toString());
    final lon = double.tryParse((first['lon'] ?? '').toString());

    if (lat == null || lon == null) {
      throw GeocodingException('Invalid geocoding response for "$query"');
    }

    final coordinate = GeoCoordinate(latitude: lat, longitude: lon);
    _cache[normalizedKey] = coordinate;
    return coordinate;
  }

  Future<void> _respectNominatimRateLimit() async {
    final last = _lastRequestAt;
    if (last == null) {
      return;
    }

    final elapsed = DateTime.now().difference(last);
    const minDelay = Duration(seconds: 1);
    if (elapsed < minDelay) {
      await Future<void>.delayed(minDelay - elapsed);
    }
  }
}

class GeocodingException implements Exception {
  GeocodingException(this.message);

  final String message;

  @override
  String toString() => message;
}
