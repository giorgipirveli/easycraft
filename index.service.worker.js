// This service worker is required to expose an exported Godot project as a
// Progressive Web App. It provides an offline fallback page telling the user
// that they need an Internet connection to run the project if desired.
// Incrementing CACHE_VERSION will kick off the install event and force
// previously cached resources to be updated from the network.
/** @type {string} */
const CACHE_VERSION = '1790846453|17135032';
/** @type {string} */
const CACHE_PREFIX = 'EasyCraft-sw-cache-';
const CACHE_NAME = CACHE_PREFIX + CACHE_VERSION;
/** @type {string} */
const OFFLINE_URL = 'index.offline.html';
/** @type {boolean} */
const ENSURE_CROSSORIGIN_ISOLATION_HEADERS = true;
// Files that will be cached on load.
/** @type {string[]} */
const CACHED_FILES = ["index.html","index.js","index.offline.html","index.icon.png","index.apple-touch-icon.png","index.audio.worklet.js","index.audio.position.worklet.js"];
// Files that we might not want the user to preload, and will only be cached on first load.
/** @type {string[]} */
const CACHEABLE_FILES = ["index.wasm","index.pck","index.mobile.pck","index.side.wasm","libvoxel.web.template_release.wasm32.threads.wasm"];
const FULL_CACHE = CACHED_FILES.concat(CACHEABLE_FILES);

// EasyCraft (tools/export_web.sh): the big files kept by their content across versions.
const EC_FILES_CACHE = 'EasyCraft-files';
const EC_HASHES = {"index.pck": "dc26e0b63d410443", "index.mobile.pck": "0dbe6f7b04e7fdb8", "index.side.wasm": "c99712114cbcedd8", "index.wasm": "eb7ab9dcb2c2c484", "index.js": "878c9ae7fb3c27ce", "assets.e298659320.pck": "e298659320a44ff5", "assets.mobile.e298659320.pck": "e298659320a44ff5", "libvoxel.web.template_release.wasm32.threads.wasm": "3b65cb54e1fed5ad"};
function ecKey(name) { return name + '?h=' + EC_HASHES[name]; }
async function ecKeep(names) {
	const cache = await caches.open(EC_FILES_CACHE);
	for (const name of names) {
		const key = new URL(ecKey(name), self.location).href;
		if (await cache.match(key) == null) {
			const response = await fetch(name);
			if (response.ok) {
				await cache.put(key, response);
			}
		}
	}
}
// Owner #95: an update's whole game for this device (the kind of main pack it kept before: a phone's or a computer's),
// downloaded before this worker takes over; nothing on a first visit (the page downloads what it needs then).
async function ecKeepUpdate() {
	const kept = await caches.open(EC_FILES_CACHE);
	const names = (await kept.keys()).map((request) => new URL(request.url).pathname.split('/').pop());
	if (!names.some((name) => name.endsWith('.pck'))) {
		return;
	}
	const phone = names.includes('index.mobile.pck');
	await ecKeep(Object.keys(EC_HASHES).filter((name) => !name.endsWith('.pck')
		|| (name === 'index.mobile.pck' || name.includes('.mobile.')) === phone));
}
// Owner #93: the page to open without the internet: this build's index.html when every file the game needs is kept
// here (the main pack and the media pack of one GPU kind), else null.
async function ecOfflinePage(cache) {
	const kept = await caches.open(EC_FILES_CACHE);
	const has = async (name) => name in EC_HASHES && (await kept.match(new URL(ecKey(name), self.location).href)) != null;
	const names = Object.keys(EC_HASHES);
	for (const name of names) {
		if (!name.endsWith('.pck') && !(await has(name))) {
			return null;
		}
	}
	for (const name of CACHED_FILES) {
		if (!(name in EC_HASHES) && (await cache.match(name)) == null) {
			return null;
		}
	}
	const assets = (mobile) => names.find((name) => name.startsWith('assets.') && name.includes('.mobile.') === mobile);
	const computer = (await has('index.pck')) && (await has(assets(false)));
	const phone = (await has('index.mobile.pck')) && (await has(assets(true)));
	return (computer || phone) ? await cache.match('index.html') : null;
}
self.addEventListener('fetch', (event) => {
	if (event.request.method !== 'GET') {
		return;
	}
	const url = new URL(event.request.url);
	const name = url.pathname.split('/').pop();
	if (!(name in EC_HASHES)) {
		return;
	}
	event.respondWith((async () => {
		const cache = await caches.open(EC_FILES_CACHE);
		const key = new URL(ecKey(name), url).href;
		let response = await cache.match(key);
		if (response == null) {
			response = await fetch(event.request);
			if (response.ok) {
				// Store the copy while the page reads the same bytes: awaiting the whole file first froze the progress
				// bar at 2 % until 64 MB had arrived (owner 2026-09-28 01:42).
				event.waitUntil(cache.put(key, response.clone()));
			}
		}
		return ENSURE_CROSSORIGIN_ISOLATION_HEADERS ? ensureCrossOriginIsolationHeaders(response) : response;
	})());
});
self.addEventListener('activate', (event) => {
	event.waitUntil(caches.open(EC_FILES_CACHE).then(async (cache) => {
		const keep = new Set(Object.keys(EC_HASHES).map(ecKey));
		for (const request of await cache.keys()) {
			const url = new URL(request.url);
			if (!keep.has(url.pathname.split('/').pop() + url.search)) {
				await cache.delete(request);
			}
		}
	}));
});

self.addEventListener('message', (event) => {
	if (event.data === 'ec-build' && event.ports && event.ports[0]) {
		event.ports[0].postMessage({ ecBuild: CACHE_NAME });   // EasyCraft: the page checks it is of this build
	}
});

