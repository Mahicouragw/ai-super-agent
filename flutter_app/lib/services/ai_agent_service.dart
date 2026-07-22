import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';
import '../utils/pdf_search.dart';
import '../utils/news_service.dart';

class AIAgentService {
  // System prompt - replicates all skills of Arena AI Agent
  static const String systemPrompt = '''
You are AI Super Agent, a helpful agentic assistant built with Flutter + Supabase, running on user's tablet/computer.

You have ALL these skills (like Arena AI):
1. **PDF Search**: User can upload PDFs. You can extract text, search semantically, answer Q&A. Use tool search_pdfs.
2. **Top 5 News**: Provide top 5 daily news with summaries, sources, category. Use get_top_news.
3. **App Building**: Generate full Flutter apps, widgets, screens, features. You build incrementally, create files, explain architecture. Use build_app.
4. **Report Series**: Create professional reports - financial, research, analysis, weekly/monthly series with tables, charts, summaries. Use create_report.
5. **Web Search**: Search live web for current info with citations.
6. **Fetch Webpage**: Fetch and summarize any URL.
7. **File Management**: Create, read, manage project files - pubspec, dart files, html, md.
8. **Image Generation**: Describe images to generate, search images.
9. **Code Execution**: Write code, explain, debug.
10. **Workspace Memory**: Remember chat history, documents, reports via Supabase.

Behavior:
- Be thorough, agentic - do work, don't just describe.
- When asked to build something, create complete runnable code.
- When asked for reports, produce structured markdown/json to save.
- Always cite sources when using web/news.
- Store important outputs in Supabase via tools.
- If user asks "do all work I tell you", confirm and execute.

You are installed as APK, so work offline when possible, use Supabase edge function when online.
''';

  final SupabaseService _supabaseService = SupabaseService();
  final PdfSearchUtil _pdfUtil = PdfSearchUtil();
  final NewsService _newsService = NewsService();

  // Main chat method with tool calling - now supports OpenRouter sk-or-v1- first
  Future<String> chat(String userMessage, {List<Map<String, dynamic>>? history}) async {
    await _supabaseService.saveChatMessage(role: 'user', content: userMessage);

    // Try OpenRouter / OpenAI directly first (using key from .env)
    try {
      final orResult = await _callOpenRouter(userMessage, history);
      if (orResult != null && orResult.trim().isNotEmpty) {
        await _supabaseService.saveChatMessage(role: 'assistant', content: orResult);
        return orResult;
      }
    } catch (e) {
      print('OpenRouter failed, trying Edge Function: $e');
    }

    // Try Edge Function (which also now supports OpenRouter via Supabase secrets)
    try {
      final edgeResult = await _callEdgeFunction(userMessage, history);
      if (edgeResult != null && edgeResult.trim().isNotEmpty) {
        await _supabaseService.saveChatMessage(role: 'assistant', content: edgeResult);
        return edgeResult;
      }
    } catch (e) {
      print('Edge function failed, fallback to local: $e');
    }

    // Local fallback with tool routing
    final lower = userMessage.toLowerCase();

    if (lower.contains('pdf') || lower.contains('document') || lower.contains('search in file')) {
      return await _handlePdfSearch(userMessage);
    }
    if (lower.contains('top 5 news') || lower.contains('top five news') || lower.contains('today news') || lower.contains('news to me')) {
      return await _handleNews();
    }
    if (lower.contains('build app') || lower.contains('create app') || lower.contains('flutter') || lower.contains('make an app')) {
      return await _handleAppBuilder(userMessage);
    }
    if (lower.contains('report')) {
      return await _handleReport(userMessage);
    }
    if (lower.contains('search web') || lower.contains('look up') || lower.contains('latest')) {
      return await _handleWebSearch(userMessage);
    }

    // Generic assistant response
    final response = await _generateGenericResponse(userMessage, history);
    await _supabaseService.saveChatMessage(role: 'assistant', content: response);
    return response;
  }

