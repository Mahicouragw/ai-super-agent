import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_agent_service.dart';
import '../../services/supabase_service.dart';
import '../../services/multi_agent_service.dart';
import '../model_selector_screen.dart';
import '../../services/skills_registry.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _promptController = TextEditingController();
  final _agentService = AIAgentService();
  final _multiAgentService = MultiAgentService();
  final _supabaseService = SupabaseService();
  final _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];
  bool _loading = false;
  String _selectedModel = 'anthropic/claude-opus-4.5';
  String _selectedMode = 'chat'; // chat, image, video, song, lyrics, content

  final List<Map<String, String>> _modes = [
    {'id': 'chat', 'label': '💬 Chat', 'hint': 'Ask anything...'},
    {'id': 'image', 'label': '🎨 Image', 'hint': 'Describe image to generate...'},
    {'id': 'video', 'label': '🎬 Video', 'hint': 'Describe video to generate...'},
    {'id': 'song', 'label': '🎵 Song', 'hint': 'Describe song + lyrics + style...'},
    {'id': 'lyrics', 'label': '📝 Lyrics', 'hint': 'Write lyrics about...'},
    {'id': 'content', 'label': '📄 Content', 'hint': 'Create content about...'},
    {'id': 'code', 'label': '💻 Code', 'hint': 'Build app/code for...'},
    {'id': 'news', 'label': '📰 News', 'hint': 'Top 5 news about...'},
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'role': 'assistant',
        'content': '''👋 Welcome to **AI Super Agent Dashboard**!

**From AI Super Agent (not Supabase) - Real OTP verified like Gmail!**

I can do everything:
- 💬 Chat like ChatGPT & Gemini
- 🎨 Generate images, 🎬 videos, 🎵 songs, 📝 lyrics, 📄 content, 💻 code
- 📄 Search PDFs, 📰 Daily news & newspapers, 📱 Build apps, 📊 Reports
- ⏰ Reminders, 🌐 Web search, 📁 File management
- 🤖 Multi-Agent: Delegates to Coder, Researcher, Analyst, Scheduler

**How to use:**
- **Prompt box below:** Type anything - "Write a love song about Pune", "Generate image of futuristic tablet", "Create video script", "Build todo app", "Top 5 news today"
- **Model chooser top right:** Choose Claude Opus 4.5, Sonnet 4.5 CloudSonic, GPT-4o, Groq Llama Grow, Mixtral Installed Group, Gemini
- **Mode chips:** Select Image/Video/Song/Lyrics/Content/Code/News for specialized generation

All your creations saved safely. No "Supabase stored" messages - just pure AI!

What would you like to create today?'''
      }
    ];
  }

  Future<void> _sendPrompt() async {
    final text = _promptController.text.trim();
    if (text.isEmpty || _loading) return;

    final mode = _selectedMode;
    final model = _selectedModel;
    final fullPrompt = _buildPromptForMode(mode, text, model);

    setState(() {
      _messages.add({'role': 'user', 'content': '[$mode • $model]\n$text'});
      _loading = true;
    });
    _promptController.clear();
    _scrollToEnd();

    try {
      String reply;
      
      // If complex task, use multi-agent orchestration
      if (text.toLowerCase().contains(' and ') && (text.toLowerCase().contains('build') || text.toLowerCase().contains('news') || text.toLowerCase().contains('remind'))) {
        final multiResult = await _multiAgentService.delegate(fullPrompt);
        reply = multiResult['summary'] as String;
      } else {
        // Use main agent service with OpenRouter Claude/GPT/Groq/Gemini
        final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
        reply = await _agentService.chat(fullPrompt, history: history);
      }

      // If mode is generation, enhance with generation note
      if (mode != 'chat') {
        reply = _enhanceForGeneration(reply, mode, text, model);
        // Save generation to Supabase generations table
        try {
          await _supabaseService.saveGeneration(
            type: mode,
            prompt: text,
            model: model,
            resultText: reply,
          );
        } catch (e) {
          print('Save generation error: $e');
        }
      }

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '❌ Error: $e\n\nTry again with different model or prompt.'});
      });
    } finally {
      setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  String _buildPromptForMode(String mode, String text, String model) {
    switch (mode) {
      case 'image':
        return 'Generate image: $text. Describe detailed image prompt for DALL-E / Stable Diffusion via OpenRouter. Include style, lighting, composition. Model: $model. After description, say "Image prompt ready" and provide prompt that can be used in image generation API.';
      case 'video':
        return 'Generate video: $text. Create video script with scenes, duration, transitions, voiceover, music. Model: $model. Provide script that can be used for video generation (Runway, Pika, Sora style).';
      case 'song':
        return 'Generate song: $text. Write full song with verses, chorus, bridge, melody description, genre, instruments, mood. Model: $model. Include lyrics and music style for AI song generation (Suno, Udio style).';
      case 'lyrics':
        return 'Write lyrics: $text. Create full lyrics with verses, chorus, bridge, rhyme, meter. Model: $model. Make it catchy, emotional, suitable for singing.';
      case 'content':
        return 'Create content: $text. Generate blog post / social media / marketing content with headings, bullet points, CTA. Model: $model.';
      case 'code':
        return 'Build app/code: $text. Generate complete Flutter code with pubspec, models, services, screens, Supabase integration, APK build steps. Use Claude Opus reasoning. Model: $model.';
      case 'news':
        return 'Top 5 news: $text. Give top 5 news today with summaries, sources, citations [1](url). Model: $model.';
      default:
        return text;
    }
  }

  String _enhanceForGeneration(String reply, String mode, String original, String model) {
    switch (mode) {
      case 'image':
        return '''🎨 **Image Generation - Model: $model**

**Your prompt:** $original

$reply

---
**Next steps for real image:**
- Use OpenRouter image models: `openai/dall-e-3` or `stabilityai/stable-diffusion-xl`
- Or use this prompt in Midjourney, DALL-E, Stable Diffusion
- Saved to generations table type=image
''';
      case 'video':
        return '''🎬 **Video Generation - Model: $model**

**Your prompt:** $original

$reply

---
**Next steps for real video:**
- Use Runway, Pika, Sora, or OpenRouter video models
- Script above ready for video generation
- Saved to generations table
''';
      case 'song':
        return '''🎵 **Song Generation - Model: $model**

**Your prompt:** $original

$reply

---
**Next steps for real song:**
- Use Suno AI, Udio, Stable Audio with lyrics above
- Lyrics + melody description ready
- Saved to generations table type=song
- To generate actual audio file, integrate Suno API via Edge Function
''';
      case 'lyrics':
        return '''📝 **Lyrics - Model: $model**

**Topic:** $original

$reply

---
Saved to generations. Ready to sing or generate song from these lyrics!
''';
      default:
        return reply;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Super Agent Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'LMArena - How it works',
            icon: const Icon(Icons.compare),
            onPressed: () => Navigator.pushNamed(context, '/arena'),
          ),
          IconButton(
            tooltip: 'Choose Model: GPT-4o, Groq Grow, Mixtral Installed Group, Gemini',
            icon: const Icon(Icons.model_training),
            onPressed: () async {
              final selected = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelSelectorScreen()));
              if (selected != null && selected is String) {
                setState(() => _selectedModel = selected);
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                // Logout
              }
            },
            itemBuilder: (c) => [
              PopupMenuItem(value: 'model', child: Text('Current: $_selectedModel')),
              const PopupMenuItem(value: 'skills', child: Text('View All 30+ Skills')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Model chooser + mode selector bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.smart_toy, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Model: $_selectedModel', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      tooltip: 'Choose Claude, ChatGPT, Groq, Gemini',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelSelectorScreen())).then((val) {
                        if (val != null) setState(() => _selectedModel = val as String);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _modes.map((m) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(m['label']!, style: const TextStyle(fontSize: 11)),
                        selected: _selectedMode == m['id'],
                        onSelected: (_) => setState(() => _selectedMode = m['id']!),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mode: ${_modes.firstWhere((mm) => mm['id'] == _selectedMode)['label']} • ${_modes.firstWhere((mm) => mm['id'] == _selectedMode)['hint']}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Chat messages - like ChatGPT/Gemini
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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
                      color: isUser ? Colors.deepPurple : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: isUser ? null : Border.all(color: Colors.grey.shade300),
                    ),
                    child: MarkdownBody(
                      data: m['content'] ?? '',
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13, height: 1.4),
                        code: const TextStyle(fontFamily: 'monospace', backgroundColor: Colors.black12),
                        h1: TextStyle(color: isUser ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                        h2: TextStyle(color: isUser ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_loading) const LinearProgressIndicator(),

          // Prompt edit box - like ChatGPT/Gemini
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendPrompt(),
                        decoration: InputDecoration(
                          hintText: _modes.firstWhere((mm) => mm['id'] == _selectedMode)['hint'],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          prefixIcon: Icon(
                            _selectedMode == 'image' ? Icons.image
                                : _selectedMode == 'video' ? Icons.videocam
                                : _selectedMode == 'song' ? Icons.music_note
                                : _selectedMode == 'lyrics' ? Icons.lyrics
                                : Icons.chat_bubble_outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _loading ? null : _sendPrompt,
                      icon: const Icon(Icons.send),
                      tooltip: 'Send prompt to AI Super Agent',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Quick actions
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _quickChip('Write a song about Pune ❤️'),
                      _quickChip('Generate image of futuristic AI tablet'),
                      _quickChip('Create video script for study app'),
                      _quickChip('Top 5 news today'),
                      _quickChip('Build todo app with Supabase'),
                      _quickChip('Write lyrics for love song'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 10)),
        onPressed: () {
          _promptController.text = text;
          _sendPrompt();
        },
      ),
    );
  }
}
