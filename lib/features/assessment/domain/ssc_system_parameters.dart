/// Central placeholder for SSC rules that administrators will eventually manage.
///
/// Planned Firestore document (not written yet — no assessment collection exists):
/// `system_parameters/ssc`
///
/// Values here are structural placeholders only. They are not scientifically
/// validated thresholds and must not be duplicated in UI widgets.
class SscSystemParameters {
  const SscSystemParameters({
    this.placeholderLowPh = 6.0,
    this.placeholderHighPh = 7.5,
    this.placeholderHighMoisturePercent = 70,
    this.placeholderLowCo2Ppm = 20,
    this.placeholderHighEcDsPerM = 1.5,
    this.placeholderClayMoisturePercent = 60,
  });

  static const current = SscSystemParameters();

  static const firestoreCollection = 'system_parameters';
  static const firestoreDocumentId = 'ssc';

  final double placeholderLowPh;
  final double placeholderHighPh;
  final double placeholderHighMoisturePercent;
  final double placeholderLowCo2Ppm;
  final double placeholderHighEcDsPerM;
  final double placeholderClayMoisturePercent;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'schema': 'ssc_v1_placeholder',
      'validated': false,
      'placeholderLowPh': placeholderLowPh,
      'placeholderHighPh': placeholderHighPh,
      'placeholderHighMoisturePercent': placeholderHighMoisturePercent,
      'placeholderLowCo2Ppm': placeholderLowCo2Ppm,
      'placeholderHighEcDsPerM': placeholderHighEcDsPerM,
      'placeholderClayMoisturePercent': placeholderClayMoisturePercent,
    };
  }

  factory SscSystemParameters.fromFirestoreMap(Map<String, dynamic> data) {
    return SscSystemParameters(
      placeholderLowPh: (data['placeholderLowPh'] as num?)?.toDouble() ?? 6.0,
      placeholderHighPh: (data['placeholderHighPh'] as num?)?.toDouble() ?? 7.5,
      placeholderHighMoisturePercent:
          (data['placeholderHighMoisturePercent'] as num?)?.toDouble() ?? 70,
      placeholderLowCo2Ppm:
          (data['placeholderLowCo2Ppm'] as num?)?.toDouble() ?? 20,
      placeholderHighEcDsPerM:
          (data['placeholderHighEcDsPerM'] as num?)?.toDouble() ?? 1.5,
      placeholderClayMoisturePercent:
          (data['placeholderClayMoisturePercent'] as num?)?.toDouble() ?? 60,
    );
  }
}
