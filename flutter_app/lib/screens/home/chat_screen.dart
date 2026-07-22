import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_agent_service.dart';
import '../../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _agent = AIAgentService();
  final _supabaseService = SupabaseService();
  List<Map<String, String>> _messages = []; // role, content
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _messages = [
      {'role': 'assistant', 'content': '👋 Hi! I am your AI Super Agent, just like Arena AI!\n\nI can:\n📄 Search PDFs\n📰 Give top 5 news\n📱 Build apps\n📊 Create report series\n🌐 Search web, fetch pages, manage files, generate images...\n\nAll your data is stored safely in Supabase with unique username/email checks and email verification.\n\nWhat should I do for you today?'}
    ];
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _supabaseService.getChatHistory();
      if (history.isNotEmpty && mounted) {
        setState(() {
          _messages = history.map<Map<String, String>>((h) => {
            'role': h['role'] as String,
            'content': h['content'] as String,
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _controller.clear();

    try {
      final historyForApi = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      final reply = await _agent.chat(text, history: historyForApi);
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: $e'});
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (ctx, i) {
              final m = _messages[i];
              final isUser = m['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.deepPurple : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: MarkdownBody(
                    data: m['content'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14),
                      code: TextStyle(backgroundColor: Colors.black12, color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Ask: search PDFs, top 5 news, build app, create report...', border: OutlineInputBorder()),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _loading ? null : _send, icon: const Icon(Icons.send)),
            ],
          ),
        ),
        // quick action chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _chip('Search PDFs'),
              _chip('Give top 5 news to me'),
              _chip('Build a todo app'),
              _chip('Create weekly report series'),
              _chip('How do you build apps?'),
            ],
          ),
        )
      ],
    );
  }

  Widget _chip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(label: Text(text), onPressed: () {
        _controller.text = text;
        _send();
      }),
    );
  }
}
