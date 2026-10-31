// Owner #90: a browser that cannot run EasyCraft gets a kind page (web/shell.html's first script), checked in a real
// headless Chromium (Playwright) without an export: the shell's placeholders get stand-ins, and the engine is a stub
// that never finishes loading. Four browsers:
//   1. everything there (WebGL 2, WebAssembly, the engine)    -> the loading screen, no kind page
//   2. no WebGL at all (--disable-3d-apis: a PlayStation's)   -> the kind page, "Missing: WebGL 2"
//   3. no WebAssembly                                         -> the kind page, "Missing: WebAssembly"
//   4. the engine's script missing or unreadable              -> the kind page, "Missing: a newer browser"
// Prints PASS/FAIL per case and exits 1 on any failure.
//
//   PW_HOME=~/src/pwenv node tools/web_kind_page_check.mjs
//
// Setup: Playwright in ~/src/pwenv with Chromium (`npx playwright install chromium`; see tools/web_iphone_check.mjs).
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const { chromium } = createRequire((process.env.PW_HOME || process.env.HOME + '/src/pwenv') + '/')('playwright');

const shell = readFileSync(join(dirname(fileURLToPath(import.meta.url)), '..', 'web', 'shell.html'), 'utf8');
const STUB_ENGINE = `<script>
window.Engine = function () { return new Proxy({}, { get: function () { return function () { return new Promise(function () {}); }; } }); };
window.Engine.getMissingFeatures = function () { return []; };
</script>`;

function page(withEngine) {
	let html = shell
		.replaceAll('$GODOT_PROJECT_NAME', 'EasyCraft')
		.replaceAll('$GODOT_HEAD_INCLUDE', '')
		.replaceAll('$GODOT_SPLASH', 'data:,')
		.replaceAll('$GODOT_CONFIG', '{"executable": "index", "fileSizes": {}}')
		.replaceAll('$GODOT_THREADS_ENABLED', 'false');
	return html.replace('<script src="$GODOT_URL"></script>', withEngine ? STUB_ENGINE : '<script src="missing-engine.js"></script>');
}

const WORDS = "This browser can’t run EasyCraft yet.";
const cases = [
	{ name: 'everything there', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'], engine: true, kind: false },
	{ name: 'no WebGL (a PlayStation)', args: ['--disable-3d-apis'], engine: true, kind: true, missing: 'WebGL 2' },
	{ name: 'no WebAssembly', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'], engine: true, kind: true,
		missing: 'WebAssembly', init: () => { delete window.WebAssembly; } },
	{ name: 'no engine script', args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'], engine: false, kind: true,
		missing: 'a newer browser' },
];

let failed = 0;
for (const c of cases) {
	const browser = await chromium.launch({ args: c.args });
	const p = await browser.newPage({ viewport: { width: 1280, height: 720 } });
	const errors = [];
	p.on('pageerror', (e) => errors.push(String(e)));
	if (c.init) {
		await p.addInitScript(c.init);
	}
	// A real navigation (init scripts run in its document): the page from memory, anything else it asks for is missing.
	await p.route('**/*', (route) => route.request().url() === 'http://kind.test/'
		? route.fulfill({ contentType: 'text/html', body: page(c.engine) })
		: route.fulfill({ status: 404, body: '' }));
	await p.goto('http://kind.test/', { waitUntil: 'load' });
	await p.waitForTimeout(500);
	const got = await p.evaluate(() => {
		const s = document.getElementById('status');
		const n = document.getElementById('status-notice');
		return { kind: s.classList.contains('cant-run'), shown: getComputedStyle(n).display !== 'none', text: n.innerText,
			webgl2: !!document.createElement('canvas').getContext('webgl2') };
	});
	let ok = got.kind === c.kind && got.shown === c.kind;
	if (c.kind) {
		ok = ok && got.text.includes(WORDS) && got.text.includes('Chrome, Edge, Firefox or Safari')
			&& got.text.includes('Missing: ' + c.missing);
	}
	ok = ok && errors.length === 0;
	console.log(`${ok ? 'PASS' : 'FAIL'} ${c.name}: kind page ${got.kind ? 'shown' : 'not shown'}`
		+ (got.kind ? ` ("${got.text.replace(/\n/g, ' / ')}")` : '') + (errors.length ? ` page errors: ${errors.join('; ')}` : ''));
	if (!ok) {
		failed++;
	}
	await browser.close();
}
console.log(failed ? `KIND_PAGE FAIL ${failed}` : 'KIND_PAGE PASS');
process.exit(failed ? 1 : 0);
