# M3 Task 14a: the action kit — gadgets and movement (notes)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night` at `6b704c1`), without
the editor or the emulator. Spec §13.3 and §14.13 (refined below), plan Task 14 (first half). The owner asked
for "all exciting items" from Fortnite: **our own designs and names only**, cartoon, free in the Sandbox's
ARMORY page. M3 Task 14b (blasters, items 415–429) ran in parallel; this task stayed out of its files.
Interrupted once by the API limit (22:05) and resumed; the first commit is the rules checkpoint.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Ids | `data/items/item_ids.gd`, `data/blocks/block_ids.gd` | Items 400–407: GLIDER, GRAPPLE (Grappling Hook), BUILD_WALL/FLOOR/RAMP/FORT (Quick Wall, Floor, Ramp, Fort), IMPULSE_ORB (**Boing Orb**), DANCE_ORB; `ItemIds.GADGETS`. Blocks 210 ZIPLINE_POST, 211 LAUNCH_PAD (page 10; `COUNT` 212). 408–414 and 212–215 stay free. |
| Rules (pure) | `core/rules/gadget_rules.gd` (`GadgetRules`) | `Move` (NONE, GLIDE, HOOK, ZIP); glider (ownership, air under the feet, opening, `glide_velocity`, `glide_ends`, looks); hook (`hook_check`: a solid block, 24 (+1.5 slack) blocks, the first block a grid ray from the eyes meets; the face point; pace; pull and release); zipline (attach points, link length, a clear line, speed along the line, the rider's feet, where the ride ends, grabbing, body room); orbs (throw velocity, `orb_path` — the first block the arc meets, `impulse_push`, `impulse_bounce`, `in_bubble`, `dance_seconds` with the boss limits, pace); quick builds (anchor, cells from `Blueprints`, empty cells only, planks then stone, "Need 12 Planks!", pace); Tilly's prices. |
| Links (pure) | `core/rules/zipline_links.gd` (`ZiplineLinks`) | A post links with the nearest waiting post of the same player, 3–48 blocks away with a clear line; a broken post frees its partner; ≤ 64 posts; saved defensively (`WorldMeta.ziplines`). |
| Blueprints | `data/blueprints/blueprints.gd` | The quick builds as stamps (§3a): wall 3 × 4 (12), floor 3 × 3 at the ground's level (9), ramp of four steps (12), fort a 5 × 5 ring 3 high with a door towards you and battlements (54). |
| Launch pad | `core/rules/pad_rules.gd`, `entities/fx/pad_fx.gd` | A `PadRules` pad: 30 m/s up (about 19 blocks), keeps the run; orange burst, boing + whoosh. Animals bounce on it too (Task 6's pads code). |
| Player | `entities/player/player.gd` (section at the end + 4 hook lines) | `gadget_move` and `glider_look` synced (spawn + on change); `has_glider`, `can_glide`, `open_glider`, `toggle_glider`, `start_hook`, `start_zip`; `_gadget_step` runs before the movement (glide, pull, ride) and moves through `_lab_move_and_slide`; JUMP in the air after the last air jump opens the glider; a launch pad opens it at the top of the throw; sleeping, knocked out or hiding lets go. |
| Looks | `entities/gadgets/gadget_models.gd`, `entities/gadgets/gadget_looks.gd` | Cached vertex-coloured meshes with WeaponModels' one material: three canopy looks, held gadgets, rope, cable, hook head, pole with wheel, rider handle, thrown orbs. `GadgetLooks` (a child of a player, made on first use) shows the canopy, rope or handle in every game. |
| Hand | `core/rules/weapon_rules.gd` (`is_holdable`), `entities/weapons/weapon_models.gd` (`mesh_for`) | Gadgets are held (synced `held_item`), with their models. |
| Input | `entities/player/gadget_user.gd` (`GadgetUser`), `block_interactor.gd` (section + 4 lines), `weapon_user.gd` (2 lines) | A tap with a gadget: hook the tapped block, throw an orb at the tapped spot, build in front, open the glider in the air. A tap on a zipline post rides (whatever is in the hand, like doors). ATTACK with the hook or an orb uses it; anything else keeps ATTACK attacking (owner feedback #29). |
| Host checks | `autoloads/session.gd`, section "M3 Task 14a" | `request_hook`/`host_hook`, `request_orb`/`host_orb`, `request_instant_build`/`host_instant_build`, `request_zipline`/`host_zipline`, `send_hook_start`, `send_zip_start`, `gadget_owns`, per-player pace with a test clock (`gadget_now_ms`). |
| Directors | `world/gadget_director.gd` (node `Gadgets`), `world/zipline_director.gd` (node `Ziplines`) | Host: orb flights and bursts (push, bounce, dance), rope and build-puff RPCs; zipline links from block changes (the owner is the nearest player), rides, saves. Every peer: orbs from a pool of 8, bursts and music notes, other players' ropes, cables and poles. |
| Monsters | `entities/monsters/monster.gd` (section + 2 lines), `stone_golem.gd` (section + 2 lines), `sand_serpent.gd`, `frost_giant.gd` (2 lines each) | `dance(seconds)`: a monster turns left and right and hops on the beat (its synced turn and place show it everywhere) and never walks, winds up or attacks; a boss's attack schedule waits (rocks in flight still land). |
| HUD | `ui/hud/hud.gd` (section + 2 lines), `hud_layout.gd` (spot `glide`), `hud_icons.gd` (`&"glide"`) | GLIDE, a context button left of ATTACK and above CROUCH (touch screens), shown in the air with room below and a glider; DROP (the down arrow) while gliding. |
| Palette, shop, icons | `ui/hud/block_palette.gd`, `core/economy/shop_rules.gd`, `ui/hud/shop_panel.gd`, `ui/hud/gadget_icons.gd`, `ui/hud/block_icons.gd` | The ARMORY page is a row: the tier grid, then a GADGETS column (two to a row, golden rims, the two blocks included). Tilly's new GADGETS section (fixed prices × 2^(u−1)). Icons are pixel maps drawn in code (no atlas file to merge). |
| Block page 10 | `data/blocks/portal_page.gd`, `tools/make_portal_page.gd`, `tools/make_portal_page.py` | Tiles (4..7, 0): the post (wood, hazard band, pulley; top: metal cap) and the launch pad (orange chevrons, glows; hazard-striped sides), both styles; the portal tiles stay byte-identical. Realistic twin from ambientCG Bark014 and Metal034 (CC0, credited). |
| Sandbox | `scenes/sandbox.gd` (section + 4 lines) | The two directors on every peer, the host's start (saved links, block changes, `client_ready`), the save, the HUD's glide button. |
| Cheats | `core/rules/chat_commands.gd` | `/give` reaches item ids up to 450 (the same line as Task 14b's). |

## Numbers

| What | Value |
|---|---|
| Glider | falls ≤ 3 m/s (a fast fall is braked at 36 m/s², under half a second), steers at 8 m/s, drifts on at 4 m/s; opens with ≥ 3 blocks of air under the feet |
| Hook | 24 blocks (+1.5 host slack), pull 22 m/s, lets go within 1.4 m (or stuck 0.25 s, or 2.5 s) with a 9 m/s hop and 3 m/s on; 1 s pace |
| Zipline | posts 3–48 blocks apart; the line 2 above a post's top, the rider's feet 2 under it (one block over the ground between two ground posts); start 5 m/s, 3–18 m/s (16 m/s² × the slope), off 1 block before the far post; grab within 6 blocks; 0.5 s pace; JUMP lets go with a 5 m/s hop |
| Orbs | 15 m/s thrown a little upwards, gravity 18, ≤ 3 s flight; 5-block bubble; Boing: monsters 15 → 6.75 m/s out (+5 up), players 13 up + 6 out; Dance: 5 s, bosses 2 s at most once in 20 s; 1 s pace; 0 damage |
| Builds | wall 12, floor 9, ramp 12, fort 54 planks; 0.6 s pace |
| Launch pad | 30 m/s up (≈ 19 blocks) |
| Tilly | Glider 60, Hook 80, Quick Wall/Floor/Ramp 20, Quick Fort 50, Boing Orbs 12 (×3), Dance Orbs 15 (×3), Zipline Posts 15 (×2), Launch Pad 10; × 2^(u−1) |

## Rulings (decided without asking, per the owner's rule 1)

1. **The glide control is JUMP or a GLIDE context button.** JUMP in the air once every air jump is used
   opens it (a triple jump, then glide: no new button on desktop), and a GLIDE button appears on touch
   screens only while the player is in the air with ≥ 3 blocks below and owns a glider; while gliding it
   says DROP. "Holding JUMP while falling" was rejected: it fights the triple jump's presses. *Cost if wrong:*
   one context button to remove, or a line in `_gadget_idle`.
2. **Sandbox always has a glider** (unlimited everything), Survivor needs one in the bag; the ARMORY's
   Glider item is there for the hand (a tap in the air opens it). *Cost if wrong:* one line in
   `GadgetRules.has_glider`.
3. **No fall damage exists in the game**, so "lands softly" is a slow landing (≤ 3 m/s: no landing thud
   either). *Cost if wrong:* none.
4. **A launch pad is a PadRules pad (211) at 30 m/s**, and it opens the glider by itself at the top of
   the throw for a player who has one. The Lab's jump and speed pads and Task 7's bounce pad stay as they
   are (Tilly already sold them: HOME). *Cost if wrong:* one number; the auto-open is one line.
5. **Names are ours**: Boing Orb (the spec's impulse orb), Dance Orb, Quick Wall/Floor/Ramp/Fort, Grappling
   Hook, Glider, Zipline Post, Launch Pad (generic words). *Cost if wrong:* the names table.
6. **ATTACK and gadgets (owner feedback #29):** ATTACK uses the hook or an orb in the hand (they are thrown
   at the middle of the screen); with a quick build or the glider in the hand, ATTACK attacks as always
   (the best weapon, else fists) — a build is placed by a tap, like a stamp. *Cost if wrong:* one line in
   `GadgetUser.attack`.
7. **The hook holds only blocks**, never players or monsters (it takes a block cell; a monster stands in
   air). The host checks the thrower's eyes with its own positions, a grid ray (water and air never stop
   it), 24 blocks + 1.5 slack, and 1 s. The pull goes only while walking (flying needs none). *Cost if
   wrong:* none known.
8. **The zipline's owner is the player nearest to the new post** (the host's positions): `block_changed`
   does not say who placed a block, and an edit hook in Session's edit paths would touch two core
   functions. Two children placing posts side by side at the same moment could get each other's post.
   Posts link with the nearest waiting post of the same owner (3–48 blocks, a clear line); a broken post's
   partner waits for the next one (it does not jump to another post). *Cost if wrong:* an owner argument
   passed from `Session._send_undo_step`.
9. **Lines hang 2 blocks above their posts** (a pole and a wheel are drawn from the post's top), and the
   rider hangs 2 below the line, so two posts on flat ground make a line a child can ride one block above
   the grass. The ride is gravity-driven but never stops (3 m/s uphill) and ends one block before the far
   post, sliding off with its speed (the glider can open then). A block in the way ends the ride. *Cost if
   wrong:* two numbers.
10. **Quick builds put blocks only into empty cells** (air or water), never replace or carve; a floor on
    flat ground says "No room to build that here!". They are built from planks; in Survivor, when the bag
    has too few planks but enough stone, from stone; otherwise "Need 12 Planks!" (the build's size) and
    nothing is taken. One undo step (the batch path). *Cost if wrong:* `GadgetRules.build_material`.
11. **Build items, the glider and the hook are kept** (Tilly never sells a second, `ShopRules.is_tool_item`);
    **orbs are used up** in Survivor (three to a pack) and unlimited in Sandbox. *Cost if wrong:* the prices
    table.
12. **Orbs never hurt anyone** (0 damage): the Boing Orb pushes monsters through `take_hit(0, …)` (they
    also notice who threw it) and bounces every player in its bubble, the thrower too (a Boing jump); bot
    friends and animals are left alone. *Cost if wrong:* a loop in `GadgetDirector.burst`.
13. **Dancing monsters** turn left and right and hop on the beat on the host (their synced turn and place
    show it in every game; no per-peer animation state), never walk, wind up or attack; a hit still hurts
    them. A boss's schedule waits (rocks already thrown still land); bosses that override
    `_physics_process` need the two-line `_dance_hold` hook (the Golem, the Serpent and the Frost Giant have
    it; **M3 Task 4's Cake Monster will need it too**). *Cost if wrong:* the dance's look.
14. **The glider needs no host request**: it only slows the owner's own fall (the owner simulates its body,
    like jumps); its ownership is read from the host's inventory snapshot. Everyone sees it through the
    synced `gadget_move`. *Cost if wrong:* a cheating LAN guest glides without buying one.
15. **A look slot, no editor yet**: `Player.glider_look` (synced, three looks, the first free) is the
    cosmetic slot; M3 Task 9's avatar editor can set it from an unlock. *Cost if wrong:* none.
16. **Page 10 tiles (4..7, 0)**, drawn after the portal tiles with their own RNG seed (the portal tiles are
    byte-identical in both styles). The post is opaque (a full block you can stand on); the launch pad glows.

## Godot patterns (godot-prompter skills)

- `player-controller`: chose the existing CharacterBody3D loop (input → velocity → `move_and_slide` in
  `_physics_process`) with a gadget step in front of the walk/fly dispatch; rejected a separate
  body/controller per gadget.
- `state-machine`: chose an enum (`GadgetRules.Move`, four states) on the Player; rejected node-based states
  (a node tree per player for three short states).
- Visuals follow the project's own rules (DEVELOPMENT §8): shared cached meshes and one material, a pool
  for thrown orbs, `Fx` bursts; no per-event materials or meshes (`test_every_game_sees_the_glider…` checks
  the mesh cache does not grow).

## Tests (RED → GREEN)

Unit tests were written first and failed to parse on the missing `GadgetRules` / `ZiplineLinks` (RED run
`red1.log`), then passed (51, after renaming `is_tool` → `is_kept`: the `Script.is_tool` gotcha). The engine
glue's integration tests were written right after the glue drafts; their first run found two test bugs (a
lambda's local copy; RPCs to a fake guest) and no code bugs, so each behaviour test was **mutation-checked**:
removing the monsters' dance hook fails `test_monsters_dance_for_5_s…`; letting the hook through walls fails
`test_a_wall_in_between_stops_the_hook`, `test_a_guests_hook_is_checked…` and the unit wall test.

- `tests/unit/test_gadget_rules.gd` (42): ids and pages, names, the glider's ownership, air, opening, JUMP,
  3 m/s, rising, steering, ending, looks; the hook's blocks-only, range, walls, face point, pace, pull and hop;
  the line's height, link length, clear line, speed downhill/uphill, rider's feet, ride end, grabbing, body
  room; orb arcs on the ground, at a wall, off a cliff; push, bounce, bubble, dance times, pace; builds' shapes
  (wall, ramp, floor, fort), empty cells, planks/stone/short, pace; the launch pad; Tilly's prices; `/give`.
- `tests/unit/test_zipline_links.gd` (10): linking per player, nearest, 48 blocks, blocked lines, breaking,
  cap, save/load, broken saves, the world save.
- `tests/integration/test_gadget_moves.gd` (16, real Player, Jolt): glide (slow, steered, closes on landing),
  JUMP opens it, Survivor needs one, launch pad auto-opens it, every game sees it (+ tampered state, no mesh
  per use); the hook pulls to the wall with a hop, a wall stops it, 24 blocks and 1 s, never a monster, a
  guest checked with the host's positions, Survivor needs it; zipline linking and a ride down the line,
  JUMP lets go, a lone and a far post, a broken post, lines saved.
- `tests/integration/test_gadget_uses.gd` (16): quick wall (one undo), never replacing, fort's door and
  ramp's steps, Survivor planks → stone → "Need 12 Planks!", ownership and pace, a guest's build; Boing
  Orb push/bounce/no harm, dance 5 s without attacks, boss 2 s once in 20 s, a thrown orb's flight and burst,
  the pool, Survivor uses up orbs, a guest's orb checked; ATTACK with the hook/orb vs a build/glider; the
  gadget in the hand.
- `tests/integration/test_palette_gadgets.gd` (6): the GADGETS column, pictures and rims, picking, fit,
  Survivor counts.
- Changed: `test_hud_layout.gd` (+1: GLIDE in the air on both screens and modes, DROP, gone on the ground),
  `test_item_ids.gd`, `test_block_palette.gd`, `test_counted_hotbar.gd`, `test_palette_armory.gd` (the
  GADGETS column beside the tier grid).

Full suite: before **3235/3235** (337 scripts, base `6b704c1`); after the rules checkpoint (`486d1e2`)
**3293/3293** (340 scripts); with the engine glue **3326/3326** (342 scripts, exit 0, run on a snapshot of
the committed index through `tests/suite_slots.sh`).

## What the lead should check on the emulator (not verifiable headless)

1. Sandbox → palette → ARMORY: the GADGETS column right of the tiers (two to a row, golden rims), every
   picture readable; the panel still above the hotbar on 20:9 and 16:9. Survivor: Tilly's GADGETS tab.
2. Glider: jump off a hill, triple jump, then JUMP again: the canopy opens over the head (both styles), a
   slow glide, the stick steers; GLIDE shows while falling (left of ATTACK), DROP folds it; landing closes
   it. A launch pad (page-10 orange chevrons, glowing): a huge throw and the glider opens at the top.
3. Hook: hook a cliff 15–20 blocks away (tap it, or ATTACK with the crosshair on it): the rope from the
   hand, the pull, the hop onto the ledge; a wall in between says so.
4. Ziplines: two posts on flat ground 20 blocks apart: poles, wheels and a cable appear; tap a post:
   the handle, the ride (faster downhill), sliding off at the end; JUMP lets go.
5. Quick builds: wall, floor over a gap, ramp, fort, each one UNDO; Survivor "Need 12 Planks!".
6. Orbs at night: the Boing Orb scatters goblins (and bounces you); the Dance Orb makes them dance
   (turning and hopping, notes) and not attack for 5 s; the Golem dances 2 s.
7. LAN: the guest sees the host's canopy, rope, handle, orbs and dances, and vice versa.
8. Performance: 20 monsters dancing and orbs flying hold the frame budget (dancers are simulated like
   standing monsters; an orb is one pooled mesh; bursts are `Fx`).

## For the merge

- Task 14b (blasters) touches the same lines: `ItemIds` (after `TREASURE_MAP`, `ALL`, `_NAMES`),
  `WeaponRules.is_holdable`, `WeaponModels.mesh_for`, `ShopRules.is_tool_item`, `block_palette.gd`
  `_armory_page` (both make it a row; keep the tier grid, then BLASTERS, then GADGETS — about 956 px wide
  with both, under the BLOCKS page's width), `BlockIcons.icon`, `WeaponUser.attack_pressed` (both hook the
  top: gadgets first or blasters first does not matter, they never share an item), `chat_commands.gd`
  `_LAST_ITEM_ID` (the same line), the palette and item tests' counts, `sandbox.gd` (both add a section).
- M3 Task 20a's SADDLE takes 216 and Tasks 21b/21c 217–219 on page 10: tiles (0..7, 1) are free.
