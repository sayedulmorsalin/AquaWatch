import 'package:flutter_test/flutter_test.dart';
import 'package:aquawatch/services/fish_water_ai_service.dart';

void main() {
  group('FishWaterAiService Calculations & Modeling', () {
    test('calculateUnionizedAmmonia computes accurate Emerson equilibrium', () {
      final nh3 = FishWaterAiService.calculateUnionizedAmmonia(
        tan: 1.0,
        ph: 8.0,
        temperatureCelsius: 28.0,
      );

      expect(nh3, greaterThan(0.04));
      expect(nh3, lessThan(0.12));
    });

    test('Higher pH dramatically increases toxic un-ionized NH3 proportion', () {
      final nh3LowPh = FishWaterAiService.calculateUnionizedAmmonia(
        tan: 1.0,
        ph: 7.0,
        temperatureCelsius: 28.0,
      );

      final nh3HighPh = FishWaterAiService.calculateUnionizedAmmonia(
        tan: 1.0,
        ph: 8.5,
        temperatureCelsius: 28.0,
      );

      expect(nh3HighPh, greaterThan(nh3LowPh * 8));
    });

    test('Optimal Tilapia pond returns optimal quality score & normal feeding', () {
      final analysis = FishWaterAiService.analyze(
        species: CommercialFishSpecies.tilapia,
        systemType: FarmingSystemType.earthenPond,
        pondName: 'Tilapia Pond #1',
        dissolvedOxygen: 6.5,
        ph: 7.6,
        temperature: 28.5,
        ammoniaTan: 0.3,
        salinity: 0.5,
        tds: 350.0,
        ec: 580.0,
      );

      expect(analysis.overallScore, greaterThanOrEqualTo(85));
      expect(analysis.overallQuality, equals(FishQualityLevel.optimal));
      expect(analysis.feedingAdvisory.toLowerCase(), contains('optimal'));
      expect(analysis.aerationAdvisory.toLowerCase(), contains('optimal'));
      expect(analysis.fishUsabilityVerdict, contains('READY FOR FISH'));
    });

    test('Works seamlessly with only standard 5 potable parameters (pH, TDS, EC, Salinity, Temp)', () {
      final analysis = FishWaterAiService.analyze(
        ph: 7.5,
        tds: 320.0,
        ec: 540.0,
        salinity: 0.4,
        temperature: 28.0,
      );

      expect(analysis.isEstimatedDo, isTrue);
      expect(analysis.dissolvedOxygen, greaterThan(5.0));
      expect(analysis.estimatedOxygenSaturation, greaterThan(7.0));
      expect(analysis.actionSteps, isNotEmpty);
      expect(analysis.speciesMatches, isNotEmpty);
      expect(analysis.whatToDoOverview, isNotEmpty);

      // Verify that Tilapia is a strong match in 28°C freshwater
      final tilapiaMatch = analysis.speciesMatches.firstWhere(
        (m) => m.species == CommercialFishSpecies.tilapia,
      );
      expect(tilapiaMatch.compatibilityPercent, greaterThanOrEqualTo(85));
    });

    test('Acid water triggers agricultural lime recommendation in action steps', () {
      final analysis = FishWaterAiService.analyze(
        ph: 5.6, // Acidic water
        tds: 200.0,
        ec: 350.0,
        salinity: 0.2,
        temperature: 27.0,
      );

      expect(analysis.overallQuality, isIn([FishQualityLevel.moderateStress, FishQualityLevel.danger, FishQualityLevel.critical]));
      expect(
        analysis.fishUsabilityVerdict,
        anyOf([
          contains('CONDITIONING REQUIRED'),
          contains('HAZARD'),
          contains('LETHAL'),
        ]),
      );

      final limeStep = analysis.actionSteps.firstWhere(
        (s) => s.category == 'pH & Liming',
      );
      expect(limeStep.description.toLowerCase(), contains('lime'));
      expect(limeStep.urgency, equals('Immediate'));
    });

    test('Critical hypoxia triggers emergency aeration and feeding suspension', () {
      final analysis = FishWaterAiService.analyze(
        species: CommercialFishSpecies.majorCarp,
        systemType: FarmingSystemType.earthenPond,
        pondName: 'Carp Nursery',
        dissolvedOxygen: 2.1,
        ph: 7.4,
        temperature: 28.0,
        ammoniaTan: 0.2,
        salinity: 0.2,
        tds: 250.0,
        ec: 400.0,
      );

      expect(analysis.overallScore, lessThan(40));
      expect(analysis.overallQuality, isIn([FishQualityLevel.danger, FishQualityLevel.critical]));
      expect(analysis.feedingAdvisory.toLowerCase(), contains('suspend feeding'));
      expect(analysis.aerationAdvisory.toLowerCase(), contains('emergency aeration'));
      expect(analysis.hypoxiaRisk.toLowerCase(), contains('hypoxia'));
    });

    test('High ammonia triggers 60% feed reduction and water flush warning', () {
      final analysis = FishWaterAiService.analyze(
        species: CommercialFishSpecies.pangasius,
        systemType: FarmingSystemType.earthenPond,
        pondName: 'Pangas Pond',
        dissolvedOxygen: 5.5,
        ph: 8.4,
        temperature: 30.0,
        ammoniaTan: 2.2,
        salinity: 0.3,
        tds: 400.0,
        ec: 650.0,
      );

      expect(analysis.feedingAdvisory.toLowerCase(), contains('reduce feed'));
      expect(analysis.pondTreatmentAdvisory.toLowerCase(), contains('water flush'));
      expect(analysis.ammoniaToxicityRisk.toLowerCase(), contains('toxic'));
    });
  });
}
