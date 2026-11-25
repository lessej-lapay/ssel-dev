import 'package:flutter_test/flutter_test.dart';
import 'package:soilsafe_app/features/auth/domain/auth_validators.dart';

void main() {
  test('email validation', () {
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('not-an-email'), isNotNull);
    expect(validateEmail('farmer@example.com'), isNull);
  });

  test('password strength requires length, letter, and number', () {
    expect(validatePasswordStrength('short1'), isNotNull);
    expect(validatePasswordStrength('longpassword'), isNotNull);
    expect(validatePasswordStrength('Password1'), isNull);
  });

  test('confirm password must match', () {
    expect(validateConfirmPassword('Password1', 'Password1'), isNull);
    expect(validateConfirmPassword('Password2', 'Password1'), isNotNull);
  });

  test('Philippine mobile numbers are accepted', () {
    expect(validateContactNumber('09123456789'), isNull);
    expect(validateContactNumber('+639123456789'), isNull);
    expect(validateContactNumber('12345'), isNotNull);
  });
}
