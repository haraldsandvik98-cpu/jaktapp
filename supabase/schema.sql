-- Jaktlogg: personlig fangstlogg. Kjør i Supabase → SQL Editor.
-- Hver bruker ser og endrer kun sine egne fangster og bilder.

create table if not exists public.entries (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade default auth.uid(),
  species    text not null,
  country    text not null default 'NO' check (country in ('NO','SE')),  -- Norge/Sverige
  taken_at   timestamptz not null,
  sted       text,
  lat        double precision,
  lng        double precision,
  notes      text,
  photos     text[] not null default '{}',   -- stier i storage-bøtta 'photos'
  created_at timestamptz not null default now()
);
-- Eldre prosjekter: legg til land-kolonnen (trygt å kjøre flere ganger)
alter table public.entries add column if not exists country text not null default 'NO';
alter table public.entries add column if not exists animal_class text;  -- kjønn/alder, f.eks. Okse/Ku/Kalv

create index if not exists entries_user_taken_idx on public.entries (user_id, taken_at desc);

alter table public.entries enable row level security;

drop policy if exists "entries_select_own" on public.entries;
drop policy if exists "entries_insert_own" on public.entries;
drop policy if exists "entries_update_own" on public.entries;
drop policy if exists "entries_delete_own" on public.entries;
create policy "entries_select_own" on public.entries for select to authenticated using (user_id = auth.uid());
create policy "entries_insert_own" on public.entries for insert to authenticated with check (user_id = auth.uid());
create policy "entries_update_own" on public.entries for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "entries_delete_own" on public.entries for delete to authenticated using (user_id = auth.uid());

-- Privat bøtte for bilder. Stier: <auth.uid()>/<entry-id>/<n>.jpg
insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do update set public = false;

drop policy if exists "photos_select_own" on storage.objects;
drop policy if exists "photos_insert_own" on storage.objects;
drop policy if exists "photos_update_own" on storage.objects;
drop policy if exists "photos_delete_own" on storage.objects;
create policy "photos_select_own" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos_insert_own" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos_update_own" on storage.objects for update to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos_delete_own" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ===== Deling (kun lesing) =====
-- Eieren lager/tilbakekaller delingslenker. Besøkende med lenken kan KUN lese art, land,
-- kjønn/alder, dato og sted via funksjonen shared_entries(token). Ingen kart-posisjon, notater eller bilder.
create table if not exists public.shares (
  token      text primary key default replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-',''),
  owner      uuid not null references auth.users(id) on delete cascade default auth.uid(),
  created_at timestamptz not null default now(),
  revoked    boolean not null default false
);
alter table public.shares enable row level security;
drop policy if exists "shares_own" on public.shares;
create policy "shares_own" on public.shares for all to authenticated using (owner = auth.uid()) with check (owner = auth.uid());

create or replace function public.shared_entries(p_token text)
returns table (species text, country text, animal_class text, taken_at timestamptz, sted text, n_photos int)
language sql stable security definer set search_path = public as $$
  select e.species, e.country, e.animal_class, e.taken_at, e.sted, coalesce(array_length(e.photos,1),0)
  from public.entries e join public.shares s on s.owner = e.user_id
  where s.token = p_token and not s.revoked and length(p_token) >= 32
  order by e.taken_at desc limit 1000
$$;
revoke all on function public.shared_entries(text) from public;
grant execute on function public.shared_entries(text) to anon, authenticated;

-- =====================================================================
-- Jaktlag: grupper med medlemmer (invitert på e-post) og eksplisitt delte fangster.
-- Egne fangster forblir private; kun fangster et medlem selv deler inn i laget blir synlige for laget.
-- =====================================================================
create table if not exists public.teams (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (length(name) between 1 and 80),
  owner      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.team_members (
  team_id  uuid not null references public.teams(id) on delete cascade,
  email    text not null check (email = lower(email)),
  role     text not null default 'member' check (role in ('owner','member')),
  added_at timestamptz not null default now(),
  primary key (team_id, email)
);
create table if not exists public.team_entries (
  team_id   uuid not null references public.teams(id) on delete cascade,
  entry_id  uuid not null references public.entries(id) on delete cascade,
  shared_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  shared_at timestamptz not null default now(),
  primary key (team_id, entry_id)
);
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.team_entries enable row level security;

-- Hjelpere (security definer for å unngå RLS-rekursjon). Medlemskap = innlogget e-post står på medlemslisten.
create or replace function public.my_email() returns text language sql stable as
$$ select lower(coalesce(auth.jwt()->>'email','')) $$;
create or replace function public.is_team_member(p_team uuid) returns boolean
language sql stable security definer set search_path = public as
$$ select exists(select 1 from team_members where team_id=p_team and email=public.my_email())
       or exists(select 1 from teams where id=p_team and owner=auth.uid()) $$;
create or replace function public.is_team_owner(p_team uuid) returns boolean
language sql stable security definer set search_path = public as
$$ select exists(select 1 from teams where id=p_team and owner=auth.uid()) $$;

drop policy if exists teams_select on public.teams;
create policy teams_select on public.teams for select to authenticated using (public.is_team_member(id));
drop policy if exists teams_insert on public.teams;
create policy teams_insert on public.teams for insert to authenticated with check (owner = auth.uid());
drop policy if exists teams_owner_upd on public.teams;
create policy teams_owner_upd on public.teams for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());
drop policy if exists teams_owner_del on public.teams;
create policy teams_owner_del on public.teams for delete to authenticated using (owner = auth.uid());

