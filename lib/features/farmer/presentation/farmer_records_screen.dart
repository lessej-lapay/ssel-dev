import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../devices/data/device_repository.dart';
import '../../devices/domain/soilsafe_device.dart';

class FarmerRecordsScreen extends StatelessWidget {
  const FarmerRecordsScreen({
    super.key,
    required this.ownerUid,
    this.title = 'My soil assessments',
    this.embedded = false,
  });

  final String ownerUid;
  final String title;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final assessments = context.read<AssessmentRepository>();
    final content = StreamBuilder<List<SoilAssessmentRecord>>(
        stream: assessments.watchForOwner(ownerUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _EmptyMessage(
              title: 'Could not load records',
              message:
                  'Check your connection. Farmers can only view their own assessments.',
            );
          }
          final records = snapshot.data ?? const [];
          if (records.isEmpty) {
            return const _EmptyMessage(
              title: 'No assessments yet',
              message:
                  'Your SSC results and soil readings will appear here after a '
                  'scan is saved to your account.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                child: ListTile(
                  title: Text(
                    record.classificationLabel,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      if (record.farmLocation != null) record.farmLocation,
                      if (record.assessedAt != null)
                        record.assessedAt.toString().split('.').first,
                      if (record.pH != null) 'pH ${record.pH}',
                    ].whereType<String>().join(' · '),
                  ),
                ),
              );
            },
          );
        },
      );

    if (embedded) {
      return ColoredBox(color: SoilSafeColors.cream, child: content);
    }

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: Text(title)),
      body: content,
    );
  }
}

class FarmerDevicesScreen extends StatelessWidget {
  const FarmerDevicesScreen({super.key, required this.farmerId});

  final String farmerId;

  @override
  Widget build(BuildContext context) {
    final devices = context.read<DeviceRepository>();

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: const Text('My SoilSAFE devices')),
      body: StreamBuilder<List<SoilSafeDevice>>(
        stream: devices.watchForFarmer(farmerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _EmptyMessage(
              title: 'Could not load devices',
              message: 'Only devices assigned to your account can be shown here.',
            );
          }
          final list = snapshot.data ?? const [];
          if (list.isEmpty) {
            return const _EmptyMessage(
              title: 'No device assigned',
              message:
                  'An administrator will assign a SoilSAFE ESP32 device to your farm.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final device = list[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.memory),
                  title: Text(device.name),
                  subtitle: Text(
                    device.serialNumber.isEmpty
                        ? 'No serial number'
                        : 'Serial: ${device.serialNumber}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey.shade700, height: 1.45),
          ),
        ],
      ),
    );
  }
}
