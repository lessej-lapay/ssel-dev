class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;

  static AuthFailure fromCode(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return const AuthFailure('Incorrect email or password');
      case 'invalid-email':
        return const AuthFailure('Enter a valid email address');
      case 'user-disabled':
        return const AuthFailure('This account has been disabled');
      case 'too-many-requests':
        return const AuthFailure('Too many attempts. Try again later');
      case 'network-request-failed':
        return const AuthFailure('Check your internet connection');
      case 'email-already-in-use':
        return const AuthFailure('An account already exists for this email');
      case 'weak-password':
        return const AuthFailure('Password should be at least 6 characters');
      case 'missing-email':
        return const AuthFailure('Enter your email address');
      case 'operation-not-allowed':
        return const AuthFailure('Email sign-in is not enabled for this app');
      case 'permission-denied':
        return const AuthFailure(
          'You do not have permission to perform this action',
        );
      case 'unauthenticated':
        return const AuthFailure('Please sign in again to continue');
      case 'invalid-argument':
        return const AuthFailure('Please check the provided information');
      case 'failed-precondition':
        return const AuthFailure(
          'This action cannot be completed in the account’s current state',
        );
      case 'not-found':
        return const AuthFailure('The requested account could not be found');
      case 'unavailable':
        return const AuthFailure(
          'Service temporarily unavailable. Check your connection and try again.',
        );
      default:
        return const AuthFailure('Something went wrong. Please try again');
    }
  }
}
