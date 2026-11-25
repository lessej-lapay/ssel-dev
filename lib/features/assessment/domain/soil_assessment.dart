import 'ssc_classification.dart';

class SoilData {
  const SoilData({
    required this.pH,
    required this.moisture,
    required this.temperature,
    required this.ec,
    required this.co2,
    required this.texture,
    this.assessedAt,
    this.placeholderClassification,
  });

  final double pH;
  final double moisture;
  final double temperature;
  final double ec;
  final double co2;
  final String texture;
  final DateTime? assessedAt;

  /// Demo-only class until a validated SSC model exists.
  /// Never treat this as a computed index score.
  final SscClassification? placeholderClassification;
}

class SoilAssessmentReport {
  const SoilAssessmentReport({
    required this.soil,
    required this.isPlaceholder,
    required this.classificationLabel,
    required this.description,
    required this.interpretation,
    required this.recommendedAction,
    required this.contributingParameters,
    required this.contributingFactors,
    required this.managementPractices,
    required this.disclaimer,
    this.classification,
  });

  final SoilData soil;
  final bool isPlaceholder;
  final SscClassification? classification;
  final String classificationLabel;
  final String description;
  final String interpretation;
  final String recommendedAction;
  final List<String> contributingParameters;
  final List<String> contributingFactors;
  final List<String> managementPractices;
  final String disclaimer;
}
