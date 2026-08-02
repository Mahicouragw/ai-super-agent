import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _loading = false;

  static const _welcome = '👋 Hi! I am your AI Super Agent, just like Arena AI!\n\n'
      'I can:\n📄 Search PDFs\n📰 Give top 5 news\n📱 Build apps\n📊 Create report series\n'
      '🌐 Search web, fetch pages, manage files, generate images...\n\n'
      'All your data is stored safely in Supabase with unique username/email checks and email verification.\n\n'
      'What should I do for you today?';

  @override
  void initState() {
    super.initState();
    _messages = [
      {'role': 'assistant', 'content': _welcome},
    ];
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _controller.clear();
    _scrollToEnd();

    try {
      final historyForApi = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      final reply = await _agent.chat(text, history: historyForApi);
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '⚠️ **I could not reach an AI service just now.**\n\n'
              '• Check your internet connection and try again.\n'
              '• If you set a custom AI key, verify it in the dashboard settings.'
        });
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i >= _messages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      Text('AI is thinking', style: TextStyle(color: Colors.deepPurple, fontSize: 12)),
                    ],
                  ),
                );
              }
              final m = _messages[i];
              final isUser = m['role'] == 'user';
              final bubble = Container(
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
              );
              if (isUser) {
                return Align(alignment: Alignment.centerRight, child: bubble);
              }
              return Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: bubble),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Copy reply',
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: m['content'] ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply copied'), duration: Duration(seconds: 1)));
                      },
                    ),
                  ],
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
        // quick action chips — tap to send instantly
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              ActionChip(
                label: const Text('📄 Search PDFs'),
                onPressed: _loading ? null : () {
                  _controller.text = 'Search my PDFs for ';
                  _send();
                },
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: const Text('📰 Top 5 news'),
                onPressed: _loading ? null : () {
                  _controller.text = 'Give me top 5 news';
                  _send();
                },
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: const Text('📱 Build an app'),
                onPressed: _loading ? null : () {
                  _controller.text = 'Build a todo app with Supabase auth';
                  _send();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
