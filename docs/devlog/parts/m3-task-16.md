# M3 Task 16: photo mode (notes)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night` at `eabb3ad`),
without the editor or the emulator. Spec §14.14 (refined here), plan Task 16. Commit `ccb0342`.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Camera button | `ui/hud/hud.gd` (section at the end), `ui/photo/photo_chip.gd` | Round button with a drawn camera, top right at (-226, 104) 90 × 90 from the top-right corner: under the username and M2's gold counter, left of the WALK/SIZE column. Shown on phones and desktop; emits `Hud.photo_requested`. P opens photo mode on desktop (`photo` action). |
| Photo mode | `ui/photo/photo_mode.gd` (`PhotoMode`, in the sandbox's CanvasLayer between the HUD and the pause menu) | Hides the HUD, looks through its own `Camera3D`, steers it with gestures, applies filters and frames, takes, saves and shares photos. `PROCESS_MODE_ALWAYS`. |
| Free camera | `core/photo/photo_orbit.gd` (`PhotoOrbit`) | Yaw/pitch/distance/pan around the player's head, started from the game camera (no jump). Limits: pitch −1.45…1.3, distance 0.8…12, pan ≤ 6 blocks, all × Size Magic (clamped 0.4…3). Walks the grid (`GridRay`) from the head to the look point and on to the camera: stops 0.3 before the first solid block, then backs off until no block is within 0.2 (the near plane). |
| Gestures | `core/photo/photo_gestures.gd` (`PhotoGestures`) | One finger orbits; two fingers pinch (zoom factor = old gap / new gap) and pan (the middle of the two fingers); a third finger is ignored. Desktop: left drag (an emulated touch, `emulate_touch_from_mouse` is on) orbits, right/middle drag pans, the wheel zooms. |
| Filters | `core/photo/photo_filters.gd`, `ui/photo/photo_filter.gdshader` | NORMAL, WARM, COOL, B&W, COMIC. One `canvas_item` shader (`hint_screen_texture`: saturation, contrast, brightness, tint, posterise levels, Sobel-style ink outline, vignette) on **one** `ShaderMaterial` owned by photo mode; a filter only sets uniforms. NORMAL hides the pass. |
| Frames | `core/photo/photo_frames.gd`, `ui/photo/photo_frame_overlay.gd` | NONE, PHOTO (instant-photo border with an "EasyCraft" caption), FILM (strip with holes), STARS (pink border with stars), GOLD. Draw calls only; each leaves ≥ 70 % of the picture and its middle free. |
| Shutter and saving | `PhotoMode.take_photo`, `core/photo/photo_files.gd` (`PhotoFiles`) | Hides the buttons, waits for one drawn frame (`RenderingServer.frame_post_draw`), reads the viewport back (filter and frame included), white flash, `shutter` sound, PNG encoded on a `WorkerThreadPool` task, then written: Android `Pictures/EasyCraft/` (Godot routes shared storage through MediaStore, no permission on Android 10+) else `user://photos/` ("Saved in the game's photo album!"); desktop `user://photos/` (the message shows the folder). Names `EasyCraft_YYYYMMDD_HHMMSS.png`, `_2`, `_3` … never overwrite. |
| Share | `ui/photo/photo_share.gd` (`PhotoShare`) | Android: writes the last PNG to `user://photo_share.png` and opens the share sheet (ACTION_SEND + `createChooser`) with a content URI from Godot's own FileProvider (`<package>.fileprovider`), all through `JavaClassWrapper` (no plugin). If any step fails: `OS.shell_open(file)` (Godot's FileProvider + ACTION_VIEW: the gallery viewer, which has a Share button). Desktop: the button says FOLDER and opens the photos folder. |
| Sound | `tools/make_photo_sfx.py` → `assets/audio/sfx/shutter.wav`, `Audio` key `&"shutter"` | Original procedural "click-clack", credited in `assets/CREDITS.md`. |
| Player | `entities/player/player.gd` | `photo_mode` flag: your own body is always drawn in photo mode (even from first person). |
| Sandbox | `scenes/sandbox.gd` (section at the end + Back) | Creates `PhotoMode`, connects the HUD button; Android Back leaves photo mode before anything else. |
| Input map | `project.godot`, `tools/setup_input_map.gd` | `photo` = P (added by hand to `project.godot`, same format as the tool writes). |

