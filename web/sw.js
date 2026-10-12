// IB Scoring service worker (design decision D1 of add-offline-icon-quick-entry).
//
// - Answers requests for the app's files and for Google fonts from the cache
//   of this version first, then from the network.
// - Keeps one complete cache for each version. A new version fills its own
//   cache in the background and starts at the next open of the app.
// - The deploy workflow replaces BUILD_ID with the commit id.

const BUILD_ID = 'dev';
const PREFIX = 'ib-score-';
const CACHE = PREFIX + BUILD_ID;
const FONT_HOSTS = ['fonts.gstatic.com', 'fonts.googleapis.com'];
const START_URL = new URL('./', self.registration.scope).href;

function isCacheable(url) {
  const u = new URL(url);
  if (u.origin === self.location.origin) {
    return u.href.startsWith(self.registration.scope) && !u.pathname.endsWith('/sw.js');
  }
  return FONT_HOSTS.includes(u.hostname);
}

async function olderCacheNames() {
  return (await caches.keys()).filter((n) => n.startsWith(PREFIX) && n !== CACHE);
}

async function store(cache, url, response) {
  if (response.ok || response.type === 'opaque') {
    await cache.put(url, response);
    return true;
  }
  return false;
}

// Install: copy the URL list of the older version and download each URL
// again from the network. Any failure stops the install, so the complete
// older version stays in use.
self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    const urls = new Set([START_URL]);
    for (const name of await olderCacheNames()) {
      const old = await caches.open(name);
      for (const request of await old.keys()) urls.add(request.url);
    }
    await Promise.all([...urls].map(async (url) => {
      const response = await fetch(url, { cache: 'reload' });
      if (!(await store(cache, url, response))) {
        throw new Error('Cannot download ' + url + ': ' + response.status);
      }
    }));
  })());
});

// Activate: remove older versions. On a first install there is no older
// version, so this worker also takes control of the open page, so that the
// page can fill the cache.
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const older = await olderCacheNames();
    await Promise.all(older.map((n) => caches.delete(n)));
    if (older.length === 0) await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const navigate = request.mode === 'navigate';
  if (!navigate && !isCacheable(request.url)) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    // Any page address of the app opens the stored start page.
    const key = navigate && request.url.startsWith(self.registration.scope)
      ? START_URL
      : request;
    const hit = await cache.match(key, { ignoreVary: true });
    if (hit) return hit;
    const response = await fetch(request);
    await store(cache, navigate ? START_URL : request.url, response.clone());
    return response;
  })());
});

// The page sends the URLs that it loaded before this worker controlled it.
self.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.type !== 'cache-urls' || !Array.isArray(data.urls)) return;
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    for (const url of data.urls) {
      if (typeof url !== 'string' || !isCacheable(url)) continue;
      if (await cache.match(url, { ignoreVary: true })) continue;
      try {
        await store(cache, url, await fetch(url));
      } catch (e) {
        // A failed download does not matter here; a later visit tries again.
      }
    }
  })());
});
