// AI Provider config - supports OpenAI, Gemini, Claude via Edge Function
// Set via .env and Supabase secrets

class AIConfig {
  static const providers = ['openai', 'gemini', 'claude', 'fallback'];
  
  static String get currentProvider {
    // Can be set in .env as AI_PROVIDER
    return 'gemini'; // default now since user asked for other than OpenAI
  }
}

// Usage in Edge Function:
// supabase secrets set AI_PROVIDER=gemini GEMINI_API_KEY=AIza... NEWS_API_KEY=... TAVILY_API_KEY=...
// or
// supabase secrets set AI_PROVIDER=openai OPENAI_API_KEY=sk-...
