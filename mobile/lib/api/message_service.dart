import 'dart:convert';
import 'api_client.dart';

class MessageService {
  final ApiClient _apiClient;

  MessageService(this._apiClient);

  Future<List<dynamic>> getHistory(String user1, String user2) async {
    final response = await _apiClient.get('/history/$user1/$user2');
    return response['history'] ?? [];
  }

  Future<void> sendMessage(
    String from,
    String to,
    Map<String, dynamic> encryptedData,
  ) async {
    final channel = _apiClient.wsChannel;
    if (channel == null) {
      throw Exception('WebSocket not connected');
    }
    final message = {'from': from, 'to': to, ...encryptedData};
    channel.sink.add(jsonEncode(message));
  }

  void connect(String userId) {
    _apiClient.connectWebSocket(userId);
  }

  void disconnect() {
    _apiClient.disconnectWebSocket();
  }

  Stream<dynamic>? get messageStream => _apiClient.wsChannel?.stream;
}
