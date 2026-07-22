# Security Setup - How tokens are handled

## DO NOT paste tokens directly in chat

If you plan to give me GitHub and Supabase tokens, here's secure way:

### Option 1: Environment variables (recommended for this workspace)
Set them as bash env vars and I'll use via scripts without logging:
```bash
export GITHUB_TOKEN=ghp_xxxx
export SUPABASE_ACCESS_TOKEN=sbp_xxxx
export SUPABASE_ORG_ID=... (optional)
node scripts/create_github_repo.js
node scripts/setup_supabase.js
```

### Option 2: GitHub Codespaces Secrets / local .env
Create flutter_app/.env with keys - this file is gitignored.

### What tokens are for
- GitHub token: create repo, push code, enable Actions for APK build
- Supabase token: create project via Management API, run init.sql, deploy edge function

### After use
- Tokens should be revoked/regenerated
- I will delete any token files after use
- No token is committed to repo

### Auth Security in App
- Password: hashed by Supabase Auth bcrypt, never plain storage
- Username UNIQUE index + email UNIQUE index prevents duplicates
- RLS policies protect data
- Email verification required - Supabase sends email via SMTP
- Session stored securely with PKCE flow

### If you still want to paste tokens in chat
We can proceed, but be aware:
- Tokens may be logged in conversation history
- Immediately revoke after repo creation
- Better to use short-lived fine-grained GitHub token with only repo scope
