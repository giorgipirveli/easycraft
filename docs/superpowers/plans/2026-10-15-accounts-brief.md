# Log in, log out, and the same name on a new device — the agent brief (owner #99)

The owner (2026-10-14): "when player plays on mobile and with the same username wants to start playing on pc and enters
username it should ask to switch into new device or not and continue accordingly", and "also do we have logout and login?"
You are building it in EasyCraft (Godot 4.7.2, typed GDScript; the online mode on a Nakama server with our TypeScript
module, `server/modules/src/main.ts`, MODULE_VERSION 0.2.19 live). Work autonomously; do not ask questions (decide, and note
rulings with what they cost if wrong).

## Today (read it end to end first)
- Sign-in is automatic by this device's id (`net/online_service.gd` sign_in, `net/nakama_online_backend.gd`); the name is
  claimed once (`ui/online/username_claim.gd`, `claim_username`); a taken name says "Someone already has that name. Try
  another one!" (`core/net/online_rules.gd`).
- Another device today: a grown-up makes a key on the old device (Grown-ups → OTHER DEVICES, `ui/parents/account_key_page.gd`,
  RPC `account_key`); the new device: PLAY ONLINE → I HAVE AN ACCOUNT → the parent gate → name + key
  (`ui/online/key_sign_in_page.gd`, `sign_in_with_key`, RPC `sign_in_with_key`). Name, progress, looks and gold come along;
  worlds stay on each device. SIGN OUT OTHER DEVICES (held 2 s) for a lost phone. No LOG OUT of this device.
- Read `docs/devlog/parts/` notes on accounts (grep "#67"), `docs/DEVELOPMENT.md`'s online and server sections, the
  profile backup and the wallet sync (gold must never double or vanish: the gold-double notes), the server's tests
  (`npm --prefix server/modules test`).

## The design (the lead's rulings)
1. **A taken name asks:** "Someone already has the name Anna. Is it you, from another phone, tablet or computer?" YES, IT'S
   ME / NO, ANOTHER NAME. NO goes back to the name (with RANDOM). YES opens **Move your game here**.
2. **Move your game here — with proof, never by the name alone** (a child's account must not be taken by someone typing its
   name). Two ways, the easy one first:
   - **A code from this screen, typed on your other device:** this device shows a 6-digit code (from the server, valid 5
     minutes) and "On your other device: open EasyCraft, and type this code there." The account's online devices get a card
     "Someone wants to play as Anna on a computer. If it's you, a grown-up types the code from that screen. Never type a code
     someone tells you." (behind the parent gate, as making a key is: ruling #67's safety); the right code approves it; the
     server hands the new device a one-time key and it signs in with the existing `sign_in_with_key`. A wrong code three
     times or 5 minutes: the request ends. Rate limits on the server (requests per name and per device). If the old device
     is not online: it shows the card when it next comes online, while the code is still valid; this device says so.
   - **A key** (today's grown-up way), offered on the same screen.
   After the move: "Welcome back, Anna! Your name, progress, looks and gold are here." The old device stays signed in (both
   play; it hears "Your game is on a computer now too."). *Cost if wrong:* the owner wanted the old device signed out:
   one call (`sign_out_other_devices`) at the end of the move.
3. **LOG OUT** (on the PLAY ONLINE account card and in Settings): first everything is saved to the account (the profile
   backup and the gold sync finished, nothing waiting offline); offline it refuses: "Connect to the internet first, so your
   game is saved."; then **Who is playing?**: the accounts played on this device before (each keeps its own device
   credential locally: one tap brings it back, like profiles on a family tablet), NEW PLAYER, and LOG IN. *Cost if wrong:*
   on a shared tablet a sibling can open another sibling's game (the family-tablet ruling; a grown-up PIN later).
4. **LOG IN:** the name, then the code from your other device or the key (rule 2). The same screen as the move.
5. **Worlds stay on each device** (as today); each account on a device keeps its own profile file and its own worlds' list
   if the save layer allows it cheaply, else the worlds are the device's (a ruling with its cost).
6. Words for children (short, plain, the read-aloud speaker); every new string through the existing word checks; English only.

## Allocation and rules
- Yours: `ui/online/*` (claim, key sign-in, the move screen, Who is playing?), `ui/parents/account_key_page.gd`, `net/*`,
  `core/net/*`, the profile's account list (`core/save/*`, `autoloads/profile.gd`: careful, every save goes through it),
  `server/modules/src/*` (new RPCs: the move request, its code, the approval, the one-time key; rate limits; MODULE_VERSION
  0.2.20) and its tests, GUT tests `tests/**/test_account_*.gd`, `test_device_move*.gd`, `test_log_out*.gd`, the net test
  (`tools/net_test.sh`: add a move between two local instances), notes `docs/devlog/parts/accounts-99.md`.
- Two VR agents work at the same time (the player, camera, input, HUD, `ui/menus/menu.gd`, `ui/menus/settings_panel.gd`,
  the loading card, PadFocus): the Settings entry for LOG OUT is one marked line in `settings_panel.gd` — list it in your
  notes for the lead instead if it would collide.
- TDD; the server module's tests (`npm --prefix server/modules test`) and the local server (`server/dev.sh reload`) for the
  real flow; `tools/net_test.sh` green. Never deploy to the live server (the lead does: say what), never merge or push,
  never open the editor or an emulator, never touch adb, never start agents. The FULL suite once at the end.

## Finish
Notes (the flows step by step as a child sees them, every ruling with its cost, the server changes and what the lead
deploys, the security review: what stops a stranger); `DEVELOPMENT.md`; spec §5.13 "As built (owner #99)". Commits ending
with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, the flows, the server
module version, the tests' and the net test's results.
