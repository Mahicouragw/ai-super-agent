import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Web Search Service - coding, searching web, giving information, newspapers/news daily
class WebSearchService {
  final _tavilyKey = dotenv.env['TAVILY_API_KEY'] ?? '';
  final _newsKey = dotenv.env['NEWS_API_KEY'] ?? '';
  final _openRouterKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// Search web with citations
  Future<List<Map<String, String>>> searchWeb(String query) async {
    if (_tavilyKey.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('https://api.tavily.com/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'api_key': _tavilyKey, 'query': query, 'max_results': 5}),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final results = data['results'] as List? ?? [];
          return results.map<Map<String, String>>((r) => {
            'title': r['title'] ?? '',
            'content': r['content'] ?? '',
            'url': r['url'] ?? '',
            'score': '${r['score'] ?? ''}',
          }).toList();
        }
      } catch (e) {
        print('Tavily error $e');
      }
    }

    // Fallback mock with structure
    return [
      {'title': 'Mock Result for $query', 'content': 'This is fallback because TAVILY_API_KEY not set. Set key in .env and Supabase secrets for live web search. Query was: $query', 'url': 'https://example.com/search?q=$query', 'score': '0.9'},
      {'title': 'Arena AI Search Example', 'content': 'Arena AI would search live web and cite sources like [1](https://example.com)', 'url': 'https://example.com', 'score': '0.8'},
    ];
  }

  /// Get top 5 news daily - newspapers
  Future<List<Map<String, String>>> getTopNews({String country = 'in'}) async {
    if (_newsKey.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse('https://newsapi.org/v2/top-headlines?country=$country&pageSize=5&apiKey=$_newsKey'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final articles = data['articles'] as List? ?? [];
          return articles.map<Map<String, String>>((a) => {
            'title': a['title'] ?? '',
            'description': a['description'] ?? '',
            'url': a['url'] ?? '',
            'source': a['source']?['name'] ?? '',
          }).toList();
        }
      } catch (e) {
        print('NewsAPI error $e');
      }
    }

    // Fallback mock daily news
    return [
      {'title': 'AI Super Agent Multi-Agent Launched - Claude Opus via OpenRouter', 'description': 'New update adds multi-agent orchestration, coordinator delegates to coder, researcher, analyst, scheduler agents working in parallel.', 'url': 'https://github.com/Mahicouragw/ai-super-agent', 'source': 'AI News (Mock)'},
      {'title': 'Inter AI Study Buddy Adds Supabase Auth + TalkBack', 'description': 'Study buddy now has email, username, password, confirm signup, email/password login, all saved safely in Supabase with RLS, plus full TalkBack accessibility and Claude Opus.', 'url': 'https://github.com/Mahicouragw/inter-ai-study-buddy', 'source': 'EdTech (Mock)'},
      {'title': 'Claude Opus vs Sonnet via OpenRouter - Best for Study', 'description': 'Claude Opus most capable for complex reasoning, Sonnet faster cheaper, both via sk-or-v1- key.', 'url': 'https://openrouter.ai', 'source': 'OpenRouter (Mock)'},
      {'title': 'Supabase Mumbai Region Powers Pune Apps', 'description': 'Low latency for Maharashtra users with ap-south-1.', 'url': 'https://supabase.com', 'source': 'Supabase (Mock)'},
      {'title': 'Flutter APK Build via GitHub Actions Success', 'description': 'Both apps now build APK automatically with GitHub Actions.', 'url': 'https://flutter.dev', 'source': 'Flutter (Mock)'},
    ];
  }

  /// Summarize with OpenRouter Claude Opus if available
  Future<String> summarizeWithClaude(String content, {String task = 'summarize'}) async {
    if (_openRouterKey.isEmpty) return content.substring(0, content.length > 500 ? 500 : content.length);

    try {
      final res = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_openRouterKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/Mahicouragw/ai-super-agent',
          'X-Title': 'AI Super Agent Web Search',
        },
        body: jsonEncode({
          'model': dotenv.env['OPENROUTER_MODEL'] ?? 'anthropic/claude-3-opus',
          'messages': [
            {'role': 'system', 'content': 'You are researcher agent, expert at summarizing web content with citations. Task: $task'},
            {'role': 'user', 'content': content},
          ],
          'max_tokens': 1000,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['choices'][0]['message']['content'] as String;
      }
    } catch (e) {
      print('Summarize error $e');
    }
    return content;
  }
}
