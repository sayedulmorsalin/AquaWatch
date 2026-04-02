import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aquawatch/services/water_reading_service.dart';

class WaterQualityData {
  final double ph;
  final double tds;
  final double ec;
  final double salinity;
  final double temperature;
  final List<XFile> phImages;
  final List<XFile> tdsImages;
  final List<XFile> ecImages;
  final List<XFile> salinityImages;
  final double latitude;
  final double longitude;
  final bool locationCaptured;

  const WaterQualityData({
    required this.ph,
    required this.tds,
    required this.ec,
    required this.salinity,
    required this.temperature,
    required this.phImages,
    required this.tdsImages,
    required this.ecImages,
    required this.salinityImages,
    required this.latitude,
    required this.longitude,
    required this.locationCaptured,
  });
}

enum QualityLevel { excellent, good, acceptable, poor, dangerous }

class ParameterResult {
  final String name;
  final String unit;
  final double value;
  final String safeRange;
  final QualityLevel level;
  final String remark;
  final IconData icon;
  final double score;

  const ParameterResult({
    required this.name,
    required this.unit,
    required this.value,
    required this.safeRange,
    required this.level,
    required this.remark,
    required this.icon,
    required this.score,
  });
}

class _ScoreGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _ScoreGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;
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
      ..color = color.withValues(alpha: 0.25)
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
  bool shouldRepaint(covariant _ScoreGaugePainter old) =>
      old.score != score || old.color != color;
}

class DataAnalysisReport extends StatefulWidget {
  final WaterQualityData data;

  const DataAnalysisReport({super.key, required this.data});

  @override
  State<DataAnalysisReport> createState() => _DataAnalysisReportState();
}

