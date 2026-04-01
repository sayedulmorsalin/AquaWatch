import 'package:flutter/material.dart';
import 'data_analysis_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DataEntry extends StatefulWidget {
  const DataEntry({super.key});

  @override
  State<DataEntry> createState() => _DataEntryState();
}

class _DataEntryState extends State<DataEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _phController = TextEditingController();
  final _tdsController = TextEditingController();
  final _ecController = TextEditingController();
  final _salinityController = TextEditingController();
  final _temperatureController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phController.dispose();
    _tdsController.dispose();
    _ecController.dispose();
    _salinityController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  Future<Position> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception(
        'Location services are disabled. Please enable location services in your device settings.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please grant location permission to save water quality readings with location data.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception(
        'Location permission permanently denied. Opening app settings. Please enable location permission for this app.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      throw Exception(
        'Failed to get location: $e. Make sure location services are enabled.',
      );
    }
  }

  Future<void> _saveReadingToFirestore({
    required double ph,
    required double tds,
    required double ec,
    required double salinity,
    required double temperature,
    required double latitude,
    required double longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Please sign in before submitting data.',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('water_quality_readings')
        .add({
          'ph': ph,
          'tds': tds,
          'ec': ec,
          'salinity': salinity,
          'temperature': temperature,
          'latitude': latitude,
          'longitude': longitude,
          'userId': user.uid,
          'userEmail': user.email,
          'userName': user.displayName,
          'submittedAt': FieldValue.serverTimestamp(),
        });
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

    setState(() => _isLoading = true);

    try {
      // Get user location
      double latitude = 0.0;
      double longitude = 0.0;
      bool locationSaved = false;

      try {
        final position = await _getUserLocation();
        latitude = position.latitude;
        longitude = position.longitude;
        locationSaved = true;
      } catch (locError) {
        if (!mounted) {
          setState(() => _isLoading = false);
          return;
        }

        // Show dialog asking user if they want to continue without location
        final shouldContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Location Not Available'),
            content: Text(
              'Error: ${locError.toString()}\n\nDo you want to save the data without location information?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue Without Location'),
              ),
            ],
          ),
        );

        if (shouldContinue == false || shouldContinue == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Save to Firestore
      await _saveReadingToFirestore(
        ph: ph,
        tds: tds,
        ec: ec,
        salinity: salinity,
        temperature: temperature,
        latitude: latitude,
        longitude: longitude,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Show success message with location status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locationSaved
                ? 'Data saved successfully with location!'
                : 'Data saved successfully (no location captured).',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to analysis report
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
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
                        child: Icon(Icons.arrow_back, color: Colors.white),
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
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _tdsController,
                                  label: 'TDS (Total Dissolved Solids)',
                                  icon: Icons.opacity_outlined,
                                  unit: 'ppm',
                                  hint: '0 - 2000',
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _ecController,
                                  label: 'Electrical Conductivity (EC)',
                                  icon: Icons.electric_bolt_outlined,
                                  unit: 'µS/cm',
                                  hint: '0 - 2000',
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _salinityController,
                                  label: 'Salinity',
                                  icon: Icons.grain_outlined,
                                  unit: 'ppt',
                                  hint: '0 - 50',
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _temperatureController,
                                  label: 'Temperature',
                                  icon: Icons.thermostat_outlined,
                                  unit: '°C',
                                  hint: '0 - 50',
                                ),
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
          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
      ],
    );
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
