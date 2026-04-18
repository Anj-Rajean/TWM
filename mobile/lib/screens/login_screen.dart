import 'package:flutter/material.dart';
import '../api/auth_service.dart';
import '../crypto/rsa_key_manager.dart';
import 'contacts_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final RsaKeyManager keyManager;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.keyManager,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegister = false;

  Future<void> _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    String? token;
    if (_isRegister) {
      token = await widget.authService.register(
        _usernameController.text,
        _passwordController.text,
      );
    } else {
      token = await widget.authService.login(
        _usernameController.text,
        _passwordController.text,
      );
    }

    if (token != null && mounted) {
      await widget.keyManager.loadOrGenerate();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ContactsScreen(
              authService: widget.authService,
              keyManager: widget.keyManager,
            ),
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegister ? 'Registration failed' : 'Login failed'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Secure Chat',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isRegister ? 'Register' : 'Login'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(
                _isRegister ? 'Have account? Login' : 'No account? Register',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
