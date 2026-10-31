# Life L2: Safe Streets, The Kitchen, Calm Corner, Life Town — the agent brief (owner #112, #113, #116, #117)

The owner (2026-10-16): life skills are "the future of education" (#112); "children should understand everything easily"
(#113); "they should be able to use any instrument and devices ... we must use same aproach for any skills children need
in real life" (#117). Life L1 is merged (the Life tab, the Passport, the grown-ups' Life page, the Experience framework,
Little Lifesaver, Fire Escape, My Money Stall); the cars (#109) are merged. You build Life's second wave in EasyCraft
(Godot 4.7.2, typed GDScript; phones, the web, PC and VR on the Meta Quest 3). Work autonomously; do not ask questions
(decide, and write each ruling down with what it costs if wrong).

## Read first
- `docs/design/life-skills.md` (the Experience loop §3, VR §4, the flagships §5 #4-#6, careful topics §6, Life Town §7,
  easy means obvious §10, parents §11, **one method for every real skill §13**: the ten motions and the device model,
  named as data in every step) and `docs/design/success-skills.md` (the Kitchen's budget week links to Money).
- **Life L1 as built:** `docs/devlog/parts/life-l1.md` (its 27 rulings, the framework, how a step names its motion, the
  rooms, the coach, the stamps, the measurements), `core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*`, spec
  §27.1. Build on its framework; don't fork it.
- **The cars:** `docs/devlog/parts/cars.md` (the kinds, their models, the kinematic car, the region's traffic side).

## Build
1. **Safe Streets** (`life-skills.md` §5 #4; the evidence: VR street-crossing training works over repeated short sessions,
   behaviour more than knowledge: the spaced repeats matter). A town street practice room with real-size cars from the
   cars' models moving at real speeds (scripted traffic in the room, not the world's cars): stop at the kerb, look both
   ways (VR: the head's look is checked; flat: a LOOK swipe), listen (the engines), the crossing and the green man,
   parked cars hide you (step out to see, never into the road), at night be seen (light clothes, a light); the bike:
   the helmet's fit (two fingers above the eyebrows, the straps); the car: the seatbelt and the booster seat; Big: the
   rules of the road from the driver's seat (give way, lights, speed). The region's traffic side (the grown-ups' Life
   page) decides "look left, right, left" or "right, left, right". Gaps between cars are real; a child who steps out
   when it isn't safe sees the car stop gently, never a crash.
2. **The Kitchen** (#5): wash hands (20 s, the germ glow fading; twist the tap), a healthy plate (food groups), measure
   (pour and the scales: fractions), cut safely with a child-safe knife (the bridge and claw grips: cut), stir and whisk
   (stroke), the hob and the oven (devices: knobs, the hot light, handles turned in, oven gloves), the kettle (the fill
   line, off before pouring), clean up; recipes from many countries; Big: a week's meals on a budget (pretend money).
   Every step names its motion and devices as data (§13), like L1.
3. **Calm Corner** (#6): a quiet room; name the feeling (the buddies' faces), balloon breathing (VR: hands rise and fall;
   flat: hold and let go), five things you can see (look around), the worry box (put a worry in); then short stories with
   buddies: a friend left out, a quarrel, someone being unkind online or in the playground (what you can do, who to tell).
   Not therapy: kind, short, always pointing to a trusted grown-up; nothing a child says or picks is kept beyond the
   stamps.
4. **Life Town** (§7): a small district by the spawn in Green Meadows (and the other home worlds): the practice house
   (Fire Escape), a clinic (Little Lifesaver), the market (My Money Stall), the street (Safe Streets), a kitchen house
   (The Kitchen), a park bench (Calm Corner); walking up to one starts its Experience (like the Launch Site's board). Find
   how the Launch Site is placed and follow it; blocks if you need any: page 45, ids 768-783.
5. **L1's follow-ups:** Life in the Gold Shop's "how to earn" list (`EarnRules.TABLE`); Android Back inside a practice room
   asks "Leave the practice?" instead of leaving the School (a small hook in `ui/menus/menu.gd`, marked owner #112).
6. **The facts and the review sheets** as in L1: every step from its authority with its source (road safety: the WHO and
   national road safety bodies; food: the WHO's healthy diet, food safety; feelings: CASEL and the national children's
   mental-health guidance), the review sheets regenerated (`tools/life_review_sheet.py`).

## Allocation and rules
- Yours: `core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*`, Life Town's placement (in the world files that place
  the Launch Site, marked owner #112), the two follow-ups' hooks, tests `tests/**/test_life_*.gd`, notes
  `docs/devlog/parts/life-l2.md`, spec §27 "As built (L2)", DEVELOPMENT.md.
- Running now: **VR-HANDS** (the shared grab: `entities/vr/*`, `autoloads/vr.gd`, `entities/player/*`,
  `core/vr/vr_gesture_rules.gd`, `core/building/build_table_rules.gd`) and **VR-SOUND** (`world/music_director.gd`,
  `core/rules/music_block_rules.gd`, `ui/flight/flight_cockpit.gd`'s poke targets, `entities/flight/rocket_flight.gd`'s
  rumble). Don't touch their files. **No grab system of your own** (VR-HANDS' lands soon); steps name their motion as
  data; VR uses the hand's pose, the trigger and `Vr.grip(side)` as L1 does.
- English only. Nothing personal kept or sent; no microphone. Calm, never scary (§6). Every Experience flat and in VR,
  on all three tracks.
- TDD (superpowers:test-driven-development); the matching godot-prompter skills first (scene-organization, godot-ui,
  xr-development, audio-system); `--import` after new class_name scripts; logs `life2_*` in the session scratchpad; a
  headless smoke that plays each new Experience on each track (extend `tools/life_smoke.gd`); the FULL suite once at the
  end. Never open the editor or an emulator, never touch adb; never merge or push; no downloads; never start agents.
  Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. A plugin's `python3` shim may be first on
  your PATH: `tests/run_tests.sh` drops it itself; for tools, `/usr/bin/python3` (DEVELOPMENT.md §8).

## Finish
Notes (what a child does in each Experience on each track, flat and in VR; Life Town; every ruling and its cost; the
sources; what the lead must check on the emulator and on the Quest 3), DEVELOPMENT.md, spec. Report: branch, commits,
the three Experiences, Life Town, the follow-ups, the full suite's result.
