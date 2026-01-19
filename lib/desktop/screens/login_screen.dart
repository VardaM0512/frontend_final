import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <--- Riverpod Import
import 'package:iesce_invigilation/main.dart';
import '../theme.dart';
import '../data_manager.dart';
import '../providers.dart'; // <--- Import the providers to invalidate them

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  String _designation = 'Assistant Professor';
  bool _isLoading = false;

  final List<String> _designations = [
    'Professor',
    'Associate Professor',
    'Assistant Professor',
    'Dean / Admin',
  ];

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        // 🔑 ACTUAL LOGIN (THIS WAS MISSING)
        final authResponse = await DataManager.postAuthLogin(
          email,
          password,
        );

        if (!mounted) return;

        // 🔄 Refresh providers
        ref.invalidate(currentUserProvider);
        ref.invalidate(facultyBookingsProvider);
        ref.invalidate(deanScheduleProvider);

        // 🚦 Route by role (backend-driven)
        if (authResponse.role.toUpperCase() == 'DEAN') {
          Navigator.pushReplacementNamed(context, Routes.desktopDean);
        } else {
          Navigator.pushReplacementNamed(context, Routes.desktopFaculty);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Debug Button to wipe data for testing
  void _handleDebugReset() async {
    await DataManager.debugReset();

    // Also clear Riverpod state so the UI doesn't show stale data
    ref.invalidate(currentUserProvider);
    ref.invalidate(facultyBookingsProvider);
    ref.invalidate(slotsForDateProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("DEBUG: Data Wiped"), backgroundColor: Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(48),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / Icon
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded,
                              size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          "Invigilation Portal",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to manage your schedule",
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 40),

                        // 1. Name Input
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your name'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // 2. Email Input
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email Address",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) =>
                              value == null || !value.contains('@')
                                  ? 'Enter a valid email'
                                  : null,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) =>
                              value == null || value.length < 6
                                  ? 'Enter valid password'
                                  : null,
                        ),
                        const SizedBox(height: 20),

                        // 3. Role Dropdown
                        DropdownButtonFormField<String>(
                          value: _designation,
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            labelText: "Designation",
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: _designations.map((String role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _designation = val!),
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Enter Portal",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded,
                                          size: 20)
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Debug Option
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _handleDebugReset,
                icon: const Icon(Icons.delete_forever,
                    size: 16, color: Colors.grey),
                label: const Text("Reset Local Data (Debug)",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
