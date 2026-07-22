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
  String? debugOtp;

  @override
  void initState() {
    super.initState();
    // Get args after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          name = args['name'] as String?;
          email = args['email'] as String?;
          password = args['password'] as String?;
          debugOtp = args['debugOtp'] as String?;
        });
        // Auto-fill debug OTP for testing if provided
        if (debugOtp != null && debugOtp!.length == 6) {
          for (int i = 0; i < 6; i++) {
            _otpControllers[i].text = debugOtp![i];
          }
        }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter 6-digit code')));
      return;
    }
    if (email == null || name == null || password == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing signup info, please sign up again')));
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
        // OTP verified, now create Supabase account and login to go directly to dashboard
        try {
          // Try to sign up in Supabase (since OTP verified, we auto-confirm)
          await _supabaseService.signUp(name: name!, username: name!.toLowerCase().replaceAll(' ', '_'), email: email!, password: password!);
        } catch (e) {
          print('Supabase signup after OTP: $e - may already exist, trying login');
          try {
            await _supabaseService.signIn(email: email!, password: password!);
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Verified! Going to AI Super Agent Dashboard...'), backgroundColor: Colors.green),
          );
          // Go directly to dashboard (home)
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
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
      final result = await _otpService.sendOtp(email: email!, name: name!);
      if (mounted) {
        final newDebugOtp = result['debugOtp'];
        if (newDebugOtp != null) {
          debugOtp = newDebugOtp;
          // Auto-fill for debug
          for (int i = 0; i < 6; i++) _otpControllers[i].text = newDebugOtp[i];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newDebugOtp != null ? 'New OTP: $newDebugOtp (debug) - Email sent from AI Super Agent' : 'New code sent from AI Super Agent to $email'), backgroundColor: Colors.green),
        );
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resend failed: $e'), backgroundColor: Colors.red));
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.mark_email_read, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              const Text('Check your email', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                email != null ? 'We sent a 6-digit code from AI Super Agent to\n$email\n(like Google Gmail verification)' : 'We sent a 6-digit code from AI Super Agent',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  '📧 Email sent from AI Super Agent, not from Supabase - Real app style like Gmail/Google',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.deepPurple),
                ),
              ),
              if (debugOtp != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                  child: Column(children: [
                    const Text('🔧 Debug Mode: No email provider configured', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Your OTP is: $debugOtp', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4)),
                    const SizedBox(height: 4),
                    const Text('In production, set RESEND_API_KEY in Supabase secrets to send real Gmail-like emails', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ]),
                ),
              ],
              const SizedBox(height: 30),

              // 6-digit OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) => SizedBox(
                  width: 45,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _focusNodes[i+1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _focusNodes[i-1].requestFocus();
                      }
                      if (_enteredOtp.length == 6 && i == 5) {
                        _verifyOtp();
                      }
                    },
                  ),
                )),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify & Go to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't get code?"),
                  TextButton(
                    onPressed: (_resendSeconds > 0 || _resending) ? null : _resendOtp,
                    child: _resending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend Code from AI Super Agent'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'After verification, you go directly to AI Super Agent Dashboard with:\n• Prompt edit box\n• Model chooser (Claude Opus, GPT-4o, Groq, Gemini)\n• Chat like ChatGPT/Gemini\n• Generate images, videos, songs, lyrics, content, everything',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
