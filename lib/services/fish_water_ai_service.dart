import 'dart:math' as math;

/// Predefined commercial aquaculture fish & crustacean species.
enum CommercialFishSpecies {
  tilapia,
  pangasius,
  majorCarp,
  catfish,
  shrimp,
  trout,
  generalPond,
}

/// Commercial aquaculture production system types.
enum FarmingSystemType {
  earthenPond,
  biofloc,
  ras,
  cageCulture,
}

/// Overall fish water quality tier.
enum FishQualityLevel {
  optimal,
  favorable,
  moderateStress,
  danger,
  critical,
}

/// Specification of biological safe and optimal ranges for a species.
class SpeciesWaterCriteria {
  final CommercialFishSpecies species;
  final String commonName;
  final String scientificName;
  final String description;
  final double optimalDoMin;
  final double optimalDoMax;
  final double criticalDo;
  final double optimalPhMin;
  final double optimalPhMax;
  final double optimalTempMin;
  final double optimalTempMax;
  final double maxSafeTan; // Total Ammonia Nitrogen (mg/L)
  final double maxSafeNh3; // Toxic un-ionized ammonia (mg/L)
  final double optimalSalinityMin;
  final double optimalSalinityMax;
  final double optimalTdsMin;
  final double optimalTdsMax;
  final double maxSafeNitrite; // mg/L

  const SpeciesWaterCriteria({
    required this.species,
    required this.commonName,
    required this.scientificName,
    required this.description,
    required this.optimalDoMin,
    required this.optimalDoMax,
    required this.criticalDo,
    required this.optimalPhMin,
    required this.optimalPhMax,
    required this.optimalTempMin,
    required this.optimalTempMax,
    required this.maxSafeTan,
    required this.maxSafeNh3,
    required this.optimalSalinityMin,
    required this.optimalSalinityMax,
    required this.optimalTdsMin,
    required this.optimalTdsMax,
    required this.maxSafeNitrite,
  });
}

/// Detailed evaluation of an individual water parameter against fish biology.
class FishParameterResult {
  final String name;
  final String symbol;
  final String unit;
  final double value;
  final String optimalRange;
  final FishQualityLevel level;
  final String remark;
  final double score; // 0.0 to 1.0

  const FishParameterResult({
    required this.name,
    required this.symbol,
    required this.unit,
    required this.value,
    required this.optimalRange,
    required this.level,
    required this.remark,
    required this.score,
  });
}

/// Species compatibility result for any tested water sample.
class FishSpeciesMatch {
  final CommercialFishSpecies species;
  final String commonName;
  final int compatibilityPercent; // 0 to 100
  final String verdict; // e.g. "Optimal Match", "Tolerable", "Unsuitable"
  final String reason;

  const FishSpeciesMatch({
    required this.species,
    required this.commonName,
    required this.compatibilityPercent,
    required this.verdict,
    required this.reason,
  });
}

/// Action item on what to do with the fish water.
class ActionPlanStep {
  final String title;
  final String description;
  final String urgency; // "Immediate", "Recommended", "Routine"
  final String category; // "pH & Liming", "Aeration", "Feeding", "Water Conditioning"

  const ActionPlanStep({
    required this.title,
    required this.description,
    required this.urgency,
    required this.category,
  });
}

/// Complete AI diagnostic result for commercial fish water monitoring.
class FishWaterAiAnalysis {
  final CommercialFishSpecies species;
  final FarmingSystemType systemType;
  final String pondName;
  final double dissolvedOxygen;
  final bool isEstimatedDo;
  final double estimatedOxygenSaturation;
  final double ph;
  final double temperature;
  final double ammoniaTan;
  final double unionizedAmmoniaNh3;
  final double? nitrite;
  final double salinity;
  final double tds;
  final double ec;
  final double? transparency;

  final int overallScore; // 0 to 100
  final FishQualityLevel overallQuality;
  final String overallStatusLabel;
  final String fishUsabilityVerdict;
  final String whatToDoOverview;
  final String executiveSummary;

  final String aerationAdvisory;
  final String feedingAdvisory;
  final String pondTreatmentAdvisory;

  final String hypoxiaRisk;
  final String ammoniaToxicityRisk;
  final String nitriteRisk;
  final String bacterialDiseaseRisk;

  final List<FishParameterResult> parameterBreakdown;
  final List<FishSpeciesMatch> speciesMatches;
  final List<ActionPlanStep> actionSteps;

  const FishWaterAiAnalysis({
    required this.species,
    required this.systemType,
    required this.pondName,
    required this.dissolvedOxygen,
    required this.isEstimatedDo,
    required this.estimatedOxygenSaturation,
    required this.ph,
    required this.temperature,
    required this.ammoniaTan,
    required this.unionizedAmmoniaNh3,
    required this.nitrite,
    required this.salinity,
    required this.tds,
    required this.ec,
    required this.transparency,
    required this.overallScore,
    required this.overallQuality,
    required this.overallStatusLabel,
    required this.fishUsabilityVerdict,
    required this.whatToDoOverview,
    required this.executiveSummary,
    required this.aerationAdvisory,
    required this.feedingAdvisory,
    required this.pondTreatmentAdvisory,
    required this.hypoxiaRisk,
    required this.ammoniaToxicityRisk,
    required this.nitriteRisk,
    required this.bacterialDiseaseRisk,
    required this.parameterBreakdown,
    required this.speciesMatches,
    required this.actionSteps,
  });
}

