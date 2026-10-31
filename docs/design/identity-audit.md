# Identity audit: does anything look copied? (owner feedback #43)

The owner (2026-09-24): *"because our game is visualli similar to minecraft, will google play allow me to upload
a game? should we change a visuals to make it different?"*

**Short answer.** Yes, Google Play allows block games: building with blocks is a genre (Roblox, Block Craft 3D,
Luanti, Terraria's cousins and hundreds more are on the store). What gets a game refused or removed is
**copying another game's assets** (textures, models, sounds, logo, names) or **suggesting a connection**
(Play's impersonation and intellectual-property policies; "like Minecraft" in a listing is both). EasyCraft
uses only its own drawings, CC0 photo textures, CC0 or original sounds, and its own names. This audit checks
every element a player, a parent or a store reviewer sees, gives a verdict, and fixes the risky ones so the
game also *looks* like itself. Spec: §3c. Build notes: `docs/devlog/parts/owner-43-identity.md`.

**Not legal advice.** The lawyer who checks the privacy policy should also look at the name (below) and this
list before the production release.

## How to read the verdicts

| Risk | Meaning |
|---|---|
| **High** | A player could take it for the other game's own asset or trademark look: fixed now. |
| **Medium** | A familiar genre element drawn so close to one game's version that it reads as that game: fixed now or given our own twist. |
| **Low** | A genre convention many games share (hearts for health, a hotbar, blocks of grass and stone), in our own drawing: kept, with the reason. |

"Fixed" names the proof: a test (all under `tests/`) or a file.

## 1. Brand: name, logo, icon, splash, store art

| Element | Could be taken for | Risk | Verdict and fix | Proof |
|---|---|---|---|---|
| The **name** "EasyCraft" | Ends in "-craft" like one famous block game (and many others: StarCraft, Warcraft, and hundreds of store apps) | **Medium** | The ending alone belongs to nobody; a registered "EasyCraft" in games would. **The owner runs a trademark search before the production release** (steps, registers and classes in `docs/store/listing.md`); the lead can prepare other names if one is found. | `test_the_listing_leads_with_our_own_magic_and_asks_for_a_trademark_search` |
| The **launcher and store icon** (was: one isometric grass block with stars on sky blue) | The most recognisable block-game picture there is | **High** | **Fixed:** the **buddy mark**, an orange block buddy with googly eyes holding the wand's star, on our teal (the living buddies are what only we have). Drawn by `tools/make_brand_art.py`; `icon.png` keeps the buddy in the adaptive-icon safe zone; the store copy is `docs/store/graphics/next/icon-512.png` (for the lead to upload). | `test_the_launcher_icon_is_the_buddy_mark_on_our_teal` |
| The **menu title** (was: "EASYCRAFT" typed in yellow capitals in the engine font) | Nothing in particular, but it had no identity | Low | **Improved:** our own **wordmark**, bubble-block letters from the script's own grid font ("Easy" sun yellow, "Craft" orange, ink outline). | `test_the_title_is_the_wordmark_picture` |
| The **boot splash** (was: Godot's logo on grey for up to 25 s on a slow phone) | Another brand (the engine's) on our first screen | Medium | **Fixed:** the buddy and the wordmark on teal (`assets/brand/splash.png`, 11 KB; `application/boot_splash/*`). | `test_boot_splash.gd` (5) |
| **Store screenshots and feature graphic** (the ones uploaded for the closed test: rainbow over grass-block trees, secrets) | A plain grass-block landscape is the other game's classic screenshot | **Medium** | **Art direction** in `docs/store/listing.md`: lead with the living buddies, Size Magic and the universes, never a plain grass-block landscape first; the new default avatar in every picture. New pictures need the emulator: the list is in the build notes for the lead. | `test_the_listing_leads_with_our_own_magic_…` |
| **Listing words and keywords** | "like Minecraft" / "Roblox" as a keyword is impersonation and keyword spam | **High** if present | None present; **a test now scans** `docs/store/`, the release notes, the public pages, every game string and data file for other games' names and creatures (English and Georgian). | `test_identity_words.gd` (5) |

## 2. Blocks and textures

| Element | Could be taken for | Risk | Verdict and fix | Proof |
|---|---|---|---|---|
| **Grass block side** (was: a ragged pixel fringe of green over brown dirt) | The other game's grass block, its best-known texture | **Medium** | **Fixed:** a soft, rounded cap of grass (scallops, a light top row, a darker lip) with two tiny flowers over dirt with round pebbles. Only this tile changed (drawn last with its own RNG). The realistic style is a CC0 photo (kept). | `test_the_grass_side_is_a_soft_rounded_cap_with_little_flowers` |
| **Ores** (was: grey stone with scattered specks of colour) | The other game's ore blocks | Medium | **Fixed:** three chunky round gems with a dark rim, a lit face and a white glint (coal, iron, gold, diamond). Realistic: raised photo blobs (kept). | `test_ores_are_round_gems_with_a_glint` |
| **Crafting table** (was: a 3 × 3 grid top, a saw and a hammer hanging on the side, "Crafting Table") | That game's crafting table almost exactly | **High** | **Fixed:** the **Workbench**: a wooden rim round a teal painted mat with a golden star stamp and three paint pots; drawers with brass knobs on the side. Same id and recipes. Both styles. | `test_the_workbench_has_a_teal_painted_top_…`, `test_the_stations_have_our_own_names` |
| **Furnace** (was: grey cobbles with an arched glowing mouth, "Furnace") | That game's furnace almost exactly | **High** | **Fixed:** the **Clay Oven**: terracotta roof tiles round a chimney hole; a clay dome front with a round window of fire. Both styles. | `test_the_clay_oven_is_warm_clay_with_a_round_window` |
| Stone, dirt, sand, planks, logs, leaves, glass, bricks, water | Every block game has them | Low | Kept: our own generated pixel tiles and CC0 photos, bright toy colours (our toy blocks, `_toy`), no copied pixels. | — |
| Bedrock (a floor you can't break), "Deep Stone" | That game's bedrock, "deepslate" | Low | Kept: plain English words, our own dark noise textures. | — |
| Birch, dark wood, stone bricks, mossy bricks, hay, dirt path (#45b) | Real-world materials the other game also has | Low | Kept: our own drawings of real things. | — |
| Smart blocks (buttons, levers, lamps, powered doors) | That game's "redstone" | Low | Kept: riveted metal plates and big candy buttons of our own, a one-step power rule (no wires to lay, no "redstone" anywhere). | — |
| TNT, obsidian, end stone, netherrack, soul sand | — | — | Not in the game. | — |

## 3. Portals and universes

| Element | Could be taken for | Risk | Verdict and fix | Proof |
|---|---|---|---|---|
| **Portal frame and swirl** (was: dark violet stone with cyan runes around a purple swirl) | The other game's purple portal in a dark frame, its second most famous picture | **High** | **Fixed:** golden frames with rainbow gems; the plain portal's swirl is gold with **rainbow arms** and rainbow sparkles (`portal_swirl.gdshader`, uniform `rainbow`); the universe cores sit in gold. Universe portals keep their universe's own colours (green, gold, ice blue, candy pink, the realm's sunrise). Both styles; no other tile changed. | `test_the_portal_frame_and_core_are_golden_…`, `test_no_portal_swirls_in_purple`, `test_universe_cores_sit_in_a_golden_setting` |
| **The Dragon Realm** (was: violet moss and lavender rock islands over a black-purple starry void, amethyst spires, purple fog) | That game's End: a dark void, pale islands, purple, a dragon | **High** | **Fixed:** a **sunrise over a sea of clouds**: coral moss, pearl-white and apricot floatstone, golden sun-crystal spires, a coral starglass frame, blush bricks; the sky a morning blue over a golden horizon, peach fog, bright clouds below. Only colours changed (every other tile byte-identical). | `test_the_dragon_realm_ground_is_sunrise_coloured_…`, `test_the_dragon_realm_sky_is_a_sunrise_…` |
| **The Sky Dragon's healing towers** (was: violet crystals on dark rock pillars with a lilac beam) | That game's end crystals on obsidian pillars healing its dragon | **High** (the look and the rule together) | **Fixed (look and words):** golden **sun lanterns** on cloud-white pillars with golden beams; "Break the sun lanterns — they heal the Sky Dragon!". The rule (break what heals the boss) is a common boss pattern and stays. *Later option:* children **light** the lanterns to weaken the dragon instead. | `test_the_sky_dragon_heals_from_sun_lanterns` |
| The Sky Dragon itself (teal scales, violet wings, pink chest gem, golden eyes) | A black dragon with purple eyes | Low | Kept: our own colours and shape. | — |
| Floating islands | Sky islands are an old fantasy picture (and many games) | Low | Kept, now at sunrise. | — |
| Universe names (Green Meadows, Sandstorm Desert, Frostpeak, Candy Kingdom, Dragon Realm, the hub) | "Nether", "End", "Overworld" | Low | Our own names; the scan keeps the others out. | `test_identity_words.gd` |

## 4. Characters

| Element | Could be taken for | Risk | Verdict and fix | Proof |
|---|---|---|---|---|
| **Default avatar** (was: yellow head and arms, a blue shirt, dark trousers, bald, a box body) | The other big block game's classic default character | **High** | **Fixed:** the new default for new players and JUST ME: peach skin, curly brown hair, an orange tee, teal trousers; every blocky body has a **rounder head** (its edges cut round, 8 % bigger) and every body (both styles) wears the **buddy badge** on its chest (hidden under a full outfit). **Looks saved before keep their colours and parts**, including profiles from before avatars existed (they load as the classic look they show today). | `test_default_avatar.gd` |
| BOY / GIRL starting looks (#48) | — | Low | Kept (their own hair and clothes; the child's skin tone). | — |
| Realistic person (Kenney "Animated Characters", CC0) | — | Low | Kept; the new default colours and the badge apply. | `test_default_avatar.gd` |
| **Slime** (was: a jelly cube with a face, splitting in two) | That game's cube slime | **Medium** | **Fixed:** a **jelly drop**: a stepped dome with a soft foot, a curl on top, a glossy spot, pink cheeks, a smile (same size, colours and splitting). | `test_the_slime_is_a_jelly_dome_not_a_cube` |
| Goblin (olive skin, pointy ears, horns, a club, a tunic of its level colour) | A green zombie | Low | Kept: ears, horns, club and tunic read as a goblin. | — |
| Mummy (arms out in front) | Zombies' arms-forward walk | Low | Kept: bandages, sash, glowing eyes; the arms-out mummy is a century-old film picture. | — |
| Candy sneaker (sneaks in the dark) | The "creeper" idea of a sneaking monster | Low | Kept: a wrapped licorice sweet with a lollipop that never explodes and never breaks builds (§6). | — |
| Scorpion, yeti, ice bat, gummy bear, goblin archer, shadow bat, wisp; Stone Golem, Sand Serpent, Frost Giant, Cake Monster | — | Low | Our own designs (box models in code). | — |
| Animals (pig, cow, sheep, chicken, dog, cat, fish, rabbit, fox, parrot, the pet dragon) | The other game's farm animals | Low | Kept: real animals drawn our own way; they hop as a whole ("Crossy Road" style), and our pets have perks. | — |
| Villagers (#45b) | That game's big-nosed robed villagers | Low | Kept: ordinary people in shirts, hats and names. | — |
| Tilly the trader, Pip the robot, Nell, bot friends | — | Low | Ours. | — |

## 5. Interface, fonts, sounds, words

| Element | Could be taken for | Risk | Verdict and fix | Proof |
|---|---|---|---|---|
| Hearts row (10 hearts, half hearts) | That game's health bar | Low | Kept: hearts for health go back to 1980s adventure games; ours are smooth vector hearts at the top left, not pixel hearts over the hotbar. | — |
| Hotbar of nine slots at the bottom | Every block and survival game | Low | Kept: rounded touch slots with our palette button. | — |
| Round touch buttons, MORE box, picture hints, emote wheel | — | Low | Ours (M2 Task 17). | — |
| Font | That game's pixel font | Low | None bundled: the engine's font and the phone's own (CC0 rule). | — |
| Sounds | That game's sounds | Low | None copied: Kenney (CC0), freesound CC0 recordings, public-domain music, our own synthesised effects (`assets/CREDITS.md`, `test_audio_credits.gd`). | — |
| Chat commands (`/give`, `/summon`, `/tp`, `/time`) | The same words in that game | Low | Kept: plain verbs children already know; our own list (`/build`, `/size`, `/universe` …). | — |
| Tool tiers (wood, stone, iron, crystal, cosmic) | That game's wood/stone/iron/gold/diamond | Low | Kept: our own top tiers; the rarity colours are ours (§13.2). | — |
| Monster, place and item names | "Creeper", "Enderman", "Nether", "Steve" … | — | None present; the scan guards it. | `test_identity_words.gd` |

## 6. The toon look (spec §5.15, §13.6): costed, left as a proposal

**What it would be.** A third choice beside BLOCKY and REALISTIC: the pixel pages with **cel lighting**
(`BaseMaterial3D.diffuse_mode = DIFFUSE_TOON`, `specular_mode = SPECULAR_TOON`, a soft rim light
`rim_enabled`), harder shadow edges, the same avatars (blocky bodies) and animals. It would make the identity
stronger (a picture-book look nobody would mistake for another game) without new art.

**Its cost, from the code and the measurements we have (no emulator run was allowed for this task):**
- **Per pixel:** toon diffuse is a step on N·L, no dearer than the default Burley diffuse; the rim is a few
  more multiply-adds. The textures, meshes and draw calls stay the same: **one draw call per page per chunk**,
  as now (`BlockLibrary`).
- **First use:** every material whose shading mode changes compiles a **new shader variant** the first time it
  is drawn. The project already measured what that costs on the emulator's GL renderer: **one 100+ ms frame
  per new shader** (DEVELOPMENT.md §8, the Fx material; M3 Task 5's portal swirl). A switch to TOON would touch
  the opaque and cut-out materials of up to 13 block pages plus the avatar parts', the animals' and the water's
  materials: a handful of distinct variants (opaque textured, cut-out textured, vertex-coloured, water), so
  **about 4–6 frames over the 100 ms bar** at the switch unless they are prewarmed while the world loads
  (`PortalSwirl.prewarm`'s pattern).
- **Outlines** (the "soft outlines" of §5.15): an inverted-hull second pass doubles the terrain's vertex work
  and draw calls; a screen-space edge pass needs the depth texture and a full-screen pass. **Neither fits the
  phone budget** without a measurement; they are left out of the proposal.
- **Headroom:** the emulator runs the autopilot's play phase at 54.6–59.9 FPS in BLOCKY (worst frame 33–38 ms;
  §7 of DEVELOPMENT.md), so per-pixel lighting has room, but phones are 3–5× slower on the CPU side and the GPU
  split was never measured.

**Verdict: unclear without a device, so a proposal.** To build it (M5 Task 2 or 3), in this order:
1. `GraphicsPreset.STYLES` gains `"toon"`; `ProfileData` accepts it; the settings row that holds BLOCKY/REAL
   gains TOON (the settings panel is 711 of 720 px: no new row).
2. `BlockLibrary.set_style("toon")`: the pixel pages' materials with `diffuse_mode`/`specular_mode` toon and
   `rim_enabled` (rim 0.3, tint 0.5); glow materials unchanged (unshaded). The same for `AvatarParts`,
   `BlockyAnimal` and the water shader (a `toon` uniform).
3. Prewarm the new variants as a world appears (a tiny quad per material in front of the camera, like
   `PortalSwirl.prewarm`).
4. **Measure on the emulator** with the autopilot in TOON (Green Meadows and the Candy Kingdom, the 60 s play
   phase and the 2 km flight): the bar is ≥ 30 FPS average and no frame over 100 ms; also the switch itself.
   Keep it only if it holds.

## 7. What changed in code (for reviewers)

| Fix | Files |
|---|---|
| Brand (icon, wordmark, splash) | `tools/make_brand_art.py`, `icon.png`, `assets/brand/`, `project.godot` (`application/boot_splash/*`), `ui/menus/menu.gd` |
| Portals | `tools/make_portal_page.gd` / `.py` (page 10), `shaders/portal_swirl.gdshader`, `entities/portal/portal_swirl.gd`, `core/rules/crystal_rules.gd` |
| Dragon Realm and sun lanterns | `tools/make_dragon_atlas.gd`, `tools/make_dragon_realistic.py` (page 11), `world/universes/dragon.gd`, `entities/monsters/sky_dragon_models.gd`, `core/rules/sky_dragon_rules.gd` |
| Workbench and Clay Oven | page 10 row 6 (both tools), `data/blocks/block_ids.gd`, `core/crafting/craft_rules.gd`, `core/progress/board_rules.gd`, `core/progress/quest_rules.gd` |
| Grass side and ores | `tools/make_atlas.gd` (`_identity_pass`) |
| Slime | `entities/monsters/monster_models.gd` |
| Default avatar and buddy badge | see the build notes' merge list |
| Words scan | `tests/unit/test_identity_words.gd` |
