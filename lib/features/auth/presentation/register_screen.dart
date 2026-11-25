import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../domain/auth_validators.dart';
import '../domain/farmer_registration.dart';
import 'auth_controller.dart';
import 'widgets/auth_chrome.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _contactController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _provinceController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _contactController.dispose();
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _municipalityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthController>();
    final ok = await auth.registerFarmer(
      FarmerRegistration(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        contactNumber: _contactController.text.trim(),
        farmName: _farmNameController.text.trim(),
        farmLocation: _farmLocationController.text.trim(),
        municipality: _municipalityController.text.trim(),
        province: _provinceController.text.trim(),
      ),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration submitted. Your account is waiting for admin approval.',
          ),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }
    if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final loading = auth.isLoading;

    return Scaffold(
      backgroundColor: SoilSafeColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            const AuthBrandHeader(compact: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed:
                            loading ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: SoilSafeColors.primaryGreen,
                        ),
                        label: Text(
                          'Back to login',
                          style: GoogleFonts.inter(
                            color: SoilSafeColors.primaryGreen,
                          ),
                        ),
                      ),
                      Text(
                        'Create farmer account',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Register to request SoilSAFE access. An administrator must '
                        'approve your account before you can use the app.',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _labeledField(
                        label: 'Full Name',
                        child: TextFormField(
                          controller: _fullNameController,
                          enabled: !loading,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                              validateRequired(value, 'Full name'),
                          decoration: authInputDecoration('Juan Dela Cruz'),
                        ),
                      ),
                      _labeledField(
                        label: 'Email Address',
                        child: TextFormField(
                          controller: _emailController,
                          enabled: !loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: validateEmail,
                          decoration:
                              authInputDecoration('farmer@example.com'),
                        ),
                      ),
                      _labeledField(
                        label: 'Password',
                        child: TextFormField(
                          controller: _passwordController,
                          enabled: !loading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: validatePasswordStrength,
                          decoration: authInputDecoration(
                            'At least 8 characters, letter and number',
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _labeledField(
                        label: 'Confirm Password',
                        child: TextFormField(
                          controller: _confirmController,
                          enabled: !loading,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (value) => validateConfirmPassword(
                            value,
                            _passwordController.text,
                          ),
                          decoration:
                              authInputDecoration('Re-enter your password')
                                  .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _labeledField(
                        label: 'Contact Number',
                        child: TextFormField(
                          controller: _contactController,
                          enabled: !loading,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: validateContactNumber,
                          decoration: authInputDecoration('09XXXXXXXXX'),
                        ),
                      ),
                      _labeledField(
                        label: 'Farm / Plantation Name or Blocks (optional)',
                        child: TextFormField(
                          controller: _farmNameController,
                          enabled: !loading,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: validateOptionalFarmName,
                          decoration:
                              authInputDecoration('Example: Block A, Sitio Farm'),
                        ),
                      ),
                      _labeledField(
                        label: 'Farm Location',
                        child: TextFormField(
                          controller: _farmLocationController,
                          enabled: !loading,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                              validateRequired(value, 'Farm location'),
                          decoration:
                              authInputDecoration('Barangay or sitio'),
                        ),
                      ),
                      _labeledField(
                        label: 'Municipality',
                        child: TextFormField(
                          controller: _municipalityController,
                          enabled: !loading,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                              validateRequired(value, 'Municipality'),
                          decoration: authInputDecoration('Municipality'),
                        ),
                      ),
                      _labeledField(
                        label: 'Province',
                        child: TextFormField(
                          controller: _provinceController,
                          enabled: !loading,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                              validateRequired(value, 'Province'),
                          onFieldSubmitted: (_) {
                            if (!loading) _handleRegister();
                          },
                          decoration: authInputDecoration('Province'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your account role is Farmer. Administrators assign Admin '
                        'accounts separately.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : _handleRegister,
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
                                  'Submit registration',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthFieldLabel(label),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