/// Service executing biological & chemical models for commercial fish water.
class FishWaterAiService {
  static const Map<CommercialFishSpecies, SpeciesWaterCriteria> speciesDatabase = {
    CommercialFishSpecies.tilapia: SpeciesWaterCriteria(
      species: CommercialFishSpecies.tilapia,
      commonName: 'Nile Tilapia',
      scientificName: 'Oreochromis niloticus',
      description: 'Hardy tropical freshwater fish with high commercial yield.',
      optimalDoMin: 5.0,
      optimalDoMax: 8.5,
      criticalDo: 3.0,
      optimalPhMin: 6.5,
      optimalPhMax: 8.5,
      optimalTempMin: 26.0,
      optimalTempMax: 32.0,
      maxSafeTan: 1.0,
      maxSafeNh3: 0.05,
      optimalSalinityMin: 0.0,
      optimalSalinityMax: 12.0,
      optimalTdsMin: 200.0,
      optimalTdsMax: 1200.0,
      maxSafeNitrite: 0.5,
    ),
    CommercialFishSpecies.pangasius: SpeciesWaterCriteria(
      species: CommercialFishSpecies.pangasius,
      commonName: 'Pangasius / Pangas',
      scientificName: 'Pangasianodon hypophthalmus',
      description: 'Fast-growing commercial catfish in high-density earthen ponds.',
      optimalDoMin: 4.0,
      optimalDoMax: 7.5,
      criticalDo: 2.8,
      optimalPhMin: 6.5,
      optimalPhMax: 8.0,
      optimalTempMin: 26.0,
      optimalTempMax: 32.0,
      maxSafeTan: 0.8,
      maxSafeNh3: 0.035,
      optimalSalinityMin: 0.0,
      optimalSalinityMax: 4.0,
      optimalTdsMin: 200.0,
      optimalTdsMax: 900.0,
      maxSafeNitrite: 0.35,
    ),
    CommercialFishSpecies.majorCarp: SpeciesWaterCriteria(
      species: CommercialFishSpecies.majorCarp,
      commonName: 'Major Carp (Rui / Catla / Mrigal)',
      scientificName: 'Labeo rohita / Gibelion catla',
      description: 'Traditional composite polyculture; highly sensitive to oxygen and ammonia.',
      optimalDoMin: 5.5,
      optimalDoMax: 8.5,
      criticalDo: 3.8,
      optimalPhMin: 7.0,
      optimalPhMax: 8.5,
      optimalTempMin: 24.0,
      optimalTempMax: 30.0,
      maxSafeTan: 0.5,
      maxSafeNh3: 0.02,
      optimalSalinityMin: 0.0,
      optimalSalinityMax: 2.0,
      optimalTdsMin: 150.0,
      optimalTdsMax: 800.0,
      maxSafeNitrite: 0.2,
    ),
    CommercialFishSpecies.catfish: SpeciesWaterCriteria(
      species: CommercialFishSpecies.catfish,
      commonName: 'Catfish / Shing / Magur',
      scientificName: 'Clarias gariepinus / Heteropneustes',
      description: 'Air-breathing commercial species; tolerates low DO but sensitive to toxic NH3.',
      optimalDoMin: 3.5,
      optimalDoMax: 7.0,
      criticalDo: 2.2,
      optimalPhMin: 6.5,
      optimalPhMax: 8.2,
      optimalTempMin: 25.0,
      optimalTempMax: 32.0,
      maxSafeTan: 1.2,
      maxSafeNh3: 0.05,
      optimalSalinityMin: 0.0,
      optimalSalinityMax: 5.0,
      optimalTdsMin: 200.0,
      optimalTdsMax: 1200.0,
      maxSafeNitrite: 0.5,
    ),
    CommercialFishSpecies.shrimp: SpeciesWaterCriteria(
      species: CommercialFishSpecies.shrimp,
      commonName: 'Whiteleg Shrimp / Prawn',
      scientificName: 'Litopenaeus vannamei',
      description: 'High-value brackish aquaculture requiring strict DO & mineral stability.',
      optimalDoMin: 5.5,
      optimalDoMax: 8.0,
      criticalDo: 3.8,
      optimalPhMin: 7.6,
      optimalPhMax: 8.4,
      optimalTempMin: 28.0,
      optimalTempMax: 32.0,
      maxSafeTan: 0.5,
      maxSafeNh3: 0.025,
      optimalSalinityMin: 12.0,
      optimalSalinityMax: 28.0,
      optimalTdsMin: 8000.0,
      optimalTdsMax: 25000.0,
      maxSafeNitrite: 0.25,
    ),
    CommercialFishSpecies.trout: SpeciesWaterCriteria(
      species: CommercialFishSpecies.trout,
      commonName: 'Rainbow Trout (Coldwater)',
      scientificName: 'Oncorhynchus mykiss',
      description: 'Coldwater commercial fish requiring high dissolved oxygen and pristine purity.',
      optimalDoMin: 7.0,
      optimalDoMax: 11.0,
      criticalDo: 5.5,
      optimalPhMin: 6.8,
      optimalPhMax: 7.8,
      optimalTempMin: 12.0,
      optimalTempMax: 18.0,
      maxSafeTan: 0.3,
      maxSafeNh3: 0.015,
      optimalSalinityMin: 0.0,
      optimalSalinityMax: 2.0,
      optimalTdsMin: 100.0,
      optimalTdsMax: 500.0,
      maxSafeNitrite: 0.15,
    ),
    CommercialFishSpecies.generalPond: SpeciesWaterCriteria(
      species: CommercialFishSpecies.generalPond,
      commonName: 'General Commercial Pond',
      scientificName: 'Aquaculture Pond Baseline',
      description: 'Standard multi-species commercial fish farming baseline.',
      optimalDoMin: 5.0,
      optimalDoMax: 8.0,
      criticalDo: 3.0,
      optimalPhMin: 6.5,
      optimalPhMax: 8.5,
      optimalTempMin: 25.0,
      optimalTempMax: 31.0,
      maxSafeTan: 0.8,
      maxSafeNh3: 0.03,
      optimalSalinityMin: 0.0,
      optimalSalinityMax: 3.0,
      optimalTdsMin: 150.0,
      optimalTdsMax: 1000.0,
      maxSafeNitrite: 0.3,
    ),
  };

  /// Calculates toxic un-ionized ammonia (NH3) from TAN, pH, and Temperature
  /// using the Emerson et al. aqueous chemical equilibrium formula.
  static double calculateUnionizedAmmonia({
    required double tan,
    required double ph,
    required double temperatureCelsius,
  }) {
    if (tan <= 0) return 0.0;
    final double kelvin = temperatureCelsius + 273.15;
    final double pKa = 0.09018 + (2729.92 / kelvin);
    final double denominator = 1.0 + math.pow(10, pKa - ph);
    final double fraction = 1.0 / denominator;
    final double nh3 = tan * fraction;
    return double.parse(nh3.toStringAsFixed(4));
  }

  /// Calculates theoretical Dissolved Oxygen 100% saturation at sea level for water temp.
  static double calculateOxygenSaturation(double temperatureCelsius) {
    final t = temperatureCelsius;
    return 14.652 - (0.41022 * t) + (0.007991 * t * t) - (0.000077774 * t * t * t);
  }

