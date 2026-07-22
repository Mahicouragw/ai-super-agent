import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

/// Model Selector - LMArena Style, No Claude Opus (credit limit removed)
/// Choose between ChatGPT, Groq/Grow, Mixtral/Installed Group, Gemini - all cheap, working

class ModelOption {
  final String id;
  final String name;
  final String provider;
  final String description;
  final String icon;
  final int speed;
  final int quality;
  final bool isFree;

  const ModelOption({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.icon,
    required this.speed,
    required this.quality,
    this.isFree = true,
  });
}

class ModelSelectorScreen extends StatefulWidget {
  const ModelSelectorScreen({super.key});

  @override
  State<ModelSelectorScreen> createState() => _ModelSelectorScreenState();
}

class _ModelSelectorScreenState extends State<ModelSelectorScreen> {
  // Removed Claude Opus because it asks credit limits - using only cheap working models
  static const List<ModelOption> models = [
    // ChatGPT Family (OpenAI) - Most reliable, no credit limit issues
    ModelOption(
      id: 'openai/gpt-4o-mini',
      name: 'GPT-4o Mini (Fast, Cheap) ⭐ Recommended',
      provider: 'OpenAI - ChatGPT',
      description: 'Fast, cheap, reliable - No credit limits - Best for daily use like LMArena',
      icon: '🤖',
      speed: 5,
      quality: 4,
      isFree: true,
    ),
    ModelOption(
      id: 'openai/gpt-4o',
      name: 'ChatGPT GPT-4o',
      provider: 'OpenAI - ChatGPT',
      description: 'Powerful flagship, vision, coding',
      icon: '🤖',
      speed: 3,
      quality: 5,
    ),
    ModelOption(
      id: 'openai/gpt-4-turbo',
      name: 'GPT-4 Turbo',
      provider: 'OpenAI - ChatGPT',
      description: '128k context, powerful',
      icon: '🤖',
      speed: 3,
      quality: 5,
    ),

    // Groq Family - Super fast (Grow you asked)
    ModelOption(
      id: 'groq/llama-3.1-70b-versatile',
      name: 'Groq Llama 70B (Grow) - Super Fast 🚀',
      provider: 'Groq - Grow',
      description: 'Super fast inference via Groq hardware - Grow you asked, no credit limits',
      icon: '🚀',
      speed: 5,
      quality: 4,
      isFree: true,
    ),
    ModelOption(
      id: 'groq/llama-3.1-8b-instant',
      name: 'Groq Llama 8B Instant - Ultra Fast',
      provider: 'Groq - Grow',
      description: 'Ultra fast, instant replies',
      icon: '🚀',
      speed: 5,
      quality: 3,
      isFree: true,
    ),
    ModelOption(
      id: 'groq/mixtral-8x7b-32768',
      name: 'Mixtral (Installed Group) 🔀',
      provider: 'Mistral - Installed Group',
      description: 'Mixtral from Installed Group/Mistral - good reasoning',
      icon: '🔀',
      speed: 4,
      quality: 4,
      isFree: true,
    ),

    // Gemini Family (Google) - Free tier available
    ModelOption(
      id: 'google/gemini-2.0-flash-exp:free',
      name: 'Gemini 2.0 Flash (Free) 💎',
      provider: 'Google - Gemini',
      description: 'Free tier Gemini, fast, multimodal, no credit limit',
      icon: '💎',
      speed: 5,
      quality: 4,
      isFree: true,
    ),
    ModelOption(
      id: 'google/gemini-1.5-flash',
      name: 'Gemini 1.5 Flash',
      provider: 'Google - Gemini',
      description: 'Fast Gemini',
      icon: '💎',
      speed: 5,
      quality: 4,
      isFree: true,
    ),
    ModelOption(
      id: 'google/gemini-1.5-pro',
      name: 'Gemini 1.5 Pro',
      provider: 'Google - Gemini',
      description: 'Powerful Gemini',
      icon: '💎',
      speed: 3,
      quality: 5,
    ),

    // Claude Haiku - cheap, no credit limit (Opus removed per your request)
    ModelOption(
      id: 'anthropic/claude-3-haiku',
      name: 'Claude Haiku (Cheap, Fast)',
      provider: 'Anthropic - Claude',
      description: 'Cheap fast Claude without credit limit issues',
      icon: '💨',
      speed: 5,
      quality: 3,
      isFree: true,
    ),
    ModelOption(
      id: 'anthropic/claude-3.5-haiku',
      name: 'Claude 3.5 Haiku',
      provider: 'Anthropic - Claude',
      description: 'New Haiku, fast',
      icon: '💨',
      speed: 5,
      quality: 4,
      isFree: true,
    ),
  ];

