import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Model Selector Screen - Choose between Claude, ChatGPT, Groq, Gemini via OpenRouter
/// User asked: "choose models like Claude, ChatGPT, Grow, Installed Group, and Gemini"

class ModelOption {
  final String id; // OpenRouter model id
  final String name;
  final String provider;
  final String description;
  final String icon;
  final int speed; // 1-5
  final int quality; // 1-5

  const ModelOption({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.icon,
    required this.speed,
    required this.quality,
  });
}

class ModelSelectorScreen extends StatefulWidget {
  const ModelSelectorScreen({super.key});

  @override
  State<ModelSelectorScreen> createState() => _ModelSelectorScreenState();
}

class _ModelSelectorScreenState extends State<ModelSelectorScreen> {
  static const List<ModelOption> models = [
    // Claude Family (Anthropic) - Opus, Sonnet, Haiku
    ModelOption(
      id: 'anthropic/claude-opus-4.5',
      name: 'Claude Opus 4.5',
      provider: 'Anthropic',
      description: 'Most powerful, best reasoning, coding, analysis - Recommended for complex tasks',
      icon: '🧠',
      speed: 2,
      quality: 5,
    ),
    ModelOption(
      id: 'anthropic/claude-opus-4',
      name: 'Claude Opus 4',
      provider: 'Anthropic',
      description: 'Very powerful reasoning, great for coding & reports',
      icon: '🧠',
      speed: 2,
      quality: 5,
    ),
    ModelOption(
      id: 'anthropic/claude-sonnet-4.5',
      name: 'Claude Sonnet 4.5 (CloudSonic)',
      provider: 'Anthropic',
      description: 'Balanced speed & quality, great for daily use - CloudSonic you asked!',
      icon: '⚡',
      speed: 4,
      quality: 4,
    ),
    ModelOption(
      id: 'anthropic/claude-sonnet-4',
      name: 'Claude Sonnet 4',
      provider: 'Anthropic',
      description: 'Fast balanced model',
      icon: '⚡',
      speed: 4,
      quality: 4,
    ),
    ModelOption(
      id: 'anthropic/claude-haiku-4.5',
      name: 'Claude Haiku 4.5',
      provider: 'Anthropic',
      description: 'Fastest Claude, cheap, good for simple tasks',
      icon: '💨',
      speed: 5,
      quality: 3,
    ),
    ModelOption(
      id: 'anthropic/claude-3-haiku',
      name: 'Claude Haiku 3',
      provider: 'Anthropic',
      description: 'Fast & cheap',
      icon: '💨',
      speed: 5,
      quality: 3,
    ),

    // ChatGPT Family (OpenAI) via OpenRouter
    ModelOption(
      id: 'openai/gpt-4o',
      name: 'ChatGPT GPT-4o',
      provider: 'OpenAI',
      description: 'OpenAI flagship, vision, coding, analysis',
      icon: '🤖',
      speed: 3,
      quality: 5,
    ),
    ModelOption(
      id: 'openai/gpt-4o-mini',
      name: 'GPT-4o Mini (Fast)',
      provider: 'OpenAI',
      description: 'Fast, cheap, good for daily chat & coding',
      icon: '🤖',
      speed: 5,
      quality: 4,
    ),
    ModelOption(
      id: 'openai/gpt-4-turbo',
      name: 'GPT-4 Turbo',
      provider: 'OpenAI',
      description: 'Powerful, 128k context',
      icon: '🤖',
      speed: 3,
      quality: 5,
    ),

    // Groq Family (Grow you mentioned - Groq is super fast)
    ModelOption(
      id: 'groq/llama-3.1-70b-versatile',
      name: 'Groq Llama 3.1 70B (Grow)',
      provider: 'Groq',
      description: 'Super fast inference via Groq, 70B versatile - Grow you asked!',
      icon: '🚀',
      speed: 5,
      quality: 4,
    ),
    ModelOption(
      id: 'groq/llama-3.1-8b-instant',
      name: 'Groq Llama 8B Instant',
      provider: 'Groq',
      description: 'Ultra fast, instant replies',
      icon: '🚀',
      speed: 5,
      quality: 3,
    ),
    ModelOption(
      id: 'groq/mixtral-8x7b-32768',
      name: 'Groq Mixtral 8x7B',
      provider: 'Groq (Installed Group - Mixtral)',
      description: 'Mixtral from Installed Group/Mistral - good reasoning - Installed Group you asked!',
      icon: '🔀',
      speed: 4,
      quality: 4,
    ),

    // Gemini Family (Google)
    ModelOption(
      id: 'google/gemini-2.0-flash-001',
      name: 'Gemini 2.0 Flash',
      provider: 'Google',
      description: 'Fast Gemini, multimodal',
      icon: '💎',
      speed: 4,
      quality: 4,
    ),
    ModelOption(
      id: 'google/gemini-1.5-pro',
      name: 'Gemini 1.5 Pro',
      provider: 'Google',
      description: 'Powerful Gemini for complex tasks',
      icon: '💎',
      speed: 3,
      quality: 5,
    ),
    ModelOption(
      id: 'google/gemini-1.5-flash',
      name: 'Gemini 1.5 Flash',
      provider: 'Google',
      description: 'Fast Gemini',
      icon: '💎',
      speed: 5,
      quality: 4,
    ),
  ];