self.addEventListener('install', (event) => {
	self.skipWaiting(); // EasyCraft: take over the page at once (tools/export_web.sh)
	event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES.filter((name) => !(name in EC_HASHES))))
		.then(() => ecKeep(CACHED_FILES.filter((name) => name in EC_HASHES)))
		.then(() => ecKeepUpdate()));
});

self.addEventListener('activate', (event) => {
	event.waitUntil(caches.keys().then(
		function (keys) {
			// Remove old caches.
			return Promise.all(keys.filter((key) => key.startsWith(CACHE_PREFIX) && key !== CACHE_NAME).map((key) => caches.delete(key)));
		}
	).then(function () {
		// Enable navigation preload if available.
		return ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve();
	}).then(function () {
		return self.clients.claim(); // EasyCraft: control the first visit's downloads too
	}));
});

/**
 * Ensures that the response has the correct COEP/COOP headers
 * @param {Response} response
 * @returns {Response}
 */
function ensureCrossOriginIsolationHeaders(response) {
	if (response.headers.get('Cross-Origin-Embedder-Policy') === 'require-corp'
		&& response.headers.get('Cross-Origin-Opener-Policy') === 'same-origin') {
		return response;
	}

	const crossOriginIsolatedHeaders = new Headers(response.headers);
	crossOriginIsolatedHeaders.set('Cross-Origin-Embedder-Policy', 'require-corp');
	crossOriginIsolatedHeaders.set('Cross-Origin-Opener-Policy', 'same-origin');
	const newResponse = new Response(response.body, {
		status: response.status,
		statusText: response.statusText,
		headers: crossOriginIsolatedHeaders,
	});

	return newResponse;
}

/**
 * Calls fetch and cache the result if it is cacheable
 * @param {FetchEvent} event
 * @param {Cache} cache
 * @param {boolean} isCacheable
 * @returns {Response}
 */
async function fetchAndCache(event, cache, isCacheable) {
	// Use the preloaded response, if it's there
	/** @type { Response } */
	let response = await event.preloadResponse;
	if (response == null) {
		// Or, go over network.
		response = await self.fetch(event.request);
	}

	if (ENSURE_CROSSORIGIN_ISOLATION_HEADERS) {
		response = ensureCrossOriginIsolationHeaders(response);
	}

	if (isCacheable) {
		// And update the cache
		cache.put(event.request, response.clone());
	}

	return response;
}

self.addEventListener(
	'fetch',
	/**
	 * Triggered on fetch
	 * @param {FetchEvent} event
	 */
	(event) => {
		const isNavigate = event.request.mode === 'navigate';
		const url = event.request.url || '';
		const referrer = event.request.referrer || '';
		const base = referrer.slice(0, referrer.lastIndexOf('/') + 1);
		const local = url.startsWith(base) ? url.replace(base, '') : '';
		const isCacheable = FULL_CACHE.some((v) => v === local) || (base === referrer && base.endsWith(CACHED_FILES[0]));
		if (isNavigate || isCacheable) {
			event.respondWith((async () => {
				// Try to use cache first
				const cache = await caches.open(CACHE_NAME);
				if (isNavigate) {
					try {
						return await fetchAndCache(event, cache, false);   // EasyCraft: online, the newest page
					} catch (e) {
						const page = await ecOfflinePage(cache);   // EasyCraft: offline, this build's page (owner #93)
						if (page != null) {
							return ENSURE_CROSSORIGIN_ISOLATION_HEADERS ? ensureCrossOriginIsolationHeaders(page) : page;
						}
						return caches.match(OFFLINE_URL);
					}
					// Check if we have full cache during HTML page request.
					/** @type {Response[]} */
					const fullCache = await Promise.all(FULL_CACHE.filter((name) => !(name in EC_HASHES) && (!name.startsWith('index.') || !name.endsWith('.pck'))).map((name) => cache.match(name)));
					const missing = fullCache.some((v) => v === undefined);
					if (missing) {
						try {
							// Try network if some cached file is missing (so we can display offline page in case).
							const response = await fetchAndCache(event, cache, isCacheable);
							return response;
						} catch (e) {
							// And return the hopefully always cached offline page in case of network failure.
							console.error('Network error: ', e); // eslint-disable-line no-console
							return caches.match(OFFLINE_URL);
						}
					}
				}
				let cached = await cache.match(event.request);
				if (cached != null) {
					if (ENSURE_CROSSORIGIN_ISOLATION_HEADERS) {
						cached = ensureCrossOriginIsolationHeaders(cached);
					}
					return cached;
				}
				// Try network if don't have it in cache.
				const response = await fetchAndCache(event, cache, isCacheable);
				return response;
			})());
		} else if (ENSURE_CROSSORIGIN_ISOLATION_HEADERS) {
			event.respondWith((async () => {
				let response = await fetch(event.request);
				response = ensureCrossOriginIsolationHeaders(response);
				return response;
			})());
		}
	}
);

self.addEventListener('message', (event) => {
	// No cross origin
	if (event.origin !== self.origin) {
		return;
	}
	const id = event.source.id || '';
	const msg = event.data || '';
	// Ensure it's one of our clients.
	self.clients.get(id).then(function (client) {
		if (!client) {
			return; // Not a valid client.
		}
		if (msg === 'claim') {
			self.skipWaiting().then(() => self.clients.claim());
		} else if (msg === 'clear') {
			caches.delete(CACHE_NAME);
		} else if (msg === 'update') {
			self.skipWaiting().then(() => self.clients.claim()).then(() => self.clients.matchAll()).then((all) => all.forEach((c) => c.navigate(c.url)));
		}
	});
});

