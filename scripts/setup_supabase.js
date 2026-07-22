// Script to auto-create Supabase project and configure it
// Usage: SUPABASE_ACCESS_TOKEN=sbp_... node setup_supabase.js
// Requires Supabase Management API token

const fs = require('fs');
const path = require('path');

async function createProject() {
  const token = process.env.SUPABASE_ACCESS_TOKEN;
  if (!token) {
    console.log('SUPABASE_ACCESS_TOKEN not set. Manual setup instructions:');
    console.log(`
1. Go to https://supabase.com/dashboard
2. New Project -> name: ai-super-agent, region: ap-south-1 (Mumbai for Pune user)
3. Set DB password
4. After creation, go to SQL Editor -> New Query -> paste content of supabase/migrations/init.sql -> Run
5. Auth -> Configuration:
   - Enable Email Confirmations = ON
   - Site URL: io.supabase.aisuperagent://login-callback/
   - Disable insecure email/password? No, keep enabled
6. Go to Project Settings -> API -> copy URL and anon key -> put in flutter_app/.env
7. For AI Edge Function:
   supabase link --project-ref YOUR_REF
   supabase functions deploy ai-agent
   supabase secrets set OPENAI_API_KEY=sk-... NEWS_API_KEY=... TAVILY_API_KEY=...
`);
    return;
  }

  console.log('Creating Supabase project via Management API...');
  const res = await fetch('https://api.supabase.com/v1/projects', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name: 'ai-super-agent',
      organization_id: process.env.SUPABASE_ORG_ID, // user must provide org id or we list orgs
      region: 'ap-south-1',
      plan: 'free',
      db_pass: process.env.SUPABASE_DB_PASSWORD || 'AiSuperAgent123!',
    })
  });

  const data = await res.json();
  console.log('Project creation response:', JSON.stringify(data, null, 2));

  if (data.id) {
    const sql = fs.readFileSync(path.join(__dirname, '../supabase/migrations/init.sql'), 'utf8');
    console.log('Project created! Now run the SQL in SQL Editor:\n', sql.substring(0, 500) + '...');
  }
}

async function listOrgs() {
  const token = process.env.SUPABASE_ACCESS_TOKEN;
  if (!token) return;
  const res = await fetch('https://api.supabase.com/v1/organizations', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const data = await res.json();
  console.log('Organizations:', JSON.stringify(data, null, 2));
}

(async () => {
  await listOrgs();
  await createProject();
})();
