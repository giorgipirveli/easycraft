# M5 Task 4: store readiness (notes, 2026-09-25)

Plan `docs/superpowers/plans/2026-09-24-m5-launch.md` Task 4, spec §15.4 and §15.6. Built by a documentation agent in its
own worktree (branch `worktree-agent-a2379db1050627c76`, cut from `m2-survive-the-night`), `lead-merge` merged at the
start (release 0.4.0, `2a33c9e`), again at 17:3x (`35276e6`, 0.4.0 delivered from `15bfae0`), after the pause at 17:44
(`5de1890`: owner #52 English only, #51 MOBS, #53 weapons, M3 Task 15 tutorial, the M4 review's module 0.2.8) and last
before the final suite (`1be3c44`: M5 Task 1 accessibility, M5 Task 3 performance, the player card in every world with
module 0.2.9's `remove_guest`). No adb, emulator, godot-mcp, browser or Play Console. Mostly documents in `docs/store/`, plus
one code fix (F3). The owner's whole hand-off list is `docs/HANDOFF.md` (the lead's); this task's checklist is the
store's part of it and links to it.

## What was done

| Part | Where | What |
|---|---|---|
| The listing | `docs/store/listing.md` | The final texts, **English only** (owner #52): short **78** characters, full **3,334** (≤ 80 / 4,000, measured with `len()` on the text blocks), only what the game has, each line traced in "What each line rests on" (0.4.0's features; after it Pip's lesson, the MOBS page, weapons' strength, the accessibility settings, the PRIVACY page: it goes up with the first upload after 0.4.0). No other game's name, no storybook hero's name, no "free"/"best". The swap line for when the shop opens. #43's art direction and trademark note kept (`test_identity_words.gd` needs them) |
| Data safety | `docs/store/data-safety.md` | Every feature checked (trading, ghost races, presents, the costume code, quests, read-aloud, babble, bot chat, the Memory Book, photos, the books, boy/girl, looks, universes, Pip's tutorial, MOBS, weapons, accessibility settings, module 0.2.8, the player card with module 0.2.9, the shop, the Theater). **No data type changes.** The exact console fields to set (below) |
| IARC and Families | `docs/store/families-and-rating.md` | The answers as submitted, the ratings Google gave (Rated for 7+, PEGI 7, ESRB E10+ Fantasy Violence / Users Interact, USK 12, GRAC 12), each answer re-checked: **no change**; the safety tools named (module 0.2.8's stricter band; the player card's REPORT, BLOCK and REMOVE FROM MY WORLD); what changes later (the shop, the Theater). The target audience corrected to what was submitted (9–12 and up; the draft said 6–8) |
| Privacy | `privacy-policy.md`, `childrens-privacy-notice.md`, `delete-account.md`, `data-retention-and-security.md`, `trust-promise.md` | New data and places: secret codes (checked, never stored; a fingerprint of a code that worked and a wrong-try count), trades (relayed, not stored; the gold in the ledger), ghost races, Pip's lessons in the backup, photos in the phone's gallery, read-aloud through the phone's own voice, no AI service behind the bot friends, the Memory Book and the boy/girl choice on the device, "a place in the game is not your location", notifications 30 days, the age group never lifted by the game (a parent e-mails us), report, block and remove in every world; deleting only some data; REPORT or BLOCK on the children's card. Web pages regenerated with `tools/make_store_pages.py` (**the lead deploys them**) |
| Shot list | `docs/store/screenshots.md` | 8 screenshots in #43's order (wake, Size Magic, a golden portal with the Candy Kingdom, the Dragon Realm at sunrise, the dog digging, the barrel, a race, the Secret Book) with mode, universe, time and chat commands (or the MOBS page); the feature graphic (photo mode + a PIL composite with `assets/brand/wordmark.png`); the icon; spares (Pip's lesson, MOBS); captions (not burned in); Play's size rules |
| Pre-launch checklist | `docs/store/pre-launch-checklist.md` | 12 testers × 14 days (and a "what to try" note), the **production-access answers drafted** (brackets for what only the owner knows), the console changes, the legal and name checks, questions for the lawyer, the consent provider (KWS or PRIVO), Play Billing (optional), the game's own M5 steps, findings F1–F6 |
| Pointers | `docs/store/README.md`, `docs/store/play-console.md`, `docs/DEVELOPMENT.md` | The README's table and facts; the console change list in `play-console.md`; the PRIVACY page in DEVELOPMENT's parent-controls paragraph |
| **Code fix F3** | `ui/online/grown_ups_panel.gd`, `core/net/online_config.gd`, `tests/integration/test_grown_up_privacy.gd` | The privacy policy inside the app (below) |

## Console changes the owner or the lead must make (exact field → new answer)
**Main store listing** (Grow users → Store presence → Main store listing):
- Short description → `Build anything, wake it up and explore five magical universes full of secrets!`
- Full description → the 3,334-character block in `listing.md`, with the first upload after 0.4.0 (it names features
  0.4.0 lacks). No translations (owner #52).
- Graphics → the icon `docs/store/graphics/next/icon-512.png`, the new feature graphic and 8 screenshots
  (`screenshots.md`); remove the eight 0.3.2 pictures.

**Data safety** (App content → Data safety → Edit) — no data type added or removed:
- User IDs → purposes: App functionality, Account management, Fraud prevention/security.
- Other info → App functionality, Account management.
- Device or other IDs → App functionality, Account management.
- Other in-app messages → App functionality, **Fraud prevention/security** (a report keeps the reported message).
- Other user-generated content → App functionality, Account management, **Fraud prevention/security** (ghost races
  and builds go to friends; the backup restores progress; reports keep a copy).
- Other actions → **App functionality**, Fraud prevention/security (trades and co-op pass the relay; the ledger,
  reports, invites, limits).
- Every type: processed ephemerally → No; optional → yes; shared → **No** (ghosts, presents, trades go only to the
  player's friends at the player's choice: a user-initiated transfer, not sharing; no third party).
- Data deletion → "request that some or all data is deleted without deleting the account" → **Yes**, URL
  https://178-104-20-64.sslip.io/delete-account (its new "Deleting only some data").

**App access** (App content): "All or some functionality is restricted" with the instructions in `data-safety.md`
(choose 13 or older for online play; under-13 online needs consent, not available yet).

**Content rating (IARC) and Target audience:** **no change**. Trading items and earned gold between players is not
gambling (no money value, nothing random, both press READY); ghost races, presents and showcases are inside "Users
interact". Change later: digital purchases → Yes and "Contains in-app purchases" when the shop opens.

**Web pages:** deploy `server/deploy/site/` (regenerated; the live /privacy was older than the drafts: F6).

## Findings
| # | What | File and line | Done |
|---|---|---|---|
| F1 | Photo SHARE has no grown-up switch (M3 Task 16 ruling 7 asked for one in M4's parent settings) | `ui/photo/photo_mode.gd:214` (`share()`), `:449` (the chip) | **Fixed** 2026-09-25 (`docs/devlog/parts/safety-leftovers.md`): "Photo sharing" ON / OFF on the grown-up area's PLAY & PHOTOS page (was PLAY TIME), off by default for under-13, on for 13+; where it is off photo mode has no SHARE. Tests `test_photo_share_switch.gd`, `test_photo_share_grown_up.gd`. The lawyer's question stays (the 13+ default) |
| F2 | The Theater's WebView library is inside the Play bundle (Gradle build); off by the server switch | `addons/easycraft_webview/plugin.gd:34`, `export_presets.cfg` `[preset.4.options]` | **Ruling (the lead, 2026-09-25): kept.** The library only wraps the phone's own system WebView (no third-party SDK, no ads, no tracking) and loads nothing while the Theater is off by the server switch; the Families check comes before the owner switches the Theater on (`docs/HANDOFF.md` §5). Cost if wrong: a review question from Google; then leave it out of the Play preset (an export-plugin check of the preset's `theater_live` feature). |
| F3 | **No privacy policy inside the app** (Play's User Data policy) | `ui/online/grown_ups_panel.gd` | **Fixed here** (not in the 0.4.0 bundle, which was built before it) |
| F4 | The Play Age Signals plugin is not built (the game side is ready since M4 F) | `net/android_age_signals.gd:6` | Open (the lawyer decides; a Kotlin plugin) |
| F5 | The under-13 trade rule is checked by the host's game (a player's phone) | `autoloads/session.gd:4589`, `:4661` | Accepted (no money value; the child presses READY) |
| F6 | The public pages were behind the policy's Markdown | `server/deploy/site/` | Regenerated; the lead deploys |

(An F7, the grown-up tab row 1,278 px wide in Georgian, was withdrawn with owner #52: the game is English only.)

No gap in **deleting data** (ghosts, codes, trades, quests, the tutorial record and the books all go with the account,
on the server and on the device) and no missing **consent gate** (ghosts, presents, showcases server-checked; trades
F5).

## The code fix (F3)
- **PRIVACY** in the grown-up area's title row (the tab row is full: 1,206 of 1,224 px), so it is one tap from every
  page and needs no online account, like PLAY TIME: "Our promise to kids and parents" with the six promise lines
  (`GrownUpsPanel.PROMISE`, two columns), PRIVACY POLICY and DELETING DATA (they open `OnlineConfig.privacy_url()` /
  `delete_account_url()` through `open_url`, i.e. `OS.shell_open`, behind the parent gate), and "Questions or requests:
  parkingi-support@googlegroups.com" (`OnlineConfig.SUPPORT_EMAIL`).
- To keep every page inside the panel with the taller title row: tabs 64 px tall (`TAB_HEIGHT`, was 72) with 22 px
  words (`TAB_FONT`, was 26: a 26 px word makes a 64 px tab taller), the area's gaps 10 px (was 14), the title 30 px
  (was 34). The SHOP pages filled the panel to the pixel (534 of 534) and went to 551 with the first try, 541 with
  26 px words.

### Tests
- `tests/integration/test_grown_up_privacy.gd` (3): PRIVACY on every page, the promise, the e-mail, the button lit,
  the page fits; the two buttons open `…/privacy` and `…/delete-account` (and the URL is the one in Play Console);
  the paths are the ones the Caddyfile serves and `make_store_pages.py` makes, and the policy names the same page and
  address.
- RED: a parse error (no `PAGE_PRIVACY`, `PROMISE`, `SUPPORT_EMAIL`, `privacy_url`, …); then the shop pages 551/537/545 px
  tall in `test_shop_grown_up.gd` (the title row's +17 px); then green. After the English-only merge the Georgian
  width test went (Lang has no locales) and the shop pages were 541 px with 26 px tab words: 22 px again. The
  grown-up, shop, delete-account and settings tests: 46/46.

## Rulings (decided on the owner's behalf; cost if wrong)
1. **No Data safety type changes**; the purposes are listed in full so the lead can compare field by field (the
   submitted purposes are not recorded in the repo). *Cost:* none if the console already has them.
2. **Ghost races, presents and trades are not "shared"** (Play: a transfer the user starts and expects, to other
   users, is not sharing); they are "collected" because they pass our server. *Cost:* if the lawyer reads it
   otherwise, one answer per type changes.
3. **IARC unchanged:** trading is not simulated gambling (no money, nothing random). *Cost:* a re-rating.
4. **The listing says "No purchases"** (the shop is closed), with the line to swap when it opens.
5. **No storybook hero named in the listing** (the lawyer's check of #36 is open) and no "free". *Cost:* fewer
   search words.
6. **English only** (owner #52): no translated listing, notice or tester note.
7. **The listing goes up with the first build after 0.4.0** (it names Pip's lesson, the MOBS page, the accessibility
   settings, the player card and the PRIVACY page). *Cost:* the store keeps 0.3.2's words until that upload.
8. **Screenshots 16:9 (1920 × 1080)** by `wm size` on the emulator (Play's 2:1 limit rules out 2400 × 1080; 16:9 is
   what Play wants for featuring); a crop as the fallback. *Cost:* a layout difference between 20:9 and 16:9 (the HUD
   tests cover 16:9).
9. **No captions burned into screenshots** (the CC0-only rule covers fonts). *Cost:* plainer pictures.
10. **PRIVACY in the title row with the trust promise** (the tab row is full; spec §16 wants the promise at the top of
    the grown-up area). *Cost:* slightly smaller tab words for grown-ups (22 px).
11. **The privacy page opens our own web pages in the browser** (no in-game copy of the policy: one text to keep true).
    *Cost:* offline, the browser shows nothing; the promise and the e-mail still show.
12. **The production-access answers are drafts with brackets:** the owner fills in only what really happened.
13. **KWS first, PRIVO for a seal later** (KWS parent verification is free, per Epic). *Cost:* no safe-harbor seal at
    first.
14. **Photos and IP addresses are not declared** (the gallery and the share sheet are the child's own action; the log
    is for security only); both are questions for the lawyer.
15. **The age group:** the policy now says the game never lifts an under-13 account (module 0.2.8) and a parent
    e-mails us to correct it (the M4 review's ruling 1: the owner changes it in the Nakama console).

## For the lead
- Deploy the regenerated pages (`server/deploy/site/`), then check /privacy and /delete-account.
- Take the screenshots (`screenshots.md`), upload them with the icon and the feature graphic, paste the listing, make
  the Data safety changes.
- On the emulator with the next build: SETTINGS → GROWN-UPS → the gate → PRIVACY (the buttons open the browser on our
  pages); the other grown-up pages with the smaller tabs.
- Module 0.2.9 is live (22:55), so the regenerated pages can go up (the policy now says the host can remove a
  player).
- A stray file came in with `lead-merge` `65530da`: `easycraft@178.104.20-64` at the repository root (183 KB, the
  server kit's tarball from `kit.sh pack`, 79 files, `.env.example` only, no secrets): an `scp` whose target lost its
  colon (the "ls alias" gotcha). Delete it with a commit.
- Merge notes: `ui/online/grown_ups_panel.gd` (header lines, `PAGE_PRIVACY`, `PROMISE`, `TAB_HEIGHT`, `TAB_FONT`,
  `_ready`'s gap, the tab row's font/height, one line in `_show`, one branch in `show_page`, a section at the end),
  `core/net/online_config.gd` (three constants, three functions at the end), `docs/store/play-console.md` (a section
  at the end, after the lead's 0.4.0 entry).

## Suite
After the last merge of `lead-merge` (`1be3c44`) and `--import`: `tests/run_tests.sh` **633 scripts, 5,877 tests,
5,874 passing, 1 failing**, 2 risky (#45b's two tests that never assert), no script errors, 1,016 s. The one failure is
**not this task's**: `tests/unit/test_low_preset.gd::test_low_bursts_have_half_the_particles` (fails alone too, 14
expected 7). Cause: an integration clash in `lead-merge` between M5 Task 3's `Fx.particle_scale` and M5 Task 1's
`Fx.calm`: `Fx.burst` sets `p.amount = scaled(amount)` (7 on LOW), then `calm(p, amount)` (`entities/fx/fx.gd:46`)
recomputes from the raw `amount` and writes 14 back (`fx.gd:295-297`). A one-line fix for the lead:
`calm(p, p.amount)` (or `FeelRules.burst_amount(scaled(amount), …)`). This branch touches no effects code.
**The final suite** after merging `lead-merge` `65530da` (the lead's Fx fix: `test_low_preset.gd` gained its test):
**633 scripts, 5,878 tests, 5,876 passing, 0 failing**, 2 risky (the same two), no script errors, 983 s, exit 0.
The task's own tests: `test_grown_up_privacy.gd` 3/3; the grown-up, shop, delete-account, settings, English-only and
identity-words tests green.
