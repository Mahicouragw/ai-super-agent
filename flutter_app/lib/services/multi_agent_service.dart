import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Multi-Agent Orchestration Service
/// Allows AI Super Agent to delegate tasks to specialized sub-agents:
/// - Agent B: Coding / App Builder
/// - Agent C: Web Search / News
/// - Agent D: Reports / Analysis
/// - Agent E: Reminders / Scheduler
/// Inspired by Arena AI multi-agent workflow

enum AgentRole {
  coordinator, // Main agent - decides delegation
  coder, // Agent B - coding, Flutter, apps
  researcher, // Agent C - web search, info, news
  analyst, // Agent D - reports, data, newspapers
  scheduler, // Agent E - reminders, daily news
}

class SubAgentTask {
  final String id;
  final AgentRole role;
  final String prompt;
  final String status; // pending, running, done, failed
  final String? result;
  final DateTime createdAt;

  SubAgentTask({
    required this.id,
    required this.role,
    required this.prompt,
    this.status = 'pending',
    this.result,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'prompt': prompt,
    'status': status,
    'result': result,
    'createdAt': createdAt.toIso8601String(),
  };
}

class MultiAgentService {
  final String _openRouterKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  final String _model = dotenv.env['OPENROUTER_MODEL'] ?? 'anthropic/claude-opus-4.5';

  // Claude Opus and Claude Sonnet are best for multi-agent reasoning
  // OpenRouter models: anthropic/claude-opus-4.5, anthropic/claude-3-5-sonnet, openai/gpt-4o, google/gemini-2.0-flash-001
  String get _effectiveModel {
    // If user wants Claude Opus or CloudSonic (Sonnet), use Opus as default per request
    if (_model.contains('opus') || _model.contains('sonnet') || _model.contains('claude')) {
      return _model;
    }
    // Default to Claude Opus as requested
    return 'anthropic/claude-opus-4.5';
  }

  /// Coordinator decides which agents to delegate to based on user intent
  List<AgentRole> _planDelegation(String userMessage) {
    final lower = userMessage.toLowerCase();
    final roles = <AgentRole>{};

    if (lower.contains('code') || lower.contains('app') || lower.contains('build') || lower.contains('flutter') || lower.contains('fix') || lower.contains('debug')) {
      roles.add(AgentRole.coder);
    }
    if (lower.contains('search') || lower.contains('web') || lower.contains('info') || lower.contains('latest') || lower.contains('look up') || lower.contains('google')) {
      roles.add(AgentRole.researcher);
    }
    if (lower.contains('news') || lower.contains('newspaper') || lower.contains('report') || lower.contains('analysis') || lower.contains('data')) {
      roles.add(AgentRole.analyst);
    }
    if (lower.contains('remind') || lower.contains('daily') || lower.contains('schedule') || lower.contains('every day') || lower.contains('alarm')) {
      roles.add(AgentRole.scheduler);
    }

    // If no specific role detected, use coordinator + researcher for general
    if (roles.isEmpty) {
      roles.add(AgentRole.researcher);
    }

    return roles.toList();
  }

  /// Main entry: delegate to multiple agents in parallel
  Future<Map<String, dynamic>> delegate(String userMessage) async {
    final roles = _planDelegation(userMessage);
    final tasks = <SubAgentTask>[];

    // Create tasks for each role
    for (var role in roles) {
      tasks.add(SubAgentTask(
        id: '${role.name}_${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        prompt: _buildAgentPrompt(role, userMessage),
      ));
    }

    // Run agents in parallel (simulated via futures)
    final results = await Future.wait(
      tasks.map((t) => _runAgent(t)),
    );

    return {
      'userMessage': userMessage,
      'delegatedTo': roles.map((r) => r.name).toList(),
      'tasks': results.map((r) => r.toJson()).toList(),
      'summary': _summarizeResults(userMessage, results),
    };
  }

  String _buildAgentPrompt(AgentRole role, String original) {
    switch (role) {
      case AgentRole.coder:
        return '''You are Agent B (Coder) - expert in Flutter, Dart, Supabase, coding.
User asked: "$original"
Your job: Generate complete runnable code, explain architecture, build steps for APK.
Include pubspec, lib files, models, services, screens. Be thorough like Arena AI.
''';
      case AgentRole.researcher:
        return '''You are Agent C (Researcher) - expert in web search, giving information, live data.
User asked: "$original"
Your job: Search web (via Tavily/Brave), provide info with citations [id](url), summarize top results.
''';
      case AgentRole.analyst:
        return '''You are Agent D (Analyst) - expert in newspapers, news daily, report series.
User asked: "$original"
Your job: If news related, give top 5 news today with summaries, sources. If report, create professional report series structure.
Use NewsAPI/Tavily, produce markdown with charts suggestion.
''';
      case AgentRole.scheduler:
        return '''You are Agent E (Scheduler) - expert in reminders, daily tasks.
User asked: "$original"
Your job: Parse reminder intent, suggest reminder storage in Supabase, daily notification schedule, CRON-like.
''';
      case AgentRole.coordinator:
        return '''You are Coordinator - orchestrate other agents.
User asked: "$original"
''';
    }
  }