## Rulings (decisions made on the owner's behalf)

1. **Solo play pauses the world while photo mode is open; LAN never pauses** (`PhotoRules.pauses_world`).
   Solo: monsters wait, nothing can hurt you, and the photo is a freeze-frame (mid-jump shots, frozen
   particles). This is the same pause the pause menu uses, so its touch-release handling applies. LAN:
   the world belongs to everyone. *Cost if wrong:* kids who want a moving scene in solo (clouds, animals)
   get a still one; switching is one line.
2. **On LAN a hit drops you out of photo mode** (`PhotoRules.exits_on_hurt`: hearts going down; healing
   doesn't). You are not protected on LAN (photo mode must not be an invincibility trick), but you can
   react at once. *Cost if wrong:* a child on LAN loses a framed shot when a monster arrives.
3. **The camera is limited and never passes through blocks** (pan ≤ 6 blocks from the head, distance
   ≤ 12, both × size). Photo mode must not become a way to scout or peek into closed rooms, pyramids or
   secrets in Survivor. *Cost if wrong:* fewer wide "drone" shots; the numbers are constants.
4. **Filters are one screen-texture shader pass, not `Environment` adjustments**: the comic outline needs
   neighbouring pixels, and it leaves the world environment (Ambience, style, fog) untouched. The pass
   only runs in photo mode with a non-NORMAL filter, and is drawn for 2 frames on opening so the shader
   compiles then, not on the first filter tap (the Fx gotcha: a new shader stalls the emulator's GL
   renderer for 100+ ms). *Cost if wrong:* one full-screen copy + pass per frame while a filter is on.
5. **Frames are part of the photo; the buttons, hint and messages are not.** *Cost if wrong:* none known.
6. **Where photos go:** the phone's gallery album `Pictures/EasyCraft` (no storage permission requested:
   Android 10+ needs none for our own media; older phones fall back to the app's folder with a clear
   message); desktop `user://photos`. *Cost if wrong:* on Android 7–9 photos stay inside the app (not in
   the gallery) until a permission is added.
7. **Sharing uses the system share sheet only** (no upload of our own, nothing collected). For children
   this is the phone's own sheet; M4's parent settings should be able to hide SHARE (§5.14). *Cost if
   wrong:* a policy review may ask for the parent gate before SHARE.
8. **While open, photo mode takes every input event** (its buttons first): nothing is built, broken or
   selected behind it, and the mouse is released on desktop. On LAN the body can still be walked with
   WASD on desktop (polled input); phones have no joystick while the HUD is hidden. The block highlight
   and the mirror wall are hidden and the `BlockInteractor` is disabled while open. *Cost if wrong:* none
   for phones.
9. **A headless run draws nothing**: `PhotoMode.capture` returns a blank picture of the viewport's size
   there (`get_image()` returns null and `frame_post_draw` never fires headless), so tests check the
   saved file and its size, not its pixels. *Cost if wrong:* none in the game (only `DisplayServer` name
   "headless" takes that path).

## Tests (RED → GREEN)

Written first; RED run: every new script failed to parse on the missing classes (`PhotoOrbit`,
`PhotoGestures`, `PhotoFilters`, `PhotoFrames`, `PhotoFiles`, `PhotoRules`, `PhotoMode`), and the HUD
tests failed on the missing `photo_button`. One test expectation was wrong and fixed before GREEN: a
real two-finger pan changes the finger gap on each event, so the test now checks that the zoom factors
multiply to 1 over the gesture. Two store tests then failed only because GUT counts the engine's
"could not create directory" error as unexpected; they now expect it (`get_errors()` handled).

