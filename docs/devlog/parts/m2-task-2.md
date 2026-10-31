# M2 Task 2: knock-out, respawn, the pickup bag and the hearts HUD

Spec §12.3 and §12.15; plan Task 2. Built in a worktree cut from `m2-survive-the-night` at `2430164`,
in parallel with other M2 tasks. The lead merges. It also covers two requests the lead sent mid-task
(child-psychology research, `docs/design/`): a picture tip after each knock-out, and the knock-out part
of Cozy / Normal / Brave difficulty.

## What was built

- **Rules** (`core/survival/knockout_rules.gd`, `KnockoutRules`, pure):
  - Which ids drop: blocks only (`BlockIds.is_valid` and breakable). Tools, weapons, shields,
    potions, magic items and gold never drop.
  - `take_blocks` / `put_back` / `merge_items` / `clean_items` for bag contents (`[[id, count], ...]`).
  - Who may take a bag: `can_take` / `refusal`.
  - Where the bag lands: `bag_spot` (out of blocks, then down through air and water to the ground,
    at most 64 cells).
  - When a new drop merges into an existing bag: `merge_index`.
  - `respawns_at_home(mode)` (Survivor) and `drops_bag(mode, difficulty)` (Survivor, except Cozy).
  - `TIPS` / `tip(n, at_home, has_bed)` for the knock-out screen.
- **Health** (`core/survival/health.gd`): one addition, `protect(seconds)`. It holds protection
  (never shortens it) while a revived player is still on the way home.
- **Pickup bag** (`entities/pickups/pickup_bag.gd`, `PickupBag`, a `StaticBody3D`):
  - One merged, vertex-coloured sack mesh (built once with `WeaponModels.build`) and one shared
    emissive material. A shared box shape. Nothing is made per bag.
  - It bobs and spins slowly (two property writes per frame, no redraws).
  - Its collider is on the tap-only layer 16 (mask 0), so nothing bumps into it.
  - It keeps `owner_name`, `items` and its age (`set_age` / `age`; the age keeps counting in a
    restored world).
- **KnockoutDirector** (`world/knockout_director.gd`): named "Knockout" on every peer, with its own
  `MultiplayerSpawner` for bags.
  - Host: on `Session.player_hurt` with hp 0, it acts only when the host's own `Health` says knocked
    out (a stale or forged 0 does nothing).
    - A sleeper is woken first.
    - Survivor (not Cozy): the carried blocks drop into a bag where the player fell.
    - Everyone is told (`Session.broadcast_knockout`).
  - After `KO_TIME` (1.6 s): `Health.revive()`, the hearts are broadcast, and everyone hears
    `knockout_respawned`.
  - Protection is held until the player's game says it has arrived (`Session.send_knockout_arrived`,
    at most 15 s), then lasts 3 s more.
  - Bag requests are checked for reach (building reach + slack, eye to bag), ownership, and "not
    while knocked out". Every block that fits goes back into the inventory; the rest stays in the bag.
  - Save and restore: `to_save` / `restore`.
  - Every peer: the knocked-out avatar lies down (`Player.set_knocked_out`), with a star burst and a
    thud.
  - This game's player gets the fade with its message and one picture tip, then moves its own body:
    Survivor goes home (`Player.go_home`: the bed, or the world spawn without one), Sandbox pops up
    on the spot (`Player.pop_up`).
  - Other players get a toast: "Mia was knocked out!".
- **Player** (`entities/player/player.gd`):
  - `knocked_out`: the body holds still but still falls to the ground; `_physics_process` checks it
    right after `sleeping`.
  - `set_knocked_out(on)`: lying pose (`AvatarModel.POSE_SLEEP`) or standing.
  - `pop_up()`: unstuck plus a small hop.
- **Taps** (`entities/player/block_interactor.gd`): a tap or a hold on a bag asks for it first,
  whatever is in the hand. The physics ray uses the bag layer plus the world, so a bag behind blocks
  can't be tapped.
