# MAKE MY SHORT: a child's own Shorts, kept on the device (spec §5.12b "As built (My Shorts)")

The brief (the lead, 2026-10-01), from spec §5.12b's "next": "A child making their own Short (from the game's photos
and a few taps) and keeping it on the device". A child makes a short learning (or showing-off) animation from the
game's own pieces with a few taps and keeps it **on this device only**: no upload, no sharing, no other child ever sees
it. Built in the worktree branch `worktree-agent-aa5a42327f4aeb21f`, reset to `lead-merge` (`9a2e5ff3`) first, while
other agents made more learning reels and looked into the gold doubling. No editor, emulator or adb was used; pictures
came from real windows (`tools/my_shorts_shots.gd`); the lead checks Android on the emulator (the list at the end).

## What a child sees, step by step

1. **In the Theater's SHORTS tab**, the filters are now four chips, two by two, each a picture beside its word: SHOWS,
   LESSONS, LIKED and **MY SHORTS** (a little person). MY SHORTS shows the child's own Shorts, the newest first. While
   there are none, the player says "Make your very own Short: your photos, your words, your music! It stays on this
   device." over a big pink **MAKE A SHORT** button; a MAKE A SHORT button (a plus) also sits above the list.
2. **MAKE A SHORT** opens the maker over the tab. On the left, five numbered dots (the step lit yellow, the done ones
   pink) and the step's words; on the right, the Short as it is now, in the same 9:16 player as every Short (a tap
   plays and pauses it). BACK at the bottom left (CLOSE on the first step), NEXT at the bottom right (SAVE at the end),
   a short hint or a kind word between them.
