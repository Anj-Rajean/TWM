import 'package:flutter/material.dart';
import '../api/auth_service.dart';
import '../api/api_client.dart';
import '../crypto/rsa_key_manager.dart';
import '../crypto/hybrid_encryptor.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  final AuthService authService;
  final RsaKeyManager keyManager;

  const ContactsScreen({
    super.key,
    required this.authService,
    required this.keyManager,
  });

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final username = await widget.authService.getUsername();
    if (username != null) {
      widget.authService.apiClient.connectWebSocket(username);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _registerPublicKey() async {
    final publicKey = widget.keyManager.getPublicKeyPem();
    if (publicKey != null) {
      final username = await widget.authService.getUsername();
      if (username != null) {
        await widget.authService.apiClient.post('/register-key', {
          'user_id': username!,
          'public_key': publicKey,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _registerPublicKey,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.authService.logout();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(contact['username'] ?? ''),
                  onTap: () async {
                    final username = await widget.authService.getUsername();
                    if (username != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            currentUser: username!,
                            contactUser: contact['username']!,
                            keyManager: widget.keyManager,
                            authService: widget.authService,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddContactDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contact'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final response = await widget.authService.apiClient.get(
                  '/get-key/${controller.text}',
                );
                final publicKeyPem = response['public_key'] as String;
                final publicKey = RsaKeyManager.parsePublicKey(publicKeyPem);
                setState(
                  () => _contacts.add({
                    'username': controller.text,
                    'public_key': publicKey,
                  }),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
