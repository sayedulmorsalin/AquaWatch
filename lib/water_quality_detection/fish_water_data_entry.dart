import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:aquawatch/services/fish_water_ai_service.dart';
import 'fish_water_analysis_report.dart';

enum FishLocationMode { auto, manual }

class FishWaterDataEntryPage extends StatefulWidget {
  const FishWaterDataEntryPage({super.key});

  @override
  State<FishWaterDataEntryPage> createState() => _FishWaterDataEntryPageState();
}

class _FishWaterDataEntryPageState extends State<FishWaterDataEntryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();

  CommercialFishSpecies _selectedSpecies = CommercialFishSpecies.tilapia;
  FarmingSystemType _selectedSystem = FarmingSystemType.earthenPond;

  final _pondNameController = TextEditingController(text: 'Commercial Pond #1');
  final _doController = TextEditingController(text: '5.8');
  final _phController = TextEditingController(text: '7.6');
  final _tempController = TextEditingController(text: '28.5');
  final _tanController = TextEditingController(text: '0.40');
  final _nitriteController = TextEditingController(text: '0.15');
  final _salinityController = TextEditingController(text: '0.5');
  final _tdsController = TextEditingController(text: '380');
  final _ecController = TextEditingController(text: '620');
  final _transparencyController = TextEditingController(text: '32');

  final List<XFile> _testImages = [];

  bool _isLoading = false;
  FishLocationMode _locationMode = FishLocationMode.auto;
  LatLng _manualMapCenter = LatLng(23.8103, 90.4125);
  LatLng? _selectedManualLocation;
  LatLng? _autoSelectedLocation;
  String? _autoLocationError;
  bool _isLocatingAuto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _captureAutoLocation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _pondNameController.dispose();
    _doController.dispose();
    _phController.dispose();
    _tempController.dispose();
    _tanController.dispose();
    _nitriteController.dispose();
    _salinityController.dispose();
    _tdsController.dispose();
    _ecController.dispose();
    _transparencyController.dispose();
    super.dispose();
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
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _autoSelectedLocation = latLng;
        _manualMapCenter = latLng;
        _autoLocationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _autoLocationError = e.toString().replaceFirst('Exception: ', '');
      });
      if (showErrorSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_autoLocationError ?? 'Could not retrieve GPS location'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocatingAuto = false);
    }
  }

  Future<Position> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw Exception('Device location service is disabled');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<void> _pickTestImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _testImages.add(picked);
      });
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      if (preset == 'tilapia') {
        _selectedSpecies = CommercialFishSpecies.tilapia;
        _selectedSystem = FarmingSystemType.earthenPond;
        _pondNameController.text = 'Tilapia Pond #2';
        _doController.text = '5.6';
        _phController.text = '7.5';
        _tempController.text = '29.0';
        _tanController.text = '0.35';
        _nitriteController.text = '0.12';
        _salinityController.text = '0.4';
        _tdsController.text = '350';
        _ecController.text = '580';
        _transparencyController.text = '30';
      } else if (preset == 'biofloc') {
        _selectedSpecies = CommercialFishSpecies.catfish;
        _selectedSystem = FarmingSystemType.biofloc;
        _pondNameController.text = 'Biofloc Tank B-1';
        _doController.text = '6.4';
        _phController.text = '7.2';
        _tempController.text = '28.0';
        _tanController.text = '0.90';
        _nitriteController.text = '0.25';
        _salinityController.text = '2.5';
        _tdsController.text = '1100';
        _ecController.text = '1800';
        _transparencyController.text = '15';
      } else if (preset == 'pangas') {
        _selectedSpecies = CommercialFishSpecies.pangasius;
        _selectedSystem = FarmingSystemType.earthenPond;
        _pondNameController.text = 'Pangas Commercial Farm';
        _doController.text = '4.2';
        _phController.text = '7.8';
        _tempController.text = '30.5';
        _tanController.text = '0.65';
        _nitriteController.text = '0.20';
        _salinityController.text = '0.3';
        _tdsController.text = '420';
        _ecController.text = '710';
        _transparencyController.text = '24';
      } else if (preset == 'shrimp') {
        _selectedSpecies = CommercialFishSpecies.shrimp;
        _selectedSystem = FarmingSystemType.earthenPond;
        _pondNameController.text = 'Shrimp Brackish Pond #4';
        _doController.text = '6.2';
        _phController.text = '8.1';
        _tempController.text = '29.5';
        _tanController.text = '0.25';
        _nitriteController.text = '0.10';
        _salinityController.text = '18.0';
        _tdsController.text = '15200';
        _ecController.text = '24000';
        _transparencyController.text = '35';
      }
    });
  }

  void _runAiAnalysis() {
    final double? doVal = double.tryParse(_doController.text.trim());
    final double? phVal = double.tryParse(_phController.text.trim());
    final double? tempVal = double.tryParse(_tempController.text.trim());
    final double? tanVal = double.tryParse(_tanController.text.trim());
    final double? nitriteVal = double.tryParse(_nitriteController.text.trim());
    final double? salinityVal = double.tryParse(_salinityController.text.trim());
    final double? tdsVal = double.tryParse(_tdsController.text.trim());
    final double? ecVal = double.tryParse(_ecController.text.trim());
    final double? transVal = double.tryParse(_transparencyController.text.trim());

    if (doVal == null || phVal == null || tempVal == null || tanVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid DO, pH, Temperature, and Ammonia (TAN) values.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final analysis = FishWaterAiService.analyze(
        species: _selectedSpecies,
        systemType: _selectedSystem,
        pondName: _pondNameController.text.trim(),
        dissolvedOxygen: doVal,
        ph: phVal,
        temperature: tempVal,
        ammoniaTan: tanVal,
        nitrite: nitriteVal,
        salinity: salinityVal ?? 0.0,
        tds: tdsVal ?? 0.0,
        ec: ecVal ?? 0.0,
        transparency: transVal,
      );

      final LatLng? finalLocation = _locationMode == FishLocationMode.auto
          ? _autoSelectedLocation
          : (_selectedManualLocation ?? _manualMapCenter);

      final double lat = finalLocation?.latitude ?? 23.8103;
      final double lng = finalLocation?.longitude ?? 90.4125;
      final bool locationCaptured = finalLocation != null;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FishWaterAnalysisReportPage(
            analysis: analysis,
            latitude: lat,
            longitude: lng,
            locationCaptured: locationCaptured,
            attachedImages: _testImages,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF031926),
              Color(0xFF0B2545),
              Color(0xFF134074),
              Color(0xFF006494),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildPresetRow(),
                  const SizedBox(height: 18),
                  _buildSpeciesSelector(),
                  const SizedBox(height: 18),
                  _buildSystemSelector(),
                  const SizedBox(height: 18),
                  _buildPondIdentityField(),
                  const SizedBox(height: 18),
                  _buildVitalParametersSection(),
                  const SizedBox(height: 18),
                  _buildMineralParametersSection(),
                  const SizedBox(height: 18),
                  _buildPhotoSection(),
                  const SizedBox(height: 18),
                  _buildLocationSection(),
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Fish Water AI',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00E676)),
                    ),
                    child: const Text(
                      'AI DRIVEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Commercial Aquaculture Water Quality & Pond Health',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Presets / Auto-fill:',
          style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _presetChip('Tilapia Earthen', () => _applyPreset('tilapia')),
              _presetChip('Biofloc Catfish', () => _applyPreset('biofloc')),
              _presetChip('Commercial Pangas', () => _applyPreset('pangas')),
              _presetChip('Vannamei Shrimp', () => _applyPreset('shrimp')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetChip(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSpeciesSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.set_meal_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Target Fish / Aquatic Species',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CommercialFishSpecies.values.map((sp) {
              final isSelected = sp == _selectedSpecies;
              final criteria = FishWaterAiService.speciesDatabase[sp]!;
              return ChoiceChip(
                selected: isSelected,
                onSelected: (val) {
                  if (val) setState(() => _selectedSpecies = sp);
                },
                selectedColor: Colors.cyan.shade600,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                label: Text(
                  criteria.commonName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            FishWaterAiService.speciesDatabase[_selectedSpecies]!.description,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waves_rounded, color: Colors.tealAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Aquaculture Farming System',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _systemChip(FarmingSystemType.earthenPond, 'Earthen Pond'),
              _systemChip(FarmingSystemType.biofloc, 'Biofloc (BFT) Tank'),
              _systemChip(FarmingSystemType.ras, 'Recirculating (RAS)'),
              _systemChip(FarmingSystemType.cageCulture, 'Cage / Pen Culture'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _systemChip(FarmingSystemType type, String label) {
    final isSelected = _selectedSystem == type;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedSystem = type);
      },
      selectedColor: Colors.teal.shade600,
      backgroundColor: Colors.white.withValues(alpha: 0.10),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildPondIdentityField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pond / Tank Identifier',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pondNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Nursery Pond 1, Grow-out #3',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              prefixIcon: const Icon(Icons.tag_rounded, color: Colors.white60),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalParametersSection() {
    final criteria = FishWaterAiService.speciesDatabase[_selectedSpecies]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Core Biological Vital Parameters',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _doController,
            label: 'Dissolved Oxygen (DO)',
            unit: 'mg/L',
            hint: 'Opt: ${criteria.optimalDoMin} - ${criteria.optimalDoMax} mg/L',
            icon: Icons.air_rounded,
            color: Colors.cyanAccent,
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _phController,
            label: 'Water pH Level',
            unit: 'pH',
            hint: 'Opt: ${criteria.optimalPhMin} - ${criteria.optimalPhMax}',
            icon: Icons.science_outlined,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _tempController,
            label: 'Water Temperature',
            unit: '°C',
            hint: 'Opt: ${criteria.optimalTempMin} - ${criteria.optimalTempMax} °C',
            icon: Icons.thermostat_outlined,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _tanController,
            label: 'Total Ammonia Nitrogen (TAN)',
            unit: 'mg/L',
            hint: 'Safe: < ${criteria.maxSafeTan} mg/L',
            icon: Icons.bubble_chart_rounded,
            color: Colors.deepOrangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildMineralParametersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Colors.lightGreenAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Secondary & Mineral Parameters',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _nitriteController,
            label: 'Nitrite (NO₂⁻) [Optional]',
            unit: 'mg/L',
            hint: 'Safe: < 0.2 mg/L',
            icon: Icons.water_drop_outlined,
            color: Colors.purpleAccent,
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _salinityController,
            label: 'Salinity',
            unit: 'ppt',
            hint: 'Freshwater: 0 - 2 ppt',
            icon: Icons.grain_rounded,
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _tdsController,
            label: 'TDS (Total Dissolved Solids)',
            unit: 'ppm',
            hint: 'e.g. 350 ppm',
            icon: Icons.opacity_rounded,
            color: Colors.indigoAccent,
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _ecController,
            label: 'Electrical Conductivity (EC)',
            unit: 'µS/cm',
            hint: 'e.g. 600 µS/cm',
            icon: Icons.electric_bolt_rounded,
            color: Colors.yellowAccent,
          ),
          const SizedBox(height: 12),
          _inputTile(
            controller: _transparencyController,
            label: 'Secchi Transparency [Optional]',
            unit: 'cm',
            hint: 'Opt: 25 - 40 cm',
            icon: Icons.remove_red_eye_outlined,
            color: Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _inputTile({
    required TextEditingController controller,
    required String label,
    required String unit,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  hint,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                suffixText: ' $unit',
                suffixStyle: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Pond & Meter Photos (Optional)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload photo of digital DO meter, test strip, or pond surface.',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickTestImage,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30, style: BorderStyle.solid),
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: Colors.white70),
                  ),
                ),
                ..._testImages.map(
                  (xfile) => Container(
                    margin: const EdgeInsets.only(left: 10),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(xfile.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Farm / Pond Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              SegmentedButton<FishLocationMode>(
                segments: const [
                  ButtonSegment(value: FishLocationMode.auto, label: Text('GPS Auto')),
                  ButtonSegment(value: FishLocationMode.manual, label: Text('Map')),
                ],
                selected: {_locationMode},
                onSelectionChanged: (set) {
                  setState(() => _locationMode = set.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Colors.cyan.shade700
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_locationMode == FishLocationMode.auto) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _autoSelectedLocation != null
                        ? Icons.check_circle_rounded
                        : Icons.gps_not_fixed_rounded,
                    color: _autoSelectedLocation != null
                        ? const Color(0xFF00E676)
                        : Colors.orangeAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _autoSelectedLocation != null
                          ? 'Lat: ${_autoSelectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_autoSelectedLocation!.longitude.toStringAsFixed(4)}'
                          : (_autoLocationError ?? 'Acquiring GPS location...'),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: _isLocatingAuto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () => _captureAutoLocation(showErrorSnack: true),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    center: _selectedManualLocation ?? _manualMapCenter,
                    zoom: 14.0,
                    onTap: (tapPos, point) {
                      setState(() {
                        _selectedManualLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.aquawatch.app',
                    ),
                    if (_selectedManualLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedManualLocation!,
                            width: 36,
                            height: 36,
                            builder: (ctx) => const Icon(
                              Icons.location_pin,
                              color: Colors.redAccent,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _runAiAnalysis,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          foregroundColor: const Color(0xFF031926),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
        ),
        child: _isLoading
          ? const CircularProgressIndicator(color: Color(0xFF031926))
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 22),
                SizedBox(width: 10),
                Text(
                  'Run AI Commercial Fish Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
      ),
    );
  }
}
