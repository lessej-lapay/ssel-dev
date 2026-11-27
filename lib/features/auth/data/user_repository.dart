import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/constants/firebase_paths.dart';
import '../domain/app_user.dart';
import '../domain/auth_failure.dart';

typedef AccountStatusCallable = Future<void> Function({
  required String farmerUid,
  required AccountModerationAction action,
  String? reason,
});

class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    AccountStatusCallable? accountStatusCallable,
  })  : _firestore = firestore,
        _functions = functions,
        _auth = auth,
        _accountStatusCallable = accountStatusCallable;

  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;
  final FirebaseAuth? _auth;
  final AccountStatusCallable? _accountStatusCallable;

  static const collection = FirebasePaths.usersCollection;

  bool get isReady => _firestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!isReady) {
      throw const AuthFailure(
        'Firebase is not configured yet. Run FlutterFire configure and add your app to a Firebase project.',
      );
    }
    return _firestore ?? FirebaseFirestore.instance;
  }

  FirebaseFunctions get _fn {
    if (Firebase.apps.isEmpty && _functions == null) {
      throw const AuthFailure(
        'Firebase is not configured yet. Run FlutterFire configure and add your app to a Firebase project.',
      );
    }
    return _functions ??
        FirebaseFunctions.instanceFor(region: FirebasePaths.functionsRegion);
  }

  FirebaseAuth? get _authInstance {
    if (_auth != null) return _auth;
    if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    return null;
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
      final enforcedFarmer = AppUser(
        uid: profile.uid,
        fullName: profile.fullName,
        email: profile.email,
        contactNumber: profile.contactNumber,
        farmName: profile.farmName,
        farmLocation: profile.farmLocation,
        municipality: profile.municipality,
        province: profile.province,
        role: UserRole.farmer,
        status: AccountStatus.pending,
      );
      await _users.doc(enforcedFarmer.uid).set(enforcedFarmer.toCreateMap());
      await _ensureAdminRegistrationNotification(enforcedFarmer);
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure(
        'Account was created, but the user profile could not be saved.',
      );
    }
  }

 
