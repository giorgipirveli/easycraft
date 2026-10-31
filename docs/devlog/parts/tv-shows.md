# TV shows: finishing the Shorts Theater (owner #89, 2026-09-30)

The owner (#89, 2026-09-29): "also finish tv shows feature". Brief: `docs/superpowers/plans/2026-09-29-tv-shows-brief.md`;
spec §5.12, §14.12 (the Theater, M3 Task 17: `docs/devlog/parts/m3-task-17.md`). Built in a worktree cut from
`lead-merge` (`24aae9b5`, owner #92's online fix on it) while the rocket and earn/invite/Gold Shop agents worked. No
editor, emulator or adb was used; the browser block was checked in headless Chromium (below), the panel in windowed
screenshots (`tools/theater_shots.gd`). The lead merges, deploys and checks Android on the emulator.

## What a child sees

A short walk from the spawn stands the cinema (unchanged). Walking in opens EasyCraft TV in the middle of the screen,
with the world's corners (the stick, JUMP, pause, chat) still there:

- **Eight channels as big picture tabs** across the top: EasyCraft TV (a TV), Space (a planet), Science (a flask),
  Nature and Animals (a paw), How Things Are Made (a gear), Music (a note), Art (a palette), History (a pyramid), each
  in its own colour; the channel on the screen has a yellow frame.
- **The video's title** over the player, and **CLOSE** at its right while a video is on the screen.
- **The player, 16:9** (YouTube's own shape, 480 × 270 in the design space: 720 × 405 px on the emulator), with
  **BACK** on its left and **NEXT** and **EXIT** on its right, never over it; a small **Grown-ups** under BACK.
- **The channel's videos as cards** under the player, four at a time with ◀ ▶ for the next page: each card has its
  number, the channel's picture, the title and the maker ("SciShow Kids", "Tate Kids"); the one playing has a yellow
  frame. A tap on a card plays it.
- Walking in shows the first video **still** (YouTube's own poster and play button): nothing starts by itself. A tab, a
  card, NEXT or BACK starts that video. At its end, NEXT lights up yellow and waits. After 10 videos (5 for a child
  while the age rules are on) "That's the show!" with BACK TO MY WORLD and MORE SHOWS (two equal choices); the list ends,
  never an endless feed. CLOSE stops the video and leaves its poster (a tap plays it again). While a video is on the
  screen the game's own music and sounds pause, and come back with CLOSE, EXIT, walking out or a menu.
- **On a PC** the buttons show their keys in a corner: **Esc** leaves the Theater (before the pause menu hears it),
  **N** is NEXT, **B** is BACK; opening the Theater frees the mouse for clicking (a click on the world looks around
  again). Touch works as before.
- **In a browser:** Chrome, Edge, Samsung Internet (and Android Chrome) show the player right in the game, with a big
  red CLOSE over the game's own. **Safari (every iPhone and iPad browser) and Firefox** can't (below): in the player's
  place a big "▶ WATCH (it opens in a new tab; CLOSE brings you back)" button opens the server's player page, whose CLOSE
  closes the tab and tells the game.
- **On Android** (the Play build and any Gradle build with the WebView plugin) the same player in the WebView; a tap on
  YouTube's own play button starts it (the WebView's made-for-kids rule). An APK built without Gradle says "Coming soon".

## What was built

| File | What |
|---|---|
| `data/theater/channels.json` | **The real list** (new): 8 channels, 77 videos, every one on YouTube, embeddable and set "made for kids" by its maker, each with its maker (`from`) and each channel with a picture (`icon`). `"source": "bundled"`. The game plays it until it reads the server's; it is also the file `tools/theater_list.py` checks and sends. |
| `data/theater/sample_channels.json` | Unchanged content (placeholders, TikTok): now only the rules' tests' list and the `Android Theater` check build's. |
| `core/theater/theater_channels.gd` | `SOURCE_BUNDLED`, `BUNDLED_PATH`, `is_real()`; a channel's `icon` (one of `ICONS`, else the TV) and a video's `from` (≤ 30 characters). |
| `core/theater/theater_rules.gd` | The made-for-kids settings for everyone: only videos made for kids, no TikTok; `STARTS_ON_OPEN`, `PLAYS_NEXT_BY_ITSELF` false, `PICKED_VIDEO_STARTS` true; a real list plays on phones and browsers with a player; `referer_for(data_dir)`: the Referer is the package the game runs as. |
| `core/theater/theater_session.gd` | `pick_video(i)` (the cards), `videos()`; `current()` adds `icon`, `from`, `index`, `count`; nothing moves by itself (`video_ended` is gone). |
| `core/theater/theater_embed.gd` | The Android page: YouTube only, `page(platform, id, autoplay, referer)` (the Referer must be a package name or nothing is made). |
| `core/theater/theater_feed.gd` (new) | Which list plays: the server's last one kept on the device (`user://theater_channels.json`), else the bundled one; `keep()` the server's answer (a server list is kept, "no list" goes back to the bundled one, a failure changes nothing); `fetch()` through a signed-in OnlineService. |
| `core/platform/web_glue.gd` | The TV calls: `tv_available`, `tv_show` (a checked id and numbers only; `tv_show_js` builds it), `tv_hide`, `tv_close`, `tv_event` (`parse_tv_event` reads only "ended", "closed", "failed:<digits>"). |
| `web/shell.html` | One block: `#tv` and `#tv-close`, their CSS, and `window.easycraftTv` (show, hide, close, take). |
| `server/deploy/site/tv/index.html` (new), `server/deploy/caddy/Caddyfile` | The player page for Safari and Firefox at `/tv/` (a public page like `/privacy`, without the thread headers). |
| `ui/theater/theater_panel.gd` | The panel rebuilt (above); `ChannelTab`, `VideoCard`; the sound hold; the keys; the poster; `card_rect()`, `close_pixel_rect()`. |
| `ui/theater/theater_web_player.gd` (new) | The browser's player, the same methods and signals as the Android one (`play`, `set_rect`, `hide`, `reveal`, `close`; `ended`, `failed`, `stopped`), events by `poll()`. |
| `ui/theater/theater_webview.gd` | The Android player's new `play(video, autoplay, rect, close)`: builds the page with this run's Referer, the plugin's `child` flag on for everyone. The Kotlin plugin is unchanged (no AAR rebuild). |
| `ui/theater/theater_icons.gd` (new) | The nine tab pictures, drawn once in code (no image files). |
| `entities/theater/theater_director.gd` | `player_backend()` (the page's block on the web, the plugin elsewhere); `online` and `_read_server_list()`: reads the server's list when online, or when the game signs in during the world. |
| `scenes/sandbox.gd` | Two lines: `TheaterFeed.load_best()` instead of the sample; `theater.online = Session.online_service_or_null`; the KEYS card counts as a menu over the player. |
| `server/modules/src/rules/theater_rules.ts`, `src/server/theater.ts` (new), `src/main.ts`, `tsconfig.json` | Module **0.2.17**: `theater_channels`, `theater_set_channels` (below). |
| `tools/theater_list.py` (new) | check, sources, push, show, off, clear (below). |
| `tools/theater_shots.gd` (new) | Pictures of the panel at 1600 × 720 and 1280 × 720 (windowed). |

## The server's list (module 0.2.17)

One storage object, collection `theater`, key `channels`, owned by the system user: **permissionRead 2** (every game
may read it), permissionWrite 0 (only the server writes it; the storage guard already refuses a game's write to any
collection but its profile).

- `theater_channels {}`: any signed-in game (or the owner): `{"ok": true, "list": <the kept list> | null}`.
- `theater_set_channels {"list": {...}}`: **the owner only** (the runtime HTTP key, or the console's API Explorer with
  no user id); a game gets `not_allowed`. The list is checked field by field (`TheaterListRules.check`: `enabled`
  a real boolean, at most 12 channels, ids `[a-z0-9_]{1,32}` once each, titles 1-40 characters without control
  characters, `youtube` or `tiktok`, colours `#rrggbb`, icons from the nine, 1-50 videos with ids per platform once
  each, `made_for_kids` a boolean, `from` 1-30 characters) and refused whole when anything is wrong:
  `{"ok": false, "error": "bad_list", "problems": ["channels[1].videos[0].id: not a youtube video id", ...]}` (at most
  50 named). Only the known fields are kept, with `"source": "server"`, `"version": 1`, `"updated_ms"`. Payload up to
  64 KiB (every other RPC takes 4 KiB). `{"clear": true}` deletes it (games go back to their bundled list).
- The kill-switch is a list: `{"enabled": false, "channels": []}` (`tools/theater_list.py off`).

The game asks when a world starts and the device is signed in (PLAY ONLINE was used once: `Session.online_autostart`),
or when it signs in during the world; the answer is kept and plays from the panel's next opening. A child who never
goes online plays the bundled list, which is the same file the owner sends (every build carries the newest).

**The tool.** `python3 tools/theater_list.py check` fetches every video's page (oEmbed: its title, its channel,
embedding allowed; the watch page: playable, playable in an embedded player, family safe, and YouTube's own "made for
kids" setting, which shows as "Miniplayer is off for videos made for kids"; no API key needed) and the list's shape;
exit 1 on any problem. `sources` prints the table below. `push` / `show` / `off` / `clear` call the RPCs with
`EASYCRAFT_HTTP_KEY` (the server's `NAKAMA_RUNTIME_HTTP_KEY`); `--server http://127.0.0.1:7350` with
`EASYCRAFT_HTTP_KEY=defaulthttpkey` for this PC's dev server.

## The privacy and made-for-kids settings

| Where | Settings |
|---|---|
| Everywhere | YouTube's privacy-enhanced host `youtube-nocookie.com`; `rel=0` (no suggestions from other channels), `iv_load_policy=3` (no notes), `fs=0` (no full screen), `disablekb=1`, `playsinline=1`; only videos made for kids; no TikTok; nothing starts by itself (a picked video starts, the next never); the end card; nothing given for watching. The Referer names the app or site (YouTube's rule; without it the player says "Error 153"). |
| Browser (Chromium) | An `<iframe credentialless>` (no cookies at all: a fresh, throwaway context), `sandbox="allow-scripts allow-same-origin allow-presentation"` (no popups, no top navigation: "Watch on YouTube", the title and the channel's link open nothing, checked), `referrerpolicy="strict-origin-when-cross-origin"`, `allow="autoplay; encrypted-media; picture-in-picture"`. The page gets the id only after the game checked it and checks it again. |
| Browser (Safari, Firefox) | The server's `/tv/` page in a tab: the same player settings and sandbox (cookies as that browser keeps them for youtube-nocookie.com), `noindex`, a big CLOSE. |
| Android | Unchanged plugin rules (M3 Task 17): every main-frame navigation refused, sub-frames only from YouTube's hosts, no popups, no file access; now the `child` flag for everyone: **no third-party cookies**, and a tap on YouTube's play button starts each video. The Referer is `https://<package>` read from the app's data folder: `com.giorgi.easycraft` in the Play build, `com.giorgi.game` in the debug ones. |

## Checked in a browser (headless Chromium 154, this PC)

The block, extracted from `web/shell.html` into a test page served with the game's own headers (COOP same-origin,
COEP require-corp: `tools/web_serve.py`), and the production origin simulated with Playwright routes:

- `crossOriginIsolated` true, `credentialless` supported: `easycraftTv.show('SOCixRhRGDw', ...)` put a credentialless,
  sandboxed youtube-nocookie iframe exactly on the rect (canvas 1920 × 1080 shown at 1280 × 720: 960 × 540 → 640 × 360
  CSS px) and CLOSE on its own rect; inside it YouTube's player ("Take a Tour of the Space Station", SciShow Kids), no
  error. Without `credentialless` the same iframe is blocked by COEP (YouTube sends only a report-only COEP), which is
  why Safari and Firefox get the tab.
- Played muted and sought to the end: the page's queue gave exactly one `ended`.
- `hide()` hid it (display none) and `show()` with the same id showed it again without reloading; CLOSE removed the
  iframe and queued `closed`; an id with a quote was refused (`show` false).
- The links inside the player ("Watch on", the title, the channel): clicked, nothing opened, the page stayed.
- Safari/Firefox path (Chromium with `credentialless` removed, both pages on `https://178-104-20-64.sslip.io` by
  routes): the WATCH button opened `/tv/#v=SOCixRhRGDw` in a new tab, the player loaded there (sandboxed), its CLOSE
  closed the tab (`window.close()`) and the game page's queue got `closed` (BroadcastChannel), its block back to hidden.
- Not checked here: real Safari and Firefox (window.close and BroadcastChannel there), a real game export (the lead's
  deploy), Android (the emulator).

## Rulings (decisions made on the owner's behalf)

1. **The made-for-kids settings for everyone.** With the age rules off (#69) every player counts as 13+, which under
   M3's rules meant videos not made for kids, TikTok and autoplay of the next video. The game is for children and the
   brief says "made for kids only": everyone gets only videos made for kids, no TikTok (it has no such setting), no
   third-party cookies (Android's `child` flag, the browser's credentialless frame), and nothing starts by itself.
   *Cost if wrong:* a teenager taps NEXT at the end of each video; a 13+ rule comes back in `TheaterRules`
   (`channels_for` keeps its `band` argument for that).
2. **Nothing starts by itself, a pick starts at once.** Walking in shows the video still (a child walking through
   isn't choosing to watch, and a sudden sound startles); a tab, a card, NEXT, BACK or PLAY starts that video
   (in the browser at once; on Android YouTube's play button still needs a tap). The end of a video lights NEXT up.
   *Cost if wrong:* one line each in `TheaterRules` (`STARTS_ON_OPEN`, `PLAYS_NEXT_BY_ITSELF`).
3. **16:9, not 9:16.** Real educational videos for children are landscape; a 9:16 screen showed them 315 × 177.
   *Cost if wrong:* "Shorts" (vertical) channels would show pillarboxed.
4. **EasyCraft TV is a mix of picks** (Paxi, the Space Station tour, making crayons, Mildred the gallery cat, the
   octopus, Yo-Yo Ma, the first Moon walk), none repeated in the other channels, until EasyCraft has its own clips on
   YouTube. *Cost if wrong:* the owner replaces seven lines.
5. **The channels and makers.** Only official channels of space agencies (ESA's Paxi, NASA Space Place), museums
   (Tate Kids, The Met), a concert hall (Sydney Opera House), public broadcasters' and non-profit children's studios
   (Sesame Street, Mister Rogers' Neighborhood, SciShow Kids, Crash Course Kids, Nat Geo Kids) and children's
   education channels (Free School, Peekaboo Kidz); no personal or family channels (so no children's own channels),
   no live streams, nothing frightening (left out on purpose: dinosaur extinction, mummies, van Gogh's life, Frida
   Kahlo's accident, "kids react" videos, a zoo's and an aquarium's videos that are not set "made for kids"). Every
   video is YouTube's "made for kids" (checked, not assumed), 55 s to 22 min, most 3-6 min. *Cost if wrong:* the
   owner edits `data/theater/channels.json`, runs `check`, `push`, commits.
6. **"Made for kids" checked without an API key**, from the watch page (the miniplayer rule YouTube applies to such
   videos), plus `isFamilySafe` and `playableInEmbed`. *Cost if wrong:* if YouTube changes that page, `check` reports
   every video as not made for kids (fails safe); the Data API key (spec §11) would replace it.
7. **The server's list is read only by signed-in games** (Nakama has no public read without a session, and the HTTP
   key is secret); a child who never goes online plays the bundled list, which every build and web deploy refreshes.
   *Cost if wrong:* a public read would need a Caddy route that adds the HTTP key for one RPC.
8. **Safari and Firefox open a tab.** The game's page must stay cross-origin isolated (its threads), which blocks
   another site's frame unless it is `credentialless` (Chromium only; Safari 27 and Firefox 159 don't have it). A
   WATCH button (a real tap: popups need one) opens `/tv/` on the game's own server. *Cost if wrong:* on an iPhone the
   video is in a tab, not over the game; when WebKit gets credentialless iframes, the inline player works there with
   no change (the page tests for it).
9. **`/tv/` plays any id in its address.** It checks the id's shape, not that it is in the list (the list is not
   public). Someone could send a child a link that plays some other embeddable YouTube video framed as "EasyCraft TV".
   *Cost if wrong:* low (YouTube's own embed rules apply, the page is `noindex`); a fix is a copy of the ids in the page.
10. **CLOSE twice in the browser.** The game's CLOSE exists everywhere; in the browser the page's own CLOSE lies
    exactly over it (the brief's "big CLOSE"), so a click always reaches a working one, even while the player has the
    keyboard focus (then Esc can't reach the game). *Cost if wrong:* none known.
11. **The game's sound is held while a video is on the screen** (the master bus muted, and restored to what it was),
    not while it is actually playing (Android's page doesn't report pausing). *Cost if wrong:* a paused video keeps
    the game quiet until CLOSE, EXIT or walking out.
12. **Four TV calls in WebGlue, not two** (show, hide, close, and the events), plus the check whether the page has the
    block: the menus must hide the player (it is a page element over the canvas) and the game must hear "ended" and
    the page's CLOSE. *Cost if wrong:* none.
13. **The Android Referer is read from the app's data folder** (`/data/user/<n>/<package>/files`), so the Play build
    (`com.giorgi.easycraft`) and the debug builds (`com.giorgi.game`) each name themselves; a test ties every preset's
    package to it. No Kotlin change, no AAR rebuild. *Cost if wrong:* if Android ever moves that folder, the Referer
    falls back to `https://com.giorgi.game`.
14. **The tab pictures are drawn in code** (nine shapes, `TheaterIcons`), like the panel's arrows: no image files,
    nothing to license. *Cost if wrong:* an artist's icons replace one function.
15. **The Theater now plays in the Play build.** "Android Play" is a Gradle build, so it carries the WebView plugin,
    and the bundled list is real: the Theater plays there after this merge. The store drafts assumed it off
    (`docs/store/data-safety.md` "Later", `families-and-rating.md`, pre-launch checklist F2). **Before the next Play
    upload the owner must re-answer those forms, or ship the Play build with `"enabled": false` in
    `data/theater/channels.json`** (a server `off` reaches only games that go online). Not changed here: the store
    drafts are the owner's lawyer's. *Cost if wrong:* a store rejection or a wrong Data safety answer.

## The channels and every video's source

Checked on 2026-09-30 with `python3 tools/theater_list.py sources` (each video's page on YouTube: its title and channel as YouTube shows them, oEmbed allowed, playable, playable in an embedded player, family safe, and YouTube's own "made for kids" setting). `THEATER_LIST ok: 77 videos, 0 problems`. The "Video" column is the short title the cards show.

| Channel | Video | Its page | Title on YouTube | YouTube channel | Length | Checked |
|---|---|---|---|---|---|---|
| EasyCraft TV | Who is Paxi? | https://www.youtube.com/watch?v=fYa-hmNzlAQ | Who is Paxi? | European Space Agency, ESA | 3:44 | embeddable, made for kids |
| EasyCraft TV | A Tour of the Space Station | https://www.youtube.com/watch?v=SOCixRhRGDw | Take a Tour of the Space Station | SciShow Kids | 3:15 | embeddable, made for kids |
| EasyCraft TV | Making Crayons | https://www.youtube.com/watch?v=ZQ_MEFVx5jM | Sesame Street: Making Crayons | Sesame Street | 2:02 | embeddable, made for kids |
| EasyCraft TV | Mildred the Gallery Cat | https://www.youtube.com/watch?v=7mbA0qyk4Pw | Mildred the Gallery Cat / Tate Kids | Tate Kids | 5:40 | embeddable, made for kids |
| EasyCraft TV | The Giant Pacific Octopus | https://www.youtube.com/watch?v=9vQnKO_2kKk | Giant Pacific Octopus 🐙 / Amazing Animals / Nat Geo Kids | Nat Geo Kids | 1:46 | embeddable, made for kids |
| EasyCraft TV | Yo-Yo Ma: The Jam Session | https://www.youtube.com/watch?v=IRixaQ4hpEI | Sesame Street: Yo Yo Ma: The Jam Session | Sesame Street | 2:33 | embeddable, made for kids |
| EasyCraft TV | Apollo 11: The First Moon Walk | https://www.youtube.com/watch?v=CbTaDOuSePk | Apollo 11 - The First Moon Walk / Things You Wanna Know / Nat Geo Kids | Nat Geo Kids | 2:45 | embeddable, made for kids |
| Space | Paxi: The Solar System | https://www.youtube.com/watch?v=mibxJwpennU | Paxi - The Solar System | European Space Agency, ESA | 5:18 | embeddable, made for kids |
| Space | Paxi: The Red Planet | https://www.youtube.com/watch?v=V4_c4DUseLU | Paxi - The Red Planet | European Space Agency, ESA | 5:06 | embeddable, made for kids |
| Space | Our Moon Isn't the Only Moon! | https://www.youtube.com/watch?v=o33NZIlfKys | Our Moon Isn't the Only Moon! | NASA Space Place | 2:40 | embeddable, made for kids |
| Space | What Is a Solar Eclipse? | https://www.youtube.com/watch?v=hyf5JF_VxwM | What Is a Solar Eclipse? | NASA Space Place | 2:06 | embeddable, made for kids |
| Space | What Is a Black Hole? | https://www.youtube.com/watch?v=OfMExgr_vzY | What is a Black Hole? | NASA Space Place | 3:00 | embeddable, made for kids |
| Space | Why Does the Moon Change? | https://www.youtube.com/watch?v=yXe0yxzYkjo | Why Does the Moon Change? | SciShow Kids | 3:48 | embeddable, made for kids |
| Space | What Do Astronauts Do? | https://www.youtube.com/watch?v=jhD8GFwy734 | What Do Astronauts Do? | SciShow Kids | 4:41 | embeddable, made for kids |
| Space | The Rocky Planets | https://www.youtube.com/watch?v=joq-IUFNkrw | Explore the Solar System: The Rocky Planets | SciShow Kids | 4:14 | embeddable, made for kids |
| Space | What Is the Sun? | https://www.youtube.com/watch?v=0b3GcLE4Vlg | What Is the Sun? | SciShow Kids | 5:05 | embeddable, made for kids |
| Space | Meet the Mars Rovers! | https://www.youtube.com/watch?v=ujh-dtEvyIw | Meet the Mars Rovers! / Let's Explore Mars! / SciShow Kids | SciShow Kids | 6:48 | embeddable, made for kids |
| Science | How to Make a Rainbow | https://www.youtube.com/watch?v=Cm9ZkYTnCNE | How to Make a Rainbow | SciShow Kids | 3:17 | embeddable, made for kids |
| Science | Why Is the Sky Blue? | https://www.youtube.com/watch?v=ehUIlhKhzDA | Why Is the Sky Blue? | NASA Space Place | 2:48 | embeddable, made for kids |
| Science | The Dry Sock Trick! | https://www.youtube.com/watch?v=jH_q1DR5-gA | The Dry Sock Trick! / Science Project for Kids | SciShow Kids | 3:52 | embeddable, made for kids |
| Science | Unpoppable Bubbles! | https://www.youtube.com/watch?v=a-SPYPAedCA | Unpoppable Bubbles! / Summer Experiments / SciShow Kids | SciShow Kids | 4:15 | embeddable, made for kids |
| Science | The Power of Sunlight! | https://www.youtube.com/watch?v=0Qmgdz9E47s | The Power of Sunlight! / Science Project for Kids | SciShow Kids | 4:30 | embeddable, made for kids |
| Science | How Do We Know When It Will Rain? | https://www.youtube.com/watch?v=dLQ0lHpyZd8 | How Do We Know When It Will Rain? / Weather Science / SciShow Kids | SciShow Kids | 4:22 | embeddable, made for kids |
| Science | What's an Engineer? | https://www.youtube.com/watch?v=owHF9iLyxic | What's an Engineer? Crash Course Kids #12.1 | Crash Course Kids | 4:30 | embeddable, made for kids |
| Science | Defining Gravity | https://www.youtube.com/watch?v=ljRlB6TuMOU | Defining Gravity: Crash Course Kids #4.1 | Crash Course Kids | 3:12 | embeddable, made for kids |
| Science | Chemical Changes | https://www.youtube.com/watch?v=37pir0ej_SE | Chemical Changes: Crash Course Kids #19.2 | Crash Course Kids | 3:51 | embeddable, made for kids |
| Science | Eggs-periments! | https://www.youtube.com/watch?v=TQgRIJdp2c0 | Eggs-periments! / Nat Geo Kids Cool Science Experiments Playlist | Nat Geo Kids | 1:55 | embeddable, made for kids |
| Nature and Animals | How Animals Find Their Way Home | https://www.youtube.com/watch?v=9_dTCWB0kNU | How Animals Find Their Way Home! | SciShow Kids | 3:49 | embeddable, made for kids |
| Nature and Animals | Why Do Animals Have Tails? | https://www.youtube.com/watch?v=3EK69vhhdqU | Why Do Animals Have Tails? | SciShow Kids | 3:38 | embeddable, made for kids |
| Nature and Animals | Animals with Winter Coats | https://www.youtube.com/watch?v=0N7FGPeykfE | Animals with Winter Coats! | SciShow Kids | 4:29 | embeddable, made for kids |
| Nature and Animals | Camouflage: Animal Hide and Seek | https://www.youtube.com/watch?v=YOIRci0CKzg | Camouflage: Animal Hide & Seek | SciShow Kids | 4:26 | embeddable, made for kids |
| Nature and Animals | Amazing Animal Groups | https://www.youtube.com/watch?v=gwH8xGmqGmo | Amazing Animal Groups / Science for Kids | SciShow Kids | 4:24 | embeddable, made for kids |
| Nature and Animals | All About Owls | https://www.youtube.com/watch?v=m0XgSrdYQRY | All About Owls for Kids: Backyard Bird Series - FreeSchool | Free School | 3:43 | embeddable, made for kids |
| Nature and Animals | All About Zebras | https://www.youtube.com/watch?v=kWxnadQI5Qw | Zebras for Kids: Learn all About Zebras - FreeSchool | Free School | 3:31 | embeddable, made for kids |
| Nature and Animals | All About Pandas | https://www.youtube.com/watch?v=VNxx8jVEm3I | All About Pandas for Kids - FreeSchool | Free School | 4:12 | embeddable, made for kids |
| Nature and Animals | All About Elephants | https://www.youtube.com/watch?v=LpzwxDqVDtc | Elephants for Children: Learn All About Elephants - FreeSchool | Free School | 4:28 | embeddable, made for kids |
| Nature and Animals | All About Polar Bears | https://www.youtube.com/watch?v=--xEE7K67Xo | All About Polar Bears for Kids: Polar Bears for Children - FreeSchool | Free School | 4:18 | embeddable, made for kids |
| Nature and Animals | Find Out About Insects! | https://www.youtube.com/watch?v=i7zpS4RkK2o | Find Out About Insects! / Nat Geo Kids Insects Playlist | Nat Geo Kids | 0:55 | embeddable, made for kids |
| How Things Are Made | How People Make Erasers | https://www.youtube.com/watch?v=ILNdFbY0Eqk | How People Make Erasers / Mister Rogers' Neighborhood | Mister Rogers’ Neighborhood | 4:54 | embeddable, made for kids |
| How Things Are Made | How People Make Books | https://www.youtube.com/watch?v=iXAZZl9Pzvg | How People Make Books / Mister Roger's Neighborhood | Mister Rogers’ Neighborhood | 7:10 | embeddable, made for kids |
| How Things Are Made | How People Make Stamps | https://www.youtube.com/watch?v=NUeMSO4kcoE | How People Make Stamps / Mister Rogers’ Neighborhood | Mister Rogers’ Neighborhood | 9:11 | embeddable, made for kids |
| How Things Are Made | How Is Cotton Candy Made? | https://www.youtube.com/watch?v=9bNaBpSh0vU | How Is Cotton Candy Made? / The Science of Food! / SciShow Kids | SciShow Kids | 4:46 | embeddable, made for kids |
| How Things Are Made | Wonderful Wool! | https://www.youtube.com/watch?v=x0HeCL6nano | Wonderful Wool! | SciShow Kids | 4:33 | embeddable, made for kids |
| How Things Are Made | How Do Bees Make Honey? | https://www.youtube.com/watch?v=A4YIpGQiD3w | How Do Bees Make Honey? / The Science of Food! / SciShow Kids | SciShow Kids | 6:02 | embeddable, made for kids |
| How Things Are Made | Where Does Maple Syrup Come From? | https://www.youtube.com/watch?v=p_Ob1q_a4xo | Where Does Maple Syrup Come From? / Winter is Alive! / SciShow Kids | SciShow Kids | 4:40 | embeddable, made for kids |
| How Things Are Made | How Compost Is Made | https://www.youtube.com/watch?v=26IO95Xt5WU | How Compost Is Made: A Field Trip! | SciShow Kids | 6:43 | embeddable, made for kids |
| How Things Are Made | The Invention of Paper | https://www.youtube.com/watch?v=COxB_GvdzWI | Invention Of PAPER / The Dr. Binocs Show / Best Learning Video for Kids / Fun Preschool Learning | Peekaboo Kidz | 7:54 | embeddable, made for kids |
| How Things Are Made | How Fire Trucks Are Made | https://www.youtube.com/watch?v=FXplXFR6gMY | Learn How Fire Trucks Are Made! 🚒🔥 / Made in a Day Full Episode / @natgeokids | Nat Geo Kids | 21:49 | embeddable, made for kids |
| Music | George Meets the Orchestra | https://www.youtube.com/watch?v=M0Jc4sP0BEE | George Meets the Orchestra / An Introduction to the Orchestra for Children | Sydney Opera House | 6:02 | embeddable, made for kids |
| Music | What Is Sound? | https://www.youtube.com/watch?v=3-xKZKxXuu0 | What is Sound? / Physics for Kids / SciShow Kids | SciShow Kids | 3:57 | embeddable, made for kids |
| Music | What Makes Music Sound So Good? | https://www.youtube.com/watch?v=iLisEwkO6C0 | What Makes Music Sound So Good? | SciShow Kids | 3:18 | embeddable, made for kids |
| Music | How Do We Sing? | https://www.youtube.com/watch?v=ibJ2xmSJuHQ | How Do We Sing? | SciShow Kids | 4:26 | embeddable, made for kids |
| Music | The Science of the String Phone | https://www.youtube.com/watch?v=3yqB2KFwJCo | The Science of the String Phone! - #sciencegoals | SciShow Kids | 4:38 | embeddable, made for kids |
| Music | Mozart for Children | https://www.youtube.com/watch?v=UyB4-6g-Vbg | Mozart for Children: Biography for kids - FreeSchool | Free School | 4:34 | embeddable, made for kids |
| Music | Beethoven for Kids | https://www.youtube.com/watch?v=ms9tyNKtjcs | Biography of Ludwig van Beethoven for Kids - Beethoven for Children: FreeSchool | Free School | 4:57 | embeddable, made for kids |
| Music | Für Elise by Beethoven | https://www.youtube.com/watch?v=PZNcKLL1kmo | Beethoven "Fur Elise" Bagatelle No. 25 in A minor - FreeSchool Radio | Free School | 2:59 | embeddable, made for kids |
| Music | Vivaldi: The Four Seasons, Spring | https://www.youtube.com/watch?v=FhgX_JekVyw | The Four Seasons: Spring, Allegro, by Antonio Vivaldi - FreeSchool Radio | Free School | 3:38 | embeddable, made for kids |
| Music | Learn About Sound | https://www.youtube.com/watch?v=HblEhc0gses | Learn About Sound / Nat Geo Kids Sound Playlist | Nat Geo Kids | 0:45 | embeddable, made for kids |
| Art | Claude Monet for Children | https://www.youtube.com/watch?v=ah5g2M14oUM | Biography of Claude Monet: Famous Artists for Children - FreeSchool | Free School | 4:53 | embeddable, made for kids |
| Art | Leonardo da Vinci for Children | https://www.youtube.com/watch?v=Rm0qszPJnc8 | Leonardo da Vinci for Children: Biography for Kids - FreeSchool | Free School | 5:02 | embeddable, made for kids |
| Art | Becoming an Artist: J.M.W. Turner | https://www.youtube.com/watch?v=ZtF5QbTOiJY | Becoming an Artist: J.M.W. Turner / Tate Kids | Tate Kids | 6:27 | embeddable, made for kids |
| Art | A Paper Pumpkin like Yayoi Kusama | https://www.youtube.com/watch?v=yvAgx3gP_m0 | How to Make a Paper Pumpkin like Yayoi Kusama / Tate Kids | Tate Kids | 2:27 | embeddable, made for kids |
| Art | How to Make Art that Moves | https://www.youtube.com/watch?v=9PV6htns_xA | How to Make Art that Moves / Tate Kids | Tate Kids | 4:19 | embeddable, made for kids |
| Art | How to Make a Hanging Mobile | https://www.youtube.com/watch?v=hOQMMyBhx4w | How to Make a Hanging Mobile like Julio Le Parc / Tate Kids | Tate Kids | 1:56 | embeddable, made for kids |
| Art | Can Geometry Be Art? | https://www.youtube.com/watch?v=Xsg_54t7T-k | Can Geometry Be Art? / Tate Kids | Tate Kids | 4:45 | embeddable, made for kids |
| Art | Weave on a Mini Loom | https://www.youtube.com/watch?v=AWLIy-Um7_0 | #MetKids—Weave on a Mini Loom | The Met | 3:07 | embeddable, made for kids |
| Art | Make Your Own Optical Illusion | https://www.youtube.com/watch?v=sKnZaiJNbNI | How To Make Your Own Optical Illusion / Create with #MetKids Microscope | The Met | 1:46 | embeddable, made for kids |
| Art | Pointillism: Art That Tricks Our Eyes | https://www.youtube.com/watch?v=vIQltnfFfLg | How Can Art Trick Our Minds? Pointillism and Optics / #MetKids Microscope | The Met | 2:46 | embeddable, made for kids |
| Art | What Does Sound Look Like? | https://www.youtube.com/watch?v=hyyIm5ENwSQ | What Does Sound Look Like? / Create with #MetKids Microscope | The Met | 2:02 | embeddable, made for kids |
| History | The Pyramids of Egypt | https://www.youtube.com/watch?v=Xtc0LQuA3z4 | The Pyramids of Egypt and the Giza Plateau: Ancient Egyptian History for Kids - FreeSchool | Free School | 5:45 | embeddable, made for kids |
| History | The Great Sphinx of Giza | https://www.youtube.com/watch?v=ExM6MiWDlnk | The Great Sphinx of Giza for Children: Ancient Egyptian History for Kids - FreeSchool | Free School | 5:41 | embeddable, made for kids |
| History | Explore Ancient Egypt | https://www.youtube.com/watch?v=0N4YX3SsG3U | Explore Ancient Egypt / Nat Geo Kids Archaeology Playlist | Nat Geo Kids | 1:21 | embeddable, made for kids |
| History | How the Great Pyramid Was Built | https://www.youtube.com/watch?v=qOlnIF6z2mA | How The Great Pyramid of Giza Was Built / Mysteries Uncovered / The Dr. Binocs Show / Peekaboo Kidz | Peekaboo Kidz | 6:03 | embeddable, made for kids |
| History | The Wright Brothers | https://www.youtube.com/watch?v=Qt3pry6cWJM | Biography of the Wright Brothers for Children: Orville and Wilbur Wright for Kids - FreeSchool | Free School | 7:28 | embeddable, made for kids |
| History | Mary Anning: Fossil Hunter | https://www.youtube.com/watch?v=koota_lwU_4 | Mary Anning: Fossil Hunter / Science for Kids | SciShow Kids | 4:13 | embeddable, made for kids |
| History | Dig In to Paleontology | https://www.youtube.com/watch?v=1FjyKmpmQzc | Dig In To Paleontology | SciShow Kids | 4:11 | embeddable, made for kids |
| History | Get to Know a Dinosaur! | https://www.youtube.com/watch?v=5l4w9HhRIrY | Get to Know a Dinosaur! | SciShow Kids | 4:13 | embeddable, made for kids |

## Tests: RED → GREEN

- **Server** (`server/modules/test/theater_rpcs.test.ts`, 11 tests): RED first, for the right reason
  (`S.rpcTheaterSetChannels is not a function`: the files were not in the build yet); GREEN after wiring
  `tsconfig.json` and `main.ts`, with one fix in the test (a refused storage write throws a plain object, not an
  Error). Covered: the owner keeps a list (public read, server write, `source`, `version`, `updated_ms`, trimmed
  titles); a game reads it (and `null` before); a game can neither send one (`not_allowed`) nor write the collection
  (the storage guard); the kill-switch; clear; only known fields kept; 19 kinds of mistakes each refused whole and
  named (a video id that is code, too many channels or videos, a channel or video twice, a control character in a
  title, a bad colour or icon, `made_for_kids` as a word...); junk payloads (`bad_request`, `too_big`); ids per
  platform; **the game's bundled list passes the server's rules as it is** (EasyCraft TV first, YouTube only, 6-12
  videos a channel, every video made for kids and named with its maker); the module is 0.2.17.
  `npm --prefix server/modules test`: **334 / 334**. The version asserts went 0.2.15 → 0.2.17 in five unit files and
  four integration files (`test/integration/*.server.ts`, against a real Nakama: not run here, the local Nakama is
  shared with the other agents and runs whatever module was loaded last).
- **Game.** `tests/unit/test_theater_channels.gd` (15), `test_theater_rules.gd` (23) and `test_theater_session.gd`
  (16) rewritten for the new rules, new `test_theater_feed.gd` (8) and `test_theater_web.gd` (6), and
  `tests/integration/test_theater.gd` rewritten (37). RED: parse errors for the missing API (`BUNDLED_PATH`,
  `SOURCE_BUNDLED`, `ICONS`, `referer_for`, the new `page()`, `TheaterFeed`, `WebGlue.tv_*`), then the web tests on the
  missing page block and site page. GREEN after the code, with two fixes in my tests (a child's end card comes on
  the sixth pick, not the fifth) and in the pages (the embed address written as one literal the test can find):
  105 / 105. `test_hud_layout.gd` (the Theater's buttons clear of every HUD button at every size, both hands, and the
  thumbs back afterwards) passed unchanged: 120 / 120 together.
- **The layout guard**, added after the first pictures (`tools/theater_shots.gd`) showed EXIT 148 px tall reaching the
  cards' arrow and three-line tab names growing the tabs: no two of the panel's buttons overlap, the side buttons keep
  130 px, EXIT ends with the player, the tabs end above the title. Watched fail with UiKit's margins (EXIT and NEXT
  140 tall, EXIT ending at 442 > 423), pass with the slim ones; the tabs became fixed-size picture buttons.
- Other suites touching the Theater, run alone: `test_web_routing.gd`, `test_parent_gate.gd`, `test_profile_backup.gd`,
  `test_identity_words.gd` (the new `/tv/` page and the list's titles), `test_grown_up_privacy.gd` (Caddy still serves
  `/privacy` and `/delete-account`), `test_hosting_kit.gd`: 53 / 53.
- **Full suite** (`tests/run_tests.sh`, once, 2026-09-30 00:45-01:25, a PC-wide slot, load 10-16): **exit 0**, 842
  scripts, 7782 tests, 7780 passing, 2 risky ("did not assert", the voxel ones, as before), no `SCRIPT ERROR` or
  `Parse Error`. One assert failed on the way (`test_audio_credits.gd`: `flight/engine_roar.wav` has no credits
  line), a file that is not in this worktree: the pack tests just before it mount packs from the shared
  `user://` folder, where the rocket-flight agent's build had left its media. Run alone right after: 3 / 3.

## For the lead

**Merge.** Branch `worktree-agent-a93cd4d1afe410905`, cut from `lead-merge` at `24aae9b5`. Expected conflicts:
- `server/modules/src/main.ts` (the `MODULE_VERSION` line and the end of the registrations), `tsconfig.json` (the
  files list) and the version asserts (`test/{match_players,keys_rpcs,gifts_rpcs,wallet_host,ghosts_rpcs}.test.ts`,
  `test/integration/{data_rights,gifts,ghosts,nakama}.server.ts`) against the earn/invite/Gold Shop agent's 0.2.16:
  keep both agents' RPCs and one number for the module you ship (0.2.17 here); `test/theater_rpcs.test.ts` asserts
  0.2.17 too.
- `scenes/sandbox.gd` `_setup_theater()` (three lines), `web/shell.html` (one CSS block before the reduced-motion
  rule, two elements after the install guide, one script at the very end), `server/deploy/caddy/Caddyfile` (the
  `@pages` line), `docs/playtests/owner-feedback.md` (row 89).
- New `class_name`s: `TheaterFeed`, `TheaterWebPlayer`, `TheaterIcons` (rescan or `--import`).

**Deploy.**
1. The server module 0.2.17 (`kit.sh pack` → scp → untar over `~/easycraft` → `./kit.sh update` → `./kit.sh check`);
   the healthcheck says 0.2.17.
2. `/tv/`: the untar brings `site/tv/index.html` (bind-mounted: live at once) and the new Caddyfile. Caddy reads its
   Caddyfile at start, and a single-file bind mount keeps the old file after an untar: recreate Caddy (the kit's
   compose options + `up -d --force-recreate caddy`), then `curl -sI https://178-104-20-64.sslip.io/tv/` → 200, with
   no `Cross-Origin-Embedder-Policy` header.
3. Optional: `EASYCRAFT_HTTP_KEY=<NAKAMA_RUNTIME_HTTP_KEY> python3 tools/theater_list.py push`, then `show` (without
   it the games play their bundled list, which is the same file).
4. The web export and deploy (`tools/export_web.sh`, `tools/deploy_web.sh`, the GitHub copy): the new page block.

**Check live** (a Sandbox world, walk into the Theater):
- Chrome on a PC: the player inside the game with its red CLOSE over the game's; Esc leaves, N and B move; the music
  stops while a video is on the screen; the pause menu (and F1) hide the player; a tap on "Watch on YouTube" opens
  nothing.
- Chrome on an Android phone: the same by touch.
- Safari on an iPhone or iPad, and Firefox: WATCH → a tab plays the video → its CLOSE closes the tab and the game shows
  the video's poster again (if Safari keeps the tab, the page says how to go back).

**Check on the emulator:** `docs/DEVELOPMENT.md` §4 "Shorts Theater: the Android player plugin" (build "Android
Theater"); especially no "Error 153" (the Referer), the sound, and NEXT lighting up at a video's end.

**Before the next Play upload:** ruling 15 (the store forms, or `"enabled": false` in the Play build).
