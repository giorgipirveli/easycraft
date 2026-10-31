// Owner #123 (2026-10-17): the owner plays the web game on a phone and on a PC, and the two ran different versions: the
// page waited only 8 s for a new version's download, then started the copy it had stored. This check: version A is
// visited (its worker keeps it); then the server gets version B, a copy of A with a new build id whose main packs must
// be downloaded again, and every .pck answer takes EC_SLOW_PCK seconds (a slow phone); the page is opened again.
// B must start (the page's and its worker's build are B), after "Updating EasyCraft…".
//
//   EC_SLOW_PCK=20 python3 tools/web_serve.py build/web_slow_link 8072
//   PW_HOME=~/src/pwenv nice node tools/web_update_slow_check.mjs <A-folder> build/web_slow_B build/web_slow_link [port] [out]
//
// It makes the B folder (hard links to A's files, its own index.html and worker) and points the link at A, then B.
import { createRequire } from 'node:module';
import { symlinkSync, unlinkSync, readFileSync, writeFileSync, readdirSync, mkdirSync, rmSync, linkSync, statSync } from 'node:fs';
import { join, resolve } from 'node:path';
const { chromium } = createRequire((process.env.PW_HOME || process.env.HOME + '/src/pwenv') + '/')('playwright');
const [dirA, dirB, link] = process.argv.slice(2, 5).map((p) => resolve(p));
const port = process.argv[5] || '8072';
const out = process.argv[6] || '.';
const url = `http://localhost:${port}/`;
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const point = (dir) => { try { unlinkSync(link); } catch (e) {} symlinkSync(dir, link); };

// B: the same files, a new build id, and the main packs keyed anew (so the update downloads them again).
rmSync(dirB, { recursive: true, force: true });
mkdirSync(dirB, { recursive: true });
for (const name of readdirSync(dirA)) {
	if (statSync(join(dirA, name)).isFile() && name !== 'index.html' && name !== 'index.service.worker.js') {
		linkSync(join(dirA, name), join(dirB, name));
	}
}
let sw = readFileSync(join(dirA, 'index.service.worker.js'), 'utf8');
let html = readFileSync(join(dirA, 'index.html'), 'utf8');
const prefix = sw.match(/const CACHE_PREFIX = '([^']+)';/)[1];
const version = sw.match(/const CACHE_VERSION = '([^']+)';/)[1];
const A = prefix + version, B = prefix + version + 'b';
sw = sw.replace(`const CACHE_VERSION = '${version}';`, `const CACHE_VERSION = '${version}b';`);
for (const pack of ['index.pck', 'index.mobile.pck']) {
	sw = sw.replace(new RegExp(`"${pack.replace('.', '\\.')}": ?"([0-9a-f]+)"`), (m, h) => m.replace(h, 'b' + h.slice(1)));
}
writeFileSync(join(dirB, 'index.service.worker.js'), sw);
writeFileSync(join(dirB, 'index.html'), html.replace(`const EC_BUILD = '${A}'`, `const EC_BUILD = '${B}'`));
console.log('A', A, 'B', B);

point(dirA);
const b = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
let p = await ctx.newPage();
const lines = [];
const watch = (page) => page.on('console', (m) => lines.push(m.text()));
watch(p);
async function start(label) {
	lines.length = 0;
	const t0 = Date.now();
	await p.waitForFunction(() => document.getElementById('status')?.classList.contains('ready'), null, { timeout: 400000 });
	const r = await p.evaluate(() => { const e = document.getElementById('play').getBoundingClientRect(); return [e.x + e.width / 2, e.y + e.height / 2]; });
	await p.mouse.click(r[0], r[1]);
	for (let i = 0; i < 240 && !lines.some((l) => l.includes('MENU ready')); i++) await wait(500);
	const menu = lines.some((l) => l.includes('MENU ready'));
	console.log(label, 'menu:', menu, 'in', ((Date.now() - t0) / 1000).toFixed(1), 's');
	return menu;
}
const workerBuild = () => p.evaluate(() => new Promise((resolve) => {
	const sw = navigator.serviceWorker.controller;
	if (!sw) { resolve(''); return; }
	const ch = new MessageChannel();
	ch.port1.onmessage = (e) => resolve((e.data && e.data.ecBuild) || '');
	sw.postMessage('ec-build', [ch.port2]);
	setTimeout(() => resolve('timeout'), 3000);
}));

await p.goto(url, { waitUntil: 'load', timeout: 60000 });
await start('A:');
await wait(15000);
console.log('worker after A:', await workerBuild());
await p.close();

point(dirB);   // the deploy
p = await ctx.newPage();
watch(p);
const seen = new Set();
let polling = true;
(async () => {
	while (polling) {
		try {
			const t = await p.evaluate(() => document.getElementById('label')?.textContent || '');
			if (t.startsWith('Updating')) seen.add(t);
		} catch (e) {}
		await wait(500);
	}
})();
await p.goto(url, { waitUntil: 'load', timeout: 60000 });
const menu = await start('B, slow:');
polling = false;
const page = await p.evaluate(() => (document.documentElement.innerHTML.match(/const EC_BUILD = '([^']+)'/) || [])[1] || '');
const worker = await workerBuild();
console.log('the page:', page, 'its worker:', worker, 'updating words seen:', [...seen].slice(0, 6).join(' | '));
await p.screenshot({ path: out + '/update_slow.png' });
const ok = menu && page === B && worker === B && seen.size > 0;
console.log(ok ? 'PASS' : 'FAIL');
await b.close();
point(dirA);
process.exit(ok ? 0 : 1);
