# Paste Your Tokens Here - Format

You selected "Paste tokens directly". Please send NEXT message with tokens in EXACT format below. I will use them immediately and then you should revoke/re-generate them after.

## Format to copy-paste:

```
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SUPABASE_ACCESS_TOKEN=sbp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SUPABASE_ORG_ID= (optional, I can list your orgs if missing - get from https://supabase.com/dashboard -> org settings)
SUPABASE_DB_PASSWORD=YourStrongDbPassword123!
GEMINI_API_KEY= (if you want Gemini instead of OpenAI, e.g., AIza...)
OPENAI_API_KEY=sk-... (optional, if you have)
NEWS_API_KEY= (optional, for top 5 news live)
```

## What I'll do in <2 minutes after you send:

1. **GitHub Repo Creation**
   - `POST https://api.github.com/user/repos` with name `ai-super-agent` public
   - `git init/add/commit/push` to that repo
   - Add secrets placeholder file

2. **Supabase Wonderful Project Creation (Mumbai ap-south-1)**
   - List your orgs `GET /v1/organizations`
   - Create project `POST /v1/projects` name: ai-super-agent, region: ap-south-1
   - Wait for project healthy
   - Get project URL & anon key
   - Run `supabase/migrations/init.sql` via SQL API to create:
     - profiles (name, username UNIQUE, email UNIQUE, duplicate prevention at DB level + app level)
     - chat_histories, documents, reports
     - RLS policies, trigger handle_new_user() for auto profile + email verification handling
   - Enable Email confirmation in Auth config (Supabase does via API/default ON)
   - Create `.env` file locally

3. **Edge Function Deploy (AI Agent Brain)**
   - If you give GEMINI_API_KEY, I'll adapt edge function at `supabase/functions/ai-agent/index.ts` to support Gemini (Google Generative AI)
   - Adapted to handle both OpenAI and Gemini via switch
   - Deploy via Supabase CLI would need linking - I will guide if token limited

4. **APK Build**
   - GitHub Actions workflow `.github/workflows/build-apk.yml` will auto-trigger on push
   - Builds `flutter build apk --release` on Ubuntu with Java 17 + Flutter 3.22
   - You download from Actions -> Artifacts -> app-release-apk -> install on tablet/computer

## Security After
- IMMEDIATELY after I push, go to:
  - GitHub -> Settings -> Developer settings -> Tokens -> Regenerate / Delete the classic token
  - Supabase -> Account -> Access Tokens -> Delete
- Tokens will NOT be committed to repo (gitignored)
- I will NOT log them in final files

## If Supabase Management API Is Restricted (Free plan sometimes blocks project creation via API)
Fallback: I'll give you 1-click instructions to create project manually in Dashboard in 30 seconds, then just give me the new project's URL + anon/service key and I'll run the SQL and finish.

## Ready?
Paste tokens now in next message. If you prefer not to expose in chat history long-term, you can delete the message after I confirm push.

