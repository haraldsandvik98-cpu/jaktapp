-- Jaktlogg: private brukerprofiler med trofeer og bilder for venner/jaktlag.
-- Harald: kjør hele filen i Supabase Dashboard > SQL Editor etter schema.sql.
-- Trygg å kjøre på nytt. Endrer ikke entries, trips, zones eller innlogging.

alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists avatar_path text;
alter table public.profiles drop constraint if exists profiles_display_name_length;
alter table public.profiles add constraint profiles_display_name_length
  check (display_name is null or char_length(display_name) <= 60);

-- Eier, gjensidige venner og medlemmer av samme jaktlag kan åpne profilen.
create or replace function public.can_view_profile(p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and (
    auth.uid() = p_user
    or exists (
      select 1 from teams t join team_members m on m.team_id = t.id
      where t.owner = p_user and t.name = 'venner' and m.email = public.my_email()
    )
    or exists (
      select 1 from teams t
      where public.is_team_member(t.id)
        and (t.owner = p_user or exists (
          select 1 from team_members m join auth.users u on lower(u.email) = m.email
          where m.team_id = t.id and u.id = p_user
        ))
    )
  )
$$;
revoke all on function public.can_view_profile(uuid) from public, anon;
grant execute on function public.can_view_profile(uuid) to authenticated;

-- Brukernavn kan fortsatt slås opp av add_friend (security definer), men vanlige
-- profilspørringer viser bare egne profiler og profiler brukeren har tilgang til.
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated
  using (public.can_view_profile(user_id));

create or replace function public.profile_info(p_username text)
returns table(user_id uuid, username text, display_name text, avatar_path text, is_own boolean)
language sql stable security definer set search_path = public as $$
  select p.user_id, p.username, p.display_name, p.avatar_path, p.user_id = auth.uid()
  from profiles p
  where p.username = lower(trim(p_username)) and public.can_view_profile(p.user_id)
  limit 1
$$;
revoke all on function public.profile_info(text) from public, anon;
grant execute on function public.profile_info(text) to authenticated;

-- Venner ser alle fangster. Jaktlag uten vennskap ser bare fangster som er delt
-- i et felles lag. Notater og nøyaktig kartposisjon returneres aldri.
create or replace function public.profile_catches(p_username text)
returns table(entry_id uuid, species text, country text, animal_class text,
  taken_at timestamptz, sted text, photos text[])
language sql stable security definer set search_path = public as $$
  with target as (
    select p.user_id from profiles p
    where p.username = lower(trim(p_username)) and public.can_view_profile(p.user_id)
    limit 1
  ), allowed as (
    select e.* from entries e join target x on x.user_id = e.user_id
    where e.user_id = auth.uid() or exists (
      select 1 from teams t join team_members m on m.team_id = t.id
      where t.owner = e.user_id and t.name = 'venner' and m.email = public.my_email()
    ) or exists (
      select 1 from team_entries te join teams t on t.id = te.team_id
      where te.entry_id = e.id and public.is_team_member(t.id)
    )
  )
  select id, species, country, animal_class, taken_at, sted, photos
  from allowed order by taken_at desc limit 2000
$$;
revoke all on function public.profile_catches(text) from public, anon;
grant execute on function public.profile_catches(text) to authenticated;

-- Fangstbilder: eier og venner kan lese alle. Andre lagmedlemmer kan bare lese
-- bilder under en fangst som faktisk er delt i et felles jaktlag.
drop policy if exists photos_select_profile on storage.objects;
create policy photos_select_profile on storage.objects for select to authenticated
using (
  bucket_id = 'photos' and exists (
    select 1 from auth.users owner
    where owner.id::text = (storage.foldername(name))[1]
      and public.can_view_profile(owner.id)
      and (
        owner.id = auth.uid()
        or exists (
          select 1 from public.teams t join public.team_members m on m.team_id = t.id
          where t.owner = owner.id and t.name = 'venner' and m.email = public.my_email()
        )
        or exists (
          select 1 from public.team_entries te join public.teams t on t.id = te.team_id
          where te.entry_id::text = (storage.foldername(name))[2]
            and public.is_team_member(t.id)
        )
      )
  )
);

-- Privat avatar-bøtte. Filen ligger under <bruker-id>/avatar.jpg.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', false)
on conflict (id) do update set public = false;

drop policy if exists avatars_select_profile on storage.objects;
create policy avatars_select_profile on storage.objects for select to authenticated
using (bucket_id = 'avatars' and public.can_view_profile(((storage.foldername(name))[1])::uuid));
drop policy if exists avatars_insert_own on storage.objects;
create policy avatars_insert_own on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists avatars_update_own on storage.objects;
create policy avatars_update_own on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists avatars_delete_own on storage.objects;
create policy avatars_delete_own on storage.objects for delete to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
