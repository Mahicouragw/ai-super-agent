import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

/// Device Accounts Service - Continue with AI Super Agent
/// Shows accounts created on this device, saved in server, cloud storage, local storage
/// Like Google account chooser but branded as AI Super Agent
class DeviceAccountsService {
  static const String _localAccountsKey = 'device_accounts';
  static const String _lastUsedKey = 'last_used_account';

  /// Get accounts created on this device (local storage)
  Future<List<Map<String, String>>> getLocalAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getStringList(_localAccountsKey) ?? [];
      return accountsJson.map((jsonStr) {
        final parts = jsonStr.split('|');
        return {
          'email': parts[0],
          'name': parts.length > 1 ? parts[1] : parts[0].split('@')[0],
          'avatar': parts.length > 2 ? parts[2] : '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get accounts from server/cloud (Supabase profiles + offline_cache)
  Future<List<Map<String, String>>> getCloudAccounts() async {
    try {
      final client = SupabaseConfig.client;
      final res = await client.from('profiles').select('email, name, username').limit(20);
      return List<Map<String, dynamic>>.from(res).map((p) => {
        'email': p['email'] as String? ?? '',
        'name': p['name'] as String? ?? p['username'] as String? ?? '',
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get all accounts (local + cloud) deduplicated - for Continue with AI Super Agent chooser
  Future<List<Map<String, String>>> getAllDeviceAccounts() async {
    final local = await getLocalAccounts();
    final cloud = await getCloudAccounts();
    
    // Merge and deduplicate by email
    final Map<String, Map<String, String>> merged = {};
    for (var acc in [...local, ...cloud]) {
      final email = acc['email']?.toLowerCase() ?? '';
      if (email.isNotEmpty && email.contains('@')) {
        merged[email] = acc;
      }
    }
    
    return merged.values.toList();
  }

  /// Save account to local + cloud + server when created
  Future<void> saveAccount({required String email, required String name}) async {
    try {
      // Local storage
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_localAccountsKey) ?? [];
      final newEntry = '$email|$name|';
      // Remove if already exists
      existing.removeWhere((e) => e.toLowerCase().startsWith(email.toLowerCase()));
      existing.insert(0, newEntry); // Most recent first
      // Keep only last 10 accounts
      if (existing.length > 10) {
        existing.removeRange(10, existing.length);
      }
      await prefs.setStringList(_localAccountsKey, existing);
      await prefs.setString(_lastUsedKey, email);

      // Cloud storage - Supabase offline_cache for remote sync without reinstall
      try {
        final client = SupabaseConfig.client;
        await client.from('offline_cache').upsert({
          'email': email.toLowerCase(),
          'app_name': 'ai-super-agent',
          'data_key': 'device_account',
          'data_value': {'email': email, 'name': name, 'saved_at': DateTime.now().toIso8601String()},
        });
      } catch (_) {}

      // Server - profiles already saved via Supabase Auth trigger handle_new_user()
      
    } catch (e) {
      print('Save account error: $e');
    }
  }

  /// Get last used account for quick login
  Future<Map<String, String>?> getLastUsedAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastEmail = prefs.getString(_lastUsedKey);
      if (lastEmail != null) {
        final accounts = await getAllDeviceAccounts();
        return accounts.firstWhere((acc) => acc['email']?.toLowerCase() == lastEmail.toLowerCase(), orElse: () => {'email': lastEmail, 'name': lastEmail.split('@')[0]});
      }
    } catch (_) {}
    return null;
  }

  /// Clear all accounts (for testing)
  Future<void> clearAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localAccountsKey);
    await prefs.remove(_lastUsedKey);
  }
}
