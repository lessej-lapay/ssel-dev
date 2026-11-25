import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/soilsafe_theme.dart';
import '../domain/auth_validators.dart';
import 'auth_controller.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_chrome.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthController>();
    final ok = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (!ok && auth.error != null) {
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
            const AuthBrandHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Welcome back',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const AuthFieldLabel('Email Address'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        enabled: !loading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: validateEmail,
                        decoration: authInputDecoration('farmer@example.com'),
                      ),
                      const SizedBox(height: 20),
                      const AuthFieldLabel('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !loading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: validatePassword,
                        onFieldSubmitted: (_) {
                          if (!loading) _handleLogin();
                        },
                        decoration: authInputDecoration('Enter your password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              color: SoilSafeColors.primaryGreen,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : _handleLogin,
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
                                  'Login',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'New to SoilSAFE?',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            'Create Farmer Account',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: SoilSafeColors.primaryGreen,
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
