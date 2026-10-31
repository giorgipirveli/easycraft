# VR on the Meta Quest, P0-P1: the panel side (VR-UI, owner #101, 2026-10-15)

The owner (#101): "this is now N1 priority". The brief: `docs/superpowers/plans/2026-10-15-vr-agents-brief.md` (role
VR-UI); the plan: `docs/superpowers/plans/2026-10-15-vr-quest.md`; the research: `docs/devlog/parts/vr-research.md`. Built
against the lead's frozen contract (`29070825`) in the worktree branch `worktree-agent-a7347d9754abec8dd`, cut from
`lead-merge` at `bcaa3d89`. VR-RIG (the world side: the body of `Vr`, the rig, the trackers, the aim, the Quest presets)
worked at the same time; nothing here needs its files, and everything here works with the contract's stub (`Vr.simulate`)
and with VR-RIG's body once merged.

## What the child sees in the headset (P1, the panel side)

- **The main menu, still.** The menu's camera never orbits in a headset (`ui/menus/menu.gd` `_on_vr_started`): the child
  stands on the backdrop's hill, the eyes at the avatar's height over the ground (`vr_stand`, `Vr.anchor(vr_stand,
  &"menu")`: VR-RIG puts the eye on a menu spot), level, looking the way the window's view looked; the title diorama rides on the camera, so it stays in front. The menu's screens are on the
  **eye panel**: 1.6 × 0.9 m, 1.4 m ahead and 0.1 m below the eyes, never tilted with the head, world-fixed, coming
  round in front again only when the head turns past 50°. A headset started in the menu (ENTER VR) stops the orbit and
  moves the screens; ended, both come back.
- **The laser.** The pointing hand (the right one; LEFT HAND in SETTINGS swaps it) points at the panel: a thin white
  beam runs from the hand to it (VR-RIG's world laser hides then) and a white ring shows where, buttons light up under it, the trigger presses them (the ring fills while squeezed). A squeeze that
  began on the panel stays the panel's until it lets go, wherever the hand goes (nothing sticks pressed, no half-squeeze
  reaches the world).
- **Loading a world: the loading room.** While the loading card is up, a calm dark room surrounds the child (an
  inside-out sphere, a floor grid at the feet one line a metre, a thin horizon ring at eye level), world-fixed, with the
  card on the eye panel: never a black void, never half a world popping in.
- **Playing: the HUD on the tray.** The same canvas, 1 m wide, 0.9 m away and 35° below the eyes, tilted to face them,
  following the head's yaw lazily (a glance aside of less than 25° leaves it; a turn brings it round within about a
  second). The touch-only buttons are hidden (in VR the controllers are the pad), the "+" is gone (the laser aims). The
  laser over the tray's empty canvas lets the trigger through to the world (VR-RIG's TAP/HOLD); over a button the
  button takes it.
- **The pause menu** (the controller's menu button = the pad's START → `pause`) and **every panel that has the pad**
  (the palette, MORE, the boards, the Theater…) move to the eye panel; RESUME brings the tray back. SAVE & QUIT goes to
  the menu as on a phone.
- **SETTINGS → VR COMFORT** (a fourth page, only in a headset): TURNING SNAP 45° (first) / SNAP 30° / SMOOTH, the
  COMFORT VIEW STRONG / LIGHT (first) / OFF, TEXT SIZE NORMAL / BIG (first), RECENTER, and one line about them.
