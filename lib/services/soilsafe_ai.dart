import '../features/assessment/domain/soil_assessment.dart';
import '../features/assessment/domain/ssc_classification.dart';
import '../features/assessment/domain/ssc_system_parameters.dart';

export '../features/assessment/domain/soil_assessment.dart';
export '../features/assessment/domain/ssc_classification.dart';

/// Builds an SSC assessment view from measured soil parameters.
///
/// Classification is not computed from a numerical SSI. Until a validated model
/// exists, reports use placeholder category copy and centralized parameter rules.
class SoilSafeAI {
  static SoilAssessmentReport generateReport(
    SoilData data, {
    SscSystemParameters parameters = SscSystemParameters.current,
  }) {
    final category = data.placeholderClassification == null
        ? null
        : SscCatalog.of(data.placeholderClassification!);

    return SoilAssessmentReport(
      soil: data,
      isPlaceholder: SscCatalog.isPlaceholder,
      classification: data.placeholderClassification,
      classificationLabel: category?.classification.label ?? 'Not classified',
      description: category?.description ??
          'Soil Suppressiveness Classification is not available until a '
              'validated model is applied.',
      interpretation: category?.interpretation ??
          'Measured soil parameters are shown below. No SSC result has been '
              'assigned because a validated classification model is not yet in use.',
      recommendedAction: category?.recommendedAction ??
          'Review the measured parameters and wait for a validated SSC result.',
      contributingParameters:
          category?.contributingParameters ?? SscCatalog.contributingParameters,
      contributingFactors: _placeholderFactors(data, parameters),
      managementPractices: [
        ...?category?.managementPractices,
        ..._placeholderTexturePractices(data, parameters),
      ],
      disclaimer: SscCatalog.disclaimer,
    );
  }

  static List<String> _placeholderFactors(
    SoilData data,
    SscSystemParameters parameters,
  ) {
    final factors = <String>[];

    if (data.pH < parameters.placeholderLowPh) {
      factors.add(
        'Low pH (acidic): acidic soils are often associated with conditions '
        'that can favor Fusarium pathogens. Placeholder rule — not validated.',
      );
    } else if (data.pH > parameters.placeholderHighPh) {
      factors.add(
        'High pH: strongly alkaline conditions can affect nutrient availability. '
        'Placeholder rule — not validated.',
      );
    }

    if (data.co2 < parameters.placeholderLowCo2Ppm) {
      factors.add(
        'Low CO₂ respiration: may indicate limited microbial activity. '
        'Placeholder rule — not validated.',
      );
    }

    if (data.moisture > parameters.placeholderHighMoisturePercent) {
      factors.add(
        'High moisture: excess wetness can support movement of soil-borne '
        'pathogens. Placeholder rule — not validated.',
      );
    }

    if (data.ec > parameters.placeholderHighEcDsPerM) {
      factors.add(
        'High electrical conductivity: elevated salt levels can stress banana '
        'plants. Placeholder rule — not validated.',
      );
    }

    final texture = data.texture.toLowerCase();
    if (texture.contains('sandy')) {
      factors.add(
        'Sandy texture: sandy soils drain quickly and may hold fewer microbial '
        'populations. Placeholder rule — not validated.',
      );
    } else if (texture.contains('clay') &&
        data.moisture > parameters.placeholderClayMoisturePercent) {
      factors.add(
        'Clay texture with high moisture: poor aeration can favor conditions '
        'associated with Foc. Placeholder rule — not validated.',
      );
    }

    return factors;
  }

  static List<String> _placeholderTexturePractices(
    SoilData data,
    SscSystemParameters parameters,
  ) {
    final texture = data.texture.toLowerCase();
    if (texture.contains('sandy')) {
      return const [
        'Consider organic amendments to improve water and nutrient retention '
            'in sandy soil. Placeholder practice — not validated.',
      ];
    }
    if (texture.contains('clay') &&
        data.moisture > parameters.placeholderClayMoisturePercent) {
      return const [
        'Improve field drainage and avoid over-irrigation in clay-heavy zones. '
            'Placeholder practice — not validated.',
      ];
    }
    return const [];
  }
}
