# M3 Task 17: the Shorts Theater (2026-09-24)

Spec §5.12 and §14.12, §6 (fair fun) and §16 / research H6 (`docs/design/engagement-and-child-psychology.md`);
plan `docs/superpowers/plans/2026-09-24-m3-worlds-of-wonder.md` Task 17. Built in a worktree cut from
`m2-survive-the-night` (`612a6a8`) while the M2 agents worked; the first try was stopped by the
network outage before any file changed (M2 dev log, 10:40), so this is a fresh start. No editor or
emulator was used. The lead merges and checks the Android player on the emulator
(`docs/DEVELOPMENT.md` §4, "Shorts Theater: the Android player plugin").

## What was built

| File | What |
|---|---|
| `data/theater/sample_channels.json` | The curated list until M4's server: `enabled` (the kill-switch), `source: "sample"`, five channels (EasyCraft TV first, Animals, Funny, Music, TikTok Picks). Placeholder ids, except Big Buck Bunny (Blender Foundation, public and embeddable; checked with YouTube's oEmbed), which is there to prove real playback on the emulator; it is not flagged Made for Kids, so only 13+ sees it. No API keys. |
| `core/theater/theater_channels.gd` (`TheaterChannels`) | Defensive parser: fails closed (unreadable list or no `"enabled": true` → no Theater); ids checked per platform (YouTube `[A-Za-z0-9_-]{11}`, TikTok 6–25 digits) so no list text can become code in the player's page; `made_for_kids` must be a real `true`; titles trimmed and capped (40); colours checked; repeats dropped; at most 12 channels × 50 videos; EasyCraft TV moved to the front. |
| `core/theater/theater_rules.gd` (`TheaterRules`) | The age rules (anyone not surely 13+ gets the child rules), the parent switch (`auto`/`on`/`off`), which screen shows (`hidden` / `ask_parent` / `empty` / `coming_soon` / `play`), autoplay, the end-card count, the Referer, the pixel rectangle and the 200 × 200 minimum. |
| `core/theater/theater_session.gd` (`TheaterSession`) | NEXT / BACK / channels, the end card after `end_card_after(band)` videos or at the end of the list, "more shows", autoplay of the next video (13+ only). |
| `core/theater/theater_embed.gd` (`TheaterEmbed`) | The page the WebView shows: the official YouTube IFrame Player API (host `youtube-nocookie.com`, `origin` = the app) or the TikTok Embed Player v1, filling the view with nothing over it; reports the end of a video and errors; `ecPause()` for hiding. |
| `core/validation/parent_gate.gd` (`ParentGate`) | "What is twenty-three times seven?" in words, answered on a number pad. Reusable by the parent corner (M3 Task 21). |
| `core/rules/theater_site.gd` (`TheaterSite`) | Where the building stands (below), `is_inside`, save/load. |
| `entities/theater/theater_building.gd` (`TheaterBuilding`) | A 9 × 9 cinema (cream walls, purple roof, red THEATER sign with bulbs, seats, a dark screen with "EasyCraft TV") on a stone plinth; one shared vertex-coloured mesh (one draw call, faces wound for Godot's clockwise front faces), one static body on the world layer (8 boxes), two `Label3D`s. Not voxels, so it can't be broken and the kill-switch can leave it out. |
| `entities/theater/theater_director.gd` (`TheaterDirector`) | Places the building (saved site or a new one), adds the panel, checks 10 times a second whether the local player is in the room (opens / closes the panel; after EXIT it stays closed until they walk out and in), hides the Android player while a menu covers it, renders the end card's picture of the world (one small `SubViewport` render from above the door, looking towards the spawn). |
| `ui/theater/theater_panel.gd` (`TheaterPanel`) | The 9:16 screen (315 × 560 in the 1280 × 720 design space, 472 × 840 px on the emulator) in the middle, BACK + channels on the left, NEXT + EXIT + "Grown-ups" on the right, icon-first buttons with a word under the icon; the cards (coming soon, ask a grown-up, gate, switch, empty, "That's the show!"). |
| `ui/theater/theater_still.gd` (`TheaterStill`) | The desktop/headless placeholder: a still drawn from the video (channel colour, stripes from its id, a play sign) and its title. |
| `ui/theater/theater_webview.gd` (`TheaterWebView`) | The wrapper around the Android singleton; `create()` is null when the build has no plugin. |
| `android/plugins/easycraft_webview/` | The Kotlin plugin `EasyCraftWebView` (Gradle project, wrapper 8.11.1, AGP 8.6.1, Kotlin 2.1.21, compileSdk 35, minSdk 24). |
| `addons/easycraft_webview/` | The export plugin (enabled in `project.godot`) and the built AARs (12 KB each). |
| `export_presets.cfg` | New preset 3, `Android Theater` (debug, Gradle build, feature tag `theater_live`, both ABIs). The other presets are unchanged. |
| `core/save/profile_data.gd` | `theater_switch` (three inserted lines). |
| `world/world_meta.gd` | `theater: [x, y, z, facing]` (four inserted lines). |
| `scenes/sandbox.gd` | `_setup_theater()` (one call in `_setup_local_player`, one section of 20 lines). |

## The Android player: plugin choice

Evaluated first, as the spec asks:

| Plugin | Licence | What it does | Verdict |
|---|---|---|---|
| office-bsmx/godot-webview (v2, Godot 4.5) | Apache 2.0 | Opens a Chrome **Custom Tab** (a full-screen browser with an address bar and share button) | Not a panel in the game; a child could browse anywhere. Rejected. |
| brown5lc/Godot-4-Android-WebView | MIT | The repository holds only the untouched Godot plugin template ("Hello World" toast); one commit, no WebView code | Nothing to use. |
| delingfenyu0711/Godot-Android-Native-WebView (found by search) | MIT | A **full-screen** transparent WebView, universal file access on, autoplay without a gesture, no navigation limits | Unsafe for children and not a panel. Rejected. |
| No plugin: `JavaClassWrapper` (Godot 4.4+) | — | Can build a `WebView`, but can't subclass `WebViewClient` (no navigation lock) or add a `@JavascriptInterface` (no "video ended") | Not enough. |

So we wrote our own minimal plugin (about 200 lines of Kotlin): one `WebView` in a see-through layer
Godot puts over its view (`onMainCreate`), placed at the pixel rectangle Godot sends; every main-frame
navigation refused (no links out, no endless feed), sub-frames only from the allowed hosts, popups
refused, no file/content access, no geolocation, mixed content never; for a child's profile no
third-party cookies and a tap needed to play; the view never takes key focus (Back reaches the game);
paused and hidden on `hide()`, freed on `close()`; `onMainPause`/`Resume`/`Destroy` handled. It emits
`video_ended` and `video_failed(code)`. Built with Gradle on this PC (`BUILD SUCCESSFUL in 9m 13s`, the
first run downloading Gradle, AGP and Kotlin); `javap` shows the class and its methods, and the AAR's
manifest carries `org.godotengine.plugin.v2.EasyCraftWebView`.

**The check APK builds here.** `godot --headless --path . --install-android-build-template --export-debug
"Android Theater" build/android/theater.apk` exited 0 in 4 min 48 s (first Gradle export; 189 MB, arm64 +
x86_64). In the APK: the manifest has `org.godotengine.plugin.v2.EasyCraftWebView` →
`com.giorgi.easycraft.webview.EasyCraftWebView` and `INTERNET`; `dexdump` finds the plugin's classes;
`assets/data/theater/sample_channels.json` is there. Not run on the emulator (the lead does that).

## Where the building stands

`TheaterSite.pick` looks around the world's first spawn in 48 directions (the seed turns the
starting direction), first 28–36 blocks out (30 first), then 38–48, then once more allowing 4 blocks
of slope instead of 2. A site needs every column under the 9 × 9 building dry (no sea, no river),
at most 2 blocks between its lowest and highest ground (the floor is the highest; the plinth, 6 deep,
fills the rest), no tree trunk within 2 blocks of the walls (leaves reach 2), dry ground for 2 blocks
in front of the door, and the building's nearest wall at least 24 blocks from the spawn (beyond the
spawn clearing, 12 past Tilly's stall at 12 and 4 past the Totem at 20, whichever way they face).
Known spots passed in `avoid` keep 6 blocks. The door faces the spawn.

