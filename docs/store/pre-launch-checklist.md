# Pre-launch checklist: what must be true before "Apply for production"

Written by the M5 Task 4 agent on 2026-09-25 (spec §15.4, §15.6). Tick a line with the date and who did it. The
application itself: Play Console → Dashboard → **Apply for production** (it unlocks after the 14 days below). Google
reviews it (usually within 7 days), then the production track opens. **Nothing here is legal advice.** This is the
store's part of the owner's hand-off list, **`docs/HANDOFF.md`** (keys, lawyer, real phones, iOS): the steps there are
not repeated here, only pointed at.

Who: **O** = the owner (their accounts, their money, their yes), **L** = the lead (console and emulator, never at the
same time as the other app's session: `play-console.md` → "Sharing the console"), **W** = a lawyer.

## 1. Google's gate: 12 testers for 14 days (personal developer account)
- [ ] **O** At least **12 testers opted in continuously for 14 days** to the closed test "Closed testing - Alpha"
  (a personal account made after 13 Nov 2023 must do this; the Dashboard counts the days). State on 2026-09-25
  03:20: 0 opted in, 2 on the list. Aim for **15 or more** so one tester leaving does not break the 14 days.
  - Real people on real Android phones with their own Google accounts; never emulators, made-up accounts or paid
    "tester" services (they put the whole developer account at risk, and it also holds the Parkingi app).
  - **Done 2026-09-27: the track's testers are the Google Group easycraft-testers@googlegroups.com** (anyone can
    join; only the owner sees members). People open https://groups.google.com/g/easycraft-testers/about → Join group,
    then https://play.google.com/apps/testing/com.giorgi.easycraft on the phone → **Become a tester**, then install
    EasyCraft from Google Play (`reviewers-and-testers.md` §1, `play-console.md`).
  - Give testers something to do (below: "What to try"), so the engagement answer is true.
- [ ] **O** The testers get the newest build: the owner uploads the newest bundle to the closed test (0.4.0 was
  delivered on 2026-09-25 17:15; the release candidate 1.0.0 next), the lead fills the notes
  (`docs/HANDOFF.md` §1 has the steps; `docs/playtests/whats-new-<version>.md`).
- [ ] **L** Read the **pre-launch report** Google makes from that upload (stability, performance, accessibility,
  security) and fix what it flags; keep **Android vitals** free of repeating crashes and ANRs.
- [x] **L** Target API level: Google requires new apps and updates to target **Android 16 (API 36)** from
  31 Aug 2026. Godot 4.7.2's Android template targets 36 (`config.gradle`: `targetSdk 36`, min 24) (checked
  2026-09-25).

### What to try (a note for the testers; the owner sends it with the join link)
"Thank you for testing EasyCraft! Please play at least three times this week: 1) Survivor: start a new world and do
Pip's lesson, get through a night, trade with Tilly, build a portal to another universe; 2) Sandbox: build something,
tap it with the wand so it wakes up, try Size Magic, bring out a creature from the MOBS page; 3) if you are 13 or
older: PLAY ONLINE with another tester, trade and race a course. Tell us what was fun, what was hard and anything that
broke: the 'Send feedback' box on EasyCraft's Play page, or parkingi-support@googlegroups.com."

## 2. The production-access answers (drafts from the closed test; the owner fills the [brackets] with the truth)
Google asks these in the form (Play Console Help, "App testing requirements for new personal developer accounts",
checked 2026-09-25). Every answer must be true on the day it is sent: replace or delete what did not happen.

