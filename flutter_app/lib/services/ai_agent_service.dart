import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';

class AIAgentService {
  // Clean system prompt - no internal details exposed
  static const String systemPrompt = '''
You are AI Super Agent, a helpful AI assistant like ChatGPT and Gemini.

You can chat naturally, answer questions, write content, generate ideas, help with coding, explain things simply.

Available capabilities (use naturally, don't list unless asked):
- Chat, Q&A, explanations
- Writing: stories, lyrics, songs, blogs, content
- Coding: Flutter apps, debugging, code generation
- Creative: images (provide detailed prompts), videos (scripts), songs (lyrics + melody description)
- Information: search, news, reports
- Files: PDFs, documents

Be friendly, concise, helpful like ChatGPT. Don't mention system internals, API keys, models, tokens, providers, Supabase, or infrastructure. Just be a great assistant.
''';

  final SupabaseService _supabaseService = SupabaseService();

  // Main chat - clean ChatGPT-like behavior
  Future<String> chat(String userMessage, {List<Map<String, dynamic>>? history}) async {
    // Save user message (try, don't fail if offline)
    try {
      await _supabaseService.saveChatMessage(role: 'user', content: userMessage);
    } catch (_) {}

    // 1. Try Edge Function (primary, handles all models via OpenRouter - Claude Opus, GPT-4o, Groq, Gemini)
    try {
      final edgeResult = await _callEdgeFunction(userMessage, history);
      if (edgeResult != null && edgeResult.trim().isNotEmpty) {
        try {
          await _supabaseService.saveChatMessage(role: 'assistant', content: edgeResult);
        } catch (_) {}
        return edgeResult;
      }
    } catch (e) {
      print('Edge function trying fallback: $e');
    }

    // 2. Try direct OpenRouter from app (if key in .env)
    try {
      final orResult = await _callOpenRouterDirect(userMessage, history);
      if (orResult != null && orResult.trim().isNotEmpty) {
        try {
          await _supabaseService.saveChatMessage(role: 'assistant', content: orResult);
        } catch (_) {}
        return orResult;
      }
    } catch (_) {}

    // 3. Clean fallback - ChatGPT style, no secrets
    return _cleanChatFallback(userMessage);
  }

  // Call Edge Function - clean, handles token limits internally
  Future<String?> _callEdgeFunction(String message, List<Map<String, dynamic>>? history) async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || anonKey == null) return null;

    try {
      // Trim history to avoid token limits - only last 4 messages, each max 1500 chars
      final trimmedHistory = (history ?? []).length > 4 
          ? history!.sublist(history.length - 4) 
          : history ?? [];
      final cleanedHistory = trimmedHistory.map((h) {
        final content = (h['content'] ?? '').toString();
        return {
          'role': h['role'],
          'content': content.length > 1500 ? content.substring(0, 1500) : content,
        };
      }).toList();

      final res = await http.post(
        Uri.parse('$url/functions/v1/ai-agent'),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message.substring(0, 3000), // Limit message to avoid token overflow
          'history': cleanedHistory,
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final reply = data['reply'] as String?;
        if (reply != null && reply.trim().isNotEmpty) {
          return reply;
        }
      }
    } catch (e) {
      print('Edge call error: $e');
    }
    return null;
  }

  // Direct OpenRouter call from app with token limit handling
  Future<String?> _callOpenRouterDirect(String message, List<Map<String, dynamic>>? history) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;

    final model = dotenv.env['OPENROUTER_MODEL'] ?? 'anthropic/claude-opus-4.5';
    
    try {
      // Trim to avoid 1400 token limit issues
      final trimmedHistory = (history ?? []).length > 3 
          ? history!.sublist(history.length - 3) 
          : history ?? [];

      List<Map<String, String>> messages = [
        {'role': 'system', 'content': systemPrompt},
      ];
      for (var h in trimmedHistory) {
        final content = (h['content'] ?? '').toString();
        if (content.trim().isEmpty) continue;
        messages.add({
          'role': h['role'] == 'user' ? 'user' : 'assistant',
          'content': content.length > 1000 ? content.substring(0, 1000) : content,
        });
      }
      messages.add({'role': 'user', 'content': message.length > 2000 ? message.substring(0, 2000) : message});

      final res = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://aisuperagent.app',
          'X-Title': 'AI Super Agent',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1500, // Keep under 1400 limit issue - use 1000-1500
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().trim().isNotEmpty) {
          return content.toString();
        }
      } else {
        // If token limit error, try with even smaller history
        final body = res.body;
        if (body.toLowerCase().contains('token') || body.toLowerCase().contains('context') || body.contains('1400')) {
          print('Token limit hit, retrying with minimal history');
          // Retry with no history
          final retryRes = await http.post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://aisuperagent.app',
              'X-Title': 'AI Super Agent',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': message.length > 1000 ? message.substring(0, 1000) : message},
              ],
              'temperature': 0.7,
              'max_tokens': 800,
            }),
          );
          if (retryRes.statusCode == 200) {
            final data = jsonDecode(retryRes.body);
            return data['choices']?[0]?['message']?['content'];
          }
        }
      }
    } catch (e) {
      print('Direct OpenRouter error: $e');
    }
    return null;
  }

  // Clean fallback - no secrets, no vulnerabilities, ChatGPT-like
  String _cleanChatFallback(String prompt) {
    final lower = prompt.toLowerCase();
    
    if (lower.contains('image') && (lower.contains('generate') || lower.contains('create') || lower.contains('make'))) {
      return '''🎨 I'd love to help you create an image!

**Your idea:** "$prompt"

**Here's a detailed prompt you can use:**

"$prompt, highly detailed, 4k resolution, professional lighting, vibrant colors, sharp focus, artistic composition, trending on artstation"

**Want me to refine it?** Tell me the style you like - realistic, cartoon, anime, 3D, watercolor, etc.

What image should we create next?''';
    }
    
    if (lower.contains('video')) {
      return '''🎬 Great idea for a video! Here's a script for: "$prompt"

**Video Script:**
- **Opening (0-3s):** Hook to grab attention
- **Main (3-20s):** Core content with visuals
- **Closing (20-30s):** Call to action

Want me to write the full script with dialogues and scene descriptions?

What video do you want to create?''';
    }
    
    if (lower.contains('song') || lower.contains('music')) {
      return '''🎵 Let's create a song about: "$prompt"

**Verse 1:**
Walking through the memories...

**Chorus:**
This is our song, our story...

**Verse 2:**
...

Tell me the genre (pop, romantic, sad, energetic) and mood, and I'll write full lyrics with verses, chorus, bridge!

What kind of song do you want?''';
    }
    
    if (lower.contains('lyrics')) {
      return '''📝 Here are lyrics for "$prompt":

**Verse 1**
In the quiet of the night...

**Chorus**
Oh, this feeling...

**Verse 2**
...

Want me to make it more romantic, sad, happy, or in a specific language like Telugu or Hindi?

Tell me the style you want!''';
    }

    // Default friendly ChatGPT-like response
    return '''Hi! I'm your AI Super Agent 🤖

You said: "$prompt"

I'm here to help you with anything! I can:

- 💬 Chat and answer questions
- 🎨 Generate images - just describe what you want
- 🎬 Create video scripts
- 🎵 Write songs and lyrics
- 📄 Create content, stories, reports
- 💻 Help with coding and building apps
- 📰 Get news and information

What would you like me to do? Just tell me - for example:
- "Generate an image of a futuristic city"
- "Write a love song about Pune"
- "Create a video script for my study app"
- "Build a todo app"

I'm listening! 👇''';
  }
}
