// Supabase Edge Function - AI Super Agent with all skills
// Supports OpenAI, Gemini, Claude via env switch
// Deno runtime
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") || ""
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") || ""
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY") || ""
const TAVILY_API_KEY = Deno.env.get("TAVILY_API_KEY") || ""
const NEWS_API_KEY = Deno.env.get("NEWS_API_KEY") || ""
const AI_PROVIDER = Deno.env.get("AI_PROVIDER") || (GEMINI_API_KEY ? "gemini" : OPENAI_API_KEY ? "openai" : "fallback")

const SYSTEM_PROMPT = `
You are AI Super Agent, a helpful agentic assistant with all skills like Arena AI, built for Pune user:

CORE AUTH SYSTEM (Supabase):
- Signup fields: name, username UNIQUE, email UNIQUE, password, confirm password
- Verification: email sent via Supabase, no duplicates allowed at app level + DB constraint
- Storage: profiles table, RLS protected, password bcrypt via auth.users, trigger handle_new_user()

AI SKILLS (all installed like Arena):
1. PDF Search - semantic search over user-uploaded docs stored in Supabase documents table via file_picker + Syncfusion PDF text extractor
2. Top 5 News - fetch daily news via NewsAPI / Tavily, summarize with sources, citations [id](url)
3. App Builder - generate full Flutter apps incrementally: scaffold -> models/services -> UI -> Supabase -> APK build via flutter build apk --release - produce complete runnable files like Arena does
4. Report Series - create professional reports with sections, charts, save to reports table, export markdown/pdf/excel, support weekly/monthly series - how I create reports: template -> data fetch -> markdown -> charts -> save
5. Web Search - use Tavily API for live search with citations
6. Fetch Webpage - summarize any URL via fetch_page
7. File Management - create/read/manage project files via workspace tools
8. Image Search/Generation + Speech generation
9. Code Building - thorough, builds apps projects incrementally across messages
10. All work user tells you to do - you are general agent

You are running inside Supabase Edge Function, powering a Flutter APK app installable on tablet/computer.
Be agentic: do work, create files, don't just describe.
`

const tools = [
  { type: "function", function: { name: "search_pdfs", description: "Search PDFs stored by user in Supabase documents table", parameters: { type: "object", properties: { query: { type: "string" } }, required: ["query"] } } },
  { type: "function", function: { name: "get_top_news", description: "Get top 5 news of today with summaries and sources", parameters: { type: "object", properties: { category: { type: "string" } }, required: [] } } },
  { type: "function", function: { name: "build_app", description: "Generate Flutter app code from prompt, incremental building", parameters: { type: "object", properties: { prompt: { type: "string" } }, required: ["prompt"] } } },
  { type: "function", function: { name: "create_report", description: "Create professional report series with title, type, sections", parameters: { type: "object", properties: { title: { type: "string" }, type: { type: "string" }, details: { type: "string" } }, required: ["title"] } } },
  { type: "function", function: { name: "web_search", description: "Search web for current info with citations", parameters: { type: "object", properties: { query: { type: "string" } }, required: ["query"] } } }
]

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' } })
  }

  try {
    const { message, history, system_prompt } = await req.json()
    const effectiveProvider = AI_PROVIDER

    if (effectiveProvider === "gemini" && GEMINI_API_KEY) {
      const reply = await callGemini(message, history, system_prompt)
      return new Response(JSON.stringify({ reply, provider: "gemini" }), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    if (effectiveProvider === "openai" && OPENAI_API_KEY) {
      const reply = await callOpenAI(message, history, system_prompt)
      return new Response(JSON.stringify({ reply, provider: "openai" }), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    if (effectiveProvider === "claude" && CLAUDE_API_KEY) {
      const reply = await callClaude(message, history, system_prompt)
      return new Response(JSON.stringify({ reply, provider: "claude" }), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    // Fallback without API keys - still useful skill routing
    const fallback = generateFallback(message)
    return new Response(JSON.stringify({ reply: fallback, provider: "fallback" }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })

  } catch (e) {
    return new Response(JSON.stringify({ error: e.message, reply: generateFallback("error") }), {
      status: 200,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  }
})

async function callGemini(message: string, history: any[], system_prompt?: string): Promise<string> {
  // Google Gemini 1.5 Flash
  const contents = [
    { role: "user", parts: [{ text: (system_prompt || SYSTEM_PROMPT) + "\n\nHistory:\n" + JSON.stringify((history||[]).slice(-8)) + "\n\nUser: " + message }] }
  ]
  const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ contents, generationConfig: { temperature: 0.7, maxOutputTokens: 2048 } })
  })
  const data = await res.json()
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text
  if (!text) throw new Error("Gemini no response: " + JSON.stringify(data).substring(0, 500))
  // Handle tool-like behavior for news/search
  if (message.toLowerCase().includes("top 5 news") || message.toLowerCase().includes("top five news")) {
    const news = await handleTopNews()
    return text + "\n\n---\n" + news
  }
  return text
}

async function callClaude(message: string, history: any[], system_prompt?: string): Promise<string> {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": CLAUDE_API_KEY, "Content-Type": "application/json", "anthropic-version": "2023-06-01" },
    body: JSON.stringify({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 2048,
      system: system_prompt || SYSTEM_PROMPT,
      messages: [...(history||[]).slice(-8).map((h:any)=>({ role: h.role === 'assistant' ? 'assistant' : 'user', content: h.content })), { role: "user", content: message }]
    })
  })
  const data = await res.json()
  return data.content?.[0]?.text || JSON.stringify(data)
}

