import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'data_analysis_report.dart';

enum LocationInputMode { auto, manual }

class DataEntry extends StatefulWidget {
  const DataEntry({super.key});

  @override
  State<DataEntry> createState() => _DataEntryState();
}

class _DataEntryState extends State<DataEntry>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _picker = ImagePicker();

  final _phController = TextEditingController();
  final _tdsController = TextEditingController();
  final _ecController = TextEditingController();
  final _salinityController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _manualLatitudeController = TextEditingController();
  final _manualLongitudeController = TextEditingController();

  final List<XFile> _phImages = [];
  final List<XFile> _tdsImages = [];
  final List<XFile> _ecImages = [];
  final List<XFile> _salinityImages = [];

  bool _isLoading = false;
  LocationInputMode _locationMode = LocationInputMode.auto;
  LatLng _manualMapCenter = LatLng(23.8103, 90.4125);
  LatLng? _selectedManualLocation;
  LatLng? _autoSelectedLocation;
  String? _autoLocationError;
  bool _isLocatingAuto = false;
  bool _isLocatingMapStart = false;
  bool _retryAutoLocationOnResume = false;
  bool _retryManualLocationOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _locationMode != LocationInputMode.auto) return;
      _captureAutoLocation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _phController.dispose();
    _tdsController.dispose();
    _ecController.dispose();
    _salinityController.dispose();
    _temperatureController.dispose();
    _manualLatitudeController.dispose();
    _manualLongitudeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    if (_retryAutoLocationOnResume && _locationMode == LocationInputMode.auto) {
      _retryAutoLocationOnResume = false;
      _captureAutoLocation(showErrorSnack: false);
    }

    if (_retryManualLocationOnResume &&
        _locationMode == LocationInputMode.manual) {
      _retryManualLocationOnResume = false;
      _centerMapOnCurrentLocation();
    }
  }

  Future<void> _pickImages(List<XFile> images) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    images
      ..clear()
      ..add(pickedFile);

    setState(() {});
  }

  Future<Position> _getUserLocation() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied.');
    }

    final serviceEnabled = await _ensureLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    final lastKnownPosition = await _getRecentLastKnownPosition();
    if (lastKnownPosition != null) {
      return lastKnownPosition;
    }

    return _getFreshLocation();
  }

  Future<Position?> _getRecentLastKnownPosition() async {
    try {
      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition == null) return null;

      final timestamp = lastKnownPosition.timestamp;
      if (timestamp == null) return lastKnownPosition;

      if (DateTime.now().difference(timestamp) <= const Duration(minutes: 10)) {
        return lastKnownPosition;
      }
    } on Exception {
      // Fall through to a fresh GPS lookup if cached data is unavailable.
    }

    return null;
  }

  Future<Position> _getFreshLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
    } on TimeoutException {
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20),
        );
      } on TimeoutException {
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            forceAndroidLocationManager: true,
            timeLimit: const Duration(seconds: 20),
          );
        } on TimeoutException {
          return Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            ),
          ).first.timeout(const Duration(seconds: 15));
        }
      }
    }
  }

  Future<bool> _ensureLocationServiceEnabled() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      return true;
    }

    if (!mounted) return false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Turn on location services'),
          content: const Text(
            'Using your current location needs your device location to be turned on. Enable Location Services, then come back and we will try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () async {
                _markLocationRetryOnResume();
                Navigator.of(dialogContext).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );

    return false;
  }

  void _markLocationRetryOnResume() {
    if (_locationMode == LocationInputMode.auto) {
      _retryAutoLocationOnResume = true;
      _retryManualLocationOnResume = false;
      return;
    }

    _retryManualLocationOnResume = true;
    _retryAutoLocationOnResume = false;
  }

  Future<bool> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Location permission required'),
            content: const Text(
              'Location permission is permanently denied. Please enable it from app settings to use Auto Select.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Not now'),
              ),
              ElevatedButton(
                onPressed: () async {
                  _markLocationRetryOnResume();
                  Navigator.of(dialogContext).pop();
                  await Geolocator.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _captureAutoLocation({bool showErrorSnack = true}) async {
    if (_isLocatingAuto) return;

    setState(() {
      _isLocatingAuto = true;
      _autoLocationError = null;
    });

    try {
      final position = await _getUserLocation();
      if (!mounted) return;

      setState(() {
        _autoSelectedLocation = LatLng(position.latitude, position.longitude);
      });
    } on Exception catch (e) {
      if (!mounted) return;
      final message = e.toString();

      setState(() {
        _autoSelectedLocation = null;
        _autoLocationError = message;
      });

      if (showErrorSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not auto-select location: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingAuto = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_phController.text.isEmpty ||
        _tdsController.text.isEmpty ||
        _ecController.text.isEmpty ||
        _salinityController.text.isEmpty ||
        _temperatureController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_phImages.length != 1 ||
        _tdsImages.length != 1 ||
        _ecImages.length != 1 ||
        _salinityImages.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide exactly 1 image for each field except temperature',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ph = double.tryParse(_phController.text);
    final tds = double.tryParse(_tdsController.text);
    final ec = double.tryParse(_ecController.text);
    final salinity = double.tryParse(_salinityController.text);
    final temperature = double.tryParse(_temperatureController.text);

    if (ph == null ||
        tds == null ||
        ec == null ||
        salinity == null ||
        temperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numeric values'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_locationMode == LocationInputMode.manual) {
      if (_selectedManualLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a location from the map before submitting'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      var latitude = 0.0;
      var longitude = 0.0;
      var locationSaved = false;

      if (_locationMode == LocationInputMode.manual) {
        latitude = _selectedManualLocation!.latitude;
        longitude = _selectedManualLocation!.longitude;
        locationSaved = true;
      } else {
        if (_autoSelectedLocation != null) {
          latitude = _autoSelectedLocation!.latitude;
          longitude = _autoSelectedLocation!.longitude;
          locationSaved = true;
        } else {
          try {
            final position = await _getUserLocation();
            latitude = position.latitude;
            longitude = position.longitude;
            _autoSelectedLocation = LatLng(latitude, longitude);
            locationSaved = true;
          } on Exception catch (locationError) {
            if (!mounted) return;
            final locationMessage = locationError.toString();
            final displayMessage = locationMessage.contains('disabled')
                ? 'Your phone location is turned off. Please enable Location Services, then try again.'
                : locationMessage.contains('permission')
                ? 'Location permission is not available. Please allow location access in app settings, then try again.'
                : 'Could not get location. Please check your GPS and try again.';

            await showDialog<void>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  title: const Text('Location unavailable'),
                  content: Text(displayMessage),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );

            setState(() => _isLoading = false);
            return;
          }
        }
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DataAnalysisReport(
            data: WaterQualityData(
              ph: ph,
              tds: tds,
              ec: ec,
              salinity: salinity,
              temperature: temperature,
              phImages: _phImages,
              tdsImages: _tdsImages,
              ecImages: _ecImages,
              salinityImages: _salinityImages,
              latitude: latitude,
              longitude: longitude,
              locationCaptured: locationSaved,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not continue to analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.cyan.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1.2,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.water_drop,
                                    size: 45,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Water Quality',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter Device Readings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please enter the data from your water quality device',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                _buildDataField(
                                  controller: _phController,
                                  label: 'pH Level',
                                  icon: Icons.science_outlined,
                                  unit: 'pH',
                                  hint: '6.5 - 8.5',
                                  images: _phImages,
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _tdsController,
                                  label: 'TDS (Total Dissolved Solids)',
                                  icon: Icons.opacity_outlined,
                                  unit: 'ppm',
                                  hint: '0 - 2000',
                                  images: _tdsImages,
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _ecController,
                                  label: 'Electrical Conductivity (EC)',
                                  icon: Icons.electric_bolt_outlined,
                                  unit: 'uS/cm',
                                  hint: '0 - 2000',
                                  images: _ecImages,
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _salinityController,
                                  label: 'Salinity',
                                  icon: Icons.grain_outlined,
                                  unit: 'ppt',
                                  hint: '0 - 50',
                                  images: _salinityImages,
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _temperatureController,
                                  label: 'Temperature',
                                  icon: Icons.thermostat_outlined,
                                  unit: 'C',
                                  hint: '0 - 50',
                                ),
                                const SizedBox(height: 16),
                                _buildLocationSelector(),
                                const SizedBox(height: 32),
                                _buildSubmitButton(),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _commonDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.85)),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colorScheme.secondaryContainer,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDataField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String unit,
    required String hint,
    List<XFile>? images,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: _commonDecoration(
            hint: hint,
            icon: icon,
            suffixText: unit,
          ),
        ),
        if (images != null) ...[
          const SizedBox(height: 8),
          Text(
            'Image: ${images.length}/1',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _pickImages(images),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Pick Image'),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.file(
                      File(images[index].path),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildLocationModeButton(
                text: 'Auto Select',
                selected: _locationMode == LocationInputMode.auto,
                onTap: () async {
                  setState(() {
                    _locationMode = LocationInputMode.auto;
                  });

                  // Check location service status first
                  final serviceEnabled =
                      await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled && mounted) {
                    // Show immediate dialog to enable location
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Enable Location Services'),
                          content: const Text(
                            'Location services are currently disabled. Please enable Location Services to use Auto Select location feature.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                _retryAutoLocationOnResume = true;
                                await Geolocator.openLocationSettings();
                              },
                              child: const Text('Enable Location'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }

                  _captureAutoLocation(showErrorSnack: false);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLocationModeButton(
                text: 'Select Own',
                selected: _locationMode == LocationInputMode.manual,
                onTap: () {
                  setState(() {
                    _locationMode = LocationInputMode.manual;
                  });
                },
              ),
            ),
          ],
        ),
        if (_locationMode == LocationInputMode.manual) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    center: _selectedManualLocation ?? _manualMapCenter,
                    zoom: 12,
                    onTap: (_, point) {
                      setState(() {
                        _selectedManualLocation = point;
                        _manualLatitudeController.text = point.latitude
                            .toStringAsFixed(6);
                        _manualLongitudeController.text = point.longitude
                            .toStringAsFixed(6);
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.aquawatch',
                    ),
                    if (_selectedManualLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedManualLocation!,
                            width: 44,
                            height: 44,
                            builder: (context) {
                              return const Icon(
                                Icons.location_pin,
                                color: Colors.redAccent,
                                size: 44,
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedManualLocation == null
                      ? 'Tap on map to select location.'
                      : 'Selected: ${_selectedManualLocation!.latitude.toStringAsFixed(6)}, ${_selectedManualLocation!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: _isLocatingMapStart
                    ? null
                    : _centerMapOnCurrentLocation,
                icon: _isLocatingMapStart
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, color: Colors.white),
                label: const Text(
                  'Use Current',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          if (_isLocatingAuto)
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Detecting current location...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else if (_autoSelectedLocation != null)
            Text(
              'Auto-selected: ${_autoSelectedLocation!.latitude.toStringAsFixed(6)}, ${_autoSelectedLocation!.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            )
          else if (_autoLocationError != null)
            Text(
              'Auto-select failed. Please retry or choose Select Own.',
              style: TextStyle(color: Colors.orange.shade100, fontSize: 12),
            ),
          const SizedBox(height: 6),
          Text(
            'We will use your current device location automatically.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isLocatingAuto
                  ? null
                  : () => _captureAutoLocation(showErrorSnack: true),
              icon: const Icon(Icons.gps_fixed, color: Colors.white),
              label: const Text(
                'Retry Auto Select',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationModeButton({
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? Colors.cyanAccent.withValues(alpha: 0.85)
                : const Color(0xFF113552).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.35),
              width: selected ? 1.6 : 1.1,
            ),
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.blue.shade900 : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _centerMapOnCurrentLocation() async {
    setState(() => _isLocatingMapStart = true);

    try {
      final position = await _getUserLocation();
      if (!mounted) return;

      setState(() {
        final point = LatLng(position.latitude, position.longitude);
        _manualMapCenter = point;
        _selectedManualLocation = point;
        _manualLatitudeController.text = point.latitude.toStringAsFixed(6);
        _manualLongitudeController.text = point.longitude.toStringAsFixed(6);
      });
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not get current location for map: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocatingMapStart = false);
      }
    }
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.blue.shade100]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleSubmit,
          borderRadius: BorderRadius.circular(12),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                )
              : const Center(
                  child: Text(
                    'Submit Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
