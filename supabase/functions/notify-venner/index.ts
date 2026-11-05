// Supabase Edge Function: sender web push til venner når en fangst deles (INSERT på team_entries).
// Kalles av en Database Webhook. Secrets: VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT, WEBHOOK_SECRET.
// SUPABASE_URL og SUPABASE_SERVICE_ROLE_KEY settes automatisk av Supabase på serveren (aldri i appen).
import { createClient } from 'npm:@supabase/supabase-js@2';
import webpush from 'npm:web-push@3.6.7';

const db = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
webpush.setVapidDetails(Deno.env.get('VAPID_SUBJECT') ?? 'mailto:admin@example.com',
  Deno.env.get('VAPID_PUBLIC_KEY')!, Deno.env.get('VAPID_PRIVATE_KEY')!);

Deno.serve(async (req) => {
  if (req.headers.get('x-webhook-secret') !== Deno.env.get('WEBHOOK_SECRET')) return new Response('forbidden', { status: 403 });
  const { record } = await req.json();                    // team_entries-rad
  if (!record?.team_id || !record?.entry_id) return new Response('ignored');
  const { data: e } = await db.from('entries').select('species, animal_class, photos, user_id').eq('id', record.entry_id).single();
  if (!e) return new Response('no entry');
  const { data: prof } = await db.from('profiles').select('username').eq('user_id', e.user_id).maybeSingle();
  // Bare send for delingen i avsenderens egen vennegruppe (unngår duplikater fra vennenes grupper)
  const { data: t } = await db.from('teams').select('owner, name').eq('id', record.team_id).single();
  if (!t || t.owner !== e.user_id || t.name !== 'venner') return new Response('skip');
  const { data: rec } = await db.rpc('push_recipients', { p_team: record.team_id });
  const ids = (rec ?? []).map((r: any) => r.user_id).filter((id: string) => id !== e.user_id);
  if (!ids.length) return new Response('no recipients');
  let image: string | undefined;
  if (e.photos?.length) {
    const { data } = await db.storage.from('photos').createSignedUrl(e.photos[0], 60 * 60 * 24 * 7);
    image = data?.signedUrl;
  }
  const payload = JSON.stringify({
    title: `🎯 @${prof?.username ?? 'en venn'} felte ${e.species}`,
    body: e.animal_class ? `${e.species} · ${e.animal_class}` : e.species,
    image, tag: record.entry_id,
  });
  const { data: subs } = await db.from('push_subscriptions').select('*').in('user_id', ids);
  await Promise.all((subs ?? []).map(async (s) => {
    try { await webpush.sendNotification({ endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } }, payload); }
    catch (err: any) { if (err?.statusCode === 404 || err?.statusCode === 410) await db.from('push_subscriptions').delete().eq('endpoint', s.endpoint); }
  }));
  return new Response(`sent ${subs?.length ?? 0}`);
});
