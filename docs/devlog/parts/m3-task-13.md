# M3 Task 13: admin panel and secret codes (2026-09-24)

Spec §5.11 and §14.10; plan `docs/superpowers/plans/2026-09-24-m3-worlds-of-wonder.md` Task 13
(allocations: the profile field for redeemed codes; the admin panel text at the main menu's bottom).
Built in a worktree cut from `m2-survive-the-night` (`eabb3ad`) while the M2 agents worked, because
it only needs the M2 Survivor gold that is already there. No editor or emulator was used. The lead
merges and checks it on the emulator.

## What was built

| File | What |
|---|---|
| `core/codes/code_rules.gd` (`CodeRules`) | The pure rule. `normalize` (trim, lowercase), `hash_code` (SHA-256 of `SALT` + normalised code), `REWARDS` (salted hash → reward; **no plain code ships**), `redeem(profile, code, tries, now_msec, rewards = REWARDS)` → `{status, message, reward, wait}`, `give`, `message`, `thousands`, `is_hash`, `sanitize_redeemed`. Reward kinds: `KIND_GOLD` (now) and `KIND_COSMETIC` (reserved for Task 9). |
| `core/codes/code_tries.gd` (`CodeTries`) | The rate limit: 5 wrong codes in a row → 30 s lock (`MAX_WRONG`, `LOCK_MSEC`). |
| `core/save/profile_data.gd` | New field `codes_redeemed: Array[String]` (the salted hashes, never the codes), parsed by `CodeRules.sanitize_redeemed`: 64-digit hex only, lowercased, no repeats, at most 256. Three inserted lines, no existing line changed. |
| `ui/menus/code_panel.gd` (`CodePanel`) | The field: title "Secret code", a big input (560 × 96, 44 px text, 32 characters), one message line, OK (green) and BACK (blue). OK needs a code and shows `WAIT <n>` while locked; Enter submits. A payout saves the profile at once, rains coins and plays `ding`. `CodePanel.admin_link()` builds the small black text. `profile`, `save_profile`, `tries` and `rewards` can be swapped (the tests never touch the real profile). |
| `ui/menus/coin_shower.gd` (`CoinShower`) | 48 spinning gold coins over the whole screen for 2.6 s, then it frees itself. A `CanvasLayer` (layer 20) with one `Control` that draws circles: no textures, no materials, no taps caught. Task 10's welcome-back shower can reuse it. |
| `ui/menus/menu.gd` | The `_admin` link (a member), added in `_build_ui`; `_show` hides it, `_show_main` shows it; `_show_codes` opens the field, and BACK returns to the main screen. |

Messages (exact): "Code accepted! +1,000 gold", "That code doesn't work.", "You already used that
code.", "Too many tries! Wait 30 seconds." (a countdown, "1 second" in the singular), and "Type a code
first." (Enter on an empty field).

### Adding a code later
1. Hash it without writing it into the repo:
   `printf '%s' 'easycraft:codes:v1:5d3f8a61c2<code, trimmed and lowercased>' | sha256sum`.
2. Add `"<hash>": {"kind": KIND_GOLD, "amount": <gold>}` to `CodeRules.REWARDS`, with a comment that
   says what it gives, not what it is.
3. `test_the_plain_code_never_ships` only knows the first code. Keep new plain codes out of every
   shipped file (release notes and social posts are outside the repo).

## Tests: RED → GREEN

New: `tests/unit/test_code_rules.gd` (16), `tests/unit/test_profile_codes.gd` (5),
`tests/integration/test_code_panel.gd` (10).

- **RED.** API stubs first (empty `CodeRules`/`CodeTries`/`CodePanel`/`CoinShower`, and the bare
  `codes_redeemed` variable), so the tests parsed and failed on their assertions, not on missing
  names. Every behaviour failed for the right reason. Examples: the known vector (`"abc"` expected to
  equal `8764c42a…`), `normalize` returned the raw text, `redeem` returned an empty status, the gold
  stayed at 25, the list round trip came back `[]`, `thousands(1000)` gave `"1000"`, the menu had no
  `AdminPanel` node, and the field showed no message or coin shower.
  `test_the_plain_code_never_ships` passed at once, which is right: nothing shipped the code.
- **GREEN.** The new and related files (the code tests plus `test_profile_data`,
  `test_main_menu_modes` and `test_dev_menu`) pass: 47/47. The one failure on the way was
  real. The flat button's minimum height (the theme's 16 px content margins plus the font) was taller
  than its offsets, and a Control grows downwards by default, so it stuck out 7 px below the
  screen. Now it grows upwards (`GROW_DIRECTION_BEGIN`).
- **Full suite:** `tests/run_tests.sh` exited 0 with 668 tests in 82 scripts, all passing (637 before
  this task plus the 31 new ones), no `SCRIPT ERROR` or `Parse Error`, in 161 s at a load average of
  49. The 20 orphans GUT reports come from older chat, HUD and player tests; the new ones leave none.
- The new test file uses `wait_process_frames`, because `wait_frames` is deprecated in GUT 9.7.

