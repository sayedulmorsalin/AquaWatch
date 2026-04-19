import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
    };
  }

  @override
  String toString() {
    return address ?? '$latitude, $longitude';
  }
}

class LocationService {
  static Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: '${placemark?.street ?? ''}, ${placemark?.locality ?? ''}',
        city: placemark?.locality,
        country: placemark?.country,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<LocationData?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception('Address not found');
      }

      final location = locations.first;
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      return LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        address: '${placemark?.street ?? ''}, ${placemark?.locality ?? ''}',
        city: placemark?.locality,
        country: placemark?.country,
      );
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
