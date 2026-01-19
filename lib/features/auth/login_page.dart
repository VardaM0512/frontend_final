// lib/features/auth/login_page.dart
import 'dart:convert';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app/branding.dart';
import '../../app/env.dart';
import '../../app/background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateUser(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Username required';
    if (s.length < 3) return 'Min 3 characters';
    return null;
  }

  String? _validatePass(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Min 8 characters';
    return null;
  }

  String? _extractMessage(String body) {
    try {
      final map = jsonDecode(body);
      if (map is Map && map['message'] is String) return map['message'] as String;
    } catch (_) {}
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
  final token = await AuthService.login(
    email: _usernameCtrl.text.trim(),
    password: _passwordCtrl.text,
  );

  if (token != null) {
    if (!mounted) return;

    // You’ll store token later; for now just navigate
    Navigator.pushReplacementNamed(context, '/dashboard');
  } else {
    setState(() => _error = 'Invalid credentials');
  }
  } catch (_) {
  setState(() => _error = 'Network error, try again');
}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const BackgroundImage(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            kLogoUrl,
                            height: 72,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox(height: 72),
                            loadingBuilder: (c, w, p) => p == null
                                ? w
                                : SizedBox(
                                    height: 72,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: p.expectedTotalBytes != null
                                            ? (p.cumulativeBytesLoaded / (p.expectedTotalBytes!))
                                            : null,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Faculty Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: cs.primary)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(labelText: 'Username'),
                          validator: _validateUser,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Password'),
                          validator: _validatePass,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: Text(_loading ? 'Signing in...' : 'Sign in'),
                          ),
                        ),
                        TextButton(
                          onPressed: _loading ? null : () => Navigator.pushReplacementNamed(context, '/register'),
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
