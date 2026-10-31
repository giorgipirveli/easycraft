# Owners #104/#105: the second adversarial review (2026-10-16 00:56)

Branch `worktree-agent-a45831f837d05a838` at `8f4fcde6`, read-only, a separate agent. **Verdict: not merged; a fix round.**

I reviewed branch `worktree-agent-a45831f837d05a838` at 8f4fcde6 against `lead-merge` and changed nothing in the repo. I found one HIGH, four MEDIUM and several LOW issues. Two LOW points are worded in the store drafts and are also listed under the docs finding (LOW 7).

To check them I wrote throwaway Node tests in a scratch copy of the server module (`npm test` there), and ran one probe against the private test server on port 7500 (running module 0.2.20). The probe deleted both accounts it made.

## Findings, worst first

**1. HIGH: an unlinked or deleted device can still quietly create a new account (CONFIRMED by reading the code; not run in Godot).**
- **Where:** `autoloads/session.gd:1674` and `:1693`. `host_online` and `join_online` call `NakamaLink.sign_in` without a `create` value, and it defaults to true. The guest's automatic rejoin (`_on_online_closed` → `_a_link_lost` → `_a_try` → `join_online`) goes through the same call.
- **Steps:**
  1. The phone is a guest in a friend's online world.
  2. The computer logs in with the password. `signOutOthers` closes every socket of the account, including the phone's match link.
  3. The phone's rejoin signs in with its now-unlinked device id and `create=true`, so Nakama makes a new empty account with that id.
  4. The phone's `OnlineService.sign_in(create=false)` then succeeds against that new account. `logged_out` is never set, so the logged-out card never shows; the child gets the claim screen instead.
  5. If the child claims a new name, the first wallet sync sends the phone's gold up while the old account keeps it, so the gold is doubled.
