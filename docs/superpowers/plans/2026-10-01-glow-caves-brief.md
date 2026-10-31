# Universe 6, the Glow Caves — the agent brief (spec §5.1; the forever roadmap §3, §4 and §6)

You are building **the Glow Caves**, universe 6 on EasyCraft's ladder (Godot 4.7.2, typed GDScript, Voxel Tools), a game
for children. The owner: "make the game such an interesting that to unlock new universes people will be ready to pay
money later" (#72), "closer to real worlds so the player starts learning real things … more secrets, more excitements"
(#74). The Star Map already shows it ("Explorers are building it now"); EasyCraft Plus (built, its shop off until the
owner opens it) covers every universe after the first two. Work autonomously; do not ask questions (decide, and note
rulings with what they cost if wrong in your notes file).

## 2026-10-17: what changed since this brief was written (the lead; this section wins over the rest)
- **Start:** your worktree is cut from lead-merge (check `git log -1`); do not `git reset`; just
  `nice godot --headless --path . --import`.
- **Allocation moved:** block page 44 is now the music page (owner #110: ids 752-753 used, 754-767 kept for more
  instruments). The Glow Caves take **page 45, ids 768-783**; move `BlockIds.COUNT` past what you use and
  `NEXT_PAGE_FIRST_ID` to 784 (update its comment and the pages' list above it). Universe **6** on the ladder is still
  free (the ladder has 5).
- **The pages' budget:** the music page came after Ganymede's 68.3 MB. Measure first (`tests/unit/test_page_sizes.gd`);
  a three-row page without alpha adds ~1.6 MB. If it does not fit, raise the budget with a ruling that gives the APK's
  and the web download's growth (`tools/export_web.sh` locally only, never deploy).
- **Running beside you now:** **Play G0** (`core/play/*`, `entities/play/*`, `ui/play/*`, `data/play/*`,
  `ui/school/school_screen.gd`, `ui/school/school_grown_ups.gd`, the menu's School button in `ui/menus/menu.gd`,
  `core/school/curriculum.gd`) and **Success S3** (`core/success/*`, `entities/success/*`, `ui/success/*`,
  `data/success/*`, Life Town's hooks). The learning reels and visuals agents named below are finished and merged.
  Don't touch the School, Life, Success or the play layer.
- **Learning is play (owner #122, 2026-10-17; `docs/design/learning-is-play.md` §3, the authority):** the caves' real
  science must be learned by doing, not read on a card: the concept is the move that wins. For example, the child
  carries glow moss or a spore lamp to light a path (bioluminescence: light without heat, as the glow-worms' blue
  ceiling shows); a stalactite grows drip by drip when the child times the drips (how slowly caves grow); the bats'
  echoes find the way through a dark tunnel (echolocation: the echo's delay tells the distance); acid rainwater
  carves a passage in limestone the child opens (how caves form); blind cave fish in a lake show why eyes are not needed
  there. A short fact may follow the play as one line (the "see why" step); the Cave Book or the Secret Book's page
  keeps what was found. In your notes, name for each fact the move that teaches it.
- **VR:** the Glow Caves must work on the Meta Quest 3 too (`docs/superpowers/plans/2026-10-15-vr-quest.md`, `2026-10-16-vr-p5-brief.md` and DEVELOPMENT.md's VR section:
  its budget and P5's levers); the soft blue-violet dark must stay readable in the headset (no pitch black; the glow
  shows the way); no fast camera moves.
- **Commits** end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (not the 1M-context line below).
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way. Right before your final full suite, merge
  lead-merge and run the suite on that merged tree. No downloads (CC0 textures you need: make them yourself, or report
  what you would download and why).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the Dragon Realm's sections: the realm, its monsters, the Sky Dragon; the
   block pages and their budget; the shader warm-up and its census rule; performance §7), spec §5.1-§5.3, §5.7, §3c
   (friendly, never scary), §14.2a (how the Dragon Realm was specified), `docs/design/` (the fair-fun rules).
3. **The model is the Dragon Realm (universe 5)**: read end to end `world/universes/dragon.gd`, `dragon_blocks.gd`,
   `world/generators/dragon_generator.gd`, `dragon_secret_rules.gd`, `core/rules/sky_dragon_rules.gd`, its monsters in
   `MonsterRules.DRAGON_KINDS`, `BossRules.SKY_DRAGON`, `world/boss_director.gd`, `tools/dragon_smoke.gd`, and how
   `UniverseRegistry.LADDER`, `ShopCatalog` (free universes), `StarMap` (`universe_6`), the hub cards, the Survivor
   scaling (gold and monsters × 2^(u−1)), Monster Wave's arena and the Secret Book find a universe by its number.

## Allocation (fixed)
- Universe **6** (`UniverseRegistry.LADDER`'s sixth entry, name `&"glow"`, display "Glow Caves"), block atlas page
  **44**, block ids **752-767** (`BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` move past them; check the page and ids are free
  after Ganymede's page 43, 736-751). New files: `world/universes/glow.gd`, `glow_blocks.gd`,
  `data/blocks/pages/glow.png` (+ its realistic twin), `world/generators/glow_*.gd`, `core/rules/glow_*.gd`, its monsters'
  and boss's files, tests `tests/**/test_glow*.gd` and `test_spore_mother*.gd`, a smoke `tools/glow_smoke.gd`, notes
  `docs/devlog/parts/glow-caves.md`. Small hooks in the registry, `MonsterRules`, `BossRules`, the boss director, the
  Star Map's `universe_6` card (real facts; LAND/PLAY instead of "being built"), the Secret Book.
- Other agents now: **learning reels** (`data/shorts`, `core/shorts`, `ui/shorts`) and **visuals** (shaders and
  materials of the world, sky, water, `GraphicsPreset`, `world/look/*`). Don't touch their files. Never touch the
  School, the cosmos worlds or the Star Map UI beyond the lines above.

## What to build
- **The world:** caves that are a joy to explore, not a fear: big open caverns with high ceilings and wide passages,
  lit by glowing mushrooms, glow-worm ceilings (the real New Zealand glow-worms' blue "starry sky"), crystal halls
  (giant gypsum crystals, as in the real Cave of Crystals), underground lakes with blind cave fish, stalactites and
  stalagmites, a waterfall, shafts of daylight down to the surface (a surface exists above: the way in). Never truly
  dark: the darkness is soft blue-violet, and the glow always shows the way (spec §3c). Its own sky rules, ambience
  (existing loops and classical pieces only; no new audio unless CC0) and music choice.
- **The blocks (16):** cave stone, glow moss, glowing mushroom stem and caps (two colours), glow-worm ceiling, gypsum
  crystal (cutout, glows softly), flowstone, a stalactite/stalagmite block, cave lake stone, fungus planks, a spore lamp,
  a cave-pearl, the treasure's block and a fake wall (as the realm's); none in the Sandbox palette unless the realm's
  rule says otherwise. Both styles (blocky atlas and the realistic twin from CC0 sources, credited). The realistic
  pages' budget (`test_page_sizes.gd`) is 68.3 of 70 MB after Ganymede and a page adds about 1.6 MB: keep the page to
  three rows without alpha where you can, raise the budget to 72 MB only if it does not fit (a ruling with the APK's and
  the web download's growth).
- **The monsters (stealth, spec §5.2's "sneaker"):** 2-3 kinds that fit the caves and stay friendly-looking (e.g. spore
  puffs that hide in the dark and show when the child's light or a glowing block is near; cave crawlers; a flyer):
  levels 1-5 by shape and colour, the visibility and noise meters matter more here (light makes the child visible, a
  crouch in the dark hides). Cartoon only: they burst into coins and confetti.
- **The boss, the Spore Mother:** a giant glowing mushroom creature in a domed cavern arena, clearly signalled attacks
  (spore clouds that slow, not hurt much; puffs that hide her), weak spots that glow when open; health scales with team
  size; the BossRules pattern (signals, arena, rewards, the Secret Book page). Beating her is the ladder's next step.
- **Learn real things (#74):** each find and sight ends with a real fact for 8-14-year-olds, checked against sources
  (NOAA, National Geographic, USGS, national park services; list them in the notes): how caves form (rainwater, a weak
  acid, dissolves limestone), how stalactites grow (drip by drip, a few centimetres in a hundred years), why cave fish
  are blind, how bats find their way (echolocation), bioluminescence (glow-worms, foxfire fungus, the light without
  heat), the Cave of Crystals' giant gypsum, the longest cave system. A short "Cave Book" or the Secret Book's page.
- **Secrets (spec §5.7):** hidden chests behind fake walls, a crystal puzzle, a riddle note, a golden monster, a hidden
  grotto; the treasure pack's own style.
- **Worth paying for (#72, §4):** a free peek from the Star Map and the hub card (a few seconds' look inside) when it is
  locked; never pressure, no tricks (the fair-fun rules).
- **Fast:** the generator no slower than the Dragon Realm's (bench: `tools/bench_generator.gd`); glowing blocks lit by
  the mesher's light or emission, **no real lights per mushroom**; at most about 20 monsters; the emulator budget (≥ 30
  FPS, no frame over 100 ms) in mind: few materials, every new material in the shader warm-up's census (the sources test
  guards it; the census's steps visit the new universe: `tools/shader_probe_steps.gd`).

## Tests and checks (TDD)
- Failing tests first (descriptor, ladder of 6, blocks in both styles, the generator's caves: open, lit, every step
  climbable, the way out; secrets; monsters and boss rules; the Star Map card; the shop's Plus line covers it). `--import`
  and grep Parse Error after new class_name scripts. Single tests with `tests/run_tests.sh -gtest=…`. The smoke must print
  0 fails (a private XDG_DATA_HOME containing "smoke"). The FULL suite once at the end.
- **Look at it:** pictures in a real window (`tools/space_shots.gd`'s or `tools/look_shots.gd`'s pattern; under `nice`,
  one at a time), both styles; fix what looks cheap or scary; say what you changed.
- Never open the editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
- Notes (rulings, facts with sources, the bench, pictures' paths, what the lead must check on the emulator); spec §5.1
  "As built" row; `DEVELOPMENT.md` (the Glow Caves section with its commands). Commits ending with
  `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Report: branch, commits, what a child sees, the bench, the smoke and full-suite results, what the lead must look at.
