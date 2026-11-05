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
