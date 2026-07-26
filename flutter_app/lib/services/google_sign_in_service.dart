import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Google Sign-In - Secure, uses Supabase Auth with Google provider
/// Never expose API keys in app - uses Supabase backend
class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final _supabase = SupabaseConfig.client;

  /// Sign in with Google - shows Google account chooser
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Google authentication failed');
      }

      // Use Provider enum from supabase_flutter - should be available as top-level Provider
      final response = await _supabase.auth.signInWithIdToken(
        provider: Provider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      if (e.toString().toLowerCase().contains('network') || e.toString().toLowerCase().contains('connection')) {
        throw Exception('Please check your internet connection');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
    } catch (_) {}
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
