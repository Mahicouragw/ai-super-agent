# AI Super Agent - Flutter + Supabase

A complete cross-platform AI agent app that you can install as APK on Android tablet, computer (via emulator), or run as web/desktop.

Built like Arena AI - with all core skills.

## Features

### 🔐 Authentication (Supabase - Secure)
- Sign Up with: **name, username, email, password, confirm password**
- Validation:
  - Username unique - not duplicate
  - Email unique - not duplicate  
  - Password strength + confirm match
- Email verification: Supabase sends verification link (no duplicate accounts)
- Login with secure session storage
- RLS policies protect all data

### 🤖 AI Agent Skills (All Included)
1. **PDF Search** - Upload PDFs, extract text, semantic search, Q&A over docs
2. **Top 5 News** - Daily curated top 5 news with summary, sources
3. **App Builder** - Generate Flutter apps, components, screens from prompt
4. **Report Series** - Create professional reports (PDF/Docx/Excel style, charts)
5. **Web Search** - Live web search with citations
6. **Fetch Webpage / Summarize URL**
7. **File Management** - Read, create, manage workspace files
8. **Image Search & Generation** - Search and create images
9. **Speech / Audio Generation** - Text-to-speech
10. **Code Execution & Building** - Build projects incrementally

### 📱 Platforms
- Android APK (via Flutter build)
- Android Tablet support
- Windows / macOS / Linux / Web

### 🏗️ Architecture
```
flutter_app/lib/
├── config/supabase_config.dart     # Supabase init
├── services/
│   ├── supabase_service.dart       # Auth & DB
│   └── ai_agent_service.dart       # AI orchestration with tools
├── screens/auth/
│   ├── signup_screen.dart          # name, username, email, password, confirm
│   ├── login_screen.dart
│   └── verification_screen.dart
├── screens/home/
│   ├── home_screen.dart
│   ├── chat_screen.dart            # Main AI chat
│   ├── pdf_search_screen.dart
│   ├── news_screen.dart
│   ├── app_builder_screen.dart
│   └── report_screen.dart
├── utils/
│   ├── pdf_search.dart
│   └── news_service.dart
└── main.dart
supabase/
├── migrations/init.sql
└── functions/ai-agent/index.ts     # Edge function for AI (secure OpenAI key)
.github/workflows/build-apk.yml     # Auto-build APK on push
```

## How to Build APK

### Option 1: GitHub Actions (Recommended - No local setup)
1. Push this repo to GitHub
2. Go to Actions -> Build APK -> Run
3. Download artifact `app-release.apk`
4. Install on tablet/computer

### Option 2: Local
```bash
cd flutter_app
flutter pub get
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

## Supabase Setup

The `supabase/migrations/init.sql` creates:
- `profiles` table (id, name, username UNIQUE, email UNIQUE)
- `chat_histories` table
- `documents` for PDF search
- `reports`
- RLS + trigger `handle_new_user()` to auto-create profile on signup
- Policies prevent duplicates at DB level

Email verification is configured in Supabase Dashboard:
Auth -> Configuration -> Email Auth -> Confirm email = ON
Set Site URL and SMTP (works out-of-the-box with Supabase email).

## Environment Variables

Create `flutter_app/.env`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
OPENAI_API_KEY=sk-... (or use Edge Function secret)
NEWS_API_KEY=your-newsapi-key
```

For Edge Function:
```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

## Security
- Passwords never stored plain - handled by Supabase Auth (bcrypt)
- Username & Email UNIQUE constraints prevent duplicates
- RLS ensures users only see own data
- Email verification required before login
- All API keys server-side in Edge Functions

## AI Agent Prompt

The AI is instructed to be a helpful agentic assistant that can:
- Search PDFs semantically
- Give top 5 news daily
- Build full apps incrementally
- Create reports, docs, presentations, spreadsheets
- Search web, fetch pages, generate images, handle files

Every tool is implemented as a callable function.

---
Built with Flutter + Supabase + OpenAI

--- LIVE DEPLOYMENT ---
Repo: https://github.com/Mahicouragw/ai-super-agent
Supabase Project: https://bwjoqomechsubjvwwbbk.supabase.co (Mumbai ap-south-1)
Project Ref: bwjoqomechsubjvwwbbk
APK: Check Actions tab for app-release.apk artifact
