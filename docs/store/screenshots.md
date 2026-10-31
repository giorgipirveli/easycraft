# Store graphics: the shot list for 0.4.0 (M5 Task 4; for the lead, on emulator-5554)

Written by the M5 Task 4 agent on 2026-09-25 from #43's art direction (`listing.md` → "Art direction",
`docs/devlog/parts/owner-43-identity.md` item 9) and the signature moments (spec §16). The agent has no emulator:
**the lead takes the pictures**, checks them against the rules below and uploads them with the new icon
(Play Console → Grow users → Store presence → Main store listing → Graphics). They replaced all eight pictures
of 0.3.2 (secrets on grass-block land; removed from `docs/store/graphics/` on 2026-09-27, still in git history).
**Uploaded 2026-09-27 02:55**: the 8 shots, the feature graphic and the icon from `graphics/next/` are the live set.

**2026-09-27: taken by script instead.** `tools/store_shots.gd` takes all eight and the feature graphic's photo on the
desktop (the real game and HUD, 1920 × 1080, a made-up player "SwiftDragon54"); the picks are in
`docs/store/graphics/next/` (`shot-1-wake.jpg` … `shot-8-book.jpg`, `feature-graphic.jpg`). How it sets each moment
up, and what differs from the rows below: `docs/devlog/parts/store-shots.md`.

## Play's rules (checked 2026-09-25) and ours
| What | Play's rule | Ours |
|---|---|---|
| App icon | 512 × 512, 32-bit PNG, ≤ 1 MB | the buddy mark, `docs/store/graphics/next/icon-512.png` (made by `tools/make_brand_art.py`) |
| Feature graphic | 1024 × 500, JPEG or 24-bit PNG (no alpha) | below; keep the buddy and the wordmark inside the middle 80 % (Play may crop the edges or lay a play button over the centre in some places, so nothing important dead centre either) |
| Phone screenshots | 2–8; JPEG or 24-bit PNG (no alpha); each side 320–3,840 px; the long side at most **twice** the short side | **8, 1920 × 1080 (16:9)**, landscape, the order below. The emulator's own 2400 × 1080 is 2.22 : 1, over Play's limit, so it cannot be uploaded as it is (see "Taking them") |
| Promotion | Play recommends at least 4 landscape 16:9 screenshots of 1080 px or more for a game to be featured | all 8 are 16:9 |
| Tablet screenshots (7", 10") | optional | after M5 Task 3's tablet layout check (same list, a tablet AVD) |
| Content | must show the real game, not mislead | real gameplay from the 0.4.0 build; nothing that is off in 0.4.0 in frame: **not the Shorts Theater** (its building stands near the spawn in Survivor worlds: turn the camera away), not the shop, not the developer menu or an FPS counter |

