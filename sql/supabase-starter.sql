-- Optional starter only. This app does not use this SQL or any live cloud database.
-- First create only Ana and Taha as users in YOUR private Supabase Auth project.
create table if not exists public.couple_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.couple_members enable row level security;
revoke all on public.couple_members from anon, authenticated;
grant select on public.couple_members to authenticated;
drop policy if exists "member reads own allowlist row" on public.couple_members;
create policy "member reads own allowlist row" on public.couple_members
  for select to authenticated using (user_id = (select auth.uid()));
create table if not exists public.couple_state (
  id text primary key check (id = 'our-universe'),
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.couple_state enable row level security;
revoke all on public.couple_state from anon, authenticated;
grant select, insert, update on public.couple_state to authenticated;
drop policy if exists "only allowlisted couple can read" on public.couple_state;
drop policy if exists "only allowlisted couple can add" on public.couple_state;
drop policy if exists "only allowlisted couple can update" on public.couple_state;
create policy "only allowlisted couple can read" on public.couple_state for select to authenticated
using (exists (select 1 from public.couple_members m where m.user_id=(select auth.uid())));
create policy "only allowlisted couple can add" on public.couple_state for insert to authenticated
with check (id='our-universe' and exists (select 1 from public.couple_members m where m.user_id=(select auth.uid())));
create policy "only allowlisted couple can update" on public.couple_state for update to authenticated
using (exists (select 1 from public.couple_members m where m.user_id=(select auth.uid())))
with check (id='our-universe' and exists (select 1 from public.couple_members m where m.user_id=(select auth.uid())));
create or replace function public.touch_couple_state_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now(); return new; end;
$$;
drop trigger if exists couple_state_touch_updated_at on public.couple_state;
create trigger couple_state_touch_updated_at before update on public.couple_state for each row execute function public.touch_couple_state_updated_at();
-- Replace with only the two real UUIDs from Auth > Users:
-- insert into public.couple_members(user_id) values ('TAHA-UUID'),('ANA-UUID');
