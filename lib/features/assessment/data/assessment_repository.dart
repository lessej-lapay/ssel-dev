import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../assessment/domain/ssc_system_parameters.dart';
import '../../auth/domain/auth_failure.dart';

class SoilAssessmentRecord {
  const SoilAssessmentRecord({
    required this.id,
    required this.ownerUid,
    required this.classificationLabel,
    this.farmLocation,
    this.assessedAt,
    this.pH,
    this.moisture,
    this.temperature,
    this.ec,
    this.co2,
  });

  final String id;
  final String ownerUid;
  final String classificationLabel;
  final String? farmLocation;
  final DateTime? assessedAt;
  final double? pH;
  final double? moisture;
  final double? temperature;
  final double? ec;
  final double? co2;

  factory SoilAssessmentRecord.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return SoilAssessmentRecord(
      id: id,
      ownerUid: (data['ownerUid'] as String?) ?? '',
      classificationLabel:
          (data['classificationLabel'] as String?) ??
          (data['ssc'] as String?) ??
          'Unclassified',
      farmLocation: data['farmLocation'] as String?,
      assessedAt: _toDate(data['assessedAt'] ?? data['createdAt']),
      pH: (data['pH'] as num?)?.toDouble(),
      moisture: (data['moisture'] as num?)?.toDouble(),
      temperature: (data['temperature'] as num?)?.toDouble(),
      ec: (data['ec'] as num?)?.toDouble(),
      co2: (data['co2'] as num?)?.toDouble(),
    );
  }
}

class AssessmentRepository {
  AssessmentRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const collection = 'assessments';

  bool get isReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!isReady) {
      throw const AuthFailure('Firebase is not configured yet.');
    }
    return _firestore ?? FirebaseFirestore.instance;
  }

  Stream<List<SoilAssessmentRecord>> watchForOwner(String ownerUid) {
    if (!isReady) return Stream.value(const <SoilAssessmentRecord>[]);
    return _db
        .collection(collection)
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map(_mapDocs);
  }

  Stream<List<SoilAssessmentRecord>> watchAll() {
    if (!isReady) return Stream.value(const <SoilAssessmentRecord>[]);
    return _db.collection(collection).snapshots().map(_mapDocs);
  }

  Stream<SscSystemParameters> watchSscParameters() {
    if (!isReady) {
      return Stream.value(SscSystemParameters.current);
    }
    return _db
        .collection(SscSystemParameters.firestoreCollection)
        .doc(SscSystemParameters.firestoreDocumentId)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) {
            return SscSystemParameters.current;
          }
          return SscSystemParameters.fromFirestoreMap(data);
        });
  }

  Future<void> saveSscParameters(SscSystemParameters parameters) async {
    try {
      await _db
          .collection(SscSystemParameters.firestoreCollection)
          .doc(SscSystemParameters.firestoreDocumentId)
          .set({
            ...parameters.toFirestoreMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure('Could not save SSC system parameters.');
    }
  }

  List<SoilAssessmentRecord> _mapDocs(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final records = snapshot.docs
        .map((doc) => SoilAssessmentRecord.fromMap(doc.id, doc.data()))
        .toList();
    records.sort((a, b) {
      final aTime = a.assessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.assessedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return records;
  }
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
