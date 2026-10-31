# Life L1: the Life tab, the Experience framework, and the first three Experiences — the agent brief (owner #112, #113)

The owner (2026-10-16): "we use a game to educate children, teach them everything they need in life not only school ...
especially now when we have VR ... teach them real life skills, this is the future of education" (#112); "the game
should be intuitive, children should understand everything easily ... parents should be excited how fast children learn
... this is not just a game, this is educational platform" (#113). The Classroom is the future, not now (#114): build
nothing for it. You are building Life's first wave in EasyCraft (Godot 4.7.2, typed GDScript; phones, the web, PC and VR
on the Meta Quest). Work autonomously; do not ask questions (decide, and write each ruling down with what it costs if
wrong).

## Read first
- **The design: `docs/design/life-skills.md`** and its second strand **`docs/design/success-skills.md`** (Life L1 builds
  Living well's first Experiences and Success's first step). `life-skills.md` (all of it: the Life map, the Experience loop §3, VR §4, the flagships
  §5, careful topics §6, how it fits §7, easy means obvious §10, parents see the learning §11) and spec §27.
- The School: spec §22, `core/school/*`, `data/school/*`, `ui/school/school_screen.gd` (the tabs, the unit format "Quick
  memory", practice, "Try it in the world", "Next"; the grown-ups' page `show_grown_ups_page` behind ParentGate), how a
  lesson pays gold (spec §25, the core loop), ReadAloud.
- The child-psychology rules `docs/design/engagement-and-child-psychology.md` (§1.8 rewards: praise effort and strategy,
  informational stamps; §1.11 fear; §1.12 age stages).
- VR: `docs/devlog/parts/vr-rig.md`, `vr-ui.md`; `autoloads/vr.gd`'s public API (`active`, `hand_grip(side)` the hand's
  pose, `trigger(side)`, `trigger_pressed`, `head_transform`, `hand_ray`, `pointer_ray`, `fade_out/in`, `sit`), the VR
  panels (`UiLayers.route`), haptics as VR-RIG uses them.

