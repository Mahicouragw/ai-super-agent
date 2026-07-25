import 'package:flutter/material.dart';
import '../../services/otp_service.dart';
import '../../services/device_accounts_service.dart';
import '../../services/secure_storage_service.dart';
import 'continue_with_ai_super_agent.dart';
import '../terms_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
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
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _cleanError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('already') || lower.contains('exists') || lower.contains('duplicate') || lower.contains('registered') || lower.contains('used')) {
      return 'This email is already used. The account is already created. Please login.';
    }
    if (lower.contains('email') && lower.contains('invalid')) {
      return 'Please enter a valid email address.';
    }
    if (lower.contains('username') && (lower.contains('taken') || lower.contains('exists'))) {
      return 'This username is already taken. Please choose another.';
    }
    if (lower.contains('network') || lower.contains('internet') || lower.contains('connection') || lower.contains('socket')) {
      return 'Please check your internet connection.';
    }
    if (lower.contains('supabase') || lower.contains('https') || lower.contains('http') || lower.contains('github.io') || lower.contains('code') && lower.contains('invalid')) {
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

    setState(() => _loading = true);
    try {
      // Validate all user input - Security requirement
      if (!SecureStorageService.isValidName(_fullNameCtrl.text)) {
        throw Exception('Please enter a valid full name');
      }
      if (!SecureStorageService.isValidUsername(_usernameCtrl.text)) {
        throw Exception('Username must be 3-20 chars, letters, numbers, underscore only');
      }
      if (!SecureStorageService.isValidEmail(_emailCtrl.text)) {
        throw Exception('Please enter a valid email');
      }
      if (!SecureStorageService.isValidPassword(_passwordCtrl.text)) {
        throw Exception('Password must be at least 6 characters');
      }

      // Send 6-digit OTP from AI Super Agent (like Gmail/Google)
      final result = await _otpService.sendOtp(
        email: _emailCtrl.text,
        name: _fullNameCtrl.text,
      );

      // Save account to device accounts (server, cloud, local) for Continue with AI Super Agent
      await _deviceAccountsService.saveAccount(email: _emailCtrl.text, name: _fullNameCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hi ${_fullNameCtrl.text}! Verification code sent to ${_emailCtrl.text} from AI Super Agent'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushNamed(
          context,
          '/verify-otp',
          arguments: {
            'name': _fullNameCtrl.text.trim(),
            'username': _usernameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'password': _passwordCtrl.text,
          },
        );
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
                const SizedBox(height: 16),
                Semantics(header: true, child: Icon(Icons.smart_toy, size: 60, color: Theme.of(context).primaryColor)),
                const SizedBox(height: 8),
                Semantics(header: true, child: const Text('Create Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                const Text('AI Super Agent - Secure OTP verification like Gmail/Google', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 12),

                // Continue with AI Super Agent
                Semantics(
                  label: 'Continue with AI Super Agent - shows accounts on this device',
                  child: ContinueWithAISuperAgent(
                    onAccountSelected: (email, name) {
                      _emailCtrl.text = email;
                      _fullNameCtrl.text = name;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hi $name! Selected $email')));
                    },
                    onAddNewAccount: () {},
                  ),
                ),
                const SizedBox(height: 12),
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Divider())]),
                const SizedBox(height: 12),

                // Full Name
                Semantics(
                  label: 'Full Name field',
                  textField: true,
                  child: TextFormField(
                    controller: _fullNameCtrl,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Full Name', hintText: 'John Doe', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().length < 2 ? 'Full Name required (at least 2 chars)' : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Username
                Semantics(
                  label: 'Username field, 3-20 chars, letters numbers underscore',
                  textField: true,
                  child: TextFormField(
                    controller: _usernameCtrl,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Username', hintText: 'johndoe123', prefixIcon: Icon(Icons.alternate_email), border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Username required';
                      if (v.trim().length < 3) return 'Min 3 chars';
                      if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(v)) return '3-20 chars, letters, numbers, _ only';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Email Address
                Semantics(
                  label: 'Email Address field',
                  textField: true,
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email Address', hintText: 'your.email@gmail.com', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                Semantics(
                  label: 'Password field',
                  textField: true,
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure1,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimum 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure1 = !_obscure1)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password required';
                      if (v.length < 6) return 'Min 6 chars';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Confirm Password
                Semantics(
                  label: 'Confirm Password field',
                  textField: true,
                  child: TextFormField(
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
                ),
                const SizedBox(height: 12),

                // Terms and Conditions + Privacy Policy Tick
                Row(
                  children: [
                    Checkbox(value: _agreedToTerms, onChanged: (v) => setState(() => _agreedToTerms = v ?? false)),
                    Expanded(
                      child: Wrap(
                        children: [
                          const Text('I agree to ', style: TextStyle(fontSize: 11)),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/terms'),
                            child: const Text('Terms & Conditions', style: TextStyle(fontSize: 11, color: Colors.deepPurple, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                          ),
                          const Text(' and ', style: TextStyle(fontSize: 11)),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/privacy'),
                            child: const Text('Privacy Policy', style: TextStyle(fontSize: 11, color: Colors.deepPurple, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                          ),
                          const Text(' of AI Super Agent', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Semantics(
                  button: true,
                  label: 'Sign up and send OTP, 6-digit code from AI Super Agent',
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signupAndSendOtp,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Send OTP - 6 Digit Code from AI Super Agent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
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
