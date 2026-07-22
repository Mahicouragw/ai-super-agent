import 'package:flutter/material.dart';

/// LMArena Style Screen - Shows how model works: thinking -> analyzing -> responding
/// Like https://lmarena.ai - side-by-side model comparison with steps

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  final _promptController = TextEditingController();
  bool _loading = false;
  List<Map<String, String>> _steps = [];
  String _responseA = '';
  String _responseB = '';
  String _modelA = 'openai/gpt-4o-mini';
  String _modelB = 'groq/llama-3.1-70b-versatile';

  Future<void> _sendArena() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _loading = true;
      _steps = [];
      _responseA = '';
      _responseB = '';
    });

    // Simulate LMArena thinking steps
    await _addStep('🤔 Thinking...', 'Understanding your prompt: "$prompt". Checking intent, context, required skills...');
    await Future.delayed(const Duration(milliseconds: 800));
    
    await _addStep('🔍 Analyzing...', 'Analyzing request type, selecting tools: ${_getToolsForPrompt(prompt)}, choosing best models ($_modelA vs $_modelB), preparing system prompt...');
    await Future.delayed(const Duration(milliseconds: 800));
    
    await _addStep('🧠 Planning...', 'Breaking into sub-tasks, planning multi-agent delegation: Coder B, Researcher C, Analyst D if needed. Preparing to call $_modelA and $_modelB via OpenRouter...');
    await Future.delayed(const Duration(milliseconds: 800));

    await _addStep('💬 Responding...', 'Both models now generating responses in parallel (like LMArena battle mode). Streaming tokens...');

    // Simulate parallel model responses (in real app, would call OpenRouter for both models)
    _simulateModelResponses(prompt);

    setState(() => _loading = false);
  }

  Future<void> _addStep(String title, String detail) async {
    setState(() {
      _steps.add({'title': title, 'detail': detail, 'time': DateTime.now().toIso8601String()});
    });
  }

  String _getToolsForPrompt(String prompt) {
    final lower = prompt.toLowerCase();
    List<String> tools = [];
    if (lower.contains('image')) tools.add('image_gen');
    if (lower.contains('code') || lower.contains('app')) tools.add('app_builder');
    if (lower.contains('news')) tools.add('news_search');
    if (lower.contains('pdf')) tools.add('pdf_search');
    if (tools.isEmpty) tools.add('chat');
    return tools.join(', ');
  }

  void _simulateModelResponses(String prompt) {
    // Simulate streaming like LMArena
    final responseTemplateA = '''**Model A ($_modelA) - GPT-4o Mini Response:**

You asked: "$prompt"

This is how I work like LMArena:
1. **Thinking:** I first understand your intent - you want ${prompt.length > 30 ? prompt.substring(0, 30) + '...' : prompt}
2. **Analyzing:** I check what tools needed, context from history, best approach
3. **Responding:** I generate helpful answer with clear structure

**Answer:**
Here's my response to "$prompt" - I'm fast, cheap, reliable, no credit limits like Claude Opus. I work like ChatGPT!

Want me to generate image, video, song, lyrics, code, or more? Just ask!

[This is simulated - in real app, this would be actual API call to $_modelA via OpenRouter]
''';

    final responseTemplateB = '''**Model B ($_modelB) - Groq Llama Grow Response:**

You asked: "$prompt"

**My LMArena process:**
- **Thinking:** Quick analysis of prompt
- **Analyzing:** Super fast inference via Groq hardware
- **Responding:** Instant generation

**Answer:**
I'm Groq Llama (Grow you asked!) - super fast, 70B versatile model. I give concise, helpful answers with no credit limit issues.

For "$prompt", here's my take: Fast, efficient, helpful!

[This is simulated - in real app, actual API call to $_modelB via OpenRouter]
''';

    setState(() {
      _responseA = responseTemplateA;
      _responseB = responseTemplateB;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LMArena Style - How It Works'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Info card about LMArena
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧠 How LMArena Works (Now in Your App):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('1. You send chat message\n2. Shows Thinking → Analyzing → Responding steps\n3. Calls 2 models in parallel (like battle mode)\n4. Shows side-by-side responses\n5. User votes best response\n6. No credit limit - uses cheap models', style: TextStyle(fontSize: 11, height: 1.3)),
                const SizedBox(height: 8),
                Row(children: [
                  ChoiceChip(label: const Text('Model A: GPT-4o Mini', style: TextStyle(fontSize: 10)), selected: _modelA == 'openai/gpt-4o-mini', onSelected: (_) => setState(() => _modelA = 'openai/gpt-4o-mini')),
                  const SizedBox(width: 6),
                  ChoiceChip(label: const Text('Model B: Groq Grow', style: TextStyle(fontSize: 10)), selected: _modelB == 'groq/llama-3.1-70b-versatile', onSelected: (_) => setState(() => _modelB = 'groq/llama-3.1-70b-versatile')),
                ]),
              ],
            ),
          ),

          // Steps - thinking, analyzing, responding
          if (_steps.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _steps.length,
                itemBuilder: (ctx, i) {
                  final step = _steps[i];
                  return Card(
                    color: i == _steps.length - 1 ? Colors.green.shade50 : Colors.white,
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(step['detail']!, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 4, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Side-by-side responses like LMArena
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.blue.shade50,
                          child: Row(children: [Text('Model A', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Spacer(), Text(_modelA.split('/').last, style: const TextStyle(fontSize: 9))]),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: Text(_responseA.isEmpty ? 'Waiting for prompt...' : _responseA, style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.orange.shade50,
                          child: Row(children: [Text('Model B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const Spacer(), Text(_modelB.split('/').last, style: const TextStyle(fontSize: 9))]),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: Text(_responseB.isEmpty ? 'Waiting...' : _responseB, style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Prompt box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: const InputDecoration(hintText: 'Enter prompt to see LMArena thinking -> analyzing -> responding...', border: OutlineInputBorder()),
                    onSubmitted: (_) => _sendArena(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _loading ? null : _sendArena, icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
