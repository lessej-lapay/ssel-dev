import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../devices/data/device_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/presentation/widgets/notification_bell_button.dart';
import 'admin_assessments_screen.dart';
import 'admin_notifications_screen.dart';
import 'device_management_screen.dart';
import 'pending_registrations_screen.dart';
import 'ssc_parameters_screen.dart';
import 'user_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    final users = context.read<UserRepository>();
    final devices = context.read<DeviceRepository>();
    final assessments = context.read<AssessmentRepository>();
    final notifications = context.read<NotificationRepository>();

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  children: [
                    // ADMIN HEADER
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        22,
                        12,
                        24,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006B55),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(
                                      alpha: 0.90,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  profile?.displayName ?? 'Administrator',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Manage your SoilSAFE system',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // EXISTING NOTIFICATION CONNECTION
                          NotificationBellButton(
                            tooltip: 'Admin Notifications',
                            unreadStream:
                                notifications.watchAdminUnreadCount(),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AdminNotificationsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION TITLE
                    Text(
                      'System Overview',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF263B32),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // PENDING REGISTRATIONS
                    StreamBuilder<List<AppUser>>(
                      stream: users.watchUsers(
                        status: AccountStatus.pending,
                      ),
                      builder: (context, snapshot) {
                        final count = (snapshot.data ??
                                const <AppUser>[])
                            .where(
                              (user) => user.role == UserRole.farmer,
                            )
                            .length;

                        return _AdminTile(
                          icon: Icons.hourglass_top_rounded,
                          iconColor: const Color(0xFFC47B24),
                          title: 'Pending registrations',
                          subtitle: count == 0
                              ? 'No farmers waiting for approval'
                              : '$count farmer${count == 1 ? '' : 's'} waiting for approval',
                          badgeCount: count,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const PendingRegistrationsScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // FARMER ACCOUNTS
                    StreamBuilder<List<AppUser>>(
                      stream: users.watchUsers(
                        role: UserRole.farmer,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;

                        return _AdminTile(
                          icon: Icons.groups_rounded,
                          iconColor: const Color(0xFF16866D),
                          title: 'Farmer accounts',
                          subtitle:
                              '$count registered farmer${count == 1 ? '' : 's'}',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const UserManagementScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // ESP32 DEVICES
                    StreamBuilder(
                      stream: devices.watchAll(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;

                        return _AdminTile(
                          icon: Icons.memory_rounded,
                          iconColor: const Color(0xFF16866D),
                          title: 'ESP32 devices',
                          subtitle:
                              '$count device${count == 1 ? '' : 's'} on record',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const DeviceManagementScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // SOIL ASSESSMENTS
                    StreamBuilder(
                      stream: assessments.watchAll(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;

                        return _AdminTile(
                          icon: Icons.analytics_rounded,
                          iconColor: const Color(0xFF16866D),
                          title: 'Soil assessments',
                          subtitle: count == 0
                              ? 'No saved assessments yet'
                              : '$count system-wide record${count == 1 ? '' : 's'}',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const AdminAssessmentsScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    // SSC SYSTEM PARAMETERS
                    _AdminTile(
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFF16866D),
                      title: 'SSC system parameters',
                      subtitle:
                          'View and update global placeholder SSC rules',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SscParametersScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 14),

                    // SIGN OUT
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthController>().signOut();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          'Sign out',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF16866D),
                          side: const BorderSide(
                            color: Color(0xFF16866D),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// REUSABLE ADMIN DASHBOARD CARD
class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
    this.iconColor = const Color(0xFF16866D),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF263B32).withValues(
                    alpha: 0.055,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // ICON
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                // TITLE AND DESCRIPTION
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF263B32),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF68736D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // PENDING COUNT
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1DF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB66B16),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(width: 5),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF53635B),
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TIME-BASED GREETING
String _greeting() {
  final hour = DateTime.now().hour;

  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';

  return 'Good evening,';
}