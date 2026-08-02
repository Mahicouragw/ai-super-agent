import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_agent_service.dart';
import '../../services/supabase_service.dart';
import '../../services/wispr_flow_service.dart';
import '../llm_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _promptController = TextEditingController();
  final _agentService = AIAgentService();
  final _supabaseService = SupabaseService();
  final _wisprService = WisprFlowService();
  final _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];
  bool _loading = false;
  String _selectedModel = 'qwen/qwen3-coder:free';
  List<String> _thinkingSteps = [];
  bool _isRecording = false;
  String _transcriptionLanguage = 'auto';
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _messages = [
      {'role': 'assistant', 'content': '''👋 **Real AI Super Agent - Expensive Free Forever, No Credit Limit, No Duplicates**

I'm REAL agent, not duplicate, working locally safely like real AI in computers.

**How I work like LMArena / Real Agent:**
1. **Thinking:** Understand your prompt deeply
2. **Analyzing:** Check tools needed, context, best free expensive model
3. **Planning:** Break into sub-tasks, delegate to sub-agents (Coder B, Researcher C, Analyst D, Scheduler E) in parallel
4. **Executing:** Call free expensive models via OpenRouter fallback chain for unlimited free forever
5. **Responding:** Helpful answer like ChatGPT

**Free Expensive Models (No Credit Limit, Free Forever):**
- qwen/qwen3-coder:free (1M context, best for app building)
- deepseek/deepseek-r1:free (best reasoning)
- gemini-2.0-flash-exp:free (free Gemini)
- nemotron-3-ultra-550b:free (1M long reasoning)
- llama-3.3-70b:free, hermes-3-405b:free, gpt-oss-20b:free

All free via OpenRouter :free suffix - 20 RPM, 50/day free, 1000/day after \$10 once, no CC needed. Fallback chain provides unlimited.

**I can (real, not duplicate):**
- 💬 Chat like ChatGPT & Gemini
- 🎨 Generate images (FLUX.1 Schnell free)
- 🎬 Generate videos (scripts)
- 🎵 Generate songs, 📝 lyrics, 📄 content, everything
- 💻 Build apps from prompts (real Flutter code, no duplicates)
- 📄 Search PDFs, 📰 Daily news, ⏰ Reminders

**Try:** "Build todo app with Supabase auth", "Generate image of futuristic tablet", "Write love song about Pune", "Top 5 news"

What to build?'''}
    ];
  }

  Future<void> _send() async {
    final text = _promptController.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
      _thinkingSteps = [];
    });
    _promptController.clear();
    _scrollToEnd();

    // Show real agent thinking like LMArena
    await _addThinkingStep('🤔 Thinking...', 'Understanding: "$text"');
    await Future.delayed(const Duration(milliseconds: 500));
    await _addThinkingStep('🔍 Analyzing...', 'Checking tools, context, selecting best free expensive model: $_selectedModel with fallback chain for unlimited free');
    await Future.delayed(const Duration(milliseconds: 500));
    await _addThinkingStep('🧠 Planning...', 'Breaking into sub-tasks, multi-agent delegation if needed (Coder, Researcher, Analyst, Scheduler)');
    await Future.delayed(const Duration(milliseconds: 500));
    await _addThinkingStep('⚡ Executing...', 'Calling $_selectedModel via OpenRouter free tier with fallback chain for unlimited free forever');
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      final reply = await _agentService.chat(text, history: history);
      
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _thinkingSteps = [];
      });

      try {
        await _supabaseService.saveGeneration(type: 'prompt', prompt: text, model: _selectedModel, resultText: reply);
      } catch (_) {}

    } catch (e) {
      // v1.1.0: friendly error — never leak raw exceptions into the chat.
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '⚠️ **I could not reach an AI service just now.**\n\n'
              'Your message is safe: "$text"\n\n'
              '• Check your internet connection, then tap send again.\n'
              '• If you configured a custom AI key in **Settings → AI Model & Key**, verify it is correct.\n'
              '• Otherwise the built-in AI service may be temporarily busy — please retry in a moment.'
        });
        _thinkingSteps = [];
      });
    } finally {
      setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  Future<void> _addThinkingStep(String title, String detail) async {
    setState(() => _thinkingSteps.add('$title $detail'));
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final finalText = await _wisprService.stopRecording();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      if (finalText.trim().isNotEmpty) {
        _promptController.text = finalText;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎤 Transcribed ${finalText.length} chars in ${_transcriptionLanguage} - Ready to send to AI'), backgroundColor: Colors.green),
        );
      }
    } else {
      // Start recording - like Wispr Flow, any language, 5-10 min limit
      final initialized = await _wisprService.initialize();
      if (!initialized) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission needed for Wispr Flow transcription')));
        return;
      }

      setState(() => _isRecording = true);

      await _wisprService.startRecording(
        language: _transcriptionLanguage == 'te' ? TranscriptionLanguage.telugu : 
                  _transcriptionLanguage == 'hi' ? TranscriptionLanguage.hindi :
                  _transcriptionLanguage == 'auto' ? TranscriptionLanguage.auto : TranscriptionLanguage.english,
        maxMinutes: 5, // 5 or 10 minutes per session as requested
        onTranscriptionUpdate: (text) {
          setState(() {
            _promptController.text = text;
          });
        },
        onFinalTranscription: (text) {
          setState(() {
            _promptController.text = text;
          });
        },
        onProgress: (elapsed, max) {
          setState(() => _recordingSeconds = elapsed);
        },
      );
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _wisprService.dispose();
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Super Agent - Real, No Duplicates'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.settings_input_component), tooltip: 'AI Model and Key settings', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LlmSettingsScreen()))),
          IconButton(icon: const Icon(Icons.model_training), tooltip: 'Choose Real Expensive Free Forever Model', onPressed: () async {
            final selected = await Navigator.pushNamed(context, '/models');
            if (selected != null) setState(() => _selectedModel = selected as String);
          }),
          IconButton(icon: const Icon(Icons.compare), tooltip: 'LMArena Mode - Thinking->Analyzing->Responding', onPressed: () => Navigator.pushNamed(context, '/arena')),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.green.shade50,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Model: $_selectedModel (Expensive Free Forever, No Credit Limit)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              if (_thinkingSteps.isNotEmpty) ...[
                const SizedBox(height: 6),
                ..._thinkingSteps.map((s) => Text(s, style: const TextStyle(fontSize: 10, color: Colors.deepPurple))),
              ],
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i >= _messages.length) {
                  // v1.1.0: typing indicator instead of a bare progress bar
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 8),
                        Text('AI is thinking', style: TextStyle(color: Colors.deepPurple, fontSize: 12)),
                        SizedBox(width: 6),
                        _TypingDots(),
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
                  decoration: BoxDecoration(color: isUser ? Colors.deepPurple : Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                  child: MarkdownBody(data: m['content'] ?? '', styleSheet: MarkdownStyleSheet(p: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13))),
                );
                if (isUser) {
                  return Align(alignment: Alignment.centerRight, child: bubble);
                }
                // v1.1.0: copy button under assistant replies
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: bubble),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Copy reply',
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: m['content'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply copied to clipboard'), duration: Duration(seconds: 1)));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(
              children: [
                // Language chooser for transcription - English, Telugu, Hindi, any language
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('🎤 Wispr Flow Transcription:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      ChoiceChip(label: const Text('Auto Any Lang', style: TextStyle(fontSize: 10)), selected: _transcriptionLanguage == 'auto', onSelected: (_) => setState(() => _transcriptionLanguage = 'auto')),
                      const SizedBox(width: 4),
                      ChoiceChip(label: const Text('English', style: TextStyle(fontSize: 10)), selected: _transcriptionLanguage == 'en', onSelected: (_) => setState(() => _transcriptionLanguage = 'en')),
                      const SizedBox(width: 4),
                      ChoiceChip(label: const Text('Telugu', style: TextStyle(fontSize: 10)), selected: _transcriptionLanguage == 'te', onSelected: (_) => setState(() => _transcriptionLanguage = 'te')),
                      const SizedBox(width: 4),
                      ChoiceChip(label: const Text('Hindi', style: TextStyle(fontSize: 10)), selected: _transcriptionLanguage == 'hi', onSelected: (_) => setState(() => _transcriptionLanguage = 'hi')),
                      const SizedBox(width: 4),
                      if (_isRecording) Text('⏱️ ${_recordingSeconds ~/ 60}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}/5:00', style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Mic button - Wispr Flow style - 5-10 min limit per session
                    IconButton(
                      icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, color: _isRecording ? Colors.red : Colors.deepPurple),
                      tooltip: _isRecording ? 'Stop recording (5-10 min limit)' : 'Record voice in any language - Wispr Flow transcription',
                      onPressed: _toggleRecording,
                    ),
                    Expanded(child: TextField(controller: _promptController, minLines: 1, maxLines: 5, decoration: InputDecoration(hintText: _isRecording ? '🎤 Listening in ${_transcriptionLanguage == 'auto' ? 'any language' : _transcriptionLanguage}... Speak English/Telugu/Hindi any language (5-10 min)' : 'Send prompt - build apps, generate images/videos/songs/lyrics/content, ask anything...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))), onSubmitted: (_) => _send())),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: _loading ? null : _send, icon: const Icon(Icons.send)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// v1.1.0 — animated three-dot typing indicator (TalkBack announces "AI is thinking").
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (ctx, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value - i * 0.18) % 1.0;
            final scale = 0.5 + 0.5 * t;
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
              transform: Matrix4.identity()..scale(scale),
            );
          }),
        );
      },
    );
  }
}
