import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Encrypt sensitive local data - Security requirement
/// Uses flutter_secure_storage which uses Android Keystore
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  static const String _keyUserSession = 'user_session_encrypted';
  static const String _keyUserEmail = 'user_email_encrypted';
  static const String _keyDeviceAccounts = 'device_accounts_encrypted';
  static const String _keyLongTermMemory = 'long_term_memory_enabled';


  Future<void> saveUserSession(String sessionJson) async {
    try {
      await _storage.write(key: _keyUserSession, value: sessionJson);
    } catch (_) {}
  }

  Future<String?> getUserSession() async {
    try {
      return await _storage.read(key: _keyUserSession);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: _keyUserEmail, value: email);
    } catch (_) {}
  }

  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _keyUserEmail);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDeviceAccounts(List<String> accounts) async {
    try {
      final jsonStr = jsonEncode(accounts);
      await _storage.write(key: _keyDeviceAccounts, value: jsonStr);
    } catch (_) {}
  }

  Future<List<String>> getDeviceAccounts() async {
    try {
      final jsonStr = await _storage.read(key: _keyDeviceAccounts);
      if (jsonStr == null) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveLongTermMemoryEnabled(bool enabled) async {
    try {
      await _storage.write(key: _keyLongTermMemory, value: enabled.toString());
    } catch (_) {}
  }

  Future<bool> isLongTermMemoryEnabled() async {
    try {
      final val = await _storage.read(key: _keyLongTermMemory);
      return val == 'true' || val == null; // Default enabled
    } catch (_) {
      return true;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  // Validate user input - Security requirement
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidName(String name) {
    return name.trim().length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim());
  }

  static bool isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  static String sanitizeInput(String input) {
    // Remove potential injection, trim
    return input.trim().replaceAll(RegExp(r'[<>]'), '');
  }
}
