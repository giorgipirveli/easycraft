# Earn gold by learning, and invite a friend — the agent brief (owner #79; spec §25.1-25.2)

You are building **the earning and the invite (referral) system** of EasyCraft (Godot 4.7.2, typed GDScript; the server
is Nakama with a TypeScript module in `server/modules/`), a game for children. The owner: "to earn golds you have to
solve puzzles and lessons or invite someone new into game, so we need referal links and whole refereal system. if
someone invites and brings someone into game, they will get golds" — "the most important parts". Work autonomously;
do not ask questions (decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the online sections, the server, the tests), spec **§25 (your design)**,
   §22 (the School's mastery and its rules: no reward for opening a lesson or for time), §4 (the fair-fun rules) and
   `docs/design/` (engagement and child-psychology research: no pressure, no tricks), `server/README.md`.
3. Study what exists: the wallet (`core/economy/wallet.gd`, `wallet_sync.gd`, `wallet_report.gd`), the School's reward
   (`MasteryRules.UNIT_GOLD`, `ui/school/school_screen.gd`), the Lab's stars (`LabData`), the Secret Book's rewards
   (`BookPages`), codes (`core/codes/code_rules.gd`), the account and sign-in (`owner-67` notes: `account_key`), the
   server's economy and wallet rules (`server/modules/src/server/economy.ts`, `rules/wallet_rules.ts`), how the web
   page reads its URL (`web/shell.html`), the Play Store listing notes (`docs/store/`).

## What to build
1. **EarnRules** (pure, one table, TDD): gold for each first-try right answer in a School round (a few gold, a daily
   cap), a unit mastered (the existing 100, once), a Lab experiment's stars (once each), a secret or puzzle found (once
   each), never for time or for opening things. Wire each into the wallet where it happens, with the words the child
   sees ("+5 gold: right the first time!"). Keep Survivor's other ways of earning as they are.
2. **Invite codes and links**: every account has an invite code (kid-safe words and a number, e.g. BLUE-OTTER-42; no
   rude words: reuse the name filter), shown in a new **INVITE A FRIEND** page (the menu or SETTINGS: your ruling) with
   the link (`https://178-104-20-64.sslip.io/play/?invite=CODE`, the GitHub Pages link the same way), SHARE (the
   device's share sheet on Android via a small plugin-free route if one exists in Godot 4.7, else COPY and a QR code
   drawn by the game) and the rewards so far. A new player can type a code at the start (after the name) or in SETTINGS
   once; the web page passes `?invite=` in; on Android the Play Store's install referrer if it can be read without new
   native code (else typed; your ruling).
3. **The server decides** (the Nakama module; bump the module version from the one on your base and say it): RPCs to
   get my code, to use a code (a new account only, never my own, never twice), and the reward: when the invited player
   has **really played** (their first unit mastered, or play on two different days: your ruling in the rules' table),
   the inviter's wallet gets the reward once, the new player a welcome gift at once; a cap per month for an inviter;
   nothing personal stored beyond the two account ids and the dates; account deletion removes it (the existing
   deletion paths). Node tests for every rule (`npm --prefix server/modules test`).
4. **The referral design of the world game plan** (`docs/superpowers/plans/2026-09-29-world-game-plan.md` §1-§2: read
   it): the inviter is the friend's **mentor** (the friend's first missions name their guide; a Mentor star when the
   friend masters their first unit; Mentor of 5 and of 10 titles); the new friend's **welcome gift** (gold and a starter
   rocket part if the parts exist on your base, else gold); a bonus when the friend lands on the Moon (a hook the
   missions call later: `InviteRules.friend_landed`); milestones (1, 3, 5, 10 friends who learned: things to show, never
   power); **class codes and family codes** (one code a whole class or family joins with; a class goal can come later).
   **The Explorer Tree** (§2b): the server keeps who brought whom; your page shows your tree (friends, their friends)
   and its count of children learning; a small gift when a friend's friend learns (two levels, capped; the gold is
   the game's, nothing is taken from anyone). **Explorer ranks** (§2b: 1, 3, 5, 10, 25, 50, 100 friends who learned).
   Postcards, the Daily Mission card, gifts, crews and friendship levels are later briefs: leave hooks, not features.
5. **The Gold Shop's frame** (spec §25.5, owner #83): one page with shelves and `SpendRules` (one price table): Explorer
   lessons (a School unit may be marked `"bonus": true` with a price: buying opens it for good; the grade's own units
   stay free and open), weapons and tools that exist, avatar and buddy things; empty shelves with hooks for rocket parts
   (the missions agent fills them) and decorations. Add two or three Explorer lessons as the first bonus units only if
   time allows (else leave the flag and the test).
6. **Words and fairness**: "Your friend NAME joined and learned! +N gold" (the in-game name only); never pressure
   (no "invite or else", no timers, no streak loss); a grown-up line for the page ("Invite links carry no personal
   information"). A note in `docs/store/` for the owner's lawyer: a refer-a-friend reward in a children's app (Google
   Play's Families policy, COPPA; the design collects no data about the friend).

## Allocation and rules
- New files: `core/economy/earn_rules.gd`, `core/invite/*`, `ui/invite/*`, server `src/rules/invite_rules.ts`,
  `src/server/invites.ts` (+ tests), notes `docs/devlog/parts/earn-invite.md`. Small additions elsewhere.
- Never touch the rocket missions or the flight (other agents are building them now), the School's unit files, the
  worlds. No block ids.
- TDD: failing tests first (EarnRules, the invite rules in GDScript and TypeScript, the page, the start's code box).
  `--import` and grep Parse Error after new class_name scripts. Single tests with `tests/run_tests.sh -gtest=…`; the
  server's `npm --prefix server/modules test`; the FULL suite once at the end. Never open the editor or an emulator;
  never touch adb; never deploy the server or the web (the lead does). Never merge or push. Never run more agents.

## Finish
Notes (rulings, the numbers, the privacy design, what the lead must check on the emulator and live); spec §25 "As
built"; `docs/DEVELOPMENT.md`; `server/README.md` (the new RPCs). Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, the module version,
what a child sees, the tests' results, what the lead must deploy and check.
