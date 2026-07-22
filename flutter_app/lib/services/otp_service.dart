import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OTP Service - Sends 6-digit OTP from AI Super Agent (like Gmail/Google verification)
/// Not from Supabase default - from AI Super Agent branded email
class OtpService {
  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://bwjoqomechsubjvwwbbk.supabase.co';
  String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Send 6-digit OTP from AI Super Agent
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
      );

      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent from AI Super Agent',
          'provider': data['emailProvider'] ?? 'ai-super-agent',
          'debugOtp': data['debugOtp'], // Only in debug mode when no email provider configured
        };
      } else {
        throw Exception(data['error'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      throw Exception('Send OTP failed: $e');
    }
  }

  /// Verify 6-digit OTP
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
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP verified, going to dashboard',
          'email': data['email'],
          'name': data['name'],
          'nextStep': data['nextStep'] ?? 'dashboard',
        };
      } else {
        throw Exception(data['error'] ?? 'Invalid OTP');
      }
    } catch (e) {
      throw Exception('Verify OTP failed: $e');
    }
  }
}
