# Owner feedback #50: "a lot chicken sounds only everywhere"

The owner (2026-09-24, playing build 0.3.2 on phones): "also pleae imorove sounds, now there is a lot chicken
sounds only everywhere". Built in a worktree from release 0.3.2 (`4d3198d`, which has the audio pass); no
editor, emulator or godot-mcp use. Spec §12.10 ("The animal chorus"), M5 plan Task 2 (the note).

## Root cause (measured first)

The audio pass (its ruling 13) moved the animals' idle calls to every device: **every animal rolled its own
8–20 s timer** and called while *any* player was within 20 blocks. Nothing shared a budget, so the calls grew
with the herd: **about 4.3 calls a minute for every animal within 20 blocks**. Nothing asked for variety
either, so a herd of one kind was one sound over and over, and the same take could repeat.

Why *chickens*:
1. **The hens' recordings are the loudest, and much louder through a phone speaker.** EBU R128 loudness of
   each take (looped so the 400 ms windows fit), full band and after two 500 Hz high-passes (a phone's small
   speaker gives almost nothing below that):

   | Kind | Takes (full band, LUFS) | Through a phone speaker | Mean (phone) |
   |---|---|---|---|
   | chicken | −11.7, −11.0, −12.2 | −12.7, −11.6, −12.6 | **−12.3** |
   | rabbit | −12.7, −14.5, −13.5 | −13.1, −17.6, −13.5 | −14.7 |
   | sheep | −16.4, −17.4, −13.9 | −17.1, −18.2, −14.2 | −16.5 |
   | cat | −12.5, −17.0, −21.2 | −12.6, −17.1, −21.7 | −17.1 |
   | dog | −14.3, −16.8, −20.0 | −17.4, −18.4, −21.9 | −19.2 |
   | pig | −15.7, −22.8, −24.5 | −16.0, −23.8, −25.2 | −21.7 |
   | cow | −15.6, −16.3, −14.4 | −26.2, −28.7, −21.7 | **−25.5** (a moo is mostly below 500 Hz) |

   On a phone a hen is 4 dB louder than a sheep and 13 dB louder than a cow at the same distance: in a mixed
   field the clucks are what you hear.
