/**
 * coi-serviceworker.js
 * Injects Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy headers
 * on every response so SharedArrayBuffer (required by sqflite_common_ffi_web)
 * is available regardless of the server configuration.
 *
 * On first load the SW installs and reloads the page; all subsequent loads
 * are cross-origin isolated and WebAssembly SQLite works normally.
 */

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil(
    self.clients.claim().then(() =>
      self.clients
        .matchAll({ type: 'window' })
        .then((windows) => windows.forEach((w) => w.navigate(w.url)))
    )
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Skip non-GET and opaque cross-origin requests that can't be cloned
  if (request.method !== 'GET') return;
  if (request.cache === 'only-if-cached' && request.mode !== 'same-origin') return;

  event.respondWith(
    fetch(request)
      .then((response) => {
        // Don't touch opaque (cross-origin no-cors) responses
        if (response.status === 0) return response;

        const headers = new Headers(response.headers);
        headers.set('Cross-Origin-Opener-Policy', 'same-origin');
        headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
        headers.set('Cross-Origin-Resource-Policy', 'cross-origin');

        return new Response(response.body, {
          status: response.status,
          statusText: response.statusText,
          headers,
        });
      })
      .catch(() => fetch(request)) // fall back to normal fetch on error
  );
});