- `tests/unit/test_photo_orbit.gd` (14): orbit direction and pitch limits, zoom limits and broken
  factors, size scaling, pan direction and limit, camera behind the look point, walls, thin walls (no
  seeing through), never under the ground (several pitches/yaws), never inside a block in a corridor,
  pan stops before a wall, starts where the game camera is, first person steps back.
- `tests/unit/test_photo_gestures.gd` (8), `test_photo_filters.gd` (8, incl. every parameter is a
  uniform of the one canvas_item shader), `test_photo_frames.gd` (3), `test_photo_files.gd` (6: name,
  no overwrite, folders per platform, messages), `test_photo_rules.gd` (2).
- `tests/integration/test_photo_mode.gd` (19): HUD hidden and photo camera current; seamless start;
  close restores camera transform, current camera and HUD (including the HUD's own hidden parts); a
  hidden HUD stays hidden; solo pauses and unpauses, LAN never pauses, an already paused game stays
  paused; one shared material for every filter and NORMAL has no pass; prewarm on open; frames; a photo
  saved at the viewport's size (1280 × 720); two photos in one second give two files; buttons left
  out of the photo, frame kept; a LAN hit closes it; touch orbit and pinch zoom through the viewport;
  wheel zoom; Esc; the P action; the player's body shows from first person.
- `tests/integration/test_hud_photo_button.gd` (2): placement clear of every control, the username and
  the gold line; under the palette; emits `photo_requested`.
- `tests/integration/test_photo_store.gd` (3): fallback to the next folder, folder created, nowhere to
  write gives no path.

Full suite after the change: **88 scripts, 702 tests, 702 passing, `tests/run_tests.sh` exit 0**
(load average ~67 on the PC at the time).

## What the lead should check on the emulator (not verifiable headless)

1. The camera button sits under the username (and under the gold counter once M2 Task 7 is merged),
   left of WALK, and doesn't collide with the gold label's real size.
2. Photo mode opens: HUD gone, hint at the top, drag orbits, pinch zooms, two-finger drag pans; the
   camera stops at walls, never shows the inside of a wall, never goes under the ground or into caves'
   rock.
3. Each filter looks right in **Compatibility (emulator)**, and COMIC's outline is visible; no frame
   over 100 ms when opening photo mode or tapping the first filter (the prewarm).
4. Each frame draws correctly on 2400 × 1080 (wider than 16:9).
5. The shutter: flash + click; the toast says "Saved to your Gallery!"; the file appears in
   `/sdcard/Pictures/EasyCraft/` (`adb shell ls /sdcard/Pictures/EasyCraft`) and in the Photos app;
   pull it and check it has the filter and frame but no buttons, at the full screen size.
6. SHARE opens the Android share sheet with the picture. If it opens the gallery viewer instead, the
   JavaClassWrapper path failed (see logcat for `JavaClassWrapper` errors) and the fallback worked.
7. Android Back leaves photo mode (not the pause menu); X leaves it; the game camera, HUD and touch
   controls are exactly as before; in solo, monsters/animals froze during photo mode and move again.
8. LAN (two instances): nothing pauses; getting hit closes photo mode.

## If the share sheet does not work on the emulator: what M5 needs

A tiny Android v2 plugin (AAR, Kotlin, ~30 lines) exposing `share_image(path: String, title: String)`:
`FileProvider.getUriForFile(activity, "$packageName.fileprovider", File(path))` (Godot's provider already
covers the app's files dir), `Intent(ACTION_SEND).setType("image/png").putExtra(EXTRA_STREAM, uri)
.addFlags(FLAG_GRANT_READ_URI_PERMISSION)`, `startActivity(Intent.createChooser(...))` on the UI thread.
That needs the Gradle build (`gradle_build/use_gradle_build=true`, currently false in every preset) and
an `EditorExportPlugin` registering the AAR. The iOS equivalent is `UIActivityViewController` in an iOS
plugin (built on the Mac in M5). `PhotoShare.share` is the only place to change.
