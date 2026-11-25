import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../devices/data/device_repository.dart';
import 'admin_assessments_screen.dart';
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

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Admin dashboard',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E4D2B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile?.displayName ?? 'Administrator',
              style: GoogleFonts.inter(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<AppUser>>(
              stream: users.watchUsers(status: AccountStatus.pending),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _AdminTile(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Pending registrations',
                  subtitle: count == 0
                      ? 'No farmers waiting for approval'
                      : '$count farmer${count == 1 ? '' : 's'} waiting for approval',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PendingRegistrationsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<List<AppUser>>(
              stream: users.watchUsers(role: UserRole.farmer),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _AdminTile(
                  icon: Icons.groups_outlined,
                  title: 'Farmer accounts',
                  subtitle: '$count registered farmer${count == 1 ? '' : 's'}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder(
              stream: devices.watchAll(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _AdminTile(
                  icon: Icons.memory_outlined,
                  title: 'ESP32 devices',
                  subtitle: '$count device${count == 1 ? '' : 's'} on record',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DeviceManagementScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder(
              stream: assessments.watchAll(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _AdminTile(
                  icon: Icons.analytics_outlined,
                  title: 'Soil assessments',
                  subtitle: count == 0
                      ? 'No saved assessments yet'
                      : '$count system-wide record${count == 1 ? '' : 's'}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminAssessmentsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            _AdminTile(
              icon: Icons.tune,
              title: 'SSC system parameters',
              subtitle: 'View and update global placeholder SSC rules',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SscParametersScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthController>().signOut(),
                icon: const Icon(Icons.logout),
                label: Text(
                  'Sign out',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: SoilSafeColors.primaryGreen.withValues(alpha: 0.2),
          child: Icon(icon, color: const Color(0xFF1E4D2B)),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
