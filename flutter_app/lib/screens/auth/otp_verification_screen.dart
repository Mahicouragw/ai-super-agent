import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/otp_service.dart';
import '../../services/supabase_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _otpService = OtpService();
  final _supabaseService = SupabaseService();
  bool _loading = false;
  bool _resending = false;
  int _resendSeconds = 0;

  String? name;
  String? email;
  String? password;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          name = args['name'] as String?;
          email = args['email'] as String?;
          password = args['password'] as String?;
        });
        _startResendTimer();
      }
    });
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    for (var c in _otpControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the 6-digit code')));
      return;
    }
    if (email == null || name == null || password == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session expired, please sign up again')));
      Navigator.pushReplacementNamed(context, '/signup');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _otpService.verifyOtp(
        email: email!,
        otp: _enteredOtp,
        name: name!,
        password: password!,
      );

      if (result['success'] == true) {
        // Create Supabase user after OTP verification
        try {
          await _supabaseService.signUp(name: name!, username: name!.toLowerCase().replaceAll(' ', '_'), email: email!, password: password!);
        } catch (e) {
          // User may already exist, try login
          try {
            await _supabaseService.signIn(email: email!, password: password!);
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Verified! Welcome to AI Super Agent'), backgroundColor: Colors.green),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        // Clean error message - no secrets, no vulnerabilities
        String cleanError = e.toString().replaceAll(RegExp(r'sk-or-v1-[a-zA-Z0-9]+'), '***');
        cleanError = cleanError.replaceAll(RegExp(r'sbp_[a-zA-Z0-9]+'), '***');
        cleanError = cleanError.replaceAll('Exception: ', '');
        if (cleanError.length > 100) cleanError = 'Invalid code. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cleanError), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || email == null || name == null) return;
    setState(() => _resending = true);
    try {
      await _otpService.sendOtp(email: email!, name: name!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New verification code sent to your email'), backgroundColor: Colors.green),
        );
        _startResendTimer();
        // Clear existing OTP fields
        for (var c in _otpControllers) c.clear();
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not resend code. Please try again.'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
                child: Icon(Icons.mark_email_read, size: 60, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 20),
              const Text('Check your email', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                email != null ? 'We sent a 6-digit verification code to\n$email' : 'We sent a 6-digit verification code',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 14),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter the code below to verify your email and go to dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 30),

              // 6-digit OTP boxes - clean Gmail style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) => SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.deepPurple, width: 2)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _focusNodes[i+1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _focusNodes[i-1].requestFocus();
                      }
                      if (_enteredOtp.length == 6) {
                        _verifyOtp();
                      }
                    },
                  ),
                )),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify & Continue to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't get the code? ", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: (_resendSeconds > 0 || _resending) ? null : _resendOtp,
                    child: _resending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend Code'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: const Column(
                  children: [
                    Row(children: [Icon(Icons.dashboard, size: 16, color: Colors.deepPurple), SizedBox(width: 6), Text('After verification you get:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
                    SizedBox(height: 8),
                    Text('• Prompt box to chat like ChatGPT & Gemini\n• Model chooser: Claude Opus, GPT-4o, Groq, Gemini\n• Generate images, videos, songs, lyrics, content, everything\n• Ask questions, create, build apps', style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
