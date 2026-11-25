import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, admin }

enum AccountStatus { pending, active, rejected, blocked }

enum AccessDestination {
  unauthenticated,
  loading,
  farmerDashboard,
  adminDashboard,
  pendingApproval,
  rejected,
  blocked,
  accessDenied,
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.farmName,
    required this.farmLocation,
    required this.municipality,
    required this.province,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String contactNumber;
  final String farmName;
  final String farmLocation;
  final String municipality;
  final String province;
  final UserRole role;
  final AccountStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == UserRole.admin;
  bool get isFarmer => role == UserRole.farmer;
  bool get isActive => status == AccountStatus.active;

  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    final local = email.split('@').first;
    if (local.isEmpty) return isAdmin ? 'Admin' : 'Farmer';
    return '${local[0].toUpperCase()}${local.substring(1)}';
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: (data['uid'] as String?)?.trim().isNotEmpty == true
          ? data['uid'] as String
          : uid,
      fullName: (data['fullName'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      contactNumber: (data['contactNumber'] as String?)?.trim() ?? '',
      farmName: (data['farmName'] as String?)?.trim() ?? '',
      farmLocation: (data['farmLocation'] as String?)?.trim() ?? '',
      municipality: (data['municipality'] as String?)?.trim() ?? '',
      province: (data['province'] as String?)?.trim() ?? '',
      role: userRoleFromString(data['role'] as String?),
      status: accountStatusFromString(data['status'] as String?),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'contactNumber': contactNumber,
      'farmName': farmName,
      'farmLocation': farmLocation,
      'municipality': municipality,
      'province': province,
      'role': role.storageValue,
      'status': status.storageValue,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toProfileUpdateMap() {
    return {
      'fullName': fullName,
      'contactNumber': contactNumber,
      'farmName': farmName,
      'farmLocation': farmLocation,
      'municipality': municipality,
      'province': province,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? fullName,
    String? contactNumber,
    String? farmName,
    String? farmLocation,
    String? municipality,
    String? province,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      contactNumber: contactNumber ?? this.contactNumber,
      farmName: farmName ?? this.farmName,
      farmLocation: farmLocation ?? this.farmLocation,
      municipality: municipality ?? this.municipality,
      province: province ?? this.province,
      role: role,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension UserRoleStorage on UserRole {
  String get storageValue => switch (this) {
        UserRole.farmer => 'farmer',
        UserRole.admin => 'admin',
      };

  String get label => switch (this) {
        UserRole.farmer => 'Farmer',
        UserRole.admin => 'Admin',
      };
}

extension AccountStatusStorage on AccountStatus {
  String get storageValue => switch (this) {
        AccountStatus.pending => 'pending',
        AccountStatus.active => 'active',
        AccountStatus.rejected => 'rejected',
        AccountStatus.blocked => 'blocked',
      };

  String get label => switch (this) {
        AccountStatus.pending => 'Pending approval',
        AccountStatus.active => 'Active',
        AccountStatus.rejected => 'Rejected',
        AccountStatus.blocked => 'Blocked',
      };
}

/// Maps stored roles onto the current model.
/// Existing documents used `regular`; treat those as farmers.
UserRole userRoleFromString(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'farmer':
    case 'regular':
    default:
      return UserRole.farmer;
  }
}

AccountStatus accountStatusFromString(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'active':
      return AccountStatus.active;
    case 'rejected':
      return AccountStatus.rejected;
    case 'blocked':
      return AccountStatus.blocked;
    case 'pending':
    default:
      return AccountStatus.pending;
  }
}

AccessDestination resolveAccess({
  required bool authReady,
  required bool profileReady,
  required bool signedIn,
  AppUser? profile,
}) {
  if (!authReady) return AccessDestination.loading;
  if (!signedIn) return AccessDestination.unauthenticated;
  if (!profileReady) return AccessDestination.loading;
  if (profile == null) return AccessDestination.accessDenied;

  if (profile.role == UserRole.admin) {
    return profile.status == AccountStatus.active
        ? AccessDestination.adminDashboard
        : AccessDestination.accessDenied;
  }

  switch (profile.status) {
    case AccountStatus.pending:
      return AccessDestination.pendingApproval;
    case AccountStatus.active:
      return AccessDestination.farmerDashboard;
    case AccountStatus.rejected:
      return AccessDestination.rejected;
    case AccountStatus.blocked:
      return AccessDestination.blocked;
  }
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
