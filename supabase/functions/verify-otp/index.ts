import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || ""
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || Deno.env.get("SERVICE_ROLE_KEY") || ""

function hashOTP(otp: string): string {
  return btoa(otp);
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type' } })
  }

  try {
    const { email, otp, name, password } = await req.json()

    if (!email || !otp) {
      return new Response(JSON.stringify({ error: 'Email and OTP required' }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    if (otp.length !== 6) {
      return new Response(JSON.stringify({ error: 'OTP must be 6 digits' }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Find latest OTP for this email that is not expired and not verified
    const { data: otpRecords, error: fetchError } = await supabase
      .from('otp_codes')
      .select('*')
      .eq('email', email.toLowerCase())
      .eq('verified', false)
      .gt('expires_at', new Date().toISOString())
      .order('created_at', { ascending: false })
      .limit(1);

    if (fetchError) {
      throw new Error(`Failed to fetch OTP: ${fetchError.message}`);
    }

    if (!otpRecords || otpRecords.length === 0) {
      return new Response(JSON.stringify({ error: 'No valid OTP found for this email or OTP expired. Please request new code.' }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    const record = otpRecords[0];

    // Check attempts
    if (record.attempts >= 5) {
      return new Response(JSON.stringify({ error: 'Too many attempts. Please request new OTP.' }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    // Verify OTP - compare hash or plain (plain for dev)
    const isValid = record.otp_hash === hashOTP(otp) || record.otp_plain === otp;

    if (!isValid) {
      // Increment attempts
      await supabase.from('otp_codes').update({ attempts: (record.attempts || 0) + 1 }).eq('id', record.id);
      return new Response(JSON.stringify({ error: 'Invalid OTP. Please check 6-digit code and try again.' }), { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
    }

    // Mark OTP as verified
    await supabase.from('otp_codes').update({ verified: true }).eq('id', record.id);

    // If password and name provided, create Supabase Auth user (for seamless flow to dashboard)
    let authUser = null;
    if (password && name) {
      try {
        // Try to create user
        const { data: signUpData, error: signUpError } = await supabase.auth.admin.createUser({
          email: email.toLowerCase(),
          password: password,
          email_confirm: true, // auto-confirm since OTP verified
          user_metadata: {
            name: name,
            username: name.toLowerCase().replace(/\s+/g, '_') + '_' + Math.floor(Math.random()*1000),
            email: email.toLowerCase(),
          }
        });

        if (signUpError) {
          // If user already exists, try to sign in? For OTP flow we allow existing users to verify and go to dashboard
          console.log('Create user error (may already exist):', signUpError.message);
        } else {
          authUser = signUpData.user;
        }
      } catch (e) {
        console.log('Admin create user failed:', e.message);
      }
    }

    // Also upsert profile
    try {
      if (authUser) {
        await supabase.from('profiles').upsert({
          id: authUser.id,
          name: name || email.split('@')[0],
          username: (name || email.split('@')[0]).toLowerCase().replace(/\s+/g, '_') + '_' + Math.floor(Math.random()*1000),
          email: email.toLowerCase(),
        });
      }
    } catch (e) {
      console.log('Profile upsert error:', e.message);
    }

    return new Response(JSON.stringify({
      success: true,
      message: 'OTP verified successfully! Redirecting to AI Super Agent dashboard...',
      verified: true,
      email: email.toLowerCase(),
      name: name || record.name,
      authUserId: authUser?.id || null,
      nextStep: 'dashboard',
      dashboardFeatures: [
        'send a prompt',
        'choose models (Claude Opus, GPT-4o, Groq Llama, Gemini)',
        'talk with AI agent like ChatGPT and Gemini',
        'ask questions',
        'do more things',
        'create content, generate videos, images, everything, generate songs, write lyrics'
      ]
    }), {
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })

  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
    })
  }
})
