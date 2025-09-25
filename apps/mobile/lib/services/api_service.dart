import 'api_client.dart';
import '../config/api_config.dart';

class ApiService {
  late final ApiClient _apiClient;

  ApiService() {
    _apiClient = ApiClient();
  }

  Future<Map<String, dynamic>> createUserProfile({
    required String userId,
    required String email,
    required String name,
    required String ageGroup,
    required String country,
    required Map<String, dynamic> consentFlags,
  }) async {
    return await _apiClient.createUserProfile(
      userId: userId,
      email: email,
      name: name,
      ageGroup: ageGroup,
      country: country,
      consentFlags: consentFlags,
    );
  }

  Future<Map<String, dynamic>> startChatSession(String userId) async {
    return await _apiClient.startChatSession(userId);
  }
}