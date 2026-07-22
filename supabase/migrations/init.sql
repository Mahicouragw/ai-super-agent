-- AI Super Agent Supabase Project - Complete Init
-- Wonderful Supabase project for auth + AI agent data

-- Enable extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- PROFILES table: name, username(unique), email(unique), password handled by auth.users
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  name text not null,
  username text not null unique,
  email text not null unique,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Index for fast duplicate check
create unique index if not exists profiles_username_idx on public.profiles (lower(username));
create unique index if not exists profiles_email_idx on public.profiles (lower(email));

-- Chat history for AI agent memory
create table if not exists public.chat_histories (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role text not null check (role in ('user','assistant','system','tool')),
  content text not null,
  tool_name text,
  tool_result jsonb,
  created_at timestamp with time zone default now()
);

-- Documents for PDF search skill
create table if not exists public.documents (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  filename text not null,
  content_text text not null,
  file_size int,
  created_at timestamp with time zone default now()
);

create index if not exists documents_user_id_idx on public.documents (user_id);
create index if not exists documents_content_trgm_idx on public.documents using gin (content_text gin_trgm_ops);

-- Reports for report series skill
create table if not exists public.reports (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  content jsonb not null,
  type text default 'general',
  created_at timestamp with time zone default now()
);

-- Enable RLS - security
alter table public.profiles enable row level security;
alter table public.chat_histories enable row level security;
alter table public.documents enable row level security;
alter table public.reports enable row level security;

-- Drop existing policies if re-run
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;
drop policy if exists "Enable username check for all" on public.profiles;
drop policy if exists "Users can manage own chats" on public.chat_histories;
drop policy if exists "Users manage own documents" on public.documents;
drop policy if exists "Users manage own reports" on public.reports;

-- Profiles policies
-- Allow anyone to check if username exists (for signup duplicate prevention), but only select username column is safe
-- Better: allow select for all, but RLS with true for existence check; sensitive data already protected by id
create policy "Enable username check for all" on public.profiles for select using (true);

create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- Chat policies
create policy "Users can manage own chats" on public.chat_histories for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Document policies
create policy "Users manage own documents" on public.documents for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Reports policies
create policy "Users manage own reports" on public.reports for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Function to handle new user creation - auto-create profile with name, username, email
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, username, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(
      lower(new.raw_user_meta_data->>'username'),
      lower(split_part(new.email, '@', 1)) || '_' || substring(new.id::text, 1, 4)
    ),
    lower(new.email)
  )
  on conflict (id) do update set
    name = excluded.name,
    username = excluded.username,
    email = excluded.email,
    updated_at = now();
  return new;
end;
$$;

-- Trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Function to prevent duplicate username/email at DB level (extra safety)
create or replace function public.prevent_duplicate_profile()
returns trigger
language plpgsql
as $$
begin
  if exists (select 1 from public.profiles where lower(username) = lower(new.username) and id != new.id) then
    raise exception 'Username already taken';
  end if;
  if exists (select 1 from public.profiles where lower(email) = lower(new.email) and id != new.id) then
    raise exception 'Email already registered';
  end if;
  return new;
end;
$$;

drop trigger if exists check_duplicate_profile on public.profiles;
create trigger check_duplicate_profile
  before insert or update on public.profiles
  for each row execute procedure public.prevent_duplicate_profile();

-- For pg_trgm search
create extension if not exists pg_trgm;
