import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/firebase_paths.dart';

/// Optional Firebase Cloud Messaging wrapper.
///
/// In-app notifications use Firestore real-time streams and work independently
/// even when push notifications are unavailable or unconfigured (e.g. desktop
/// targets, denied permissions, or web without a VAPID key).
class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging,
        _firestore = firestore;

  final FirebaseMessaging? _messaging;
  final FirebaseFirestore? _firestore;

  StreamSubscription<String>? _tokenRefreshSub;
  String? _activeUid;
  String? _activeToken;
  bool _hasRegisteredToken = false;

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool get isReady => Firebase.apps.isNotEmpty && isSupportedPlatform;

  bool get hasRegisteredToken => _hasRegisteredToken;

  FirebaseMessaging get _fcm => _messaging ?? FirebaseMessaging.instance;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<void> syncForUser(String uid) async {
    if (uid.trim().isEmpty || !isReady) return;
    _activeUid = uid;

    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) {
        _hasRegisteredToken = false;
        return;
      }

      final token = await _fcm.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _saveToken(uid: uid, token: token.trim());
      }

      _tokenRefreshSub ??= _fcm.onTokenRefresh.listen((newToken) {
        final targetUid = _activeUid;
        if (targetUid != null && newToken.trim().isNotEmpty) {
          unawaited(_saveToken(uid: targetUid, token: newToken.trim()));
        }
      });
    } catch (e) {
      _hasRegisteredToken = false;
      debugPrint('FCM sync skipped: $e');
    }
  }

  Future<void> clearForUser(String? uid) async {
    final targetUid = uid ?? _activeUid;
    final token = _activeToken;
    _activeUid = null;
    _activeToken = null;
    _hasRegisteredToken = false;

    if (targetUid == null || targetUid.isEmpty || token == null || !isReady) {
      return;
    }

    try {
      await _db
          .collection(FirebasePaths.usersCollection)
          .doc(targetUid)
          .collection(FirebasePaths.fcmTokensSubcollection)
          .doc(tokenDocumentId(token))
          .delete();
    } catch (e) {
      debugPrint('FCM token cleanup skipped: $e');
    }
  }

  Future<void> _saveToken({required String uid, required String token}) async {
    _activeToken = token;
    final ref = _db
        .collection(FirebasePaths.usersCollection)
        .doc(uid)
        .collection(FirebasePaths.fcmTokensSubcollection)
        .doc(tokenDocumentId(token));

    await ref.set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _hasRegisteredToken = true;
  }

  
static String tokenDocumentId(String token) {
  // Deterministic 64-bit FNV-1a hash using BigInt for Flutter Web compatibility.
  final mask = BigInt.parse('ffffffffffffffff', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);

  var hash = BigInt.parse('cbf29ce484222325', radix: 16);

  for (final unit in token.codeUnits) {
    hash = hash ^ BigInt.from(unit);
    hash = (hash * prime) & mask;
  }

  return 'fcm_${hash.toRadixString(16).padLeft(16, '0')}';
}

  void dispose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
