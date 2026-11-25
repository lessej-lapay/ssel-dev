import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../auth/domain/auth_failure.dart';
import '../domain/soilsafe_device.dart';

class DeviceRepository {
  DeviceRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const collection = 'devices';

  bool get isReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!isReady) {
      throw const AuthFailure('Firebase is not configured yet.');
    }
    return _firestore ?? FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _devices =>
      _db.collection(collection);

  Stream<List<SoilSafeDevice>> watchAll() {
    if (!isReady) return Stream.value(const <SoilSafeDevice>[]);
    return _devices.snapshots().map(_mapDocs);
  }

  Stream<List<SoilSafeDevice>> watchForFarmer(String farmerId) {
    if (!isReady) return Stream.value(const <SoilSafeDevice>[]);
    return _devices
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map(_mapDocs);
  }

  Future<void> save(SoilSafeDevice device) async {
    try {
      final ref = device.id.isEmpty ? _devices.doc() : _devices.doc(device.id);
      await ref.set(device.toCreateMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure('Could not save device information.');
    }
  }

  Future<void> assignToFarmer({
    required String deviceId,
    String? farmerId,
  }) async {
    try {
      await _devices.doc(deviceId).update({
        'farmerId': farmerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure('Could not update device assignment.');
    }
  }

  List<SoilSafeDevice> _mapDocs(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final devices = snapshot.docs
        .map((doc) => SoilSafeDevice.fromMap(doc.id, doc.data()))
        .toList();
    devices.sort((a, b) => a.name.compareTo(b.name));
    return devices;
  }
}
