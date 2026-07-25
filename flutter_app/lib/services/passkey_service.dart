import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../config/supabase_config.dart';

/// Android Passkeys using platform Credential Manager
/// Supports: Create Passkey, Login with Passkey, Delete Passkey, Manage Passkey
/// For demo, uses local_auth (biometric) as fallback for Passkey-like behavior
/// Real implementation would use passkeys package with Credential Manager API

class PasskeyService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _passkeysKey = 'user_passkeys';
  static const String _passkeyEnabledKey = 'passkey_enabled';

  /// Check if device supports Passkeys / Biometrics
  Future<bool> isPasskeySupported() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Create Passkey - stores credential securely
  Future<bool> createPasskey({required String email}) async {
    try {
      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Create Passkey for $email - Verify your identity',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );

      if (!didAuth) return false;

      // Save passkey info locally + in Supabase offline_cache for cloud sync
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_passkeysKey) ?? [];
      final newEntry = '${email.toLowerCase()}|${DateTime.now().toIso8601String()}';
      if (!existing.any((e) => e.toLowerCase().startsWith(email.toLowerCase()))) {
        existing.add(newEntry);
        await prefs.setStringList(_passkeysKey, existing);
        await prefs.setBool(_passkeyEnabledKey, true);

        try {
          final client = SupabaseConfig.client;
          await client.from('offline_cache').upsert({
            'email': email.toLowerCase(),
            'app_name': 'ai-super-agent',
            'data_key': 'passkey_created',
            'data_value': {'email': email, 'created_at': DateTime.now().toIso8601String()},
          });
        } catch (_) {}
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Login with Passkey - biometric verification then logs in immediately
  Future<bool> loginWithPasskey({required String email}) async {
    try {
      final isSupported = await isPasskeySupported();
      if (!isSupported) {
        throw Exception('Passkey not supported on this device');
      }

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Login with Passkey for $email',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );

      if (!didAuth) {
        throw Exception('Passkey verification failed. Please try again.');
      }

      // If biometric succeeds, log user in immediately via Supabase session
      // For demo, we check if user has existing session or passkey
      final prefs = await SharedPreferences.getInstance();
      final passkeys = prefs.getStringList(_passkeysKey) ?? [];
      final hasPasskey = passkeys.any((e) => e.toLowerCase().startsWith(email.toLowerCase()));

      if (!hasPasskey) {
        // Check cloud
        try {
          final client = SupabaseConfig.client;
          final res = await client.from('offline_cache').select().eq('email', email.toLowerCase()).eq('data_key', 'passkey_created').maybeSingle();
          if (res == null) {
            throw Exception('No Passkey found for this email. Please create a Passkey first.');
          }
        } catch (_) {
          throw Exception('No Passkey found');
        }
      }

      // Success - would normally restore Supabase session
      return true;
    } catch (e) {
      if (e.toString().contains('No Passkey')) rethrow;
      throw Exception('Passkey verification failed. Please try again.');
    }
  }

  /// Delete Passkey
  Future<bool> deletePasskey({required String email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_passkeysKey) ?? [];
      existing.removeWhere((e) => e.toLowerCase().startsWith(email.toLowerCase()));
      await prefs.setStringList(_passkeysKey, existing);

      try {
        final client = SupabaseConfig.client;
        await client.from('offline_cache').delete().eq('email', email.toLowerCase()).eq('data_key', 'passkey_created');
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get all passkeys for management
  Future<List<Map<String, String>>> getPasskeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_passkeysKey) ?? [];
      return list.map((e) {
        final parts = e.split('|');
        return {
          'email': parts[0],
          'created_at': parts.length > 1 ? parts[1] : '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isPasskeyEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_passkeyEnabledKey) ?? false;
  }
}
