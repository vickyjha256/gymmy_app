class MembershipModel {
  final String id;
  final String memberId;
  final String membershipPlanId;
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  final String memberName;
  final String memberPhone;
  final String planName;

  MembershipModel({
    required this.id,
    required this.memberId,
    required this.membershipPlanId,
    required this.startDate,
    required this.endDate,
    required this.amountPaid,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.memberName,
    required this.memberPhone,
    required this.planName,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    final member = json['member'] as Map<String, dynamic>;
    final plan = json['membershipPlan'] as Map<String, dynamic>;

    final firstName = member['firstName'] ?? '';
    final lastName = member['lastName'] ?? '';

    return MembershipModel(
      id: json['id'],
      memberId: json['memberId'],
      membershipPlanId: json['membershipPlanId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      amountPaid: double.tryParse(
        json['amountPaid'].toString(),
      ) ??
          0,
      paymentMethod: json['paymentMethod'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      memberName: '$firstName $lastName'.trim(),
      memberPhone: member['phone'] ?? '',
      planName: plan['name'] ?? '',
    );
  }
}