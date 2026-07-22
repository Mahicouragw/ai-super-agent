import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  final _client = SupabaseConfig.client;

  // Check if username exists - prevents duplicate
  Future<bool> isUsernameTaken(String username) async {
    final res = await _client
        .from('profiles')
        .select('username')
        .eq('username', username.trim().toLowerCase())
        .maybeSingle();
    return res != null;
  }

  // Check if email exists
  Future<bool> isEmailTaken(String email) async {
    final res = await _client
        .from('profiles')
        .select('email')
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();
    return res != null;
  }

  // SIGN UP with name, username, email, password, confirm password handling
  Future<AuthResponse> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    // Double-check duplicates before calling auth
    if (await isUsernameTaken(cleanUsername)) {
      throw Exception('Username already taken. Please choose another.');
    }
    if (await isEmailTaken(cleanEmail)) {
      throw Exception('Email already registered. Please login instead.');
    }

    final response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'name': name.trim(),
        'username': cleanUsername,
        'email': cleanEmail,
      },
      emailRedirectTo: 'io.supabase.aisuperagent://login-callback/',
    );

    // Profile will be auto-created via DB trigger handle_new_user()
    // But if trigger fails, ensure manually:
    if (response.user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'name': name.trim(),
          'username': cleanUsername,
          'email': cleanEmail,
        });
      } catch (e) {
        // Ignore if already created by trigger, but log
        print('Profile upsert info: $e');
      }
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Resend verification email
  Future<void> resendVerification(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  // Chat history methods
  Future<void> saveChatMessage({
    required String role,
    required String content,
    String? toolName,
    Map<String, dynamic>? toolResult,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await _client.from('chat_histories').insert({
      'user_id': userId,
      'role': role,
      'content': content,
      'tool_name': toolName,
      'tool_result': toolResult,
    });
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    final res = await _client
        .from('chat_histories')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(100);
    return List<Map<String, dynamic>>.from(res);
  }

  // Documents for PDF search
  Future<void> saveDocument({
    required String filename,
    required String contentText,
    required int fileSize,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not logged in');
    await _client.from('documents').insert({
      'user_id': userId,
      'filename': filename,
      'content_text': contentText,
      'file_size': fileSize,
    });
  }

  Future<List<Map<String, dynamic>>> searchDocuments(String query) async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    // Simple ilike search - for production use pgvector semantic search
    final res = await _client
        .from('documents')
        .select()
        .eq('user_id', userId)
        .ilike('content_text', '%$query%')
        .limit(10);
    return List<Map<String, dynamic>>.from(res);
  }

  // Reports
  Future<void> saveReport({
    required String title,
    required Map<String, dynamic> content,
    String type = 'general',
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not logged in');
    await _client.from('reports').insert({
      'user_id': userId,
      'title': title,
      'content': content,
      'type': type,
    });
  }

  // Generations for dashboard - images, videos, songs, lyrics, content, prompts
  Future<void> saveGeneration({
    required String type, // image, video, song, lyrics, content, prompt
    required String prompt,
    String? model,
    String? resultText,
    String? resultUrl,
  }) async {
    try {
      final userId = currentUser?.id;
      final email = currentUser?.email ?? 'anonymous';
      await _client.from('generations').insert({
        'user_id': userId,
        'email': email,
        'type': type,
        'prompt': prompt,
        'model': model ?? 'anthropic/claude-opus-4.5',
        'result_text': resultText,
        'result_url': resultUrl,
      });
    } catch (e) {
      print('Save generation error (table may not exist yet): $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGenerations({String? type}) async {
    final userId = currentUser?.id;
    try {
      var query = _client.from('generations').select().order('created_at', ascending: false).limit(50);
      if (userId != null) {
        // query = query.eq('user_id', userId); // allow all for demo
      }
      if (type != null) {
        query = query.eq('type', type);
      }
      final res = await query;
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }
}
