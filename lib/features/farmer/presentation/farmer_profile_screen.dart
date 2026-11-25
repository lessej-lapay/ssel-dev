import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_validators.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/widgets/auth_chrome.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key, required this.profile});

  final AppUser profile;

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _contactController;
  late final TextEditingController _farmNameController;
  late final TextEditingController _farmLocationController;
  late final TextEditingController _municipalityController;
  late final TextEditingController _provinceController;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _fullNameController = TextEditingController(text: profile.fullName);
    _contactController = TextEditingController(text: profile.contactNumber);
    _farmNameController = TextEditingController(text: profile.farmName);
    _farmLocationController = TextEditingController(text: profile.farmLocation);
    _municipalityController = TextEditingController(text: profile.municipality);
    _provinceController = TextEditingController(text: profile.province);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _municipalityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    final updated = widget.profile.copyWith(
      fullName: _fullNameController.text.trim(),
      contactNumber: _contactController.text.trim(),
      farmName: _farmNameController.text.trim(),
      farmLocation: _farmLocationController.text.trim(),
      municipality: _municipalityController.text.trim(),
      province: _provinceController.text.trim(),
    );
    final ok = await auth.updateOwnProfile(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profile updated.' : (auth.error ?? 'Could not update profile.'),
        ),
      ),
    );
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      appBar: AppBar(title: const Text('My profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.profile.email,
                style: GoogleFonts.inter(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.profile.role.label} · ${widget.profile.status.label}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E4D2B),
                ),
              ),
              const SizedBox(height: 20),
              const AuthFieldLabel('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullNameController,
                enabled: !loading,
                validator: (value) => validateRequired(value, 'Full name'),
                decoration: authInputDecoration('Full name'),
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Contact Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                enabled: !loading,
                keyboardType: TextInputType.phone,
                validator: validateContactNumber,
                decoration: authInputDecoration('09XXXXXXXXX'),
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Farm / Plantation Name or Blocks'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _farmNameController,
                enabled: !loading,
                validator: validateOptionalFarmName,
                decoration: authInputDecoration('Optional'),
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Farm Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _farmLocationController,
                enabled: !loading,
                validator: (value) => validateRequired(value, 'Farm location'),
                decoration: authInputDecoration('Barangay or sitio'),
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Municipality'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _municipalityController,
                enabled: !loading,
                validator: (value) => validateRequired(value, 'Municipality'),
                decoration: authInputDecoration('Municipality'),
              ),
              const SizedBox(height: 16),
              const AuthFieldLabel('Province'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _provinceController,
                enabled: !loading,
                validator: (value) => validateRequired(value, 'Province'),
                decoration: authInputDecoration('Province'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _save,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save changes',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
