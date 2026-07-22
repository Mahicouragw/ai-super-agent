import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../services/ai_agent_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _service = SupabaseService();
  final _agent = AIAgentService();
  String _output = '';
  bool _loading = false;

  Future<void> _create() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final aiRes = await _agent.chat('Create report series: Title: ${_titleCtrl.text}, Details: ${_promptCtrl.text}');
      setState(() => _output = aiRes);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('📊 Report Series - AI Skill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('How I create reports: template -> data fetch -> markdown -> charts -> save to Supabase', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Report Title', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _promptCtrl, decoration: const InputDecoration(labelText: 'Report details / goals', border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: _loading ? null : _create, icon: const Icon(Icons.analytics), label: const Text('Create Report Series')),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: SelectableText(_output))),
        ],
      ),
    );
  }
}
