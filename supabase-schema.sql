-- =====================================================================
-- EDC HYPE MARKET — Supabase schema
-- Tables are prefixed `edc_` so they coexist with FlowSpace's tables
-- in the same Supabase project.
-- Run this once in the SQL editor of project tojhthgimlwlxibskkbm.
-- =====================================================================

-- 1. Profiles: one row per auth user, stores display handle for the market
create table if not exists public.edc_profiles (
  id          uuid primary key references auth.users on delete cascade,
  handle      text not null check (char_length(handle) between 2 and 24),
  created_at  timestamptz not null default now()
);

-- 2. Ballots: one row per user. Upsert on re-cast.
--    top5 and top10 are arrays of dj IDs (lowercase-hyphenated names).
create table if not exists public.edc_ballots (
  user_id     uuid primary key references auth.users on delete cascade,
  top5        text[] not null default '{}',
  top10       text[] not null default '{}',
  updated_at  timestamptz not null default now()
);

-- Trigger to auto-update updated_at
create or replace function public.edc_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists edc_ballots_touch on public.edc_ballots;
create trigger edc_ballots_touch
before update on public.edc_ballots
for each row execute function public.edc_touch_updated_at();

-- 3. Row Level Security
alter table public.edc_profiles enable row level security;
alter table public.edc_ballots  enable row level security;

-- Anyone (even anon) can read the market (it's public by design)
drop policy if exists edc_profiles_read on public.edc_profiles;
create policy edc_profiles_read on public.edc_profiles for select using (true);

drop policy if exists edc_ballots_read on public.edc_ballots;
create policy edc_ballots_read on public.edc_ballots for select using (true);

-- Only the authenticated user can insert/update THEIR OWN profile + ballot
drop policy if exists edc_profiles_own_write on public.edc_profiles;
create policy edc_profiles_own_write on public.edc_profiles
  for insert with check (auth.uid() = id);

drop policy if exists edc_profiles_own_update on public.edc_profiles;
create policy edc_profiles_own_update on public.edc_profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists edc_ballots_own_write on public.edc_ballots;
create policy edc_ballots_own_write on public.edc_ballots
  for insert with check (auth.uid() = user_id);

drop policy if exists edc_ballots_own_update on public.edc_ballots;
create policy edc_ballots_own_update on public.edc_ballots
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Allow users to delete their own ballot (the "withdraw" button)
drop policy if exists edc_ballots_own_delete on public.edc_ballots;
create policy edc_ballots_own_delete on public.edc_ballots
  for delete using (auth.uid() = user_id);

-- 4. Realtime: broadcast ballot + profile changes so leaderboards tick live.
--    Safe re-run: check before adding (duplicates would error on redo).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'edc_ballots'
  ) then
    execute 'alter publication supabase_realtime add table public.edc_ballots';
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'edc_profiles'
  ) then
    execute 'alter publication supabase_realtime add table public.edc_profiles';
  end if;
end $$;

-- Done.
-- Next: Auth → Providers → enable "Anonymous Sign-Ins".
-- Then: Auth → URL Configuration → add your Vercel URL to Redirect URLs.
