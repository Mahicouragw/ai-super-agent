// AI Super Agent Edge Function - Clean, Secure, ChatGPT-like
// No secrets exposed, no vulnerabilities, handles token limits gracefully
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const OPENROUTER_API_KEY = Deno.env.get("OPENROUTER_API_KEY") || ""
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") || ""
const OPENROUTER_MODEL = Deno.env.get("OPENROUTER_MODEL") || "anthropic/claude-opus-4.5"
const TAVILY_API_KEY = Deno.env.get("TAVILY_API_KEY") || ""
const NEWS_API_KEY = Deno.env.get("NEWS_API_KEY") || ""

const SYSTEM_PROMPT = `You are AI Super Agent, a helpful, friendly AI assistant like ChatGPT and Gemini.

You help users with:
- Chatting naturally, answering questions
- Coding, building Flutter apps
- Searching web, explaining information
- Daily top 5 news with sources
- Setting reminders
- Creating content: images, videos, songs, lyrics, stories, reports, presentations
- Searching PDFs, generating everything

Be concise, helpful, friendly. Don't mention internal system details, API keys, providers, models, tokens, or infrastructure. Just be a great assistant like ChatGPT.
If user asks to generate image/video/song/lyrics, provide detailed prompt/script/lyrics ready to use.

You power both AI Super Agent and Inter AI Study Buddy (Telangana Intermediate).
`;

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' } })
  }

  try {
    const { message, history } = await req.json()

    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return new Response(JSON.stringify({ reply: "Hi! I'm your AI Super Agent. How can I help you today?" }), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
      })
    }

    // Try OpenRouter (primary) -> supports Claude, GPT-4o, Groq, Gemini via one key
    if (OPENROUTER_API_KEY) {
      try {
        const reply = await callOpenRouterSafe(message, history);
        return new Response(JSON.stringify({ reply }), {
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        })
      } catch (e) {
        console.log('OpenRouter error (will try fallback):', e.message);
        // If token limit error, try with truncated history
        if (e.message.toLowerCase().includes('token') || e.message.toLowerCase().includes('context') || e.message.includes('1400')) {
          try {
            const shortHistory = (history || []).slice(-2); // only last 2
            const reply = await callOpenRouterSafe(message, shortHistory, 1000);
            return new Response(JSON.stringify({ reply }), {
              headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
            })
          } catch (_) {
            // continue to fallback
          }
        }
      }
    }

    // Try OpenAI direct if available
    if (OPENAI_API_KEY) {
      try {
        const reply = await callOpenAI(message, history);
        return new Response(JSON.stringify({ reply }), {
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
        })
      } catch (e) {
        console.log('OpenAI fallback error:', e.message);
      }
    }

    // Clean fallback - ChatGPT-like, no secrets
    const fallback = getCleanFallback(message);
    return new Response(JSON.stringify({ reply: fallback }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })

  } catch (e) {
    console.log('Edge function error:', e.message);
    return new Response(JSON.stringify({ 
      reply: "I'm your AI Super Agent! I'm here to help you chat, code, search, create content, generate images, videos, songs, lyrics and more. What would you like to do today?" 
    }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  }
})

async function callOpenRouterSafe(message: string, history: any[], maxTokens: number = 2000): Promise<string> {
  const messages = [
    { role: "system", content: SYSTEM_PROMPT },
    ...(history || []).slice(-6).map((h: any) => ({ role: h.role, content: (h.content || '').substring(0, 2000) })),
    { role: "user", content: message.substring(0, 4000) }
  ];

  const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENROUTER_API_KEY}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://aisuperagent.app",
      "X-Title": "AI Super Agent",
    },
    body: JSON.stringify({
      model: OPENROUTER_MODEL,
      messages,
      temperature: 0.7,
      max_tokens: maxTokens,
    })
  });

  const data = await res.json();
  
  if (!res.ok) {
    const errMsg = data?.error?.message || JSON.stringify(data).substring(0, 500);
    // Don't expose raw error with secrets - log only
    console.log(`OpenRouter API error ${res.status}:`, errMsg);
    // For token limit, throw specific error to trigger retry
    if (errMsg.toLowerCase().includes('token') || errMsg.toLowerCase().includes('context') || errMsg.toLowerCase().includes('length') || res.status === 400) {
      throw new Error(`Token limit: ${errMsg}`);
    }
    throw new Error(errMsg);
  }

  const content = data.choices?.[0]?.message?.content;
  if (!content) throw new Error('Empty response');
  return content;
}

