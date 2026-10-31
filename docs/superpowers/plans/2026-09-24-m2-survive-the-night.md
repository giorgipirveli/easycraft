# M2 "Survive the Night" Implementation Plan — Survivor mode, monsters, stealth, tiers, trader, waves, the Stone Golem

> **For agentic workers:** the lead builds Task 1 (the shared foundation) itself, then runs the
> independent tasks as parallel background agents in git worktrees (`.claude/worktrees/`), each with
> the fixed allocations below, no editor or emulator use, and a notes file in `docs/devlog/parts/`.
> The lead merges, fixes the integration, and verifies on the emulator. TDD for every rule in `core/`.

**Goal:** Survivor mode, playable end to end in the first universe: gather and build with counted
blocks, earn and spend gold, hide from or fight night monsters, survive Totem waves, and beat the
Stone Golem, which opens the portal to universe 2.

**Requested by the owner on 2026-09-24** (09:20): "setup goal to finish all mentioned, before ios app.
continue non stop work" — the whole roadmap (spec §8), M2 first. Added the same morning: real water
with swimming and effects (#17, Task 14), bot friends (#18, Task 15), Sandbox monsters (#19, Task 4)
and secrets and treasures, "most important" (#20, Task 16, pulled forward from M3).

**Spec:** `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` §4.3, §5.1–5.6 and the detailed
**§12** (added with this plan).

**Architecture:** Survivor reuses the Sandbox scene with `Game.mode`; `ModeRules` (pure) decides what
each mode allows. Gold (`Wallet`), blocks and items (`Inventory`) and health (`Health`) are pure rule
objects with host-validated changes through `Session`, like every edit since M1. Monsters follow the
animal pattern: a host-side director spawns them through a `MultiplayerSpawner`, one shared mesh per
kind and level, simulated only near players (the M1b performance lessons: activity by distance,
decisions at 10 Hz, shared materials, no per-event materials). Weapons hit monsters through the M1b
`CombatDirector` (group `monsters`, duck-typed `take_hit`).

## Global constraints
- Everything from M1/M1b still applies (Godot 4.7.2, typed GDScript, landscape, host-validated
  actions, CC0 assets credited in `assets/CREDITS.md`, emulator = test device).
- Performance: the autopilot bar (≥ 30 FPS average, no frame over 100 ms after load, both styles)
  must still hold on the emulator, now also at night with monsters around (≤ 20 monsters).
- Sandbox stays creative: unlimited blocks, ∞ gold, no losses; its monsters are gentle (§12.15).
- No per-event materials or meshes (shared, long-lived resources only; see `Fx`).
- Fair fun (§6): no loot boxes, no pay-to-win, no punishing streaks.

## Allocations (fixed; agents never take others' ids or spots)
- **Block ids** (added in Task 1 with placeholder atlas tiles): DOOR 25, DOOR_OPEN 26, SPIKE_TRAP 27,
  LANTERN 28, BUSH 29, BARREL 30, CLOSET 31 (`COUNT` 32). Task 8 owns door/trap/lantern behaviour and
  looks, Task 5 owns bush/barrel/closet. **Task 16 adds** FAKE_WALL 32, PRESSURE_PLATE 33, TROPHY 34,
  GOLD_LAMP 35 (`COUNT` 36).
- **Atlas tiles** (`data/blocks/atlas.png`, both styles): Task 8 (3..7, 4) and (7, 3); Task 5 (0..5, 6);
  Task 16 (6..7, 6) and row 7. **Item icons** go into a new item icon atlas made by Task 6
  (`data/items/item_icons.png`, 8 × 8 tiles of 16 px): Task 6 rows 0–3, Task 16 row 4, Task 15 row 5.
- **Item ids** for Task 16: TREASURE_MAP 170, GOLDEN_TROPHY 171 (places TROPHY), GOLD_LAMP_ITEM 172;
  Task 6: SPEAR 118, MACE 119, SPEAR_STONE…COSMIC 161–164, MACE_STONE…COSMIC 166–169.
- **Item ids** (Task 1): tiers — SWORD 110 / BOW 111 / AXE 114 / PICKAXE 115 are the wood tier;
  SWORD_STONE…COSMIC 121–124, BOW_STONE…COSMIC 126–129, PICKAXE_STONE…COSMIC 131–134,
  AXE_STONE…COSMIC 136–139, SHIELD_WOOD…COSMIC 140–144; potions POTION_JUMP 150, POTION_INVIS 151,
  POTION_SPEED 152. Task 6 owns their behaviour, Task 7 their prices.
- **HUD** (1280 × 720 design space, `ui/hud/hud.gd`): hearts row top-left right of CHAT (Task 2
  builds it); gold counter top-right under the username (Task 7 builds it); Secret Book button in the
  left column under MIRROR (Task 16); FRIENDS row in the pause menu (Task 15); wave line and boss
  bar top-centre above the toasts (Tasks 9 and 10); stealth eye + noise bars top-left under the hearts
  (Task 5); CROUCH button where DOWN sits when walking (Task 5); shop panel centred (Task 7).
- **Session signals/RPCs**: each task adds its own section at the end of `session.gd` (merges keep
  both); names are prefixed by the task's system (`gold_`, `hurt_`, `monster_`, `trade_`, `wave_`,
  `boss_`).
- **Notes files**: `docs/devlog/parts/m2-task-<n>.md`.

## Review focus
1. Sandbox keeps its freedom: nothing counted, no losses at a knock-out, gentle monsters (≤ 8, level ≤ 2).
2. Gold can never go negative or be minted by a client (every change decided by the host).
3. Knock-out, respawn and the pickup bag never lose or duplicate blocks (save/load, LAN).
4. Monsters at night keep the performance bar (activity by distance, cap 20, shared meshes).
5. Stealth is fair: a crouching player in the dark is not seen from far away; hiding really hides.

---

### Task 1: Survivor foundation (lead)
**Files:** `autoloads/game.gd` (`mode`, `SURVIVOR_SLOT`, `start_survivor`), `ui/menus/menu.gd`
(SURVIVOR enabled), `core/rules/mode_rules.gd`, `core/economy/wallet.gd`, `core/survival/inventory.gd`,
`core/survival/health.gd`, `core/save/profile_data.gd` (`survivor_gold` 25, `universe_unlocked` 1),
`world/world_meta.gd` (`mode`, `inventories`), `data/blocks/block_ids.gd` + atlas (ids above),
`data/items/item_ids.gd` (ids above), `entities/player/player.gd` (`health`, no ghost in Survivor),
`world/combat_director.gd` (group `monsters` in `hittables`), `scenes/sandbox.gd` (mode, slot, starter
kit, save), `ui/hud/hud.gd` (hearts, gold), `scenes/chat_command_runner.gd` (cheats off in Survivor),
`autoloads/session.gd` (host-decided gold and damage).
- [ ] Tests: ModeRules per mode; Wallet never negative, spend fails without enough; Inventory add/take/
  count, cap 999, save round trip; Health damage/heal/regen timing/knock-out edge; profile defaults and
  bad values; WorldMeta `mode` and inventories round trip; Survivor refuses cheat commands and Ghost;
  Sandbox unchanged (existing tests).
- [ ] Implement; commit per rule object; the menu opens a Survivor world with the starter kit.

**Produces (for Tasks 2–16):** `Game.mode: StringName` (`ModeRules.SANDBOX` / `ModeRules.SURVIVOR`),
`Game.allows(rule) -> bool`, `ModeRules.allows(mode, rule)` with rules `GHOST`, `FREE_FLY`,
`UNLIMITED_BLOCKS`, `CHEATS`, `INFINITE_GOLD`, `DAMAGE`, `LOSSES` (bag, respawn at the bed),
`MONSTER_SPAWNS`, `GENTLE_MONSTERS`; `Game.slot()`; `Wallet` (`balance`,
`can_spend(n)`, `spend(n) -> bool`, `add(n)`); `Profile.data.survivor_gold`; `Session.gold_add(peer, n,
reason)` / `Session.gold_spend(peer, n) -> bool` (host) and signal `gold_changed(balance)`;
`Inventory` (`count(id)`, `add(id, n) -> int`, `take(id, n) -> bool`, `items() -> Array[int]`,
`to_save()`/`from_save()`), per player on the host: `Session.inventory_of(peer) -> Inventory`;
`Health` (`hp`, `MAX_HP` 20, `damage(n) -> bool knocked_out`, `heal(n)`, `tick(delta)`),
`Player.health`, `Session.hurt_player(peer, n, from: Vector3)` (host) with signal
`player_hurt(peer, hp, from)`; monsters join group `monsters` and implement
`take_hit(damage: int, from: Vector3, knockback: Vector3)`.

### Task 2: Knock-out, respawn and the pickup bag
**Files:** `core/survival/knockout_rules.gd`, `entities/pickups/pickup_bag.gd`, player, sandbox, HUD.
- [ ] Tests: knock-out respawns at the bed or the world spawn with full HP and 3 s protection; blocks go
  into a bag at the spot, gold/tools/potions stay; taking the bag restores exactly; bags are saved;
  Sandbox pops back up on the spot keeping everything (§12.15); LAN: only the host decides.
- [ ] Implement (fade, message, hearts animation, regen); commit.

### Task 3: Gathering and counted blocks
**Files:** `core/survival/gather_rules.gd`, block interactor, palette, hotbar.
- [x] Tests: drops per block (grass → dirt, leaves → nothing, water/bedrock nothing), pickaxe tier gates
  ores, placing takes one and is refused at zero with a message, counts cap 999, tool powers (axe,
  hammer, pickaxe) give their blocks, undo of a gathered block gives it back; Sandbox unlimited.
- [x] Implement; hotbar count badges, Survivor palette shows only owned things; commit.
- [x] Added by the lead mid-task (child-friendly feedback): a break ring that fills while a finger
  holds, a placed block pops in, a first-time picture hint for ores that need an iron pickaxe.
  Notes and rulings: `docs/devlog/parts/m2-task-3.md`.

### Task 4: Monsters of Green Meadows (and gentle Sandbox monsters, owner feedback #19)
**Files:** `core/rules/monster_rules.gd`, `entities/monsters/` (Monster, models), `world/monster_director.gd`,
`entities/pickups/coin.gd`, sandbox, chat (`/summon slime 3`, `/summon goblin 2`), pause menu
"Monsters: ON / OFF" (Sandbox worlds, §12.15).
- [ ] Tests: stats per kind and level (§12.4 table) with universe scaling; night spawn rules (distance,
  lantern/bed exclusion, caps 20 / 10 per player, levels by distance); sunrise puff; defeat → coins
  (count and value); coins go to the nearest player within 2 blocks once; slime split at level ≥ 3;
  Sandbox never spawns by itself; activity by distance and 10 Hz decisions like animals.
- [ ] Sandbox (§12.15): ≤ 8 night monsters of level 1–2, confetti without gold, the world setting.
- [ ] Implement chaser and jumper, level looks (size + spikes), health bars; commit.

### Task 5: Stealth
**Files:** `core/rules/stealth_rules.gd`, monster perception, player crouch, BUSH/BARREL/CLOSET.
- [x] Tests: visibility factors (§12.5), sight range × visibility, 120° view, grid-ray line of sight;
  noise radii; state machine wander → ? → ! → search 6 s → wander; hidden players are never seen;
  crouch halves speed. (Also: a monster that saw you hide searches next to the spot; knocked-out
  players and bots ignored; bot friends perceived and hurt through `hurt()`.)
- [x] Implement with ?/! labels, CROUCH button and C key, hiding spots; commit. Added by the lead: the
  stealth HUD (eye and noise bars) and the danger arrow (research A3). Notes and rulings:
  `docs/devlog/parts/m2-task-5.md`.

### Task 6: Tool tiers, shield, potions, spear and mace (spear/mace: owner feedback #22, spec §13.1–13.2)
**Files:** `core/rules/weapon_rules.gd` (tier stats, spear, mace), `core/survival/potion_rules.gd`, player,
weapon models, the item icon atlas (tiers, shields, potions, spear, mace), rarity colours.
- [ ] Tests: tier multipliers for damage and dig power; best shield's frontal block share; potion
  effects and durations; items are consumed; Sandbox gets every tier in the palette.
- [ ] Spear (reach 4.5 thrust, short throw) and mace (reach 3, heavy knockback, small ground shake),
  each in five tiers; item ids SPEAR 118 / MACE 119 (wood) and SPEAR_STONE…COSMIC 161–164,
  MACE_STONE…COSMIC 166–169 (added to `ItemIds` by this task).
- [ ] Rarity colours (§13.2) on icons, held items and names.
- [ ] Implement tier looks (colour per tier), shield, potion drinking; commit.

### Task 7: Tilly the trader and the economy
**Files:** `core/economy/shop_rules.gd` (prices), `entities/npcs/trader.gd`, `ui/hud/shop_panel.gd`, sandbox.
- [ ] Tests: price table (§12.7); buy needs gold and gives the thing; sell gives gold and takes the
  block; the host checks reach and gold; flying costs 10 gold/min, lands gently when broke; Sandbox has
  no trader and flies free.
- [ ] Implement the stall near the spawn (Survivor worlds), shop panel, fly cost; commit.

### Task 8: Defenses — door, spike trap, lantern
**Files:** block library (looks), `core/rules/defense_rules.gd`, monster director/monster hooks.
- [x] Tests: door toggles (host), monsters never pass closed doors; spike trap hurts monsters 2/s, never
  players; lanterns keep level ≤ 2 monsters 6 blocks away and stop spawns within 8.
- [x] Implement; commit. As built: `DefenseRules`, `Session.request_door` (host), `DefenseDirector`
  (traps, the lantern index, lantern lights), monster hooks, looks in both styles, sounds, doors in pairs
  at Tilly's, `tools/defense_smoke.gd`. Notes and rulings: `docs/devlog/parts/m2-task-8.md`.

### Task 9: Monster Totem and waves
**Files:** `core/rules/wave_rules.gd`, `entities/interactables/totem.gd`, sandbox, HUD wave line.
- [x] Tests: wave N size and levels (§12.8), end conditions, rewards only for players not knocked out,
  N rises on a win, the boss is offered after wave 5; totem placed on flat ground at world creation.
- [x] Implement; commit. (Done in a worktree: `docs/devlog/parts/m2-task-9.md`, with the boss hook for
  Task 10; the emulator check is the lead's.)

### Task 10: The Stone Golem and the portal
**Files:** `core/rules/boss_rules.gd`, `entities/monsters/stone_golem.gd`, portal, HUD boss bar.
- [ ] Tests: HP by team size, attack schedule and wind-ups, slam hits only grounded players within 7,
  dazed double damage, defeat splits 300 gold, portal unlocks universe 2 in the profile.
- [ ] Implement; commit.

### Task 11: Music and feel
**Files:** `autoloads/audio.gd` (music bus, crossfade), CC0 tracks under `assets/music/`, settings
(music volume), camera shake, vibration.
- [ ] Tests: which track plays for day/night/boss, crossfade timing, music volume setting saved.
- [ ] Implement; credit tracks; commit.

### Task 14: Real water — swimming and water effects (owner feedback #17)
**Files:** `core/rules/water_rules.gd` (swim physics), player movement, both avatar models (swim pose
and strokes), `entities/fx/fx.gd` (splash, ripples, bubbles, drips), sounds (CC0).
- [x] Tests: in water the player never stands on the bottom (buoyancy floats the head at the surface),
  swim speed and diving by look direction, JUMP up / DOWN dives, climbing out at a 1-block bank, splash
  size by entry speed, bubbles only under water, no drowning; the same in flooded caves.
- [x] Implement swim pose/strokes in both styles and all effects with the shared particle material; commit.
  (Done in a worktree: `docs/devlog/parts/m2-task-14.md`; the emulator check is the lead's.)

### Task 15: Bot friends (owner feedback #18)
**Files:** `core/rules/bot_rules.gd`, `entities/bots/` (a bot body with the avatar models), pause
menu FRIENDS row, sandbox (spawn/save), chat lines.
- [ ] Tests: up to 3 bots; personalities pick behaviours (follow, explore, fight, build); they fight
  monsters near the player with the host's rules; count for boss health; knocked out and back; never
  take the player's things; saved and restored; 10 Hz decisions and rest far away.
- [ ] Implement; commit.

### Task 16: Secrets and treasures (owner feedback #20; pulled forward from M3)
**Files:** `world/generators/secret_rules.gd` (deterministic placement), generator (structures:
treasure, hidden rooms, sky islands, temples, geodes), `entities/interactables/` (chest, fake wall,
pressure plates, riddle notes, Wanderer, shooting star), `ui/hud/secret_book.gd`, profile/world meta.
- [ ] Tests: placement is deterministic and seam-free, a few per 128 × 128 area, never in water or
  inside the spawn clearing; a chest opens once (saved); loot tables (§12.16) scale by universe and are
  never bought; treasure maps point to the next buried chest; fake walls open with a knock; the temple
  opens only in the riddle's order; the Wanderer's riddle rewards the right answer once; the Secret
  Book counts found/total.
- [ ] Implement with banners and sparkles; commit.

### Task 17: Kid-friendly UX pass (owner feedback #21; research quick wins) (lead, after round 1)
- [x] **Icon-first HUD buttons** with a word under each; JUMP and ATTACK ≈ 225 px, others ≥ 135 px in
  the 1280 × 720 design space; rarely used buttons (CAM, MIRROR) into a small "more" menu. Test: every
  HUD button meets its minimum size. — Built in a worktree: `HudLayout` (one table), `HudIcons`
  (pictures drawn in code), `MorePanel` (EMOTE, PHOTO, CAM, SIZE, MIRROR, UNDO, LAB); JUMP 225, ATTACK
  200, the rest 135 (`tests/integration/test_hud_layout.gd`,
  `test_every_button_is_big_with_a_picture_and_nothing_overlaps`). Rulings:
  `docs/devlog/parts/m2-task-17-hud.md`.
- [x] **Buddy wake-up ceremony** (sparkles swirl, the camera leans in, eyes blink open, the name with a
  tune).
- [x] **Cozy / Normal / Brave** per Survivor world (a new-world choice; Cozy: monsters do half damage,
  no bag; Brave: harder hits, a badge; same gold) — ModeRules/knock-out parameter from Task 2.
- [x] **Sleep and save**: the sleep screen offers *Wake up* and *Stop for today* (equal buttons).
- [x] **No-guilt word test** over every player-facing string (`tests/unit/test_no_guilt_words.gd`).
- [x] **Dog digs toward buried treasure** (pet + Task 16's `nearest_buried` hook).
- [x] Honest Golem help and the portal peek (with Task 10), the danger arrow (with Task 5).
- Quick wins inside running tasks (messaged to their agents): break ring and place pop (T3), picture
  tips after a knock-out (T2), short numbers and have/need bars + an arrow to Tilly (T7), tier dots
  (T6), reduce motion (T11), monsters never break builds + hit feel (T4), bot rules (T15), picture
  riddles + secret chime (T16).

### Task 18: Creature minds (owner feedback #24, spec §12.17)
**Files:** `core/mind/` (TinyNet, Mind, Drives, Memory, rewards, save), species tables, `entities/animals`
(`world/animal*.gd`), `entities/bots/bot_friend.gd`, `entities/monsters/monster.gd` (after Task 5), a
thought bubble (shared picture atlas, cached meshes), `WorldMeta.minds`.
- [x] Tests (pure): forward pass, action choice with drives and personality, learning converges on a
  toy reward and stays clamped, memory caps and forgetting, save/load round trip, the same seed gives
  the same individual; budget: 10,000 decisions under 200 ms on this desktop.
- [x] Tests (behaviour): an animal fed by player A comes to A and keeps away from player B who hit it;
  herds follow a leader and sleep together at night; a builder friend prefers the child's blocks; an
  explorer learns what the child follows; a goblin hit by arrows from far learns to zigzag within a few
  encounters, never faster/stronger than the spec, eases off after knock-outs, off in Cozy.
- [x] Part 1: core + animals + bot friends; part 2 (after Task 5 merges): monsters. Commit each.

### Task 12: Acceptance on the emulator and release 0.3.0 (lead)
- [x] Extend the tour with Survivor checks (gather, trade, night monsters, stealth, knock-out and bag,
  wave, boss, portal); autopilot at night in Survivor; version 0.3.0 (code 5); release APK to
  `~/Downloads/EasyCraft-0.3.0.apk`; fill `docs/superpowers/notes/m2-acceptance.md`.

### Task 13: Whole-branch review and fix pass (lead)
- [x] Fresh reviewer on the most capable model; fix Critical/Important test-first; ledger minors (16:00 review; its one Important finding fixed by M4 F).
