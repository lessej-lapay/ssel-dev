final _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
final _mobilePattern = RegExp(r'^(\+63|0)9\d{9}$');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email address is required';
  if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
  return null;
}

String? validatePassword(String? value, {int minLength = 6}) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password is required';
  if (password.length < minLength) {
    return 'Password should be at least $minLength characters';
  }
  return null;
}

String? validatePasswordStrength(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password is required';
  if (password.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
    return 'Password must include a letter';
  }
  if (!RegExp(r'\d').hasMatch(password)) {
    return 'Password must include a number';
  }
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) return 'Please confirm your password';
  if (value != password) return 'Passwords do not match';
  return null;
}

String? validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label is required';
  return null;
}

String? validateContactNumber(String? value) {
  final raw = (value ?? '').trim().replaceAll(RegExp(r'[\s-]'), '');
  if (raw.isEmpty) return 'Contact number is required';
  if (!_mobilePattern.hasMatch(raw)) {
    return 'Enter a valid mobile number (09XXXXXXXXX or +639XXXXXXXXX)';
  }
  return null;
}

String? validateOptionalFarmName(String? value) {
  final name = value?.trim() ?? '';
  if (name.length > 80) return 'Farm name is too long';
  return null;
}
