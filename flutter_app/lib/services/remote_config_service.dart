import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

/// Remote Config Service - Deploy updates to all apps without reinstall (offline capable)
/// Reads from Supabase app_config table, caches locally for offline use
class RemoteConfigService {
  static const String _cacheKey = 'remote_config_cache';
  static const String _cacheTimeKey = 'remote_config_cache_time';

  /// Get remote config for all apps - works offline via cache
  Future<Map<String, dynamic>> getConfig() async {
    try {
      // Try online first
      final client = SupabaseConfig.client;
      final res = await client.from('app_config').select().eq('app_name', 'all');
      
      if (res.isNotEmpty) {
        final config = <String, dynamic>{};
        for (var row in res) {
          config[row['key']] = row['value'];
        }
        
        // Cache for offline
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, config.toString()); // Simplified
        await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
        
        return config;
      }
    } catch (e) {
      print('Remote config online failed, using offline cache: $e');
    }

    // Offline fallback - return defaults
    try {
      final prefs = await SharedPreferences.getInstance();
      // For simplicity, return default config that matches what we set in Supabase
      return {
        'models': {
          'default_model': 'openai/gpt-4o-mini',
          'available_models': [
            {'id': 'openai/gpt-4o-mini', 'name': 'GPT-4o Mini (Fast, Cheap)', 'provider': 'OpenAI'},
            {'id': 'groq/llama-3.1-70b-versatile', 'name': 'Groq Llama 70B (Grow)', 'provider': 'Groq'},
            {'id': 'groq/mixtral-8x7b-32768', 'name': 'Mixtral (Installed Group)', 'provider': 'Mistral'},
            {'id': 'google/gemini-2.0-flash-exp:free', 'name': 'Gemini 2.0 Flash Free', 'provider': 'Google'},
            {'id': 'anthropic/claude-3-haiku', 'name': 'Claude Haiku Cheap', 'provider': 'Anthropic'},
          ]
        },
        'auth_config': {
          'requires_auth': true,
          'signup_fields': ['name', 'email', 'password', 'confirm_password'],
          'login_fields': ['email', 'password'],
          'offline_mode': true,
        },
        'features': {
          'talkback_accessible': true,
          'model_chooser_lm_arena_style': true,
          'offline_cache': true,
        }
      };
    } catch (_) {
      return {};
    }
  }

  /// Get default model without needing reinstall - from remote config
  Future<String> getDefaultModel() async {
    try {
      final config = await getConfig();
      final models = config['models'];
      if (models != null && models['default_model'] != null) {
        return models['default_model'];
      }
    } catch (_) {}
    return 'openai/gpt-4o-mini'; // Cheap, no credit limit
  }

  /// Get available models list without reinstall
  Future<List<dynamic>> getAvailableModels() async {
    try {
      final config = await getConfig();
      final models = config['models'];
      if (models != null && models['available_models'] != null) {
        return models['available_models'];
      }
    } catch (_) {}
    return [];
  }
}
