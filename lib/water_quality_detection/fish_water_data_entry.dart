import 'package:flutter/material.dart';

import 'package:aquawatch/services/fish_water_ai_service.dart';
import 'fish_water_analysis_report.dart';

class FishWaterDataEntryPage extends StatefulWidget {
  const FishWaterDataEntryPage({super.key});

  @override
  State<FishWaterDataEntryPage> createState() => _FishWaterDataEntryPageState();
}

class _FishWaterDataEntryPageState extends State<FishWaterDataEntryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  CommercialFishSpecies _selectedSpecies = CommercialFishSpecies.generalPond;
  final FarmingSystemType _selectedSystem = FarmingSystemType.earthenPond;
  String? _selectedPreset;

  final _pondNameController = TextEditingController(text: 'Commercial Pond #1');
  final _phController = TextEditingController();
  final _tdsController = TextEditingController();
  final _ecController = TextEditingController();
  final _salinityController = TextEditingController();
  final _temperatureController = TextEditingController();

  // Optional aquaculture specific inputs
  final _doController = TextEditingController();
  final _ammoniaController = TextEditingController();

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
    _pondNameController.dispose();
    _phController.dispose();
    _tdsController.dispose();
    _ecController.dispose();
    _salinityController.dispose();
    _temperatureController.dispose();
    _doController.dispose();
    _ammoniaController.dispose();
    super.dispose();
  }

  void _applyQuickPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset == 'tilapia') {
        _selectedSpecies = CommercialFishSpecies.tilapia;
        _pondNameController.text = 'Tilapia Pond #1';
        _phController.text = '7.5';
        _tdsController.text = '380';
        _ecController.text = '620';
        _salinityController.text = '0.5';
        _temperatureController.text = '28.5';
        _doController.text = '6.2';
        _ammoniaController.text = '0.35';
      } else if (preset == 'carp') {
        _selectedSpecies = CommercialFishSpecies.majorCarp;
        _pondNameController.text = 'Major Carp Pond #1';
        _phController.text = '7.8';
        _tdsController.text = '260';
        _ecController.text = '420';
        _salinityController.text = '0.2';
        _temperatureController.text = '27.0';
        _doController.text = '6.8';
        _ammoniaController.text = '0.20';
      } else if (preset == 'pangas') {
        _selectedSpecies = CommercialFishSpecies.pangasius;
        _pondNameController.text = 'Pangas Pond #1';
        _phController.text = '7.4';
        _tdsController.text = '450';
        _ecController.text = '720';
        _salinityController.text = '0.4';
        _temperatureController.text = '30.0';
        _doController.text = '4.5';
        _ammoniaController.text = '0.60';
      } else if (preset == 'catfish') {
        _selectedSpecies = CommercialFishSpecies.catfish;
        _pondNameController.text = 'Catfish Pond #1';
        _phController.text = '7.2';
        _tdsController.text = '520';
        _ecController.text = '850';
        _salinityController.text = '0.8';
        _temperatureController.text = '29.0';
        _doController.text = '4.0';
        _ammoniaController.text = '0.70';
      } else if (preset == 'acid_water') {
        _selectedSpecies = CommercialFishSpecies.generalPond;
        _pondNameController.text = 'Acidic Pond #1';
        _phController.text = '5.8';
        _tdsController.text = '180';
        _ecController.text = '290';
        _salinityController.text = '0.1';
        _temperatureController.text = '26.5';
        _doController.text = '4.2';
        _ammoniaController.text = '0.20';
      }
    });
  }

  void _handleSubmit() {
    final ph = double.tryParse(_phController.text.trim().replaceAll(',', '.'));
    final tds =
        double.tryParse(_tdsController.text.trim().replaceAll(',', '.'));
    final ec = double.tryParse(_ecController.text.trim().replaceAll(',', '.'));
    final salinity =
        double.tryParse(_salinityController.text.trim().replaceAll(',', '.'));
    final temperature = double.tryParse(
        _temperatureController.text.trim().replaceAll(',', '.'));

    if (ph == null ||
        tds == null ||
        ec == null ||
        salinity == null ||
        temperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all 5 water quality parameters (pH, TDS, EC, Salinity, Temperature).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (ph < 0 || ph > 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('pH value must be between 0 and 14.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (temperature < 0 || temperature > 55) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Temperature must be between 0 and 55 °C.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (tds < 0 || ec < 0 || salinity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TDS, EC, and Salinity cannot be negative values.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double? optionalDo =
        double.tryParse(_doController.text.trim().replaceAll(',', '.'));
    final double? optionalTan =
        double.tryParse(_ammoniaController.text.trim().replaceAll(',', '.'));

    setState(() => _isLoading = true);

    try {
      final analysis = FishWaterAiService.analyze(
        species: _selectedSpecies,
        systemType: _selectedSystem,
        pondName: _pondNameController.text.trim().isEmpty
            ? 'Commercial Pond #1'
            : _pondNameController.text.trim(),
        ph: ph,
        tds: tds,
        ec: ec,
        salinity: salinity,
        temperature: temperature,
        dissolvedOxygen: optionalDo,
        ammoniaTan: optionalTan,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FishWaterAnalysisReportPage(
            analysis: analysis,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.cyan.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
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
                                    Icons.phishing_rounded,
                                    size: 45,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Fish Water Quality',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Enter Test Readings & Get Action Plan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Input the same water quality parameters as potable testing to receive instant AI guidance on what to do with your fish water.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildQuickPresetBar(),
                        const SizedBox(height: 24),
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
                                  hint: 'e.g. 7.5 (Fish safe: 6.5 - 8.5)',
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _tdsController,
                                  label: 'TDS (Total Dissolved Solids)',
                                  icon: Icons.opacity_outlined,
                                  unit: 'ppm',
                                  hint: 'e.g. 350 (Freshwater: 150 - 1000)',
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _ecController,
                                  label: 'Electrical Conductivity (EC)',
                                  icon: Icons.electric_bolt_outlined,
                                  unit: 'µS/cm',
                                  hint: 'e.g. 600',
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _salinityController,
                                  label: 'Salinity',
                                  icon: Icons.grain_outlined,
                                  unit: 'ppt',
                                  hint: 'e.g. 0.5 (Freshwater: 0 - 2 ppt)',
                                ),
                                const SizedBox(height: 16),
                                _buildDataField(
                                  controller: _temperatureController,
                                  label: 'Temperature',
                                  icon: Icons.thermostat_outlined,
                                  unit: '°C',
                                  hint: 'e.g. 28 (Optimal: 26 - 32 °C)',
                                ),
                                const SizedBox(height: 20),
                                _buildOptionalAquacultureExpandable(),
                                const SizedBox(height: 32),
                                _buildSubmitButton(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPresetBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF072033),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                color: Colors.amberAccent,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Quick Test Presets (Tap to auto-fill):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_selectedPreset != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPreset = null;
                      _selectedSpecies = CommercialFishSpecies.generalPond;
                      _pondNameController.text = 'Commercial Pond #1';
                      _phController.clear();
                      _tdsController.clear();
                      _ecController.clear();
                      _salinityController.clear();
                      _temperatureController.clear();
                      _doController.clear();
                      _ammoniaController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _presetChip(
                  id: 'tilapia',
                  label: 'Healthy Tilapia',
                  icon: Icons.check_circle_outline_rounded,
                ),
                _presetChip(
                  id: 'carp',
                  label: 'Major Carp (Rui)',
                  icon: Icons.set_meal_rounded,
                ),
                _presetChip(
                  id: 'pangas',
                  label: 'Pangas Farm',
                  icon: Icons.water_rounded,
                ),
                _presetChip(
                  id: 'catfish',
                  label: 'Catfish / Shing',
                  icon: Icons.bubble_chart_rounded,
                ),
                _presetChip(
                  id: 'acid_water',
                  label: 'Acid Pond (Needs Lime)',
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPreset == id;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _applyQuickPreset(id),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00E676)
                  : const Color(0xFF0E3854),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.cyanAccent.withValues(alpha: 0.6),
                width: isSelected ? 1.8 : 1.2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : icon,
                  size: 15,
                  color:
                      isSelected ? const Color(0xFF003554) : Colors.cyanAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF003554)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalAquacultureExpandable() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: const Text(
          'Target Species & Advanced Inputs (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: const Text(
          'Choose species target or provide measured DO / Ammonia',
          style: TextStyle(fontSize: 11, color: Colors.white60),
        ),
        leading: const Icon(Icons.tune_rounded, color: Colors.cyanAccent),
        collapsedIconColor: Colors.white70,
        iconColor: Colors.cyanAccent,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pond / Water Body Name:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pondNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Pond #1, Nursery Tank, Farm A',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.10),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Select Cultured Species:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CommercialFishSpecies>(
                  key: ValueKey(_selectedSpecies),
                  initialValue: _selectedSpecies,
                  dropdownColor: Colors.blue.shade900,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.10),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: CommercialFishSpecies.values.map((sp) {
                    final info = FishWaterAiService.speciesDatabase[sp]!;
                    return DropdownMenuItem(
                      value: sp,
                      child: Text(info.commonName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSpecies = val);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _doController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Dissolved Oxygen (DO)',
                          labelStyle:
                              const TextStyle(color: Colors.white70, fontSize: 12),
                          hintText: 'e.g. 5.5 mg/L',
                          hintStyle:
                              const TextStyle(color: Colors.white30, fontSize: 11),
                          suffixText: 'mg/L',
                          suffixStyle:
                              const TextStyle(color: Colors.white60, fontSize: 11),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ammoniaController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Total Ammonia (TAN)',
                          labelStyle:
                              const TextStyle(color: Colors.white70, fontSize: 12),
                          hintText: 'e.g. 0.35 mg/L',
                          hintStyle:
                              const TextStyle(color: Colors.white30, fontSize: 11),
                          suffixText: 'mg/L',
                          suffixStyle:
                              const TextStyle(color: Colors.white60, fontSize: 11),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.cyan.shade100],
        ),
        borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(14),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF003554)),
                      SizedBox(width: 8),
                      Text(
                        'Analyze Fish Water & Get Action Plan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003554),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