Measured over 87 seeds (1–80 and seven others): **every world got a Theater**, 75 of them about 30
blocks out and 12 at 38–48 (spawns between the sea and rivers); none needed the steeper last try. The
search took 15 ms on average and 61 ms at most on this PC, once when a world is made (a LAN guest
works it out when it joins). Seed 12345 (the generator benchmark's) has no dry, tree-free spot at
28–36 and gets its Theater 44 blocks out.

## Tests: RED → GREEN

New: `tests/unit/test_theater_channels.gd` (13), `tests/unit/test_theater_rules.gd` (24),
`tests/unit/test_theater_session.gd` (15), `tests/unit/test_theater_site.gd` (11),
`tests/unit/test_parent_gate.gd` (4), `tests/integration/test_theater.gd` (23): 90 tests.

- **RED.** Every class first existed as an API stub (same names and signatures, empty bodies,
  `profile_data`/`world_meta` fields declared but not saved), so the tests parsed and failed on their
  assertions: 76 of the 89 failing and 13 passing. The 13 passing ones only assert that
  something is absent (no page for a bad id, an empty list, the sea has no site, and so on), which a
  stub trivially satisfies; they became meaningful once the real code existed.
- **GREEN, first run: 84 of 89.** Real failures found:
  - A number title came out as `"7.0"` (JSON numbers are floats); now whole numbers print as `7`.
  - The "no reward hooks" scan matched `session.` because the case-insensitive flag covered the whole
    pattern; the flag now only covers the reward words.
  - **Seed 12345 had no Theater at all.** The first search (28–36 blocks, 32 directions) failed for 3
    of 20 seeds: spawns between the sea and rivers, and 13 × 13 tree-free squares are rare (1.4 % of
    land columns have a tree). The wider search above fixed all of them, without allowing trees
    closer (a first try with a looser tree rule put leaves into the walls).
  - Two director tests failed with it (seed 12345).
- Orphans: the gate tests left 27 and 15 orphan nodes (old card buttons removed from the tree before
  `queue_free`); they are now hidden and freed in place.
- **GREEN: 89 / 89** on the new files (3,197 asserts).
- Later, a layout guard: every card (the gate with its "Not quite" line, the end card) must fit inside
  the screen area. It passed with the first number pad as well as with the slimmer one it prompted;
  made to fail on purpose with 120 px keys (keys 7–9 fell out of the screen), then put back.
- **Full suite:** `tests/run_tests.sh` exited 0, 757 / 757 tests in 88 scripts, 164.7 s at a load
  average of 46, with the Gradle export running at the same time. The 20 orphans are the older ones
  (M3 Task 13 notes); the Theater's tests leave none. After the last layout change and the fit test
  it ran once more before the commit: exit 0, **758 / 758** in 88 scripts, 146 s at a load average of
  26, no `SCRIPT ERROR` or `Parse Error`.

Covered: the sample parses (EasyCraft TV first, YouTube and TikTok), holds no key; broken JSON, no
flag, a string or number flag → hidden; source; ids per platform (injection attempts); bad channels
and videos dropped; made-for-kids must be a real yes; titles, colours, caps; a missing file. Age
rules: under-13 sees only made-for-kids videos, no TikTok (even flagged for kids), a channel with
nothing for kids disappears, EasyCraft TV stays first, no autoplay (current or next), unknown bands
get the child rules, the end card after 5 (13+ later); the parent switch both ways; every screen
state (kill-switch, ask a grown-up, desktop placeholder, phone "coming soon" with the sample or
without the plugin, the live check build, nothing to watch). The page: the official API, the
privacy-enhanced host, the app as origin/Referer (checked against the package name in
`export_presets.cfg`), autoplay only for 13+, exactly one element and nothing over it, TikTok's embed
player, no page for a bad id or a child on TikTok, allowed hosts; the pixel rectangle and the 200 px
minimum. Navigation: order across channels, BACK, the end card after 5 (BACK counts too), "more
shows", the end of the list, autoplay of the next video only for 13+, channels, an empty list,
closing; nothing is given for watching (gold unchanged, no reward-like signals, and a scan of the
Theater's code for gold / wallet / reward / XP / coins / `Session.`). Placement: real worlds (flat,
dry, no trees, floor on the highest ground, about 30 out, beyond the Totem ring), deterministic,
clear of every point of the trader's and Totem's rings, `avoid`, flat ground at 30 facing the spawn,
the seed turns it, sea / slopes / forest refused, inside vs doorway / roof / under the floor, save and
load (through JSON, broken saves), `WorldMeta`. The building: nothing solid in the room or the door,
closed walls, roof and plinth; placed and turned by the site; one static body on the world layer
with a shape per box; one shared mesh; a sign. The panel: 9:16 in the middle, the placeholder still
and title (not over the player), every button beside the player and on screen (2400 × 1080), NEXT on
the right and BACK on the left, NEXT at least 110 tall, NEXT / BACK / channels, EXIT; a child's
"ask a grown-up" → gate (a wrong answer keeps it shut and asks again) → TURN ON (saved at once) →
the show without TikTok; a parent turning it off; the end card after 5 with two equal choices, "more
shows", "back to my world". On a "phone": "coming soon" with the sample list and without the plugin;
with a fake plugin: one `show_page` per video (the page, the rect ≥ 200 px and 9:16, autoplay and
child flags, the hosts), no placeholder under it, `close` on EXIT and on the end card, a child's video
waits at its end while 13+ goes on, menus hide and reveal it once, a resize moves it. Walking in opens
the panel, EXIT keeps it closed while inside, walking out and in opens it again, walking out closes
it; a menu hides the player; the director keeps a saved site; the kill-switch builds nothing and keeps
the saved site.

## Rulings (decisions made on the owner's behalf)

1. **Our own Kotlin plugin** instead of an existing one (table above). *Cost if wrong:* about 200 lines
   of Kotlin to maintain; the iOS twin (WKWebView) is M5 on the Mac anyway.
2. **The WebView plugin ships only in Gradle builds; only the new `Android Theater` preset uses Gradle
   for now.** The game presets stay as they were (no Gradle build template needed, no new build step)
   until the Theater can really play (the owner's API accounts, spec §11, and M4's server list). *Cost
   if wrong:* one line per preset (`use_gradle_build=true`) and a template install when the Theater
   goes live; until then phones show "Coming soon", which the spec asks for anyway.
3. **"Coming soon" is decided by the list:** a phone plays only a `"source": "server"` list with the
   plugin present; the bundled list says `"sample"`. The check build (`theater_live` feature tag)
   overrides it. Desktop always plays the list as placeholders. *Cost if wrong:* none until M4.
4. **Under-13: the Theater is off until a grown-up opens it** (research H6 "default off for under-13s
   is worth considering"; spec "behind the parent gate"), and a grown-up can switch it off for any
   profile (`theater_switch`: `auto` = on for 13+, off for children). *Cost if wrong:* a child who
   expected videos meets "Ask a grown-up" first.
5. **The parent gate is a multiplication in words** (13–29 × 6–9 on a number pad). It keeps out young
   children and slows older ones; it is not verifiable consent (that is M4). *Cost if wrong:* a
   10–12-year-old can open it; the parent corner (Task 21) or M4 can replace it.
6. **No autoplay at all for under-13** (not even the first video; "one autoplaying player" is 13+
   only, as the brief says), and **every video shown counts** towards the end card, whichever way the
   child moved (NEXT, BACK, a channel). *Cost if wrong:* one more tap per video for a child.
7. **13+ also gets an end card, after 10 videos** (a natural stopping point, §6), and the list ends:
   no endless feed for anyone. *Cost if wrong:* a teenager taps "MORE SHOWS" every 10 videos.
8. **The end card's two choices look the same** ("BACK TO MY WORLD", "MORE SHOWS"; same size and
   colour, like the sleep screen), with a picture of the world from above the Theater's door. *Cost
   if wrong:* the owner may want a stronger nudge to stop.
9. **Privacy-enhanced YouTube (`youtube-nocookie.com`) for everyone**, third-party cookies off for
   children, `rel=0`, no full-screen button, and the page can never navigate away. *Cost if wrong:*
   none known; YouTube's own rules for the IFrame API still apply (checked on the device).
10. **The Referer is `https://com.giorgi.game`** (the page's base URL), tied to the package name by a
    test. The package name is a placeholder (§4): change both together before the store.
11. **The building is a node, not voxels**: unbreakable, one draw call, and the kill-switch can leave
    it out. Blocks can still be built against it, and a block tap ray passes through its walls (they
    are not voxels). *Cost if wrong:* a child can place blocks inside the walls (harmless).
12. **The Theater is per device**: each device loads the list, decides its own screen and plays its
    own video; nothing goes over the network. A LAN guest works the site out from the seed (the host's
    save is only for the host). *Cost if wrong:* if the placement rules ever change, a guest in an old
    world could see the Theater elsewhere than the host; making the host send the site is one field in
    the handshake.
13. **A 9 × 9 building 28–48 blocks out**, not always exactly 30: the nearest good ground wins. *Cost
    if wrong:* on some coasts the Theater is 40+ blocks away (12 of 87 seeds).
14. **The JS bridge is `addJavascriptInterface`** with two harmless methods (`ended`, `failed`), not
    `androidx.webkit` message listeners (a new dependency). Android exposes it to the player's iframes
    too, which can at most say a video ended. *Cost if wrong:* switch to `WebMessageListener` if a
    review asks.
15. **The YouTube API script loads without Subresource Integrity** (a security hook suggested it):
    `iframe_api` is Google's live loader and changes without notice, so a hash would break playback.
16. **The TikTok player's messages** (`onStateChange` value 0 = ended, `pause`) follow TikTok's Embed
    Player documentation as understood here; they are checked only once the owner's TikTok developer
    app exists. *Cost if wrong:* 13+ TikTok videos don't move on by themselves; NEXT still works.

## What the owner must provide (spec §11)

- A **Google Cloud project with a YouTube Data API key** (for the server, M4, to build the curated
  lists from channels; the key never goes into the app) and the curated channels themselves
  (EasyCraft TV's own clips on YouTube, flagged Made for Kids).
- A **TikTok developer app** (Embed Player terms) if TikTok for 13+ is still wanted.
- Before the store: the final package name (the Referer follows it) and, for the Kids category, the
  parent-gate decision (Apple 1.3 / Google Families).

## For the lead

- **Merge:** `scenes/sandbox.gd` gains `_setup_theater()` at the end of `_setup_local_player()` and
  one new section before "Day and night"; `world/world_meta.gd` the `theater` field (parse line before
  the targets, one `to_json` line); `core/save/profile_data.gd` `theater_switch` (field, parse line,
  `to_json` line); `project.godot` one more enabled editor plugin; `export_presets.cfg` preset 3 at the
  end; `assets/CREDITS.md` a code section; `docs/DEVELOPMENT.md` §4 (new subsection and a preset row),
  §5 and §8. New `class_name`s: `TheaterChannels`, `TheaterRules`, `TheaterSession`, `TheaterEmbed`,
  `ParentGate`, `TheaterSite`, `TheaterBuilding`, `TheaterDirector`, `TheaterPanel`, `TheaterStill`,
  `TheaterWebView` (rescan or `--import`).
- **When M2 merges:** pass Tilly's stall and the Totem to the director (`setup(..., avoid)` takes
  `Vector2i` spots); the 24-block wall distance already clears their rings. M2 Task 16's secrets should
  avoid the Theater's footprint (`TheaterSite.from_save(meta.theater)`, 9 × 9 around `pos`). The
  weapons smoke run and the tour pick flat voxel spots; one could land inside the building (not seen).
- **Emulator:** the steps in `docs/DEVELOPMENT.md` §4 ("Shorts Theater: the Android player plugin").
