import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;
  static const String baseUrl = 'http://192.168.68.65:3000';

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  // Auth methods
  Future<Map<String, dynamic>> signup({
    required String nick,
    required String ageGroup,
    required String country,
    required String locale,
  }) async {
    final response = await post('/auth/signup', data: {
      'nick': nick,
      'ageGroup': ageGroup,
      'country': country,
      'locale': locale,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createUserProfile({
    required String userId,
    required String email,
    required String name,
    required String ageGroup,
    required String country,
    required Map<String, dynamic> consentFlags,
  }) async {
    final response = await post('/auth/signup', data: {
      'userId': userId,
      'email': email,
      'nick': name,
      'ageGroup': ageGroup,
      'country': country,
      'locale': country.toLowerCase() == 'cz' ? 'cs-CZ' : 'en-US',
      'consentFlags': consentFlags,
    });
    return response.data;
  }

  // Chat methods
  Future<Map<String, dynamic>> startChatSession(String userId) async {
    final response = await post('/chat/session', data: {'userId': userId});
    return response.data;
  }

  // SOS methods
  Future<List<dynamic>> getSosContacts({
    required String country,
    String? locale,
  }) async {
    final response = await get('/sos/resources', queryParameters: {
      'country': country,
      if (locale != null) 'locale': locale,
    });
    return response.data;
  }
}