  /// Analyzes fish pond water quality comprehensively using biological modeling.
  /// Works seamlessly with the standard 5 potable testing parameters (pH, TDS, EC, Salinity, Temperature),
  /// with optional aquaculture additions (DO, TAN, Nitrite, Transparency).
  static FishWaterAiAnalysis analyze({
    CommercialFishSpecies species = CommercialFishSpecies.generalPond,
    FarmingSystemType systemType = FarmingSystemType.earthenPond,
    String pondName = 'Commercial Fish Pond',
    required double ph,
    required double tds,
    required double ec,
    required double salinity,
    required double temperature,
    double? dissolvedOxygen,
    double? ammoniaTan,
    double? nitrite,
    double? transparency,
  }) {
    final criteria = speciesDatabase[species] ?? speciesDatabase[CommercialFishSpecies.generalPond]!;

    // If DO is not explicitly measured, estimate typical well-circulated pond daytime DO (80% of saturation)
    final double oxygenSaturation = calculateOxygenSaturation(temperature);
    final bool isEstimatedDo = dissolvedOxygen == null;
    final double effectiveDo = dissolvedOxygen ??
        double.parse((oxygenSaturation * 0.80).toStringAsFixed(2));

    // If TAN is not provided, estimate normal pond baseline (0.3 mg/L)
    final double effectiveTan = ammoniaTan ?? 0.30;

    // Calculate un-ionized toxic NH3 fraction
    final nh3 = calculateUnionizedAmmonia(
      tan: effectiveTan,
      ph: ph,
      temperatureCelsius: temperature,
    );

    // 1. Dissolved Oxygen Analysis (Weight: 32%)
    final doResult = _analyzeDissolvedOxygen(effectiveDo, criteria, isEstimated: isEstimatedDo);

    // 2. Toxic Ammonia & TAN Analysis (Weight: 24%)
    final nh3Result = _analyzeAmmonia(nh3, effectiveTan, criteria);

    // 3. pH Level Analysis (Weight: 18%)
    final phResult = _analyzePh(ph, criteria);

    // 4. Temperature Analysis (Weight: 14%)
    final tempResult = _analyzeTemperature(temperature, criteria);

    // 5. Salinity / TDS Analysis (Weight: 12%)
    final salinityResult = _analyzeSalinity(salinity, tds, criteria);

    final List<FishParameterResult> breakdown = [
      doResult,
      nh3Result,
      phResult,
      tempResult,
      salinityResult,
    ];

    if (nitrite != null) {
      breakdown.add(_analyzeNitrite(nitrite, criteria));
    }
    if (transparency != null) {
      breakdown.add(_analyzeTransparency(transparency));
    }

    // Weighted Overall Score (0 - 100)
    double weightedScore = (doResult.score * 32.0) +
        (nh3Result.score * 24.0) +
        (phResult.score * 18.0) +
        (tempResult.score * 14.0) +
        (salinityResult.score * 12.0);

    // Penalty for critical single parameters
    if (effectiveDo < criteria.criticalDo) {
      weightedScore = math.min(weightedScore, 34.0);
    }
    if (nh3 > criteria.maxSafeNh3 * 2.5) {
      weightedScore = math.min(weightedScore, 38.0);
    }
    if (ph < 5.8 || ph > 9.5) {
      weightedScore = math.min(weightedScore, 35.0);
    }

    final int overallScore = weightedScore.round().clamp(0, 100);

    // Determine Quality Tier
    final FishQualityLevel overallQuality;
    final String statusLabel;
    final String fishUsabilityVerdict;

    if (overallScore >= 85) {
      overallQuality = FishQualityLevel.optimal;
      statusLabel = 'Optimal for Commercial Growth';
      fishUsabilityVerdict = 'SAFE & READY FOR FISH STOCKING';
    } else if (overallScore >= 70) {
      overallQuality = FishQualityLevel.favorable;
      statusLabel = 'Favorable & Stable Quality';
      fishUsabilityVerdict = 'USABLE WITH ROUTINE MANAGEMENT';
    } else if (overallScore >= 50) {
      overallQuality = FishQualityLevel.moderateStress;
      statusLabel = 'Moderate Stress Warning';
      fishUsabilityVerdict = 'CONDITIONING REQUIRED BEFORE STOCKING';
    } else if (overallScore >= 32) {
      overallQuality = FishQualityLevel.danger;
      statusLabel = 'Alert: Unsafe Fish Environment';
      fishUsabilityVerdict = 'HIGH HAZARD: DO NOT STOCK FISH YET';
    } else {
      overallQuality = FishQualityLevel.critical;
      statusLabel = 'Emergency: Lethal Danger Hazard';
      fishUsabilityVerdict = 'LETHAL WATER: IMMEDIATE TREATMENT REQUIRED';
    }

    // Generate Species Matching List
    final speciesMatches = _calculateSpeciesMatches(
      ph: ph,
      temperature: temperature,
      salinity: salinity,
      tds: tds,
      dissolvedOxygen: effectiveDo,
    );

    // Generate Structured Action Steps ("What To Do With This Fish Water")
    final actionSteps = _generateActionPlanSteps(
      ph: ph,
      temperature: temperature,
      salinity: salinity,
      tds: tds,
      dissolvedOxygen: effectiveDo,
      nh3: nh3,
      overallQuality: overallQuality,
      species: criteria.commonName,
      systemType: systemType,
    );

    // AI Dynamic Advisories
    final aerationAdvisory = _generateAerationAdvisory(
      dissolvedOxygen: effectiveDo,
      criteria: criteria,
      temperature: temperature,
      systemType: systemType,
      isEstimated: isEstimatedDo,
      oxygenSaturation: oxygenSaturation,
    );

    final feedingAdvisory = _generateFeedingAdvisory(
      dissolvedOxygen: effectiveDo,
      nh3: nh3,
      temperature: temperature,
      criteria: criteria,
    );

    final pondTreatmentAdvisory = _generatePondTreatmentAdvisory(
      ph: ph,
      nh3: nh3,
      ammoniaTan: effectiveTan,
      nitrite: nitrite,
      systemType: systemType,
      criteria: criteria,
    );

    // Risk Indicators
    final hypoxiaRisk = effectiveDo < criteria.criticalDo
        ? 'Extreme Hypoxia (Surface Gasping Likely)'
        : (effectiveDo < criteria.optimalDoMin ? 'Moderate Sub-lethal Deficit' : 'Safe / Oxygen Saturated');

    final ammoniaRisk = nh3 > criteria.maxSafeNh3 * 2.0
        ? 'Severe Toxicosis (Gill Damage & Mortality)'
        : (nh3 > criteria.maxSafeNh3 ? 'Elevated NH3 Stress' : 'Safe Ammonia Reserve');

    final nitriteRisk = nitrite == null
        ? 'Not Measured'
        : (nitrite > criteria.maxSafeNitrite * 2.0
            ? 'High Brown Blood Disease Risk'
            : (nitrite > criteria.maxSafeNitrite ? 'Moderate Methemoglobin Risk' : 'Safe Nitrite Level'));

    final bacterialRisk = (temperature > criteria.optimalTempMax && effectiveTan > criteria.maxSafeTan)
        ? 'High Aeromonas / Columnaris Vulnerability'
        : (overallScore < 60 ? 'Moderate Pathogen Susceptibility' : 'Low Infection Risk');

    final whatToDoOverview = _generateWhatToDoOverview(
      overallQuality: overallQuality,
      ph: ph,
      temperature: temperature,
      salinity: salinity,
    );

    final executiveSummary = _generateExecutiveSummary(
      species: criteria.commonName,
      quality: overallQuality,
      doValue: effectiveDo,
      nh3Value: nh3,
      phValue: ph,
    );

    return FishWaterAiAnalysis(
      species: species,
      systemType: systemType,
      pondName: pondName.trim().isEmpty ? 'Commercial Fish Pond' : pondName.trim(),
      dissolvedOxygen: effectiveDo,
      isEstimatedDo: isEstimatedDo,
      estimatedOxygenSaturation: double.parse(oxygenSaturation.toStringAsFixed(2)),
      ph: ph,
      temperature: temperature,
      ammoniaTan: effectiveTan,
      unionizedAmmoniaNh3: nh3,
      nitrite: nitrite,
      salinity: salinity,
      tds: tds,
      ec: ec,
      transparency: transparency,
      overallScore: overallScore,
      overallQuality: overallQuality,
      overallStatusLabel: statusLabel,
      fishUsabilityVerdict: fishUsabilityVerdict,
      whatToDoOverview: whatToDoOverview,
      executiveSummary: executiveSummary,
      aerationAdvisory: aerationAdvisory,
      feedingAdvisory: feedingAdvisory,
      pondTreatmentAdvisory: pondTreatmentAdvisory,
      hypoxiaRisk: hypoxiaRisk,
      ammoniaToxicityRisk: ammoniaRisk,
      nitriteRisk: nitriteRisk,
      bacterialDiseaseRisk: bacterialRisk,
      parameterBreakdown: breakdown,
      speciesMatches: speciesMatches,
      actionSteps: actionSteps,
    );
  }

