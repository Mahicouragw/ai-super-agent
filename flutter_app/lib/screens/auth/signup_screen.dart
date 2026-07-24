import 'package:flutter/material.dart';
import '../../services/otp_service.dart';
import '../../services/device_accounts_service.dart';
import 'continue_with_ai_super_agent.dart';
import '../terms_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agreedToTerms = false;
  final _otpService = OtpService();
  final _deviceAccountsService = DeviceAccountsService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _cleanError(String error) {
    String clean = error.toLowerCase();
    if (clean.contains('already') || clean.contains('exists') || clean.contains('duplicate') || clean.contains('registered')) {
      return 'This email is already used. The account is already created. Please login instead.';
    }
    if (clean.contains('email') && clean.contains('invalid')) {
      return 'Please enter a valid email address.';
    }
    if (clean.contains('password') && clean.contains('6')) {
      return 'Password must be at least 6 characters.';
    }
    if (clean.contains('network') || clean.contains('internet') || clean.contains('connection')) {
      return 'Please check your internet connection. Login works online only.';
    }
    // Hide Supabase, HTTPS, github.io, raw codes
    if (clean.contains('supabase') || clean.contains('https') || clean.contains('http') || clean.contains('github.io') || clean.contains('invalid') && clean.contains('code')) {
      return 'Something went wrong. Please try again.';
    }
    return 'This email is already used. Please login.';
  }

  Future<void> _signupAndSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions and Privacy Policy')),
      );
      return;
    }

    if (!mounted) return;
    
    setState(() => _loading = true);
    try {
      // Check internet - online only when signing up
      // In real app, check connectivity

      // Send 6-digit OTP from AI Super Agent (like Gmail/Google) - real free via Gmail SMTP
      final result = await _otpService.sendOtp(
        email: _emailCtrl.text,
        name: _nameCtrl.text,
      );

      // Save account to device accounts (server, cloud, local)
      await _deviceAccountsService.saveAccount(email: _emailCtrl.text, name: _nameCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hi ${_nameCtrl.text}! Verification code sent to ${_emailCtrl.text} from AI Super Agent'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushNamed(
          context,
          '/verify-otp',
          arguments: {
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'password': _passwordCtrl.text,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final clean = _cleanError(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(clean), backgroundColor: Colors.red),
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
                const SizedBox(height: 20),
                Icon(Icons.smart_toy, size: 70, color: Theme.of(context).primaryColor),
                const SizedBox(height: 8),
                const Text('Create Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('AI Super Agent - Real, No Duplicates', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),

                // Continue with AI Super Agent - shows accounts created on this device, saved in server, cloud, local
                ContinueWithAISuperAgent(
                  onAccountSelected: (email, name) {
                    _emailCtrl.text = email;
                    _nameCtrl.text = name;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hi $name! Selected $email')));
                  },
                  onAddNewAccount: () {},
                ),
                const SizedBox(height: 16),
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Divider())]),
                const SizedBox(height: 16),

                // Just Name as requested
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name', hintText: 'Your full name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 14),

                // Just Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'your.email@gmail.com', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Just Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure1,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure1 = !_obscure1)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure2 = !_obscure2)),
                  ),
                  validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 12),

                // Terms and Conditions + Privacy Policy Tick
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    ),
                    Expanded(
                      child: Wrap(
                        children: [
                          const Text('I agree to ', style: TextStyle(fontSize: 11)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                            child: const Text('Terms & Conditions', style: TextStyle(fontSize: 11, color: Colors.deepPurple, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                          ),
                          const Text(' and ', style: TextStyle(fontSize: 11)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                            child: const Text('Privacy Policy', style: TextStyle(fontSize: 11, color: Colors.deepPurple, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                          ),
                          const Text(' of AI Super Agent', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: _loading ? null : _signupAndSendOtp,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Sign Up & Send 6-Digit Code from AI Super Agent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have account?', style: TextStyle(fontSize: 12)),
                    TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Login', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
