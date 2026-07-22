import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/model_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const AISuperAgentApp());
}

class AISuperAgentApp extends StatelessWidget {
  const AISuperAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Super Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/verify-otp': (context) => const OtpVerificationScreen(),
        '/home': (context) => const DashboardScreen(), // New dashboard with prompt box + model chooser
        '/old-home': (context) => const HomeScreen(),
        '/models': (context) => const ModelSelectorScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen to auth changes for auto-login after OTP verification
    try {
      SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    try {
      final session = SupabaseConfig.client.auth.currentSession;
      if (session != null) {
        // After OTP verification, user is auto-confirmed and goes directly to dashboard
        // No more "Supabase stored" messages - just dashboard with prompt box
        return const DashboardScreen();
      }
    } catch (e) {
      print('AuthGate offline: $e');
    }
    // If no session, show login (just email + password)
    return const LoginScreen();
  }
}
