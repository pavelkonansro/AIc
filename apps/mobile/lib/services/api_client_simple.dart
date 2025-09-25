import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.68.65:3000';
  final Dio _dio;
  final Logger _logger = Logger();

  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  )) {
    _dio.interceptors.add(LogInterceptor(
      logPrint: (message) => _logger.d(message),
    ));
  }

  // Простая проверка соединения с API
  Future<Map<String, dynamic>?> checkConnection() async {
    try {
      final response = await _dio.get('/health');
      _logger.i('API connection successful: ${response.statusCode}');
      return response.data;
    } catch (e) {
      _logger.e('API connection failed: $e');
      return null;
    }
  }

  // Создание гостевого пользователя для тестирования
  Future<Map<String, dynamic>?> createGuestUser() async {
    try {
      _logger.i('Attempting to create guest user at: $baseUrl/auth/guest');
      final response = await _dio.post('/auth/guest');
      _logger.i('Guest user created successfully: ${response.statusCode}');
      _logger.i('Response data: ${response.data}');
      return response.data;
    } catch (e) {
      _logger.e('Guest user creation failed with error: $e');
      _logger.e('Error type: ${e.runtimeType}');
      if (e is DioException) {
        _logger.e('DioException details:');
        _logger.e('- Type: ${e.type}');
        _logger.e('- Message: ${e.message}');
        _logger.e('- Response: ${e.response?.data}');
        _logger.e('- Status code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  // Получение информации о пользователе
  Future<Map<String, dynamic>?> getUserInfo(String token) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _logger.i('User info retrieved: ${response.statusCode}');
      return response.data;
    } catch (e) {
      _logger.e('Get user info failed: $e');
      return null;
    }
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}

// Provider для API клиента
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());