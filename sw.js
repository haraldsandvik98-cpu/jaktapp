// Jaktlogg service worker: enkel app-shell-cache for offline bruk.
// Supabase-kall (innlogging, data, bilder) og karttiles caches ikke.
const V = 'jaktlogg-v7';
const SHELL = ['./', './index.html', './manifest.json', './assets/logo.svg', './assets/logo-wordmark.svg', './assets/species/lirype.jpg', './assets/bg.jpg',
  './assets/icons/icon-180.png', './assets/icons/icon-192.png', './assets/icons/icon-512.png', './assets/sounds/seierhorn.mp3'];
const CDN = /^https:\/\/(unpkg\.com\/leaflet@|cdn\.jsdelivr\.net\/npm\/@supabase\/supabase-js@)/;

self.addEventListener('install', e => {
  e.waitUntil(caches.open(V).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== V).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const r = e.request, u = new URL(r.url);
  if (r.method !== 'GET') return;
  if (r.mode === 'navigate') { // nettverk først, så cachet app-skall
    e.respondWith(fetch(r).then(res => { const c = res.clone(); caches.open(V).then(x => x.put('./index.html', c)); return res; })
      .catch(() => caches.match('./index.html')));
    return;
  }
  const same = u.origin === self.location.origin && u.pathname.startsWith(new URL('./', self.location).pathname);
  if (same || CDN.test(r.url)) { // cache, oppdater i bakgrunnen
    e.respondWith(caches.match(r).then(hit => {
      const net = fetch(r).then(res => { if (res.ok || res.type === 'opaque') { const c = res.clone(); caches.open(V).then(x => x.put(r, c)); } return res; }).catch(() => hit);
      return hit || net;
    }));
  }
});

// Web push fra edge-funksjonen notify-venner
self.addEventListener('push', e => {
  let d = {}; try { d = e.data ? e.data.json() : {}; } catch (_) {}
  const title = d.title || 'Ny fangst fra en venn';
  const opt = { body: d.body || '', icon: './assets/icons/icon-192.png', badge: './assets/icons/icon-192.png',
    image: d.image || undefined, tag: d.tag || 'venner', renotify: true, vibrate: [80, 40, 160], data: { url: './#venner' } };
  e.waitUntil(self.registration.showNotification(title, opt).then(() =>
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(cs => cs.forEach(c => c.postMessage({ type: 'venn-fangst' })))));
});
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(cs => {
    const c = cs.find(x => 'focus' in x); if (c) { c.postMessage({ type: 'open-venner' }); return c.focus(); }
    return self.clients.openWindow('./#venner');
  }));
});
