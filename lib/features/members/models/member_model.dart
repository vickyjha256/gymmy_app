class MemberModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String status;

  final String? email;
  final String? gender;
  final String? address;
  final DateTime? dateOfBirth;
  final double? height;
  final double? weight;

  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? notes;

  final List<Map<String, dynamic>> membershipHistory;

  const MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.status,
    this.email,
    this.gender,
    this.address,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.notes,
    this.membershipHistory = const [],
  });

  String get fullName => [firstName, lastName]
      .where((name) => name.trim().isNotEmpty)
      .join(' ');

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'UNKNOWN',
      email: json['email']?.toString(),
      gender: json['gender']?.toString(),
      address: json['address']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
      notes: json['notes']?.toString(),
      membershipHistory: (json['membershipHistory'] as List?)
          ?.map((item) => Map<String, dynamic>.from(item as Map))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'status': status,
      'email': email,
      'gender': gender,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'height': height,
      'weight': weight,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'notes': notes,
      'membershipHistory': membershipHistory,
    };
  }
}