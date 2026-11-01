class MembershipPlanModel {
  final String id;
  final String gymId;
  final String name;
  final String? description;
  final double price;
  final int durationDays;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MembershipPlanModel({
    required this.id,
    required this.gymId,
    required this.name,
    this.description,
    required this.price,
    required this.durationDays,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory MembershipPlanModel.fromJson(Map<String, dynamic> json) {
    return MembershipPlanModel(
      id: json['id']?.toString() ?? '',
      gymId: json['gymId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gymId': gymId,
      'name': name,
      'description': description,
      'price': price,
      'durationDays': durationDays,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}