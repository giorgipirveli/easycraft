# The audio pass: sounds, real animal voices, ambience and classical music

Owner feedback **#27** ("also consider to add sounds, effect sounds, musics and other sounds"), **#31** ("musics
i like, please also add some clasical musics like bethhoven, mozart and etc.") and, relayed by the lead at 20:42,
"animals should have sounds, like real ones". This is M5 Task 2's audio parts, pulled forward. Built in a
worktree from `m2-survive-the-night` (merged in again at 20:19 for M3 Task 12's `Progress`); no editor, emulator
or godot-mcp use. Spec §12.10 (the audio pass paragraph), M5 plan Task 2 (the note), credits in
`assets/CREDITS.md`.

## Patterns (the `godot-prompter:audio-system` and `godot-optimization` skills)

| Chosen | Why | Rejected |
|---|---|---|
| Fixed pools in the `Audio` autoload (6 flat, 12 positional players), a free player first, else the oldest (round robin) | The skill's SFX pool: no node is ever made per sound; 500 sounds add none (`test_five_hundred_sounds_never_add_a_player`) | An `AudioStreamPlayer3D` per animal or monster (hundreds of nodes, instancing churn); one player with `max_polyphony` (every copy at the same place) |
| Buses Master → `Music`, Master → `Effects` (new), the settings' sliders on them | The skill's bus layout; the SOUND EFFECTS slider is one bus volume, no per-player math | A separate `UI` bus: one more slider for children to understand |
| Music: our own `MusicMix` cross-fade (from M2 Task 11) driven by a pure `MusicPlan` | Pieces are chosen by game state (style, mood, universe, what was heard) and must be testable headless with exact timings | `AudioStreamPlaylist` (no moods), `AudioStreamInteractive` (every piece in one resource: 14 MB in memory, transitions by clip, not by the day/night/boss state) |
| Pieces loaded on the loader thread (`ResourceLoader.load_threaded_request`), two piece players, a faded-out piece drops its stream | A 1 MB Vorbis file takes 4–20 ms to open on this PC (`tools/measure_audio.gd`, load 36), 3–5× more on a phone: never on the main thread; at most two pieces in memory | Preloading all pieces (14 MB RAM), `load()` when a piece starts (a 20–60 ms hitch on a phone) |
| Silent players stopped (music tracks, pieces, ambience) | Nothing decodes that nobody hears (one music stream, one ambience loop; two while fading) | Players left playing at −80 dB |
| A cap on the same sound (3 in 80 ms), a flat sound once a frame, positional sounds beyond 40 m of the camera skipped | Ten slimes squishing at once are one squish; far sounds would only take pool players | Per-emitter timers |
| Every `BaseButton` gets its click from `SceneTree.node_added` | "Sound for every button" without touching every panel; toggles click softer (`UiSoundRules`) | Editing every panel's buttons (dozens of files, merge conflicts) |

## What was added

### Classical music (owner #31)

| Piece | File (`assets/music/classical/`) | Recording | Licence (on the Commons page) | Moods |
|---|---|---|---|---|
| Beethoven — Für Elise | `fur_elise.ogg` 882 KB, 135.7 s, mono | Gaodifan (V Gao) | PD-self + CC0 | menu, day |
| Beethoven — Ode to Joy | `ode_to_joy.ogg` 1009 KB, 131.4 s | US Air Force Band of the Rockies | PD-USGov-Military-Air Force | day |
| Beethoven — Moonlight Sonata (1st mvt) | `moonlight.ogg` 900 KB, 140.4 s, mono | Paul Pitman for Musopen | PD-author | night, underground |
| Mozart — Eine kleine Nachtmusik (1st mvt) | `nachtmusik.ogg` 798 KB, 116.5 s | **our own rendering** of the public-domain Mutopia score #900 | score PD; rendering original | day |
| Mozart — The Marriage of Figaro: Overture | `figaro.ogg` 1224 KB, 167.0 s | Musopen Symphony | PD-author | day |
| Mozart — Symphony No. 40 (1st mvt) | `symphony_40.ogg` 856 KB, 117.6 s | Musopen Symphony | PD-author | boss |
| Bach — Air on the G String | `air.ogg` 1245 KB, 167.7 s | Air Force Strings | PD-USGov-Military-Air Force | menu, night |
| Bach — Goldberg Variations: Aria | `goldberg_aria.ogg` 916 KB, 140.9 s, mono | Shelley Katz for Musopen | Cc-zero | menu, night, underground |
| Grieg — Morning Mood | `morning_mood.ogg` 1157 KB, 158.1 s | Musopen Symphony (Czech National SO) | PD-author | morning (the sunrise) |
| Grieg — In the Hall of the Mountain King | `mountain_king.ogg` 1181 KB, 153.5 s (whole) | Musopen Symphony | PD-author | boss |
| Tchaikovsky — Waltz of the Flowers | `waltz_flowers.ogg` 1221 KB, 162.8 s | US Air Force Band (arr. L. Odom) | PD-USGov-Military-Air Force | menu, day |
| Vivaldi — Spring (1st mvt) | `spring.ogg` 1027 KB, 137.6 s | The Modena Chamber Orchestra (Musopen) | PDMark-owner | morning, day |
| Satie — Gymnopédie No. 1 | `gymnopedie.ogg` 1122 KB, 181.4 s (whole), mono | Robin Alciatore (Musopen) | PD-author | menu, night, underground |
| Rimsky-Korsakov — Flight of the Bumblebee | `bumblebee.ogg` 589 KB, 81.1 s (whole) | Strolling Strings, US Air Force Band | PD-USGov-Military-Air Force | boss |

- 14 pieces, **13.8 MB** together (the largest 1.25 MB; limit 2.5 MB each). Vorbis at 32 kHz: q1 stereo for
  orchestras (~60 kb/s), q2 mono for solo piano (~52 kb/s).
- `tools/make_classical_music.py`: each excerpt ends at the quietest 0.4 s in the last third of its span (a breath
  between phrases; −25 to −55 dB) with a 3 s fade, levelled to −19 dBFS RMS over the louder half of the piece.
- **Not found as a public-domain recording:** Dance of the Sugar Plum Fairy (only a 5 s celesta excerpt on
  Commons). The Candy Kingdom gets the Nutcracker's Waltz of the Flowers (the Land of Sweets) instead; the Candy
  Kingdom's descriptor should say `var classical := [&"waltz_flowers"]`.
- CC BY / CC BY-SA recordings seen and not used are listed in `assets/CREDITS.md`.

**The MUSIC setting** (`MusicPlan`, `settings.music_style`):

| Style | Menu | Morning (sunrise → 0.3) | Day | Night | Caves | Boss |
|---|---|---|---|---|---|---|
| GAME MUSIC | day loop | day loop | day loop | night loop | night loop (Crystal Cave) | boss loop |
| CLASSICAL | gentle pieces | Morning Mood, Spring | day pieces | night pieces | calm pieces | Mountain King, Symphony 40, Bumblebee (no rest) |
| **MIX** (default) | gentle pieces | Morning Mood, then the day loop | day loop 150 s ↔ a day piece | night loop | Crystal Cave loop | boss loop |

- A piece plays once; the next is the least heard that fits, never the one just heard; the universe's
  favourites first among equals. CLASSICAL rests 2 s between two pieces (not in a boss fight).
- A mood change keeps a piece that fits the new mood (Für Elise goes on from the menu into a daytime world).
- A starting piece shows **"Now playing: Mozart — Eine kleine Nachtmusik"** for 4 s (+0.5 s fade) in a small
  dark pill at the bottom centre, just above the hotbar (CanvasLayer 80, never takes a tap, hidden when idle).
  The **Song names** toggle hides it.

### Effects (owner #27) and the animals' real voices (owner 20:42)

| Sound | Files (`assets/audio/sfx/`) | Source | Licence |
|---|---|---|---|
| Dog: bark ×3, happy whine ×2, yelp ×2 | `dog_*.ogg`, `dog_happy_*.ogg`, `dog_hurt_*.ogg` | freesound.org: kwahmah_02, JovianSounds, exe2be, AustinXYZ, esperri, unfa | CC0 |
| Cat: meow ×3, purr ×2, hiss | `cat_*.ogg`, `cat_purr_*.ogg`, `cat_hurt_1.ogg` | freesound.org: tuberatanka, skymary, TRNGLE, Trautwein, Reitanna | CC0 |
| Pig: oink/grunt ×3, squeal | `pig_*.ogg`, `pig_hurt_1.ogg` | freesound.org: qubodup | CC0 |
| Cow: moo ×3, distressed moo | `cow_*.ogg`, `cow_hurt_1.ogg` | freesound.org: Zozzy, Bird_man, JosephSardin, gibarroule | CC0 |
| Sheep: baa ×3, short bleat | `sheep_*.ogg`, `sheep_hurt_1.ogg` | freesound.org: esperar, michaelperfect | CC0 |
| Chicken: cluck ×3, alarm call | `chicken_*.ogg`, `chicken_hurt_1.ogg` | freesound.org: Breviceps, Rudmer_Rotteveel | CC0 |
| Rabbit: squeak ×3, thump, high squeak | `rabbit_*.ogg`, `rabbit_hurt_*.ogg` | freesound.org: kessir, policemouse67 | CC0 |
| Fish: splash ×2 (with the old blub) | `fish_splash_*.ogg` | freesound.org: dslrguide, paulprit | CC0 |
| Goblin grunts ×3, hurt cries (goblin, slime, mummy, scorpion), scorpion clicks | `goblin_grunt_*.ogg`, `*_hurt.ogg`, `scorpion_click.ogg` | synthesised (vowel formants, noise clicks) | original |
| Footsteps: dirt, stone, wood, snow, cloth, sand, leaves, glass | `step_<ground>_*.ogg` | Kenney Impact Sounds / RPG Audio (sand, leaves: derived) | CC0 |
| Toggle click, hotbar tick, pickup pop, gold clink | `ui_toggle.ogg`, `ui_tick.ogg`, `pickup_pop.ogg`, `gold_clink.ogg` | Kenney Interface Sounds, RPG Audio | CC0 |
| Level-up, goal, badge jingles | `jingle_level.ogg`, `jingle_goal.ogg`, `jingle_badge.ogg` | Kenney Music Jingles | CC0 |
| Wave-start horn | `wave_horn.ogg` | synthesised (two brass-like notes) | original |

Every freesound page was read (the page's licence link is `creativecommons.org/publicdomain/zero/1.0`); the tool
asserts it again before each download. The per-file table with links is in `assets/CREDITS.md`.

- **Animals:** a call now and then (8–20 s) while a player is within **20 blocks**, now on every peer (it was the
  host's only); a hurt voice when pushed or hit (`Animal.knockback`); a happy voice when petted or fed (`cheer`:
  a purr, a happy whine, the others their call); every animal its own pitch, 1 ± 0.12 from its id, divided by the
  square root of its size (`VoiceRules.voice_pitch`; ready for baby animals). The old synthesised bark, meow,
  oink, moo, baa, cluck and squeak files are gone (`make_animal_sounds.py --all` still makes them).
- **Monsters:** an idle voice every 6–14 s near a player (a goblin grunts, a slime squishes, a mummy moans, a
  scorpion clicks), on every peer; a cry when a hit lands (seen through the synced hearts, so every peer).
  The growl on spotting you and the boss roars were there already.
- **Footsteps by block** (`FootstepRules`): grass (the old steps), dirt, stone (also brick, ores, sandstone,
  smart blocks), sand, wood, leaves (and cactus), glass (and crystal, lamps), cloth (the coloured blocks, the
  bed), snow (Frostpeak's page 80–95), wading when the feet are wet. Splashes and swim strokes were there
  (M2 Task 14).
- **Buttons:** every `BaseButton` clicks, toggles and check buttons softer; HUD touch buttons click except
  JUMP/UP, ATTACK, CROUCH/DOWN and UNDO (their own sounds, pressed all the time); hotbar slots tick.
  `UiKit.big_button` and the hotbar no longer connect their own click.
- **Pickups and gold:** blocks coming into this game's bag pop (Survivor gathering; host and solo); gold going
  up clinks (every gain).
- **Jingles and horn:** Progress's level-up, goal done and new badge play their jingles on this game (the
  level-up's ding is replaced); a wave starts with a horn at the Totem (was a ding).

### Ambience (owner #27)

| Loop | File (`assets/audio/ambience/`) | Source | Licence |
|---|---|---|---|
| birds (day) | `birds.ogg` 40 s, 280 KB | nick121087 — Morning Birds (freesound 342462) | CC0 |
| crickets (night) | `crickets.ogg` 36 s, 263 KB | hdfreema — Night Crickets Back Porch (333221) | CC0 |
| waves (by the sea) | `waves.ogg` 48 s, 338 KB | Noted451 — Ocean Waves (531015) | CC0 |
| drips (caves) | `drips.ogg` 40 s, 268 KB | Sclolex — Water Dripping in Cave (177958) | CC0 |
| wind (peaks, flying high, the desert by day) | `wind.ogg` 36 s, 252 KB | synthesised | original |

- Seamless mono loops (the 4–6 s after the cut faded equal-power over the start), `loop=true`.
- `AmbienceSoundRules.choose`: quiet under water and in a sandstorm (it has its own wind); caves drip (underground
  ≥ 0.5); 36+ blocks above the sea is windy; ≥ 35 % open sea in a 14-block ring (water at the sea level over a
  floor 4+ blocks down, so rivers don't count) washes; else the universe's own loops (`ambience` in its
  descriptor: the desert has wind by day, crickets at night), else birds by day and crickets at night.
- `AmbienceSounds` (a child of `Ambience`): two players on the Effects bus, 3 s cross-fades, a loop starts at a
  random place, a silent player stops; the sea is looked for once a second (8 `get_block` calls). It also gives
  Music the cave mood (on at 0.6 underground, off below 0.3).

### Settings

| Key | Default | Parsed | Where |
|---|---|---|---|
| `sfx_volume` | 0.8 | number, clamped 0..1 | SETTINGS: the **Effects** slider on the Volume row |
| `music_style` | `"mix"` | one of game / classical / mix, else mix | SETTINGS: the **Music** button on the Jumps row (GAME MUSIC → CLASSICAL → MIX) |
| `song_names` | true | bool, else true | SETTINGS: the **Song names** toggle on the toggles row |

The panel is **1166 × 711** on the 1280 × 720 screen (`test_settings_fit_on_the_screen` prints it); no new row.

## Tests (RED → GREEN)

| File | Tests | RED seen | GREEN |
|---|---|---|---|
| `tests/unit/test_voice_rules.gd` (10) | every animal has a call, hurt and happy voice Audio knows; 2–3 recorded takes (ogg, not the old wav); idle calls within 20 blocks, 8–20 s apart; each animal its own pitch, the same every time, spread out, higher when small; every monster kind has idle and hurt voices | "Audio knows dog_hurt" ×9, "dog: 1 takes", "…animal_bark.wav is a recording (ogg)"; then "animals sound different" (a weak hash, fixed by mixing) | ✓ |
| `tests/integration/test_animal_voices.gd` (5) | petted → happy voice in its own pitch; pushed → hurt; calls now and then at 19 blocks, none at 21; two dogs sound different | parse error: no `Audio.played` | ✓ |
| `tests/integration/test_monster_voices.gd` (3) | a hit monster cries out (all four kinds); goblins grunt near a player; far monsters are quiet | mutation: with both `Audio.play` lines removed, 2 of 3 fail | ✓ |
| `tests/unit/test_footstep_rules.gd` (5) | each ground its step; wet feet wade; Frostpeak's page is snow; fallbacks; every placeable block has a step with 2+ takes | written with the rules (class missing) | ✓ |
| `tests/integration/test_player_footsteps.gd` (2) | a real Player: the block under the feet picks the step; walking on planks sounds like wood | "Nonexistent function step_sound", "[step] != [step_wood]" | ✓ |
| `tests/unit/test_ui_sound_rules.gd` (8) | buttons click, toggles softer, own sound or silence; JUMP/ATTACK/… quiet; menu-like touch buttons click, switches softer, hotbar ticks; every HUD symbol decided | written with the rules | ✓ |
| `tests/integration/test_audio_pool.gd` (14) | **500 sounds add no player**; ≤ pool size playing; the same sound capped at 3; far sounds skipped; the Effects bus under Master; the SOUND EFFECTS volume (0 mutes); every button clicks, toggles softer; a moved button clicks once; meta silence; HUD touch buttons (pause clicks, JUMP quiet, slots tick); gold clinks up, not down, and the first coin after the game starts clinks too; the bag pops on a gain, not on a new bag; a kit button clicks once, a kit toggle only softly; a button with its own click is heard once | mutation (no burst/far checks, no hooks): 6 fail; the last two: 2 fail before the frame dedupe; the first coin: fails with the baseline at −1 | ✓ |
| `tests/integration/test_feedback_jingles.gd` (4) | level-up, goal, badge jingles; the wave horn | "[] != jingle_level", "ding != horn" | ✓ |
| `tests/unit/test_music_plan.gd` (18) | moods from the clock/boss/caves; styles (unknown → mix); GAME loops; silence; CLASSICAL only fitting pieces; **no piece twice in a row** (5 moods × 5 seeds, an hour each); every fitting piece before a repeat; the 2 s rest; boss never rests; MIX takes turns by day; MIX keeps night/cave/boss loops; sunset → night loop; **sunrise → Morning Mood**; the menu's gentle piece; a fitting piece keeps playing; favourites first; a style change is immediate; bad steps | written with the plan; mutation (no "not the last one", no sunrise piece, no MIX turn): 4 fail | ✓ |
| `tests/unit/test_music_pieces.gd` (5) | ≥ 8 pieces by the seven composers; title, file, length, moods; every mood has pieces; labels; the boss pieces | written with the catalogue | ✓ |
| `tests/integration/test_classical_music.gd` (12) | every piece a small non-looping ogg as long as the catalogue says, ≤ 20 MB together; the menu's piece plays on the Music bus and fades in; MIX menu; 25 minutes of pieces on two players only; "Now playing" once and short; Song names off; GAME shows nothing; the setting changes the music; MIX sunrise; caves; favourites; the menu forgets them | written with Music's changes | ✓ |
| `tests/integration/test_music.gd` (12, changed) | M2 Task 11's tests now set the GAME style (their behaviour is unchanged) | — | ✓ |
| `tests/unit/test_ambience_sound_rules.gd` (8) | birds/crickets, caves, sea, peaks, quiet under water and in a storm, a universe's own, the loops loop, the desert's | written with the rules | ✓ |
| `tests/integration/test_ambience_sounds.gd` (6) | birds fade in on the Effects bus; nightfall cross-fades and stops the birds; never more than two loops; under water fades away; caves drip and tell Music (with hysteresis); leaving the world stops everything | written with the node | ✓ |
| `tests/unit/test_profile_data.gd` (+4) | sfx_volume, music_style, song_names defaults, round trips, bad values; **a profile from before the audio pass** keeps its settings and gets the new ones | "Invalid access to key 'sfx_volume'" | ✓ |
| `tests/integration/test_settings_panel.gd` (+4) | the Effects slider, the Music button's word for each style, the style steps, the Song names toggle (and it still fits) | "Cannot find member MUSIC_STYLE_WORDS" | ✓ |
| `tests/unit/test_audio_credits.gd` (3) | **every audio file under `assets/` has a credits line**; the matcher; the sources are named | 71 files not in CREDITS.md | ✓ |
| `tests/integration/test_universe_menu.gd` (changed) | its `pressed.get_connections().back()` became Audio's click: it now skips Audio's connection | "[Button] != [survivor, true, cozy, 2]" | ✓ |

Full suite: first commit (animal voices) **3108 / 3108**; second commit (music, ambience, footsteps, buttons) **3197 / 3197**; third (the first-coin clink, these notes) **3198 / 3198**.

## APK size (release "Android Phone", arm64, exported headless)

| Build | APK | Uncompressed |
|---|---|---|
| Before (`ac72611`, the base with M3 Tasks 7 and 12) | **89 784 294 B (85.6 MB)** | 141.5 MB, 1278 files |
| After (`be2aca8`, the audio pass) | **106 441 591 B (101.5 MB)** | 158.9 MB, 1494 files |
| **Growth** | **+16 657 297 B (+15.9 MB)**, budget ~30 MB | +17.4 MB, +216 files |

- Where it goes: the classical pieces 13.8 MB, the ambience loops 1.4 MB, the effects folder +0.59 MB (2.05 →
  2.64 MB: ~0.75 MB of new sounds, the seven old synthesised animal wavs gone). The APK is still under M5's
  120 MB target (§15.3).
- Measured with `git archive <commit>`, the worktree's `.godot` copied in, `--import`, then
  `godot --headless --export-release "Android Phone"` (the debug keystore, as in §4 of DEVELOPMENT.md).
- Room to save if needed: the pieces at Vorbis q0 (~45 kb/s) would save ~3 MB; dropping the four longest
  pieces ~4.8 MB.

## Rulings (decision — why — cost if wrong)

1. **Real recordings for the animals, synthesised voices for the monsters.** The owner asked for real animal
   sounds; monsters are cartoon creatures and no CC0 recording of a goblin exists. Cost if wrong: swap files in
   `make_audio_pass_sfx.py`.
2. **freesound HQ previews, not the original files.** Downloading originals needs an account; the preview is the
   same CC0 recording (128 kb/s MP3), which we cut to short mono Vorbis anyway. Cost if wrong: a login and the
   same script with other URLs.
3. **MIX is the default and keeps the game's loops at night, in caves and in boss fights.** They carry game
   information (night = monsters, the boss is here); by day and in menus classical music takes turns. Cost if
   wrong: one line in `MusicPlan._mix_plays_pieces`.
4. **The MUSIC setting is one button that steps GAME MUSIC → CLASSICAL → MIX**, on the Jumps row: the panel
   has no room for a row (711 px of 720) and three buttons do not fit beside the jumps. Cost if wrong: a
   scrollable panel.
5. **"Now playing" is shown once when a piece starts, 4 s, bottom centre above the hotbar, on by default** with
   a Song names toggle to hide it. Children learn the names of the pieces they like. Cost if wrong: default off.
6. **Morning Mood at sunrise** (sunrise → 0.3 is "morning"); a new world at 0.3 starts in the day, with the
   world's own loop in MIX. Cost if wrong: `MusicPlan.MORNING_END`.
7. **Eine kleine Nachtmusik is our own rendering** (music box, marimbas, plucked bass): the Commons recordings
   of the 1st movement are CC BY-SA, except one marked public domain whose performer is the "European
   Archive" (old LP transfers, public domain in Europe by age but not clearly in the US; its own Commons page
   says the attribution "does not make sense"). Cost if wrong: a real recording when one is verified.
8. **No Sugar Plum Fairy**: no public-domain recording found. The Candy Kingdom gets Waltz of the Flowers from the
   same ballet. Cost if wrong: render it from a public-domain score like Nachtmusik.
9. **Ambience on the Effects bus** (the SOUND EFFECTS slider), not the Music bus. Cost if wrong: one line.
10. **Every button clicks automatically** (`node_added`), toggles softer, the playing buttons stay quiet. Cost if
    wrong: meta `ui_sound = &""` on a button, or a line in `UiSoundRules.QUIET`.
11. **The level-up plays its jingle flat (on this game), not at the player** (it is this game's player's news).
12. **The pickup pop is host/solo only**: a LAN guest's bag arrives as new snapshots, indistinguishable from a
    world load. Cost if wrong: send "gained" from the host.
13. **Idle animal calls moved from the host's physics to every peer's `_process`**: guests heard no idle calls
    before. Each peer rolls its own timing (cosmetic). Cost if wrong: back to the host with an RPC.
14. **Frostpeak's block page (80–95) steps like snow** until that task names its blocks in `FootstepRules`
    (ice would sound like stone). Cost if wrong: one table line.
15. **Piece excerpts end at the quietest moment of their last third with a 3 s fade** instead of at a musical
    bar found by hand. Cost if wrong: set `span` per piece.

## What the lead should listen for on the emulator

1. Menu: a gentle piece fades in (MIX default) and "Now playing: … — …" shows for ~4 s above the bottom edge.
   SETTINGS: the Volume row has Volume, Music and **Effects** sliders; the Jumps row has **Music: MIX**; tapping
   it goes GAME MUSIC → CLASSICAL → MIX and the music changes within ~2.5 s; **Song names** hides the toast.
2. Every button clicks once (not twice); toggles click softer; JUMP and ATTACK make no click.
3. In a world by day: birds; the day loop, then after ~2.5 min a piece, then the loop again. `/time sunset`:
   crickets and the night loop. `/time sunrise`: Morning Mood. Dig into a cave: drips and the Crystal Cave loop.
   Walk to the sea: waves. Fly high: wind. The desert: wind by day.
4. Walk on grass, dirt, stone, sand, planks, leaves and glass: each sounds different; wading sounds wet.
5. Animals near you call now and then (real moos, baas, clucks, barks, meows, oinks, rabbit squeaks); petting a
   cat purrs, a dog whines happily; hitting an animal makes it cry out. Two cows moo in slightly different voices.
6. Goblins grunt and slimes squish now and then; a hit makes them cry out. A wave starts with a horn.
7. Survivor: breaking a block pops as it comes into the bag; gold going up clinks; a level-up plays its jingle.
8. Autopilot: the frame budget holds (music pieces load on a thread; at most two music streams and two ambience
   loops decode; 12 + 6 effect players).

## Merge notes

- Shared files touched (small blocks): `autoloads/audio.gd` (rewritten: tasks adding to `SOUNDS` merge by
  adding lines), `autoloads/music.gd`, `core/rules/music_mix.gd` (add/remove/has), `core/save/profile_data.gd`
  (three settings), `entities/animal/animal.gd` (knockback, cheer, `voice()`, `voice_tick`, the idle call moved
  out of `_physics_process`), `entities/monsters/monster.gd` (`voice_tick`, a hurt cry in the looks),
  `entities/player/player.gd` (`step_sound`), `ui/controls/touch_button.gd` (one line), `ui/hud/hotbar.gd` and
  `ui/theme/ui_kit.gd` (their own click removed), `ui/menus/settings_panel.gd`, `world/ambience.gd` (adds
  `AmbienceSounds`), `world/progress_director.gd` (jingles), `world/wave_director.gd` (horn),
  `world/universes/universe_registry.gd` (`ambience`, `classical`), `world/universes/desert.gd` (`ambience`),
  `scenes/sandbox.gd` (one line), `tests/integration/test_music.gd` and `test_universe_menu.gd`.
- Combat untouched except the animal's `knockback` (one line: its hurt voice); the pause menu untouched.
- The owner-bugs agent (#26, animals can be killed): when animals get hearts, play
  `VoiceRules.animal_hurt(species)` where they are hurt (today `knockback` does).
- The Frostpeak and Candy Kingdom descriptors can add `var ambience := {"day": &"wind", "night": &"crickets"}`
  and `var classical := [&"waltz_flowers"]`; Frostpeak's blocks can be named in `FootstepRules._STEPS`.
- New sounds: add the file, a line in `Audio.SOUNDS`, a credits line (the test fails otherwise).
