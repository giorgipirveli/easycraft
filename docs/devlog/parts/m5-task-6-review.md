# M5 Task 6 — the whole-game review and fix pass (notes, 2026-09-26)

Plan `docs/superpowers/plans/2026-09-24-m5-launch.md` Task 6. Done by a background agent in its own worktree, with
`lead-merge` merged at the start (`34a1f96` = main, the 1.0.0 release candidate) and again at the end (`ce69f5f`, docs only). No
editor, emulator, adb or godot-mcp; neither the live nor the Docker server was touched. **No server change** (module
stays 0.2.11). English only (owner #52): the new words are English, nothing was translated.

## Scope and how it was done
Everything merged since 2026-09-25 17:00 that no reviewer had read: M5 T1 accessibility, T2 art and audio polish, T3
performance and size, T4 store readiness (the PRIVACY page), M3 T15 the tutorial with Pip, owner #51 (MOBS), #52
(English only), #53 (weapon strength), the lead's "safety in the world" (`PlayerCard`, `Session.host_remove_guest`, the
server's `remove_guest`), the wild meadows' `_generate_by_chunks` and the bubble's pop. The earlier reviews' notes
(`m3-task-19-review.md`, `m4-task-10-review.md`, `m4-review-leftovers.md`, `safety-leftovers.md`) were read first so
nothing is reported twice.

- **Own review:** the safety pieces end to end (card → TradeDirector → Session → OnlineService → the module's
  `remove_guest`; LAN and online), #51/#52/#53, T3 (LOW, pages, hot paths, the start), T4 (the PRIVACY page, the trust
  promise's six lines against the game), the generator fix and the bubble; the tutorial director read in full.
- **Three read-only reviewers** (at most two at once, the owner's cap of three agents): the tutorial and its seams; T1
  and T2 and their seams (LOW × Reduce motion, captions, left hand, text size); then the M5 hooks' lifecycle across
  worlds, the menu and the pause menu. Every finding was re-checked here by reading the code, then fixed test-first
  or written down below.
- **Runs:** the baseline suite on `34a1f96` (653 scripts, 6007 tests, 6005 passing, 2 risky, exit 0); the tutorial
  smoke run on the fixed tree (`tools/smoke_all.sh tutorial`: PASS, 24 checks, all 211 cells back); a probe of every
  generator's off-grid boxes against the real 16³ chunks (5 generators × 4 boxes: 0 cells differ).

## Findings

Severity: **high** = a crash, lost saves or a child's safety at risk for many; **medium** = a real bug players will meet
or a safety feature that doesn't hold; **low** = rare, cosmetic, or a hardening. Lines are as they were before the fix.

| # | Severity | What was wrong | Where (file:line) | Fixed? | Test (RED: why it failed first) | Commit |
|---|---|---|---|---|---|---|
| 1 | medium (safety) | **A player the host removed on LAN could join straight back.** Online the server strikes a removed guest off the invite list; on LAN `host_remove_guest` only dropped the connection, so the same game could JOIN again at once and REMOVE meant nothing there (spec §17.3). | `autoloads/session.gd:4898-4918` (`host_remove_guest`'s LAN branch), `:2247` (`_a_peer_connected`) | **Fixed.** The LAN host remembers the address a removed player's game connected from; while it hosts, a new connection from there gets the same kind words ("The host asked you to leave their world."), its hello and ready are not heard, and the link drops 0.3 s later. The next `host_lan` forgets. | `tests/integration/test_m5_review_lan_remove.gd` (2, real ENet on this machine; RED: the second connection stayed, status CONNECTED) | `c8f3e17` |
| 2 | medium (accessibility, merge seam T1 × T15) | **Pip's step card ignored TEXT SIZE BIG.** M5 Task 1 grows every word a child reads while playing; the tutorial card (merged the same evening) kept 22 px words (a plain font override), so a child who chose BIG got every line bigger except the tutorial's instructions. A plain `TextSize.mark` would have grown the card to 251 px and into the crosshair. | `ui/tutorial/tutorial_card.gd:51` | **Fixed.** The words are marked (22 → 28 px at BIG); at BIG the step's picture and the dots step aside and the words take their width (288 px), so the card keeps its NORMAL box (370 × 143: clear of the HUD, above the crosshair). A change in SETTINGS while it plays applies at once (`Game.settings_applied`). | `test_tutorial_ui.gd::test_the_cards_words_grow_with_text_size_big_and_it_keeps_its_box` (RED: 22 instead of 28) | `e6af399` |
| 3 | low (cheat path, save) | **The tutorial could give a child's blocks back twice.** The X (or the end) put the child's own blocks in the playground back in their bag at once, but their cells went back a batch a tick (about a second) while the world's meta kept the whole record until the last cell. A game saved and closed in that second (SAVE & QUIT right after the X) found them still in the world at the next start and gave them back again: blocks built into the playground doubled (a replay from SETTINGS makes it repeatable). | `world/tutorial_director.gd:435-445` (`_put_back`), `core/tutorial/tutorial_props.gd` (`clear`) | **Fixed.** `TutorialProps.clear` lists the cells whose blocks go back first (`theirs`); `_put_back` writes them in the same frame the blocks reach the bag, the rest a batch a tick as before. | `test_tutorial_director.gd::test_blocks_given_back_are_never_given_twice_after_a_close_mid_clearing` (RED: 19 planks instead of 16) | `0257d01` |
| 4 | low (performance, merge seam #51 × T3) | **LOW's monster cap did not hold for summons.** LOW keeps at most 6 monsters near a child on a weak phone (night spawns); owner #51's MOBS tab brings one a tap through /summon, up to the game's 20: the busy case M5 Task 3 measured as over a phone's budget, in a few taps. | `world/monster_director.gd:224-233` (`summon`) | **Fixed.** On LOW a summon near a child who has 6 gets the existing words ("Lots of monsters here already!"); elsewhere and on MEDIUM / HIGH the game's caps only. | `test_monster_director.gd::test_low_caps_what_a_summon_brings_near_a_child` (RED: a 7th came) | `013631b` |
| 5 | low (hardening; reviewer's finding) | **A boss's win roar was guarded by a host-only flag.** M5 Task 2's roar plays on every screen when the synced phase goes DOWN, unless the boss was defeated, known by `_defeated`, which only the host's `take_hit` sets. A guest's copy that got DOWN with 0 hearts would roar over the defeat's crumble. Godot 4.7 never sends a change made in the frame a node is freed (§8), so guests can't hear it today; the reviewer's end-to-end claim was re-checked and does not reproduce, but the guard was wrong. | `entities/monsters/stone_golem.gd:612-614` (`_win_roar`; all five bosses) | **Fixed.** Guarded by the synced hearts (`hp > 0`) too. | `test_creature_moves_looks.gd::test_a_guests_copy_of_a_defeated_boss_stays_quiet` (all five bosses, with a control that a win does roar; RED: a roar tried for each defeat) | `a4caeb3` |
| 6 | medium (merge seam T1 × the Back chain; reviewer's finding, rated high there: in Survivor a knock-out behind the editor can cost the child what a knock-out costs) | **Android Back went past MOVE BUTTONS.** Android's Back is `NOTIFICATION_WM_GO_BACK_REQUEST`, sent to every node, not the `ui_cancel` the editor listened to (Escape only). In a world (pause → SETTINGS → BUTTONS & TEXT → MOVE BUTTONS) it fell through the sandbox's Back chain to `pause_menu.close()`: the game ran on, unpaused and unseen, behind the editor (a Survivor night went on). At the main menu it took the menu back to its first screen under the editor, freeing the SETTINGS panel that opened it. | `ui/hud/hud_editor.gd:145-148`, `scenes/sandbox.gd:558-586`, `ui/menus/menu.gd:178-184`, `ui/menus/settings_panel.gd:526-541` | **Fixed.** The editor closes itself on Back (nothing saved); the sandbox's Back chain (extracted as `go_back()`) and the menu ask `HudEditor.close_open()` first (it also counts an editor closed earlier in the same frame, whatever order the notification reaches them); an editor closes when the settings panel that opened it leaves the tree (a world closing under it, e.g. a LAN guest whose host quit). The reviewer's claimed engine error on DONE after the panel was freed was not reproduced here; the path to it is gone. | `tests/integration/test_m5_review_back.gd` (4: the editor alone, in a world under the pause menu, at the main menu, the panel leaving; RED: the pause menu closed and the tree unpaused, SETTINGS freed, the editor left open) | `f21a73a` |
| 7 | medium (merge seam T2 × the pause menu) | **Back during a load looked stuck.** Back while a world loads opens the pause menu, which lives on the world's layer (1), under M5 Task 2's loading card (layer 88, full screen, takes every touch). A paused game never spawns the player, so the card never went: the load looked frozen, and the pause menu could be neither seen nor touched until a second Back. Loads take 7–20 s on the emulator: a child presses Back. | `ui/loading/loading_card.gd` (no pause handling), `scenes/sandbox.gd:584-586` | **Fixed.** The card steps aside while the tree is paused and comes back on RESUME (`NOTIFICATION_PAUSED` / `UNPAUSED`). | `test_loading_card.gd::test_the_card_steps_aside_while_the_game_is_paused` (RED: the card stayed over the pause menu) | `f431749` |

## Not fixed (and why)

| Finding | Severity | Where | Why not now | Proposed fix |
|---|---|---|---|---|
| Online REMOVE when the server's `remove_guest` fails (no network at that moment): the guest's own game leaves on the host's RPC, but the server never struck them off the invite list, so they could come back through the invite (1 h) or the way back after a drop (24 h) while they are still friends. The host sees the error words; once the guest has left, their name tag (and so the card's REMOVE) is gone. | low (safety, needs a network failure at that moment) | `autoloads/session.gd` `host_remove_guest` (the online branch) | The host can still BLOCK them from FRIENDS (a block bars the invite and the way back since the M4 review's #4); a retry needs a queue that outlives the card. | Keep failed removals in a small host-side list and send `remove_guest` again at the next sign-in or match; or send it before the RPC to the guest and only then tell the guest. |
| LAN turn-away is by the address a game connected from: a removed player on another device (or after the phone gets a new address on the Wi-Fi) can join the same game again. | low | `autoloads/session.gd` `_lan_turn_away` | LAN has no accounts (by design, spec §7): the address is the only thing the host knows. The host can remove them again or stop hosting. | None needed while LAN has no accounts. |
| LOW's animal cap (12 near a child) does not hold for animal summons (`AnimalRules.SUMMON_CAP` 30 near a child, MOBS and /summon). | low (ruling) | `scenes/sandbox.gd` `summon_animal`, `core/rules/animal_rules.gd` `summon_refusal` | Animals cost far less than monsters (M5 Task 3's bench: 0.5–1.4 ms a tick for about 20, resting beyond 32 blocks); the monster cap was the one the bench showed over a phone's budget. *Cost if wrong:* a LOW phone slows with 30 summoned animals round the child. | The same `near_cap` check in `summon_animal` (`AnimalDirector.near_cap + 10`). |

## Checked and found clean

- **Safety in the world:** `PlayerCard` shows REPORT and BLOCK only online, REMOVE only to the host with that peer in its
  world; every step that can't be taken back asks first; the widest card (online host in Survivor: five buttons) is
  1,048 px on the 1,280 px canvas. `host_remove_guest` refuses a non-host, itself and an unknown peer, and reads the
  guest's Nakama id before any await. The module's `remove_guest` is host-only (the hosting record and presence),
  strikes the guest off `invited` whether or not they are still in the match, and its notification 107 is acted on only
  by a game in that very match (`Session._on_removed_from_world`); a report mutes, and muted or blocked players' team
  chat never shows (`OnlineService._readable`).
- **#51 MOBS:** Sandbox only (`counted` hides it in Survivor and in the Monster Wave arena); a tap runs the host's
  `/summon` (a grown-up's commands-off holds, the caps hold); the page fits above the hotbar (its test).
- **#52 English only:** no translation registered, `Lang.apply()` sets English, a 0.4.0 profile's `language` key is
  dropped on load, nothing reads it; the welcome cards and the settings no longer name a language.
- **#53 weapon strength:** `WeaponStrength` only measures; blasters, the rocket's area and the boomerang still never hit
  players, bot friends or buddies (`BlasterDirector`); the bubble's pop lands its stored hits on the host only, with the
  shooter's place for the coins (`Monster._blast_tick`); the practice slime still takes 0.
- **The generator fix:** every generator's off-grid box equals the real 16³ chunks cell for cell (probe above), so a
  copy over ground that is not loaded reads what the world will hold; the v1/v2 terrain of normal chunks is unchanged.
- **M5 T3:** `GraphicsPreset.view_distance` is used everywhere the view is set (player, world fog, the guest's view sent
  to the host, visits); the first start's preset comes only for a new profile; the hot-path changes keep behaviour
  (`CourseDirector` still stops a knocked-out or gone runner, 10 times a second); page UV scales follow each page's rows.
- **M5 T4:** the PRIVACY page needs no online account, opens only our own two pages behind the parent gate, and the
  six promise lines hold in 1.0.0: no ad SDK (the Theater's YouTube/TikTok players stay off by the server switch; the
  Families check before switching it on is in `docs/store/families-and-rating.md`), nothing random for money, no
  streaks (the Survivor night record is a score, not a daily streak), private by default (online off until a grown-up;
  photo sharing off for under-13), data small, reports reviewed by a person.
- **The tutorial (reviewer):** where it plays (`TutorialRules.plays_here`, never for a guest), the worker tasks (each
  waited once, closures over copies, never `self`), the reward once (`finish`, the backup merge ORs `rewarded`), the
  practice slime (pounces but never hurts; `spawn_monster` skips LOW's cap; not wild, so no sunrise puff), the loading
  card above the offer (layer 88, gone before the site search answers).
- **T1 / T2 (reviewer):** `Fx`'s live cap and far skip (bounded, stand-ins never tracked); LOW × Reduce motion never
  reaches 0 pieces; pooled bursts re-calm before each restart; the pounce and crouch are host-gated with the synced
  `winding`; the chorus and captions keep small bounded dictionaries; the HUD's sizes, mirror and moves; the profile's
  new fields are coerced and sanitised on load; universe art caches tiles from the pixel pages only.

## Suites

| Run | Scripts | Tests | Passing | Failing | Risky | Script errors | Exit |
|---|---|---|---|---|---|---|---|
| Baseline, `34a1f96` (the RC) | 653 | 6,007 | 6,005 | 0 | 2 | 0 | 0 |
| After fixes 1–5 (`013631b`) | 654 | 6,013 | 6,011 | 0 | 2 | 0 | 0 |
| **Final** (fixes 1–7, `05182fa`) | **655** | **6,018** | **6,016** | **0** | 2 | **0** | **0** (904 s) |

`lead-merge` moved during the final run (`ce69f5f`: one line of `docs/devlog/2026-09-26-release-1.0.0.md`) and was merged
after it (`fd31d63`); it changes only `docs/`, a `.gdignore` folder Godot never loads, so the suite's code is the merged
tree's, byte for byte. The two risky tests are #45b's that never assert (`test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`).
Node tests were not run: the server module did not change. Smoke: `tools/smoke_all.sh tutorial` PASS (24 checks).

## Is a 1.0.1 warranted?

**Yes: build 1.0.1 (code 11) before the first Play upload; not an emergency.** Nothing found crashes, loses a save or
changes a save's format, and the server does not change (module 0.2.11 stays; 1.0.1 works with it). But three things a
child meets on a phone are fixed only in the game: Back during a load (the load looked stuck), Back over MOVE BUTTONS
(a Survivor night ran on unseen behind the editor), and REMOVE on LAN (the safety feature the listing now names did not
hold there); plus TEXT SIZE BIG in the first-run tutorial. `docs/HANDOFF.md` lists the upload of 1.0.0 as the owner's
first step: if it has not happened yet, 1.0.1 can be the first closed-test build instead; if 1.0.0 is already up, 1.0.1
is the next closed-test release. No store document changes: no data type, permission or rating answer changes, and the
listing's lines still hold (REMOVE now holds on LAN too). A line for `whats-new`: "Back while a world loads now shows
the pause menu; Back in MOVE BUTTONS closes it; bigger words in Pip's lessons with Text size BIG; a player removed from
a Wi-Fi game can't come straight back." The lead measures nothing new: no frame cost changed (LOW's summon check runs
per summon; the loading card's pause check is a notification).

## For the lead on emulator-5554

The dev APK for anything timed, the phone APK only to install and run (DEVELOPMENT.md gotchas).
1. **Back during a load:** CONTINUE a world and press Back while the loading card shows: the pause menu shows (the card
   steps aside); RESUME: the card again until the player stands; Back → SAVE & QUIT from there works.
2. **Back over MOVE BUTTONS, in a world:** a Survivor night, pause → SETTINGS → BUTTONS & TEXT → MOVE BUTTONS, drag JUMP,
   then Back: the editor closes, the move is not kept, the pause menu still shows and the world stays paused (monsters
   still); Back again resumes. **At the main menu:** SETTINGS → BUTTONS & TEXT → MOVE BUTTONS → Back: the editor closes and
   SETTINGS stays; Back again: the main menu.
3. **Pip's card at TEXT SIZE BIG:** BUTTONS & TEXT → Text size BIG, HELP → PIP'S LESSONS, a solo Survivor world: the
   card's words bigger, no picture or dots, the card the same size under the toasts (clear of CHAT, BOOK, RIDE and the
   find arrow, above the crosshair) on 20:9 and 16:9; Text size NORMAL from the pause menu mid-lesson: the picture and
   dots come back.
4. **The tutorial's blocks once:** count the bag's planks, lay the bridge (3), press the X, at once pause → SAVE & QUIT,
   then CONTINUE: the planks are back once (not 3 more) and the playground is gone.
5. **REMOVE on LAN:** host on the emulator, a desktop guest over LAN (`tools/net_test.sh --lan --remove` for the removal
   itself); after the removal, JOIN again from the same guest: "The host asked you to leave their world." and back to
   its menu, nothing joins the host's world. Host a new LAN game: that guest may join again.
6. **LOW and MOBS:** SETTINGS → LOW, a Sandbox world, MOBS → slime seven times: the 7th says "Lots of monsters here
   already!"; MEDIUM: more come.
7. The smoke runs (`tools/smoke_all.sh`) on the final tree: this review ran only the tutorial's (PASS).
