// lib/features/auth/register_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app/branding.dart';
import '../../app/env.dart';
import '../../app/background.dart';

enum Position { professor, associateProfessor, assistantProfessor }

String positionToApi(Position p) {
  switch (p) {
    case Position.professor:
      return 'prof';
    case Position.associateProfessor:
      return 'associate prof';
    case Position.assistantProfessor:
      return 'assistant prof';
  }
}

int requiredSlots(Position p) {
  switch (p) {
    case Position.professor:
      return 2;
    case Position.associateProfessor:
      return 3;
    case Position.assistantProfessor:
      return 4;
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  Position _position = Position.assistantProfessor;
  int _morningTaken = 0;
  int _eveningTaken = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _nonEmpty(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
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
    final payload = {
      'name': _nameCtrl.text.trim(),
      'position': positionToApi(_position),
      'username': _userCtrl.text.trim(),
      'password': _passCtrl.text,
      'morningSlotsTaken': _morningTaken,
      'eveningSlotsTaken': _eveningTaken,
      'totalSlotsNeeded': requiredSlots(_position),
    };
    try {
      final res = await http.post(
        Uri.parse('$BASE_URL/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() => _error = _extractMessage(res.body) ?? 'Registration failed');
      }
    } catch (_) {
      setState(() => _error = 'Network error, try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = requiredSlots(_position);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const BackgroundImage(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
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
                        Text('Create Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: cs.primary)),
                        const SizedBox(height: 16),
                        TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: _nonEmpty),
                        const SizedBox(height: 12),
                        TextFormField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Username'), validator: _validateUser),
                        const SizedBox(height: 12),
                        TextFormField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: _validatePass),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Position>(
                          value: _position,
                          decoration: const InputDecoration(labelText: 'Position'),
                          items: const [
                            DropdownMenuItem(value: Position.professor, child: Text('Professor')),
                            DropdownMenuItem(value: Position.associateProfessor, child: Text('Associate Professor')),
                            DropdownMenuItem(value: Position.assistantProfessor, child: Text('Assistant Professor')),
                          ],
                          onChanged: (p) => setState(() => _position = p!),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Morning slots taken'),
                                initialValue: '0',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _morningTaken = int.tryParse(v) ?? 0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Evening slots taken'),
                                initialValue: '0',
                                keyboardType: TextInputType.number,
                                onChanged: (v) => _eveningTaken = int.tryParse(v) ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InputDecorator(
                          decoration: const InputDecoration(labelText: 'Total slots needed'),
                          child: Text('$total'),
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
                            child: Text(_loading ? 'Creating...' : 'Create account'),
                          ),
                        ),
                        TextButton(
                          onPressed: _loading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('Back to login'),
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