- **HUD**:
  - `ui/hud/hearts_bar.gd` (`HeartsBar`): 10 hearts of 2 HP, drawn full, half or empty.
    - A hurt flashes the full hearts and shakes the row for 0.45 s.
    - While hearts come back (5 s after the last hurt, until full), the heart being refilled pulses.
    - It is drawn as polygons and only redrawn while it moves.
  - `ui/hud/knockout_overlay.gd` (`KnockoutOverlay`): a dark red fade. The message is
    "You were knocked out!" (Survivor) or "Oops! Back on your feet!" (Sandbox), with one picture tip
    under it (a 72 px atlas icon and a short line). It fades out once the player is home.
  - `Hud.add_health_controls()` (called by the director): hearts at (194, 26), 307 × 28, right of
    CHAT and under the open chat bar. They are driven by `Session.player_hurt` for this game's
    player only and shown in both modes.
  - The **FPS label moved** from (194, 30), where the hearts go, to the bottom-right corner under
    JUMP.
- **Session** (`# --- M2 Task 2` section at the end):
  - Signals: `knockout_received(peer_id, at_home)`, `knockout_respawned(peer_id, at_home)`,
    `knockout_arrived(peer_id)` (host), `bag_take_requested(peer_id, bag_name)` (host) and
    `bag_inventory_changed(peer_id)` (host: a knock-out or a bag changed that inventory).
  - Functions: `broadcast_knockout`, `broadcast_knockout_respawn`, `send_knockout_arrived`,
    `request_take_bag`.
  - Task 1's `hurt_player` now returns early when the hit changed nothing (knocked out already, or
    protected). A knocked-out player takes no more damage and nobody hears a second "0 HP".
- **WorldMeta**: `bags` = `[{owner, pos: [x, y, z], items: [[id, n], ...], age}]`, parsed
  defensively:
  - Bad positions are dropped.
  - Items keep only real blocks with finite counts ≥ 1.
  - A non-string owner means anyone's.
  - A negative or broken age becomes 0.
  - At most 64 bags.
- **Sandbox** (`scenes/sandbox.gd`, small hooks plus a section at the end):
  - The director is added in `_ready` on every peer (so a LAN guest has the spawner before bags
    arrive).
  - Bags are restored as soon as the world exists, not on spawn, so a save during loading keeps them.
  - `setup_local` runs in `_setup_local_player`; `meta.bags` is written in `save_world`.
  - `_player_name(peer)`: this device's player is the profile name (like homes and inventories); a
    guest is their chat name.
- **Tools**:
  - `tools/knockout_smoke.gd` + `_steps.gd`: a headless run in a new Survivor world, through the real
    sandbox, HUD and Session.
  - `tools/lan_test.gd`: a `--ko` knock-out phase for the two-instance LAN run.

## Tests (TDD, RED then GREEN)

| Test file | RED (why) | GREEN |
|---|---|---|
| `tests/unit/test_knockout_rules.gd` (21) | `KnockoutRules` not declared; then difficulty/tips members missing | 21/21 |
| `tests/unit/test_world_meta_bags.gd` (3) | no `bags` on WorldMeta; then a numeric owner came back as "7.0" | 3/3 |
| `tests/integration/test_hearts_hud.gd` (7) | `HeartsBar` / `KnockoutOverlay` not declared; then `knock_out` took no tip | 7/7 |
| `tests/integration/test_knockout.gd` (22) | `KnockoutDirector` / `PickupBag` not declared; the tap tests: the interactor ignored bags; the knocked-out taker (found on LAN) took the bag | 22/22 |

The integration tests use a real Player, world and Session in solo play (the host). They cover:
- A Survivor knock-out drops exactly the blocks and keeps tools and gold.
- No damage while down, and no second bag.
- Getting up at the bed, or at the world spawn without one, with full hearts and protection.
- Protection held until arrival, then 3 s; never forever when the arrival message never comes.
- Taking a bag restores exactly and only once.
- Out of reach: refused. Someone else's bag: refused for 5 minutes, then taken.
- A full pocket leaves the rest in the bag.
- A second knock-out at the same spot fills the same bag.
- Saved and restored bags, with the age still counting.
- Sandbox pops up on the spot keeping everything.
- A forged 0 HP does nothing.
- A sleeper is woken first.
- Cozy drops no bag; Brave does.
- The message and the tip, with the tips taking turns.
- A tap or a hold on a bag takes it; a tap beside it doesn't.
- A knocked-out player can't take a bag until up again.