## Build (L1 of the design's plan)
1. **The Life tab** in the School (a 13th subject, "Life", its own colour and icon): the ten areas, each skill on the
   Little (6-8), Middle (9-11) and Big (12+) track; the track picked by the child (big picture buttons, read aloud) or
   on the grown-ups' page; units in the School's lesson format whose "Try it in the world" starts the Experience; Life
   units pay gold like any lesson. Units for the three flagships' skills on all three tracks now; the other areas'
   units can be short stubs that say "coming soon" only if a unit needs an Experience not built yet (prefer real short
   lessons from the School's existing Health, Citizenship and Computing content where they fit).
2. **The Experience framework** (`core/life/*` pure rules, `entities/life/*` the rooms, `ui/life/*`):
   - an Experience = ordered steps, each with what to do, how it is checked, the coach's show-me, its kind feedback; a
     self-contained **practice room** scene (its own small space, not the voxel world), started from the Life tab, with a
     calm way out at any moment ("I need a break") and a good ending always;
   - **easy means obvious** (design §10): the coach shows a step with see-through ghost hands (VR) or a ghost finger
     (flat); the one next thing glows; every line read aloud on the Little track (and on request on the others); the
     same controls everywhere (grip takes, trigger uses, A says yes; flat: tap, hold, drag); the coach steps in after
     about 10 s without progress, by showing, not by text; big forgiving targets;
   - the **before-and-after check** (3-5 picture questions, design §11), the **name it** card (the authorities' own
     steps), spaced repeats (the skill comes back later, varied), the **Try it for real** card;
   - the **Life Passport** (a book like the Secret Book: a page per skill, stamps *Done it*, *By myself*, *Expert*; a
     surprise celebration on a new Expert stamp);
   - first-time success measured on the device (how often a step is done without the hint, how long), kept locally;
   - progress in the profile (so the existing backup carries it; nothing else sent).
3. **The grown-ups' Life page** (behind the existing gate): what was practised, the before-and-after numbers, "your
   child can now..." in plain words, the **Try it for real** list, the **region** (the emergency number: 112 for Georgia
   and Europe, 911, 999 ...; which side cars drive on; default from the device's locale; a short list, a ruling), and
   the careful topics' switches (all off; nothing behind them yet).
4. **Little Lifesaver** (design §5 #1): Little: is it safe? call for help: dial the region's number on a play phone, the
   calm operator's questions ("What happened? Where are you?": the child answers by picking pictures; the address is
   "tell it to your grown-up", never typed), stay with the person. Middle: a cut (press with a clean cloth), a burn
   (cool running water, a time-lapse of the minutes), the recovery position (move the dummy's arm, knee, roll). Big:
   hands-only CPR (two hands on the chest centre, push to a beat of 100-120 a minute; VR: the hands' up-and-down from
   `hand_grip`, the controllers buzz on each good push, a rate meter; flat: tap to the beat), choking basics. The dummy
   or a friendly buddy, never an injury shown.
5. **Fire Escape** (#2): the practice house; the alarm beeps (soft); get low (VR: the head's height from
   `head_transform`; flat: a CROUCH button), check a door with the back of the hand (warm: use the other way), close doors
   behind you, out to the meeting point, call the region's number from outside, never back in; stop, drop and roll.
   Little: the hazard hunt (find 10 dangers in a house). Big: the extinguisher (pull, aim, squeeze, sweep) on a small bin
   fire. Smoke is a soft grey haze at the ceiling; nothing frightening (§6).
6. **My Money Stall** (#3; also **the first step of the Success strand's My Business**, `docs/design/success-skills.md`
   §2.1: build its stand, customers, prices, coins and saving jar so the later shop and company grow from them): a market stall: goods (bread from wheat, crafts: given, or from the child's own if they have
   them), set prices, a customer pays, give change coin by coin (maths), count the day's takings; the saving jar for a
   goal (the rocket); the bank: put some in, its interest grows week by week (in-game days); a shopping trip with a list
   and a budget (needs and wants); spot the scam ("give me 10 gold, I'll give you 100"). Uses its own pretend coins (a
   ruling, so the child's real gold is never lost in practice; the Experience's reward is gold like a lesson).
7. **The facts and the review sheets:** every step from its authority (first aid: the IFRC International First Aid,
   Resuscitation and Education Guidelines and the ERC guidelines; fire: the national fire services' and NFPA's child
   fire-safety guidance; money: the OECD/INFE and EU frameworks), each with its source URL in your notes; a review sheet
   per Experience (`docs/devlog/parts/life-l1-review.md`: every step, its words, its source) for the owner's experts.
   First aid Experiences say "This is practice. A real first aid course teaches more."

## VR hands: no grab system of your own
VR round 4 (`docs/devlog/parts/vr-ideas-research.md`) will build ONE shared grab system (grab near things, pull far ones,
throws, the shoulder bag, the wrist hotbar) behind a contract the lead freezes. Don't build a general grab system:
L1's VR steps use the hand's pose (`Vr.hand_grip`), the trigger and a grip reading (hold the hand on the cut and
squeeze; push on the chest; point at a coin and pull the trigger), each step written so it can later take the shared
grab without changing its rules (the step's check reads "the hand is here and squeezing", not a particular input).

## Allocation and rules
- Yours: `core/life/*`, `entities/life/*`, `ui/life/*`, `data/life/*` (new), tests `tests/**/test_life_*.gd`, notes
  `docs/devlog/parts/life-l1.md`, spec §27 "As built (L1)", DEVELOPMENT.md. Small hooks, marked "owner #112", in
  `ui/school/school_screen.gd` (the tab, the grown-ups' page), `core/school/*` (the subject), the profile
  (`core/save/profile_data.gd`: the Life progress keys; keep the backup's limits in mind), and `autoloads/vr.gd` only to
  add a read-only `grip(side) -> float` accessor if you need it (marked).
- Two other agents run now: the cars (#109: `entities/vehicles/*`, `world/vehicle_director.gd`, `ui/vehicles/*`, HUD
  driving buttons) and VR P5 (`core/rules/graphics_preset.gd`, `entities/fx/*`, VR-only HUD icons). Don't touch their
  files. Blocks if you need any: page 45, ids 768-783 (the cars may take page 44; move `BlockIds.NEXT_PAGE_FIRST_ID` on).
- **English only. Nothing personal kept or sent; no microphone.** Calm, never scary (§6). Every Experience playable
  flat and in VR.
- TDD (superpowers:test-driven-development); invoke the matching godot-prompter skills (godot-ui and hud-system for the
  screens, xr-development for the hands, scene-organization for the rooms, save-load for the progress) before building;
  `--import` after new class_name scripts; logs named `life1_*`; the FULL suite once at the end; a headless smoke that
  plays each Experience through on each track. Never open the editor or an emulator, never touch adb; never merge or
  push; no downloads; never start agents. Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Finish
Notes (what a child sees and does in each Experience on each track, flat and in VR; every ruling and its cost; the facts'
sources; the review sheets; what the lead must check on the emulator and on the Quest 3), DEVELOPMENT.md, spec §27 "As
built (L1)". Report: branch, commits, the three Experiences, the Life tab and the Passport, the grown-ups' page, the
full suite's result.
