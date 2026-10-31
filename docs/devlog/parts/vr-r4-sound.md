# VR round 4, VR-SOUND: instruments you play, the cockpit you touch (owner #110)

The owner (2026-10-16 11:24, #110): "research what can be done else, what exciting things with vr". The plan:
`docs/superpowers/plans/2026-10-16-vr-round4.md` (the VR-SOUND row); the research with each idea's design and the
rulings R1-R12: `docs/devlog/parts/vr-ideas-research.md` §5.3 ideas 7 and 8, §6, §7. This agent is **VR-SOUND**, in the
worktree branch `worktree-agent-a2e22bf03cad3d385`, cut from `lead-merge` at `df69e2e1` (VR rounds 1-3, P5, the cars and
round 4's frozen contract `9fb0c96e`), while VR-HANDS builds the grabber and Life L1 its first Experiences. No editor, no
emulator, no adb, no download. Logs: `vrsound_*` in the session's scratchpad.

## In short

- **Idea 7, instruments you play.** Two new blocks for everyone: the **Xylophone** (eight rainbow bars, C5 to C6, longer
  bars lower) and the **Bongo Drums** (a big low skin, a small high one, a wooden shell). On a phone, the web or a PC a
  tap on a bar plays its note and its letter pops up over it; a tap on a skin plays that drum. In VR two mallets float
  over the nearest music block: grip one (VR-HANDS' grabber), hit a bar, and that note plays, louder the harder the hit,
  with a short buzz in that hand at the note's own frequency; the trigger plays the bar under the mallet's head too (no
  big arm motion needed). **LOOP** (over the hotbar, near a music block) counts in a bar (4, 3, 2, 1 with the
  metronome), records four bars, then plays them again and again while the child plays over them; LOOP + adds a layer
  from the next bar (three at most); STOP clears it. A friend in the world hears every note (events, never audio).
- **Idea 8, the cockpit you touch.** Seated in the rocket's capsule in VR, the dashboard has three big buttons in a row
  over its screens: **STAGE** and **LEGS** light up amber when the flight waits for them, **LIGHTS** turns the cabin lights
  off (the capsule goes dark: the stars show better) and on. Poke one with the index finger of either hand: it goes in,
  a click in that hand, and the rocket stages or puts its legs out (a dark button only clicks softly; a crew member's
  STAGE and LEGS do nothing: the pilot flies). The hand's picture stops at the panel. On the burns both controllers
  rumble low, stronger with more throttle, in short pulses; the stage separation is a thump; the countdown's 3, 2, 1
  tick on the hands. A and the trigger work as before; off VR nothing of it exists.

## What a child learns (the School's Music, `core/school/gen/g3..g7_arts_gen.gd`)

- **Note names and the scale** (grade 4, `name_the_note`): the bars are the C major scale, C D E F G A B C; each bar's
  letter pops up as it sounds, in its bar's colour. **The pentatonic scale** (grade 4, `step_or_leap`: C, D, E, G, A): a
  step is the next bar, a leap skips one; any tune on those five bars sounds nice.
- **Pitch and length** (grade 4 science, "sound"; grade 3 `higher_lower`, `tune_direction`): longer bars are lower; the
  west end is low, the east end high; up the bars is up the scale.
- **Rhythm** (grade 3: `count_claps`, `copy_rhythm`: ta, ti-ti and rests): the bongos play the rhythms; the loop snaps
  every note to the nearest half beat, so a child's ta and ti-ti come back exactly.
- **Bars, beats and time** (grade 4 `fill_the_bar`, `count_the_bar`): four beats in a bar (4/4), the bar's first beat
  ticked louder, a bar's count-in, four bars a loop; **ostinato layers** (grade 4 `ostinato_count`): LOOP + stacks a
  repeating pattern under a tune; **loops in a music maker** (grade 5 `loop_time`): four bars at 100 beats a minute are
  9.6 seconds. **Instrument families** (grade 3): a tuned percussion instrument (the xylophone) and an untuned one (the
  bongos).

## How it is built

| What | Where |
|---|---|
| The rules (pure): voices, notes, where a ray or a tip comes in, which bar, loudness, buzz, the host's budget, the loop | `core/rules/music_block_rules.gd` (`MusicBlockRules`, `MusicBlockRules.Loop`) |
| The blocks' data (page 44) and their pictures (pixel page and its realistic twin, our own) | `data/blocks/music_page.gd` (`MusicPage`), `tools/make_music_page.gd`, `data/blocks/pages/music*.png` |
| The tones (our own: a struck wooden bar, two struck skins, a woodblock) | `tools/make_instrument_tones.gd`, `assets/audio/sfx/instrument_*.wav` |
| The music played: taps, the letter, LOOP and STOP, VR's mallets, friends' notes | `world/music_director.gd` (`MusicDirector`, node "Music" in the sandbox; its inner `Mallet`) |
| The cockpit's rules (pure): the buttons' places, a quad point as a canvas pixel, the fingertip, a poke, the rumble | `core/rules/cockpit_touch_rules.gd` (`CockpitTouchRules`) |
| The poke buttons (drawn, dashboard mode only) | `ui/flight/flight_cockpit.gd` (`poke_buttons`, `poke()`, `poked`) |
| The fingertips, the cabin lights, the rumble, the buzz log | `entities/flight/rocket_flight.gd` (`_vr_touch`, `_on_poked`, `_vr_rumble`, `vr_haptic_log`) |
| The wiring | `scenes/sandbox.gd` (`_add_music`, `music.setup_local`), `world/block_library.gd` (page 44), the palette's HOME row, the Workbench recipes, `PaintRules.JOBS` |

- **Ids:** `BlockIds.XYLOPHONE` 752 and `DRUM` 753 on page 44 (tiles row 0: the xylophone's top (0,0), its side (1,0),
  both blocks' plank bottom (2,0), the bongos' top (3,0) and side (4,0)); 754-767 kept for more instruments on this page;
  `BlockIds.COUNT` 754, `NEXT_PAGE_FIRST_ID` 768 (Life L1's page 45 starts there). Both are solid opaque cubes, in the
  Sandbox palette's HOME row (with the trophy shelf, the bookshelf and the Lab bench), made at a Workbench (the
  xylophone: 4 planks and 2 sticks; the bongos: a log and 2 planks), never painted, `/give` has them.
- **A tap** reaches `MusicDirector.tap_at_screen` through `BlockInteractor.vehicle_tap`, chained before the cars' own
  (ruling S1): the block under the tap's ray (`ray_at`), nothing hittable in front (`hittable_at`), the exact point where
  the ray comes into the block (`MusicBlockRules.entry`), the voice there (`voice_at`), played as a 1.6 m/s hit.
- **A mallet** is the director's inner `Mallet` (a stick and a round head, a `VrGrabbable` "Grabbable" of kind `&"tool"`,
  `throwable` false, `far_pull` true, `hold_offset` the stick tilted 20° down from the fist). Held (`holder` left or
  right), it sits at `Vr.hand_grip(side) * hold_offset` every frame; let go, at its rest over the nearest music block
  (the head over the block, the grip towards the child). Each frame a held mallet's head (TIP_RADIUS 2 cm) that came
  into a music block's cell from outside, at 0.3 m/s or more, strikes it where it came in; it strikes again only once
  out of that block by 3 cm and 0.07 s later. The `used` signal (the trigger) at 0.6 strikes the bar under the head
  within 15 cm, again after it fell under 0.35.
- **The loop** keeps the director's own clock (`MusicDirector.time`, moved by `step(delta)`: a paused game's loop
  waits). `Loop.record` (a bar's count-in for the first take; the next bar line for a layer), `note` (snapped to the
  nearest half beat; a note half a quantum early is the take's first beat; the same note twice on a half beat once),
  `tick` (the count-in becomes the take, a take of 16 beats a layer, an empty one dropped; the layers' notes due since
  the last tick, in order), `beat_tick` (the metronome: `Audio.play(&"beep")`, the bar's first beat louder), `stop`.
- **Friends:** a guest's note goes to the host (`_rpc_note`, unreliable), the host checks it (`host_note`: a music block
  at the cell, the friend's feet within a tap's reach of it, 16 notes a second a friend) and plays it, then passes it on
  (`_rpc_heard`) only to games that said they hear notes (`_rpc_listen` once from a guest's `setup_local`, `_rpc_welcome`
  back: a guest sends notes only after its host answered, so an older build never gets a call it lacks).
- **The cockpit:** `CockpitTouchRules.button_rects(band)` puts STAGE, LEGS and LIGHTS (150 × 96 canvas px = 84 × 54 mm on
  VrUi's 0.72 m quad, 30 px = 17 mm apart) in a row centred over the dashboard's screens. RocketFlight, in VR only, each
  tick: each hand's index fingertip (`CockpitTouchRules.fingertip`: VrHandModel's mitten, the trigger's curl, Size
  Magic's size) in the dashboard node's space; its height over the face and its canvas pixel; a press when it comes in
  through the face over a button (`poke`; again after 1.5 cm out; deeper than 4 cm behind is a hand round the panel);
  the nearest one over a button makes it glow; a fingertip behind the face moves the hand's picture back onto the panel
  (touch limiting: the tracked hand is never moved). `cockpit.poke(b)` sends `poked(b)`; RocketFlight's `_on_poked`:
  LIGHTS toggles `cabin_lights` (VrCapsule's material parameters `shell` and `rim`), STAGE and LEGS do `run.act` when the
  run waits for them (never a crew member's).
- **The buzzes** all go through `RocketFlight._vr_buzz(pulse, sides)` (amplitude, seconds, Hz; `Vr.haptic`'s round 4
  frequency), logged in `vr_haptic_log` (the last 200: tests): the burn's rumble every 0.25 s while `pose.fire` is over
  0.05, the stage's thump where a stage falls away, the countdown's ticks at 3, 2, 1, the pokes' clicks, and the round 3
  touchdown, crash and wreck buzzes as before.

## Measurements

- **The tones** (2026-10-16, the Loudness way: EBU R128 over the file looped 7 times, full band / through a phone
  speaker): the bars C5 -12.5 / -17.3, G5 -13.3 / -14.6, C6 -11.9 / -12.4 LUFS; the low bongo -18.4 / -36.1, the high
  -19.1 / -29.6, the shell -19.7 / -20.4; the build notes' marimba -18.7 / -30.5 (played at -6 dB). `VOICE_DB` brings
  every bar's mean of the two to about -22 at a full hit; the bongos (bass a phone barely plays) sit near the cap
  (`MAX_DB` -1). Pitches checked by autocorrelation within 1.2 % (`test_music_blocks_tones.gd`). Size: 672 KB of WAV
  sources, **141 KB** imported (QOA, what a build packs).
- **The page:** the pixel page 2.9 KB; the realistic twin one row without alpha, 2048 × 256: 0.35 MB albedo + 0.17 MB
  normal map as ETC2 in a build (the 70 MB budget of `test_page_sizes.gd` holds).
- **Draws (VR):** the music blocks are terrain (one more page material where a chunk has one: +1 draw for that chunk);
  near a music block in VR the two mallets are 4 MeshInstance3Ds (a stick and a head each, 4 draws, no shadows) and the
  letter one Label3D while it shows (1); LOOP and STOP are two TouchButtons in the HUD's canvas (text only). In the
  capsule the three poke buttons are drawn in the cockpit's canvas (a style box and a word each). An estimate from what
  is drawn, not a bench run (the bench needs a window; P5's budget is 100 a frame in play: +5 at most here).
- **Tests:** `tests/unit/test_music_blocks_rules.gd` (13), `test_music_blocks_tones.gd` (5), `test_music_blocks_page.gd`
  (5), `tests/integration/test_music_blocks_taps.gd` (7), `test_music_blocks_loop.gd` (6), `test_music_blocks_net.gd`
  (4), `test_vr_r4_sound_mallets.gd` (8), `tests/unit/test_vr_r4_sound_cockpit_rules.gd` (8),
  `tests/integration/test_vr_r4_sound_cockpit.gd` (9): 65. Mutation checks: the host's reach and budget, the mallets'
  re-arm and slowest hit, the cockpit's touch limiting and the crew's guard each turned off made their tests fail.
- **The smoke run** in the real sandbox (`tools/smoke_all.sh music`, `tools/music_smoke.gd`): node Music, a xylophone
  and bongos placed through the host, a tap from the eyes plays G (nothing built on it, G's letter), LOOP counts in,
  records C, G and the low bongo, plays them back in order (20 metronome ticks), STOP, a simulated headset's two mallets
  and a hit playing C, out of VR none: **PASS in 47 s**.
- **The full suite** (the end): see "The full suite" below.

## Rulings (decided here; the cost if wrong)

- **S1. The music's tap rides on `BlockInteractor.vehicle_tap`, chained before the cars' own** (BlockInteractor is
  VR-HANDS' file in round 4; there is no other hook). [If VehicleDirector sets `vehicle_tap` again after the music's
  setup, a tap on a music block builds on it again: the lead's fix at the merge is a `music_tap` Callable in
  BlockInteractor next to `vehicle_tap` (3 lines) and `MusicDirector.setup_local` setting it.]
- **S2. A tap plays a music block whatever is in the hand** (like the bookshelf and the Lab bench); a hold still breaks
  it. [A child can't build onto a music block by tapping it: build from the block beside it.]
- **S3. x alone picks the bar** (the frame between the bars plays the bar under it; the west and east sides play the end
  bars); the bongos: the west half of the top is the low skin, the east half the high, every side the shell. [A child
  aiming between two bars hears one anyway: meant (forgiving).]
- **S4. The xylophone is the C major scale C5-C6, low on the west end** (blocks have no facing in the voxel library).
  [From the east side the low end is on the child's right; a facing would need rotated block models.]
- **S5. The loop: 100 beats a minute, four beats a bar, four bars, a bar's count-in, half-beat snapping, three layers
  of 64 notes; a new layer starts at the next bar line; it stops when its player is 24 m from its blocks; a broken
  block's notes are silent; the metronome ticks only while a take counts in and records.** [The tempo is one constant
  (a TEMPO choice if the owner wants faster songs); triplets and swing come back squared.]
- **S6. LOOP and STOP sit in the cars' HORN and FLY spots** (never in a car), hidden while SLEEP shows (no HUD spot was
  allocated). [If a later context button takes those spots off a car, the two overlap: move LOOP to its own spot.]
- **S7. VR's mallets: two float over the nearest music block within 2.5 m, in VR only; they go beyond 4.5 m (even held;
  the scan reaches 4 cells round the feet) or when VR ends; let go, a mallet floats back to its rest (never thrown);
  the trigger strikes the bar under the head (within 15 cm) for a child who can't swing** (the research's §4 rule 1:
  nothing needs fast or big arm motion).
  [A child can't carry the mallets elsewhere (nothing to play there).]
- **S8. A hit's loudness from 0.3 m/s (a mallet laid on it: no note) to 3 m/s (the loudest); a tap is a 1.6 m/s hit;
  every voice capped at -1 dB; the buzz is the note's own frequency two octaves down (the drums 60, 95 and 200 Hz),
  0.03-0.05 s, 0.15-0.6 strong.** [A Quest 2's Touch controllers may play the runtime's own frequency (only Touch Plus
  plays it, the research's [S42]): the Quest 3 checks it.]
- **S9. Friends hear notes as events through the host** (a music block there, within a tap's reach of 12 m, 16 notes a
  second a friend; only to games that said they listen). [An unreliable packet lost drops a friend's note (meant: no
  resend of a late note); a friend's notes come a ping late.]
- **S10. Page 44 is the music page: `NEXT_PAGE_FIRST_ID` 768** (the brief: "move it on only if you take the whole
  page"; the id-space test holds COUNT ≤ NEXT_PAGE_FIRST_ID, and page 44's PNG is MusicPage's). [None for Life L1 (the
  brief gave it page 45); a later instrument takes 754-767 on this page.]
- **S11. The tones are WAV written by our own GDScript tool and imported as QOA** (the research said .ogg: GDScript
  can't encode Vorbis; QOA is the build notes' format, a fifth of the PCM). [None.]
- **S12. STAGE, LEGS, LIGHTS: 84 × 54 mm, 17 mm apart, centred over the screens, in dashboard mode only, hidden in the
  descent** (its dials and card take that band); STAGE and LEGS act only when the flight waits for them (the same
  `run.act` as A); a dark button only clicks softly; a crew member's never act. This overrides VR-UI's ruling 22 ("the
  dashboard is a display") for these three only: the laser still presses only the hint card. [A child who wants
  LIGHTS in the descent has to wait for the touchdown.]
- **S13. LIGHTS: the cabin lights on by default; off darkens the capsule's walls and the window's warm ring**
  (VrCapsule's material parameters, set from RocketFlight: VrCapsule is VR-HANDS' file). [A child who turned them off
  finds the capsule dark: one poke turns them on.]
- **S14. A poke: in through the face over a button; again after 1.5 cm out; deeper than 4 cm behind ignored; both
  hands' index fingertips from VrHandModel's geometry; touch limiting moves only the hand's picture.** [Whether the
  press is felt at the fingertip (the grip-to-finger offset of a real controller) only the Quest 3 can tell.]
- **S15. The rumble: a 0.12 s pulse every 0.25 s at 70 Hz, 0.08-0.4 with the engines' fire, from the moment the engines
  light (T-3 in the countdown); the stage's thump 0.85 for 0.15 s at 45 Hz; the countdown's ticks 0.3 for 0.03 s at
  250 Hz; a poke's click 0.45 for 0.035 s at 180 Hz, a dark button's 0.15 for 0.02 s at 120 Hz.** [If the owner finds it
  tiring: a VR COMFORT switch "rumble off" (one setting, `_vr_rumble` skips).]

## What only the Quest 3 can check (the lead, on the owner's headset)

- The mallets: they hit what the eye expects (the head's 2.8 cm ball, the 20° tilt in the fist); the grip finds them
  over the block (VR-HANDS' grabber); a hit feels sure, not late (the frame's sampling at 72-90 Hz: a fast hit's head
  moves ~6 cm a frame); the buzz at each bar's frequency is felt as higher and lower; the trigger strike is easy.
- The tones in the Quest's speakers: the bars clear, the bongos' bass heard, the loop's three layers never too loud.
- The pokes press at the fingertip (not before, not after); the hand's picture resting on the panel feels right; the
  buttons are easy to tell apart and to reach seated (0.55 m ahead, 0.32 m down); LIGHTS off looks good (the stars).
- The rumble is pleasant, not tiring (70 Hz on Touch Plus); the thump and the ticks are felt.

## The full suite

2026-10-16 17:27-18:32 (`tests/run_tests.sh`, through a PC-wide slot, at commit `672be8ef`): **1,147 scripts, 10,434
tests, 10,431 passing, 0 failing**, 3 risky or pending, none of them VR-SOUND's (`test_the_column_cache_changes_nothing`
and `test_chunks_meet_without_seams` assert nothing, `test_the_code_from_the_computer_typed_on_the_phone_moves_the_game`
is pending while MoveRules is off), 3,884 s. The run before it (16:19-17:24) found two things. The first was
VR-SOUND's: `test_shader_warmup_sources.gd` failed because MusicDirector made a material and a 3D label that the
warm-up did not list. The fix is in `672be8ef`. The second was this session's own: `test_assets_pack_load.gd` failed
because a Claude Code hook's `python3` shim on the session's PATH refused the test's `python3 tools/pck_tool.py`. Run
without the shim it passes 5/5, and the final run took it off PATH (`vrsound_full.sh`).

## Next

- The lead at the merge: a `music_tap` hook in BlockInteractor for ruling S1 (or keep the chain), VR-HANDS' grabber
  driving the mallets (the tests' `holder` and signals become the grabber's).
- More instruments on page 44 (754-767): chimes, a piano block; a song card to play along (the letters over the bars:
  "Twinkle, Twinkle" on C C G G A A G); a School exercise played on the xylophone (the research's "School's block rounds"
  path); a VR COMFORT "rumble off" switch if the owner asks.