Suite: **before 637 tests, 79 scripts (exit 0); after 690 tests, 83 scripts (exit 0).**

### Headless checks of the glue

- **Smoke run** (`tools/knockout_smoke.gd`, new Survivor world, private user folder):
  - Hearts row, then knock-out: fade, message, bed tip, bag with the starter blocks, sword and
    pickaxe kept, no more damage.
  - Up at the world spawn with full hearts and protection, and the fade clears.
  - The bag is in `world.json`.
  - A real tap through the camera takes it back ("You got your blocks back!").
  - Sandbox rules: "Oops! Back on your feet!", no bag, nothing lost, up on the spot.
  - Result: 3/3 runs clean after one fix *in the smoke script*. Two earlier runs (of 5) missed the tap:
    from a spot 2.5 blocks +Z of the bag, a slope hid the bag from the third-person camera. That is
    correct game behaviour (you can't tap what the hill hides). The script now picks a side with a
    clear line of sight and looks in first person.
- **LAN run** (host `--auto-host --survivor --lan-test --ko`, guest `--auto-join=127.0.0.1 --lan-test
  --ko`, private user folders with a copied profile):
  - Run 2 found the guest taking its bag *during* the fade: it stood on the bag, which was in reach.
    Fixed test-first: the host refuses bag requests while the requester is down.
  - Run 3, all clean. The guest got the fade (`overlay_down=true`), got up (hp 20) and moved to the
    spawn column. The bag was replicated to the guest (`bags=1`). The guest's request after getting
    up was accepted, and the host showed `bags=0 guest_dirt=5` (exactly the 5 dirt back); the bag
    was gone on both peers.

## Rulings (decisions made on the owner's behalf)

1. **A bag is its owner's for 5 minutes, then anyone's** (`KnockoutRules.OWNER_ONLY_TIME` 300 s).
   Friends can't take your blocks while you walk back from your bed, but blocks are never stuck in
   the world forever (a player who left can't block them). A bag without an owner name (a LAN guest
   who never joined the chat) is anyone's at once.
   *Cost if wrong:* one constant; an owner-only-forever rule needs a "friend returns it" path.
2. **Tap or hold to take a bag, whatever is in the hand.** Spec §12.3 says "one tap"; a child
   holding a sword should still get their bag. A tap *beside* a bag stays an ordinary tap.
   *Cost if wrong:* a bag can't be swung at (there is nothing to gain from hitting it).
3. **Bags share the practice targets' physics layer 16** (the tap-only layer: static, mask 0) instead
   of taking a new layer that parallel tasks (monsters, coins) may also want.
   *Cost if wrong:* a bag right in front of a practice target catches a tap meant for the target.
4. **Protection is held until the player is home, then lasts 3 s** (spec: "3 s of protection"). A
   far bed can take seconds to stream in; 3 s from the revive could run out while the body waits
   invisible. The player's "I'm home" message can only *end* the hold, and the host lets it go
   after 15 s anyway, so a modified guest gains nothing by sending it or not.
   *Cost if wrong:* up to 15 s of safety for a player whose bed never loads.
5. **Bags merge instead of multiplying.** A new drop within 2.5 blocks of the same owner's bag goes
   into it. With 8 bags already, the owner's oldest takes it, and the bag moves to the new spot. With
   64 in the world, the oldest bag takes it (long free for anyone by then). Blocks are never lost or
   duplicated, and saves stay small. Merged counts may pass 999 per block kind (capped at 99 999);
   what doesn't fit into an inventory stays in the bag.
   *Cost if wrong:* a player who wants many separate bags (none known).
6. **The bag falls to the ground under the spot**, sinking through water to the bottom and rising out
   of blocks. With no ground within 64 cells (terrain not loaded), it stays where the player fell.
   *Cost if wrong:* a bag at the bottom of a deep lake needs a dive (swimming is Task 14).
7. **No bag takes while knocked out** (found by the LAN run): otherwise a player standing on their
   own bag undoes the knock-out during the fade. *Cost if wrong:* none.
8. **Sandbox gets up on the spot with a small hop** and the message "Oops! Back on your feet!"
   (spec §12.15, "pops back up next to where they were"). *Cost if wrong:* the wording.
9. **Difficulty (the lead's request): Cozy drops no bag; Normal and Brave drop it like the spec.**
   `KnockoutDirector.difficulty` (default Normal) is the hook for the lead's world setting
   (`KnockoutRules.valid_difficulty` for parsing). Monster damage scaling (Cozy half, Brave harder)
   belongs to the damage side (Task 4 / the lead), not the knock-out.
   *Cost if wrong:* one line in `drops_bag`.
10. **One picture tip per knock-out (the lead's request).**
    - A small list (6) of kind "what helps" lines with an atlas icon: bed, lantern, barrel, door,
      bush, sword. Never blaming words; a test bans "fault", "fail", "bad", "died", "lost" and
      "should have".
    - Survivor players without a bed always see the bed tip ("Sleep in a bed to wake up there next
      time."). Otherwise the others take turns, never the same twice in a row.
    - The icons for lantern, barrel, door and bush are the M2 placeholder tiles until Tasks 5 and 8
      draw theirs.
    - *Cost if wrong:* the texts and the order.
11. **Knocked-out bodies lie down with the sleep pose** (on every peer) plus a star burst. There is no
    new animation, and it works in both styles. *Cost if wrong:* a dedicated knocked-out pose later.
12. **The FPS label moved to the bottom-right corner** (developer setting; its old spot is the
    allocated hearts row). *Cost if wrong:* none.

## For the lead

- **Merge points** (small, self-contained hunks):
  - `session.gd`: 3 lines in `hurt_player`, plus the section at the end.
  - `player.gd`: 3 lines in `_physics_process`, plus the section at the end.
  - `hud.gd`: the FPS label line, plus the section at the end.
  - `sandbox.gd`: 1 line each in `_ready`, `_start_host_or_solo`, `_setup_local_player` and
    `save_world`, plus the section at the end.
  - `block_interactor.gd`: 2 lines each at the top of `place_at_screen` and `break_at_screen`, plus
    the section at the end.
  - `world_meta.gd`: `bags` and `_parse_bags`.
  - `health.gd`: `protect`.
  - `lan_test.gd`: the `--ko` phase.
- **Task 3 (counted blocks)** should refresh the hotbar counts on `Session.bag_inventory_changed(peer)`
  (host). A guest needs the counts sent to it, which is Task 3's sync.
- **Task 4 (monsters)**: hurt players through `Session.hurt_player` only; players with
  `knocked_out` or not `is_spawned()` should not be targets.
- **Cozy / Normal / Brave**: set `sandbox._knockout.difficulty` from the world setting.
- **Minor, not fixed here**: a knocked-out player can still swing a weapon or place a block during
  the 1.6 s fade (the host accepts attacks and edits). It is harmless today; the host could refuse
  both while `health.is_knocked_out()`.

### What to check on the emulator

1. The Survivor hearts row sits right of CHAT and is readable at phone size; the open chat bar covers
   it.
2. A hurt flashes and shakes; the pulse while hearts come back is gentle.
3. Knock-out (use `Session.hurt_player` from godot-mcp exec, or a monster once Task 4 is in): the
   fade, the message and the tip icon look right; you get up at the bed, or at the spawn without
   one; the bag glows at night and in caves.
4. Tap the bag from a few blocks away, with the sword selected too.
5. Sandbox: the same, but up on the spot and no bag.
6. The FPS label (settings) is now bottom-right.
7. Performance: bags are one shared mesh and material; check a pile of about 10 bags does not dent
   the autopilot numbers.

## Final suite

`tests/run_tests.sh`: **690 tests in 83 scripts, all passing, exit 0** (before: 637 in 79). That is
53 new tests: 21 rules, 3 save, 7 HUD and 22 integration. Measured on a busy PC (load average about 40);
the suite took about 4 minutes.
