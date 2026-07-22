import 'package:flutter/material.dart';
import '../../utils/news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _newsService = NewsService();
  List<Map<String, String>> _news = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _newsService.getTop5News();
    setState(() { _news = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('📰 Top 5 News - AI Skill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Daily top 5 with summaries, sources, auto-updated', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Refresh Top 5 News')),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _news.length,
                itemBuilder: (c,i) {
                  final n = _news[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i+1}. ${n['title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(n['description'] ?? ''),
                          const SizedBox(height: 6),
                          Text('${n['source']} - ${n['url']}', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
