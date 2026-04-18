class ChatMessage {
  final String from;
  final String to;
  final String payload;
  final String iv;
  final String? encryptedKey;
  final DateTime timestamp;

  ChatMessage({
    required this.from,
    required this.to,
    required this.payload,
    required this.iv,
    this.encryptedKey,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      from: json['from'] as String,
      to: json['to'] as String,
      payload: json['payload'] as String,
      iv: json['iv'] as String,
      encryptedKey: json['encrypted_key'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'payload': payload,
    'iv': iv,
    'encrypted_key': encryptedKey,
    'timestamp': timestamp.toIso8601String(),
  };
}
