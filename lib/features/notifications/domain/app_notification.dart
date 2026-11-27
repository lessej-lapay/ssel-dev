import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationTargetRole { admin, farmer }

enum NotificationType {
  newRegistration,
  accountApproved,
  accountRejected,
  accountBlocked,
  accountUnblocked,
  unknown,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.targetRole,
    required this.farmerUid,
    required this.farmerName,
    required this.farmerEmail,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.recipientUid,
    this.rejectionReason,
    this.createdAt,
    this.registrationDate,
    this.readAt,
    this.readBy,
    this.handled = false,
    this.handledStatus,
    this.handledAction,
    this.handledBy,
    this.handledAt,
  });

  final String id;
  final NotificationTargetRole targetRole;
  final String? recipientUid;
  final String farmerUid;
  final String farmerName;
  final String farmerEmail;
  final String title;
  final String message;
  final NotificationType type;
  final String? rejectionReason;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? registrationDate;
  final DateTime? readAt;
  final String? readBy;
  final bool handled;
  final String? handledStatus;
  final String? handledAction;
  final String? handledBy;
  final DateTime? handledAt;

  bool get isHandled =>
      handled || handledStatus != null || handledAt != null;

  DateTime? get displayTimestamp => createdAt ?? registrationDate;

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    final targetRoleRaw =
        (data['targetRole'] as String?)?.trim().toLowerCase() ?? 'farmer';
    final targetRole = targetRoleRaw == 'admin'
        ? NotificationTargetRole.admin
        : NotificationTargetRole.farmer;

    return AppNotification(
      id: (data['id'] as String?)?.trim().isNotEmpty == true
          ? (data['id'] as String).trim()
          : id,
      targetRole: targetRole,
      recipientUid: _optionalString(data['recipientUid']),
      farmerUid: (data['farmerUid'] as String?)?.trim() ?? '',
      farmerName: (data['farmerName'] as String?)?.trim() ?? '',
      farmerEmail: (data['farmerEmail'] as String?)?.trim() ?? '',
      title: (data['title'] as String?)?.trim() ?? 'Notification',
      message: (data['message'] as String?)?.trim() ?? '',
      type: notificationTypeFromString(data['type'] as String?),
      rejectionReason: _optionalString(data['rejectionReason']),
      isRead: data['isRead'] == true,
      createdAt: _toDate(data['createdAt']),
      registrationDate: _toDate(data['registrationDate']),
      readAt: _toDate(data['readAt']),
      readBy: _optionalString(data['readBy']),
      handled: data['handled'] == true,
      handledStatus: _optionalString(data['handledStatus']),
      handledAction: _optionalString(data['handledAction']),
      handledBy: _optionalString(data['handledBy']),
      handledAt: _toDate(data['handledAt']),
    );
  }
}

NotificationType notificationTypeFromString(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'new_registration':
      return NotificationType.newRegistration;
    case 'account_approved':
      return NotificationType.accountApproved;
    case 'account_rejected':
      return NotificationType.accountRejected;
    case 'account_blocked':
      return NotificationType.accountBlocked;
    case 'account_unblocked':
      return NotificationType.accountUnblocked;
    default:
      return NotificationType.unknown;
  }
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

String? _optionalString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