3. **KIND: "What kind of Short?"** Three big cards: **HOW I BUILT IT** (a camera: "Your photos and your words"),
   **3 FACTS ABOUT…** (a planet: "A planet, a wonder or an animal"), **STEP BY STEP** (stairs of blocks: "How to build
   it, layer by layer"). A tap goes on.
4. **PICK.**
   - How I built it: "Pick 2 to 4 photos": the child's photos from photo mode, newest first, nine a page (◀ 1 of 2 ▶).
     A tap numbers a photo 1, 2, 3, 4 (the order it plays in); a fifth says "4 photos at most". With no photos: a
     camera and "No photos yet! In your world, tap MORE, then PHOTO, and take a few of your build."
   - 3 facts about…: "What is it about?": PLANETS, WONDERS, ANIMALS, then eight pictures a page (the planets in the Star
     Map's colours, the Wonders Passport's stamps, the animals' portraits) with their names; the picked one is pink and
     framed and its name is read aloud.
   - Step by step: "Pick a build": the child's own stamps (My Stamp 1…) and the game's six blueprints (a house, a tower,
     a bridge, a tree, a rainbow, a fort), each drawn from above its front corner with the game's own block pictures.
5. **WORDS: "Your words".** On the left, a row for each scene: TITLE, PHOTO 1…4 (or FACT 1…3, STEP 1…3) and THE END,
   each with its words now. On the right, the slot's **quick phrases** ("First, I picked my blocks.", "I made it
   colourful!"…; for facts the subject's facts; for the end, questions): a tap uses one and **reads it aloud** (no
   reading needed). **TYPE MY OWN** (a pencil) puts a field at the top right (above a phone's keyboard) with OK: the
   typed words go through the game's word filter for children, English letters only, no names; when they can't be
   used, a kind word says why ("That word can't go in a Short. Try saying it another way!", "No names in a Short, to
   keep everyone safe. Your avatar shows it's yours!"). Facts and the ending are picked, never typed. The preview jumps
   to the scene being changed.
6. **LOOK: "Look and sound".** BACKDROP: nine small backdrops (sky, grass, sea, sunset, night, space, paper, chalk,
   lab), the chosen one framed yellow. MUSIC: No music, Ode to Joy, Spring, Morning, Waltz, Für Elise, Night Music,
   Mountain King (picking one plays the Short with it). VOICE: VOICE ON / VOICE OFF (off: captions only).
7. **SAVE: "Watch it, then SAVE".** The Short plays on the right; on the left its title, its kind and seconds, and "It
   stays on this device. Only you can watch it." SAVE keeps it, a jingle plays, and MY SHORTS shows it **playing**.
8. **In MY SHORTS** a Short of one's own plays like every Short: swiped, paused with a tap, LIKE (a heart: it waits in
   LIKED too), LEARN IT where it fits (a planet's or a wonder's opens the Star Map; a build's or an animal's has none:
   the button rests), "My Short" in pink over its title. Under the list, **CHANGE** (the maker again, from PICK, the
   Short's own choices in it) and **DELETE** (tapped once it says SURE? for four seconds; tapped again the Short, its
   heart and its seen mark go).
9. **At most 20.** With 20, MAKE A SHORT shows "You have 20 Shorts: the most this device keeps. Delete one in MY
   SHORTS to make a new one."
10. Back (Android Back, Esc, a controller's Circle / B) goes a step back in the maker; on the first step it closes the
    maker and the Theater stays. A controller's D-pad reaches every choice of every step (the focus starts on the
    page's first choice), Cross / A picks.

What the Shorts look like (frame sheets, a picture every 2 s, `tools/my_shorts_shots.gd -- --sheets`):
- **How I built it** (28.5 s with three photos): the title on a yellow sticker, the child's avatar (their own look,
  drawn) sliding in and waving, the first photo popping in tilted, two stars spinning; then a scene a photo: the photo
  in a white frame with a soft shadow drops in with a bounce (or slides, or pops: in turn), a yellow number sticker
  pops on its corner, the photo drifts slowly closer while its caption is read, the avatar gives a thumbs up, claps,
  cheers; the end: every photo small and tilted round the avatar cheering, stars, and the question.
- **3 facts about…** (29-34 s): the title over the subject's picture (a planet with its rings, a wonder's stamp, an
  animal bouncing) and the avatar waving; a scene a fact: a big number pops, the picture slides in from a side and
  drifts, a star, the avatar thinking, thumbs up, clapping; the end: the picture, the numbers 1 2 3 popping in turn,
  the avatar cheering.
- **Step by step** (28.5 s): the whole build pops in under its title; a scene a step: STEP 1, 2, 3, the build rising
  layer by layer (each layer drops in and fades in, a layer pop sounding); the end: the whole build, stars, cheering.

## The safety and fairness rules, and their proof

| Rule | How | Proof |
|---|---|---|
| Nothing leaves the device | The recipes are `ProfileData.my_shorts`, a `ProfileBackup.DEVICE_ONLY_FIELDS` entry: left out of the backup, and a merge keeps this device's. Their hearts and seen marks are left out too (`_leave_out_device_only`). Photos and stamp copies are files in `user://my_shorts/`, never in the profile. | `test_my_shorts_privacy.gd`: the backup's text has no `mine:` id, no caption, no photo name; a merge with a newer server copy keeps them; against the fake server, making, liking, keeping and deleting a Short make **no upload** (the backup is the same), and a real change uploads without them; the maker's code names nothing that talks to a network (HTTPRequest, OnlineService, Session, rpc, multiplayer, Nakama, JavaScriptBridge, WebGlue, sockets, PhotoShare, ProfileSync…). `test_my_short_maker_view.gd: test_nothing_talks_to_a_network_while_making`: no HTTP request or peer node appears while a Short is made and saved. The smoke run: the backup's text has none of it. |
| No names of real children | Typed words: `MyShortRules.check_words` refuses the child's username (whole word, any case, or spelled out) and "my name…", "I am called…", "I'm called…"; the maker never puts the username, a friend's name or a credit in a Short; the avatar is a drawing of the child's look. | `test_my_short_rules.gd: test_no_names_of_real_children`, `test_my_short_maker_view.gd: test_typed_words_go_through_the_filter` |
| Typed words are safe for children | The game's own filter, `ChatRules.filter_code` (bad words, phone numbers, emails, links, addresses, "my school"), then English letters, digits and plain punctuation only. Facts and endings are picked, never typed. | `test_typed_words_go_through_the_game_s_filter`, `test_english_letters_only`; every quick phrase passes the same check |
| No rewards for making many | No gold, stars, badges, progress events, stickers or counts anywhere in the maker. | `test_my_shorts_privacy.gd: test_making_shorts_rewards_nothing` (five Shorts change nothing else in the profile) |
| English only | Every word is English; no language picker; typed words in other alphabets are refused. | `test_english_letters_only` |
| Every Short passes `ShortCheck` | The maker paces each scene (its words read at 2.5 words a second, then 1.8 s to look, at least 5-6 s; the whole stretched to 20 s) and lays every actor inside the frame above the caption's band. | `test_my_short_maker.gd`: 60 random How I built it, every subject of 3 facts (planets, wonders, animals), every blueprint and stamps of 2-16 layers; `test_my_short_player.gd`: 70+ made Shorts drawn: every actor inside the frame (at its arrival and its scene's end), never under the caption, no words on words |

