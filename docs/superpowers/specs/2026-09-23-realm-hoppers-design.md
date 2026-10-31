# EasyCraft — Game Design Spec

- **Date:** 2026-09-23
- **Status:** Draft for review
- **Name:** **EasyCraft**, chosen by the owner on 2026-09-23 (the working title was "EasyCraft"). Check store names and trademarks before launch.
- **Scope of this document:** the whole-game design (all milestones) plus the detailed spec for **Milestone 1 (M1) "First Steps"**. Later milestones get their own spec → plan → build cycle, refining the sections tagged with their milestone here.

---

## 1. Summary

A 3D open-world block game for phones, played in landscape, inspired by Roblox and Minecraft. On start the player chooses **Sandbox** (everything unlimited, build anything) or **Survivor** (gather, earn gold, build, hide from and fight monsters). Survivor is a ladder of **universes**: beating the strongest boss of a universe opens the next one, which pays 2× gold and is 2× harder, forever. The world is endless, full of secrets, and friends can play together as a team.

**Hook:** an endless block multiverse full of secrets, where every boss you beat opens a stranger, richer universe.

## 2. Decisions log

| Topic | Decision | Why |
|---|---|---|
| Engine | Godot 4.7.2, GDScript (statically typed) | Installed and verified on this PC; text-based scenes Claude can edit; free |
| Platforms | Android first; iOS built later on the owner's Mac | iOS builds require macOS + Xcode |
| Test device | The Android emulator on this PC (`Pixel_8_API_35`) | Owner's choice |
| Orientation | Landscape only | Owner's requirement |
| Audience | All ages with an age check — the Roblox/Minecraft approach | Owner's choice; kids are the core audience |
| Distribution | Public, Google Play and App Store | Owner's choice |
| Monetization | Free to play, no ads ever; **parents pay for clear value** (§18, owner #35): EasyCraft Plus (a one-time unlock) and cosmetic packs at fixed real-money prices, only in the grown-up area behind the parent gate, never random, nothing needed to play (no rewarded ads: §6) | Faster first release; the engagement research (docs/design/); the lead's ruling on owner #35 |
| World tech | Voxel Tools (Zylann) GDExtension 1.7 — prebuilt for Android arm64/x86_64 and iOS arm64, Godot 4.5+ | Endless terrain, meshing, editing, saving and multiplayer sync already built; saves weeks |
| Online backend | Nakama (open source) + official Godot client; server logic in TypeScript | Usernames, friends, blocking, chat, relayed matches built in |
| Multiplayer model | Host phone is authoritative; Nakama relays traffic | Owner wants the server on the phone; relay solves mobile NAT |
| Currency | One currency, **Gold**, kept separately per mode | Sandbox's unlimited gold must never leak into Survivor |
| Team size | Up to 4 players per world (host + 3) | Host-phone performance |
| Video | YouTube embedded player for everyone; TikTok embed player for 13+ only | Owner wants video inside the app; TikTok is 13+ only |

## 3. Design pillars

Every feature must serve at least one pillar.

1. **Freedom** — no forced path: build, explore, fight or hide.
2. **Discovery** — a secret around every corner, and a book that shows how many are still hidden.
3. **Progress you can see** — the base, the gold and the universe number keep growing.
4. **Together** — co-op waves and bosses, reviving friends, visiting each other's builds.
5. **Fair fun** — engaging through play, never through tricks (section 6).

## 3a. Signature features — why EasyCraft, not Minecraft or Roblox

Added 2026-09-23 at the owner's request ("we need something Minecraft and Roblox didn't build").

**The gap:** in Minecraft, blocks are dead — making anything move needs redstone engineering, and
touch building is one slow block at a time. In Roblox, making anything move or play needs Lua on a
PC; most kids only consume, and cool avatar items cost money. Neither lets a child make a creation
*come alive* instantly, with zero coding, on a phone.

**Signature: "Build it. Bring it to life."**

| Feature | What the player does | Milestone |
|---|---|---|
| **Magic Wand — living buddies** | Tap a build with the wand: it wakes up with googly eyes and a name, follows and cheers. Personality comes from its blocks: size sets speed and hop (small = zippy, huge = slow stomper), light blocks make it glow, a mostly-glass build floats like a ghost. A walking tree is possible. Tap it with the wand again to turn it back into blocks. Buddies are saved with the world. Cap: 200 blocks per buddy, 10 buddies per world. | **M1 (extension)** |
| **Size Magic** | Tiny (¼ size: explore builds like a bug, fit 1-block tunnels — future secret passages) and Giant (3×). Extends the physics switch. | **M1 (extension)** |
| **Stamps** | One tap stamps a house, tower, bridge, giant tree or rainbow arch facing away from the player, then customise it. One undo removes the whole stamp. | **M1 (extension)** |
| **Mirror mode** | Every block placed or broken is mirrored across a vertical plane through the player — symmetric builds in half the time. | **M1 (extension)** |
| Game Blocks | Start / finish / checkpoint / coin / bounce blocks: an obstacle course or race in 60 seconds, no code; friends play it with a timer and medals. | M3 |
| Build-and-Wear | Build a tiny thing and wear it as a hat, backpack or wings — self-made cosmetics instead of bought ones. | M3 |
| Build Rewind | Time-lapse replay of a build with an orbiting camera, shareable. | M3 |
| Buddies in co-op | Buddies meet friends' buddies, carry items, help in Survivor fights. | M2–M4 |

**Engagement without tricks:** the pull comes from the magic of creation (build → alive in seconds),
surprise (emergent personalities), discovery (tiny-only secrets) and showing friends — never from
loot boxes, streaks or pressure (section 6 still applies).

### Item ids
Hotbar slots hold block ids (1–16) or item ids (100+): `WAND=100`, `STAMP_HOUSE=101`,
`STAMP_TOWER=102`, `STAMP_BRIDGE=103`, `STAMP_TREE=104`, `STAMP_RAINBOW=105`. The default hotbar
for a new world: grass, stone, planks, brick, glass, red, blue, wand, house stamp.

## 3c. Our own look — nothing that looks copied (owner feedback #43; M5 Task 2)
The owner (2026-09-24): "because our game is visualli similar to minecraft, will google play allow me to upload a
game? should we change a visuals to make it different?" Block building is a genre; what gets a game removed is
copying another game's assets or suggesting a connection. The audit of every element, with verdicts, is
`docs/design/identity-audit.md`; the build notes are `docs/devlog/parts/owner-43-identity.md`.
- **The brand**: the **buddy mark** (an orange block buddy with googly eyes holding the wand's star) on our **teal**
  (`#139e9b`) is the launcher and store icon; the **wordmark** "EasyCraft" in our own bubble-block letters is the
  menu's title; the **boot splash** is the buddy and the wordmark on teal (never Godot's logo on grey while a slow
  phone loads). All drawn by `tools/make_brand_art.py` (no font file, no third-party art).
- **The default avatar** (new players and JUST ME) is ours: peach skin, curly brown hair, an orange tee, teal
  trousers; every blocky body has a rounder head (its edges cut round, a little bigger) and every body wears the
  **buddy badge** on its chest (hidden under a full outfit). Looks saved before keep their colours and parts.
- **Portals are golden and rainbow**, never purple swirls in dark frames: a gold frame with rainbow gems, the
  plain portal's swirl in rainbow-gold, each universe's own colours for universe portals.
- **The Dragon Realm is a sunrise sky**: islands of cloud-white and peach stone with rose moss and golden
  crystals over a sea of clouds, never a black-and-purple void; the Sky Dragon's healing towers are **sun
  lanterns** on cloud pillars (golden beams), never crystals on dark pillars.
- **Our own stations**: the **Workbench** (a bench with a painted top, paint pots and a star-stamp, drawers with
  round knobs) and the **Clay Oven** (a warm clay dome with a round window and a chimney) replace the crafting
  table and the furnace (same ids, same recipes).
- **Our own ground and ores**: the grass side is a soft rounded cap of grass with little flowers, the ores are
  chunky round gems with a glint.
- **Words**: no other game's name, creature or place anywhere a player, a parent or a store reviewer reads
  (the store drafts, release notes, public pages, game text and data; `test_identity_words.gd`); the owner does a
  trademark search for "EasyCraft" before the production release (`docs/store/listing.md`).
- **Store art** leads with the living buddies, Size Magic and the universes, never a plain grass-block landscape
  (`docs/store/listing.md`, "Art direction").
- **The toon look** (§5.15, §13.6) is a documented proposal with its cost in the audit until the lead measures it
  on the emulator (it needs a first-use shader compile per material).

## 3b. World v2 — underground, water, realistic style, double jump, animals, sleep, weapons, chat commands (M1b)

Added 2026-09-23 at the owner's request. Plan: `docs/superpowers/plans/2026-09-23-m1b-world-v2.md`.

- **Underground like Minecraft, plus magic:** winding tunnels, big caverns, occasional surface
  entrances; stone above y = 0, darker deep stone below; an unbreakable **bedrock** floor at the bottom
  of the world; **ores** by depth (coal → iron → gold → diamond deep down); **glowing crystals** on deep
  cave walls (a secret to find, and they can come alive with the wand); **underground lakes** in the
  deepest caverns; caves get darker with a soft **lantern** around the player.
- **Water:** **oceans and rivers** in the world; **flowing water** (falls, then spreads up to 5 blocks —
  dig next to a lake and it pours in); an **underwater view** (blue tint and fog).
- **Graphics style switch:** Settings → Style **BLOCKY** (pixel art) or **REALISTIC** (CC0 photo
  textures with bump detail, real sky, glow, animated water). Same block layout, instant switch, saved.
  In REALISTIC the players become **real-looking people** too (owner, 2026-09-24: "consider to make
  avatar real as well in realistic world"): a CC0 human-proportioned, textured, rigged character with
  idle, walk, run and jump animations, kid-friendly (no uncanny photoreal faces), one skinned mesh
  (cheap on phones). Each device shows every player in its own chosen style. Held items, the sleep
  pose and Size Magic work with both avatars.
- **Double or triple jump:** Settings → Jumps **DOUBLE / TRIPLE** (default triple). In Survivor (M2) the
  player starts with double jump and unlocks triple jump.
- **Quick taps on JUMP fly, and every tap goes up** (owner feedback #75, 2026-09-29, replacing #54's rule below: "when i
  click on jump several times i should start fliying and going up not only down"). In the Sandbox the **second quick
  tap** (within 0.35 s of the one before) takes off at once with a clear lift (0.45 s of UP); in Survivor, where flying
  costs gold, the **third** quick tap does (two taps stay its double jump and never spend gold); Monster Wave has no
  flying (the jumps, then the glider). Flying, **every tap on JUMP adds 0.3 s of UP** (at most 2 s), so tapping on keeps
  climbing; holding JUMP climbs too. One tap, and slow taps, stay jumps. The rule is `JumpTaps`
  (`core/rules/jump_taps.gd`; tests `test_jump_taps.gd`, `test_jump_taps_player.gd`,
  `test_several_quick_taps_fly_and_keep_going_up`, `test_survivor_keeps_the_double_jump_and_flies_on_the_third_tap`).
- (Superseded by #75 above.) **A double tap on JUMP flies; tapping on opens the parachute** (owner feedback #54, 2026-09-28, playing the browser
  version on an iPhone: "when i click on up multyply times like 4-5-6 it should start flying with parashute as it
  uses but when i click same time on up it should go up and start flying"). Ruling for the JUMP button (the touch
  HUD's JUMP, which shows UP while flying, and Space on a keyboard press the same action, so they behave alike):
  - **Two quick taps** (the second within **0.35 s** of the first, then no third within 0.35 s) are a double tap. In
    the Sandbox both taps jump at once (the ground jump and an air jump: the child goes up straight away), and
    0.35 s after the second tap the player **takes off like the FLY button**: **0.25 s** more of rising (a clear
    little lift) and a whoosh, then hovering. The WALK button says FLY, JUMP becomes UP (hold it to climb) and DOWN
    shows. Back to walking the way it always was: the FLY button (FLY → GHOST → WALK), F on a keyboard, `/walk`.
  - **Tapping on** (three or more taps in a row, each within 0.35 s of the one before) is what it always was: the
    jumps, then the parachute (the glider) at the next tap once there are 3 blocks of air under the feet (Jumps
    TRIPLE: the 4th tap; DOUBLE: the 3rd); taps under the canopy do nothing, a landing closes it. One tap is one jump;
    a slow second tap (over 0.35 s) is a plain double jump. A row of taps goes on through a glide and its landing,
    so tapping on never ends in a take-off.
  - **Only where flying is free (the Sandbox).** Survivor pays gold for flying and its double jump is earned, and
    Monster Wave has no flying: there a double tap stays a double jump and never spends gold. Taps never take off
    while flying already, swimming (JUMP swims up), on a zipline or a hook, or under the glider, and a moment the
    body did not move (asleep, riding, hidden) forgets the taps before it.
  - Why 0.35 s: Minecraft's double-tap-to-fly window is 7 ticks (0.35 s) and a phone's double-tap timeout is about
    0.3 s; a child's thumb is slower, so the upper end. The rule is `JumpTaps` (`core/rules/jump_taps.gd`); notes and
    the tap-by-tap table (before and after) in `docs/devlog/parts/owner-54-jump-fly.md`.
  - *Cost if wrong:* in the Sandbox a child who taps twice fast to double-jump onto a ledge flies instead (a slower
    second tap still double-jumps; walking again is the FLY button twice). Letting Survivor players take off by a
    double tap too (paying gold) is one rule (`JumpTaps.counts`). A double tap while flying that lands again
    (Minecraft) was not asked for: it would drop children who tap UP twice to climb.
- **Animals and pet dogs** (added 2026-09-23, owner: "we also need to add dogs, and different animals"):
  - Blocky, cute animals live in the world: **dog, cat, pig, cow, sheep, chicken, rabbit** on grass and
    **fish** in oceans and rivers. Each has its own look, sound and idle animation (tail wag, head bob,
    rabbit hops, fish swim in schools).
  - They wander, look at nearby players and scurry away from a running player. They never hurt anyone,
    and in M1b nobody can hurt them (Survivor food and farming come with M2).
  - **Owner feedback #26 (2026-09-24, overrules the line above):** animals can be defeated. Health by kind
    (small 3, medium 6, cow 9); weapons, fists and arrows hurt them (they run, squash and cry out); at 0
    they puff away in the monsters' cartoon cloud (never blood). In Survivor the defeater gets a little
    (building blocks by kind, never gold nor anything Tilly buys); the Sandbox drops nothing. Pets and
    golden animals are never hurt, by anyone. A hunted herd animal comes back after 3 minutes. Rulings:
    `docs/devlog/parts/owner-bugs-26-29-30.md`.
  - **Pets:** pet a dog or a cat (tap it 3 times) and hearts pop out. It becomes your pet, with a collar in
    your colour and a name tag. It follows you like a buddy, sits when tapped, jumps when you jump, and is
    saved with the world. Up to 3 pets per player.
  - When a LAN guest leaves, their pets sit down where they are and wait, wagging their tails. A waiting
    pet that falls out of the world comes back up next to the world spawn and waits there. After a
    reload the pets belong to the host (review M12, 2026-09-24).
  - The host spawns animals around each player from a deterministic per-area rule: herds on grass, schools
    in water. Up to 20 animals near each player; wild animals far away despawn, and only pets are saved.
- **Beds, sleeping and day/night** (added 2026-09-23, owner: "we also should be able to make sleep player"):
  - A gentle **day/night cycle** (20 minutes: 12 day, 2 dusk, 4 night, 2 dawn) with sun, moon and stars.
    Sandbox nights are moonlit and safe; Survivor's night monsters still come in M2.
  - A placeable **bed** block. Standing next to a bed shows a **SLEEP** button: the avatar lies down,
    "Zzz" floats up, the screen fades, and you wake at the next sunrise (at night) or sunset (by day).
    In multiplayer the time skips only when every player is asleep; the others see who is sleeping.
  - Sleeping in a bed makes it your **home**: after a fall out of the world you come back to it
    (the world spawn if it is gone). The time of day and each player's home are saved with the world.
- **Sword and weapons** (added 2026-09-23, owner: "player should have a sword and different weapons"). The
  M2 combat core (§5.3) arrives early; monsters, health and tiers still come in M2:
  - **Weapons:** sword (swing combo), bow (hold to draw, arrows arc and stick into blocks), boomerang
    (flies out and comes back), hammer (slow, big knockback). Each is held in the avatar's hand with its
    own attack animation, sound and hit effect. On touch screens an **ATTACK** button appears while a
    weapon is selected, with light aim assist. *Owner feedback #29 (2026-09-24):* ATTACK always shows
    and always attacks: the weapon in the hand, else the best melee weapon in the hotbar comes to hand,
    else **fists** (a small, quick punch; everybody has fists, Survivor too).
  - **Tools with block powers:** the **axe** fells a whole tree at once, the **pickaxe** digs a
    player-sized tunnel step, the hammer's ground smash breaks a 3×3 patch. All go through the host's
    edit checks (bedrock stays unbreakable).
  - **Targets now:** a placeable **practice dummy** that wobbles and shows hit numbers, and a **bullseye**
    target that scores arrows. Animals and other players are pushed back but never hurt (no health yet;
    no player-versus-player).
  - Every weapon has a damage value in one table, so M2 monsters use the same hits; tiers
    (wood → cosmic) come with the M2 economy.
- **Game chat with commands** (added 2026-09-23, owner: "we also should have commands in the game chat"):
  - A **CHAT** button on the HUD (T or Enter on a keyboard) opens a chat bar. Typing `/` shows the command
    list as tappable buttons, so children do not need to remember them.
  - **Commands (Sandbox):** `/help`, `/tp x y z` (with `~` for "here") or `/tp name`, `/spawn`, `/home`,
    `/time day|night|noon|midnight`, `/give block-or-item`, `/summon animal`, `/fly`, `/ghost`, `/walk`,
    `/size giant|tiny|normal`, `/jumps 2|3`, `/style blocky|realistic`, `/seed`, `/clear`. Anything that
    changes the world runs on the host. Survivor (M2) turns commands off except `/help`.
  - **Messages to other players** (LAN now, online in M4) follow §5.13: `under_13` gets the quick-chat
    phrases and emotes only, `13_plus` gets free text through the bad-word and personal-info filter.
    Messages are short (at most 120 characters), and the host rate-limits them.
  - **More commands** (owner feedback #40, 2026-09-24: "add more commands in the game"). Each has a
    usage line, a one-line "about", tappable choice buttons and a Georgian name (and Georgian words for
    its choices; a native speaker checks them):
    - Sandbox cheats (off in Survivor, like the old ones): `/weather clear|rain|snow|sandstorm` (only
      what the universe has: the desert's sandstorms, Frostpeak's snow; no rain yet), `/heal`,
      `/peace on|off` (monsters puff away and stop coming: the pause menu's MONSTERS switch),
      `/freeze on|off` (the day clock stops for everyone), `/give name 64` (a count 1–999), `/kit` (a
      builder's hotbar), `/speed 1|2|3` (slow motion, normal, the Speed potion's 1.5×) and
      `/gravity moon|normal|zero` (the Physics Lab's modes), `/build house|tower|bridge|tree|rainbow`
      (a stamp two blocks ahead, one undo), `/boss` (the universe's boss). `/peace` and `/freeze` alone
      switch on and off.
    - Everywhere: `/dance [hop|robot|star|victory]` and `/emote name` (only emotes you own), `/pet`
      (your pets stand up and come; far ones pop next to you), `/bot add builder|explorer|fighter` and
      `/bot remove name` (the host's bot friends, like the FRIENDS row), `/xp` and `/level`, `/music
      next|classical|game|on|off`, `/photo`, `/save`, `/find tilly|home|portal|treasure` (an arrow
      with the distance at the compass's spot, and words like "42 blocks away, on your left"; in
      Survivor the treasure needs a Treasure Map you own).
    - Survivor only: `/clearbag` (asks twice: the second `/clearbag` within 15 s empties the bag) and
      `/universe 1–N` or a name (travel, alone, to an unlocked universe). `/fill block [n | w h d]` (a box
      two blocks ahead, ≤ 16 a side, empty cells only, one undo) and `/copy` (the build you look at goes into
      the COPY tool) came with the building tools (M3 Task 8): Sandbox cheats, rate-limited like `/build`.
    - `/help` and the "/" buttons show only what this child may use in this mode. World-changing ones
      (weather, heal, peace, freeze, pet, boss, clearbag) run on the host, which re-checks the text and
      rate-limits them; heavy local ones (build, save, bot) have their own limit; a LAN guest follows the
      host's mode and the host's command switch (sent at join).
  - **A chat you can read on a phone** (owner feedback #49, 2026-09-24: "when you type you dont see the
    text, also text chats are not showing correctly"). While the chat is open (the bar, the quick-chat
    wheel or MUTE / REPORT) it is drawn over every other HUD piece (a game's round line, the wave and boss
    lines, the Brave badge, the gold, the game clock, ATTACK) and hears touches first; closed, it goes
    back under the overlays. The phone keyboard (about the bottom half of a landscape screen) never
    covers what the child needs: the bar stays at the top, the phrase and command buttons shrink to
    about one row (they scroll), and the history shows the newest lines that fit above the keyboard,
    following it up and down. With the wheel open the lines sit in a column left of it, under CHAT.
    Every line has a dark backing as wide as its words (contrast at least 4.5 on snow, sky, sand or a
    cave), wraps inside the history (one long word too), and the closed history keeps to its box
    (older lines give way). Letters the built-in font lacks (Georgian) come from the device's own font
    (Android's Noto Sans Georgian), added to the default font's fallbacks, never a bundled font.
- **The palette's MOBS page (owner feedback #51, 2026-09-25):** "in the plus icon … in sandbox add a mob version,
    where all the monsters or pets are (not the pets we already added)". In the Sandbox the "+" palette has a MOBS
    tab: every animal kind (Pip, a pet, stays on the PETS tab), every monster kind and the bosses, each a small
    picture tile drawn from its own model (ANIMALS, MONSTERS, BOSSES). A tap closes the palette and is the same as
    typing `/summon <kind>`: the host brings it out beside the child, with the same checks (a grown-up's "commands
    off" holds) and chat line. Monsters come at level 1. Survivor has no MOBS tab (free monsters would break its
    fair play).
- **VR on the Meta Quest (owner #101, 2026-10-15: "I have meta quest and we have to adapt the game for VR, this is
    now N1 priority"):** the whole game in a Quest headset: stand in your own world in first person, walk with the stick
    (a light comfort vignette), snap turn, break and place blocks with a laser from the hand, every menu, the School and
    the boards on floating panels, the rocket flight seated in the capsule, friends seen with their heads and hands.
    Comfort first for children: no camera move the child did not make, black fades on every jump in place, a break card
    after 30 minutes. Two ways in, one code: the web build's ENTER VR in the Quest's browser (`/vr/`) and a native
    Quest app. Quest 2 is the floor (72 Hz). The plan, rulings and phases: `docs/superpowers/plans/2026-10-15-vr-quest.md`;
    the research: `docs/devlog/parts/vr-research.md`.
  - **As built (P5, performance; owner #108 "i have quest 3"):** every world measured through the rig on the desktop
    (`tools/vr_bench.gd`): the scene was 16-37 draws everywhere; the 230 came from the HUD's tray, whose drawn pictures
    (the hearts, the buttons' symbols, the hotbar's frames, the coin, the stealth eye, the read-aloud speaker) were a draw
    per shape. In a headset they are one draw each now (`CanvasBatch`). The terrain streams 16-cube blocks again in VR: a
    32-cube block's collision was built on the main thread in one go, a stutter for every block streaming in. Every world
    is now 69-103 draws a frame on average, 126 at the most (the budget 100, 150 at the heaviest landings).
    Labels drawn over the hills end at 32 m in VR, at most 16 particle bursts live. **`vr_plus`** for the Quest 3 / 3S
    (picked by itself at the first start; VR and VR PLUS on the settings page in a headset): 90 Hz (one step down to the
    next rate when the frames keep missing it), an 80-block view, sun shadows to 24 m, MSAA 4x, the child's own style
    (REALISTIC allowed, never glow). Each session prints the headset's model, its preset and the rate in logcat. Notes:
    `docs/devlog/parts/vr-perf.md`.
  - **As built (round 4, VR-SOUND; owner #110 "what exciting things with vr"; plan
    `docs/superpowers/plans/2026-10-16-vr-round4.md`, notes `docs/devlog/parts/vr-r4-sound.md`):** **instruments you play**:
    two blocks for everyone, the **Xylophone** (eight rainbow bars, the C major scale C5-C6, longer bars lower) and the
    **Bongo Drums** (a big low skin, a small high one, a wooden shell). A tap plays the bar or skin under it on a phone,
    the web or a PC, the bar's letter popping up over it; in VR two mallets float over the nearest one: grip one and
    hit, louder the harder, a buzz in that hand at the note's own frequency (the trigger plays the bar under the mallet
    too). **LOOP** counts in a bar, records four bars at 100 beats a minute and plays them again and again under the
    child's playing (up to three layers; STOP). Friends hear every note. The School's Music in it: the note names, the
    pentatonic scale, pitch and length, ta and ti-ti, bars and beats, ostinato layers, loops. The tones are our own.
    **The cockpit you touch**: seated in the rocket in VR, STAGE, LEGS and LIGHTS are big buttons on the dashboard,
    poked with a fingertip (STAGE and LEGS light up when it is their moment; LIGHTS darkens the capsule to see the stars);
    the controllers rumble with the engines in short pulses, the stages part with a thump, the countdown's last three
    seconds tick in the hands.
  - **As built (round 4, VR-HANDS; owner #110 "hands ... handle items", #116 "build a house like in real world"):**
    both hands take things (a glow and a tick near, the laser's far pull with a flick or a 0.6 s hold, throws, two-hand
    stretches, an over-the-shoulder bag, pickup bags); the hand's picture stops at a block's face. **Bricks by hand in the
    world:** a block from the bag over the shoulder, from the wrist hotbar or out of a wall, carried brick-sized, a
    life-size ghost where it goes, let go and it is laid (the laser's own place: one undo, Survivor's bag, online). The
    wrist hotbar is touchable. Waves (buddies wave back and hold up a paw, animals look up, bot friends wave),
    high-fives (the paw, VR friends), buddies' eyes that look at the child, a 0.5 m personal bubble. **The Build Table**
    (MORE → BUILD TABLE in a headset): 10 cm blocks at hand height, SAVE STAMP, WAKE IT (a buddy), the School's
    "build the answer" boards on it. **MODEL VIEW** (MORE, the Sandbox only): a giant over their world as a model,
    the little figure of themselves put down to go there. Notes and rulings: `docs/devlog/parts/vr-r4-hands.md`.
  - **As built (round 4, VR-WONDER; owner #110 "what exciting things with vr"):** **hold a planet**: in a headset the
    Star Map's solar system is a moving orrery within reach under the map's panel (the planets where they really are
    today, an Earth year in 40 seconds, their moons, Uranus on its side; a hand near one holds time still). A planet taken
    grows to its true size against Earth (Earth 4 cm, Jupiter 45 cm), opens its card (read aloud; the Space Book), two
    hands stretch it, a planet in each hand is compared ("Jupiter is 11 times as wide as Earth!"); let go it glides home;
    dropped in the gold LAND ring it flies there as LAND or HOME does; TRUE SIZE lines the planets up before a Sun 109
    Earths across. **The telescope and the magnifier** (items 500 and 501, VR only for now: the palette's LOOK row,
    Survivor's things for free): the hotbar's lens is in the hand; its zoom (2x to 8x, the magnifier 2x to 4x) only inside
    the lens, steadied; the magnifier over sand, leaves, a trunk, snow, ores shows a close-up of our own and a short fact.
    **The Lab bench by hand**: float or sink and magnets on a real bench at hand height (a handle lifts it): cubes sorted
    into two baskets are the guess, dropped in the tank they float or sink as the Lab's tested models say, the magnet
    pulls the iron nail, the steel clip and the food tin from 10 cm; the why cards after, on the panel. The School's
    units each links to: the notes.
    Notes and rulings: `docs/devlog/parts/vr-r4-wonder.md`.
- **Cars (owner #109, 2026-10-16: "in the game we also should have a cars to drive, different kind of cars and flying
    cars"):** ready-made cars to drive, beside the built-buddy rides (a buddy with WHEELS or WINGS stays as it is). The
    brief: `docs/superpowers/plans/2026-10-16-cars-brief.md`; the notes, rulings and sources: `docs/devlog/parts/cars.md`.
  - **Eight kinds**, each with its own feel, look and seats, built from boxes in the game's blocky style (our own
    models: no brands, no real makes), four colours each (cosmetic, picked in the garage):
    | Kind | Top speed (m/s = blocks a second) | Climbs | Seats | Survivor price | Its own thing |
    |---|---|---|---|---|---|
    | Go-Kart | 9 | 1 block | 1 | 40 | small, the quickest turns |
    | Off-Roader (the brief's jeep: a 4×4) | 10 | 2 blocks | 4 | 120 | big tyres for hills |
    | Race Car | 14 (the fastest on flat ground) | 1 block | 1 | 200 | low, wide, a wing |
    | Pickup Truck | 10.5 | 1 block | 2 | 150 | carries a load of blocks in its bed |
    | Bus | 7 | 1 block | 8 | 180 | slow; the whole team rides along |
    | Monster Truck | 9.5 | 3 blocks | 2 | 250 | huge wheels; it bounces |
    | Hover Car | 10 driving, 10 flying | 1 block | 2 | 400 | floats on air; FLY lifts it up (24 blocks over the ground at most) |
    | Sky Taxi | 8 driving, 11 flying | 1 block | 4 | 500 | a flying car with seats for friends |
    No car is faster than 14 m/s on the ground, and no flying car faster than the paid Fly (11 m/s, the rides' ruling).
    Flying cars never go higher than the flight ceiling (150, under the sky's darkening at 160 and the space line at
    200: a car never takes a child to space; the rocket does).
  - **Getting a car: the garage** (MORE → CARS, every world but Monster Wave's arena): a page of the eight cars, each
    with its picture (drawn from its own model), its numbers, its colours and its card. The Sandbox: GET IT, free. The
    Survivor: BUY with Survivor gold (earned by learning, never a paywall): bought once, the child's own for good (the
    profile's, in every Survivor world); CALL MY CAR brings it in front of the child. Each child has at most one car of
    each kind in a world (GET IT or CALL again brings that one, in the colour picked), at most 4 out at once (the oldest
    parked one goes back to the garage), 12 cars in a world. PUT AWAY sends one back. A car left alone stays where it
    was parked and is saved with the world; a lost car (far away, fallen off an island) is called back.
  - **Driving is arcade and kind:** the stick drives (forward, back, turn); the camera follows behind. Buttons: the
    RIDE button says DRIVE (or GET IN for a free passenger seat) next to a car, and HOP OFF in it; HORN; FLY / LAND in
    a flying car (in the air JUMP is UP and DOWN dives, as on the dragon). PC: WASD, Space (FLY; in a ground car the
    horn), E (HOP OFF; Y as for rides), H (horn); a pad and the Quest's controllers: the left stick, A (FLY / UP; the
    horn on the ground), B (DOWN), Triangle / Y (HOP OFF). A tap on a car gets in too; a tap on a pickup's bed with a
    block in the hand loads 8 of it. A car hops up steps it can climb (1, 2 or 3 blocks), bumps off higher walls and
    stops; it never runs anyone over: players, animals, monsters and buddies stop it and are pushed gently aside (never
    in VR). No damage, no fuel. In water a ground car floats like a boat at a slow 3 m/s and climbs out onto a bank; a
    hover car glides over water.
  - **Together online:** host-authoritative like the rides: the host decides every seat (near the car, a free seat,
    able to ride: not knocked out, asleep or hiding) and every move (only the driver's stick moves the car); friends
    take the free seats, see each other inside, and hop off anywhere safe (never inside blocks). Guests see cars move
    smoothly (the synchronizer's interpolation).
  - **VR:** the rider sits on the car's seat as on a ride (the origin follows the seated body; the comfort vignette
    while it moves, the guest's mount filtered), no roll ever (a car only turns round its up axis), a black blink on
    getting in and out, facing the car's front as one gets in; the walking stick drives.
  - **Learning:** each kind has a short card the child can read and hear (how an engine turns the wheels, four-wheel
    drive, downforce and electric race cars, a pickup's bed and springs, buses and electric buses, why big wheels climb,
    how a hovercraft floats, real flying cars that were tested): every fact checked, sources in the notes.

## 4. Game modes

### 4.1 Start flow
1. Title screen.
2. **First launch only:** neutral birth-year picker → only the **age band** (`under_13` / `13_plus`) is stored, never the birth date. Changing the band later requires the parent gate.
3. **First launch only:** choose a username (rules in 5.13).
4. Main menu: **Sandbox**, **Survivor**, settings, and a small black "admin panel" text at the bottom (M3).
5. The username is always shown at the top right of the screen.

### 4.2 Sandbox
- Unlimited gold (shown as ∞), every block, every tool, every Physics Lab mode.
- Build anything: homes, portals, parkour courses.
- [M2] Monsters can be summoned for fun but never appear on their own.
- Sandbox gold and items stay in Sandbox worlds; they never unlock account-wide items.

### 4.3 Survivor
- The player starts with almost nothing, gathers blocks by breaking them, and buys tools and special blocks with gold.
- Monsters roam at night; the player can hide (5.2) or fight (5.3).
- The **Monster Totem** is an in-world object; tapping it starts a wave. Surviving the wave pays gold.
- Each universe has monster levels 1–5 and one boss. Beating the boss opens a portal to the next universe (5.1).
- **Death:** the player respawns at their bed (world spawn if none), drops carried blocks in a pickup bag at the death spot, and keeps gold and tools.
- **Flying** costs gold per minute (amount scaled by universe, tuned in M2). Ghost mode is not available. Owner #78
  (§21e): flying needs a machine the child invented (the kite's lift, the balloon free, the plane, the jet twice the fuel).

## 5. Systems

Each system is tagged with the milestone that builds it.

### 5.1 Universes [M2 first universe, M3 universes 2–4, later the rest]
Each universe has its own look, blocks, music, monster levels 1–5, a boss and secrets.

| # | Universe | Monsters | Boss |
|---|---|---|---|
| 1 | Green Meadows | slimes, goblins | Stone Golem |
| 2 | Sandstorm Desert | mummies, scorpions; trap-filled pyramids | Sand Serpent |
| 3 | Frostpeak | yetis, ice bats; snowstorms hide everyone | Frost Giant |
| 4 | Candy Kingdom | gummy monsters | Cake Monster |
| 5 | Dragon Realm (owner feedback #39, §14.2a) | shadow bats, wisp spirits; floating islands over a starry void | Sky Dragon |
| 6 | Glow Caves (built 2026-10-17) | spore puffs (see only light), blind cave crawlers (hear only); stealth in a soft glowing dark | Spore Mother |
| 7 | Neon City | robots, laser drones | Mega Mech |
| 8 | Lava Core | fire imps | Magma Titan |
| 9+ | Remix universes | mixed themes + random twists (low gravity, giant monsters, endless night) | remixed bosses |

- **Scaling:** in universe *u*, gold rewards and monster health and damage are multiplied by 2^(u−1). Gear tiers and upgrades keep pace so it stays winnable; exact balance is tuned in M2/M3 playtests.
- **The Glitch:** a hidden universe reachable only through a secret portal recipe whose clues are scattered across all universes [later].
- **As built (universe 6, the Glow Caves, 2026-10-17; `docs/devlog/parts/glow-caves.md`, `docs/DEVELOPMENT.md` "The
  Glow Caves"):** the ladder's sixth universe (`world/universes/glow.gd`), opened by beating the Sky Dragon. A 2.5-D
  layered cave under a meadow roof (`GlowShape`, `GlowGenerator`): big domed halls and wide passages, crystal halls with
  selenite beams, underground lakes, stalactites and stalagmites, daylight shafts with a spiral ramp up to the roof's
  flowery meadow, bedrock at y −16; its own soft blue-violet dark (never black) lit by glow moss, giant glowshrooms and
  glow-worm ceilings (no real lights). 16 blocks on page 45 (ids 768-783) in both styles, its portal core 223 on page 10.
  Spore puffs (see only light) and blind cave crawlers (hear only), levels 1-5 by shape and colour, a golden puff; the
  Spore Mother (spores on rings shown first, a rolling ring to jump, a puff that hides her, open gills: double damage).
  The caves' secrets in their own blocks (pearl-X treasure, hidden rooms, the flowstone temple, hidden grottos, selenite
  geodes, the treasure pack's places); Mira the cave guide's quests. **Learning is play (owner #122):** a Cave Wonder in
  nearly every 128 × 128 area (the Glow-worm Grotto, the Drip Stone, the Echo Fork, the Rain Carver, the Blind Fish
  Lake: each real fact is the move that wins), two sights (a crystal hall, the longest cave), the Cave Book (the Secret
  Book's page). A free PEEK at the locked caves on the hub's card and the Star Map's (a moving picture, no pressure).

### 5.2 Monsters and stealth [M2]
- **Visibility meter:** light level, crouching, fog and cover change how visible the player is.
- **Noise meter:** running is loud, crouching is quiet.
- **Hiding spots:** bushes, barrels, closets.
- Monsters show **?** when suspicious and **!** when they see the player, then search the last known position.
- **Behaviours:** chaser, jumper, spitter (ranged), sneaker (invisible in darkness), tank, flyer. Each universe adds a twist.
- Monster level is shown by **shape and color** (colorblind-safe), with a health bar.
- At most about 20 active monsters at a time.

### 5.3 Combat, tools, defenses [M2; first weapons and tools in M1b §3b]
- Cartoon combat: monsters burst into coins and confetti; no blood.
- Tool tiers: wood → stone → iron → crystal → cosmic (sword, bow, shield, pickaxe, axe). Melee has light aim assist for touch screens.
- Defenses: walls, doors, traps, lanterns that scare away weak monsters.
- Boss fights: arena, clearly signalled attacks, boss health scales with team size.
- Potions bought with gold: Moon Jump, Invisibility, Speed.
- No hunger or thirst.
- Co-op: knocked-out players can be revived by teammates [M4].

### 5.4 Physics switch and Physics Lab [M1 basic, M3 full]
- **M1:** Normal, Fly (no gravity, up/down buttons), Ghost (fly + pass through blocks). Sandbox only.
- **M3 Physics Lab (Sandbox):** Normal, Moon gravity, Zero-G, Fly, Ghost, slow motion; jump pads and speed pads.
- **Survivor:** Fly only, for gold per minute (4.3).
- **Owner feedback #54 (§3b):** in the Sandbox a double tap on JUMP takes off too, like the FLY button.

### 5.5 Building [M1 basic, M3 tools]
- Semi-transparent preview of where the block will go; tap to place; press and hold to break.
- **Undo** (last 20 actions).
- [M3] paint any block; Sandbox power tools: line, fill, copy/paste; smart blocks: buttons, doors, pressure plates, jump pads, teleport pads; **portal network** (place portal frames and link them).

### 5.6 Economy and Gold Farm [M2 economy, M3 farm]
- **Gold sources:** waves, monsters, bosses, secrets, missions, farm, selling to the trader, tutorial, codes.
- **Gold sinks:** tools, blocks, avatar items, pets, farm upgrades, flying, potions.
- **Gold Farm:** a building in Survivor worlds. If the player is inside it when they leave or close the game, they earn `rate_per_hour × 2^(u−1)` for the time away, capped at 12 hours. Farm upgrades raise the rate and the cap; animated workers show the farm working.
- **Welcome-back celebration:** on return, a coin shower shows exactly what was earned.
- **Clock:** before M4 the device clock is used (cheating possible, accepted pre-launch); from M4 the server clock decides.
- Optional notification "Your farm is full!": **off by default**; for `under_13` only a parent can turn it on; at most once a day; never 20:00–08:00.

### 5.7 Secrets [M3]
- **Secret Book:** one page per universe with "???" slots and a found/total count.
- Fake walls, hidden chests, pressure-plate puzzles, riddle notes.
- **Golden monsters:** rare, they flee, and drop a pile of gold.
- **The Wanderer:** a rare, mysterious character who gives riddles.
- A hidden back room in the Shorts Theater.
- New admin codes released with updates, on social media **and hidden in the game** (the Wanderer, bottles, a news board at spawn); no short expiry.

### 5.8 Progress and rewards [M3]
- Player level and titles on the name tag ("Boss Slayer", "Secret Hunter").
- An **adventure board**: 3 picture goals the child picks, which never expire (a new one appears when one is done). No daily login gift: pets sometimes bring a **present while the child plays**. Titles for every play style. **Missing a day never costs anything.**

### 5.9 Avatar, pets, photo mode [M3]
- Blocky Roblox-style avatar. The editor covers skin, face, hair, hats, shirts, pants, capes, wings, running trails, emotes and dances.
- Avatar items are **account-wide** and unlocked with Survivor gold, achievements or codes. A basic set is free. Sandbox does not unlock them.
- **Pets** follow the player and each has a small perk (glows in caves, pulls in coins, barks when a monster is near).
- Items and pets have fixed prices or are earned. No random boxes, ever.
- Photo mode saves to the phone's gallery and shares through the phone's share sheet only where a grown-up's
  **photo sharing** switch allows it (§5.14: off for `under_13` until a grown-up turns it on); photos also feed the
  **Animal Book** and the **Memory Book**.
- A free base set of emotes and dances. Pets never get sick, starve, run away or feel sad.

### 5.10 Tutorial [M3]
- A buddy robot, **Pip**, teaches by doing: move and look, triple-jump a gap, build a bridge, break a wall, hide from a harmless practice monster, tap a Totem. **Voice-first and icon-first** (babble voice, pictures, one action per step, any step can be replayed).
- Finishing gives **500 Survivor gold** and a free hat, and Pip becomes the player's first pet.
- It can be skipped, but skipping gives no reward.

### 5.11 Admin panel and secret codes [M3]
- Small black "admin panel" text at the bottom of the main menu opens a code field.
- Codes are normalized (trimmed, lowercased), and only their SHA-256 hashes (with an app salt) ship in the app.
- Each code works once per account. Before M4, once per device profile; from M4 the server redeems and validates.
- First code: `sasa192974` → **1,000 Survivor gold**.

### 5.12 Shorts Theater [M3]
- A building near spawn. Entering it opens a vertical (9:16) video panel in the middle of the landscape screen. Next/previous and exit buttons sit **beside** the player, never on top of it.
- **YouTube (everyone):** the official embedded player in a WebView. It plays **curated channels** (e.g. Funny, Animals, Gaming, Music) defined on the server, so they can change without an app update. It is not an endless algorithmic feed, which would risk YouTube API policy III.I.1 ("must not mimic or replicate YouTube's core user experiences").
  - Player rules: at least 200×200 px, no overlays, one autoplaying player, and a Referer header identifying the app.
  - Video lists come from the YouTube Data API on the server and are cached for at most 30 days.
- **TikTok (13+ only):** a TikTok channel using TikTok's Embed Player (`tiktok.com/player/v1/{id}`) in the same panel.
- **Under 13:** only videos flagged Made for Kids, tracking off, behind the parent gate. Google is notified that the app is child-directed (policy III.J). No TikTok.
- No gold or rewards for watching.
- The feature can be switched off from the server.
- **Tech:** an Android WebView plugin in Kotlin (evaluate existing plugins first: `office-bsmx/godot-webview`, `brown5lc/Godot-4-Android-WebView`; otherwise write our own). The iOS plugin (WKWebView) is built on the Mac in M5.
- **As built (owner #89, 2026-09-30, "finish tv shows"; `docs/devlog/parts/tv-shows.md`):** EasyCraft TV plays **real
  videos**: 8 channels (EasyCraft TV's picks, Space, Science, Nature and Animals, How Things Are Made, Music, Art,
  History), 77 YouTube videos from official channels of space agencies, museums and children's educational studios,
  each embeddable and set "made for kids" by its maker (`tools/theater_list.py check`), bundled with the game
  (`data/theater/channels.json`) and kept on the server (module 0.2.17: `theater_channels` for every game,
  `theater_set_channels` for the owner only; a game that is online reads it and keeps the last one). The panel: the
  channels as big picture tabs across the top, the title and CLOSE over a **16:9** player (real children's videos are
  landscape), BACK left and NEXT/EXIT right of it, the channel's videos as cards (title, maker) under it, four a page.
  **The made-for-kids settings for everyone** (the age rules are off, #69): only videos made for kids, no TikTok,
  no third-party cookies, and nothing starts by itself (walking in shows the video still; a tab, a card, NEXT or BACK
  starts it; its end lights NEXT up). The game's sound pauses while a video is on the screen. A PC: Esc leaves, N
  next, B back. **In the browser** the page shows YouTube's privacy-enhanced player over the game (a sandboxed
  credentialless iframe, Chromium) with a big CLOSE; Safari and Firefox (whose cross-origin-isolated pages can't show
  it) get WATCH, which opens the server's `/tv/` player page in a tab. Android: the plugin, with the Referer naming
  the package the game runs as.

### 5.12b EasyCraft Shorts: short learning animations made in the game (owner #94, 2026-09-30)
The owner: "implement short scrollings like tiktok where [we] create videos and animations which must be educational,
like how to build a rocket, lessons explanations, learning animations … this should be presented at tv shows room".
- **Where:** the TV shows room (the Theater, §5.12): a **SHORTS** tab first among the channels. Its screen turns into a
  **portrait (9:16) player** in the middle of the landscape screen, with a feed beside it; the other channels keep their
  16:9 real videos.
- **What a Short is:** 20-60 seconds, **drawn by the game itself** (no video files, no internet: it plays offline and
  costs nothing to download): a timeline of scenes, each with actors (words, the School's pictures, blocks, rocket
  parts, planets, the game's characters: Professor Hoot, Pip, Gemma, the robots) that move, grow, spin, fade and pop in
  step, big captions always on screen, the words read aloud (the game's read-aloud voice), and sounds (the School's
  notes, the game's effects). A Short is data (`data/shorts/<id>.json`), checked by tests like the School's lessons.
- **Swiping like TikTok:** up and down to the next or the last Short (a finger's swipe, the mouse wheel, the arrow keys,
  a controller's D-pad), each plays as it snaps in and loops; a heart keeps it in the child's own **LIKED** list (on
  the device; no counts, no one else sees it); **LEARN IT** opens what it teaches (the School's unit, the Mission Board,
  the Star Map, a planet's guide). Never an endless algorithm: a feed of our own Shorts in an order that teaches
  (a topic's Shorts together; new ones first; each seen Short marked).
- **Where they come from:** (1) **made by hand** (the first set: how to build a rocket and why stages, thrust against
  weight, the planets' orbits, the Moon's phases, gravity on each world, why Venus is the hottest, Saturn's rings are
  ice, ISRU on the Moon, how a lever lifts, the water cycle, photosynthesis, fractions of a pizza, …); (2) **made from
  the School's lessons**: every written unit's lesson (grades 3-7) becomes a "Lesson in a minute" Short, its cards'
  pictures and words animated in turn — hundreds from day one, one feed per grade and subject.
- **Safe for every child:** only our own Shorts (no uploads, no other people's videos in this tab, no comments, no
  names, nothing public); no gold or rewards for watching (§5.12); the grown-ups' Theater switch covers this tab too.
  A child **making their own Short** (from the game's photos and a few taps) and keeping it on the device: built (MY
  SHORTS, "As built (My Shorts)" below).
- **Performance:** 2D drawing only, one Short playing at a time, the next one built while the current plays; the
  emulator budget (≥ 30 FPS, no frame over 100 ms) holds while swiping.
- **High quality, with real tools (owner #96, 2026-09-30: "we must keep reels high quality, implement visuals, video,
  animation tools and use them"):** a **style guide** (the game's palette, one typeface family, caption sizes and safe
  margins for a phone held upright, motion curves: ease-out arrivals, a small overshoot on pops, no linear slides, 12-18
  frames per move), captions timed to the voice (at most ~2.5 words a second on screen), and a **quality checker** in
  the tests (durations, pacing, text sizes and contrast, every actor inside the frame). The tools: **ReelKit** (the
  timeline: keyframes, easing, transitions, particle bursts, text styles, a camera for 3D), **3D scenes in a reel** (a
  `scene3d` actor: the game's own rocket parts, planets and moons, the avatar, blocks, domes and wonders in a lit
  studio, the camera moving), **the reel studio** (`tools/reel_preview.gd`: a reel in a window, scrubbing; frame sheets:
  every half second as one picture to review; every reel is reviewed this way before it ships), and **real video**:
  cinematic reels recorded in the game with Godot's Movie Maker (`--write-movie`), converted with ffmpeg to Theora
  (`.ogv`, the game's own video player) at 540 × 960 or 720 × 1280, a `video` actor or a whole-reel video, delivered in a
  background pack (like the music) so the first download stays small; live reels (drawn in real time) stay the default
  because they are tiny and play offline.
- **As built (2026-10-01; `docs/devlog/parts/shorts.md`, `docs/DEVELOPMENT.md` "EasyCraft Shorts"):** the Theater opens
  on SHORTS, its first tab: a 9:16 player (a 360 × 640 stage the game draws: 10 backdrops; actors: words, School
  pictures, blocks, rocket parts, planets, characters, arrows and lines that draw on, 27 shapes, maps, counts; 15
  time-based moves with easing, so any moment can be sought exactly; a slow camera push-in; the caption band always
  on; the voice reads once, then the Short loops silently), swiped with a snap (finger, wheel, ↑/↓, the D-pad), a tap to
  pause, a double tap or LIKE for a heart; filters SHOWS, LESSONS (grades 3-7, then subject) and LIKED; a seen tick; a
  break card after 10. LEARN IT opens the School's unit over the Theater, the Mission Board or the Star Map. **18
  hand-made Shorts** (rockets 4, space 6, science 3, nature 2, maths 2, history 1; 36-52 s, every number re-worked by
  the tests from the game's tables or NASA's) and **614 Lessons in a minute** (35-60 s, made when shown; a card without
  a picture borrows an exercise picture that asks nothing or shows its headline; the lesson's Quick memory is left
  out). Hearts and seen Shorts live in the profile and its backup. The music rests while a Short plays. No rewards;
  the grown-ups' Theater switch covers it. The style guide is `ShortStyle`, and the quality checker is `ShortCheck` plus
  `test_short_quality` (frame, caption band, words on words). The reel studio is `tools/reel_preview.gd`: scrubbing and
  frame sheets; every Short was reviewed on its sheet. Actor kinds are pluggable (`ShortKinds`, `ShortDrawers`,
  `ShortDrawer`) with marked hooks for `scene3d` and `video`, which are next and not built. Bench: 2.4 ms a frame on
  average, the worst 25 ms (this PC, the voice on).
- **As built (Reel Studio, 2026-10-01; `docs/devlog/parts/reel-studio.md`, `docs/DEVELOPMENT.md` "The Reel Studio"):**
  a **3D stage** is data (StudioRules: a sky that can fade from day to space, a light preset of key, fill and rim
  lights without shadows, models, effects, camera keys), shown as a cinematic reel's whole picture (the Short's
  `stage`) or as a `scene3d` actor; every moment is a pure function of the time (StudioMotion, StudioCamera,
  StudioParticles: seekable, so the feed's snap, the frame sheets and the Movie Maker show what playing shows). Models:
  a rocket of the missions' real parts that RocketCheck flies to the Moon (built part by part, stages letting go and
  tumbling away), planets and moons with the flight's maps and banded gas giants, the Sun, Saturn's rings and their
  ice chunks at Kepler speeds, the flight's ground and pad, the Launch Site, **the game's own places from their worlds'
  generators** (the Moon colony, Venus's city, the Seven Wonders), the blocky avatar with emotes; effects (flame, smoke,
  dust, white billows, sparkles, steam, snow); camera dolly, crane, push-in and orbit, cuts, follow, shake and roll. A
  stage draws in a SubViewport of its own, once a pose, at its size on the screen, with the game's own looks only.
  **Real video:** `tools/reel_render.sh` films a reel with the Movie Maker and makes Theora at 540 × 960 (quality 3
  after a slight blur against the pixel art's shimmer), its still, its frame sheet and its manifest; a reel with
  `"video"` plays it under the live captions, stickers, voice and sounds (`video` actor too); ReelCheck checks it
  (here, plays, under 8 MiB, as long as its Short, no black frame). **Eight cinematic reels**, every one reviewed on
  frame sheets and the video's sheet: live *Build it part by part*, *Lift-off!*, *The planets go round*, *Landing on
  the Moon*; video *Saturn's rings up close*, *A home on the Moon*, *The city in the clouds*, *Fly over the Seven
  Wonders* (19.6 MiB together: in the APK; on the web a background reels pack after the music, an iPhone once the
  Shorts are opened; a still and "coming…" until it is in). Live reels cost 0.5-3.6 ms of GPU and about 1 ms of CPU a
  frame here at a phone's player size.
- **As built (learning reels, round 2, 2026-10-01; `docs/devlog/parts/reels-2.md`, `docs/DEVELOPMENT.md` "Learning
  reels"):** owner #94's "lessons explanations, learning animations" as **twelve more live 3D reels**, one idea each in
  50 s, across the School's subjects, each linked to its unit: *How a volcano erupts* (a cutaway island volcano, then
  Io), *The water cycle in 3D*, *Why we have seasons* (Earth's tilted axis round the Sun), *Why day turns to night*,
  *How the pyramids were built* (sledges on wet sand, courses and a ramp, the casing), *Levers and pulleys lift*, *The
  Moon's phases in 3D* (seen from Earth itself), *How plants make food*, *How mountains grow* (plates folding rock
  layers), *Volume with blocks*, *How gold is found* (the game's prospecting: quartz veins, river gravel, panning),
  *Why things float or sink*. Every number is re-worked by a test from the game's tables or a cited source and the 3D
  is checked to show what the words say; every reel was reviewed on its frame sheets and fixed. The stage gained
  teaching rigs (riders, stretch, ropes, walking, marks, the camera's aim, light and sun keys, a night side, blocks
  from shapes, rain, lava, an effect's gravity and area), a generator (`tools/make_learning_reels.py`) and a headless
  checker (`tools/reel_check.gd`); blocks shapes are filled on a worker thread and meshed a frame later (each reel
  builds in 4-13 ms here). No video: the APK's videos stay at 19.6 MiB; the twelve are 127 KB of data, 0.6-2.9 ms of
  GPU and 0.4-2.4 ms of pose a frame at a phone's player size.
- **As built (My Shorts, 2026-10-01; `docs/devlog/parts/my-shorts.md`, `docs/DEVELOPMENT.md` "MAKE MY SHORT"):** the
  SHORTS tab's fourth filter, **MY SHORTS** (the child's own, newest first), with a big **MAKE A SHORT** button. The
  maker opens over the tab in five steps, the Short playing beside it in the same 9:16 player: **KIND** (HOW I BUILT IT:
  2-4 of the child's own photos; 3 FACTS ABOUT…: one of 17 planets and moons, 14 wonders or 27 real animals, with the
  game's own facts and pictures (the Star Map's, the Wonders Passport's, the Animal Book's fact and two more each for
  the Shorts); STEP BY STEP: a build's layers rising, from one of the child's stamps or the game's six blueprints),
  **PICK**, **WORDS** (the title, each scene's words and the ending: a quick phrase, read aloud when tapped, or typed
  words through the game's word filter for children, English letters only, no names; facts and endings are picked),
  **LOOK** (nine backdrops, seven of the game's classical pieces or none, the voice on or off) and **SAVE**. A Short is a
  small recipe in the profile (`ProfileData.my_shorts`, at most 20) made into a Short when it plays (MyShortMaker), so it
  always passes ShortCheck (paced and laid out by the maker); its photos and stamp copies are small files beside it
  (`user://my_shorts/`; photo mode keeps a copy of each photo it takes). **On this device only:** the server backup
  leaves the field and its hearts out (a test proves the profile sync writes nothing when a Short is made, liked or
  deleted, and the maker's code names nothing that talks to a network); no names, no rewards; no video export (there
  is no save path for a video: a ruling). In MY SHORTS a Short of one's own has its heart, LEARN IT where it fits (the
  Star Map for a planet or a wonder), CHANGE and DELETE (SURE?). New actor kinds: `photo` (only in a child's Short),
  `me` (the child's avatar, drawn), `wonder` (a stamp), `build` (a build seen from above a corner, its layers rising).
  Touch, mouse and controller; Android Back goes a step back. Bench here: the feed 1.5 ms a frame (the worst 14 ms), the
  maker 0.9-1.6 ms (the worst 19-32 ms when a step's page is first drawn).

### 5.13 Accounts, friends, chat, co-op [M4; in-game chat bar and commands in M1b §3b]
- **Login:** unique username only; the account is bound to the device (Nakama device authentication). No password. A lost phone means a lost account until optional Google/Apple account linking is added [later].
  **Owner #67 (2026-09-28): the account on every device.** A grown-up makes a **sign-in key** on a device where the
  child plays (GROWN-UPS → ONLINE PLAY → OTHER DEVICES, behind the parent gate: 8 letters and numbers, shown once);
  on a new phone, a tablet or a browser whose storage was wiped, PLAY ONLINE → I HAVE AN ACCOUNT (the parent gate)
  takes the online name and the key, and that device signs in to the same account: the name, progress, looks and
  gold come back (§17.1). Still no password and no e-mail; MAKE A NEW KEY stops the old one, SIGN OUT OTHER DEVICES
  is for a lost phone. Google/Apple linking stays [later].
  **As built (owner #99, 2026-10-15; module 0.2.20; notes `docs/devlog/parts/accounts-99.md`): the same name on a new
  device, LOG OUT and LOG IN.** A taken name asks "Someone already has the name Anna. Is it you, from another phone,
  tablet or computer?" (YES, IT'S ME / NO, ANOTHER NAME, back to the name with RANDOM). YES opens **Move your game
  here**: never by the name alone, the new device shows a 6-digit code from the server (5 minutes) and "On your other
  device: open EasyCraft, and type this code there."; every device signed in to the account shows a card over every scene
  ("Someone wants to play as Anna on a computer. If it's you, a grown-up types the code from that screen. Never type a
  code someone tells you.", TYPE THE CODE behind the parent gate, NOT ME). The right code hands the new device a one-time
  key (only for it, once) and it signs in to the account: "Welcome back, Anna! Your name, progress, looks and gold are
  here." Three wrong codes or 5 minutes end an ask; asks are limited per name and per asking device; the new device is
  never told whether the other device is online or what it did (the lead's security review). A grown-up's key works on
  the same screen (USE A KEY). The old device stays signed in and hears "Your game is on a computer now too."
  (Its first LOG OUT kept several players on one device, "Who is playing?"; that was removed in the final review's
  simple model below: one player on a device.)
  **As built (owner #99, #105, 2026-10-16; module 0.2.20; the same notes): a password, LOG IN with it, one device at a
  time.** The owner (2026-10-15 23:06): "fix logout, still cant logout, why i need to go to grow up to logout? … also when
  i delete my account it is not deleting"; 23:14: "when starting playing create a password. so when logging in another
  device you can use password and username again to login, but if you login another device you should logout
  automatically from old device". **The move by code above rests** (the lead's quick-ship round: off in the game and on
  the server). Right after the name is claimed the child makes a **password** (typed twice in secret with SHOW; 6 to 64
  characters, at most 72 bytes; not the name, not one of the commonest, no runs like 123456 or qwerty; "Make it two
  words and a number that only you would think of." and "Never tell anyone your password. Not even a friend."); an
  account from before is asked once, with LATER. **One player on a device** (the final review's simple model, 2026-10-16:
  no kept player slots). **LOG IN** (the start screen's LOG IN beside PLAY, PLAY ONLINE's I HAVE AN ACCOUNT, a taken
  name's YES, IT'S ME, the main menu's LOG IN, a logged-out device) takes the name and the password, or a grown-up's key,
  on any device; that device plays as the account (its profile backup comes down: name, progress, looks and gold; worlds
  stay on each device), starting from a fresh player unless it is the same account it played before (known by its id),
  so gold can't double; when this player's gold and progress would go it asks first ("Pip's gold and progress on this
  device will go. Your worlds stay. Log in as Anna?" YES / NO); and **every other device is logged out**: it shows "This
  device was logged out. LOG IN to play here." (with NEW PLAYER, which asks first, and LATER; LOG IN and NEW PLAYER on the
  main menu only; offline play goes on; what was played there goes up at its next LOG IN as that account) and never
  makes a new account by itself.
  A wrong try says only "That name and password don't match."; too many make the next one wait (the frozen
  design: 5 wrong from one device, 15 minutes; past 10 wrong from new devices in 24 hours, one try every 10 minutes; a
  device linked to the account and a grown-up's key are never slowed; at most about 144 + 10 guesses a day per name); the account hears
  "Someone tried to log in as you on a new device." at most once an hour. FORGOT PASSWORD? says to ask a grown-up:
  GROWN-UPS → ONLINE PLAY → CHANGE PASSWORD on a device still logged in (the old one, or a key made there; a key made
  there is shown). **LOG OUT** is one tap and YES (the main menu's own button, SETTINGS, PLAY ONLINE's account card),
  never the parent gate; it saves to the account first (offline: refused; only with every coin on the server: "Some of
  your gold is still on its way: try LOG OUT again in an hour."), makes the player make a password first when
  the account has none, unlinks this device on the server, and forgets the account and the player on this device (the
  worlds stay: they belong to the device); then the start screen (PLAY for a new player, or LOG IN). **DELETE MY ONLINE
  ACCOUNT** asks for the password and takes this player off the device too (worlds stay): the game starts again for a
  new player, and nothing signs in again by itself.
- **Username rules:** 3–16 characters, letters, digits and underscore, starting with a letter. Uniqueness is case-insensitive. It must pass a bad-word and personal-info filter (no phone numbers, emails or addresses).
- **Friends:** request by exact username → accept or decline. Friends list with online status. Block removes and blocks.
- **Invites:** invite a friend into your world. The host phone runs the world; Nakama relays traffic. Up to 4 players. When the host leaves, the session ends and the world is saved on the host.
- **Chat:** friends-only direct messages and team chat, no message-count limit, history kept 30 days.
  - `under_13`: quick-chat wheel (preset phrases) and emotes only.
  - `13_plus`: filtered free-text chat.
  - Everyone: block, report and mute.
- Visiting a friend's world is possible only while they host it.

### 5.14 Safety and age [M1 age band, M4 the rest]
- Neutral age gate at first launch; only the age band is stored.
- **Parent settings** behind a parent gate: turn off chat, turn off online play, change the age band, and switch
  **photo sharing** (M5 store readiness F1): SHARE in photo mode sends a photo out of the game through the phone's
  share sheet, so it is **off by default for `under_13`** (and a profile without a band) and on for `13_plus`; where
  it is off, photo mode only saves to the phone's gallery. The switch is on this device (the profile, like the
  Theater's switch; it travels with the profile backup) and works without an online account. Any later way out of
  the game for a picture or a video (Build Rewind's video export) follows the same switch.
- **Parent corner** (on the device): play time, gentle reminders at natural stops (end of a wave, home, sleep), switches, "what they built". A natural stopping point: the sleep screen offers *Wake up* and *Stop for today* as equal buttons.
- M4 online rules for `under_13`: **verifiable parental consent** before friends, invites, findable usernames, chat history or shared builds; the local digital age of consent (13–16 by country); store age signals (Google Play Age Signals); a "stay safe online" card; high-privacy defaults (online play off until a parent turns it on; no voice chat).
- Reports are stored server-side and reviewed in the Nakama console.
- Privacy policy, Google Play Families policy, COPPA and GDPR compliance are reviewed before launch. **A legal review is needed; this spec is not legal advice.**

### 5.15 Look, sound, feel, accessibility [M1 onward, polish M5]
- Bright flat-colored blocks with baked ambient occlusion, a sky gradient and sun, and soft distance fog. A toon style and soft outlines are evaluated in M5 against the performance budget.
- **The look (the visuals brief, 2026-10-01; docs/devlog/parts/visuals.md):** every picture's colours as painted on
  every renderer (the web and the emulator had shown them decoded twice: neon grass, near-black leaves); ACES
  tonemapping at a lower exposure; the far land melting into the sky (the haze and the sky under the horizon are the
  horizon's colour: no band, no seam), hazy blue far hills; a golden low sun; the photo sky orange at sunset and blue at
  night; moonlit nights; Mars's red under its own dimmer sun; blocky water deeper blue across with the sun's glint and a
  gentle shimmer; leaves, flowers and wheat that sway in the wind on HIGH (not with Reduce motion); the title diorama
  whole beside the wordmark.
- **Feedback:** particles, screen shake, coin sounds, haptics.
- **Motion (owner #94, 2026-09-30: "also make more animations"):** the School's pictures that teach motion move on a
  lesson's cards (gears, pulleys, cams, levers, circuits' current, food webs, waves; new: the water cycle, the Moon's
  phases, orbits, pendulums, a rocket's stages), still in an exercise unless it asks; every panel pops in the same way,
  buttons squash, gold and stars fly to their counter, a right answer bursts stars, a unit's level-up glows; a standing
  child glances round, stretches, thinks, yawns at night and waves at a friend who walks up, and jumps for joy at a
  secret, a quest step, a goal, a tamed animal, a Wonders stamp or a landing; the helpers hop hello and cheer a quest
  step; animals hop, shake and sniff; over the meadows fireflies blink at night and birds circle by day, leaves and
  petals flutter from broken trees and flowers, the Launch Site's light blinks and its flag waves. Reduce motion calms
  it; all of it inside the performance budget (pooled, shared materials, off when unseen).
- **Music:** calm day → tense night → boss theme.
- **Accessibility:** icon-first buttons with a word underneath; main buttons (JUMP, ATTACK) about 2 cm (≈ 225 px in the 1280 × 720 design space; built in M2 Task 17 as JUMP 225, ATTACK 200 so both fit a 16:9 phone), others ≥ 135 px; the screen keeps what a child uses every minute and a **MORE** button opens a box of the rest (emotes, photos, camera view, Size Magic, Mirror, Undo, the Physics Lab); movable controls, left-handed layout, never colour alone (dots/stripes/shapes too), text size, **reduce motion** (no shake, nothing flashes more than 3 times a second), danger arrows and captions for important sounds, **read-aloud** of game text (text-to-speech; never chat), translation files (the owner's language + English first), a break ring that fills while holding.
- Placeholder art and sound come from CC0 packs (e.g. Kenney.nl) until final art.

## 6. Fair-fun rules (non-negotiable)

- No loot boxes or random paid rewards.
- No pay-to-win.
- No streaks that punish missed days, no guilt notifications. Notifications are opt-in only.
- No rewards for watching videos.
- No random rewards for *any* currency, earned gold included; no countdowns or "never returns" items.
- No guilt from characters, bots or notifications ("don't go", "miss you", "last chance", "hurry"…); a
  test fails on such phrases. **Bots are always labelled as bots** and never pretend to be children.
- Natural stopping points (sleep and save) with equal buttons; no autoplay of the next video for
  `under_13`; no analytics or advertising IDs for children.
- **Monsters never break player builds.**
- **Real money only from a grown-up** (§18): purchases only in the grown-up area behind the parent
  gate, the exact items and the price shown first; a child never sees a real-money price or a buy button.
- These are also required by store policies for young audiences (research: `docs/design/`).

## 7. Technical architecture

### 7.1 Stack

| Part | Choice |
|---|---|
| Engine | Godot 4.7.2, GDScript (typed), Mobile renderer (Vulkan) with automatic OpenGL fallback |
| World | Voxel Tools 1.7 GDExtension: VoxelTerrain, VoxelMesherBlocky, VoxelBlockyLibrary, generator (graph or script), VoxelStreamSQLite, VoxelTool, VoxelViewer, VoxelTerrainMultiplayerSynchronizer (to verify in step 0) |
| Online | Nakama in Docker (this PC for development, a small VPS for launch); `nakama-godot` client; TypeScript runtime modules |
| Video | Android WebView plugin (Kotlin); iOS WKWebView plugin (M5) |
| Tests | GUT (unit and integration), godot-mcp (automated playtests), Android emulator (device tests) |
| Placeholder assets | CC0 packs (Kenney.nl) |

### 7.2 Layers
Each layer has one job, and only talks to the layers beneath it (UI may observe any layer through signals).

1. **Rules** (`core/`) — pure logic, no nodes; fully unit-testable. Covers: wallet per mode, jump counter, physics modes, universe scaling, farm payout, code hashing, username validation, age band, chat permissions, undo stack. Game data (blocks, monsters, universes, items, avatar parts) lives in `.tres` Resources under `data/`, so adding content does not require code.
2. **World** (`world/`) — wraps Voxel Tools behind a small API: `get_block(pos)`, `set_block(pos, id)`, `raycast(from, dir, max)`, `save()`. Also holds the generator per universe and structure/secret placement from the world seed.
3. **Entities** (`entities/`) — player (state machine: idle, run, jump, fall, fly, ghost, crouch, hidden, knocked-out), monsters (perception by sight and noise, then an AI state machine), and interactables (Totem, hiding spots, portals, farm, trader, Theater).
4. **UI** (`ui/`) — HUD, menus, touch controls, theme, camera rig.
5. **Net** (`net/`) — the session layer and the RPC contracts.

### 7.3 Networking model
- Godot's high-level multiplayer API (RPCs, MultiplayerSynchronizer).
- The `Session` autoload owns the peer:
  - `OfflineMultiplayerPeer` — solo; the local game is the host.
  - `ENetMultiplayerPeer` — developer LAN mode on this PC (M1).
  - `NakamaMultiplayerBridge` — online (M4).
- **Every game-changing action goes through the same path:** client requests → host validates → host applies and broadcasts. Solo play uses this path too, so M4 plugs in without rewrites.
- The host owns world edits, monsters, pickups and wallets for its world. Clients own only their input and their camera.

### 7.4 Data and saves
- `user://profile.json`: username, age band, settings, avatar, account unlocks, Survivor gold, universe level, Secret Book, missions. Versioned schema with migrations.
- `user://worlds/<mode>_<id>/`: `voxels.sqlite` (block edits), `world.json` (seed, time of day, player state, entities).
- Autosave every 60 s, and on pause, quit and `NOTIFICATION_APPLICATION_PAUSED` (switching apps).
- From M4: the profile is backed up to Nakama storage; server RPCs handle `redeem_code`, `farm_collect` (server time) and `report_user`. Nakama wallet ledger for Survivor gold.
- Owner #67: the backup is the account's (on every device it signs in to), without the gold (the ledger is the only
  truth) and without what fits one device; worlds (`user://worlds/`) stay on the device where they were made (§17.1).

### 7.5 Performance budget
- **Target:** at least 30 FPS on Medium; 60 FPS on High for strong devices.
- **M1 measurement device:** the Android emulator on this PC (owner's choice). The emulator uses the host iGPU through the OpenGL fallback, so its numbers are only indicative. A real-phone check is on the M5 pre-launch list.
- **Levers:** view distance setting, Low/Medium/High presets (Low: no shadows), threaded meshing (Voxel Tools), one texture atlas, no heavy post-processing on mobile, about 20 active monsters at most.

### 7.6 Testing strategy
- **Unit tests (GUT)** for everything in `core/`.
- **Integration and playtests via godot-mcp:** run the game frozen, inject input (e.g. jump ×4 must yield exactly 3 jumps), place and break blocks, read the runtime state.
- **Device tests on the emulator:** exporting, installing, lifecycle (switching apps, killing the app), touch controls, FPS.
- **Playtest sessions** with children of the target age at the end of each milestone.

### 7.7 Project layout
```
res://
  autoloads/   event_bus.gd, session.gd, profile.gd, settings.gd, audio.gd
  core/        pure rules (economy/, farm/, codes/, rules/, validation/)
  data/        .tres resources (blocks/, universes/, monsters/, items/, avatar/)
  world/       terrain scene, generators/, structures/, secrets/
  entities/    player/, monsters/, interactables/
  ui/          hud/, menus/, controls/, theme/
  net/         peers, RPC contracts
  addons/      godot_mcp, zylann.voxel, gut, (M4) nakama, (M3) webview
  tests/       unit/, integration/
server/        Nakama docker-compose.yml, TypeScript modules (M4)
docs/          specs, plans
```

## 8. Roadmap

| Milestone | Name | Contents |
|---|---|---|
| **M1** | First Steps | Voxel Tools check, endless Meadows, avatar, touch controls, triple jump, build/break/undo, basic physics switch, saving, first-launch flow, multiplayer-ready core with developer LAN mode |
| M2 | Survive the Night | Survivor mode, night monsters (day/night and beds arrive in M1b), monsters and stealth, combat and tools, gold and trader, Totem waves, first boss, death and respawn |
| M3 | Worlds of Wonder | Universes 2–4 and the universe ladder, portals, Secret Book and secrets, avatar editor, pets, Gold Farm, tutorial, admin codes, missions, Physics Lab, smart blocks, Shorts Theater, photo mode |
| M4 | Better Together | Nakama: unique usernames, friends, invites, chat and quick chat, safety tools, parent settings, co-op and revive, server-side codes, farm and wallet |
| M5 | Launch | Art and audio polish, performance, accessibility, real-phone check, iOS build on the Mac, store pages, privacy policy, legal review, age ratings |
| Later | — | Universes 5–8, Remix universes, The Glitch, seasonal events, sharing saved builds, account linking, optional cosmetic shop |

Every milestone ends with a playable build on the emulator and a playtest.

## 9. Milestone M1 "First Steps" — detailed spec

### 9.1 Goal
A fun, smooth Sandbox on the Android emulator that proves the foundation — world, player, controls, saving, multiplayer-ready core — before anything is built on top.

### 9.2 Step 0: Voxel Tools feasibility check (go/no-go)
Install the Voxel Tools 1.7 GDExtension into the project and build a throwaway scene. On the emulator:
1. Terrain generates and renders around a moving viewer.
2. A block can be set and read back with VoxelTool.
3. Edits persist through VoxelStreamSQLite across an app restart.
4. FPS is measured while walking and flying.
5. Confirm whether `VoxelTerrainMultiplayerSynchronizer` exists and works over ENet between two desktop instances.

**Go:** 1–4 pass → continue with Voxel Tools. If 5 fails, block-edit sync is written by hand with RPCs; that is not a blocker.
**No-go:** any of 1–3 fails, or FPS is unusable → stop, report, and re-plan with a custom GDScript block engine.

### 9.3 First-launch flow
Title → birth-year picker → age band stored → username entry (rules in 5.13; the local check covers format and filters only; the uniqueness check arrives in M4) → main menu. Survivor shows "coming soon". On later launches: title → main menu.

### 9.4 World: endless Green Meadows
- **Size:** endless horizontally; vertical build range of about 256 blocks.
- **Terrain:** noise-based hills, lakes (water below sea level), sand beaches, trees placed by the generator from the world seed.
- **Blocks (16):** grass, dirt, stone, sand, wood log, planks, leaves, glass, brick, light block, water, and 5 bright colors (red, yellow, green, blue, purple).
- **Water** is static in M1: not solid, slows the player, and the player floats up slowly.
- **Sky and fog:** sky gradient, sun (directional light), distance fog at the view-distance edge.

### 9.5 Player
- Blocky avatar made from boxes (head, torso, 2 arms, 2 legs) with procedural walk, run, jump and fall animations. Default colors.
- **Movement:** walk and run (analog from the joystick). **Triple jump:** up to 3 jumps total, 1 from the ground and 2 in the air, resetting on landing. Coyote time 0.1 s and jump buffer 0.1 s. A small puff and sound on air jumps.
- **Camera:** third-person spring-arm camera that never clips through blocks, plus a first-person toggle. First person shows a crosshair.

### 9.6 Controls
- **Touch (landscape):**
  - Left: virtual joystick.
  - Right half: drag to look.
  - Buttons: Jump, camera toggle, physics-mode button, Undo, pause.
  - Hotbar: 9 slots at the bottom, plus a palette button that opens all 16 blocks.
- **Placing and breaking:**
  - Tap on a block face places the selected block on that face (third person: ray from the camera through the tap point; first person: the crosshair).
  - Press and hold (0.25 s in Sandbox) breaks the block.
  - A touch on the right half is classified by what it does: it moves more than 12 px → look (drag); it lifts within 0.25 s without moving → tap (place); it stays still for 0.25 s → hold (break).
  - Reach: 10 blocks. Undo covers the last 20 place/break actions.
- **Keyboard and mouse (for testing):** WASD, mouse look, Space jump, left click break, right click place, 1–9 hotbar, Z undo, F physics mode, V camera.
- All inputs are Input Map actions, so godot-mcp can drive them.

### 9.7 Physics switch (M1)
One button cycles Normal → Fly → Ghost, with an on-screen indicator.
- **Fly:** no gravity, up/down buttons.
- **Ghost:** Fly plus no collision with blocks.
- Returning to Normal while inside blocks pushes the player up to the nearest free space.

### 9.8 Saving
- One Sandbox world slot with Continue and New world (confirmation required).
- Saves block edits (VoxelStreamSQLite), player position, rotation, physics mode and hotbar.
- Autosave every 60 s, and on pause, quit and switching apps.
- Force-closing the app loses at most 60 s of progress.

### 9.9 HUD and settings
- **HUD:** username top-right, hotbar, buttons, physics-mode indicator, optional FPS counter.
- **Pause menu:** Resume, Settings, Save & Quit.
- **Settings:** graphics preset (Low/Medium/High), view distance, master volume, FPS counter toggle. Saved in the profile.

### 9.10 Look and sound
- Flat bright block textures in one atlas, with baked ambient occlusion from the blocky mesher.
- CC0 placeholder sounds: place, break, jump, air jump, footsteps.

### 9.11 Developer LAN mode
A hidden developer menu (e.g. triple-tap the version label) offers Host and Join on this PC. Two desktop instances connect with ENet:
- Each sees the other's avatar move and animate.
- Block place/break syncs both ways through the host.
- The host saves the world.

### 9.12 Out of scope for M1
Monsters, gold, Survivor, avatar editor, secrets, tutorial, admin codes, online accounts, Theater, portals, smart blocks, music. (Day/night and beds moved to M1b §3b.)

### 9.13 Acceptance criteria
1. A fresh install on the emulator goes age → username → menu → Sandbox, with the world playable in under 10 s.
2. Triple jump works; a 4th jump press in the air does nothing (automated test).
3. All 16 blocks can be placed and broken; Undo reverts the last 20 actions.
4. Block edits and player position survive force-closing and relaunching the app.
5. Walking or flying 2 km in a straight line: no holes in terrain, and no frame longer than 100 ms after the initial load.
6. Fly and Ghost modes work; leaving Ghost inside blocks moves the player to free space.
7. At least 30 FPS average on Medium on the emulator during a 2-minute walk-and-build session.
8. Two desktop instances in LAN mode see each other's movement and block edits.
9. All GUT tests pass headless.
10. At least one child has played the build; notes on what they liked and where they got stuck are recorded in `docs/playtests/`.

## 10. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Voxel Tools GDExtension is less tested than its module builds | Step 0 go/no-go; custom-engine fallback |
| Emulator-only testing hides real-phone performance and Vulkan issues | Real-phone check in M5; Vulkan/OpenGL differences tracked |
| Huge scope | Strict milestones, each playable; features tagged by milestone; YAGNI inside each milestone |
| Host phone performance and battery in co-op | Max 4 players; monster cap; host-quality check before inviting |
| YouTube/TikTok policy (III.I.1, embedding rules) | Curated channels in game context, no rewards, no overlays; server kill-switch; compliance review before launch |
| Children's privacy and safety law | Age band only, quick chat for under-13s, parent settings, legal review before launch |
| iOS WebView and Voxel Tools on iOS unverified | Verify on the Mac early in M5 |
| Economy exploits (clock, codes) | Server authority from M4 |

## 11. Open items (decide before the listed milestone)

| Item | Needed by |
|---|---|
| Nakama hosting provider and monthly budget (the kit is ready: `server/deploy/`; three providers, sizes and cost estimates in `docs/hosting.md`) | M4 |
| Google Cloud project and YouTube Data API key; TikTok developer app registration | M3 (Theater) |
| Final game name and trademark check | M5 |
| Privacy policy, legal review, Google Play ($25 once) and Apple ($99/year) developer accounts | M5 |
| Final art direction (possibly hiring an artist) | M5 |

## 12. Milestone M2 "Survive the Night" — detailed spec

Written 2026-09-24 by the lead from §4.3 and §5.1–5.6 after the owner's order to build the whole
roadmap without questions ("finish all mentioned, before ios app"). Numbers are first values, tuned in
playtests; every choice the spec left open is a ruling in `docs/devlog/2026-09-24-m2.md`.

### 12.1 Survivor mode and worlds
- The main menu's **SURVIVOR** button opens Continue / New world / Back, like Sandbox. One Survivor world
  in M2 (slot `survivor_1`); it uses the Sandbox scene with `Game.mode = &"survivor"`.
- `ModeRules` (pure) says what each mode allows. Survivor: blocks and items are counted, no Ghost mode,
  Fly costs gold, monsters come at night, players can be knocked out, cheat chat commands are off
  (`/tp /spawn /home /give /fly /ghost /time /summon /size`: "That works in Sandbox only."). Sandbox: all unlimited,
  gold shows ∞, and gentle night monsters (§12.15, owner 2026-09-24: "even in sandbox mode we should
  face some monsters"; a world setting turns them off), plus `/summon slime 3`.
- **Gold** (§2: one currency, separate per mode): Survivor gold lives in the profile
  (`survivor_gold`, never negative; `Wallet` rules); Sandbox never earns or spends real gold.
  New profiles start with 25 Survivor gold.
- **Starter kit** (new Survivor world): wooden sword, wooden pickaxe, 16 planks and 8 dirt;
  lanterns, beds and better tools come from the trader. The hotbar shows counts.

### 12.2 Gathering and inventory
- Breaking a block in Survivor gives it to the player (grass gives dirt, leaves give nothing, water
  and bedrock nothing). Placing uses one. Counts cap at 999 per block.
- **Pickaxe tiers** gate ores: coal, iron — any pickaxe; gold, diamond, crystal — iron pickaxe or
  better. Without it: "You need an iron pickaxe for this!". Other blocks need no tool.
- The palette in Survivor shows only what the player owns, with counts. The inventory is saved in the
  world (per player name, like homes).
- Stamps and mirror copies are paid for whole or not at all ("You need 3 more Planks!"); tool powers
  gather every block they may break; undo gives back or takes back exactly what its edit took or gave
  (rulings in `docs/devlog/parts/m2-task-3.md`).
- Feel (the lead, for young children): holding a finger to break shows a ring filling on the block,
  a placed block pops in with a soft glow, and the first ore that needs an iron pickaxe shows a picture
  (a blue pickaxe) as well as the words.

### 12.3 Health, knock-out, respawn
- 10 hearts (20 HP). After 5 s without damage, 1 HP comes back every 3 s. No hunger, no thirst, no fall
  damage.
- At 0 HP the player is **knocked out**: a short fade, "You were knocked out!", then respawn at their
  bed (world spawn without one) with full health and 3 s of protection. Carried **blocks** drop in a
  **pickup bag** at the spot (glowing, saved with the world, one tap within reach takes it all back).
  Gold, tools and potions are kept.
- Sandbox (§12.15): hearts too, but at 0 HP the player pops back up next to where they were, keeping
  everything (no bag).

### 12.4 Monsters of Green Meadows
| Monster | Behaviour | HP (level l) | Hit | Gold |
|---|---|---|---|---|
| Slime | jumper: hops at you, splits into 2 small slimes at level ≥ 3 | 4 + 3(l−1) | 1 + ⌊l/2⌋ | 2l |
| Goblin | chaser: runs at you, swings a club (0.8 s wind-up) | 6 + 4(l−1) | 2 + (l−1) | 3l |
- Level 1–5 shown by **shape and colour** (colourblind-safe): size grows, and a level-l monster has l
  spikes/horns; a health bar shows above it once hurt.
- **Night spawns** (DayCycle night, Survivor only): on the surface in the dark, 18–40 blocks from a
  player, never within 8 blocks of a lantern or a bed with someone home; at most 20 monsters at once
  (and ≤ 10 per player). Level = 1 + ⌊distance from world spawn / 150⌋ (max 5), ±1 at random.
- At sunrise wild monsters puff away (no gold). Defeated monsters burst into confetti and **coins**
  (pickups, drawn to a player within 2 blocks; each coin is shown in the HUD counter).
- Universe scaling: HP, hits and gold × 2^(u−1) (u = 1 in M2).
- The behaviour framework has chaser and jumper; spitter, sneaker, tank and flyer come with M3's
  universes.

### 12.5 Stealth
- **Visibility** 0–1: daylight 1.0, night 0.45, dark cave 0.3, near a lantern 1.0; crouching × 0.5;
  inside a hiding spot 0; Invisibility potion 0.
- A monster **sees** a player when within 16 × visibility blocks, inside its 120° view and with a clear
  line (grid ray over the voxel data).
- **Noise**: running (sprint) heard 12 blocks away, walking 6, crouching 1.5, landing a jump 8,
  breaking a block 7, attacking 6.
- Monster states: wander → **?** (heard or half-seen: walks to the noise) → **!** (sees you: chase and
  attack) → search the last known spot for 6 s → wander. The ? and ! float over its head.
- **Crouch**: a CROUCH button / C key; half speed, lower body, quiet.
- **Hiding spots** (new blocks): BUSH (walk into it and crouch: hidden), BARREL and CLOSET (tap: you
  hide inside, tap again or move to come out). Monsters that saw you go in will search next to it.
- *As built (Task 5):* monsters perceive players **and bot friends**; "near a lantern" is a LANTERN or
  LIGHT block within 6 blocks; just beyond the sight range (up to 1.5×) a monster half-sees you ("?");
  glass, bushes, water and open doors don't block sight; "?" also shows while it searches; it only
  attacks what it sees; a far archer's hit makes it come to where the shot came from. Crouching is a
  toggle (a lower camera and eyes: a 1-block wall hides a crouching player). A barrel or closet is
  within 4 blocks to hide in (a tap, whatever is in the hand; the camera looks out from inside, a warm
  vignette, muffled sounds, a closed eye and "They can't see me!"). HUD: an eye (open / half / closed)
  and 0–3 noise bars under the hearts; the danger arrow (research A3) at the screen edge for a monster
  that starts to see you from behind or off-screen. Rulings: `docs/devlog/parts/m2-task-5.md`.

### 12.6 Combat, tools and defenses
- **Tiers** wood → stone → iron → crystal → cosmic for sword, bow, pickaxe, axe and **shield**; damage
  and dig power × 1, 1.5, 2, 3, 4.5. The M1b items are the wood tier. A shield in the inventory blocks
  30 / 40 / 55 / 70 / 85 % of damage from the front (the best one owned counts; no button).
- Melee keeps its light aim assist. Monsters are hittable like dummies (host-validated, cooldowns).
- **Defenses** (new blocks): DOOR (tap to open or close; monsters cannot open doors), SPIKE TRAP
  (hurts monsters that step on it, 2 per second; never players), LANTERN (light; monsters of level ≤ 2
  will not come within 6 blocks).
- **Potions** (one use, 60 s): Moon Jump (jumps × 1.8), Invisibility (visibility 0, 30 s), Speed
  (× 1.5). Drinking one is a tap on the hotbar slot.
- *As built (Task 6):* Moon Jump is jump **height** × 1.8; Speed is walking and swimming; a potion
  still working is not drunk again; small timer chips top-centre-left; an invisible player looks
  see-through to everyone. In Sandbox the best shield **in the hotbar** counts. Better axes and
  pickaxes use their block power faster (dig power). Colour is never the only sign of a tier: icons
  carry 1–5 pips and held models 1–5 bands (accessibility). Numbers and rulings:
  `docs/devlog/parts/m2-task-6.md`.
- *As built (Task 8):* a door is one block and a doorway is two doors stacked: a tap opens or closes the
  whole stack, whatever is in the hand (a hold still breaks it; the host decides, one undo step, nothing
  counted in Survivor; it never closes on a player, a bot friend or a monster in the doorway). Monsters
  never open a door, step up onto a closed one or hop over it. The spike trap is a full block (in the
  floor or on it): a monster on it or in it loses 2 HP a second from the first step and the spikes pop
  up; players, bot friends and animals never. Only lanterns scare monsters (light blocks do not), 6 blocks
  measured from the lantern; a weak monster already closer walks away; night spawns stay 8 blocks away.
  Lanterns glow, and the 2 lanterns nearest the camera also light the ground (a warm, shadowless light;
  none on Low). Tilly sells doors in pairs (a doorway for 10 gold). Rulings:
  `docs/devlog/parts/m2-task-8.md`.

### 12.7 Trader and economy
- **Tilly the trader** has a stall 12 blocks from the world spawn in Survivor worlds. Tap her: the shop
  (Buy / Sell tabs).
- Buy: tool tiers (stone 30, iron 120, crystal 400, cosmic 1200 gold per tool; the wood tier is 5),
  potions (25 / 40 / 30), bed 20, lantern 5, door 10, spike trap 15, barrel 10, closet 20, bush 3,
  building blocks 1 gold per 4.
- Sell: coal 1, iron 3, gold 8, crystal 12, diamond 20 gold each; other blocks 0 (not listed).
- **Flying** in Survivor costs 10 gold per minute (charged every 6 s); with no gold left the player
  lands gently and FLY is refused. Owner #78 (§21e): only in a machine the child invented; the plane pays this, the jet
  twice, the balloon nothing.
- Gold sources in M2: monsters, waves, the boss, selling. (Secrets, missions, farm, codes: M3.)
- Shop and counter as built (Task 7, with the lead's child-psychology notes): gold in short numbers
  everywhere ("1.2K", rounded down); picture cards with a coin price and a have/need bar ("340 / 1.2K")
  under prices not yet affordable; icon-first buttons with a small word under each; two taps to buy
  (card, then BUY); one of each tool or shield; a bobbing "SHOP" arrow over the stall in a new
  Survivor world until the first visit. Rulings: `docs/devlog/parts/m2-task-7.md`.

### 12.8 Monster Totem and waves
- The **Monster Totem** stands 20 blocks from the world spawn on flat ground (built when the world is
  made). Tap it: "Wave N starts in 5…".
- Wave N: 3 + 2N monsters (≤ 20), levels ⌈N/2⌉…⌈N/2⌉+1 (max 5), from the edge of a 25-block circle.
  The wave ends when all are defeated or after 3 minutes. Every player who was not knocked out during
  it gets 10 × N gold. A won wave raises N; waves can be started day or night. The Totem glows while a
  wave runs; the HUD shows "Wave N — k left".
- After wave 5 is won, the Totem offers the **boss**.
- *As built (Task 9):* the Totem stands in every world (Sandbox waves are gentle: ≤ 8 monsters, level ≤ 2,
  no gold; MONSTERS: OFF refuses them). A tap opens a small picture panel ("Wave N", a slime "× count", the
  gold, START). Gold goes only to a **won** wave; "everyone knocked out" means every player was knocked out
  at least once during it (solo: the first knock-out). After a wave that was not won the Totem offers
  **Try again** or **Try an easier wave** (N−1, a normal wave paid normally; research G6), as equal buttons.
  Each wave always brings the same monsters; they walk to the Totem while they see nobody, and one stuck
  15 s far away is called closer. No night monsters while a wave runs. Rulings:
  `docs/devlog/parts/m2-task-9.md`.
- **Since owner feedback #44 (2026-09-24 21:07): Survivor has no Totem waves and no boss.** Waves and the
  raid boss live in the new **MONSTER WAVE** mode (§12.20). The Totem stands in Sandbox worlds (gentle waves,
  as before) and in the Monster Wave arena; a Survivor world made before keeps its wave number and boss help
  in its save, unused.

### 12.9 Boss: the Stone Golem
- Summoned at the Totem (after wave 5). HP 300 × (1 + 0.5 × (players − 1)); a big health bar at the top.
- Attacks, each clearly signalled: **Slam** (raises both fists 1.2 s, shockwave ring 7 blocks: 4 HP
  unless you are in the air), **Rock throw** (glowing rock, 1 s wind-up, 3 HP), **Charge** (paws the
  ground 1 s, runs straight 12 blocks: 5 HP). After a slam it is **dazed** for 2 s and takes double
  damage.
- Defeat: a big burst of 300 gold (split among the players present), and a **portal** opens at the
  Totem. In M2 the portal says "Sandstorm Desert opens in the next update!" and unlocks universe 2 in
  the profile (`universe_unlocked`); M3 makes it lead there.
- **Since owner feedback #44:** the boss is Monster Wave's raid boss at wave 10 (§12.20), where beating it
  unlocks the next universe and offers the choice to go there; Survivor has no boss. Universes unlocked in
  Monster Wave can be visited from Survivor's portal hub (M3 Task 5).

### 12.10 Music and feel
- Music (CC0): calm day, tense night, boss theme; crossfades on dusk, dawn and boss fights; a music
  volume setting.
- Screen shake and a vibration (Android) when hurt and on the Golem's slam; coin sounds on pickup.
- Built (Task 11): the night music plays from sunset to sunrise; the menu plays the day track; a soft red
  edge flash on hurt. Settings: Music volume, **Vibration** (buzz and shake, default ON) and **Reduce
  motion** (no screen shake or camera bob, softer flashes, default OFF; the lead's child-psychology notes).
  Never more than 3 flashes a second. Details: `docs/devlog/parts/m2-task-11.md`.
- **The audio pass** (owner feedback #27 "sounds, effect sounds, musics", #31 "clasical musics like bethhoven,
  mozart", and 20:42 "animals should have sounds, like real ones"; M5 Task 2's audio parts pulled forward;
  details `docs/devlog/parts/audio-pass.md`):
  - **MUSIC setting**: GAME MUSIC (the loops above), CLASSICAL (only classical pieces that fit the mood, a
    2 s breath between two) and **MIX** (default): by day a classical piece after every 150 s of the day
    loop, Grieg's Morning Mood at sunrise, the game's own loops at night, in caves (the Crystal Cave loop)
    and in boss fights, whose moods tell the child what is going on. The menu plays gentle pieces. No piece
    plays twice in a row; a universe can name its own pieces first (the Candy Kingdom: the Nutcracker).
    14 pieces by Beethoven, Mozart, Bach, Grieg, Tchaikovsky, Vivaldi, Satie and Rimsky-Korsakov, in
    public-domain or CC0 recordings (or our own rendering of a public-domain score). A starting piece shows
    "Now playing: Mozart — Eine kleine Nachtmusik" for 4 s (the **Song names** setting hides it).
  - **SOUND EFFECTS** volume beside the music volume. Every button clicks (softer for toggles); animals have
    real voices (a call now and then within 20 blocks, a hurt voice, a happy one when petted or fed, each
    animal its own pitch); monsters grunt and cry out when hit; footsteps by block; a pickup pop, a gold
    clink, jingles for levels, goals and badges, a horn when a wave starts; **ambience** by place and time
    (birds by day, crickets at night, cave drips, sea waves, wind on peaks and in the desert by day).
  - **The animal chorus** (owner feedback #50, "a lot chicken sounds only everywhere"; details
    `docs/devlog/parts/owner-50-sounds.md`): the idle calls a device hears share one budget, at most one call
    every 6–10 s however many animals are near (every animal used to roll its own timer: a flock of 5 hens was
    18 clucks a minute). A kind rests 20 s after it called and the kind heard least lately comes first, so
    one kind never dominates; the nearest animals call first, farther ones are rarer and quieter; a take never
    plays twice in a row; the loudest recordings are evened out (the hens were 4–13 dB louder than the others
    through a phone speaker). The listener is the device's own camera. A child's own action's animal voice
    (hurt, happy) is never held back; the chorus keeps quiet a moment after it. Ambience fills the space.

### 12.11 Multiplayer
- The host owns monsters, health, knock-outs, pickups, waves, the boss and the trader's checks. Each
  player's Survivor gold is their own profile's: the host decides every change and sends it
  (`Session`), the player's game applies it (LAN trust until M4 moves the wallet to the server).

### 12.12 Acceptance (emulator)
All §12 behaviours are covered by the acceptance tour (`tools/tour.gd` gains Survivor checks), and
the autopilot bar still holds in both styles with a night of monsters around.

### 12.13 Real water (owner 2026-09-24: "player should swim not walk like on ground … also underground
waters", "add water effects, like swimming, splashing")
- In any water (sea, rivers, lakes, flooded caves, placed water) the player **swims**: the body tips
  forward into a swimming pose with arm strokes and kicking legs, floats with the head above the
  surface when idle, moves at swim speed in the look direction (look down and push forward to dive;
  JUMP swims up, DOWN / crouch dives), and never walks on the bottom.
- Getting out: at the edge, pushing forward against a 1-block bank climbs out. *Owner feedback #30
  (2026-09-24):* whatever the view's tilt (a push into a bank never dives: the swimmer floats up to it),
  UP alone next to a bank climbs it too, and UP + a push climbs a wall 2 blocks above the water.
- Effects: a **splash** (droplets + sound, size by speed) when entering or jumping in, **ripples** on
  the surface around a swimmer, **bubbles** rising from a diver, **drips** falling off for a moment
  after climbing out, wet footsteps, a muffled sound under water. Animals and monsters that enter
  water splash too. All effects use the shared particle material (`Fx`).
- No drowning (children's game); the underwater view (M1b) stays.
- Built in M2 Task 14 (rulings in `docs/devlog/parts/m2-task-14.md`): the body swims once the water
  reaches its chest (1 × size above the feet); knee-deep water is waded (half speed). Idle, the eyes
  float 0.3 above the surface. A look down of more than 0.5 rad dives (the third-person camera rests at
  −0.35). JUMP lifts the chest, never out of the water: getting out is the climb over a bank at most
  1 block above the water. The realistic avatar's strokes are procedural (no swim clip in the Kenney
  pack).

### 12.14 Bot friends (owner 2026-09-24: "we should be able to play with bots as a friends")
- In any world (Sandbox or Survivor, solo or host), the pause menu's **FRIENDS** row adds up to 3 bot
  friends. Each has a name, its own avatar colours and a personality (builder, explorer, fighter).
- Bots play *with* the player: follow at a distance, explore nearby, fight monsters next to the player
  (the host's combat rules), help at Totem waves and the boss (they count for boss health like a
  player), place small builds next to the player's (builder), point at secrets they find (explorer:
  "Look! Something shiny over here!"), and say short friendly lines in the chat. They can be knocked
  out and come back like players; they never take the player's blocks, gold or kills' gold.
- Bots are simulated only by the host, with the animals' cost rules (decisions at 10 Hz, rest far
  away). They are saved with the world.

### 12.14a Talking to bot friends (owner feedback #38, 2026-09-24: "make sure when chatting with bot friends they understand what you say and what you ask")
- **Understanding on the device, no internet, no big model:** a small scored matcher
  (`core/bots/BotIntents`) reads the child's words in **English and Georgian** (Georgian letters or
  Georgian typed in Latin letters): it cleans them (lower case, accents, stretched letters like
  "folllow", common misspellings, "u"/"plz"/"thx"), fixes small typos against its word list, and picks
  an intent from keywords, phrases and a question cue. Nothing is stored or sent anywhere; the chat
  filter still applies to what the child types, and bots never react to personal information.
- **Who hears:** the child's own bot friends near them (32 blocks); a bot's name at the start or end
  ("Mossy, follow me") talks to that one only, wherever it is; "follow me", "come here", "help" and
  "where are you?" reach all the child's own friends. Other players' bots never listen to them.
- **What they do** (they switch behaviour and answer with a fixed, friendly line in the child's
  language, "Name (bot): …"): follow me / come here (they follow closer for a minute), wait / stay /
  stop (they wait there), go home (they wait at the child's bed), give me space, build (a house, a
  tower, a wall, next to me, with my blocks: a builder builds it in a few steps; Survivor builds stay
  leaves), explore / find treasure / find secrets (an explorer leads the way to the nearest secret
  nobody found), fight / guard me / protect me (they stay close and guard a wider circle), run away /
  hide, dance / do a trick, race me (M3 Task 7's race), hello / thanks / good job / bye (friendly
  replies and a heart).
- **Questions answered from the game:** where is Tilly? (her stall's direction and distance, then the
  friend shows the way), where is treasure / the nearest secret? (direction words such as "over that
  way, up the hill", then the explorer leads), what are you doing?, how many hearts do I have?, is it
  night soon?, what's your name? (always "…your builder bot"), can you help me? (what you can say),
  where are you?
- **Words the bot doesn't understand** get a kind hint, never mocking: "Hmm? You can say: follow me,
  build a house, find treasure…" (alone in a world always; with other players only when a bot was
  named, so chat between people is never interrupted).
- **Under-13 players** talk to bots with pictures: the quick-chat wheel's phrases reach their bots too
  ("Follow me!", "Help!", "Let's build!"…), and the wheel's BOTS page has picture phrases for bots only
  (wait, build a house, find treasure, guard me, dance, where is Tilly?…). Words typed to their own bots
  never reach other people.
- **Memory:** a friend remembers what its child asks for (fading over time, saved with it): asked to
  follow often, it keeps closer; asked to build often, it builds more often; kind words make it like
  the child more (a heart).

### 12.15 Sandbox monsters (owner 2026-09-24: "even in sandbox mode we should face some monsters")
- Sandbox worlds get gentle night monsters: at most 8, levels 1–2, the same kinds as Survivor. A world
  setting **Monsters: ON / OFF** (default ON) in the pause menu.
- Sandbox players have hearts; at 0 HP they pop back up next to where they were with full health and
  keep everything. Defeated monsters give confetti (no gold: Sandbox gold is ∞).

### 12.16 Secrets and treasures (owner 2026-09-24: "most important we need secrets, surpices,
hidden treasures and similar exciting things") — pulled forward from M3 for Green Meadows
- The world hides deterministic secrets (seed + area): the same world always has the same ones, and
  every area of 128 × 128 blocks has a few.
  1. **Buried treasure**: a chest 2–4 blocks under a small "X" of flowers or pebbles. Some chests hold
     a **treasure map** that points to the next buried treasure (compass arrow + distance on the HUD).
  2. **Hidden rooms**: underground rooms behind a **fake wall** (looks like stone but a tap makes a
     hollow knock and it opens) with torches, a chest and sometimes a riddle note.
  3. **Sky islands**: rare floating islands with a golden chest, reachable by building or flying.
  4. **Golden slimes** (Survivor) and **golden animals** (both modes): rare, they run away; catching
     one gives a pile of gold (Survivor) or a golden trophy block (Sandbox).
  5. **Puzzle temples**: small stone temples with three pressure plates; a riddle note tells the order;
     the right order opens the vault.
  6. **The Wanderer**: a rare hooded visitor at dusk who asks a riddle (3 choices) and gives a reward
     for the right answer, then vanishes in sparkles.
  7. **Shooting stars**: some nights a star falls nearby, leaving a glowing meteor with crystals.
  8. **Crystal geodes**: hollow crystal balls deep underground.
- Chests hold gold (Survivor: 20–150 × 2^(u−1)), rare blocks, sometimes a better tool or a potion, and
  **unique decorations** (golden trophy, lamp, flag) that exist only in treasure. No paid randomness,
  ever (§6): treasure is found by playing.
- The **Secret Book** (a book button next to CHAT): one page per universe with a slot per kind of
  secret, "???" until found, and a found / total count per area explored. Found secrets are saved in
  the profile (account-wide progress) and the world (so a chest opens once).
- Surprises are announced with a sparkle sound and a short banner ("You found a hidden room!").
- **For children who can't read yet** (lead, from the child-psychology research): a temple's plates are
  painted with a sun, a moon and a star, and its note draws them in the order to step on them; the
  Wanderer's three answers are big picture buttons with a short word under each. Texts stay short.
- **The secret chime**: the first time a player comes within about 12 blocks of a secret, a soft chime and a
  twinkle around the player — a hint that something is near, never where.
- Built in M2 Task 16 (details, numbers and rulings: `docs/devlog/parts/m2-task-16.md`): a hidden room's
  stone stairs lead down to a dead end, the fake wall; the treasure map points to the nearest buried
  treasure not opened yet (Survivor uses one up per buried chest opened); treasure-only things wait on the
  Secret Book's shelf; the Secret Book button sits under MIRROR. The Wanderer comes on a world's first dusk
  and then about one dusk in three; a star falls on the first night and then about every other night;
  about one wild herd in twenty has a golden animal.

### 12.16b More secrets, chests and treasures (owner 2026-09-24 20:43: "also please create more secrets in the game" + "more chests and treasures")
Built by the owner-42 agent (details, numbers and rulings: `docs/devlog/parts/owner-42-secrets.md`). Every
new kind follows §12.16's rules: decided from the seed and the 128 × 128 area alone (the same world always
has the same ones), every structure stays inside its area (chunks meet without seams), a few blocks apart
from the other secrets, never in the **spawn's landmark zone** (60 blocks from the world spawn: Tilly, the
Totem, the hub circle, the Theater and the ways between them stay clear) and never across a river; every
entrance is open and walkable. The host decides every find and reward; finds are saved with the world, the
Secret Book counts them for the account.
- **Shipwreck** on a beach: a broken plank ship with a mast and a torn sail, a hole in its side, barrels
  and a chest (rare). In the Sandstorm Desert a ship lies lost in the dunes.
- **Sunken chest** on the seabed, 4–12 blocks under water, among broken planks (rare; swim down, §12.13).
- **Mineshaft**: a timber frame over stairs down to a short tunnel with plank rails, log sleepers, beams
  and lanterns; a **loot cart** (a chest on wheels, rare) waits at the end.
- **Dungeon vault** deep underground (about 20 blocks): a spiral stair under a lantern pillar leads to a
  hall with **three levers** (M3 Task 7's smart blocks) painted with a key, a crown and a gem, and a note
  showing the order; the right order opens the golden door to a **legendary** chest (a wrong lever: the
  levers flip back, "Clunk!"). Digging in never unlocks the chest.
- **Waterfall cave** (Green Meadows): a mossy rock with water pouring over the mouth of a crystal-lit cave
  (epic chest).
- **Hollow tree**: a giant tree with a doorway into its hollow trunk and a chest inside (rare).
- **Rainbow's end**: after rain (a hook for weather) or, while there is no rain, at the start of the day
  after the first dawn and then about one dawn in two, a rainbow arches over the land near a player for
  three minutes; walking up to the **pot of gold** at its end gives each player, once per rainbow, a fixed
  pile of Survivor gold (50 × 2^(u−1)) and rainbow blocks.
- **Wishing well** in a village-like clearing (a cobbled plaza with lamp posts): tap it to toss a (free,
  pretend) coin: a friendly sparkle and a small fixed gift — once per in-game day for each player (never a
  timer, never gold).
- **Pirate cove**: a sea cave with a sandy floor, a lagoon, barrels, lanterns and a flag on top (epic).
- **Ancient ruins**: a broken floor, fallen and standing pillars, wall stubs, an old note with a riddle
  about another secret, and a chest (common).
- **Friendly haunted house**: an old wooden house with broken windows, where two gentle ghosts float and
  giggle; tap one for its picture riddle; the right answer opens the chest (epic). Wrong: "Hee hee! Not
  quite. Try again!"
- **Campsite**: a tent, a campfire ringed with stones, log seats and a supply chest (common).
- Universes: Green Meadows has all of them; the Sandstorm Desert has the dune ship, mineshafts, vaults,
  wells, ruins and camps in sandstone; Frostpeak has mineshafts, vaults, hollow pines, ruins, snowy haunted
  cabins and camps.
- **Chest rarities** (§13.2 colours, the chest glows in its colour): common (camp, ruins), rare
  (shipwreck, sunken chest, loot cart, hollow tree), epic (cove, waterfall, haunted house), legendary
  (vault). Contents come from **fixed tables by rarity and universe**: a fixed amount of Survivor gold
  (15 / 40 / 80 / 150 × 2^(u−1)), always the same things for that chest (a pick without repeats from the
  rarity's table, fixed per chest); an epic chest always holds gold blocks and a legendary one a golden
  trophy. §6: no random gold anywhere — the M2 kinds' gold becomes fixed per kind too.
- **Secret Book**: a second page, "Treasure Hunt", with a slot per new kind; until found each shows a
  **picture riddle** (a picture of where to look and a few words); page buttons ◀ ▶. Hidden rooms' and
  ruins' notes hint at the new kinds; `/secret <kind>` knows them (`/secret rainbow` brings a rainbow).
- **Hints**: pet dogs (and foxes and parrots once they exist, owner #41) sniff out any unopened chest that
  isn't locked, not only buried ones; explorer bots say what they spotted ("Look! An old ship!").

### 12.17 Creature minds (owner 2026-09-24 11:47: "for monsters, for bots and for animals implement something like a mind, like a small llm, which will be used for their decisions, for their learning, so they act more like real animals, real monsters and real friends" — "but it should be light weight")
- **What a mind is.** Every animal, monster and bot friend gets a small **learned mind**: the same idea as
  a language model (a small neural network picks what to do next from what the creature senses and
  remembers, and it learns from what happens), sized for a phone. **Ruling (cost if wrong):** it is not a
  text-generating LLM. A real LLM costs hundreds of MB and about a second per answer on a phone, so it
  cannot decide 10 times a second for 40 creatures, and free-generated words reaching children would
  break §6/§16 (bots only say fixed, checked lines). If the owner wants a real language model later,
  it can speak for bots from a curated, filtered set on the M4 server; the mind's interface stays.
- **Parts of a mind** (pure code in `core/mind/`, the same for every creature, tuned per species):
  - **Senses** (about 16 numbers, 0–1): the nearest player (distance, direction, how much this
    creature likes them), own hearts, hunger, energy, time of day, light, how many friends of its kind
    are near, a threat (who hit it lately), food or a shiny thing near, and how the last action went.
  - **Drives** that rise and fall like needs: hunger, sleepiness, fear, curiosity, company; monsters
    add boldness and caution; bot friends add helpfulness and play.
  - **Memory**, small and capped: up to 8 players it knows (by name: how much it likes or fears each,
    when it saw them last) and up to 8 places (food, its den or bed, danger). Pets and bot friends
    keep it in the world save; wild animals and monsters keep it while they live, and each species
    in a world keeps a small **learned table** (saved) so the goblins of a world slowly change their
    tactics over many nights.
  - **A tiny network**: one hidden layer, a few hundred weights per species, started from hand-made
    defaults (so a new creature already acts sensibly) plus a small per-creature personality offset
    from its id (no two dogs are the same). It scores the species' actions; drives and personality
    tilt the scores; a gentle random pick among the best keeps it lively.
  - **Learning** from rewards after each action (only the last layer, small steps, weights clamped,
    so it drifts gently and never breaks): animals like being fed and petted and dislike being hit or
    chased; monsters like landing a hit and dislike being hit or defeated; bot friends like it when the
    child keeps their build, mines the ore they pointed at, or tames the animal they found, and learn
    to keep more space when the child keeps walking away.
- **What children see — minds you can read:** now and then a small **thought bubble** with a picture
  (a heart for a player it likes, a question mark when curious, zzz when sleepy, a drumstick when
  hungry, a sweat drop when scared, a light bulb when a friend learned something). Animals run over
  to a child who fed them and keep away from one who hit them; herds follow a leader, graze by day
  and sleep together at night; a dog remembers its owner. Bot friends learn the child's style: a
  builder builds with the child's favourite blocks and shapes, an explorer learns whether the child
  loves ores, animals or secrets, a fighter guards the side the monsters come from; they greet the
  child by their username (never asking anything personal).
- **Fair monsters (non-negotiable guards):** learning only chooses among fair, signalled tactics
  (straight at you, zigzag, go round, wait by cover, back off when hurt, call a friend) — never more
  damage, speed, sight or hearts than §12.4/§12.5 allow, never breaking blocks; a monster's learning
  eases off after the child's knock-outs (honest help, §16) and is capped by the universe; gentle
  Sandbox monsters learn slowly; Cozy worlds switch monster learning off. A one-time hint tells the
  child what the monsters learned ("The goblins remember your bow — they zigzag now!").
- **Light:** minds run only on the host for creatures that are active (near a player), decide at most
  10 times a second (monsters 3), ≤ 20 µs per decision on this desktop, learn only when something
  happens, and add ≤ 0.3 ms per frame for 20 monsters + 24 animals + 3 friends; saved minds ≤ 2 KB per
  world. Guests see the results and the thought bubbles (synced on change).

### 12.18 Survivor games (owner 2026-09-24, feedback #33: "in survivor mode we need different modes, one should something like you must build a house to be able to hide from monsters, if you dont hurry and build house you diy. also anothe mode can be like killing mosnters and as much monsters you kill you get more money")
- **The choice.** A new Survivor world asks "How brave are you?" (COZY / NORMAL / BRAVE, §12.1) and then
  "Which game?": two big picture cards — **CLASSIC** (a pickaxe: "Explore, build and trade.") and **BUILD TO
  SURVIVE** (a house: "Night comes fast. Build a house!"). (The first plan's third card, MONSTER HUNTER, was
  folded into the MONSTER WAVE mode by owner feedback #44, §12.20.) The game is saved with the world (`WorldMeta.game`)
  and never changes; worlds made before are CLASSIC. The difficulty works in every game. Children are
  **knocked out, never killed** (§12.3): the owner's "you die" becomes a knock-out and a new try.
- **CLASSIC** is today's Survivor.
- **BUILD TO SURVIVE:**
  - *A fast clock.* A new world starts in the morning (t = 0.25) and the first sunset comes **3:00**
    later: days run 4× (sunrise to sunset 3:30), nights 2× (sunset to sunrise 3:00). Sky, music and
    monsters follow this clock (the host's, synced; guests run the same speed between syncs).
  - *The night clock* on the HUD (one label, never a button; top, left of the middle, under the potion
    chips): a moon and "Night in 1:20" by day, a sun and "Morning in 0:45" at night, and "Nights 3 ·
    Best 5" under it. It is game time only: it stops when the game pauses and has nothing to do with real
    days, shopping or coming back. Its words stay kind (the no-guilt word test covers them).
  - *The shelter rule* (`ShelterRules`, pure): a player is **sheltered** when a solid block is within 4
    above the head (a roof) and every one of 16 flat rays from the head **and from the feet** meets a
    solid block within 6 (walls). Solid is `BlockIds.is_solid`: closed doors, glass and leaves count;
    open doors, water, bushes and air don't. The label shows a house and "Safe inside!" when sheltered;
    otherwise, with a roof but a gap, "Close the gap!" (an open door is a gap), and a picture of a roof
    with "Add a roof!" when walls are up.
  - *Sheltered players are safe:* monsters can't see them (visibility 0, like a hiding spot), so they
    never chase or hit them; monsters never change blocks (§6).
  - *Nights are fiercer outside:* up to 14 monsters per player (instead of 10; 20 in all) and one level
    higher (at most 5).
  - *Knocked out:* you wake at home (your bed or the world spawn) as in Classic; in solo, or when every
    player is down, the night ends and everyone wakes in the morning. Your run of nights starts again;
    gold is never lost.
  - *Beds* skip a night only for a sleeper who is sheltered ("Build walls and a roof around your bed
    first!"), so a bed in a field is no shortcut.
  - *Score:* nights survived in a row in this world without a knock-out, and the best; each morning "You
    made it through night 3!" (and "A new best!"). It is a score inside one world: nothing is lost by
    being away, playing another world or skipping a day (§6).
  - *A quick start:* the starter kit gets 32 more planks (48), a doorway of 2 doors and a lantern (both on the
    hotbar), and
    Tilly's building blocks come 8 per gold (instead of 4) in this game — all but logs, which
    stay 4 per gold so that charcoal can never be sold for more than its logs cost.
- **MONSTER HUNTER** (planned first) became part of **MONSTER WAVE** (§12.20, owner feedback #44): its combo
  lives on there as a small kill bonus; its packs, its Tilly prices and its clock line were removed. An old
  world saved as "hunter" reads as CLASSIC.
- **LAN and online:** the host decides everything — the clock, shelters, nights and scores —
  and sends the game to a guest with the universe, before `world_info`. Each game works out its own
  player's shelter for the label; the host's answer is the one monsters obey.
- Rulings with their cost if wrong: `docs/devlog/parts/survivor-games-crafting.md`.

### 12.19 Crafting (owner 2026-09-24, feedback #34: "we should be able to create different things like crafting and minecraft")
- **Survivor only** (Sandbox has everything already). The block palette gets a **CRAFT** tab: a picture
  recipe book, no grid to remember. Each recipe is a card: the result's picture and count, the ingredients'
  pictures with have/need ("2/3"), and where it is made (a hand, the crafting table, the furnace). Cards
  you can make now **shine** (a gold rim) and come first; the others show what is missing in orange. A tap
  on a shining card crafts it (asked of the host); a tap on another says kindly what is missing ("You need
  2 more Sticks!", "Stand next to a Crafting Table!"). A new thing goes into an empty hotbar slot if there
  is one.
- **Blocks:** the **CRAFTING TABLE** (220) and the **FURNACE** (221) on block page 10, in both styles;
  placed and broken like other blocks. "Next to" means within 4 blocks of the player's eyes.
- **Recipes** (one table, `core/crafting/recipes.gd`; 28 recipes):
  - *By hand:* 1 log → 4 planks; 2 planks → 4 sticks; 4 planks → a crafting table.
  - *At the crafting table:* 8 stone → a furnace; 6 planks → 2 doors; 5 planks → a bed; 1 coal + 1 stick →
    4 lights (torches); 1 coal + 1 stick + 1 glass → a lantern; 6 planks + 2 sticks → a barrel; 8 planks →
    a closet; 1 iron + 2 stone + 2 sticks → a spike trap; 6 planks → a wooden shield; and the tools and
    weapons of §12.6's tiers from sticks and a material: wood (planks), stone, iron, crystal (from
    **diamond**) and cosmic (from **gold + crystal**) — sword (2 material + 1 stick), pickaxe (3 + 2) for all
    five tiers, axe (3 + 2) for wood, stone and iron. The cosmic sword needs 2 gold + 2 crystal + 1 stick,
    the cosmic pickaxe 3 gold + 3 crystal + 2 sticks.
  - *At the furnace:* 4 sand → 4 glass; 4 stone → 4 bricks; 3 logs → 1 coal (charcoal). Each furnace
    recipe also burns **1 fuel**: coal, or a log when there is no coal (never the recipe's own result).
- **Rules:** a craft is all or nothing; tools and shields are one of each (like Tilly: "You already have
  one!"); counts cap at 999; crafting never gives gold and is never random. Ores are used directly: **no
  ingots** (ruling: one step fewer for young children, and no new items). The recipe table is validated by
  tests: every id a real block or item, positive counts, no loops (the recipe graph is acyclic, so nothing
  comes from nothing), and no recipe's result sells to Tilly for more than its ingredients (and fuel) cost
  from her (no gold from crafting).
- **LAN and online:** `Session.request_craft(recipe)` → the host checks (a Survivor world, a known recipe,
  the station within reach of the requester's body on the host, the ingredients and the fuel), takes and
  gives, and answers the player (`craft_done`); the inventory follows by the usual snapshot.

### 12.20 Monster Wave (owner 2026-09-24 21:07, feedback #44: "i want to wave part and the monster part should be separated by a new gamemode ,,monster wave" and that gamemode only is a flat world and ur goal is to stay as long as possible alive. And more time you are alive the more gold u get when u die. But if u have managed to stay alive till the final raid boss at wave 10 u get teleported into a another universe where u get 2xgold 2xhard and 2xharder to find secret but dosent count in sandbox. But the player has a choise. But on the other hand in normal survival there is no longer a wave part.")
- **A third main mode.** The main menu reads SANDBOX / SURVIVOR / **MONSTER WAVE** / PLAY ONLINE (one row of big
  buttons). MONSTER WAVE opens "Monster Wave": a picture card for every universe unlocked (a missing one says
  "Coming soon!"), each with its best ("Best 3:10 · Wave 5"); a tap starts a run there. `ModeRules.WAVE`; each
  universe has its own arena world (save slot `wave_<u>`). Not in Sandbox (Sandbox keeps its gentle Totem).
- **The arena:** a flat world of the universe's ground (Green Meadows grass, the Desert's sand, Frostpeak's snow;
  a universe without its own is grass) with low cover here and there (2-block pillars and short walls of the
  universe's stone and wood on a grid, none within 12 blocks of the middle); the Monster Totem in the middle, the
  players start 6 blocks from it; always bright day. No building or breaking, no flying (no WALK/FLY button), no
  night monsters, no Tilly, no secrets, no animals, no weather or traps, no Theater in the arena: the goal is to
  **stay alive**.
- **The kit** is the same for everyone and fixed per universe (no carrying, nothing to buy): a sword, a bow, a spear,
  a mace and a shield of the universe's tier (stone in Green Meadows, iron in the Desert, crystal in Frostpeak,
  cosmic from the fourth universe on; monsters grow × 2 per universe), 2 Speed and 2 Moon Jump potions.
- **The run:** "Get ready!" and wave 1 comes 8 s after arriving; each next wave comes 8 s after the last is cleared
  (or after its 3 minutes; §12.8's waves: 3 + 2N monsters, the universe's kinds and × 2^(u−1), team-sized).
  **Wave 10 is the raid boss** (the universe's boss through the shared BossDirector: the Stone Golem, the Sand
  Serpent, the Frost Giant, the Cake Monster when it exists). The HUD shows the time survived and the wave
  ("3:24 · Wave 5") where Build to Survive's clock sits, the best under it, and §12.8's wave line and §12.9's boss bar.
- **A knock-out ends the run** when every player in the arena is down at once (solo: the first knock-out; with
  friends, one who is down gets up on the spot and fights on, M4 E's help-up works). Children are knocked out,
  never killed. The run's end pays **gold for the time survived and the waves cleared**: ⌊seconds / 10⌋ + 5 × waves
  cleared, × 2^(u−1), to every player in the arena, once, through the host's gold path into their own Survivor
  gold — more time, more gold. A result panel says "You lasted 3:24 and cleared 5 waves! +45 gold" (and "A new
  best!") with PLAY AGAIN and LEAVE as equal buttons. The best time and best wave are saved per universe (the
  arena world's `WorldMeta.arena`, per player name).
- **A small kill bonus** (Monster Hunter's combo, owner #33): every monster defeated pays the one who defeated it
  1 gold × the combo (a second defeat within 5 s × 2, a third and more × 3, never more) × 2^(u−1), at once, with
  a "+2 × 2!" pop; no coins drop in the arena.
- **The raid boss beaten:** its gold (300 split, × 2^(u−1)) and the run's gold are paid, the next universe unlocks
  for every player (`Session.boss_unlock`), and a **choice** comes: **NEXT UNIVERSE** (Monster Wave in universe
  u+1: gold × 2, monsters × 2 — the ladder's scaling; that universe's Survivor world keeps its secrets, harder to
  find, and its portal hub lists it) or **STAY** (a new run here). When that universe's world isn't built yet
  the panel offers STAY only and says "The next universe is coming soon!"; NEXT UNIVERSE is for solo play (with friends everyone stays; the host can start the
  next universe from the menu).
- **LAN and online:** the host runs the waves, the clock, the knock-outs, the gold, the bonus and the choice;
  guests see the same timer, waves, pops and results.
- Rulings with their cost if wrong: `docs/devlog/parts/survivor-games-crafting.md` ("Monster Wave").

## 13. Action kit — inspired by Fortnite, our own designs (owner 2026-09-24)

The owner: "add into game a mace and a spear, and also some modern weapons from fortnite, add skins,
styles and tacktikes from fortinite, actually all exciting items from it". Rulings (dev log M2 15–17):
**our own designs only** (Epic Games' names, skins, characters and art are protected; mechanics are
not), **cartoon blasters, never realistic guns** (a children's game keeps a low store age rating; hits
stay "burst into confetti and coins"), and **no item shop, battle pass or timed pressure** (§6):
everything is earned by playing, cosmetics included.

### 13.1 New weapons (M2, Task 6)
- **Spear**: long thrust (reach 4.5, narrow), good against charging monsters; can be thrown short and
  picked up again. **Mace**: slow heavy swing (reach 3) with big knockback and a small ground shake.
  Both come in the five tiers (§12.6) with rarity colours.
- *As built (Task 6):* spear damage 4, 20° thrust, 2 hits; a tap on something beyond its reach (or
  ATTACK held and let go) throws it up to about 22 m for × 1.5 damage; it sticks where it lands and
  its thrower walks up to take it back (it flies back by itself after 20 s; never lost). Mace damage 6,
  0.9 s, knockback 12 (the hammer stays the slowest and hardest-pushing tool); every swing shakes the
  ground within 8 m, at most three times a second. *Owner #53 (§13.4b):* spear damage 5, mace 8 at 0.85 s.

### 13.2 Rarity colours (M2, Tasks 6 and 16)
- Tiers and treasure show a colour everywhere (icon rim, glow, name): wood/common grey, stone/uncommon
  green, iron/rare blue, crystal/epic purple, cosmic/legendary gold. Chests glow in their rarity.

### 13.3 Gadgets and movement (M3)
- **Glider**: open it in the air to glide down slowly (a cosmetic can change its look).
- **Launch pad** and **bounce pad** blocks; **grappling hook** item; **zipline** between two posts.
- **Instant builds**: one tap places a wall, floor, ramp or a small fort in front of you (uses blocks in
  Survivor) — the "build to protect yourself" tactic; builds from the stamps (§3a) in a combat form.
- **Impulse orb**: a throw that pushes monsters (and bouncing players, for fun) away.
- **Dance orb**: monsters caught in it dance for 5 s (they stop attacking).

### 13.4 Blasters (M3)
Cartoon, clearly toy-like, never real-world guns: **Foam Blaster** (quick darts), **Bubble Cannon**
(traps small monsters in floating bubbles), **Paint Splatter** (marks monsters, slows them), **Snowball
Launcher**, **Confetti Rocket** (area knockback, a burst of confetti). Ammo in Survivor is bought or
found; Sandbox is unlimited. Tiers and rarity like other weapons.
- *As built (M3 Task 14b):* one blaster per rarity (items 415–419: Foam Blaster common, Snowball Launcher
  uncommon, Paint Splatter rare, Bubble Cannon epic, Confetti Rocket legendary; icon rims, 1–5 pips and
  bands), each with its own ammo (420–424, Survivor only: Tilly's TOOLS section in packs, piñatas and supply
  balloons). Toy colours and an orange tip; hits burst into little cubes. Foam: 1 damage, 8 darts at 0.16 s,
  1.2 s reload. Snowball: arcs, a small push. Paint: 30 % slower for 5 s and a mark over the head that
  shines through fog and darkness (for everyone: the team). Bubble: a monster of level ≤ 2 floats 4 s in a
  see-through bubble (no moving, no attacking), bigger ones are half as fast for 4 s. Rocket: one shot,
  3 s reload, pushes everything within 4 blocks it can see (never through a wall). ATTACK fires and keeps
  firing while held; a tap fires where it points. Shots never hit players, bot friends or buddies (no
  friendly fire; animals are only pushed). Sandbox: the ARMORY page's BLASTERS column, free and unlimited.
  The host checks every shot (owned, ammo, rate and reload); shots fly in a fixed pool (no node per shot).
  Rulings: `docs/devlog/parts/m3-task-14b.md`. *Owner #53 (§13.4b) changed the numbers:* foam 3, snowball 9,
  paint 12, bubble 22 (0.5 s, 1.2 s reload), rocket 50 with three rockets (0.6 s, 2.4 s reload), rockets in
  packs of 3 for 18 gold, the rocket 500 gold.

### 13.4b Strength follows how hard a weapon is to get (owner #53, 2026-09-25)
The owner: "based on how difficult the weapon is to get, based on their strength. For example the blaster: it's
hard to get but doesn't really deal much damage." (The legendary Confetti Rocket did 1 damage a second; a wood
sword does 11.)
- **How hard to get** is a weapon's rarity: the colour it shows everywhere (§13.2). Tilly's prices follow it: a
  rarer weapon never costs less than a commoner one (the Confetti Rocket 350 → 500 gold, above the crystal tools'
  400). The boomerang (priced like a stone tool) is uncommon.
- **How strong** is the damage it does per second to one monster over a whole fight: a hit every cooldown, a
  blaster's magazine and then its reload, a boomerang's round trip (one hit a throw).
- Every fighting weapon (the sword, bow, spear and mace in every tier, the boomerang, the five blasters) sits in
  its rarity's band: common 7–12, uncommon 12–18, rare 18–26, epic 26–40, legendary 40–60 damage a second. The
  bands never overlap, so a rarer weapon always hits harder; the sword of each tier is inside its band. Inside a
  band a weapon's style is its difference: reach, area, range, a push, a slow, a bubble.
- In each family (a tier line, the blasters) a rarer one also hits harder per hit.
- Tools (pickaxe, axe, hammer) are for blocks and stay under the band of their rarity; bare hands under common.
- As built: `WeaponStrength` (`core/rules/weapon_strength.gd`), `tests/unit/test_weapon_strength.gd`. Spear 4 → 5;
  mace 6 → 8 and 0.9 → 0.85 s; boomerang 3 → 21 (a big hit, then it has to come back); foam 1 → 3, snowball
  2 → 9, paint 2 → 12, bubble 1 → 22 (0.7 → 0.5 s, 1.8 → 1.2 s reload), rocket 3 → 50 with three rockets a
  magazine (0.5 → 0.6 s, 3 → 2.4 s reload). In universe 1 the rarer blasters now end most small monsters in one
  hit, so their effects (the bubble, the mark, the push) show on bigger monsters, in later universes and on bosses.
  Ruling (the lead): the measure is damage a second, not per hit, because a quick weapon with a small hit can be as
  strong as a slow big one; cost if wrong: numbers only, one table.

### 13.5 Surprise drops (M2 Task 16 hooks, M3 content)
- **Party Piñata**: some days a piñata floats down on a small parachute somewhere nearby; hit it to
  burst it into supplies (blocks, a potion, ammo). **Supply balloons** in Survivor waves.
- *As built (M3 Task 14b):* after ≥ 10 minutes of play (10–15, fixed by the world's seed; only while a
  player is in the world; the clock is saved) a striped paper piñata floats down on a parachute 8–30 blocks
  from a player (about 14 s), never two at once; anything that hits monsters hits it (weapons, blasters,
  fists, bot friends); 3 hits burst it into confetti and supplies for every player within 12 blocks
  (Survivor: blocks, always a potion, two kinds of ammo; never gold; the same for a given piñata; Sandbox:
  the fun only). Left 5 minutes on the ground it floats away. Survivor waves from wave 3: 8 s in, one red
  balloon with a crate drifts in over the Totem and settles 3 blocks beside it, low enough for a sword; one
  pop gives a potion and ammo to every player within 16 blocks; it leaves with the wave.

### 13.6 Skins, styles and celebrations (M3, with the avatar editor §5.9)
- Skins and outfits of our own (knight, astronaut, dino suit, robot, pirate, ninja, candy…), back
  items (Build-and-Wear §3a), glider looks, pickaxe/tool skins, trails, **emotes and dances**, and a
  **victory celebration** after a wave or the boss (a dance and confetti). All earned by playing
  (waves, bosses, secrets, missions), none bought.
- A **toon look** option alongside BLOCKY and REALISTIC (evaluated in M5, §5.15).

### 13.7 Challenges and tactics (M3–M4)
- **Build-fight practice**: instant builds and high ground matter against monsters (goblin archers in
  M3 shoot from cover).
  *As built (M3 Task 14b):* the goblin archer (hood, quiver, bow) keeps 10–20 blocks from a child it sees
  (backs off when closer), picks a spot among a few around it (cover: a block between it and the child with a
  free step beside it; higher is better), waits there, steps out, draws its bow for a whole second (the
  arrow's tip glows) and shoots a slow, big arrow onto where the child stands (no lead: a sidestep dodges
  it); arrows stop at the first block and it never shoots into a wall; it never changes a block. It comes at
  night instead of 2 in 5 goblins of level ≥ 2 (Green Meadows) and in waves from wave 4 (every other
  goblin); `/summon archer`. **Storm Run** mini-game (co-op, M4): a shrinking safe circle while collecting
  stars, with friends or bot friends — no player-vs-player elimination for under-13 players.

## 14. Milestone M3 "Worlds of Wonder" — detailed spec

Written 2026-09-24 by the lead (owner's standing order: the whole roadmap without questions). It
refines §5.1, §5.4–5.12, §3a (Game Blocks, Build-and-Wear, Build Rewind) and §13.3–13.7. The research
in `docs/design/` (owner feedback #21) adds to it when it lands; rulings are in the M3 dev log.

### 14.1 Universes 2–4 and the ladder
- Each Survivor universe is its own world (save slot `survivor_u<u>`), reached through the portal its
  predecessor's boss opens (M2's portal leads to universe 2 now). The **portal hub** (a menu screen
  and a stone circle at each world's spawn) lets a player return to any unlocked universe.
- Scaling × 2^(u−1) for gold and monster HP and hits (§5.1). Trader prices scale too; tools keep their
  tiers (a cosmic sword in universe 4 still needs upgrades — tier shop items gain "+" levels there).
- **Sandstorm Desert (2):** dunes, mesas, oases, sandstone and cactus blocks, sandstorms that lower
  visibility; **pyramids** with traps (arrow slits, sand pits, pressure-plate doors) and treasure
  rooms. Monsters: **mummy** (slow tank, unwraps into two halves at level ≥ 3), **scorpion** (spitter:
  poison spit at range). Boss: **Sand Serpent** (dives through sand, surfaces with signalled bursts).
- **Frostpeak (3):** snowy peaks, ice lakes (slippery), pine forests, igloos; **snowstorms hide
  everyone** (visibility × 0.5 for monsters and players; the screen whitens). Monsters: **yeti** (tank
  that throws snowballs), **ice bat** (flyer, swoops). Boss: **Frost Giant** (freezing stomp rings that
  make the ground icy; hide behind snow walls from his breath).
- **Candy Kingdom (4):** candy-cane forests, chocolate rivers (swimmable), gumdrop hills, cake
  mountains, sprinkles falling at night. Monsters: **gummy bear** (jumper that bounces off walls),
  **candy sneaker** (invisible in darkness, shimmers when close). Boss: **Cake Monster** (layers fall off
  as it is hurt; each layer changes its attack).
- Each universe: its own blocks (≈ 6 new, both styles), music loops, secrets (5 kinds adapted from
  §12.16), a trader with local items, and a Totem with 5 waves before the boss.
- **New behaviours** complete §5.2's list: spitter (ranged, leads its shot), sneaker (invisible in the
  dark), tank (slow, heavy, needs 2 players or tools), flyer (swoops, lands to rest).

### 14.2 Portals and the portal network (Sandbox too)
- Portal frames (a block) + a portal core: two linked frames teleport players between them (in one
  world). In Survivor the universe portals link worlds. Portals swirl (shared shader), with a whoosh.

### 14.2a Universe portals you build, and the Dragon Realm (owner feedback #39)
The owner (2026-09-24 20:35): "please add portals in the game, when you enter into portals you move to different
universes like in minecraft, like dragon universe and others". Built on §14.1–§14.2 (M3 Task 5's frames, cores,
hub and travel rules); notes and rulings in `docs/devlog/parts/owner-39-portals-dragon.md`.
- **Universe crystals** (items 480–489; one per universe: 480 Meadows … 484 Dragon, 485–489 kept for 6–10). A
  crystal is **earned by reaching its universe**: every universe a profile has opened gives its crystal once, into
  the child's bag the next time they play one of their own Survivor worlds; Tilly sells copies (HOME, a fixed 50
  gold × 2^(u−1)) of the crystals of the universes up to the one she stands in. Sandbox's palette has the crystals
  of the universes the child reached, free as everything there.
- **A universe portal** is a portal frame ring (§14.2's shape: a 1–3 wide, 2–3 high doorway, corners optional)
  with a **crystal in its core slot**: placing a crystal in the bottom row puts that universe's **portal core**
  there (blocks 212–215 and 222 on page 10), and breaking the core gives the crystal back. It needs no partner and
  swirls in its universe's colours (one shared material per universe). Walking in (the host decides, as for
  linked frames):
  - **Survivor:** to that universe's Survivor world (§14.1's travel: solo only, the bag and hotbar come along, the
    Plus rule of §18.3, "Beat the boss to open this universe!" for one not reached yet).
  - **Sandbox:** to **that universe's Sandbox world** (a save slot per universe, `sandbox_<u>`; universe 1 keeps
    `sandbox_1`), made the first time: its terrain, sky, music, weather and gentle monsters, everything free,
    nothing scaled (Sandbox never scales). The main menu's SANDBOX then shows a card per Sandbox world. The Plus
    rule applies as in Survivor (a Plus universe is a place to explore).
  - **The portal back stands at the arrival point:** the traveller arrives in front of a portal to the universe
    they came from — the world's own gate to it when it has one, else one the game builds a few steps in front
    of the spawn (frames and that universe's core; never inside a player).
  - A portal to the universe you are in says "You are here!"; with friends in the game, "Travel works when you
    play alone." (as the hub).
- **The Dragon Realm (universe 5, after the Candy Kingdom; its own block page 11, ids 224–239):** floating islands
  over a starry purple void — fall off and the wind carries you back to the island you fell from (never lost, no
  knock-out, nothing dropped); crystal spires, giant glowing mushrooms, dragon-scale blocks, clouds you pass
  through. Secrets: its own five kinds, and **dragon nests** with a **dragon egg**: a tap hatches it into a small
  **pet dragon** (a `PetRules` kind, given like Pip) that follows its child and flies or glides beside them in the
  air — it never fights anyone. Monsters: **shadow bats** (flyers that swoop, always signalled) and **wisp
  spirits** (floating lights that drift and throw a slow, signalled spark), gentle and fair like every monster.
  *As built (the monsters' part):* both nip like the ice bat (1 + ⌊l/2⌋, × 2^(u−1)); the shadow bat (dark violet,
  lilac eyes) signals 1 s (wings flare, eyes brighten, a squeak), swoops at where the child stood, then flies up
  and away to rest 3 s; the wisp (a pastel orb with a face and a trail) keeps 7 blocks away, signals 1.2 s (it
  lights up, chimes, a ring grows) and throws a spark at 5 m/s (slower than a walking child, no lead) that a wall
  stops; their minds' tactics only steer. Every flyer over the void keeps its height and goes back to the islands;
  one below y 0 over nothing puffs away. `/summon shadowbat`, `/summon wisp` in any world.
  Boss (Monster Wave's raid boss at wave 10, §12.20): the **Sky Dragon** (our own design) circles, then **dives**
  along a line it shows first; **crystal towers** round the arena heal it until the team breaks them; health by
  team size and honest help like the Golem; it never changes a block. Beating it gives every child who fought a
  **baby dragon pet** (it lives in the profile like Pip and comes into every world) and a Dragon Crystal. Music: a
  public-domain classical piece already in the game (the audio pass's `MusicPieces`), sky and fog in purples.
  - **The Sky Dragon as built** (notes `docs/devlog/parts/owner-39-sky-dragon.md`): a big teal-and-violet box dragon
    (horns, beating wings, a swaying tail, golden eyes), health 480 × (1 + 0.5 per extra player or bot friend), 75 %
    when tired. It arrives from the sky and **circles** 8 blocks up round the Totem (12 blocks out; only arrows and
    thrown spears reach it there). **The dive:** it picks the nearest child, climbs and glows (eyes, belly) for 1.4 s
    while a striped line shows on the ground on every screen, from under it, through the child and 7 blocks on
    (never out of the arena circle, 30 blocks from the middle); then it swoops along it: a child on the line when it
    passes low takes 4 HP and a push off the line (back towards the middle near the edge); a step off the line
    dodges it. After a dive it **glides low** and slow towards the middle for 2.5 s (a sword reaches it); after every
    second dive it **lands and rests** 3.5 s (stars; double damage), then takes off and circles again. **Crystal
    towers:** 4 (tired: 3) rise round the arena when it has arrived and once more at a third of its health, each
    healing it 0.5 % of its health every second (a beam with sparks to it; the bar shows it) until broken by 4 hits
    of anything (weapons, arrows, spears, blasters, orbs, bot friends); "Break the crystal towers — they heal the Sky
    Dragon!". Towers never hurt. A tired dragon also dives slower and rests longer. It flies above the ground and
    cover under its whole body (never into a block), never changes a block, and Monster Wave's win promises no portal
    ("Every universe is yours!").
- **The ladder:** meadows, desert, frost, candy, dragon; the Candy Kingdom's boss portal and Monster Wave's NEXT
  UNIVERSE lead to the Dragon Realm, whose own boss portal leads to the hub (the last universe). The Dragon Realm
  comes with EasyCraft Plus while the build has a store (§18.3, `Entitlements.universe_open`).

### 14.3 Physics Lab (Sandbox, §5.4)
- A "LAB" button cycles Normal, **Moon gravity** (× 0.35), **Zero-G** (float, push off walls), Fly,
  Ghost and **Slow motion** (× 0.4 time for your own body and nearby things). **Jump pads** and
  **speed pads** (blocks). Survivor keeps Normal and paid Fly.
- Refined by Task 6 (rulings in `docs/devlog/parts/m3-task-6.md`): LAB is its own button (under the
  camera button; L on desktop), Sandbox only; the WALK/FLY/GHOST button stays and shows the lab mode's
  name. Moon: the same jump speed under 0.35 gravity (jumps 2.9 × as high and long). Zero-G: no
  gravity, the drift fades slowly, the stick, JUMP and DOWN thrust gently (up to 3 m/s), and moving into
  a wall, floor or ceiling kicks off it at 7 m/s. Slow motion slows only your own body (movement, jumps,
  pads, animation) and the puffs of your pads; the world, animals, monsters and other players keep
  their time, so LAN stays fair; other players see you move slowly. The mode is synced and saved with
  the world. Jump pad: up at 16 m/s (about 5 blocks; 15 on the Moon) with a boing and a puff. Speed pad:
  14 m/s the way you were going (the way you face when standing) for 1.5 s, with a whoosh. Both work on
  players and animals (monsters use the same rules), in both modes (Survivor players buy them from the
  trader, M2 Task 7's prices), never in Ghost, and a body's pads rest 0.5 s after firing, so no pad
  loop runs faster. Pads are placeholder-coloured glowing blocks until Task 1's block pages.

### 14.4 Smart blocks and Game Blocks (§3a, §5.5)
- Smart blocks: **button**, **lever**, **pressure plate** (M2 has one for temples), **powered door**,
  **jump pad**, **teleport pad** (pairs), **light switch**. Wires are simple: a smart block powers the
  blocks it touches (one-step, no redstone logic — kid-simple).
- **Game Blocks**: START, FINISH, CHECKPOINT, COIN and BOUNCE blocks. Stepping on START starts a timer
  and a course; checkpoints respawn a fallen runner; FINISH shows time and a **medal** (gold / silver /
  bronze by time goals the builder sets). Friends and bot friends can race it.

### 14.5 Building tools (§5.5)
- **Paint** any block (a paint bucket: tint colours from a palette of 16).
- Sandbox power tools: **line** (two taps), **fill** (box between two taps, with a size cap and one
  undo), **copy / paste** (a box, rotate 90°).
- **Build Rewind**: record block edits in an area; replay as a time-lapse with an orbiting camera
  (and a video export via the share sheet in M5).
- **Build-and-Wear**: a small build (≤ 5 × 5 × 5) can be turned into a hat, backpack or wings with
  the wand; worn items are saved in the profile.
- Refined by Task 8 (rulings in `docs/devlog/parts/m3-task-8.md`): everything is in the palette's new
  **BUILD** tab (no HUD button): a TOOLS row (LINE, FILL, COPY, REWIND) and 16 paint buckets. **Paint** turns a
  plain block into one of 16 painted blocks (block page 12, ids 240–255; items 435–450); blocks with a job
  (doors, beds, lights, pads, smart blocks, portals, stations, secrets' blocks) are never painted; free in
  Sandbox and Survivor, where ores and gems are never painted and a painted block drops as itself. **LINE**
  (≤ 64, a walkable staircase on diagonals), **FILL** (≤ 4,096) and **COPY / PASTE** (≤ 16 on a side; a paste
  turns with the child, TURN adds quarter turns) are Sandbox's; they build with the block held last, only
  into empty cells (air, water), never inside a body, one undo step each; a bar at the top says what to tap
  next (CANCEL, TURN, NEW COPY). The host checks and writes a big edit a little every frame (about 8 ms of it), so
  it never stalls the game. `/fill block [n | w h d]` and
  `/copy` (the build you look at) come with them. **Build Rewind**: the first REWIND tap records this child's
  edits within 32 blocks of the spot (≤ 5,000, saved with the world); the next plays them in ≤ 20 s on a
  stage of its own around an orbiting camera (AGAIN, NEW, CLOSE; SHARE waits for M5's video export).
  **Build-and-Wear**: the wand on a build of at most 5 × 5 × 5 asks WAKE UP (a buddy, as before), HAT,
  BACKPACK or WINGS; the build is copied (it stays in the world), baked into one small mesh in its blocks' own
  materials (both styles), takes the catalogue hat's, cape's or wings' place, is saved in the profile's look
  and sent to other players with it; the avatar editor's HAT, CAPE and WINGS tiles take it off.

### 14.6 Avatar editor, skins and celebrations (§5.9, §13.6)
- The **avatar editor** (main menu and pause menu): skin colour, face, hair, hats, shirts, pants,
  capes, wings, running trails, emotes and dances, in both styles (blocky parts; realistic skins map
  to the Kenney characters' variants and colours). Items are account-wide, unlocked by Survivor gold,
  achievements, secrets or codes; a free basic set. Fixed prices, no random boxes (§6).
- Own-design **skins**: knight, astronaut, dino suit, robot, pirate, ninja, candy, and a legendary
  "cosmic" skin earned by beating the Cake Monster.
- **Emotes and dances** (an emote wheel), **victory celebration** after waves and bosses.
- Refined by Task 9 (rulings in `docs/devlog/parts/m3-task-9.md`): the editor has a turning 3D preview
  (BLOCKY / REAL), 11 picture tabs and big picture tiles; anything can be tried on, DONE keeps only what
  is owned. Colours and hair styles are always free, plus a basic set of faces, hats, a cape and a
  trail; other items have fixed, round Survivor-gold prices (60–1000, never real money, no countdowns);
  earned items say how to earn them: Pip's Cap (tutorial), Rock Helmet (Stone Golem), Fairy Wings (a
  Secret Book page), the legendary **cosmic** outfit (Cake Monster), the Victory dance (the first won
  wave); codes can give items. Sandbox gold never buys items. The emote wheel (a HUD button under
  MIRROR) has 8 slots the child fills in the editor: wave, cheer, laugh, thumbs up, clap, sit, Bunny
  Hop and Robot are free; Star Spin and Bow cost gold. Emotes are seen by everyone on LAN; moving ends
  them. The realistic style recolours its skin, hair, shirt, pants and shoes and wears the same hats,
  helmets, capes and wings; its hair style picks the long- or short-haired skin.

### 14.6a Boy and girl looks (owner feedback #48; M3 Task 25)
The owner: "when choosing avatar there should be avatar of girls as well", "beautifull girl". Rulings in
`docs/devlog/parts/owner-48-girl-avatars.md`.
- **A first choice, never a lock:** BOY / GIRL / JUST ME at the top of the avatar editor and as the last
  first-launch step (after the name). It puts on a matching starting look (skin tone and dance wheel stay)
  and opens the ready-made looks; every part stays free to mix (a girl can wear a cape, a boy long hair).
  The choice (`AvatarLook.base`: boy, girl, neutral; old profiles are neutral) stays on this phone: it is
  not in the synced look code or the online backup, only the parts are.
- **Girl parts, all FREE, in both styles** (a child's gender look is never for gold or in a pack): hair
  (long with bangs, ponytail, two pigtails, braid, two buns, curly bob, plus the old long, bun and curly)
  and purple and platinum hair; hair clips, a flower crown and a hair bow (HAT); faces with cartoon
  eyelashes, a sweet smile and rosy cheeks (the realistic face gets its lashes and cheeks in the skin
  shader); a **CLOTHES** tab: classic, dress, princess gown, skirt, leggings with a tunic, hoodie,
  overalls and an adventure jacket with boots, worn in the child's own shirt and pants colours (the
  realistic style adds real skirts and hair shapes); lilac, mint and rose colours. Outfits still win over
  clothes. Stylised like a cartoon heroine: no body shaping, no make-up beyond lashes and rosy cheeks,
  clothes fit for children.
- **Ready-made looks, one tap each:** Adventurer (ponytail, jacket and boots) and Princess of the Realms
  (flower crown, gown) for girls; Skater and Little Hero for boys. All free.
- **Bot friends** wear girl and boy looks (the first friend is a girl, then they alternate).

### 14.6b The Storybook costume pack (owner feedback #36; M3 Task 27)
The owner asked for "charachters from different movies, tv shows, marvell, harry potter". **Ruling #36:** film, TV
and comic characters are owned (Disney, Warner Bros, Marvel/DC), so instead: public-domain storybook heroes drawn
our own way **from the books** (never a film's look), and our own genre costumes. Rulings and the legal-check list in
`docs/devlog/parts/owner-36-costumes.md` (a lawyer's check is suggested before release).
- **21 costumes**, each a whole look of catalogue parts in both styles: Alice (Tenniel's yellow dress and white
  pinafore, an Alice band), Dorothy (Baum's blue-and-white gingham, pink sunbonnet, **silver shoes**), Pinocchio
  (bread cap, flowered paper suit, the long nose), Robin Hood, the Mad Hatter (the "10/6" hat), the Tin Woodman
  (Baum's name; funnel hat, the Wizard's heart), Sherlock Holmes (deerstalker, Inverness cape, magnifying glass),
  King Arthur (three gold crowns on blue), Merlin (green robe and hat, a beard), Aladdin (turban, kaftan, the lamp),
  Hercules (the Nemean lion's hood), Captain Nemo (the Nautilus' golden N); and our own Fairy, Little Wizard (our
  own crest and colours), Cube Hero (our own golden-block emblem), Pirate Captain (a parrot on the shoulder), Knight,
  Ninja, Astronaut, Robot and Dragon Suit (M3 Task 9's outfits with a cape or a trail; a new dragon outfit).
- **In the avatar editor** the OUTFIT tab becomes **COSTUME**: the costumes first (one tap puts on the whole look,
  keeping the skin tone, the first choice and the dance wheel), then the outfits. A costume's own new parts (13
  hats and faces, 13 clothes cuts, 2 back pieces, 3 trails, 2 outfits) sit in their own tabs and mix with anything
  once earned. No new HUD button.
- **Earned by playing, one fixed way each, never random, never for gold or money** (never in a grown-up's pack):
  bosses of the free universes (the Stone Golem: King Arthur; the Sand Serpent: Hercules), Tilly's and Zara's
  stories (Pinocchio, Dorothy, Little Wizard, Aladdin, Knight), levels 3, 6 and 10 (Alice, Mad Hatter, Astronaut),
  play-style titles (Robin Hood, Sherlock Holmes, Merlin, Tin Woodman, Ninja), the 1,000-blocks badge (Robot),
  Secret Book finds (a pirate cove: Pirate Captain; a sunken chest: Captain Nemo; a whole page: Fairy, with the
  Fairy Wings), riding a flying buddy (Dragon Suit) and a secret code (Cube Hero). Earning a costume gives
  everything in it; ways read from the profile are given as they happen in a world (a message) and when the editor
  opens (profiles from before the pack get what they already earned).
- **Never a boy's or a girl's**: every costume is offered to everyone; BOY / GIRL stays a starting point.
- **Nobody else's names**: a test keeps a list of film, TV, comic, game and toy names out of every shipped string
  (the joint "Super Hero" mark included: our hero is the "Cube Hero").

### 14.7 Pets with perks (§5.9)
- Pets (M1b tame dogs/cats) gain **perks**: glow in caves (cat), pull in coins (dog), bark when a
  monster is near (dog), plus new pets: **Pip the robot** (from the tutorial), a **fox** (finds buried
  treasure: sniffs and digs), a **parrot** (repeats chat lines, points at secrets). Pets have names,
  collars and a happiness heart (pet them, feed treats — never needed, never punishing).
- **As built (M3 Task 11, 2026-09-24; rulings in `docs/devlog/parts/m3-task-11.md`):** a perk works only for a
  tamed pet within 16 blocks of its child. Cat (and Pip's lamp): one shared soft light per game on the nearest
  glowing pet, in caves and at night. Dog: coins within 4 blocks of it fly to its child; a bark and a "!" when a
  monster comes within 16 (once per monster, 8 s apart); it still sniffs out buried treasure. Fox: wild by the
  woods, tamed with two treats, sniffs twice as often and digs a dirt puff. Parrot: wild by the water, tamed with
  two treats; repeats only its own child's lines and quick phrases, on that child's device only (never sent to
  anyone, never other players' words); every 15 s points its beak at the nearest secret nobody found within 24
  blocks. Pip the robot: given by the tutorial (`PetRules.give_pip`), lives in the profile and comes into every
  world; shiny metal in the realistic style. A tap on your own pet pats it and opens its card: the heart, SIT /
  COME, a name (a list; a typed name through the username filter for 13+ only), 8 collar colours. Treats (items
  430–434, each kind's favourite): 2 gold at Tilly, free in Sandbox (the palette's PETS tab); they tame, raise the
  heart and teach the pet's mind. The heart falls slowly only while the child plays and never below a quarter; a
  less happy pet only wags and jumps along less. Pet kinds are one table (`PetRules.KINDS`), so the baby dragon
  (owner #39) is one more row.

### 14.8 Gold Farm (§5.6)
- A farm building in Survivor worlds (bought from the trader): if the player is inside when they leave
  or close the game, they earn `rate_per_hour × 2^(u−1)` for the time away, capped at 12 h; upgrades
  raise rate and cap; animated workers; the **welcome-back coin shower** shows the exact amount. Device
  clock before M4 (§5.6). An opt-in notification "Your farm is full!" (Android local notification).
- Refined by Task 10 (rulings in `docs/devlog/parts/m3-task-10.md`): Tilly sells the farm (150 gold × 2^(u−1),
  HOME section) as an item placed like a stamp on flat, open ground (a 9 × 7 barn, yard and field; the door faces
  the child); one per world, the world owner's (guests see it and walk in; it pays and grows for the owner only).
  20 gold an hour × 2^(u−1) for 12 h; FASTER 30/40/50 an hour (200/400/800) with one more farmer each (at most 3),
  BIGGER 16/20/24 h (150/300/600), all × 2^(u−1). "Inside" = over its footprint; every world save with the owner
  inside records the time; the welcome-back comes when the world starts and when the app returns from the
  background after 5 minutes, pays once, with "Your farm made 240 gold!" and a coin shower. Signed in, the server's
  `farm_collect` clock pays (§17.6); otherwise the device clock (a clock that went backwards pays nothing). MOVE
  puts the farm back in the bag with its levels. The note: a SETTINGS switch "Farm note" (off; under-13 behind the
  parent gate), never 20:00-08:00, once a day; the Android plugin that rings it is M5's.

### 14.9 Tutorial with Pip (§5.10)
- First Survivor start (skippable, no reward if skipped): Pip teaches by doing — move and look,
  triple-jump a gap, build a bridge, break a wall, hide from a harmless practice monster, tap a Totem.
  Reward: 500 Survivor gold, a free hat, and Pip becomes the first pet. Voice-free, icon-first
  instructions with short text for early readers.
- **As built (M3 Task 15, 2026-09-25; rulings in `docs/devlog/parts/m3-task-15.md`):** after the first-launch
  flow (age → name → look → controls → menu; owner #52: English only), the first time a child plays a **solo** Survivor world
  (CLASSIC game; never LAN, online, Sandbox, Monster Wave, Build to Survive or the Dragon Realm) a card offers
  **PLAY WITH PIP** / **SKIP**. SKIP gives nothing and is never asked again; SETTINGS → HELP →
  **PIP'S LESSONS** plays it again in the next solo Survivor game (at once when asked from the pause menu).
  A visiting Pip rolls beside the child; each step has a picture card with very short words (every line has an id,
  read aloud with "Read to me" and babbled by Pip), and the child does the real thing on "Pip's playground", a
  course the game lays out near the spawn from pure rules (`TutorialCourse`: level dry ground within 60 blocks of
  the spawn, clear of Tilly, the Totem, the stone circle, the Theater, the quest giver and the spawn; a pad of at
  most ±4 blocks; worked out on a worker thread): **move and look** (walk to the arrow, turn the camera) → **jump the hole** (6 wide: a double or
  triple jump) → **build a bridge** (3 blocks across a hole) → **break the wall** → **hide** from a harmless
  practice slime (a real slime that can't hurt or be hurt) by crouching in a bush → **craft sticks** by Pip's
  Workbench → **visit Tilly** (owner #37's shop tip and its arrow). The Totem step is gone (owner #44: no waves in
  Survivor). A small X stops it at any time: nothing is lost, the course goes away and it resumes at that step
  next time. No timers. The course is never kept: every changed cell is recorded in the world's meta the moment it
  is placed, put back when the tutorial ends or stops, and after a crash the next load puts it back; blocks the
  child built into the course come back to their bag. Finishing (the first time only, also after a skip):
  **500 Survivor gold, Pip's Cap, and Pip becomes the first pet** (`PetRules.give_pip`).

### 14.10 Admin panel and secret codes (§5.11)
- The small black "admin panel" text at the bottom of the main menu opens a code field. Codes are
  normalised (trim, lowercase); only SHA-256 hashes with an app salt ship; each works once per device
  profile (server-side from M4). First code: `sasa192974` → 1,000 Survivor gold.
- Messages: "Code accepted! +1,000 gold" with a coin shower, "That code doesn't work.", "You already
  used that code."; 5 wrong tries in a row → a 30 s wait (no mashing). Reward kinds: Survivor gold, and
  cosmetic unlocks (§14.6, M3 Task 9).

### 14.11 Progress, missions and daily gift (§5.8)
- Player level from XP (monsters, secrets, builds, missions), titles on the name tag ("Boss Slayer",
  "Secret Hunter", "Master Builder"). The **adventure board** (3 picture goals the child picks, never
  expiring) replaces daily missions, and pets bring presents during play (no daily gift); missing a day never
  costs anything (no streak loss). Achievements with badges in a trophy room.
- Refined by Task 12 (rulings in `docs/devlog/parts/m3-task-12.md`): XP from events (monster 10, secret
  25, block 1 — a stamp is one event —, wave 40, boss 150, buddy 20, tamed 30, photo 5, race 25, friend 15,
  new place 5, goal 50); levels need 25 (L−1)(L+2) XP (level 2 in about 10 minutes of play, 10 in about
  4 hours); ten play-style titles (Master Builder, Secret Hunter, Monster Buster, Boss Slayer, Animal
  Friend, Buddy Maker, Explorer, Photographer, Speedy Racer, Team Player) earned at 50 XP in the style,
  the child picks one or the tag shows the style played most, over other players' heads as "Lv 5 Master
  Builder". The board (pause menu, BOARD): 23 picture goals of ≤ 4 words, 3 slots, counted from the pick,
  starting with Take a photo / Wake a buddy / Find 3 secrets; a goal done gives its sticker, and in
  Survivor 40-150 fixed gold through the host (building, buddy, photo and friend goals: the sticker
  only); it stays "Done!" until the child picks another. 24 badges on the trophy room's shelves (shadows
  until found) and a sticker book. Presents: a tamed pet within 24 blocks brings one after 15-25 minutes
  (a fixed round) of active play; the child picks one of three gifts (Survivor: 15 gold, 2 lanterns or 10
  planks from the host; Sandbox: a sticker); nothing for time away, presents never pile up.

### 14.12 Shorts Theater (§5.12)
- The building near spawn, the vertical video panel with next/previous/exit beside the player, the
  Android WebView plugin, curated channel lists from the server (Nakama storage from M4; a bundled JSON
  until then), YouTube for everyone (Made-for-Kids only for under-13, behind the parent gate), TikTok
  13+ only, no rewards for watching, a server kill-switch. **Needs from the owner:** a Google Cloud
  project + YouTube Data API key and a TikTok developer app (spec §11) — until then the Theater shows a
  "coming soon" screen and the code path is tested with a local sample list.
- As built (M3 Task 17, research H6): a 9 × 9 building about 30 blocks from the spawn (door towards
  it; further out when the ground there is sea or hills); for `under_13` the Theater is **off until a
  grown-up opens it** behind the parent gate, nothing autoplays (not even the first video), and
  "That's the show!" (with a picture of the world and two equal choices) comes after 5 videos; 13+
  gets one autoplaying player, the next video by itself and the card after 10. EasyCraft TV is always
  the first channel. The list fails closed: without `"enabled": true` there is no Theater.
- As built (owner #89, see §5.12): the real list (bundled and on the server, module 0.2.17), no API key needed (the
  owner curates the list; `tools/theater_list.py` checks every video on YouTube's own pages); the made-for-kids
  settings for everyone replace M3's 13+ autoplay and TikTok; the browser's player; the 16:9 panel with picture tabs
  and video cards.

### 14.13 Action kit (§13.3–13.7)
- Gadgets (glider, launch/bounce pads, grappling hook, zipline, instant builds, impulse orb, dance
  orb), blasters (foam, bubble, paint, snowball, confetti rocket), Party Piñata drops and supply
  balloons, build-fight practice with goblin archers, as specified in §13.
- Refined by Task 14a (gadgets; rulings in `docs/devlog/parts/m3-task-14a.md`): our own names — Glider,
  Grappling Hook, Quick Wall / Floor / Ramp / Fort, **Boing Orb** (the impulse orb), Dance Orb, Zipline Post,
  Launch Pad. The glider opens with JUMP after the last air jump or a GLIDE button shown only while falling;
  it falls at most 3 m/s and steers at 8 m/s; Sandbox always has one, Survivor buys it. The launch pad throws
  about 19 blocks up and opens the glider at the top. The hook holds blocks only (24 blocks, never through
  walls, once a second) and pulls you there with a hop at the end. Two posts a player placed up to 48 blocks
  apart link; the line hangs 2 blocks over them; a tap on a post rides it (faster downhill, never stuck
  uphill) and slides off at the end. Quick builds go only into empty cells, one undo; Survivor pays planks
  (else stone): "Need 12 Planks!". Orbs never hurt: the Boing Orb scatters monsters and bounces players;
  the Dance Orb makes monsters dance 5 s without attacking (bosses 2 s, once in 20 s). All free in the
  Sandbox palette's ARMORY page; Tilly sells them at fixed prices (orbs used up, three to a pack).

### 14.14 Photo mode (§5.9)
- A camera button: free camera around the player, filters, frame, hide HUD, save to the gallery and
  share (Android share sheet).
- Refined by Task 16 (rulings in `docs/devlog/parts/m3-task-16.md`): the camera button sits top right
  under the username and gold (P on desktop). One finger orbits, a pinch zooms, two fingers pan (mouse
  drag, right-drag and wheel on desktop); the camera stays within 6 blocks of the player's head and 12
  blocks away (× Size Magic) and never passes through blocks, so it can't scout closed rooms. Filters:
  normal, warm, cool, black & white, comic (one shader, one material). Frames: none, photo, film,
  stars, gold (drawn by the UI and saved with the photo). The shutter flashes and clicks and saves a PNG
  without the buttons: `Pictures/EasyCraft` on Android (else the app's folder, with a message saying
  so), `user://photos` on desktop, never overwriting. SHARE opens the system share sheet (no in-game
  upload). Solo play pauses the world while photo mode is open; LAN never pauses, and a hit there
  closes photo mode. Leaving (X, Back, Esc) restores the camera and HUD exactly.
- (M5 store readiness F1, §5.14) SHARE (FOLDER on desktop) shows only where the grown-up's photo sharing switch
  allows it (off for `under_13` by default); otherwise photo mode has the shutter only, which saves to the gallery,
  and nothing in it opens the share sheet. The switch is read each time photo mode opens.

### 14.15 Acceptance
- The acceptance tour gains checks for each universe (travel through the portal, a monster of each
  behaviour, a boss fight start), the Physics Lab, smart blocks and a Game Blocks course, the avatar
  editor, pets' perks, the farm payout, the tutorial, a code, missions, photo mode and the Theater's
  local sample list; the performance bar holds in every universe in both styles.

### 14.16 Rideable buddies (research signature bet "the dragon you built and fly"; Task 20a)
- A buddy built with a **SADDLE** block (block 216) can be ridden: woken with the wand, or a sleeping buddy
  (its blocks) that gets a saddle and is woken again. Near one nobody rides, a **RIDE** context button shows
  (right of BOOK; HOP OFF while riding); RIDE again gets off, and JUMP gets off anything but a flyer.
- What it does comes from its shape: **wings** (blocks sticking out left and right in its upper half, at least 2
  each side) fly like a dragon — the stick steers, JUMP climbs, CROUCH dives, at most 11 m/s (the paid Fly's
  speed); **wheels** (four blocks at the bottom corners with a gap between front and back) drive like a car — at
  most 10 m/s, turning, bumping gently off walls, climbing 1 block, never 2; **on water** anything but a flyer
  sails like a boat (6 m/s); anything else is a gentle **walk** mount (the player's speed + 20 %). A build whose
  wings or wheels are the other way round turns a quarter when it wakes, so it goes where it looks. A flyer comes
  down on the water's top, never under it. The wake line says what it does ("Your dragon can fly!", "Vroom! A
  car!", "Ahoy! A boat!").
- Sandbox: free (the saddle is in the palette's MAGIC row). Survivor: the saddle is bought from Tilly (60 gold ×
  2^(u−1)); riding costs nothing, but a flight lasts until the dragon lands again. Nobody takes fall damage.
- Anyone may ride a free saddled buddy (the owner still decides its sleep; a ridden buddy can't be put to sleep).
- One compact collision box as every buddy (owner feedback #9); the host decides every ride and moves the buddy
  (the rider's stick goes to it like a player's input); every game shows the rider on the saddle.

### 14.17 Quests: more board goals, quest givers, picture-story chains, the quest book (owner #45a; Task 24a)
Owner 2026-09-24 21:49: "save into plan that we should continue implementing new quests". Fair fun (§6, R4):
no timers, nothing expires, no streaks, nothing is lost; rewards are fixed, never random.
- **More board goals** (§14.11's board): at least 30 new picture goals — the desert, Frostpeak and the Candy
  Kingdom (their monsters, bosses, secrets and places), crafting, Monster Wave's arena waves, pets (fox, parrot,
  treats), the #41 animals (listed only once that species is in the game), the #42 treasures (shipwreck,
  vault, haunted house, well, rainbow, mineshaft…), races (a gold medal), building (500 blocks, riding and
  flying a buddy) and quests. Every goal names where its counter can rise (Sandbox, Survivor, Monster Wave), and
  the goal list says so on a goal that can't be done here ("in Monster Wave", "in the Sandstorm Desert"); a
  goal only the Sandbox can finish pays no gold, and gold is paid only where gold is real (Survivor and
  Monster Wave, as before). A goal of one universe ("Find 3 desert secrets") counts only what happens in that
  universe: the progress keeps a count per universe next to the account-wide one.
- **New counters** (each raised by the host or the child's own game, tested through the real code):
  `item_crafted/<recipe>` (a craft the host made), `pet_fed/<species>` (a treat given), `buddy_ridden/<fly|drive|
  sail|walk>` (a ride started), `quest_step` and `quest_done/<chain>`; more detail on old ones: `boss_beaten/<the
  real boss>` (the Serpent, the Giant, the Cake Monster, not always "golem"), `wave_won/arena` (Monster Wave),
  `race_finished/<medal>`; every event is also counted in the universe it happened in (Progress.universe).
- **Quest givers:** Tilly in Green Meadows (her stall in Survivor; in the Sandbox she stands where her stall
  would be) and a helper by the spawn of each other universe: **Zara the explorer** (desert), **Bram the ranger**
  (Frostpeak), **Mimi the baker** (Candy Kingdom). A helper stands 13–19 blocks from the spawn on dry, level
  ground clear of trees, at least 6 blocks from Tilly's stall, the Totem and the hub circle and 3 blocks off the
  straight ways from the spawn to them and to the Theater (inside the treasure pack's 60-block clear zone);
  found from the seed alone, so every game of a world agrees. None in Monster Wave arenas. A picture bubble over
  a giver: "!" when a story waits for this child, "?" when the child's quest step is "come back to me". A tap
  opens the giver's card: the story told in pictures and short read-aloud words, LET'S GO / NOT NOW (Tilly's
  card in Survivor also has SHOP, her shop otherwise opens as before).
- **Chains:** 9 chains (Tilly 3, the helpers 2 each) of 3–5 steps from what the world has: dig up treasure,
  follow the arrow to a place (ruins, a pyramid, the ice temple), find a secret, tame, beat monsters, craft (a
  lantern, glass), then **come back** to the giver (walking up is enough). A chain's steps count only in its own
  universe and from the moment the step starts. A chain with a Survivor-only step (crafting) is only offered in
  Survivor. Each chain ends with a **keepsake** (on the Secret Book's new "Keepsakes" page and in the quest
  book), a **title** for the name tag (picked on the board's title page like the play-style titles), **gold** in
  Survivor (fixed: its base × 2^(u−1), paid by the host once) and **a new place** kept in the profile (where the
  chain led; the world map of 45b shows it; until then the quest book's ARROW points to it in that world). A
  chain is done once; its rewards come once.
- **The quest book** (MORE → QUESTS, a picture page): the chain being followed (its steps as pictures, done
  ones ticked, the current one with its words, "2/3", ARROW to show the way, STOP FOR NOW), the chains stopped
  (GO ON), the givers and how many of their stories are done, and the keepsakes. No timers, no countdowns, no
  nagging: nothing happens when a chain waits for months. A new chain can be started any time; the one being
  followed then waits where it was.
- **Co-op:** in LAN or online games the host decides: PLAY TOGETHER in the host's quest book shares the host's
  chain (of this world's universe) with everyone. The host counts the team's steps (each game sends its matching
  events; "come back" and "follow the arrow" steps count for any player), every player sees the shared chain and
  its arrow, and when it ends **everyone who helped** (counted something, or was within 24 blocks when a step was
  done — and the host) gets its keepsake, title and place, and in Survivor its gold (the host pays each helper
  once). A child's own chain keeps its place meanwhile.
- **Bot friends help:** asked to find treasure or to help with the quest ("follow the arrow", the BOTS picture
  page's treasure), bot friends lead the child to the quest step's place first.
- Tests first: goal definitions (every kind has a counter that is really raised, per-universe counts, modes and
  gold), chain steps and their checks, rewards once, save/load of a chain in the middle, no timer anywhere (no
  time words or numbers in the data or on the pages), the giver spots, co-op sharing (host only, helpers
  rewarded, non-helpers not), the book fits the screen.

### 14.18 A bigger world: wild meadows, places to find, the world map (owner #45b; Task 24b)
Owner 2026-09-24 21:49: "we should extend the world". The world is already endless, so this adds variety and
reasons to travel. Green Meadows only; the other universes keep their terrain.
- **Terrain versions.** Only edited chunks are saved; the rest is generated again from the seed every time. So a
  world keeps the terrain it was made with: `WorldMeta.terrain` 1 is the M1–M3 Green Meadows (every world saved
  before, forever), 2 the **wild meadows** below (every new world). A guest gets the host's version with the
  universe, before the world. Cost if wrong: a child sees the new lands only in a new world.
- **Biomes** blended into the old noise (the same continents, hills and mountains): birch forests (white birch),
  dark forests (dark oaks, dense), flower fields, swamps (mud, shallow pools with lily pads, dark trees), wide
  sandy beaches, a sea with islands (sand rings, trees on top), tall mountains with rock faces and snowy tops, and
  deeper caves: glowing mushroom caves (giant mushrooms with glowing caps) and underground lakes, in their own
  regions. **Rivers run to the sea:** two families of long winding rivers (one roughly north–south, one east–west,
  each a warped line that never closes into a loop) cross the land about every kilometre, meet each other and
  widen where they reach the coast, so every river joins the sea.
- **New blocks** (page 13, ids 256–271, both styles, CC0): birch wood and leaves, dark wood and leaves, flowers,
  lily pad, mud, stone bricks, mossy bricks, white plaster, roof tiles, hay, wheat, sail cloth, glowing mushroom
  cap, dirt path. Flowers and wheat are walk-through crossed pictures; a lily pad is a thin pad you can stand on.
  Gathered in Survivor like any block (leaves give nothing), `/give` in the Sandbox.
- **Places to find**, one at most in each 256 × 256 region, decided from the seed, the region and the terrain
  alone; never within 60 blocks of the world spawn (like the treasure pack), never on a secret's ground (secrets
  never move for them), never cutting into water or a cliff (the ground under a place rises and falls at most a
  few blocks; pads fill dips and cut bumps). **Rarer farther away:** a windmill from 60 blocks, a village from 150,
  a lookout tower from 250, a lighthouse on a coast from 250, a ship moored at a pier from 400, castle ruins from
  700, a big village (a town with a market) from 1,200; the chance of a place in a region grows with its
  distance too, so going farther always finds something new.
  - **A village:** a plaza with a well, 3–6 houses (plaster or planks, log frames, roof tiles, glass, a door, a
    lantern) around it with doors to the plaza, dirt paths, a wheat farm with hay bales, and 2–5 **villagers who
    wave** at players who come near. In Survivor a tap on a villager opens Tilly's shop (her rules and prices); in
    the Sandbox they wave and say hello. Every village has a name ("Maplebrook") and a centre, for the quest
    givers of §14.17.
  - A windmill with sails, a red-and-white lighthouse with a glowing lamp room, a lookout tower with a stair up
    to its top, a ship with masts and sails at a pier, castle ruins of mossy bricks; every one can be walked
    into, and every stair climbed.
- **Finding a place:** coming within its find circle (the host decides for every player) marks it found for the
  whole world (saved in `WorldMeta.places_found`); the finder's screen says "You found Maplebrook!" with its
  picture.
- **The world map** (MORE → MAP, a picture page): the places found in this world, each with its picture and name,
  around the child's arrow and the home marker; places nobody found are never shown (secrets stay secret). A tap
  on a place sets the find arrow (the /find arrow) towards it. Other tasks can add their own found places to it
  (the quest chains' places).
- **Cost:** the generator stays at or under Green Meadows' old cost per chunk (a chunk column's heights and
  biomes are worked out once for the whole stack of chunks; `tools/bench_generator.gd -- --biomes`), and nothing
  new runs every frame: the host looks for finds and villagers a few times a second, villagers exist only near
  players.
- Tests first: the biome picks (deterministic per seed), rivers reach the sea, villages never cut into water or
  cliffs, every place's rarity against the distance, the map's found-only rule, the generator benchmark.

### 14.19 More animals (owner feedback #41, 2026-09-24 20:42: "include more different animals"; "animals should have sounds, like real ones")
- **Each universe names its animals** (its descriptor's `animals` list; `UniverseRegistry.animals(u)`), and herds
  spawn only near players with M1b's budget (≤ 20 near a player, decisions ≤ 10 Hz, rest beyond 32 blocks, shared
  meshes and materials). A universe that names none keeps Green Meadows' animals.
  - **Green Meadows:** today's farm animals, dogs, cats, rabbits, fish, foxes and parrots, plus **horse**, **donkey**,
    **goat**, **deer**, **duck**, **frog**, **turtle**, **squirrel**, **owl** and **hedgehog**. About half of the herds
    become one of the new kinds that fits the place (a seeded roll of its own, so the other herds stay): ducks, frogs
    and turtles by the water, deer, squirrels and owls by the woods, goats on the hills, horses, donkeys and
    hedgehogs in the open. **Bees and butterflies** flutter over the meadow by day (one cheap particle system per
    screen, nothing sent).
  - **Sandstorm Desert:** **camel** (on the sand and by the oases), **lizard**, **fennec fox**.
  - **Frostpeak:** **penguin** (on the frozen lakes and their shores), a gentle **polar bear** (big, fluffy, calm;
    no animal ever attacks), **arctic fox**, **seal** (on the lake ice).
  - **Candy Kingdom:** **gummy bunnies** (bouncy, on the frosting plains) and **candy birds** (in the candy-cane
    forests).
- **What they do:** a goat jumps up 2 blocks (others 1); a deer is shy (runs from anyone walking up within 9 blocks);
  ducks, frogs, turtles, penguins, seals and polar bears swim (they float on the water's top); a frog and a gummy
  bunny hop high; a turtle is slow, and now and then lays an egg on sand — a small secret: a child who finds it sees
  it hatch into a baby turtle; a squirrel runs up tree trunks; an owl sleeps by day and hoots at night; a hedgehog
  curls up instead of running; penguins and seals belly-slide on ice (faster); a lizard darts.
- **Food and taming:** every kind has its food (grass and leaves for the grazers, the treats for the rest: Fish Snack
  for penguins, seals and polar bears, Seed Cracker for birds, candy blocks for the candy animals). Food makes an
  animal like the child (M2 Task 18's mind). New pets (spec §14.7's table): **horse** and **camel** (two treats, then a
  **SADDLE** — Tilly's, spec §14.16 — given with a tap makes them rideable), **donkey** (two treats; carries a
  **chest of 9 slots** on its back: its card's CHEST page puts the held stack in and takes a slot back), and the
  **fennec** and **arctic fox** (two treats; they sniff out treasure like the fox). The arctic fox and the fennec are
  species of their own (white and sandy), not Green Meadows' fox.
- **Riding** (spec §14.16's RIDE button and RideRules): near a saddled horse or camel nobody rides, RIDE gets on;
  anyone may ride it. A horse **gallops** (9.5 m/s, under the paid Fly's 11), a camel **treks** (6.5 m/s) and keeps its
  pace in a sandstorm while a horse slows to 70 %. A ridden animal never walks into water nor off a drop of more than
  4 blocks; HOP OFF (or JUMP) puts the child beside it, never inside blocks. Nobody takes fall damage.
- **Voices:** every kind has a call, a hurt voice and a happy voice from **real CC0 recordings** (freesound.org, the
  licence read on each page by `tools/make_audio_pass_sfx.py`, credited in `assets/CREDITS.md`); the fox and the
  parrot get their own real voices. Every kind joins the **animal chorus** (spec §12.10) with a measured level
  (`VoiceRules.CALL_GAIN_DB`, towards −17 LUFS through a phone speaker), and wild animals asleep never call.
- **Pictures:** box animals (shared meshes, one material) in both styles, like every animal; a saddled horse or camel
  and the donkey's packs are part of the cached meshes.

### 14.20 Words and voices: read-aloud, babble voices, English only, simple controls (M3 Task 21a)
Research O6, O7, O8, F7, A6 (§16's M3 core set). Notes and rulings: `docs/devlog/parts/m3-task-21a.md`.
- **Read-aloud** through the system's text-to-speech (`ReadAloud`, owner #45a's speaker extended): a speaker
  button beside a panel's title reads it at once (menus' titles, the pause menu, SETTINGS, the Secret Book,
  riddle notes, the stay-safe card, the quest card and book); **"Read to me"** (SETTINGS → HELP, off
  by default) also reads toasts, banners, first-time tips, riddles and each menu screen's title as they appear,
  one at a time (`SpeechQueue`). **Never chat** (bot friends' lines included) and never another player's name
  ("a friend"). No voice for the game's language: nothing is read and the speakers hide.
- **Babble voices** (`BabbleRules`, `BabbleVoices`): bot friends' chat lines, a buddy's cheer and wake-up,
  Tilly's hello at her shop, a story friend's hello on its card and the parrot's echo "talk" in nonsense
  syllables (12 original takes, `tools/make_babble_sfx.py`) at the speaker's own pitch (its kind, its size —
  tiny squeaks, giants rumble — and a personality from its name). One line at a time per device, a speaker
  rests after talking, 20 blocks at most; the animals' chorus rests while babble plays. Animals keep their real
  voices (owner #27).
- **English only** (owner #52, 2026-09-25: "please dont build game in georgian, i didnt ask it. remove it from
  game and never include"). The Georgian translation, its LANGUAGE card and setting, its word check and tools,
  the Georgian chat-command names and the bot friends' Georgian words and answers were removed; the store drafts
  are English only. `tests/unit/test_english_only.gd` keeps Georgian letters out of the game. Players' own chat
  still shows whatever letters they type, drawn with the phone's font (owner #49): that is not a translation.
  Ruling (the lead): `tr()` / `Lang.t()` stay as passthroughs (removing them touches hundreds of lines for
  nothing); cost if wrong: none, they return the English.
- **Simple controls**, offered once (a card after the look: SIMPLE and CLASSIC as equal pictures) and in
  SETTINGS: auto-jump over a 1-block gap as well as up a 1-block step (everyone keeps M1b's auto-step), the
  camera turns to follow while the stick pushes sideways, and ATTACK and CROUCH show only when they apply
  (a weapon in the hand or a monster within 16 blocks).
- SETTINGS has two pages, GAME and HELP (Read to me, Simple / Classic, Reduce motion), both inside 1280 × 720.

### 14.21 Buddy magic: secret shapes, the Buddy Album, My Stamps, befriending, mini-buddies, tricks (research §16; Task 20b)
- **Secret buddy shapes** (signature moment "secret buddy shapes", research D1): eight small patterns that, woken with
  the wand, become a special buddy with its own name, name-tag colour, traits and a thing it does now and then on every
  screen: the Jolly Snowman *Frosty* (three white blocks stacked, an orange nose: gentle snowflakes), the Lantern Robot
  *Bolt* (a grey body, two grey arms, a lamp head: beeps and glows), the Growing Flower Pot *Petal* (pot, leaves, a
  flower: grows a little each time, up to twice its size, its collision box never grows), the Singing Castle *Melody*
  (a 3 × 3 floor with four corner towers: a tune of chimes), the Lighthouse Buddy *Beacon* (red and white, three tall, a
  light on top: a bright light that flares), the Rainbow Caterpillar (red, yellow, green, blue, purple in a row: a
  rainbow wiggle), the Crystal Fairy *Twinkle* (a crystal body, glass wings: it floats and twinkles) and the Puppy
  Buddy *Scout* (two legs, a back, a head up front, any blocks: barks and runs ahead). A class of blocks counts for
  each cell (any white, any lamp...). Matching turns the build four ways and mirrors it, and forgives one spare block;
  it never tips a build over. The first time a child wakes a shape: a burst on every screen, "A secret shape! Frosty
  the Jolly Snowman is alive!", and it counts as a secret found. Build-and-Wear's WAKE UP (a build up to 5³) wakes it
  the same way.
- **The Secret Book's Buddy Recipes page**: a slot per shape: its silhouette (the recipe's front view, dark) and a
  picture riddle ("Three white blocks in a stack, and a carrot nose!") until found, then the picture in its blocks'
  colours and its name; "Secret shapes found: 3 of 8".
- **The Buddy Album** (research C2), the Secret Book's last page: every buddy the child woke, newest first: a small
  picture of its front (drawn from its blocks' tiles), its name (a secret shape's in purple), the universe and the
  day. The profile keeps the newest 40 (`ProfileData.buddy_magic`); older ones are a count ("Buddies woken: 52 (not shown: 12 older)").
- **My Stamps**: the palette's STAMPS page (both modes): NEW STAMP, then a tap on a build of theirs picks it (BuildPicker:
  the connected non-natural blocks, at most 16 a side and 1,600 blocks, so a stamp is always one edit and one undo);
  it glows; SAVE STAMP keeps it (turned so the side the child saw is its front). Five stamps (item ids 495-499), each
  with its picture; the small x deletes one (SURE?). Placed like the preset stamps (Survivor pays its blocks). Kept on
  the device (`user://my_stamps.json`), not in the profile backup (its 60 KB cap).
- **Befriend a monster** (research P4): the wand on a calm (not chasing) monster of level 1-2 → hearts, and it becomes
  the child's pet friend: the monster's look without its weapon, shrunk to pet size, pink cheeks; it follows, never
  hurts anyone, fights nothing, glows softly in the dark and counts toward the 3-pet cap. Never a boss ("Bosses are
  too big to be friends... but beat one and see what happens!"), a wave's monster or the golden slime; Sandbox and
  Survivor, not Monster Wave. The host decides; saved with the world's pets.
- **Bosses become mini-buddies** (signature moment "the Golem that becomes a tiny Pebble Golem friend", research P5):
  when a boss is beaten, every child there gets its tiny version once: the Pebble Golem, the Mini Sand Serpent
  (*Sandy*), the Little Frost Giant (*Flurry*), the Cupcake Monster (*Cupcake*); the Sky Dragon's is owner #39's baby
  dragon. It hops out of the boss's spot, follows like Pip, lives in the profile (one per boss kind, never sold, never
  a pet place) and comes into every world. Shared box models in the animals' material.
- **Tricks** (signature moment "the buddy that learns your dance", research P2): an emote done three times near one's
  own buddy or pet (8 blocks) teaches it ("Scout is watching you... 1 more!", then "Scout learned to dance!"); after
  that it does its own version whenever the child does it: a dance (the dances), a spin (Star Spin, cheer), a wave, a
  hop (clap, laugh, thumbs up), a sit, a bow. Never forgotten, no timers. Saved with the buddy or pet in the world;
  Pip's, the baby dragon's and the minis' in the profile.

### 14.22 The wonder pack: the Tiny world, waking more things, building sounds (M3 Task 21c; research core set §16)
- **The Tiny world** (§3a Size Magic "tiny-only secrets", §16 "a Tiny-only mouse village"): **mouse holes** — a door
  one block high at the foot of a hill, or between the roots of a big old tree on a grassy knoll — lead through a short
  tunnel into a **mouse village**: a little room under the ground with the mice's houses (a red-roofed house, a pumpkin
  or cactus or snowman house, a barrel to hide in), glowing lamps, a **mouse family** that turns to a child close by,
  waves and squeaks hello, and a **tiny treasure chest** (the mice's cheese, a treasure-only block for the Secret
  Book's shelf, a little something, and in Survivor a little fixed gold). A pumpkin (the desert: a cactus, Frostpeak: a
  small snowman, the Candy Kingdom: a jack-o-lantern) stands by every door. Only a **tiny** child fits through the
  door and finds the village (the Secret Book's first page has a slot with a picture riddle); a normal-size child who
  gets into the room (dug in, or grew there) is shown out to the door. Placed like secrets (the seed, the 128-block
  area and the terrain alone; seam-safe; at most one per area), in every universe but the Dragon Realm, never within
  60 blocks of the spawn, never on a secret, a treasure-pack place or a wild-meadows place (none of those move for
  a village), never on water or a river; a knoll's sides go up and down a block at a time. `/secret mice` (Sandbox).
- **Wake more things:** the Magic Wand wakes a **cactus** (its hugs never prickle; a flower pops out when it cheers),
  a **pumpkin** (or a jack-o-lantern, which glows orange, or a little scarecrow with a pumpkin head; it rolls as it
  hops and giggles), a **snowman** (a snowman's head on snow blocks; it puffs snow) with names of their own; and an
  opened treasure chest wakes as a **chest mimic**: googly eyes, it hops after the child, giggles, opens wide with a
  small present (never gold) and hops back to sleep — once per chest, never scary, never harmful (nobody bumps into
  it). New blocks on page 14: pumpkin, jack-o-lantern, snowman's head (Sandbox palette MAGIC row, Tilly's HOME) and the
  cheese (treasure only).
- **Building sounds and melody:** every placed block sings a soft note of its own (a marimba; glass, crystal, ice and
  lights a bell) on the **major pentatonic scale**, and blocks placed one after another in a row climb a rising
  melody (six notes, then again). One note per tap or tool step (a LINE or FILL of many blocks sings once), from a
  small pool of players that never grows, at most eight notes a second. SETTINGS → LANGUAGE & HELP: **Block music**
  (on; off plays the plain pop).

### 14.23 The shop and trading (owner #37; M3 Task 28)
Owner 2026-09-24: "we should have a shop in the game, where you can trade". Tilly's shop (§12.7) is the game's
shop (the owner found it at 20:19); this makes her easy to find, puts more traders in the worlds and lets players
trade with each other. **Gold is never sold for money and never mixed with the grown-ups' shop (§18).** Survivor
only (Sandbox gold is ∞ and nothing is counted; the Monster Wave arenas have no shop).
- **Find Tilly:** MORE → **SHOP** opens a small picture card: Tilly (her stall, or the nearest villager who
  trades, whichever is nearer) with how far she is and an arrow the way to go; a tap on her row points the HUD's
  find arrow at her (the /find arrow of §3b) and closes the card, and when the child gets there the shop opens by
  itself. Close by, the row says OPEN. The first time a child plays a Survivor world (once per profile) a picture
  tip says where Tilly is and the arrow points at her for a while.
- **Stands by the helpers:** in Survivor worlds of every universe with a helper of its own (§14.17: Zara in the
  Sandstorm Desert, Bram in Frostpeak, Mimi in the Candy Kingdom, Nell in the Dragon Realm), the helper keeps a
  small stand beside them (a table with the universe's things and an awning in its colours, a sign "Zara's
  stand"). A tap on the stand opens the shop on the universe's own things (its descriptor's `trader_stock`, Tilly's
  prices × 2^(u−1)); a tap on the helper still opens their quest card. Green Meadows' stand is Tilly's stall. (The
  universe's things stay in Tilly's BLOCKS too.)
- **Market day:** each Survivor world counts its days (a day begins at sunrise; the host counts; saved in
  `WorldMeta.market`). Every 7th day, starting with the world's 2nd, is market day: from sunrise to sunset
  **Nico the traveller**'s cart stands beside Tilly's stall. He brings the same things every time at fixed prices
  × 2^(u−1): the village blocks no shop sells (stone and mossy bricks, plaster, roof tiles, hay, dirt path, sail
  cloth, glowing mushrooms, flowers, wheat, lily pads, birch and dark wood). No countdown, no "only today",
  nothing gone for ever: it just happens, like weather. A banner says so once when it starts.
- **Trading between players** (Survivor, LAN and online; the host decides everything):
  - A tap on another player's name tag (within 8 blocks) opens their card with TRADE; MORE → SHOP lists the other
    players in this world with TRADE too. Bot friends are not players and have no TRADE.
  - The other child sees "Bob would like to trade." with YES and NO THANKS; nothing opens without YES. One ask at a
    time; asking again waits a moment.
  - The trade window shows both sides: YOU GIVE and BOB GIVES, up to 8 kinds of things from the bag and gold. Every
    change makes both not ready. When both press READY the host swaps at once, all or nothing: it checks again that
    each still has what they offered and that each bag has room for what comes, else nothing moves and both are
    told why. X, leaving the game or the world ending stops the trade; nothing leaves a bag until the swap, so a
    stopped trade gives everything back by itself and nothing can be copied.
  - Tradable: the Survivor bag's blocks and items and Survivor gold (at most 500 × 2^(u−1) gold a trade). Not
    tradable: universe crystals (you earn one by reaching its universe) and the Gold Farm (one per world, its
    owner's). Pets, tamed animals, looks, stickers, keepsakes and what a grown-up bought are not in the bag.
  - Age: online, a player under 13 trades only with players on their own friends list (in the world they play in
    together); on LAN the players are together at home and trade freely (like LAN chat).
  - Both traders get a chat line: "You traded with Bob: you gave 10 Stone; you got 1 Iron Sword."
- Tests first: the arrow and the distance, the tip once, the stand per universe, market day's schedule and stock,
  trade windows (both ready, cancel, one leaves, a full bag, not owned, no copies), the host's checks for a guest,
  the age rules, bots.

### 14.24 Books and memories (the research's M3 core set, §16; plan Task 21b)
One book: the HUD's BOOK button (no new button) opens the Secret Book with a column of picture tabs — SECRETS (the
Secret Book, §12.16), ANIMALS, MEMORIES, IDEAS, SAVING. A tap on a **bookshelf** block (218) opens it on MEMORIES.
- **Animal Book** (research C1): a page for every animal kind in the species table (new kinds come by themselves):
  a silhouette and "???" (with a clue where it lives) until the child has been close to one, then its picture (drawn
  from its own box model), its name and one true, friendly fact; a treat mark once fed (a pet treat or its food from
  the hand), a heart once it became the child's pet. Kept in the profile (and its server backup).
- **Memory Book** (research R2, C5): the child's big moments, collected by themselves, once each, with the date —
  the first buddy, pet, secret, geode, monster, wave, race, ride, craft, story and photo; a friend played with; every
  boss beaten; every new universe reached; the first Survivor night got through without a knock-out; a Secret Book page
  done; levels 5, 10 and 20. A photo the child takes within 10 minutes of a moment goes with the newest moment still
  without one (a small copy). **On this device only**: never in the profile or its backup, never shared by itself.
- **Trophy shelf** (research C3): block 217, an open wooden cabinet; every shelf near a player shows the world owner's
  badges (§14.11) as little 3D trophies, four a shelf, the top row of shelves first. A guest sees the host's.
- **Idea cards** (research X5): 28 picture cards with build ideas to flip through; no rewards, no timers.
- **Saving up** (research R3): SAVE UP beside BUY at Tilly's (when the gold isn't there yet) and in BUY's place in the
  avatar editor puts a gold thing on the child's saving list (at most 6); a have/need bar under the HUD's gold (the first
  thing, Survivor) and on the SAVING tab. It never spends gold; buying it takes it off. Owner #35's wish list stays the
  grown-up's list of pack items (a pack item never goes on this one).
- **Secret Book page rewards** (research C4): a page done (every kind on it found: the M2 secrets, the Treasure Hunt,
  the Keepsakes) gives, once, its avatar item (Fairy Wings, Pirate Bandana, Storybook Cape), its sticker and a golden
  star on the Hub Tree.
- **The Hub Tree** (research R1): beside the stone circle of every Survivor world, a tree that grows a leafy crown in
  each explored universe's colours, a glowing fruit per boss beaten and a star per page done; it only ever grows. A
  guest sees the host's.

## 15. Milestone M5 "Launch" — detailed spec (everything except the iOS build)

Written 2026-09-24 by the lead. The iOS build happens later on the owner's Mac (owner's order). Steps
that need the owner's own accounts or a lawyer are prepared as far as possible and listed in §15.6.

### 15.1 Accessibility (§5.15)
- Settings: **button size** (normal / big / huge), **movable controls** (drag the joystick and buttons
  in an edit layout, saved), **left-handed layout** (mirror the controls), **text size** (3 steps),
  **colourblind-safe** indicators everywhere (shape + colour), **reduced motion** (no screen shake,
  softer flashes), **vibration** on/off (M2), subtitles for important sounds (a small icon when a
  monster growls behind you).

#### 15.1a As built (M5 Task 1; notes and rulings: `docs/devlog/parts/m5-task-1.md`)
- SETTINGS gets a third page, **BUTTONS & TEXT** (the header's third button, beside GAME and HELP), inside
  1280 × 720: BUTTON SIZE (NORMAL / BIG / BIGGER), HANDS (RIGHT HAND / LEFT HAND) and MOVE BUTTONS, TEXT SIZE
  (NORMAL / BIG) and Sound captions.
- **Button size** grows the thumb controls, the ones pressed fast while moving and fighting: the stick, JUMP (UP),
  ATTACK, CROUCH (DOWN) and GLIDE, ×1.1 (BIG) and ×1.2 (BIGGER). The top buttons (pause, CHAT, BOOK, RIDE, WALK,
  MORE) and the middle word buttons (SLEEP, WAKE UP, STOP FOR TODAY, HELP UP, TEAM PHOTO) keep their size (they are
  135 or more already, and the chat bar, the MORE panel and the labels are laid out around them). A 16:9 phone has
  no room for a bigger thumb cluster in the old shape, so BIG and BIGGER have their own spots in `HudLayout`:
  CROUCH above JUMP, ATTACK left of JUMP (above the hotbar), GLIDE above ATTACK, the stick's area 400 × 260, SLEEP /
  WAKE UP over STOP FOR TODAY / HELP UP left of ATTACK, the help ring above HELP UP, TEAM PHOTO under CHAT.
  ×1.2 is the most: at ×1.25 JUMP in the corner meets the hotbar on a 16:9 phone.
- **Left hand:** the whole HUD in a mirror (every spot of the table): the stick on the right, JUMP and ATTACK on the
  left, pause, CHAT and BOOK top right, WALK and MORE top left; the chat bar and its history and the MORE panel
  follow.
- **Movable controls:** MOVE BUTTONS opens a picture of the HUD where JUMP, ATTACK, CROUCH and the stick can be
  dragged (a child or a grown-up; no gate); DONE saves, RESET puts all four back. Moves are saved in the profile
  per button size (the right hand's frame; the left hand sees them mirrored). A control that would cover another
  control, a label or the hotbar, or leave the screen's safe area, stays where it was (checked again on every
  screen; an old move that no longer fits is ignored).
- **Text size** (NORMAL / BIG, ×1.25): toasts, banners, first-time picture hints, notes and riddles, the knock-out
  words, the chat's lines and bar, the name. Menus keep their size (their buttons are big already and every page
  must fit 720 px).
- **Sound captions** (on by default: phones are often muted): a small chip with a picture and a few words on an oval
  round the middle of the screen, towards the sound (behind the camera: at the bottom), inside the HUD's corner
  buttons: a monster nearby (its voice), the Sneaker's jingle, a hiss, a boss's roar, the Sand Serpent's rumble
  below, the wave horn, night falling, someone talking (`CaptionRules`). One per kind every 4 s, at most three at
  once, 2.5 s each; with Reduce motion a new chip doesn't pop.
- **Never colour alone:** rarity has pips as well as its rim (tier items and blasters had them; avatar and shop
  tiles get them, shown while worn too), an empty heart is a hollow outline, the chat's game lines ("» "), errors
  ("! ") and bot friends' lines ("(bot) ") carry a mark, the danger arrow is an arrow, the stealth eye opens and
  closes; the game has no team colours (the co-op games are one team; the seeker is named in words). MOVE BUTTONS
  crosses out a place with no room.
- **Reduce motion** also calms the newer effects: every `Fx` burst (the gadgets', piñatas' and block breaks'), the
  blasters' pooled bursts and the rocket's confetti, the farm's coin shower (half the pieces, slower, no spin) and
  the menus' coin rain (a third of the coins, no spin or sway).
- **Read aloud on every screen:** a test opens each menu screen, the pause menu, SETTINGS' three pages, MOVE
  BUTTONS and the HUD's reading panels and checks that a speaker reads them; the boy-or-girl step, the secret-code
  panel, the avatar editor, Tilly's shop and the Monster Totem got theirs.
### 15.2 Art and audio polish
- A consistent icon set, menu backgrounds per universe, a title screen with a living diorama, loading
  hints with pictures, sound for every button, footsteps per block type, ambient loops per biome (these
  three built early with classical music in the audio pass, §12.10),
  improved monster/boss animation, particles pass. A **toon look** option is evaluated against the
  performance bar (§5.15, §13.6).
- **The polish pass** (the rest of M5 Task 2, after #43's identity pass and the audio pass; notes
  `docs/devlog/parts/m5-task-2.md`):
  - **Universe pictures.** Every universe card (the Survivor hub, the Sandbox worlds, Monster Wave, the stone
    circle's panel) shows a little scene of that universe drawn from its own block tiles and colours in #43's
    look, with the brand's orange buddy exploring it: Green Meadows' grass hill and tree; the desert's dunes, a sandstone pyramid and a cactus;
    Frostpeak's snowy peaks, a pine and an igloo; the Candy Kingdom's frosting hills, candy canes, a lollipop and a
    chocolate river; the Dragon Realm's floating island of cloud-white stone with golden spires over a sea of
    clouds at sunrise. A universe's own screens (CONTINUE / NEW WORLD, new world?, how brave, which game) show
    its scene behind the buttons under a soft veil. Locked and EasyCraft Plus cards keep their grey and star.
  - **A living title diorama.** Behind the menu's wordmark: a floating grass island with the orange block buddy
    (the brand's, with googly eyes and the wand's star) asleep; the star sparkles, it wakes (its eyes pop open, it
    hops and waves), the dog beside it wags and hops, then it dozes off again (a 12 s loop), while the camera
    orbits slowly. Shared meshes and the materials the world already compiled, nothing made per frame. With
    **Reduce motion** it is hidden and the camera holds still.
  - **Loading hints.** While a world loads (until this device's player stands in it) a card over the universe's
    picture shows one picture and one short line at a time (5 s each), picked for the mode and the universe,
    never the same twice in a row; **Read to me** reads each line (English only, owner #52).
  - **Monster and boss moves** (one shared `CreatureMoves`, poses only, no per-monster materials): slimes and
    gummy bears crouch for 0.3 s before they pounce (the wind-up every other monster already had); every monster
    and boss leans back when a hit lands (with the squash it had); the bosses breathe and sway while they stand,
    and when they win a fight they cheer for 2 s (arms up, a hop, their roar) before they sink or fly away.
  - **Particle pass.** `Fx` keeps at most 32 effects alive (the oldest ends early), skips bursts far from this
    device's camera and gives the big moments one style with the shared material: a block breaking, a buddy
    waking (gold stars), a portal (rainbow-gold) and a level-up (gold stars round the child, with the confetti).
  - **Audio.** The universes' music loops and ambience are evened out by gains measured the way #50 did
    (EBU R128 after two 500 Hz high-passes, a phone speaker; `tools/measure_loudness.py`). Frostpeak and the
    Candy Kingdom get their own ambience and classical pieces (public-domain or CC0 recordings). Monsters' idle
    voices share one budget per device like #50's animal chorus: a night with 20 goblins stays calm (a few
    voices a minute, the nearest first, a kind rests after it spoke); a hurt cry or a growl on spotting you is
    never held back.
  - The **toon look** stays the costed proposal of `docs/design/identity-audit.md` §6 (not built).
### 15.3 Performance
- The bar holds on the emulator in every universe and both styles (M1b/M2 method, autopilot +
  `AUTOPILOT slow` logs), plus a **low-end preset** (view distance 64, no shadows, fewer animals).
  Startup under 5 s on the emulator; APK size tracked (target ≤ 120 MB).
- **Built (M5 Task 3, `docs/devlog/parts/m5-task-3.md`):**
  - **LOW** (`GraphicsPreset.PRESETS.low`): the view at most 64 blocks whatever the slider says
    (`GraphicsPreset.view_distance`), no shadows, 3D at 75 % resolution, half the particles (`Fx.particle_scale`: bursts,
    coin showers, butterflies and bees, candy sprinkles), simpler realistic water (no wave normals: one uniform of the
    shared water material), at most 6 night monsters near each child (so never more than 6 within the 32 blocks where
    monsters are simulated) and 12 animals around each child (the host phone's preset). MEDIUM and HIGH add no caps of
    their own.
  - **The first start picks it:** a phone with under 3.5 GiB of memory or 4 cores or fewer starts on LOW, any other on
    MEDIUM (never HIGH by itself; `GraphicsPreset.for_device`, `ProfileData.first_start`). Only the first start: the
    child changes it in SETTINGS and that choice stays; a restored backup keeps this phone's own setting.
  - **Size:** each realistic block page keeps only the rows it draws (the materials stretch the 8 × 8 page's UVs over
    them), a page with no see-through block has no alpha, the normal maps are imported at half size, `docs/` is never
    exported. Phone APK 193.5 → 96.5 MB, Play download 88.8 → 66.8 MB.
  - **Startup:** the menu prints `MENU ready_ms=` (logcat); sounds load when they first play.
### 15.4 Store readiness (Google Play)
- **Final package id**: `com.giorgi.easycraft` (permanent after the first upload; ruling).
- **Upload key** (Play App Signing: Google keeps the app signing key; a lost upload key can be reset):
  generated locally outside the repo, never committed; the password in a local file only the owner's
  account can read; release builds signed with it.
- Store listing drafts: short and full description (English; Georgian as a second language), feature
  graphic and phone screenshots from the emulator, the **Data safety** answers (no ads, no tracking,
  age band only, chat rules), the **Families / Designed for Families** answers, content rating
  (IARC questionnaire answers prepared: cartoon violence against fantasy creatures, moderated
  chat for 13+, no gambling, no purchases).
- **Privacy policy** draft (plain language, children-first, COPPA/GDPR-K/UK Children's Code topics) and
  a hosted page plan. **Not legal advice**: a lawyer reviews it (§5.14).
### 15.5 Release candidate
- Version 1.0.0 (code bumped), a release APK and an **AAB** (Play requires AAB) in `~/Downloads`, a
  full acceptance tour on the emulator, a final whole-game review, and the release checklist in
  `docs/DEVELOPMENT.md`.
### 15.6 Needs from the owner (prepared, not done by the lead)
- A Google Play developer account ($25 once) and the upload of the AAB; the content-rating
  questionnaire submitted under that account; a lawyer's review of the privacy policy and the
  children's-privacy setup; a **real-phone check** (spec §7.5) on the owner's phone; the YouTube/TikTok
  developer accounts for the Theater (§14.12); the Nakama hosting provider and budget (§11); the Apple
  developer account and the iOS build on the Mac.

## 16. Engagement research (owner feedback #21) — how it shapes the plans

`docs/design/engagement-and-child-psychology.md` (research with 62 sources, 83 catalogued additions,
the techniques we use and reject) and `docs/design/long-term-roadmap-proposal.md` (ten signature
moments, M2 quick wins, ranked M3/M4/M5/Later lists) are part of this spec. Adopted by the lead:
- **Signature moments** every milestone aims at: a build that wakes up and blinks; the dog that digs up
  treasure; hiding in a barrel as the goblin walks past; the Golem that becomes a tiny Pebble Golem
  friend; the dragon you built and fly; secret buddy shapes; a Tiny-only mouse village; the buddy that
  learns your dance; neighbours moving into your house; friends racing your course.
- **M2 quick wins** go into M2 (the running tasks and Task 17 "Kid-friendly UX pass").
- **M3 core set** (read-aloud, pets find secrets, trophy shelf, idea cards, wish list, honest boss help,
  easier-wave choice, Secret Book page rewards, building sounds, wake more objects, bottles, simple
  controls, secret buddy shapes, Buddy Album, befriend a monster, bosses become mini-buddies, tricks,
  the Tiny world, Animal Book, Hub Tree, Memory Book, babble voices, languages, the parent corner,
  hide-and-seek with bots, **rideable buddies**) joins the M3 plan; the stretch set follows if time allows.
- **M4 must-haves** (parental consent, age of consent, age signals, "stay safe", privacy defaults,
  parent controls, human-reviewed reports, data policies) come before new social fun.
- **M5**: playtests with children of three age groups (owner), legal review, a privacy notice children
  can read, tablet and small-phone layouts, the trust promise on the store page.
- Ruling: **the CC0-only asset rule stays** (owner's rule 8); the dyslexia-friendly OFL font is not used
  unless the owner changes the rule; text size and spacing options instead.

## 17. Milestone M4 "Better Together" — detailed spec

Written 2026-09-24 by the lead from §5.13–5.14, §7.3–7.4, §16 (research must-haves) and the M4 early
online spike (`docs/devlog/parts/m4-online-spike.md`). Server: Nakama in Docker (this PC for
development; hosting provider and budget are the owner's decision, §11).

**Priority (owner 2026-09-24 12:19, feedback #25):** "what i want to start focusing is online game, this
game is online so players should be able to join the world and play together, friends invitations,
and other things. online and not just lan". M4 runs now, in parallel with M2's last tasks, before the
rest of M3. Online play is part of the game's identity: the main menu gets PLAY ONLINE next to SANDBOX
and SURVIVOR; LAN stays for play at home without the internet.

### 17.0 World sync over the internet (from the spike's measurements)
- A guest builds the terrain from the world seed (the generator is a pure function of seed and place)
  and receives only the host's **edits**: the changed blocks of a chunk when it comes into view, then
  each change as it happens. Targets on the emulator: joining in under 2 s, under 50 kbit/s per guest
  while playing (the spike measured 4–9 Mbit/s while a guest flew).
- Player and creature sync stays small and paced (one reliable stream: nothing big may queue ahead of
  positions); a dropped connection **rejoins the same match within 30 s** keeping the guest's player;
  plain-word messages for every network problem ("The internet went away. Trying again…").
- Who may join is checked on the server (invited friends only, at most 4 players).
- (M4 Task 10 review H) A packet meant for some players never reaches a player who joined after it was made: a join
  first names the players every waiting "everyone else" relay message was made for (the only-other-player shortcut
  leaves the presence out).
- (M4 Task 10 review I) A guest forgets the edits of a chunk its terrain has had unloaded for 10 s (sooner, they
  stay: the host's copy of the guest's player lags), and the host sends that chunk's edits again when it comes back
  into the guest's view, so a guest keeps only about one view's edits in memory.

### 17.1 Accounts (§5.13)
- Device authentication (no password); the username chosen at first launch becomes the Nakama username
  (unique, case-insensitive, the §5.13 rules and filters, checked by the server too). A lost phone
  loses the account until account linking [later].
- The profile (§7.4) is backed up to Nakama storage; Survivor gold moves to the server wallet ledger;
  codes, the farm clock and reports become server RPCs (`redeem_code`, `farm_collect`,
  `report_user`).
- (M4 Wave 2, agent F) The backup is private, restored at sign-in when the phone's profile is new;
  the newer copy wins and the child's gold never goes backwards. In an online world the server keeps
  each player's Survivor gold: the host starts a guest's wallet from the server and reports every
  change; the phone's own gold is reconciled with the ledger when signed in. Codes used offline are
  recorded on the server at the next sign-in. Details and rulings: `docs/devlog/parts/m4-f.md`.
- (M4 Task 10 review C, module 0.2.10) The spends a host reports for a guest are limited to 20,000 × 2^(u−1) gold
  an hour per guest (`spend_limit`: refused whole, the guest keeps that gold on the server and the next online world
  starts from it); a player's own spends are limited only by their balance.
- **(Owner #67, module 0.2.12) The account on every device: when a child signs in, the account feels loaded.**
  - *Signing in elsewhere:* the sign-in key (§5.13). `sign_in_with_key` links a new random id of the asking device
    to the named account (Nakama's own device table) and deletes the asking device's never-claimed account; wrong
    keys get one answer whatever the reason and lock per name (5 in 15 min, known or not) and per asking account (10
    an hour). The server keeps only the key's salted hash. `account_key`: state, a new key (5 an hour), sign out
    other devices (unlinks them, logs the account out, closes its sockets).
  - *What the account keeps* (`profiles/profile`, one object, private): the name, the age band (the stricter),
    the child's settings (sound, music, style, SIMPLE/CLASSIC, read-aloud, button and text size, the left hand,
    captions, reduce motion...), the look and costumes owned (not boy/girl), purchases and the wish list, codes
    used, the highest universe, crystals, the Secret Book and treasures, stickers, levels/XP/badges/presents/quests,
    Pip and the baby dragon, the books, buddy magic, the tutorial, hints seen, the grown-up switches (Theater,
    photo sharing). **Gold is the wallet ledger's only**; a device's gold follows it at every sync (the server's
    balance plus what the device changed that the server has not taken yet), so gold given on the server or earned
    on another device arrives, and gold spent elsewhere is never spent twice.
  - *What stays on the device:* the worlds (their blocks, what was built, the Survivor bag, buddies and pets, homes,
    farms: too big for the server, and a bag belongs to its world), graphics, view distance, FPS, the browser's
    install card, the farm's phone note, moved buttons, boy/girl, play time, the Memory Book, photos, friends' stamps
    and races, online prefs.
  - *The merge* (at sign-in and whenever another device wrote first): earned things never lost (unions, the larger
    count, the higher universe); the child's choices per group (look, settings, grown-up switches, pets' names), the
    newest wins (a stamp per group set when it changes); the rest from the newer copy; a new device (no progress
    yet) takes everything from the account. Every write names the version it was merged with (Nakama's version
    check): no device writes over another's progress.
  - *When it saves:* 5 s after the profile goes quiet (at most 30 s), at once when the menu opens after a world, when
    the game quits or goes to the background, and at every sign-in; offline, the profile on the device is the
    queue: the next sign-in (every menu visit tries) merges and uploads.
  - *The server checks every write* (`ProfileRules`): one object, a JSON object of sane size and shape, no gold,
    nothing of one device, the account's own name and band. Deleting the account deletes the backup, the key and
    every linked device.
  - A guest (never signed in) plays exactly as before; nothing new is asked of anyone (no e-mail, no password).
    Details and rulings: `docs/devlog/parts/owner-67-cloud-profile.md`.

### 17.2 Consent and age (research must-haves, §5.14) — before any social feature
- **Verifiable parental consent** for `under_13` (and under the local digital age of consent, 13–16 by
  country) before friends, invites, a findable username, chat history or shared builds: an adult flow
  outside the child's reach (a parent gate plus a verification provider such as Epic's Kids Web
  Services — free for developers; the owner registers the app there). Until consent: solo, LAN and
  bots only.
- Store **age signals** (Google Play Age Signals) mapped to our bands; the local age of consent table.
- A **"stay safe online"** card (pictures + read-aloud) before the first online game and after long
  breaks; **high-privacy defaults** (online play off for `under_13` until a parent turns it on;
  profiles private; no voice chat, ever, in M4).
- **Parent controls** from the parent's side after consent: approve friends, switch chat and online
  play, see play time (extends the parent corner). (M4 Wave 2, agent F: the grown-up area behind the
  parent gate, from SETTINGS and PLAY ONLINE; every under-13 friend request, either way, waits there
  for a grown-up's YES; play time is counted on the device only, never uploaded; the store's age
  signal only ever makes the band stricter and never blocks play.) (M4 Task 10 review: the server's
  account follows the phone's stricter band at the next read of the account, and the server never lifts
  an `under_13` account to `13_plus` from a game — the owner does it in the console on a parent's
  request; a DM, an invite and the way back into a world end when the two stop being friends.)
  (M4 Task 10 review E) Three wrong answers in a row rest every parent gate (the grown-up pages, online play, the
  Theater) for a minute, with a kind line to the grown-up saying when to try again ("Let's take a short break. A
  grown-up can try again in 42 seconds."); closing and opening the gate keeps the rest; it stays the grown-up's
  multiplication in words.
  (M5 store readiness F1, §5.14) **Photo sharing** is a parent switch too: in the grown-up area the PLAY TIME tab
  becomes **PLAY & PHOTOS** (the parent corner on this device: it needs no online account, unlike ONLINE PLAY's
  switches, and every under-13 child has none today), with "Photo sharing" ON / OFF under today's play time, saved
  at once in the profile. It starts from the band (off for `under_13`, on for `13_plus`) until a grown-up picks ON
  or OFF; the grown-up's choice then holds whatever the band.
- Written data-retention and security policies (COPPA 2025 rule); chat history 30 days (13+), quick
  phrases only for `under_13` (nothing to retain).
- (M4 Task 8b, agent G: data rights and retention, `docs/store/`.) DELETE MY ONLINE ACCOUNT in the
  grown-up area (ONLINE PLAY → the page says what goes and what stays → hold 3 s): the server deletes
  the account and everything of it (reports the child made stay without their name, reports about them
  stay for the reviewer), and the game forgets its online link while offline play goes on; a parent's
  e-mail is handled by the owner in the console (`docs/hosting.md`). The server's daily clean-up deletes
  accounts without a sign-in for 13 months, chat older than 30 days and reports 12 months after their
  review; a report about a chat message keeps a copy of that one message; the server's access log
  (addresses) is kept 14 days at most. Rulings: `docs/devlog/parts/m4-g.md`. (M4 Task 10 review F, module
  0.2.10: a reporter's rate-limit window, which names the players they reported, goes with the daily clean-up once
  their last report is an hour old.)

### 17.3 Friends and invites
- Friend requests by exact username → accept / decline; the friends list with online status (Nakama
  presence); block removes and blocks; mute; report (reviewed by a person in the Nakama console).
- **Invite a friend into your world**: the host phone runs the world and Nakama **relays** traffic
  (§7.3: `NakamaMultiplayerBridge`); up to 4 players; when the host leaves, the session ends and the
  world is saved on the host. Join from the friends list or an invite toast.
- Visiting a friend's world only while they host it.
- **Safety in the world (the M4 review's finding A, 2026-09-25):** a tap on another player's name tag opens their
  card in **every** world with other players (not only Survivor, where it also has TRADE). Online it offers
  **REPORT** (the same reasons as the friends page: mean words, scary, asked secrets, something else; they are muted
  here too) and **BLOCK** (asks first; blocked players can't message, invite or come back), friend or not. The
  **host** also gets **REMOVE FROM MY WORLD** (asks first; also online after BLOCK): online the server
  (`remove_guest`, host only) takes the guest out of the relayed match and off the invite list, and tells their
  game ("The host asked you to leave their world."), which goes to the menu without trying to rejoin; on LAN the
  host's game drops the guest's connection. Removing never deletes or takes anything of the guest's.

### 17.4 Chat (§5.13)
- Friends-only direct messages and team chat. `under_13`: quick-chat wheel and emotes only; `13_plus`:
  filtered free text (the client filter plus a server-side filter); block, report, mute everywhere.
- *As built (Wave 2, Agent E):* DMs open from TALK on a friend's row; the team room is named after the
  relayed match and the in-game chat uses it in an online match (LAN keeps the host's chat). The
  quick-chat wheel holds eight picture phrases from the server's list ("Hi!", "Follow me!", "Look!",
  "Help!", "Thanks!", "Good job!", "Let's build!", "Bye!"); it is everyone's, and under-13 players chat
  with it only. A tap on someone else's message offers MUTE and REPORT. History: only a DM between two
  13+ players with text chat is kept (the server decides), for 30 days. Rulings: `docs/devlog/parts/m4-e.md`.
- (M4 Task 10 review B, module 0.2.11) Online, the host names its players and checks its relay chat, trades and pets
  with the server's word (`match_players`, host only: each player's username, band and chat level from the account),
  never a guest's own claim; until the server answers a guest counts as under 13 and has no name, and when it can't
  say the guest is "Player" and under 13. There is no relay-chat stand-in for the team room online: when the room
  can't open, the chat says it is resting ("Chat is resting for now. Quick phrases still work!"), typed words wait
  for the room, the wheel's quick phrases still go through the host (which passes quick phrases only online, and
  nothing to or from a player whose grown-up switched chat off), and the room is tried again when the chat opens.
  LAN keeps the joining device's word (§12.11). Rulings: `docs/devlog/parts/safety-leftovers.md`.

### 17.5 Co-op
- Knocked-out players can be **revived** by a teammate (hold near them 3 s) before respawning (§5.3).
- Waves and bosses scale with the team (§12.8–12.9); bot friends fill empty seats (M2).
- *As built (Wave 2, Agent E):* with a teammate near, a knocked-out player waits up to 10 s for help
  (GET UP goes at once); a teammate holding HELP UP within 3 blocks for 3 s helps them up on the spot
  with full hearts, a ring fills and both cheer (host-decided; Sandbox and Survivor; players only).
  Waves: +50% monsters for each player or bot friend beyond the first, at most 20 (Sandbox 8). Online,
  bot friends take the seats the players leave (four in all): the newest makes room for a joining
  player and comes back later. Rulings: `docs/devlog/parts/m4-e.md`.
- Research additions: hide-and-seek with friends, a team photo after a boss, ghost races on friends'
  Game Blocks courses, buddy playdates, bottle mail between friends (preset phrases and small builds),
  blueprint gifts and read-only showcase visits.
- *Co-op games (Wave 3, agent H; research T5, T6, §13.7):* the host's pause menu → FRIENDS → GAMES
  starts a round in the host's world (LAN and online alike; every start, find and star is a request the
  host checks). While a round runs no monster comes (wild ones puff) and the Totem starts no wave or boss.
  **Hide-and-seek** (players and bot friends; at least two): one seeker (chosen, or random) sees a friendly
  counting screen for 30 s and holds still while the others hide inside 40 blocks of the counting spot
  (barrels, closets, bushes, crouching — M2's stealth rules); then the seekers find hiders by seeing them
  (the monsters' sight rules, never through walls) within 3 blocks, or by tapping their hiding spot; a
  found hider joins the seekers (nobody sits out); after 2 minutes of seeking a sparkle near a hider
  gives a hint every 20 s; the round ends when all are found or after 3 minutes. Bots hide (a free
  hiding spot within 30 blocks, else a spot out of the counting spot's sight, crouched) and seek (they
  search the hiding spots and covered places they know, with the same sight rules, walking slower than a
  child). **Storm Run** (co-op): a glowing circle of radius 40 shrinks to 8 over 3 minutes while its
  centre drifts (at most 16 blocks); stars appear inside it; everyone collects them for one team score;
  outside the circle you are gently pushed back in (no damage, nobody out); the best team score is saved
  per world. Everyone who played gets the game's **sticker** (the same for all, kept in the profile; no
  gold). **Team photo:** after a boss is beaten, a TEAM PHOTO button shows for 20 s on every game; a tap
  lines up everyone within 24 blocks (players and bot friends) facing a camera, they cheer, and photo mode
  takes the shot on each child's own game (saved like other photos; sharing only through the child's own
  share button).
- *As built (Wave 3, agent I: friends apart; module 0.2.4):* SHARE in the MORE panel (the child's own
  world, signed in, friends allowed): GIFT A BUILD (a tap picks the connected build, at most 8 × 8 × 8
  and 512 blocks, `BuildPicker`; it glows; SEND TO A FRIEND) and MY SHOWCASE (the 32 × 32 × 32 area around
  the child, from 8 layers under the feet; their buddy standing in it waits there waving). A friend's
  present opens into a stamp (the palette's GIFTS tab; Sandbox free, Survivor pays the blocks). VISIT on
  a friend's row: a small read-only island with their showcase, their name on a sign, even while they are
  away; a preset sticker for their guestbook. Bottle mail: a quick-chat phrase and maybe a tiny build
  (4³) floats up near the friend (water, else beach, else ground) and opens with a tap. Buddy playdates:
  two friends' buddies within 16 blocks wave, meet, dance and follow a little (host-decided, 10 Hz), then
  rest a minute. Guards: friends only, consent first, sizes and ids checked by the server, preset stickers
  and phrases only, REPORT on everything received (the build kept for the reviewer), everything received
  deletable, unopened things and stickers kept 60 days, all of it deleted with the account; nothing from a
  muted or blocked player is shown (a sticker note too: M4 Task 10 review G). Rulings:
  `docs/devlog/parts/m4-i.md`.
- *As built (M4 ghost races; research T2; module 0.2.6):* the child's own best run on a course they built
  travels as a **ghost**: SHOW IT takes the courses inside the showcase's frame along (one per course, at most
  3; a new own best replaces it), and GIFT A BUILD of a whole course (START and FINISH in the picked build)
  sends the race with the present. A friend visiting the showcase finds a see-through runner in the owner's
  look waiting on each START (no name for an under-13 viewer without consent: "A friend's ghost"); stepping
  off START (M3 Task 7) starts both; FINISH gives a medal against the ghost's time (its time gold, ×1.3
  silver, ×1.6 bronze) and a kind line ("You beat Mia's ghost!", "Mia's ghost got there first. Race
  again!"). A gift's race waits where its stamp is stamped in the child's own world. Ghosts never block and
  can't be touched, race on the child's own game only, and are kept on the device (offline races: PLAY ONLINE's
  FRIENDS' RACES when it can't connect). The server checks every ghost against its course (from START to
  FINISH, no faster than 40 m/s, jumps only onto START, CHECKPOINT or a teleport pad), friends only, consent
  first, 12 shares an hour; reports cover ghosts; deleted with the account; no ranking anyone else sees.
  Rulings: `docs/devlog/parts/m4-ghosts.md`.

### 17.6 Server-side codes and the farm clock (§5.6, §5.11)
- Codes are redeemed and validated by the server (once per account); the Gold Farm's time away comes
  from the server clock. (M4 Task 10 review D, module 0.2.10) At most 20 farm clocks per player (one per world;
  the game uses one per Survivor save slot): a new world's clock over that is `too_many_farms`, and that farm keeps
  the phone's clock.

### 17.7 Acceptance
- Two emulators (or an emulator + a desktop instance) play together through the relay: invite,
  join, build, fight a wave, revive, chat within the age rules; consent gates block under-13 social
  features until approved; server RPCs work; reports reach the console. Performance bar holds.

## 18. Monetization — honest, parent-facing (owner feedback #35)

The owner asked (2026-09-24) for "psychological tricks … to motivate players to spend money". **The
lead's ruling (19:52, `docs/playtests/owner-feedback.md` #35): no manipulation aimed at children.**
Tricks like countdown sales, loot boxes, fake scarcity, nagging and pay-to-win are what the FTC fined
Epic for (Fortnite, 2022), what Google Play's Families policy removes kids' apps for, and they would
break the trust promise (`docs/store/trust-promise.md`). Instead **parents pay, for clear value**.
Built by the owner-35 agent; rulings in `docs/devlog/parts/owner-35-shop.md`.

### 18.1 The rules (non-negotiable, like §6)
- A grown-up buys; the child never sees a real-money price or a buy button. Every purchase happens in
  the grown-up area (SETTINGS → GROWN-UPS), behind the parent gate (`ParentGate`), after a page that
  shows **the exact items and the price** in the store's own currency; then Google Play's own sheet.
- **Nothing random for money**; no currency for money (gold is never sold); nothing consumable; every
  product is a one-time unlock at a fixed price. Nothing sold can be earned by play (no "pay to
  skip"), and nothing sold makes anyone stronger (cosmetics and places to explore only).
- No timers, sales, "only today", streaks, rotation, fake scarcity, nags or "ask your parents"
  pressure. The one line a child may see about Plus is said **once** per profile, calmly.
- **Nothing is needed to play**; no ads, ever. What was bought stays (restored from the store's
  purchase history on a new phone or a reinstall with the same Google account).

### 18.2 Free forever
Sandbox (every block, every tool); **Survivor's first universes** (Green Meadows and the Sandstorm
Desert, with their bosses); bot friends; playing together at home (LAN) and online with friends; the
avatar editor's free set and everything earned with gold, bosses, secrets and codes; the profile backup.

### 18.3 EasyCraft Plus (one-time unlock, a grown-up buys it)
- **Every Survivor universe after the free ones**: Frostpeak, the Candy Kingdom and each universe
  added to the ladder later (the Dragon Realm…), by one rule over `UniverseRegistry.LADDER`
  (`ShopCatalog.FREE_UNIVERSES` names the free ones). Universes still open by beating bosses; Plus
  lets the child travel to the ones opened after the free ones.
- **The Plus set**: an outfit and three cosmetics of our own (Frost Ranger, Explorer Hat, Aurora
  Cape, Snowflakes trail).
- **Later, when the owner's server exists** (listed in the table, never shown or sold before they
  work): worlds saved on the server, and visiting friends' worlds while they are away.
- A locked universe card says "EasyCraft Plus"; the first time, the line under the cards (or on the
  portal) says "With EasyCraft Plus — ask a grown-up to look in the grown-up area." Never again.

### 18.4 Cosmetic packs
Fixed price each; the grown-up sees every item (picture and name) before buying; the items exist only
in their pack (avatar kind `PACK`). Sky Pack and Ocean Pack now; a slot for **Glider Looks** (when gliders
exist, M3 Task 14a). Owner #36's Storybook costumes are **earned by playing and never sold** (§14.6b; a test keeps
every costume and its parts out of every product).

### 18.5 The wish list reaches the grown-up area
In the avatar editor a child can put a pack item on their wish list (WISH, a heart). The grown-up
area's SHOP → WISH LIST shows the list with what each thing is, its price and GIVE AS A GIFT (the
same confirm page). No notification is ever sent; nothing tells the child to ask.

### 18.6 Billing
`Billing` (`core/shop/billing.gd`) is an adapter: a **fake store** for tests and debug builds (says
"Test store: nothing is charged"), and **Google Play** through the Godot Google Play Billing plugin
(MIT), **off** until the owner creates the products in Play Console, sets their ids in
`ShopCatalog.PLAY_IDS` and turns the Gradle build on (the plugin is an Android v2 plugin). Purchases are
acknowledged, pending payments open when they complete, and a hook (`ShopService.verify_receipt`) lets
the owner's server check receipts later.

## 19. Milestone M6 "iPhone" — detailed spec (on the owner's Mac)

Written 2026-09-27 by the lead, when the Android roadmap (M2–M5) was complete with release 1.0.1. The owner: "our next
job is to produce app version for iphone". The work moves to the owner's Mac (iOS builds need macOS and Xcode). The same
game, the same rules and the same server; only the platform glue differs. Start: `docs/IOS-START-HERE.md`; plan:
`docs/superpowers/plans/2026-09-27-m6-iphone.md`.

### 19.1 What stays the same
Every game rule, the English-only rule (owner #52), the child-safety rules (§5.14, §17), the online server (module
0.2.11, `https://178-104-20-64.sslip.io`), the save format, the tests. An iPhone and an Android phone play together
online (same relay, same protocol).

### 19.2 What the iPhone build needs (each behind the interface the Android build already uses)
- **Voxel Tools on iOS:** the addon ships `libvoxel.ios.*.arm64.dylib` (device only, no Simulator build): prove it
  first with a spike on a real iPhone, as M1 did on Android (risk table: "Voxel Tools on iOS unverified").
- **Rendering:** the Mobile renderer on Metal; the performance bar of §7 on a real iPhone (≥ 30 FPS, no frame over
  100 ms) in every universe and both styles; the LOW preset's weak-device rule for iPhones.
- **Screen:** landscape only; the HUD, cards and panels keep clear of the notch or Dynamic Island and the home
  indicator (`DisplayServer.get_display_safe_area`); layouts at iPhone 19.5:9 and iPad 4:3 sizes as well.
- **Photos:** SAVE puts a photo in the Photos library ("EasyCraft" album where possible; the add-only permission with a
  plain usage text); SHARE opens the iOS share sheet, still behind the grown-up's photo-sharing switch (§5.14).
- **Buying (only if the owner turns the shop on):** a StoreKit 2 backend for `Billing`, behind the same parent gate,
  products created by the owner in App Store Connect; off until then (§18).
- **Farm reminders:** local notifications for the Gold Farm (the Android `farm_notifier` rules), asking permission only
  when the child sets the farm up and never for under-13 profiles unless a grown-up allows it.
- **Age:** Apple's Declared Age Range as the iOS `AgeSignals` backend, if the lawyer asks for it; the band only ever
  gets stricter (as on Android).
- **Haptics:** the same short buzzes as Android (`Feel` currently buzzes only on Android).
- **Development server:** iOS debug builds reach the Mac's development server by its address (Android's 10.0.2.2 rule
  does not apply).
- **The Theater** stays off (its WKWebView plugin comes only if the owner turns the Theater on).

### 19.3 The App Store
The owner's Apple Developer Program membership; the app record `com.giorgi.easycraft` in App Store Connect; the age
rating questionnaire, App Privacy answers (from `docs/store/data-safety.md`), the privacy policy URL, in-app account
deletion (already in the grown-up area), screenshots for iPhone and iPad; TestFlight for the owner's testers first.
Whether to enter the **Kids category** is the owner's and the lawyer's choice (it forbids third-party analytics and ads,
which the game has none of, and asks for a parental gate before links and purchases, which the game has).

## 20. Milestone M7 "Play in the Browser" — detailed spec (owner 2026-09-27)
The owner: "can we build this game as web aplication, which will work on android, ios, mac, windows? one app for all …
something to not use app store and play store, so users can directly open in browser and play as a full game not just
in browser window?" — then "ok, lets find out and make the best possible, lets build game for browsers".

### 20.1 What it is
- The **same game, same code, same branch**, exported a third way ("Web" preset) next to Android and iOS. One web
  build serves Android phones and tablets, iPhones and iPads, Macs, Windows and Linux PCs.
- Opened from our own server (`https://<server>/play/`), no store. It can be **installed as a web app** (Android and
  desktop Chrome/Edge: "Install"; iPhone/iPad Safari: "Add to Home Screen"): its own icon, full screen, no browser bars,
  and it works offline after the first load (a progressive web app).
- The store builds stay (Google Play is close to launch; the stores are where parents look). The web build is an extra
  door, not a replacement.

### 20.2 The engine side
- **Voxel Tools in the browser:** its authors ship no web build, so we build one from the same source as our 1.7
  binaries (tag `v1.7x`, godot-cpp master of 2026-08-20) with Emscripten 4.0.20 (the version Godot 4.7.2's web templates
  were built with), as a side module for Godot's "dlink" web templates. Reproducible with `tools/build_voxel_web.sh`.
- **Renderer:** browsers get the Compatibility renderer (WebGL 2), which the game already supports (the emulator uses it).
- **Threads:** on (Voxel Tools meshes and generates on worker threads). That needs `SharedArrayBuffer`, so the page is
  served with `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.

### 20.3 What differs in the browser (each behind one platform rule, tested)
| Thing | In the browser |
|---|---|
| Controls | Phones and tablets (`web_android`, `web_ios`, or a touch screen) get the touch HUD exactly as on Android; desktop browsers get keyboard and mouse |
| Game controllers (owner #90) | A PlayStation or Xbox controller (any pad the browser's Gamepad API knows) plays the whole game, as on Android and the desktop: the browser shows the pad after its first button press, which also presses the loading page's PLAY |
| A browser that cannot run it (owner #90) | No WebGL 2 or no WebAssembly (a PlayStation's, an old TV's): a kind page ("This browser can't run EasyCraft yet. Try Chrome, Edge, Firefox or Safari on a computer, tablet or phone.") instead of a loading screen that never ends |
| Home Wi-Fi play (LAN) | Browsers cannot open that kind of connection: the LAN buttons are **hidden**, never a dead button; online play with friends works (the same server, secure WebSockets, same site so no CORS) |
| Saves | Browser storage (Godot's `user://` in IndexedDB), asked to be persistent; the online backup restores a profile. The voxel world database is flushed to storage with the rest |
| Photos | Saved as a download (the grown-up photo-sharing switch still decides SHARE) |
| Read-aloud | The browser's own speech voice |
| Quit | No QUIT button (a browser tab is closed by the browser) |
| Graphics | Starts on LOW on phones and tablets in the browser; players can raise it |
| Shop | Off, as everywhere until the owner turns it on |
| Farm reminders | None (a page can't schedule a notification while it is closed; web push is not built) |
| Shorts Theater | "Coming soon", as on phones while the channel list is the sample; the real list needs a browser video player |
| First download | Small (owner 2026-09-28): the background music and the REALISTIC style's pictures come as packs while the child plays (WebContent, kept in the browser's storage); REALISTIC keeps the pixel pictures, says they are on their way, and turns on by itself when they land (a REALISTIC child's come first) |
| Updates | Download only what changed (owner 2026-09-28: "after refresh i dont need to redownload the data"): the game's media (sounds, the core music loops, the characters) come in their own pack next to the code, before the start, kept by their content; an update that changes only code costs the code pack (~2.8 MB instead of ~11.6), a refresh nothing |

The full list, with the device run that checks it: `docs/web/parity.md`.

**As built: game controllers (owner #90, 2026-09-30).** The owner asked for the PlayStation's browser; neither
PlayStation browser can run a 3D web game (the PS5's is hidden and has no WebGL or pad input, the PS4's has no WebGL 2),
so the game meets PlayStation players another way: their **controller** plays the whole game in a PC, phone or TV
browser, on Android and on the desktop, and the PlayStation's own browser gets the kind page above. Everything a child
does has a button (the table: `docs/devlog/parts/controllers.md`; left stick walks, right stick looks, Cross / A jumps,
R2 breaks, L2 places and opens, L1 / R1 pick the block, Square / X attacks, Triangle / Y walk-fly-ghost, the D-pad flies
and opens the blocks and MORE, Options pauses, the touchpad / View opens the map). Every menu, SETTINGS, the School, the
Star Map, the shop and the pause menu move with the D-pad or the stick, a yellow ring shows the focus, Cross / A
presses and Circle / B goes back; the KEYS card becomes the CONTROLLER card with the pad's own words (PlayStation or
Xbox, by its name); on a phone the touch buttons hide while the pad plays. One rule for every platform
(`GamepadRules`), one focus keeper for every screen (`PadFocus`): docs/DEVELOPMENT.md §5 "Game controllers".

### 20.4 Privacy and children
The same privacy policy, updated to say the browser version keeps its data in the browser's storage on the device. The
page loads nothing from third parties: no analytics, no ads, no fonts or scripts from other sites, no cookies.

### 20.5 Done when
The web build loads and plays (menu → Sandbox → build, wake a buddy, walk, save and reload keeps the edit) in Chrome on
this PC and in Chrome on the Android emulator; installs as a web app; the page is live on our server; the numbers
(load time, download size, FPS) are measured and written down; the owner's iPhone check is on the owner's list.

## 21. Space: the Moon and the planets (owner feedback #55, 2026-09-28)
The owner: "when i fly up to sky, i should be able to lend on moon and other planets where there is different and new
worlds". Plan: `docs/superpowers/plans/2026-09-28-space.md`; notes, rulings and measurements:
`docs/devlog/parts/owner-55-space.md`.

### 21.1 What a child does
1. **Fly up.** In any world where flying is allowed (Sandbox flies free; Survivor pays its usual fly gold), keep going
   up. Above the highest block (y 192) the sky starts to darken and stars come out (from **y 160**, fully at the line);
   at **y 180** a line says "Keep flying up! Space is up there!".
2. **Space.** Crossing **the space line, y 200**, opens the space moment: the game holds still (solo), a starry sky,
   the child's own round planet below in its colours, and the big question **"Where shall we land?"** with big picture
   cards — **The Moon**, **Planet Boing**, **Rainbow Planet** — and **STAY HERE** (back to the sky of this world). From a
   space world the first card is **HOME** (the universe the trip started from).
3. **Landing.** A card flies there: the child arrives standing on the world's **landing pad** (a round glowing pad at
   its spawn) with a **portal home** beside it (the universe portal of owner #39, golden, with the home universe's
   swirl), a whoosh and a puff of dust, and a line: "You landed on the Moon! Jump: you float!".
4. **Coming home.** Walk into the portal home, or fly up again and pick HOME. Home, the child lands on the ground where
   they took off (not at the world spawn).

### 21.2 The new worlds (our own look, §3c; bright and friendly, never dark and scary)
| # | World | Ground and look | Gravity | Something to find and do | Friendly creatures | Sounds |
|---|---|---|---|---|---|---|
| 16 | **The Moon** | silver-grey moon dust over moon rock, round craters with raised rims, glowing pale-blue moon crystals in the craters; a black sky full of stars with the home planet (blue and green) hanging in it | **0.35** (the Physics Lab's Moon: jumps go almost 3 times as high and float down) | the **Moon Base** (a silver dome with round portholes, a chest inside); buried moon treasure, a hidden room (the Moon **is** made of cheese: its walls are cheese), a star temple, moon-crystal geodes | **moon bunnies** (new: silver-white, very floaty hops, they love cheese and moon crystals) | the Moonlight Sonata and Gymnopédie, soft wind chimes |
| 17 | **Planet Boing** | lime **boing moss** on teal soil and purple rock, round rolling hills, jelly pools in the dips, giant **spring mushrooms**; a violet sky with a ringed planet | **0.6** | boing moss, jelly and spring caps **bounce** a child who lands on them (the Candy Kingdom's gumdrop rule); the **Boing Tower** (spring caps spiral up to a chest on top); treasure, a room, a temple, geodes | frogs and goats (the jumpers) | Eine kleine Nachtmusik and Spring, a babbling brook |
| 18 | **Rainbow Planet** | terraced hills whose rock is **rainbow stripes** (red, orange, yellow, green, blue, violet), pastel prism grass on top, glowing **prism crystal** spires; a pale lilac sky with two small moons | **0.8** | the **Rainbow Arch** (a giant striped arch, a chest on its top); treasure, a room, a temple, geodes | candy birds and horses | the Waltz of the Flowers and Morning Mood, wind chimes |

- Every space world is a real, endless world like a universe: its own blocks (block pages 15-17, both graphics
  styles), terrain generator, secrets (the Secret Book counts them), sky, gravity, light, music and ambience, animals,
  loading hints and picture card; MY MAP shows its landing pad and its landmark. **No monsters come by themselves in
  space** (a friendly place; the Sandbox Totem and `/summon` still work). The day and night go on as at home.
- Worlds 19 and 20 are kept for more planets. Universes 6-15 stay the ladder's (§5.1: Glow Caves, Neon City, Lava Core
  and the remixes).

### 21.3 Rules
- **Modes.** Sandbox: fly up, free. Survivor: fly up (the fly clock charges as usual); the bag comes along and goes home
  with the child (like universe travel, `UniverseRules.carry`); a new space world gives no starter kit. Monster Wave: no
  flying, no space. Friends in the game: "Space trips work when you play alone." (like universe travel).
- **Saves.** Each space world has a save per mode like a universe (`sandbox_16`, `survivor_u16`, …); it remembers its
  home (`WorldMeta.space_home`); the home world remembers where the child took off (`WorldMeta.space_return`).
- **Free for everyone.** Space worlds are not on the universe ladder: never EasyCraft Plus, never scaled (gold, prices
  and flying cost as in Green Meadows), no universe crystals or cores (they are reached by flying).
- **Fair fun (§6):** nothing to buy, no timers, no pressure; a child is never stranded: the portal home is always free.

### 21.4 Performance (phones, §7.5)
The space moment is a 2D panel (no new 3D scene). Space generators are simpler than Green Meadows' (no caves, no water):
the generator bench (`tools/bench_generator.gd -- --space`) must show them no slower than the meadows. The sky's
climb blend re-lights the sky at most a few times while climbing (the sky updates once a second as before).

### 21.5 Rulings (the owner's rule: decide and write down; cost if wrong)
1. **The space line is y 200** (8 blocks over the highest block; about 18 s of flying from the meadows' ground).
   *Cost:* one constant (`SpaceRules.SPACE_Y`).
2. **Survivor reaches space the same way (paid flying), no rocket and no Dragon Realm gate**: the owner's words are "when
   i fly up"; flying already costs gold in Survivor, and a gate behind the Dragon Realm would put space behind Plus.
   *Cost:* a gate is one check in `SpaceRules.may_launch`.
3. **Space worlds are free** (not Plus) and **never scaled**. *Cost:* one line each in `ShopCatalog.needs_plus` and
   `UniverseRules.scale`.
4. **Space worlds are numbers 16-18** in the universe numbering (not on the ladder, whose 6-15 stay free for §5.1).
   *Cost:* renumbering needs a save migration (worlds are saved per number).
5. **Peaceful:** no night monsters in space. *Cost:* the space descriptors' `peaceful` flag.
6. **Home lands you where you took off**; the portal home stands by the landing pad. *Cost:* none.
7. **The menus list only the ladder's worlds**; space worlds are reached by flying (Save & Quit on the Moon keeps it
   saved; flying up again finds it). *Cost:* a SANDBOX/SURVIVOR card for space worlds later.
8. **Gravity is the world's** (`LabRules.world_gravity`, set by the world, times the Physics Lab's own): a player's jumps,
   falls and glides; animals and monsters keep their own hops. *Cost:* animals' gravity if they should float too.

### 21.6 As built (2026-09-28; notes `docs/devlog/parts/owner-55-space.md`)
- Worlds 16-18 are universe descriptors (`world/universes/moon.gd`, `boing.gd`, `rainbow.gd`) in `UniverseRegistry.SPACE`;
  one terrain class for all three (`SpaceShape`, `SpaceGenerator`), the landmarks as each world's ISLAND secret
  (`SpaceSecretRules`), block pages 15-17 (ids 288-330), the moon bunny. The space line and the picker: `SpaceDirector`,
  `SpacePanel`; the trip: the sandbox's section "Owner #55: space" with `SpaceTrip` and owner #39's portal home.
- Every planet's generator is cheaper than Green Meadows' (cold surface chunks 1.14-1.50 ms vs 1.63-1.71 ms); 105 tests;
  `tools/space_smoke.gd` (the whole trip in the real sandbox) 34 checks, 0 fails. The emulator check is the lead's.

### 21b The cosmos: the Star Map and the real solar system (owner #72, #74, 2026-09-29; the forever roadmap §2)
The owner: "add cosmos, stars and planets where is planet is different universe" and "make the universies closer to
real worlds so player start learning real things".

**21b.1 The Star Map** (it grows out of "Where shall we land?", §21.1). Crossing the space line opens a map of the sky,
not a row of cards:
- **Our solar system** along the bottom, in its real order out from the Sun: Mercury, Venus, Earth (with the Moon),
  Mars, Jupiter (with Io, Europa, Ganymede and Callisto), Saturn (with its rings and Titan), Uranus, Neptune and Pluto,
  sized so a child sees that Jupiter is the biggest (not to scale in distance: that would not fit a screen).
- **Far away**, across the top: the game's own planets (Planet Boing, Rainbow Planet) and **every universe as its own
  planet** in its colours (Green Meadows, Sandstorm Desert, Frostpeak, Candy Kingdom, the Dragon Realm, and each new
  one). The home the trip started from glows ("You are here").
- **Tap a planet: its card.** Its picture, its name, three real facts read aloud (for real planets: a day's length,
  gravity as "you would weigh …", the temperature on a space thermometer, a wonder; for universes: what lives there),
  then **LAND** when it can be visited, or what opens it: a universe's boss or the portal ladder (§5.1), **EasyCraft
  Plus** where the ladder needs it (§4, the shop stays off until the owner opens it), and **"Coming soon: explorers are
  building it"** for a real planet not built yet. A peek is free for every planet and universe (§4 "worth paying for
  later": the child sees what waits).
- **STAY HERE** and **HOME** as today. The map is a 2D panel over the starry sky (no new 3D scene; §21.4 performance).

**21b.2 Real planets are worlds** (space worlds, free for everyone like the Moon; numbers 19-40, `SpaceRules.LAST` 40).
Each is built like the Moon (§21.6: its descriptor, block page, shape and generator, secrets, animals none or its own
robots, sky, sounds) with **real gravity** (a fraction of Earth's), **real colours**, **real landmarks** and **its facts
to discover** (each secret found shows one real fact; the Planet Book, a page of the Books, collects them). In order:
| # | World | Gravity | What it looks like and what to find (real) |
|---|---|---|---|
| 19 | **Mars** | 0.38 | red dust (iron oxide: rust) over dark basalt, craters, dry river valleys, the polar ice cap (water ice and dry ice), a giant shield volcano like Olympus Mons (the tallest in the solar system), a canyon like Valles Marineris, a rover to find, dust devils; a butterscotch sky with blue sunsets and two small moons (Phobos and Deimos) |
| 20 | **Europa** | 0.13 | a smooth white ice crust with long reddish cracks (lineae), ice cliffs, water plumes (geysers), the ocean under the ice (a deep ice cave down to dark water), Jupiter huge in the sky |
| 21 | **Io** | 0.18 | yellow and orange sulphur plains, black lava lakes that glow, volcanoes that fountain (the most volcanic place in the solar system), Jupiter in the sky |
| 22 | **Titan** | 0.14 | orange haze, dunes of dark grains, lakes of liquid methane (swim: very floaty), icy rocks, Saturn's rings in the sky |
| 23 | **Mercury** | 0.38 | grey craters and long cliffs, the Sun three times as big as at home, burning days and freezing nights (the thermometer), ice in the dark craters at the poles |
| 24 | **Venus's cloud city** | 0.9 | Venus's surface is hotter than an oven (465 °C) and crushed by its air; about 50 km up the air is Earth-like: a floating cloud city over yellow clouds (a real scientists' idea), lightning far below |
| 25 | **Saturn's rings** | 0.05 | floating chunks of ice and rock in bands, Saturn huge below, hopping from chunk to chunk |
| 26 | **Pluto** | 0.06 | the heart-shaped plain of nitrogen ice, water-ice mountains, a hazy blue sky, Charon big in the sky |
| 27 | **Triton** (Neptune's moon) | 0.08 | pink nitrogen ice, dark geyser streaks, Neptune deep blue in the sky |
| 28 | **Ganymede** (Jupiter's moon, the biggest moon of all) | 0.15 | the only moon with its own magnetic field: auroras (glowing belts round its poles, a gentle night show); old dark cratered terrain with furrows and younger bright grooved terrain (long parallel ridges and grooves); bright ray craters (some with a pit in the middle); frost at the poles; a salty ocean deep under its ice; Jupiter huge and banded, never moving (tidally locked), Io and Europa swinging past it as bright dots; the Sun small (5 times Earth's distance) |
- The Moon keeps its playful cheese secret; its gravity (0.35) is a game choice while the real Moon's is 0.17 (its card
  says so: "In the game you jump 3 times higher; on the real Moon, 6 times!"). Ruling (cost if wrong): changing the Moon
  to 0.17 is one number, after an emulator check that building there stays comfortable.
- **No real brands or mission names** as landmarks ("a rover", "a lander", never a trademark); the facts say what real
  missions found, in general words.

**As built** (notes: `docs/devlog/parts/cosmos-mars.md`, `docs/devlog/parts/cosmos-europa.md`,
`docs/devlog/parts/cosmos-io.md`, `docs/devlog/parts/cosmos-titan.md`, `docs/devlog/parts/cosmos-mercury.md`,
`docs/devlog/parts/cosmos-venus.md`, `docs/devlog/parts/cosmos-rings.md`, `docs/devlog/parts/cosmos-pluto.md`,
`docs/devlog/parts/cosmos-triton.md`, `docs/devlog/parts/cosmos-ganymede.md`):
| # | World | Built |
|---|---|---|
| 19 | **Mars** (2026-09-29) | `world/universes/mars.gd`; `SpaceShape` MARS with `MarsTerrain`: red dust plains with craters and dry river valleys (pale beds, gypsum crystals), a shield volcano ~330 blocks north-west of the pad (rim ~70 above the plains, a caldera 12 deep, a two-step cliff at its foot, gentle flanks), a canyon ~2,400 blocks long east-west ~125 south (floor at y 30, terraced walls showing pale layers), the north cap (water ice with dust layers, wind troughs) ~600 north and the south cap (dry ice on top) ~730 south, frost near both; block page 18 (ids 336-349); the Mars Rover (six wheels, solar deck, camera mast, tracks) as the landmark; treasure, an explorers' room of basalt, an old lander's puzzle in gold foil, gypsum geodes; gravity 0.38, peaceful, no animals (`lifeless`), a butterscotch sky with a blue sunset glow, Phobos and Deimos (lumpy, no moon disc at night), the wind; a real fact in every find's words and at five sights (the volcano's summit, the canyon's floor, both caps, a river bed: `SpaceSights`, MY MAP shows the big four from the landing). Dust devils and dust storms: next. |
| 20 | **Europa** (2026-09-29) | `world/universes/europa.gd`; `SpaceShape` EUROPA with `EuropaTerrain`: a smooth white crust of ice (a 1-block step now and then) over blue deep ice in white-banded layers and the seafloor rock under y 0; three families of long reddish cracks (lineae: a trough of reddish ice, a stained ridge on each side) crossing ~16 % of the ice; the ice cliffs, a plateau ~110 across ~150-220 blocks from the pad (two cliffs of 8 with a terrace, layered faces); water plumes: geyser vents in mounds of glowing salt, about one per 200 × 200 blocks (a vent throws a child ~41 blocks up; `SpaceGeysers` puffs vapour from the ones near the child); the ocean under the ice: a well 23 blocks across ~200-265 blocks from the pad, a ramp winding down its wall from the rim to a shelf over dark water 45 blocks down, the ocean reaching on under the ice, glowing rings on its walls, open to the sky (never dark); ice blades (penitentes) and salt crystals; block page 20 (ids 368-380); the Ice Lander (four legs, a deck with lights, a melt probe in a glowing hole) as the landmark; treasure under salt, a room of deep ice, the explorers' ice station (ice bricks), salt geodes; gravity 0.13, peaceful, no animals, space's black starry sky with giant banded Jupiter (its Great Red Spot), Io and Ganymede, icy chimes; a real fact in every find and at four sights (the ocean, the cliffs, a plume, a crack: MY MAP shows the first three from the landing). The auto-step hop keeps the Moon's height in lower gravity. Chaos terrain, craters (Pwyll) and the plumes' frost: next. |
| 21 | **Io** (2026-09-29) | `world/universes/io.gd`; `SpaceShape` IO with `IoTerrain`: yellow sulphur plains (a 1-block step now and then) with orange sulphur patches and white frost (frozen sulphur dioxide) over Io's rock in layers of black lava; volcanoes, about one per 170 × 170 blocks: black lava cones 6 high with the vent in a crater on top (a vent throws a child ~30 blocks up; `SpaceGeysers` puffs yellow sulphur from the ones near the child), a ring of red sulphur round each; small lava lakes (hollows of black crust with glowing cracks, cooled); the lava lake ~180-230 blocks from the pad: a crust to walk on over hot lava, a moat of bright hot lava two blocks wide fenced by a rim of black lava rock, four causeways stepping down to the crust; **hot lava never hurts**: a warm bounce (`PadRules.LAVA_SPEED`, ~7 blocks) throws the child up and out, and a loading hint says so; the tall mountain (a tilted block of crust 40 over the plains: a gentle side, steep sides a jump each, a frosty top); sulphur crystals and lava boulders; block page 21 (ids 384-398; the last page under the items' ids, `BlockIds.COUNT` 400); the Volcano Lander (four legs, heat tiles, a heat camera on a mast, a dish, a heat probe) as the landmark; treasure under sulphur crystals, a warm room of black lava behind a fake Io-rock door, the explorers' station (sulphur bricks), sulphur geodes; gravity 0.18, peaceful, no animals, space's black starry sky with giant banded Jupiter (bigger than over Europa), Europa and Ganymede, chimes, Figaro and the Moonlight Sonata; a real fact in every find and at four sights (the lava lake, the mountain, a volcano, a red ring: MY MAP shows the first three from the landing). A lava fountain curtain, the lake's crust overturning in slow waves, Jupiter's eclipses: next. |
| 22 | **Titan** (2026-09-29) | `world/universes/titan.gd`; `SpaceShape` TITAN with `TitanTerrain`: orange-brown soil plains with patches of ice pebbles and ice boulders over icy rock (water ice as hard as stone); the methane sea ~150-180 blocks north of the pad (~230 across, 8 deep) and small methane lakes (more to the north), all filled to one level with liquid methane (the game's WATER shown amber: `liquid`, `TitanRules`; the view under it amber), a beach level with it, a gentle coast and a ring of glowing shore crystals, so a child walks out anywhere; **very floaty**: JUMP at the surface leaps a swimmer out like a dolphin (~6 blocks), and it never hurts; long east-west dunes of dark grains from ~150 blocks south of the pad on; a range of icy mountains ~200-235 east or west (a block per block up to a pale top 30 over the plains); block page 29 (ids 512-522: the first page past the items' ids 400-511, `BlockIds.COUNT` 528; gifts carry blocks up to 1023, server module 0.2.15); the Landing Probe (a round shell of gold foil and white, lamps round its rim, its striped parachute lying behind it) as the landmark; treasure under shore crystals, a hidden ice room, the explorers' station (station bricks), shore crystal geodes; gravity 0.14, peaceful, no animals, an orange haze by day (never space's black, never the photo sky) with Saturn and its rings hanging in it (the real haze would hide it: the game shows it and says nothing of it), the wind, Morning Mood and Air; a real fact in every find and at four sights (the sea, a lake, the dunes, the mountains: MY MAP shows the sea, the dunes and the mountains from the landing). Methane rain, rivers into the sea, dry lake beds: next. |
| 23 | **Mercury** (2026-09-29) | `world/universes/mercury.gd`; `SpaceShape` MERCURY with `MercuryTerrain`: grey dust plains (darker than the Moon's silver) with patches of darker blue-grey dust over grey rock; craters everywhere: small bowls with raised rims, about one in five young, its bowl and long streaks round it of bright ray dust; big craters (radius 20-28, about one per 220 × 220 blocks) with a flat floor 9 under the plains, a central peak and terraced rock walls (3 a step) up to a raised rim; long cliffs (lobate scarps: arcs of radius 150-250 whose inside is a raised slab 12-18 high with a gentle back and a face of terraces 3 high and 2 deep, fading out at the ends; the great one's face ~145-185 blocks from the pad), the words saying Mercury shrank as it cooled; the ice crater ~370-550 blocks north of the pad (a floor of shadow ice with glowing ice crystals) and ice on every big crater's floor beyond 360 blocks north or south (the poles); rock boulders; the explorers' thermometer 11 blocks from the pad (a plinth, a glowing red bulb, a tube with its red line and marks); every step 4 or less (a jump there reaches ~4.4); block page 30 (ids 528-541, `BlockIds.COUNT` 544; the realistic pages' budget rose to 48 MB); the Sunshade Lander (four legs, a silvery heat blanket, mirror panels to both sides, lamps, its big white sunshade on its sunny side, the south, where the Sun is at noon) as the landmark; treasure under ice crystals, a hidden rock room, the explorers' station (explorer bricks), ice crystal geodes; no secret on a cliff's face or in a big crater; gravity 0.38, peaceful, no animals, space's black sky with stars by day and the Sun three times as big as at home (a descriptor's `sun_size`, `SkyCycle.sun_size`, both styles), Venus, Earth and our Moon as tiny points, no moon of its own, soft chimes, Ode to Joy and Gymnopédie; its heat is a fact, never a danger; a real fact in every find and at four sights (the thermometer: 430 °C by day, −180 °C at night; a long cliff; a big crater; the ice crater: MY MAP shows all four from the landing). Hollows, the Caloris basin, a double sunrise, the thermometer's reading changing with the day: next. |
| 24 | **Venus's cloud city** (2026-09-30) | `world/universes/venus.gd`; `SpaceShape` VENUS with `VenusTerrain`: round platforms all at one deck height (y 80: every walk level) on silvery float hulls (round undersides, deepest in their middle: full of the air we breathe), white rims, joined by 3-wide bridges of honey planks with lamp posts; the landing deck (radius 20) with the pad and the cloud scope at its rim; a ring of seven ~45 blocks out: the airship dock (its mooring mast; the Research Blimp moored beyond it), the aliens' camp deck, the show deck (the Theater), the cloud homes (four little domed homes round a square), the sky garden (turf, flowers, little trees, a pond with a lamp fountain), the west lookout (a telescope looking west) and the orchard, joined by a promenade; an outer ring of groves and plazas (~100); isles every ~96 blocks far out, joined to their neighbours; the yellow clouds 40-50 blocks below (lumpy pale-yellow tops over deeper ochre clouds), never reached: a child who steps off is lifted back to the city by a warm breeze (the Dragon Realm's void with Venus's own line far over the clouds and its own words: `DragonRules.rescue_y`, `carried_back_words`), unhurt; soft silent lightning deep in the clouds (`VenusLightning`); the clouds and bridges are no dry land for spawners, the aliens camp on their deck, the Theater on its deck; block page 38 (ids 656-671, `BlockIds.COUNT` 672; the pages' budget 60 MB); the Research Blimp (a gangway, a gondola with round windows and lamps, a long white envelope with teal stripes, solar film, tail fins, a nose lamp) as the landmark; treasure under glowing cloud crystals in a deck, a hidden room in a hull behind a fake hull door, the explorers' station (home panels), cloud crystal geodes in the hulls; gravity 0.9, peaceful, no animals, a hazy golden sky of its own (thick air) with the Sun 1.4 × and rising in the west (`SkyCycle.sun_west`, `DayCycle.backwards`), Earth and our Moon as tiny points, no moon disc, the wind, Für Elise and Air; a real fact in every find and at five sights (the cloud scope: the clouds are tiny drops of sulfuric acid; the airship dock: the air we breathe floats in Venus's heavy air; the sky garden: 50 km up the air presses like home's; the cloud homes: a day longer than a year; the west lookout: the Sun rises in the west; MY MAP shows all five from the landing); Nimbus the helper robot, Nubi's and Brezz's camp; the Mission to Venus (9.4 + 3.5 + 0.5 km/s, about 5 months, a heat shield and a parachute). Every world's low Sun: its disc stays out of the painted sky until its light is full. Airships between the platforms, a slower day, the upper haze hiding the stars: next. |
| 25 | **Saturn's rings** (2026-09-30) | `world/universes/rings.gd`; `SpaceShape` RINGS with `RingsTerrain`: a strip of the rings, endless east-west, north towards Saturn: chunks of water ice floating in a thin sheet over open space (no bedrock), their flat frosty tops at slightly different heights (57-71), round rough undersides; the C ring's darker, dustier chunks (~200-300 north of the pad), the bright dense B ring (the landing chunk, radius 22, with the pad, the Ring Station (white panels, round windows, lamps, a radio dish, a glowing power pack), a Saturn model and the Saturn scope at its north rim; the camp, show, explorer and edge chunks a hop away; big chunks up to house-sized and bigger, boulders and pebbles, some of rock), the Cassini Division (60 wide: a few small darker lumps to hop on; the edge chunk's beacon), the A ring with the Encke Gap (Pan in it: a round moonlet with a dusty ridge round its middle, walnut-shaped, a beacon on top) and the Keeler Gap, the braided F ring (two wandering strands of little lumps, a chunk with a beacon), then space; gravity 0.05 (the spec's; a jump floats ~34 blocks up for ~15 s; the words say a real chunk's pull is far weaker still): a child who falls between the chunks floats down ~5 s and the space suit's little jets carry it back to the ice (the void with its own line under every chunk and its own words), never towards Saturn; open space, lumps and Pan are no dry land for spawners, the aliens camp on their chunk, the Theater on the show chunk; block page 40 (ids 688-703, `BlockIds.COUNT` 704; page 39 held for another agent's work; the pages' budget 64 MB); the Ring Explorer (a body in gold foil with a white deck, a big radio dish with a lamp on its feed, three glowing power packs on arms, a long boom, little feet; its door toward the pad, the chest inside) as the landmark; treasure under glowing ring crystals, a hidden room in a chunk's ice behind a fake ice door, the explorers' station (station panels), ring crystal geodes in the chunks; peaceful, no animals, space's black starry sky with Saturn huge over the northern horizon (~77° across: its pale gold bands, its rings edge-on as a bright line across its middle, their shadow on its clouds, its shadow cutting them past its edge: a sky planet's `dir`, `ring_edge`, `pixels`), the Sun 0.1 × (9.5 times farther than from Earth), Titan, Enceladus, Mimas and the F ring's shepherds Prometheus and Pandora, icy chimes, the Waltz of the Flowers and the Moonlight Sonata; a real fact in every find and at six sights (the Saturn scope: about 760 Earths fit inside Saturn; the Ring Station: sunlight takes 80 minutes to get here; the Cassini Division: 4,700 km wide, seen in 1675; the C ring: darker, dustier chunks; the F ring: its shepherd moons; Pan: walnut-shaped, it sweeps the Encke Gap clean; MY MAP shows all six from the landing); Hoop the helper robot, Frosi's and Clink's camp; the Mission to Saturn's rings (9.4 + 7.3 + 0.6 + 2.7 = 20.0 km/s: dips through Saturn's thin upper air slow the rocket first, about 6 years); the Star Map's Saturn card says "Saturn's rings: LAND". Ring dust glittering between the chunks, Saturn's shadow sweeping over them at night, propellers and the A ring's waves, the chunks drifting: next. |
| 26 | **Pluto** (2026-09-30) | `world/universes/pluto.gd`; `SpaceShape` PLUTO with `PlutoTerrain`: the heart (Tombaugh Regio: an exact heart shape ~400 blocks wide, its point to the south) ~70-95 blocks east of the pad; its west half the plain (Sputnik Planitia): flat pale nitrogen ice at one level in a basin, cut into cells ~40 blocks across by darker edges (the ice slowly churns like a lava lamp; flat at the game's scale, as the real cells are), floating hills of water ice (lighter than nitrogen ice: icebergs; their ice reaches twice their height down into the plain) on the cells' edges in its western part, a rim up to the uplands; its east half the bright side (methane snow, glowing frost crystals); the ice mountains (Tenzing and Hillary Montes: jumbled flat-topped blocks of water ice up to 24 over the ground, snowy tops) along the plain's south-west side ~180-260 from the pad; the red-brown lands (tholins over red-stained ice, rolling hills with methane frost on their tops, old craters with frosty rims) ~100-140 west; peach-tan uplands of frost elsewhere, water-ice boulders; every step a Pluto jump climbs (~27), the plain, its rim and the uplands one block at most; block page 41 (ids 704-716, `BlockIds.COUNT` 720; the pages' budget holds at 64 MB with 62.2 MB); the Charon Lookout 12 west of the pad (a frost-brick floor, a telescope looking west and up at Charon, a globe of Charon, a glowing heart); the Balloon Lander (legs, a gold-foil body, a white deck with lamps, a glowing power pack, a radio dish, its silvery drag balloon spread out behind it) as the landmark; treasure under frost crystals, a hidden water-ice room behind a fake water-ice door, the explorers' station (frost bricks), frost crystal geodes; no secret on the mountains or among the hills; gravity 0.063 (real: a jump floats ~27 blocks up for ~12 s), peaceful, no animals, a thin nitrogen air: black and starry overhead by day with a blue haze along the horizon and over the far ground, the Sun a very bright star (`sun_size` 0.025: 40 times farther than from Earth; `MIN_SUN` 0.025) rising in the west (Pluto spins backwards), Charon big and grey with its red cap low in the west, never moving (a sky planet's `cap`), Nix and Hydra tiny points, icy chimes, Vivaldi's Winter and the Moonlight Sonata; a real fact in every find and at six sights (the Charon Lookout: Pluto and Charon always face each other; the heart: frozen nitrogen churning in cells; a floating hill: an iceberg; the ice mountains: named for Tenzing Norgay and Edmund Hillary; the red-brown lands: tholins; the bright side: nitrogen frost carried through the air; MY MAP shows all six from the landing); kindly, a dwarf planet since 2006 and why (it shares its path round the Sun with many icy worlds: the robot's first fact, hints); Nixie the helper robot, Wisp's and Tumble's camp; the Mission to Pluto (9.4 + 8.9 + 0.3 = 18.6 km/s, about 9 and a half years, a heat shield and a parachute: the real spacecraft flew past at ~14 km/s, and the game lands the way a real study planned, slowed in Pluto's thin, tall air under a giant drag balloon; a 239-part rocket passes the check). Charon seen only from its own side, Wright Mons (an ice volcano?), the bladed terrain of methane ice, nitrogen glaciers flowing into the plain, a slower day (6.4 Earth days): next. |
| 27 | **Triton** (2026-09-30) | `world/universes/triton.gd`; `SpaceShape` TRITON with `TritonTerrain`, from Voyager 2 (1989): the pad on a bright band of fresh nitrogen frost (bluish white, over a crust of nitrogen ice over water ice: Pluto's blocks, its cousin's); the pink south polar cap from ~60-110 blocks south of the pad (nitrogen ice turned pink by sunlight on its methane, a little higher, mottled with darker patches); its geysers, at most one per 96 × 96 blocks deep in the cap (the first ~125-150 south of the pad, alone): a dark vent in a ring of dark dust, flush with the ice, a dark streak of dust from each drawn north-east by the wind (40-72 blocks, narrowing, breaking up at its end, as Voyager saw ~50 of them); the cantaloupe terrain ~105-150 blocks north-west (dimples in cells ~26 across with pale ridges between, like a melon's rind; it fades back to the band by the cap's edge far west); a walled plain ~150-190 north-east: a frozen lake of ice lava, flat, 4 under the band, with six terraced one-block steps up to a flat rim; one of its few craters ~115-140 east (a bowl dug into the nitrogen ice); water-ice boulders on the band, glowing nitrogen crystals on the cap; every step a Triton jump climbs (~21), the band, the cap, the cantaloupe terrain and the lake one block at most; block page 42 (ids 720-733, `BlockIds.COUNT` 736; the pages' budget 64 → 70 MB with 63.8 MB); the Neptune Lookout ~13 north-east of the pad (a cap-brick floor, a telescope looking north-east and up at Neptune, a Neptune globe, a blue beacon); **the geysers are a ride**: a vent is a pad (`PadRules.PUFF_SPEED`: a gentle puff ~32 blocks up, ~11 s in the air) and Triton's thin wind drifts the rider north-east until it lands (`drift_left`; it steers across the wind); `SpaceGeysers` puffs dark dust and frost from the vents near the child, drifting north-east; the Hopper Lander (legs, a gold-foil body with a rocket nozzle under it, a white deck with lamps and the chest, a big white nitrogen tank, a scoop arm at a heap of frost, a glowing power pack, a radio dish, the scorched rings of its last hops behind it) as the landmark; treasure under nitrogen crystals, a hidden pink-ice room behind a fake pink-ice door, the explorers' station (cap bricks, blue beacons), nitrogen crystal geodes; no secret on the lake, the crater or a geyser; gravity 0.079 (real: a jump floats ~21 blocks up for ~10 s), peaceful, no animals, a very thin nitrogen air: black and starry by day with a faint cold haze low down, the Sun a very bright star (`sun_size` 0.033: 30 times farther than from Earth), Neptune big and deep blue low over the north-east horizon with faint bands and its great dark spot (a sky planet's `spot_color`), never moving (Triton always shows it the same face), two small moons as points, icy chimes, The Snow Is Dancing and the Moonlight Sonata; a real fact in every find and at seven sights (the Neptune Lookout: the same face; a geyser: nitrogen gas and dark dust ~8 km up; a dark streak: the wind carried the dust up to 150 km; the pink cap: sunlight turns its methane pink; the cantaloupe terrain: a melon's skin; the frozen lake: probably icy lava of water; the lone crater: its ground is young; MY MAP shows all seven from the landing); it goes round Neptune backwards (the only big moon that does; probably caught from the Kuiper Belt, Pluto's cousin: the robot's first fact, hints); Spout the helper robot, Puffle's and Glim's camp; the Mission to Triton (9.4 + 7.4 + 0.3 + 1.4 = 18.5 km/s, about 12 years: a spacecraft flew past in 1989, 12 years after launch; the game's rocket stays by skimming Triton's thin air behind a blow-up heat shield, as a real study planned (a mission's new `skim`: a heat shield, never a parachute), then lands on its engines; a 266-part rocket passes the check). Ice volcanoes and their dark flows, the long double ridges across the cantaloupe terrain, Triton's seasons (its south pole in a summer lasting decades), Neptune's rings and more moons in the sky, a Planet Book page: next. |
| 28 | **Ganymede** (2026-10-01) | `world/universes/ganymede.gd`; `SpaceShape` GANYMEDE with `GanymedeTerrain`: the pad on a smooth plain of bright ice; the bright grooved terrain all round it (lanes ~84 across of long parallel ridges of pale ice and blue-grey grooves, a ridge every 7-11 blocks up to 2.5 high, each lane its own way, flat seams between them); the old dark terrain from ~90-125 blocks west (3 higher, brownish-grey dark ice over old dusty ice, long curved furrows round one middle far to the west, old softened craters); a young bright ray crater ~120-150 east (a bowl of fresh ice with a pit in its middle and aurora crystals in it, a low rim, 10-13 rays of fresh ice 60-100 long laid on the ground, breaking up at their ends); violet-white frost at both poles (~215-255 north, ~255-300 south); block page 43 (ids 736-747, `BlockIds.COUNT` 752; the pages 68.3 of 70 MB); built parts: the Jupiter Lookout by the pad (a telescope looking east at Jupiter, a Jupiter globe, an aurora lamp), the Aurora Watch on the northern frost (a mast with a lamp, a boom with the magnetometer at its tip), the ocean drill ~80-100 south-west (a shaft 8 deep lined with deep blue ice, its light at the bottom, a tower over it: a child jumps out); the Solar Wing Lander (legs, a gold-foil body, a white deck with lamps and the chest, two giant solar wings, a magnetometer on a boom, a dish) as the landmark; treasure under aurora crystals, a hidden grooved-ice room behind a fake door, the explorers' station (groove bricks, aurora lamps), aurora crystal geodes; none on the crater or a built part; gravity 0.146 (real: a jump floats ~11.6 blocks up for ~5 s), peaceful, no animals, space's black starry sky, the Sun 0.19 ×, Jupiter big and banded with its Great Red Spot low in the east, never moving, **Io and Europa swinging back and forth past it** (out to 23° and 39°, in front and behind: `GanymedeSky`), **the auroras: glowing belts over both poles at night** (green low, pink high, low over the northern and southern horizons from the pad, overhead from the frost, rocking slowly; NatureSky's look and the night sky's material: no new shader), chimes, Eine kleine Nachtmusik and the Air on the G String; a real fact in every find and at seven sights (the Jupiter Lookout: the same face; the grooved terrain: ridges up to 700 m from the crust stretching; the dark terrain: about 4 billion years old; the ray crater: fresh ice thrown out in rays; the polar frost: the magnetic field steers Jupiter's particles there; the Aurora Watch: the magnetic field makes auroras; the ocean drill: the salty ocean ~150 km down; MY MAP shows all seven from the landing); the biggest moon of all, bigger than Mercury, the only one with its own magnetic field (the robot's first fact, hints); Compass the helper robot, Lumo's and Ridgy's camp; the Mission to Ganymede the way the real spacecraft on its way now goes (9.4 + 3.5 + 2.1 + 2.5 = 17.5 km/s, almost 12 years: swinging past the Moon, Venus and Earth to save fuel, then past Jupiter's moons to slow down; a 209-part rocket passes the check). Palimpsests, dark-floored and dome craters, Jupiter eclipsing the Sun, Callisto, a Planet Book page: next. |

**21b.3 Order of work:** the Star Map (with every planet's card and facts, the real ones "Coming soon"), then Mars,
Europa, Io, Titan, Mercury, Venus's cloud city, the rings, Pluto, Triton, one at a time, each tested like the Moon
(`tools/space_smoke.gd`, the generator bench, the emulator).

### 21c Colonies under domes (owner #77, 2026-09-29)
The owner: "On the planets like moon, create domes for living creatures, something like [a famous rocket builder] is
dreaming, find it. same on the mars. also create portals on earth to move to cosmos".

**21c.1 The real idea** (checked against the agencies' own pages by the agent that builds it; no real person's,
company's or mission's name in the game, §21b.2): space agencies plan a base near the Moon's south pole, and rocket
builders dream of a city on Mars for many people. Homes under glass domes and inside the ground (the Moon's and Mars's
dust and rock shield people from the Sun's radiation and from tiny meteorites), greenhouses growing food under lamps,
water dug out of ice, oxygen made from water (splitting it with electricity) or from Mars's carbon dioxide air (a real
instrument on a Mars rover did it, 2021-2023), solar panels, and a big reusable rocket on a landing pad that carries
people and cargo.

**21c.2 The colony** on the Moon (16) and on Mars (19), a short walk from the landing pad and seen from it:
- **The Great Dome**: a round glass dome (about 21 blocks across) with Earth inside: green grass, a greenhouse garden
  (vegetables, fruit trees and flowers in rows under grow lamps), a pond, and **living creatures**, animals the game
  already has (bunnies, chickens, fish in the pond, bees or butterflies): the only animals on Mars, and they stay under
  the glass. The sky shows through; the light inside is warm.
- **Smaller domes joined by glass tunnels**: homes (beds, a table), a lab (a Lab Bench: the Science Lab works there),
  the water plant (ice melts into a tank), the oxygen maker (bubbles), the control room (screens, a big map).
- **Outside**: fields of solar panels, the big rocket standing on its landing pad (tall and silver, fins and legs; our
  own design), a rover garage, and the ice mine (Mars: toward the ice cap; the Moon: a crater in shadow).
- **Facts**: each part says a real fact the first time a child walks in (sights, MY MAP); the Space Book notes the
  colony.
- **Friendly**: doorways are open (the airlock is two doors in a row, pretend), always lit, never scary, peaceful; the
  world's own gravity inside (a child still jumps high).
- **Build your own**: the colony's blocks (dome glass, colony panels, greenhouse soil, a grow lamp…) are in Tilly's
  stock on those worlds.

**21c.3 No portals to the cosmos** (owner #78, the same evening: "instead of portals we have to have a mission to
mars, mission to moon"). The Star Gate first planned here is not built; the way to a planet is a mission with a
rocket the child builds (§21d).

**21c.4 Rulings** (cost if wrong): "living creatures" are plants and animals, and the idea that people could live
there (people as figures: later, with the owner's word); the colony keeps its world's gravity (one number).

**21c.5 Order**: the colonies (an agent: Mars first, then the Moon; brief
`docs/superpowers/plans/2026-09-29-colony-domes-brief.md`), then colonies on more worlds (Titan by its sea, Europa under
the ice).

**21c.6 As built** (2026-09-30; notes, the facts with their sources, rulings and measurements:
`docs/devlog/parts/colony-domes.md`):
- **Terrain, like a landmark:** `ColonyLayout` (`world/colony/`, pure) holds the colony as 1,446 boxes indexed per chunk;
  the Moon's and Mars's `SpaceShape` place it (`colony`: the Great Dome's middle 40 blocks from the landing pad, the
  airlock facing it; the Moon's opposite its landmark, Mars's north or south of the pad so its mine faces an ice cap, on
  calm plains), flatten the ground at the pad's height within 44 blocks (blended back over 12), grow nothing there and
  give Mars's plains' dust there; `SpaceGenerator` writes the boxes (no slower than the planet's own chunks); the
  landmark, the secrets and the Shorts Theater keep off it.
- **Its blocks** on page 31 (ids 544-559, `ColonyBlocks`, both styles; `tools/make_colony_page.gd`,
  `tools/make_colony_realistic.py`): Dome Glass (a clear cut-out sheet with a thin frame), Colony Panel, Colony Floor,
  Greenhouse Soil, Grow Lamp (pink), Colony Light, Fruit Leaves (oranges), Water Tank, Ice Melter, Oxygen Maker, Control
  Screen, Colony Map, Airlock Frame, Rocket Hull, Printed Regolith, Colony Table. Tilly sells them all on both worlds;
  the Gold Shop's DECORATIONS shelf sells ten dome decorations into the backpack (`ColonyRules.register_shelf`).
- **The parts:** the Great Dome (21 across: grass, the greenhouse garden in three rows under pink grow lamps, a pond 4 deep
  with fish, two orange trees, flowers, warm lights), the airlock (two striped doors, open), the homes (under printed
  regolith: three beds, a table, a bookshelf), the lab (two Lab Benches: the Science Lab opens there), the water plant
  (ice melting into tanks), the oxygen maker, the control room (a big map, screens), joined by glass tunnels; outside the
  solar panel field, the big rocket (30 tall, our own design) on its pad, the rover garage with a rover, the ice mine
  (Mars) or ice crater (the Moon) with its drill. Every doorway open, every step one block, always lit.
- **Facts:** each of the twelve parts says a real fact once when walked into (the descriptors' `sights` from
  `ColonyRules.WORDS`; checked against NASA, JPL and ESA pages); the Great Dome is the big sight ("Mars Colony", "Moon
  Colony" on MY MAP and one line of the explorer's checklist), the other parts are never marked by themselves. The Space
  Book gets no new mark (ruling 9 of the notes).
- **Living creatures:** `ColonyAnimals` brings the game's own rabbits, chickens, ducks and fish under the Great Dome when a
  child comes near (one a tick) and keeps them inside (on Mars the only animals); bees and butterflies over its grass.
- Tests `tests/*/test_colony_*.gd`; smoke `tools/colony_smoke.gd` (Mars then the Moon, 62 checks, 0 fails); the bench's
  `BENCH_COLONY_<P>` lines; pictures `tools/space_shots.gd -- --universe=19 --colony`. The emulator check is the lead's.

### 21d Missions: build a rocket, alone or with friends (owner #78, 2026-09-29)
The owner: "we have to have a mission to mars, mission to moon and etc. where you must build a ship, rocket to get into
planets, which can be built by team or alone … all things must be educational in the game, close to real world".

**21d.1 What a child does.** Every home world has a **Launch Site** a short walk from the spawn (placed like the
Theater: the seed finds flat, dry ground, never in front of the Theater; the save keeps it): a big concrete **launch
pad** (the build square), a service tower beside it, and **Mission Control**, a small building with the **Mission
Board**. The board lists missions in the real order people did or plan them: **Mission to the Moon** (3 days away),
**Mission to Mars** (about 7 months), then Europa, Io, Titan, Mercury … (each planet world that exists). A mission's
card says where, how long the real trip takes, and **what the rocket needs**, in plain words.

**21d.2 Building the rocket** on the pad, from **rocket parts** (blocks on their own atlas page, both styles):
engine (bell nozzle), fuel tank, nose cone, crew capsule (a window, seats 1), service module (air, water, power for the
crew), heat shield, landing legs, fins, stage separator (between stages), solar panel, parachute pack. In Sandbox they
are in the palette's SPACE row; in Survivor they are crafted at a workbench from iron, gold, glass and the like (the
recipes teach what each is made of). **A team builds together**: in a shared world (LAN or online) everyone may place
and break parts on the pad.

**21d.3 The check, like real rockets** (`RocketCheck`, pure rules, unit-tested): it reads the parts standing on the pad
(one stack, bottom to top, stage separators splitting it into stages) and says, with numbers a child can follow:
- **Lift-off:** the engines' push must beat the rocket's weight ("Your engines push 60 tonnes; your rocket weighs 52.
  Lift-off!" / "Too heavy: add an engine or take off a tank"). Each part has a real-ish mass (a full tank is heavy, an
  empty one light).
- **How far the fuel takes you:** the real rocket equation per stage (a stage's engines and fuel; dropping an empty
  stage makes the rest lighter), shown as a bar from the ground to Earth orbit, the Moon, Mars and beyond, against the
  mission's need (the real speed changes, rounded: Earth orbit about 9.4 km/s, then about 6 more to land on the Moon and
  come back, about 8 more to land on Mars; the exact numbers are the rules' constants, in the notes with their sources).
- **The crew:** a capsule with a seat for every astronaut (in a team, everyone who flies), a service module with air
  and water for the whole trip (Mars: months, so more), a heat shield to come home through Earth's air (and to land
  through Mars's), landing legs to land, a parachute pack where there is air (Mars, Titan).
- Every miss says why and what real rockets do about it; every part and number is in a small "rocket science" panel.

**21d.4 Launch: the child flies it** (owner #79: "you just sit into it at steering wheel and fly to moon, you actually
fly into moon, here we need real animations and visuals"). All green: the child climbs into the capsule and **sits at
the controls** (a steering wheel and a big throttle; friends take the other seats). The flight is played, not watched
(§25.3): lift-off of the very rocket they built, through the clouds, the stages falling away, into space with the Earth
below and the Moon ahead, orbit and landing. The rocket stays built on the pad at home (a copy flies). On the planet,
the **lander** stands on the landing pad: sitting in it flies the crew home the same way.

**21d.5 Going again, and flying up.** A planet reached by a mission once is **on the child's route**: the Star Map's
LAND works for it from then on (flying up past the space line, or at the Mission Board). A planet not yet reached says
**"Mission needed: build a rocket at the Launch Site"** on its card (the Star Map still shows every card and fact: a
free peek). Planets already landed on before missions existed count as reached. The playful planets (Boing, Rainbow)
stay reachable by flying up.

**21d.6 With friends.** Phase 1 (first): friends build together on the pad and see the check; the launch flies the one
who pressed LAUNCH (travel today is solo). Phase 2: the whole crew flies together (the host's world moves and the
guests follow), with a seat for each in the capsule.

**21d.7 Rulings** (cost if wrong): the rocket's numbers are real-ish, rounded for children (the rules' constants, one
table); Sandbox keeps free flying (owner #54, #75) while space needs a mission (§21e); a planet landed on once stays on
the route (one rule in `StarMap.states`).

**21d.8 As built** (2026-09-29; notes, the numbers table with sources and every ruling: `docs/devlog/parts/missions.md`):
- **Rocket parts** on block page 32 (ids 560-573: Rocket Engine, Space Engine, Fuel Tank, Nose Cone, Crew Capsule,
  Service Module, Heat Shield, Landing Legs, Rocket Fins, Stage Separator, Solar Array, Parachute Pack, and the pad's
  Pad Concrete and Pad Stripe; page 31, ids 544-559, kept empty for the colony domes; `BlockIds.COUNT` 576), both styles
  (`tools/make_rocket_page.gd`, `tools/make_rocket_realistic.py`), engines, nose, capsule, legs and fins cut out to
  their shapes, never painted. `RocketParts`: each part's tonnes (full, empty), push (tonnes-force), Isp (s), seats,
  crew-days and gold price in one table (`PRICES`).
- **The check** (`RocketCheck`, pure): the biggest piece of parts standing on the 9 × 9 build square; stages split at a
  layer with a separator; lift-off (push ≥ 1.1 × weight), the rocket equation per stage against the mission's legs, an
  upper stage pushing ≥ half of what it carries, engines needing room for their flame, space engines not in stage 1;
  the crew on the last stage (a seat each, 200 crew-days per service module, 3 legs, a solar array, an engine and fuel to
  land, a heat shield and a parachute where there is air); 3 fins; a pointed top; in the Sandbox every part bought.
- **Missions** (`MissionRules`): the Moon 15.3 km/s (3 days), Mars 16.1 (7 months, air), Europa 19.2 and Io 19.7
  (2 years 9 months), Titan 17.5 (6 years, air), Mercury 24.3 (4 months, the hardest); one way (the lander at the
  planet's pad brings the crew home, ruling 1). The route: flown (`MissionData`, in the profile, backed up) or landed on
  before (the Space Book); `StarMap.MISSION` "Mission needed: build a rocket at the Launch Site"; `travel_to_space`
  refuses a planet off the route; Boing and Rainbow fly up as before.
- **The Launch Site** (`LaunchSite`, `LaunchDirector`, `LaunchBuildings`) in every home world ~36 blocks from the spawn,
  clear of the Theater (flat open ground first, else steeper ground with its trees cleared: 25 of 25 seeds), the pad
  stamped once by the host, only over the world's own ground (never a child's build), saved in `WorldMeta.launch_site`;
  the service tower and Mission Control are models. **The Mission Board** (`MissionBoard`, `RocketBar`) opens by walking
  up to it: MISSIONS, MY ROCKET (the rocket science panel), PARTS (the shop; the Sandbox's BUY WHAT MY ROCKET STILL
  NEEDS); X, Esc and Back close it. **Parts cost gold in every mode**: Survivor's into the bag (and five simple ones
  made at a Workbench or Clay Oven), the Sandbox's kept by the profile (building free, a launch needs them bought); the
  palette's SMART page has a SPACE row. **LAUNCH** hands `{destination, cells, stages, seats}` to the sandbox's
  `fly` (the plain space trip until the flight is merged: "Mission complete! You landed on the Moon!"); the host
  launches in a shared world (everyone told), a guest from its own pad. Smoke: `tools/mission_smoke.gd`.
- **Next**: the flight (§25.3) in `fly`; the Gold Shop's rocket shelf on `RocketParts.PRICES`; crews flying
  together (phase 2: §21d.9); the lander on each planet's pad as a model to sit in; missions for Venus's cloud city, the
  rings, Pluto and Triton as their worlds are built; a mission log and crew badges (crew badges: §21d.9).

**21d.9 As built: crew flights, phase 2** (2026-09-30; owner #78 "which can be built by team or alone", #79; brief
`docs/superpowers/plans/2026-09-30-crew-flights-brief.md`; notes, 22 rulings and the net tests' output:
`docs/devlog/parts/crew-flights.md`). No server change.
- **The crew call.** The host's LAUNCH with friends in its world (LAN or online) calls them (`CrewFlights`, node "Crew"
  on every game; `CrewCall`, `CrewFlightRules`: pure): every friend gets a card, "Anna is launching to the Moon! Take your
  seat.", with TAKE MY SEAT, STAY HERE and a 10-second countdown; the pilot's card lists each answer (LAUNCH NOW, NOT
  YET). A friend who never answers comes along (ruling 2). The whole check runs with the crew counted (a seat each, air
  and water for everyone); when the takers don't fit: "3 friends want to fly and the rocket has 1 seat: add crew
  capsules!" with FLY WITH 1 FRIEND (or FLY ALONE: the first to take a seat fly) and ADD CAPSULES FIRST (the launch
  waits for everyone). Friends who don't fly go back to the menu with kind words when it lifts off ("Anna's world is
  flying to the Moon, so back to the menu for now…"). A guest still never launches the host's rocket.
- **Flying together.** Each crew member flies the pilot's flight in its own RocketFlight (the same rocket from the same
  pad; `RocketFlight.crew_follow`): the pilot's run goes to the crew 4 times a second (`FlightRun.snapshot`/`follow`:
  its step, time, action done, stages let go, burn and aim); a crew member's run catches up when behind, waits when
  ahead (never more than 1 s past the pilot's last word), acts only when the pilot did, and never holds the pilot up.
  A crew member's cockpit has no throttle, ACTION or SKIP (the dials, the view, the menu stay) and reads what the pilot
  does ("Anna lets the empty stage go!"); its inside camera sits a seat to the side. The crew in their seats: down the
  cockpit's right side each crew member's avatar sits with their name (PILOT, YOU), WAVE waves on every screen; the
  HUD's chat rides on the cockpit (typed and quick phrases on the way).
- **Landing together, home together.** Landed, the host's world moves to the destination without closing the session
  (`Session.crew_move`: the match or the LAN game goes on; the host waits up to 2 s for its guests to let go, then
  holds every hello until its new world stands); each guest ("Landing with your crew…") lets go of its link and a fresh
  guest scene joins the same match or LAN host again, straight into the host's new world: the landing's words ("Mission
  complete!"), the guide card and the postcard offer for everyone, the lander by the pad. A guest that can't follow
  within 75 s: "We couldn't follow your crew this time. Back to the menu for now!", never a hang. The host's HOME with
  friends in an away world brings them home the same way ("Back home with your crew!"); a guest's HOME goes home on its
  own ("You flew home on your own. Your crew stays on the Moon: see you soon!").
- **Everyone's mission counts.** In the destination world the host welcomes each crew member (online by its peer id,
  LAN by its crew seat's token): its own profile flies the mission (`MissionData.fly`: the route, the Space Book,
  `InviteRules.friend_landed` for a first Moon mission) and keeps a **crew badge** (`CrewBadges` in `MissionData.crews`:
  "Crew of the Moon mission with Anna and Sam", the names the world showed; one per world and crew; backed up and
  merged like the rest), shown after the landing and on the mission's card on the Mission Board. Nothing pays twice.
- A crew member whose link drops mid-flight (online) rejoins the host's world and is put back on board (its flight
  resumes at the pilot's step), or lands straight in the destination if the host landed meanwhile.
- Checks: 70 tests (`tests/**/test_crew_*.gd`, 8 files); `tools/net_test.sh --crew` (LAN and online) and `--crew --drop=close`: PASS.
- **Next**: a 3D capsule interior with the crew sitting in it, the Star Map's LAND for a crew (a landing together),
  the lander flying the crew home, the social Crews' (§25.7) crew rocket, a LAN crew member's Survivor bag carried.

**21d.10 As built (owner #98): the rocket easy to build and to buy** (2026-10-15; the owner: "its getting way way to
out of hands. so do fix that to make the rocket to build easier"; brief
`docs/superpowers/plans/2026-10-15-rocket-easier-brief.md`; notes, the plans table and every ruling:
`docs/devlog/parts/rocket-easier.md`):
- **Supplies:** a service module keeps one astronaut for the whole trip, however long (it reuses air and water like the
  space station and grows a little food): the check wants one on the top stage for each astronaut; the cards still say
  the real trip. This alone shrank the far worlds' rockets from 113-436 parts to 49-220.
- **Prices halved** (multiples of 5): engine 25, space engine 30, tank 5, nose cone 5, capsule 40, service module 20,
  heat shield 20, legs 5, fins 5, separator 5, solar array 10, parachute 15. Mission Control's Moon rocket costs 450 gold
  (about a good day of learning), Mars's 615, the far worlds' 680-1,130 for one astronaut, Mercury's 3,090 (its speed).
- **Mission Control's plan** for every mission and crew of 1 to 4 (`RocketPlan`, a stored table made by
  `tools/make_rocket_plans.gd` with the real `RocketCheck`, guarded by `test_rocket_plan.gd`): shaped like a rocket
  (centred stages narrowing upward, engines at each stage's bottom, a separator under the next stage, legs round the
  lander's engine, capsules and a nose cone on top), at most 24 layers, at least 0.05 km/s over the need. Mercury with
  3 or 4 astronauts has no plan (more than the pad's 78 first-stage engines): the board says so plainly.
- **BUILD IT FOR ME** (MY ROCKET, and under the empty-pad line): the host builds the plan for the crew here on its own
  pad layer by layer (16 cells a frame, a layer every 0.4 s, a caption and spoken line per stage), keeps a half-built
  rocket's right cells, clears stray rocket parts, never breaks a child's other blocks (it says how many to move), waits
  while someone stands on the pad; refused before the stamp, during a crew call or a flight, and on a friend's pad
  (LAUNCH's words). No XP, no undo step. Survivor takes the parts from the bag (BUY THE MISSING PARTS first).
- **Buying in one place:** BUY THE PARTS FOR THIS ROCKET under the Sandbox's paid line, a card first ("Buy 36 parts for
  450 gold?"), the exact gold still to earn ("You have 120 gold: 330 more to go. A School unit mastered gives 100 gold."),
  plurals everywhere; the board opens on MY ROCKET when the pad has parts; a grey LAUNCH says how many lines to fix and
  the first one; the mission card says the plan's parts and gold and lists every rule.
- **Bugs fixed:** Gold Shop parts and a friend's present now also wait in the backpack for the next Survivor world's bag;
  two devices' purchases add up (counts per install, `MissionData.by`); a friend's bulk buy is refused kindly; BUY keeps
  the page's place; a changed rocket makes the card ask again instead of charging a price it never showed.
- **Survivor:** Tilly sells kerosene in the first universe (10 gold): the jet and rocket inventions need no other
  universe. **Finding it:** the Launch Site is on MY MAP from the start, `/find launch`, and the Star Map's card of a
  planet that needs a mission says how far it is while the arrow points there.
- **Next:** a ghost of the plan on the pad to build by hand; the "build a rocket" Short aligned with the plan (the reels
  agent); a "buy what I can afford now" option.

**21d.11 As built (owner #106): a real landing, and what a crash costs** (2026-10-16; the owner: "landing a rocket to
the moon is simply too easy … you will have half the hearts … some parts break and have to rebuild it. But it's random.
But not catastrophic"; brief `docs/superpowers/plans/2026-10-15-moon-landing-brief.md`; notes, every ruling and the
facts' sources: `docs/devlog/parts/moon-landing.md`):
- **The landing is the child's** (every mission; `FlightDescent`, `FlightPlan.DESCENT`): after the legs come out, the
  last 120 m (falling 8 m/s) are flown on the throttle (the lever, Shift, or BURN held) against the world's real pull
  (kept between 1.0 and 3.71 m/s²; the engine pushes 2.5 times it, 40% hovers), with the lander's fuel (20 s of full
  throttle, 2 s more per fuel tank in the lander, at most 30). Touchdown at **3 m/s or less** lands (the Apollo lunar
  module's legs were built for 3.05 m/s); faster, or out of fuel above the ground, crashes. **No autopilot on the
  descent** (every earlier action keeps its own). Big dials over the dashboard: HEIGHT (m), SPEED (m/s) in green (room
  to slow down), yellow (slow down now), red (too fast) or blue (going up), the lander's FUEL; a beep that quickens near
  the ground; short words ("Slow down! Hold the throttle!", "Good: gently now.", "30 seconds of fuel left…"). The first
  try on a world is easier (80 m, 4 m/s, half as much fuel again) behind a hint card with GO. The Star Map's LAND ends
  with the same descent as a **practice** (a crash tries again; after 3 Mission Control lands it).
- **A crash fails the mission, kindly:** the crew's capsule comes home (its rescue rockets lift it, the Earth ahead, a
  fiery re-entry, its parachute down beside the home world's pad in the real world; a real fact on the way: Beresheet
  2019, Luna 25 2023, India's lander 2019 and its next one landing in 2023); the rocket falls by the Launch Site and
  **15-35% of its parts break** (at least 1; seeded per crash; engines, tanks and fins three times as likely as the
  crew's parts: `CrashRules`), gone from the pad and, in the Sandbox, from the parts owned (`MissionData.lost`, per
  device, never brought back by a merge). The child stands at the Mission Board **with half the hearts** in Survivor
  (never a knock-out, they come back by themselves), the Sandbox keeps its hearts (a knock-out costs nothing there); the world is not on the
  route. The board opens on MY ROCKET: "Your rocket crashed: 9 parts broke. Rebuild them: 120 gold." (the gold beyond
  the parts the child still has); BUILD IT FOR ME and BUY THE PARTS FOR THIS ROCKET work as on any rocket. In VR: a
  fade cut, never a shake.
- **Crew flights:** the pilot flies the descent, every crew member sees it on its own dials; the pilot's crash is
  everyone's (each flight comes home the same way, the host halves every crew member's hearts in Survivor), only the
  host's rocket breaks, no world moves.
- Checks: `tests/**/test_landing_*.gd`, `tests/**/test_crash_*.gd` (62 tests); `tools/mission_smoke.gd` (a crash, the
  rebuild, a flown landing).
- **Next:** a horizontal drift to steer over the pad (the landing spot counting), the lander's own way home flown the
  same way, a mission log of landings and their touchdown speeds.

### 21e Invent it: flying, in history's order (owner #78)
"if you want to fly you have to invent acordingly". In **Survivor**, flight is invented step by step, in the order
people invented it, each with its real story and the science that makes it work: the **kite** (China, over 2,000 years
ago: wind and a string), the **hot-air balloon** (1783: hot air is lighter than cold air), the **glider** (the 1890s:
wings lift), the **plane with an engine** (1903: the first powered flight lasted 12 seconds), the **jet** (1939), the
**rocket** (1957 the first satellite, 1961 the first person in space, 1969 people on the Moon). Each is crafted at a
workbench from real materials, teaches its principle in one card, and opens the next; the rocket opens the Launch Site's
missions (§21d). **Sandbox** keeps free flying (the owner's #54 and #75: jump taps fly); its rocket still needs the
check. Names: people of history only, never living people. More invention lines follow the same way (the wheel to the
car, the boat to the steamship, fire to electricity).

**As built** (2026-09-30; notes, the facts with their sources, 23 rulings: `docs/devlog/parts/invent-flight.md`):
- **The Inventions book** (`InventionsPanel`, its own panel; INVENT in MORE, I on a PC, MORE → INVENT with a controller):
  "How people learned to fly", a tab per invention in history's order (its picture, its year, ✓ once invented) and a
  page read aloud: when and where, the real story (people of history only: each has its death year in the table), HOW IT
  WORKS, what it opens, its School unit. The line (`InventionLine`): the kite (China, 5th century BC), the hot-air
  balloon (1783), the glider (Lilienthal, 1891), the plane (the Wrights, 1903), the jet (Whittle, von Ohain, 1939), the
  rocket (Tsiolkovsky, Goddard, Sputnik 1957, Gagarin 1961, Armstrong 1969).
- **Survivor** (`InventionRules`): nothing flies until invented ("Invent a way to fly first!"); each is made at a
  Workbench from the bag (Sticks, Planks, Iron, Coal, Glass, Kerosene; Cloth = sail cloth or a sheep's wool) for 10, 25,
  40, 60, 100 or 150 gold, free once its School unit is mastered; one opens the next. It opens: the kite a lift of about
  6 blocks on high ground, then down gently (never flying); the balloon slow flying, free, drifting with the wind; the
  glider the glide in every world; the plane fast flying that must keep moving (fuel: FlyCost's 10 gold a minute); the
  jet the fastest (20 gold a minute); **the rocket the Launch Site's missions** (`MissionBoard.gate`, the sandbox's
  `mission_gate`; the Sandbox's stay open). FLY WITH IT picks the machine (saved). No air, no wings: never on the Moon,
  Europa, Io or Mercury, nor in Mars's thin air.
- **The Sandbox** keeps its classic free flying; the book is to read and try (TRY IT and FLY WITH IT for all, FREE FLYING).
- **TRY IT** (`InventionTry`, `TryBanner`): the kite 5 s with the child's back to the wind (the wind's arrow), the balloon
  15 blocks up, one glide of 25 blocks, the plane 12 s in the air, the jet 300 blocks, the rocket a bottle rocket in the
  book (30 m); 20 gold once each (`EarnRules.INVENT_TRY_GOLD`).
- The machines (`FlightCrafts`, the Player's synced `flight_craft`; `FlightModels`, `FlightLook`: one vertex-coloured mesh
  each): the striped balloon over its basket, the 1903-style biplane, the white jet, the kite on its string. 64 tests;
  `tools/inventions_smoke.gd` 60 checks, 0 fails; `tools/invention_shots.gd` pictures. Next: the other invention lines,
  the helicopter, co-op inventing, a BOOK tab.


### 21f Robots and aliens on the planets (owner #86, 2026-09-29)
"on the planets we should have some aliens, robots as well". Our own designs (§3c), friendly, never scary:
- **Robots on every planet** (true to how people really explore space: with robots): helper robots at the landing pad
  and in the colonies (they give quests, carry blocks, point to sights and tell facts), rover buddies that follow the
  child and dig samples, drones that scout ahead, a robot guide at each landmark; they speak in short, kind lines.
- **Friendly aliens**: on the real planets they are **travelling explorers and traders like us** (a camp, a small ship,
  alien things to trade for gold), and their words stay honest ("No one has found life beyond Earth yet: scientists
  keep looking, and so do we!"); on the playful planets (Boing, Rainbow) and in the far universes, whole alien villages
  with their own homes, games and music.
- They never hurt the child; aliens can become friends (the buddy system: a friendship, a gift) and a few join the
  crew's colony dome.
- Brief: `docs/superpowers/plans/2026-09-29-space-creatures-brief.md` (after the core loop's agents).

**As built** (2026-09-30; notes, the facts with their sources, 18 rulings: `docs/devlog/parts/space-creatures.md`):
- **Every space world** (16-23): the **helper robot** by the landing pad (Lumo, Sprocket, Prism, Dusty, Glint, Ember, Haze,
  Sunny: a white round robot with a screen face, the planet's badge; `HelperRobot`, `RobotRules.helper_spot`: five steps
  front-right of the landing child, clear of the portal home, the lander, Tilly's stall, the thermometer). Its arm points
  where the HUD's compass points (the planet guide's next place; the aliens where there are no sights); it greets a child
  who comes near in a speech bubble and babble, then says the next place (never a card of its own: the guide card and the
  compass keep their jobs). A tap: its card (`CreatureCard`): its hello, the planet's first fact, the next place, and its
  **science quest** (dig a sample with the rover, explore the next place, come back and answer a question about the planet:
  EarnRules' fact quiz, 10 gold once per question right the first time; "Not yet!" and a hint otherwise). The **rover
  buddy** follows the child and digs a sample when tapped (a real fact about the ground); the **scout drone** flies ahead
  towards the next place and says how far and which way.
- **The real bodies** (the Moon, Mars, Europa, Io, Titan, Mercury): a travelling **explorers' camp** 30-50 blocks from the
  pad on calm, level plains (`AlienRules.site`; MY MAP "Explorers' Camp"): a small round ship, a telescope, a lamp post,
  the trader's table; the **explorer** (its home world always make-believe, always "No one has found life beyond Earth yet:
  scientists keep looking, and so do we!", a real fact about how scientists look for life) becomes the child's friend for
  the rover's sample (a present, and COME ALONG); the **trader** sells make-believe souvenirs for gold (also on the Gold
  Shop's DECORATIONS shelf: `SpendRules.register`, `alien:<id>`).
- **The playful planets** (Boing, Rainbow): an **alien village** (Boingaloo, Prismtown) in a clearing: four round homes,
  four drum pads, the chief and three villagers strolling; the chief's game **Echo** (`EchoGame`: a song on the drums, hop
  on them in the same order, 2 to 5 notes, a wrong drum replays the round, never a loss) makes the chief a friend.
- **Friendship is the buddy system**: a friend (`CreatureData.friends`) gives a present and may come along as a
  **mini-buddy** (`MiniRules.MINIS`' alien kinds, `BuddyMagicData.minis`, into every world, never fighting); one alien at a
  time (`CreatureData.buddy`); the friends are kept for the colony dome.
- Cheap (0.05 ms a frame for all of them on the desktop, one mesh per model, the animals' material, Pip's shiny metal for
  robots in the realistic style, asleep beyond 64 blocks); 54 tests; `tools/creatures_smoke.gd` 0 fails;
  `tools/creature_shots.gd` pictures. Next: a robot guide at each landmark, souvenirs in the dome, the far universes'
  villages.

## 22. School: grades 3 to 8 inside the game, every subject (owner feedback #68, 2026-09-28; #70, 2026-09-29)
The owner: "dont forget about school educational program implementation, at the end we should have full school
4-5-6-7-8 grade programs in the game". English only (owner #52). Plan: `docs/superpowers/plans/2026-09-28-school.md`
(with the full outline of every grade, subject and unit); notes and rulings: `docs/devlog/parts/owner-68-school.md`.

### 22.0 Learning is play, not lessons (owner #122, 2026-10-17: the authority above everything in §22)
"all lessons should be game, part of game, mini games and etc but games, not lectures and slides and classical lessons,
this is why we are not school, we are something more". The design: `docs/design/learning-is-play.md`. The School's
content (grades, subjects, goals, standards, checked facts, levels, generators, mastery) stays; its form changes: every
unit is played in the world. Seven rules: the concept is the mechanic (take the knowledge away and the game can't be
won), play first and words after, the world answers (with one line of why), shown not told when stuck (the ghost
hands), short and again and mixed, in the world and for the world (a real task checked there), words are tools (the
cards become the Book, on request). Each unit's loop: hook, try, see why, play (levels 1-3, `ExerciseCheck` the
referee, `MasteryRules` unchanged), use it in the world, come back. Two layers: G0's seven generic mechanics (Make it,
Sort it, Order it, Connect it, Fix it, Build/Code/Beat/Mix/Find it, Choose by doing and Test it) make every written
unit playable at once; the signature games (G1-G5: e.g. Fraction Bakery, Balance Altar, Array Farm, Size Magic Voyages,
Word Magic, Story Theater, Time Portals, Map Quest, Village Council) replace them family by family. For children the
menu says DISCOVER; grown-ups keep the programme's words. New units are written play-first (a `play` block). §22.1-22.4
below describe the School as built before #122; where they say cards first, §22.0 wins.

#### As built (G0, 2026-10-17, re-scoped 2026-10-18 by owner #133, #134; notes `docs/devlog/parts/play-g0.md`)
Owner #133 ("consider no one will start reading in the game") and #134 ("we need future lessons, not just texts with
visuals like slides"): `docs/design/future-lessons.md` is the authority over §5 and §8 of the design; the "every unit is
a game at once" plan above is replaced by **depth before breadth**: one deep game at a time (its five tests: choice,
mute, cheat, transfer, wow), and G0 is **the foundation** they stand on.
- **Rule 0, a child never has to read** (with the voice on, Read to me being on for everyone): every line of the play
  (the hook, each question, the coach, the world's answer, the hint) is spoken at once by itself; a big ear says it
  again; a thing says its name when touched; on the screen while a challenge plays at most 7 words (the numbers
  themselves, or the mechanic's few words), the count as dots, the buttons as pictures; the world answers, never a
  written "Correct!". Without a voice the words show, as for a reader.
- **Show, then do:** a new unit's first challenge of each mechanic is shown one step first by the coach's ghost (finger
  flat, hands in VR), then "Your turn!"; it still counts.
- **What plays (`PlayReadless`):** only an action that is the answer (make a quantity, sort, order, connect, put labels
  back, build, code, beat, mix, find) with pictures, numbers or names of at most 3 words and a question of at most 16
  words. **Written choices and true-or-false claims are never dressed as games** (Choose by doing and Test it are
  shelved, `data/play/mechanics.json` says why).
- **DISCOVER:** the map shows a game's picture on a unit only when it plays; a unit that plays (404 of 818) offers PLAY
  and THE BOOK; every other unit stays in the School as it was (LESSON, then PRACTICE), P0 with its reading debt, until
  its deep game exists. The grown-ups' page: P0 the School's own, P1 a deep game (a tooltip: how much plays).
- **The place:** one play arena (`PlayArena`, a Life room) run by `PlayHost`, flat and VR (as first built: notes §1).
  `ExerciseCheck` judges; **`SkillShown`** is the bridge from what any game saw (SOLVED, NEW_SETTING, HELPED, SHOWN) to
  `MasteryRules` (stars, the gold once, reviews, the grown-ups' page, a friend's reward, postcards, learning together);
  the School's rounds record through it too. `PlayHost.setup(…, count)` plays a short round (Play W1's crystals).
- **The reading debt** (`tools/play_audit.py`, `tools/play_debt.gd`): of 13,559 hand-written challenges 2,402 play
  without reading and 11,157 need it (written choices 5,922, claims 2,362, long questions 793, words on things 2,080);
  the Book's 6,050 cards hold 180,792 words. All 818 units are P0; the first deep games (Size Magic Voyages: Inside a
  Leaf, Balance Altar, Fraction Bakery) bring the first P1s.
- **The play block** (DEVELOPMENT.md) stays the units' format: its hook is spoken; `game` names a deep game.
- **Left for the lead:** Life's PRACTICE and TODAY'S MISSION are still questions on a panel; the in-world HUD does not
  yet show MY QUESTS; a game controller can't act on the place's things (Life's ruling 24).

**As built (W1: learning inside the world; owner #132, #133).** The owner, watching a child play 30 minutes (#132):
"there is no educational content … it should be in the game"; then (#133) "no one will start reading in the game".
W1 brings learning to where the child plays (`docs/devlog/parts/play-w1.md`). Stage 1: **DISCOVER inside the world**:
MORE's first picture (a magnifying glass) and a picture beside RESUME in the pause menu, in every world but Monster
Wave's arena, open the School over the world (as Life Town opens Life; Play G0's DISCOVER map once merged: one marked
call) and give the world back; the avatar is held and kept safe meanwhile. **Professor Hoot's invitation**: in a home
world, once the child has stood in it 20 s with nothing over it, on each world's first visit (a world seen before: at
most once a day), Hoot's card pops in (Hoot, one DISCOVER picture, a cross; top middle, never over the thumbs), his line
spoken by itself; it waits quietly and fades after 30 s; in a headset his line goes on the toast strip. No W1 screen asks
a child to read: pictures, numbers and at most four words, every line spoken, DISCOVER's word spoken when pointed at.
Stage 2: **discovery crystals** (#134: only real play): after 150 s of free play in a home world (then every 300 s; never
in a fight, a wave, a race, a round, riding, flying; a grown-up's switch on PLAY & PHOTOS), a glowing crystal rises a
few metres off on dry ground with a chime and a spoken line; walking up, a tap or a hand starts three short challenges
where the number sense is the move: MAKE (gems of place values, coins, tenths, negatives taken until the crystal shows
the number; a gem past it bounces off) and ORDER (number gems taken smallest first). It plays the child's own unit when
that unit's concept is one of these (11 units, grades 3-8), else a number challenge from the grade, and the unit is kept
on the device as "play debt" for deep games to pay. Answer gold for each solved with no miss (the School's cap); no
mastery written (G0's bridge will); untouched it fades; nothing lost. Stage 3: **the Discovery Academy** by every home
world's spawn: a 15 m tower with Professor Hoot on top and DISCOVER's glass glowing over its door, twelve gates round it
(the eleven subject families and Life), each a picture on its colour, its name spoken as the child walks up; placed by
Life Town's search after the town and the Market Square (they keep 6 of 8 and 6; the Academy stands in 7 of 8 real
meadows, 34-42 m from the spawn; no room: a small island floating over the spawn); the Maths Workshop opens a crystal's
real play at its door, Life opens Life, every other door a calm "coming soon" (a picture and a spoken line, never a list
of lessons) until its game comes; MY MAP marks it; the compass points to it until the child has been in; it glows at
night. Hoot comes in person with his invitation: he lands near the child, then flies to the Academy's top. **On Play G0's
foundation** (merged 2026-10-18): a crystal opens G0's short round (four challenges, the child's own unit when it plays
without reading, else one of the grade that does) and records through SkillShown as the School does; W1's own MAKE and
ORDER remain only where nothing in the grade plays; each subject's Academy door opens a whole round of its playable unit
("coming soon" where none plays yet); every W1 line is spoken by G0's PlayVoice.

### 22.1 What a child does
1. **SCHOOL** on the main menu (beside AVATAR and SETTINGS) opens the School: **Professor Hoot**, an owl drawn from the
   game's own owl, says hello. The first time, the child picks a grade (**4, 5, 6, 7, 8**; "about 9-10 years", …). A
   grown-up can choose and fix the grade behind the parent gate.
2. **The map.** One page per subject (**MATHS**, **SCIENCE**, **ENGLISH**): the grade's units as numbered stops, each
   with its stars (none, one, two, three) and a small "review" leaf when a review would help. A unit whose lessons are
   not written yet says "Coming soon" (its learning goals still show).
3. **A unit.** What you will learn (its goals in a child's words), **LESSON** and **PRACTICE**.
   - **LESSON:** short illustrated cards (a picture drawn from data: base-ten blocks, arrays of blocks, fraction walls,
     number lines, farms with fences, angles, shapes, rock layers…), each read aloud by its speaker; "Read to me" reads
     them by itself.
   - **PRACTICE:** a round of **6 exercises**, easy to harder, picked from the unit's hand-written exercises and its
     generators (seeded, so every round is new): **choose** an answer, type a **number** on the game's own number pad (no
     phone keyboard: digits, and `.` `/` `-` only when the answer needs them), put things **in order**, **true or false**,
     and **build the answer** with blocks on a block board (an array of 3 rows of 4, a farm with area 12 and fence 14,
     3/8 of a wall, the other half of a mirrored build).
4. **Hints, never failure.** A wrong answer says "Not yet!" with a hint and lets the child try again; a second miss shows
   how it works and the answer, then NEXT. No buzzer, no red cross, no timer. Only answers right the first time count
   towards stars.
5. **The end of a round** says how many were right the first time ("5 of 6 right the first time!"), with praise for
   effort and strategy ("You kept going and worked it out!"), and the stars the unit has now.

### 22.2 Progress and rewards (the fair-fun rules, §6)
- **Stars per unit**, never lost: ★ a round finished; ★★ a round with 5 of 6 right the first time (**mastered**);
  ★★★ mastered again on a later day (**remembered**).
- **Spaced practice:** after mastering, a review is suggested after 1, 3, 7, 21 and 60 days (a leaf on the stop, and
  PRACTICE says REVIEW). A review is never required and nothing is lost or expires when it waits.
- **Rewards (fixed, once, never random):** a unit mastered the first time gives **100 Survivor gold** (with the coin
  shower) and the unit's **badge** on its stop; a subject of a grade with every unit mastered shows its **certificate**
  on the map. No gold for opening lessons or for time spent; no streaks, no "come back" lines.
- **Where it is kept:** `ProfileData.school` (`SchoolData`): the grade, the grown-up's lock, and per unit its stars, rounds,
  answers, answers right the first time, the best round, the review step and day, the last day practised, and whether
  its gold was paid. Account-wide and offline-first (a phone or a browser without the server); the server backup keeps
  it like the rest of the profile (`SchoolData.merge_from` never loses a star or a paid reward).

### 22.3 For grown-ups
SCHOOL → **GROWN-UPS** (behind the parent gate, `ParentGate`): the child's grade (4-8) and **ONLY A GROWN-UP CHANGES THE
GRADE** (on / off); per subject, every unit with its stars, how many rounds, how many answers were right the first time,
and the day last practised; a line on what the lessons follow (22.4). Nothing is sent anywhere.

### 22.4 The curriculum (the lead's ruling, see 22.6)
- **Maths:** the US **Common Core State Standards for Mathematics**, grades 4-8 (4.NBT.1 …). **English:** the **Common
  Core English Language Arts** reading and language standards (RL, RI, L). **Science:** the **Next Generation Science
  Standards** (NGSS): grades 4 and 5 by grade, middle school (6-8) split into grades by a common integrated sequence.
- Every unit carries its standard codes (shown small on the unit page and to grown-ups). Everything a child reads is our
  own writing (no copied text); stories are our own; public-domain text only if quoted and credited.
- Metric units, time and the game's gold (no dollars or customary units); the game's own world in word problems (Tilly,
  Zara, Bram, Mimi, buddies, blocks, farms, the Moon's gravity).
- Units per grade (the full outline with goals is the plan's and `data/school/grade<N>.json`): maths 14-17, science
  9-13, English 10-13 per grade; at most 18 units per subject (the map's grid).

### 22.4b Every subject, grade 3 up (owner #70, #73, #74, 2026-09-29; the forever roadmap §1)
The owner: "when you say school part is done you lie, which subjects did you cover? did you cover all lessons tought at
school? start from grade 3 and finish all grades acordingly" and "research school programs, world leading schools and
create better shcool program". So:
- **Grades 3 to 8** (grade 3 first; grades 1-2 and 9-12 later: unit ids already allow g1-g12).
- **Ten subjects**, each its own tab and colour, in this order: maths, science, English, history, geography,
  citizenship, computing, art and design, music, health and PE (frameworks: the forever roadmap §1 and
  `docs/design/school-curriculum-research.md`). No second-language subject (English only, owner 2026-09-25).
- A grade lists the subjects it has (known ones, in the tabs' order, always maths, science and English); the map shows
  that grade's tabs: one row of big tabs for up to four, rows of five (smaller) for more; with two rows, the gold
  "mastered" words go into the page title so the map still fits the frame.
- Progress keeps up to 4000 units; the server keeps profile backups up to 1 MiB with up to 5000 keys an object (module
  0.2.14), and Nakama takes requests up to 4 MiB.
- Each new subject teaches real facts and skills with its own lessons and practice, and later its worlds (roadmap §6:
  labs, real crafts, places and history in the game's worlds).

### 22.4c As built, grade 3 (2026-09-29, agents' notes `docs/devlog/parts/m8-grade3-*.md`)
- Maths 18 units (120 cards, 329 exercises; generators g3m, g3f, g3g: 97; 13 picture kinds in
  `ui/school/school_picture_g3.gd`), science 18 and English 18 (239 cards, 576 exercises; g3s, g3e: 35 generators),
  history 10, geography 10, citizenship 11 (241 cards, 437 exercises; g3h: 9 generators). Every lesson opens with a
  memory question and ends with what comes next or a "try it in the world" idea (research §5.3).
- New practice for every grade: sort, match, "code the robot", and sounds (tunes and claps) with LISTEN.
- The School now: 817 units in the outline (grades 3-8, 12 subjects), 286 written, 3,815 hand-written exercises.
  Next: grade 3 computing, art, music, health and PE, D&T and projects (agents at work), then grades 4-8's new subjects.

### 22.4d As built, grade 4 (2026-09-29, notes `docs/devlog/parts/m8-grade4-*.md`)
- History 10, geography 10, citizenship 11 (443 exercises; g4h: 15 generators; Egyptian and Babylonian numerals),
  computing 11, art 9, music 9 (453 exercises; g4a: 18 generators; the treble stave, block code, flowcharts, the
  colour wheel, tertiary colours), health and PE 11, D&T 9, projects 3 (349 exercises; g4w: 21 generators), and the
  research's new maths, science and English units (11 units, 203 exercises; g4d, g4c: 17 generators; the circuits,
  heat and states units match the Science Lab's experiments). Every grade 4 unit of the outline is written.
- Grades 5-8 next, subject group by subject group (the reusable brief `2026-09-29-school-subjects-brief.md`).

### 22.4e As built, grade 5 (2026-09-29, notes `docs/devlog/parts/m8-grade5-*.md`)
- History 10, geography 10, citizenship 11 (467 exercises; g5h: 16 generators; Olympiads, BC and AD, Roman and Maya
  numbers, latitude and longitude, time zones), computing 11, art 9, music 9 (428 exercises; g5a: 25 generators; loops
  and procedures on a pen, spreadsheets with formulas, perspective, chords heard as chords), health and PE 11, D&T 9,
  projects 3 (371 exercises; g5w: 35 generators; first aid DR ABC, medicines and harmful substances factual and only
  in that unit, gears, pulleys, cams, bridges), and the research's 12 new maths, science and English units (210
  exercises; g5c: 32 generators; percentages, angle facts, forces and machines, circuits, life cycles, breathing and the
  heart, quoting to prove, opinion writing, speaking and presenting). Every grade 5 unit of the outline is written.
- A number exercise whose answer is a year says `"year": true`: the pad and the worked answer show 1850, not 1,850.
- Grade 6 next, subject group by subject group; then grades 7 and 8.

### 22.4f As built, grade 6 (2026-09-29, notes `docs/devlog/parts/m8-grade6-*.md`)
- History (the medieval world) 10, geography 10, citizenship 11 (248 cards, 465 exercises; g6h: 28 generators;
  timelines, quipus, the feudal pyramid, castles, grid references and contours, climate graphs, river courses, layer
  maps, savings; 11 picture kinds in `SchoolPictureG6Hum`). Hard history named with respect, never shown (Lindisfarne,
  Hastings, Baghdad 1258, 1453, Benin 1897, the Spanish conquest, the Black Death, the Peasants' Revolt), listed for
  grown-ups in the notes. Next for grade 6: computing, art, music, health and PE, D&T, projects, and the research's new
  core units.
- Computing 11, art 9, music 9 (232 cards, 487 exercises; g6c: 31 generators; binary, pixels and light, logic gates,
  pseudocode with REPEAT UNTIL, spreadsheet models, passwords and phishing, learning from examples; tessellations,
  two-point perspective, layered prints, lettering; key signatures, intervals, the 12-bar blues, syncopation, variations,
  instruments of the world, frequency and timbre heard: SchoolSound gains volume and tone; 25 picture kinds in
  `SchoolPictureG6Arts`). Next for grade 6: health and PE, D&T, projects, and the research's new core units.
- Health and PE 11, D&T 9, projects 3 (184 cards, 369 exercises; g6w: 40 generators; FITT and the talk test, formations
  and tactics, the crouch start and the relay's 30 m zone, analysing a skill, food as fuel and 5 A DAY, mental health and
  the five ways to wellbeing, box breathing and the circle of control, respect and asking first, smoking, vaping and
  alcohol factual and only in that unit, FAST, burns and the CPR beat, Naismith's rule; user-centred design and ACCESS
  FM, biomimicry, trusses and the five forces, lever classes, moments, linkages and gear ratios, sensors and thresholds,
  the food danger zone, cooking on a budget, material families, Arts and Crafts and the Bauhaus; a market town, a
  weather station and a design for a real need; 18 picture kinds in `SchoolPictureG6Health`). Next for grade 6: the
  research's new core units.
- The research's last maths, science and English units (104 cards, 234 exercises; g6k: 43 generators): the
  problem-solving toolkit (Polya's four steps; draw a model, work backwards, a systematic list, guess and check, a
  pattern), skeleton and muscles, nutrition and digestion (food tests, enzymes), classifying life (five kingdoms,
  vertebrates and invertebrates, keys, Linnaeus), light travels (shadows by similar triangles, the law of reflection, a
  periscope, a pinhole camera), energy changes (Sankey diagrams and efficiency), engineering design (criteria and
  constraints, decision matrices, the Wright brothers' wind tunnel), reading closely, arguments with counterclaims,
  informative and narrative writing, research and sources (paraphrase, plagiarism, a source list), discussing and
  presenting (a speaker's pace and volume heard); 18 picture kinds in `SchoolPictureG6Core`. Every unit of grade 6's
  outline is written now. Next: grades 7 and 8.

### 22.4g As built, grade 7 (notes `docs/devlog/parts/m8-grade7-*.md`, `school-g7-dt-hpe-projects.md`)
- Health and PE 11, D&T 9, projects 3 (2026-10-17; 184 cards, 380 exercises; g7w: 49 generators; 14 picture kinds in
  `SchoolPictureG7Life`): advanced tactics, racket sports and their scoring, heart-rate zones, dance styles,
  officiating and tournaments, teenage sleep, influences and adverts, self-image and edited photos, drugs and the law
  (factual, only in that unit, no street names), resolving conflicts, where to get help; product analysis, CAD and CAM,
  electronic circuits and the resistor code, microcontrollers, technical textiles, food of the world, less food waste,
  a product's life, prototyping; a voyage, an eco-district and a mini business. Owner #112 and #117 (learn by doing): a
  unit whose topic is a Life Experience ends by naming it in the LIFE tab (Calm Corner, Little Lifesaver, Fire Escape,
  Safe Streets, The Kitchen, Real Builder, My Money Stall, the Tool Book). Grade 7 has all twelve subjects and all 136
  units (its last 14 below, 2026-10-17); what comes next is play (§22.0, owner #122), not more cards.
- Maths, science and English: the research's last 14 units (2026-10-17; notes `m8-grade7-core.md`; 103 cards, 272
  exercises; g7k: 40 generators; 18 picture kinds in `SchoolPictureG7Core`): primes, powers and estimates; speed,
  distance and time; graphs that mislead; the periodic table; mixtures and separating; acids and alkalis; light and
  colour; the air and the carbon cycle; strong evidence; fiction and history; speeches and media; arguments with
  counterclaims; explaining like an expert; point of view in stories. Ten end by naming their Life or Success
  Experience (My Money Stall, Safe Streets, Success Stories, Electricity Safety, The Poisons Cupboard, Fire Escape,
  Talk & Deal). Every one of grade 7's 136 units is written now; grade 7's next units come from the forever roadmap.

### 22.4h As built, grade 8 (notes `docs/devlog/parts/m8-grade8-*.md`)
- Grade 8 started with maths, science and English. History 10, geography 10, citizenship 11 (2026-10-17; 248 cards,
  470 exercises; g8h: 64 generators; 10 picture kinds in `SchoolPictureG8Hum`): the modern world 1745 to today (hard
  history listed for grown-ups), global issues, and citizenship with money (tax, loans, interest, investing as maths,
  never advice). Computing 11, art and design 9, music 9 (2026-10-17; 232 cards, 472 exercises; g8c: 46 generators;
  27 picture kinds in `SchoolPictureG8Arts`): bigger programs, algorithms compared, logic gates, databases, how
  machines learn, cyber security (the game's own log-in rules as examples; networks taught inside it), design for
  users; Impressionism to public art, animation, an exhibition; Romantic to 20th-century music, jazz, producing a
  track, sight-reading, a composition project (64 exercises to listen to). No living people, no brands. Units whose
  topic is a Life or Success Experience end by naming it in the LIFE tab (15 humanities, 8 arts).
- Health and PE 11, D&T 9, projects 3 (2026-10-17; 184 cards, 364 exercises; g8l: 60 generators; 10 picture kinds in
  `SchoolPictureG8Life`): game strategy and match statistics, fitness testing and profiles, active for life, mental
  health (anxiety, low mood, thinking traps, getting help), bouncing back, respect online (consent, private pictures and
  the law, Report Remove), chance and gambling (factual, only in that unit), alcohol, vaping and peer pressure (factual,
  only in that unit, no street names), CPR and defibrillators, a health campaign, digital balance; from brief to
  product, smart and modern materials, a programmable product, mechanical advantage, big structures, nutrition, food
  production, circular design, future technology; an invention expo, a history documentary and a global goal campaign.
  Owner #112, #115 and #117 (learn by doing): 22 units end by naming a Life or Success Experience in the LIFE tab
  (Little Lifesaver, Calm Corner, the Poisons Cupboard, Earth and Weather, The Kitchen, Real Builder, My Money Stall,
  the Goal Board, Talk & Deal, the Connections Book, Success Stories, the Tool Book). Grade 8 has all twelve subjects
  and all 136 units (its last 14 below, 2026-10-17); next: grade 9, written play-first (§22.0, owner #122).
- Maths 2, science 6, English 6: the research's last 14 units (2026-10-17; 112 cards, 225 exercises; g8k: 37
  generators; 12 picture kinds in `SchoolPictureG8Core`): expanding and factorising (a parabola drawn from its
  equation), sine, cosine and tangent (a right-angled triangle named from its marked angle, a ladder and a ramp);
  pressure in solids, liquids and gases (floating and upthrust), energy, power and bills (kWh, the electricity
  counter's readings, gold prices), hot and cold reactions (energy level diagrams, bonds), current, voltage and
  resistance (series and parallel circuits with ammeters and voltmeters whose readings follow from Ohm's law),
  transport in plants and animals (xylem and phloem, the heart's chambers, an air sac), breeding and genes (selective
  breeding, genetic engineering and the questions it raises); the strongest evidence, old stories in new versions,
  arguing with counterclaims and credible sources, explaining with headings and graphics, a narrative with a
  flashback, presenting with slides (clear and crammed) and sounds to judge a talk's pace and a mix. Nine units end
  by naming a Life or Success Experience in the LIFE tab (Real Builder, Water Safety, Electricity Safety, the Poisons
  Cupboard, Little Lifesaver, Medical Emergencies, Talk & Deal, Success Stories). Grade 8 is written in full (136
  units); its 39 older maths, science and English units are under the quality bar (the audit's 51-73) and can be
  raised as grades 3-7's were; then depth, and grades 1-2 and 9-12 (the forever roadmap §1).

### 22.5 How it is built
- **Data:** `data/school/grade<N>.json` is a grade's outline (subjects → units: id, title, goals, standards, the content
  file when written); `data/school/g<N>/<subject>/<unit>.json` a unit's lesson cards, hand-written exercises and the
  generators it uses. Generators are GDScript (`core/school/gen/`), seeded.
- **Pure rules** (`core/school/`, unit-tested): `Curriculum` (loads and checks the files), `SchoolData`, `MasteryRules`
  (stars, reviews, the reward once), `ExerciseCheck` (every type's checker), `NumberAnswer` (exact values: whole numbers,
  decimals, fractions, negatives), `NumberPad`, `BuildCheck` (the block board's goals on any set of cells, so a build in
  the world can be checked the same way later), `RoundPlan`, `SchoolSpeech` ("3/4" is read "3 fourths"), `NumberWords`.
- **UI** (`ui/school/`): `SchoolScreen` (the pages, inside the menu's panel, 1180 × 636, so it fits 1280 × 720 and every
  wider phone), the map, the unit page, the lesson cards, the exercise panel and its answers, the round's end, the grade
  picker, the grown-ups' page; `SchoolPicture` draws every picture from its data (UI draw calls and block icons only).
- A **content test** runs every hand-written exercise and thousands of generated ones through their own checker (a valid
  answer that is right, wrong choices that are wrong, a board goal with a solution that fits), checks every unit of the
  outline, and keeps guilt, pressure and other games' words out of the lessons.

### 22.6 Rulings (decide and write down; cost if wrong)
1. **Curriculum framework: Common Core (maths, English) and NGSS (science).** They are the most widely used
   English-language standards written grade by grade for 4-8, public, with codes a parent or teacher recognises, and
   they are used by many international schools. Cambridge Lower Secondary was the alternative (international, but
   stages 7-9 only for ages 11-14 and a different grade mapping). *Cost:* units are data; another framework is new codes
   and a few units moved by one grade.
2. **Three subjects: maths, science, English.** No national history (the players are worldwide); world geography sits in
   the science units about Earth. *Cost:* a fourth subject is one entry per grade file.
3. **British spelling in the game's own words** (the game's voice: "colour", "favourite", "maths", "metre"), US standard
   codes. Spelling exercises never test words spelled differently in the US and the UK. *Cost:* a spelling pass over the
   data files.
4. **Metric, time and gold; no customary units or dollars.** *Cost:* one extra unit per grade for schools that want them.
5. **School opens from the main menu first** (offline, every platform, no world loading); a School building with
   Professor Hoot in the worlds, in-world build challenges and school quests come later on the same screens and checkers
   (plan). *Cost:* none: `SchoolScreen` is a Control an in-world building can open unchanged.
6. **The in-world exercise type is the block board** (`build`): the game's building on a grid inside the lesson, checked
   by `BuildCheck`, which takes any cells (the world's later). *Cost:* the world version is a later step.
7. **Mastery = 5 of 6 right the first time; remembered = mastered again on a later day; reviews at 1/3/7/21/60 days.**
   *Cost:* constants in `MasteryRules`.
8. **100 Survivor gold once per unit mastered**; nothing for the Sandbox purse (its gold is endless). *Cost:* a constant.
9. **The child picks the grade and may look at other grades; a grown-up can fix it** (then the grade picker says a
   grown-up chose it). *Cost:* one flag.
10. **Professor Hoot the owl** is the teacher (drawn from the game's owl). *Cost:* one constant.
11. **The menu loads the School's script only when SCHOOL is pressed** (the start stays as fast as before, §15.3).
12. **The server backup's merge line** (`out.school.merge_from(other.school)`) is left to the agent building profile sync
    (the owner's split: this agent never touches the sync); until then the newer profile wins as for every field.

### 22.7 As built (2026-09-28; notes `docs/devlog/parts/owner-68-school.md`)
- The framework (22.5) and the whole outline: 201 units in `data/school/grade4.json` … `grade8.json`, each with its standards
  and goals. **Grade 4 written:** maths complete (17 units: 71 lesson cards, 143 hand-written exercises, 86 generators),
  science "Rock layers and fossils" (6 cards, 13 exercises, 3 generators), English "Stories: characters and theme" (our own
  story of Juno and her tiny buddy Wick; 7 cards, 12 exercises) and "Words that sound alike" (5 cards, 11 exercises, 2
  generators over our own 31 sentences). Grades 5-8 show their units as "Coming soon" with their goals.
- 15 picture kinds drawn from data; five exercise types (choice, true or false, number on the School's pad, order, build on
  the block board); Professor Hoot is the game's owl in a drawn square cap.
- The content test runs every hand-written exercise and every generator (120 seeds × 3 levels) through its own checker;
  the generators' answers are checked against arithmetic done in the tests.
- Left to the profile-sync agent or the lead: `out.school.merge_from(other.school)` in `ProfileBackup.merge` (ruling 12).

## 23. Learning worlds: the Science Lab (owner #74, 2026-09-29; the forever roadmap §6)
The owner: "make the universies closer to real worlds so player start learning real things, real crafts, real
allsubjects, we need more labs, more eduction, more secrets, more excitments". The Physics Lab (§14.3) changes how the
player moves; the **Science Lab** is a place to do real experiments with the game's own blocks.

### 23.1 What a child does
- **The lab bench** is a block (a white bench with a glass flask and a tiny burner: our own look). The Sandbox has it
  in the palette; Survivor crafts it (planks, glass, iron) and finds one in some villages' houses. A tap on the bench
  opens **the Lab**: a page of experiments (big picture cards), each tied to the School's units.
- **Every experiment has the same three steps**, the scientist's way (research §5.3, NGSS practices): **1. Predict**
  ("What do you think will happen?", choose one), **2. Try it** (the child does it with blocks from the bag or the
  bench's own supplies, and sees it happen), **3. What happened and why** (a card, read aloud) and the result goes into
  **the Lab Book** (a page of the book: each experiment's prediction, result and a star when done; never a mark for a
  wrong guess: "Scientists guess wrong all the time; that is how they learn!").
- **The first experiments (v1):**
  1. **Float or sink** (g3 science materials; buoyancy): drop blocks into the bench's water tank one by one; wood, ice,
     a leaf and a sponge float, stone, iron, gold and glass sink. Sort your predictions first.
  2. **Magnetic or not** (g3.science.magnets): hold the magnet to blocks from the bag: iron and steel stick; wood,
     glass, gold, copper and stone do not.
  3. **Melting and freezing** (states of matter, g4/g5 science): warm ice on the burner: ice → water at 0 °C, water →
     steam at 100 °C, on a big thermometer; cool it again.
  4. **Mixing colours** (art and light): paint colours mix (red + yellow = orange, blue + yellow = green, all together:
     brown) and light colours mix (red + green light = yellow, all three: white).
  5. **A fair test: what do plants need?** (g3.science.plants_needs): plant three seeds on the bench's shelf: one with
     light and water, one in the dark, one without water; come back after two game days and see.
  6. **A simple circuit** (g4 science circuits): battery, wires, a bulb and a switch on a small board; a gap stops the
     light; add a second bulb.
- **From the School:** a unit with an experiment shows **TRY IT IN THE LAB** on its page; from the Lab, **LEARN MORE**
  opens that unit.

### 23.2 Rules
- Free in every mode (never EasyCraft Plus), no timers, no failing: every experiment can be done again; supplies of
  the bench are endless in the Sandbox and cost a few ordinary blocks in Survivor (the child's own).
- Per device and in the profile (`WonderData` or its own field): the Lab Book's pages, backed up like the rest.
- Safety words: the burner is a lab burner used with a grown-up; nothing teaches fire at home.

### 23.3 How it is built
- Data first: `data/lab/*.json` (an experiment: id, title, units, predict {prompt, choices}, steps, result words, why
  card), checked by a content test like the School's; the Lab screen and each experiment's small 2D scene are UI (like
  the School's pictures: drawn from data, no new art files); the bench block on a free atlas page.
- More experiments come as data (roadmap §6: pottery in a kiln, smelting, dyes from plants, bread from wheat, paper
  from wood, weaving, glass from sand: the **crafts**; then sound and pitch with the music room, light and shadows,
  rocks and soils, weather station).

### 23.4 As built (2026-09-29; notes `docs/devlog/parts/science-lab.md`)
- **The lab bench** is block 352 (`BlockIds.LAB_BENCH`, `COUNT` 353) on atlas page 19 (`LabPage`, ids 352-367; drawn by
  `tools/make_lab_page.gd` and `.py`): a white bench, a shelf with a flask of green liquid and a tiny burner, teal knobs.
  The Sandbox palette's SMART page (HOME row); Survivor crafts it at a Workbench (3 planks, 1 glass, 1 iron) and finds one
  in some village houses (against the back wall); never painted. A tap opens the Lab over the world (`LabPanel`).
- **The six experiments** are data (`data/lab/index.json` and one file each), checked by `test_lab_content.gd` (the facts
  against numbers held in the test; the School's word lists); their scenes are six kinds of pure models (`core/lab/`)
  drawn in code (`ui/lab/`). The prediction is a School exercise form (choice, or a sort of the scene's things) that is
  never marked; the why is three cards read aloud.
- **The Lab Book** is `ProfileData.lab` (`LabData`: guesses, runs and stars, the plants' planting; merged by the backup
  without loss) and the book's seventh tab, **LAB**; the plants grow over two game days of 20 minutes on the device's
  clock. Survivor's supplies (1-3 ordinary blocks) come from the host's bag; a guest's bench is free for now.
- **From the School:** TRY IT IN THE LAB on the page of every unit an experiment lists (the Lab inside the School's frame);
  LEARN MORE opens the unit of the child's grade (or the nearest below).

## 24. The world's wonders, all of them (owner #78, 2026-09-29)
"next thing we must have world wonders, all wonders in the game". Earth's own worlds get a range of their own (41-60,
`UniverseRules.MAX_UNIVERSE` 60): **41 Wonders of the World**, a friendly Earth world where the wonders stand along a
world tour, each at a scale a child can walk round and climb, each with its real story, its facts at sights and a stamp
in the **Wonders Passport** (a page of the Books):
- **The Seven Wonders of the Ancient World**: the Great Pyramid of Giza (the only one still standing), the Hanging
  Gardens of Babylon (no one knows for sure they existed: the game says so), the Temple of Artemis at Ephesus, the Statue
  of Zeus at Olympia, the Mausoleum at Halicarnassus, the Colossus of Rhodes, the Lighthouse of Alexandria; the lost ones
  as people believe they looked, and the words say which are gone.
- **The New Seven Wonders** (chosen in 2007): the Great Wall of China, Petra, the Colosseum, Chichen Itza, Machu Picchu,
  the Taj Mahal, Christ the Redeemer (culture and history, §22.4 safety: religion as culture and belief).
- **Wonders of nature** (the seven natural wonders and more): the Grand Canyon, the Great Barrier Reef, Victoria Falls,
  Mount Everest, the harbour of Rio de Janeiro, the Paricutin volcano, the northern lights; then more (the Amazon, the
  Sahara, Ha Long Bay).
- **Wonders people built later** (a second tour): Stonehenge, the Eiffel Tower, the Sydney Opera House, the Panama
  Canal and more, never a company's brand.
- **Getting there**: first from the Star Map's Earth card ("Wonders of the World: LAND"); when flight is invented (§21e),
  by a mission with a plane from the Launch Site.
- The School links: history and geography units say "Visit it in the game" for a wonder they teach.
Built by agents, a tour at a time (brief `docs/superpowers/plans/2026-09-29-world-wonders-brief.md`): the ancient
seven first, then the new seven, then nature's.

**As built, the first tour: the Seven Wonders of the Ancient World** (2026-09-30; notes
`docs/devlog/parts/wonders-ancient.md`): Earth's own worlds are numbers 41-60 (`EarthRules`; `UniverseRules.MAX_UNIVERSE`
60), a trip away like a space world (`SpaceRules.is_away`: their own saves `sandbox_41` / `survivor_u41`, a home, the
portal home, never scaled, never Plus). **World 41, Wonders of the World** (`world/universes/wonders.gd`): the Star Map's
Earth card says "Wonders of the World: LAND" (a whoosh down, no rocket; the plane's hook `EarthRules.way_there`); Earth's
gravity, sky, animals and weather, peaceful; a flat park round a paved landing square (seven signposts, paths out) that
blends into Green Meadows' own land beyond radius 190, a sea to the north-east with a beach, olive trees to the west,
palms on the sand (`WondersShape`, `WondersGenerator`: no caves under the tour). The seven, seed-free round the square
(`WonderTour`, `WonderBuilds`), in our own blocks (pages 33-34, ids 576-597: limestone, casing stone, granite, marble,
fluted columns, scrolled tops, a carved band, bronze, ivory, gold leaf, ebony, Babylon's yellow and blue glazed bricks,
the beacon fire, white stone, paving, the wonder plaque, a water screw, olive leaves): the **Great Pyramid** (45 wide, 29
courses at the real slope, the entrance on the north face, the corridor, the Queen's Chamber, the Grand Gallery, the King's
Chamber of granite with its stone box; climbable outside), the **Hanging Gardens** (four terraces with gardens, palms and
trailing plants, stairs to a pool on top, arches into a vaulted gallery, a water screw and a channel), the **Temple of
Artemis** (89 marble columns in two rows, facing west), the **Statue of Zeus** in its temple (6 × 13 columns; ivory and
gold on an ebony throne, his head just under the roof; galleries up stairs), the **Mausoleum** (36 columns, a stepped
roof, four horses and a chariot), the **Colossus** (bronze, legs together, a torch as people imagine it) and the
**Lighthouse** (three tiers on an island at the end of a causeway, stairs and a spiral up to the fire). Each is a sight
(`WonderSights`): reaching it says its real fact (which are gone; that no one knows the gardens existed; religion as what
people believed) and stamps the **Wonders Passport** (`WonderData.wonders`, the Books' WONDERS tab); the explorer's card
and the red arrow lead the tour (`WondersDirector`); a plaque by each opens its card and **fact quiz** (EarnRules'
`fact_quiz`: +10 gold a question right the first time, once). A secret at each ends with a real fact (the pyramid's hidden
room over the Grand Gallery, the gardens' cool room, the temple's treasury, Phidias's workshop, the Mausoleum's tomb room,
treasure by the Colossus, a chest by the lighthouse's fire: `WondersSecretRules`). The generator is cheaper than Green
Meadows' over whole stacks (`tools/bench_generator.gd -- --wonders`); `tools/wonders_smoke.gd` 61 checks, 0 fails. The
emulator check is the lead's. Next: the New Seven Wonders, nature's, the plane.

**As built, the second tour: the New Seven Wonders** (2026-09-30; notes `docs/devlog/parts/wonders-new-seven.md`): in
the same world 41, their own region round the **New Seven's square** (`WonderTour.NEW_SQUARE`, 350 blocks west of the
landing square) at the end of the **Wonders Road** (3 wide, sand, straight west, speed pads across it past the first
park, a signpost on each square; nothing new in the landing spot's view: its draws went from 225 to 214 a frame), its ground `NewSevenGround` (flat, with the Great Wall's ridge, Corcovado and Huayna Picchu;
Petra's desert; no caves). The tours are data (`WonderFacts.TOURS`: the ancient seven, the New Seven); the explorer's
card lists both side by side, MY MAP marks the new square and all fourteen, the passport shows each tour under its
heading, the fact quizzes cover both (three questions each for the New Seven). Our own blocks on pages 36-37 (ids
624-641: wall brick, rose rock, rose stone, rose column, travertine, Maya stone, Maya carving, serpent head, jaguar throne,
Inca stone, soapstone, inlaid marble, Mughal red stone; five fakes). The **Great Wall** (grey bricks along a ridge, its
walkway rising and falling, a low parapet inside and battlements facing north, five watchtowers the walkway passes
through, a beacon fire, a stair up), **Petra** (a weathered rose cliff, the Siq winding to a court, the Treasury's facade
with six columns, pediment, tholos and urn, its chamber, a stair cut in the rock to a ledge by the urn), the **Colosseum**
(an oval of arches in three storeys and a top storey, broken to two on the south side as today; the sand arena, tiers
rising round it, a corridor under them, four entrances, stairs up the tiers), **Chichen Itza** (El Castillo: nine terraces,
a stair up each side, the feathered serpent's heads at the foot of the north stair, the temple on top), **Machu Picchu**
(six terraces with a stair up the middle, stone houses with thatched roofs, the Temple of the Sun on its rock, the Temple
of the Three Windows, the Intihuatana, Huayna Picchu behind), the **Taj Mahal** (the red sandstone gate, the garden with
its long pool and cypresses, the plinth, the tomb with a great arch on each side, the hall with the two tombs under a
lamp, the onion dome with its golden top, four kiosks, four minarets, one hollow with a spiral stair, the river behind to
the north) and **Christ the Redeemer** (40 steps up Corcovado, the summit's terrace, the pedestal, the soapstone statue
with its arms spread wide, facing the square). A secret at each ends with a real fact (the watchtower's store room, treasure
by Petra's urn, the tunnels under the Colosseum's arena, the pyramid inside El Castillo with its red jaguar throne, the
cave under the Temple of the Sun, treasure at the top of the Taj Mahal's minaret, the room in the statue's pedestal).
Religion as culture and belief; hard history (forced labour on the Great Wall, enslaved gladiators and builders, the
Spanish conquest) named with respect, never shown; people of history only. `tools/wonders_smoke.gd` visits both tours
(95 checks, 0 fails). The emulator check is the lead's. Next: nature's wonders.

**As built, the third tour: the Seven Natural Wonders** (2026-10-01; notes `docs/devlog/parts/wonders-nature.md`): in
the same world 41, a region of its own round the **nature square** (`WonderTour.NATURE_SQUARE`, 442 blocks south-south-east
of the landing square, its nearest edge past the landing spot's view) at the end of the **Nature Trail** (a dirt trail 3
wide, speed pads past the first park, a signpost on each square; nothing new in the landing view: its draws 220 → 215 a
frame). The ground is the wonders (`NatureGround`, seed-free: heights and kinds per column, a round sea in the
south-east, snow in the west; the generator writes the kinds itself and keeps each chunk column's samples); what people
built there is `WonderBuildsNature`. The **Grand Canyon** (a plateau with a canyon about 40 deep cut into it, its walls
in the real layers from the dark Vishnu schist to the pale Kaibab rim, the Colorado River in its bottom, three buttes, a
lookout, a glass walk over it, a trail down a side gully to the river, a granary in the cliff), the **Great Barrier
Reef** (a coral cay in a shallow reef flat of brain coral, staghorn coral and sea fans, a jetty, a glass tube down into a
glass room on the reef, Endeavour's cannon), the **Harbour of Rio de Janeiro** (a round bay with islands opening to the
sea, a promenade, Urca and the Sugarloaf rising from the water, a ridge of steps to its lookout), **Mount Everest** (88
over the park with Lhotse and the South Col, base camp's tents and prayer flags, a stair of packed snow up to Camp IV on
the col and along the ridge to the summit, its rock a sea fossil), the **Northern Lights** (a snowy valley with pines, a
frozen lake, a cabin, a deck and ice lanterns; at night curtains of green, pink and violet light sway over it:
`NatureSky`, drawn with the night sky's star material, no new shader), **Parícutin** (a cinder cone in its cornfield,
glowing lava in the crater behind a ring of rock, the church tower of San Juan in the black lava field) and **Victoria
Falls** (a river pouring 24 blocks into a narrow basalt chasm, split by a buttress and Livingstone Island, spray rising
as "the smoke", a rainbow by day, a rainforest path along the far lip, a stair down to the pool). Each is a sight with
its real geology and life (how the canyon was carved, corals and their algae, why Everest grows, what makes the
northern lights, a volcano born in a cornfield in 1943, the smoke that thunders), a stamp (a third passport heading, 21
stamps), a card ("formed" in place of "built"; "A wonder of nature") and a quiz; a secret at each ends with a real fact
(the granary, the cannon, the climbers' ledge, the summit's fossil, the ice cave, the tower room, Livingstone Island).
Safe adventures only (the game's lava bounces, glass walks and rooms, no drowning, no fall damage); religion as culture
and belief (prayer flags, the church's altar); people of history only. Blocks on page 37's free ids 642-655 (no new
page). The emulator check is the lead's. Next: the wonders people built later, more of nature's.

## 25. The core loop: learn and invite to earn gold, buy and build the rocket, fly it yourself (owner #79, 2026-09-29)
The owner: "next the most important parts, to earn golds you have to solve puzzles and lessons or invite someone new
into game, so we need referal links and whole refereal system … at the end if you have sufficient gold you can build a
rocket or space ship to get into another planets. when ship is built, you just sit into it at steering wheel and fly to
moon, you actually fly into moon, here we need real animations and visuals" and "remember this into plan this is very
important". This loop is the game's spine; everything else hangs on it.

**25.1 Gold from learning and puzzles.** The School already pays 100 gold for a unit mastered (once). Also: gold for
each first-try right answer in a round (a few gold, a daily cap so it never becomes a grind; never for opening a lesson
or for time, §22), for the Science Lab's stars, for the worlds' puzzles and secrets (each find pays once), for a
wonder's or a planet's fact quiz. The numbers are one table (`EarnRules`), tuned so the Moon's rocket takes a few days
of learning and Mars's a few weeks.

**25.2 Invite a friend** (the referral system). Every player has an **invite code** (kid-safe words and a number, e.g.
BLUE-OTTER-42) and an **invite link** (the web game `…/play/?invite=CODE`; the Play Store link carries it as the
install referrer; a code can also be typed at the start or in SETTINGS). Sharing uses the device's own share sheet or
copies the link: the game never reads contacts and never asks for a friend's name, email or number. A **new** player
who joins with a code gets a welcome gift; the inviter gets **gold when the new player has really played** (for example
their first School unit mastered, or play on two different days), so empty accounts pay nothing. The **server** decides
(Nakama module: codes, who invited whom, the reward once per new player, a cap per month, never your own device or
account, a new account only); the inviter sees "Your friend NAME joined and learned! +N gold" (the in-game name only).
A note for the owner's lawyer goes in `docs/store/` (a refer-a-friend reward in a children's app: Google Play's
Families policy, COPPA: no personal data of the friend is collected).

**25.3 The rocket costs gold, then the child flies it.**
- Rocket parts (§21d.2) are bought with gold at the Launch Site in every mode (the rest of Sandbox stays free); the check
  (§21d.3) still decides whether it flies.
- **Sit and fly**: the camera moves into the capsule: the window, the dials (speed in km/s, height, fuel per stage, the
  distance to the Moon counting down from 384,400 km) and the controls. LAUNCH: the countdown, the engines' fire and
  smoke, the pad shaking, the rocket rising; the child steers (tilt, a gentle turn; the autopilot keeps it safe: never a
  crash, kind corrections) through the clouds, the sky turning black, the first stage falling away, the Earth's curve
  then the whole blue Earth with its clouds behind, the Moon growing ahead with its real craters and seas; into orbit
  round the Moon, the engine burn to slow down, the landing legs out, dust on touchdown at the landing pad, then the
  Moon world, the child stepping out. About 2-3 minutes of play, the real numbers on the dials (the trip itself takes 3
  days: the words say so). Mars: the same with the long cruise shown in a few seconds and a fiery entry through its air
  with the heat shield and the parachute.
- **Movie-style moments** (owner #86: "on the space ship we should have visuals from different movies"), in our own
  look: the jump to light speed (stars stretching into lines, a flash), a warp tunnel, a wormhole's swirl, flying through
  an asteroid field and a coloured nebula, glowing cockpit screens and a hologram of the destination; never a film's
  own ships, logos, sounds or music (only CC0 or our own).
- **Real animations and visuals**: particles for fire, smoke and dust, the camera's shake, the Earth and Moon as real
  spheres (their own textures made by us or CC0), stars, the Sun's light; in both graphics styles; within the
  performance budget (≥ 30 FPS, no frame over 100 ms on the emulator).
- Friends: phase 1 builds together and one flies; phase 2 the whole crew flies in their seats (built: §21d.9).
- **As built** (2026-09-30; notes `docs/devlog/parts/rocket-flight.md`): `RocketFlight` (`entities/flight/`, the cockpit
  `ui/flight/`). The sandbox's `fly_rocket(rocket)` (the missions' `fly`) flies RocketStages' description from its pad:
  the camera glides into the capsule, the countdown (10 … 1 spoken, the engines lit at 3), LIFT-OFF on the throttle (a
  lever, Shift, or the big button; the autopilot after 5 s), the rise from the real pad (fire, smoke, the shake, the
  launch camera), the clouds' white-out into the flight's own space (the Earth a sphere with turning clouds, the sky
  black, the gravity turn, steering into the green ring), STAGE (the empty stage falls away with a puff), orbit at 7.8
  km/s, the burn toward the destination, the trip (the Moon: its 3 days in 22 s, the Earth a marble behind, the Moon's
  real seas and craters growing ahead; farther: light speed, a warp tunnel, the asteroid belt, a wormhole through the
  game's own portal swirl, a nebula, each with true words), the turn round and burn into orbit (or a fiery entry and
  CHUTE where there is air), then the landing (DEORBIT, LEGS, the ground rising, the engine's dust, touchdown on the
  pad), `landed` and the world loads with the lander by the pad (this session). Owner #87: the Star Map's LAND plays
  the same landing on its own first (~14 s, the sandbox's `land_on_space`; SKIP on a repeat visit). The dials (km/s,
  height, the distance counting down from 384,400 km, the trip's real clock, fuel per stage), the hologram, the wheel,
  the aim with kind hints ("Nudge left to aim at the Moon!"); the autopilot never lets the child fail. Keys on a PC
  (WASD or the arrows, Shift, Space, V; the KEYS card), big buttons and a drag on a phone. The developer menu's FLY
  ROCKET, `--fly-moon`, `--fly=<world>`, `--land=<world>`. 89 tests; `tools/flight_smoke.gd` 24 checks, 0 fails; the
  emulator's frame rate is the lead's check.

**25.5 What gold buys** (owner #83: "gold is good to buy new things and unlock new exciting lessons to learn, new
planets, new weapons, parts for rocket and spaceships, and many many other things"). One **Gold Shop** (a page of its
own, and Tilly's stall in the worlds) with shelves:
- **Explorer lessons**: new, exciting lessons beyond the School's grades (how rockets work, volcanoes, dinosaurs, the
  human body, codes and ciphers, the wonders' stories, deep space …), each a School unit marked `bonus` with a price.
  **The School's own grade units stay open to every child, free** (the owner's goal is every child's education, #82):
  ruling, cost if wrong: one flag per unit.
- **Rocket and spaceship parts**: the way to new planets (§21d: a planet opens by flying a mission to it).
- **Weapons** (the game's own: Survivor's swords, bows and the like, §3b), **tools** for quests and mining (§26: a
  metal detector, a gold pan, an ice drill), **avatar and buddy things**, **decorations** for the dome, the base and the
  crew wall.
- Prices in one table (`SpendRules`), with EarnRules (§25.1) so the first rocket part is a day of learning away, the Moon
  a few days, Mars a few weeks; new shelves as the game grows (#71).

**25.4 Order** (the plan, 2026-09-29): (1) the earning and the invite system (brief `2026-09-29-earn-invite-brief.md`),
(2) the missions: the Launch Site, the parts bought with gold, the check (`2026-09-29-missions-brief.md`), (3) the
flight (`2026-09-29-rocket-flight-brief.md`), then the colonies (§21c), the wonders (§24), invent it (§21e).

**25.6 As built: earning, inviting, the Gold Shop's frame** (2026-09-29; notes `docs/devlog/parts/earn-invite.md`;
server module 0.2.16; the lawyer's note `docs/store/refer-a-friend-note.md`).
- **EarnRules** (`core/economy/earn_rules.gd`, one table): +5 gold for a School answer right the first time (at once:
  "+5 gold: right the first time!"; 150 a day at most, then "That's all the answer gold for today…"), the unit's 100
  once, +25 for a new Lab star; the worlds' secrets and puzzles pay once each as before (LootRules); hooks for the first
  secret of each kind (50) and fact quizzes (10). Never for time or for opening things. A day of learning ≈ 275 gold.
- **Invites** (`core/invite/`, `ui/invite/`, server `referral_rules.ts`, `referrals.ts`): a code of two kid-safe words and
  a number for every claimed account (typed any way), the link `…/play/?invite=CODE` (the web page keeps it across its
  redirect), INVITE A FRIEND on the main menu (the code, COPY LINK, SHARE in a browser with a share sheet, the game's own
  QR code, the friends by their in-game names, the Explorer Tree's count, the rank, the month's friend gold, the grown-ups'
  line), the code box after the name at the start and in SETTINGS (a code without the internet waits for the next
  sign-in). The server: a new account (under 14 days) only, never its own code, once; the welcome 100 at once; when the
  friend masters their first unit the inviter 250 and the friend 50 (both win), the inviter's inviter 25 (two levels,
  never named); a first Moon landing 150 (`InviteRules.friend_landed`, for the missions); rolling 30-day caps (10, 20,
  10); news on a card; class and family codes (behind the parent gate; counts only, never names); deletion removes it
  all. Explorer ranks at 1, 3, 5, 10, 25, 50, 100 friends who learned (Mentor … Wonder Maker: things to show).
- **SpendRules and the GOLD SHOP** (`core/economy/spend_rules.gd`, `ui/shop/gold_shop.gd`): EXPLORER LESSONS (units
  marked `"bonus": true` with a `"price"`; open for good; the grade's own units stay free), ROCKET PARTS and DECORATIONS
  (empty shelves with the hook `SpendRules.register`), WEAPONS & TOOLS (Tilly's price in the highest universe opened; the
  backpack comes into the next Survivor world), AVATAR & BUDDY; HOW TO EARN. The first Explorer lesson: "How rockets
  work" (grade 4 science, 150 gold, 14 exercises).
- Not yet (later briefs, hooks in place): the rank rewards themselves, the Android install referrer (typed codes for
  now), the first-secret bonus's wiring. Postcards, the Daily Mission card, gifts, crews and friendship levels: §25.7.

**25.7 As built: the Daily Mission, postcards, presents, friendship levels, study buddies, crews** (2026-09-30; owner
#81, #82, #85; brief `2026-09-30-daily-mission-brief.md`; notes `docs/devlog/parts/daily-and-friends.md`; server module
0.2.18).
- **The Daily Mission** (Wordle's lesson): TODAY'S MISSION on the School's map; 5 questions from the grade's subjects (the
  grade's generators first, a unit's own exercise where it has none), easy to harder, **the same for every child of a
  grade** on a UTC day; a star per answer right the first time, 10 gold a star once a day (EarnRules' `daily` line); the
  result card (the date, the grade, the stars as pictures, "Today's Mission: 4 of 5!", "Play and learn with me!", the invite
  code and link, never an answer) with SHARE, COPY and SAVE PICTURE and "Grown-ups: share today's mission card…"; mission
  days that never go down and a week of stars and rest days ("Rest days are fine"); STOP keeps the answers (the same
  mission all day). Its finish tells friends this child learned today.
- **Postcards** at proud moments, offered once: a unit or a grade's subject mastered (the School's round end: MAKE A
  POSTCARD, a drawn picture); a first landing, a mission, a wonder's stamp, a deposit found (`PostcardOffer`, the hook the
  lead wires to the flight and the other agents' moments: a photo of the world, "I landed on the Moon!"); SAVE PICTURE,
  SHARE, COPY; the words and the invite link only. The moment also goes to friends to cheer.
- **Presents** a friend opens in the game (a rocket part: a Fuel Tank; seeds: Wheat and Flowers into the backpack; a
  buddy egg: a secret buddy shape not found yet, or pet treats; a treasure map piece, kept for the prospecting quests);
  one a day to each friend, 5 a day; one can wait on the invite code for the next new friend; THANK YOU gives the sender
  10 gold (5 a day).
- **Friendship levels** by days together (learning the same day, a present, a cheer; once a day per pair; never falling):
  Good friends (1 day: a friendship badge), Great (7: a two-seat rover to drive together), Best (30: a shared room in the
  colony dome); the rewards are hooks. **Cheers** for friends' proud moments, kind words only (six, never typed).
  **Study buddies** (at most 3): the shared goal is both learning something each day; their days together only grow, the
  week's row shows rest days calmly.
- **Crews** of 2-6 friends: a name from two kid-safe word lists and a badge (never typed), invitations to friends, the
  crew page (each member's avatar and what each learned this week, never a ranking), the weekly goal (3 learning days a
  member, together); the crew rocket and crew flights come with the missions (hooks: the crew's id and members).
- Everything between mutual friends on the server (ids and kinds only: nothing personal), server-only storage, deletion
  forgets the player everywhere; friends' news on the main menu's card once.

## 26. Prospecting and mining: the real world's riches, found by quests (owner #80, 2026-09-29)
The owner: "we should have minnings on planets and on eath, where we find preious metals, petrols and other things like
a real world has. to find such places you need find them with quests which include solving problems, quizes, maps,
advantures, findings and other exciting things".

**26.1 Real resources where the real world has them.** Beside the game's scattered ores, each world hides **rich
deposits** in the places real geology puts them: gold (in quartz veins, and as flakes in rivers below them), silver,
copper (with its green stain), iron ore, aluminium ore (bauxite, red earth in warm lands), coal (old swamp forests),
**oil and natural gas** (old sea floors, under a dome of rock), salt (dried-up seas), diamonds (deep pipes of old
volcanoes) and gems. **On the planets:** the Moon's ice in craters in shadow, its titanium-rich dark rock; Mars's ice
under the dust and its iron-rich red rock; Europa's salts; Titan's methane seas; the rocky planets' metals.

**26.2 Found by quests.** A deposit is found, not stumbled on: a **prospecting quest** (from Tilly, a geologist at the
Launch Site, or an old map found in a secret) teaches a real clue at each step: read a map (coordinates, compass
directions, the scale), follow the river's gold upstream, look for the rock that goes with the treasure, solve a problem
(the echo survey: the echo's time gives the rock layer's depth; a metal detector's beeps), a short quiz with the facts
learned, an adventure to reach it (a canyon, a cave, a frozen crater on the Moon). The quest's last step marks the
deposit on MY MAP.

**26.3 Mining and refining, as people really do it.** A deposit is worked with the right tool: a mine (a shaft and
tunnels for a vein), panning (gold in a river), a quarry, an **oil well** (a derrick drills, a pump jack pumps), an ice
drill on the Moon and Mars. What comes out is refined in real steps: ore smelted to metal (iron, copper, aluminium with
electricity), oil refined into fuels (the kerosene rockets burn: the core loop's **rocket fuel**), plastics, salt for
food; on the Moon and Mars, ice melted to water and split into oxygen and hydrogen (air and rocket fuel, the real plan).
Each step shows one real fact.

**26.4 In the core loop** (§25): refined riches sell for gold at Tilly's (a fair price table) or go into the rocket
(fuel, metal parts). Quests pay gold too, like the School's lessons. Deposits are finite but new quests always find more
(the game never ends, #71).

**26.5 Order**: Earth first (gold, copper, iron, coal, oil and salt in Green Meadows and the Desert), then the Moon's and
Mars's ice (the colonies' water, §21c), then the rest (brief `2026-09-29-prospecting-brief.md`).

**26.6 As built: Earth** (2026-09-30; notes `docs/devlog/parts/prospecting-earth.md`; block page 35, ids 608-623).
- **Deposits** (`DepositRules`, written by the terrain generators with the secrets): each 512 × 512 region of Green
  Meadows (old and wild) holds a gold (gravel at the water's edge below a hill, a quartz vein in the hillside), an iron
  (rusty rock on a hilltop over banded iron) and a coal deposit (a seam in a hillside under fern shale); each region of
  the Sandstorm Desert a copper (malachite on a mesa's edge over copper ore), an oil (a seep on the flank of a dome 1-3 km
  down) and a salt deposit (a white crust over rock salt on level ground). 130-470 m from the spawn over the seeds tried;
  never on a secret or a place; the same for a seed.
- **Gemma the geologist** at her camp 21-26 blocks from the spawn (walk up; DIG in MORE; J on a PC): six quests of 7
  steps each: a map of this world to read (which way, how far by the scale, which square), walks the compass points
  along, the sign found up close (a real fact), a problem (the flakes' doubling, 1% copper, the detector's beeps, 10 m of
  plants to 1 m of coal, the echo's depth, grams of salt a litre) or a clue, a quiz of School exercises, and MARK IT on MY
  MAP. 100 gold the first time a quest is finished, 20 for each later find (up to 100 a day); the exercises pay the
  School's answer gold. An oil quest stands an oil well (derrick and pump jack): 40 drums of crude oil into a Survivor
  bag. The Gold Shop's Metal Detector (150) beeps near metal. A LAN guest prospects in its own world.
- **Mining and refining** (Survivor, the Craft Book, a fact each): panning, the Clay Oven's smelting (gold, copper, iron,
  salt), drying salt, a Refinery (crude oil → kerosene, plastic). Tilly buys table salt, crude oil, plastic, copper and
  kerosene at fair prices and sells none of them. **Kerosene is the rocket's fuel hook** (`RefiningRules.ROCKET_FUEL`).
- Next (the brief's order): the Moon's and Mars's ice and metals (their kinds, sites and quests; an ice drill on the Gold
  Shop's shelf), then the rest of §26.1 (silver, aluminium, gas, diamonds, gems; Europa's salts, Titan's methane).

**26.7 As built: the Moon and Mars** (2026-09-30; notes `docs/devlog/parts/prospecting-space.md`; block page 39, ids
672-687). Living off the land (in-situ resource use) is the lesson.
- **Deposits** (`DepositRules` → `SpaceDepositSites`, written by SpaceGenerator with the secrets): each 512 × 512 region of
  the Moon holds its ice (icy regolith on a deep crater's floor: the Moon's world is the land by its south pole), an
  ilmenite sea (dark mare dust on low, crater-free plains, black ilmenite glinting, a lens of it under), a helium-3 sea
  (the widest, oldest mare dust), KREEP rock on a big crater's rim and an iron meteorite in a small crater (its lump
  standing out of the dust); each region of Mars its ground ice (a small fresh crater in the mid-latitudes, ice under the
  dust round it), hematite blueberries (plains by an old river bed), dark iron-rich sand (a big crater's floor), salt
  (a low, level basin) and an iron meteorite lying on the plain. 130-470 m from the landing pad over the seeds tried;
  never on the colony's ground, a secret or the landmark.
- **Gemma the space geologist** (a spacesuit, a little habitat, an ice drill) at her camp 21-26 blocks from the landing
  pad, off the colony: the planet's own five quests (a board tells its place's quests: Earth's six, the Moon's five,
  Mars's five), 7 steps each like Earth's; the crater quests walk to the rim, then down to the sign. Problems of real
  numbers (350 degrees between sun and shadow, 40% oxygen in Moon rock, 20 mg of helium-3 a tonne, 1,200 km a minute,
  120 litres for a crew, 4 mm blueberries, 24 oxygen atoms), clues, quizzes (the ice's chain in order: dig, melt, split,
  fly home). The planet guide's compass follows a quest's walk first. No real mission's name.
- **Living off the land** (Survivor, a fact each, nothing burns): the colony's Ice Melter (ice → water), its Oxygen Maker
  (water → hydrogen fuel or oxygen; ilmenite → oxygen), a Solar Oven (Tilly: 30; mirrors and sunlight: dust → the
  colony's Printed Regolith bricks, ilmenite → titanium, mare dust → helium-3, KREEP → rare earth powder, meteorites,
  hematite and dark sand → iron, Mars salt → oxygen); blueberries sieved by hand. **The hydrogen fuel made from ice
  pays toward the next rocket** (Tilly: 4; `RefiningRules.SPACE_FUEL`; the rocket's parts stay bought with gold).
  Titanium, helium-3 and rare earth powder sell at Tilly's too; water, air and bricks help (never sold). The Gold Shop's Ice Finder (150) clicks
  near ice; the Metal Detector hears meteorites.
- Next: the rest of §26.1 (silver, aluminium, gas, diamonds, gems; Europa's salts, Titan's methane, Mercury's ice); a
  trip home that needs the fuel made there would be the missions' (a home leg).

## 27. Life skills: everything a child needs in life, learned by doing (owner #112, #113, 2026-10-16)

The owner: "we use a game to educate children, teach them everything they need in life not only school ... especially
now when we have VR ... teach them real life skills, this is the future of education" (#112); "the game should be
intuitive, children should understand everything easily ... parents should be excited how fast children learn ... maybe
later i will buy 20 vr and setup separate lessons ... this is not just a game, this is educational platform" (#113).

The design, its evidence and its plan: **`docs/design/life-skills.md`**. In short:
- **Life**, the second pillar beside the School: ten areas (body and health, feelings, people, staying safe, life
  online, money, home and everyday, getting around, thinking and the future, our world), each skill on a Little (6-8),
  Middle (9-11) and Big (12+) track chosen by the child or a grown-up.
- **Experiences:** each skill is done, not read: a reason, the real steps with hands (VR) or taps, kind feedback, a card
  that names the steps (the authorities' own words, sources kept), spaced repeats, a **Try it for real** card for home,
  three stamps in the **Life Passport** (Done it, By myself, Expert).
- **Easy means obvious:** ghost hands show, the next thing glows, one thing at a time, every line read aloud, the same
  controls everywhere, the coach steps in after ~10 s stuck; first-time success measured and designed for.
- **Parents see it:** before-and-after checks, a weekly "your child can now...", the child shows the grown-up.
- **Safe and calm:** practice framing, no injuries or scares, always a way out and a good ending, the region's emergency
  number and traffic side, nothing personal kept or sent, careful topics only with experts and a grown-up's choice,
  expert review before each flagship ships, safety and health never paid.
- **The plan:** L1 the Life tab, the Passport, the grown-ups' Life page, the Experience framework, **Little Lifesaver**,
  **Fire Escape**, **My Money Stall**; later, when the owner says (#114: "the future, not now"), C1 **EasyCraft Classroom** (a
  teacher's console for ~20 headsets: class codes, live progress, Pause all, the class report, lesson plans); L2 Safe Streets (with the cars), The Kitchen, Calm Corner, Life
  Town; L3 and L4 the rest (§5 of the design).
- **Success, Life's second strand (owner #115):** "skills school dont deliver ... how to be successfull, business,
  trading, money, comunications, connections, everything to be sucsessfull". The design, its evidence and its plan:
  **`docs/design/success-skills.md`**. Eleven families on the three tracks (money mastery, business, trading and
  markets, communication, connections, negotiation and persuasion, leadership and teamwork, self-mastery, thinking for
  success, character and trust, work and the future); success means value for yourself and for others; taught by doing
  in the game's own world: **My Business** (a stand, a shop, a company; real gold capped like learning's, only while
  played), **the Market Square** (prices that move for visible reasons; shares and dividends on the Big track), **the
  Connections Book** (the worlds' people, helping first, introductions, mentors, trust), **Talk & Deal**, **Team
  Projects**, **Goals & Habits** (if-then plans, a gentle habit garden), **Success Stories**. Never gambling, no real
  money or advice, no pressure tricks, honesty rewarded, trading only with approved friends. Plan S1 (with L1: the stand)
  → S2 (goals, Talk & Deal, connections, stories) → S3 (the shop, the market) → S4 (teams, habits, the Big track).


### 27.1 As built (L1, 2026-10-16; notes `docs/devlog/parts/life-l1.md`, the experts' review sheet `docs/devlog/parts/life-l1-review.md`)
- **The Life tab:** the School's 13th tab on every grade (its own green and a heart). The track is picked with three big
  read-aloud pictures (LITTLE about 6-8, MIDDLE 9-11, BIG 12 and up) or set and fixed on the grown-ups' page; EASIER and
  HARDER look at the other tracks. The map: the ten areas in **Living well** (body and health, feelings, people, staying
  safe, life online, home and everyday, getting around, our world) and **Success** (money and business; thinking and the
  future), each with units on all three tracks: 9 of Life's own (one per Experience track, in the School's lesson format:
  LESSON, PRACTICE, TRY IT), 60 of the School's own lessons where they fit (their progress and reward stay the School's),
  "coming soon" only for L2's Experiences. Life's units pay gold like any lesson.
- **The Experience framework:** an Experience is data (`data/life/experiences/*.json`: per track its steps, an Expert try
  with a twist, a 3-5 picture before-and-after check, the "name it" card in the authorities' words with its source, Try
  it for real, "your child can now..." and the sources); 17 kinds of step checked from one sample a frame ("the hand is
  here and squeezing", never a button); a practice room built in code far above the voxel world; the coach shows after
  ~10 s without progress (20 s on the Expert try), on SHOW ME and after a miss, with a ghost finger (flat) or ghost hands
  (VR); the one next thing glows; I NEED A BREAK always; every run ends well. Stamps in the **Life Passport**: Done it,
  By myself (no hint), Expert (the Expert try, no hint), a surprise on a new Expert stamp; the first finished run of a
  skill pays 100 gold once; repeats come back after 1, 3, 7, 21 and 60 days, varied by seed. Step measurements stay on
  the device (`user://life_measure.json`).
- **Little Lifesaver** (Little: is it safe, call the region's number on a play phone, the calm helper's picture
  questions, the address said to a grown-up and never typed, stay; Middle: a cut pressed with a clean cloth, a burn under
  cool running water for 20 minutes with a time-lapse, cling film, the recovery position on Bobo; Big: hands-only CPR on
  Max the dummy, 30 pushes at 100-120 a minute with a beat meter and a buzz on each good push in VR, choking: cough, 5
  back blows, 5 tummy thrusts), **Fire Escape** (Little: the hazard hunt in a doll's-house living room, then the drill;
  Middle: the night escape, the back of the hand on a door, doors closed behind you, the meeting point, the call from
  outside, never back in, stop, drop and roll; Big: the escape and PASS on a small bin fire outside, "if in doubt, get
  out"), **My Money Stall** (the first step of My Business: the stand, prices, change coin by coin, takings, the saving
  jar for the rocket, the pretend bank's interest week by week, simple then compound, a shopping trip with a list and a
  budget, scams spotted; pretend market coins only). Each playable flat and in VR; calm, practice-framed, no injury shown.
- **The grown-ups' Life page** (behind the parent gate): "your child can now..." (what was done alone), practising with
  help, this week, the honest before-and-after line per skill, the Try it for real list; the track and its lock; the
  region (10, the default from the device's locale, unknown: Europe's 112) with its number and side of the road; the
  careful topics' switches (all off, nothing behind them yet).
- **Real motions and devices (owner #117, design §13):** every hands-on step names its motion (one of the ten: CPR and
  the cloth press, a back blow strikes, a tap twists, the extinguisher squeezes then aims, change is a press for now), its
  tool and its device (the play phone, the extinguisher, the till: controls, what they show, the order, the safety
  steps), as data for the shared recogniser to come; no engine built in L1. In a headset LIFE sits in the School map's
  header (its tabs keep to six columns at VR's 24 px words).
- **Left for the lead:** the emulator's FPS and look, the Quest 3 (reach, squeeze, crouch, CPR, the tray), Android Back in
  a room (the menu's own Back leaves the School), a game controller for a room's 3D things (E0), an `EarnRules.TABLE`
  row for Life, the shader census through a room, the experts' review.

### 27.2 As built (L2, 2026-10-16; notes `docs/devlog/parts/life-l2.md`, the experts' review sheet `docs/devlog/parts/life-l2-review.md`)
- **Safe Streets** (Getting around): a real-sized practice street with the cars' own models at 30-40 km/h on the region's
  side (scripted traffic, `LifeTraffic`: a real safe gap every 16 s; their engines heard where they are). Little: hold a
  grown-up buddy's hand, stop at the kerb, look in the region's order (VR: the head's turn; flat: LOOK buttons or a
  swipe), listen, cross on a big gap (the far side glows only when safe), the back seat, the booster and the belt.
  Middle: a parked van's edge, the button crossing and the green man (never when it flashes), dusk (light clothes, a
  shiny band, a torch), a bike helmet's 2-V-1 fit on Pip-pop. Big: the driver's seat of a practice car on rollers (it
  never moves): belts, the lights, giving way, the accelerator kept at the sign's limit (a gauge), the phone, stopping
  distances, cyclists, zebras. A child who steps out at an unsafe moment sees the cars stop gently: a kind miss, never a
  crash.
- **The Kitchen** (Home and everyday; links to Money): 20 seconds of hand washing (the germs' glow fades), a healthy
  plate, measuring by pouring and weighing in fractions and grams, the bridge and claw grips with a child-safe knife,
  whisking, the hob and the oven with a grown-up (handles in, the hot light, oven gloves), the kettle (MIN to MAX, it
  switches itself off, pour slowly), food safety (raw apart, the fridge at 5 °C), a week's meals on a pretend-coin
  budget and the better buy; recipes from many countries vary by the seed.
- **Calm Corner** (My feelings): naming feelings from the buddies' faces, balloon breathing (VR: the hands rise and fall),
  five things you can see, a worry box, stories (left out, a quarrel, unkindness in the playground and online, pressure
  to share a photo), who and where to ask for help. Not therapy: nothing a child picks is kept or marked.
- **Life Town:** a district by the spawn of every home world (placed like the Launch Site; models; the host clears the
  trees in its places' way once; `WorldMeta.life_town`): the practice house, the clinic, the market, the street, the
  kitchen house and the park bench; walking up opens Life on that Experience's unit; while a practice room from it shows
  the avatar is held and kept safe. MY MAP marks it.
- **The framework grew, not forked:** seven kinds of step (look, cross, rub, pour, breathe, feel, steady), every hands-on
  step naming its motion, tool and device as data (owner #117), the region's kerb drill and speed sign as tokens, the
  Passport's pages, "Leave the practice?" on Android Back inside a room, and Life in the Gold Shop's How to earn list.
- **Left for the lead:** the emulator's FPS in each room (the street most) and in a room opened from Life Town, the Quest 3
  (the head's look, the trigger to cross and for the pedals, rubbing, the tilt to pour, the hands to breathe), the
  experts' review of the sheet, the census through a room.
### 27.3 As built (tools, round 4b, 2026-10-16; owner #116, #117, #118; notes `docs/devlog/parts/tools-r4b.md`)
- **One engine for every real skill (design §13):** the ten motions (strike, stroke, twist, squeeze, press, spread,
  measure, pour, aim, cut) recognised from a held tool's tip in VR and from a finger on a phone in the same way, each with
  its checks (speed, path, angle, depth, rate, time); done well it counts with a soft buzz, almost says kind words, a bad
  use never counts, none is ever a miss. The device model at run time on Life L1's device data: controls in the right
  order, what it shows, its safety steps first ("Safety first: goggles on."). The right tool for the job is noticed
  kindly ("That works better with the trowel ...") and the right one glows. Life's room host runs it (ToolRoomHost); a
  room opts in by giving its work frames, so L1's Experiences play as before.
- **The Tool Book:** 56 tools, devices and safety gear in the design's 11 areas (building and making, fixing, kitchen,
  home, garden, health and safety, money, tech, science, getting around, music and art), each with what it is for, how to
  hold it, its motion in VR and on a phone, its safety rule (a grown-up's job says so) and a device's right order; three
  stamps per tool (Done it, By myself, Expert) in the profile and its backup; "you can use N tools".
- **Real Builder** (a Life Experience in Life's format, Home and everyday): a true-scale practice building site. Little:
  a little wall of real concrete blocks (mortar with the trowel, the blocks laid where they glow, a high one tapped down,
  the spirit level, the half block that staggers the joints, the coach's straight-jointed test wall split by a push while
  the child's holds). Middle: a garden shed of real bricks (215 x 102.5 x 65 mm, 10 mm joints): measure and count the
  bricks, the mixer's order (a grown-up's job), the front's rows with the doorway open and half bricks at it, the level,
  the plumb line, the team's rows in the same bond, the lintel (why), the saw (goggles first), rafters, a nail, why a roof
  slopes, tiles from the bottom up. Big: a small house: a square corner by 3-4-5, the corner pier, lintels over the window
  and the door with their 15 cm bearing measured, the roof, and a walk in through the front door. Bricks snap to the
  bond's places (never free physics): tapped flat, carried and let go in VR. Safety first on every track; owner #118's
  safe mistakes shaped for Life's coming kind (the saw without goggles: the coach's calm why and a gentle sawdust puff;
  straight joints; no lintel), never on Little. Try it for real: find the stagger and the lintels in a real wall with a
  grown-up, from the pavement. Three Life units (the School's format), "coming soon" on Life's map until the lead's hook.
- **Left for the lead:** the hooks (Life's catalogue knows `real_builder`, its room, ToolRoomHost and the TOOL BOOK button
  in the Life screen, the units' switch), the Quest 3 (the motions' numbers with a child's hand, the bench, carrying
  bricks, the hop-ups and the scaffold), the emulator (the tray and the finger motions), the experts' review of the facts.

### 27.4 As built (Success S2, 2026-10-17; owner #115; notes `docs/devlog/parts/success-s2.md`, the experts' review sheet `docs/devlog/parts/success-s2-review.md`)
- **Four new Success areas on Life's map** (the strand's row of six: money and business, thinking and the future, goals
  and habits, talk and deal, connections, success stories), each with its Life Experience's unit on every track (the
  School's format: a memory question first, Try it last, 10-11 exercises on three levels) and the School's own lessons
  that fit (personal best; kind feedback, speak and present, discuss and present; honesty, people who help us, many
  cultures, global and active citizens; inventions, inventors and engineers, design for a need, jobs and industry).
- **The Goal Board** (Experience `goal_board`, the Goal Room; and the place MY GOAL BOARD): Little helps Bobo with a goal
  you can see (a tower three blocks high), one step at a time, trying again after a gentle fall, saving for a kite, a
  plant watered every morning that waits on a forgotten day; Middle puts a real rocket goal on the board (Mission
  Control's Moon plan in gold), orders its steps, picks the "When I finish a lesson, I put 10 gold aside" plan and an
  obstacle plan, keeps a week's habit (Wednesday's cloud: one day off hardly matters); Big builds WOOP (wish, outcome,
  obstacle, plan), an if-then plan from parts, big rocks first in the week's jar, bouncing back, habit stacking and
  honest progress. MY GOAL BOARD makes the child's own goal from pictures (a dream, a goal the game measures where it
  can: the gold against the rocket plan, a flight, the next universe, lessons mastered, stamps by myself; steps; the
  plan; Big's obstacle plan), ticks the steps, celebrates reaching it once (no gold); the habit garden beside it grows a
  plant on each day kept (YES or NOT TODAY once a day, "thank you for being honest"), counts days in all, never in a row,
  welcomes the child back after days away and keeps earlier habits' plants.
- **Talk & Deal** (`talk_deal`, the market square): Little listens to Mo's complaint (it varies), says it back, says
  sorry without a "but", fixes it, thanks him, and gives Robo clear words (Robo does EXACTLY what was said: a muddled
  order puts a box on his head for a moment); Middle asks what Ana needs, makes a win-win deal, shakes hands (VR: the
  hand squeezes), keeps the promised delivery, gives Robo instructions in order and handles a second complaint; Big
  pitches a bread cart to three friendly investors in the meeting tent (VR: standing in front of them; the problem, the
  idea, why me, what I need on the pitch board; eye contact with each), answers honestly, takes feedback, says no
  politely to an unfair deal (and, on the Expert try, to "sign now or it's gone"), shakes on a fair one and gives
  Pip-pop kind, useful feedback.
- **The Connections Book** (`connections`, the village square; and the place MY CONNECTIONS BOOK): sixteen people of the
  practice village and the market (names, jobs, wishes, needs, offers, a mentor's tip, a new chance, four of them
  different from many children: Kenji is 80, Lina is new from far away, Omar uses a wheelchair, Sam is deaf and signs);
  Little meets and remembers names, helps first (flour for Amara), includes Lina and keeps a promise the next morning;
  Middle finds needs, introduces people who can help each other, promises only what it can do and keeps it, asks Omar
  politely to teach and talks with Sam; Big builds a network of all kinds of people, a chain of introductions, keeps its
  good name, keeps in touch and stays safe online (never an address or a password). A finished try fills the book:
  warmth rises by kind acts (at most two steps a try) and shows only in words, never as a number or a score others see.
- **Success Stories** (`success_stories`, the Story Theatre; and the place THE STORY SHELF): twenty true stories of real
  people of the past from seventeen countries (eight women; nurses, teachers, farmers, engineers, inventors, doctors,
  scientists, founders), five to seven lines each, read aloud, every fact checked with its source (two or more each),
  then "Which skill did they use?"; the theatre acts three a track (Braille, Maathai, the Wrights; the Wrights, Carver,
  Nightingale; Dunant, Johnson, Yuan) with an Expert story more (Seacole, Fleming, Phule).
- **Parents:** the grown-ups' Life page says the goal and its plan, the habit's days, the people met, helped, promises
  kept and introductions, and the stories read; the Passport's four new pages; Try it for real on every track.
- **Left for the lead:** Life Town places for the four (L3a owns the plaza now), the emulator (the map's row of six at
  the real font, the Goal Board's two panels, the book's cards), the Quest 3 (the handshakes, the pitch's stance, the
  laser on the people), the experts' review of the sheet (a child psychologist, a speaking-and-listening teacher, a
  financial educator, an online-safety educator, a history teacher).

### 27.5 As built (L3a, 2026-10-17; owner #118; notes `docs/devlog/parts/life-l3a.md`, the experts' review sheet `docs/devlog/parts/life-l3a-review.md`)
- **Safe mistakes (the design's §14):** on the Middle and Big tracks a step may let the child try the wrong way (a thing in
  the room, a body action such as standing up on the ice, or a picture). Then time freezes: the practice room stills, the
  scene softens (a pale veil flat; a 35% dim in VR, under the panel), the room shows calmly and still what would happen
  (never an injury), and the coach's card says why and the right way; GOT IT goes on and the child does it right. Never a
  hint on a normal try (trying it is learning), one on the Expert try. On the Little track the coach says the rule first
  and no mistake is shown. The device counts how often each wrong way is tried.
- **Time at danger moments** runs at half speed on a skill's first two tries, three quarters later, real speed on the Expert
  try (a SLOW PRACTICE mark shows); a danger moment may want its action in time (the earthquake's drop and cover).
- **The intensity:** gentle by default; a grown-up may choose MORE REAL on the grown-ups' SAFETY tab, used only on the Big
  track: real speed from the first try and the storm, the shaking and the alarms a little stronger; never injuries or
  scares. **The debrief:** after every emergency Experience (Little Lifesaver, Fire Escape and the three below) a calm page,
  "You did it. In real life, grown-ups help too.", with the region's number.
- **Water Safety** (the catalogue's row 2): Little: the water rules, Bobo's life jacket, help from the side (shout, throw
  the float, never jump in). Middle: spot the quiet friend in trouble among playing ones, reach with the pole from the
  side (safe mistake: jumping in after someone), swim between the flags, swim along the beach out of a rip (safe mistake:
  swimming straight back against it), float and wave, a life jacket's fit. Big: stay off thin ice; fallen in: keep still,
  arms out, kick, slide out, roll (safe mistake: standing up on the ice), crawl back; help from the bank with a branch
  (safe mistake: walking onto the ice).
- **The Poisons Cupboard** (row 5): Little: the red-diamond warning signs, tell a grown-up, medicine only from your
  grown-up, a button battery to a grown-up, never wild berries. Middle: the GHS's signs and what each means, the child lock,
  never mix cleaners (safe mistake: two cleaners poured together), the garage's dangers, a swallowed button battery is an
  emergency, never wild mushrooms. Big: the carbon monoxide alarm (test it; it sounds at night: everyone out, call from
  outside, wait until it's safe), cleaners one at a time (the safe mistake again, the gases named), a swallowed battery,
  medicine doses, foraging.
- **Earth and Weather** (row 9; Georgia's mountains in the region's own sentence and Georgia's Emergency Management Service
  among the sources): Little: Drop, Cover, Hold On under a strong table, open ground with a grown-up, thunder (go indoors),
  lost (hug a tree, answer). Middle: the drill (safe mistake: running outside during the shaking), no table (an inside
  wall), aftershocks, floods (turn around), lightning, heat. Big: the emergency bag first, the drill by a window, shoes on,
  open ground, the hills' thunder, lost (stay put, be seen and heard), cold and heat; Expert: shaking outside (a clear
  space; safe mistake: running into a building).
- Each flat and in VR on three tracks, with its nine Life units (the School's format), seven Tool Book entries, three new
  places in Life Town (the practice pool, the poisons cupboard house, the weather hut; the plaza is now full).
- **Left for the lead:** the emulator (the freeze, the rooms' FPS, the small warning signs at phone size), the Quest 3 (the
  dim, the water-level views, the ice and the table by the body, the reach of the branch), the experts' review of every fact
  (not re-fetched: Georgia's service's own advice most), Real Builder's and Safe Streets' safe mistakes (small hooks).

### 27.6 As built (L3b, 2026-10-17; owner #118, #115; notes `docs/devlog/parts/life-l3b.md`, the experts' review sheet `docs/devlog/parts/life-l3b-review.md`)
- **Two small new rules:** a safe mistake may be **the right thing at the wrong moment** (`try: "unsafe"`): Safe Streets'
  crossing while a car comes or before the green man (Middle: time freezes, the street's still picture, the coach's why;
  Little keeps L2's kind miss, a car stopping gently) and Real Builder's saw before the goggles (the first try freezes,
  then the goggles glow). And a body action, **be a tree** (a dog runs at you): flat the BE A TREE button; in VR the head
  looking down at the feet, both arms folded in, still.
- **Electricity Safety** (the catalogue's row 7): Little: the hazard hunt only (a dryer by the bath, a drink by a socket,
  a frayed cable, an adaptor in an adaptor, a fork in the toaster, a toy key by a socket, a kite in the lines: tell a
  grown-up), dry hands, only plugs in sockets. Middle: dry hands first (safe mistake: the hair dryer with wet hands), the
  dryer far from the bath, unplug by the plug, a frayed cable (tell a grown-up), one adaptor at most, kites in open
  fields, never climb trees near lines, never into a substation. Big: the fuse box and the RCD's test button, a cracked
  plug, someone stuck to electricity (safe mistake: grabbing him; switch off at the fuse box if it can be reached safely,
  call), a fallen line after a storm (safe mistake: going closer; at least 10 metres away, keep others away, call;
  touching or moving a line "not for a child to do").
- **Safe with Animals** (row 8, in Our world): Little: ask the owner, the back of the hand, a gentle stroke on the side,
  let sleeping dogs sleep, be a tree, walk away from bees, tell about a sting, never behind a horse. Middle: read a dog's
  warning signs (a stiff body, a hard stare, lips back, the tail high), no hugs (safe mistake: hugging a dog you don't
  know), be a tree (safe mistake: running), horses, cows with calves, wasps, a sting's allergy (call), a snake (step back,
  go round). Big: the hills with the group, noise on the path, a bear far off (back slowly), never feed a fox, a flock and
  its guard dogs (go round; be a tree, safe mistake: running), a snake, an allergic reaction to a sting (call, the
  person's own pen). Georgia's mountains in the region's own sentence (`{wild_where}`: bears, wolves, wild boar, shepherd
  dogs). Never a bite or its sound.
- **Medical Emergencies** (row 10): Little: tell a grown-up (a bump, a nosebleed, a hot friend into the shade with water,
  swelling lips), call the region's number on the play phone. Middle: a nosebleed (sit, lean forward, pinch the soft part
  10 minutes; safe mistake: the head tipped back), a bump on the head, asthma with a trainer inhaler and spacer (shake,
  press once, five slow breaths), heat and heatstroke (shade, cool, water, call). Big: anaphylaxis's signs and the call,
  the auto-injector on a trainer pen and a practice pad ("blue to the sky, orange to the thigh"; a real pen is only ever
  the person's own, said plainly), lying with the legs raised; a seizure (time it, hard things away, soft under the head;
  safe mistake: something in the mouth; never hold them down; the recovery position after; over 5 minutes: call).
- **Fire and heat, what L1 left** (row 3), in the old rooms' data: The Kitchen's Middle pan fire (heat off, the lid on,
  leave it covered; safe mistake: water on the pan, frozen before the flare; a fire that grows: get out, call), its
  Little hot tap and a baby cousin's small things tidied away and grapes cut (choking, row 6), its Big scald (cool running
  water 20 minutes, cling film); Fire Escape's Little matches (a grown-up's job: tell Gus) and Middle campfire (a ring of
  stones away from the tent and the tree, water ready, small, then drown, stir and feel with the back of the hand).
- Each flat and in VR on three tracks, with its nine Life units, eight Tool Book entries (the fuse box, the RCD, the plug,
  the trainer pen, the inhaler and spacer, the pan lid; Success S2's calendar and jar), and L3a's seven entries with their
  own pictures. **Life Town's second row** (nearest the spawn, fronts facing it): the power hut, the animal corner, the
  first aid hut, and Success S2's four (the goal board, the talk tent, the village board, the story stage): every
  Experience has its place.
- **Left for the lead:** the emulator (the three rooms' FPS, the freezes, the pictures at phone size, the second row's
  models and signs), the Quest 3 (be a tree with the head and the arms, the stuck Gus and the fuse box by laser, the nose's
  pinch, the trainer pen on the pad, the campfire's pour and stir), the experts' review of every fact (the review sheet's
  checkboxes).

### 27.7 As built (L3c, 2026-10-17; owner #112, #113, #117, #118; notes `docs/devlog/parts/life-l3c.md`, the experts' review sheet `docs/devlog/parts/life-l3c-review.md`)
- **Online City** (the catalogue's row 7, Life online; §14 row 14): a calm practice living room with Gus, and a play
  tablet with Online City on it: a pretend town of games, chats, news and a shop. Everything is pretend: no real sites,
  apps, brands or people; nothing the child types or says is kept or sent; nothing personal is ever typed (every answer is
  a button or a picture); no microphone. Flat the tablet is in front of the view; **in VR it is held in the off hand**
  (`LifeRoom.held`: it follows the hand that doesn't point, its face to the eyes; the other hand or the laser presses its
  buttons; the holding hand never does). Little: ask a grown-up before a new game, keep your name, school and home
  private, tell a grown-up (a sad screen), close a pop-up, be kind, take a break. Middle: a stranger in a game's chat asks
  for a photo and where you live (**safe mistake: answering**, SEND PHOTO: frozen, the photo on its way to a grey "?",
  "once it's sent, you can't take it back"; then BLOCK and tell), online friends are still strangers (never meet), a mean
  post ("you're bad at this game": don't reply, keep it to show, BLOCK, REPORT, tell), **the game's own password rules**
  (#105: at least 6, never your name, nothing easy to guess; "Never tell anyone your password. Not even a friend."), free
  gold for a password is a trick, a pop-up's download (close it, ask), a news story's three checks (who made it, when,
  does anyone else say so), kind comments, breaks (never guilt). Big: a pretend profile's private cards (school, address,
  photo, password), think before you post, a friend request and "let's meet" (never), **free gold, just give your
  password (safe mistake: clicking: a hook over the password card, "a trick to take your account")**, phishing links,
  passwords and the game's own brake (5 wrong tries in 15 minutes), fake news and changed pictures, standing by a friend
  in a group chat, screens before bed.
- **Find Your Way** (rows 10 and 14, Getting around): the address and a grown-up's number said aloud to a grown-up, never
  typed or kept (the game never asks; Try it for real: "Say your address to your grown-up now"). Little: lost at the
  practice market (STAY HERE: still; find the safe grown-ups: a shop worker with a name badge, a mum with her children, a
  police officer; never go anywhere with anyone, said first), a fire drill at the practice school (the line behind the
  teacher, the meeting point, never back in), landmarks. Middle: lost again (**safe mistake: walking off with a man who
  says "come with me"**: a see-through figure a few steps off towards the way out, "walking away makes you harder to
  find"; he only ever stands where he is, never grabbing or following), a safe grown-up may hear your grown-up's number,
  the fire drill, the practice metro (two lines, green and red, meeting at CENTRAL; the region's own metro in a sentence,
  `{metro_where}`: Tbilisi's two lines meeting at Station Square), the ticket on the gate's reader, behind the yellow line,
  the compass (north, the eight points). Big: plan a journey (start, change, end; the train towards the end station),
  the ticket, **the platform's edge while a train comes in (safe mistake: a danger moment; the train frozen, "trains come
  in fast and close")**, let people off first, separated from the group (stay put, the help point), a map's key and grid
  squares, a compass bearing walked to a flag (90 degrees; Expert 45). No lockdown simulation anywhere: the school's
  emergency is a fire drill.
- **Home Helper** (row 11, Home and everyday): no safe mistakes in chores (a wrong bin or a knife pointing up is a kind
  miss with its why). Little: whites and colours, a pair of socks, a T-shirt folded (sleeve, sleeve, half), everything
  back in its home, a plant watered by its soil (a new pour gauge: "the soil is still dry", "damp: just right", "too
  wet"), Biscuit's food and fresh water, the paper and plastic bins, the smoke alarm's test button held with Gus. Middle:
  the red sock in the whites, folding, four bins (paper, plastic and cans, glass, food waste; the region's bins in a
  sentence, `{bins_where}`; Expert: a battery to a battery box), plants, a daily walk, fresh water, a poorly pet (the vet),
  the table set (fork left, knife right), the smoke alarm once a month. Big: the care label's symbols (the tub's number, a
  hand, the crossed-out tumble dryer), the washing machine (door, the 30 programme with a grown-up, start), folded and put
  away, the dishwasher (plates below, cups on top, knives point down), batteries, plants on holiday, the smoke alarm's
  chirp (never take its battery out) and its monthly test. Hands fold, pour and sort in VR.
- Each flat and in VR on three tracks, with its nine Life units (three per area; Online City's Big unit beside the School's
  grade 6-8 online-safety links, grade 8's Cyber security among them), five new Tool Book entries (the metro ticket, the
  washing label, the ticket gates, the help point, the dishwasher) besides the tablet, the compass, the smoke alarm and the
  watering can already there; Online City and Find Your Way end with the calm debrief. **Life Town's third row** (z 15..16,
  in front of the second, doors facing the spawn 5 m apart): the web café with its big play tablet, the metro entrance
  with its red M and two-line map, the helper's house with its washing line and four bins; every Experience has its place;
  6 of 8 real meadows get their town (7 before: the deeper plaza costs one).
- **Hooks outside Life** (each marked "owner #118 (L3c)"): the Goal Board's jar and habit-calendar steps name their
  devices (their Tool Book stamps); grade 8's Cyber security ends by naming Online City (its test's `LIFE_LINKS` line
  too); the Life map links `g8.computing.cyber_security`.
- **Left for the lead:** the emulator (the tablet's pages and buttons at phone size, the market's people, the metro map,
  the compass's letters, the care label, the bins; FPS in Find Your Way's Middle, 210 meshes), the Quest 3 (the tablet in
  the off hand and the finger on its buttons, STAY HERE standing still, the platform by laser, the compass by hand, the
  watering can's tilt, the folding by hand, the smoke alarm), the experts' review of every fact.

### 27.8 As built (Success S3, 2026-10-17; owner #115; notes `docs/devlog/parts/success-s3.md`, the experts' review sheet `docs/devlog/parts/success-s3-review.md`)
- **Money and business grows** (My Money Stall's area): on each track My Business's shop unit and the Market Square's
  unit (the School's format: a memory question first, Try it last, 10-11 exercises on three levels), the School's lessons
  that fit (money and change; farming, trade and the first money; trade around the world; chance, gambling and
  spending), and two places as cards among the units: **MY SHOP** and **THE PRICE BOARD**.
- **My Business: the shop** (Experience `my_shop`, the shop's room; the customers are the Connections Book's people with
  their own wishes, budgets and moods; pretend market coins): **Little keeps the stand** (an honest sign, "Hello! What
  would you like?", their wish, a fair price for what cost 1 coin, the coins into the cash box, change coin by coin,
  thank you and 5 stars, coins kept in the FLOUR jar, what is left is the profit; Expert: no pies, said honestly);
  **Middle runs the bakery** (a clear and honest sign; price = what it costs + a little profit, too high and nobody buys,
  too low and no money for more flour; ask first and what it is for; the wish; the change from a 10 at the till; an
  unsure customer's budget in honey buns; flour weighed on the scales (money out); Mo's complaint listened to, said back,
  sorry and a fresh loaf; Bobo the helper paid a fair wage; the ledger: money in, money out, profit; the week's bars; the
  review board; Pip-pop's rival bakery won back only with better bread and kinder service, fake reviews and untrue words
  turned down with the coach's why; Expert: dearer flour, a customer waiting); **Big gets the harder days** (dearer flour
  and a fair new price said honestly, baking less on a rainy day, a big order and its promise kept, the hours' wage,
  the loss day in the ledger, a rival's price war below cost refused, an unfair review answered kindly, saving half the
  profit for an oven, giving back; Expert: the honey late, told early). **The shop pays real gold only while the child
  plays it**: 5 for each customer served in a try (like a School answer right the first time), at most 50 a day, through
  the game's own award path (EarnRules.credit; the server's limits are far above), a try stopped for now paying only the
  customers already served; MY SHOP keeps the ledger (the last seven days' profit as bars, the week's money in and out,
  the days, customers and complaints fixed in all), the reviews (honest, kind: 5 stars, or 4 "next time it will be even
  quicker" when the coach helped), the sign picked from six, the day's gold out of its cap, and OPEN MY SHOP.
- **The Market Square** (Experience `market_square`, its room; the buddy merchants Tomas, Ana, Kenji and Amara; the PRICE
  BOARD): **Little's swap stall** (why people swap, a fair swap good for both, a handshake is a promise, "No, thank you"
  to 1 sticker for all your apples, a drawing for a jar when both are happy); **Middle's supply and demand with causes
  you can see** (a dry summer: wheat up; the festival: cakes up; many sellers: apples down; the harvest: wheat down
  again; buying flour from Tomas, haggling politely with Ana and shaking on it, specialising and trading makes both
  richer, selling with change; Expert: two causes pulling opposite ways); **Big's honest trading** (buy when there is
  plenty and sell when it is scarce, never lies; keep the stock you can store and sell; spread across three baskets, a
  storm hits one) and **the dice lesson** (pretend counters only, never gold, never a bet: six throws by the child, then
  600 throws drawn as a chart that ends about 200 down, because a 6 pays 4 and comes once in six throws; gambling is
  paying for a chance to win, trading and saving are not; Expert: a game paying 5 still loses). THE PRICE BOARD shows
  today's market (the School's day; a season lasts 7 days): every price with its arrow and its cause in words and a
  picture, and what the next season brings. Nothing random, nothing to buy there.
- **The Market Square in the world**: a second plaza beside Life Town (the town is full), placed by Life Town's own
  search with its own layout, the cells nearest the town first, off the town's plaza and beside it (never behind); the
  bakery and the market stalls with the Price Board as models; walking up to one opens its unit; saved with the town.
  Measured: the town keeps its 6 of 8 real meadows; 6 of 6 towns get their Market Square, 26-34 m from the town's middle.
- **Flat and VR**: the till's coins in the hand, the scales by the hand, the goods on the shelf by hand or laser, the
  Price Board read and its rows pressed by laser, the handshakes, the dice by hand.
- **The Tool Book**: the ledger and the price board (new), the till and the scales. **Parents**: the grown-ups' Life page
  says the shop's days, customers, profit in pretend coins, complaints fixed and gold earned, and the market's tries,
  Price Board readings and the dice lesson.
- **Left for the lead:** the Gold Shop's "How to earn" row for the shop, MY MAP's mark for the Market Square, the
  emulator (Money and business's ten cards, MY SHOP's panels, the boards' words, FPS in the Big market, 213 meshes), the
  Quest 3 (the coins in the hand, the turn to the bake corner, the Price Board's rows by laser at 3.5 m, the
  handshakes), the experts' review of `success-s3-review.md`.
