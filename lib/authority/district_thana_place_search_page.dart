import 'package:flutter/material.dart';

import 'bangladesh_area_data.dart';
import '../services/geocoding_service.dart';
import '../services/place_repository.dart';

class DistrictThanaPlaceSearchPage extends StatefulWidget {
  const DistrictThanaPlaceSearchPage({super.key});

  @override
  State<DistrictThanaPlaceSearchPage> createState() =>
      _DistrictThanaPlaceSearchPageState();
}

class _DistrictThanaPlaceSearchPageState
    extends State<DistrictThanaPlaceSearchPage> {
  final GeocodingService _geocodingService = GeocodingService();
  final PlaceRepository _placeRepository = PlaceRepository();

  late String _selectedDistrict;
  late String _selectedThana;

  bool _isLoading = false;
  String? _error;
  GeoCoordinate? _resolvedCoordinate;
  List<PlaceRecord> _places = const [];

  double _radiusKm = 10;

  @override
  void initState() {
    super.initState();
    _selectedDistrict = districtToThanas.keys.first;
    _selectedThana = districtToThanas[_selectedDistrict]!.first;
  }

  @override
  Widget build(BuildContext context) {
    final thanas = districtToThanas[_selectedDistrict] ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Places Search')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select District and Thana',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
              items: districtToThanas.keys
                  .map(
                    (district) => DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedDistrict = value;
                  final nextThanas =
                      districtToThanas[value] ?? const <String>[];
                  _selectedThana = nextThanas.isNotEmpty
                      ? nextThanas.first
                      : '';
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: thanas.contains(_selectedThana)
                  ? _selectedThana
                  : (thanas.isNotEmpty ? thanas.first : null),
              decoration: const InputDecoration(
                labelText: 'Thana / Upazila',
                border: OutlineInputBorder(),
              ),
              items: thanas
                  .map(
                    (thana) => DropdownMenuItem<String>(
                      value: thana,
                      child: Text(thana),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedThana = value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Search Radius: ${_radiusKm.toStringAsFixed(0)} km',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _radiusKm,
              min: 5,
              max: 30,
              divisions: 25,
              label: '${_radiusKm.toStringAsFixed(0)} km',
              onChanged: (value) => setState(() => _radiusKm = value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _selectedThana.isEmpty
                    ? null
                    : _searchNearbyPlaces,
                icon: const Icon(Icons.search),
                label: const Text('Find Nearby Places'),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildErrorCard(_error!)
            else
              _buildResults(),
          ],
        ),
      ),
    );
  }

  Future<void> _searchNearbyPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _places = const [];
      _resolvedCoordinate = null;
    });

    try {
      final coordinate = await _geocodingService.geocodeDistrictThana(
        district: _selectedDistrict,
        thana: _selectedThana,
      );

      final places = await _placeRepository.findNearbyPlaces(
        centerLatitude: coordinate.latitude,
        centerLongitude: coordinate.longitude,
        radiusKm: _radiusKm,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _resolvedCoordinate = coordinate;
        _places = places;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }

  Widget _buildResults() {
    if (_resolvedCoordinate == null) {
      return const Text(
        'Select a district and thana, then tap "Find Nearby Places".',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolved Coordinates: '
          '${_resolvedCoordinate!.latitude.toStringAsFixed(6)}, '
          '${_resolvedCoordinate!.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'Nearby Results (${_places.length})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (_places.isEmpty)
          const Text('No places found within selected radius.')
        else
          ListView.separated(
            itemCount: _places.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final place = _places[index];
              return Card(
                child: ListTile(
                  title: Text(place.name),
                  subtitle: Text(
                    '${place.address}\n'
                    '${place.latitude.toStringAsFixed(6)}, '
                    '${place.longitude.toStringAsFixed(6)}',
                  ),
                  isThreeLine: true,
                  trailing: Text('${place.distanceKm.toStringAsFixed(2)} km'),
                ),
              );
            },
          ),
      ],
    );
  }
}
