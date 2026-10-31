# M3 Task 9: avatar editor, skins, emotes and celebrations (notes)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night` at `a794b02`),
without the editor or the emulator. Spec §5.9, §13.6, §14.6 (refined here), plan Task 9, research X4.
Commits: `8370b88` (rules, both avatar styles, emotes, Session, celebrations) and `b19e864`
(editor, emote wheel, menus, merged part meshes, docs).

## What was built

| Piece | Where | What it does |
|---|---|---|
| Catalog | `core/avatar/avatar_catalog.gd` (`AvatarCatalog`) | Every item, id `"<slot>.<name>"`. Slots: skin, face, hair (+ hair colour), hat, shirt, pants, cape, wings, trail, outfit, emote. Colours (8 skin tones, 8 hair colours, 16 cloth colours) and hair styles are always free. Unlock kinds: `FREE`, `GOLD` (fixed price), `ACHIEVEMENT`, `BOSS`, `SECRET`, `CODE`; no random kind exists. Earn events (hooks for other tasks): `EARN_TUTORIAL`, `EARN_FIRST_VICTORY`, `EARN_GOLEM`, `EARN_CAKE_MONSTER`, `EARN_SECRET_PAGE`, each with a friendly reason. Rarity (§13.2) from the kind and price; only boss items are legendary. |
| Outfits (skins) | `AvatarCatalog.OUTFITS` + `entities/player/avatar_parts.gd` | Own designs: knight (steel, visor helmet with plume, red cross, metal), astronaut (white suit, visor helmet, backpack, badge), dino suit (hood with eyes and teeth, spikes, tail), robot (metal head with glowing eyes and antenna, chest panel), pirate (tricorn, eyepatch, red-white stripes), ninja (mask, red belt and headband tails), candy (candy crown, lollipop, stripes and sprinkles), **cosmic** (glowing halo, starry suit and cape; legendary, earned by beating the Cake Monster). An outfit sets clothes, shoes, headgear, pattern and pieces; skin, hair colour, face, cape, wings and trail stay the child's. |
| The look | `core/avatar/avatar_look.gd` (`AvatarLook`) | One name per slot + an 8-emote wheel. `from_dict`/`to_dict`, `to_code`/`from_code` (JSON, ≤ 1024 chars), `resolve()` (colours and parts to draw, outfit applied). Every bad field falls back to its default on its own. |
| One rule for price and ownership | `core/avatar/avatar_unlocks.gd` (`AvatarUnlocks`) | `is_owned`, `check_buy` (OK / OWNED / NOT_ENOUGH / NOT_FOR_SALE / UNKNOWN), `buy(profile, id)` (menu path), `grant`, `earn(profile, event)`, `lock_reason`, `message`, `wearable(look, owned)` (takes off what isn't owned), `sanitize_owned`. |
| Emote poses | `core/avatar/emote_poses.gd` (`EmotePoses`) | Wave, cheer, laugh, thumbs up, clap, sit, bow, Bunny Hop, Robot, Star Spin, Victory: poses over time (arms as pitch + spread, legs, hop, spin, lean, sit), shared by both styles. One-shots end by themselves; sit and dances last until the player moves. |
| Profile | `core/save/profile_data.gd` | New `avatar` (AvatarLook) and `cosmetics` (owned ids), parsed defensively; a loaded look wears only what is owned. |
| Codes | `core/codes/code_rules.gd` | `KIND_COSMETIC` rewards now grant the item (`{"kind": KIND_COSMETIC, "item": "trail.confetti"}`); message "Code accepted! New: Confetti". `trail.confetti` is the reserved code item. |
| Box parts | `entities/player/avatar_parts.gd` (`AvatarParts`) | Recipes (boxes) for hair, faces, hats, helmets, capes, wings and outfit pieces, in HEAD, FACE, BACK, HIP or BODY space. Each part is **one merged mesh** (wings: one per wing) cached per part and colours, drawn with one of **two shared materials** (vertex colours; unshaded for glowing boxes). The blocky body's own boxes share one material per colour. |
| Realistic recolour | `entities/player/avatar_skin.gd` (`AvatarSkin`), `avatar_skin.gdshader`, `tools/make_avatar_masks.py` → `assets/characters/avatar_masks/*_regions.png` | The Kenney skin is recoloured by region (skin tint, hair, shirt, pants; shoes by UV rectangle), keeping its painted shading; patterns stripes / stars (glowing) / metal. **One `ShaderMaterial` per look**, cached for the game; one shader. Long hair styles pick the long-haired texture. |
| Both avatars | `avatar_model.gd` (section at the end), `blocky_avatar.gd`, `realistic_avatar.gd` | `apply_look`, anchors (`head_anchor`, `face_anchor`, `back_anchor`, `hip_anchor`, `body_anchor`), `play_emote` / `stop_emote` / `emote()`, cape flutter, wing flap, trail. The realistic person wears parts on `BoneAttachment3D`s (Head, UpperChest, Hips), at head scale 0.85 and back scale 0.7; helmets fit bigger there (`_fit_cover`). Its emotes are an `EmotePoser` (`SkeletonModifier3D`, like `SwimStrokes`) over the idle clip. Jumps, attacks, sleep and swimming end an emote at once. |
| Trails and confetti | `entities/player/avatar_trail.gd` (`AvatarTrail`), `celebration.gd` (`Celebration`) | CPUParticles3D with the shared `Fx.material()` and shared gradients: trails while running on the ground; confetti burst for the celebration. |
| Player | `entities/player/player.gd` (section at the end) | `look_code` synced (spawn + on change) and worn in either style; the local player wears `Profile.data.avatar` and follows `Profile.avatar_changed`. `play_emote` (local, sent through Session), `show_emote` (any body: remote players, bots), **`celebrate()`** (victory dance + confetti; the first Survivor win earns the Victory dance). |
| Session | `autoloads/session.gd` (section `# --- M3 Task 9`) | `request_emote` → host `accept_emote` (known emote, cooldown 400 ms per player) → `_rpc_emote` to every other game; `emote_played(peer_id, emote)` signal (bots/buddies can copy dances). `celebrate_all()` (host → every game, every body). `request_cosmetic_buy(item)` → host `gold_spend` → `cosmetic_result(item, status)`. |
| Editor | `ui/avatar/avatar_editor.gd` (`AvatarEditor`), `avatar_preview.gd`, `avatar_tile.gd`, `avatar_icon.gd` | Left: a live 3D preview (own small world, turning by itself, drag to turn; BLOCKY / REAL buttons; the gold). Right: 11 picture tabs (SKIN … DANCE) and 124 px picture tiles with rarity rims, coin price tags, padlocks and a tick on what is worn. Tapping tries on (locked too). BUY shows the fixed price; not enough gold says how much more; earned items say how to earn them. DANCE: the 8 wheel spots on top (tap one, then an emote). DONE saves only owned items. Every picture is drawn from the same data as the 3D parts (no image files). |
| Emote wheel | `ui/avatar/emote_wheel.gd` (`EmoteWheel`), `emote_button.gd` (`EmoteButton`), `ui/hud/hud.gd` (section at the end) | A round button with a cheering figure in the HUD's left column at (14, 214) 90 × 90 (under MIRROR, above the joystick's area), on phones and desktop. The wheel: 8 slots of 128 px around the middle, each with a moving figure and a word; tap one to do it; the middle cross or anywhere else closes it; it takes every touch while open; pausing closes it. |
| Menus | `ui/menus/menu.gd`, `pause_menu.gd` | Main screen: AVATAR next to SETTINGS. Pause menu: AVATAR under RESUME (in a Survivor world the host takes the gold). |
| Tools | `tools/avatar_gallery.gd`, `tools/make_avatar_masks.py` | The gallery renders every look in both styles to a PNG (front, back, side, close-up, an emote); it needs a display. |

