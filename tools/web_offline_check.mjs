// Owner #93 ("play alone without an internet"), the browser version: a first visit online (the offline worker keeps
// every file), then the network is cut: reload, the page's PLAY, the game's menu, a new player (name, no invite code, a
// look) and SANDBOX: a world. Prints the time to the menu online and offline and the console's key lines; saves
// screenshots of each step in the out-folder.
//
//   PW_HOME=~/src/pwenv node tools/web_offline_check.mjs http://localhost:8068/ [out-folder]
//
// A local build: python3 tools/web_serve.py build/web 8068. Software rendering in a headless browser: slow, not wrong.
import { createRequire } from 'node:module';
const { chromium } = createRequire((process.env.PW_HOME || process.env.HOME + '/src/pwenv') + '/')('playwright');
const url = process.argv[2]; const out = process.argv[3] || '.';
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const b = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
const p = await ctx.newPage();
const lines = [];
p.on('console', (m) => lines.push(m.text()));
p.on('pageerror', (e) => lines.push('PAGEERROR ' + String(e).slice(0, 160)));
async function start(label) {
	const t0 = Date.now();
	await p.waitForFunction(() => document.getElementById('status')?.classList.contains('ready'), null, { timeout: 240000 });
	const r = await p.evaluate(() => { const e = document.getElementById('play').getBoundingClientRect(); return [e.x + e.width / 2, e.y + e.height / 2]; });
	await p.mouse.click(r[0], r[1]);
	for (let i = 0; i < 240 && !lines.some((l) => l.includes('MENU ready')); i++) await wait(500);
	console.log(label, 'page ready + menu in', ((Date.now() - t0) / 1000).toFixed(1), 's; menu:', lines.some((l) => l.includes('MENU ready')));
}
await p.goto(url, { waitUntil: 'load', timeout: 60000 });
await start('ONLINE first visit:');
await wait(20000);   // the music pack and the rest settle into the cache
console.log('cache:', await p.evaluate(async () => { const ks = await caches.keys(); let n = 0; for (const k of ks) n += (await (await caches.open(k)).keys()).length; return ks.length + ' caches, ' + n + ' files'; }));
lines.length = 0;
await ctx.setOffline(true);
try {
	await p.reload({ waitUntil: 'load', timeout: 60000 });
	await start('OFFLINE reload:');
} catch (e) { console.log('OFFLINE reload failed:', String(e).slice(0, 200)); }
await p.screenshot({ path: out + '/offline_menu.png' });
// the game's PLAY: a new player -> the name screen; type a name and go on to the world
await p.mouse.click(640, 421); await wait(3000);
await p.keyboard.type('Offkid'); await p.keyboard.press('Enter'); await wait(4000);
await p.screenshot({ path: out + '/offline_after_name.png' });
await p.mouse.click(537, 524); await wait(6000);   // NO CODE
await p.screenshot({ path: out + '/offline_step3.png' });
await p.mouse.click(640, 421); await wait(6000);
await p.screenshot({ path: out + '/offline_step4.png' });
await p.mouse.click(280, 405); await wait(8000);   // SANDBOX
await p.screenshot({ path: out + '/offline_step5.png' });
await p.mouse.click(640, 421); await wait(20000);
await p.screenshot({ path: out + '/offline_step6.png' });
await wait(30000);
await p.screenshot({ path: out + '/offline_world.png' });
console.log(lines.filter((l) => /MENU|ONLINE|online|offline|PAGEERROR|error|SANDBOX|spawned/i.test(l)).slice(0, 60).join('\n'));
await b.close();
