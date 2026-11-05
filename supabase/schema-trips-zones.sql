-- Harald: kjør hele denne filen i Supabase Dashboard > SQL Editor.
-- Filen kan kjøres på nytt uten å slette eksisterende data.

create table if not exists public.trips (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null default 'Jaktur',
  started_at timestamptz not null,
  ended_at timestamptz not null,
  notes text,
  track jsonb not null default '[]'::jsonb,
  distance_m double precision not null default 0,
  created_at timestamptz not null default now(),
  constraint trips_track_array check (jsonb_typeof(track) = 'array')
);

create table if not exists public.zones (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null default 'Jaktsone',
  kind text not null check (kind in ('polygon', 'rectangle')),
  coords jsonb not null,
  notes text,
  created_at timestamptz not null default now(),
  constraint zones_coords_array check (jsonb_typeof(coords) = 'array')
);

alter table public.trips enable row level security;
alter table public.zones enable row level security;
revoke all on table public.trips from anon, authenticated;
revoke all on table public.zones from anon, authenticated;
grant select, insert, delete on table public.trips to authenticated;
grant select, insert, delete on table public.zones to authenticated;
create index if not exists trips_user_id_idx on public.trips (user_id);
create index if not exists zones_user_id_idx on public.zones (user_id);

do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='trips' and policyname='trips_select_own') then
    create policy trips_select_own on public.trips for select to authenticated using ((select auth.uid()) = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='trips' and policyname='trips_insert_own') then
    create policy trips_insert_own on public.trips for insert to authenticated with check ((select auth.uid()) = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='trips' and policyname='trips_delete_own') then
    create policy trips_delete_own on public.trips for delete to authenticated using ((select auth.uid()) = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='zones' and policyname='zones_select_own') then
    create policy zones_select_own on public.zones for select to authenticated using ((select auth.uid()) = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='zones' and policyname='zones_insert_own') then
    create policy zones_insert_own on public.zones for insert to authenticated with check ((select auth.uid()) = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='zones' and policyname='zones_delete_own') then
    create policy zones_delete_own on public.zones for delete to authenticated using ((select auth.uid()) = user_id);
  end if;
end $$;
