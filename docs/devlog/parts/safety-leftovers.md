# Safety leftovers: M5 Task 4's F1 and the M4 review's B and H (notes, 2026-09-25)

Three open findings, each test-first (RED seen for the reason named, then GREEN): **F1** from the store readiness
pass (`docs/devlog/parts/m5-task-4.md`), **B** and **H** from the M4 whole-branch review
(`docs/devlog/parts/m4-task-10-review.md`, "Not fixed"). Done by a background agent in its own worktree
(`worktree-agent-aa0d24bfb86da3d1b`), with `lead-merge` merged at the start (`c3c2b0d`, module 0.2.10 live) and again
before the final suites. No editor, emulator, adb or godot-mcp; neither the live server nor the Docker development
server was touched (the GUT suite's own relay tests probe the development server as always, read-only).

**Server module 0.2.11** (from 0.2.10): `match_players`. **The lead deploys it, before the next APK** (ruling 12).

## Fixed

| # | Finding | Fix | Tests (RED: why it failed first) |
|---|---|---|---|
| F1 | **Photo SHARE had no grown-up switch.** A child could send a photo out of the game through the phone's share sheet with nobody's say (M3 Task 16's ruling 7 asked M4's parent settings for one). | Spec §5.9, §5.14, §14.14, §17.2 first. `ProfileData.photo_share` (`auto` / `on` / `off`, saved in `profile.json` and the backup, like the Theater's switch) and `PhotoRules.may_share(band, switch)`: `auto` is on for 13+ only (no band or an unknown one: off). `PhotoMode.share_allowed` (a Callable, default the Profile autoload) is read at every `open()`: where it is false the SHARE chip (FOLDER on desktop) is hidden and `share()` does nothing; the shutter still saves. `PhotoMode.sharer` wraps `PhotoShare.share` so tests never open a real sheet or folder. The grown-up area's **PLAY TIME** tab is now **PLAY & PHOTOS**: under today's play time, "Photo sharing" ON / OFF (the effect lit: from the band until a grown-up picks one) and a hint line; a tap saves at once through the service's profile (`OnlineService.profile` / `save_profile`, the Profile autoload's in the game), no online account needed. | `tests/unit/test_photo_share_switch.gd` (5: the rule, a grown-up's choice, junk switches, the profile, the backup) and `tests/integration/test_photo_share_grown_up.gd` (7: photo mode only saves where it is off, SHARE where on, read at each open, the default from the profile; the page off for a child, a grown-up's ON reaches photo mode, 13+ on and a grown-up's OFF). RED: parse errors (no `PhotoRules.SHARE_AUTO`, `may_share`, `photo_share`, `share_allowed`); then, with the fields in, the three page tests (no PLAY & PHOTOS tab, no switch). The grown-up tests that pressed PLAY TIME press PLAY & PHOTOS. The page is 432 of 534 px tall; the tab row keeps its 1,206 px. |
| B | **Online, the host's chat names and bands were the guests' own word** (`chat_join`): a modified guest could show another player's name (chat lines, name tags, the player card, trades) or claim 13+ for free text on the relay and trades with strangers; the relay stood in for the team room when it could not open. | Server: `match_players {"match_id"}` (`server/modules/src/server/social.ts`), host only (the hosting record and presence, as `Economy.target`): everyone in the relayed match now with `user_id`, `username`, `age_band` (`AccountRules.effectiveBand`) and `chat_level` (`AccountRules.chatLevel`). Game: `OnlineService.match_players`, `MatchRoster` (`net/match_roster.gd`: `lookup(peer)`, and `players_from` reads the answer carefully: a name that is not a username is none, a band that is not one is under 13, a level that is not one is off). Session section "M4 Task 10 review B": an online host (`_f_online_host`) registers a guest from the roster (`_b_join_from_server`), under 13 with no name until it answers, "Player" and under 13 when it can't say; a guest who leaves meanwhile is forgotten (`_on_chat_peer_left` for a name on its way, a per-ask number). Online the relay (`_host_chat`) passes quick phrases only for everyone ("Chat is resting for now. Quick phrases still work!" for anything else) and nothing from, and `chat_recipients` nothing to, a player whose server chat level is off (`_chat_levels`). `ChatPanel`: online (`_online_world`) no relay stand-in: when the room can't open (sign-in, the server, not in the match yet) a kind line says the chat rests, the wheel only (even 13+), typed words wait (they still reach the child's own bot friends), the wheel's phrases go through the host, the room is tried again whenever the chat opens (`_open_room`, `_retry_room`, one try at a time), and a relay line that is not a quick phrase never shows. LAN is unchanged. | Node `server/modules/test/match_players.test.ts` (5; RED: `S[fn] is not a function`). GUT `tests/unit/test_match_roster.gd` (3), `tests/integration/test_host_players_online.gd` (9), `tests/integration/test_chat_panel_online.gd` (4 new). RED: `MatchRoster` not declared; the old panel relayed "anyone want to build?", showed no resting line, never retried and showed a relay line that was not a phrase. The fake server answers `match_players` as the module does. |
| H | **The relay's "only other player" shortcut and a join** (suspected, not reproduced). | Reproduced in `tests/unit/test_relay_bridge_targets.gd` (a socket double records the addon's own sends): Ann's packets for the only other player went without presences; Bob's join made the addon greet him at once (`_host_add_peer` writes straight to the socket), and the frame's run (or a queued message held by flow control) then went without presences after that, so Nakama would relay it to Bob. Fix: every "everyone else" message remembers its packet and the players it was made for (`_others()` at enqueue, `RelayQueue.push`'s `extra`); a join (while connected) first ends the frame's run and names those players, still here, on every waiting such message (`RelayQueue.retarget_everyone`, `RelayBridge._name_everyone_waiting`); none left: it goes nowhere. New packets after the join name their player as before (three players: no shortcut). | `test_relay_bridge_targets.gd` (4 new: the frame's run, a held message, new packets after the join, a held message whose players all left). RED: `targets` null and no presences in the envelope after the join (3 of 4; the "new packets" one passed already, as expected). The development server's relay tests (`test_relay_flow.gd`, 6, incl. two guests' order) pass with it. |

