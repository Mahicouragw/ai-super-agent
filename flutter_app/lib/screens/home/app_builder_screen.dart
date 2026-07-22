import 'package:flutter/material.dart';
import '../../services/ai_agent_service.dart';

class AppBuilderScreen extends StatefulWidget {
  const AppBuilderScreen({super.key});

  @override
  State<AppBuilderScreen> createState() => _AppBuilderScreenState();
}

class _AppBuilderScreenState extends State<AppBuilderScreen> {
  final _promptCtrl = TextEditingController();
  String _result = '';
  bool _loading = false;
  final _agent = AIAgentService();

  Future<void> _build() async {
    if (_promptCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final res = await _agent.chat('Build app: ${_promptCtrl.text}');
    setState(() { _result = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('📱 App Builder - AI Skill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('How I build apps: scaffold -> models -> services -> UI -> Supabase -> APK', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(controller: _promptCtrl, decoration: const InputDecoration(labelText: 'Describe app to build (e.g., todo with Supabase)', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _loading ? null : _build, icon: const Icon(Icons.build), label: const Text('Generate Flutter App Code')),
          if (_loading) const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          Expanded(child: SingleChildScrollView(child: SelectableText(_result))),
        ],
      ),
    );
  }
}
