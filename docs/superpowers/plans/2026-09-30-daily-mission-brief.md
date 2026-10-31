# The Daily Mission, postcards, gifts, crews and friendship levels — the agent brief (owner #81, #82, #85)

You are building the **"better together" half of the world game plan** in EasyCraft (Godot 4.7.2, typed GDScript; the
Nakama server module in `server/modules/`), an educational game for children. The owner: "we must bring more childrens
here because they will become educated … bring referal programs which include all possible motications", and (#85)
the research of the most successful programs. The invite program itself is built (codes, links, the Explorer Tree,
ranks, class and family codes: `core/invite/*`, `ui/invite/*`, server `referral_rules.ts`). Work autonomously; do not
ask questions (decide, and note rulings with what they cost if wrong in your notes).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, **`docs/superpowers/plans/2026-09-29-world-game-plan.md` (§1, §2, §2b, §3:
   your design)**, spec §25 (the core loop; §25.6 as built), the School (`core/school/*`: generators, `RoundPlan`,
   `ExerciseCheck`, mastery), EarnRules, the invite code (`core/invite/*`, `ui/invite/*`, `WebGlue.share`), photo mode
   (`ui/photo/*`: a picture of the world), showcases and gifts (M4 I: `core/gifts/*`), the online service.

## What to build (in this order)
1. **The Daily Mission** (Wordle's lesson): one short challenge a day, **the same for every player of a grade** (seeded
   by the UTC date and the grade: 5 exercises from that grade's generators across subjects), in the School's own panel;
   a star per first-try answer; gold by EarnRules (a daily line of its own); a **result card**: the date, the grade, the
   stars as a row of pictures, "Today's Mission: 4 of 5!", no answers, the invite code and link (the game draws it as a
   picture; SHARE uses the browser's share sheet or COPY; parents share it: "Grown-ups: share today's mission card").
   A calm streak that forgives (a missed day is a rest day, never a loss).
2. **Postcards at proud moments**: landing on a planet for the first time, a mission complete, a unit or a grade
   mastered, a wonder's stamp, a deposit found: a picture postcard (photo mode's camera, a frame and the words "I landed
   on the Moon!"), SAVE and SHARE, carrying the invite link; offered once at the moment, never nagging.
3. **Gifts** a friend opens in the game: send a rocket part, seeds, a buddy egg or a quest map piece to a friend (an
   in-game friend, or an invite link carrying the gift for a new player); THANK YOU sends a small gift back. Server:
   gifts held for the receiver, once, capped per day; nothing personal in them.
4. **Friendship levels** (Pokémon GO's lesson): learning together (both in one world, a lesson each the same day),
   gifts and cheers raise a friendship (good, great, best friends), each level opening a shared reward (a two-seat
   rover, a shared room in the colony dome later); **study buddies** (Duolingo's lesson): a shared daily goal with one
   friend that forgives a missed day; **cheers**: "Sam just landed on the Moon: send a cheer!" (one tap, kind words only).
5. **Crews** (belonging): a crew of 2-6 friends with a name (from the kid-safe name lists), a badge and a crew page
   (members' avatars and what each learned this week, never a ranking), the crew's weekly learning goal; the crew
   rocket and crew flights come with the missions later (hooks).
Everything within the fair-fun rules (`docs/design/`): no pressure, no timers that punish, no rankings of children, no
public lists of invites; the grown-ups' lines where sharing leaves the game.

## Allocation and rules
- New files: `core/daily/*`, `core/social/*` (pure rules), `ui/daily/*`, `ui/social/*`, server `src/rules/social_rules.ts`,
  `src/server/social.ts` (+ tests; bump the module version from the one on your base and say it), tests
  `tests/**/test_daily*.gd`, `test_postcard*.gd`, `test_gift*.gd`, `test_friendship*.gd`, `test_crew*.gd`, notes
  `docs/devlog/parts/daily-and-friends.md`. Small additions elsewhere. Never touch other running agents' files.
- PC mode (`PlatformRules.keyboard_first`), controllers (focus) and phones all work; new keys go on the KEYS card.
- TDD; `--import` and grep Parse Error; single tests; server `npm --prefix server/modules test`; the FULL suite once at
  the end (a `test_nakama_account_key.gd` or `test_audio_credits.gd` failure can come from other agents sharing the local
  server or user folder: rerun it alone). Never open the editor or an emulator; never touch adb; never deploy. Never
  merge or push. Never run more agents.

## Finish
Notes (rulings, the numbers, what a child sees, what the lead must deploy and check); the world game plan's "As built"
lines; spec §25; `docs/DEVELOPMENT.md`; `server/README.md`. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, the module version,
what a child sees, the tests' results, what the lead must look at.
