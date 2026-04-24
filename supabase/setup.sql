-- SNS Dashboard setup SQL
-- Run this in Supabase Dashboard -> SQL Editor.
-- This app is currently configured as a personal/internal dashboard, so RLS is disabled.

create table if not exists public.contents (
  id bigint generated always as identity primary key,
  title text,
  master_text text,
  status text default 'draft',
  scheduled_at timestamptz,
  platforms text[],
  platform_drafts jsonb default '{}',
  publish_results jsonb default '{}',
  registrant text,
  registered_at text,
  first_published_at timestamptz,
  updated_at timestamptz
);

create table if not exists public.sns_credentials (
  platform text primary key,
  credentials jsonb not null default '{}',
  is_connected boolean default false,
  updated_at timestamptz default now()
);

create table if not exists public.service_credentials (
  service text primary key
    check (service in ('supabase', 'github', 'vercel', 'googleSheet', 'openai')),
  credentials jsonb not null default '{}',
  is_connected boolean default false,
  updated_at timestamptz default now()
);

create table if not exists public.settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz default now()
);

create table if not exists public.members (
  id bigint generated always as identity primary key,
  created_at timestamptz default now()
);

alter table public.members add column if not exists name text;
alter table public.members add column if not exists email text;
alter table public.members add column if not exists joined_at text;
alter table public.members add column if not exists approval_status text default 'pending';
alter table public.members add column if not exists role text default 'operator';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'members_email_key'
      and conrelid = 'public.members'::regclass
  ) then
    alter table public.members add constraint members_email_key unique (email);
  end if;
end $$;

alter table public.contents disable row level security;
alter table public.sns_credentials disable row level security;
alter table public.service_credentials disable row level security;
alter table public.settings disable row level security;
alter table public.members disable row level security;

alter table public.contents no force row level security;
alter table public.sns_credentials no force row level security;
alter table public.service_credentials no force row level security;
alter table public.settings no force row level security;
alter table public.members no force row level security;

grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on table public.contents to anon, authenticated;
grant select, insert, update, delete on table public.sns_credentials to anon, authenticated;
grant select, insert, update, delete on table public.service_credentials to anon, authenticated;
grant select, insert, update, delete on table public.settings to anon, authenticated;
grant select, insert, update, delete on table public.members to anon, authenticated;

grant usage, select on all sequences in schema public to anon, authenticated;

notify pgrst, 'reload schema';
