import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/user_model.dart';

class AuthResult {
  final String accessToken;
  final UserModel user;

  AuthResult({required this.accessToken, required this.user});
}

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AuthResult(
      accessToken: data['access_token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AuthResult(
      accessToken: data['access_token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.dio.get(ApiEndpoints.me);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}
