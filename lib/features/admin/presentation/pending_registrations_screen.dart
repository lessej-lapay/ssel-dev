import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
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
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final farmer = pending[index];
              return Card(
                child: ListTile(
                  title: Text(
                    farmer.displayName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${farmer.email}\n${farmer.municipality}, ${farmer.province}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            FarmerAccountDetailsScreen(farmer: farmer),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
