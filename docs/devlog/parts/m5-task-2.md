# M5 Task 2: art and audio polish (the rest after #43 and the audio pass)

The plan's Task 2 (`docs/superpowers/plans/2026-09-24-m5-launch.md`), spec §15.2 ("The polish pass", written before the
build). The identity pass (owner #43, `owner-43-identity.md`) and the audio pass (`audio-pass.md`, owner #50's animal
chorus `owner-50-sounds.md`) came first. Built in a worktree from `lead-merge` (0.4.0, then `6ceb218`, `cbd134c` and `65530da`
merged in), without the editor, the emulator or godot-mcp. English only (owner #52): no translations.

![The menu with the title diorama (the buddy awake and waving, the dog), the Survivor hub's universe cards, Frostpeak's
scene behind "How brave are you?", the Candy Kingdom's loading card](m5-task-2/m5-task-2-menus.jpg)

*Drawn in a window by `tools/polish_shots.gd` (1600 × 720, the emulator's 20:9 canvas; it also draws 1334 × 750).*

## What was built

| Part | What | Where |
|---|---|---|
| **Universe pictures** | Every universe card (Survivor hub, Sandbox worlds, Monster Wave, the stone circle's panel) draws that universe's own little scene from its own block tiles and colours: Green Meadows' grass hill and tree, the desert's sandstone pyramid and cacti, Frostpeak's snow-brick igloo and pine, the Candy Kingdom's candy cane, gumdrop and lollipop by a chocolate river, the Dragon Realm's floating island with golden spires over the clouds at sunrise; the brand's orange buddy explores each. Tiles are cut from each block's own page (their size read from the page, for M5 Task 3's page changes). Locked: grey veil and "?"; Plus: veil and star, as before. The Dragon Realm's ladder colours were still the violet void (#43): now its sunrise. | `ui/universe/universe_art.gd` (new), `universe_card.gd` (`UniversePicture`), `world/universes/universe_registry.gd` (the dragon's `LADDER` colours) |
| **Menu backgrounds** | A universe's own screens (CONTINUE / NEW WORLD, "Start a new world?", how brave, which game) show its scene behind the buttons under a soft veil, filling the panel's inside, never asking for room. | `ui/universe/universe_backdrop.gd` (new), `ui/menus/menu.gd` (`_show(content, universe)`) |
| **The living title diorama** | A floating grass island rides in front of the menu's orbiting camera, under the wordmark: the brand's orange buddy (googly eyes, the wand with its star) sleeps, the star sparkles, its eyes pop open with a blink, it hops twice and waves, the dog hops and wags harder, it dozes off again (12 s loop); the island turns slowly to and fro. Shared meshes made once (the island by the voxel mesher with the terrain's own materials, the buddy and the dog with the animals' vertex-colour material, the sparkle with Fx's), its own small light (no shadows), no shadows cast, nothing made per frame (the sparkle is one emitter, restarted). **Reduce motion**: hidden, and the menu camera holds still. | `ui/menus/title_diorama.gd`, `core/rules/title_diorama_rules.gd` (new), `menu.gd` (`_place_camera`, the diorama on `_cam`) |
| **Loading hints** | While a world loads (until this device's player stands in it), the universe's scene fills the screen and a card shows one picture and one short line (16 hints, 5 s each, picked for the mode and universe, never the same twice in a row), read aloud with Read to me; it fades away (0.35 s) when the child stands in the world. | `core/rules/loading_hints.gd`, `ui/loading/loading_card.gd` (new), `scenes/sandbox.gd` (`_setup_local_player`: `LoadingCard.cover`) |
| **Monster moves** | Slimes and gummy bears crouch 0.3 s (synced `winding`, every screen sees it) before they pounce at a child they see within 3 blocks (out of touch; touching still hurts as before); every monster leans back when a hit lands (with its squash). | `core/rules/creature_moves.gd` (new), `entities/monsters/monster.gd` (the M5 Task 2 section; `_windup_time`, the crouch in `_process`) |
| **Boss moves** | Every boss leans back a little when a hit lands; the Golem and the Frost Giant breathe and sway their arms while they stand (the serpent, the cake and the dragon already swayed, wobbled or flapped); a boss that wins a fight cheers for 2 s with its own roar (arms up and pumping, hops, chest out; the serpent rears and rattles its tail; the cake twirls) before it sinks; the Sky Dragon roars with its head up as it flies off. | `stone_golem.gd` (shared: `win_sound`, `_took_hit_look`, `_recoil_lean`, `_win_roar`, `_sink` waits `CreatureMoves.WIN_TIME`), `sand_serpent.gd`, `frost_giant.gd`, `cake_monster.gd`, `sky_dragon.gd` |
| **Particle pass** | `Fx` keeps at most 32 effects alive (a new one ends the oldest), never makes a burst farther than 48 m from this device's camera (a stand-in comes back, never drawn, freed at the frame's end), and the big moments have one style with the shared material: `Fx.wake` (gold stars floating up; the buddy's wake), `Fx.portal` (rainbow-gold stars; portal travel, a boss's win portal), `Fx.level_up` (gold stars rising in a ring round the child, with the confetti), `Fx.confetti` (one emitter for every colour: a defeated monster's four emitters are one now, the boss win's too); a shared star mesh (20 triangles). Merged with M5 Task 1's `calm` and M5 Task 3's `particle_scale`. | `entities/fx/fx.gd`, `buddy.gd`, `portal_director.gd`, `progress_director.gd`, `monster_director.gd`, `boss_director.gd` |
| **Monster voice budget** | Monsters never speak on their own timers: one `MonsterChorus` per device (beside the animals'): at most one idle voice every 4.5–7.5 s, a kind rests 12 s, the nearest first, farther ones rarer and quieter, nothing beyond 20 blocks of the camera, a bat asleep under a ceiling is quiet. Hurt cries and growls on spotting a child play at once and make it wait 2 s. | `core/rules/monster_chorus_rules.gd`, `world/monster_chorus.gd` (new), `monster.gd` (`voice_tick` gone), `core/rules/voice_rules.gd` (`monster_wait` gone), `scenes/sandbox.gd` (3 lines) |
| **Loudness balance** | Everything a universe plays measured the #50 way (EBU R128 full band and after two 500 Hz high-passes, and the true peak) and evened out: a universe's day and night loops to Green Meadows', the pieces to the loops they take turns with, a universe's day and night ambience to the birds and crickets, monster idle voices to the goblins' grunts. | `tools/measure_loudness.py`, `core/rules/loudness.gd` (new), `autoloads/music.gd` (loop and piece gains), `ambience_sound_rules.gd` (`volume_db`), `voice_rules.gd` (`monster_gain_db`) |
| **Frostpeak's and the Candy Kingdom's own audio** | Frostpeak: a cold whistling wind by day, a quiet windy pine forest at night; Vivaldi's Winter (Largo) and Debussy's The Snow Is Dancing. Candy Kingdom: wind chimes by day, a brook (the chocolate river) at night; Chopin's Minute Waltz beside the Nutcracker's Waltz of the Flowers. A universe's own piece (`"own"`) plays only there. The candy descriptor's `classical` was a Dictionary the registry ignored: now a list of piece ids. | `tools/make_audio_pass_sfx.py universes`, `tools/make_classical_music.py`, `assets/audio/ambience/*.ogg`, `assets/music/classical/*.ogg`, `core/rules/music_pieces.gd`, `music_plan.gd`, `world/universes/frost.gd`, `candy.gd`, `assets/CREDITS.md` |

Not built: **the toon look** stays the costed proposal (`docs/design/identity-audit.md` §6); §15.2's "consistent icon set"
was not in this brief.

## Patterns (GodotPrompter `particles-vfx`, `animation-system`; `audio-system` as in #50)

| Chosen | Why | Rejected |
|---|---|---|
| CPUParticles3D one-shots with a live cap (ids, oldest ended) and a far skip | The emulator runs Compatibility; the one material stays compiled; callers keep using the returned node | GPUParticles (a second shader path, the first-use compile); a pool of emitters (callers keep references and tweak them; parents differ) |
| One emitter per multi-coloured burst (`color_initial_ramp`, hard steps, cached per colour list) | Fewer emitters, the same look | An emitter per colour (4 per defeat, 8 per boss win) |
| Code-driven poses from pure curves (`CreatureMoves`, `TitleDioramaRules`), transforms written only when they change | Code-built box meshes with no skeletons; poses already come from synced state (`winding`, `phase`, `hp`); testable as numbers | AnimationPlayer/AnimationTree per body (a node and clips per monster); a hit flash (per-instance materials, forbidden here: shader compiles, draw-call breaks) |
| The diorama as a child of the menu camera | It always sits under the wordmark, never inside a hill, whatever the world | A world-placed scene (a spot search, and it would slide off screen as the camera orbits) |
| One chooser per device for monster voices (like #50) | The rate stays flat however many monsters come | A longer per-monster timer (still grows with the crowd); Audio's same-sound cap (drops arbitrary voices) |
| Gains at play time from a measured table | No re-encoding of shipped files (no APK diff), one table, tested | Re-levelling files (new downloads, bigger diff; the headroom-bound cases would need a limiter anyway) |

## Tests (RED → GREEN)

| Test file | Tests | RED seen |
|---|---|---|
| `tests/integration/test_fx_pass.gd` | 11: the cap and the oldest ending, freed ones leave room, far bursts skipped (stand-in freed at the frame's end), no camera: made, every kind counted, wake / portal / level-up / confetti looks, the star mesh, a defeat's one confetti emitter | parse errors: no `Fx.wake`, no `Fx.confetti` |
| `tests/unit/test_creature_moves.gd` | 5: crouch, recoil, breath, cheer, the pounce's numbers | "CreatureMoves not declared" |
| `tests/integration/test_creature_moves_looks.gd` | 10: slime and gummy crouch then pounce, far: just hops, every screen shows the crouch, every monster leans back and straightens, every ground boss cheers with its roar then sinks, the Golem's arms go up, the Golem and Giant breathe, every boss leans back, the dragon roars as it leaves | "slime: it winds up" false, scale 1.0, rotation 0.0 ×6, "Nonexistent function win_sound" |
| `tests/unit/test_monster_chorus_rules.gd` | 6 | "MonsterChorusRules not declared", then `monster_wait` still in `monster.gd` |
| `tests/integration/test_monster_chorus.gd` | 4: 20 goblins calm (`MONSTER_CHORUS` line), near the camera only, a perched bat quiet, a cry never held back | parse error (no `MonsterChorus`) |
| `tests/integration/test_universe_art.gd` | 7 | "UniverseArt not declared" |
| `tests/integration/test_universe_screens.gd` | 3 | "Expected [null]…" ×4 (no backdrop) |
| `tests/unit/test_loading_hints.gd` | 5 | "LoadingHints not declared", then an 11-word hint |
| `tests/integration/test_loading_card.gd` | 6 | "Could not find type LoadingCard" |
| `tests/unit/test_title_diorama_rules.gd` | 5 | "TitleDioramaRules not declared" |
| `tests/integration/test_title_diorama.gd` | 6 (with `TITLE_DIORAMA step` timing) | "Could not find type TitleDiorama" |
| `tests/unit/test_loudness.gd` | 8 (prints `LOUDNESS` lines) | "Loudness not declared"; then ambience 3.8–4.2 dB off (a +3 dB cap: ambience may now rise to its file's level), and three shipped files already at -0.8/-0.9 dBTP (the rule became "no gain *lifts* a file past -1 dBTP") |
| `tests/unit/test_universe_audio.gd` | 3 | written with the descriptors (the loops' length rule caught an 18 s brook: rebuilt from a longer CC0 take) |
| `tests/integration/test_music_balance.gd` | 2 | written after `Music`'s gains (mutation: without the gain line the candy loop plays at 0 dB) |
| Changed to the new meaning | `test_monster_voices.gd` (the two `voice_tick` tests moved to the chorus), `test_voice_rules.gd` (the chorus's gap), `test_candy_universe.gd` (`classical` is a list of ids), `test_music_plan.gd` (own pieces aren't in a plan without favourites), `test_classical_music.gd` (a piece fades in to its evened-out level) | |

**Full suite:** see "Full suite" at the end of this file.

## Measurements

**Monster idle voices** (`test_a_night_of_twenty_goblins_is_calm`: 20 goblins 2–18 blocks round the camera, ten
simulated minutes): **4.7 grunts a minute**. Before: every goblin its own 6–14 s timer, simulated with the old rule
for the same crowd (5 seeds): **119.9 a minute**.

**Loudness** (`python3 tools/measure_loudness.py`; LUFS full band / through a phone, true peak) and the gains now
applied (`Loudness`):

| Music loop | Full | Phone | Peak | Gain |
|---|---|---|---|---|
| Green Meadows day / night (the references) | -16.1 / -17.0 | -24.5 / -24.9 | -3.3 / -2.5 | 0 |
| boss (every universe's, left as it is) | -15.4 | -19.3 | -4.2 | 0 |
| desert day / night | -17.7 / -18.2 | -24.4 / -23.4 | -0.9 / -1.0 | 0 / 0 (within 1 dB) |
| frost day | -21.8 | -25.9 | -1.5 | 0 (3.5 dB under, but only 0.5 dB of headroom) |
| frost night | -16.0 | -21.1 | -1.0 | **-2.4** |
| candy day | -14.9 | **-16.1** | -2.3 | **-4.8** (8.4 dB over Green Meadows through a phone) |
| candy night | -15.7 | -22.8 | -3.4 | **-1.7** |

Pieces against the day loop (the boss pieces against the boss loop): goldberg_aria +1.8, minute_waltz +1.2,
symphony_40 +1.3, winter_largo -1.9; the others within 1 dB or without headroom (Für Elise, Moonlight, Waltz of the
Flowers and The Snow Is Dancing peak at -0.7 to -1.3 dBTP: quiet piano stays a little quiet).

| Ambience (own volume + gain = plays at) | Full | Phone | Peak | Volume |
|---|---|---|---|---|
| birds (by day, the reference) | -22.0 | -22.0 | -5.0 | -8.0 |
| crickets (at night, the reference) | -22.0 | -22.7 | -10.5 | -10.0 |
| wind (the desert's and the Dragon Realm's days, peaks) | -25.2 | -30.4 | -8.9 | -9 + 6.8 = **-2.2** |
| snow_wind (Frostpeak by day) | -24.5 | -27.2 | -11.6 | -8 + 3.9 = -4.1 |
| snow_night (Frostpeak at night) | -25.1 | -27.3 | -10.6 | -10 + 3.8 = -6.2 |
| chimes (the Candy Kingdom by day) | -29.2 | -29.3 | -2.7 | -8 + 7.2 = -0.8 |
| brook (the Candy Kingdom at night) | -22.3 | -22.7 | -7.8 | -10.0 |
| waves, drips (the same everywhere: left as they were) | -25.3, -37.5 | -28.5, -38.7 | | -7, -6 |

Monster idle voices through a phone (the goblins' grunts -20.2 the reference): ice bat screech -10.8 → **-9.4 dB**,
candy sneaker jingle -15.5 → **-4.7 dB**, mummy +1.5, scorpion +1.5 (headroom), shadow bat +3.0, wisp +3.0 (capped); the
others within 1 dB or without headroom.

**Sizes (the APK):** the pieces `winter_largo.ogg` 1146 KB (153 s), `snow_dancing.ogg` 795 KB (143 s),
`minute_waltz.ogg` 686 KB (107 s); the loops `snow_wind.ogg` 283 KB, `snow_night.ogg` 279 KB, `chimes.ogg` 184 KB,
`brook.ogg` 264 KB: **+3.6 MB of audio** (the performance agent is shrinking the APK: these are Vorbis q1/q2 like the
rest; the pieces could go to q0 for ~0.6 MB). No image files: the universe pictures, the backdrops, the loading card
and the diorama are drawn in code or from the existing pages (the devlog picture is in a `.gdignore` folder).

**Cost:** the diorama's step (8 transform writes, a few float curves): **6.9 µs a frame** on this desktop
(`TITLE_DIORAMA step` in the suite log; a phone 3–5× that, ~35 µs); a minute of it makes no object
(`test_a_minute_of_it_makes_nothing_new`: fewer than 5, since a piece of music loading on its thread may add one). Its draws: 8 meshes (the island one surface
per page material, the buddy's four parts, the dog and its tail), one omni light without shadows, one 10-star emitter
once every 12 s. A universe card draws ~60 tile rects once (only when it redraws); a backdrop the same, tiled.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Universe pictures are drawn in code from each universe's own block tiles** (no painted image files: nothing added
   to the APK, and #43's look is the tiles' own). *Cost:* a painted picture per universe would need five image files.
2. **The backdrop shows behind every screen of one universe, Sandbox's too** (the brief named the Survivor panels;
   CONTINUE / NEW WORLD and "Start a new world?" are shared by both modes). *Cost:* one argument in `_show_mode`.
3. **The Dragon Realm's card colours are its sunrise** (the ladder still had #39's violet void). *Cost:* three colours.
4. **The diorama rides on the menu's camera** (a stage in front of it, above the view's middle), so it always sits
   under the wordmark and never in a hill; the world orbits behind it. On tall panels (the hub) the panel covers most
   of it. *Cost:* a world-placed diorama needs a spot search and a camera path.
5. **It has its own small warm light** (no shadows, 8 m reach: only the island): the world's sun turns round the
   camera during the orbit and lit the buddy from behind half the time (seen in the first window pictures).
   *Cost:* one omni light's pass over 8 small meshes on the Compatibility renderer; measure on the emulator.
6. **Reduce motion hides the diorama and also holds the menu camera still** (a slow orbit is camera motion).
   *Cost:* one line in `menu.gd`'s `_process`.
7. **No wake sound in the diorama** (the menu's music plays; a chime every 12 s would nag). *Cost:* one `Audio.play`.
8. **The loading card stays exactly until the child stands in the world** (no minimum time: a fast load only flashes
   it). *Cost:* a minimum would delay play.
9. **Loading hints are English only** (owner #52). Each line says something the game does (checked in its system).
10. **The jumpers' wind-up is a pounce**: only while chasing a child it sees within 3 blocks and out of touch; a touch
    hurts as before, and the pounce lands where the child is now (stepping aside dodges it). The tutorial's practice
    slime pounces too but never hurts. *Cost:* slimes reach a child ~0.3 s later; `CreatureMoves.POUNCE_*`.
11. **Hit reactions are a lean back** (monsters 0.35 rad, bosses 0.12) with the squash they had; no hit flash (it needs
    per-monster materials, which the brief rules out). *Cost:* the two constants.
12. **Boss idle moves**: the Golem and the Frost Giant breathe and sway when they stand; the serpent, the cake and the
    dragon already moved while idle, so they were left as they were.
13. **A boss that wins cheers for 2 s before it sinks** (the host holds the sink; every screen poses from the synced
    DOWN phase). The boss bar shows the loss meanwhile, and a new fight may start (a boss going down never counts as
    fighting). **The Sky Dragon roars as it flies off without waiting** (its flight is its exit;
    `test_a_lost_fight_flies_it_away_with_its_towers` unchanged). *Cost:* `CreatureMoves.WIN_TIME`.
14. **`Fx.MAX_LIVE` is 32, not 24** (the spec line was corrected): a boss win in the last universe with its fireworks
    is ~26 emitters in 1.2 s. The oldest ends early (the newest is usually the child's own action). **`Fx.FAR` 48 m.**
    *Cost:* two constants.
15. **Only the most frequent multi-colour bursts became one emitter** (a monster's defeat, a boss's win); bot friends'
    confetti, course finishes, piñatas and the Dance Orb still make one emitter per colour (they count against the
    cap). *Cost:* a line each with `Fx.confetti`.
16. **The portal burst plays at portal travel inside a world and at a boss's win portal**; not at universe travel
    (that world is about to go).
17. **Monster chorus: 4.5–7.5 s, a 12 s rest** (livelier than the animals' 6–10 s and 20 s: at night a voice says
    "something is near"). *Cost:* `MonsterChorusRules.GAP_*`, `KIND_REST`.
18. **Loudness references are Green Meadows' loops** (the level the owner has heard since M2), the boss loop, the sea
    and the caves stay as they were; the balance is the **mean of the full-band and the phone difference** (a bass-heavy
    loop is loud on headphones and quiet on a phone); **no gain lifts a file past -1 dBTP**, music and voices rise at most
    3 dB, ambience up to its file's level. So **Frostpeak's day loop stays ~3.5 dB under** (it peaks at -1.5 dBTP).
    *Cost:* re-level `frost_day.ogg` in `tools/make_frost_music.py` (+3 dB with a limiter) and re-measure.
19. **Pieces are evened out too** (MIX takes turns between loops and pieces): only 4 of 17 change (headroom).
20. **Frostpeak's pieces: Vivaldi's Winter (Largo; the Musopen Modena set, the same licence as Spring) and Debussy's
    The Snow Is Dancing** (a virtual-piano rendering, PD-self, cut from the suite at 569.6–712.7 s). **The Candy
    Kingdom's: Chopin's Minute Waltz** (Musopen, CC0, pianist not named) beside the Waltz of the Flowers. No public-domain
    Sugar Plum Fairy exists (checked again). The Skaters' Waltz had no clean public-domain recording. *Cost:* swap ids in
    the tool and `MusicPieces`.
21. **A universe's own piece plays only there** (`"own"`: only when the universe names it; never in the menu). *Cost:*
    drop the flag and they join every universe's day.
22. **Frostpeak's night has no owl** (an owl in a 40 s loop repeats noticeably); **the kingdom's night is a brook** (its
    rivers are chocolate). *Cost:* `AmbienceSoundRules.LOOPS` and the descriptors.
23. **freesound HQ previews** (as the audio pass): the tool checks each page still says CC0 before it downloads.

## For the lead

**Merge notes (shared files touched).**
- `entities/fx/fx.gd`: two lines in `burst` (`_too_far`, `_track`), `_track(p)` after `ripple`, `drips`, `spikes`,
  `coin_shower`, and the M5 Task 2 section at the end (merged with M5 Task 1's `calm` and Task 3's `particle_scale`).
- `entities/monsters/monster.gd`: `_voice_t`, `_voice_rng`, `voice_tick` removed; `_recoil`, `_crouch_t`; `_strike`
  (jumpers pounce), `_hop_step` (the crouch first), the `_process` early exit and look lines, and the M5 Task 2
  section at the end (after M3 Task 15's practice slime).
- Bosses: `stone_golem.gd` (two vars, `_sink`, `_enter_look`, `_pose`, the shared section before the Dance Orb), and in
  each of `sand_serpent.gd`, `frost_giant.gd`, `cake_monster.gd`, `sky_dragon.gd`: `win_sound()`, `_took_hit_look()`,
  a DOWN line in the enter-look, the DOWN pose, the recoil in the tilt.
- `scenes/sandbox.gd`: the `MonsterChorus` (3 lines after the animals' chorus), `LoadingCard.cover` (2 lines in
  `_setup_local_player`).
- `ui/menus/menu.gd`: `_diorama`, `_place_camera`, `_process`'s Reduce-motion return, `_show(content, universe)` and the
  four universe screens' `_show(v, universe)`.
- `autoloads/music.gd` (`_gains`, `_piece_db`, `use_tracks`), `core/rules/music_plan.gd` (two own-piece lines),
  `music_pieces.gd` (three pieces, `is_own`), `ambience_sound_rules.gd` (four loops, `volume_db`), `voice_rules.gd`
  (`monster_gain_db`; `monster_wait`, `MONSTER_MIN/MAX` removed).
- `world/universes/frost.gd`, `candy.gd`, `universe_registry.gd` (the dragon's ladder colours); `boss_director.gd`,
  `monster_director.gd`, `portal_director.gd`, `progress_director.gd`, `buddy.gd` (one line each).
- **When an audio file changes, re-measure it** (`tools/measure_loudness.py`) and copy its numbers into `Loudness`.

**Check on the emulator** (both styles where it matters):
1. The menu: the island with the buddy and the dog shows under the wordmark on 20:9 and 16:9, not cut by the screen's
   top; the buddy sleeps (line eyes), the star sparkles, it blinks awake, hops twice, waves; the dog hops and wags; it
   dozes off again; lit from the front all round the orbit; the frame budget holds in the menu (no spike every 12 s
   at the sparkle).
2. SETTINGS → Reduce motion on: the diorama is gone and the menu's view stands still; off: both come back.
3. SURVIVOR's hub (and the stone circle, Sandbox worlds, Monster Wave): five universe pictures, each its own; locked and
   Plus cards as before.
4. Frostpeak → how brave / which game / CONTINUE: Frostpeak's scene behind the buttons, the words readable.
5. Start or continue any world: the universe's scene and one hint card until the player stands; with Read to me on, the
   hint is read; a slow load shows a second hint after 5 s; the card fades and the tutorial's card (y 176) comes after.
6. A slime or gummy bear chasing you: it crouches for a moment, then jumps at you; step aside and it misses. Hit any
   monster: it leans back and squashes. A boss standing (Golem, Giant): it breathes. Lose a boss fight: it cheers with
   its roar for 2 s, then sinks (the dragon roars and flies off).
7. Break blocks, wake a buddy (gold stars), go through a portal (rainbow-gold stars), level up (a ring of gold stars
   rising with the confetti), defeat monsters (confetti).
8. A night with many goblins: a grunt every ~12 s, not a stream; hurt cries at once.
9. Listen (a phone speaker, the owner's check): the Candy Kingdom's day loop no longer louder than the Meadows';
   Frostpeak's wind and pine night, the kingdom's chimes and brook; Frostpeak's Winter / The Snow Is Dancing and the
   Minute Waltz by day in MIX; none of them in the menu or in Green Meadows.
10. The toon look: not built.

## Merging with M5 Tasks 1 and 3 (what changed on the way)

- `Fx`: M5 Task 1's `calm` (Reduce motion: half the pieces, slower, no spin) and Task 3's `particle_scale` (LOW: half)
  merged with the budget; the lead's seam fix (`256b3da`: `calm` scales the unscaled amount itself) came with the last
  merge. The diorama's sparkle is a pooled burst: `Fx.calm(sparkle, SPARKLES)` before each restart.
- `test_read_aloud_screens.gd` (M5 Task 1) reads a menu screen as the panel's first child: the universe backdrop is
  now an **internal** child of the panel (`INTERNAL_MODE_FRONT`: drawn first, outside the panel's layout, sized to the
  panel's content margins by `UniverseBackdrop.fit_inside`), so the screen's content stays child 0.

## Full suite

The first full run after the `cbd134c` merge: 646 scripts, 5953 tests, **5948 passing, 3 failing**: M5 Task 3's
`test_low_bursts_have_half_the_particles` (the T1/T3 `calm` seam, fixed on `lead-merge` by `256b3da` meanwhile),
`test_read_aloud_screens.gd`'s menu screens (the backdrop was the panel's first child: now internal) and
`test_a_minute_of_it_makes_nothing_new` (+1 object in a minute from a background load: the test now allows fewer
than one a loop). After merging `65530da` and the two fixes:
**646 scripts, 5954 tests, 5952 passing, 0 failing, 2 risky** (the existing "did not assert"), 1039 s, **exit 0**; no
`SCRIPT ERROR` or `Parse Error`. `MONSTER_CHORUS 20 goblins: 4.7 grunts a minute`, `TITLE_DIORAMA step: 7.2 us a frame`.
**After the last `lead-merge` merge (`4ad6efc`, the grown-up area and the online wallets): 648 scripts, 5972 tests,
5970 passing, 0 failing, 2 risky, 944 s, exit 0.**