- **Text is BIG** in a headset until the child picks NORMAL on that page (the flat screen's own TEXT SIZE is unchanged).
- **The TV** (YouTube in an Android WebView, or the browser page's player) is not drawn in the VR frame: its sign says
  "The TV plays on a phone or tablet. EasyCraft Shorts play here!" with WATCH SHORTS and BACK TO MY WORLD; the Shorts
  (the game's own reels) play.
- **The world's colour tint** (a flat screen's underwater blue, a sandstorm's sand) is not drawn on the panel: the fog
  and the light carry the mood.

## How it is built (files)

- **The canvas** — `ui/vr/vr_ui.gd` (`VrUi`): made under `Vr` the first time `Vr.ui_viewport()` is asked while a session
  runs, freed when it ends (`Vr.ended`). A transparent 1280×720 `SubViewport` "VrCanvas" (the game's own canvas size:
  every screen lays out as on a phone), `disable_3d`, `PROCESS_MODE_PAUSABLE`, drawn only while the panel shows
  (`UPDATE_DISABLED` otherwise). `VrUi` itself is `PROCESS_MODE_ALWAYS` and `process_priority = -100` (its pointer reads
  the trigger before the world does).
- **Routing** — `core/vr/ui_layers.gd` (`UiLayers.route`, the contract's name; the body is this side's): off VR exactly
  `owner.add_child(layer)`; every routed layer is remembered weakly with its owner. In VR the layer goes into the canvas,
  and leaves it (removed at once, then freed) when its owner leaves the tree. A layer routed before the headset starts
  moves in when it starts and back to its owner when it ends (`move_all_in` / `move_all_out`): the WebXR route starts
  VR in the menu, and the autoloads' toasts are made at boot. A layer keeps its owner's pause behaviour (an
  `PROCESS_MODE_ALWAYS` autoload's toast gets `ALWAYS` set while it is in the canvas, put back after).
- **The layers routed** (the research's 14 CanvasLayers): the world's HUD layer (`scenes/sandbox.gd:103`, the lead's
  seam), the menu's two (`menu.gd`: its screens, the "Back online" note), the loading card (`loading_card.gd` `cover`),
  Music's "Now playing" (`autoloads/music.gd`), Session's invite toast (`autoloads/session.gd`), SETTINGS' MOVE BUTTONS
  (`settings_panel.gd`), the visit's HUD (`world/visit/visit_world.gd`). Already in the canvas with their parents: the
  coin shower (`coin_shower.gd`, a CanvasLayer under a menu's control) and the chat wheels (`dm_panel.gd`). PadFocus's
  ring layer moves with PadFocus. **Not routed, on purpose:** Ambience's tint (hidden in VR, above), Feel's red edge
  (`autoloads/feel.gd`, VR-RIG's: a head-locked tint there), the rocket's cockpit layer (`entities/flight/rocket_flight.gd:259`,
  VR-RIG's, P3: it must go through `UiLayers.route` then, with this side's dashboard mode).
- **PadFocus** (`ui/help/pad_focus.gd`) — moved into the canvas while VR runs (its focus, its ring and every menu's pad
  live there; `VrUi._keep_pad_focus` also catches main.gd's deferred install), back where it was after. `set_vr(true)`:
  the controllers are the pad from the start (the touch HUD hides through the sandbox's `device_changed` → `Hud.set_pad`),
  the laser's mouse and finger events never take the pad away, and the CONTROLLER card's words are the headset's
  (`PadFocus.vr_family()`: `GamepadRules.QUEST` once VR-RIG adds it, else the generic pad's).
- **The forwarder** — `VrUi._input`: the root window's keys and actions, and a **connected** pad's buttons and sticks,
  are pushed on into the canvas (handled there → handled in the root too): a desktop preview's keyboard and game
  controller reach the panels. The headset's controllers are VR-RIG's virtual pad (`VrInput`, device 12, in no joypad
  list), which pushes each event into `Vr.ui_viewport()` itself before `Input.parse_input_event`, so the forwarder leaves
  that device alone (never twice). Never the root's mouse or fingers: the laser is the canvas's only pointer.
- **The panel** — `entities/vr/vr_panel.gd` (`VrPanel`, a `MeshInstance3D` quad): EYE or TRAY (`VrPanelRules.place_for`:
  EYE while a panel has the pad, the game is paused or a world loads). Unshaded, `BLEND_MODE_PREMULT_ALPHA` (a transparent
  2D viewport stores premultiplied colours), no depth test, render priority **127** (the top: over the world, the loading
  room and VR-RIG's comfort sphere, whose black fade and vignette draw at 100: a spawn held behind black still shows the
  loading card).
  Its place is kept relative to the XR origin (`Vr.camera`'s parent), so a world-fixed panel moves with the body, never
  with the head. The head is `Vr.camera`, else the viewport's camera (a desktop preview).
- **The rules** — `ui/vr/vr_panel_rules.gd` (`VrPanelRules`, pure): the head's yaw (looking straight down or up: the
  head's top), the eye and tray transforms, the 50° re-centre, the tray's lazy yaw (`tray_yaw`), the ray-on-panel hit
  (`hit`: u, v and the distance; only the front takes a pointer), the canvas pixel. At 1.4 m the eye panel is 59.5° wide:
  **21.5 canvas pixels a degree**, about one per Quest 2 pixel (20 a degree).
- **The pointer** — `entities/vr/vr_pointer.gd` (`VrPointer`): each frame the pointing hand's ray
  (`Vr.hand_ray(VrRules.pointing_hand(left_handed))`) meets the panel; over it the canvas gets an `InputEventMouseMotion`
  at that pixel; the trigger pushes a mouse button and a finger (`InputEventScreenTouch` index 0; `ScreenDrag` while
  held), as a desktop's mouse does with `emulate_touch_from_mouse`, so `Button`s and the HUD's `TouchButton`s both answer.
  The trigger comes from the hand's `XRControllerTracker` through the XR server exactly as VR-RIG's `VrInput` reads it
  (`trigger`, else `trigger_click`; squeezed from 0.6, let go under 0.35: VrRules' `TRIGGER_ON` / `TRIGGER_OFF`), so
  the panel and the world never disagree about a squeeze; this side needs none of the rig's nodes. The beam
  (`VrPointer.beam`, unshaded, no depth test, priority 126: under the panel it ends on) shows while the panel has the
  laser. `wants_pointer()` (= `Vr.ui_wants_pointer()`): a squeeze the canvas took
  is held; or over the eye panel; or over a control that stops the mouse on the tray. `distance`: where the laser meets
  the panel (for the rig's laser length).
- **The loading room** — `ui/vr/vr_loading_room.gd` (`VrLoadingRoom`): open while a node is in `LoadingCard.GROUP`;
  render priority 110-111 (over VR-RIG's black fade: a spawn holds black until the child stands, and the room is what
  the child sees then, with the card on the panel).
- **ENTER VR** — `ui/vr/vr_entry.gd` (`VrEntry`): only in the Web VR export (`OS.has_feature("webxr")`), asks the browser
  once (`WebXRInterface.is_session_supported("immersive-vr")`), shows the button (top-left of the menu, purple) when the
  answer is yes, the menu's shader warm-up is done and VR is not running; the press calls `Vr.start(VrRules.WEBXR)` (a
  browser starts a session only from a tap) and shows its words if it can't. Also `--vr-preview` (below).
- **VR COMFORT** — `ui/vr/vr_comfort_page.gd` (`VrComfortPage`), a page of `settings_panel.gd` only in a headset;
  `ui/vr/vr_words.gd` (`VrWords`): the words. RECENTER: `Vr.recenter()` once the rig has one, else
  `XRServer.center_on_hmd(RESET_BUT_KEEP_TILT, true)` and `Vr.recentered`.
- **The profile** — `core/save/profile_data.gd`: the contract's `vr_*` keys with VrRules' defaults (`vr_turn`,
  `vr_vignette`, `vr_walk_dir`, `vr_teleport`, `vr_height`, `vr_break_minutes`) and `vr_text_size` ("big"); a turn,
  vignette or text size the game doesn't know reads its default (`VrComfortPage.value_of`). `core/save/profile_backup.gd`:
  all of them in `DEVICE_ONLY_SETTINGS` (a phone's newer backup never resets the headset's comfort).
- **Text** — `ui/theme/text_size.gd`: `TextSize.VR_KEY`; `factor()` reads it in a headset (BIG first); `VrUi` refreshes
  every marked control when VR starts and ends.
- **The HUD** — `ui/hud/hud.gd` `Hud.shows_crosshair` (never in VR); `danger_arrows.gd`, `sound_captions.gd`:
  `VrUi.world_camera(self)` (its own viewport's camera off VR, as before; in VR the headset's: the canvas has none).
- **The TV** — `ui/theater/theater_panel.gd` `VIEW_VR_TV`, `WATCH_SHORTS`.

## The WebXR route (`/vr/`)

- **The export preset** — `export_presets.cfg` **preset.16 "Web VR"**: the "Web" game preset (the same shell, exclude
  filter, threads, PWA with the isolation headers, `script_export_mode=1`) with `custom_features="webxr"`,
  `export_path="build/web_vr/index.html"`, both texture formats (S3TC and ETC2) in its one main pack, and a
  `head_include` whose full-screen-on-the-first-tap script does nothing where `navigator.xr` exists (ENTER VR is the tap).
  `project.godot` `[xr] shaders/enabled.webxr=true`: the multiview shader variants only in that export (the base switch
  stays off: phones and `/play/` compile nothing new; checked in the exported `project.binary`: `_custom_features="webxr"`
  and the override key).
- **The build** — `tools/export_web_vr.sh` runs `tools/export_web.sh` (untouched) with checked swaps: `build/web_vr` and
  `build/web_vr-*`; "Web VR" in place of "Web" and "Web Mobile" (`index.mobile.pck` a copy: one pack, both formats); its
  own browser caches (`EasyCraft-vr-files`, `vr-EasyCraft-sw-cache-…`: `/play/` and `/vr/` share one origin and so one
  Cache Storage, and each worker deletes caches it doesn't know); the page's way home (a browser that cannot run threads)
  `/vr/`. Each swap stops the script with words if `export_web.sh` changed under it. Godot reads presets 0, 1, 2… up to
  the first missing number: **until the lead merges VR-RIG's preset.14 and .15**, the script exports "Web VR" from a copy
  of `export_presets.cfg` numbered without the gap and puts the file back (it said "exported as preset.14").
- **Measured here** (2026-10-15 18:52): 1 min 18 s. `index.pck` **40.8 MB** (the flat build's today: 40.7 MB, so both
  texture formats cost 0.1 MB: the big pictures are in the realistic packs), the same content packs as `/play/` (assets
  7.6, music 20.2, reels 19.6, realistic 69.2 MB). `python3 tools/web_serve.py build/web_vr 8061` +
  `~/src/cdpenv/bin/python tools/web_check.py http://localhost:8061/ 70` (headless Chrome): ready in 6.1 s, the engine
  in Compatibility, the assets pack in, `MENU ready`, the music pack in; **a refresh fetched 0.00 MB** (its own caches).
  Headless Chrome has no headset, so ENTER VR stays hidden there (as on a PC without one).
- **The server** — `server/deploy/caddy/Caddyfile`: `redir /vr /vr/ 308` and `handle_path /vr/*` from `/srv/vr` with the
  same COOP / COEP / CORP and `Cache-Control` as `/play/`, plus `Permissions-Policy "xr-spatial-tracking=(self)"`;
  `server/deploy/docker-compose.yml`: `./vr:/srv/vr:ro`; `.gitignore`: `server/deploy/vr/`. `tools/deploy_web_vr.sh`:
  `tools/deploy_web.sh` (untouched) with `build/web_vr` and the server's `vr/` folder (checked swaps).
- **What the lead deploys** (needs the owner's go for the server, like every deploy):
  1. after the merge: `tools/export_web_vr.sh` (then the presets have no gap);
  2. the server's kit, as for `/tv/` (docs/hosting.md step 4, RESUME-HERE 2026-09-30): `server/deploy/kit.sh pack` →
     scp **the printed path** → untar into `~/easycraft` → `mkdir -p ~/easycraft/server/deploy/vr` →
     `server/deploy/kit.sh update` → `docker compose … up -d --force-recreate caddy` (the new `./vr` bind mount needs the
     container made again; a Caddy reload alone does not add it) → `kit.sh check` (the module's version unchanged: this
     changes no server code);
  3. `tools/deploy_web_vr.sh` (brotli + gzip, rsync to `~/easycraft/server/deploy/vr/`);
  4. check: `curl -sI https://178-104-20-64.sslip.io/vr/ | grep -i cross-origin` (both headers) and
     `~/src/cdpenv/bin/python tools/web_check.py https://178-104-20-64.sslip.io/vr/ 60`; `/play/` unchanged
     (`curl -sI …/play/`).

## Rulings (the cost if wrong)

1. **Panels are drawn over the world** (no depth test). A wall nearer than 1.4 m (the child stands against a cliff) never
   hides a menu. [Stereo depth conflict when something is nearer than the panel: depth-test it and pull the panel to the
   nearest free distance.]
2. **One canvas, two places.** The tray shows the whole 1280×720 HUD (corners included) at 1 m; no wrist strip yet (P2).
   [The tray's corners are at the edge of comfortable reading: the P2 wrist hotbar and hearts.]
3. **EYE whenever PadFocus says a panel has the pad**, the tree is paused or a world loads. Every watched panel (the
   palette, MORE, the boards) therefore comes to the eye, the world's pad inputs set aside as with a pad. [A panel meant
   to be glanced at while walking (none in P1) would need a "tray" mark.]
4. **The laser lets the trigger through on the tray's empty canvas** (only a control that stops the mouse, or a press a
   control handled, keeps it). The HUD's TouchButtons pass the mouse, so hovering one does not stop the world, but a
   press on one does (it handles the finger). [A rig that decides TAP/HOLD on the press frame and asks
   `ui_wants_pointer()` before this side's step would see "no" over a TouchButton: `VrUi.process_priority = -100` runs
   first; if the rig acts in `_input`, it should ask on the release instead.]
5. **The menu stands the child on the hill**, not at the orbit's camera spot 20 m in the air (height with no floor is a
   classic fear trigger): the menu spot is the eye's place, the avatar's eye height over the ground. When the menu leaves
   the tree it lets go of the spot (`Vr.anchor(null)`). [A tree on the hill's top block: the head in leaves; move the
   spot to the first free column.]
6. **Ambience's tint is hidden in VR** instead of routed (a tint on the canvas would colour only the HUD). [The underwater
   blue is lost in VR until VR-RIG's head-locked tint shows it.]
7. **The vr_* settings stay on their device** (`DEVICE_ONLY_SETTINGS`). [A child with two headsets sets each.]
8. **Text BIG by default in VR**, as its own setting (`vr_text_size`), so a phone's NORMAL never shrinks the headset's.
9. **One Web VR main pack with both texture formats** (measured: +0.1 MB). [None now; a split like Web/Web Mobile
   if pictures move into the main pack.]
10. **`/vr/` has its own browser caches.** [None: without it each visit to the other path deleted the other's downloads.]
11. **ENTER VR waits for the menu's shader warm-up** (a first-sight compile in a headset freezes the whole view).
    [A slow device waits longer before the button shows.]
12. **The full-screen script does nothing where `navigator.xr` exists** (a PC's Chrome too, at `/vr/`). [A PC opening
    `/vr/` doesn't go full screen on its first click: `/play/` is the flat game.]
13. **The panel draws at the top (127), the beam at 126, the loading room at 110-111**, all without a depth test: over
    VR-RIG's fade (100). [A fade meant to hide a menu (none in P1) would need the panel hidden instead.]
14. **The forwarder hands in only a connected pad's events**: the headset's virtual pad pushes its own. [A virtual pad
    that does not push into the canvas (a future one) never reaches the menus: it must push as VrInput does.]
15. **The rule-5 question (test on the emulator)**: VR is tested with `Vr.simulate` under GUT and headless here; the
    emulator stays for non-VR regressions; the owner's Quest decides (the plan's ruling 6).

## Seams and what the lead must merge

- **Outside this side's files, one-line or small, marked `owner #101`:** `autoloads/vr.gd` (the contract's two bodies,
  `ui_viewport` → `VrUi.ensure(self).viewport` while active, `ui_wants_pointer` → `VrUi.wants_pointer()`; VR-RIG writes
  the rest of the file: keep these two lines), `project.godot` (`[xr] shaders/enabled.webxr=true`; VR-RIG adds its own
  `xr/*` lines to the same section), `export_presets.cfg` (preset.16 after VR-RIG's 14 and 15: the file's end conflicts,
  keep all three), `core/save/profile_backup.gd` (`DEVICE_ONLY_SETTINGS`), `ui/theme/text_size.gd` (the VR text size),
  `.gitignore`, `server/deploy/*`, `tools/export_web_vr.sh`, `tools/deploy_web_vr.sh` (new). Nothing in
  `scenes/sandbox.gd` or `scenes/main.gd`: the research's `main.gd:18` seam (PadFocus's parent) is not needed (VrUi moves
  PadFocus in itself, also after main.gd's deferred install).
- **VR-RIG's body, as it is now (read from its branch, nothing of it edited):** it leaves `ui_viewport` and
  `ui_wants_pointer` to this side; its `VrInput._send` pushes the headset's pad into the canvas first (the forwarder
  above leaves that device alone); its comfort sphere draws at 100 (the panel at 127, the room at 110-111, the beam at
  126); `Vr.recenter()` and `Vr.pointing_hand()` exist (the VR COMFORT page calls `recenter()` when it is there; the
  pointer's `VrRules.pointing_hand(left_handed)` is the same rule); `GamepadRules.QUEST` exists, so
  `PadFocus.vr_family()` already gives the CONTROLLER card the Quest's words (VR-RIG's suggested one-liner in
  `PadFocus._set_pad` is not needed); a `&"menu"` anchor puts the eye on the node (the menu's spot is at eye height);
  its own `--vr-preview` starts first (`VrEntry.preview_from_args` then only marks the preview; `--vr-preview=sandbox`
  starts the rig's preview through `Vr.preview(true)` when it exists).
- **The integration, checked before the lead's merge** (no merge: the merged tree of this branch and VR-RIG's
  `worktree-agent-af972211a2b1e38dd` computed with `merge-tree`, unpacked into a scratch copy with both sides of the
  three conflicts kept): conflicts only in `project.godot` (`[xr]`: keep both sides' lines), `export_presets.cfg` (its
  end: keep preset.14, .15 and .16) and `docs/DEVELOPMENT.md` (keep both VR sections); `autoloads/vr.gd` and
  `tests/unit/test_shader_warmup_sources.gd` merge by themselves. Both agents' VR tests on it: **121 of 121 pass** (13
  scripts: the contract, `test_vr_rig_*`, `test_vr_ui_*`, the warm-up's list); the headless previews (`--vr-preview`:
  the rig's; `--vr-preview=sandbox`: menu → loading room → `SANDBOX spawned_ms=3080` → tray) print no errors.
- **For VR-RIG (through the lead):**
  - `Vr.step_physics` follows `_anchor` while `is_instance_valid`; a node that left the tree but is not freed yet (a
    scene change's frame) gave `get_global_transform` errors (`!is_inside_tree()`) from `VrRig.eye_point`: also check
    `_anchor.is_inside_tree()`. The menu now lets go of its spot itself, so this side no longer triggers it.
  - `Vr.ui_wants_pointer()` before a world TAP/HOLD (it asks already): true while a squeeze the canvas took is held.
  - The laser's length: while `VrUi.instance.pointer.hovering`, the panel is `pointer.distance` metres along the ray.
  - Feel's red edge (`feel.gd:21`) stays in the root (invisible in the headset): its VR tint is the comfort sphere's.
    The rocket's cockpit layer (`rocket_flight.gd:259`) goes through `UiLayers.route` in P3 (the dashboard quad: a node
    path agreed in both notes then).
- **Contract additions proposed** (not made; the names are the lead's to freeze): `Vr.recenter()` and
  `Vr.pointing_hand()` (VR-RIG made them: freeze them), `Vr.trigger(side) -> bool` (one reading of the trigger for
  both sides instead of two copies of VrInput's rule), `Vr.ui_hit() -> float` (the laser's length).

## What only the headset can check, and how the lead checks it

- **Readability and comfort of the panels** (the eye panel's size and distance, the tray's angle and its lazy follow,
  the ring): put the headset on, open SETTINGS from the menu, read the smallest words (the menu's credit is 20 px:
  P2's readability pass raises every word under 24 px), turn the head 60° and back (the panel comes round past 50°).
- **The laser into the canvas** (UV → pixel on the real quad, Buttons, the HUD's TouchButtons, sliders): menu → SANDBOX →
  NEW, press MORE and BLOCKS with the laser, drag the volume slider in SETTINGS.
- **The pad in the canvas** (the left stick and A in the menus; the pause menu's START): needs VR-RIG's `VrInput`.
- **The WebXR route**: `https://178-104-20-64.sslip.io/vr/` in the Quest's browser (after the deploy above): ENTER VR
  shows (the browser says immersive-vr is supported), the permission prompt, the menu on the eye panel. UNCONFIRMED until
  then: `crossOriginIsolated` in the Quest Browser, WebXR Layers (Godot needs them), the session starting from the
  button's tap one frame later.
- **Premultiplied alpha** (the canvas's soft edges look right, not dark-fringed) and the panel's sharpness (a
  composition layer later if text is soft: P2).
- **Cost**: the canvas is drawn only while the panel shows, but it is a full 1280×720 2D pass every frame then; the
  VR_BENCH line (VR-RIG's `tools/vr_bench.gd`) shows it.

## Tests and how to look without a headset

- `tests/unit/test_vr_ui_panel_rules.gd` (9: the places, the re-centre, the tray's follow, hits, pixels, the pixels a
  degree), `tests/integration/test_vr_ui_canvas.gd` (9: off VR nothing; the canvas; routing in, out, with the owner, the
  pause behaviour; PadFocus in the canvas with the headset's words; the headset's pad (VrInput's way) presses once and
  the root's keys reach it; the root's mouse doesn't; which events the root hands in), `test_vr_ui_pointer.gd` (8:
  clicks on the eye panel, the tray's let-through, a TouchButton, a squeeze let go off the panel, the beam, the ring,
  the render priorities, the places), `test_vr_ui_menu.gd` (7: still, on the hill at eye height, level; the spot let go
  when the menu leaves; the screens on the panel; the game's PadFocus puts the menu at the eye; started and ended in the
  menu; no ENTER VR off the Web VR export; ENTER VR's rules), `test_vr_ui_screens.gd` (9: loading card and room, the
  autoloads' toasts, VR COMFORT, text BIG, the profile's keys, device-only, no cross, the TV's sign, no tint),
  `tests/unit/test_vr_ui_web_vr.gd` (4: the preset, the shaders' switch, the scripts, the server): 46, and the
  contract's 7. Three VR materials are in `test_shader_warmup_sources.gd`'s COVERED list (rare: VR only; the WebXR
  census in P5).
- **The full suite** (2026-10-15, at `ac162cf4`, its own log `vrui_full_ac162cf4.log`): 1065 scripts, 9826 tests,
  **9824 passing, 0 failing**, 11 risky or pending (tests without an assert and the Nakama scripts skipped without a
  server, as before), 3824 s, exit 0. An earlier run (at `4a071f68`) failed two: the warm-up's COVERED list (fixed:
  the VR materials listed) and `test_theater.gd`'s server-list cache, a `user://` file every worktree's suite shares
  (passes alone; another agent's suite ran at the same time).
- **Desktop preview:** `XDG_DATA_HOME=<a private folder> godot --path . -- --vr-preview` (the menu) or
  `-- --vr-preview=sandbox` (on into the Sandbox world): VR-RIG's preview once merged (`Vr.preview(true)`), else a
  simulated session; the panel stands in front of the head, a free mouse is the laser (its left button the trigger; a click on the panel never captures the mouse), a
  click in the world captures the mouse as on a PC (mouse look turns the "head"), Esc frees it. The log prints
  `VR_PREVIEW place=eye|tray layers=N loading=… paused=…` at every change. Headless here
  (`timeout 75 godot --headless --path . -- --vr-preview=sandbox`): `place=eye loading=true` → `SANDBOX spawned_ms=3007`
  → `place=tray`, no script errors.

## Round 2 (P2, and the rocket's dashboard with VR-RIG's P3), 2026-10-15 21:40-22:30

Started from `lead-merge` with both P0-P1 sides (`f8bef3d9`), then VR-RIG's round 2 (`cc821392`) and the lead's docs
(`97d56b3e`, owner #102's hold: this round finishes and is saved; nothing new starts). The lead's two settled points are
followed: the trigger through `Vr.trigger(side)` now and `Vr.trigger_pressed(side)` the moment VR-RIG's round 3 adds it
(`VrPointer._default_trigger`, one `has_method` switch); the dashboard at `RocketFlight.vr_dashboard()`
(`RocketFlight/VrSeat/VrCapsule/Dashboard`, +Z to the child) on `RocketFlight.LAYER`.

### What the child sees now (new in P2)

- **Every word on the panels is 24 px or more** (21.5 canvas px a degree at 1.4 m: about 1.1° or more), and white or
  yellow words on buttons have the labels' dark outline (white on the game's green is 2.88:1, orange 2.51:1, blue
  4.06:1: under the 4.5:1 floor without it; the dark box is 12.4:1). Screens that did not fit their words at 24 px got
  a VR-only change: the School map's tiles keep two lines and end with "…" (the unit's page has the whole title), the
  Secret Book's tabs show their pictures alone (bigger), the chat's hint takes a second line, the Gold Shop's shelf tabs
  wrap.
- **A keyboard** comes up on the eye panel whenever a text box has the focus (the name, chat, codes, a pet's name, the
  online keys, the invite code, the Shorts maker: any box, none of them changed): big keys (digits, letters, - . _ ?,
  SHIFT for one capital, SPACE, DELETE, ENTER, DONE), a line at its top showing what is typed. The laser presses its keys;
  the sticks move a yellow ring over them and A presses; B or DONE puts it away (it comes back when the box is chosen
  again). It covers the screen's foot as a phone's keyboard does: ENTER submits (the name's OK), DONE shows what is under.
- **VR COMFORT**, the whole page: Turning (SNAP 45° / SNAP 30° / SMOOTH), Comfort view (STRONG / LIGHT / OFF), Walking
  (WHERE I LOOK / WHERE I POINT), Height (GAME / MY OWN), Teleport (ON / OFF), Break (30 MIN / 60 MIN / NEVER), Text size
  (NORMAL / BIG), RECENTER. SETTINGS with it is 669 px tall.
- **The break card** after 30 minutes in the headset (VR COMFORT's Break): "Time for a break! You have been in VR for 30
  minutes. Take the headset off and rest your eyes for a while: the game waits for you." on the eye panel, the game
  paused behind it, I'M BACK (A) goes on; the next card 30 minutes later.
- **On the other wrist** (the hand that does not point) the hotbar, the hearts and the gold float over the hand, facing
  the eyes, while the child plays; **a toast** (else the boss bar, else the wave line) floats on a strip just above the
  gaze while it shows, lazily following the head. The tray stays (everything pressable is there).
- **The rocket's dashboard**: seated in VR-RIG's capsule, the cockpit's screens, hologram, lever, ACTION, the trip's
  words and the countdown are on a screen 0.55 m ahead and 0.32 m down, tilted to the eyes (0.72 m wide); no tray while
  flying, a pause still comes to the eye panel.

### How it is built (files, round 2)

- `ui/vr/vr_readability.gd` (`VrReadability`): `lift` (a text control under `MIN_PX` gets an override of 24, its own
  size kept in meta `vr_font_kept`), `watch` (its `theme_changed`: a size its screen sets again later is lifted again,
  `relift`), `outline` (a `Button` whose `font_color` is light: outline 6 px, black 0.8), `restore` (all of it back when
  VR ends), `in_picture` (meta `vr_picture`: a Short's stage, `ShortPlayer`, keeps its own sizes), `too_small` (the
  audit's check, the drawn scale counted), `contrast` (WCAG 2). `VrUi` lifts the whole canvas when VR starts and every
  control added to it a frame later (`node_added`).
- `ui/vr/vr_keyboard.gd` (`VrKeyboard`, on its own CanvasLayer 125 in the canvas): `step` (VrUi, every frame: up for the
  canvas's focused editable `LineEdit` / `TextEdit`, `edit()` on a LineEdit), its keys `FOCUS_NONE` and `pad_skip`, the
  typing as `InputEventKey`s pushed into the canvas a moment after the press (so the box's own `max_length`,
  `text_changed`, `text_submitted` work), `pad_input` (PadFocus hands it every pad event while it shows:
  `PadFocus.keyboard`), the ring (`Ring`). `VrUi` puts the panel at the eye while it shows.
- `ui/vr/vr_comfort_page.gd`: every vr_* setting (`CHOICES`, `ROWS_KEYS`), `value_of` for any type (a JSON float back to
  an int; an unknown answer reads the default), used by `ProfileData` for every key. `ui/vr/vr_words.gd`: the words.
- `ui/vr/vr_break_card.gd` (`VrBreakCard`, CanvasLayer 115): `due(worn, minutes, last)`, `open` (pauses, remembers a
  pause that was there), `close`; `VrUi.worn` counts the seconds in the headset.
- `entities/vr/vr_wrist.gd` (`VrWrist`): strips of the canvas (UV sub-rects, 0.0004 m a pixel on the wrist, 0.0011 m for
  the toast at 1.3 m and 18° up), from `Hud.vr_rects()` (`ui/hud/hud.gd`: the hotbar, hearts, gold, toast, boss bar and
  wave line's rects; `Hud.GROUP`), placed at the hand from `Vr.hand_ray` (the non-pointing side), facing the eyes.
- `ui/flight/flight_cockpit.gd`: `dashboard_mode` (set when VR starts or ends), `dashboard_rect` (the canvas's bottom
  400 px), `GROUP`. `VrUi._step_dashboard` finds the node that offers `vr_dashboard()` once per cockpit (a tree search,
  at most once a second while none) and copies its transform to the quad each frame; the quad's UV is the band.
- `VrPanelRules.LAYERS` (`1 | RocketFlight.LAYER`) on every VR mesh (panel, beam, loading room, wrist, toast,
  dashboard): the head draws the flight camera's layers in space.

### The readability audit (the research's P2 acceptance)

- `tests/integration/test_vr_ui_audit.gd` makes each screen in the VR canvas as its own tests do
  (`tools/vr_ui_screens.gd`): the School's map, a unit and a round; the Mission Board's MISSIONS, MY ROCKET with BUILD IT
  FOR ME, PARTS and the buy card; the Gold Shop; Gemma's board; the inventions book; the Star Map; the Secret Book; MY
  MAP; the Shorts feed and maker; the chat; VR COMFORT. On each: no word drawn under 24 px, the screen fits 1280 × 720,
  no word past the panel's edge, no one-line word cut off by its box; and the School map's tiles keep their words inside.
- `tests/integration/test_vr_ui_reach.gd` ("a test like test_pad_screens over VrUi"): the main menu's screens (the
  start, the name, BOY / GIRL / JUST ME, the mode choice, AVATAR, the School, the codes, Monster Wave), SETTINGS' four
  pages, the School's map, a unit and a round, the Mission Board's pages, the Gold Shop and the pause menu, in the VR
  canvas on the eye panel: the sticks reach every control the pad can focus (PadFocus's candidates, GamepadRules'
  rules, from the focus PadFocus put there), the laser lands on each (aimed at its middle from the pointing hand; one in
  a scroll once scrolled in), and where a box has the focus every key of the keyboard too; one real push of the walking
  stick moves the focus in the canvas.
- **Pictures** (`tools/vr_ui_shots.gd`, a window for about 20 s; 19 PNGs in `user://vr_ui_shots/`): the smallest word on
  every screen is 24 px (28 on a round, 30 on the Star Map and the break card, 36 on the keyboard). Looked at: the
  School map (fixed: before, three-line titles ran over the stars), MY ROCKET with BUILD IT FOR ME, PARTS, the inventions
  book (fixed: the books' dark ink had been given the white words' outline), the Secret Book (fixed: the tabs' words were
  cut), VR COMFORT, the keyboard over the name and over the chat. Still seen: the keyboard covers the chat's quick
  phrases until DONE (ruling 19).
- **Not lifted:** words drawn inside the School's pictures (`draw_string` in `school_picture_*.gd`: a diagram's labels at
  the picture's own size) and a Short's stage (its actors' labels; its caption is big already). They are pictures.

### The eye panel as an OpenXRCompositionLayerQuad: ruled out

The lead's condition was "only if it is sharper and works on WebXR too". It cannot work on WebXR: the composition layer
classes are the OpenXR module's, which Godot's web templates are built without (the WebXR route has no
`OpenXRCompositionLayerQuad` at all), and a layer drawn by the runtime over the world needs the hole-punch trick to sit
behind the hands and the laser (Godot's composition-layers page). Sharper is also unmeasurable without the headset. So
the eye panel stays one depth-free mesh quad on both routes (the canvas's 21.5 px a degree is about the Quest 2's 20).
If the owner finds the text soft on the native APK, a native-only layer behind `OS.has_feature("quest")` is the next step
(P5), with `transparent_bg` and `layer_viewport = VrUi.viewport`.

### Rulings (round 2; the cost if wrong)

16. **24 px for every word in the canvas, by lifting sizes in VR** rather than rewriting 120 small sizes in 260 scripts.
    [A screen that lays out words it was not made for: the audit and the pictures found four (fixed); one the audit does
    not open could spill: the next pictures run.]
17. **Pictures keep their words** (the School's drawn diagrams, a Short's stage). [A diagram's small label is hard to
    read in the headset: the School's picture pass for VR (P5).]
18. **The keyboard is in the canvas, at its foot** (as a phone's), not on a panel of its own. [It covers what is under
    it: ENTER and DONE are the ways out; a separate keyboard panel under the eye panel is the alternative.]
19. **It comes up whenever a box has the focus**, also when a screen focuses it itself (the name, the chat). [The
    chat's quick phrases are under it until DONE: open it only on a press if children miss the phrases.]
20. **The tray stays with the wrist** (everything pressable is on the tray; the wrist and the toast strip are glances).
    [Two HUDs to look at: drop the tray (a VR COMFORT choice) if the owner finds it busy.]
21. **The break card pauses the game** and has one button (I'M BACK). [A child who wants to go on presses it at once:
    the card is a reminder, not a lock.]
22. **The dashboard is a display**: the flight is flown with the controllers (VR-RIG's rocket mapping), the laser does
    not press its buttons. [A child pointing at ACTION finds it does nothing: make the dashboard a second pointer target.]
23. **The Secret Book's tabs are pictures in VR** (a 24 px word never fits a 104 px tab). [A child unsure of a picture
    opens it to read its title.]

### For the lead and VR-RIG (round 2)

- Files outside the round's own (each a few lines, marked `owner #101`): `ui/shop/gold_shop.gd` (the shelf tabs wrap),
  `ui/school/unit_stop.gd` (two lines in VR), `ui/shorts/short_player.gd` (its stage is a picture),
  `ui/hud/secret_book.gd` and `ui/hud/chat_panel.gd` (this side's HUD files), `tests/unit/test_shader_warmup_sources.gd`
  (COVERED: `vr_pointer.gd`, `vr_wrist.gd`, `vr_ui.gd` besides P1's two). VR-RIG's files: none.
- **For VR-RIG:** the cockpit sits in the sandbox's layer, so `VrUi` finds the flight by a tree search for a node with
  `vr_dashboard()` once per cockpit; one line in `rocket_flight.gd` (`add_to_group(&"rocket_flight")`) would make it a
  lookup. When `Vr.trigger_pressed` lands nothing else changes here.
- Nothing to deploy (owner #102's hold): the Web VR export picks all of this up at its next `tools/export_web_vr.sh`.

### What only the headset can check (P2)

1. Readability at 1.4 m: the School map, a lesson, the Mission Board's PARTS, the Secret Book, VR COMFORT; the smallest
   words (24 px) and the outlined white words on green and orange.
2. The keyboard: the name typed with the laser and with the sticks (the yellow ring), ENTER's OK, DONE.
3. The wrist: raise the other hand: the hotbar, hearts and gold readable over it; a toast above the gaze.
4. The break card: VR COMFORT's Break at 30 MIN (or a developer's shorter test by setting `VrUi.instance.worn`).
5. The dashboard in a Moon flight (VR-RIG's capsule): the screens readable at 0.55 m, the countdown on it.

### Tests (round 2)

`test_vr_ui_readability.gd` (5), `test_vr_ui_keyboard.gd` (6), `test_vr_ui_comfort.gd` (5), `test_vr_ui_wrist.gd` (3),
`test_vr_ui_dashboard.gd` (3), `test_vr_ui_audit.gd` (7), `test_vr_ui_reach.gd` (5); the pointer test checks the layers
too. All VR-UI tests with the contract's: 87 of 87 (14 scripts).

**Stopped by the owner (22:25, "stop all works").** Every round-2 item is built, tested (87 of 87 VR-UI tests) and committed.
Not done: round 2's full suite (killed partway; the last full run, P1 at `ac162cf4`: 9824 of 9826, 0 failing).
Resumed 2026-10-16 (owner #108, below).

## Round 2, continued (2026-10-16, owner #108: "continue and finish VR"; the headset is a Quest 3)

The lead's `lead-merge` brought the accounts (owner #104 / #105: LOG IN, LOG OUT, PASSWORD, the logged-out card, the
device-move card) and the Moon landing (owner #106: the descent, its panel and the first try's hint card). This part
makes them work in the headset.

### The merge

`01f22cff`: one conflict, `ui/flight/flight_cockpit.gd`; both kept (the dashboard mode with its countdown in the band,
and #106's DESCEND word, `_build_descent`, the descent's dials and hint card).

### What the child sees now (new)

- **LOG IN, LOG OUT and PASSWORD in the headset:** the account overlay comes to the eye panel (in the VR canvas, not on
  the flat screen behind the headset); every word 24 px or more. The name and the password are typed with the VR
  keyboard. A password stays secret: the keyboard's own line shows dots, it is never read aloud and never in any words
  on the canvas. A purple **SHOW** key (only for a password box) shows it; it becomes **HIDE**, and the field's own
  SHOW button follows.
- **The logged-out card** ("This device was logged out. LOG IN to play here.") comes to the eye panel whatever the child
  was doing, and the controllers reach LOG IN, NEW PLAYER and LATER; LATER sends the panel back. The device-move card
  is drawn in the canvas too.
- **The main menu's account button** (LOG IN / LOG OUT) is on the panel at 24 px or more.
- **The Moon landing on the dashboard:** the descent's panel (HEIGHT, SPEED, FUEL, "safe: under 3 m/s") and the first
  try's hint card are inside the dashboard's band; the panel's small words are 24 px there (20 on a phone). The hint card
  sits under the trip's words; while it shows, the words drop their hint line (the card says it). Its button reads
  **PRESS A TO GO!** (read aloud too); the controller's A is GO (and only GO: not ACTION as well), and so is the
  laser's trigger anywhere on the card (the one part of the dashboard the laser presses).

### How it is built (files)

- `ui/online/accounts_overlay.gd` (`_frame`) and `net/online_service.gd` (`_lo_layer`, `_mv_layer`): one line each,
  `UiLayers.route(layer, host)` instead of `add_child` (owner #101 marks). Off VR it is the same `add_child`.
- `ui/online/logged_out_card.gd`: `PadFocus.watch(self)` when `Vr.active()` and on `Vr.started` (in VR only: on a phone
  the card is as it was).
- `ui/vr/vr_keyboard.gd`: `SHOW` in the bottom row (SPACE 330 to 250 px, SHOW 150 px), `is_secret()`, `shown_text()`
  gives dots for a secret box, `_show_key()` (visible only for a password box; meta `vr_secret_box` keeps it after SHOW
  shows the words), `_toggle_secret()` (the parent's `toggle()` when it has one, as `PasswordField`, else `secret`).
- `ui/flight/flight_cockpit.gd`: `DASH_REGION_H` 400 to 520 px (the dashboard's quad: 0.72 x 0.29 m, was 0.23 m tall;
  well inside the capsule's 1.25 m), `DESCENT_WORDS` and `descent_word_px()` (24 in dashboard mode), `_place_hint_card()`
  (screen centre off VR; in VR the band under the words, re-placed when the words' box resizes), `_go()` (GO, and in
  dashboard mode with the card up the controller's `rocket_action`), the hint line hidden in dashboard mode while the
  card shows. Off VR nothing changes (20 px, the card centred).
- `tools/vr_ui_screens.gd`: four more screens for the audit and the pictures: `log_in`, `password_make`, `logged_out`,
  `cockpit_descent`.

### Rulings (the cost if wrong)

24. **SHOW on the keyboard drives the field's own SHOW** (one state, two buttons). [A field without `toggle()` flips
    `secret` itself: a later password field with its own state would need the same method.]
25. **The logged-out card comes to the eye** in VR, also mid-play. [It interrupts: it is a stop the child must answer
    (LOG IN or LATER), as on a phone where it covers the screen.]
26. **The hint card's GO is A on the dashboard, and the card says so** (the coordinator's fix before the merge): in VR
    its button reads **PRESS A TO GO!** (the word from `rocket_action`'s Quest binding, `FlightCockpit.go_key()`) and
    the card is read aloud with "Press A to go!" after the hint (`hint_words()`). **The laser presses the card too:**
    the one exception to ruling 22. `VrPointer` has the dashboard's quad as a second surface (`dash`, `dash_band`,
    `dash_area`) that it hits only inside `FlightCockpit.laser_area()` (the hint card while it shows, nothing
    otherwise; nothing while a pause or a menu is at the eye). There the beam and the ring show and a trigger press
    anywhere on the card is GO (the card's `gui_input`; `_go()` runs once per press). The rest of the dashboard (the
    lever, the dials, ACTION) stays a display. [In the seat the trigger is also VR-RIG's throttle: a child who
    squeezes GO and keeps squeezing starts the burn at once (what the hint asks for). If that surprises children,
    VrInput could hold the throttle at 0 while `Vr.ui_wants_pointer()`.]
27. **The band grew to 520 px** rather than shrinking the descent's panel or the card. [A bigger quad below the eyes:
    if it reaches the window's view in the headset, lower `DASH_REGION_H` and the card's words.]
28. **On the dashboard the words drop their hint line while the card shows** (the card and a two-line hint do not both
    fit under each other in 520 px). [The child reads the hint once, on the card; after GO the line is back.]

### Tests (this part)

- `test_vr_ui_accounts.gd` (4, new): LOG IN at the eye in the canvas and readable; the name and a secret password typed
  with the keyboard (dots, never in the canvas's words, never read aloud by a spy voice, SHOW / HIDE, no SHOW for a
  name); the logged-out card at the eye and readable, LATER sends it away; the menu's account button readable on the
  panel.
- `test_vr_ui_dashboard.gd` (5, two new): the descent's panel and the hint card inside the band, the panel under the
  words, the card under the words, 24 px, A is GO and not ACTION; off VR as it was (20 px, the card centred).
- `test_vr_ui_audit.gd` (8, one new): the four new screens (23 screens in all, smallest word 24 px or more in the
  pictures).
- `test_vr_ui_reach.gd`: skips a hidden key (SHOW for a name box).
- The GO fix (ruling 26), `test_vr_ui_dashboard.gd` (8, three new): in VR the card says PRESS A TO GO! and is read
  aloud with "Press A to go!" (24 px, inside the card and the band); the laser on the card shows its beam and a
  trigger press there is GO, the laser on the lever or ACTION presses nothing, after GO the dashboard is a display
  again; the laser on GO is one GO, not two. Off VR: "GO!" and the hint read as it was. Run with the audit, the
  pointer's tests and the flight and descent tests: 13 scripts, 124 of 124; every `test_vr*` script: 25, 201 of 201.
- **The full suite at `9de0a386`** (`tests/run_tests.sh`, 2026-10-16): 1103 scripts, 10153 tests, 10151 passing,
  0 failing, 12 risky/pending; exit 0. All 14 `test_vr_ui_*` scripts in it.

### What only the headset can check (this part)

1. LOG IN with the laser and with the sticks: the name, the password (dots), SHOW / HIDE, ENTER.
2. The logged-out card in front of the eyes (log the device out from another device while the child plays).
3. A Moon landing on the dashboard: the panel readable at 0.55 m, the card under the words, PRESS A TO GO! with A
   and with the laser's trigger on the card (the beam and the ring on the dashboard); whether the taller quad (0.29 m)
   stays below the window.
