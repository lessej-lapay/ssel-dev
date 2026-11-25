import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';

class AdminAssessmentsScreen extends StatelessWidget {
  const AdminAssessmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assessments = context.read<AssessmentRepository>();
    final users = context.read<UserRepository>();

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: const Text('System assessments')),
      body: StreamBuilder<List<AppUser>>(
        stream: users.watchUsers(role: UserRole.farmer),
        builder: (context, farmerSnapshot) {
          final farmers = {
            for (final farmer in farmerSnapshot.data ?? const <AppUser>[])
              farmer.uid: farmer,
          };
          return StreamBuilder<List<SoilAssessmentRecord>>(
            stream: assessments.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Could not load soil assessments.'),
                );
              }
              final records = snapshot.data ?? const [];
              if (records.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No soil assessments are saved in Firestore yet. '
                      'When scans are stored with an ownerUid, they will appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade700,
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final record = records[index];
                  final farmer = farmers[record.ownerUid];
                  return Card(
                    child: ListTile(
                      title: Text(
                        record.classificationLabel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          farmer?.displayName ?? record.ownerUid,
                          record.farmLocation,
                          if (record.assessedAt != null)
                            record.assessedAt.toString().split('.').first,
                        ].whereType<String>().where((item) => item.isNotEmpty).join(' · '),
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
