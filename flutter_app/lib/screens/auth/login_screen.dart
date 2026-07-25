import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/device_accounts_service.dart';
import '../../services/google_sign_in_service.dart';
import '../../services/passkey_service.dart';
import '../../services/secure_storage_service.dart';
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
  bool _rememberMe = false;
  bool _keepSignedIn = false;
  
  final _service = SupabaseService();
  final _deviceService = DeviceAccountsService();
  final _googleService = GoogleSignInService();
  final _passkeyService = PasskeyService();
  final _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    try {
      final savedEmail = await _secureStorage.getUserEmail();
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          _emailCtrl.text = savedEmail;
          _rememberMe = true;
        });
      }
      final longTermEnabled = await _secureStorage.isLongTermMemoryEnabled();
      setState(() => _keepSignedIn = longTermEnabled);
    } catch (_) {}
  }

  String _cleanError(String error) {
    final lower = error.toLowerCase();
    // Do not reveal which field is incorrect - generic message
    if (lower.contains('invalid') && (lower.contains('credentials') || lower.contains('email') || lower.contains('password'))) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('network') || lower.contains('internet') || lower.contains('connection') || lower.contains('socket')) {
      return 'Please check your internet connection. Login works online only.';
    }
    // Hide internal details
    if (lower.contains('supabase') || lower.contains('https') || lower.contains('http') || lower.contains('github.io') || lower.contains('sk-or-') || lower.contains('eyj')) {
      return 'Incorrect email or password. Please try again.';
    }
    return 'Incorrect email or password. Please try again.';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      final res = await _service.signIn(email: _emailCtrl.text, password: _passwordCtrl.text);
      if (res.session != null && mounted) {
        await _deviceService.saveAccount(email: _emailCtrl.text, name: _emailCtrl.text.split('@')[0]);
        
        if (_rememberMe) {
          await _secureStorage.saveUserEmail(_emailCtrl.text);
        } else {
          await _secureStorage.saveUserEmail('');
        }
        
        await _secureStorage.saveLongTermMemoryEnabled(_keepSignedIn);
        
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

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final res = await _googleService.signInWithGoogle();
      if (res != null && res.session != null && mounted) {
        final email = res.user?.email ?? '';
        await _deviceService.saveAccount(email: email, name: res.user?.userMetadata?['name'] ?? email.split('@')[0]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hi ${email.split('@')[0]}! Logged in with Google'), backgroundColor: Colors.green));
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_cleanError(e.toString())), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithPasskey() async {
    if (_emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email first for Passkey login')));
      return;
    }

    setState(() => _loading = true);
    try {
      final success = await _passkeyService.loginWithPasskey(email: _emailCtrl.text);
      if (success && mounted) {
        // In real app, would restore Supabase session via passkey verification
        // For demo, try to get existing session or show success
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passkey verification succeeded. Logged in immediately.'), backgroundColor: Colors.green));
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('No Passkey') || msg.contains('not supported')) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passkey verification failed. Please try again.'), backgroundColor: Colors.red));
        }
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
                Semantics(
                  header: true,
                  label: 'AI Super Agent Logo',
                  child: Icon(Icons.smart_toy, size: 70, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 8),
                Semantics(header: true, child: const Text('AI Super Agent', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                const Text('Welcome Back', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Continue with AI Super Agent - shows device accounts
                Semantics(
                  label: 'Continue with AI Super Agent - shows accounts created on this device',
                  child: ContinueWithAISuperAgent(
                    onAccountSelected: (email, name) {
                      _emailCtrl.text = email;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hi $name! Selected $email')));
                    },
                    onAddNewAccount: () {},
                  ),
                ),
                const SizedBox(height: 12),

                // Google Sign-In Button - Shows as Continue with AI Super Agent style
                Semantics(
                  button: true,
                  label: 'Continue with AI Super Agent using Google account',
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _loginWithGoogle,
                    icon: const Icon(Icons.account_circle, color: Colors.deepPurple),
                    label: const Text('Continue with AI Super Agent (Google)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(height: 8),

                // Passkey Login
                Semantics(
                  button: true,
                  label: 'Login with Passkey, biometric verification',
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _loginWithPasskey,
                    icon: const Icon(Icons.fingerprint, color: Colors.green),
                    label: const Text('Login with Passkey', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Divider())]),
                const SizedBox(height: 12),

                // Email - Just Email
                Semantics(
                  label: 'Email field',
                  textField: true,
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'your.email@gmail.com', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Password - Just Password
                Semantics(
                  label: 'Password field',
                  textField: true,
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
                  ),
                ),
                const SizedBox(height: 8),

                // Remember Me + Keep Me Signed In
                Row(
                  children: [
                    Semantics(
                      label: 'Remember Me checkbox',
                      child: Row(
                        children: [
                          Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false)),
                          const Text('Remember Me', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Keep Me Signed In checkbox',
                      child: Row(
                        children: [
                          Checkbox(value: _keepSignedIn, onChanged: (v) => setState(() => _keepSignedIn = v ?? false)),
                          const Text('Keep Me Signed In', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text('Forgot Password?', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 8),

                Semantics(
                  button: true,
                  label: 'Login button',
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have account?", style: TextStyle(fontSize: 12)),
                    TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/signup'), child: const Text('Sign Up - Full Name, Username, Email, Password', style: TextStyle(fontSize: 11))),
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
