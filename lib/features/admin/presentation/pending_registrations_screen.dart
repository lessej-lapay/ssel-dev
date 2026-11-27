import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import 'farmer_account_details_screen.dart';

class PendingRegistrationsScreen extends StatelessWidget {
  const PendingRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final users = context.read<UserRepository>();

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: const Text('Pending registrations')),
      body: StreamBuilder<List<AppUser>>(
        stream: users.watchUsers(status: AccountStatus.pending),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load pending registrations.'),
            );
          }
          final pending = (snapshot.data ?? const <AppUser>[])
              .where((user) => user.role == UserRole.farmer)
              .toList();
          if (pending.isEmpty) {
            return Center(
              child: Text(
                'There are no pending farmer registrations.',
                style: GoogleFonts.inter(color: Colors.grey.shade700),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final farmer = pending[index];
              return _PendingFarmerCard(
                farmer: farmer,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FarmerAccountDetailsScreen(
                        farmer: farmer,
                        farmerUid: farmer.uid,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PendingFarmerCard extends StatelessWidget {
  const _PendingFarmerCard({required this.farmer, required this.onTap});

  final AppUser farmer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = [farmer.municipality, farmer.province]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmer.displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          farmer.email,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC48A2B).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      farmer.status.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8A5D14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Row(
                icon: Icons.phone_outlined,
                label: farmer.contactNumber.isEmpty ? '—' : farmer.contactNumber,
              ),
              if (farmer.farmName.isNotEmpty)
                _Row(
                  icon: Icons.agriculture_outlined,
                  label: farmer.farmName,
                ),
              _Row(
                icon: Icons.location_on_outlined,
                label: location.isEmpty ? '—' : location,
              ),
              _Row(
                icon: Icons.calendar_today_outlined,
                label: farmer.createdAt != null
                    ? 'Registered ${DateFormatters.formatDateTime(farmer.createdAt!)}'
                    : 'Registration date pending',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Review application',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E4D2B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF1E4D2B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
