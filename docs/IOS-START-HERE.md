# EasyCraft on the Mac — start here (the iPhone build)

For the owner and for Claude on the owner's Mac. Written 2026-09-27 on the Linux PC where M1–M5 (Android) were built.
The game, the server and every document are in this folder; only the iPhone glue is new work (spec §19, plan
`docs/superpowers/plans/2026-09-27-m6-iphone.md`).

## 1. What this folder is
- A full copy of the game's git repository (all history, branch `m2-survive-the-night`, the latest commit is the one this
  file came with). `git log` works; there is no remote (the owner said: never push without asking).
- Not included on purpose: `.godot/` (Godot rebuilds it on the first open, a few minutes), build outputs, the Android
  upload key and the server's SSH key (not needed for iPhone work; see §5).
- `CLAUDE.md` (the rules), `docs/DEVELOPMENT.md` (how everything works), `docs/superpowers/plans/2026-09-24-RESUME-HERE.md`
  (the whole story and the state), `docs/HANDOFF.md` (what only the owner can do).

## 2. Set up the Mac (once)
1. **Xcode** from the App Store (it brings the iOS SDK), then open it once and accept its licence (the owner does that).
   In Xcode → Settings → Accounts the owner adds their Apple ID (Claude never types the password).
2. **Apple Developer Program** (99 USD a year, https://developer.apple.com/programs/) for TestFlight and the App Store;
   a free Apple ID is enough to run a debug build on the owner's own iPhone for 7 days.
3. **Godot 4.7.2 (standard, not .NET)** for macOS from https://godotengine.org/download/archive/ into `/Applications`, and
   a command `godot`: `sudo ln -s /Applications/Godot.app/Contents/MacOS/Godot /usr/local/bin/godot`.
   Then the **export templates 4.7.2** (Godot → Editor → Manage Export Templates → Download), which include iOS.
4. **Homebrew** (https://brew.sh), then `brew install coreutils flock node`. The test scripts use `timeout`
   (coreutils installs it as `gtimeout`: `brew link coreutils` or add `$(brew --prefix coreutils)/libexec/gnubin` to
   PATH) and `flock` (the PC-wide suite slots; on the Mac you can also run the tests with `EASYCRAFT_SLOT_HELD=1`).
5. **Unblock the copied files** (macOS marks files that came from another computer, and then refuses to load the Voxel
   Tools library): `xattr -dr com.apple.quarantine <this folder>`. If Godot still says the voxel library can't be
   loaded, sign it for this Mac: `codesign --force -s - addons/zylann.voxel/bin/libvoxel.macos.*.framework/libvoxel.macos.*`.
6. **Claude Code** on the Mac, started in this folder. The project's `.mcp.json` brings godot-mcp (it needs the Godot
   editor open with the `godot_mcp` addon enabled, which it is in this project).
7. **Claude's memory** (optional but helpful): copy the files from the folder `claude-memory/` (next to this repository in
   the copy the owner received) into `~/.claude/projects/<slug>/memory/`, where `<slug>` is this folder's full path with
   every `/` turned into `-` (for `/Users/giorgi/Documents/game` it is `-Users-giorgi-Documents-game`). Some notes there
   are about the Linux PC (the emulator, CPU load, adb ports): they don't apply on the Mac.

## 3. First steps for Claude on the Mac
1. Read `CLAUDE.md`, then `docs/DEVELOPMENT.md`, then this file and the M6 plan.
2. Open the project once (`godot -e --path .`, or `godot --headless --path . --import`) so `.godot/` is rebuilt.
3. Run the tests: `tests/run_tests.sh` (expected: 6016 of 6018 pass; the two others never assert). Then
   `npm --prefix server/modules ci && npm --prefix server/modules test` (280 pass).
4. Start the M6 plan at Task 1 and write every Mac difference into `docs/DEVELOPMENT.md` (a new "Mac and iOS" section)
   and each step into a dev log `docs/devlog/2026-09-27-m6.md`.

## 4. Rules that differ on the Mac
- The Android rules in CLAUDE.md (adb ports 5038, `emulator-5554`, the other app's emulator, the 3 PC-wide suite slots,
  the Linux CPU notes) are about the Linux PC. On the Mac: test on the owner's real iPhone (Voxel Tools has no iOS
  Simulator build); keep the full suite to one run at a time if the Mac is small.
