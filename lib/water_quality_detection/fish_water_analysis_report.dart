import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:aquawatch/services/fish_water_ai_service.dart';

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

  const FishWaterAnalysisReportPage({
    super.key,
    required this.analysis,
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

  final Set<int> _checkedChecklistIndices = {};

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
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _listController.dispose();
    super.dispose();
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF051923),
              Color(0xFF003554),
              Color(0xFF006494),
              Color(0xFF0582CA),
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
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      _buildScoreGaugeCard(primaryColor),
                      const SizedBox(height: 16),
                      _buildWhatToDoHeroCard(primaryColor),
                      const SizedBox(height: 20),
                      _buildSectionTitle('What To Do With This Fish Water (Action Steps)'),
                      const SizedBox(height: 10),
                      ...analysis.actionSteps.map(_buildActionStepCard),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Best Fish Species for This Water'),
                      const SizedBox(height: 10),
                      ...analysis.speciesMatches.map(_buildSpeciesMatchCard),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Pre-Stocking Pond Preparation Checklist'),
                      const SizedBox(height: 10),
                      _buildPreStockingChecklist(),
                      const SizedBox(height: 20),
                      _buildRealtimeChemicalCard(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Water Quality Parameter Breakdown'),
                      const SizedBox(height: 10),
                      ...analysis.parameterBreakdown.map(_buildParameterCard),
                      const SizedBox(height: 20),
                      _buildAdvisoryPrivacyNote(),
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
                  'Fish Water Action Report',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'What To Do With This Fish Water',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    final analysis = widget.analysis;
    final speciesInfo = FishWaterAiService.speciesDatabase[analysis.species]!;

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
                  '${_systemLabel(analysis.systemType)} • Commercial Advisory',
                  style: TextStyle(
                    fontSize: 12,
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
            'FISH WATER QUALITY INDEX (FWQI)',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _gaugeAnim,
              builder: (context, _) {
                final curScore = normalizedScore * _gaugeAnim.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(260, 140),
                      painter: FishScoreGaugePainter(
                        score: curScore,
                        color: primaryColor,
                      ),
                    ),
                    Positioned(
                      bottom: 18,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(curScore * 100).round()}',
                            style: const TextStyle(
                              fontSize: 44,
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
        ],
      ),
    );
  }

  Widget _buildWhatToDoHeroCard(Color primaryColor) {
    final analysis = widget.analysis;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment_turned_in_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  analysis.fishUsabilityVerdict,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.whatToDoOverview,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Colors.white,
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

  Widget _buildActionStepCard(ActionPlanStep step) {
    Color badgeColor = const Color(0xFF00E676);
    IconData icon = Icons.check_circle_outline;

    if (step.urgency == 'Immediate') {
      badgeColor = const Color(0xFFFF5252);
      icon = Icons.priority_high_rounded;
    } else if (step.urgency == 'Recommended') {
      badgeColor = const Color(0xFFFFB74D);
      icon = Icons.lightbulb_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: badgeColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  step.urgency.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.42,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesMatchCard(FishSpeciesMatch match) {
    Color matchColor = const Color(0xFF00E676);
    if (match.compatibilityPercent < 50) {
      matchColor = const Color(0xFFFF5252);
    } else if (match.compatibilityPercent < 75) {
      matchColor = const Color(0xFFFFB74D);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.commonName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${match.compatibilityPercent}% Match',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: matchColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: match.compatibilityPercent / 100.0,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(matchColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            match.reason,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreStockingChecklist() {
    final checklist = [
      'Maintain adequate pond water depth (ideal 3.5 – 5.0 feet).',
      'If pH is below 6.8, broadcast recommended agricultural lime 48 hours before stocking.',
      'Pre-aerate the pond for 12 hours before introducing seed / fry.',
      'Float transport fish bags in pond water for 25–30 minutes to equalize temperature before releasing.',
      'Test dissolved oxygen early in the morning (5:30 AM) to verify night stability.',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: checklist.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isChecked = _checkedChecklistIndices.contains(idx);

          return InkWell(
            onTap: () {
              setState(() {
                if (isChecked) {
                  _checkedChecklistIndices.remove(idx);
                } else {
                  _checkedChecklistIndices.add(idx);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: isChecked ? const Color(0xFF00E676) : Colors.white60,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? Colors.white54 : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
                  'Chemical Equilibrium & Oxygen Balance',
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
                  isNh3Safe ? 'SAFE' : 'TOXIC RISK',
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
            'At water temp ${analysis.temperature.toStringAsFixed(1)}°C and pH ${analysis.ph.toStringAsFixed(2)}, oxygen saturation capacity is ${analysis.estimatedOxygenSaturation} mg/L. Un-ionized toxic free ammonia (NH₃) is estimated at:',
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
                    Text(
                      analysis.isEstimatedDo ? 'Theoretical DO' : 'Measured DO',
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
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

  Widget _buildAdvisoryPrivacyNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: Color(0xFF00E676),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Private advisory: no fish water data, location, or images are saved or transmitted.',
              style: TextStyle(fontSize: 11.5, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
