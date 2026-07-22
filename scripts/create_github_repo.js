// Script to create GitHub repo and push code
// Usage: GITHUB_TOKEN=ghp_... node create_github_repo.js [repo-name]
// Default repo name: ai-super-agent

const { execSync } = require('child_process');
const fs = require('fs');

async function createRepo() {
  const token = process.env.GITHUB_TOKEN;
  const repoName = process.argv[2] || 'ai-super-agent';
  
  if (!token) {
    console.log('GITHUB_TOKEN not set. Manual steps:');
    console.log(`
1. Go to https://github.com/new
2. Create repo: ${repoName} (public/private)
3. Then run:
   git init
   git add .
   git commit -m "Initial: AI Super Agent with Supabase Auth, PDF Search, News, App Builder, Reports - APK ready"
   git branch -M main
   git remote add origin https://github.com/YOURUSERNAME/${repoName}.git
   git push -u origin main
4. Add secrets in Settings -> Secrets:
   - SUPABASE_URL
   - SUPABASE_ANON_KEY
   - OPENAI_API_KEY
   - NEWS_API_KEY
5. Trigger GitHub Action Build APK - download APK artifact
`);
    return;
  }

  console.log(`Creating GitHub repo: ${repoName}`);

  const res = await fetch('https://api.github.com/user/repos', {
    method: 'POST',
    headers: {
      'Authorization': `token ${token}`,
      'Content-Type': 'application/json',
      'Accept': 'application/vnd.github.v3+json'
    },
    body: JSON.stringify({
      name: repoName,
      description: 'AI Super Agent - Flutter + Supabase Auth (name, username, email, password, confirm, verification) + AI skills: PDF search, top 5 news, app builder, report series. APK ready.',
      private: false,
      auto_init: false,
    })
  });

  const data = await res.json();
  console.log('GitHub API response:', JSON.stringify(data, null, 2));

  if (data.html_url) {
    console.log(`\n✅ Repo created: ${data.html_url}`);
    console.log(`Clone URL: ${data.clone_url}`);

    // Auto push if git available
    try {
      console.log('\nAttempting to push local code...');
      // We are in scripts folder, go up to project root
      process.chdir(__dirname + '/..');
      // Check if git repo already
      try { execSync('git rev-parse --git-dir'); console.log('Existing git repo found'); }
      catch { execSync('git init'); console.log('git init done'); }

      execSync('git add .');
      execSync('git commit -m "Initial: AI Super Agent complete with Flutter + Supabase + AI skills" || echo "commit maybe already"');
      execSync('git branch -M main');
      
      // Use token for auth
      const remoteUrl = data.clone_url.replace('https://', `https://${token}@`);
      try { execSync(`git remote remove origin`); } catch {}
      execSync(`git remote add origin ${remoteUrl}`);
      execSync('git push -u origin main');
      console.log('✅ Code pushed to GitHub!');
      console.log('\nNext: Enable GitHub Actions to build APK automatically.');
    } catch (e) {
      console.error('Auto push failed, push manually:', e.message);
    }
  } else {
    console.error('Failed:', data);
  }
}

createRepo();