## The game's facts in "3 facts about…"

- **Planets** (17: the Sun, the eight planets, Pluto and the Moon, Io, Europa, Ganymede, Callisto, Titan, Triton):
  the Star Map's own three facts each (`StarMap.SOLAR`), already checked against NASA's fact sheets by their agents.
  The game's own planets and universes stay out (their "facts" are the game's).
- **Wonders** (14 of the 21): the Wonders Passport's facts (`WonderFacts`) that fit a caption (≤ 90 letters), checked
  when the tours were built (`wonders-ancient.md`, `wonders-new-seven.md`, `wonders-nature.md`). A wonder needs three
  such facts: the Colossus, the Grand Canyon, the Great Barrier Reef, Rio's harbour, Everest, the northern lights and
  Parícutin have longer ones today (next: a caption-sized version of a fact, kept beside it in WonderFacts).
- **Animals** (27 real ones): the Animal Book's fact first (`AnimalBookRules.FACTS`), then two more kept for the Shorts
  in `MyShortFacts.ANIMAL_FACTS` (new, short, checked):

| Animal | Its two new facts | Checked against |
|---|---|---|
| Dog | Hears high sounds people can't; wags its tail to show how it feels | Britannica, "dog" (hearing to about 45 kHz); Dogs Trust, body language |
| Cat | Whiskers help it feel if it fits through a gap; can't taste sweet things | Cats Protection, "cat whiskers"; Li et al. 2005, PLoS Genetics (the sweet-taste gene Tas1r2 is broken in cats) |
| Pig | Rolls in mud to cool down (can hardly sweat); digs with its snout | Britannica, "pig" (few working sweat glands, wallowing; rooting) |
| Cow | A stomach of four parts; chews the cud | Britannica, "ruminant" (rumen, reticulum, omasum, abomasum) |
| Sheep | Sees almost all the way round; most sheep's wool keeps growing until cut | Britannica, "sheep"; the British Wool board (domestic woolly breeds don't shed) |
| Chicken | No teeth: swallows tiny stones to grind food; dust-bathes | RSPCA, "chickens" (grit in the gizzard; dust bathing) |
| Rabbit | Teeth never stop growing; turns each ear on its own | RSPCA / PDSA, "rabbits" |
| Fish | Breathes with gills; many swim in schools | National Geographic Kids, "fish" |
| Fox | Hears a mouse under the snow; a baby is a cub or a kit | National Geographic, "red fox" (hunting by sound under snow); The Wildlife Trusts |
| Parrot | Two toes forward, two back; some live over 50 years | Britannica, "parrot" (zygodactyl feet; large parrots' long lives) |
| Horse | The biggest eyes of any land mammal; a foal stands soon after birth | Britannica, "horse"; The Horse Trust (foals stand within about an hour) |
| Donkey | Its call is a bray; remembers places and friends for many years | The Donkey Sanctuary, "donkey facts" (memory of places and companions over many years) |
| Goat | Rectangle-shaped pupils; a baby is a kid | Britannica, "goat"; Banks et al. 2015, Science Advances (horizontal pupils of grazers) |
| Deer | Most male deer grow new antlers every year; a baby is a fawn | The Wildlife Trusts / British Deer Society (antlers cast and regrown yearly) |
| Duck | Webbed feet work like paddles; ducklings follow the first moving thing they see | RSPB; Konrad Lorenz's imprinting (Britannica, "imprinting") |
| Frog | Starts life as a tadpole in water; many catch insects with a sticky tongue | National Geographic Kids, "frog life cycle" |
| Turtle | Its shell is part of its skeleton; sea turtles rest under water for hours | Britannica, "turtle"; NOAA Fisheries, "sea turtles" (resting dives of several hours) |
| Squirrel | Its tail helps it balance; its front teeth never stop growing | The Wildlife Trusts, "red/grey squirrel"; Britannica, "rodent" |
| Owl | Turns its head much further round than we can; flies almost silently | RSPB / Britannica, "owl" (up to about 270°; soft-edged feathers) |
| Hedgehog | About 5,000 to 7,000 spines; many sleep through the winter | British Hedgehog Preservation Society |
| Camel | Two rows of long eyelashes keep out the sand; drinks a lot quickly | Britannica, "camel"; San Diego Zoo Wildlife Alliance |
| Lizard | Some drop their tail to escape and grow a new one; many flick their tongues to smell | Britannica, "lizard" (autotomy; the vomeronasal organ) |
| Fennec | Lives in the Sahara; big ears lose heat and keep it cool | Britannica, "fennec"; Smithsonian's National Zoo |
| Penguin | Almost all live in the south half of the world; emperors huddle to keep warm | Britannica, "penguin" (only the Galápagos penguin's range crosses the equator); British Antarctic Survey |
| Polar bear | Great swimmers; live in the Arctic near the North Pole | WWF, "polar bear" |
| Arctic fox | Fur under its feet; lives in the cold far north | National Geographic, "arctic fox" (furry paws: *Vulpes lagopus*, "hare-footed") |
| Seal | Keeps warm with blubber; a baby is a pup | NOAA Fisheries, "seals" |

The game's fantasy friends (Pip, the baby dragon, gummy bunnies, candy birds, Moon bunnies) stay out of "3 facts":
their facts are the game's, and a child's Short about facts teaches true things.

## How it is built

| File | What |
|---|---|
| `core/shorts/mine/my_short_rules.gd` | MyShortRules: ids (`mine:<n>`), the cap, templates and their words, quick phrases, titles and endings, backdrops, music, blueprints, the words check, the new actor kinds' checks, `clean_recipe` |
| `core/shorts/mine/my_short_facts.gd` | MyShortFacts: planets, wonders, animals and their facts, titles, LEARN IT links |
| `core/shorts/mine/my_shorts_data.gd` | MyShortsData: `ProfileData.my_shorts` (recipes, newest first, ids never reused, the files they use) |
| `core/shorts/mine/my_short_maker.gd` | MyShortMaker: a recipe made into a Short (paced, laid out, the three templates) |
| `core/shorts/mine/my_short_album.gd` | MyShortAlbum: `user://my_shorts/photos` and `builds`, the photo folder's photos, tidying, pictures loaded on workers |
| `ui/shorts/mine/my_short_drawers.gd` | The `photo`, `me`, `wonder` and `build` actors' drawers; IsoBuild (a build as cached per-layer meshes) |
| `ui/shorts/mine/my_short_maker_view.gd` | MyShortMakerView: the maker's five steps, the preview, typing, the pad |
| `ui/shorts/shorts_view.gd` | MY SHORTS, MAKE A SHORT, CHANGE, DELETE, the maker over the view (the chips two by two) |
| `core/shorts/short_feed.gd` | ShortFeed.MINE, `mine_entries`, `short_of` |
| `core/shorts/short_check.gd`, `short_kinds.gd`, `short_rules.gd`, `ui/shorts/short_drawers.gd` | A `mine:` Short checked (its topic, LEARN IT optional, photos only there, music and voice); the four kinds plugged in; the "My Short" topic |
| `ui/shorts/short_player.gd` | A Short's `music` (loaded on a worker, quietly on the effects bus) and `voice: false` |
| `ui/shorts/shorts_icon.gd` | camera, planet, stairs, pencil, music, plus, bin, person |
| `core/save/profile_data.gd`, `profile_backup.gd`, `core/shorts/shorts_data.gd` | `my_shorts`; device only; `ShortsData.forget` |
| `ui/theater/theater_panel.gd`, `scenes/sandbox.gd` | Esc and Android Back a step back in the maker; photo mode's photo kept in the album |
| `tools/my_shorts_shots.gd` (+ `_steps.gd`), `tools/my_shorts_smoke.gd` (+ `_steps.gd`) | Pictures, frame sheets, the bench; the smoke run |

A recipe, as kept in `profile.json` (200-600 bytes of JSON; twenty of the longest possible, four photos and four
80-letter captions each, are about 12 KB):

```json
{"id": "mine:3", "made": 1790000000, "template": "built", "title": "How I built my castle",
 "photos": ["p_20261001_101500.jpg", "p_20261001_101642.jpg"], "captions": ["First, I picked my blocks.", ""],
 "ending": "What will you build next?", "backdrop": "sky", "music": "spring", "voice": true}
```

## Rulings (each with what it costs if wrong)

1. **A Short is kept as its recipe, made when it plays** (MyShortMaker), not as the made scenes. Small (twenty of the
   longest are about 12 KB of the profile) and every Short gets the maker's later improvements. *If wrong:* a Short looks a little
   different after an update; keeping the made Short instead is one field.
2. **Device only means the whole field and its hearts stay off the backup**; a new phone, a reinstall or a cleared
   browser has no My Shorts. *If wrong (a family wants them back on a new phone):* a backup would need a grown-up's
   yes and the photos' upload; that is a new decision for the owner, not a default.
3. **The photos are small copies in the game's own folder**, made when photo mode takes one (640 wide, JPG, on a worker
   thread, every platform: a browser keeps its photos in the game, not in a folder), plus the photo folder's photos found
   (user://photos on a computer, Pictures/EasyCraft on a phone), copied when picked. The newest 40 copies and every one
   a Short shows are kept. *If wrong:* photos taken before this build show only where the folder can be read (a
   phone's own files in Pictures/EasyCraft; not a browser's); a deleted gallery photo stays in the Short (the copy).
4. **A stamp is copied for a Step by step** (`user://my_shorts/builds/b_<n>.txt`), so the Short stays when the stamp's
   slot is used again. *If wrong:* a few KB a Short.
5. **Three templates** (How I built it, 3 facts about…, Step by step). *If wrong:* more templates are a template's
   words, a maker function and a page (the forever roadmap).
6. **Typing is open to every child** (not the online chat's quick-chat-only rule for under-13): a Short is never seen
   by anyone else, and the game's filter still applies. *If wrong:* a child could type something unkind that only they
   see; the quick phrases are always there.
7. **The game's filter as it is** (`ChatRules.filter_code`): it refuses a few innocent words too ("street", "address",
   "my school"). *If wrong:* a child picks other words; the message says why.
8. **No names** = the username (and its letters spelled out), "my name…", "I am called…". Other names can't be known.
   *If wrong:* a child could type a friend's first name ("with Max"); it stays on their own device.
9. **Endings are picked, never typed** (every Short ends with a question to wonder about: ShortCheck). *If wrong:* less
   freedom at the end; four questions a template.
10. **Animals: real ones only, with two new facts each** (54, checked above). *If wrong:* a fact needs fixing in one
    table (`MyShortFacts.ANIMAL_FACTS`); a test keeps every one short and ending in a stop.
11. **Music: seven of the game's classical pieces or none, at −15 dB on the effects bus** (the Music bus rests while a
    Short plays). *If wrong:* the child's music volume doesn't change it; the pieces are not "own" universe pieces.
12. **At most 20 Shorts.** *If wrong:* one constant (`MAX_SHORTS`).
13. **DELETE asks SURE? (a second tap within 4 s)**; its heart and seen mark go; the album keeps only what the others
    use. *If wrong:* a slow second tap needs a third.
14. **No video export**: there is no save path for a video (photo mode and `CardPicture` save pictures; Godot's Movie
    Maker is a desktop command-line mode, not something a phone can run; phones' galleries don't play the MJPEG AVI it
    writes), and the brief allowed one only "if there is one". *If wrong:* a family can't keep a Short outside the game;
    the next step is a poster picture of the Short's scenes through `CardPicture.save_png`, behind the grown-ups' photo
    switch.
15. **Walking out (or EXIT, another tab) while making drops the unsaved Short** (no draft). *If wrong:* a child loses a
    half-made Short; a draft in the profile is the next step.
16. **The avatar in a Short is the child's look now** (the profile's), drawn (AvatarIcon), never a name. *If wrong:* a new
    look changes old Shorts too; it is still "me".
