import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('AI Super Agent - Terms & Conditions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Last updated: July 24, 2026', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          _section('1. Acceptance of Terms', 'By creating an account and using AI Super Agent, you agree to these Terms & Conditions and Privacy Policy. AI Super Agent provides AI assistance with Claude, GPT-4o, Groq, Gemini and 30+ skills.'),
          _section('2. Accounts', 'You must provide accurate Name, Email, Password. You are responsible for keeping your account secure. One account per email. If email already used, we will show "This email is already used" - please login instead. Accounts are saved in server, cloud storage, and local storage on your device for Continue with AI Super Agent feature.'),
          _section('3. AI Usage', 'AI Super Agent provides AI-generated responses for information, coding, content creation, images, videos, songs, lyrics, news, etc. AI responses may not always be accurate. Verify important information. Do not use for illegal activities.'),
          _section('4. Free Models', 'We provide expensive quality AI models free forever via OpenRouter :free suffix (20 RPM, 50/day free, 1000/day after \$10 credits once). Models include Qwen3 Coder (best for app building), DeepSeek R1 (reasoning), Gemini 2.0 Flash, Nemotron Ultra, Llama 70B, Hermes 405B, Flux image generation. No credit card needed to start. Works like real agent AI in computers, locally safely.'),
          _section('5. Content Generation', 'You can generate images, videos, songs, lyrics, content, code, reports. You own your creations. Do not generate harmful, illegal, or infringing content. We may review content for safety.'),
          _section('6. Privacy', 'We respect your privacy. Your data is saved safely with RLS, bcrypt passwords, verification email via Resend/Gmail SMTP from AI Super Agent. API keys stored only on device, never uploaded. See Privacy Policy for details.'),
          _section('7. No Money Required', 'AI Super Agent works free without asking for money. If one day you get money and want to support, you can pay, but not required. Free models work like real agent without credit limits.'),
          _section('8. Updates Without Reinstall', 'App uses Supabase remote config app_config table for updates without reinstall. Features, models, auth config sync when online, cached offline. Works online when logging in, offline after for many features.'),
          _section('9. TalkBack & Accessibility', 'App is fully TalkBack accessible with Semantics labels, screen reader navigation, voice replies. Licensed under MIT with open source attributions.'),
          _section('10. Termination', 'We may suspend accounts that violate terms, spam, or abuse free tier. You can delete account anytime via Settings.'),
          _section('11. Changes', 'We may update terms. Continued use after changes means acceptance.'),
          _section('12. Contact', 'For questions: AI Super Agent <numbersareplaying@gmail.com> via Resend/Gmail SMTP real-time OTP system.'),
          const SizedBox(height: 20),
          Card(
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('AI Super Agent Email', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('All verification emails sent from AI Super Agent (not Supabase) like Gmail/Google real apps via Resend onboarding@resend.dev or Gmail SMTP numbersareplaying@gmail.com with App Password - free unlimited real-time.', style: TextStyle(fontSize: 11)),
                const SizedBox(height: 8),
                const Text('Continue with AI Super Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const Text('Shows accounts created on this device, saved in server, cloud storage, local storage - like Google account chooser but branded as AI Super Agent.', style: TextStyle(fontSize: 11)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text('I Agree to Terms & Conditions'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://github.com/Mahicouragw/ai-super-agent')),
            child: const Text('View Full Terms on GitHub'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.black87)),
      ]),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('AI Super Agent - Privacy Policy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Last updated: July 24, 2026', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          _section('Data We Collect', 'Name, Email, Password (bcrypt hashed), username (from name), chat history, generations (images/videos/songs/lyrics/content prompts), PDFs, reports, reminders, study progress, device accounts list, selected model. All saved in Supabase Mumbai ap-south-1 with RLS.'),
          _section('How We Use', 'To provide AI assistance, authenticate via OTP from AI Super Agent (Resend/Gmail SMTP), show Continue with AI Super Agent accounts, save generations, sync across devices via cloud storage, offline cache.'),
          _section('Storage', 'Server: Supabase profiles, chat_histories, documents, reports, reminders, study_progress, otp_codes, generations, app_config, offline_cache tables with RLS. Cloud: Supabase cloud storage. Local: SharedPreferences device_accounts, selected_model, offline_cache for offline use without reinstall.'),
          _section('Email', 'Verification emails sent from AI Super Agent <onboarding@resend.dev> via Resend (free 100/day) or Gmail SMTP numbersareplaying@gmail.com with App Password (free 500/day, unlimited real-time). Not from Supabase default. Like Gmail/Google verification.'),
          _section('API Keys', 'OpenRouter API key sk-or-v1-... stored in Supabase Edge Function secrets and GitHub Secrets, not in app code. User API keys (Gemini, OpenRouter) stored only on device via SharedPreferences, never uploaded, never in database.'),
          _section('Third Parties', 'OpenRouter for AI models (Qwen3 Coder, DeepSeek R1, Gemini 2.0 Flash, etc free), Supabase for auth/storage, Resend/Gmail for emails. No selling data.'),
          _section('Your Rights', 'Access, delete, export your data via Settings. Delete account clears server + cloud + local.'),
          _section('Security', 'Passwords bcrypt, RLS policies, JWT, HTTPS, OTP 6-digit expires 10 min, attempts limit 5, hashed OTP, no secrets in client, no vulnerabilities showing.'),
          _section('Children', 'Not for children under 13 without parental consent.'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: const Text('I Agree to Privacy Policy'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(fontSize: 11, height: 1.4)),
      ]),
    );
  }
}
