# The Reel Studio: 3D scenes and real video in the Shorts — the agent brief (owner #96; spec §5.12b)

You are building EasyCraft's **Reel Studio** (Godot 4.7.2, typed GDScript, Voxel Tools), a game for children: the tools
that make the Shorts (reels) **look like real, high-quality videos**, and the first cinematic reels made with them. The
owner (2026-09-30): "consider we must keep reels high quality, implement visuals, video, animation tools and use them".
EasyCraft Shorts already exists on lead-merge (the feed in the Theater's SHORTS tab, the Short format, the player, the
style guide, the quality checker, `tools/reel_preview.gd` with frame sheets, the pluggable actor kinds). Work
autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the Shorts section, the web packs: `tools/export_web.sh`, `core/platform/web_content.gd`,
   the shader warm-up and its census rule), spec §5.12b whole, `docs/devlog/parts/shorts.md` (the style guide, the
   actor registry, where the `scene3d` and `video` hooks are), `docs/devlog/parts/animations.md` (the School pictures'
   animation API, the UI motion helper).
3. Study the game's 3D you will film: the rocket (`RocketParts`, the flight `RocketFlight`/`FlightRun`, its meshes), the
   planets and moons (`SpaceDirector`, the sky's bodies, StarMap's colours), the avatar (`AvatarParts`), the colony
   domes, the wonders, Venus's city, Saturn's rings; `SubViewport` rendering.

## What to build
1. **The `scene3d` actor.** A small 3D stage in a SubViewport inside a Short: the game's own models (a rocket built
   from real parts and its stages separating, a planet or moon as a lit sphere with its colours or texture, the
   avatar waving, blocks, a dome, a wonder's model), a studio light preset (key, fill, rim) and a sky or starfield
   background, **camera moves** (dolly, orbit, crane, push-in; eased keyframes), simple particles (engine flame,
   sparkles, dust). Seekable (a Short's frame at any time is the same), cheap (one SubViewport at the Short's size;
   no shadows on phones; measure it).
2. **Real video.** (a) `tools/reel_render.gd` + `tools/reel_render.sh`: records a Short (any: live or 3D) with Godot's
   Movie Maker (`--write-movie`, a real window, `--fixed-fps 30`) and converts it with ffmpeg to Theora video
   (`ffmpeg -i x.avi -c:v libtheora -q:v 7 -c:a libvorbis`, 540 × 960, or 720 × 1280 for the best ones) — the voice and
   sounds too if the recording carries them, else silent video with the game's live captions and voice over it.
   (b) The `video` actor / a whole-reel video playing a `.ogv` with `VideoStreamPlayer`, seekable enough for the feed's
   snapping (start at 0 on snap). (c) Delivery: the videos in a **reels pack** fetched in the background on the web
   (as the music pack: `packs.json`, kept by its content, `user://packs/`; the feed shows a video reel once its file is
   here, a still and "coming…" until then) and in the Android build (in the APK if the total stays under 20 MB, else
   the same background download; a ruling with the sizes).
3. **Cinematic reels, made with these tools** (at least 8, each 30-60 s, every fact checked with a source in your
   notes): the rocket launch and staging (from the real flight), landing on the Moon, the planets round the Sun (the
   orrery in 3D), a tour of the Moon colony's domes, Venus's floating city, Saturn's rings up close, building a rocket
   part by part on the pad, the Seven Wonders flyover. Rendered to video where live 3D would be too heavy for a phone;
   live otherwise. **Review every reel with the frame sheets** (and the rendered video's frames: `ffmpeg -vf fps=2`
   into a sheet) and fix what looks cheap before it ships; say what you changed.
4. **Quality**: follow the Shorts style guide; add to the quality checker what 3D and video need (the video file
   exists and plays, its size under a cap, its length matches the Short's, the frame not empty/black at 3 points).

## Allocation and rules
- Yours: `core/shorts/studio/*`, `ui/shorts/actors/scene3d*.gd`, `ui/shorts/actors/video*.gd`, `tools/reel_render.*`,
  `data/shorts/cinematic/*.json`, `assets/reels/*.ogv` (git-ignored if big: then the pack is built by the export script
  from `tools/reel_render.sh` outputs; a ruling), tests `tests/**/test_reel_studio*.gd`, `test_scene3d*.gd`,
  `test_video_actor*.gd`, notes `docs/devlog/parts/reel-studio.md`. Small hooks in the Shorts code and the export script.
- Every new material or particle system goes into the shader warm-up's census (the sources test guards it).
- Only CC0 assets (credited in `assets/CREDITS.md`); the game's own models first. English only; no brand names; only
  people of the past named.
- You may open a real window for the Movie Maker and the preview (not the editor). Never open the editor or an emulator;
  never touch adb; never merge or push; never start agents. Keep the PC light (renders under `nice`, one at a time).
  One full suite at the end (tests/run_tests.sh waits for a PC-wide slot).

## Finish
Notes (the tools and how to use them, each reel with its facts' sources and what the review changed, the sizes, the
cost on a phone, rulings); `DEVELOPMENT.md` (how to film a reel, render it to video, add it to the pack); spec §5.12b
"As built (Reel Studio)"; commits ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
Report: branch, commits, the reels made, frame sheets you looked at (where they are), sizes, the full suite's result,
what the lead must check on the emulator.
