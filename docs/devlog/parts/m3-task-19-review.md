# M3 Task 19 — the whole-branch review and fix pass (single player and LAN)

Plan: `docs/superpowers/plans/2026-09-24-m3-worlds-of-wonder.md` Task 19. Worktree cut from `m2-survive-the-night`, with
`lead-merge` (release 0.4.0) merged in first and again before the final suite.

## How the review was done
- Scope: the M3 code merged since M2 (`git log m1b-underground..lead-merge`, about 123,000 added lines in `core/`,
  `world/`, `entities/`, `scenes/`, `ui/` without `ui/online/`, `autoloads/` without the online sections, `tools/`).
- Nine read-only reviewers, one per area, with one brief (the host/guest model, the fixed `gh_world_key` and babble
  bugs as examples, block ids past 255, words on screen, the children's rules, §8's performance rules; only findings
  traced end to end, confidence 75 or more): Session's M3 sections (two halves), `sandbox.gd` and `hud.gd`, the world
  directors, save and load, `entities/`, the pure rules and words, `ui/`, the generators and block ids. Every finding
  was checked again by reading the code, then fixed test-first or written down here.
- Own checks: the native byte searches against every block id past 255, the chat command runner (no reviewer had it),
  `Audio`, `Music`, the books director, every `any_peer` RPC outside Session (all check the host and use the sender id).
- Runs: `tools/net_test.sh --lan` (PASS, 0 errors on both sides); a LAN Survivor run with `--trade` (host first, the
  guest joining late: found fix 2 below); `tools/books_smoke.gd` on the merged tree (25 ok, no errors).

## Fixed (each test-first: RED for the right reason, then GREEN)