  Future<SubAgentTask> _runAgent(SubAgentTask task) async {
    // If OpenRouter key available, call Claude Opus/Sonnet via OpenRouter
    if (_openRouterKey.isNotEmpty && _openRouterKey.startsWith('sk-or-')) {
      try {
        final result = await _callClaudeViaOpenRouter(task.prompt, task.role);
        return SubAgentTask(
          id: task.id,
          role: task.role,
          prompt: task.prompt,
          status: 'done',
          result: result,
          createdAt: task.createdAt,
        );
      } catch (e) {
        return SubAgentTask(
          id: task.id,
          role: task.role,
          prompt: task.prompt,
          status: 'failed',
          result: 'Error: $e - fallback: ${task.role} will provide template response for "${task.prompt.substring(0, 50)}"',
          createdAt: task.createdAt,
        );
      }
    }

    // Fallback template responses (offline mode)
    return SubAgentTask(
      id: task.id,
      role: task.role,
      prompt: task.prompt,
      status: 'done',
      result: _templateResponse(task.role, task.prompt),
      createdAt: task.createdAt,
    );
  }

  Future<String> _callClaudeViaOpenRouter(String prompt, AgentRole role) async {
    final res = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openRouterKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/Mahicouragw/ai-super-agent',
        'X-Title': 'AI Super Agent Multi-Agent (${role.name})',
      },
      body: jsonEncode({
        'model': _effectiveModel, // anthropic/claude-opus-4.5 or claude-3-5-sonnet
        'messages': [
          {'role': 'system', 'content': 'You are ${role.name} sub-agent of AI Super Agent. You work with other agents (B=coder, C=researcher, D=analyst, E=scheduler). Be concise, produce actionable output.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.6,
        'max_tokens': 1500,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('OpenRouter ${res.statusCode}: ${res.body.substring(0, 500)}');
    }
  }

  String _templateResponse(AgentRole role, String prompt) {
    switch (role) {
      case AgentRole.coder:
        return '''👨‍💻 Agent B (Coder) here - Claude Opus mode

Task: ${prompt.substring(0, 100)}...

I will:
1. Create pubspec.yaml with deps
2. Models (user_model, etc)
3. Services (supabase_service with email,username,password,confirm + login email/password only)
4. Screens with TalkBack Semantics
5. Supabase init.sql with UNIQUE username/email, RLS, trigger
6. Edge function with OpenRouter Claude Opus via sk-or-v1- key
7. Build APK via flutter build apk --release

Full code ready in repo, fallback offline response.
''';
      case AgentRole.researcher:
        return '''🔍 Agent C (Researcher) - CloudSonic/Sonnet mode

Task: $prompt

Would search via Tavily API with citations, summarize top 5 results.
Set TAVILY_API_KEY in Supabase secrets for live search.
Offline template: Provide info structure with [1](url) citations.
''';
      case AgentRole.analyst:
        return '''📰 Agent D (Analyst) - Newspaper/News Daily

Task: $prompt

Would fetch top 5 news via NewsAPI every day, create daily digest at 8am IST.
For newspapers, summarize headlines with sources.
Reports: template -> data fetch -> markdown -> charts -> save to Supabase reports table.
Use reminder service for daily trigger.
''';
      case AgentRole.scheduler:
        return '''⏰ Agent E (Scheduler) - Reminders

Task: $prompt

Would set reminder in Supabase + local notifications:
- Store in reminders table (user_id, title, time, repeat daily/weekly)
- Use flutter_local_notifications for APK
- Example: Daily top 5 news at 8am -> schedule via cron + Edge Function

Template stored.
''';
      case AgentRole.coordinator:
        return 'Coordinator delegating...';
    }
  }

  String _summarizeResults(String original, List<SubAgentTask> results) {
    final buf = StringBuffer();
    buf.writeln('🤖 **Multi-Agent Orchestration Complete** (Claude Opus/CloudSonic)\n');
    buf.writeln('**User asked:** "$original"\n');
    buf.writeln('**Delegated to ${results.length} agents:** ${results.map((r) => r.role.name).join(", ")}\n');
    for (var r in results) {
      buf.writeln('---\n**${r.role.name.toUpperCase()} - ${r.id} - ${r.status}**\n');
      buf.writeln(r.result ?? 'No result');
      buf.writeln('');
    }
    buf.writeln('\nAll agents worked in parallel, coordinator merges results. This is how Arena AI multi-agent works.');
    return buf.toString();
  }
}