17. **The filters are four chips, two by two** (40 design px tall each: the view's finger-size rule); LESSONS' grade chips
    and the list moved 22 px down (SHOWS' list shows six rows, not seven). *If wrong:* one more swipe in a long list.
18. **The maker's preview plays by itself only on SAVE and when music is picked** (the child's own Short, which they just
    asked for), never in the feed. *If wrong:* one tap on the preview.
19. **LEARN IT for a child's Short**: a planet's or a wonder's opens the Star Map, others have none (the button rests).
    *If wrong:* an animal could link to the Animal Book; one function (`MyShortFacts.link_of`).
20. **ShortCheck knows a child's Short by its id** (`mine:<n>`): topic "mine", LEARN IT optional, and only it may show a
    photo; `music` and `voice` are checked for every Short. *If wrong:* none for the hand-made Shorts (their rules are the
    same as before).

## Performance

Windowed on this PC (`tools/my_shorts_shots.gd -- --bench`, the Theater's panel at 1600 × 720, six of every kind of
Short; the PC shared with other agents, load 7-10):

| Run | Frames | Average | p99 | Worst |
|---|---|---|---|---|
| MY SHORTS played and swiped (the voice on) | 10,114 | 1.48 ms | 3.16 ms | 14.3 ms |
| The maker, 24 changes with the preview playing (`--novoice`) | 10,840 | 0.89 ms | 2.01 ms | 18.8 ms |
| The same with the desktop's speech service | 6,112 | 1.58 ms | 2.98 ms | 32.2 ms |

A step's page builds in 1.4-4.5 ms and the preview in 1-4 ms of CPU, in different frames; the worst frames are a new
page drawn for the first time. What the review changed: a Step by step's build was a polygon a face (a tower: ~400
draw calls a frame, and 22 ms to make its Short: five actors each made the build again); it is now made once and kept
as per-layer meshes (two draw calls a layer; 5 ms); a quick phrase rebuilt the whole page (12 ms), now only the rows'
words change (1.5 ms); the photo picks, the backdrops and the music chips change in place. At a phone's 3-5× the worst
step change would be about 60-160 ms with the desktop's speech service (Android's text-to-speech is asynchronous) and
55-95 ms without: the lead checks it on the emulator.

