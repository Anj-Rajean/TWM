import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/auth_service.dart';
import '../crypto/rsa_key_manager.dart';
import '../crypto/hybrid_encryptor.dart';
import 'package:pointycastle/export.dart' hide State, Padding;

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String contactUser;
  final RsaKeyManager keyManager;
  final AuthService authService;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.contactUser,
    required this.keyManager,
    required this.authService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final HybridEncryptor _encryptor = HybridEncryptor();
  StreamSubscription? _wsSubscription;
  RSAPublicKey? _contactPublicKey;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _listenToMessages();
  }

  Future<void> _loadHistory() async {
    final response = await widget.authService.apiClient.get(
      '/history/${widget.currentUser}/${widget.contactUser}',
    );
    final history = response['history'] as List? ?? [];
    _decryptMessages(history);
  }

  void _decryptMessages(List history) {
    final privateKey = widget.keyManager.getPrivateKey();
    if (privateKey == null) return;
    for (final msg in history) {
      try {
        final decrypted = _encryptor.decrypt(
          Map<String, String>.from(msg),
          privateKey,
        );
        _messages.add({...msg, 'decrypted': decrypted});
      } catch (e) {
        _messages.add(msg);
      }
    }
    setState(() {});
  }

  void _listenToMessages() {
    final channel = widget.authService.apiClient.wsChannel;
    if (channel != null) {
      _wsSubscription = channel.stream.listen((data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        if (msg['from'] == widget.contactUser) {
          setState(() => _messages.add(msg));
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _contactPublicKey == null) return;

    final encrypted = _encryptor.encrypt(
      _messageController.text,
      _contactPublicKey!,
    );
    final channel = widget.authService.apiClient.wsChannel;
    if (channel != null) {
      channel.sink.add(
        jsonEncode({
          'from': widget.currentUser,
          'to': widget.contactUser,
          ...encrypted,
        }),
      );
      setState(() {
        _messages.add({
          'from': widget.currentUser,
          'to': widget.contactUser,
          'decrypted': _messageController.text,
        });
      });
      _messageController.clear();
    }
  }

  Future<void> _fetchContactKey() async {
    try {
      final response = await widget.authService.apiClient.get(
        '/get-key/${widget.contactUser}',
      );
      final publicKeyPem = response['public_key'] as String;
      setState(
          () => _contactPublicKey = RsaKeyManager.parsePublicKey(publicKeyPem));
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contactUser)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['from'] == widget.currentUser;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['decrypted'] ?? msg['payload'] ?? ''),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
