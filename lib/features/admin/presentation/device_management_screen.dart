import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_failure.dart';
import '../../auth/presentation/widgets/auth_chrome.dart';
import '../../devices/data/device_repository.dart';
import '../../devices/domain/soilsafe_device.dart';

class DeviceManagementScreen extends StatelessWidget {
  const DeviceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = context.read<DeviceRepository>();
    final users = context.read<UserRepository>();

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: const Text('ESP32 devices')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDevice(context),
        icon: const Icon(Icons.add),
        label: const Text('Add device'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: users.watchUsers(role: UserRole.farmer),
        builder: (context, farmerSnapshot) {
          final farmers = farmerSnapshot.data ?? const <AppUser>[];
          return StreamBuilder<List<SoilSafeDevice>>(
            stream: devices.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Could not load devices.'));
              }
              final list = snapshot.data ?? const [];
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'No devices yet. Add an ESP32 and assign it to a farmer.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.grey.shade700),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final device = list[index];
                  AppUser? farmer;
                  for (final item in farmers) {
                    if (item.uid == device.farmerId) {
                      farmer = item;
                      break;
                    }
                  }
                  return Card(
                    child: ListTile(
                      title: Text(
                        device.name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if (device.serialNumber.isNotEmpty)
                            'Serial: ${device.serialNumber}',
                          farmer == null
                              ? 'Unassigned'
                              : 'Assigned to ${farmer.displayName}',
                        ].join('\n'),
                      ),
                      isThreeLine: device.serialNumber.isNotEmpty,
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _editDevice(
                        context,
                        device: device,
                        farmers: farmers,
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

Future<void> _editDevice(
  BuildContext context, {
  SoilSafeDevice? device,
  List<AppUser> farmers = const [],
}) async {
  final nameController = TextEditingController(text: device?.name ?? '');
  final serialController =
      TextEditingController(text: device?.serialNumber ?? '');
  final notesController = TextEditingController(text: device?.notes ?? '');
  String? farmerId = device?.farmerId;
  final formKey = GlobalKey<FormState>();

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device == null ? 'Add device' : 'Edit device',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AuthFieldLabel('Device name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Device name is required'
                            : null,
                    decoration: authInputDecoration('SoilSAFE probe 01'),
                  ),
                  const SizedBox(height: 16),
                  const AuthFieldLabel('Serial number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: serialController,
                    decoration: authInputDecoration('ESP32 serial'),
                  ),
                  const SizedBox(height: 16),
                  const AuthFieldLabel('Assigned farmer'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    key: ValueKey(farmerId),
                    initialValue: farmerId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...farmers.map(
                        (farmer) => DropdownMenuItem<String?>(
                          value: farmer.uid,
                          child: Text(farmer.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => farmerId = value),
                  ),
                  const SizedBox(height: 16),
                  const AuthFieldLabel('Notes'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notesController,
                    decoration: authInputDecoration('Optional notes'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Save device'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  if (saved != true || !context.mounted) {
    nameController.dispose();
    serialController.dispose();
    notesController.dispose();
    return;
  }

  try {
    await context.read<DeviceRepository>().save(
          SoilSafeDevice(
            id: device?.id ?? '',
            name: nameController.text.trim(),
            serialNumber: serialController.text.trim(),
            farmerId: farmerId,
            notes: notesController.text.trim(),
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device saved.')),
      );
    }
  } on AuthFailure catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  } finally {
    nameController.dispose();
    serialController.dispose();
    notesController.dispose();
  }
}
