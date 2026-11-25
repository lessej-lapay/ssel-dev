import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/farmer_registration.dart';
import 'user_repository.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    UserRepository? userRepository,
  })  : _auth = auth,
        _firestore = firestore,
        _userRepository = userRepository;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final UserRepository? _userRepository;

  bool get isReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get _authInstance {
    _ensureReady();
    return _auth ?? FirebaseAuth.instance;
  }

  UserRepository get _users {
    return _userRepository ?? UserRepository(firestore: _firestore);
  }

  Stream<User?> authStateChanges() {
    if (!isReady) return Stream<User?>.value(null);
    return _authInstance.authStateChanges();
  }

  User? get currentUser => isReady ? _authInstance.currentUser : null;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authInstance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Something went wrong. Please try again');
    }
  }

  Future<void> registerFarmer(FarmerRegistration registration) async {
    UserCredential? credential;
    try {
      credential = await _authInstance.createUserWithEmailAndPassword(
        email: registration.email.trim(),
        password: registration.password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Account creation failed.');
      }

      await user.updateDisplayName(registration.fullName.trim());

      final profile = AppUser(
        uid: user.uid,
        fullName: registration.fullName.trim(),
        email: user.email ?? registration.email.trim(),
        contactNumber: registration.contactNumber.trim(),
        farmName: registration.farmName.trim(),
        farmLocation: registration.farmLocation.trim(),
        municipality: registration.municipality.trim(),
        province: registration.province.trim(),
        role: UserRole.farmer,
        status: AccountStatus.pending,
      );

      await _users.createFarmerProfile(profile);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } on AuthFailure {
      await _rollbackAuthUser(credential?.user);
      rethrow;
    } catch (_) {
      await _rollbackAuthUser(credential?.user);
      throw const AuthFailure(
        'Account was created, but the user profile could not be saved.',
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authInstance.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Something went wrong. Please try again');
    }
  }

  Future<void> signOut() async {
    _ensureReady();
    await _authInstance.signOut();
  }

  Future<void> _rollbackAuthUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {}
  }

  void _ensureReady() {
    if (!isReady) {
      throw const AuthFailure(
        'Firebase is not configured yet. Run FlutterFire configure and add your app to a Firebase project.',
      );
    }
  }
}
