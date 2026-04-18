import 'package:flutter/material.dart';
import 'api/auth_service.dart';
import 'crypto/rsa_key_manager.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SecureChatApp());
}

class SecureChatApp extends StatelessWidget {
  const SecureChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          final authService = AuthService();
          final keyManager = RsaKeyManager();
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return ContactsScreen(
              authService: authService,
              keyManager: keyManager,
            );
          }
          return LoginScreen(authService: authService, keyManager: keyManager);
        },
      ),
    );
  }
}

class ContactsScreen extends StatelessWidget {
  final AuthService authService;
  final RsaKeyManager keyManager;

  const ContactsScreen({
    super.key,
    required this.authService,
    required this.keyManager,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
