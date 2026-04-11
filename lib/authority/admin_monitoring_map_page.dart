import 'dart:math' as math;
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminMonitoringMapPage extends StatefulWidget {
  const AdminMonitoringMapPage({super.key});

  @override
  State<AdminMonitoringMapPage> createState() => _AdminMonitoringMapPageState();
}

class _AdminMonitoringMapPageState extends State<AdminMonitoringMapPage> {
  final MapController _mapController = MapController();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<_MonitoringReading> _readings = const [];
  List<_MonitoringReading> _filteredReadings = const [];
  _MonitoringReading? _selectedReading;
  double _radiusKm = 1;
  LatLng? _currentCenter;
  double _currentZoom = 14;
  bool _loading = true;

  void _updateFilteredReadings() {
    final center = _currentCenter;
    if (center == null) {
      _filteredReadings = List.from(_readings);
      return;
    }

    debugPrint('--- Filtering Updates ---');
    debugPrint('Center coordinates: ${center.latitude}, ${center.longitude}');
    debugPrint('Radius: $_radiusKm km');

    _filteredReadings = _readings.where((reading) {
      final distance = _distanceKm(
        center.latitude,
        center.longitude,
        reading.latitude,
        reading.longitude,
      );
      debugPrint('Distance to reading ${reading.id}: $distance km');
      return distance <= _radiusKm;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _subscription = FirebaseFirestore.instance
        .collection('water_quality_readings')
        .where('verificationStatus', isEqualTo: 'approved')
        .snapshots()
        .listen(_onReadingsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (mounted) {
          setState(() {
            _currentCenter = _mapController.center;
            _currentZoom = _mapController.zoom;
            _updateFilteredReadings();
          });
        }
        _mapController.mapEventStream.listen((mapEvent) {
          if (mounted) {
            final newCenter = _mapController.center;
            final newZoom = _mapController.zoom;
            if (_currentCenter?.latitude != newCenter.latitude || 
                _currentCenter?.longitude != newCenter.longitude ||
                _currentZoom != newZoom) {
              setState(() {
                _currentCenter = newCenter;
                _currentZoom = newZoom;
                _updateFilteredReadings();
              });
            }
          }
        });
      } catch (e) {
        debugPrint('Error setting up map listener: $e');
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _onReadingsChanged(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final nextReadings = <_MonitoringReading>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final latitude = _toDouble(data['latitude']);
      final longitude = _toDouble(data['longitude']);
      if (latitude == null || longitude == null) {
        continue;
      }

      final userId = data['userId']?.toString();
      var userName = 'Submitted Reading';
      var userEmail = 'Unknown';

      if (userId != null && userId.isNotEmpty) {
        try {
          final userDoc = await firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            userName = userData?['name']?.toString() ?? userName;
            userEmail = userData?['email']?.toString() ?? userEmail;
          }
        } catch (_) {
          // Keep defaults when the user record cannot be loaded.
        }
      }

      nextReadings.add(
        _MonitoringReading(
          id: doc.id,
          userName: userName,
          userEmail: userEmail,
          latitude: latitude,
          longitude: longitude,
          overallQuality: (data['overallQuality'] ?? 'Unknown').toString(),
          ph: _toDouble(data['ph']) ?? 0,
          tds: _toDouble(data['tds']) ?? 0,
          ec: _toDouble(data['ec']) ?? 0,
          salinity: _toDouble(data['salinity']) ?? 0,
          temperature: _toDouble(data['temperature']) ?? 0,
          status: (data['verificationStatus'] ?? 'approved').toString(),
          submittedAt:
              (data['verifiedAt'] as Timestamp?)?.toDate() ??
              (data['submittedAt'] as Timestamp?)?.toDate(),
        ),
      );
    }

    nextReadings.sort((a, b) {
      final aTime = a.submittedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.submittedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _readings = nextReadings;
      _updateFilteredReadings();
      _selectedReading = _readings.isNotEmpty
          ? _selectedReading == null
                ? _readings.first
                : _readings.firstWhere(
                    (reading) => reading.id == _selectedReading!.id,
                    orElse: () => _readings.first,
                  )
          : null;
      _loading = false;
    });
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _selectReading(_MonitoringReading reading) {
    setState(() => _selectedReading = reading);
    _mapController.move(LatLng(reading.latitude, reading.longitude), 13);
  }

  double get _metersPerPixel {
    if (_currentCenter == null) return 1;
    final lat = _currentCenter!.latitude;
    final metersPerPixelAtEquator = 156543.03392 / math.pow(2, _currentZoom);
    return metersPerPixelAtEquator * math.cos(lat * math.pi / 180);
  }

  double get _pixelRadius {
    return (_radiusKm * 1000) / _metersPerPixel;
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  Color _qualityColor(String value) {
    switch (value.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF2ECC71);
      case 'good':
        return const Color(0xFF29B6F6);
      case 'acceptable':
      case 'fair':
        return const Color(0xFFFFB74D);
      case 'poor':
      case 'unsafe':
      case 'dangerous':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.white70;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Unknown time';
    }
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedReading;

    return Scaffold(
      backgroundColor: const Color(0xFF06131F),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  _buildHeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Monitoring Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Use the circle to find readings in an area',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10263D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fixed geographic area: ${_radiusKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: _radiusKm,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: '${_radiusKm.toStringAsFixed(1)} km',
                      onChanged: _currentCenter == null
                          ? null
                          : (value) {
                              setState(() {
                                _radiusKm = value;
                                _updateFilteredReadings();
                              });
                            },
                    ),
                    Text(
                      _currentCenter == null
                          ? 'Loading map area...'
                          : 'Pan and zoom the map to adjust the search circle.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _readings.isEmpty
                  ? const Center(
                      child: Text(
                        'No approved readings found.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      center: LatLng(
                                        selected?.latitude ?? 23.81,
                                        selected?.longitude ?? 90.38,
                                      ),
                                      zoom: 14,
                                      maxZoom: 18,
                                      minZoom: 5,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.example.aquawatch',
                                      ),
                                      CircleLayer(
                                        circles: _currentCenter == null
                                            ? const []
                                            : [
                                                CircleMarker(
                                                  point: _currentCenter!,
                                                  color: Colors.transparent,
                                                  borderColor: const Color(0xFF8B5CF6),
                                                  borderStrokeWidth: 5,
                                                  useRadiusInMeter: false,
                                                  radius: _pixelRadius,
                                                ),
                                              ],
                                      ),
                                      MarkerLayer(
                                        markers: _filteredReadings
                                            .map(
                                              (reading) => Marker(
                                                point: LatLng(
                                                  reading.latitude,
                                                  reading.longitude,
                                                ),
                                                  width: 58,
                                                  height: 58,
                                                  builder: (context) {
                                                    final isSelected =
                                                        selected?.id ==
                                                        reading.id;
                                                    return GestureDetector(
                                                      onTap: () =>
                                                          _selectReading(reading),
                                                      child: AnimatedContainer(
                                                        duration: const Duration(
                                                          milliseconds: 220,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color:
                                                              _qualityColor(
                                                                reading
                                                                    .overallQuality,
                                                              ).withValues(
                                                                alpha: isSelected
                                                                    ? 0.95
                                                                    : 0.72,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors.white,
                                                            width: isSelected
                                                                ? 3
                                                                : 2,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black
                                                                  .withValues(
                                                                    alpha: 0.25,
                                                                  ),
                                                              blurRadius:
                                                                  isSelected
                                                                  ? 18
                                                                  : 10,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .water_drop_rounded,
                                                          color: Colors.white,
                                                          size: isSelected
                                                              ? 28
                                                              : 22,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                              .toList(),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF0E1B2A,
                                        ).withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        'Total approved: ${_readings.length}  |  In circle: ${_filteredReadings.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 5,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10263D),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Area details',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentCenter == null
                                          ? 'Loading map area...'
                                          : 'Showing ${_filteredReadings.length} of ${_readings.length} total approved readings.',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildAreaDetailRow(
                                      'Circle center',
                                      _currentCenter == null
                                          ? 'Loading...'
                                          : '${_currentCenter!.latitude.toStringAsFixed(5)}, ${_currentCenter!.longitude.toStringAsFixed(5)}',
                                    ),
                                    _buildAreaDetailRow(
                                      'Circle radius',
                                      '${_radiusKm.toStringAsFixed(1)} km',
                                    ),
                                    _buildAreaDetailRow(
                                      'Readings in circle',
                                      _filteredReadings.length.toString(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_filteredReadings.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10263D),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Text(
                                    'No approved readings are inside the selected circle.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              else
                                ..._filteredReadings.map((reading) {
                                  final isSelected = selected?.id == reading.id;
                                  final accent = _qualityColor(
                                    reading.overallQuality,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: GestureDetector(
                                      onTap: () => _selectReading(reading),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? accent.withValues(alpha: 0.16)
                                              : const Color(0xFF10263D),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? accent
                                                : Colors.white.withValues(
                                                    alpha: 0.08,
                                                  ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    reading.userName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: accent.withValues(
                                                      alpha: 0.16,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    reading.overallQuality,
                                                    style: TextStyle(
                                                      color: accent,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              reading.userEmail,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'pH ${reading.ph.toStringAsFixed(2)}  |  TDS ${reading.tds.toStringAsFixed(2)}  |  EC ${reading.ec.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Salinity ${reading.salinity.toStringAsFixed(2)}  |  Temperature ${reading.temperature.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Location ${reading.latitude.toStringAsFixed(5)}, ${reading.longitude.toStringAsFixed(5)}',
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDate(reading.submittedAt),
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAreaDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringReading {
  const _MonitoringReading({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.latitude,
    required this.longitude,
    required this.overallQuality,
    required this.ph,
    required this.tds,
    required this.ec,
    required this.salinity,
    required this.temperature,
    required this.status,
    required this.submittedAt,
  });

  final String id;
  final String userName;
  final String userEmail;
  final double latitude;
  final double longitude;
  final String overallQuality;
  final double ph;
  final double tds;
  final double ec;
  final double salinity;
  final double temperature;
  final String status;
  final DateTime? submittedAt;
}
