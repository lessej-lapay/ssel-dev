import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../../core/widgets/confirm_action_dialog.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_failure.dart';
import '../../farmer/presentation/farmer_records_screen.dart';

class FarmerAccountDetailsScreen extends StatelessWidget {
  const FarmerAccountDetailsScreen({super.key, required this.farmer});

  final AppUser farmer;

  Future<void> _setStatus(
    BuildContext context, {
    required AccountStatus status,
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final confirmed = await confirmAction(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await context.read<UserRepository>().setAccountStatus(
            uid: farmer.uid,
            status: status,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account marked as ${status.label}.')),
      );
      Navigator.of(context).pop();
    } on AuthFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: const Text('Farmer account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            farmer.displayName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(farmer.email, style: GoogleFonts.inter(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          Text(
            farmer.status.label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E4D2B),
            ),
          ),
          const SizedBox(height: 20),
          _info('Contact number', farmer.contactNumber),
          _info('Farm / blocks', farmer.farmName.isEmpty ? 'Not provided' : farmer.farmName),
          _info('Farm location', farmer.farmLocation),
          _info('Municipality', farmer.municipality),
          _info('Province', farmer.province),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('View this farmer’s assessments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FarmerRecordsScreen(
                    ownerUid: farmer.uid,
                    title: 'Farmer assessments',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          if (farmer.status == AccountStatus.pending) ...[
            _actionButton(
              label: 'Approve registration',
              onPressed: () => _setStatus(
                context,
                status: AccountStatus.active,
                title: 'Approve this farmer?',
                message:
                    '${farmer.displayName} will be able to use the farmer dashboard.',
                confirmLabel: 'Approve',
              ),
            ),
            const SizedBox(height: 12),
            _actionButton(
              label: 'Reject registration',
              outlined: true,
              onPressed: () => _setStatus(
                context,
                status: AccountStatus.rejected,
                title: 'Reject this registration?',
                message:
                    '${farmer.displayName} will see a rejection screen and cannot use SoilSAFE.',
                confirmLabel: 'Reject',
                destructive: true,
              ),
            ),
          ],
          if (farmer.status == AccountStatus.active) ...[
            _actionButton(
              label: 'Block account',
              outlined: true,
              onPressed: () => _setStatus(
                context,
                status: AccountStatus.blocked,
                title: 'Block this account?',
                message:
                    '${farmer.displayName} will be signed out of farmer features until unblocked.',
                confirmLabel: 'Block',
                destructive: true,
              ),
            ),
          ],
          if (farmer.status == AccountStatus.blocked) ...[
            _actionButton(
              label: 'Unblock account',
              onPressed: () => _setStatus(
                context,
                status: AccountStatus.active,
                title: 'Unblock this account?',
                message: '${farmer.displayName} will regain farmer access.',
                confirmLabel: 'Unblock',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '—' : value,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
