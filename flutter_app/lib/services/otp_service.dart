import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OTP Service - Sends 6-digit OTP from AI Super Agent (like Gmail/Google)
/// Clean, no secrets exposed, ChatGPT-like UX
class OtpService {
  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://bwjoqomechsubjvwwbbk.supabase.co';
  String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Send 6-digit OTP from AI Super Agent - Real free email via Resend or Gmail SMTP
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String name,
  }) async {
    final url = '$supabaseUrl/functions/v1/send-otp';
    
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'apikey': anonKey,
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'name': name.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Code sent',
        };
      } else {
        // Clean error without exposing details
        throw Exception('Could not send verification code. Please try again.');
      }
    } catch (e) {
      // Clean error for user
      throw Exception('Could not send code. Please check your internet and try again.');
    }
  }

  /// Verify 6-digit OTP - clean, no secrets
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String name,
    required String password,
  }) async {
    final url = '$supabaseUrl/functions/v1/verify-otp';

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
          'apikey': anonKey,
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          'name': name.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'email': email.toLowerCase(),
          'name': name,
        };
      } else {
        // Map errors to clean user messages
        final error = data['error']?.toString().toLowerCase() ?? '';
        if (error.contains('expired')) {
          throw Exception('Code expired. Please request a new code.');
        } else if (error.contains('attempts')) {
          throw Exception('Too many attempts. Please request a new code.');
        } else if (error.contains('invalid')) {
          throw Exception('Invalid code. Please check and try again.');
        } else {
          throw Exception('Invalid code. Please try again.');
        }
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('internet')) {
        throw Exception('Network error. Please check internet connection.');
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
