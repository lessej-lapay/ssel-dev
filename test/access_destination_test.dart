import 'package:flutter_test/flutter_test.dart';
import 'package:soilsafe_app/features/auth/domain/app_user.dart';

AppUser _user({
  UserRole role = UserRole.farmer,
  AccountStatus status = AccountStatus.pending,
}) {
  return AppUser(
    uid: 'uid-1',
    fullName: 'Test User',
    email: 'test@example.com',
    contactNumber: '09123456789',
    farmName: 'Block A',
    farmLocation: 'Sitio Uno',
    municipality: 'Sample',
    province: 'Davao del Norte',
    role: role,
    status: status,
  );
}

void main() {
  test('legacy regular role is treated as farmer', () {
    expect(userRoleFromString('regular'), UserRole.farmer);
    expect(userRoleFromString('farmer'), UserRole.farmer);
    expect(userRoleFromString('admin'), UserRole.admin);
  });

  test('fromMap keeps compatibility with older user documents', () {
    final user = AppUser.fromMap('abc', {
      'email': 'old@example.com',
      'role': 'regular',
      'status': 'active',
    });
    expect(user.role, UserRole.farmer);
    expect(user.status, AccountStatus.active);
    expect(user.uid, 'abc');
  });

  test('missing status defaults to pending', () {
    expect(accountStatusFromString(null), AccountStatus.pending);
    expect(accountStatusFromString('active'), AccountStatus.active);
  });

  test('unsigned users see login', () {
    expect(
      resolveAccess(
        authReady: true,
        profileReady: true,
        signedIn: false,
        profile: null,
      ),
      AccessDestination.unauthenticated,
    );
  });

  test('farmer pending sees approval screen', () {
    expect(
      resolveAccess(
        authReady: true,
        profileReady: true,
        signedIn: true,
        profile: _user(),
      ),
      AccessDestination.pendingApproval,
    );
  });

  test('active farmer sees dashboard', () {
    expect(
      resolveAccess(
        authReady: true,
        profileReady: true,
        signedIn: true,
        profile: _user(status: AccountStatus.active),
      ),
      AccessDestination.farmerDashboard,
    );
  });

  test('rejected and blocked farmers are isolated from the dashboard', () {
    expect(
      resolveAccess(
        authReady: true,
        profileReady: true,
        signedIn: true,
        profile: _user(status: AccountStatus.rejected),
      ),
      AccessDestination.rejected,
    );
    expect(
      resolveAccess(
        authReady: true,
        profileReady: true,
        signedIn: true,
        profile: _user(status: AccountStatus.blocked),
      ),
      AccessDestination.blocked,
    );
  });

  test('active admin sees admin dashboard', () {
    expect(
      resolveAccess(
        authReady: true,
        profileReady: true,
        signedIn: true,
        profile: _user(role: UserRole.admin, status: AccountStatus.active),
      ),
      AccessDestination.adminDashboard,
    );
  });

  test('non-active admin is denied', () {
    expect(
      resolveAccess(
        authReady: true,
        profileReady: true,
        signedIn: true,
        profile: _user(role: UserRole.admin, status: AccountStatus.pending),
      ),
      AccessDestination.accessDenied,
    );
  });
}
