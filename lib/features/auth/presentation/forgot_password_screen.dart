import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';
import 'widgets/auth_chrome.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthController>();
    final ok = await auth.sendPasswordReset(_emailController.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
        ),
      );
      Navigator.of(context).pop();
    } else if (auth.error != null) {
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
                        onPressed: loading ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: SoilSafeColors.primaryGreen,
                        ),
                        label: Text(
                          'Back to login',
                          style: GoogleFonts.inter(color: SoilSafeColors.primaryGreen),
                        ),
                      ),
                      Text(
                        'Forgot password',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the email on your SoilSAFE account and we will send a reset link.',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const AuthFieldLabel('Email Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        enabled: !loading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: validateEmail,
                        onFieldSubmitted: (_) {
                          if (!loading) _handleReset();
                        },
                        decoration: authInputDecoration('farmer@example.com'),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : _handleReset,
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
                                  'Send reset email',
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
}
