import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../auth/domain/auth_failure.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

class FarmerNotificationsScreen extends StatelessWidget {
  const FarmerNotificationsScreen({super.key, required this.farmerUid});

  final String farmerUid;

  Future<void> _markAllRead(
    BuildContext context,
    List<AppNotification> items,
  ) async {
    final readerUid = context.read<AuthController>().user?.uid ?? farmerUid;
    try {
      await context.read<NotificationRepository>().markAllAsRead(
            notifications: items,
            readerUid: readerUid,
          );
    } on AuthFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<NotificationRepository>();

    return StreamBuilder<List<AppNotification>>(
      stream: repo.watchFarmerNotifications(farmerUid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AppNotification>[];
        final hasUnread = items.any((item) => !item.isRead);

        return Scaffold(
          backgroundColor: SoilSafeColors.cream,
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              if (hasUnread)
                TextButton(
                  onPressed: () => _markAllRead(context, items),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load notifications.',
                    style: GoogleFonts.inter(color: Colors.grey.shade700),
                  ),
                );
              }
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 56,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Account updates from the SoilSAFE administrator will appear here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final iconData = switch (item.type) {
                    NotificationType.accountApproved =>
                      Icons.verified_user_outlined,
                    NotificationType.accountRejected => Icons.cancel_outlined,
                    NotificationType.accountBlocked => Icons.block,
                    NotificationType.accountUnblocked =>
                      Icons.lock_open_outlined,
                    _ => Icons.notifications_outlined,
                  };
                  final iconColor = switch (item.type) {
                    NotificationType.accountApproved ||
                    NotificationType.accountUnblocked =>
                      const Color(0xFF1E4D2B),
                    NotificationType.accountRejected ||
                    NotificationType.accountBlocked =>
                      const Color(0xFFB42318),
                    _ => Colors.blueGrey,
                  };

                  return Material(
                    color: item.isRead
                        ? Colors.white
                        : const Color(0xFFF0FAF2),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: item.isRead
                          ? null
                          : () async {
                              try {
                                await repo.markAsRead(
                                  notificationId: item.id,
                                  readerUid: farmerUid,
                                );
                              } on AuthFailure catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.message)),
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isRead
                                ? Colors.grey.shade200
                                : SoilSafeColors.primaryGreen,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  iconColor.withValues(alpha: 0.14),
                              child: Icon(iconData, color: iconColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: item.isRead
                                                ? FontWeight.w600
                                                : FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (!item.isRead)
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD92D20),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.message,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  if (item.createdAt != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormatters.formatDateTime(
                                        item.createdAt!,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
