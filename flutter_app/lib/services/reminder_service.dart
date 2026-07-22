import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Reminder Service - daily tasks, newspaper/news every day
class ReminderService {
  final _client = SupabaseConfig.client;

  Future<void> ensureTable() async {
    // Table creation via SQL already done in init.sql? Ensure via query if needed
    // For now, we create locally and rely on migration
  }

  /// Set daily reminder for top 5 news at 8am IST etc.
  Future<void> setReminder({
    required String title,
    required String description,
    required DateTime time,
    String repeat = 'daily', // daily, weekly, once
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    // Save to Supabase (need reminders table - create if not exists via supabase)
    try {
      await _client.from('reminders').insert({
        'user_id': userId,
        'title': title,
        'description': description,
        'remind_at': time.toIso8601String(),
        'repeat': repeat,
        'is_active': true,
      });
    } catch (e) {
      // If table doesn't exist, fallback to local + log
      print('Reminders table missing, would create: $e');
      // For offline, we would use local storage + flutter_local_notifications
      // Here we just simulate
    }
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final res = await _client.from('reminders').select().eq('user_id', userId).order('remind_at');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Daily news scheduler - called by Edge Function or local timer
  Future<String> getDailyNewsDigest() async {
    // This would call NewsService + save to reports with type daily_digest
    return '''
📰 Daily News Digest (8am IST) - Would fetch top 5 news + newspapers

To enable auto daily:
1. Create Edge Function cron: Supabase Dashboard -> Edge Functions -> ai-agent -> Add cron schedule "0 2 * * *" (2am UTC = 7:30am IST)
2. Set function to fetch news and save to reports table type=daily
3. App shows daily digest card

Template for newspaper search:
- Search via Tavily: "today newspaper headlines India"
- Summarize with citations
''';
  }
}
