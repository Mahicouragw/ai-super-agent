import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  final _service = SupabaseService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      final res = await _service.signUp(
        name: _nameCtrl.text,
        username: _usernameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );

      if (res.user != null && mounted) {
        // If email confirmation disabled, user goes straight to home, otherwise verification screen
        final needsVerification = res.user!.emailConfirmedAt == null && res.session == null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(needsVerification 
                ? 'Account created! Verification email sent to ${_emailCtrl.text}. Please verify.'
                : 'Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (needsVerification) {
          // Stay on verification flow - AuthGate will show pending
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $e'), backgroundColor: Colors.red),
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
                Icon(Icons.smart_toy, size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 12),
                const Text(
                  'Create AI Super Agent Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Name, username, email, password - all secured in Supabase',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // NAME
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 16),

                // USERNAME
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username (unique)', prefixIcon: Icon(Icons.alternate_email), border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username required';
                    if (v.trim().length < 3) return 'Min 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) return 'Only letters, numbers, _ allowed';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // EMAIL
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email (unique, verification sent)', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // PASSWORD
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 chars';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  child: _loading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up & Send Verification Email', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have account?'),
                    TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Login')),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '✓ Username unique check\n✓ Email unique check\n✓ Verification email via Supabase\n✓ Password stored safely (bcrypt)\n✓ Stored in Supabase securely',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