  static FishParameterResult _analyzeDissolvedOxygen(
    double doValue,
    SpeciesWaterCriteria criteria, {
    bool isEstimated = false,
  }) {
    final prefix = isEstimated ? '(Est.) ' : '';
    if (doValue >= criteria.optimalDoMin && doValue <= criteria.optimalDoMax) {
      return FishParameterResult(
        name: 'Dissolved Oxygen (DO)',
        symbol: 'DO',
        unit: 'mg/L',
        value: doValue,
        optimalRange: '${criteria.optimalDoMin} – ${criteria.optimalDoMax} mg/L',
        level: FishQualityLevel.optimal,
        remark: '${prefix}Optimal oxygen concentration for maximal feeding and growth vigor.',
        score: 1.0,
      );
    } else if (doValue > criteria.optimalDoMax) {
      return FishParameterResult(
        name: 'Dissolved Oxygen (DO)',
        symbol: 'DO',
        unit: 'mg/L',
        value: doValue,
        optimalRange: '${criteria.optimalDoMin} – ${criteria.optimalDoMax} mg/L',
        level: FishQualityLevel.favorable,
        remark: '${prefix}High oxygen concentration. Ensure adequate circulation during nighttime.',
        score: 0.88,
      );
    } else if (doValue >= criteria.criticalDo) {
      return FishParameterResult(
        name: 'Dissolved Oxygen (DO)',
        symbol: 'DO',
        unit: 'mg/L',
        value: doValue,
        optimalRange: '${criteria.optimalDoMin} – ${criteria.optimalDoMax} mg/L',
        level: FishQualityLevel.moderateStress,
        remark: '${prefix}Sub-optimal oxygen level. Supplemental mechanical aeration recommended.',
        score: 0.55,
      );
    } else {
      return FishParameterResult(
        name: 'Dissolved Oxygen (DO)',
        symbol: 'DO',
        unit: 'mg/L',
        value: doValue,
        optimalRange: '${criteria.optimalDoMin} – ${criteria.optimalDoMax} mg/L',
        level: FishQualityLevel.critical,
        remark: '${prefix}CRITICAL HYPOXIA: Fish suffocation hazard. Immediate aerator start required.',
        score: 0.15,
      );
    }
  }

  static FishParameterResult _analyzeAmmonia(
    double nh3,
    double tan,
    SpeciesWaterCriteria criteria,
  ) {
    if (nh3 <= criteria.maxSafeNh3 * 0.5) {
      return FishParameterResult(
        name: 'Toxic Un-ionized Ammonia',
        symbol: 'NH₃',
        unit: 'mg/L',
        value: nh3,
        optimalRange: '< ${criteria.maxSafeNh3} mg/L',
        level: FishQualityLevel.optimal,
        remark: 'Low toxic free ammonia. Fish gills and respiratory epithelium are in safe condition.',
        score: 1.0,
      );
    } else if (nh3 <= criteria.maxSafeNh3) {
      return FishParameterResult(
        name: 'Toxic Un-ionized Ammonia',
        symbol: 'NH₃',
        unit: 'mg/L',
        value: nh3,
        optimalRange: '< ${criteria.maxSafeNh3} mg/L',
        level: FishQualityLevel.favorable,
        remark: 'Acceptable commercial range. Monitor feeding closely so unconsumed pellets do not decay.',
        score: 0.82,
      );
    } else if (nh3 <= criteria.maxSafeNh3 * 2.0) {
      return FishParameterResult(
        name: 'Toxic Un-ionized Ammonia',
        symbol: 'NH₃',
        unit: 'mg/L',
        value: nh3,
        optimalRange: '< ${criteria.maxSafeNh3} mg/L',
        level: FishQualityLevel.moderateStress,
        remark: 'Elevated toxic ammonia. Causes gill irritation, reduced feeding, and stress.',
        score: 0.48,
      );
    } else {
      return FishParameterResult(
        name: 'Toxic Un-ionized Ammonia',
        symbol: 'NH₃',
        unit: 'mg/L',
        value: nh3,
        optimalRange: '< ${criteria.maxSafeNh3} mg/L',
        level: FishQualityLevel.critical,
        remark: 'TOXIC AMMONIA RISK: High mortality hazard. Reduce feeding and exchange water.',
        score: 0.12,
      );
    }
  }

