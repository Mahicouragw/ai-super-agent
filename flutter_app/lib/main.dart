import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';

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
        '/home': (context) => const HomeScreen(),
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
    // Listen to auth changes
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = SupabaseConfig.client.auth.currentSession;
    if (session != null) {
      // Check if email confirmed
      final user = session.user;
      if (user.emailConfirmedAt == null) {
        return const VerificationPendingScreen();
      }
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Verification email sent!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your inbox and click the verification link. After verifying, come back and login.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await SupabaseConfig.client.auth.signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Go to Login'),
            ),
            TextButton(
              onPressed: () async {
                final email = SupabaseConfig.client.auth.currentUser?.email;
                if (email != null) {
                  await SupabaseConfig.client.auth.resend(type: OtpType.signup, email: email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email resent!')),
                    );
                  }
                }
              },
              child: const Text('Resend Verification Email'),
            )
          ],
        ),
      ),
    );
  }
}
