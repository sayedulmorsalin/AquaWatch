import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceRecord {
  const PlaceRecord({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
}

class PlaceRepository {
  PlaceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<PlaceRecord>> findNearbyPlaces({
    required double centerLatitude,
    required double centerLongitude,
    required double radiusKm,
  }) async {
    // Fetch candidate place records, then filter in-memory by geo distance.
    final snapshot = await _firestore.collection('places').get();
    final results = <PlaceRecord>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final latitude = _parseDouble(data['latitude']);
      final longitude = _parseDouble(data['longitude']);
      if (latitude == null || longitude == null) {
        continue;
      }

      final distanceKm = _haversineDistanceKm(
        centerLatitude,
        centerLongitude,
        latitude,
        longitude,
      );

      // Keep only points inside the configurable radius.
      if (distanceKm > radiusKm) {
        continue;
      }

      results.add(
        PlaceRecord(
          id: doc.id,
          name: (data['name'] ?? 'Unknown').toString(),
          address: (data['address'] ?? '').toString(),
          latitude: latitude,
          longitude: longitude,
          distanceKm: distanceKm,
        ),
      );
    }

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }

  double _haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Standard Haversine formula over WGS84 coordinates.
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.pow(math.sin(dLat / 2), 2).toDouble() +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.pow(math.sin(dLon / 2), 2).toDouble();

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