Covered: normalisation; the salted hash (a known vector computed outside Godot with `sha256sum`, so
it pins the salt and the algorithm); the table holds only hashes; the first code → 1,000 Survivor gold;
the plain code is in no shipped text file; once per profile (also with other case and spaces; another
profile may still use it); unknown and repeat messages; empty input is not a try; 5 wrong → locked
30 s even for the right code, then unlocked; 5 new tries after a lock; repeats don't count and a right
code resets the count; an ungivable reward is not used up; the wallet cap; a broken gold reward gives
nothing; thousands separators. For the profile: the round trip and the defaults for old profiles; bad
data (not a list, non-strings, wrong length, non-hex, a `+` sign, upper case, repeats) and the cap;
other fields survive bad code data. For the menu: the small black text is at the bottom of a
2400 × 1080 screen and covers no button; it opens the field (a big input, OK and BACK) and hides
itself; BACK returns; onboarding doesn't show it. For the field: OK waits for a code; a right code
pays, saves, clears and rains coins; the unknown and repeat messages; 5 wrong → `WAIT`, and Enter can't
get round it; OK comes back when the wait is over (and per-frame work stops). The coin shower ignores
taps and frees itself.

## Rulings (decisions made on the owner's behalf)

1. **`hash_code`, not `hash`.** GDScript has a global `hash()`, and a method with the same name would
   shadow it. *Cost if wrong:* none (a name).
2. **One salted SHA-256, as the spec says; no key stretching.** The salt ships in the APK. The hashes
   keep codes out of the APK's strings and defeat lookup tables, but an adult with the APK could still
   brute-force a short code offline. A rooted phone can edit `profile.json` anyway. Gold is local and
   can't be traded, and from M4 the server redeems codes. *Cost if wrong:* a code leaks before M4 and
   gives someone local gold; nobody else is affected.
3. **The profile keeps hashes, not codes** (`codes_redeemed`, at most 256). A code that would go past
   the cap is not given, so a reload can never drop an old entry and make it redeemable again.
   *Cost if wrong:* none in practice (256 codes).
4. **Rate limit: 5 wrong codes in a row → 30 s.** After a lock the count starts again; a right code
   also resets it; empty input and "already used" don't count. The limit lasts for one app run
   (`CodePanel.shared_tries`, a static var, on the steady `Time.get_ticks_msec` clock), so closing and
   reopening the field keeps it, but it is not saved. *Cost if wrong:* a child who restarts the app
   gets 5 tries sooner, which doesn't matter against a 10-character code. Saving it would need the
   wall clock (which the player can change) and another profile field.
5. **A reward this build can't give** (a cosmetic before Task 9) says "That code doesn't work.", is
   not used up and is not a wrong try, so a code announced early works once the update arrives.
   *Cost if wrong:* a child briefly thinks a real code is wrong, and only if a cosmetic code ships
   before Task 9.
6. **Gold goes straight into the profile** (`Wallet`, capped at `Wallet.MAX_GOLD`) and the profile is
   saved at once. Codes are redeemed from the menu, outside a world, so `Session.gold_add` (the host's
   in-world path) isn't involved. *Cost if wrong:* an in-world code field (if one is ever wanted) must
   go through `Session` instead.
7. **Where the text sits:** the bottom centre of the screen, outside the main panel, so no existing
   button moves (the dev menu's tap positions are unchanged). It is a flat `Button` (black, 22 px,
   a 260 × 63 tap area), only on the main screen, not during onboarding or on other panels. Black on
   the bright menu backdrop is readable but low-key, as §5.11 intends. *Cost if wrong:* the owner
   wanted it inside the panel, which is a small move.
8. **The coin shower draws circles** on its own canvas layer instead of using particles or textures.
   That means no shader compile spike (see the `Fx` gotcha), and it frees itself. *Cost if wrong:*
   it looks simpler than an `Fx` burst; restyle later.
9. **The keyboard** uses the same defaults as the name field (same centred layout, which passed on
   the emulator). The alternative, `KEYBOARD_TYPE_PASSWORD` (no suggestions or autocorrect), was not
   tried because it can't be checked here. *Cost if wrong:* Android autocorrect could change a typed
   code; the emulator check below covers it.
10. **The plain first code is written only in `tests/unit/test_code_rules.gd`.** It can't be avoided
    there, because it is the only way to prove the shipped hash is the owner's code. Both game presets
    exclude `tests/*`, and `test_the_plain_code_never_ships` scans every shipped text file (outside
    `tests/`, `docs/`, `addons/` and `build/`). The spec already names the code in `docs/`, which
    doesn't ship. The `Android Spike` preset has no exclude filter, but it is a Voxel Tools check that
    players never get. *Cost if wrong:* none for the game APKs.

## For the lead

- **Merge:** `core/save/profile_data.gd` gets three inserted lines (the field, the parse line, and
  `"codes_redeemed"` in `to_json` on its own line). `ui/menus/menu.gd` gets one member, three lines
  in `_build_ui`, one line each in `_show` and `_show_main`, and `_show_codes` after `_show_settings`.
  There are four new `class_name`s (`CodeRules`, `CodeTries`, `CodePanel`, `CoinShower`), so rescan or
  `--import`.
- **Emulator check (2400 × 1080):** the "admin panel" text is centred at about **(1200, 1027)** (the
  viewport is 1600 × 720 with a 1.5 scale; the test prints the rect). Check the following:
  - The soft keyboard doesn't cover the field.
  - A typed code isn't autocorrected.
  - The coins show over the panel.
  - The first code gives +1,000 once.
  - A second try says "You already used that code."
  - Five wrong tries show `WAIT 30`.
- **Task 9:** fill the `KIND_COSMETIC` branch in `CodeRules.give` (unlock `reward.item` in the
  profile's avatar items). **Task 10:** `CoinShower.new(count, seconds)` for the welcome back.
