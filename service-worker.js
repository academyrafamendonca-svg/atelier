// Service worker mínimo — necessário para o telemóvel considerar
// esta página "instalável" como aplicação.
const CACHE_NAME = 'atelier-rm-v1';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

// Estratégia simples: tenta a rede primeiro (para os dados do Supabase
// estarem sempre atualizados); se falhar (sem internet), tenta a cache.
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request).catch(() => caches.match(event.request))
  );
});