**Part 1 — About your closed test**
1. *How easy was it to recruit testers?* → [the owner's honest choice, e.g. "Neither easy nor difficult"].
2. *Tester engagement (did testers use the features; did their use look like production?):* "[N] testers, family,
   friends and parents with children aged [ages], played on their own Android phones for 14 days. They built and
   woke up buddies in Sandbox, played Survivor nights, travelled through portals to the other universes, did quests,
   and [N] of them played online together through our server with invited friends (trading and racing courses).
   Sessions were [15–40] minutes, mostly offline or with bot friends, which is how we expect families to play."
3. *Feedback and how it was collected:* "From the Play testing feedback, our support e-mail group and talking with
   the families. Testers told us the chat was hard to read while typing on a phone, that one animal sound was
   everywhere, that they wanted girl avatars, more animals, more secrets, portals to other worlds and a way to
   trade, and [other points from the testers]."

**Part 2 — About your app or game**
1. *Intended audience:* "Children about 9 to 12 are the core audience, and families play together; teens and adults
   play too. Target groups 9–12, 13–15, 16–17 and 18+, with a neutral age screen. Players under 13 play offline, at
   home over Wi-Fi and with bot friends; online play stays off for them until a parent gives verified consent."
2. *What makes the game unique:* "Anything you build can come alive: tap your build with a wand and it wakes up,
   blinks and follows you, and you can ride the dragon you built. Size Magic shrinks you into hidden mouse villages
   or makes you a giant, and golden portals lead to five universes with their own animals, quests and bosses. It is
   made for children: no ads, no loot boxes, nothing to buy in this version, bot friends that understand what you
   type, Pip the pet who teaches the basics in a playground lesson, and settings for bigger buttons, a left hand,
   bigger text and sound captions."
3. *Expected installs in the first year:* → [the owner's estimate; for a new game without marketing "0–10K" is the
   honest choice].

**Part 3 — About your production readiness**
1. *What you changed because of the closed test:* "0.3.3: a chat you can read while typing on a phone and quieter,
   more varied animal sounds. 0.4.0: girl avatars and storybook costumes; five universes through portals; quests;
   19 new animals to ride and befriend; trading between friends; races against a friend's best run; read-aloud and
   simple controls for younger children; our own look and icon. After 0.4.0: a first lesson with Pip for new
   players, a page to bring out any creature in Sandbox, weapons whose strength follows how hard they are to get,
   accessibility settings (button size, left-handed layout, movable buttons, text size, sound captions), stricter
   age rules on the server, a report, block and remove card for every player in a world, and our privacy promise
   inside the game. [Fixes from the pre-launch report and the testers' later feedback.]"
2. *How you decided it is ready:* "Every build passes our automated tests (about 5,600) and scripted play-throughs
   on an Android emulator in every universe and both graphics styles at 30+ FPS; the pre-launch report shows no
   crashes; [N] testers played for 14 days with no open crash in Android vitals; a lawyer reviewed our privacy policy
   and children's data practices; [the parental consent service is live / online play for under-13 players stays
   off until it is]."

## 3. The store page and the declarations (the console; `docs/store/`)
- [x] **O** approves, **L** pastes the **listing** (`listing.md`: short 78 characters, full 3,334; English only, owner
  #52: no translations) with the first upload after 0.4.0 (it names Pip's lesson, the MOBS page, the accessibility
  settings and the PRIVACY page, which 0.4.0 lacks). Done 2026-09-27 01:15 (the owner's "do all of them"), sent for
  review 01:25 (`play-console.md`).
- [x] **L** uploads the new **icon** (`graphics/next/icon-512.png`), the **feature graphic** and **8 screenshots**
  (`screenshots.md`). The icon: 2026-09-27 01:20 (approved, live). The feature graphic and the 8 screenshots:
  2026-09-27 02:55, sent for review (`play-console.md`).
- [x] **L** makes the **Data safety** changes (`data-safety.md` → "What the lead or the owner changes": purposes,
  the partial-deletion question, App access instructions). No data type changes. Done 2026-09-27 01:25 (App access
  is now called "Sign-in details"), sent for review.
- [x] **Content rating (IARC):** no answer changes (`families-and-rating.md`); re-submit unchanged only if Play asks.
- [x] **Target audience:** no change (9–12, 13–15, 16–17, 18+; Families policy).
- [x] **L** deploys the regenerated **web pages** (`python3 tools/make_store_pages.py` → `server/deploy/site/`,
  then the kit's `update` on the server; finding F6) and checks https://178-104-20-64.sslip.io/privacy and
  /delete-account show "Last updated: 25 September 2026" and "Deleting only some data". Checked live 2026-09-27.
- [x] Developer name "API Studio" (verified 2026-09-25); contact e-mail; privacy policy URL; ads: none.
- [ ] **O** sends a test e-mail to parkingi-support@googlegroups.com from an outside address and sees it arrive
  (parents' deletion requests come here).

## 4. Legal and names (before the production release; the lawyer can do them in one visit)
- [ ] **W** reviews `privacy-policy.md`, `childrens-privacy-notice.md`, `data-retention-and-security.md` and the
  Data safety answers; the owner fills `[OWNER NAME]` in the retention policy and adopts it.
- [ ] **O/W** the **trademark search for "EasyCraft"** (`listing.md` → the steps; classes 9 and 41; USPTO, EUIPO or
  TMview, WIPO, Sakpatenti; Play and the App Store). Write the result into `listing.md`.
- [ ] **W** #36's storybook costume names (Sherlock Holmes, Aladdin, Pinocchio, Hercules and the rest in
  `docs/devlog/parts/owner-36-costumes.md`): public domain where we sell, no film-only details.
- [ ] **W** "For the lawyer" below.

### For the lawyer (questions the drafts leave open)
1. **Age signals:** Texas (SB2420), Utah and Louisiana's app-store laws and Brazil's Digital ECA (the game is
   offered in 177 countries). Google's **Play Age Signals API** returns an age range for users in those places; the
   game can map it to our bands (only ever stricter) but its Android plugin is not built yet (finding F4). Is our own neutral age screen enough, or must the game read the store's
   signal (and, for Texas, a parent's approval) before launch?
2. **IP addresses** in the server's access log (14 days, security only): declare them in Data safety or not?
3. **Photo sharing** (finding F1, fixed 2026-09-25): off for under-13 players until a parent turns it on in the
   grown-up area (PLAY & PHOTOS, behind the parent gate), on by default for 13+ (a parent can switch it off). Is on by
   default for 13+ right for a mixed-audience game, or should it be off for everyone until a grown-up says yes?
4. **Trading between under-13 friends** (in-game items, no money): anything to add to the notices?
5. **The trust promise** ("No ads, not now and not later"): fine as a public promise?
6. **Countries:** anything special for the EU (GDPR-K ages 13–16 by country: our "under 13" band follows COPPA),
   the UK Children's Code (a DPIA?), Georgia?

## 5. Parental consent for under-13 online friends (optional for launch; online stays off for them until it is done)
The server already has the whole flow (`consent_start` → the provider → `consent_status`, spec §17.2), with a fake
provider for development; production answers "consent_unavailable" and the grown-up area says so. To open it:
- [ ] **O** chooses and registers a provider:
  - **Epic Games' Kids Web Services (KWS)** — parent verification, free for developers (no upfront or per-parent
    cost, per Epic), used by large children's games; register through Epic's developer portal (Epic Online
    Services), get the KWS credentials.
  - **PRIVO** — verification plus a paid **COPPA safe-harbor** programme (a seal parents recognise, an outside
    audit); costs money.
  - Recommendation: **KWS first** (free, enough for verifiable consent); PRIVO or kidSAFE later if the owner wants a
    safe-harbor seal.
- [ ] **L** builds the server adapter for that provider (`EASYCRAFT_CONSENT_PROVIDER`, `server/README.md`; the
  parent's e-mail is passed on and never stored) with tests, and checks it on the live server with a real parent
  account.
- [ ] **W/L** name the provider in `privacy-policy.md` ("Service providers") and the children's section; regenerate
  and deploy the pages.
- No store answer changes (`families-and-rating.md` → "Later").

## 6. Play Billing (optional; the game launches without it)
The shop is built and closed (owner #35, spec §18: EasyCraft Plus and cosmetic packs, bought only by a grown-up
behind the parent gate). To open it:
- [ ] **O** sets up a **payments profile** (merchant account) in Play Console and checks it can be made from Georgia.
- [ ] **O** creates the one-time products (EasyCraft Plus and each pack) with their prices; **L** puts their ids into
  `core/shop/shop_catalog.gd` `PLAY_IDS` and adds the Godot Google Play Billing plugin to the "Android Play" preset
  (`core/shop/play_billing.gd`).
- [ ] **L** tests with Play's license testers (no real money), then in the same release: Data safety "Purchase
  history", IARC "digital purchases: Yes", the listing's "Contains in-app purchases" and its "No purchases" line
  (`listing.md` → "When the shop opens"), the privacy policy's "Today the shop is not open" sentence.

## 7. The game itself (M5; the lead)
- [ ] The acceptance runs on the emulator (M3 Task 18, M4 Task 9, with the agents' checklists), the whole-game
  review (M5 Task 6), release candidate 1.0.0 (M5 Task 5). (Pip's tutorial, M5 Task 1 accessibility and M5 Task 3
  performance are merged.)
- [x] **L** module **0.2.9** (`remove_guest`: the host's REMOVE FROM MY WORLD online; spec §17.3) live on the server
  since 2026-09-25 22:55 (the live removal test passed); now the regenerated web pages can go up (§3).
- [ ] **L** the next upload after 0.4.0 carries F3's PRIVACY page (0.4.0 was built before it); on the emulator: SETTINGS → GROWN-UPS → the gate → **PRIVACY** (the promise, PRIVACY POLICY and
  DELETING DATA open the browser on our pages) (F3).
- [ ] **O** the real-phone check and the child playtests (spec §15.6).
- [ ] **L** keep the **Shorts Theater off** in production (F2) until its Families check is done.

## Findings (M5 Task 4, 2026-09-25)
| # | What | Where | Risk | Done |
|---|---|---|---|---|
| F1 | **Photo SHARE has no grown-up switch.** M3 Task 16's ruling 7 asked for "M4's parent settings" to be able to hide SHARE; the parent settings have online play and chat only. A photo (maybe with online names on it) goes to any app the child picks. Nothing reaches us | `ui/photo/photo_mode.gd:214` (`share()` → `PhotoShare.share`), its SHARE chip at `:449`; the parent settings `ui/online/grown_ups_panel.gd` `_settings_view` | Low (the child's own action; no data to us). A switch on the device ("Photo sharing ON/OFF" in the grown-up area) is a UI task for M5 Task 1/6 | **Fixed** (2026-09-25, `docs/devlog/parts/safety-leftovers.md`): the grown-up area's PLAY TIME tab is PLAY & PHOTOS with "Photo sharing" ON / OFF (`ProfileData.photo_share`, `PhotoRules.may_share`: off by default for under-13, on for 13+); where it is off photo mode has no SHARE and only saves to the gallery. Tests `test_photo_share_switch.gd`, `test_photo_share_grown_up.gd`. Ships with the next APK; the lawyer's question §4.3 stays (the 13+ default) |
| F2 | **The Shorts Theater's WebView library is inside the Play bundle.** The export plugin adds it to every Android export with Gradle on, and "Android Play" has Gradle on. It is off by the server's switch, so nothing loads | `addons/easycraft_webview/plugin.gd:34` (`_get_android_libraries`), `export_presets.cfg` `[preset.4.options]` `gradle_build/use_gradle_build=true` | Low today; before switching the Theater on: the Families policy's rules for embedded content and ads, and the "shared" answers (`data-safety.md` → "Later"). Leaving it out of the Play preset would also save size (M5 Task 3) | Open |
| F3 | **No privacy policy inside the app.** Play's User Data policy asks for it in the app as well as in the console; the children's notice and the trust promise were not in the game either | `ui/online/grown_ups_panel.gd` | Medium (a policy finding at review) | **Fixed** on this branch: PRIVACY in the grown-up area's title row, on every page: the trust promise and PRIVACY POLICY / DELETING DATA buttons that open our pages (`OnlineConfig.privacy_url`, `delete_account_url`); test `tests/integration/test_grown_up_privacy.gd` (4). **Not in the 0.4.0 bundle** (built from `15bfae0` before the fix): it ships in the next upload, which should come before "Apply for production". The children's notice card with pictures stays M5 art work (`childrens-privacy-notice.md`) |
| F4 | **The Play Age Signals plugin is not built** (spec §5.14, §17.2 "store age signals"). The game side is ready since M4 F: the mapping (`core/validation/age_signals_rules.gd`, only ever stricter), the adapter and its plugin contract (`net/android_age_signals.gd:6`, the TODO: "the plugin is not built yet … only a Gradle build can add" the Play library). The "Android Play" preset **is** a Gradle build now (owner #46), so the plugin (`com.google.android.play:age-signals`, a Godot v2 plugin like `android/plugins/easycraft_webview`) can go in | `net/android_age_signals.gd:6`, `android/plugins/` | Depends on the lawyer (§4 question 1); a Kotlin plugin and a Gradle export, not a small fix | Open |
| F5 | **The trade age rule is checked by the host's game**, which is a player's phone; a modified host could skip "under 13 trades online only with friends" (#37 ruling 13). The server relays trades and cannot see them | `autoloads/session.gd:4589` (`host_trade_ask`) and `:4661` (`host_trade_friends`: each game reports its own friends) | Low (items with no money value; the child still sees both sides and presses READY; under-13 online needs consent and invited friends) | Accepted; noted for the lawyer (§4 question 4) |
| F6 | **The public pages were behind the policy's Markdown** (the shop and ghost-race paragraphs were missing from `server/deploy/site/privacy/index.html`), so the live page is older than the drafts | `server/deploy/site/` | Low | Regenerated on this branch; **the lead deploys** (§3) |

No gap was found in **deleting data**: every new kind of data in 0.4.0 goes with the account (ghosts: the server's
`ghosts` collection in `Deletion.COLLECTIONS` and `user://ghosts.json` in `OnlineService.online_files`; codes: the
`codes` collection; trades: nothing stored but the gold ledger, which Nakama deletes with the account; quests and
the books: the profile backup). No missing **consent gate** either: ghosts, presents, showcases and trading all check
the under-13 rules (server-side for everything stored; F5 for the relayed trade).