## Tests and checks

- 67 new tests. Unit: `test_my_short_rules.gd` (13), `test_my_short_facts.gd` (6), `test_my_shorts_data.gd` (9),
  `test_my_short_maker.gd` (10). Integration: `test_my_short_album.gd` (6), `test_my_short_player.gd` (4),
  `test_my_shorts_privacy.gd` (6), `test_my_short_maker_view.gd` (11), `test_pad_my_shorts.gd` (2). The Shorts' and the
  Theater's own tests pass unchanged (`test_shorts_view`, `test_theater_shorts`, `test_theater`, `test_short_quality`,
  `test_short_feed`, `test_short_check`, `test_profile_backup`, `test_profile_sync`, `test_pad_screens`).
- **The smoke run** (`XDG_DATA_HOME=/tmp/…-smoke godot --headless --path . --script res://tools/my_shorts_smoke.gd`): a
  new Sandbox world, two photos in photo mode kept in the album, the Theater, MY SHORTS empty, a How I built it made from
  the two photos (a quick phrase, grass, Spring), SAVE: in profile.json, not in the backup's text, playing with its
  music; Android Back a step back, then the maker closed and the Theater still open; DELETE, SURE?; walking out:
  **22 ok, 0 failed**.
- **Pictures** (`tools/my_shorts_shots.gd -- --panel --sheets`, 1600 × 720 and 1280 × 720): MY SHORTS empty and
  playing, every step of the maker, the planets, wonders, animals and builds pages, the full card; frame sheets of six
  made Shorts. The review fixed: the kind cards' second line ran off the card (a label's size set before its wrapping:
  now wrapping first), the chosen backdrop's frame was drawn under its picture, the SAVE page said "stays on this
  device" twice, CHANGE and DELETE showed (disabled) while MY SHORTS was empty, the fact scenes stood still (the picture
  now drifts slowly), the avatar was small (96 → 104), the photos sat high (centre 236 → 244).
