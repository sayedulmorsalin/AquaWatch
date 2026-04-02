import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeoMap extends StatefulWidget {
  const GeoMap({super.key});

  @override
  State<GeoMap> createState() => _GeoMapState();
}

class _GeoMapState extends State<GeoMap> with TickerProviderStateMixin {
  late AnimationController _panelController;
  late Animation<double> _panelSlide;
  late MapController _mapController;

  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _panelExpanded = false;
  int? _selectedStationIndex;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _verifiedReadingsSub;

  final List<Map<String, dynamic>> _waterStations = [];

  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _mapController = MapController();
    _verifiedReadingsSub = FirebaseFirestore.instance
        .collection('verified_water_quality_readings')
        .orderBy('approvedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          _syncVerifiedReadings(snapshot.docs);
        });

    _panelController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _panelSlide = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _verifiedReadingsSub?.cancel();
    _panelController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _waterStations.where((s) {
        final matchesStatus =
            _selectedFilter == 'All' || s['status'] == _selectedFilter;
        final matchesQuery =
            query.isEmpty ||
            s['name'].toString().toLowerCase().contains(query) ||
            s['area'].toString().toLowerCase().contains(query);
        return matchesStatus && matchesQuery;
      }).toList();
    });
  }

  void _syncVerifiedReadings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    _waterStations
      ..clear()
      ..addAll(
        docs
            .map((doc) {
              final data = doc.data();
              final lat = (data['latitude'] as num?)?.toDouble();
              final lng = (data['longitude'] as num?)?.toDouble();
              if (lat == null || lng == null) {
                return <String, dynamic>{};
              }

              final status = (data['overallQuality'] ?? 'Unknown').toString();
              final userName = (data['userName'] ?? 'Submitted Reading')
                  .toString();
              final submittedBy = (data['userEmail'] ?? 'Unknown').toString();

              return {
                'name': userName,
                'area': submittedBy,
                'ph': (data['ph'] as num?)?.toDouble() ?? 0.0,
                'tds': (data['tds'] as num?)?.toDouble() ?? 0.0,
                'ec': (data['ec'] as num?)?.toDouble() ?? 0.0,
                'salinity': (data['salinity'] as num?)?.toDouble() ?? 0.0,
                'temperature': (data['temperature'] as num?)?.toDouble() ?? 0.0,
                'status': status,
                'lat': lat,
                'lng': lng,
              };
            })
            .where((item) => item.isNotEmpty),
      );

    _applyFilters();
  }

  void _selectFilter(String status) {
    _selectedFilter = status;
    _applyFilters();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Excellent':
        return const Color(0xFF00E676);
      case 'Good':
        return const Color(0xFF29B6F6);
      case 'Fair':
        return const Color(0xFFFFA726);
      case 'Poor':
      case 'Unsafe':
      case 'Dangerous':
        return const Color(0xFFFF5252);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Excellent':
        return Icons.verified_rounded;
      case 'Good':
        return Icons.thumb_up_alt_rounded;
      case 'Fair':
        return Icons.info_rounded;
      case 'Poor':
      case 'Unsafe':
      case 'Dangerous':
        return Icons.warning_amber_rounded;
      default:
        return Icons.help_outline;
    }
  }

  void _flyTo(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 13);
  }

  void _togglePanel() {
    setState(() => _panelExpanded = !_panelExpanded);
    if (_panelExpanded) {
      _panelController.forward();
    } else {
      _panelController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D1B2A).withValues(alpha: 0.92),
                    const Color(0xFF0D1B2A).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildCircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Water Monitoring Map',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap a marker for details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCircleButton(
                          icon: _panelExpanded
                              ? Icons.map_rounded
                              : Icons.list_rounded,
                          onTap: _togglePanel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSearchBar(),
                    const SizedBox(height: 8),
                    _buildFilterRow(),
                  ],
                ),
              ),
            ),
          ),

          _buildBottomPanel(),

          Positioned(
            bottom: _panelExpanded ? null : 24,
            top: _panelExpanded ? null : null,
            left: 0,
            right: 0,
            child: _panelExpanded
                ? const SizedBox.shrink()
                : Center(
                    child: GestureDetector(
                      onTap: _togglePanel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0D1B2A,
                          ).withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.water_drop_rounded,
                              color: Colors.cyanAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_filtered.length} station${_filtered.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(23.81, 90.38),
        zoom: 10,
        maxZoom: 18,
        minZoom: 5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.aquawatch',
        ),
        PolygonLayer(
          polygons: [
            Polygon(
              points: [
                LatLng(22.0, 88.0),
                LatLng(26.5, 88.0),
                LatLng(26.5, 92.5),
                LatLng(22.0, 92.5),
              ],
              color: Colors.cyan.withValues(alpha: 0.08),
              borderColor: Colors.cyanAccent.withValues(alpha: 0.35),
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
        MarkerLayer(
          markers: _filtered.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final color = _statusColor(s['status']);
            final isSelected = _selectedStationIndex == i;

            return Marker(
              point: LatLng(s['lat'], s['lng']),
              width: isSelected ? 52 : 44,
              height: isSelected ? 52 : 44,
              builder: (ctx) => GestureDetector(
                onTap: () {
                  setState(() => _selectedStationIndex = i);
                  _showStationSheet(s);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: isSelected ? 52 : 44,
                        height: isSelected ? 52 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.9,
                            stops: const [0.0, 0.35, 0.7, 1.0],
                            colors: [
                              color.withValues(alpha: isSelected ? 0.9 : 0.8),
                              color.withValues(alpha: isSelected ? 0.45 : 0.32),
                              color.withValues(alpha: isSelected ? 0.16 : 0.1),
                              color.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(
                                alpha: isSelected ? 0.55 : 0.4,
                              ),
                              blurRadius: isSelected ? 16 : 10,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.water_drop_rounded,
                        color: Colors.white.withValues(alpha: 0.95),
                        size: isSelected ? 24 : 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A).withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search stations...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    const filters = ['All', 'Excellent', 'Good', 'Fair', 'Unsafe'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final selected = _selectedFilter == f;
          final color = f == 'All' ? Colors.cyanAccent : _statusColor(f);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.2)
                      : const Color(0xFF0D1B2A).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? color
                        : Colors.white.withValues(alpha: 0.1),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.white60,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return AnimatedBuilder(
      animation: _panelSlide,
      builder: (context, child) {
        final panelHeight =
            MediaQuery.of(context).size.height * 0.48 * _panelSlide.value;
        if (panelHeight <= 0) return const SizedBox.shrink();

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: panelHeight,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A).withValues(alpha: 0.94),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _togglePanel,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_filtered.length} Station${_filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _togglePanel,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_off_rounded,
                                size: 40,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No stations found',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildStationTile(_filtered[i], i),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationTile(Map<String, dynamic> station, int index) {
    final color = _statusColor(station['status']);
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStationIndex = index);
        _flyTo(station['lat'], station['lng']);
        _showStationSheet(station);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(Icons.water_drop_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    station['area'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            _buildMiniMetric('pH', station['ph'].toString()),
            const SizedBox(width: 10),
            _buildMiniMetric('TDS', '${station['tds']}'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                station['status'],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }

  void _showStationSheet(Map<String, dynamic> station) {
    final color = _statusColor(station['status']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0D1B2A), const Color(0xFF1B2838)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _statusIcon(station['status']),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              station['area'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      station['status'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildMetricCard(
                    'pH Level',
                    '${station['ph']}',
                    'pH',
                    Icons.science_outlined,
                    color,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    'TDS',
                    '${station['tds']}',
                    'ppm',
                    Icons.opacity_outlined,
                    color,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricCard(
                    'EC',
                    '${station['ec']}',
                    'µS/cm',
                    Icons.electric_bolt_outlined,
                    color,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    'Salinity',
                    '${station['salinity']}',
                    'ppt',
                    Icons.grain_outlined,
                    color,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricCard(
                    'Temperature',
                    '${station['temperature']}',
                    '°C',
                    Icons.thermostat_outlined,
                    color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Coordinates',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${station['lat']}, ${station['lng']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _flyTo(station['lat'], station['lng']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.2),
                    foregroundColor: color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: color.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_fixed_rounded, size: 18, color: color),
                      const SizedBox(width: 8),
                      Text(
                        'Center on Map',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color accent,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
