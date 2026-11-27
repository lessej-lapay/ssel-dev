import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/constants/firebase_paths.dart';
import '../../auth/domain/auth_failure.dart';
import '../domain/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const collection = FirebasePaths.notificationsCollection;

  bool get isReady => _firestore != null || Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db {
    if (!isReady) {
      throw const AuthFailure('Firebase is not configured yet.');
    }
    return _firestore ?? FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection(collection);

  /// Streams all persistent admin notifications (both unread and read).
  /// Never filters out read notifications so history remains visible.
  Stream<List<AppNotification>> watchAdminNotifications() {
    if (!isReady) return Stream.value(const <AppNotification>[]);
    return _notifications
        .where('targetRole', isEqualTo: 'admin')
        .snapshots()
        .map(_mapAndSort);
  }

  Stream<int> watchAdminUnreadCount() {
    return watchAdminNotifications().map(
      (list) => list.where((item) => !item.isRead).length,
    );
  }

  Stream<List<AppNotification>> watchFarmerNotifications(String uid) {
    if (!isReady || uid.trim().isEmpty) {
      return Stream.value(const <AppNotification>[]);
    }
    return _notifications
        .where('recipientUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return _mapAndSort(snapshot)
          .where((item) => item.targetRole == NotificationTargetRole.farmer)
          .toList();
    });
  }

  Stream<int> watchFarmerUnreadCount(String uid) {
    return watchFarmerNotifications(uid).map(
      (list) => list.where((item) => !item.isRead).length,
    );
  }

  Future<void> markAsRead({
    required String notificationId,
    required String readerUid,
  }) async {
    try {
      await _notifications.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
        'readBy': readerUid,
      });
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure('Could not mark notification as read.');
    }
  }

  Future<void> markAllAsRead({
    required List<AppNotification> notifications,
    required String readerUid,
  }) async {
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    try {
      const batchLimit = 450;
      for (var i = 0; i < unread.length; i += batchLimit) {
        final batch = _db.batch();
        final chunk = unread.skip(i).take(batchLimit);
        for (final item in chunk) {
          batch.update(_notifications.doc(item.id), {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
            'readBy': readerUid,
          });
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } catch (_) {
      throw const AuthFailure('Could not mark notifications as read.');
    }
  }

  List<AppNotification> _mapAndSort(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final items = snapshot.docs
        .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
        .toList();
    items.sort((a, b) {
      final aTime =
          a.displayTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime =
          b.displayTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return items;
  }
}