drop policy if exists tm_select on public.team_members;
create policy tm_select on public.team_members for select to authenticated using (public.is_team_member(team_id));
drop policy if exists tm_insert on public.team_members;   -- kun lagleder inviterer
create policy tm_insert on public.team_members for insert to authenticated with check (public.is_team_owner(team_id));
drop policy if exists tm_delete on public.team_members;   -- lagleder fjerner, eller medlem forlater selv
create policy tm_delete on public.team_members for delete to authenticated using (public.is_team_owner(team_id) or email = public.my_email());

drop policy if exists te_select on public.team_entries;
create policy te_select on public.team_entries for select to authenticated using (public.is_team_member(team_id));
drop policy if exists te_insert on public.team_entries;   -- medlem deler kun egne fangster
create policy te_insert on public.team_entries for insert to authenticated with check (
  shared_by = auth.uid() and public.is_team_member(team_id)
  and exists(select 1 from public.entries e where e.id = entry_id and e.user_id = auth.uid()));
drop policy if exists te_delete on public.team_entries;   -- den som delte, eller lagleder, kan fjerne
create policy te_delete on public.team_entries for delete to authenticated using (shared_by = auth.uid() or public.is_team_owner(team_id));

-- Lagets fangster: kun for medlemmer. Ingen kartposisjon, notater eller bilder.
create or replace function public.team_catches(p_team uuid)
returns table(entry_id uuid, species text, country text, animal_class text, taken_at timestamptz, sted text, hunter text, mine boolean)
language sql stable security definer set search_path = public as $$
  select e.id, e.species, e.country, e.animal_class, e.taken_at, e.sted, u.email::text, e.user_id = auth.uid()
  from team_entries t join entries e on e.id = t.entry_id join auth.users u on u.id = e.user_id
  where t.team_id = p_team and public.is_team_member(p_team)
  order by e.taken_at desc limit 2000 $$;
revoke all on function public.team_catches(uuid) from public, anon;
grant execute on function public.team_catches(uuid) to authenticated;
revoke all on function public.is_team_member(uuid) from public, anon;
grant execute on function public.is_team_member(uuid) to authenticated;
revoke all on function public.is_team_owner(uuid) from public, anon;
grant execute on function public.is_team_owner(uuid) to authenticated;

-- Varsler: nye fangster andre medlemmer har delt i lagene dine siden et tidspunkt.
create or replace function public.team_feed(p_since timestamptz)
returns table(team_id uuid, team_name text, species text, animal_class text, hunter text, shared_at timestamptz)
language sql stable security definer set search_path = public as $$
  select t.team_id, tm.name, e.species, e.animal_class, u.email::text, t.shared_at
  from team_entries t join teams tm on tm.id = t.team_id join entries e on e.id = t.entry_id join auth.users u on u.id = t.shared_by
  where public.is_team_member(t.team_id) and t.shared_by <> auth.uid() and t.shared_at > p_since
  order by t.shared_at desc limit 50 $$;
revoke all on function public.team_feed(timestamptz) from public, anon;
grant execute on function public.team_feed(timestamptz) to authenticated;

-- Automatisk deling: nye fangster deles til alle jaktlag eieren er medlem av (kan fjernes per fangst i appen).
create or replace function public.auto_share_entry() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into team_entries(team_id, entry_id, shared_by)
  select distinct x.team_id, new.id, new.user_id from (
    select m.team_id from team_members m join auth.users u on lower(u.email) = m.email where u.id = new.user_id
    union select t.id from teams t where t.owner = new.user_id) x
  on conflict do nothing;
  return new;
end $$;
drop trigger if exists entries_auto_share on public.entries;
create trigger entries_auto_share after insert on public.entries for each row execute function public.auto_share_entry();

-- Realtime for varsler (RLS gjelder: kun medlemmer får hendelser).
do $$ begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime')
     and not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='team_entries')
  then alter publication supabase_realtime add table public.team_entries; end if;
end $$;

