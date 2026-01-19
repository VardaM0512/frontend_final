import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'faculty_portal/pages/dashboard.dart';
import 'app/theme.dart';
import 'app/branding.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'desktop/data_manager.dart';
import 'desktop/screens/dean_dashboard.dart' as desktop_dean;
import 'desktop/screens/faculty_dashboard.dart' as desktop_faculty;
import 'desktop/screens/login_screen.dart' as desktop_login;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ADD THIS BLOCK (nothing else changes)
  await Supabase.initialize(
    url: 'https://yympjikhjkzoeaeaqbdw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5bXBqaWtoamt6b2VhZWFxYmR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzNzg5NDcsImV4cCI6MjA3NTk1NDk0N30.g18mbJ4GkDUfw-BZtEemcpZRAkaJqI2iaAqES-vk1AI',
  );

  // Existing logic — DO NOT REMOVE
  if (!kIsWeb) {
    const bool runInTestMode = false;
    await DataManager.init(isMemoryOnly: runInTestMode);
  }

  runApp(
    const ProviderScope(
      child: ProctorPilotApp(),
    ),
  );
}

class ProctorPilotApp extends StatelessWidget {
  const ProctorPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String startRoute = kIsWeb ? Routes.login : Routes.desktopLogin;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: kAppName,
      theme: AppTheme.light(),
      initialRoute: startRoute,
      routes: {
        Routes.login: (_) => const LoginPage(),
        Routes.register: (_) => const RegisterPage(),
        Routes.dashboard: (_) => FacultyDashboard(),
        Routes.desktopLogin: (_) => const desktop_login.LoginScreen(),
        Routes.desktopDean: (_) => const desktop_dean.DeanDashboard(),
        Routes.desktopFaculty: (_) => const desktop_faculty.FacultyDashboard(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }
}

class Routes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';

  static const desktopLogin = '/desktop/login';
  static const desktopDean = '/desktop/dean';
  static const desktopFaculty = '/desktop/faculty';
}
