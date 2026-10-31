# VR on the Meta Quest, P0-P1 — the two agents' brief (owner #101: "this is now N1 priority")

Two agents work at the same time: **VR-RIG** (the world side) and **VR-UI** (the panel side). Your role is named in your
prompt. EasyCraft is a Godot 4.7.2 game for children (typed GDScript, Voxel Tools). Work autonomously; do not ask questions
(decide, and write rulings with what they cost if wrong in your notes).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3` (the lead's contract `29070825`); `nice godot --headless --path . --import`.
2. Read **whole**: `docs/superpowers/plans/2026-10-15-vr-quest.md` (rulings 1-7, the contract, the split, the phases) and
   `docs/devlog/parts/vr-research.md` (the platform; the adaptation map with files and lines; comfort; the budget; P0-P5 with
   acceptance; "Two agents in parallel": **your fixed files**). Then the contract: `autoloads/vr.gd`, `core/vr/vr_rules.gd`,
   `core/vr/ui_layers.gd`, `tests/unit/test_vr_contract.gd`.
3. Use the godot-prompter skills that fit (xr-development, player-controller, input-handling, godot-ui, godot-testing).

## Your goal this round: P0 and P1 (the research's deliverables and acceptance), on your side of the split
- **VR-RIG:** the body of `Vr` (the XR rig: XROrigin3D, XRCamera3D, two XRController3D, persistent across scenes; `start`
  for OpenXR and WebXR — `XRServer.find_interface`, `initialize`, `get_viewport().use_xr`, V-Sync off, the refresh rate,
  foveation; `simulate` with fake head and hand trackers via `XRServer.add_tracker`), `entities/vr/*` (rig, input as a
  virtual gamepad reusing `GamepadRules.BINDINGS`, comfort vignette, haptics), the OpenXR action map (Touch / Touch Plus
  bindings), `VrRules` (walk, snap turn, vignette, eye height curves), the CameraRig VR mode (first person, head yaw/pitch,
  no shake), the body following the head, a head in a block fades, the aim seam (`Player.aim_ray` replacing the 24
  screen-point ray call sites; the right hand's laser; TAP/HOLD on the trigger), Feel in VR (shake off, flash a tint,
  vibrate haptics), spawn and teleport fades, the `vr` GraphicsPreset, the **Quest export presets** (`export_presets.cfg`
  preset.14 "Quest": Gradle, OpenXR, arm64, min SDK 32, target SDK 34, package `com.giorgi.easycraft.quest`, Mobile; preset.15
  "Quest GL" with `--rendering-method gl_compatibility`; feature tag `quest`) and the `xr/*` project settings with feature
  overrides so phones and the web stay unchanged; `tools/vr_bench.gd`. **Build the Quest APK** (`--export-debug "Quest"
  build/android/EasyCraft-quest.apk`, JAVA_HOME=$HOME/.local/jdk17, ANDROID_HOME=$HOME/android-sdk) and say its size.
- **VR-UI:** `UiLayers.route` (every CanvasLayer into the VR canvas: the research lists the 14), `Vr.ui_viewport` and
  `ui_wants_pointer` (the canvas: a 1280×720 SubViewport), `entities/vr/vr_panel.gd` (the eye panel, world-fixed, re-centred
  past 50°; the tray) and `vr_pointer.gd` (the laser into the UI with `push_input`; PadFocus there), the main menu still in
  VR (no orbit), the loading room, the pause menu, a minimal **VR COMFORT** page (turn, vignette, recenter; the `vr_*` keys
  in ProfileData), the TV sign, TEXT SIZE BIG by default in VR, the HUD on the tray; **the WebXR route**: an ENTER VR button
  (shown only where `WebXRInterface.is_session_supported("immersive-vr")`), the **Web VR** export (`export_presets.cfg`
  preset.16 "Web VR", feature tag `webxr`, `xr/shaders/enabled.webxr=true`), `tools/export_web_vr.sh` producing
  `build/web_vr/` to be served at **`/vr/`** (beside `/play/`, outside its service worker's scope; the same COOP/COEP headers
  as `/play/`: write the server config change in `server/deploy/` and say what the lead must deploy).
- **Both:** a desktop way to see it without a headset if you can (a flat "VR preview" with the fake head driven by the mouse
  is fine); never break the flat game: off VR nothing changes (the full suite proves it).

## Rules
- **No downloads** without the owner's yes (the session's safety rule): not the Godot OpenXR Vendors plugin, not Monado, not
  Godot XR Tools. Build with what Godot 4.7.2 has (the OpenXR and WebXR modules, the Khronos loader Godot's Gradle build adds
  by itself). If something truly needs a download, write it in your notes as a request for the lead.
- **Your files only** (the research's split). The rocket agent (#98) works at the same time on `ui/missions/*`,
  `entities/launch/*`, `core/rules/rocket*`, the board's hooks in `scenes/sandbox.gd`: don't touch those. Small hooks in
  `scenes/sandbox.gd`, `scenes/main.gd` or `project.godot` you cannot avoid: allowed, one line each, marked `# owner #101`,
  listed in your notes. Never change the contract's names; add to them only by noting it for the lead.
- TDD (a failing test first, for the right reason): tests `tests/**/test_vr_rig_*.gd` or `test_vr_ui_*.gd`, with
  `Vr.simulate` and fake trackers. `--import` and grep Parse Error after new class_name scripts. Single files with
  `tests/run_tests.sh -gtest=…`; the FULL suite once at the end (it waits for a PC-wide slot).
- Never open the editor or an emulator; never touch adb (the lead installs on the owner's Quest); never merge or push; never
  start agents. Keep the PC light (`nice`).

## Finish
Notes `docs/devlog/parts/vr-rig.md` or `vr-ui.md` (what you built, rulings with their cost if wrong, the seam lines for the
lead, what only the headset can check and how the lead checks it); `docs/DEVELOPMENT.md` (a VR section: build, the Quest
install with its own adb serial, the desktop preview, the tests). Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what the owner will see in the
headset, what you could not check, the full suite's result.
