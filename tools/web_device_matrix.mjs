// The browser version on many devices at once (M7, "universal app for any device using browser"): for each browser
// and device profile it opens the page, waits for PLAY, presses it (a real touch on touch devices), waits for the
// game's own menu ("MENU ready" in the console), presses the game's PLAY (a new player: the name screen comes) and
// saves a screenshot. It prints one line per device: the time to the page's PLAY and to the game's menu, threads on
// (cross-origin isolation), and any page error. Software rendering in headless browsers makes the times slow and
// shapes, not speeds, what counts.
//
//   PW_HOME=~/src/pwenv node tools/web_device_matrix.mjs https://178-104-20-64.sslip.io/play/ [out-folder]
//
// Setup: Playwright in ~/src/pwenv with chromium, webkit and firefox (`npx playwright install chromium webkit
// firefox`); tools/web_iphone_check.mjs has the rest. Runs the devices one after another (the PC is shared).
import { createRequire } from 'node:module';
import { mkdirSync } from 'node:fs';
const { chromium, webkit, firefox, devices } = createRequire((process.env.PW_HOME || process.env.HOME + '/src/pwenv') + '/')('playwright');
const url = process.argv[2] || 'https://178-104-20-64.sslip.io/play/';
const out = process.argv[3] || '.';
mkdirSync(out, { recursive: true });

const MATRIX = [
	['desktop Chrome (Windows/Linux)', chromium, { viewport: { width: 1366, height: 768 } }],
	['desktop Firefox', firefox, { viewport: { width: 1366, height: 768 } }],
	['desktop Safari (Mac, WebKit)', webkit, { viewport: { width: 1440, height: 900 } }],
	['Android phone (Chrome)', chromium, devices['Pixel 7 landscape']],
	['Android small phone (Chrome)', chromium, devices['Galaxy S8 landscape']],
	['Android tablet (Chrome)', chromium, devices['Galaxy Tab S4 landscape']],
	['iPhone (Safari)', webkit, devices['iPhone 15 landscape']],
	['iPhone small (Safari)', webkit, devices['iPhone SE landscape']],
	['iPad (Safari)', webkit, devices['iPad Pro 11 landscape']],
];

function wait(ms) { return new Promise((r) => setTimeout(r, ms)); }

for (const [name, type, profile] of MATRIX) {
	const b = await type.launch();
	const row = { name };
	try {
		const ctx = await b.newContext({ ...profile });
		const p = await ctx.newPage();
		const lines = [];
		const errors = [];
		p.on('console', (m) => lines.push(m.text()));
		p.on('pageerror', (e) => errors.push(String(e).slice(0, 120)));
		const t0 = Date.now();
		await p.goto(url, { waitUntil: 'load', timeout: 60000 });
		await p.waitForFunction(() => document.getElementById('status') && document.getElementById('status').classList.contains('ready'),
			null, { timeout: 240000 });
		row.play_s = ((Date.now() - t0) / 1000).toFixed(1);
		row.threads = await p.evaluate(() => self.crossOriginIsolated);
		const r = await p.evaluate(() => { const e = document.getElementById('play').getBoundingClientRect(); return [e.x + e.width / 2, e.y + e.height / 2]; });
		if (profile.hasTouch) {
			await p.touchscreen.tap(r[0], r[1]);
		} else {
			await p.mouse.click(r[0], r[1]);
		}
		const t1 = Date.now();
		for (let i = 0; i < 480 && !lines.some((l) => l.includes('MENU ready')); i++) {
			await wait(500);
		}
		row.menu_s = lines.some((l) => l.includes('MENU ready')) ? ((Date.now() - t1) / 1000).toFixed(1) : 'none';
		await wait(3000);
		const vp = p.viewportSize();
		if (profile.hasTouch) {   // the game's PLAY (a new player): the name screen
			await p.touchscreen.tap(0.5 * vp.width, 0.585 * vp.height);
		} else {
			await p.mouse.click(0.5 * vp.width, 0.585 * vp.height);
		}
		await wait(2500);
		await p.screenshot({ path: `${out}/${name.replace(/[^a-z0-9]+/gi, '_')}.png` });
		row.page_errors = errors.length;
		row.first_error = errors[0] || '';
	} catch (e) {
		row.error = String(e).slice(0, 140);
	}
	await b.close();
	console.log(JSON.stringify(row));
}
