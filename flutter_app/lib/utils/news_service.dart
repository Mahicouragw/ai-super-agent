import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  Future<List<Map<String, String>>> getTop5News() async {
    final newsApiKey = dotenv.env['NEWS_API_KEY'];
    
    // Try NewsAPI if key available
    if (newsApiKey != null && newsApiKey.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(
            'https://newsapi.org/v2/top-headlines?country=us&pageSize=5&apiKey=$newsApiKey'
        ));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final articles = data['articles'] as List;
          return articles.map<Map<String, String>>((a) => {
            'title': a['title'] ?? 'No Title',
            'description': a['description'] ?? '',
            'url': a['url'] ?? '',
            'source': a['source']?['name'] ?? 'NewsAPI',
          }).toList();
        }
      } catch (e) {
        print('NewsAPI failed: $e');
      }
    }

    // Fallback mock top 5 (works offline)
    return [
      {
        'title': 'AI Super Agent Launched on Flutter',
        'description': 'New AI app with PDF search, news, app builder and reports hits APK stores.',
        'url': 'https://example.com/ai-agent',
        'source': 'TechCrunch (Mock)',
      },
      {
        'title': 'Supabase Announces Enhanced Auth Features',
        'description': 'Supabase adds improved email verification and duplicate prevention for secure apps.',
        'url': 'https://supabase.com/blog',
        'source': 'Supabase Blog (Mock)',
      },
      {
        'title': 'Flutter 3.22 Released with Performance Boost',
        'description': 'Latest Flutter release makes APK building 20% faster for tablet apps.',
        'url': 'https://flutter.dev',
        'source': 'Flutter (Mock)',
      },
      {
        'title': 'Top 5 Productivity Apps for Tablets in 2026',
        'description': 'Review of apps that combine AI and local storage for offline work.',
        'url': 'https://example.com/tablet-apps',
        'source': 'The Verge (Mock)',
      },
      {
        'title': 'India Tech Market Grows Amid AI Adoption',
        'description': 'Pune emerging as hub for AI agent development with Supabase stack.',
        'url': 'https://example.com/india-tech',
        'source': 'Economic Times (Mock)',
      },
    ];
  }
}