| # | What was wrong | Fix | Test | Commit |
|---|---|---|---|---|
| 1 | **A village roof was a lantern.** Block ids past 255 are two bytes in a copied box (low byte first); `MonsterDirector.find_blocks` matched the low byte alone, so ROOF_TILES (266 = 0x0A 0x01) was LIGHT (10): monsters kept away from every village roof (`lights_around`), and at night a child within 6 blocks of one was lit as if beside a lantern, so monsters saw them from far (`StealthDirector.light_around`, `StealthRules.light_level`). `BotRules.find_in_buffer` could not look for an id past 255 at all (256 found every air cell) | Both match the low byte and check the high byte after it | `test_m3_review_block_ids.gd` (5 tests) | `e206a38` |
| 2 | A LAN guest whose host left logged "The multiplayer instance isn't currently active" every physics frame of its 3 s goodbye (175 errors): `Session._physics_process` asked `is_host()` of the closed ENet peer (fly, M3 Task 8's tool slices, #37's trade checks) | A closed peer runs no host ticks | `test_m3_review_guest.gd` | `99fb080` |
| 3 | A buddy whose owner left a LAN game (a guest went home) followed another child for the rest of the game: `Buddy._find_owner` fell back to the last player it looked at (the M1b review's note said it froze) | It waits where it is, like a pet; a saved buddy is the host's again on load | `test_m3_review_buddy_owner.gd` | `0805d2b` |
| 4 | /summon's chat line put the animal's id into "%s called a %s!": owner #41's animals read "Pip called a arctic_fox!", "… a owl!", "… a polar_bear!" | "an arctic fox", "an owl", "a polar bear" | `test_m3_review_summon_words.gd` | `e6bf489` |
| 5 | Counts a child can make 1 said "Your team got 1 stars!" (Storm Run), "Best: 1 stars" (the GAMES page), "Copied 1 blocks!" (COPY and /copy) | `GameWords.end_storm`, `GamesPanel.best_words`, `BuildToolUser.copied_words` say the singular | `test_m3_review_plurals.gd` | `b91ec9e` |
| 6 | A chest mimic whose child left before its present (a LAN guest going home) was marked "gave its present" when it went back to sleep: nobody could wake that chest again in the world, and its present was lost | Only a present given uses the chest up | `test_a_mimic_whose_child_left_can_be_woken_again` (`test_tiny_world.gd`) | `2f7ff5a` |

**Georgian fixes withdrawn.** Three commits fixed Georgian words (lines a Label got as English pieces joined, the
universes' bosses in the Totem's words, pets and buddies named Pumpkin, Button or Bubbles shown as Georgian words, five
new ka.po lines): `54dc712`, `9030e8e`, `a96cad8`. At 17:57 the owner said the game is English only ("please dont build
game in georgian, i didnt ask it. remove it from game and never include"), and the lead is removing the language card,
the LANGUAGE setting, `ka.po` and its test. The three commits are reverted whole (English words were never changed by
them), so the lead's removal meets no Georgian from this task.

## Not fixed (written down for the lead)

| Finding | Where | Why not now | Proposed fix |
|---|---|---|---|
| A LAN guest can claim a quest story's, a board goal's or a present's Survivor gold without finishing it: the host checks only that the id is known, once per peer (quests) or a time gap (goals, presents) | `world/quest_director.gd:762` (`host_gold`), `:807` (`_rpc_gold`); `autoloads/session.gd:2684`, `:2711` | Each child's own game counts its own progress (spec: trusted LAN, Session's M3 Task 12 comment); the host can't see a guest's personal story. Needs a modified game to exploit | Let the host count the steps it can see (its `_arrivals`, co-op team events) and pay only chains it saw finish, or move the check to M4's server with the online wallet |
| The host's building-tool jobs have no cap: every LINE/FILL/PASTE request (each capped at 4,096 cells) is queued and written 8 ms a frame, so a flood of requests from one peer slows every frame until the queue drains | `autoloads/session.gd:3920` (`_tool_jobs.append`), `:4075` (`_rpc_build_tool`) | A child can't make requests faster than they drain (two taps per FILL; /fill is rate-limited); the same holds for `_rpc_request_set_blocks` (1,600 edits at once) | At most one or two unfinished jobs per peer (refuse with "Wait for your last build!") — **fixed by the lead** 2026-09-25: `TOOL_JOBS_PER_PLAYER` = 2, "Still building! Wait a moment." (`test_a_player_has_at_most_two_unfinished_tool_edits`) |
| Survivor's night records and Monster Wave's bests are capped at 16 players only when a save loads, in the order they were made, so a 17th friend's record is dropped at the next load (never more than 16 + 4 in the file, so no unbounded growth) | `world/survivor_game_director.gd:81` (`record_of`), `world/arena_director.gd:197` (`best_of`); `GameScores.clean_all`, `ArenaRules.clean_all` | By design of the cap; the host's own record comes first | Keep the most recently played 16 (a `last` time in each record) — **ruling (the lead, 2026-09-25): kept as it is.** Only a 17th different friend in one world loses a record, the host's own always stays, and the file can't grow; cost if wrong: that friend's best starts again. |
| When the host quits, the guest's own player leaves the tree before it is freed, and the Theater's `player_position` read its `global_position` once ("!is_inside_tree()") | `scenes/sandbox.gd:763` | One error line per host quit | `is_instance_valid(player) and player.is_inside_tree() and player.is_spawned()` |
| The team chat's and REPORT's `await online.…` touch the chat panel after a server round trip; leaving the world meanwhile resumes on a freed panel (a debug error, nothing in release) | `ui/hud/chat_panel.gd:224`, `:286`, `:668` | Online code (M4 reviewer's) | `if not is_inside_tree(): return` after each await, as elsewhere in the file |
| Every buddy looks the players group up each host physics frame (`get_nodes_in_group`, one small array each; animals, monsters and bots share one lookup a frame) | `entities/buddy/buddy.gd:301` | At most 10 buddies and 4 players: a few µs a frame | The same static per-frame cache as `Animal._players_now` |
| A chest mimic's sleep sparkle is sent in the frame the host frees it, so a guest may not see it (§8, "a node the host frees in the same frame") | `world/tiny_director.gd` `_sleep` | Cosmetic | Free it a moment after `sleep_away` |
| A few more "1 blocks" lines, rarer: a one-block stamp or gift ("This one? %d blocks", "From %s\n%d blocks") and /secret's "Nearest %s: %d blocks away" | `ui/building/my_stamp_bar.gd:111`, `ui/gifts/share_panel.gd:132`, `ui/gifts/gifts_page.gd:41`, `world/secret_director.gd:177` | A one-block build or a secret 1 block away is unlikely; the gifts are online UI | The same singular as `BuildToolUser.copied_words` |

## Found clean (reviewers and own checks)
- Session's 82 any_peer RPCs check the host and use `get_remote_sender_id()`; reach, ids, NaN, ownership and costs are
  checked before anything changes; trading's swap re-checks both bags and is atomic; crafting, gathering and the
  ledgers refuse first.
- `sandbox.gd`: every `meta.` use is host or solo only (or guarded); `_on_spark`'s order is secret shape, then wake
  kind, then a plain buddy, and `Buddy.setup` agrees; every saved field is read back.
- Save and load: every `from_json` checks types, finiteness and shapes; round trips keep every field; the lists that grow
  with play are capped; `JsonStore.write_atomic` survives a kill mid-write.
- Generators: shared caches under mutexes, seeds from coordinates only, floor division for negative coordinates, boxes
  clipped to their chunk, the v1 meadows untouched (terrain v2 is its own class). `BuildCodec`, `RewindLog`,
  `EditCodec`/`EditLog` and `ShowcaseArea` keep ids past 255.
- Children's rules: no guilt or pressure words found outside the existing tests' reach; nothing random is sold.

## For the lead on emulator-5554
- **A village at night** (a new world, terrain v2, Survivor): monsters come near village roofs again, and the HUD's
  stealth eye stays low for a child crouching in the dark beside a house (roofs counted as lanterns before).
- **LAN** (two devices or instances): a guest's buddy stays where it is when the guest leaves; the guest's log has no
  flood of "multiplayer instance isn't currently active" when the host quits.
- **Words**: `/summon owl` in a Sandbox says "… called an owl!"; COPY on a single block says "Copied 1 block!".

## Suite
- 17:50, before the owner's English-only decision (Georgian fixes still in, `lead-merge` of 17:45 merged): 602 scripts,
  5681 tests, 5679 passing, 0 failing (the 2 are #45b's tests that don't assert), exit 0.
- 19:10, after the Georgian fixes were reverted, the English fixes added and `lead-merge` `8445d17` (#51 MOBS, #52
  English only) merged: 604 scripts, 5665 tests, 5663 passing, 0 failing, exit 0.
- The final run, with `lead-merge` `33c8356` (#53 weapon strength) merged too (load 12–23): 605 scripts, 5673 tests,
  5670 passing, 1 failing, 2 risky. The failure is the known flaky wait `test_visit_world.gd`
  `test_nothing_can_change_in_a_visit` (M3 dev log 13:40, "for M5"; M4 I's visits, untouched here): alone it passed
  6/6 twice right after.