  static FishParameterResult _analyzePh(
    double ph,
    SpeciesWaterCriteria criteria,
  ) {
    if (ph >= criteria.optimalPhMin && ph <= criteria.optimalPhMax) {
      return FishParameterResult(
        name: 'Water pH Level',
        symbol: 'pH',
        unit: 'pH',
        value: ph,
        optimalRange: '${criteria.optimalPhMin} – ${criteria.optimalPhMax}',
        level: FishQualityLevel.optimal,
        remark: 'Ideal balance (Golden Zone). Optimal gill respiration and nitrification cycle.',
        score: 1.0,
      );
    } else if ((ph >= criteria.optimalPhMin - 0.5 && ph < criteria.optimalPhMin) ||
        (ph > criteria.optimalPhMax && ph <= criteria.optimalPhMax + 0.4)) {
      return FishParameterResult(
        name: 'Water pH Level',
        symbol: 'pH',
        unit: 'pH',
        value: ph,
        optimalRange: '${criteria.optimalPhMin} – ${criteria.optimalPhMax}',
        level: FishQualityLevel.moderateStress,
        remark: ph < criteria.optimalPhMin
            ? 'Slightly acidic. Apply Agricultural Lime (CaCO3) to raise alkalinity.'
            : 'Slightly alkaline. Increases proportion of toxic un-ionized ammonia (NH3).',
        score: 0.60,
      );
    } else if (ph < 6.0) {
      return FishParameterResult(
        name: 'Water pH Level',
        symbol: 'pH',
        unit: 'pH',
        value: ph,
        optimalRange: '${criteria.optimalPhMin} – ${criteria.optimalPhMax}',
        level: FishQualityLevel.critical,
        remark: 'ACID WATER HAZARD: Corrodes fish gills and precipitates excess mucus.',
        score: 0.20,
      );
    } else {
      return FishParameterResult(
        name: 'Water pH Level',
        symbol: 'pH',
        unit: 'pH',
        value: ph,
        optimalRange: '${criteria.optimalPhMin} – ${criteria.optimalPhMax}',
        level: FishQualityLevel.critical,
        remark: 'EXTREME ALKALINE HAZARD: Damages gill lamellae and magnifies ammonia toxicity.',
        score: 0.20,
      );
    }
  }

  static FishParameterResult _analyzeTemperature(
    double temp,
    SpeciesWaterCriteria criteria,
  ) {
    if (temp >= criteria.optimalTempMin && temp <= criteria.optimalTempMax) {
      return FishParameterResult(
        name: 'Water Temperature',
        symbol: 'Temp',
        unit: '°C',
        value: temp,
        optimalRange: '${criteria.optimalTempMin} – ${criteria.optimalTempMax} °C',
        level: FishQualityLevel.optimal,
        remark: 'Prime tropical growth temperature for maximum feed digestion and growth rate.',
        score: 1.0,
      );
    } else if ((temp >= criteria.optimalTempMin - 3.0 && temp < criteria.optimalTempMin) ||
        (temp > criteria.optimalTempMax && temp <= criteria.optimalTempMax + 2.5)) {
      return FishParameterResult(
        name: 'Water Temperature',
        symbol: 'Temp',
        unit: '°C',
        value: temp,
        optimalRange: '${criteria.optimalTempMin} – ${criteria.optimalTempMax} °C',
        level: FishQualityLevel.favorable,
        remark: temp < criteria.optimalTempMin
            ? 'Cooler water; fish digestive enzymes slow down.'
            : 'Warm water; fish oxygen consumption doubles and ammonia production rises.',
        score: 0.75,
      );
    } else {
      return FishParameterResult(
        name: 'Water Temperature',
        symbol: 'Temp',
        unit: '°C',
        value: temp,
        optimalRange: '${criteria.optimalTempMin} – ${criteria.optimalTempMax} °C',
        level: FishQualityLevel.moderateStress,
        remark: 'Thermal stress zone. High temperature drops oxygen solubility sharply.',
        score: 0.35,
      );
    }
  }

  static FishParameterResult _analyzeSalinity(
    double salinity,
    double tds,
    SpeciesWaterCriteria criteria,
  ) {
    if (salinity >= criteria.optimalSalinityMin && salinity <= criteria.optimalSalinityMax) {
      return FishParameterResult(
        name: 'Salinity & Mineral TDS',
        symbol: 'Salinity',
        unit: 'ppt',
        value: salinity,
        optimalRange: '${criteria.optimalSalinityMin} – ${criteria.optimalSalinityMax} ppt',
        level: FishQualityLevel.optimal,
        remark: 'Ideal osmotic equilibrium; minimal fish energy expended on osmoregulation.',
        score: 1.0,
      );
    } else if (salinity > criteria.optimalSalinityMax * 1.5) {
      return FishParameterResult(
        name: 'Salinity & Mineral TDS',
        symbol: 'Salinity',
        unit: 'ppt',
        value: salinity,
        optimalRange: '${criteria.optimalSalinityMin} – ${criteria.optimalSalinityMax} ppt',
        level: FishQualityLevel.danger,
        remark: 'High salinity for freshwater species. Osmotic dehydration stress.',
        score: 0.30,
      );
    } else {
      return FishParameterResult(
        name: 'Salinity & Mineral TDS',
        symbol: 'Salinity',
        unit: 'ppt',
        value: salinity,
        optimalRange: '${criteria.optimalSalinityMin} – ${criteria.optimalSalinityMax} ppt',
        level: FishQualityLevel.favorable,
        remark: 'Tolerable osmoregulation balance.',
        score: 0.70,
      );
    }
  }

