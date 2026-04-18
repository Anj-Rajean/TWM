import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiClient {
  static const String baseUrl =
      'http://10.0.2.2:8000'; // Android emulator localhost
  String? _token;
  WebSocketChannel? _wsChannel;

  void setToken(String token) => _token = token;

  String get token => _token ?? '';

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  void connectWebSocket(String userId) {
    _wsChannel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8000/ws/$userId'),
    );
  }

  WebSocketChannel? get wsChannel => _wsChannel;

  void disconnectWebSocket() {
    _wsChannel?.sink.close();
    _wsChannel = null;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