class _DataAnalysisReportState extends State<DataAnalysisReport>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late AnimationController _listController;
  late Animation<double> _gaugeAnim;
  late List<ParameterResult> _results;
  late QualityLevel _overallQuality;
  late int _overallScore;
  late String _overallSummary;
  final WaterReadingService _waterReadingService = WaterReadingService();
  bool _isSavingReport = false;
  bool _reportSaved = false;

  @override
  void initState() {
    super.initState();
    _results = _analyzeData(widget.data);
    _overallQuality = _calculateOverallQuality(_results);
    _overallScore = _numericScore(_results);
    _overallSummary = _generateSummary(_overallQuality);

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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _listController.forward();
    });

    _saveReportWithAnalysis();
  }

  Future<void> _saveReportWithAnalysis() async {
    if (_isSavingReport || _reportSaved) {
      return;
    }

    setState(() => _isSavingReport = true);

    try {
      await _waterReadingService.saveReading(
        ph: widget.data.ph,
        tds: widget.data.tds,
        ec: widget.data.ec,
        salinity: widget.data.salinity,
        temperature: widget.data.temperature,
        latitude: widget.data.latitude,
        longitude: widget.data.longitude,
        phImagePath: widget.data.phImages.first.path,
        tdsImagePath: widget.data.tdsImages.first.path,
        ecImagePath: widget.data.ecImages.first.path,
        salinityImagePath: widget.data.salinityImages.first.path,
        overallQuality: _qualityLabel(_overallQuality),
        overallScore: _overallScore,
        overallSummary: _overallSummary,
        parameterResults: _results
            .map(
              (r) => {
                'name': r.name,
                'unit': r.unit,
                'value': r.value,
                'safeRange': r.safeRange,
                'level': _qualityLabel(r.level),
                'remark': r.remark,
                'score': r.score,
              },
            )
            .toList(),
      );

      if (!mounted) return;
      setState(() {
        _isSavingReport = false;
        _reportSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.data.locationCaptured
                ? 'Analysis and data saved successfully.'
                : 'Analysis saved (without location).',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingReport = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save analysis report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    _listController.dispose();
    super.dispose();
  }

  List<ParameterResult> _analyzeData(WaterQualityData data) {
    return [
      _analyzePh(data.ph),
      _analyzeTds(data.tds),
      _analyzeEc(data.ec),
      _analyzeSalinity(data.salinity),
      _analyzeTemperature(data.temperature),
    ];
  }

  ParameterResult _analyzePh(double value) {
    QualityLevel level;
    String remark;
    double score;
    if (value >= 6.5 && value <= 8.5) {
      level = QualityLevel.excellent;
      remark = 'pH is within the safe drinking water range.';
      score = 1.0;
    } else if ((value >= 6.0 && value < 6.5) || (value > 8.5 && value <= 9.0)) {
      level = QualityLevel.acceptable;
      remark = 'pH is slightly outside the ideal range.';
      score = 0.55;
    } else if (value < 6.0) {
      level = QualityLevel.poor;
      remark = 'Water is too acidic. May corrode pipes and harm health.';
      score = 0.25;
    } else {
      level = QualityLevel.poor;
      remark = 'Water is too alkaline. May cause scaling and taste issues.';
      score = 0.25;
    }
    return ParameterResult(
      name: 'pH Level',
      unit: 'pH',
      value: value,
      safeRange: '6.5 – 8.5',
      level: level,
      remark: remark,
      icon: Icons.science_outlined,
      score: score,
    );
  }

  ParameterResult _analyzeTds(double value) {
    QualityLevel level;
    String remark;
    double score;
    if (value <= 300) {
      level = QualityLevel.excellent;
      remark = 'Excellent water purity. Very low dissolved solids.';
      score = 1.0;
    } else if (value <= 500) {
      level = QualityLevel.good;
      remark = 'Good water quality. Acceptable dissolved solids.';
      score = 0.8;
    } else if (value <= 900) {
      level = QualityLevel.acceptable;
      remark = 'Fair quality. Consider filtration for drinking.';
      score = 0.55;
    } else if (value <= 1200) {
      level = QualityLevel.poor;
      remark = 'Poor quality. Not recommended for drinking.';
      score = 0.3;
    } else {
      level = QualityLevel.dangerous;
      remark = 'Unsafe. Very high dissolved solids detected.';
      score = 0.1;
    }
    return ParameterResult(
      name: 'TDS',
      unit: 'ppm',
      value: value,
      safeRange: '0 – 500 ppm',
      level: level,
      remark: remark,
      icon: Icons.opacity_outlined,
      score: score,
    );
  }

  ParameterResult _analyzeEc(double value) {
    QualityLevel level;
    String remark;
    double score;
    if (value <= 800) {
      level = QualityLevel.excellent;
      remark = 'Low conductivity. Indicates clean water.';
      score = 1.0;
    } else if (value <= 1500) {
      level = QualityLevel.acceptable;
      remark = 'Moderate conductivity. Acceptable for most uses.';
      score = 0.55;
    } else if (value <= 2000) {
      level = QualityLevel.poor;
      remark = 'High conductivity. High mineral content detected.';
      score = 0.3;
    } else {
      level = QualityLevel.dangerous;
      remark = 'Very high conductivity. Water may be contaminated.';
      score = 0.1;
    }
    return ParameterResult(
      name: 'Electrical Conductivity',
      unit: 'µS/cm',
      value: value,
      safeRange: '0 – 800 µS/cm',
      level: level,
      remark: remark,
      icon: Icons.electric_bolt_outlined,
      score: score,
    );
  }

  ParameterResult _analyzeSalinity(double value) {
    QualityLevel level;
    String remark;
    double score;
    if (value <= 0.5) {
      level = QualityLevel.excellent;
      remark = 'Fresh water. Very low salinity.';
      score = 1.0;
    } else if (value <= 1.0) {
      level = QualityLevel.good;
      remark = 'Slightly saline but acceptable for most purposes.';
      score = 0.8;
    } else if (value <= 5.0) {
      level = QualityLevel.acceptable;
      remark = 'Brackish water. Not ideal for drinking.';
      score = 0.55;
    } else if (value <= 30.0) {
      level = QualityLevel.poor;
      remark = 'Saline water. Unsuitable for drinking or irrigation.';
      score = 0.25;
    } else {
      level = QualityLevel.dangerous;
      remark = 'Highly saline. Comparable to seawater.';
      score = 0.1;
    }
    return ParameterResult(
      name: 'Salinity',
      unit: 'ppt',
      value: value,
      safeRange: '0 – 0.5 ppt',
      level: level,
      remark: remark,
      icon: Icons.grain_outlined,
      score: score,
    );
  }

  ParameterResult _analyzeTemperature(double value) {
    QualityLevel level;
    String remark;
    double score;
    if (value >= 20 && value <= 25) {
      level = QualityLevel.excellent;
      remark = 'Ideal water temperature for drinking.';
      score = 1.0;
    } else if ((value >= 15 && value < 20) || (value > 25 && value <= 30)) {
      level = QualityLevel.good;
      remark = 'Acceptable temperature range.';
      score = 0.8;
    } else if ((value >= 10 && value < 15) || (value > 30 && value <= 35)) {
      level = QualityLevel.acceptable;
      remark = 'Outside ideal range. May affect taste and dissolved oxygen.';
      score = 0.55;
    } else {
      level = QualityLevel.poor;
      remark = 'Extreme temperature. May indicate environmental issues.';
      score = 0.25;
    }
    return ParameterResult(
      name: 'Temperature',
      unit: '°C',
      value: value,
      safeRange: '20 – 25 °C',
      level: level,
      remark: remark,
      icon: Icons.thermostat_outlined,
      score: score,
    );
  }

  QualityLevel _calculateOverallQuality(List<ParameterResult> results) {
    final worst = results
        .map((r) => r.level.index)
        .reduce((a, b) => a > b ? a : b);
    return QualityLevel.values[worst];
  }

  int _numericScore(List<ParameterResult> results) {
    final avg =
        results.map((r) => r.score).reduce((a, b) => a + b) / results.length;
    return (avg * 100).round();
  }

  String _generateSummary(QualityLevel overall) {
    switch (overall) {
      case QualityLevel.excellent:
        return 'All parameters are within excellent range. The water is safe for drinking and daily use.';
      case QualityLevel.good:
        return 'Water quality is good overall. All parameters are within acceptable limits.';
      case QualityLevel.acceptable:
        return 'Water quality is fair. Some parameters are outside ideal ranges. Consider treatment before drinking.';
      case QualityLevel.poor:
        return 'Water quality is poor. One or more parameters exceed safe limits. Treatment is strongly recommended.';
      case QualityLevel.dangerous:
        return 'Water quality is unsafe! Critical parameters exceed safe limits. Do NOT use for drinking without proper treatment.';
    }
  }

  Color _qualityColor(QualityLevel level) {
    switch (level) {
      case QualityLevel.excellent:
        return const Color(0xFF00E676);
      case QualityLevel.good:
        return const Color(0xFF69F0AE);
      case QualityLevel.acceptable:
        return const Color(0xFFFFA726);
      case QualityLevel.poor:
        return const Color(0xFFFF5722);
      case QualityLevel.dangerous:
        return const Color(0xFFFF1744);
    }
  }

  String _qualityLabel(QualityLevel level) {
    switch (level) {
      case QualityLevel.excellent:
        return 'Excellent';
      case QualityLevel.good:
        return 'Good';
      case QualityLevel.acceptable:
        return 'Fair';
      case QualityLevel.poor:
        return 'Poor';
      case QualityLevel.dangerous:
        return 'Unsafe';
    }
  }

  IconData _qualityIcon(QualityLevel level) {
    switch (level) {
      case QualityLevel.excellent:
        return Icons.verified_rounded;
      case QualityLevel.good:
        return Icons.thumb_up_rounded;
      case QualityLevel.acceptable:
        return Icons.info_rounded;
      case QualityLevel.poor:
        return Icons.warning_amber_rounded;
      case QualityLevel.dangerous:
        return Icons.dangerous_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overallColor = _qualityColor(_overallQuality);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D1B2A),
              const Color(0xFF1B2838),
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Report',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Water Quality Assessment',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: overallColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: overallColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _qualityIcon(_overallQuality),
                            color: overallColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _qualityLabel(_overallQuality),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: overallColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  child: Column(
                    children: [
                      _buildScoreGauge(overallColor),
                      const SizedBox(height: 24),
                      _buildSummaryCard(overallColor),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Parameter Breakdown'),
                      const SizedBox(height: 12),
                      ..._buildParameterTiles(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('Recommendations'),
                      const SizedBox(height: 12),
                      _buildRecommendationCard(),
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

  Widget _buildScoreGauge(Color color) {
    return AnimatedBuilder(
      animation: _gaugeAnim,
      builder: (context, child) {
        final animScore = _gaugeAnim.value * (_overallScore / 100.0);
        final displayScore = (_gaugeAnim.value * _overallScore).round();
        return SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(260, 200),
                painter: _ScoreGaugePainter(score: animScore, color: color),
              ),
              Positioned(
                bottom: 40,
                child: Column(
                  children: [
                    Text(
                      '$displayScore',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'out of 100',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(Color color) {
    return AnimatedBuilder(
      animation: _gaugeAnim,
      builder: (context, _) {
        return Opacity(
          opacity: _gaugeAnim.value.clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _qualityIcon(_overallQuality),
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _overallSummary,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  List<Widget> _buildParameterTiles() {
    return List.generate(_results.length, (index) {
      final result = _results[index];
      final delay = index / _results.length;

      return AnimatedBuilder(
        animation: _listController,
        builder: (context, child) {
          final curvedValue = Curves.easeOutBack.transform(
            (_listController.value - delay).clamp(0.0, 1.0 - delay) /
                (1.0 - delay),
          );
          return Transform.translate(
            offset: Offset(0, 30 * (1 - curvedValue)),
            child: Opacity(opacity: curvedValue.clamp(0.0, 1.0), child: child),
          );
        },
        child: _buildParameterTile(result),
      );
    });
  }

  Widget _buildParameterTile(ParameterResult result) {
    final color = _qualityColor(result.level);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: result.score,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Icon(result.icon, color: color, size: 22),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.remark,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildSmallChip('${result.value} ${result.unit}', color),
                    const SizedBox(width: 8),
                    _buildSmallChip(result.safeRange, Colors.white38),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Text(
              _qualityLabel(result.level),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final items = <_RecommendationItem>[];

    for (final r in _results) {
      if (r.level == QualityLevel.excellent || r.level == QualityLevel.good) {
        continue;
      }
      IconData icon;
      Color iconColor;
      switch (r.level) {
        case QualityLevel.acceptable:
          icon = Icons.tune_rounded;
          iconColor = const Color(0xFFFFA726);
          break;
        case QualityLevel.poor:
          icon = Icons.build_rounded;
          iconColor = const Color(0xFFFF5722);
          break;
        case QualityLevel.dangerous:
          icon = Icons.block_rounded;
          iconColor = const Color(0xFFFF1744);
          break;
        default:
          icon = Icons.check;
          iconColor = Colors.green;
      }
      items.add(
        _RecommendationItem(
          icon: icon,
          iconColor: iconColor,
          title: r.name,
          text: r.remark,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _RecommendationItem(
          icon: Icons.check_circle_outline_rounded,
          iconColor: Color(0xFF00E676),
          title: 'All Clear',
          text: 'All parameters are within safe limits. No action needed.',
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildRecommendationRow(items[i]),
            if (i < items.length - 1)
              Divider(color: Colors.white.withValues(alpha: 0.08), height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(_RecommendationItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.text,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String text;

  const _RecommendationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.text,
  });
}