Ours, from #43: the new default avatar (orange tee, teal trousers, the buddy badge) or a dressed-up one in every
picture with a player (never the old yellow-and-blue classic look); **BLOCKY style** (the brand's look) unless a row
says otherwise; the HUD visible and readable (photo mode hides it, so use a plain screenshot) except the feature
graphic; no text over faces; never a plain grass-block landscape as picture 1 or 2; no other game's name anywhere.

## Before you start (one time)
1. **Build:** a debug APK of the 0.4.0 tree (`com.giorgi.game`), so the profile can be edited with `run-as`. In a
   debug build the pretend store is on; with `purchases: ["plus"]` in the profile nothing about the shop shows.
2. **Profile** (`adb shell run-as com.giorgi.game`, `files/profile.json`, as on 2026-09-25 08:40): `universe_unlocked`
   5 (every universe's crystal shows in the Sandbox palette's SMART → PORTALS row), `purchases` ["plus"],
   `settings.show_fps` false, `settings.style` "blocky", a username that is clearly made up (e.g. "SwiftDragon54":
   it shows on the name tag). The game is English only (owner #52).
3. **Avatar:** AVATAR → JUST ME (the new default), or a costume for pictures 5–8 if you like variety (the Cube Hero
   or the Fairy: our own designs, no book hero).
4. **16:9 screen:** `export ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554`, then
   `~/android-sdk/platform-tools/adb shell wm size 1080x1920` (portrait numbers; the game runs landscape at
   1920 × 1080 and lays its HUD out for 16:9, which the HUD tests cover). Take every picture with
   `adb exec-out screencap -p > shot-<n>-<name>.png`. **Afterwards `adb shell wm size reset`.** Never touch
   emulator-5556.
   *Fallback* if a 16:9 screen misbehaves: take them at 2400 × 1080 and cut 240 px off each side
   (`python3 -c "from PIL import Image; Image.open('in.png').crop((240,0,2160,1080)).convert('RGB').save('out.jpg', quality=92)"`),
   checking that no HUD button is cut in half; or cut only 120 px a side to 2160 × 1080 (exactly 2 : 1, still
   allowed, but not 16:9).
5. **Files:** save them as `docs/store/graphics/next/shot-<n>-<name>.jpg` (JPEG, quality ≈ 92, RGB; `next/` has a
   `.gdignore`, so they stay out of the APK), then move the old ones out when the upload is done.

Chat commands work in **Sandbox** only (cheats: `/time`, `/give`, `/summon`, `/size`, `/fly`, `/build`, `/secret`,
`/find`, `/peace`, `/weather`); `/give` takes a block's or item's name without spaces (`/give startblock`,
`/give portalframe`). Universe crystals cannot be given: they come from the palette (SMART → PORTALS) once the
profile has reached that universe. A universe's own Sandbox world is reached **through a portal**: build a frame,
put that universe's crystal in, walk in; after the first trip the SANDBOX menu offers "Choose a Sandbox world".

## The eight screenshots, in this order
| # | File | The moment | Where | Set-up | Camera and check |
|---|---|---|---|---|---|
| 1 | `shot-1-wake.jpg` | **A build wakes up**: googly eyes open, it blinks, the wand's sparkle | Sandbox, Green Meadows, a flat meadow by trees | `/time day`; build a small creature 3–4 blocks tall in bright blocks (orange and teal paint from BUILD's paints), or a secret buddy shape (the jolly snowman: white blocks, an orange nose); `/give wand`; tap the build | third person, the child beside the build, both faces visible; take it in the second after the tap (sparkles, eyes open). No other buddies in frame |
| 2 | `shot-2-size.jpg` | **Size Magic**: a tiny child at the feet of a giant buddy | the same world | build a big buddy (7–9 blocks tall, a head, arms, the same colours), wake it with the wand; `/size tiny`; stand between its feet | camera low, looking up at the buddy's face; the child's name tag readable |
| 3 | `shot-3-portal.jpg` | **A golden rainbow portal with the Candy Kingdom behind it** | the Candy Kingdom's Sandbox world | in Green Meadows' Sandbox: SMART → PORTALS → Portal Frame, build a ring round a doorway 2 wide × 3 high, put the **Candy Crystal** in the bottom row, walk in. You arrive in the Candy Kingdom with the portal back 3 blocks in front of you; `/time day` | stand beside the portal so it fills the left third (the golden frame, the rainbow swirl) and the candy land fills the rest; the child in frame. Both styles are fine; blocky preferred |
| 4 | `shot-4-dragon.jpg` | **The Dragon Realm at sunrise with the Sky Dragon and a sun lantern** | the Dragon Realm's Sandbox world (a Dragon Crystal portal, as in 3) | `/time sunrise`; `/summon skydragon`; wait until its golden sun lanterns stand; `/fly` if a higher view helps | the sea of clouds and the floating islands in the back, the dragon in the sky, one sun lantern with its beam, the child on an island edge; the boss bar on the HUD is fine. Take it before the dragon dives at you |
| 5 | `shot-5-dog.jpg` | **The dog digs up treasure** | Sandbox, Green Meadows | `/summon dog`, tap it three times quickly (it becomes your pet: a collar); `/secret treasure` (the nearest buried treasure) and `/find treasure` (the arrow); walk there with the dog; it sniffs about every 20 s and digs a dirt puff over the treasure | the dog mid-dig with the dirt puff, the child close, the find arrow on the HUD |
| 6 | `shot-6-hide.jpg` | **Hiding in a barrel as a goblin walks past** | Sandbox, Green Meadows, by a small house (`/build house`) | `/time night`; `/give barrel`, place it by the house; `/summon goblin 1` about 10 blocks away; tap the barrel to hide | the barrel in the foreground, the goblin in the moonlight 3–6 blocks away looking about; the night must still read (a lantern on the house helps: `/give lantern`) |
| 7 | `shot-7-race.jpg` | **Friends racing a course** | Sandbox, Green Meadows, level ground | build a short lane: `/give startblock`, `/give checkpoint`, `/give finishblock`, a few `/give bouncepad`, blocks to hop over; `/bot add explorer`; stand on START and say "race me" in the chat; step off | mid-race: the race clock on the HUD, the bot friend (its name tag says it is a bot) running beside the child over a bounce pad. With a second phone or the desktop on LAN, a real friend instead of the bot |
| 8 | `shot-8-book.jpg` | **The Secret Book** | Sandbox or Survivor after some play | find two or three secrets first (`/secret`, then go there), meet a few animals (`/summon horse`, `/summon duck`, `/summon owl` nearby: each counts as met); BOOK | the book open on the SECRETS page with its column of tabs (SECRETS, ANIMALS, MEMORIES, IDEAS, SAVING) showing; if ANIMALS looks richer, use that page |

**Spares** (if one of the eight fails or looks weak; same rules): a quest card with Tilly and her "!" (MORE → QUESTS,
or tap Tilly in a new Survivor world); riding a horse through a #45b village (`/summon horse`, a saddle); the avatar
editor with BOY / GIRL / JUST ME and a costume; the trade window between the emulator and the desktop on LAN (both
Survivor); Pip's playground lesson in a new Survivor world (the step card and Pip; build after M3 Task 15); the
MOBS page open in the Sandbox palette (owner #51).

**Captions:** none burned in for now (a caption needs a font, and the CC0-only rule covers fonts; Play does not ask
for captions). If the owner wants them later, these are the words, and they fit a band at the top, never over a
face: 1 "Build it. Wake it up!" · 2 "Shrink tiny or grow giant" · 3 "Walk through golden portals" · 4 "Five magical
universes" · 5 "Your dog finds treasure" · 6 "Hide from the night's monsters" · 7 "Race on courses you build" · 8 "Fill
the Secret Book".

**The MOBS page** (owner #51, after 0.4.0) is a second way to bring out a creature for a shot: in Sandbox, "+" →
MOBS → tap the dog, the goblin or the Sky Dragon; it comes out in front of the child, like `/summon`.

## The feature graphic (1024 × 500)
A buddy waking up in front of a castle at sunset, the wordmark on the left:
1. Sandbox, Green Meadows: `/build tower` two or three times side by side (a castle wall), a buddy of 4–5 blocks in
   front of it, `/time sunset`.
2. Wake the buddy with the wand, then at once MORE → PHOTO (photo mode hides the HUD; filter NORMAL, no frame);
   frame the buddy in the **right half** with the castle behind and the sunset sky above; take the photo. It is saved
   in the phone's gallery (`/sdcard/Pictures/EasyCraft/`, `adb pull`).
3. Compose on this PC (the wordmark is ours, `assets/brand/wordmark.png`, 992 × 240):
   ```bash
   python3 - <<'EOF'
   from PIL import Image
   shot = Image.open("photo.png").convert("RGB")            # 1920 x 1080 (or 2400 x 1080)
   w, h = shot.size; ch = int(w * 500 / 1024)                 # the 1024 x 500 shape, full width
   top = max(0, (h - ch) // 2)
   fg = shot.crop((0, top, w, top + ch)).resize((1024, 500), Image.LANCZOS)
   mark = Image.open("assets/brand/wordmark.png").convert("RGBA")
   mark = mark.resize((440, int(440 * mark.height / mark.width)), Image.LANCZOS)
   fg.paste(mark, (60, (500 - mark.height) // 2), mark)       # left side, inside the middle 80 %
   fg.save("docs/store/graphics/next/feature-graphic.jpg", quality=92)
   EOF
   ```
   Check that the wordmark sits on a calm part of the sky (no busy blocks behind the letters) and that the buddy's
   face is not under it.

## After the upload
Write the date and which files went up into `play-console.md` ("State"), move the old `docs/store/graphics/*.jpg`
out, and tick the line in `pre-launch-checklist.md`. (Done 2026-09-27. `docs/` has a `.gdignore`, so no store picture
is imported into the APK.)