  static FishParameterResult _analyzeNitrite(
    double nitrite,
    SpeciesWaterCriteria criteria,
  ) {
    if (nitrite <= criteria.maxSafeNitrite) {
      return FishParameterResult(
        name: 'Nitrite Level',
        symbol: 'NO₂⁻',
        unit: 'mg/L',
        value: nitrite,
        optimalRange: '< ${criteria.maxSafeNitrite} mg/L',
        level: FishQualityLevel.optimal,
        remark: 'Safe nitrite level. Healthy blood hemoglobin oxygen capacity.',
        score: 1.0,
      );
    } else if (nitrite <= criteria.maxSafeNitrite * 2.5) {
      return FishParameterResult(
        name: 'Nitrite Level',
        symbol: 'NO₂⁻',
        unit: 'mg/L',
        value: nitrite,
        optimalRange: '< ${criteria.maxSafeNitrite} mg/L',
        level: FishQualityLevel.moderateStress,
        remark: 'Elevated nitrite. May cause methemoglobinemia (brown blood disease).',
        score: 0.50,
      );
    } else {
      return FishParameterResult(
        name: 'Nitrite Level',
        symbol: 'NO₂⁻',
        unit: 'mg/L',
        value: nitrite,
        optimalRange: '< ${criteria.maxSafeNitrite} mg/L',
        level: FishQualityLevel.critical,
        remark: 'TOXIC NITRITE: Acute brown blood disease hazard. Apply technical salt (NaCl).',
        score: 0.15,
      );
    }
  }

  static FishParameterResult _analyzeTransparency(double secchiCm) {
    if (secchiCm >= 25 && secchiCm <= 40) {
      return FishParameterResult(
        name: 'Pond Transparency',
        symbol: 'Secchi',
        unit: 'cm',
        value: secchiCm,
        optimalRange: '25 – 40 cm',
        level: FishQualityLevel.optimal,
        remark: 'Optimal phytoplankton density for natural food production & stable dissolved oxygen.',
        score: 1.0,
      );
    } else if (secchiCm < 20) {
      return FishParameterResult(
        name: 'Pond Transparency',
        symbol: 'Secchi',
        unit: 'cm',
        value: secchiCm,
        optimalRange: '25 – 40 cm',
        level: FishQualityLevel.moderateStress,
        remark: 'Excessive algal bloom or suspended clay. High night-time oxygen crash hazard.',
        score: 0.55,
      );
    } else {
      return FishParameterResult(
        name: 'Pond Transparency',
        symbol: 'Secchi',
        unit: 'cm',
        value: secchiCm,
        optimalRange: '25 – 40 cm',
        level: FishQualityLevel.favorable,
        remark: 'Clear water; low natural food productivity. Organic fertilization can help.',
        score: 0.75,
      );
    }
  }

  static List<FishSpeciesMatch> _calculateSpeciesMatches({
    required double ph,
    required double temperature,
    required double salinity,
    required double tds,
    required double dissolvedOxygen,
  }) {
    final List<FishSpeciesMatch> matches = [];

    for (final entry in speciesDatabase.entries) {
      if (entry.key == CommercialFishSpecies.generalPond) continue;

      final sp = entry.value;
      double score = 100.0;
      final List<String> reasons = [];

      // pH penalty
      if (ph < sp.optimalPhMin) {
        final diff = sp.optimalPhMin - ph;
        score -= diff * 25.0;
        reasons.add('Water is too acidic for ${sp.commonName}');
      } else if (ph > sp.optimalPhMax) {
        final diff = ph - sp.optimalPhMax;
        score -= diff * 30.0;
        reasons.add('High pH increases toxic ammonia for ${sp.commonName}');
      }

      // Temp penalty
      if (temperature < sp.optimalTempMin) {
        final diff = sp.optimalTempMin - temperature;
        score -= diff * 4.0;
        reasons.add('Temperature is below ideal growth zone');
      } else if (temperature > sp.optimalTempMax) {
        final diff = temperature - sp.optimalTempMax;
        score -= diff * 6.0;
        reasons.add('Temperature is above ideal growth zone');
      }

      // Salinity penalty
      if (salinity < sp.optimalSalinityMin) {
        final diff = sp.optimalSalinityMin - salinity;
        score -= diff * 4.0;
        reasons.add('Salinity is too low (requires brackish water)');
      } else if (salinity > sp.optimalSalinityMax) {
        final diff = salinity - sp.optimalSalinityMax;
        score -= diff * 8.0;
        reasons.add('Salinity exceeds freshwater threshold');
      }

      // Dissolved Oxygen penalty
      if (dissolvedOxygen < sp.criticalDo) {
        score -= 40.0;
        reasons.add('Critical oxygen shortage for this species');
      } else if (dissolvedOxygen < sp.optimalDoMin) {
        score -= 15.0;
        reasons.add('Oxygen is below peak growth demand');
      }

      final int finalScore = score.round().clamp(5, 99);
      final String verdict;
      if (finalScore >= 85) {
        verdict = 'Optimal Match';
      } else if (finalScore >= 68) {
        verdict = 'Good Compatibility';
      } else if (finalScore >= 45) {
        verdict = 'Tolerable with Caution';
      } else {
        verdict = 'Unsuitable';
      }

      final String summaryReason = reasons.isEmpty
          ? 'Water parameters match ideal biological conditions.'
          : reasons.join('; ');

      matches.add(
        FishSpeciesMatch(
          species: entry.key,
          commonName: sp.commonName,
          compatibilityPercent: finalScore,
          verdict: verdict,
          reason: summaryReason,
        ),
      );
    }

    // Sort by compatibility descending
    matches.sort((a, b) => b.compatibilityPercent.compareTo(a.compatibilityPercent));
    return matches;
  }

