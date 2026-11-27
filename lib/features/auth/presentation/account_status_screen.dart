import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../notifications/presentation/farmer_notifications_screen.dart';
import '../domain/app_user.dart';
import 'auth_controller.dart';

class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.statusLabel,
    this.statusDetails,
    this.extraContent,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? statusLabel;
  final Widget? statusDetails;
  final Widget? extraContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: iconColor.withValues(alpha: 0.15),
                        child: Icon(icon, size: 42, color: iconColor),
                      ),
                      if (statusLabel != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: iconColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            statusLabel!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E4D2B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (statusDetails != null) ...[
                        const SizedBox(height: 24),
                        statusDetails!,
                      ],
                      if (extraContent != null) ...[
                        const SizedBox(height: 16),
                        extraContent!,
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AuthController>().signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(
                    'Log out',
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
      ),
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key, this.profileOverride});

  final AppUser? profileOverride;

  @override
  Widget build(BuildContext context) {
    final profile =
        profileOverride ?? context.select<AuthController, AppUser?>((c) => c.profile);

    return AccountStatusScreen(
      icon: Icons.hourglass_top_rounded,
      iconColor: const Color(0xFFC48A2B),
      statusLabel: 'PENDING APPROVAL',
      title: 'Your Account is Waiting for Approval',
      message:
          'Your farmer account is currently being reviewed by the SoilSAFE '
          'administrator. You will automatically be redirected to your Farmer '
          'Dashboard once your account is approved.',
      statusDetails: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7DFC8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC48A2B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Listening for account approval updates...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8A5D14),
                    ),
                  ),
                ),
              ],
            ),
            if (profile != null) ...[
              const Divider(height: 24),
              _DetailRow(label: 'Farmer', value: profile.displayName),
              _DetailRow(label: 'Email', value: profile.email),
              if (profile.municipality.isNotEmpty ||
                  profile.province.isNotEmpty)
                _DetailRow(
                  label: 'Location',
                  value: [profile.municipality, profile.province]
                      .where((s) => s.isNotEmpty)
                      .join(', '),
                ),
              if (profile.createdAt != null)
                _DetailRow(
                  label: 'Submitted',
                  value: DateFormatters.formatDateTime(profile.createdAt!),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class RejectedAccountScreen extends StatelessWidget {
  const RejectedAccountScreen({super.key, this.profileOverride});

  final AppUser? profileOverride;

  @override
  Widget build(BuildContext context) {
    final profile =
        profileOverride ?? context.select<AuthController, AppUser?>((c) => c.profile);
    final reason = profile?.rejectionReason?.trim();

    return AccountStatusScreen(
      icon: Icons.cancel_outlined,
      iconColor: const Color(0xFFB42318),
      statusLabel: 'REJECTED',
      title: 'Registration Was Not Approved',
      message:
          'Your farmer registration was reviewed by the SoilSAFE administrator '
          'and was not approved. Please review the details below or contact an '
          'administrator for assistance.',
      statusDetails: reason != null && reason.isNotEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECDCA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason for Rejection',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB42318),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reason,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: const Color(0xFF7A271A),
                    ),
                  ),
                ],
              ),
            )
          : null,
      extraContent: profile == null
          ? null
          : TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        FarmerNotificationsScreen(farmerUid: profile.uid),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('View Account Notifications'),
            ),
    );
  }
}

class BlockedAccountScreen extends StatelessWidget {
  const BlockedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountStatusScreen(
      icon: Icons.block,
      iconColor: Color(0xFFB42318),
      statusLabel: 'BLOCKED',
      title: 'Account Blocked',
      message:
          'This account cannot use SoilSAFE right now. Please contact an '
          'administrator if you need access restored.',
    );
  }
}

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountStatusScreen(
      icon: Icons.lock_outline,
      iconColor: Color(0xFF475467),
      statusLabel: 'ACCESS DENIED',
      title: 'Access Denied',
      message:
          'This account does not have permission to use SoilSAFE. Log out and '
          'contact an administrator if you need help.',
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
