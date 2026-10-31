// Owner #95 ("get upgraded after getting online"): a child plays version A online; while the game runs, the server gets
// version B (a deploy) and the page asks for an update (as it does when the browser is online again, or a minute after
// the start); B's worker downloads the whole game for this device before it takes over (tools/export_web.sh:
// ecKeepUpdate). Then the network is cut and the page reloads: version B must open and play, offline.
//
//   python3 tools/web_serve.py <served-folder> 8071   (the folder is a symlink this tool points at A, then at B)
//   PW_HOME=~/src/pwenv nice node tools/web_update_offline_check.mjs <A-folder> <B-folder> <symlink> [port] [out-folder]
//
// Prints each step and PASS or FAIL: B's build id in the page after the offline reload, and the game's MENU ready.
import { createRequire } from 'node:module';
import { symlinkSync, unlinkSync, readFileSync } from 'node:fs';
const { chromium } = createRequire((process.env.PW_HOME || process.env.HOME + '/src/pwenv') + '/')('playwright');
const [dirA, dirB, link] = process.argv.slice(2, 5);
const port = process.argv[5] || '8071';
const out = process.argv[6] || '.';
const url = `http://localhost:${port}/`;
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const buildOf = (dir) => readFileSync(dir + '/index.html', 'utf8').match(/const EC_BUILD = '([^']+)'/)[1];
const point = (dir) => { try { unlinkSync(link); } catch (e) {} symlinkSync(dir, link); };

const A = buildOf(dirA), B = buildOf(dirB);
console.log('A', A, 'B', B);
point(dirA);
const b = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
const p = await ctx.newPage();
const lines = [];
p.on('console', (m) => lines.push(m.text()));
async function start(label) {
	lines.length = 0;
	const t0 = Date.now();
	await p.waitForFunction(() => document.getElementById('status')?.classList.contains('ready'), null, { timeout: 240000 });
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
await start('A online:');
await wait(15000);
console.log('worker after A:', await workerBuild());
point(dirB);   // the deploy
await p.evaluate(() => navigator.serviceWorker.getRegistration().then((r) => r && r.update()));
let now = '';
for (let i = 0; i < 120; i++) {   // B's worker downloads the whole game, then takes over
	now = await workerBuild();
	if (now === B) break;   // the worker's build id is the page's EC_BUILD (tools/export_web.sh)
	await wait(2000);
}
console.log('worker after the update:', now);
await ctx.setOffline(true);
let ok = false;
try {
	await p.reload({ waitUntil: 'load', timeout: 60000 });
	const page = await p.evaluate(() => (document.documentElement.innerHTML.match(/const EC_BUILD = '([^']+)'/) || [])[1] || '');
	console.log('offline page build:', page);
	const menu = await start('B offline:');
	ok = page === B && menu;
} catch (e) { console.log('offline reload failed:', String(e).slice(0, 200)); }
await p.screenshot({ path: out + '/update_offline.png' });
console.log(ok ? 'PASS' : 'FAIL');
await b.close();
point(dirA);
process.exit(ok ? 0 : 1);