  static List<ActionPlanStep> _generateActionPlanSteps({
    required double ph,
    required double temperature,
    required double salinity,
    required double tds,
    required double dissolvedOxygen,
    required double nh3,
    required FishQualityLevel overallQuality,
    required String species,
    required FarmingSystemType systemType,
  }) {
    final List<ActionPlanStep> steps = [];

    // 1. pH & Liming Action
    if (ph < 6.5) {
      final double deficit = (7.5 - ph);
      final int doseKgPerDecimal = (deficit * 1.2).ceil().clamp(1, 3);
      final int doseKgPerAcre = doseKgPerDecimal * 100;
      steps.add(
        ActionPlanStep(
          title: 'Apply Agricultural Lime (CaCO₃)',
          description:
              'Water is acidic (pH $ph). Broadcast $doseKgPerDecimal kg per decimal (~$doseKgPerAcre kg/acre) of agricultural limestone across the pond surface in the morning. Re-test pH after 48 hours before stocking.',
          urgency: 'Immediate',
          category: 'pH & Liming',
        ),
      );
    } else if (ph > 8.5) {
      steps.add(
        ActionPlanStep(
          title: 'Mitigate Alkaline pH / Ammonia Spike',
          description:
              'Water is alkaline (pH $ph). DO NOT add lime. Carry out a 15–20% partial water exchange with fresh tube-well water to lower pH and prevent toxic un-ionized ammonia (NH₃) formation.',
          urgency: 'Immediate',
          category: 'pH & Liming',
        ),
      );
    } else {
      steps.add(
        ActionPlanStep(
          title: 'pH is Balanced (Golden Zone)',
          description:
              'Water pH is $ph, which is within the safe 6.5–8.5 range. No corrective liming is required. Routine maintenance liming (0.5 kg/decimal every 2 months) can be followed.',
          urgency: 'Routine',
          category: 'pH & Liming',
        ),
      );
    }

    // 2. Aeration Action
    if (dissolvedOxygen < 3.5) {
      steps.add(
        ActionPlanStep(
          title: 'Emergency Mechanical Aeration',
          description:
              'Dissolved oxygen is low ($dissolvedOxygen mg/L). Start all paddlewheel aerators or air blowers at 100% capacity right away. If fish are at surface, add fresh oxygenated water or emergency sodium percarbonate.',
          urgency: 'Immediate',
          category: 'Aeration',
        ),
      );
    } else if (dissolvedOxygen < 5.0) {
      steps.add(
        ActionPlanStep(
          title: 'Scheduled Night-time Aeration',
          description:
              'Dissolved oxygen is moderate ($dissolvedOxygen mg/L). Run aerators for 6 hours nightly from 12:00 AM to 6:00 AM when algal photosynthesis halts and nocturnal respiration peaks.',
          urgency: 'Recommended',
          category: 'Aeration',
        ),
      );
    } else {
      steps.add(
        ActionPlanStep(
          title: 'Aeration Schedule is Optimal',
          description:
              'Oxygen level is healthy ($dissolvedOxygen mg/L). Keep standard aeration cycle: 2 hours around 1:00 PM for water de-stratification and 3 hours before dawn (3:00 AM–6:00 AM).',
          urgency: 'Routine',
          category: 'Aeration',
        ),
      );
    }

    // 3. Feeding Strategy Action
    if (dissolvedOxygen < 3.5 || nh3 > 0.05) {
      steps.add(
        ActionPlanStep(
          title: 'Suspend / Cut Feeding Today',
          description:
              'Hold back feed by 50% to 100%. Digesting feed requires high metabolic oxygen. Feeding during oxygen or ammonia stress causes immediate fish mortality and severe water fouling.',
          urgency: 'Immediate',
          category: 'Feeding',
        ),
      );
    } else if (temperature > 32.0 || temperature < 22.0) {
      steps.add(
        ActionPlanStep(
          title: 'Adjust Feeding Time & Ration',
          description:
              'Water temperature is ${temperature.toStringAsFixed(1)}°C. Reduce daily feed by 20–30%. In hot weather, feed only during cooler morning hours (7:30 AM) and evening (5:00 PM).',
          urgency: 'Recommended',
          category: 'Feeding',
        ),
      );
    } else {
      steps.add(
        ActionPlanStep(
          title: 'Feed at Normal Commercial Rate',
          description:
              'Water conditions are prime. Deliver full daily feed ration (2.5% to 3.5% of total estimated fish body weight), divided into 2 equal daily meals.',
          urgency: 'Routine',
          category: 'Feeding',
        ),
      );
    }

    // 4. Salinity & Water Conditioning Action
    if (salinity > 3.0) {
      steps.add(
        ActionPlanStep(
          title: 'Salinity / Mineral Regulation',
          description:
              'Salinity is $salinity ppt. This water is slightly brackish. Highly suitable for Tilapia and Shrimp, but unsuitable for delicate Major Carp fry (Rui/Catla). Add fresh canal/well water if cultivating freshwater carp.',
          urgency: 'Recommended',
          category: 'Water Conditioning',
        ),
      );
    } else if (tds > 1000.0) {
      steps.add(
        ActionPlanStep(
          title: 'Bottom Sludge Siphon & Water Exchange',
          description:
              'Total Dissolved Solids are elevated ($tds ppm). Drain 20% bottom water and replace with fresh water to prevent mineral toxicity and gill clogging.',
          urgency: 'Recommended',
          category: 'Water Conditioning',
        ),
      );
    } else {
      steps.add(
        ActionPlanStep(
          title: 'Pre-Stocking Pond Acclimatization',
          description:
              'Water mineral balance is optimal ($tds ppm, $salinity ppt). Float seed bags in pond water for 25–30 minutes to equalize water temperature before releasing fingerlings into the pond.',
          urgency: 'Routine',
          category: 'Water Conditioning',
        ),
      );
    }

    return steps;
  }

  static String _generateWhatToDoOverview({
    required FishQualityLevel overallQuality,
    required double ph,
    required double temperature,
    required double salinity,
  }) {
    switch (overallQuality) {
      case FishQualityLevel.optimal:
        return 'This water is in EXCELLENT condition for commercial fish farming. Temperature ($temperature°C) and pH ($ph) are in the prime biological zone. You can stock fingerlings directly after 25 minutes of temperature acclimatization.';
      case FishQualityLevel.favorable:
        return 'This water is SAFE and ready for fish cultivation with routine management. Ensure regular night-time aeration and maintain standard feeding schedules.';
      case FishQualityLevel.moderateStress:
        return 'This water needs CONDITIONING before introducing new fish. Check the liming and aeration guidance below to bring pH and oxygen into the optimal zone before stocking.';
      case FishQualityLevel.danger:
      case FishQualityLevel.critical:
        return 'DO NOT STOCK FISH in this water yet. Critical stress parameters were detected. Apply the recommended lime or water exchange treatment and re-test after 48 hours.';
    }
  }

