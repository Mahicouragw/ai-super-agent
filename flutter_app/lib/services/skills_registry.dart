/// Registry of ALL skills installed in AI Super Agent
/// Like Arena AI, includes every tool capability

class AISkill {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final bool requiresApiKey;

  const AISkill({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.requiresApiKey = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'category': category,
    'requiresApiKey': requiresApiKey,
  };
}

class SkillsRegistry {
  static const List<AISkill> allSkills = [
    // Core Arena Skills
    AISkill(id: 'pdf_search', name: 'PDF Search', description: 'Upload PDFs, extract text via Syncfusion, semantic search, Q&A with citations', icon: '📄', category: 'Documents'),
    AISkill(id: 'top_news', name: 'Top 5 News Daily', description: 'Daily top 5 news with summaries, sources, newspapers, NewsAPI + Tavily', icon: '🗞️', category: 'News'),
    AISkill(id: 'app_builder', name: 'App Builder', description: 'Generate full Flutter apps incrementally: scaffold -> models -> services -> UI -> Supabase -> APK', icon: '📱', category: 'Coding'),
    AISkill(id: 'report_series', name: 'Report Series', description: 'Create professional reports: financial, research, weekly/monthly series with charts, tables', icon: '📊', category: 'Productivity'),
    AISkill(id: 'web_search', name: 'Web Search', description: 'Live web search with citations via Tavily/Brave, summarization with Claude', icon: '🔍', category: 'Research'),
    AISkill(id: 'fetch_page', name: 'Fetch Webpage', description: 'Fetch and summarize any URL, extract content', icon: '🌐', category: 'Research'),
    AISkill(id: 'file_mgmt', name: 'File Management', description: 'Create, read, edit, manage workspace files, projects', icon: '📁', category: 'System'),
    
    // AI Generation Skills
    AISkill(id: 'image_search', name: 'Image Search', description: 'Search web for images', icon: '🖼️', category: 'Media'),
    AISkill(id: 'image_generation', name: 'Image Generation', description: 'Generate images via DALL-E / OpenRouter image models (prompt -> image)', icon: '🎨', category: 'Media', requiresApiKey: true),
    AISkill(id: 'speech_tts', name: 'Text to Speech', description: 'Generate spoken audio from text (flutter_tts + OpenAI TTS)', icon: '🔊', category: 'Media'),
    AISkill(id: 'speech_stt', name: 'Speech to Text', description: 'Transcribe voice to text via speech_to_text', icon: '🎤', category: 'Media'),
    
    // Productivity Skills
    AISkill(id: 'reminders', name: 'Reminders & Scheduler', description: 'Set reminders daily/weekly, daily news digest at 8am IST, local notifications', icon: '⏰', category: 'Productivity'),
    AISkill(id: 'coding', name: 'Coding & Debugging', description: 'Write, debug, explain code in any language, Flutter, Dart, Python, JS', icon: '💻', category: 'Coding'),
    AISkill(id: 'excel_csv', name: 'Excel/CSV Reports', description: 'Create Excel .xlsx, CSV data analysis via openpyxl style, charts', icon: '📈', category: 'Productivity'),
    AISkill(id: 'ppt_generator', name: 'Presentation Generator', description: 'Generate PowerPoint .pptx presentations with slides', icon: '📽️', category: 'Productivity'),
    AISkill(id: 'doc_generator', name: 'Document Generator', description: 'Generate Word .docx reports', icon: '📝', category: 'Productivity'),
    AISkill(id: 'translate', name: 'Translation', description: 'Translate text between languages (English, Telugu, Hindi)', icon: '🌍', category: 'Language'),
    AISkill(id: 'summarize', name: 'Summarization', description: 'Summarize PDFs, webpages, reports, conversations', icon: '✂️', category: 'Language'),
    
    // Multi-Agent Skills
    AISkill(id: 'multi_agent', name: 'Multi-Agent Orchestration', description: 'Delegate to Agent B Coder, Agent C Researcher, Agent D Analyst, Agent E Scheduler working in parallel', icon: '🤖', category: 'Advanced'),
    AISkill(id: 'task_planner', name: 'Task Planner', description: 'Break complex tasks into sub-tasks, assign to sub-agents, merge results', icon: '🧩', category: 'Advanced'),
    
    // Device Skills
    AISkill(id: 'geolocation', name: 'Location', description: 'Get device location (geolocator), maps', icon: '📍', category: 'Device'),
    AISkill(id: 'camera_picker', name: 'Camera & Gallery', description: 'Pick images from camera/gallery, image_picker', icon: '📷', category: 'Device'),
    AISkill(id: 'connectivity', name: 'Connectivity Check', description: 'Check internet connectivity status', icon: '📶', category: 'Device'),
    AISkill(id: 'share', name: 'Share & Export', description: 'Share files, reports, APK via share_plus', icon: '📤', category: 'Device'),
    
    // Study / Education (from Inter Buddy)
    AISkill(id: 'tutor', name: 'AI Tutor ELI5', description: 'Explain like 5, doubt solver, exam-oriented, Telugu/Hinglish support', icon: '🎓', category: 'Education'),
    AISkill(id: 'exam_answers', name: 'Exam Answer Writer', description: 'Generate 2/5/10 marks model answers for board exams', icon: '✍️', category: 'Education'),
    AISkill(id: 'vocab', name: 'Vocabulary Builder', description: 'Words with Telugu meanings, flashcards, quiz', icon: '🔤', category: 'Education'),
    
    // Accessibility
    AISkill(id: 'talkback', name: 'TalkBack Accessible', description: 'Full Semantics labels, screen reader navigation, voice replies', icon: '♿', category: 'Accessibility'),
    AISkill(id: 'license_nav', name: 'License Navigation', description: 'Open source licenses, privacy info, official sources', icon: '📄', category: 'Accessibility'),
  ];

  static List<AISkill> byCategory(String category) =>
      allSkills.where((s) => s.category == category).toList();

  static List<String> get categories =>
      allSkills.map((s) => s.category).toSet().toList();
}
