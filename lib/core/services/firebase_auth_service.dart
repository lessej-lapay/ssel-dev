import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/domain/auth_failure.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  bool get isReady => true;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure(
        'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw const AuthFailure(
          'Account creation failed.',
        );
      }

      // Create the user's profile in Firestore.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'role': 'regular',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Account was created, but the user profile could not be saved.',
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure(
        'Could not send password reset email.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure(
        'Could not sign out.',
      );
    }
  }
}