  static String _generateAerationAdvisory({
    required double dissolvedOxygen,
    required SpeciesWaterCriteria criteria,
    required double temperature,
    required FarmingSystemType systemType,
    bool isEstimated = false,
    double oxygenSaturation = 7.8,
  }) {
    final note = isEstimated ? ' (Estimated from temperature saturation capacity: ${oxygenSaturation.toStringAsFixed(1)} mg/L)' : '';
    if (dissolvedOxygen < criteria.criticalDo) {
      return 'EMERGENCY AERATION ACTIVATION: DO is below critical threshold (${dissolvedOxygen.toStringAsFixed(1)} mg/L). Start mechanical aerators (paddlewheels / blowers) at 100% capacity immediately.$note';
    } else if (dissolvedOxygen < criteria.optimalDoMin) {
      return 'PROACTIVE AERATION SCHEDULE: Run aerators continuously from 11:00 PM to 7:00 AM when photosynthesis ceases and nocturnal respiration consumes oxygen.$note';
    } else {
      return 'AERATION OPTIMAL: Dissolved oxygen is healthy (${dissolvedOxygen.toStringAsFixed(1)} mg/L). Follow standard energy-saving schedule: operate aerators during mid-day destratification and late night.$note';
    }
  }

  static String _generateFeedingAdvisory({
    required double dissolvedOxygen,
    required double nh3,
    required double temperature,
    required SpeciesWaterCriteria criteria,
  }) {
    if (dissolvedOxygen < criteria.criticalDo) {
      return 'SUSPEND FEEDING IMMEDIATELY: Digestion consumes high metabolic oxygen. Feeding during hypoxia will trigger rapid fish mortality and feed waste.';
    } else if (nh3 > criteria.maxSafeNh3 * 1.8) {
      return 'REDUCE FEED BY 60%: High toxic ammonia (${nh3.toStringAsFixed(3)} mg/L). Switch to lower-protein feed or skip 1-2 feeding sessions.';
    } else if (dissolvedOxygen < criteria.optimalDoMin || nh3 > criteria.maxSafeNh3) {
      return 'REDUCE FEED BY 25%: Environmental stress detected. Adjust ration size to maintain feed conversion ratio (FCR) and prevent uneaten feed from sinking.';
    } else if (temperature > criteria.optimalTempMax + 2.0) {
      return 'SHIFT FEEDING TIME: Water is warm (${temperature.toStringAsFixed(1)} °C). Feed during cooler morning hours (7:30 AM) and late afternoon (5:00 PM).';
    } else {
      return 'OPTIMAL FEEDING RATION: Water conditions are ideal. Deliver 100% daily feed allowance based on biomass calculation (2.5 - 3.5% body weight).';
    }
  }

  static String _generatePondTreatmentAdvisory({
    required double ph,
    required double nh3,
    required double ammoniaTan,
    required double? nitrite,
    required FarmingSystemType systemType,
    required SpeciesWaterCriteria criteria,
  }) {
    final List<String> actions = [];

    if (ph < 6.8) {
      final double deficit = (7.5 - ph);
      final int doseKgPerAcre = (deficit * 120).round().clamp(50, 250);
      final int doseKgPerDecimal = (doseKgPerAcre / 100).ceil();
      actions.add('LIMING: Apply Agricultural Limestone (CaCO3) at $doseKgPerDecimal kg/decimal (~$doseKgPerAcre kg/acre) to restore buffer capacity.');
    } else if (ph > 8.8) {
      actions.add('ALKALINE BUFFER: High pH ($ph) accelerates toxic NH3 formation. Carry out a 15-20% partial water exchange; avoid adding quicklime.');
    }

    if (nh3 > criteria.maxSafeNh3) {
      if (systemType == FarmingSystemType.biofloc) {
        actions.add('BIOFLOC CARBON DOSING: Add carbon source (Molasses or Rice Bran) targeting C:N ratio of 15:1 to stimulate heterotrophic ammonia assimilation.');
      } else {
        actions.add('WATER FLUSH: Perform a 20-30% bottom-sludge siphon and refill with clean water to dilute total ammonia nitrogen (TAN).');
      }
    }

    if (nitrite != null && nitrite > criteria.maxSafeNitrite) {
      actions.add('SALT INTERVENTION: Apply coarse aquaculture salt (NaCl) at 50-80 kg/acre. Chloride ions (Cl-) block nitrite absorption through fish gills.');
    }

    if (actions.isEmpty) {
      return 'ROUTINE BIO-SECURITY: Parameters are in excellent equilibrium. Maintain regular weekly pond bottom probiotic dosing and monitor weekly alkalinity.';
    }

    return actions.join('\n• ');
  }

  static String _generateExecutiveSummary({
    required String species,
    required FishQualityLevel quality,
    required double doValue,
    required double nh3Value,
    required double phValue,
  }) {
    switch (quality) {
      case FishQualityLevel.optimal:
        return 'All critical aquaculture metrics are within optimal biological thresholds for $species. Dissolved oxygen ($doValue mg/L) and toxic ammonia ($nh3Value mg/L) provide maximum growth velocity and feed efficiency.';
      case FishQualityLevel.favorable:
        return 'Pond water quality is favorable and safe for $species farming. Routine monitoring recommended to prevent afternoon pH swings or dawn oxygen dips.';
      case FishQualityLevel.moderateStress:
        return 'Sub-optimal conditions detected for $species. Fish are experiencing environmental stress which may depress feed intake and slow growth. Follow the aeration and feeding recommendations.';
      case FishQualityLevel.danger:
        return 'WARNING: Elevated toxicity or oxygen deficit poses a health hazard to $species. Prompt corrective management is necessary to prevent mortality and biomass loss.';
      case FishQualityLevel.critical:
        return 'EMERGENCY: Lethal parameters detected! Immediate intervention required for $species (check DO: $doValue mg/L, pH: $phValue, NH3: $nh3Value mg/L) to prevent severe fish die-off.';
    }
  }
}
