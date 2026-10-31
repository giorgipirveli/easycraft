# M3 Task 11: pets with perks (notes)

Built by a background agent in its own worktree (branch cut from `m2-survive-the-night`, with the lead's
integration branch `lead-merge` merged in first: main + owner #38 bot chat, M4 I gifts/visits, M3 Task 4 Candy
Kingdom), without the editor or the emulator. Spec §14.7 (refined below), §5.9, §6, §16 (signature moment "the
dog that digs up treasure"); plan Task 11. Item ids **430–434** (pet treats). Brief:
`docs/superpowers/briefs/prompt-m3t11.md`.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Pet rules (pure) | `core/rules/pet_rules.gd` (`PetRules`) | **The kinds table** `KINDS` (dog, cat, fox, parrot, Pip): how each becomes a pet (`BY_PETS` three quick pets, `BY_TREATS` two treats from the same child, `GIVEN`), its perks, its favourite treat, the sniffers' pace (`sniff_every`, `sniff_pace`, `digs`), `cap` (Pip never counts toward the 3 pets). A new kind — owner #39's baby dragon — is one row here plus an `AnimalRules.SPECIES` body, `BlockyAnimal` boxes (and `COLLAR`) and `AnimalSpecies.TRAITS`; the tests check every row has all four. The happiness heart (`after_pat`, `after_treat`, `after_time`, `heart_scale`, `play_factor`, `synced`, `clean_happiness`, and `follows` / `obeys` / `perks_work` that are always true), names (`FUN_NAMES`, 32, none a bot friend's name; `first_name`, `name_refusal`, `saved_name`), collars (`COLLARS` = the 8 M1b owner colours, `OWNER_COLOUR` = unchosen), treats (`is_treat`, `treat_tames`, `TREAT_PRICE`), Pip (`give_pip(profile)`, `pip_record`, `clean_pip`). |
| Perk rules (pure) | `core/rules/pet_perks.gd` (`PetPerks`) | `active` (a tamed pet within 16 blocks, sideways, of its child who is in the game), `glows` (cat or Pip, in a cave — underground ≥ 0.5 — or at night), `glow_pick` (the nearest within 24), `coin_owner` (coins within 4 blocks of a dog go to its child), `bark` (a monster it doesn't know comes within 16; 8 s apart; one that leaves and comes back is new again; one it could not bark at yet stays new), `point_target` (the nearest unfound secret within 24) and `point_yaw`. |
| The parrot's words (pure) | `core/rules/pet_echo.gd` (`PetEcho`) | `hear_own(text, from_peer, my_peer)` keeps a line only when the sender is this device's own player, not a command, clean (the chat filter; quick phrases always), cut to 28 characters; 6 lines at most; `squawk(roll)` → "Squawk! <line>". No network, no Session, no chat_received (a test reads the file). |
| Treats | `data/items/item_ids.gd` | `TREAT_BISCUIT` 430 (dogs' favourite), `TREAT_FISH` 431 (cats'), `TREAT_BERRIES` 432 (foxes'), `TREAT_SEEDS` 433 (parrots'), `TREAT_BOLT` 434 (Pip's): in `ALL`, `TREATS`; names Dog Biscuit, Fish Snack, Berries, Seed Cracker, Shiny Bolt. Icons drawn in code (`ui/pets/pet_pictures.gd`, `PetPictures`, via one line in `BlockIcons.icon`): no atlas rows shared with other tasks. |
| Tilly | `core/economy/shop_rules.gd` | `TREAT_PRICES` (2 gold each, × 2^(u−1)), listed on the POTIONS shelf; never bought back. |
| Palette | `ui/hud/block_palette.gd` (section at the end) | A **PETS** tab (the 5th): TREATS and "Hold a treat and tap your pet!". Free in Sandbox; Survivor shows the treats owned like everything else. |
| New animals | `core/rules/animal_rules.gd`, `core/mind/species/animal_species.gd`, `entities/animal/blocky_animal.gd` | `fox`, `parrot`, `pip` species (weight 0: never picked by the herd weights), health 6/3/6, no drops, mind traits (a shy curious fox, a watchful parrot, Pip who comes over to look); box models (a fox with a white-tipped bushy tail that wags, a red parrot with green wings and blue tail feathers that wag, Pip: wheels, a silver body, a screen face with blue eyes and a smile, an antenna with a yellow ball that bobs), collars (Pip's is a bow tie). **Wild foxes live by the woods, parrots by the water** (`AnimalRules.wild_pet_at`): 35 % of the herds whose centre has sea level or a river within 5 blocks are parrots, else with a tree within 3 blocks foxes; from a hash of its own, so every other herd keeps its species and spots. |
| The animal | `entities/animal/animal.gd` (section "M3 Task 11" at the end, plus small edits marked M3 Task 11) | Synced (on change) `collar` and `happiness` (1/20 steps; the host keeps the exact value); `treat` (tames a fox or parrot on the second treat from the same child, feeds a pet, "liked" for a wild animal that can be a pet), `pat` (0.6 s apart), `pet_tick` (the heart falls); `bark()` → RPC: every game hears it and sees the monsters' shared "!" over it for 1.5 s; `point_at(target)` → the host holds it still 2.5 s, beak towards the secret; RPC: the squawk and a trail of sparkles on every game; the dig puff over treasure is an RPC now (every game sees it; the fox's is bigger); `squawk_line(text)` (a Label3D bubble, this game only); Pip's realistic look. Edits: `pet_tap` tames only `BY_PETS` kinds and names from `PetRules`; `_sniff_treasure` for every `SNIFF` kind near its child, at its kind's pace; a happier pet wags faster and jumps along more often; `to_save` / `setup` carry `collar` and `happiness`; `PET_NAMES` is `PetRules.FUN_NAMES`. |
| The director | `world/pet_director.gd` (`PetDirector`, node **`Pets`** in the sandbox, every game) | Host, 5 times a second: hearts of pets whose child is in the game, the dogs' barks (monsters gathered once per tick, only when a dog is active), coins within 4 blocks of an active dog get its child as `collector` (they fly and pay as in M2 Task 4), the parrots' pointing. Requests: `on_treat` (reach like petting; Survivor pays one treat from the bag first, only when something will happen; a wild dog/cat's treat also counts as one of its three pets through `request_pet`; the mind is fed: Task 18's reward), `on_pat`, `on_name` (the owner only; `PetRules.name_refusal` with the sender's registered chat band), `on_collar` (the owner only, 0–7), `on_pip` (one Pip per child, next to their player), `on_peer_left` (a guest's Pip goes home with them). Every game: **one** `OmniLight3D` (`PetGlow`, no shadows, range 7, warm for a cat, cool for Pip) picked 5 times a second and moved onto the pet every frame, fading in and out; `hear_own(text)` (the parrot repeats the line 1.2 s later, and one it knows every 45–90 s; only this player's own parrots within 16 blocks); `keep_pip_record()` every 2 s (this child's Pip's name, collar and heart into the profile, saved when they change); `bring_pip()`. |
| The pet's card | `ui/pets/pet_panel.gd` (`PetPanel`), `ui/pets/pet_heart.gd` (`PetHeart`) | A tap on your own pet (it is also a pat) opens it: the name, a heart drawn as big as the pet is happy, SIT / COME, NAME (12 fun names a page, MORE NAMES; 13+ also a typed name, checked here and on the host), COLLAR (8 colour swatches), CLOSE. 440 px wide at y 150, clear of every always-visible HUD button at 16:9 and 20:9 (tested); closes when the pet goes, strays 14 blocks, or the pause menu opens. |
| Session | `autoloads/session.gd`, section `# --- M3 Task 11` at the end | `pet_request_treat`, `pet_request_pat`, `pet_request_name` (cut to 64 characters), `pet_request_collar`, `pet_request_pip` (a cleaned record), host signals of the same names, `pet_band_of(peer)` (the registered chat band, under 13 when none). |
| Taps | `entities/player/block_interactor.gd` | A tap on an animal holding a treat → `pet_request_treat` (and `request_pet` for a wild dog or cat); a tap on your own pet → `pet_request_pat` and the signal `pet_tapped` (the card); a treat never places a block. |
| Chat | `ui/hud/chat_panel.gd` | Signal `own_line_sent(text)`: this player's own typed line (after the filter) or quick phrase, emitted where owner #38's bots hear it. `core/rules/chat_commands.gd`: `/summon fox`, `parrot` and `pip`; `/give` reaches the treats (`_LAST_ITEM_ID` 434; RED: "expected 430, got null"). |
| Saves | `world/world_meta.gd`, `core/save/profile_data.gd`, `core/save/profile_backup.gd` | `WorldMeta.pets[i]` keeps `collar` and `happiness` (cleaned; an M1b pet gets the owner's colour and 0.7; a name the filter refuses becomes a fun name); Pip is never in a world (not tameable, and the sandbox skips him). `ProfileData.pip` (`{}` or `{name, collar, happiness}`); the backup never loses Pip and a profile with Pip is not "new". |
| Sounds | `autoloads/audio.gd` | Named hooks `yip` (fox), `squawk` (parrot), `beep` (Pip), on stand-ins (the bark, the cluck, the ding) until the audio pass gives each its voice. |
| Sandbox | `scenes/sandbox.gd` (section at the end + one line each in `_ready`, `_start_host_or_solo`, `_setup_local_player`, `save_world`, `_restore_pets`, `_on_pet`, `summon_animal`) | `_add_pets`, `_start_pets` (the monsters' coins, `_unfound_secrets` from the secrets' rules and state, Survivor's treat from `Session.inventory_of(peer)`, Pip through the animal spawner), `_setup_pets_local` (the card, Ambience's underground and the sky's night for the glow, the chat's own lines, Pip on spawn), `bring_pip()` (for M3 Task 15), `_summon_pip`. |
| Smoke run | `tools/pets_smoke.gd`, `tools/pets_smoke_steps.gd` | A new Sandbox world on real terrain (below). |

## Hooks in shared files (for the lead)

| File | What |
|---|---|
| `scenes/sandbox.gd` | `_add_pets()` after `_add_playdates()`; `_start_pets()` after `_start_animals()`; `_setup_pets_local()` after `_i_setup_local()`; `save_world` skips Pip; `_restore_pets` passes `collar` and `happiness`; `_on_pet` counts with `pets.pets_owned(peer_id)` (Pip never counts) and says "Tap X to see its card."; `summon_animal` hands `pip` to `_summon_pip`; section at the end |
| `entities/animal/animal.gd` | `PET_NAMES`, `setup`, `to_save`, `pet_tap`, the sync list, `_make_collar`'s colour, the wag speed, `_process` (`_pet_show`), `_walk` (`_plays`), `_decide` (`_pet_hold`, the pointing look), `_sniff_treasure`; section at the end |
| `autoloads/session.gd` | section at the end |
| `entities/player/block_interactor.gd` | signal `pet_tapped`; `_tap_pet` before the old pet tap; treats never place; section at the end |
| `ui/hud/chat_panel.gd` | signal `own_line_sent`; one emit in `_bots_hear` and one in `_to_own_bots` |
| `ui/hud/block_palette.gd` | the PETS tab and page (section at the end) |
| `ui/hud/block_icons.gd` | two lines: treats' icons from `PetPictures` |
| `data/items/item_ids.gd`, `core/economy/shop_rules.gd`, `core/rules/animal_rules.gd`, `core/mind/species/animal_species.gd`, `entities/animal/blocky_animal.gd`, `core/rules/chat_commands.gd`, `autoloads/audio.gd`, `world/world_meta.gd`, `core/save/profile_data.gd`, `core/save/profile_backup.gd` | small additions, each marked "M3 Task 11" |
| Tests changed | `tests/unit/test_item_ids.gd` (the rows now include `ItemIds.TREATS`), `tests/integration/test_palette_armory.gd` (5 tabs), `tests/integration/test_counted_hotbar.gd` (the PETS page counts) |

**For M3 Task 15 (the tutorial):** `PetRules.give_pip(Profile.data)` (true the first time; never resets a named
Pip), then `sandbox.bring_pip()` — Pip appears next to the child now, and in every world after.
**For owner #39 (the baby dragon):** a row in `PetRules.KINDS` (its tame way, perks, favourite treat), a species in
`AnimalRules.SPECIES`, boxes and a `COLLAR` in `BlockyAnimal`, traits in `AnimalSpecies.TRAITS`
(`test_every_kind_has_a_body_perks_a_way_to_become_a_pet_and_a_favourite_treat` lists what is missing). A dragon
that hatches from an egg is `GIVEN` like Pip; if it should live in the profile too, generalise `ProfileData.pip`.
**For the audio pass:** the pets' voices are the hooks `yip`, `squawk`, `beep` in `Audio.SOUNDS` (and the dog's
`bark`, which the perk's bark plays).
**For owner #41 (more animals):** the fox and parrot here are Green Meadows' own (by the woods, by the water);
#41's fennec and arctic foxes are other species.

## Tests (RED → GREEN)

Suite: **3561 → 3652** passing (`tests/run_tests.sh` through `tests/suite_slots.sh`, exit 0; 383 scripts).
Commits: `311c202` (the feature), `407e9b8` (`/give` treats).

| Test file | Tests | RED |
|---|---|---|
| `tests/unit/test_pet_rules.gd` | 27 | "Identifier PetRules not declared", "Cannot find member TREATS in ItemIds"; then `after_time` (a first draft kept values below the floor below it), and the name list (three names were bot friends' names: Sprout, Pebble, Comet → Muffin, Toffee, Honey) |
| `tests/unit/test_pet_perks.gd` | 9 | "PetPerks not declared"; one test's own expectation was wrong (the nearest secret) |
| `tests/unit/test_pet_echo.gd` | 6 | "PetEcho not declared" |
| `tests/unit/test_pet_saves.gd` | 3 | "Invalid access to property or key 'collar'" (the world save dropped them) |
| `tests/integration/test_pet_director.gd` | 29 | written before the director, first run after it (all green); mutation checks below |
| `tests/integration/test_pet_panel.gd` | 10 | first run: the card was 453 px wide over the treasure compass (three 135 px buttons in a row → two rows of two); a test that set the size of an anchored control was an engine error |
| `tests/integration/test_pet_animals.gd` | 7 | the fox's first trip came as late as the dog's (both started at 10 s: now half its own `sniff_every`) |
| Changed | 3 | the palette: a TREATS row on ARMORY made the palette 658 px high, over the hotbar (642): the PETS page instead |

Mutation checks on the director (each broken rule made its test fail, then restored): a pet whose child left
still losing heart ("a pet waiting for its child never gets sadder"); every parrot squawking the line, not only
this player's ("another child's parrot never says my words"); a light per glowing pet ("one light, never one per
pet"); no owner check on renaming ("only its own child renames it").

## Smoke run (headless, real terrain)

`XDG_DATA_HOME=<private dir with "smoke" and a copy of profile.json> godot --headless --path . --script res://tools/pets_smoke.gd`

A new Sandbox world: three pets tame a summoned dog ("Sunny"); two treats tame a fox and a parrot; Pip comes
from the profile, 1.9 blocks from the child; the dog is named Mochi and gets collar 4 (the collar's material is
colour 4); a biscuit raises its heart 0.70 → 1.00; a summoned slime makes the dog bark within 0.2 s ("!" shown);
a coin 3 blocks beyond the dog (5.8 from the child) flies to the child; the chat's own line "Hello!" comes back
as "Squawk! Hello!" over the parrot; at night the one light sits on Pip (the nearest glowing pet) and the world
has exactly one `PetGlow`; the world saves dog, fox and parrot (the dog with its name and collar) and not Pip;
the profile keeps Pip. Pointing at a secret is checked when one lies within 24 blocks (none did at this seed's
spawn; the director test covers it). 5 runs: 4 passed; the first run's night check found no glowing pet (before
its message printed the state: the check now prints night, underground and every pet's distance; the lead should
look at it if it shows again).

## Measurements

- The glow on every game: picking the pet to light with 12 glowing pets, 71 µs per pick (5 picks a second; load
  about 15–20); between picks a frame moves one light (one transform write) and fades its energy.
- The host's perk tick: 5 times a second over the pets only; the monsters are gathered once per tick and only
  when a dog's perk is active; coins only when a dog is active.
- No per-event materials: the "!" is the monsters' shared mesh; collars share one material per colour; Pip's
  realistic material is one for every Pip with the animals' own shader flags (vertex colours; only metal and
  roughness differ), so no new shader compiles; the bubble and the name tag are one Label3D each, made once.

## Patterns (godot-prompter skills)

- `3d-essentials` (the glow): **one OmniLight3D per game without shadows**, moved to the chosen pet. Rejected: a
  light per pet (cost grows with pets, the brief's "not a light per pet"), an emissive material on the cat (a
  new shader variant and a material change per event), a SpotLight (direction to manage for nothing).
- `godot-ui` (the card): a `PanelContainer` of containers built in code with `UiKit` / `OnlineUi` like the other
  panels, pages swapped by rebuilding the content. Rejected: `TabContainer` (the §8 gotcha: its internal
  nodes break child counts), a `Window`/popup (focus and touch trouble on phones), a Theme resource.
- `multiplayer-sync` (LAN / online): state that rarely changes as synced properties **on change** (collar; the
  heart quantised to 1/20, so it changes every few minutes, not every tick), events as reliable RPCs on the
  animal (bark, point, dig). Rejected: syncing perk timers or the host's exact heart, a second synchronizer.
- The perks follow the animals' cost rules (M1b, M2 Task 4): decisions ≤ 10 Hz, nothing per frame but the
  light's move and small timers, `is_instance_valid` for players and pets that can vanish.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **A tap on your own pet pats it and opens its card; SIT / COME moved onto the card** (M1b: a tap made it sit).
   The card is what "tap a pet → a small picture panel" asks for, and a tap that opens a card and also toggles
   sitting would make every look at the card move the pet. *Cost if wrong:* one more tap to make a pet sit.
2. **Coins within 4 blocks of the dog** (not of the child) go to the dog's child, only once landed (the pop out
   stays). *Cost if wrong:* none known.
3. **The bark:** once per monster coming within 16 blocks of the dog, at most every 8 s, with the monsters' "!"
   over the dog on every game; no toast and no new arrow (the danger arrow exists). *Cost if wrong:* a busy
   night barks every 8 s; one constant.
4. **The glow:** one light per game, on the nearest glowing pet whose perk works (any child's); "dark" is where
   this game's player is (Ambience's underground ≥ 0.5, or night). **Pip glows too** (his lamp; each kind has a
   perk). Kept on the Low preset (one shadowless light). *Cost if wrong:* Low players who need every frame can
   lose one light's cost; `DefenseDirector.lights_for` shows how to switch it off by preset.
5. **Foxes** live by the woods, **parrots** by the water (35 % of such herds, from the seed); both are tamed with
   **two treats of any kind from the same child** (a treat is liked by any would-be pet; its favourite raises a
   pet's heart most). Three quick pets never tame them. *Cost if wrong:* taming counts are one constant.
6. **The fox** sniffs every 10 s (the dog 20), trots there 1.4× faster, digs a bigger dirt puff. **The dig puff
   now shows on every game** (M2 Task 17's showed on the host only). *Cost if wrong:* none known.
7. **The parrot's words** are only its child's own lines (typed after the chat filter, or quick phrases), kept
   and shown **on the child's own device only** — never sent, so no other player ever sees them ("only
   offline/own"). A guest's parrot on the host's screen says nothing. Commands are never repeated; 28 characters,
   6 lines, a new line 1.2 s later and an old one every 45–90 s. *Cost if wrong:* friends don't see a parrot
   talk; showing it to others would need the chat's age rules (never other children's words).
8. **Pointing:** every 15 s the parrot turns its beak to the nearest secret nobody found within 24 blocks (3D
   distance, the secret's anchor) and holds 2.5 s; a squawk and a sparkle trail on every game; it never walks
   there (the dog and fox lead; the parrot only hints). *Cost if wrong:* hints are one constant apart.
9. **Names:** a list of 32 fun names for everyone (none a bot friend's name); a typed name only for 13+ and only
   through the username filter (letters, digits and _, 3–16, no blocked words), checked on the card and on the
   host with the sender's registered chat band (a player who never registered counts as under 13). Pet names
   show on name tags to every player. *Cost if wrong:* the same exposure as usernames today.
10. **Collars:** the 8 M1b owner colours; unchosen = the owner's colour (M1b's look is kept for every old pet).
11. **The heart:** starts 0.7; a pat +0.05 (0.6 s apart), a treat +0.15, its favourite +0.3; it falls 0.01 a
    minute **only while its child is in the world** (never while away, never while the game is closed), never
    below 0.25. A happier pet wags faster and jumps along more often (60–100 %); following, obeying, perks and
    presents never depend on it, and a pet never leaves. *Cost if wrong:* numbers in `PetRules`.
12. **Treats** 430–434 (five: each kind's favourite), 2 gold each at Tilly (× 2^(u−1)), on her POTIONS shelf (one
    shelf for things used up, so the shop keeps its four sections for owner #35's work); never bought back; free
    in Sandbox on the palette's new **PETS** tab (ARMORY had no room). A treat is used only when something
    happened. *Cost if wrong:* a fifth shop section later.
13. **Pip lives in the profile** (`ProfileData.pip`) and comes into every world the child plays — Sandbox,
    Survivor, every universe, a friend's LAN world (the guest's game asks the host); he goes home with a guest
    who leaves; no world saves him; the backup never loses him; he never counts toward the 3 pets. `/summon pip`
    (Sandbox) brings the child's own Pip, or a visiting Pip for that game when they have none (only
    `give_pip` — the tutorial — gives him for keeps). *Cost if wrong:* a Pip per world would need the old
    `WorldMeta.pets` path back (one line in `save_world`).
14. **Pip's two looks:** blocky, the animals' vertex colours; realistic, the same boxes in shiny metal (one shared
    material with the animals' shader flags). No imported model (CC0 robots would bring a new shader and an
    import to test on the emulator). *Cost if wrong:* a nicer realistic robot later is one mesh swap.
15. **Two Pips:** bot friends' first name is also "Pip" (`BotRules.NAMES`, M2 Task 15); the spec names the robot
    Pip, so the robot keeps it. *Hand-off:* the lead may drop "Pip" from `BotRules.NAMES`.
16. **No HUD edits:** the card is its own overlay in the sandbox's CanvasLayer (blockers registered, closed by the
    pause menu). It may cover HELP UP or TEAM PHOTO (context buttons) while open. *Cost if wrong:* close the card
    to reach them; the card could hide when they show.

## What the lead should check on the emulator

- Sandbox: `/summon dog`, tap it three times → "… is your pet now! Tap … to see its card."; tap it again → the
  card: the heart, SIT / COME, NAME (list pages), COLLAR (the band changes colour on the dog).
- `/summon fox` and `/summon parrot`, PETS tab → hold Berries / Seed Cracker, tap each twice → tamed. Say
  something in chat (or a quick phrase) near the parrot → "Squawk! …" over it a moment later.
- `/summon pip` → Pip rolls up; switch GRAPHICS to REALISTIC: Pip turns shiny, no hitch when he first shows.
- `/time night` near a pet cat or Pip: one soft light on it; walk into a cave in daylight: the same. Check the
  frame time with a cat and Pip in both styles (one extra light).
- `/summon slime 1` near the dog: a bark and a red "!" over it.
- Survivor: Tilly's POTIONS shelf has the treats at 2 gold; a treat is used from the bag when fed.
- LAN (two instances): a guest's collar and name changes show on the host and back; the guest's Pip comes with
  them and goes when they leave.
