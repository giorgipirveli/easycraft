# Inside a Leaf, phase B3: the voyage sings — the agent brief (owner #133, #134; "amazing and best visuals")

B2 ("the voyage plays") passed the lead's review on 2026-10-18 (`docs/devlog/parts/game-leaf-b.md`, its last section):
both voyages play from start to end, flat and VR, from every door, and `PlaySignature` is the registry every deep game
uses. This is **B3, "the voyage sings"** (the design's §4.8 step 3, about two sessions), the last part of phase B: after
it the owner's child plays Inside a Leaf, and that play decides the choice and wow tests. Work autonomously; do not ask
questions (decide, and write each ruling down with its cost).

## Read first
The design's §3.5-3.8 (the beats, show/say/do), §3.11 (the look), §4.4-4.8; your notes B1 and B2 with the lead's two
reviews; the lead's emulator check when it arrives (a message with what was seen: the first PLAY's load, the garden
while the leaf builds, both voyages' frame rates, anything that looked wrong); the audio system (`Audio`, the music and
ambience in `assets/`, how other places play their sounds), the godot-prompter skills first (audio-system,
particles-vfx, tween-animation, godot-optimization, xr-development).

## Build (B3)
1. **The loading moment** (the lead's B2 decision): the first PLAY of a session froze the page 360-720 ms here (about
   1-2 s on a phone). A picture card (the sunflower, a gentle sparkle) and Hoot's line show at once, the host is built a
   step a frame behind it, and the voyage opens when ready; never a frozen page. Granted: `SchoolScreen.show_play` and
   `DiscoveryDirector._open_place`, only where the host is made and opened (the same lines B2 touched). Test first: the
   page answers within a frame of the press; the voyage opens; Back during the loading cancels it cleanly.
2. **The desert night complete** (5.T1): the dune, the cactus's wax and its sunken doors, the jars, the night sky with
   its stars, the cactus flower opening under the stars (the design's wow), in both graphics styles.
3. **Sounds** (`tools/make_leaf_sfx.py`: synthesised, original, CC0 by construction): the doors' squeeze and pop, the
   water's bloops, the dive's whoosh and chimes, the sugar's pick and the pipe's gulp, the bud filling, cicadas at the
   desert night; placed in 3D in VR; **music and ambience** from `assets/` (what is already credited in
   `assets/CREDITS.md`); volumes under the voice (Hoot is never drowned).
4. **Juice** (calm, never scary, never a flashing screen): the bloom opening petal by petal and the bee landing, the leaf's
   lift as the cells fill, the cloud's shadow sliding over the roof, the workshops lighting, the sugar's glow, the
   dive's sparkle; the end card's stars arriving one by one.
5. **The smoke and the bench again**: `tools/leaf_smoke.gd` (both voyages, flat and simulated VR), `tools/leaf_bench.gd`
   (draws and the worst frames with the new particles and sounds); the Quest's 100 draws kept (aim 70).
6. **Pictures** in a real window under `nice`, one at a time: the bloom with the bee, the desert's flower under the stars,
   the loading card, the cloud's shadow, the end card; looked at and fixed until they are beautiful.

## Allocation and rules
- Yours as before (`core/play/leaf/*`, `entities/play/leaf/*`, `ui/play/leaf/*`, `data/play/leaf/*`, tests
  `test_leaf_*.gd`, tools `tools/leaf_*`, `tools/make_leaf_sfx.py`, the leaf's sounds under `assets/audio/leaf/` with
  their lines in `assets/CREDITS.md`, notes `docs/devlog/parts/game-leaf-b.md` (a B3 part)); the granted hooks above; the
  census (`tools/shader_probe_steps.gd`, `data/shader_warmup.json`) and `test_shader_warmup_sources.gd` for new
  materials; `test_mesh_winding.gd` for new box meshes.
- First merge `lead-w1b` (it has the rooms' look and the lead's fixes). TDD; `--import` after new class_name scripts;
  logs `leafb3_*` in the session scratchpad; the FULL suite once at the end, right after merging `lead-w1b` again. Never
  open the editor or an emulator, never touch adb; never merge into lead-merge or push; no downloads; never start
  agents; no server changes. CC0 or own assets only. English only. Commits end with
  `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.

## Finish
Notes (B3: what works, the sounds and their sources, the pictures, the draws and worst frames, the rulings). Report:
branch, commits, the pictures, the bench, the full suite, and what the lead's emulator and Quest checks and the owner's
child's first play should look for.