-- =====================================================================
-- Venner (bygger på jaktlag-tabellene over): hver bruker har én vennegruppe (teams.name='venner').
-- Legg til venn med brukernavn => gjensidig medlemskap i hverandres vennegruppe.
-- Nye fangster deles automatisk via trigger-en entries_auto_share over.
-- =====================================================================
create table if not exists public.profiles (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  username   text not null unique check (username ~ '^[a-z0-9_.]{3,24}$'),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists profiles_read on public.profiles;      -- innloggede kan slå opp brukernavn (ikke e-post)
create policy profiles_read on public.profiles for select to authenticated using (true);
drop policy if exists profiles_own on public.profiles;
create policy profiles_own on public.profiles for insert to authenticated with check (user_id = auth.uid());
drop policy if exists profiles_own_upd on public.profiles;
create policy profiles_own_upd on public.profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.friends_team(p_user uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare t uuid; em text;
begin
  select id into t from teams where owner = p_user and name = 'venner' limit 1;
  if t is null then
    insert into teams(name, owner) values ('venner', p_user) returning id into t;
    select lower(email) into em from auth.users where id = p_user;
    insert into team_members(team_id, email, role) values (t, em, 'owner') on conflict do nothing;
  end if;
  return t;
end $$;

create or replace function public.add_friend(p_username text) returns text
language plpgsql security definer set search_path = public as $$
declare f uuid; fe text; me text;
begin
  if auth.uid() is null then raise exception 'Ikke innlogget'; end if;
  select user_id into f from profiles where username = lower(trim(p_username));
  if f is null then return 'ukjent'; end if;
  if f = auth.uid() then return 'deg'; end if;
  select lower(email) into fe from auth.users where id = f;
  select lower(email) into me from auth.users where id = auth.uid();
  insert into team_members(team_id, email) values (public.friends_team(auth.uid()), fe) on conflict do nothing;
  insert into team_members(team_id, email) values (public.friends_team(f), me) on conflict do nothing;
  return 'ok';
end $$;

create or replace function public.remove_friend(p_username text) returns void
language plpgsql security definer set search_path = public as $$
declare f uuid; fe text; me text;
begin
  select user_id into f from profiles where username = lower(trim(p_username));
  if f is null or auth.uid() is null then return; end if;
  select lower(email) into fe from auth.users where id = f;
  select lower(email) into me from auth.users where id = auth.uid();
  delete from team_members where team_id = public.friends_team(auth.uid()) and email = fe;
  delete from team_members where team_id = public.friends_team(f) and email = me;
  delete from team_entries te using entries e where te.entry_id = e.id and
    ((te.team_id = public.friends_team(auth.uid()) and e.user_id = f) or (te.team_id = public.friends_team(f) and e.user_id = auth.uid()));
end $$;

create or replace function public.my_friends() returns table(username text)
language sql stable security definer set search_path = public as $$
  select p.username from team_members m join auth.users u on lower(u.email) = m.email join profiles p on p.user_id = u.id
  where m.team_id = (select id from teams where owner = auth.uid() and name = 'venner' limit 1) and u.id <> auth.uid()
  order by 1 $$;

-- Vis brukernavn i stedet for e-post i fangstlister og varsler.
create or replace function public.team_catches(p_team uuid)
returns table(entry_id uuid, species text, country text, animal_class text, taken_at timestamptz, sted text, hunter text, mine boolean)
language sql stable security definer set search_path = public as $$
  select e.id, e.species, e.country, e.animal_class, e.taken_at, e.sted, coalesce(p.username, split_part(u.email::text,'@',1)), e.user_id = auth.uid()
  from team_entries t join entries e on e.id = t.entry_id join auth.users u on u.id = e.user_id left join profiles p on p.user_id = e.user_id
  where t.team_id = p_team and public.is_team_member(p_team)
  order by e.taken_at desc limit 2000 $$;
create or replace function public.team_feed(p_since timestamptz)
returns table(team_id uuid, team_name text, species text, animal_class text, hunter text, shared_at timestamptz)
language sql stable security definer set search_path = public as $$
  select distinct on (t.entry_id) t.team_id, tm.name, e.species, e.animal_class, coalesce(p.username, split_part(u.email::text,'@',1)), t.shared_at
  from team_entries t join teams tm on tm.id = t.team_id join entries e on e.id = t.entry_id join auth.users u on u.id = t.shared_by
  left join profiles p on p.user_id = t.shared_by
  where public.is_team_member(t.team_id) and t.shared_by <> auth.uid() and t.shared_at > p_since
  order by t.entry_id, t.shared_at desc limit 50 $$;
revoke all on function public.friends_team(uuid) from public, anon, authenticated;
revoke all on function public.add_friend(text) from public, anon;
grant execute on function public.add_friend(text) to authenticated;
revoke all on function public.remove_friend(text) from public, anon;
grant execute on function public.remove_friend(text) to authenticated;
revoke all on function public.my_friends() from public, anon;
grant execute on function public.my_friends() to authenticated;
