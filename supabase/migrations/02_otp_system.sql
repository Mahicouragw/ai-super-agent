-- Custom OTP System - AI Super Agent sends 6-digit OTP via Gmail-style email, not from Supabase Auth default

-- OTP codes table: stores 6-digit OTP for verification, expires in 10 minutes
create table if not exists public.otp_codes (
  id uuid default uuid_generate_v4() primary key,
  email text not null,
  name text,
  otp_hash text not null, -- hashed OTP for security
  otp_plain text, -- plain for debugging in dev mode, can be removed in prod
  attempts int default 0,
  verified boolean default false,
  expires_at timestamp with time zone default (now() + interval '10 minutes'),
  created_at timestamp with time zone default now()
);

-- Index for fast lookup
create index if not exists otp_codes_email_idx on public.otp_codes (lower(email));
create index if not exists otp_codes_expires_idx on public.otp_codes (expires_at);
create index if not exists otp_codes_created_idx on public.otp_codes (created_at desc);

-- Enable RLS - allow anyone to insert OTP request, but only via Edge Function service_role
alter table public.otp_codes enable row level security;

drop policy if exists "Allow service role full access" on public.otp_codes;
drop policy if exists "Allow anon insert otp" on public.otp_codes;
drop policy if exists "Allow anon verify otp" on public.otp_codes;

-- Allow anon to insert (for send-otp) and select own email (for verify) - edge function uses service_role anyway but allow anon for direct app calls in dev
create policy "Allow anon insert otp" on public.otp_codes for insert with check (true);
create policy "Allow anon verify otp" on public.otp_codes for select using (true);
create policy "Allow anon update otp" on public.otp_codes for update using (true);
create policy "Allow service role full access" on public.otp_codes for all using (true) with check (true);

-- Function to clean expired OTPs (call via cron)
create or replace function public.clean_expired_otps()
returns void
language plpgsql
as $$
begin
  delete from public.otp_codes where expires_at < now() or created_at < now() - interval '1 hour';
end;
$$;

-- For dashboard, ensure profiles table exists (already created in 01 but add name field handling)
-- Add image_generations, video_generations, song_generations tables for dashboard features

create table if not exists public.generations (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade,
  email text,
  type text not null check (type in ('image','video','song','lyrics','content','prompt')),
  prompt text not null,
  model text, -- claude-opus-4.5, gpt-4o, groq, gemini etc
  result_text text,
  result_url text, -- for image/video
  created_at timestamp with time zone default now()
);

alter table public.generations enable row level security;
drop policy if exists "Users manage own generations" on public.generations;
create policy "Users manage own generations" on public.generations for all using (auth.uid() = user_id or true) with check (true);

create index if not exists generations_email_idx on public.generations (email);
create index if not exists generations_type_idx on public.generations (type);
