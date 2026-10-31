# M3 Task 15 — the tutorial with Pip (spec §14.9, §5.10; the LAST M3 feature task)
(House rules: `docs/superpowers/briefs/m3-common.md` + `owner-common.md`. Start from main after the night's merges.)
Read spec §14.9 and §5.10, `docs/devlog/parts/m3-task-11.md` (Pip is a pet: `PetRules.give_pip(profile)`,
`sandbox.bring_pip()`), M2 Task 3's first-time picture hints, the HUD (`ui/hud/hud_layout.gd`, MORE panel), the
Monster Wave and Survivor-games notes (Survivor has **no Totem waves any more**, owner #44), crafting (#34),
the adventure board (Task 12) and bot chat (#38).
Build, test-first:
1. The **first Survivor start** offers the tutorial: PLAY WITH PIP / SKIP. Skipping gives no reward and is never
   asked again (a SETTINGS → "Tutorial" button replays it, with no second reward). Pip, the small robot, walks
   beside the child and shows each step with a picture bubble and very short words (read aloud when M3 Task 21a
   arrives, so give every line an id), icon-first:
   move and look → triple-jump a gap → build a 3-block bridge → break a wall → hide from a harmless practice
   slime in a bush (it can't hurt: a practice monster) → craft a stick at a crafting table (spec §12.19) → visit
   Tilly and see the SHOP arrow. (Tapping a Totem is out: Survivor has no waves.)
2. The steps happen in the real world near the spawn, placed by pure rules: flat ground, never into water or
   the Theater, clear of the treasure pack's 60-block spawn rule. Nothing is saved into the world after the
   tutorial ends; the practice props disappear.
3. **Reward** (spec): 500 Survivor gold (fixed), a free hat (`AvatarCatalog.EARN_TUTORIAL` exists), and **Pip
   becomes the first pet** (`give_pip`). Once per profile.
4. It can be stopped at any time (a small X): nothing lost, it resumes from the step it stopped at. No timers.
   The tutorial never runs in LAN or online games (solo only), and never in Sandbox or Monster Wave.
Tests: the step order and each step's check (real player actions), placement rules, skip never asks again, the
reward only once, resume, solo only, and a headless smoke run on real terrain doing every step with simulated
input. Notes: `docs/devlog/parts/m3-task-15.md`. Suites through the slot gate: `tests/suite_slots.sh tests/run_tests.sh`.
