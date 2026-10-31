// The browser version as an iPhone sees it (M7), in Playwright's WebKit (Safari's engine) with an iPhone's screen,
// touch and user agent. It opens the page (the GitHub link must send it on to our server), waits for PLAY, starts the
// game, answers the age pad (9), taps the name box, types "Bear" and saves screenshots to the folder in argv[3] (default: the system's temp folder, never the project,
// where Godot would import them):
// iphone-1-age.png, iphone-2-name.png, iphone-3-typed.png. It prints the game's console lines and the focused field.
//
//   PW_HOME=~/src/pwenv node tools/web_iphone_check.mjs https://178-104-20-64.sslip.io/play/
//
// One-time setup: `mkdir -p ~/src/pwenv && cd ~/src/pwenv && npm init -y && npm i playwright && npx playwright install
// webkit`, and `sudo apt-get install libmanette-0.2-0 libenchant-2-2`. The taps are fractions of the 1280 x 720 menu
// (a new player: clear the site's data or use a fresh context, as this does). A real iPhone is still the only proof
// that the keyboard opens (WebKit here types without one).
import { createRequire } from 'node:module';
const { webkit, devices } = createRequire((process.env.PW_HOME || process.env.HOME + '/src/pwenv') + '/')('playwright');
const url = process.argv[2] || 'https://178-104-20-64.sslip.io/play/';
const shots = process.argv[3] || (await import('node:os')).tmpdir();
const b = await webkit.launch();
const ctx = await b.newContext({ ...devices['iPhone 15 landscape'] });
const p = await ctx.newPage();
const t0 = Date.now(); const T = () => ((Date.now() - t0) / 1000).toFixed(1) + 's';
p.on('console', m => { const t = m.text(); if (/EasyCraft|MENU|rror/i.test(t)) console.log(T(), 'console:', t.slice(0, 160)); });
p.on('pageerror', e => console.log(T(), 'PAGEERROR', String(e).slice(0, 200)));
p.on('framenavigated', f => { if (f === p.mainFrame()) console.log(T(), 'page:', f.url()); });
await p.goto(url, { waitUntil: 'load' });
await p.waitForFunction(() => document.getElementById('status') && document.getElementById('status').classList.contains('ready'),
	null, { timeout: 180000 });
console.log(T(), 'PLAY shows; threads allowed:', await p.evaluate(() => self.crossOriginIsolated));
const r = await p.evaluate(() => { const b = document.getElementById('play').getBoundingClientRect(); return [b.x + b.width / 2, b.y + b.height / 2]; });
await p.touchscreen.tap(r[0], r[1]);
await p.waitForEvent('console', { predicate: m => m.text().includes('MENU ready'), timeout: 120000 });
await p.waitForTimeout(3000);
const { width: W, height: H } = p.viewportSize();
const tap = async (fx, fy, wait = 1200) => { await p.touchscreen.tap(fx * W, fy * H); await p.waitForTimeout(wait); };
await tap(0.5, 0.585, 2000);            // the menu's PLAY (a new player)
await p.screenshot({ path: `${shots}/iphone-1-age.png` });
await tap(0.628, 0.781);                 // 9
await tap(0.628, 0.893, 2000);           // OK
await p.screenshot({ path: `${shots}/iphone-2-name.png` });
await tap(0.527, 0.53, 1500);            // the name box
console.log(T(), 'focused:', JSON.stringify(await p.evaluate(() => {
	const i = document.activeElement; const b = i.getBoundingClientRect();
	return { tag: i.tagName, visible: getComputedStyle(i).visibility, rect: [b.x, b.y, b.width, b.height].map(Math.round) };
})));
await p.keyboard.type('Bear', { delay: 80 });
await p.waitForTimeout(800);
await p.screenshot({ path: `${shots}/iphone-3-typed.png` });
await b.close();
