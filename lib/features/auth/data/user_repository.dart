import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../domain/app_user.dart';
import '../domain/auth_failure.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const collection = 'users';

  bool get isReady => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!isReady) {
      throw const AuthFailure(
        'Firebase is not configured yet. Run FlutterFire configure and add your app to a Firebase project.',
      );
    }
    return _firestore ?? FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(collection);

  Stream<AppUser?> watchUser(String uid) {
    if (!isReady) return Stream<AppUser?>.value(null);
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AppUser.fromMap(snapshot.id, data);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return AppUser.fromMap(snapshot.id, data);
  }

  Future<void> createFarmerProfile(AppUser profile) async {
    try {
      await _users.doc(profile.uid).set(profile.toCreateMap());
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure(
        'Account was created, but the user profile could not be saved.',
      );
    }
  }

  Future<void> updateOwnProfile({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    try {
      await _users.doc(uid).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure('Could not update your profile.');
    }
  }

  Stream<List<AppUser>> watchUsers({
    UserRole? role,
    AccountStatus? status,
  }) {
    if (!isReady) return Stream.value(const <AppUser>[]);
    Query<Map<String, dynamic>> query = _users;
    if (status != null) {
      query = query.where('status', isEqualTo: status.storageValue);
    }
    return query.snapshots().map((snapshot) {
      var users = snapshot.docs
          .map((doc) => AppUser.fromMap(doc.id, doc.data()))
          .toList();
      if (role != null) {
        users = users.where((user) => user.role == role).toList();
      }
      users.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return users;
    });
  }

  Future<void> setAccountStatus({
    required String uid,
    required AccountStatus status,
  }) async {
    try {
      await _users.doc(uid).update({
        'status': status.storageValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure('Could not update account status.');
    }
  }
}