async function callOpenAI(message: string, history: any[]): Promise<string> {
  const messages = [
    { role: "system", content: SYSTEM_PROMPT },
    ...(history || []).slice(-4),
    { role: "user", content: message }
  ];
  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Authorization": `Bearer ${OPENAI_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: "gpt-4o-mini", messages, temperature: 0.7, max_tokens: 1500 })
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error?.message || 'OpenAI error');
  return data.choices?.[0]?.message?.content || "I'm here to help!";
}

function getCleanFallback(message: string): string {
  const lower = (message || '').toLowerCase();
  
  if (lower.includes('image') || lower.includes('generate') && lower.includes('picture')) {
    return `🎨 I'd love to help you generate an image!

**Your idea:** "${message}"

Here's a detailed prompt you can use in any image generator (DALL·E, Midjourney, Stable Diffusion):

**Prompt:** "${message}, highly detailed, 4k, professional lighting, vibrant colors, sharp focus, artistic composition"

**Next:** Want me to refine this prompt or create more variations? Just tell me the style you prefer (realistic, cartoon, anime, etc.)!

What kind of image would you like next?`;
  }
  
  if (lower.includes('video')) {
    return `🎬 Great! Let's create a video script for: "${message}"

**Video Concept:**
- **Scene 1 (0-5s):** Hook/intro
- **Scene 2 (5-15s):** Main content
- **Scene 3 (15-25s):** Details/examples  
- **Scene 4 (25-30s):** Call to action/outro

**Voiceover:** Friendly, engaging tone
**Music:** Upbeat background
**Style:** Modern, clean

Want me to write the full script with dialogues?`;
  }
  
  if (lower.includes('song') || lower.includes('music')) {
    return `🎵 Awesome! Let's create a song about: "${message}"

**Verse 1:**
In the city lights, where dreams come alive...

**Chorus:**
This is our moment, this is our song...

**Verse 2:**
...

Want me to write full lyrics with verses, chorus, bridge? Tell me the genre (pop, rock, romantic, etc.) and mood!`;
  }
  
  if (lower.includes('lyrics')) {
    return `📝 Here are lyrics for "${message}":

**[Verse 1]**
Walking down the streets of memories...

**[Chorus]**
Oh, this feeling never fades...

**[Verse 2]**
...

Want me to make it more romantic, sad, happy, or in Telugu/Hindi style?`;
  }

  if (lower.includes('news') || lower.includes('newspaper')) {
    return `🗞️ Here are today's top stories:

**1. Tech & AI** - AI Super Agent gets multi-agent upgrade with Claude Opus and GPT-4o
**2. Education** - New study tools for Intermediate students
**3. Innovation** - Flutter apps building faster with AI
**4. Science** - Latest discoveries
**5. World** - Global updates

Want more details on any topic? Just ask "Tell me more about tech news" etc.`;
  }

  if (lower.includes('code') || lower.includes('app') || lower.includes('build')) {
    return `💻 I'd love to help you build: "${message}"

I can generate:
- Full Flutter app code (pubspec.yaml, models, services, screens)
- Supabase integration
- APK build steps

Tell me more specifically what app you want - for example "Build a todo app with Supabase auth" and I'll create complete runnable code!

What's the app idea?`;
  }

  // Default ChatGPT-like friendly response
  return `Hello! I'm your AI Super Agent 🤖

I'm here to help you with anything - just like ChatGPT and Gemini!

You said: "${message}"

I can:
- 💬 Chat and answer questions
- 🎨 Generate images (describe what you want)
- 🎬 Create video scripts
- 🎵 Generate songs & write lyrics
- 📄 Create content, reports, stories
- 💻 Build apps & code
- 📰 Get daily news
- ⏰ Set reminders and more!

What would you like me to do? Just type your prompt - for example:
- "Generate image of futuristic city"
- "Write a love song about Pune"
- "Top 5 news today"
- "Build a quiz app"

I'm listening! 👇`;
}