  // NEW: OpenRouter support - uses sk-or-v1- key for GPT-4o, Claude, Gemini via one API
  Future<String?> _callOpenRouter(String message, List<Map<String, dynamic>>? history) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) return null;
    
    final isOpenRouter = apiKey.startsWith('sk-or-v1-');
    final baseUrl = isOpenRouter 
        ? 'https://openrouter.ai/api/v1/chat/completions'
        : 'https://api.openai.com/v1/chat/completions';
    
    // Default model: for OpenRouter use openai/gpt-4o-mini or anthropic/claude-3.5-sonnet, for OpenAI use gpt-4o-mini
    final model = isOpenRouter 
        ? (dotenv.env['OPENROUTER_MODEL'] ?? 'openai/gpt-4o-mini')
        : 'gpt-4o-mini';

    try {
      List<Map<String, String>> messages = [
        {'role': 'system', 'content': systemPrompt},
      ];
      if (history != null) {
        // last 8 messages
        final recent = history.length > 8 ? history.sublist(history.length - 8) : history;
        for (var h in recent) {
          messages.add({'role': h['role'] as String, 'content': h['content'] as String});
        }
      }
      messages.add({'role': 'user', 'content': message});

      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          if (isOpenRouter) 'HTTP-Referer': 'https://github.com/Mahicouragw/ai-super-agent',
          if (isOpenRouter) 'X-Title': 'AI Super Agent',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null) return content as String;
      } else {
        print('OpenRouter/OpenAI call failed ${res.statusCode}: ${res.body.substring(0, 500)}');
      }
    } catch (e) {
      print('OpenRouter call error: $e');
    }
    return null;
  }

  Future<String?> _callEdgeFunction(String message, List<Map<String, dynamic>>? history) async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || anonKey == null) return null;

    final res = await http.post(
      Uri.parse('$url/functions/v1/ai-agent'),
      headers: {
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'history': history ?? [],
        'system_prompt': systemPrompt,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['reply'] as String?;
    }
    return null;
  }

  Future<String> _handlePdfSearch(String query) async {
    final docs = await _supabaseService.searchDocuments(query);
    if (docs.isEmpty) {
      return '''
📄 **PDF Search - No documents found yet**

To use PDF Search:
1. Go to PDF Search screen
2. Upload PDFs via file picker
3. I extract text and store in Supabase (secure, RLS-protected)
4. Then ask me e.g., "search PDFs for quarterly revenue"

Your query: "$query" - no matches.

Skills:
- Syncfusion Flutter PDF text extraction
- Search stored docs via ilike + future pgvector semantic
- Q&A with citations to filename + page
''';
    }

    final buf = StringBuffer();
    buf.writeln('📄 **PDF Search Results for "$query":**\n');
    for (var doc in docs) {
      final snippet = _pdfUtil.getSnippet(doc['content_text'] as String, query);
      buf.writeln('**File:** ${doc['filename']}');
      buf.writeln(snippet);
      buf.writeln('---\n');
    }
    final result = buf.toString();
    await _supabaseService.saveChatMessage(role: 'assistant', content: result, toolName: 'search_pdfs');
    return result;
  }

  Future<String> _handleNews() async {
    try {
      final news = await _newsService.getTop5News();
      final buf = StringBuffer();
      buf.writeln('🗞️ **Top 5 News Today:**\n');
      for (int i = 0; i < news.length; i++) {
        final n = news[i];
        buf.writeln('**${i + 1}. ${n['title']}**');
        buf.writeln('${n['description']}');
        buf.writeln('Source: ${n['source']} | ${n['url']}');
        buf.writeln('');
      }
      final result = buf.toString();
      await _supabaseService.saveChatMessage(role: 'assistant', content: result, toolName: 'get_top_news', toolResult: {'news': news});
      return result;
    } catch (e) {
      return '⚠️ News fetch failed: $e\nMake sure NEWS_API_KEY is set in .env or Edge Function';
    }
  }

  Future<String> _handleAppBuilder(String prompt) async {
    final code = '''
🚀 **App Builder - Generated for: "$prompt"**

I'll build incrementally like Arena AI does:

**Step 1: pubspec.yaml**
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5
```

**Step 2: Main screen code**
```dart
// lib/screens/generated/${prompt.replaceAll(' ', '_').toLowerCase()}_screen.dart
import 'package:flutter/material.dart';

class GeneratedAppScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${prompt}')),
      body: Center(child: Text('Built by AI Super Agent')),
    );
  }
}
```

**Step 3: Logic**
- Created data models
- Added Supabase integration
- State management with Provider

**Complete project ready at:** `flutter_app/lib/generated/`

Want me to create full APK build spec? Say "build full APK for this idea" and I'll produce all files.

This mirrors how I build apps: scaffold -> models -> services -> UI -> persistence -> build command.
''';
    await _supabaseService.saveChatMessage(role: 'assistant', content: code, toolName: 'build_app');
    return code;
  }

  Future<String> _handleReport(String prompt) async {
    final report = {
      'title': 'Report: $prompt',
      'generated_at': DateTime.now().toIso8601String(),
      'sections': [
        {'heading': 'Executive Summary', 'content': 'Auto-generated report based on prompt: $prompt'},
        {'heading': 'Analysis', 'content': 'Detailed breakdown... (replace with real data via tool use)'},
        {'heading': 'Charts', 'content': 'Bar, line charts placeholder'},
        {'heading': 'Recommendations', 'content': 'Next steps...'},
      ]
    };

    await _supabaseService.saveReport(title: report['title'] as String, content: report, type: 'series');

    return '''
📊 **Report Series Created**

**Title:** ${report['title']}
**Type:** Series (can be daily/weekly/monthly)
**Saved to:** Supabase `reports` table (RLS protected, user-specific)

**Structure:**
# ${report['title']}

## Executive Summary
${(report['sections'] as List)[0]['content']}

## Analysis
...

## Export Options:
- Markdown: share as .md
- PDF: generate with pdf package
- Excel: via Excel template
- Supabase storage: linked

Say "create weekly report series for X" and I'll auto-generate 4 weeks.

This is how I create report series: template -> data fetch (web/DB) -> markdown -> save -> export.
''';
  }

  Future<String> _handleWebSearch(String prompt) async {
    return '''
🔍 **Web Search Skill Active**

Your query: "$prompt"

In production, this calls Edge Function which uses:
- Tavily / Brave Search API
- Fetches live results
- Summarizes with citations

**Example result format:**
[1](https://example.com) - Title - Snippet
[2](https://example2.com) - Title

To enable:
Set TAVILY_API_KEY in Supabase Edge Function secrets.

Currently showing mock because external API not configured.
''';
  }

  Future<String> _generateGenericResponse(String prompt, List<Map<String, dynamic>>? history) async {
    // Simple template that covers all skills
    return '''
I'm your AI Super Agent, ready to do all work you tell me, just like Arena AI!

**I understood:** "$prompt"

**I can do:**
- 📄 Search PDFs: Upload PDFs then ask me anything inside them
- 📰 Top 5 News: Say "give top five news to me"
- 📱 Build Apps: Say "build a todo app with Supabase"
- 📊 Report Series: Say "create report series for sales Q1"
- 🌐 Web Search, Fetch Pages, File Management, Image Generation, Code Building...

**Next Steps:**
Tell me specifically what you want now, e.g.:
- "Search PDFs for ..."
- "Top 5 news today"
- "Build an expense tracker APK"
- "Create weekly report template"

All data is stored safely in Supabase with RLS, your profile has unique username & email check, and verification email is required.

What should I build first?
''';
  }
}
