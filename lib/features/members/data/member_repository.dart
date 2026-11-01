
import '../../../core/network/api_client.dart';
import '../models/member_model.dart';

class MemberRepository {



  Future<List<MemberModel>> getMembers({
    int page = 1,
    int limit = 10,
    String search = '',
  }) async {
    final response = await ApiClient.dio.get(
      '/members',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final body = Map<String, dynamic>.from(response.data as Map);
    final data = Map<String, dynamic>.from(body['data'] as Map);
    final membersJson = data['members'] as List;

    return membersJson
        .map(
          (member) => MemberModel.fromJson(
        Map<String, dynamic>.from(member as Map),
      ),
    )
        .toList();
  }




  Future<void> createMember({
    required String firstName,
    String? lastName,
    required String phone,
    String? email,
  }) async {
    await ApiClient.dio.post(
      '/members',
      data: {
        'firstName': firstName.trim(),
        if (lastName != null && lastName.trim().isNotEmpty)
          'lastName': lastName.trim(),
        'phone': phone.trim(),
        if (email != null && email.trim().isNotEmpty)
          'email': email.trim(),
      },
    );
  }



  Future<MemberModel> getMemberById(String id) async {
    final response = await ApiClient.dio.get('/members/$id');

    final body = Map<String, dynamic>.from(response.data as Map);

    if (body['success'] != true || body['data'] == null) {
      throw Exception('Unable to load member details.');
    }

    return MemberModel.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }





  Future<Map<String, dynamic>> updateMember(
      String id,
      Map<String, dynamic> data,
      ) async {
    final response = await ApiClient.dio.put(
      '/members/$id',
      data: data,
    );

    final body = Map<String, dynamic>.from(
      response.data as Map,
    );

    if (body['success'] != true || body['data'] == null) {
      throw Exception(body['message'] ?? 'Unable to update member.');
    }

    return Map<String, dynamic>.from(
      body['data'] as Map,
    );
  }



  Future<void> deleteMember(String id) async {
    final response = await ApiClient.dio.delete('/members/$id');

    final body = Map<String, dynamic>.from(response.data as Map);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Unable to delete member.');
    }
  }

  Future<void> deactivateMember(String id) async {
    final response = await ApiClient.dio.put(
      '/members/$id',
      data: {'status': 'INACTIVE'},
    );

    final body = Map<String, dynamic>.from(response.data as Map);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Unable to deactivate member.');
    }
  }





}
