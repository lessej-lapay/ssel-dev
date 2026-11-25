import 'package:cloud_firestore/cloud_firestore.dart';

class SoilSafeDevice {
  const SoilSafeDevice({
    required this.id,
    required this.name,
    required this.serialNumber,
    this.farmerId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String serialNumber;
  final String? farmerId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAssigned => farmerId != null && farmerId!.isNotEmpty;

  factory SoilSafeDevice.fromMap(String id, Map<String, dynamic> data) {
    final farmerId = (data['farmerId'] as String?)?.trim();
    return SoilSafeDevice(
      id: id,
      name: (data['name'] as String?)?.trim() ?? 'SoilSAFE device',
      serialNumber: (data['serialNumber'] as String?)?.trim() ?? '',
      farmerId: farmerId == null || farmerId.isEmpty ? null : farmerId,
      notes: (data['notes'] as String?)?.trim(),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'name': name,
      'serialNumber': serialNumber,
      'farmerId': farmerId,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

DateTime? _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