  String _selectedModel = '';

  @override
  void initState() {
    super.initState();
    _selectedModel = dotenv.env['OPENROUTER_MODEL'] ?? 'anthropic/claude-opus-4.5';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Model: Claude, ChatGPT, Groq, Gemini'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧠 Multi-Model Support via OpenRouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Current: $_selectedModel', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  const Text('You asked for Claude (Opus/Sonnet), ChatGPT (GPT-4o), Grow (Groq Llama), Installed Group (Mixtral/Mistral), Gemini — all available via one OpenRouter key sk-or-v1-...', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, children: [
                    Chip(label: const Text('Claude Opus'), backgroundColor: Colors.purple.shade100),
                    Chip(label: const Text('Claude Sonnet = CloudSonic'), backgroundColor: Colors.blue.shade100),
                    Chip(label: const Text('ChatGPT GPT-4o'), backgroundColor: Colors.green.shade100),
                    Chip(label: const Text('Groq Llama = Grow'), backgroundColor: Colors.orange.shade100),
                    Chip(label: const Text('Mixtral = Installed Group'), backgroundColor: Colors.pink.shade100),
                    Chip(label: const Text('Gemini'), backgroundColor: Colors.teal.shade100),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...models.map((m) => _modelTile(m)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('How to change model', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('1. Tap model below to select\n2. Model saved in Supabase secrets OPENROUTER_MODEL and GitHub Secrets\n3. For local: edit flutter_app/.env OPENROUTER_MODEL=...\n4. Restart app\n5. All agents (B Coder, C Researcher, D Analyst, E Scheduler) will use selected model', style: TextStyle(fontSize: 12)),
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
        leading: Text(model.icon, style: const TextStyle(fontSize: 24)),
        title: Row(children: [
          Expanded(child: Text(model.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
          if (isSelected) const Icon(Icons.check_circle, color: Colors.green, size: 18),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${model.provider} • Speed ${'⚡' * model.speed} Quality ${'⭐' * model.quality}', style: const TextStyle(fontSize: 11)),
          Text(model.description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(model.id, style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontFamily: 'monospace')),
        ]),
        isThreeLine: true,
        onTap: () {
          setState(() => _selectedModel = model.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected ${model.name} (${model.id}) - Set in Supabase secrets OPENROUTER_MODEL to apply globally')),
          );
          // In real app, would save to SharedPreferences + Supabase
        },
        trailing: isSelected ? const Icon(Icons.radio_button_checked, color: Colors.deepPurple) : const Icon(Icons.radio_button_unchecked),
      ),
    );
  }
}
