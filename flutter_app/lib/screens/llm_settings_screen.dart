import 'package:flutter/material.dart';
import '../../services/llm_settings.dart';

/// AI Super Agent — AI Model & Key settings (v1.1.0)
///
/// Configure your own LLM at runtime:
///  - Edge (default): Supabase edge function, works out of the box.
///  - OpenRouter: pick a model + paste an OpenRouter key (sk-or-v1-...).
///  - Custom: any OpenAI-compatible endpoint (base URL + model + key).
/// Keys are stored in the Android Keystore via flutter_secure_storage.
class LlmSettingsScreen extends StatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  State<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends State<LlmSettingsScreen> {
  late String _provider;
  late TextEditingController _baseUrl;
  late TextEditingController _model;
  late TextEditingController _apiKey;
  bool _enabled = false;
  bool _obscureKey = true;
  bool _saving = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _provider = 'edge';
    _baseUrl = TextEditingController(text: 'https://openrouter.ai/api/v1');
    _model = TextEditingController();
    _apiKey = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await LlmSettingsService.load();
    if (!mounted) return;
    setState(() {
      _provider = s.provider;
      _baseUrl.text = s.baseUrl;
      _model.text = s.model;
      _apiKey.text = s.apiKey;
      _enabled = s.enabled;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final s = LlmSettings(
      provider: _provider,
      baseUrl: _baseUrl.text.trim().isEmpty ? 'https://openrouter.ai/api/v1' : _baseUrl.text.trim(),
      model: _model.text.trim(),
      apiKey: _apiKey.text.trim(),
      enabled: _enabled,
    );
    await LlmSettingsService.save(s);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _status = s.isDirect
          ? '✅ Saved — AI responses now use ${s.provider} / ${s.effectiveModel}'
          : '✅ Saved — using the built-in AI service (Edge).';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.isDirect ? 'AI provider configured: ${s.effectiveModel}' : 'Using built-in Edge AI'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDirect = _provider != 'edge';
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model & Key'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Where should AI responses come from?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Your key is stored only on this device (Android Keystore). '
                    'Nothing is sent anywhere except to the provider you choose.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    title: const Text('Built-in (Edge) — no key needed'),
                    subtitle: const Text('Supabase edge function, works out of the box'),
                    value: 'edge',
                    groupValue: _provider,
                    onChanged: (v) => setState(() => _provider = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('OpenRouter — any model'),
                    subtitle: const Text('Free :free models or paid. Paste your sk-or-v1 key.'),
                    value: 'openrouter',
                    groupValue: _provider,
                    onChanged: (v) => setState(() => _provider = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Custom — OpenAI-compatible API'),
                    subtitle: const Text('Any provider: base URL + model + key'),
                    value: 'custom',
                    groupValue: _provider,
                    onChanged: (v) => setState(() => _provider = v!),
                  ),
                ],
              ),
            ),
          ),
          if (isDirect) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _baseUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://openrouter.ai/api/v1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _model,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'anthropic/claude-opus-4.5 or qwen/qwen3-coder:free',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKey,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                  tooltip: _obscureKey ? 'Show key' : 'Hide key',
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use my AI configuration'),
            subtitle: Text(isDirect
                ? 'Chat will call ${_provider == 'openrouter' ? 'OpenRouter' : 'your custom endpoint'}'
                : 'Chat uses the built-in AI service'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: 12),
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_status, style: const TextStyle(color: Colors.green, fontSize: 12)),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(_saving ? 'Saving…' : 'Save settings'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  await LlmSettingsService.clear();
                  if (!mounted) return;
                  setState(() {
                    _provider = 'edge';
                    _baseUrl.text = 'https://openrouter.ai/api/v1';
                    _model.clear();
                    _apiKey.clear();
                    _enabled = false;
                    _status = 'Cleared — back to built-in AI.';
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tips:\n'
            '• OpenRouter free models end with :free (e.g. qwen/qwen3-coder:free).\n'
            '• Gemini works via OpenRouter too: google/gemini-2.0-flash-exp:free\n'
            '• For a custom endpoint, the app calls <base URL>/chat/completions.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
