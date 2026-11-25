class FarmerRegistration {
  const FarmerRegistration({
    required this.fullName,
    required this.email,
    required this.password,
    required this.contactNumber,
    required this.farmLocation,
    required this.municipality,
    required this.province,
    this.farmName = '',
  });

  final String fullName;
  final String email;
  final String password;
  final String contactNumber;
  final String farmName;
  final String farmLocation;
  final String municipality;
  final String province;
}
