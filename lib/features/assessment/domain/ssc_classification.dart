/// Soil Suppressiveness Classification (SSC) categories.
///
/// These labels are the project's proposed classes. They are not derived from a
/// validated numerical index and must not be presented as a scientific score.
enum SscClassification {
  suppressive,
  moderatelySuppressive,
  conducive;

  String get label {
    switch (this) {
      case SscClassification.suppressive:
        return 'Suppressive';
      case SscClassification.moderatelySuppressive:
        return 'Moderately Suppressive';
      case SscClassification.conducive:
        return 'Conducive';
    }
  }

  /// Stable value for a future Firestore `ssc` / `classification` field.
  String get storageValue {
    switch (this) {
      case SscClassification.suppressive:
        return 'suppressive';
      case SscClassification.moderatelySuppressive:
        return 'moderately_suppressive';
      case SscClassification.conducive:
        return 'conducive';
    }
  }

  static SscClassification? tryParse(String? value) {
    switch (value) {
      case 'suppressive':
        return SscClassification.suppressive;
      case 'moderately_suppressive':
      case 'moderatelySuppressive':
        return SscClassification.moderatelySuppressive;
      case 'conducive':
        return SscClassification.conducive;
      default:
        return null;
    }
  }
}

class SscCategoryContent {
  const SscCategoryContent({
    required this.classification,
    required this.description,
    required this.interpretation,
    required this.recommendedAction,
    required this.contributingParameters,
    required this.managementPractices,
  });

  final SscClassification classification;
  final String description;
  final String interpretation;
  final String recommendedAction;
  final List<String> contributingParameters;
  final List<String> managementPractices;
}

/// Placeholder copy for each SSC category.
///
/// Content is structural only. It is not produced by a trained or field-validated
/// classification model.
abstract final class SscCatalog {
  static const isPlaceholder = true;

  static const contributingParameters = <String>[
    'Soil pH',
    'Soil moisture',
    'Soil temperature',
    'Electrical conductivity (EC)',
    'CO₂ respiration indicator',
    'Soil texture',
  ];

  static const disclaimer =
      'This assessment only evaluates soil conditions that may favor or suppress '
      'the establishment of Fusarium wilt. SoilSAFE does not detect Fusarium '
      'oxysporum f. sp. cubense Tropical Race 4 (Foc TR4) and does not confirm '
      'the presence or absence of the pathogen.';

  static SscCategoryContent of(SscClassification classification) {
    switch (classification) {
      case SscClassification.suppressive:
        return const SscCategoryContent(
          classification: SscClassification.suppressive,
          description:
              'Placeholder class for soil conditions associated with higher '
              'potential to suppress Fusarium wilt development.',
          interpretation:
              'The assessed soil conditions are shown here as a placeholder '
              'Suppressive classification. A validated SSC model has not been '
              'applied. Continue monitoring measured parameters and follow '
              'recommended soil management practices.',
          recommendedAction:
              'Maintain current soil-management practices and keep monitoring '
              'pH, moisture, and microbial activity indicators.',
          contributingParameters: contributingParameters,
          managementPractices: [
            'Continue organic mulching to support microbial activity.',
            'Keep drainage functional so moisture does not become excessive.',
            'Reassess after major weather or amendment events.',
          ],
        );
      case SscClassification.moderatelySuppressive:
        return const SscCategoryContent(
          classification: SscClassification.moderatelySuppressive,
          description:
              'Placeholder class for soil conditions with moderate '
              'suppressiveness potential.',
          interpretation:
              'The assessed soil conditions indicate moderate suppressiveness '
              'potential. Continue monitoring and follow recommended soil '
              'management practices.',
          recommendedAction:
              'Monitor key soil parameters and apply recommended management '
              'practices while the classification model is being validated.',
          contributingParameters: contributingParameters,
          managementPractices: [
            'Incorporate organic matter to support beneficial microbial activity.',
            'Watch drainage after heavy rain to limit waterlogging.',
            'Record follow-up readings so later assessments can be compared.',
          ],
        );
      case SscClassification.conducive:
        return const SscCategoryContent(
          classification: SscClassification.conducive,
          description:
              'Placeholder class for soil conditions associated with higher '
              'potential to favor Fusarium wilt development.',
          interpretation:
              'The assessed soil conditions are shown here as a placeholder '
              'Conducive classification. This does not confirm that Fusarium is '
              'present. Review measured parameters and recommended management '
              'practices, then reassess after interventions.',
          recommendedAction:
              'Review contributing parameters, apply recommended soil management '
              'practices, and schedule a follow-up assessment.',
          contributingParameters: contributingParameters,
          managementPractices: [
            'Improve drainage in persistently wet areas.',
            'Add organic amendments to support microbial competition.',
            'Reassess after management changes; do not treat this as a disease diagnosis.',
          ],
        );
    }
  }
}