## Rulings (decisions made on the owner's behalf)

1. **Gold prices, and "earned by playing" (§13.6) at once.** §5.9 says items are unlocked with Survivor
   gold, achievements or codes; §13.6 says all earned by playing, none bought. Survivor gold is only
   earned by playing, so fixed gold prices keep both: nothing costs real money, there is no shop
   pressure (no countdowns, no rotation, every item always there). *Cost if wrong:* if the owner reads
   §13.6 as "no gold prices", change the `GOLD` items to earn events; the rule object stays.
2. **Prices** (round, fixed): faces 60; hats 60–400; capes 150–400; wings 250–600; trails 80–300;
   outfits 500–1000; Star Spin 200, Bow 60. A wave pays 10 × N and the Golem 300 (§12.7–12.9), so a
   crown is a few good nights and an outfit a boss or two. *Cost if wrong:* balance; the numbers live in
   `AvatarCatalog.ITEMS`.
3. **The free base set fills the whole wheel**: wave, cheer, laugh, thumbs up, clap, sit (6 emotes) and
   Bunny Hop and Robot (2 dances) are free; Star Spin (the spec's third dance) and Bow cost gold;
   Victory is earned by the first won wave (Survivor). All colours and hair styles are free, plus a
   face set, cap, beanie, hero cape and sparkles trail. *Cost if wrong:* none known (the research asks
   for exactly this: "the base set is free; no emote is only for payers").
4. **Nothing bought outranks the earned legendary.** Only boss items are legendary (cosmic outfit, Rock
   Helmet); gold items are at most epic (a test checks it). *Cost if wrong:* none.
5. **Sandbox gold never unlocks items (§5.9).** In a Sandbox world the editor spends the profile's
   Survivor gold (Sandbox ∞ gold never pays); in a Survivor world the host decides through
   `Session.gold_spend` (a LAN guest's gold lives in the host's wallet for them, so paying from the
   guest's own profile there would let the host's copy overwrite it later). *Cost if wrong:* none known.
6. **The look is one synced string** (`Player.look_code`, JSON ≤ 1024 chars, spawn + on change), not an
   RPC: late joiners get it with the body. Other games check ids against the catalog only (a peer can't
   prove ownership before M4's server); a tampered peer can at worst wear an item it didn't buy on
   its own body. *Cost if wrong:* M4 server validation replaces this.
7. **Emotes go through the host** (known emote, 400 ms cooldown per player) and play at once locally.
   A spammed emote still changes locally but isn't sent. *Cost if wrong:* none known.
8. **Emotes end when the body moves faster than 0.8 m/s, leaves the ground, jumps, attacks, sleeps or
   swims**; the same rule runs in every game from the synced speed, so no "stop" message is needed.
   *Cost if wrong:* a remote dance may end a frame later than on its owner's screen.
9. **The realistic style keeps its painted hair; the hair style picks the texture** (long, bun, curly →
   the long-haired Kenney skin; none, short, spiky → the short-haired one). Box hair on a realistic head
   would look wrong, and there are only two Kenney skins. "classic" skin (the blocky yellow) keeps the
   Kenney skin's own tone on the realistic person. Faces are painted too: only "cool" adds sunglasses.
   *Cost if wrong:* realistic players see fewer face/hair choices; more Kenney skins or painted
   variants can be added as masks later.
10. **Recolouring is a shader with baked region masks**, not recoloured textures: one material per look,
    no per-look image work at run time, same shader for everyone. The masks are generated (original
    work) from the CC0 textures; the Kenney files stay unmodified. *Cost if wrong:* one more shader to
    compile at the first realistic spawn (the old skin compiled a StandardMaterial3D shader there too).
11. **Parts are merged meshes with two shared materials.** A fully dressed blocky avatar would otherwise
    be ~40 draw calls (every box); now it is its 13 body boxes plus one per part. *Cost if wrong:* none
    known; the old per-box approach is a small change back in `AvatarParts.build`.
12. **Parts cast no shadows** (small pieces, an extra shadow pass each). *Cost if wrong:* capes and
    wings have no shadow in High.
13. **The editor lets children try anything on**, locked items too; DONE keeps only what is owned. A
    try-on shows the price or the way to earn it, never pressure words (a test checks the reasons).
    *Cost if wrong:* none known.
14. **Victory celebration API**: `Session.celebrate_all()` on the host (every game shows every body
    dancing, with confetti), or `Player.celebrate()` for one body in one game. M2 Tasks 9–10 should call
    `Session.celebrate_all()` after a won wave or boss. The first celebration in Survivor earns the
    Victory dance (a toast says so). *Cost if wrong:* none; the other tasks call one function.
15. **Earn hooks for other tasks**: `AvatarUnlocks.earn(Profile.data, AvatarCatalog.EARN_TUTORIAL)`
    (Task 15: Pip's Cap, the "free hat" of §5.10), `EARN_GOLEM` (M2 Task 10: Rock Helmet),
    `EARN_CAKE_MONSTER` (Task 4: cosmic outfit), `EARN_SECRET_PAGE` (secrets: Fairy Wings); a code can
    give any item (`KIND_COSMETIC`, reserved: `trail.confetti`). The callers save the profile.
    *Cost if wrong:* none; unused hooks only show "how to earn it" text.
16. **Bots**: any body can show an emote (`Player.show_emote`, `AvatarModel.play_emote`), and
    `Session.emote_played` tells followers what someone did (for "the buddy that learns your dance").
    *Cost if wrong:* none.

## Tests (RED → GREEN)

New: `tests/unit/test_avatar_look.gd` (13), `test_avatar_unlocks.gd` (20), `test_emote_poses.gd` (11),
`test_profile_avatar.gd` (5); `tests/integration/test_avatar_looks.gd` (14), `test_emotes.gd` (16),
`test_look_sync.gd` (5), `test_cosmetic_session.gd` (7), `test_avatar_editor.gd` (12),
`test_emote_wheel.gd` (6), `test_avatar_menus.gd` (3). 112 tests.

- **Rules (proper RED).** The four unit scripts were written first against stub classes, so they
  parsed and failed on their assertions: 40 failures (the default wheel wasn't free, round trips lost
  every field, unknown ids weren't dropped, resolve returned `{}`, nothing was free or priced…). Then
  GREEN: 80/80 with the profile and code tests.
- **Engine glue and UI.** The avatar, emote, sync and session tests were written together with the code
  (their first run was their first GREEN). So each key one was checked **by breaking the code**: with
  the material caches turned off, `test_box_part_materials_are_one_per_colour_and_shared` and
  `test_the_realistic_person_is_recoloured_by_one_shared_material_per_look` both failed, then passed
  again with the caches back. The merged-mesh test was RED first (missing API, 13 separate boxes).
  The editor and wheel tests were written before their classes. Failures on the way, all real: a
  realistic hat measured at its root, not its boxes; `push_input` treats positions as the window's
  (the test now passes viewport coordinates); a merged mesh built nothing (see gotchas).
- **Visual checks** (no emulator): `tools/avatar_gallery.gd` renders on this desktop (Vulkan) found
  and fixed real problems a test could not: face pieces 7 cm too high on the realistic head (the Kenney
  eyes sit lower under the hair: a separate FACE anchor), realistic hair poking out of helmets (helmets
  fit bigger there), the cosmic cape the same colour as the suit, tall hats cut off in tile pictures,
  truncated tab words.
- **Full suite:** checkpoint 1 (`8370b88`): 104 scripts, 889 tests, all passing, exit 0. Final (with
  the UI and merged meshes): **107 scripts, 911 tests, 911 passing, `tests/run_tests.sh` exit 0**, no
  `SCRIPT ERROR` / `Parse Error`, 226 s at a load average of about 25–37 (799 tests before this task).
  GUT orphans left by the new scripts come from paths older tests share: `Player.set_avatar_style`
  queues the old body for freeing (`test_avatar_looks`, 65) and the HUD's own nodes
  (`test_emote_wheel`, 16).

## Gotchas found (also in DEVELOPMENT.md §8)

- Packed arrays are values: appending to one read out of a Dictionary (or cast with `as`) appends to a
  copy, and a merged mesh came out empty. Gather into plain `Array`s and pack once.
- `JSON.parse_string` logs an engine error on bad input (GUT fails the test); use `JSON.new().parse`.
- `Viewport.push_input(event)` converts positions from the window to the viewport (the stretch
  transform); tests that give viewport coordinates pass `in_local_coords = true`.
- `queue_free` on nodes a test just removed counts as GUT orphans until the frame ends; parts, trails,
  tiles and preview bodies nothing else refers to are `free()`d at once.
- An image imported with an alpha channel that is data (the pants weight) needs
  `process/fix_alpha_border=false`, or Godot rewrites the colour of every pixel whose alpha is 0.

## What the lead should check on the emulator (not verifiable headless)

1. Main menu: AVATAR next to SETTINGS; the editor fits the 2400 × 1080 screen under the logo; the
   preview turns and a finger drag turns it; BLOCKY / REAL switch the preview.
2. The realistic preview and players in **Compatibility (emulator)**: skin, hair, shirt, pants and shoes
   recoloured correctly (the `force_srgb` path: colours not washed out), stripes on pirate/candy, stars
   on cosmic, metal on knight/robot; no frame over 100 ms the first time a realistic look appears.
   Parts share the lit part material with `Fx` (same shader features, compiled by `Fx.prewarm`); the
   unshaded glow material (robot eyes, cosmic halo and stars, night cape, lamps) is a second shader:
   check for a long frame the first time a glowing part shows in a world. If there is one, prewarm
   `AvatarParts.part_glow_material()` next to `Fx.prewarm` on `spawned`.
3. Every tab's tiles are readable at phone size; locked items show price or padlock; BUY with enough
   gold (menu: profile gold drops, tick appears), not enough gold shows "You need N more gold."
4. DONE: the player in a world wears the look in both styles (Settings → style), hats and helmets sit
   right on the realistic head, capes flutter when running, wings flap (faster when flying or falling),
   the trail shows while running.
5. The emote button under MIRROR: the wheel opens, the figures move, tapping one does it and closes;
   walking or jumping ends it; sit and dances keep going while standing still; nothing behind the
   wheel reacts while it is open.
6. Pause menu: AVATAR under RESUME; in a Survivor world buying spends the HUD's gold at once.
7. LAN (two instances): the other player's look shows in each game's style; emotes show on the other
   screen; a late joiner sees looks already set.
8. `Session.celebrate_all()` (from godot-mcp exec, once M2's waves call it): every player dances the
   Victory dance with confetti; the first time in Survivor a toast says "New dance: Victory!".
9. Performance: autopilot in both styles with a dressed avatar (cape, wings, trail): the bar still
   holds.
