import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aquawatch/services/fish_water_ai_service.dart';
import 'package:aquawatch/services/water_reading_service.dart';

class FishScoreGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  FishScoreGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = size.width * 0.40;
    const startAngle = math.pi;
    const sweepFull = math.pi;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      trackPaint,
    );

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull * score.clamp(0.0, 1.0),
      false,
      valuePaint,
    );

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull * score.clamp(0.0, 1.0),
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FishScoreGaugePainter old) =>
      old.score != score || old.color != color;
}

class FishWaterAnalysisReportPage extends StatefulWidget {
  final FishWaterAiAnalysis analysis;
  final double latitude;
  final double longitude;
  final bool locationCaptured;
  final List<XFile> attachedImages;

  const FishWaterAnalysisReportPage({
    super.key,
    required this.analysis,
    required this.latitude,
    required this.longitude,
    required this.locationCaptured,
    required this.attachedImages,
  });

  @override
  State<FishWaterAnalysisReportPage> createState() =>
      _FishWaterAnalysisReportPageState();
}

class _FishWaterAnalysisReportPageState
    extends State<FishWaterAnalysisReportPage>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _listController;
  late Animation<double> _gaugeAnim;

  final WaterReadingService _readingService = WaterReadingService();
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _gaugeAnim = CurvedAnimation(
      parent: _gaugeController,
      curve: Curves.easeOutCubic,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _gaugeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _listController.forward();
    });

    _saveAnalysisToFirestore();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _saveAnalysisToFirestore() async {
    if (_isSaving || _isSaved) return;
    setState(() => _isSaving = true);

    try {
      final analysis = widget.analysis;
      final imagePaths = widget.attachedImages.map((e) => e.path).toList();

      final parameterResults = analysis.parameterBreakdown
          .map(
            (p) => {
              'name': p.name,
              'symbol': p.symbol,
              'unit': p.unit,
              'value': p.value,
              'safeRange': p.optimalRange,
              'level': p.level.name,
              'remark': p.remark,
              'score': p.score,
            },
          )
          .toList();

      await _readingService.saveCommercialFishReading(
        species: FishWaterAiService.speciesDatabase[analysis.species]?.commonName ??
            analysis.species.name,
        farmingSystem: _systemLabel(analysis.systemType),
        pondName: analysis.pondName,
        dissolvedOxygen: analysis.dissolvedOxygen,
        ph: analysis.ph,
        temperature: analysis.temperature,
        ammonia: analysis.ammoniaTan,
        unionizedAmmonia: analysis.unionizedAmmoniaNh3,
        nitrite: analysis.nitrite,
        tds: analysis.tds,
        ec: analysis.ec,
        salinity: analysis.salinity,
        transparency: analysis.transparency,
        latitude: widget.latitude,
        longitude: widget.longitude,
        imagePaths: imagePaths,
        overallQuality: analysis.overallStatusLabel,
        overallScore: analysis.overallScore,
        overallSummary: analysis.executiveSummary,
        aerationAdvisory: analysis.aerationAdvisory,
        feedingAdvisory: analysis.feedingAdvisory,
        pondTreatmentAdvisory: analysis.pondTreatmentAdvisory,
        parameterResults: parameterResults,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.locationCaptured
                ? 'Commercial fish analysis & location saved successfully.'
                : 'Commercial fish analysis saved (without GPS).',
          ),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      // Non-fatal if offline or not logged in
    }
  }

  Color _tierColor(FishQualityLevel level) {
    switch (level) {
      case FishQualityLevel.optimal:
        return const Color(0xFF00E676);
      case FishQualityLevel.favorable:
        return const Color(0xFF26C6DA);
      case FishQualityLevel.moderateStress:
        return const Color(0xFFFFB300);
      case FishQualityLevel.danger:
        return const Color(0xFFFF7043);
      case FishQualityLevel.critical:
        return const Color(0xFFFF1744);
    }
  }

  String _systemLabel(FarmingSystemType type) {
    switch (type) {
      case FarmingSystemType.earthenPond:
        return 'Semi-Intensive Earthen Pond';
      case FarmingSystemType.biofloc:
        return 'Intensive Biofloc System (BFT)';
      case FarmingSystemType.ras:
        return 'Recirculating Aquaculture (RAS)';
      case FarmingSystemType.cageCulture:
        return 'Cage / Pen Culture';
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final primaryColor = _tierColor(analysis.overallQuality);
    final speciesInfo =
        FishWaterAiService.speciesDatabase[analysis.species]!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF051923),
              const Color(0xFF003554),
              const Color(0xFF006494),
              const Color(0xFF0582CA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(speciesInfo),
                      const SizedBox(height: 16),
                      _buildScoreGaugeCard(primaryColor),
                      const SizedBox(height: 16),
                      _buildRealtimeChemicalCard(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('AI Commercial Advisories'),
                      const SizedBox(height: 10),
                      _buildAdvisoryCard(
                        title: 'AI Aeration Schedule & Control',
                        subtitle: analysis.aerationAdvisory,
                        icon: Icons.air_rounded,
                        color: const Color(0xFF4FC3F7),
                      ),
                      const SizedBox(height: 10),
                      _buildAdvisoryCard(
                        title: 'AI Feeding Rate Adjustment',
                        subtitle: analysis.feedingAdvisory,
                        icon: Icons.restaurant_rounded,
                        color: const Color(0xFFFFB74D),
                      ),
                      const SizedBox(height: 10),
                      _buildAdvisoryCard(
                        title: 'AI Pond Treatment & Water Management',
                        subtitle: analysis.pondTreatmentAdvisory,
                        icon: Icons.sanitizer_rounded,
                        color: const Color(0xFF81C784),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Disease & Toxicity Risk Matrix'),
                      const SizedBox(height: 10),
                      _buildRiskMatrixCard(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Parameter Breakdown (Fish Criteria)'),
                      const SizedBox(height: 10),
                      ...analysis.parameterBreakdown.map(_buildParameterCard),
                      const SizedBox(height: 20),
                      _buildSaveStatusBanner(),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fish Water AI Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Commercial Aquaculture Intelligence',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (_isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else if (_isSaved)
            const Icon(Icons.cloud_done_rounded, color: Color(0xFF00E676)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(SpeciesWaterCriteria speciesInfo) {
    final analysis = widget.analysis;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyan.shade300.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phishing_rounded,
              color: Colors.cyanAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        analysis.pondName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        speciesInfo.commonName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_systemLabel(analysis.systemType)} • ${speciesInfo.scientificName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGaugeCard(Color primaryColor) {
    final analysis = widget.analysis;
    final normalizedScore = analysis.overallScore / 100.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'COMMERCIAL FISH WATER QUALITY INDEX (CFWQI)',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: AnimatedBuilder(
              animation: _gaugeAnim,
              builder: (context, _) {
                final curScore = normalizedScore * _gaugeAnim.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(260, 150),
                      painter: FishScoreGaugePainter(
                        score: curScore,
                        color: primaryColor,
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(curScore * 100).round()}',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const Text(
                            'SCORE / 100',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor),
            ),
            child: Text(
              analysis.overallStatusLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            analysis.executiveSummary,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeChemicalCard() {
    final analysis = widget.analysis;
    final nh3 = analysis.unionizedAmmoniaNh3;
    final isNh3Safe = nh3 <= 0.05;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNh3Safe
              ? Colors.tealAccent.withValues(alpha: 0.4)
              : Colors.deepOrangeAccent.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_rounded,
                color: isNh3Safe ? Colors.tealAccent : Colors.deepOrangeAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Smart Chemical Equilibrium AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isNh3Safe
                      ? Colors.teal.withValues(alpha: 0.3)
                      : Colors.deepOrange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isNh3Safe ? 'NH₃ SAFE' : 'NH₃ TOXIC HAZARD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isNh3Safe ? Colors.tealAccent : Colors.deepOrangeAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Based on aqueous temperature (${analysis.temperature.toStringAsFixed(1)}°C) and pH (${analysis.ph.toStringAsFixed(2)}), the AI determined that ${analysis.ammoniaTan.toStringAsFixed(2)} mg/L Total Ammonia (TAN) produces:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Toxic Free NH₃',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                    Text(
                      '${nh3.toStringAsFixed(4)} mg/L',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isNh3Safe ? Colors.tealAccent : Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white24,
                ),
                Column(
                  children: [
                    const Text(
                      'Target DO Min',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                    Text(
                      '${analysis.dissolvedOxygen.toStringAsFixed(1)} mg/L',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildAdvisoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMatrixCard() {
    final analysis = widget.analysis;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          _buildRiskRow('Hypoxia Suffocation', analysis.hypoxiaRisk, Icons.air_rounded),
          const Divider(color: Colors.white12, height: 16),
          _buildRiskRow('Ammonia Toxicosis', analysis.ammoniaToxicityRisk, Icons.warning_amber_rounded),
          const Divider(color: Colors.white12, height: 16),
          _buildRiskRow('Nitrite (Brown Blood)', analysis.nitriteRisk, Icons.water_drop_rounded),
          const Divider(color: Colors.white12, height: 16),
          _buildRiskRow('Pathogen Vulnerability', analysis.bacterialDiseaseRisk, Icons.bug_report_rounded),
        ],
      ),
    );
  }

  Widget _buildRiskRow(String label, String value, IconData icon) {
    Color riskColor = const Color(0xFF00E676);
    if (value.toLowerCase().contains('danger') ||
        value.toLowerCase().contains('severe') ||
        value.toLowerCase().contains('extreme') ||
        value.toLowerCase().contains('high')) {
      riskColor = const Color(0xFFFF5252);
    } else if (value.toLowerCase().contains('moderate') ||
        value.toLowerCase().contains('elevated')) {
      riskColor = const Color(0xFFFFB74D);
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: riskColor),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: riskColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParameterCard(FishParameterResult param) {
    final color = _tierColor(param.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  param.symbol,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  param.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${param.value} ${param.unit}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Species Target: ${param.optimalRange}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                param.level.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            param.remark,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSaved ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 16,
            color: _isSaved ? const Color(0xFF00E676) : Colors.white70,
          ),
          const SizedBox(width: 8),
          Text(
            _isSaved
                ? 'Report synced to AquaWatch Cloud Monitoring.'
                : 'Saving report to AquaWatch Database...',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
