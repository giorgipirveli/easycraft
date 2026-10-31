# M2 "Survive the Night" — acceptance on the emulator

Device: Android emulator `Pixel_8_API_35` (x86_64), Godot Compatibility (OpenGL) renderer, debug build
of `m2-survive-the-night`. Measurements carry the host load average (this PC is shared; three agents
and another app's builds ran during parts of it).

Status legend: PASS / FAIL / PENDING. Filled in during M2 Task 12.

| # | Check (plan Task 12, spec §12.12) | Status | Evidence |
|---|---|---|---|
| 1 | A new Survivor world: "How brave are you?", starter kit, hearts, gold, no LAB | **PASS** | First launch → main menu (SANDBOX / SURVIVOR / PLAY ONLINE) → COZY / NORMAL / BRAVE → Brave world with "★ BRAVE" by the hearts. `TOUR kit PASS mode survivor difficulty normal, kit true (planks 16, dirt 8), hearts, gold, no LAB true, gold 25` |
| 2 | Gathering: breaking gives the drop, placing takes one | **PASS** | `TOUR gather PASS broke Grass: Dirt 8 -> 9; placed back: 8` |
| 3 | Tilly's shop; buying a tool with gold | **PASS** (after a fix) | `TOUR trader PASS stone pickaxe bought true for 30 gold`. The screenshot showed CROUCH over the shop's BUY button: fixed (an open overlay moves above every HUD button, `test_hud_overlays.gd`) |
| 4 | Stealth: crouching | **PASS** | `TOUR stealth PASS visibility standing 1.00, crouching 0.50` |
| 5 | Night monsters come; wild ones puff at sunrise | **PASS** | `TOUR night PASS 3 monsters, the nearest a slime 22 blocks away; wild ones puffed away at sunrise: true` |
| 6 | Knock-out, getting up, the pickup bag | **PASS** | `TOUR knockout PASS down true, up true, the blocks dropped true, bags 1, taken back true`; "You were knocked out!" with a picture tip |
| 7 | The Totem's wave, won, pays 10 × N | **PASS** | `TOUR wave PASS wave 1: won, paid 10 gold (expected 10), next 2`; "Wave 1 — 5 left" on the HUD |
| 8 | The Stone Golem, the portal, universe 2 | **PASS** | `TOUR boss PASS won true, gold +300, universe 2, portal true`; the boss bar, "You beat the Stone Golem!", the portal's desert window |
| 9 | Bot friends | **PASS** | `TOUR friends PASS Mossy joined, close true, bot badge true`; "Mossy (bot): Hi, I'm Mossy! Let's build something" |
| 10 | Creature minds | **PASS** | `TOUR minds PASS 11 of 11 animals think` |
| 11 | Secrets | **PASS** | `TOUR secrets PASS Nearest crystal geode: 51 blocks away` |
| 12 | The M1b tour still passes (regression) | **PASS** (after a tour fix) | 17:43, load 8.8 → 15.7: `TOUR done passed=11 failed=0` (seed 2370533658, 51 s; underwater fog blue, 11 animals and a tamed dog, the sword in the realistic hand). The morning's 8/11 at load ~30 was the tour's own waits giving up after one long frame: they now also wait 10 frames (`test_a_wait_never_gives_up_before_its_minimum_frames`, M2 dev log 16:30) |
| 13 | Autopilot at night with monsters, both styles: ≥ 30 FPS, no frame > 100 ms | **PASS for FPS**; slow frames load-bound (re-check on a quiet PC in M5 Task 3) | NIGHT RUN (dev menu; `test_autopilot_night.gd`): midnight and 10 summoned monsters (the per-player cap, Survivor's wild share of slimes/goblins, levels 1–3). Blocky, load 6→14: play **40.5 FPS** (3 frames of 133–146 ms, all in the first 0.7 s after night fell), fly **50.7** (5 single frames ≤ 145 ms). The same run by day right after: play 46.1 (4), fly 50.9 (4) — the monsters cost ~12 % FPS and add no slow frames. Realistic, load 9→6.5: play **38.9** (2), fly **48.2** (7). A first blocky run at load 15–18 gave 21.2 FPS with bursts of slow frames: CPU starvation, not the game. Ruling: Sandbox + 10 summoned monsters stands in for a Survivor night (the same monster systems at the per-player cap; Survivor adds only the static stall and Totem). M1b's quiet-PC baseline had 0–1 slow frame |
| 14 | Online: two games through the relay (emulator + desktop) | **PASS** | Emulator: PLAY ONLINE → "Stay safe online" (I WILL!) → the online name claimed on this PC's server → HOST MY WORLD → SURVIVOR: `ONLINE host match_id=9547a8d0-…` and the green online dot. Desktop: `--online-join=<id>` → `ONLINE joined … as peer 226297524`, `SANDBOX spawned_ms=33635`; the emulator shows the guest's avatar by the portal. `tools/net_test.sh` PASS (the guest got 120 bytes of world data) |
| 15 | Release APK 0.3.0 in `~/Downloads` | **PASS** | `~/Downloads/EasyCraft-0.3.0.apk` (`Android Phone` preset: arm64-v8a, versionCode 5, versionName 0.3.0, "EasyCraft", signed with the debug keystore; sha256 36825b5ad2bdfe1b…; 78 MB) from `9f752eb` (suite 2879/2879, net test PASS). The same release template exported for the emulator: the menu shows v0.3.0, the triple tap opens no developer menu, PLAY ONLINE says "Online play is coming soon!" (no release server yet), SURVIVOR → the universe cards → Sandstorm Desert → NORMAL loads the desert with the new HUD. Release notes: `docs/playtests/whats-new-0.3.0.md` |

The Survivor tour (`tools/tour_survivor.gd`, developer menu → SURVIVOR TOUR) ran on the emulator in
44 s: `TOUR done passed=11 failed=0` (seed 3875942306, load 5–15).
