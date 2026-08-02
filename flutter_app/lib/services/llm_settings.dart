import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AI Super Agent — configurable LLM integration (v1.1.0)
///
/// Lets the user pick their own provider at runtime:
///   - "edge"     → Supabase Edge Function (default, no key needed)
///   - "openrouter" → any OpenRouter model (free :free models or paid)
///   - "custom"   → any OpenAI-compatible API (base URL + model + key)
///
/// The API key is stored ONLY in the platform keystore
/// (flutter_secure_storage), never in plain text or in the repo.
class LlmSettings {
  final String provider; // edge | openrouter | custom
  final String baseUrl; // e.g. https://openrouter.ai/api/v1 (custom providers override)
  final String model;
  final String apiKey;
  final bool enabled;

  const LlmSettings({
    this.provider = 'edge',
    this.baseUrl = 'https://openrouter.ai/api/v1',
    this.model = '',
    this.apiKey = '',
    this.enabled = false,
  });

  bool get isDirect => enabled && provider != 'edge' && apiKey.isNotEmpty;

  String get effectiveModel => model.trim().isNotEmpty ? model.trim() : '';

  LlmSettings copyWith({
    String? provider,
    String? baseUrl,
    String? model,
    String? apiKey,
    bool? enabled,
  }) {
    return LlmSettings(
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, String> toJson() => {
        'provider': provider,
        'baseUrl': baseUrl,
        'model': model,
        'enabled': enabled ? 'true' : 'false',
        // apiKey deliberately NOT persisted here as plain JSON; stored separately
      };
}

class LlmSettingsService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _kProvider = 'llm_provider';
  static const _kBaseUrl = 'llm_base_url';
  static const _kModel = 'llm_model';
  static const _kApiKey = 'llm_api_key';
  static const _kEnabled = 'llm_enabled';

  static Future<LlmSettings> load() async {
    try {
      final provider = await _storage.read(key: _kProvider) ?? 'edge';
      final baseUrl = await _storage.read(key: _kBaseUrl) ?? 'https://openrouter.ai/api/v1';
      final model = await _storage.read(key: _kModel) ?? '';
      final apiKey = await _storage.read(key: _kApiKey) ?? '';
      final enabled = await _storage.read(key: _kEnabled) == 'true';
      return LlmSettings(provider: provider, baseUrl: baseUrl, model: model, apiKey: apiKey, enabled: enabled);
    } catch (_) {
      return const LlmSettings();
    }
  }

  static Future<void> save(LlmSettings s) async {
    try {
      await _storage.write(key: _kProvider, value: s.provider);
      await _storage.write(key: _kBaseUrl, value: s.baseUrl);
      await _storage.write(key: _kModel, value: s.model);
      await _storage.write(key: _kApiKey, value: s.apiKey);
      await _storage.write(key: _kEnabled, value: s.enabled ? 'true' : 'false');
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _kProvider);
      await _storage.delete(key: _kBaseUrl);
      await _storage.delete(key: _kModel);
      await _storage.delete(key: _kApiKey);
      await _storage.delete(key: _kEnabled);
    } catch (_) {}
  }
}
