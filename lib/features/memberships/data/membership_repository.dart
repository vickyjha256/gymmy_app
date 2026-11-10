import '../../../core/network/api_client.dart';
import '../models/membership_model.dart';

class MembershipRepository {
  Future<List<MembershipModel>> getMemberships({
    String? status,
  }) async {
    final response = await ApiClient.dio.get(
      '/memberships',
      queryParameters: status == null ? null : {'status': status},
    );

    final List<dynamic> data = response.data['data'];

    return data
        .map(
          (item) => MembershipModel.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }



  Future<void> renewMembership({
    required String memberId,
    required String membershipPlanId,
    required String paymentMethod,
  }) async {
    final response = await ApiClient.dio.post(
      '/memberships/renew/$memberId',
      data: {
        'membershipPlanId': membershipPlanId,
        'paymentMethod': paymentMethod,
      },
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to renew membership');
    }
  }

  Future<void> cancelMembership(String membershipId) async {
    final response = await ApiClient.dio.patch(
      '/memberships/$membershipId/cancel',
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to cancel membership');
    }
  }








}