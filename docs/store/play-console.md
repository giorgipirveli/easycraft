# Google Play: how EasyCraft versions are uploaded (owner feedback #46, #47)

The owner (2026-09-24 22:20): "i have google play developer acount … please use it and for updating versions use
the console". The owner's Play developer account also holds **another app of theirs: never touch it.**

## Decided (rulings; the cost if wrong)
| What | Decision | Cost if wrong |
|---|---|---|
| Package name | `com.giorgi.easycraft` (preset "Android Play"; `test_play_preset.gd`) | Play never allows a change after the first upload. Players don't see it. The developer APKs keep `com.giorgi.game`, so a phone can have both. |
| Signing | **Play App Signing** (Google keeps the app signing key). We sign uploads with our **upload key** | If the upload key is lost, Play support can reset it (a few days) |
| Upload key | `~/.local/share/godot/keystores/easycraft-upload.jks` (PKCS12, alias `easycraft-upload`, RSA 4096, 10,000 days). Its password is in `~/.config/easycraft/upload-key.env` (mode 600). **Never in git.** | The owner keeps a copy of both files in their password manager |
| Format | Android App Bundle (`.aab`, Godot's Gradle build), arm64-v8a only | 32-bit-only tablets can't install it. Add `armeabi-v7a` if the owner wants them |
| First track | **Internal testing** (up to 100 testers by email, no review wait, not public) | — |
| Testers (#47) | [tester 1's Gmail], [tester 2's Gmail] (the owner, 22:24; the addresses are kept privately in `~/.config/easycraft/testers.txt`, never in git, since the source is public) | — |
| Version | Every upload raises `version/code` (all presets, `test_release_version.gd`) | Play refuses a code it has seen |

## Build the bundle
```bash
set -a; . ~/.config/easycraft/upload-key.env; set +a
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$EASYCRAFT_UPLOAD_KEYSTORE \
  GODOT_ANDROID_KEYSTORE_RELEASE_USER=$EASYCRAFT_UPLOAD_ALIAS \
  GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=$EASYCRAFT_UPLOAD_PASSWORD \
  JAVA_HOME=$HOME/.local/jdk17 ANDROID_HOME=$HOME/android-sdk
godot --headless --path . --install-android-build-template --export-release "Android Play" build/android/EasyCraft-play.aab
```
The first Gradle export downloads its tools. `android/build/` is git-ignored.

## Upload a version (Play Console, in the browser)
1. https://play.google.com/console → the EasyCraft app (created once: name "EasyCraft", game, free, the
   declarations need the **owner's yes**).
2. Testing → Internal testing → Create new release → upload `EasyCraft-play.aab`. The release notes come
   from `docs/playtests/whats-new-<version>.md`, shortened.
3. Save → Review release → Start rollout to Internal testing.
4. Testers (once): Internal testing → Testers → an email list with the two addresses above. Copy the opt-in
   link and send it to the owner.

## Needed before the store (not for internal testing)
Store listing (`docs/store/listing.md`), content rating (IARC: `docs/store/families-and-rating.md`),
target audience and Families, Data safety (`docs/store/data-safety.md`), and a privacy policy URL. The policy
(`docs/store/privacy-policy.md`) is a draft for the owner's lawyer. It is served from our server once the
owner's details are filled in.

## Sharing the console (the owner, 22:32: "consider there is another process using console now")
The Play Console account (developer name **"Parkingi"**, a personal account, id 7471453960475553489) is also used by
another session that publishes the owner's other app. Never work in the console while that one does. Only one
Claude session can use the Chrome extension safely at a time. Before a console step, check that the console is free;
if in doubt, save the step here and do it later. Note: Google Play shows the developer account's name on the store
page, so EasyCraft would read "by Parkingi" unless the owner changes the developer name.

## State
- 22:30: the upload key was made; the "Android Play" preset added (0.3.2, code 7); the first bundle is building.
- 22:31: the Create app form was filled (EasyCraft, `com.giorgi.easycraft`, Game) and **not submitted**: another
  session was using the console. The form was closed without saving. Still to do: create the app. It needs the owner's
  yes to three declarations (Developer Programme Policies, Play app signing Terms of Service, US export laws).
- 22:47: the owner uploaded the 0.3.2 bundle to **internal testing**; the lead rolled it out ("Available to
  internal testers"). The join link for the two testers: https://play.google.com/apps/internaltest/4701687062099278326
- 22:50–23:47, all declarations and settings, in the console:
  - **App content:** privacy policy URL https://178-104-20-64.sslip.io/privacy; Ads: none; Sign-in: no
    restrictions; Advertising ID: not used (the manifest has only INTERNET, ACCESS_NETWORK_STATE, VIBRATE).
  - **Content rating (IARC):** Google Play "Rated for 7+", PEGI 7, ESRB Everyone 10+ (Fantasy Violence, Users
    Interact), USK 12, GRAC 12. The answers: fantastical violence against non-humans, pixel/childlike style,
    unrealistic reactions, no blood, humanlike creatures (goblins, mummies), real animals can be defeated (#26),
    mild scary elements often (night monsters), no fierce or dark overtones (cartoon monsters), no sex, gambling,
    language, drugs, crude humour or digital purchases; users interact, with block, report, moderation and
    friends only.
  - **Target audience:** 9–12, 13–15, 16–17, 18+. Google allows nothing below 9 with ESRB 10+. The Families
    policy applies, and the owner certified children's-law compliance (their yes, 23:1x). Expert Approved: not
    now.
  - **Data safety:** collected, none shared, all optional. User IDs, other info (age band, consent), in-app
    messages, other user-generated content, other actions, device IDs. Encrypted in transit. Accounts: username
    and other authentication. Deletion link https://178-104-20-64.sslip.io/delete-account. The Families badge is
    shown.
  - **Government, financial and health apps:** none.
  - **Store settings:** Game, Adventure; contact parkingi-support@googlegroups.com (the owner's support group),
    no phone or website.
  - **Default listing (en-GB):** name EasyCraft; short and full description (only what 0.3.2 has); icon;
    feature graphic; 8 screenshots (`docs/store/graphics/`); AI label: none (game renders).
  - **Developer name:** "API Studio" (the owner's choice, 22:55), waiting for Google's approval of the new
    name.
- 23:44: the **closed test "Closed testing - Alpha"**: 176 countries, the list "EasyCraft testers", feedback to
  the support e-mail, release 7 (0.3.2). **16 changes sent for Google review** (quick checks, then usually
  within 7 days).
- **The two release warnings are advisory.** "No deobfuscation file": we don't use R8/ProGuard, so there is
  nothing to upload. "No native debug symbols": Godot's official Android templates ship stripped .so files, so
  there are no symbols to upload. It only makes native crash stacks less readable. Revisit if Android vitals
  shows native crashes (then build the templates with symbols or use Godot's debug-symbol packages).
- Next: after Google's review, send testers the closed test's join link (Testers tab → "Join on Android"). At
  least 12 must stay in for 14 days (`docs/store/reviewers-and-testers.md`). Then Apply for production. Every new
  version: build the bundle (above), Test and release → Closed testing → Create new release → upload → notes →
  review, with the version code raised.

- **2026-09-25 00:15: Google approved everything.** "App update published" on 25 Sept; the developer identity
  "API Studio" verified. **Closed testing - Alpha is Active** (release 7 (0.3.2), 177 countries/regions). **The
  testers' join link: https://play.google.com/apps/testing/com.giorgi.easycraft** (the same on Android and on
  the web). The 14-day clock runs once at least 12 testers have opted in. Add testers' Gmail addresses to the
  "EasyCraft testers" email list (Play Console → Test and release → Testing → Closed testing → Testers → the
  list's arrow), or switch the track to a Google Group.

- **2026-09-25 03:10: hotfix 0.3.3 (code 8)** = 0.3.2 + owner #49 (a readable chat) + #50 (the animal chorus),
  branch `hotfix-0.3.3` (`cfd548e`). Suite 4104/4105 (the one failure, `test_visit_world`, passes 3 of 3 alone).
  Files: `~/Downloads/EasyCraft-0.3.3.apk` (133 MB, dev package `com.giorgi.game`, sha256 `39263a85…`) and
  `~/Downloads/EasyCraft-0.3.3-play.aab` (70 MB, `com.giorgi.easycraft`, upload-key signed, sha256 `52230843…`).
  **Emulator check (emulator-5554):** the menu shows v0.3.3; in Sandbox the CHAT wheel opens, "/ COMMANDS" opens
  the bar at the top, typed text ("/tim…") shows dark on white with the command suggestion under it, and after
  SEND the line "SwiftDragon54 made it day." sits on a dark backing under the hearts. (`adb shell input tap` is too
  quick for the HUD buttons, which act on release; use `input motionevent DOWN …; sleep 0.15; input motionevent
  UP …`.) **Waiting on the owner:** the Chrome extension uploads only files under 10 MB, so the owner drags the
  bundle into Test and release → Closed testing → Create new release → Upload; the lead then fills the notes
  (`docs/playtests/whats-new-0.3.3.md`) and sends it for review.
- **03:20, the console's warnings checked:** Policy status (the account and the app): "No issues found". No
  pre-launch report yet: Google makes one only from a bundle uploaded to a testing track (0.3.2 went to internal
  testing first and was promoted), so the 0.3.3 upload to the closed test gives the first one (stability,
  performance, accessibility, security). Read it after that upload and fix what it flags. The dashboard's
  production checklist: "0 testers currently opted in". The list "EasyCraft testers" has the 2 addresses, but
  each tester must open https://play.google.com/apps/testing/com.giorgi.easycraft on their phone (signed in with
  that Gmail) and tap **Become a tester**; only then do they count toward the 12.

- **2026-09-25 17:15: release 0.4.0 (code 9)** from `15bfae0`: `~/Downloads/EasyCraft-0.4.0.apk` (193 MB, dev package
  `com.giorgi.game`, debug-key signed, sha256 `47cb5e11…`) and `~/Downloads/EasyCraft-0.4.0-play.aab` (90 MB,
  `com.giorgi.easycraft`, upload key, jarsigner verified, sha256 `8547d2df…`). What's new:
  `docs/playtests/whats-new-0.4.0.md` (its last paragraph is the Play "What's new" text). The first export's APK failed
  signing: owner #43's boot splash went in twice ("keep" importer + Godot's own raw copy); fixed (`15bfae0`). On
  emulator-5554 (installed over 0.3.3; the profile kept): the teal splash with the buddy and the wordmark, the new title,
  v0.4.0, a world with the new grass, no script errors. **The owner uploads the bundle** (over the extension's 10 MB):
  Test and release → Closed testing → Create new release → Upload → the notes → Next → Save → Send for review. 0.3.3 need
  not be uploaded: 0.4.0 has everything it had.

## Before "Apply for production" (M5 Task 4, 2026-09-25)
**`pre-launch-checklist.md`** holds every step, who does it, and the drafted production-access answers. The console
changes for 0.4.0, in short (each one's exact field and answer is in the file named):
- **Main store listing:** the new short and full descriptions, English only (`listing.md`; its accessibility line
  only with a build that has M5 Task 1); the new icon, feature graphic and 8 screenshots (`screenshots.md`).
- **Data safety:** no data type changes; set the purposes per type, the optional "delete some data without deleting
  the account" → Yes, and App access instructions for reviewers (`data-safety.md` → "What the lead or the owner
  changes").
- **Content rating and Target audience:** no change for 0.4.0 (`families-and-rating.md`).
- **Web pages:** deploy the regenerated `server/deploy/site/` (the live /privacy is older than the drafts).

- **2026-09-26 01:15: release candidate 1.0.0 (code 10)** from `93edc27` (main `75549fc`): `~/Downloads/EasyCraft-1.0.0.apk`
  (100.3 MB, `com.giorgi.game`, debug-key signed, sha256 `e73842e4…`) and `~/Downloads/EasyCraft-1.0.0-play.aab` (71.6 MB,
  `com.giorgi.easycraft`, upload key, jarsigner verified, sha256 `d3859b9e…`). Acceptance: `docs/devlog/2026-09-26-release-1.0.0.md`.
  What's new: `docs/playtests/whats-new-1.0.0.md` (its last paragraph is the Play text, 306 characters). The live server
  runs module 0.2.11, which this version needs. **The owner uploads the bundle** (Test and release → Closed testing →
  Create new release → Upload → the notes → Save → Send for review), and makes the listing and Data safety changes in
  `docs/store/pre-launch-checklist.md`.

- **2026-09-26 02:57: 1.0.1 (code 11)**, the whole-game review's fixes on top of 1.0.0: `~/Downloads/EasyCraft-1.0.1.apk`
  (sha256 `579c8232…`) and `~/Downloads/EasyCraft-1.0.1-play.aab` (upload key, sha256 `5ad76235…`). **Upload 1.0.1 instead of
  1.0.0**; the notes are `docs/playtests/whats-new-1.0.0.md`'s last paragraph (they still fit).

- **2026-09-27 01:05, checked: 1.0.1 is published** on Closed testing - Alpha ("11 (1.0.1) · Available to selected testers ·
  Released on 27 Sept 00:20"; "App update published"). The owner dragged the bundle into the release the lead had
  prepared (notes filled in). Testers: the list "EasyCraft testers" has 2 addresses; the dashboard's production checklist
  says **1 tester currently opted in** of the 12 needed, then 14 days with at least 12 before "Apply for production".


- **2026-09-27 01:10–01:30: the store page and the forms brought up to 1.0.1** (the owner: "can we do something to move
  the game on google play more forward, before testers are testing? … if there is something we can do, do all of
  them"). Done by the lead in the console:
  - **Default store listing:** the short description (78 characters) and the full description (3,334) from
    `listing.md`; the **app icon** replaced by the buddy mark (`graphics/next/icon-512.png`; the grass-block icon
    removed). The feature graphic and the 8 screenshots were still the 0.3.2 ones at that point (new ones below).
  - **Sign-in details** (formerly "App access"): now **Yes, some parts are restricted**, one entry "Online play (no
    password needed)" with no username or password and these instructions (492 of 500 characters): *No username or
    password is needed. Offline play (Sandbox, Survivor, home Wi-Fi) needs nothing. Online play: at "When were you
    born?" pick a year that makes the player 13 or older; PLAY ONLINE then makes an account by itself. For players
    under 13, online play stays off until verified parental consent, which is not offered yet. The grown-up area's
    parent gate asks a multiplication written in words (type the number). Playing online together needs a second
    device and an invite. No purchases.* "Full access to all features" ticked; Google may use the details for
    pre-launch testing (left on).
  - **Data safety:** the optional question "delete some or all data without deleting the account" → **Yes**, the
    same URL (https://178-104-20-64.sslip.io/delete-account, whose "Deleting only some data" part is live).
    Purposes: **Other in-app messages** + Fraud prevention, security and compliance; **Other user-generated
    content** + Account management + Fraud prevention, security and compliance. Checked and already right: User IDs
    (app functionality, fraud prevention, account management), Other info (app functionality, account
    management), Other actions (app functionality, fraud prevention), Device or other IDs (app functionality,
    account management); every type collected, not shared, not ephemeral, optional. No data type added or removed.
  - **Sent for review at 01:25:** 4 changes (short description, full description, app icon, Data safety; the
    sign-in instructions go with them as "What you've told us"). Managed publishing is off, so they go live when
    approved.
  - **Checked, nothing to do:** the pre-launch report has no switch (it runs by itself on uploads to a testing
    track) and **no report exists yet for 1.0.1** (look again in a day; if none comes, Google may not crawl this
    build, and the owner's real-phone check stands in); **open testing and pre-registration are locked** until
    production access, so the only way forward is the closed test's 12 testers for 14 days. The closed test:
    177 countries, the list "EasyCraft testers" (2 addresses), feedback to the owner's support group
    parkingi-support@googlegroups.com (on purpose: the same contact as the listing and the privacy policy).

- **2026-09-27 02:55: the new store pictures uploaded and sent for review.** The feature graphic (1024 × 500) and the
  8 phone screenshots (1920 × 1080, in the order of `screenshots.md`: wake, size, portal, dragon, dog, hide, race, book),
  all from `docs/store/graphics/next/`, made by `tools/store_shots.gd` (`docs/devlog/parts/store-shots.md`); the 0.3.2
  feature graphic and 8 screenshots removed from the listing. Submission 5 "Store listing": **in review**.
  **Submission 4 (01:28: the texts, the icon, Data safety, the sign-in details) was already approved: "Published".**
  How the order was kept: the asset library adds a batch in upload order, so each screenshot was added on its own
  (search "shot-N" in the library, tick its circle, Add); there is no reorder button on the listing page.

- **2026-09-27 19:25, the owner: the join link says "App not available".** Checked in the browser: the closed test is
  live (1.0.1), but the page shows "App not available … isn't available for this account" to **every Google account
  that is not on the list "EasyCraft testers"**. The list holds only [tester 1's Gmail] and
  [tester 2's Gmail]; both accounts signed in to this PC's Chrome get that page. Fix: add the tester's Gmail
  to the list first (Testers tab → the list's arrow → Add email addresses → Save changes → Save), then that person
  opens the link signed in with that same Gmail. The link is not a public page: it works only for listed accounts.

- **2026-09-27 19:40, the owner: "is it possible to make it open to test to anyone with link? i dont want this closed
  testing anymore".** Open testing is locked until production access (Test and release → Open testing: "available when
  you have production access"), and production needs the closed test's 12 testers for 14 days, so the closed test
  stays. The owner chose the closest thing: **a Google Group anyone can join.**
  - Created (by the lead, in Google Groups under the developer account `/u/1/`; the owner ticked the CAPTCHA): **"EasyCraft
    Testers", easycraft-testers@googlegroups.com**. Anyone on the web can see and join it (no approval); only owners
    and managers can see members, see posts or post, so testers never see each other's addresses. Its description has
    the three steps. Page to share: https://groups.google.com/g/easycraft-testers/about
  - **Closed testing - Alpha → Testers → Google Groups: easycraft-testers@googlegroups.com** (Play allows either email
    lists or Google Groups, not both: the list "EasyCraft testers" no longer gives access; its 2 people must join the
    group). Sent for review 19:40 (submission 6, "In review"). Submission 5 (the new store pictures) is **Published**.
  - How a tester joins now: (1) the group page → **Join group**; (2) on the Android phone, signed in with the same
    Gmail, https://play.google.com/apps/testing/com.giorgi.easycraft → **Become a tester**; (3) install from Google Play.
- **2026-09-27 19:57: submission 6 (testers → the Google Group) is Published.** Anyone who joins
  easycraft-testers@googlegroups.com can now become a tester.

- 2026-09-28 11:25: **1.0.2 (code 12)** built from `d9f7682`: `~/Downloads/EasyCraft-1.0.2.apk` (104 MB, `com.giorgi.game`,
  debug key, sha256 `d72289726d9cdab3…`; installed over 1.0.1 on the emulator: the profile kept, the menu, a world) and
  `~/Downloads/EasyCraft-1.0.2-play.aab` (73.5 MB, `com.giorgi.easycraft`, upload key: the same certificate as 1.0.1,
  `9D:E2:02:27…`; jarsigner verified; sha256 `81edcc3cc08438a9…`). What's new: `docs/playtests/whats-new-1.0.2.md`
  (space, the double-tap flight, the account on every device (#67: sign-in keys, gold from the server), the age pad,
  the credit, SIMPLE/CLASSIC on SETTINGS' first page). **Not uploaded:** the browser tool uploads at most 10 MB, so
  the owner uploads it: Play Console → EasyCraft → Testing → Closed testing → Create new release → upload the .aab →
  paste the notes → Save → Review release → Start rollout.
- 2026-09-28 12:05: **1.0.2 rebuilt with the School (#68)** (still code 12: the first 1.0.2 was never uploaded) from
  `6cd1360`: `EasyCraft-1.0.2.apk` (99 MB, sha256 `e64ed5e6d91aaee5…`) and `EasyCraft-1.0.2-play.aab` (70 MB, upload key,
  jarsigner verified, sha256 `68952a488aed6031…`) replace the 11:25 files in `~/Downloads`. On the emulator: installed over the
  earlier 1.0.2, the menu, SCHOOL → Professor Hoot. What's new gains the School.
- 2026-09-29 01:40: **1.0.2 rebuilt again** (code 12, never uploaded) with #69 (no age question, no under-13 limits, no
  grown-up gates): `EasyCraft-1.0.2.apk` (sha256 `e750138f…`) and `EasyCraft-1.0.2-play.aab` (`5138f390…`, upload key,
  jarsigner verified) replace the earlier files. **Before a Play review:** the Families / Data safety / target-age
  answers in the console and in `docs/store/` assumed the age question and parental consent; they need a look.
- 2026-09-29 05:35: **1.0.2 rebuilt a third time** (code 12, never uploaded) with the whole School (grades 4-8, 201
  units) and the browser's shader warm-up (web only): `EasyCraft-1.0.2.apk` (109 MB, `com.giorgi.game`, sha256
  `5a17ce61326ee8ba…`) and `EasyCraft-1.0.2-play.aab` (78 MB, upload key `9D:E2:02:27…`, jarsigner verified, sha256
  `cb75c77e299b0023…`) from `b0cb1e3` replace the earlier files in `~/Downloads`. What's new updated (the whole School).
- 2026-09-29 17:55: **1.0.3 (code 13)** built from `e60cd98` (suite 7279/7281, 0 failures) and put in `~/Downloads`:
  `EasyCraft-1.0.3.apk` (110 MB, `com.giorgi.game`, sha256 `2a71dbe8891c5fb3…`) and `EasyCraft-1.0.3-play.aab`
  (77 MB, `com.giorgi.easycraft`, upload key `9D:E2:02:27…`, jarsigner verified, sha256 `a53ec97bd5f72928…`). It
  replaces 1.0.2 (never uploaded; code 12 is skipped, which Play allows). What's new: `docs/playtests/whats-new-1.0.3.md`
  (grades 3-4 in every subject, the Star Map, Mars, Europa, the Science Lab, jump taps fly up). Uploading needs the
  owner's yes (Play Console steps above).
- 2026-10-01 11:00: **1.0.4 (code 14)** built from `96c226c4` (suite 43: 9630/9632, 0 failures) and put in `~/Downloads`:
  `EasyCraft-1.0.4.apk` (169 MB, `com.giorgi.game`, debug-key signed, sha256 `fab944607bab5575…`; installs beside the store app, plays
  EasyCraft Shorts; the Theater's real videos need the Play build's player) and `EasyCraft-1.0.4-play.aab` (113 MB,
  `com.giorgi.easycraft`, upload key `9D:E2:02:27…`, jarsigner verified, sha256 `d5349d9e704d24fc…`). It replaces 1.0.3 (never
  uploaded). What's new: `docs/playtests/whats-new-1.0.4.md` (its last paragraph is the Play text, 327 characters).
  **Before uploading, the owner decides the Theater** (Data safety and Families answers for the TV room, or a build with
  it off); uploading needs the owner's yes. Checked: the APK installs and starts on the emulator (v1.0.4, MENU ready).