async function callOpenAI(message: string, history: any[], system_prompt?: string): Promise<string> {
  const messages = [
    { role: "system", content: system_prompt || SYSTEM_PROMPT },
    ...(history || []).slice(-10),
    { role: "user", content: message }
  ]
  const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Authorization": `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: "gpt-4o-mini", messages, tools, tool_choice: "auto", temperature: 0.7 })
  })
  const data = await openaiRes.json()
  const choice = data.choices?.[0]
  if (choice?.message?.tool_calls) {
    let toolResults = []
    for (const tc of choice.message.tool_calls) {
      const args = JSON.parse(tc.function.arguments)
      let result = ""
      if (tc.function.name === "get_top_news") result = await handleTopNews()
      else if (tc.function.name === "web_search") result = await handleWebSearch(args.query)
      else result = `Tool ${tc.function.name} executed with ${JSON.stringify(args)}.`
      toolResults.push({ tool_call_id: tc.id, role: "tool", content: result })
    }
    const secondRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gpt-4o-mini", messages: [...messages, choice.message, ...toolResults], temperature: 0.7 })
    })
    const secondData = await secondRes.json()
    return secondData.choices?.[0]?.message?.content || "Done."
  }
  return choice?.message?.content || "I'm your AI Super Agent!"
}

function generateFallback(message: string): string {
  const lower = (message||"").toLowerCase()
  if (lower.includes("top 5 news") || lower.includes("top five")) {
    return `🗞️ **Top 5 News (Fallback - set API keys in Supabase secrets)**

Run: supabase secrets set GEMINI_API_KEY=... or OPENAI_API_KEY=... NEWS_API_KEY=...

Mock Top 5 for now:
1. AI Super Agent Launched - Flutter APK with PDF search, news, app builder, reports
2. Supabase Auth - secure email verification, duplicate checks
3. Flutter 3.22 faster APK builds for tablets
4. Tablet productivity apps rising in 2026
5. Pune emerging as AI hub

Set keys for live data. Current AI Provider: ${AI_PROVIDER}, but no key found for it - set secret.`
  }
  if (lower.includes("pdf")) return `📄 **PDF Search Skill Ready** - Upload PDFs in app, extracted, stored secure in Supabase documents with RLS. Ask "search PDFs for X". Message: "${message}"`
  if (lower.includes("build") && lower.includes("app")) return `📱 **App Builder - How I build apps incrementally like Arena AI**
1. pubspec.yaml + deps
2. Models (user_model, etc)
3. Services (supabase_service, ai_agent_service)
4. Screens (auth with name, username unique check, email unique+verification, password+confirm)
5. Supabase migration init.sql + RLS + trigger
6. Edge function for AI brain
7. flutter build apk --release via GitHub Actions

Your prompt: "${message}" - ask specifics and I generate full code.`
  if (lower.includes("report")) return `📊 **Report Series Skill** - Template -> data fetch (web/DB) -> markdown -> charts -> save to reports table. Weekly/monthly series. Prompt: "${message}"`
  return `🤖 AI Super Agent (Edge Function) ready! Provider: ${AI_PROVIDER}

Received: "${message}"

Skills: PDF Search, Top 5 News, App Builder (how I build apps), Report Series, Web Search, Fetch, File Mgmt, Image Gen, Build.

Set GEMINI_API_KEY or OPENAI_API_KEY in Supabase secrets to enable full intelligence.

Auth: name, username unique NOT duplicate, email unique NOT duplicate, password+confirm, verification email sent, stored safely in Supabase (RLS, bcrypt).`
}

async function handleTopNews(): Promise<string> {
  if (!NEWS_API_KEY) return "NEWS_API_KEY not set - add in Edge Function secrets for live news. Showing mock above."
  try {
    const res = await fetch(`https://newsapi.org/v2/top-headlines?country=us&pageSize=5&apiKey=${NEWS_API_KEY}`)
    const data = await res.json()
    return "Live News:\n" + JSON.stringify(data.articles.map((a:any)=>({title:a.title, desc:a.description, url:a.url, source:a.source.name})), null, 2)
  } catch (e) { return `News fetch failed: ${e.message}` }
}

async function handleWebSearch(query: string): Promise<string> {
  if (!TAVILY_API_KEY) return `TAVILY_API_KEY not set. Would search "${query}"`
  try {
    const res = await fetch("https://api.tavily.com/search", { method:"POST", headers:{"Content-Type":"application/json"}, body:JSON.stringify({api_key:TAVILY_API_KEY, query, max_results:5}) })
    return JSON.stringify(await res.json())
  } catch (e) { return `Search failed: ${e.message}` }
}