- **Same path after DELETE:** a guest device of a deleted account rejoins, the deleted name is free again, and the child can re-claim it. That is the "it is not deleting" bug (#104) again.
- **The notes are wrong here:** they list this as a residual "protected by the flow", but the rejoin happens after the unlink.
- **Fix:**
  - Pass `create=false` from Session whenever the device id file already exists.
  - Better, on the server: `signOutOthers` and `Deletion.run` record each removed device id (salted hash, system user), and `beforeAuthenticateDevice` refuses creation for a recorded id. This also covers old builds.

**2. MEDIUM-HIGH: `known_device` works like a bearer token and skips the name brake entirely (CONFIRMED by test).**
- **Where:** `server/modules/src/server/passwords.ts:306`, `:315`, `:319`, `:328`. `knows()` accepts any id in `password_devices`, and that list keeps ids that were unlinked (logged-out or lost devices) for good. A "known" request skips the network window, the name's soft cap and the "someone tried" note.
- **Test:** using a logged-out phone's old id as `known_device`, with a fresh asking account every 5 tries, 2000 wrong guesses were checked in one simulated hour from one address. There were no slow-downs and no note to the account.
- **Where an old id can come from:** a lost phone the family logged out (the very case this is meant for), or a shared or school computer's browser storage.
- **Fix:**
  - Drop an id from `password_devices` when SIGN OUT OTHER DEVICES unlinks it.
  - Give the known path its own server-side limit keyed by the known id (for example 5 per 15 minutes, across every asker).
  - Still send the "someone tried" note for known-device failures.

**3. MEDIUM: the brake can be turned into a lock-out for new devices (CONFIRMED by test).** This does not match "never a lock" or "a child is never more than 10 minutes from a try".
- **Where:** `reserveSoft` gives one shared slot per brake period. A refused try costs the attacker nothing, because every counter it reserved is given back.
- **Test:** someone polling once a second took every slot. The child's new tablet, retrying 3 seconds after each wait it was told, got 706 "slow down" answers in 23.5 hours and never got in.
- **The key path is also blockable:** its existing per-name lock (5 wrong keys per 15 minutes, from #67) blocked 13 of 14 tries with the right key over about 1.6 hours. So "the key always works" does not hold under attack.
- **Fix:**
  - Give each asking device its own brake turn (per asker, per name) instead of one global slot.
  - Let the key path's lock count only per asking account, not per name.

**4. MEDIUM: the stated numbers are about 4.7 times too low (CONFIRMED by test).**
- **Where:** `server/modules/src/rules/password_rules.ts:164-166`. The brake's start time resets whenever `braked_until` has passed, which happens after a 2-hour pause.
- **Test:** pausing 2 hours just before each day is up keeps the brake at 2 minutes forever. Measured per day: 739, 680, 680, 680 … about 6,860 in 10 days. A 10,000-word list takes about 15 days, not "about 2 months".
- **Fix:** keep the start time across pauses and let it decay slowly (for example halve it per idle day), or set the brake from a rolling 24-hour count. Then correct the numbers in the notes and in `docs/store/data-retention-and-security.md`.

**5. MEDIUM: an online player can come back on Who is playing? with one tap, no password (code path CONFIRMED; trigger is timing-dependent, PLAUSIBLE).**
- **Where:** `net/account_switch.gd:175`. A kept player's `online` flag is `status == ONLINE and claimed()` at the moment of the switch, not whether the slot has an online account.
- **Steps:**
  - The connection drops between LOG OUT's save and the tap on NEW PLAYER or another player. The slot is kept as `online: false`, and from then on one tap brings it back with its credential, which is still linked on the server.
  - A second route: an upgraded player whose `account_name` is still empty, started offline. The menu shows LOG IN; its BACK opens Who is playing?; NEW PLAYER then records the slot the same way.
- **Fix:** record `online` from `prefs.account_name != ""` or `has_online_link()`.
- **Related, LOG OUT is local only:** the slot's device credential stays linked on the server. Since coming back already needs the password, LOG OUT could unlink that id and delete the file at no cost to the child.

**6. MEDIUM-LOW: gold and progress are copied into another account from PLAY ONLINE (CONFIRMED by reading the code).**
- **Where:** `net/online_service.gd:2883` (`log_in_here`) has no name check. On a logged-out device, PLAY ONLINE fills in the old name, but the field can be edited.
- **Steps:** LOG IN as another account Z. Slot Y's profile merges into Z's backup. Z has no wallet marker yet, so the first sync takes `max(local, server)`. Z gets Y's gold while Y's other device keeps it.
- **Fix:** if the typed name is not `prefs.account_name`, route through `AccountSwitch.log_in`, which opens a new player slot.

**7. LOW items**
- **Timing reveals names (measured on the private server):** a name nobody has answers in 11-19 ms; a real name with a wrong password takes 740-820 ms (bcrypt). An account without a password also answers fast. Fix: run one bcrypt compare against a dummy hash on every path.
- **Who is playing? sends the wrong `known_device`** (`online_service.gd:2823`): it reads the current slot's id, not the picked player's. The child's own kept slot is treated as a new device.
- **CHANGE PASSWORD with an empty OLD silently replaces the family's key** (`online_service.gd:2804`): it makes a new sign-in key, the written-down one stops working, and the new one is never shown. This also means any logged-in session past the parent gate can change the password, and so can DELETE.
- **Network window:**
  - The full IPv6 address is used; it should be the /64 prefix.
  - 30 wrong tries an hour per address can lock a whole school network: new-device typos count, and the network window applies to every new device.
  - A device's own typos lock it for 15 to 60 minutes (the pair and asker windows), against the "longest wait 10 minutes" line.
- **Password rules:**
  - The game's own example `moon7tiger` is accepted (test confirmed). Children will copy it; add it and its variants to COMMON, or change the example.
  - bcrypt's 72-byte limit is not checked: up to 64 multi-byte characters can be over 72 bytes, so a long non-ASCII password may fail with an unclear error.
- **Wrong words after a DELETE on another device:** a new build shows "You logged in on another device", and LOG IN can never work. The slot can only be left via the LOG IN page's BACK, then NEW PLAYER, then REMOVE.
- **Stale comment:** the comment at `keys.ts:84` says old session tokens keep working; they don't (see below).
- **Docs:**
  - "At most 144 a day" and "a key always works" are not true (findings 3 and 4).
  - The device's leftover asking account (`login_device.json`, kept 13 months) is not disclosed in the privacy policy.
  - The `password_pair:<id>` windows stored on other accounts outlive a DELETE by up to 2 days.

## Checked and sound
- **One device at a time, on the real server:** after a password LOG IN the old phone's session token answers 401 on RPCs and on GET `/v2/account`, its refresh token is refused, and signing in with its device id and `create=false` gives 404. The honest client stops calling once its socket closes.
- **Counting:** every try is counted before the check and fails closed. All spellings of a name share one window. A correct login gives back only its own try, so no credit builds up from your own logins. Version races hold (the branch's tests).
- **Storage:** hashes are bcrypt, server-only, and no RPC exports them. Client storage writes and deletes are guarded.
- **Network address:** Caddy (default `trusted_proxies`) replaces any client-sent X-Forwarded-For, and port 7350 is not published.
- **DELETE:** needs the password, counted in its own window; `Deletion.run` removes the `account` and `limits` collections, which include the password and devices objects.
- **Client side of DELETE and the main sign-in:** the device wipes the player and keeps the worlds, and the menu's sign-in uses `create=false`.
- **LOG OUT:** no gate on any of its three entry points; it saves the profile, gold, waiting reports and codes first, and refuses offline.
- **Busy and stale guards:** `busy()` and the session counter stop late writes after a switch.
- **Rules match:** the password rules are the same in the game and on the server; the move by code is off on both sides.

## Throwaway tests
All are in `/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/review105/`:
- `modules/test/zz_review_brake.test.ts` (finding 4)
- `modules/test/zz_review_snipe.test.ts` (finding 3; the key-path test there fails its own assertion, but its output shows the 13 of 14 blocked tries)
- `modules/test/zz_review_known.test.ts` (finding 2, and the `moon7tiger` check)
- `probe/session_probe.mjs` (the real-server session and timing probe)
