import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/confirm_action_dialog.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_failure.dart';
import '../../farmer/presentation/farmer_records_screen.dart';

class FarmerAccountDetailsScreen extends StatefulWidget {
  const FarmerAccountDetailsScreen({
    super.key,
    this.farmer,
    this.farmerUid,
  }) : assert(farmer != null || farmerUid != null);

  final AppUser? farmer;
  final String? farmerUid;

  String get effectiveUid => farmerUid ?? farmer!.uid;

  @override
  State<FarmerAccountDetailsScreen> createState() =>
      _FarmerAccountDetailsScreenState();
}

class _FarmerAccountDetailsScreenState
    extends State<FarmerAccountDetailsScreen> {
  bool _submitting = false;

  Future<void> _moderate({
    required AppUser farmer,
    required AccountModerationAction action,
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
    String? reason,
  }) async {
    final confirmed = await confirmAction(
      context: context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (!confirmed || !mounted) return;

    await _executeModeration(
      farmer: farmer,
      action: action,
      reason: reason,
    );
  }

  Future<void> _rejectWithReason(AppUser farmer) async {
    final result = await showDialog<({bool confirmed, String reason})>(
      context: context,
      builder: (_) => _RejectAccountDialog(farmerName: farmer.displayName),
    );

    if (result == null || !result.confirmed || !mounted) return;

    await _executeModeration(
      farmer: farmer,
      action: AccountModerationAction.reject,
      reason: result.reason.isEmpty ? null : result.reason,
    );
  }

  Future<void> _executeModeration({
    required AppUser farmer,
    required AccountModerationAction action,
    String? reason,
  }) async {
    setState(() => _submitting = true);
    try {
      await context.read<UserRepository>().reviewFarmerAccount(
            uid: farmer.uid,
            action: action,
            reason: reason,
          );
      if (!mounted) return;
      final successText = switch (action) {
        AccountModerationAction.approve =>
          'Account approved. Farmer has been notified.',
        AccountModerationAction.reject =>
          'Account rejected. Farmer has been notified.',
        AccountModerationAction.block => 'Account blocked.',
        AccountModerationAction.unblock => 'Account unblocked.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successText)),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.read<UserRepository>();

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: const Text('Farmer account')),
      body: StreamBuilder<AppUser?>(
        initialData: widget.farmer,
        stream: users.watchUser(widget.effectiveUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load farmer account details.'),
            );
          }
          final farmer = snapshot.data;
          if (farmer == null) {
            return const Center(
              child: Text('Farmer account was not found.'),
            );
          }

          return ListView(
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
              Text(
                farmer.email,
                style: GoogleFonts.inter(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(status: farmer.status),
              ),
              const SizedBox(height: 20),
              _info('Contact number', farmer.contactNumber),
              _info(
                'Farm / plantation name',
                farmer.farmName.isEmpty ? 'Not provided' : farmer.farmName,
              ),
              _info('Farm location', farmer.farmLocation),
              _info('Municipality', farmer.municipality),
              _info('Province', farmer.province),
              _info(
                'Registration date',
                farmer.createdAt != null
                    ? DateFormatters.formatDateTime(farmer.createdAt!)
                    : '—',
              ),
              if (farmer.approvedAt != null)
                _info(
                  'Approved',
                  '${DateFormatters.formatDateTime(farmer.approvedAt!)}'
                      '${farmer.approvedByName != null ? ' by ${farmer.approvedByName}' : ''}',
                ),
              if (farmer.rejectedAt != null)
                _info(
                  'Rejected',
                  '${DateFormatters.formatDateTime(farmer.rejectedAt!)}'
                      '${farmer.rejectedByName != null ? ' by ${farmer.rejectedByName}' : ''}',
                ),
              if (farmer.rejectionReason != null)
                _info('Rejection reason', farmer.rejectionReason!),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: const Text('View this farmer’s assessments'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _submitting
                    ? null
                    : () {
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
                  loading: _submitting,
                  onPressed: _submitting
                      ? null
                      : () => _moderate(
                            farmer: farmer,
                            action: AccountModerationAction.approve,
                            title: 'Approve this farmer?',
                            message:
                                '${farmer.displayName} will gain access to the farmer dashboard.',
                            confirmLabel: 'Approve',
                          ),
                ),
                const SizedBox(height: 12),
                _actionButton(
                  label: 'Reject registration',
                  outlined: true,
                  loading: _submitting,
                  onPressed:
                      _submitting ? null : () => _rejectWithReason(farmer),
                ),
              ],
              if (farmer.status == AccountStatus.active) ...[
                _actionButton(
                  label: 'Block account',
                  outlined: true,
                  loading: _submitting,
                  onPressed: _submitting
                      ? null
                      : () => _moderate(
                            farmer: farmer,
                            action: AccountModerationAction.block,
                            title: 'Block this account?',
                            message:
                                '${farmer.displayName} will be blocked from farmer features until unblocked.',
                            confirmLabel: 'Block',
                            destructive: true,
                          ),
                ),
              ],
              if (farmer.status == AccountStatus.blocked) ...[
                _actionButton(
                  label: 'Unblock account',
                  loading: _submitting,
                  onPressed: _submitting
                      ? null
                      : () => _moderate(
                            farmer: farmer,
                            action: AccountModerationAction.unblock,
                            title: 'Unblock this account?',
                            message:
                                '${farmer.displayName} will regain farmer access.',
                            confirmLabel: 'Unblock',
                          ),
                ),
              ],
            ],
          );
        },
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
    required VoidCallback? onPressed,
    bool outlined = false,
    bool loading = false,
  }) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(onPressed: onPressed, child: child)
          : ElevatedButton(onPressed: onPressed, child: child),
    );
  }
}

class _RejectAccountDialog extends StatefulWidget {
  const _RejectAccountDialog({required this.farmerName});

  final String farmerName;

  @override
  State<_RejectAccountDialog> createState() => _RejectAccountDialogState();
}

class _RejectAccountDialogState extends State<_RejectAccountDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reject this registration?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.farmerName} will see the rejected account screen and '
                'will not be deleted. You may provide a reason below.',
                style: GoogleFonts.inter(height: 1.4, fontSize: 14),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason (optional)',
                  hintText: 'e.g., Incomplete farm location details',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop((confirmed: false, reason: '')),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop((
            confirmed: true,
            reason: _reasonController.text.trim(),
          )),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red.shade700,
          ),
          child: const Text('Reject account'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      AccountStatus.pending => (
          const Color(0xFFC48A2B).withValues(alpha: 0.15),
          const Color(0xFF8A5D14),
        ),
      AccountStatus.active => (
          SoilSafeColors.primaryGreen.withValues(alpha: 0.2),
          const Color(0xFF1E4D2B),
        ),
      AccountStatus.rejected || AccountStatus.blocked => (
          const Color(0xFFFEF3F2),
          const Color(0xFFB42318),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
