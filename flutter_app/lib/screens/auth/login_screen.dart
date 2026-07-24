import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/device_accounts_service.dart';
import 'continue_with_ai_super_agent.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  final _service = SupabaseService();
  final _deviceService = DeviceAccountsService();

  String _cleanError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('invalid') && lower.contains('credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (lower.contains('email') && lower.contains('not') && lower.contains('confirmed')) {
      return 'Please verify your email with the 6-digit code from AI Super Agent.';
    }
    if (lower.contains('network') || lower.contains('internet') || lower.contains('connection')) {
      return 'Please connect to internet. Login works online only.';
    }
    // Hide supabase, https, github.io, codes
    if (lower.contains('supabase') || lower.contains('https') || lower.contains('github.io') || lower.contains('invalid') && lower.contains('code')) {
      return 'Login failed. Please check your details.';
    }
    return 'Login failed. Please try again.';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Online only check
    // In real app, use connectivity_plus to check
    // For now, try and catch will handle offline

    setState(() => _loading = true);
    try {
      final res = await _service.signIn(email: _emailCtrl.text, password: _passwordCtrl.text);
      if (res.session != null && mounted) {
        // Save to device accounts for Continue with AI Super Agent
        await _deviceService.saveAccount(email: _emailCtrl.text, name: _emailCtrl.text.split('@')[0]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hi ${_emailCtrl.text.split('@')[0]}! Welcome back'), backgroundColor: Colors.green),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_cleanError(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                Icon(Icons.smart_toy, size: 70, color: Theme.of(context).primaryColor),
                const SizedBox(height: 8),
                const Text('AI Super Agent', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('Welcome Back', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Continue with AI Super Agent - shows accounts on this device, saved in server, cloud, local
                ContinueWithAISuperAgent(
                  onAccountSelected: (email, name) {
                    _emailCtrl.text = email;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hi $name! Selected $email - Enter password to login')));
                  },
                  onAddNewAccount: () {},
                ),
                const SizedBox(height: 16),
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Divider())]),
                const SizedBox(height: 16),

                // Just Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'your.email@gmail.com', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
                ),
                const SizedBox(height: 14),

                // Just Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have account?", style: TextStyle(fontSize: 12)),
                    TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/signup'), child: const Text('Sign Up - Name, Email, Password', style: TextStyle(fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Login works online only, not offline. After login, works offline with cached data. No reinstall needed via Supabase remote config app_config.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
