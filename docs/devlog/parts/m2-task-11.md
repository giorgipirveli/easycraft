# M2 Task 11: Music and feel

Plan Task 11, spec §12.10 (music and feel) and §5.15. The lead added a request midway (child-psychology
research, `docs/design/`): a **Reduce motion** setting (default OFF) that turns off screen shake and camera
bob and softens flashes, and nothing in Feel flashing more than 3 times a second. Built in an isolated
worktree from `2430164` (branch `m2-survive-the-night`); no editor, emulator or godot-mcp use.

## What was built

### Music (`autoloads/music.gd`, `core/rules/music_rules.gd`, `core/rules/music_mix.gd`, `assets/music/`)

| Track | Piece (all by The Cynic Project / cynicmusic, CC0) | Loop | File |
|---|---|---|---|
| `day.ogg` (and the menu) | "Happy Lullaby (song17)": bells and arpeggios | 16 bars at 100 bpm = 38.400 s | 370 KB, stereo 32 kHz, Vorbis q3 |
| `night.ogg` | "Crystal Cave (song18)": deep bass, stone and bell textures, arpeggios | 20 bars at 100 bpm = 48.000 s | 413 KB, stereo 32 kHz, Vorbis q3 |
| `boss.ogg` | "Battle Theme A": strings, horns and drums | 56 bars at 146 bpm = 92.055 s | 1040 KB, stereo 44.1 kHz, Vorbis q2 |

- **Sources and licences** (checked on each page on 2026-09-24; every page lists **CC0** as its only
  licence):
  - https://opengameart.org/content/happy-lullaby-song17 (`song17.mp3`)
  - https://opengameart.org/content/crystal-cave-song18 (`song18_0.mp3`)
  - https://opengameart.org/content/battle-theme-a (`battleThemeA.mp3`)

  All three are from the author's free game Pixelsphere. Credited in `assets/CREDITS.md`. The song17 and
  Battle Theme A pages ask users to get in touch so the author can keep track of who uses his music. That is a courtesy, not a
  licence condition; the owner may want to write to him before the store release.
- **Why these three:** song17 and song18 are siblings from one composer: same tempo (100.00 bpm), same bell
  and arpeggio sound. The dusk cross-fade therefore sounds like one piece darkening, not like a radio
  station switching. The night track is moody (deep bass, cave textures) rather than scary: a children's
  game. Battle Theme A is the same composer's "epic strings and horns" and gives the Golem fight its lift.
  Also CC0, looked at and not used: Dark Forest Theme and Town Theme RPG by the same author (spookier, and
  an intro plus an ending, not built to loop), and other composers' boss loops (Boss Battle (loop) by Pro
  Sensory, Basilisk Boss Battle), which would not match the day and night pair.
