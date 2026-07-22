# How to get APK for Tablet / Computer

## Quick Method - GitHub Actions Builds APK automatically

1. After repo is created and pushed, Go to GitHub -> Actions tab -> Build APK -> Run workflow
2. Wait 5-10 mins
3. Download artifact `app-release-apk`
4. On tablet: allow install from unknown sources, install APK
5. On computer: use BlueStacks / Android Studio emulator, or build desktop version: `flutter build windows` / `flutter build linux` / `flutter build macos`

## Local Build (if you have Flutter SDK)
```bash
cd flutter_app
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Install .env
Before building, create .env with Supabase URL/keys - otherwise app will show "Supabase not configured" but still runs offline fallback.

## Wonderful Supabase Project Auto-Setup
See ../supabase/migrations/init.sql - run in Supabase SQL Editor. It creates:
- profiles with UNIQUE username, email
- triggers for auto-profile creation
- RLS
- chat_histories, documents, reports tables

Email verification is enabled in Dashboard -> Auth -> Email -> Confirm email ON.

## App Flow
Signup: name, username, email, password, confirm password -> checks duplicate username/email both in Flutter and via DB constraint -> Supabase Auth signUp -> verification email -> click link -> login -> stored safely in Supabase -> RLS protects

Login: email, password -> Supabase returns session -> check emailConfirmedAt -> home

Home has AI Agent that does all work you tell it.

## AI Agent Replicating Arena AI Skills
We implemented services/ai_agent_service.dart with:
- search_pdfs() - uses documents table + PdfSearchUtil
- get_top_news() - NewsAPI or mock top 5
- build_app() - generates Flutter code like Arena
- create_report() - report series with JSON save to reports table
- web_search, fetch_page etc via Edge Function

All documented in lib/services/ai_agent_service.dart
