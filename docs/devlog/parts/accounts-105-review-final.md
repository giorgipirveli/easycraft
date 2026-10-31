# Owners #104/#105: the fourth (final A-G) review (2026-10-16 03:59)

Branch `worktree-agent-a45831f837d05a838` at `446f929c`. **Verdict: not mergeable** (blockers 1, 2, 4). The lead's decision: drop the multi-player kept slots ("Who is playing?"), which remove 1 and 2 at the root; the owner asked for log out, log in with name + password, one device at a time.

**Verdict: NOT MERGEABLE.** Three things block it: finding 1 (a child locked out of her own player when her account has no password), finding 2 (the game sends the wrong device id, so the server brakes devices that are still linked to the account), and finding 4 (the timing still shows whether a name has a password; a one-line fix). Findings 3 and 5–8 should be fixed or written down, but they don't block.

I changed nothing in the repo. My throwaway tests and probe are in `/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/review_final_acct/` (`modules/test/zz_final.test.ts`, `probe.mjs`). The probe ran on the private server (port 7500, build matches 446f929c) and deleted every account it made. The module's own Node suite passes 481/482 in my copy; the one failure is only a path problem from where I copied it.

## A–G

| | Status | Evidence |
|---|---|---|
| **A** two windows | **Server: implemented. In the game: partly** | `password_rules.ts` and `passwords.ts` have the pair and the name window and nothing else. Simulated over 3 days: 153 real guesses a day per name (the notes say about 154). Three small differences from the notes: a name refusal gives the pair try back (`passwords.ts:283`; harmless, but the notes say nothing is released); the name window is a fixed 24 hours from its first try, not rolling (`:151`); it counts correct tries too, not only wrong ones. "Linked devices are never braked" fails because of the client (finding 2), and "longest wait 10 minutes" is not true (finding 3). |
| **B** online flag | **Partly** | `account_switch.gd:182` no longer uses the device id file alone, so a player who only browsed comes back with one tap. But a claimed account with no password is still marked online (finding 1). |
| **C** never-claimed / remake | **Implemented** | A deleted never-claimed account leaves no tombstone. On the real server, the deleted asking id signed in again with 200. The remake fires on any error (finding 6). |
| **D** `device_logged_out` | **Implemented** | Real server: a logged-out id gets 403 `{"code":7,"message":"device_logged_out"}` with create=false and with create=true. The game maps it to the logged-out words whatever its prefs say. A small gap remains (finding 7). |
| **E** probe / try-catch | **Partly** | The fixed probe and the try/catch are there; 15 of 15 paths spend exactly one compare. But the timing still leaks (finding 4). |
| **F** cap / 13 months | **Partly** | The 13-month tombstone clean-up is there. The cap runs only on the password path, right before `signOutOthers`, which already leaves one device, so it never does anything. The key path has no cap: in my test, 15 key sign-ins left 16 linked ids against a cap of 10. A device in use is logged out cleanly (sessions ended, socket closed, id tombstoned). |
| **G** network window | **Implemented** | No network code is left. `KNOWN_MAX` in `password_rules.ts:35` is an unused leftover. |

## New findings, worst first

1. **HIGH: a child whose account has no password is locked out of her own player. CONFIRMED by reading the code.** (`net/account_switch.gd:182`, `ui/online/accounts_flow.gd:186`)
   - Who has no password: every account claimed before #105 that tapped LATER when asked, and every account an old build claims.
   - `prefs.account_name` is set for any claimed account, with or without a password.
   - Steps: on a family tablet, LOG OUT, then NEW PLAYER. Her slot is kept as online. When she picks it later, it asks for a password that doesn't exist and answers "wrong password" forever. Her worlds there are stuck; REMOVE deletes them.
   - Fix: count a slot as online only when it also has a password (`has_password != 0`; it is known after LOG OUT's sign-in). Or have LOG OUT ask her to make a password first when there is none.

2. **MEDIUM: Who is playing? sends the current player's device id, not the picked player's. CONFIRMED by test.** (`online_service.gd:2839`)
   - So her own kept slot, whose id is still linked to her account, is treated as a new device and braked.
   - With no attacker at all: switching back to Anna every 9 minutes gave ok ten times, then `slow_down`.
   - With an attacker on her name: sending Ben's id got `slow_down 600 s`; sending her own kept id got ok.
   - Fix: when `player_named(username)` finds the kept slot, send the id from that slot's `device_id.json`.

3. **MEDIUM: "a child's longest wait on a new device is 10 minutes" is false, and the grown-up's key doesn't work from a logged-out player. CONFIRMED (simulation and code).**
   - An attacker polling once a second takes the name's slot every time it opens. The child's new tablet, even retrying at exactly the second it was told, got in 0 times out of 144 tries in 24 hours. Each refused try costs the attacker nothing, because the pair is given back.
   - The escape is supposed to be the key, but `sign_in_with_key` and `link_new_device` (`online_service.gd:2009`, `:2469`) sign in first. On a logged-out player that returns "LOG IN to play here", so the key page fails too. The only way out is NEW PLAYER, then the key.
   - Fix (stays inside the frozen design): let the key path ask with the device's asking account, the way LOG IN does. Change the notes and the store drafts to say "an attacker who keeps polling can hold a new device off; the key or a linked device always works".

4. **MEDIUM-LOW: the timing still shows whether a name exists and has a password. CONFIRMED on the real server.** (`passwords.ts:32`)
   - The fake hash uses bcrypt cost 10 (`$2a$10$`). The real ones Nakama makes use cost 13 (`$2a$13$`, checked in the database).
   - Measured: a name nobody has, or an account with no password, answers in 97–107 ms. A real name with a password answers in 734–748 ms.
   - Fix: make the fake hash once at startup with `nk.bcryptHash`, so it has the same cost. Add a timing check to `passwords.server.ts`; the Node tests use a fake bcrypt and cannot catch this.

5. **LOW: F's gaps. CONFIRMED by test.**
   - The key path links ids with no cap and without logging the other devices out.
   - Anyone with the password and one linked id can log in again and again with no brake: 200 calls made 200 tombstones.
   - Fix: run the cap in `sign_in_with_key` too, and also end the sessions of the ids it unlinks. Consider limiting how often a known device can log in.

6. **LOW: the C remake fires on any sign-in failure, not only a missing account. PLAUSIBLE.** (`online_service.gd:2847`)
   - With create=true a gone asking account is simply made again, so a 404 never happens here. A network blip, though, throws away an asking account that was old enough: the next LOG IN waits about 30 s, and the old account is left for the 13-month clean-up.
   - Fix: remake only on a 404 or 403.

7. **LOW: D's gap. PLAUSIBLE.** (`online_service.gd:109`)
   - A 404 with no tombstone still makes a quiet new account for an old profile with no kept name. That happens when the tombstone write was lost, the owner deleted the account in the console, the tombstone is past 13 months, or the device was unlinked before this deploy.

8. **Docs and small points:**
   - After a DELETE on another device, the device still says "You logged in on another device", and LOG IN can never work there.
   - `data-retention-and-security.md:31` still says wrong keys are counted per name; they are now counted per asking account only.
   - The notes say "rolling" and "wrong tries"; the window is fixed and counts every try.

**Checked and sound:**
- **Gold:** no new way to double or lose it.
- **Quiet new accounts:** none from the guest rejoin, PLAY ONLINE, LOG IN or after DELETE. Old builds get a 403 error, never a new account.
- **DELETE leftovers:** they are disclosed: tombstones for 13 months, other accounts' pair windows for 2 days, the asking account for 13 months.