- **How the loops were made** (`tools/make_music.py`, reproducible, deterministic):
  1. Each source is a loop region followed by its reverb tail: the ends decay from about -18 to -50 dB over
     1–4 s.
  2. The tempo came from the autocorrelation of an onset (spectral-flux) envelope, refined at long lags:
     song17 and song18 are 100.00 bpm (peaks at 4.800, 9.600, 19.201, 28.80 s for 8–48 beats), and Battle
     Theme A is 146.00 bpm.
  3. The beat grid starts at 0 in song17 and song18 (the first notes fall on the 0.15 s sixteenth grid).
     In Battle Theme A the grid starts about 0.12 s in, and its final chord lands exactly 56 bars later
     (92.175 s). So each loop is cut at a whole number of bars from sample 0, just after the last note
     attack (song17 37.63 s → 38.4; song18 47.78 s → 48.0; Battle A 92.16 s → 92.055, the chord falling on
     the next loop's first downbeat).
  4. The tail after the cut is mixed back onto the start (its last 60 ms faded), so the reverb rings on
     over the repeat.
  5. The loudness is evened out to -18 dBFS RMS, with the peak kept at -1 dBFS or below.
  6. The audio is encoded as Ogg Vorbis with ffmpeg's libvorbis, and imported with `loop=true`.
  7. The decoded files are sample-exact: 1 228 800, 1 536 000 and 4 059 616 samples.
- **Seam check** (printed by the script):

  | Track | Sample step at the seam | Inside the piece (p99) | Spectral jump at the seam | Inside (median / p95) |
  |---|---|---|---|---|
  | day | 0.0017 | 0.0287 | 13.9 | 3.5 / 5.7 |
  | night | 0.0092 | 0.0246 | 3.7 | 3.3 / 5.7 |
  | boss | 0.0269 | 0.0868 | 10.4 | 9.5 / 13.6 |

  - The small sample steps mean no clicks.
  - Day's large spectral jump is its first bright bell downbeat. The last bar of the lullaby dies away
    quietly (-32 dB, no highs), then the tune starts again. That is how the piece is written (the page:
    "Easy for perfect loop"), not a cut in the middle of a note.
- **System**
  - A separate `Music` autoload, which adds the `Music` bus (sent to Master) at start.
  - One `AudioStreamPlayer` per track. `MusicMix` gives each track a gain 0..1. The wanted track rises
    and the others fall, at 1 / `MusicRules.CROSSFADE` (2.5 s) per second. So a change takes exactly
    2.5 s, and a change of mind halfway turns around from where it is.
  - The gain is heard through an equal-power curve (sin): halfway, both tracks are at -3 dB.
  - A silent track is stopped, so a phone decodes one Vorbis stream (two during a fade). A track that
    fades in starts from its beginning.
  - `process_mode` ALWAYS: the music keeps playing in the pause menu.
- **Which track** (`MusicRules.track_for(time_of_day, boss)`):
  - The boss theme during a boss fight.
  - The night track while `DayCycle.is_night` (sunset 0.85 → sunrise 0.15), the same test the night
    monster spawns use.
  - The day track otherwise.
- **Hooks**
  - `ui/menus/menu.gd` `_ready` → `Music.play_menu()` (the day track).
  - `scenes/sandbox.gd` `_add_sky` → `Music.follow_sky(sky)`. This covers solo, host and LAN client:
    Music reads `sky.time` every frame, and the clients' SkyCycle follows the host's clock.
  - A freed sky falls back to the menu track.
  - `play_menu` and `follow_sky` clear the boss flag.
- **Volume**
  - `settings.music_volume` sets the Music bus in dB (muted at 0), on top of `settings.volume` on Master.
  - Music listens to `Game.settings_applied`, so `game.gd` is unchanged.

### Settings (`core/save/profile_data.gd`, `ui/menus/settings_panel.gd`)

- New keys, saved and coerced like the others:
  - `music_volume`: 0.6, clamped to 0..1, bad types become the default.
  - `vibration`: true.
  - `reduce_motion`: false.
- **Panel**
  - The Music slider sits on the Volume row (two 250 px sliders).
  - Vibration and Reduce motion are CheckButtons next to Show FPS. Turning Vibration on gives a 60 ms buzz
    on Android.
  - The panel was already **725 px tall on the 720 px screen** (measured headless: title 61 + rows +
    7 × 18 gaps + 2 × 28 margins). The row gap is now 16 and no row was added, so it is 928 × 711
    (measured headless).
    `test_settings_fit_on_the_screen` guards it. There is no room for another row: new settings must
    join an existing row, or the panel must become scrollable.

### Feel (`autoloads/feel.gd`, `core/rules/feel_rules.gd`, `entities/player/camera_rig.gd`)

| API | Does |
|---|---|
| `Feel.shake(metres, seconds)` | Wobbles the camera this device looks through (`CameraRig.shake`), via the camera's `h_offset`/`v_offset`: the spring arm, aim and body are untouched. It eases out to exactly 0. A weaker shake never cuts a stronger one short. At most 0.35 m. |
| `Feel.vibrate(ms)` | `Input.vibrate_handheld` on Android only, capped at 600 ms. |
| `Feel.flash(alpha)` | A red tint at the screen's edges (a radial `GradientTexture2D` on a `TextureRect`, CanvasLayer 90, `MOUSE_FILTER_IGNORE`, hidden when clear: no new shader, no fill rate when idle) fading out in 0.3 s. |
| `Feel.slam(distance)` | The Stone Golem's slam (Task 10), on every peer, with this player's distance: full shake (0.16 m, 0.5 s) and a 120 ms buzz inside the 7-block shockwave; the shake fades out to nothing at 20 blocks. |
| `Feel.motion_allowed()` | False with Reduce motion on. **Anything else that moves the view (a camera bob, a mace's ground shake) must check it.** No camera bob exists in the game yet. |

- **Hurt**
  - `Session.player_hurt` for this device's peer: a 0.07 m shake × (hit / 3, from 0.6 to 1.6) for
    0.25 s, a 40 ms buzz and a flash of 0.3.
  - Knock-out (hp 0): 0.2 m for 0.6 s, a 250 ms buzz and a flash of 0.45.
  - Only hearts going **down** count. The same signal also brings heals, regeneration and respawns
    (`broadcast_health`) to LAN clients.
  - Feel remembers the last hearts per local `Player` node. A new world is a new node, whose hearts start
    full.
- **Limits**
  - Shake needs Vibration ON (as the task said) and Reduce motion OFF (the lead).
  - Reduce motion flashes at 35 % strength over 0.5 s.
  - Flashes start at least 0.35 s apart, so there are at most 3 in any one-second window, however fast
    the hits come (tested with a hit every frame).
  - The shake wobble changes no brightness, so it is not a flash.
- **Android**: `permissions/vibrate=true` in the `Android` and `Android Phone` presets (Godot needs it for
  `vibrate_handheld`).

### Coin sound

- `Audio.play(&"coin", pos)`: `assets/audio/sfx/coin.wav` (22 KB), two bright bell notes (B5 then E6),
  generated by `tools/make_feel_sfx.py` (original work).
- Tasks 4, 9 and 10 play it on coin pickups.

## Tests (RED → GREEN)

| File | Tests | RED seen | GREEN |
|---|---|---|---|
| `tests/unit/test_profile_data.gd` (+2) | music volume default, saved, bad type, clamped; vibration and reduce motion defaults, saved, bad types | "Invalid access to key 'music_volume' / 'vibration'" | ✓ |
| `tests/unit/test_music_rules.gd` (14) | day/night/boss per time of day (sunset/sunrise edges), menu = day, crossfade 2–3 s, fade in from silence, exact swap time, equal power, dB, turn-around mid fade, same track, silence, bad deltas, unknown tracks | "Identifier MusicRules not declared" | ✓ |
| `tests/unit/test_feel_rules.gd` (14) | shake decays to 0 and never grows, caps, offsets within the amplitude, shake needs Vibration on and Reduce motion off, vibration off by the setting and off desktop, hit / knock-out / heal, ≤ 3 flashes in any second, softened flashes, flash fade, slam by distance | "Could not find script for class FeelRules" (file moved away), then "slam_feel not found" | ✓ |
| `tests/integration/test_music.gd` (12) | small looping OGGs (loop, > 30 s, ≤ 1.5 MB), the Music bus, the volume setting (and mute at 0), silent until asked, the menu fades in the day track, the sky clock cross-fades at sunset and back at sunrise (−3 dB halfway, silent tracks stopped), boss and back, restart from the beginning, leaving the world, a freed sky, pause, the real main menu | "Identifier Music not declared" | ✓ |
| `tests/integration/test_feel.gd` (14) | rig shake wobbles then offsets back to 0, a small shake keeps a big one, `Feel.shake` moves the current camera, Vibration off / Reduce motion off → no shake, local hurt shakes and flashes, knock-out bigger, other players not felt, heals and respawns not felt, ≤ 3 flashes a second from hits every frame, flash hides its overlay, Reduce motion softer flash, overlay ignores touches, slam by distance | "Identifier Feel not declared" | ✓ |
| `tests/integration/test_settings_panel.gd` (3) | fits 1280 × 720 (it was 725 px), the Music slider and both toggles show the settings (the panel's changes save the shared profile, so the tests only read) | "725 expected <= 720", missing controls | ✓ |
| `tests/unit/test_project_settings.gd` (+2) | VIBRATE permission in both game presets; Music and Feel autoloads after Profile, Game, Session | failed as expected | ✓ |
| `tests/unit/test_feel_assets.gd` (+1) | `Audio.SOUNDS` has `coin` (and every sound file loads, existing test) | — (written with the change) | ✓ |

Full suite: 637 → **699 passing, 0 failing**, `tests/run_tests.sh` exit 0.

## Rulings (decision — why — cost if wrong)

1. **A new `Music` autoload, not more code in `Audio`.** Many M2 tasks add lines to `Audio.SOUNDS`; music
   in its own file keeps merges apart, and `Music.play_boss(on)` is the name the plan gives Task 10. Cost
   if wrong: move ~100 lines into `audio.gd`.
2. **`Feel` is an autoload, not static helpers.** It must listen to `Session.player_hurt` without edits
   to the sandbox and must own the flash overlay. Cost if wrong: small.
3. **Night music from sunset to sunrise (`DayCycle.is_night`), not from the start of dusk.** Same moment
   night monsters may spawn: the music tells the child. A 2.5 s cross-fade in a 2-minute dusk. Cost if
   wrong: one line in `MusicRules.track_for`.
4. **The menu plays the day track** (the task allowed it): no extra download, and a daytime world
   continues the same music seamlessly. Cost if wrong: one more file and a `MENU` constant.
5. **Vibration turns off the shake as well as the buzz** (the task: "both respecting a setting
   Vibration"), and **Reduce motion turns off the shake** (the lead). So the shake needs both. Cost if
   wrong: one line in `FeelRules.can_shake`.
6. **A red edge flash on hurt was added** as part of Feel (spec §5.15 "feedback"), with the lead's limits:
   ≤ 3 a second, softer with Reduce motion. Cost if wrong: remove the `flash` call in `_on_player_hurt`.
7. **Hurt means hearts went down**, tracked per local Player node, not "the hit has a position". Heals
   and respawns arrive through the same signal on LAN clients. Cost if wrong: a missed shake at worst.
8. **A track fading in restarts from its beginning; silent tracks stop.** Musical starts, and a phone
   decodes one stream (two during a fade). Cost if wrong: switch to `stream_paused` to resume.
9. **Music volume is on top of the overall volume** (Music bus under Master). Cost if wrong: route the
   Music bus differently.
10. **The settings panel's row gap is 16 (was 18) and no row was added**, because it was already 5 px
    taller than the screen. Cost if wrong: a scrollable panel.
11. **Vibration only on Android** (the task), iOS later on the Mac. Cost if wrong: `OS.has_feature("mobile")`.
12. **Loops are baked into the files** (tail mixed onto the start at a bar line), with no `loop_offset`
    or bpm/beat-count import settings, so Godot just loops the whole file. Cost if wrong: re-run the tool
    with other bar counts.
13. **Stereo Vorbis, 1.8 MB for all three** (limit 1.5 MB each). Cost if wrong: mono or q1 halves it.

## What to check on the emulator (lead)

1. Menu: the lullaby fades in over about 2.5 s. SETTINGS shows Volume + Music on one row and Show FPS /
   Vibration / Reduce motion on another. The whole panel is on screen in the menu and the pause menu.
2. Music slider at 0: music silent, effects still audible. Volume at 0: everything silent.
3. In a world, `/time sunset` (or wait): the night track cross-fades in about 2.5 s; `/time sunrise` back.
   Listen for the loop seams (day every 38.4 s, night every 48 s): no click, no beat hiccup.
4. Pause menu: the music keeps playing.
5. Survivor, hurt by a monster: a small shake, a short buzz (Android emulator: none; a real phone buzzes)
   and a red edge flash. A knock-out shakes more. Healing is not felt.
6. Reduce motion ON: no shake, a fainter flash. Vibration OFF: no shake and no buzz.
7. Task 10 merged: `Music.play_boss(true)` → Battle Theme A within 2.5 s; `Feel.slam(d)` shakes near the
   Golem.
8. Autopilot: the frame budget holds. Music adds one Vorbis decode (two during a fade); the flash overlay
   is hidden when idle.

## Merge notes

- Shared files touched, each in a small block:
  - `project.godot`: two autoload lines after `Audio`.
  - `export_presets.cfg`: `permissions/vibrate` in presets 0 and 2.
  - `autoloads/audio.gd`: one `coin` entry at the end of `SOUNDS`.
  - `core/save/profile_data.gd`: `DEFAULT_SETTINGS` and one clamp line.
  - `entities/player/camera_rig.gd`: shake vars and methods, and one line at the top of `_process`.
  - `ui/menus/settings_panel.gd`: the volume row, the toggles row and `ROW_GAP`.
  - `ui/menus/menu.gd` and `scenes/sandbox.gd`: one line each.
  - `tests/unit/test_project_settings.gd` and `test_profile_data.gd`: tests appended.
- Other tasks:
  - **Task 10** calls `Music.play_boss(true/false)` on every peer and `Feel.slam(distance)` on the slam.
  - **Tasks 4, 9, 10** use `Audio.play(&"coin", pos)`.
  - **Task 2** should not add its own hurt shake or buzz; its knock-out fade can sit under Feel's flash
    (layer 90).
  - Anything that moves the camera checks `Feel.motion_allowed()`.
- `tests/integration/test_main_menu_modes.gd.uid` and `test_survivor_session.gd.uid` (Task 1's files) were
  generated by the import here and left uncommitted, to avoid a clash with the lead's own.