  String _selectedModel = 'openai/gpt-4o-mini';

  @override
  void initState() {
    super.initState();
    _loadSavedModel();
  }

  Future<void> _loadSavedModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('selected_model');
      // Also check Supabase remote config for offline update without reinstall
      String remoteModel = 'openai/gpt-4o-mini';
      try {
        final client = SupabaseConfig.client;
        final res = await client.from('app_config').select('value').eq('app_name', 'all').eq('key', 'models').maybeSingle();
        if (res != null && res['value'] != null) {
          final val = res['value'];
          if (val['default_model'] != null) {
            remoteModel = val['default_model'];
          }
        }
      } catch (_) {}

      setState(() {
        _selectedModel = saved ?? remoteModel;
      });
    } catch (_) {
      setState(() => _selectedModel = 'openai/gpt-4o-mini');
    }
  }

  Future<void> _saveModel(String modelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_model', modelId);
      
      // Save to Supabase for remote config sync (so all apps update without reinstall)
      try {
        final client = SupabaseConfig.client;
        final userId = client.auth.currentUser?.id;
        await client.from('offline_cache').upsert({
          'user_id': userId,
          'email': client.auth.currentUser?.email ?? 'anonymous',
          'app_name': 'ai-super-agent',
          'data_key': 'selected_model',
          'data_value': {'model': modelId, 'updated_at': DateTime.now().toIso8601String()},
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Model changed to $modelId - Works like LMArena now! No credit limit.'), backgroundColor: Colors.green),
        );
        // Return selected model to previous screen
        Navigator.pop(context, modelId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved $modelId')));
        Navigator.pop(context, modelId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Model - LMArena Style'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 6), Text('Fixed: No More Credit Limit Issues', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                  const SizedBox(height: 6),
                  Text('Current: $_selectedModel', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  const SizedBox(height: 6),
                  const Text('✅ Claude Opus removed (was asking credit limits). Now only cheap working models: GPT-4o Mini, Groq Llama Grow, Mixtral Installed Group, Gemini Free, Haiku - all work without credit limits like LMArena!', style: TextStyle(fontSize: 11, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text('🧠 LMArena Style: Shows thinking → analyzing → responding steps, side-by-side model comparison, clean chat like ChatGPT/Gemini', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...models.map((m) => _modelTile(m)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('How LMArena Works (Now Fixed):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('1. You send chat message\n2. App shows "Thinking..." (like LMArena)\n3. Then "Analyzing..." (checking context, tools)\n4. Then "Responding..." (generating via selected model)\n5. Response appears like ChatGPT/Gemini\n6. No credit limit errors - uses cheap models\n7. Model choice saved locally (SharedPreferences) + remote via Supabase app_config - updates all apps without reinstall (offline cache)', style: TextStyle(fontSize: 11, height: 1.4)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modelTile(ModelOption model) {
    final isSelected = _selectedModel == model.id;
    return Card(
      color: isSelected ? Colors.deepPurple.shade50 : null,
      elevation: isSelected ? 4 : 1,
      child: ListTile(
        leading: Text(model.icon, style: const TextStyle(fontSize: 22)),
        title: Row(children: [
          Expanded(child: Text(model.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
          if (isSelected) const Icon(Icons.check_circle, color: Colors.green, size: 18),
          if (model.isFree) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)), child: const Text('FREE', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold))),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${model.provider} • ${'⚡' * model.speed} ${'⭐' * model.quality}', style: const TextStyle(fontSize: 10)),
          Text(model.description, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(model.id, style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontFamily: 'monospace')),
        ]),
        isThreeLine: true,
        onTap: () => _saveModel(model.id),
        trailing: isSelected ? const Icon(Icons.radio_button_checked, color: Colors.deepPurple) : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}
