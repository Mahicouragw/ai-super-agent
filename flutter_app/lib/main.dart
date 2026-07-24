import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/model_selector_screen.dart';
import 'screens/arena_screen.dart';
import 'screens/terms_screen.dart';

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
      title: 'AI Super Agent - LMArena Style',
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
        '/home': (context) => const DashboardScreen(),
        '/old-home': (context) => const HomeScreen(),
        '/models': (context) => const ModelSelectorScreen(),
        '/arena': (context) => const ArenaScreen(),
        '/terms': (context) => const TermsScreen(),
        '/privacy': (context) => const PrivacyScreen(),
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
        return const DashboardScreen();
      }
    } catch (e) {
      print('AuthGate offline: $e');
    }
    return const LoginScreen();
  }
}