- **Private user folders don't work on macOS the Linux way.** The smoke runs (`tools/*_smoke.gd`, `tools/smoke_all.sh`)
  and the network tests (`tools/net_test.sh`, `tools/ghost_net_test.sh`) give each game a private folder through
  `XDG_DATA_HOME`, but Godot on macOS ignores it and always uses `~/Library/Application Support/Godot/app_userdata/EasyCraft`.
  Until that is solved (for example a `--user-dir` argument the tools pass, read in `scenes/main.gd`), don't run them on
  the Mac: they would replace the Mac's own worlds and profile, and two games would share one device id. The GUT suite
  (`tests/run_tests.sh`) is safe: its tests never write the shared profile.
- Everything else holds: English only, CC0 only, test-first, document in the project, never merge or push without the
  owner, never type passwords, declarations and agreements need the owner's yes.

## 5. Secrets (not in this folder)
- **Android upload key** (`~/.local/share/godot/keystores/easycraft-upload.jks` and `~/.config/easycraft/upload-key.env`
  on the Linux PC): only for Google Play bundles; keep building Android on the Linux PC, or copy both files by hand
  (never into the repository) if the Mac should build Android too.
- **Server SSH key** (`~/.ssh/easycraft_hetzner` on the Linux PC): only to deploy the online server. The iPhone work needs
  no server change; if one comes, the Linux PC deploys it, or the owner copies the key to the Mac's `~/.ssh/` by hand.
- Apple signing lives in Xcode (the owner's Apple ID); nothing to copy.

## 6. Where things are
| What | Where |
|---|---|
| The rules | `CLAUDE.md` |
| How the game is built and tested | `docs/DEVELOPMENT.md` |
| The design (the authority) | `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` (§19 is the iPhone milestone) |
| The iPhone plan | `docs/superpowers/plans/2026-09-27-m6-iphone.md` |
| The whole story and the state | `docs/superpowers/plans/2026-09-24-RESUME-HERE.md` |
| Everything the owner reported, and the fixes | `docs/playtests/owner-feedback.md` |
| Store texts, privacy, data safety (reuse for the App Store) | `docs/store/` |
| The online server (live, module 0.2.11) | `server/`, `docs/hosting.md`; https://178-104-20-64.sslip.io |

## 7. The App Store compared with Google Play (written 2026-09-27 for the owner's question)
- **No 12 testers, no 14 days.** Apple has no minimum testing before release. The route: Apple Developer Program
  (99 USD a year; as an individual the seller name on the store is the owner's own legal name, as an organization it
  can be a company name but needs a D-U-N-S number) → the app record in App Store Connect → upload a build from Xcode →
  TestFlight (optional but wise) → **App Review** (usually 1–2 days; a first rejection with a list of fixes is common,
  then resubmit) → release.
- **TestFlight** = Apple's testing: up to 100 internal testers (people added to the owner's App Store Connect team, no
  review) and up to 10,000 external testers by e-mail or a **public link** (the first build needs a short Beta App
  Review). Testers install the TestFlight app. A build expires after 90 days.
- **What App Store Connect asks for** (drafts come from `docs/store/`): name (must be unique on the App Store — check
  "EasyCraft" is free when making the record), subtitle (30 characters), description, keywords (100 characters),
  support and privacy policy URLs (already live on the server), the age rating questionnaire, **App Privacy** labels
  (≈ Play's Data safety, from `data-safety.md`), export compliance (the game only uses HTTPS: exempt; set
  `ITSAppUsesNonExemptEncryption` = NO), review notes (how to reach online play: a 13+ profile, like Play's sign-in
  details), and screenshots: iPhone 6.9" (e.g. 2868 × 1320 landscape) and iPad 13" (2752 × 2064) if iPad is supported.
  The store screenshots can be made on the Linux PC with `tools/store_shots.gd` at those sizes (it needs Linux's
  private `XDG_DATA_HOME`, §4).
- **Rules that matter for EasyCraft:** in-app account deletion (done: the grown-up area); purchases only through
  Apple's in-app purchase (the shop is off); no Sign in with Apple needed (no Google/Facebook login); the **Kids
  category** is optional (owner and lawyer; it adds a parental gate before links and purchases, which the game has, and
  forbids third-party ads and analytics, which it has none of); an original look and name (guideline 4.3 on copies:
  EasyCraft has its own brand, buddies and magic; keep "Minecraft" out of every text).