## Rulings (decided on the owner's behalf; cost if wrong)

1. **The switch is on the PLAY TIME page, renamed PLAY & PHOTOS**, not on ONLINE PLAY next to the online switches.
   ONLINE PLAY's switches show only when signed in with consent (13+ or verified), and no under-13 child has an online
   account today, so they could never reach it; the PRIVACY page had 31 px left (503 of 534). The spec calls the
   device's page the parent corner ("play time, … switches", §5.14). *Cost if wrong:* moving the row is small; the tab
   name is one string and five test lines.
2. **`auto` follows the band: on for 13+, off for under-13** (the task's ask). *Cost:* a 13+ player shares until a
   grown-up turns it off; the lawyer's question (`pre-launch-checklist.md` §4.3) now asks whether 13+ should start off.
3. **ON / OFF only, no "AUTO" button**: the page lights the switch's effect; once a grown-up picks, the band no longer
   changes it. *Cost:* a parent's OFF for a 12-year-old stays off after the owner lifts the band (intended); a parent's
   ON stays on if the band gets stricter (the grown-up chose it).
4. **The switch lives in the profile and travels with the backup** (newer copy wins, like the Theater's), not
   "stricter wins" like the band. *Cost:* none seen: a grown-up's change makes this phone's copy the newer one.
5. **Saved at once, no SAVE button** (ONLINE PLAY's SAVE is a server call; this is the phone's). *Cost:* none.
6. **Desktop's FOLDER hides with SHARE** (the desktop build is for developers). *Cost:* none for players.
7. **Photo mode reads the switch at every open**, not live while open (the grown-up area is not reachable while photo
   mode is open). *Cost:* none.
8. **Until the server answers, a guest is under 13 and unnamed** (no name tag, no "joined" line yet, trades see
   "friends only" between two 13+ players in that moment). *Cost:* about one round trip (100–300 ms) of a nameless
   guest.
9. **When the server can't say, the guest is "Player" and under 13, and the host does not ask again.** *Cost:* a real
   13+ guest shows as "Player" with under-13's relay rules until they rejoin. Rare: the host is online and the guest
   came in through the same server. Never the guest's own word, which is the point.
10. **Online the relay carries quick phrases only, for everyone**, even a 13+ player with text chat whose room could
    not open; typed words wait for the room. *Cost:* no free text while the team room is down (which usually means the
    server is struggling anyway). An online game also drops a relay line that is not a quick phrase (only a modified
    host would send one).
11. **The room is tried again when the chat opens** (the bar or the wheel), not on a timer, one try at a time; the
    resting line shows once, at the first failure. *Cost:* a child who never opens the chat never retries (they do not
    chat either).
12. **Deploy 0.2.11 before the next APK reaches players.** The new host game asks `match_players`; on 0.2.10 the call
    fails and every guest is "Player" and under 13 (safe, but wrong names). 0.2.11 changes nothing for older games
    (they never call it). *Cost if the order slips:* guests named "Player" until the server is updated.
13. **Trades and pets read the same registration** (`_chat_bands`: `_pt_refusal`, `pet_band_of`), so they follow the
    server too; the trade friend lists (`_pt_friends`) stay each guest's own word (M5 Task 4's F5, accepted).
14. **`match_players` lists everyone present, the host too**, with usernames: only players already in the host's
    world, whose names the host's game shows anyway. *Cost:* none seen.
15. **H: a join names the players a waiting "everyone" message was made for**, so broadcasts made before the join go
    to the players present then, not to the newcomer, as ENet's broadcasts reach the peers connected at the send. The
    newcomer's state comes from the host's join flow. *Cost:* none seen (the relay tests with two guests pass).
16. **H's remaining window (not fixed):** a message already handed to the WebSocket before the join was seen. From the
    host it arrives before the greeting (the same socket, in order), so the newcomer drops it (no peer id for the host
    yet; the addon logs "isn't assigned a peer id" on the newcomer). From a guest (its messages for the host, the only
    other player) it could reach a newcomer who already knows that guest's peer id; guest-to-host RPCs check
    `is_host()` where they land. *Cost if wrong:* a stray guest packet on the newcomer in that moment. The full fix is
    the review's first option (always name the target while fewer than 4 play), which costs the presence on every
    message in two-player games, against the 50 kbit/s per-guest budget.

## Store documents

The Data safety **types do not change** (photos are never collected; the share is the child's own action, now behind
a grown-up's switch for under-13). Updated: the Photos row in `docs/store/data-safety.md`, the Families checklist's
"links out of the app" in `families-and-rating.md`, the photo paragraph of `privacy-policy.md`, the camera line of
`childrens-privacy-notice.md`, F1 and the lawyer's question 3 in `pre-launch-checklist.md`. The public pages were
regenerated (`python3 tools/make_store_pages.py`: only the privacy page's photo paragraph changed): **the lead
deploys `server/deploy/site/`**.

## Final suites (after merging `lead-merge` `6405240` last: M5 Task 2's polish pass; then `--import`)

- Node (`npm --prefix server/modules test`): **280 tests, 280 pass** (275 before: `match_players.test.ts`'s 5).
- GUT (`tests/run_tests.sh`): **653 scripts, 6,007 tests, 6,005 passing, 2 risky/pending** (the voxel "did not
  assert" checks), **0 SCRIPT ERRORs, exit 0**, 965 s.
- English only (owner #52): the new words are English; no translation was added.
- The integration tests (`test:server`) were not run: they need the development server on 0.2.11 (the lead deploys).

## Deploy (the lead; module 0.2.11)

1. On the development PC: `npm --prefix server/modules test`, then `server/dev.sh reload` and
   `EASYCRAFT_SERVER=http://127.0.0.1:7350 npm --prefix server/modules run test:server` (the integration tests expect
   0.2.11; `nakama.server.ts` has a new `match_players` test with a consented child guest).
2. `server/deploy/kit.sh pack`, copy it to the server, unpack it, `./kit.sh update`, then `./kit.sh check` (the `rpc`
   line shows 0.2.11). Deploy the regenerated `server/deploy/site/` with it.
3. Then the next APK (ruling 12). F1, B's game side and H ship with it.

## What the lead should check (emulator)

1. **F1, under-13 profile:** SETTINGS → GROWN-UPS → the gate → **PLAY & PHOTOS**: "Played today", then "Photo
   sharing" with OFF lit and the hint line; the page and the tab row fit. In a world, PHOTO: no SHARE chip; the shutter
   saves ("Saved…", the photo in the gallery's EasyCraft album).
2. **F1, a grown-up's ON:** back to PLAY & PHOTOS → ON ("Photo sharing is on."); PHOTO again: SHARE shows and opens
   the share sheet. OFF again hides it. A 13+ profile starts with ON lit.
3. **B, online (after the deploy), emulator host + desktop guest, 13+ friends:** the guest's name tag and "… joined
   the game." show the guest's account name; team chat works as before (no "Chat is resting" line; `adb logcat` has no
   "CHAT team room not open"). With an under-13 consented guest: the host's player card and trades treat them as under
   13 whatever their game says.
4. **H:** the online round with three players (host, then a second guest joining while the first plays): no stray
   actions on the newcomer (its inventory and gold are its own), as in M4 acceptance.
5. The whole online round of M4 acceptance (Task 9) still passes.
