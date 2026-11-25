import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import 'auth_controller.dart';

class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              CircleAvatar(
                radius: 42,
                backgroundColor: iconColor.withValues(alpha: 0.15),
                child: Icon(icon, size: 42, color: iconColor),
              ),
              const SizedBox(height: 24),
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
              const Spacer(),
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
      ),
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountStatusScreen(
      icon: Icons.hourglass_top_rounded,
      iconColor: Color(0xFFC48A2B),
      title: 'Waiting for approval',
      message:
          'Your farmer account was created successfully. A SoilSAFE administrator '
          'will review your registration. You can sign in again after your account '
          'is approved.',
    );
  }
}

class RejectedAccountScreen extends StatelessWidget {
  const RejectedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountStatusScreen(
      icon: Icons.cancel_outlined,
      iconColor: Color(0xFFB42318),
      title: 'Registration was not approved',
      message:
          'Your farmer registration was reviewed and not approved. If you believe '
          'this is a mistake, contact a SoilSAFE administrator for help.',
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
      title: 'Account blocked',
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
      title: 'Access denied',
      message:
          'This account does not have permission to use SoilSAFE. Sign out and '
          'contact an administrator if you need help.',
    );
  }
}
