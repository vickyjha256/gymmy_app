import '../../../core/network/api_client.dart';
import '../models/membership_plan_model.dart';

class MembershipPlanRepository {


  Future<List<MembershipPlanModel>> getMembershipPlans() async {
    final response = await ApiClient.dio.get('/membership-plans');

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to fetch membership plans');
    }

    final plans = body['data'] as List<dynamic>;

    return plans
        .map((plan) => MembershipPlanModel.fromJson(
      Map<String, dynamic>.from(plan as Map),
    ))
        .toList();
  }

  Future<MembershipPlanModel> createMembershipPlan(
      Map<String, dynamic> data,
      ) async {
    final response = await ApiClient.dio.post(
      '/membership-plans',
      data: data,
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true || body['data'] == null) {
      throw Exception(body['message'] ?? 'Failed to create membership plan');
    }

    return MembershipPlanModel.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }

  Future<MembershipPlanModel> updateMembershipPlan(
      String id,
      Map<String, dynamic> data,
      ) async {
    final response = await ApiClient.dio.put(
      '/membership-plans/$id',
      data: data,
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true || body['data'] == null) {
      throw Exception(body['message'] ?? 'Failed to update membership plan');
    }

    return MembershipPlanModel.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }

  Future<void> activateMembershipPlan(String id) async {
    final response = await ApiClient.dio.patch(
      '/membership-plans/$id/activate',
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to activate plan');
    }
  }

  Future<void> deactivateMembershipPlan(String id) async {
    final response = await ApiClient.dio.patch(
      '/membership-plans/$id/deactivate',
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to deactivate plan');
    }
  }

  Future<void> deleteMembershipPlan(String id) async {
    final response = await ApiClient.dio.delete(
      '/membership-plans/$id',
    );

    final body = response.data as Map<String, dynamic>;

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to delete plan');
    }
  }
}