2. **Hens come in flocks** (2–5; 20 % of the land animals by AnimalRules' weights and herd sizes), and a
   flock right by the child calls ~18 times a minute.
3. **Animals gather round a child**: they walk over to a child they like (M2 Task 18's minds), and children
   `/summon` them: 10 summoned hens made 41 clucks a minute, 11 in one 10 s window, 0.01 s apart.
4. **On a LAN guest's phone** the timer measured the distance to the *nearest player* (any), so the herds
   round the host also called if they were within 40 m of the guest's camera.

At the world spawn the Meadows are sparse (45 % of 32×32 areas have a herd): 0–1.7 animals within 20 blocks.
The flood is where herds are, and wherever animals come to the child.

### How it was measured

`tools/animal_voices_measure.gd` (new; `docs/DEVELOPMENT.md` §4): a new Sandbox world by day, headless on real
terrain; after 30 s (the animals come a few a second) it counts every `Audio` play by name for 150 s through
the new `Audio.sound_played` signal, with each idle call's distance from the camera and its level there
(volume + Audio's inverse-distance fall-off, unit size 6, max +3 dB). Scenarios: standing at the spawn,
walking at 2.5 m/s, standing at the **busiest place** of the world (AnimalRules' own spawns in the 13×13 areas
round the spawn: most animals within 20 blocks), at the biggest **chicken flock**, and after 10 `/summon
chicken`. Nine runs before (release 0.3.2 plus only the counting signal) and the same nine after.

## Before and after

Idle animal calls a child hears (150 s each; "most in 10 s" = the most calls in any 10 s window):

| Scenario (seed) | Animals within 20 blocks | Before: calls/min, most in 10 s, same kind back to back | After | Kinds heard after |
|---|---|---|---|---|
| spawn (7) | 0 | 0.0 | 0.0 | — |
| spawn (42) | 1.7 sheep (+ fish at 21 m) | 6.0, 4, 64 % (80 % fish blubs) | **2.0**, 1 | sheep |
| walking (7) | 0–1 | 3.2, 3, 71 % | **1.6**, 1, 33 % | cat, sheep, rabbit |
| busiest (7): 4 pigs, 3 cows | 3.2 | 16.0, 6, 82 % (88 % oinks) | **2.8**, 2 | pig, cow |
| busiest (42): 7 pigs | 6.2 | **27.2**, 7, 100 % | **2.4**, 1 (one oink every 20–25 s) | pig |
| busiest (1234): 4 cows, 2 sheep, a cat | 5.9 | 23.2, 8, 54 % (72 % moos) | **5.2**, 2, **0 %** | cow 46 %, cat 46 %, sheep 8 % |
| chicken flock (7): 4 hens, sheep | 3.0 | 13.6, 9, 55 % | **1.6**, 2, 33 % | sheep, chicken |
| chicken flock (42): 5 hens, pigs | 6.3 | **22.0**, 7, 70 % (**84 % clucks**, 18.4/min) | **4.0**, 2, 22 % | chicken 60 %, pig 40 % |
| 10 summoned hens (7) | 9.8 | **41.2**, 11, 100 % (0.01 s apart) | **2.8**, 1 (one cluck every 20 s) | chicken |

- The shortest gap between two calls: before 0.01–1.0 s; after ≥ 7.1 s with several kinds near, ≥ 20 s with
  one kind.
- The hens' level where the child stands (flock 42): before −7.4 dB mean, after −15.8 dB (−5 dB kind gain,
  far ones quieter); the cows' (busiest 1234): before −6.2 dB, after −3.1 dB (+3 dB) though the calls are
  fewer.
- With one kind near, "same kind back to back" stays 100 % by nature, but 20 s apart and never the same take
  twice.
- The scene test's crowd (20 hens and 5 others in 2–18 blocks, 10 minutes): **5.7 calls a minute, chickens
  23 %** (13 of 57: cow 12, sheep 10, pig 10, dog 7, cat 5), never the same kind twice in a row. With the rules
  mutated to "no budget, no rest" it was 63.4 a minute and 62 % chickens.

## What was built

- **`AnimalChorusRules`** (`core/rules/animal_chorus_rules.gd`, pure): `next_call(now, candidates, rng)`
  returns which of the animals near the listener calls now, or −1.
  - One budget: at most one idle call every **6–10 s** (`GAP_MIN`, `GAP_MAX`) per device, however many animals.
  - A kind **rests 20 s** after it called (`KIND_REST`); the kind with the best score calls: seconds since it
    was last heard (at most 60) minus **1.5 s per block** to its nearest animal (`DIST_COST`). Never-heard kinds
    first, near kinds first among equals.
  - Within the kind, nearer animals are picked more (weight 1 / (1 + (d/6)²)).
  - Farther ones are **rarer** (`call_chance`: always within 6 blocks, 35 % at 20, never beyond; a far one
    kept quiet still spends the gap) and **quieter** (`volume_db`: −4 dB near, −10 dB at 20 blocks, on top of
    Audio's distance fall-off), plus the kind's gain.
  - Nobody near (or every kind near resting): it looks again after 1 s.
  - `heard(kind, now)`: a voice the chorus did not choose (a hurt cry, a happy purr) lets that kind rest and
    keeps the chorus quiet 3 s (`AFTER_VOICE`). The voice itself is never held back.
  - `take(count, last, rng)`: never the same take twice in a row.
- **`VoiceRules.call_gain_db`** (`CALL_GAIN_DB`): chicken −5, rabbit −2, sheep 0, cat 0, dog +2, pig +3,
  cow +3 dB, from the phone-speaker table above (towards −17 LUFS; boosts capped at +3 dB). Idle calls only.
  `CALL_MIN`, `CALL_MAX` and `call_wait` are gone.
- **`AnimalChorus`** (`world/animal_chorus.gd`): one per world, added by the sandbox on every peer (cosmetic,
  nothing sent). When a call is due it walks the `animals` group (at most once a second), takes those within
  20 blocks of **this device's camera**, asks the rules and plays the call at the animal, in its own voice
  (`Animal.voice()`), at the rules' volume. Signal `called(animal, sound, volume_db)`. It listens to
  `Audio.sound_played` for animal voices it did not play (`heard`).
- **`Animal`**: its own idle-call timer and `voice_tick` are gone. `knockback` (hurt) and `cheer` (happy) play
  at once as before. The setup keeps its one RNG draw so every animal's choices stay as they were.
- **`Audio`**: every sound picks its take with `AnimalChorusRules.take` (footsteps, clicks and all: no take
  twice in a row), `last_take`, and the signal `sound_played(sound, at, volume_db)` for every sound that plays.
- Ambience unchanged: birds by day and crickets at night keep playing under everything (loops of −22 LUFS at
  −8 and −10 dB on the Effects bus).

## Patterns (the `godot-prompter:audio-system` skill, `superpowers:systematic-debugging`)

| Chosen | Why | Rejected |
|---|---|---|
| One chooser per device (a "voice manager") over the emitters, with a global cooldown and per-category cooldowns | The skill's SFX pooling limits how many sounds play; here the problem was how many are *started*. A chooser can prefer variety and nearness, which first-come timers cannot | A cap in `Audio` on the same sound (drops arbitrary calls, keeps the one-kind flood, no variety); a longer per-animal timer (the rate still grows with the herd) |
| Per-kind gain table at play time | Evens the takes without re-encoding files; one table, testable | Re-levelling the files in `make_audio_pass_sfx.py` (downloads, a new APK asset diff; a later option if phones need it) |
| The listener is the current camera | What the device actually hears; a guest never hears calls chosen for the host's herds | The nearest player (any peer): the old behaviour |
| `Audio.sound_played` signal | The measurement counts by name without touching callers; the chorus hears a child's own animal voices without the animal knowing about it | Hooks in `Animal.knockback`/`cheer` (couples the animal to the chorus) |

## Tests (RED → GREEN)

| File | Tests | RED seen | GREEN |
|---|---|---|---|
| `tests/unit/test_animal_chorus_rules.gd` (11) | `test_one_budget_at_most_one_call_every_six_to_ten_seconds` (5 seeds, 10 min of 20 hens + 5 others), `test_a_kind_rests_after_it_called_so_one_kind_never_dominates` (chickens ≤ 30 %, all six kinds heard, never the same kind twice in a row), `test_a_lone_flock_is_calm`, `test_kinds_not_heard_lately_come_first`, `test_the_nearest_animals_call_first`, `test_farther_ones_are_quieter_and_rarer`, `test_beyond_twenty_blocks_nothing_is_heard`, `test_nobody_near_then_a_call_comes_soon`, `test_a_childs_own_animal_voice_makes_the_chorus_wait`, `test_the_loudest_recordings_are_evened_out`, `test_the_same_take_never_plays_twice_in_a_row` | "Could not find type AnimalChorusRules" (written first); mutation (6–10 s → 0.5–1 s, rest 20 → 0 s, random takes): 8 of the 18 new tests fail, e.g. "idle calls a minute: 63.4", "chickens are 62 % of the calls" | ✓ |
| `tests/integration/test_animal_chorus.gd` (7) | real `Animal` nodes round a camera: `test_twenty_chickens_and_five_other_animals_make_a_calm_mixed_chorus` (4–10 a minute; chickens ≤ 30 %; every other kind heard; never the same kind twice in a row), `test_a_call_is_heard_through_audio_in_the_animals_own_voice`, `test_every_call_is_as_loud_as_its_kind_and_distance_say`, `test_the_listener_is_this_devices_camera`, `test_animals_never_call_on_their_own`, `test_a_childs_own_animal_voice_is_never_blocked`, `test_the_same_take_never_plays_twice_in_a_row` (Audio) | "Invalid access to property or key 'last_take'" (Audio without the take rule) | ✓ |
| `tests/unit/test_voice_rules.gd` (changed) | the idle-call test now checks the chorus's gap | — | ✓ |
| `tests/integration/test_animal_voices.gd` (changed) | the two `voice_tick` tests moved to `test_animal_chorus.gd` | — | ✓ |

Full suite (`tests/suite_slots.sh tests/run_tests.sh`): the first run was **4093 / 4096**; the 3 failures
(`test_main_menu_modes.gd`: `test_after_how_brave_a_new_survivor_world_asks_which_game`,
`test_monster_wave_lists_the_arenas_and_a_card_starts_one`; `test_candy_generator.gd`:
`test_secret_structures_are_generated_without_seams`) fail the same way on the untouched release code
`4d3198d` (checked in a copy of it): merge leftovers of the audio pass (Audio's click is the button's last
connection) and the treasure pack (13 secret kinds, not 5). The lead has already fixed both files in
`lead-merge`; this branch takes those two files **verbatim** from there (so they merge cleanly). Second run:
**4096 / 4096**, exit 0.

## Rulings (decision — why — cost if wrong)

1. **One chorus per device, listening at the camera.** What a phone hears is what its camera hears; each peer
   chooses its own (cosmetic, nothing sent, as the audio pass ruled). Cost if wrong: two phones side by side
   hear different animals at different moments (they did before too).
2. **6–10 s between idle calls, a kind rests 20 s.** A lone herd calls about every 20–25 s (2.4–2.8 a minute
   measured), several kinds every 6–10 s in turn (4–5.2 a minute measured). The owner asked for fewer sounds:
   calm first. Cost if wrong: `GAP_MIN`, `GAP_MAX`, `KIND_REST` (a livelier farm: rest 12 s).
3. **Variety beats nearness only by a little** (1.5 s of "not heard lately" per block). A cow 12 blocks away
   that was never heard beats hens 3 blocks away heard 20 s ago; hens next to you beat a far sheep heard 30 s
   ago. Cost if wrong: `DIST_COST`.
4. **Far animals: 35 % of the time at 20 blocks and 6 dB quieter**, on top of the distance fall-off. Cost if
   wrong: `FAR_CHANCE`, `FAR_DB`.
5. **Kind gains for idle calls only** (hens −5 dB … cows +3 dB, boosts capped at +3 dB against clipping).
   Hurt and happy voices stay as recorded: they answer the child's own action. Cost if wrong: one table; if
   cows are still too quiet on a phone, re-level the cow takes with a high-pass-aware target in
   `make_audio_pass_sfx.py`.
6. **No take twice in a row, for every sound** (footsteps, clicks, hits too), not only the animals. Cost if
   wrong: none known (a single-take sound is unchanged).
7. **A child's own animal voice is never blocked; the chorus waits 3 s after it and that kind rests.** A pet
   purring as the child strokes it is not followed by a random cluck. Cost if wrong: `AFTER_VOICE`.
8. **Ambience not made louder.** Fewer calls leave more room for the birds and crickets already there
   (−22 LUFS loops at −8/−10 dB); louder birds could become the next "too much". Cost if wrong: the numbers in
   `AmbienceSoundRules.LOOPS`.
9. **Monster idle voices unchanged** (each monster still rolls its own 6–14 s timer). The owner asked about
   animals, and at night a grunt says "a monster is near". Noted in the M5 plan: give them the same kind of
   budget if a phone test finds nights too busy.
10. **Fish blubs stay in the chorus** (gain 0): at the spawn of seed 42 they were 80 % of the calls before,
    from the shore 21 blocks away (the old distance was the player's, not the camera's); now they take their
    turn like any kind within 20 blocks of the camera.

## What the lead should listen for on the phone

1. Stand next to a herd (sheep, pigs or cows): a call about every 20 s, not a constant chorus. Where several
   kinds live (a farm field): one call every 6–10 s at most, the kinds taking turns (moo, baa, oink, cluck…).
2. Next to a flock of hens: an occasional, softer cluck (5 dB quieter), never clucking over clucking.
3. `/summon chicken` ten times: still about three clucks a minute.
4. Cows and pigs are now audible next to hens (they were 9–13 dB quieter on a phone speaker).
5. Far animals (15–20 blocks) are rarer and quieter than near ones; beyond 20 blocks: silence.
6. Pet a cat (purr), a dog (happy whine), hit a chicken (alarm call): each plays at once, every time; the
   animals then keep quiet a moment.
7. Birds by day and crickets at night fill the quiet between calls.
8. Footsteps never repeat the same step sound twice in a row.
9. LAN on two phones: each phone hears the animals near itself only.

## Merge notes

- Shared files touched (small, marked "owner #50"): `autoloads/audio.gd` (the signal, `last_take` and the take
  rule in `play`), `core/rules/voice_rules.gd` (call gains; `call_wait` and `CALL_MIN/MAX` removed),
  `entities/animal/animal.gd` (the idle-call timer and `voice_tick` removed), `scenes/sandbox.gd` (3 lines in
  `_ready`: the chorus), `tests/unit/test_voice_rules.gd`, `tests/integration/test_animal_voices.gd`, the spec
  §12.10, the M5 plan (Task 2 note), `docs/DEVELOPMENT.md` (§4 the measuring tool, §5 Audio and the chorus).
- `tests/integration/test_main_menu_modes.gd` and `tests/unit/test_candy_generator.gd` are byte-for-byte the
  `lead-merge` worktree's (the lead's fixes of 0.3.2's three failing tests), not changes of this task.
- `docs/playtests/owner-feedback.md`: this branch (from 0.3.2) has no rows 48–49, so row 50 sits after row 47;
  keep the lead's rows 48–49 and take this row 50.
- Anything that called `Animal.voice_tick` or `VoiceRules.call_wait` must go through the chorus now (nothing
  else did at `4d3198d`).
- A new animal kind needs a `VoiceRules.CALL_GAIN_DB` line only if its takes are far from −17 LUFS through a
  phone speaker (`docs/devlog/parts/owner-50-sounds.md`, the table).
