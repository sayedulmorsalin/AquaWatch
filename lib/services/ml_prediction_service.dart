import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class MlPredictionResult {
  final bool isPotable;
  final String predictionLabel;
  final double potabilityProbability;
  final double unsafeRiskProbability;
  final String riskLevel;
  final double decisionThresholdUsed;
  final List<String> providedFeatures;
  final List<String> missingFeatures;
  final String dataCompleteness;
  final List<String> featureWarnings;
  final String regulatoryDisclaimer;

  MlPredictionResult({
    required this.isPotable,
    required this.predictionLabel,
    required this.potabilityProbability,
    required this.unsafeRiskProbability,
    required this.riskLevel,
    required this.decisionThresholdUsed,
    required this.providedFeatures,
    required this.missingFeatures,
    required this.dataCompleteness,
    required this.featureWarnings,
    required this.regulatoryDisclaimer,
  });

  factory MlPredictionResult.fromJson(Map<String, dynamic> json) {
    return MlPredictionResult(
      isPotable: json['is_potable'] as bool? ?? false,
      predictionLabel: json['prediction_label'] as String? ?? 'Unknown',
      potabilityProbability:
          (json['potability_probability'] as num?)?.toDouble() ?? 0.0,
      unsafeRiskProbability:
          (json['unsafe_risk_probability'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['risk_level'] as String? ?? 'Unknown',
      decisionThresholdUsed:
          (json['decision_threshold_used'] as num?)?.toDouble() ?? 0.54,
      providedFeatures: List<String>.from(json['provided_features'] ?? []),
      missingFeatures: List<String>.from(json['missing_features'] ?? []),
      dataCompleteness: json['data_completeness'] as String? ?? '',
      featureWarnings: List<String>.from(json['feature_warnings'] ?? []),
      regulatoryDisclaimer: json['regulatory_disclaimer'] as String? ?? '',
    );
  }
}

class MlPredictionService {
  /// Base URL auto-detection:
  /// - Android Emulator: 10.0.2.2 points to host PC localhost
  /// - Web / Windows Desktop / macOS: localhost
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  /// Sends water parameters collected in the app to the AquaWatch ML API.
  /// Missing features are automatically imputed with baseline medians by the API.
  static Future<MlPredictionResult?> predictPotability({
    required double ph,
    required double tds,
    required double ec,
    double? salinity,
    double? temperature,
    double? turbidity,
    String? customBaseUrl,
  }) async {
    final baseUrl = customBaseUrl ?? defaultBaseUrl;
    final url = Uri.parse('$baseUrl/predict');

    final payload = <String, dynamic>{
      'ph': ph,
      'tds': tds,
      'ec': ec,
    };
    if (salinity != null) payload['salinity'] = salinity;
    if (temperature != null) payload['temperature'] = temperature;
    if (turbidity != null) payload['turbidity'] = turbidity;

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MlPredictionResult.fromJson(data);
      }
    } catch (_) {
      // Graceful fallback if ML API server is currently unreachable
      return null;
    }
    return null;
  }
}