- **The full suite** (2026-10-01, rebased on `lead-merge` `96c226c4`: reels round 2 and the gold fix merged): 1,058
  scripts, 9,699 tests, **9,697 passing, 0 failing**, 2 risky (the generator's `test_the_column_cache_changes_nothing`
  and `test_chunks_meet_without_seams`, which make no assertions, as on lead-merge), no SCRIPT ERROR or Parse Error,
  exit 0, 57 min.

## What the lead must check on the emulator

1. **Typing on Android:** TYPE MY OWN opens the phone's keyboard; the field (top right of the maker) stays above it;
   OK and Enter keep the words; a refused word shows its kind message; after typing, walking and jumping work again.
2. **Photos:** take two photos in photo mode, open MY SHORTS → MAKE A SHORT → HOW I BUILT IT: they show (the album's
   copies); photos taken before this build show only if Android lets the game read Pictures/EasyCraft.
3. **Frame times:** swiping MY SHORTS for a minute and going through the maker's steps: ≥ 30 FPS, no frame over 100 ms
   (here the worst was 14 ms in the feed and 19-32 ms at a step change).
4. **Sound:** quick phrases are read aloud when tapped; a Short's music plays quietly under its voice and stops on
   EXIT, a pause and walking out; VOICE OFF Shorts are silent but for the music and sounds.
