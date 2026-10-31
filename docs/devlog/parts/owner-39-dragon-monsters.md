# Owner #39, part: the Dragon Realm's monsters (shadow bats and wisp spirits)

Spec §14.2a ("Monsters: shadow bats … and wisp spirits …"), §6 (fair fun), §12.4–§12.5, §12.17, §14.1 (the flyer);
brief `docs/superpowers/briefs/prompt-own39.md` (a worker's part; the lead builds the portals and crystals, other
workers the realm's world and its boss). Built in an isolated worktree cut from the lead's branch
`worktree-agent-a317d3c66e402be33` (with the #39 spec commit), without the editor or the emulator.

## What was built

### Rules (`core/rules/monster_rules.gd`, section "Owner #39" and the tables)

| | HP (l = 1…5) | Hit | Gold | Speed | Attack |
|---|---|---|---|---|---|
| Shadow bat (flyer) | 3 + 2(l−1) | 1 + ⌊l/2⌋ | 3l | 3.8 + 0.2(l−1) | hovers over the child's side; wings flare, eyes brighten, a squeak for **1.0 s** (an ice bat 0.8: it is dark); dives at 8 m/s at the chest where the child stood; flutters low 1.4 s; then **flies up and away** (7 flat, 5 up on its side) and **rests 3 s** before it comes back |
| Wisp spirit (flyer) | 4 + 2(l−1) | 1 + ⌊l/2⌋ | 3l | 2.6 + 0.2(l−1) | floats 2.5 over the ground; keeps **7 blocks** from a child it sees (3 above their feet), watching them; from 4 blocks or further, with a clear line within 11, it lights up, chimes and grows a ring for **1.2 s**, then throws a **spark at 5 m/s** (slower than a walking child's 6) in a straight line at the chest where the child stands (no lead); a wall stops it; 3.5 s between sparks |

- `SHADOW_BAT` (`&"shadow_bat"`), `WISP` (`&"wisp"`), `DRAGON_KINDS` (the lead's `dragon.gd` uses it), in `KINDS` and
  every table (`KIND`, `HP_TABLE`, `GOLD_PER_LEVEL`, `hit`, `windup`); × 2^(u−1) through `universe_scale`.
- Pure helpers: `shadow_rest_spot`, `wisp_spot`, `back_off_spot`, `spark_aim` / `spark_time` / `spark_point` /
  `spark_hits`, `may_spark`, `cruise_height`, `over_void`, `lost_in_void`, `WINDUP_SOUND`.

### The monsters (`entities/monsters/monster.gd`, section "Owner #39" plus small hooks)

- Both use the ice bat's flyer code (a point to fly to ten times a second, steering, hovering while they signal,
  perception through `perceive()`: they attack only what they see). Hooks: `_strike` (a wisp throws instead of
  diving), `_fly_step` (a shadow bat's low flutter hands over to `_fly_away`), `_process` (`_animate_wisp`),
  `_animate_bat` (the signal's sound per kind), `_turn` (a wisp keeping its distance faces its target),
  `_hover_at` → `_open_side` (shared with the wisp's spot), `_physics_process` (`_fly_sparks`).
- **The spark** (the brief: "reuse the scorpion's spit machinery … or the archers' ShotPool — pick and say why"):
  **SpitGlob** (a `straight` flag, `end_at`) with a host-side flight in the monster (`_sparks`). Why: it lives with
  the monster (a wisp summoned anywhere throws, with no BlasterDirector needed), one shared mesh and the shared Fx
  burst like the scorpion's glob, and the host checks every step (a block is read only when the spark enters a new
  cell: a wall built while it flies stops it; the first child or bot friend it touches is hit, never an invisible
  one; where the child stood it fizzles). The ShotPool path was rejected: it belongs to the BlasterDirector (the
  archers' arrows go through `BlasterDirector.monster_arrow`, a node other worlds may not have), its looks and hit
  checks are the blasters' (a new look and team there = edits in M3 Task 14b's files), and its arrows fall with
  gravity; the spark flies straight and slow.
- **The void** (floating islands; for every flyer, the ice bat too): the ground look (three times a second) also
  says whether there is nothing within `BAT_LOOK_DOWN` under it (`_void`) or under where it goes (`_void_ahead`).
  Over the void a flyer keeps its height (its "ground" is its cruise height under it); wandering, it turns round at
  an island's edge and flies back to the last place it had ground under it (`_home`). Below `VOID_Y` (0) over
  nothing it is lost: the new signal `Monster.lost` → `MonsterDirector.puff` (a little cloud, no gold). A bat in a
  deep cave below y 0 has ground under it and stays.
- **Minds** (`MonsterSpecies`, one table per kind as for every monster; ten new hints): while a Dragon Realm flyer
  sees a child, its mind's tactic only moves where it flies (`_dragon_aim`): zigzag (a weave on the way), go round
  (to the side the child isn't looking), wait (it holds where it is; a waiting or weaving shadow bat swoops only
  from its usual spot), back off when hurt (up and away, no attack meanwhile), call (its sound; quiet friends near
  come with "?"). Speed, sight, hits and the signal are unchanged. (The ice bat keeps flying its own way.)

### Looks, sounds, words

- `MonsterModels` (section "Owner #39"): the **shadow bat** — dark violet body and round head, lilac eyes (in its
  arm mesh with the wings, so they light up with the wing flare as it signals: `SHADOW_EYES_LIT`, `SHADOW_FLARE`),
  ear tips and a belly patch of its level colour, l soft tufts, wings flapping by two shared meshes; the **wisp** — a
  pastel orb of its level colour with a tiny face (eyes, a smile, blushing cheeks), a glowing band of its level
  colour, l little flames, a soft trail (its arm), and while it winds up a lit body (`wisp_body`) and a ring round
  the orb (BALL boxes) that grows from 0.35 to full size over the signal; the **spark** (`spark_mesh`). All on the
  one shared vertex-colour material, two meshes per monster.
- Sounds (`tools/make_dragon_monster_sounds.py`, original, synthesised; credited in `assets/CREDITS.md`): `Audio`
  keys `shadow_squeak` (spots you / its signal), `shadow_flutter` (idle), `shadow_hurt`, `wisp_chime` (spots you),
  `wisp_charge` (its 1.2 s signal), `wisp_hum` (idle), `wisp_hurt`, `spark_pop`. `VoiceRules`: idle and hurt voices.
- `/summon shadowbat` and `/summon wisp` (1–5) in any Sandbox world: `ChatCommands.MONSTERS` has the words the child
  types, `MONSTER_WORDS` maps "shadowbat" to the kind; the chat line says "a level 2 shadow bat".
- Night spawns and Monster Wave's waves take any kinds (`MonsterRules.pick_kind`, `WaveRules.roster`,
  `ArcherRules.wave_roster` only touches goblins): the lead's descriptor `monster_kinds = MonsterRules.DRAGON_KINDS`
  is all universe 5 needs (tested with the directors and the rosters).

## Tests (RED → GREEN)

Suite (`tests/suite_slots.sh tests/run_tests.sh` on a snapshot of the staged index): **4502** after merging the
lead's branch (4501 passing; the one failure was `test_visit_world.gd`'s showcase tower, not touched here) →
**4538 of 4538**, exit 0.

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_dragon_monster_rules.gd` | 12 | `MonsterRules.SHADOW_BAT` / `WISP` / `DRAGON_KINDS` not found (parse errors) |
| `tests/integration/test_dragon_monsters.gd` | 24 | `MonsterModels.SHADOW_EYES`, `Monster.sparks_in_flight` not found; then 3 of the new tests: the shadow bat's rest was cancelled by a moment of "search" (fixed: the rest runs its time whatever it sees, to a spot fixed when it starts), the island test's player was half-seen from 24 blocks (the bats went to look; now an invisible player), the back-off test asserted past the tactic's commit |

Mutation checks (DEVELOPMENT.md §8), each run on the whole integration file, then restored:
- without `_fly_away()` the shadow bat stays near the child (2.3 blocks, not 5.5) and swoops again during its rest;
- without the per-step wall check the spark hits the child through the new wall;
- without the height kept over the void both flyers sink (31.0 from 41.5);
- without the turn at the island's edge they spent 767 steps over the void (with it: 0), the test's bound is 150;
- without the tactic pick in `_dragon_aim` the wisp never picks a tactic.

Changed shared tests: `tests/unit/test_chat_commands.gd` (the MONSTERS words go through `ChatCommands.monster_kind`).

## Cost (the brief: decisions ≤ 10 Hz, shared meshes, a flyer's step no costlier than the ice bat's)

`godot --headless --path . --script res://tools/dragon_monster_bench.gd` (20 of each kind round a walking player on
flat ground, 2 s blocks each in turn, 60 s; this thread's CPU time; load 25–35 from the other agents). Three runs
after the last change:

| 20 of | physics step, mean ms | p99 ms | looks (`_process`), mean ms |
|---|---|---|---|
| ice bat | 0.546 – 0.561 | 1.44 – 1.61 | 0.289 – 0.323 |
| shadow bat | 0.532 – 0.572 | 1.45 – 1.60 | 0.298 – 0.324 |
| wisp | 0.570 – 0.642 | 1.63 – 1.94 | 0.203 – 0.251 |

The shadow bat's step is the ice bat's. The wisp's is 3–15 % dearer (it always faces the child it keeps its distance
from, so every look finds it and casts the sight ray, and it flies its sparks), while its looks are 25–30 % cheaper:
per frame, step and looks together, the three cost the same (0.82–0.89 ms per 20). The first version was dearer
(0.63–0.69): the spark loop built temporary arrays and read a block every step; now it reads one only in a new cell
and looks closely only at bodies within 2 blocks. Baseline for scale: 20 walking goblins and slimes 0.9 ms a step
(M2 Task 4).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Both nip like the ice bat** (1 + ⌊l/2⌋) and have a bat's health (the wisp one more at level 1): "gentle".
   *Cost:* table entries.
2. **The shadow bat's signal is 1.0 s** (longer than the ice bat's 0.8, because it is dark) and **it rests 3 s up and
   away after every swoop**. *Cost:* two constants.
3. **The "dark" twist is only its colours**: nothing is hidden (unlike the candy sneaker); its eyes are the brightest
   thing on it and brighten before a swoop. "Glowing" is bright vertex colour on the shared material (an emissive
   material would compile a shader: DEVELOPMENT.md §8), so at night the eyes are bright but not lit. *Cost:* a
   shared emissive material for the eyes (one prewarmed shader).
4. **The spark has no lead** (the brief: "a moving child can dodge"), flies at 5 m/s (a walking child outruns it) and
   a wisp never throws from closer than 4 blocks. *Cost:* constants.
5. **The spark is SpitGlob with a host-side flight**, not the ShotPool (above). *Cost:* if the lead wants every
   projectile in one pool, a `monster_spark` in the BlasterDirector.
6. **The void rules apply to every flyer** (the ice bat too: summoned in a Dragon Sandbox world it would otherwise
   sink away). A flyer puffs away below y 0 **only with nothing under it** (a bat in a deep cave below y 0 stays).
   *Cost:* one condition.
7. **Their minds use the walkers' tactics, as steering of where they fly**; the ice bat keeps none (M3 Task 3).
   *Cost:* `_dragon_flyer()`.
8. **`/summon shadowbat`** (the kind is `shadow_bat`): a word map in ChatCommands. *Cost:* one entry.

## What the lead should check on the emulator

1. A Dragon Realm night (or `/summon shadowbat 3`, `/summon wisp 3` in any Sandbox world): the shadow bat reads as a
   bat in the dark (lilac eyes), its flare and squeak before every swoop, the swoop, then up and away; the wisp's
   bob, trail and face, its lit body, chime and growing ring, the spark's flight (dodge it by walking), a wall that
   stops it (the pop at the wall).
2. Floating islands: flyers stay over the islands, never sink into the void; one pushed off comes back.
3. Monster Wave in universe 5: waves of both kinds; the arena's Totem goal still draws them (flyers fly to it).
4. Performance: the autopilot with 20 Dragon Realm monsters in both styles (the bench's numbers are the desktop's).

## Merge notes (shared files, for the lead)

`core/rules/monster_rules.gd` (KINDS, `DRAGON_KINDS`, KIND/HP/GOLD entries, `hit`, `windup`, section at the end),
`entities/monsters/monster.gd` (`lost` signal, `_body_mesh`, hooks listed above, section at the end),
`entities/monsters/monster_models.gd` (`arm_mesh_for` glow per kind, `lights_up`, `arm_pivot_for`, `windup_angle`,
`boxes`, section at the end), `entities/monsters/spit_glob.gd` (`straight`, `end_at`), `world/monster_director.gd`
(one line: `m.lost.connect(puff)`), `core/mind/species/monster_species.gd` (ten HINTS), `core/rules/voice_rules.gd`
(two entries each), `core/rules/chat_commands.gd` (MONSTERS, `MONSTER_WORDS`, `monster_kind`, the usage line),
`scenes/chat_command_runner.gd` (the chat line's kind name), `autoloads/audio.gd` (eight keys), `assets/CREDITS.md`,
`tests/unit/test_chat_commands.gd`, `docs/DEVELOPMENT.md` (§4 subsection, §5 bullet), the spec §14.2a and the M3 plan
(one line each).
