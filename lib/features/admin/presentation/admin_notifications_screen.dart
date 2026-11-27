import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../auth/domain/auth_failure.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/domain/app_notification.dart';
import 'farmer_account_details_screen.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  Future<void> _markAllRead(
    BuildContext context,
    List<AppNotification> items,
  ) async {
    final readerUid = context.read<AuthController>().user?.uid;
    if (readerUid == null) return;
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

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    final readerUid = context.read<AuthController>().user?.uid;
    if (!notification.isRead && readerUid != null) {
      try {
        await context.read<NotificationRepository>().markAsRead(
              notificationId: notification.id,
              readerUid: readerUid,
            );
      } catch (_) {
        // Still allow navigating to review the farmer application.
      }
    }

    if (!context.mounted || notification.farmerUid.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FarmerAccountDetailsScreen(farmerUid: notification.farmerUid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<NotificationRepository>();
    final readerUid = context.watch<AuthController>().user?.uid;

    return StreamBuilder<List<AppNotification>>(
      stream: repo.watchAdminNotifications(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <AppNotification>[];
        final hasUnread = items.any((item) => !item.isRead);

        return Scaffold(
          backgroundColor: SoilSafeColors.cream,
          appBar: AppBar(
            title: const Text('Admin Notifications'),
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load notifications.',
                        style: GoogleFonts.inter(color: Colors.grey.shade700),
                      ),
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
                            'New farmer registrations awaiting review will appear here automatically.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade700,
                            ),
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
                    final date = item.registrationDate ?? item.createdAt;
                    return Material(
                      color: item.isRead
                          ? Colors.white
                          : const Color(0xFFF0FAF2),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _openNotification(context, item),
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
                                backgroundColor: item.isRead
                                    ? Colors.grey.shade200
                                    : SoilSafeColors.primaryGreen
                                        .withValues(alpha: 0.2),
                                child: Icon(
                                  Icons.person_add_alt_1_outlined,
                                  color: item.isRead
                                      ? Colors.grey.shade700
                                      : const Color(0xFF1E4D2B),
                                ),
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
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        if (item.farmerName.isNotEmpty)
                                          Text(
                                            'Farmer: ${item.farmerName}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E4D2B),
                                            ),
                                          ),
                                        if (date != null)
                                          Text(
                                            'Registered: ${DateFormatters.formatDateTime(date)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (!item.isRead && readerUid != null) ...[
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            minimumSize: const Size(0, 32),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () async {
                                            try {
                                              await repo.markAsRead(
                                                notificationId: item.id,
                                                readerUid: readerUid,
                                              );
                                            } on AuthFailure catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(e.message),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('Mark as read'),
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