5. **Back:** Android Back goes a step back in the maker, closes it on the first step, and only then leaves the Theater.
6. **A controller:** the D-pad reaches every choice, Cross picks, Circle goes back.
7. **The size on a phone:** the kind cards, photo tiles, chips and phrase buttons readable and easy to hit.

## Merge notes

- Touches shared files (all additive): `core/shorts/short_check.gd`, `short_kinds.gd`, `short_rules.gd`,
  `short_feed.gd`, `shorts_data.gd`; `ui/shorts/short_drawers.gd`, `short_player.gd`, `shorts_view.gd`, `shorts_icon.gd`;
  `ui/theater/theater_panel.gd`; `scenes/sandbox.gd` (two lines); `core/save/profile_data.gd`, `profile_backup.gd`; the
  spec §5.12b; `docs/DEVELOPMENT.md`; `docs/store/data-safety.md`.
- New `class_name`s (run `--import` after the merge): MyShortRules, MyShortFacts, MyShortsData, MyShortMaker,
  MyShortAlbum, MyShortDrawers, MyShortMakerView.
- Another agent adding hand-made reels: nothing to do (MY SHORTS is its own filter). A new actor kind still plugs in as
  before; `ShortKinds._builtins()` and `ShortDrawers._builtins()` gained a loop for the four new kinds.
