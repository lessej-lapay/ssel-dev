import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/firebase_auth_service.dart';
import '../data/user_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_failure.dart';
import '../domain/farmer_registration.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    FirebaseAuthService? authService,
    UserRepository? userRepository,
  })  : _authService = authService ?? FirebaseAuthService(),
        _userRepository = userRepository ?? UserRepository() {
    _user = _authService.currentUser;
    _subscription = _authService.authStateChanges().listen(_onAuthChanged);
    if (!_authService.isReady) {
      _ready = true;
      _profileReady = true;
    }
  }

  final FirebaseAuthService _authService;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _subscription;
  StreamSubscription<AppUser?>? _profileSubscription;

  User? _user;
  AppUser? _profile;
  bool _ready = false;
  bool _profileReady = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  AppUser? get profile => _profile;
  bool get isReady => _ready;
  bool get isProfileReady => _profileReady;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _user != null;

  AccessDestination get destination => resolveAccess(
        authReady: _ready,
        profileReady: _profileReady,
        signedIn: isSignedIn,
        profile: _profile,
      );

  Future<bool> signIn({
    required String email,
    required String password,
  }) {
    return _run(() => _authService.signIn(email: email, password: password));
  }

  Future<bool> registerFarmer(FarmerRegistration registration) {
    return _run(() => _authService.registerFarmer(registration));
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _authService.sendPasswordResetEmail(email));
  }

  Future<bool> updateOwnProfile(AppUser updated) {
    return _run(() async {
      final uid = _user?.uid;
      if (uid == null) {
        throw const AuthFailure('You must be signed in to update your profile.');
      }
      await _userRepository.updateOwnProfile(
        uid: uid,
        fields: updated.toProfileUpdateMap(),
      );
    });
  }

  Future<void> signOut() async {
    _error = null;
    try {
      await _authService.signOut();
    } on AuthFailure catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  void _onAuthChanged(User? user) {
    _user = user;
    _ready = true;
    _profileSubscription?.cancel();
    if (user == null) {
      _profile = null;
      _profileReady = true;
      notifyListeners();
      return;
    }
    _profileReady = false;
    notifyListeners();
    _profileSubscription = _userRepository.watchUser(user.uid).listen(
      (profile) {
        _profile = profile;
        _profileReady = true;
        notifyListeners();
      },
      onError: (_) {
        _profile = null;
        _profileReady = true;
        notifyListeners();
      },
    );
  }

  Future<bool> _run(Future<void> Function() action) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthFailure catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