Future<void> _ensureAdminRegistrationNotification(AppUser farmer) async {
  final notifId = 'new_registration_${farmer.uid}';
  final displayName = farmer.displayName;

  try {
    await _db
        .collection(FirebasePaths.notificationsCollection)
        .doc(notifId)
        .set({
      'id': notifId,
      'targetRole': 'admin',
      'recipientUid': null,
      'farmerUid': farmer.uid,
      'farmerName': displayName,
      'farmerEmail': farmer.email,
      'title': 'New Farmer Registration',
      'message':
          '$displayName has submitted a registration request and is waiting for account approval.',
      'type': 'new_registration',
      'isRead': false,
      'readAt': null,
      'readBy': null,
      'handled': false,
      'handledStatus': null,
      'handledAction': null,
      'handledBy': null,
      'handledAt': null,
      'registrationDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  } on FirebaseException catch (e) {
    print('NOTIFICATION CREATION FAILED');
    print('Error code: ${e.code}');
    print('Error message: ${e.message}');
    rethrow;
  }
}


  Future<void> updateOwnProfile({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final safeFields = Map<String, dynamic>.from(fields)
        ..remove('role')
        ..remove('status')
        ..remove('uid')
        ..remove('email')
        ..remove('createdAt')
        ..remove('approvedBy')
        ..remove('approvedByName')
        ..remove('approvedAt')
        ..remove('rejectedBy')
        ..remove('rejectedByName')
        ..remove('rejectedAt')
        ..remove('rejectionReason')
        ..remove('blockedBy')
        ..remove('blockedByName')
        ..remove('blockedAt')
        ..remove('unblockedBy')
        ..remove('unblockedByName')
        ..remove('unblockedAt');

      await _users.doc(uid).update({
        ...safeFields,
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

  /// Performs privileged account moderation via the trusted Cloud Function,
  /// with a Firestore-rules-enforced admin fallback when functions are not yet
  /// deployed to the Firebase project.
  Future<void> reviewFarmerAccount({
    required String uid,
    required AccountModerationAction action,
    String? reason,
  }) async {
    try {
      if (_accountStatusCallable != null) {
        await _accountStatusCallable(
          farmerUid: uid,
          action: action,
          reason: reason?.trim(),
        );
        return;
      }

      final callable = _fn.httpsCallable(
        FirebasePaths.updateFarmerAccountStatusFunction,
      );
      await callable.call<Map<String, dynamic>>({
        'farmerUid': uid,
        'action': action.storageValue,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
    } on FirebaseFunctionsException catch (e) {
      if (_shouldFallbackToFirestore(e)) {
        await _reviewFarmerAccountViaFirestore(
          uid: uid,
          action: action,
          reason: reason,
        );
        return;
      }

      final message = e.message?.trim();
      if (message != null &&
          message.isNotEmpty &&
          (e.code == 'failed-precondition' ||
              e.code == 'invalid-argument' ||
              e.code == 'permission-denied' ||
              e.code == 'not-found' ||
              e.code == 'unauthenticated')) {
        throw AuthFailure(message);
      }
      throw AuthFailure.fromCode(e.code);
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Could not update account status.');
    }
  }

  bool _shouldFallbackToFirestore(FirebaseFunctionsException e) {
    if (e.code == 'unimplemented' || e.code == 'unavailable') {
      return true;
    }
    if (e.code == 'not-found') {
      return e.message?.trim() != 'Farmer account not found.';
    }
    if (e.code == 'internal') {
      final msg = e.message?.trim().toLowerCase() ?? '';
      return msg.isEmpty ||
          msg == 'internal' ||
          msg.contains('cors') ||
          msg.contains('not found');
    }
    return false;
  }

  Future<void> _reviewFarmerAccountViaFirestore({
    required String uid,
    required AccountModerationAction action,
    String? reason,
  }) async {
    final currentUser = _authInstance?.currentUser;
    if (currentUser == null) {
      throw AuthFailure.fromCode('unauthenticated');
    }
    if (currentUser.uid == uid) {
      throw const AuthFailure(
        'Administrators cannot modify their own approval status.',
      );
    }

    try {
      final targetSnap = await _users.doc(uid).get();
      final targetData = targetSnap.data();
      if (!targetSnap.exists || targetData == null) {
        throw const AuthFailure('Farmer account not found.');
      }

      final farmer = AppUser.fromMap(targetSnap.id, targetData);
      if (farmer.isAdmin) {
        throw const AuthFailure(
          'Administrator accounts cannot be modified through farmer approval.',
        );
      }

      final transition = _resolveTransition(
        currentStatus: farmer.status,
        action: action,
        reason: reason,
      );

      final adminProfile = await getUser(currentUser.uid);
      final adminName = adminProfile?.displayName ??
          currentUser.displayName ??
          currentUser.email ??
          'Administrator';

      final batch = _db.batch();
      final userUpdates = <String, dynamic>{
        'status': transition.nextStatus.storageValue,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (action) {
        case AccountModerationAction.approve:
          userUpdates['approvedBy'] = currentUser.uid;
          userUpdates['approvedByName'] = adminName;
          userUpdates['approvedAt'] = FieldValue.serverTimestamp();
          userUpdates['rejectionReason'] = null;
        case AccountModerationAction.reject:
          userUpdates['rejectedBy'] = currentUser.uid;
          userUpdates['rejectedByName'] = adminName;
          userUpdates['rejectedAt'] = FieldValue.serverTimestamp();
          userUpdates['rejectionReason'] = transition.rejectionReason;
        case AccountModerationAction.block:
          userUpdates['blockedBy'] = currentUser.uid;
          userUpdates['blockedByName'] = adminName;
          userUpdates['blockedAt'] = FieldValue.serverTimestamp();
        case AccountModerationAction.unblock:
          userUpdates['unblockedBy'] = currentUser.uid;
          userUpdates['unblockedByName'] = adminName;
          userUpdates['unblockedAt'] = FieldValue.serverTimestamp();
      }

      batch.update(_users.doc(uid), userUpdates);

      final notificationsCol =
          _db.collection(FirebasePaths.notificationsCollection);
      if (action == AccountModerationAction.approve ||
          action == AccountModerationAction.reject) {
        final adminNotifRef = notificationsCol.doc('new_registration_$uid');
        final adminNotifSnap = await adminNotifRef.get();
        if (adminNotifSnap.exists) {
          final existing = adminNotifSnap.data() ?? const <String, dynamic>{};
          batch.update(adminNotifRef, {
            'isRead': true,
            if (existing['readAt'] == null)
              'readAt': FieldValue.serverTimestamp(),
            if (existing['readBy'] == null) 'readBy': currentUser.uid,
            'handled': true,
            'handledStatus': transition.nextStatus.storageValue,
            'handledAction': action.storageValue,
            'handledBy': currentUser.uid,
            'handledAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final farmerNotifRef = notificationsCol.doc();
      batch.set(farmerNotifRef, {
        'id': farmerNotifRef.id,
        'targetRole': 'farmer',
        'recipientUid': uid,
        'farmerUid': uid,
        'farmerName': farmer.displayName,
        'title': transition.title,
        'message': transition.message,
        'type': transition.notificationType,
        'rejectionReason': transition.rejectionReason,
        'isRead': false,
        'readAt': null,
        'readBy': null,
        'actorUid': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
   } on FirebaseFunctionsException catch (e) {
  print('=== CLOUD FUNCTION ERROR ===');
  print('Code: ${e.code}');
  print('Message: ${e.message}');
  print('Action: ${action.storageValue}');
  print('Farmer UID: $uid');

  if (_shouldFallbackToFirestore(e)) {
    print('FALLING BACK TO FIRESTORE');

    await _reviewFarmerAccountViaFirestore(
      uid: uid,
      action: action,
      reason: reason,
    );
    return;
  }

  final message = e.message?.trim();
  if (message != null &&
      message.isNotEmpty &&
      (e.code == 'failed-precondition' ||
          e.code == 'invalid-argument' ||
          e.code == 'permission-denied' ||
          e.code == 'not-found' ||
          e.code == 'unauthenticated')) {
    throw AuthFailure(message);
  }
  throw AuthFailure.fromCode(e.code);
    }
  }

  ({
    AccountStatus nextStatus,
    String notificationType,
    String title,
    String message,
    String? rejectionReason,
  }) _resolveTransition({
    required AccountStatus currentStatus,
    required AccountModerationAction action,
    String? reason,
  }) {
    final cleanReason = reason?.trim() ?? '';
    switch (action) {
      case AccountModerationAction.approve:
        if (currentStatus == AccountStatus.active) {
          throw const AuthFailure('This farmer account is already approved.');
        }
        if (currentStatus != AccountStatus.pending) {
          throw const AuthFailure(
            'Only pending farmer accounts can be approved.',
          );
        }
        return (
          nextStatus: AccountStatus.active,
          notificationType: 'account_approved',
          title: 'SoilSAFE Account Approved',
          message:
              'Your account has been approved. You can now access your SoilSAFE dashboard.',
          rejectionReason: null,
        );

      case AccountModerationAction.reject:
        if (currentStatus == AccountStatus.rejected) {
          throw const AuthFailure('This farmer account is already rejected.');
        }
        if (currentStatus != AccountStatus.pending) {
          throw const AuthFailure(
            'Only pending farmer accounts can be rejected.',
          );
        }
        return (
          nextStatus: AccountStatus.rejected,
          notificationType: 'account_rejected',
          title: 'SoilSAFE Account Not Approved',
          message: cleanReason.isNotEmpty
              ? 'Your registration was not approved. Reason: $cleanReason'
              : 'Your registration was not approved. Please contact a SoilSAFE administrator for assistance.',
          rejectionReason: cleanReason.isEmpty ? null : cleanReason,
        );

      case AccountModerationAction.block:
        if (currentStatus == AccountStatus.blocked) {
          throw const AuthFailure('This farmer account is already blocked.');
        }
        if (currentStatus != AccountStatus.active) {
          throw const AuthFailure(
            'Only active farmer accounts can be blocked.',
          );
        }
        return (
          nextStatus: AccountStatus.blocked,
          notificationType: 'account_blocked',
          title: 'SoilSAFE Account Blocked',
          message:
              'Your account has been blocked by an administrator. Please contact support for assistance.',
          rejectionReason: null,
        );

      case AccountModerationAction.unblock:
        if (currentStatus == AccountStatus.active) {
          throw const AuthFailure('This farmer account is already active.');
        }
        if (currentStatus != AccountStatus.blocked) {
          throw const AuthFailure(
            'Only blocked farmer accounts can be unblocked.',
          );
        }
        return (
          nextStatus: AccountStatus.active,
          notificationType: 'account_unblocked',
          title: 'SoilSAFE Account Restored',
          message:
              'Your account access has been restored. You can now use your SoilSAFE dashboard.',
          rejectionReason: null,
        );
    }
  }
}
