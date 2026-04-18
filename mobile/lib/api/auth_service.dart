import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';
  static const String _usernameKey = 'username';

  Future<String?> login(String username, String password) async {
    try {
      final response = await _apiClient.post('/login', {
        'username': username,
        'password': password,
      });
      final token = response['token'] as String?;
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _usernameKey, value: username);
        _apiClient.setToken(token);
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<String?> register(String username, String password) async {
    try {
      final response = await _apiClient.post('/register', {
        'username': username,
        'password': password,
      });
      final token = response['token'] as String?;
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _usernameKey, value: username);
        _apiClient.setToken(token);
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      _apiClient.setToken(token);
    }
    return token;
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
    _apiClient.setToken('');
    _apiClient.disconnectWebSocket();
  }

  ApiClient get apiClient => _apiClient;
}
