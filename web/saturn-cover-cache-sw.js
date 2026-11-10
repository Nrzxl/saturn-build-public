/* SATURN cover cache: browser-managed, limited and non-invasive.
 * Never intercept authentication, documents or the Flutter application.
 * Cache Storage is best-effort: a browser can evict data when space is low.
 */
const SATURN_BOOK_COVERS = 'saturn-book-covers-v1';
const MAX_CACHED_COVERS = 180;
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== 'https://covers.openlibrary.org') return;
  if (!/^\/b\/(?:id|olid|isbn)\/[^/]+-[SML]\.jpg$/i.test(url.pathname)) return;
  event.respondWith((async () => {
    let cache;
    try {
      cache = await caches.open(SATURN_BOOK_COVERS);
      const stored = await cache.match(event.request);
      if (stored) return stored;
    } catch (_) {
      // Private browsing or quota restrictions must not block book covers.
    }
    const response = await fetch(event.request);
    if (cache && (response.ok || response.type === 'opaque')) {
      event.waitUntil((async () => {
        try {
          await cache.put(event.request, response.clone());
          const keys = await cache.keys();
          for (let i = 0; i < keys.length - MAX_CACHED_COVERS; i++) {
            await cache.delete(keys[i]);
          }
        } catch (_) {
          // Persisted caching is optional; never interfere with rendering.
        }
      })());
    }
    return response;
  })());
});
