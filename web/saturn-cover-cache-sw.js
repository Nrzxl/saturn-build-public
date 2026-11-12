/* SATURN artwork cache: public catalog images only. Never store sign-in,
 * Supabase, user data, HTML, JS or API JSON. Browser storage is best-effort.
 */
const SATURN_BOOK_COVERS = 'saturn-book-covers-v1';
const MAX_CACHED_COVERS = 180;
const SATURN_CINEMATIC_ART = 'saturn-cinematic-art-v1';
const MAX_CACHED_ART = 220;
const CINEMATIC_HOSTS = new Set([
  'image.tmdb.org',
  'img.amodb.dev',
  'static.tvmaze.com',
  'is1-ssl.mzstatic.com',
  'is2-ssl.mzstatic.com',
  'is3-ssl.mzstatic.com',
  'is4-ssl.mzstatic.com',
  'is5-ssl.mzstatic.com',
  'books.googleusercontent.com',
  'books.google.com',
  's4.anilist.co'
]);

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});

function saturnArtworkStore(url) {
  if (url.protocol !== 'https:') return null;
  if (url.username || url.password) return null;
  // Only public cover endpoints, not arbitrary requests to known hosts.
  if (url.origin === 'https://covers.openlibrary.org') {
    return /^\/b\/(?:id|olid|isbn)\/[^/]+-[SML]\.jpg$/i.test(url.pathname)
      ? [SATURN_BOOK_COVERS, MAX_CACHED_COVERS] : null;
  }
  if (!CINEMATIC_HOSTS.has(url.hostname)) return null;
  if (url.searchParams.has('token') ||
      url.searchParams.has('key') ||
      url.searchParams.has('api_key')) return null;
  const path = url.pathname.toLowerCase();
  if (url.hostname === 'image.tmdb.org' ||
      url.hostname === 'img.amodb.dev') {
    if (!/^\/t\/p\/(?:w\d+|original)\/[^/]+\.(?:jpg|jpeg|png|webp)$/.test(path)) {
      return null;
    }
  } else if (!/\.(?:jpg|jpeg|png|webp)(?:$|\/)/.test(path) &&
             !path.includes('/image/') && !path.includes('/cover/')) {
    return null;
  }
  return [SATURN_CINEMATIC_ART, MAX_CACHED_ART];
}

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const store = saturnArtworkStore(new URL(event.request.url));
  if (!store) return;
  event.respondWith((async () => {
    const [cacheName, limit] = store;
    let cache;
    try {
      cache = await caches.open(cacheName);
      const stored = await cache.match(event.request);
      if (stored) return stored;
    } catch (_) {
      // Private browsing and low storage must never block an image.
    }
    const response = await fetch(event.request);
    if (cache && (response.ok || (response.type === 'opaque' &&
        event.request.mode === 'no-cors'))) {
      event.waitUntil((async () => {
        try {
          await cache.put(event.request, response.clone());
          const keys = await cache.keys();
          for (let i = 0; i < keys.length - limit; i++) {
            await cache.delete(keys[i]);
          }
        } catch (_) {
          // Cache is optional. Network response still reaches the browser.
        }
      })());
    }
    return response;
  })());
});


/* Web Push shares this exact service-worker scope with cover caching.
 * It receives already-encrypted messages through the browser PushService.
 * Never cache private notification data or Supabase responses.
 */
self.addEventListener('push', event => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) { /* malformed messages get a neutral notification */ }
  const title = String(payload.title || 'SATURN · Nossa Órbita').slice(0,90);
  const body = String(payload.body || 'Há novidades na Nossa Órbita.').slice(0,175);
  const base = new URL('./', self.registration.scope);
  const appIcon = new URL('icons/Icon-192.png', base).href;
  // System notifications are platform-rendered: image/icon is supported
  // on many browsers; custom borders and animated insects are not.
  let cover = '';
  try {
    const candidate = new URL(String(payload.image || ''));
    if (saturnArtworkStore(candidate)) cover = candidate.href;
  } catch (_) { /* missing or invalid artwork: keep the SATURN icon */ }
  const options = {
    body,
    icon: cover || appIcon,
    badge: appIcon,
    tag: String(payload.tag || 'saturn-notification').slice(0,260),
    data: {url: base.href},
    renotify: false
  };
  if (cover) options.image = cover;
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  const destination = self.registration.scope;
  event.waitUntil((async () => {
    const windows = await clients.matchAll({
      type: 'window', includeUncontrolled: true
    });
    for (const view of windows) {
      if (view.url.startsWith(destination) && 'focus' in view) {
        await view.focus();
        return;
      }
    }
    if (clients.openWindow) await clients.openWindow(destination);
  })());
});
