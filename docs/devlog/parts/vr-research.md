# VR on the Meta Quest — the research (owner #101, 2026-10-15)

Workflow `vr-research` (run `wf_b45811ea-e78`, two agents: the platform; the game's adaptation map and budget). The plan built on it: `docs/superpowers/plans/2026-10-15-vr-quest.md`. UNCONFIRMED marks what only the headset can settle.

## The platform

### Recommendation

Do both routes in this order. They share one XR rig: XROrigin3D, XRCamera3D, two XRController3D and 3D UI panels. Only the start-up differs: XRServer.find_interface("OpenXR") on the APK and on the desktop with Monado, and find_interface("WebXR") in a browser.

STEP 0, today, no game code:
- (a) The owner opens https://178-104-20-64.sslip.io/play/ in the Meta Quest Browser as a flat page. This proves threads, SharedArrayBuffer, WebGL2 and the ETC2 pack choice work there; the shell already shows a "cannot run" message otherwise (web/shell.html:627-642). He also reads the model under Settings > About.
- (b) We host Godot XR Tools' prebuilt WebXR demo (release asset WebXR.zip of 4.5.2, MIT) on our server. That checks Quest Browser plus Godot WebXR without any of our code.

STEP 1, 1-2 days, the WebXR preview: the fastest way for the owner to try EasyCraft in VR.
- Nothing to install, no developer account, no cable: open the URL and press ENTER VR.
- Needed: xr/shaders/enabled=true, an ENTER VR button that calls WebXRInterface.initialize(), the XR rig, a short view distance, and a redeploy with tools/export_web.sh.
- It is a preview, not the product: no Space Warp, no Vulkan, WebGL and wasm overhead, and a frame rate that is not guaranteed.

STEP 2, in parallel and the main route, the native Quest APK:
- Godot 4.7.2 OpenXR with the Khronos loader that Godot 4.6+ adds by itself, plus the Godot OpenXR Vendors plugin 5.1.0-stable (Meta vendor).
- A new Gradle "Quest" preset: arm64 only, min SDK 32, target SDK 34, XR mode OpenXR.
- Mobile (Vulkan) renderer, as Godot 4.7 now recommends for new XR projects, with a Compatibility A/B build measured on the owner's headset.
- Foveation on, 72 Hz, Application SpaceWarp later.
- Delivery: adb sideload from this PC when the owner and headset are here. When he is away, a private ALPHA release channel uploaded with ovr-platform-util, which has a Linux binary. The Horizon Store last.

Plan for Quest 2 as the floor: XR2 Gen 1, 6 GB, 1832×1920 per eye, 72 Hz. Quest 3S is the same resolution on the faster XR2 Gen 2, so it is the easiest. Quest 3 adds GPU headroom but has about 30% more pixels per eye (2064×2208).

Rulings for the ledger (cost if wrong):
- The VR build is the "Children" or "Mixed Ages" store category and is for ages 10 and up (Meta's minimum).
- No Meta Platform SDK in version 1, so no Meta in-app purchases: the shop is off on Quest.
- Package com.giorgi.easycraft.quest. Changing it is free until the first store upload.

### The native Quest APK

- 1. Install the Godot OpenXR Vendors plugin 5.1.0-stable: the GitHub release asset godotopenxrvendorsaddon.zip, 48 MB; copy asset/addons/godotopenxrvendors into addons/. Godot 4.7 can also install it from the Asset Store. Its plugin.gdextension sets compatibility_minimum="4.6" and has libraries for Android, Linux, Windows and macOS only, with no web or iOS entry. Do NOT use 4.3.x, which is the line for Godot 4.4/4.5.
- 2. Exclude addons/godotopenxrvendors/* from every non-Quest preset: Android, Android Phone, Theater, Play, all Web presets, and later iOS. Their filters are at export_presets.cfg:11,78,113,147,183,302. Without this, web and phone builds would carry, or fail to load, a GDExtension that has no library for them. Update tests/unit/test_assets_pack.gd:160-174, which walks every .gdextension.
- 3. project.godot gets per-feature overrides so phones, web and the test suite stay as they are: xr/openxr/enabled=false and xr/openxr/enabled.quest=true. The Godot 4.7.2 OpenXR export plugin reads xr/openxr/enabled through the preset's feature tags. Also xr/shaders/enabled=true, needed for multiview; the Godot WebXR demo sets it too. Measure its shader cost on web with tools/web_shader_probe.py before making it global. Also xr/openxr/foveation_level=3, xr/openxr/foveation_dynamic=true, and physics/common/physics_ticks_per_second.quest=72 so physics matches 72 Hz.
- 4. Add the 'Quest' export preset (preset.14, see export_preset). The Android build template 4.7.2 is already installed in android/build (android/.build_version), and the Theater preset already exports Gradle builds headless (docs/DEVELOPMENT.md:2585).
- 5. Godot itself adds the Khronos loader when xr_mode=OpenXR. Its OpenXRExportPlugin adds the Maven dependency org.khronos.openxr:openxr_loader_for_android:<XR_CURRENT_API_VERSION>, which is 1.1.53 in the 4.7.2 template's config.gradle. It also adds the OPENXR permissions, the IMMERSIVE_HMD intent category and headtracking required=false. The Meta vendor adds com.oculus.intent.category.VR, com.oculus.supportedDevices, com.oculus.vr.focusaware and horizonos:uses-horizonos-sdk min/target 69.
- 6. Game glue, platform side:
- PlatformRules: core/platform/platform_rules.gd:44-66 treats OS.has_feature("mobile") as a touch device, so the Quest APK and the Quest Browser (web_android) would show the touch HUD. Add an XR rule (feature 'quest', or XRServer.primary_interface initialized).
- Turn off the Theater WebView plugin (addons/easycraft_webview/plugin.gd:30-37 adds its AAR to every Gradle Android build). An Android View overlay is not visible in immersive VR.
- Turn off the glow of the REALISTIC style (world/world_service.gd:196). Glow disables foveation in the Compatibility renderer.
- 7. Startup code: XRServer.find_interface("OpenXR") → is_initialized() → get_viewport().use_xr=true. XR does its own sync, so V-Sync goes off. Set display_refresh_rate (72, or 90 on Quest 3 after measuring), set_cpu_level and set_gpu_level to SUSTAINED_HIGH, and enable foveation (see perf_features). Handle the session_visible, session_focussed and session_stopping signals for the pause menu and the Quest system menu.
- 8. Action map: Godot 4.7 simplified the default action map to the generic controller profile. Add explicit Oculus/Meta Touch (Plus) bindings, because Quest runtime support for khr/generic_controller is UNCONFIRMED.
- 9. Build: nice godot --headless --path . --export-debug "Quest" build/android/EasyCraft-quest.apk. Keep a 'Quest GL' twin preset with command_line/extra_args="--rendering-method gl_compatibility" (the option exists in Godot 4.7.2's Android exporter) for the renderer A/B.
- 10. Desktop check before every headset run: Monado on this PC (testing_without_headset). It covers the OpenXR session lifecycle, the action map and both renderers' multiview shaders on the Intel iGPU.
- 11. Install on the owner's Quest over adb with its own serial (testing_on_the_owners_quest). Measure with OVR Metrics Tool against the VRC rule: 72 Hz, no long stretches under 60 fps over 45 minutes.
- 12. Later, for remote installs and the store: release-sign the APK (not debuggable), upload with ovr-platform-util to an ALPHA channel and invite the owner's Meta e-mail. Production review only after the VRCs and the age-group forms (store_and_policy).

**Plugins and versions:**

- Godot 4.7.2-stable (official): the OpenXR module is built in. Since 4.6 it bundles the Khronos OpenXR loader for Android: Maven org.khronos.openxr:openxr_loader_for_android 1.1.53 (Apache-2.0), added automatically when XR Mode is OpenXR with a Gradle build.
- Godot OpenXR Vendors plugin 5.1.0-stable (2026-05-19, for Godot 4.6+, the Meta vendor). Code is MIT. The meta/LICENSE-SDK file puts the Meta part under the Oculus SDK License Agreement; the Khronos and OpenXR headers are Apache-2.0. Version 5.0.0 removed the loader it used to bundle. Version 5.0.1 (and 4.3.1) fixed a crash with Space Warp on Godot 4.7.
- Voxel Tools 1.7 (v1.7x GDExtension, MIT), already in the repo. Its Android arm64 libraries run on Quest's arm64 Android-based OS (see voxel_tools_on_quest).
- Optional: Godot XR Tools 4.5.2 (2026-10-08, MIT): a maintenance release that fixes script errors with Godot 4.7. Useful parts are the 2D-in-3D viewport panels, pointer, snap turn, comfort vignette and teleport. Avoid 4.6.0-dev2, a pre-release with big changes.
- Dev-only, never exported: Godot XR Simulator 0.0.1 (MIT, a fork of Cafezinhu/godot-vr-simulator adjusted for Godot 4.7.2). Monado 25.0.0 from Ubuntu 26.04 universe (monado-service and libopenxr1-monado, mostly BSL-1.0). openxr-layer-corevalidation 1.1.47 (Apache-2.0).
- Not in version 1: Godot Meta Toolkit 1.0.3-stable (2025-07-29, MIT wrapper around Meta Platform SDK v77, under Meta's SDK licence). Needed only for Meta in-app purchases, the entitlement check or the Get Age Category API. A 'Children' app must not use Platform SDK features. Compatibility with Godot 4.7 is UNCONFIRMED (no release since July 2025).
- Meta tools: ovr-platform-util (proprietary, has a native Linux binary) for release-channel uploads; OVR Metrics Tool (installed on the headset from the Horizon Store). Not usable here: Meta Quest Developer Hub and the Meta XR Simulator (both Windows and macOS only).

**export preset:**

New preset.14 (export_presets.cfg has 14 presets, 0-13, and none of them uses XR):

[preset.14]
name="Quest"
platform="Android"
runnable=false
custom_features="quest"
export_filter="all_resources"
exclude_filter="spikes/*, tests/*, addons/gut/*"
export_path="build/android/EasyCraft-quest.apk"
script_export_mode=2

[preset.14.options]
gradle_build/use_gradle_build=true  ; required: "Use Gradle Build must be enabled when xr_mode is OpenXR"
gradle_build/export_format=0        ; APK
gradle_build/min_sdk="32"           ; Meta's recommendation for Quest 2/Pro/3 (29-34 allowed)
gradle_build/target_sdk="34"        ; Meta: apps created since 2026-03-01 must target 34; immersive range 32-34; Godot's default 36 would be wrong
architectures/arm64-v8a=true
architectures/x86_64=false
xr_features/xr_mode=1               ; OpenXR
xr_features/enable_meta_plugin=true ; Vendors plugin. Enable only ONE vendor per preset (plugin docs)
meta_xr_features/quest_2_support=true
meta_xr_features/quest_3_support=true    ; writes quest3|quest3s
meta_xr_features/quest_pro_support=false ; Meta: Quest Pro is not supported for users under 13
meta_xr_features/hand_tracking=<none>, passthrough=<none>, boundary_mode=<enabled> ; defaults, version 1 uses controllers
package/unique_name="com.giorgi.easycraft.quest"  ; ruling
package/name="EasyCraft"            ; the label must be unique on Meta's platform
package/exclude_from_recents=true   ; Meta release manifest: excludeFromRecents=true
screen/immersive_mode=true
permissions/internet=true
permissions/access_network_state=true   ; Nakama online play

Twin preset 'Quest GL': the same plus command_line/extra_args="--rendering-method gl_compatibility", for the renderer A/B.

Meta manifest rules the merged manifest must meet:
- launch activity has action.MAIN and com.oculus.intent.category.VR;
- installLocation auto;
- android:debuggable false in release builds;
- com.oculus.supportedDevices in <application>;
- uses-feature android.hardware.vr.headtracking.

Watch out: Godot core writes headtracking required=false, and the vendors plugin changes it to true only in boundaryless mode. Meta's page says immersive apps set it true. Check the merged manifest before the first store upload (UNCONFIRMED whether false fails review).

The Khronos loader alone (no vendors plugin) builds an APK with only IMMERSIVE_HMD and the Khronos permissions. Godot's docs say the vendors plugin is optional since 4.6 but "may be required to release on app stores". Whether a Khronos-only APK starts immersive on a Quest is UNCONFIRMED. For Quest we use the Meta vendor anyway.

**renderer:**

Use Mobile (Vulkan) as the default, as the phones already do (project.godot:355 renderer/rendering_method="mobile"), and keep a Compatibility A/B build.

Godot's guidance:
- Godot 4.7 release notes: Vulkan subsampled images (PR #116220) "dramatically improves performance of foveated rendering in the Vulkan Mobile render"; Mobile now "matches or even outperforms our Compatibility renderer in a number of benchmarks"; "we now recommend new XR projects use the Mobile renderer."
- 'Setting up XR' (stable) also recommends Mobile for standalone headsets such as Quest 3.
- The 4.7 'Deploying to Android' page still says "highly advisable to use the compatibility renderer (OpenGL) for the time being". The docs contradict each other; the release notes are the newer statement.

The Mobile gap has a history. W4 Games' 2026 talk (seen only as a search snippet; the page returned 404) started at OpenGL 72/66/72 fps against Vulkan 36/36/60 on Quest 3 and "nearly" closed it. PR #116220 measured on Quest 2, Quest 3 and Galaxy XR: about 1 ms better, Quest 3 markers 14.64→13.89 ms and 17.36→15.79 ms.

Why keep the A/B:
- Quest 2's XR2 Gen 1 has had Vulkan driver problems: Godot 4.5 worked around a Qualcomm Gen 1 fragment-density-map crash (secondary source).
- Our game already runs in Compatibility on web and the emulator (core/platform/platform_rules.gd:21-22,50), and the emulator cannot test Vulkan (docs/DEVELOPMENT.md:72-76). Only the owner's headset can settle it.
- Monado on this PC can run both renderers on the Intel iGPU (Mesa Vulkan 1.4.335).

Forward+ is not an option ("isn't well optimized for XR").

**voxel tools on quest:**

Expected to work. Not yet run on a headset, so device behaviour is UNCONFIRMED until the first install.
- The manifest addons/zylann.voxel/voxel.gdextension:25-26 maps android.debug.arm64 → bin/libvoxel.android.editor.arm64.so (9.0 MB) and android.release.arm64 → bin/libvoxel.android.template_release.arm64.so (7.3 MB). compatibility_minimum is 4.4.1 (line 4).
- readelf on the release library: ELF aarch64, "for Android 24, built by NDK r28b", 16 KB-aligned LOAD segments (0x4000). It needs only libc++_shared.so, libm, libdl and libc. Godot's own Android template ships lib/arm64-v8a/libc++_shared.so.
- Quest's OS is arm64 Android (minimum SDK 32 here, above the library's 24), and these exact binaries already run in the shipped phone APKs. So no rebuild is needed.
- Zylann/godot_voxel (MIT; latest v1.7x, 2026-08-20) has no Quest or OpenXR issues on GitHub, and no XR-specific code.
- VR-specific care:
  - Voxel's thread pool: there is only a web override today (project.godot:360 threads/count/ratio_over_max.web=0.25). Add a .quest one after measuring.
  - Collision only near the player (Player.COLLISION_DISTANCE 48, docs/DEVELOPMENT.md:4778) still applies.
  - VoxelViewer follows the XRCamera3D (the head), not the body.
- Only the voxel web build is our own build (tools/build_voxel_web.sh). The WebXR route uses the threads wasm (voxel.gdextension:29-30). The nothreads file it references (lines 31-32) is not in bin/, so the browser must be cross-origin isolated.

**perf features:**

Foveated rendering:
- Compatibility: project settings xr/openxr/foveation_level (0-3) and xr/openxr/foveation_dynamic ("Compatibility renderer only"). They are disabled when post effects such as glow, bloom or DOF are used, so the REALISTIC style's glow (world/world_service.gd:196) must be off in VR.
- Mobile: Viewport.vrs_mode=VRS_XR. OpenXRInterface.is_foveation_supported() requires that on Vulkan. Uses XR_FB_foveation_vulkan density maps (Godot 4.5, PR #99768). Subsampled images (xr/openxr/foveation_with_subsampled_images) are on by default since 4.7 (PR #117868). Open bug #124344 (4.8): foveation enabled without VRS_XR.
- Eye-tracked foveation (xr/openxr/foveation_eye_tracked; XR_META_foveation_eye_tracked, 4.6) works only on Quest Pro.

Application SpaceWarp (Meta and Pico): the app renders at half rate and the runtime makes the in-between frames.
- Turn it on with the vendors plugin's OpenXR > Extensions > 'Application Space Warp' (an advanced setting).
- Renderer needs motion vectors: Mobile since 4.5 (PR #100283), Compatibility since 4.6 (PR #97151, "primarily for use with XR_FB_space_warp").
- Vendors 5.0.1 fixed a Space Warp crash on 4.7.
- Meta's VRC allows half-rate rendering only with motion vectors that limit artifacts. Our custom shaders (voxel, water, leaves) need checking. Use it as a later lever, not a crutch.

Refresh rates:
- OpenXRInterface.display_refresh_rate, get_available_display_refresh_rates() and the refresh_rate_changed signal.
- VRC.Quest.Performance.1 allows 72/80/90/96/100/120 Hz for interactive apps and requires rendering at 60 fps or more, or half the rate with Space Warp.
- Plan 72 Hz on every model; try 90 Hz on Quest 3/3S only when there is measured headroom.

Other levers:
- render_target_size_multiplier (set before initialize).
- Meta Dynamic Resolution (vendors plugin, on by default).
- set_cpu_level / set_gpu_level (PERF_SETTINGS_LEVEL_SUSTAINED_HIGH) with the cpu_level_changed and gpu_level_changed signals for thermal throttling.
- Multiview draws both eyes in one pass.
- Godot 4.6 added OpenXR 1.1 frame synthesis (stereo only).

**What the owner does:**

- Tell us the model, or plug in the headset and we read it: Settings > About, or adb shell getprop ro.product.model. Update the headset to the latest Horizon OS; the vendors plugin's Meta manifest declares Horizon OS SDK 69.
- Create a Meta developer account (Meta requires 18+) and an organization in the Meta Horizon Developer Dashboard. Verify the account with SMS two-factor or a payment method (not PayPal). Unverified accounts lose Developer Mode.
- In the Meta Horizon phone app: tap the headset icon, pick the paired headset, then Headset Settings > Developer Mode on.
- Connect the headset to THIS PC with a USB-C data cable. Put it on and accept 'Allow USB debugging', choosing 'Always allow from this computer'. In Settings > Developer, MTP Notification may help. No driver is needed on Linux: /usr/lib/udev/rules.d/51-android.rules already lists Oculus 2833:0186 (Quest 2 and Quest 3), and the user is in plugdev.
- Optional: install the OVR Metrics Tool from the Horizon Store for the FPS overlay. Set up the Guardian boundary and a clear play space before children play.
- For the WebXR preview: open the link in the Meta Quest Browser, press ENTER VR and allow the VR permission prompt.
- For remote installs and later the store: create the app in the Developer Dashboard (name, package) and give the lead the App ID. The App Secret stays only on this PC for ovr-platform-util. Invite your own Meta e-mail to the ALPHA channel.
- For the store, later, with the lawyer (docs/store/): age-group self-certification ('Children' or 'Mixed Ages'), the Data Use Checkup, the privacy-policy URL, the IARC questionnaire, store art (CC0 or our own), organization verification. Use parent-managed Meta accounts for 10-12-year-old testers.

### WebXR in the Quest browser

**how:**

Same game code in our existing web build (Compatibility/WebGL2 is the only web renderer, and WebXR requires it). The official 4.7.2 web templates include the WebXR module: the web_dlink_release.zip godot.js contains godot_webxr_initialize, XRWebGLBinding and createProjectionLayer.

Steps:
1. Set xr/shaders/enabled=true (the Godot WebXR demo's project.godot does).
2. Add an ENTER VR button. A browser starts a session only after a user tap; Godot's demo connects it to a CanvasLayer button.
3. In code:
   - var xr := XRServer.find_interface("WebXR"); connect session_supported, session_started, session_ended and session_failed; call xr.is_session_supported("immersive-vr").
   - On the tap: session_mode="immersive-vr", requested_reference_space_types="bounded-floor, local-floor, local", required_features="local-floor", optional_features="bounded-floor, high-fixed-foveation-level". Godot passes optional_features to navigator.xr.requestSession unchanged, and Meta documents high/medium/low-fixed-foveation-level for Quest Browser.
   - Call initialize(); on session_started set get_viewport().use_xr=true.
   - Controllers: XRController3D trackers, plus the select and squeeze signals; get_input_source_tracker() for targeted rays.
   - Refresh rate: get_available_display_refresh_rates() and set_display_refresh_rate() ("not supported on all HMDs and browsers").
4. Re-export and deploy with tools/export_web.sh. The XR rig, panels and locomotion are the same code as the native APK; only the interface name changes.

**limits:**

- Godot needs WebXR Layers (XRWebGLBinding.createProjectionLayer) or the polyfill; otherwise it throws "This browser doesn't support WebXR Layers". Meta Quest Browser is the intended target of Godot's WebXR demo; native Layers support on the current Quest Browser is UNCONFIRMED by a Meta statement.
- Godot needs multiview for stereo.
- No Application SpaceWarp in WebXR (Godot PR #99433 is a draft) and no Vulkan.
- Godot does not set fixedFoveation itself; we can only request it through optional_features.
- Changing the refresh rate depends on the browser.
- Web Audio limits: no reverb or doppler.
- Our web build already freezes on first-sight shader compiles (docs/DEVELOPMENT.md §7, ShaderWarmup). In a headset a freeze is far worse; the warm-up must finish before ENTER VR.
- Expect a shorter view distance than the native APK. No Quest Browser frame-rate figures for Godot exist (UNCONFIRMED).
- 2D CanvasLayer HUDs and menus do not appear in the headset: the same world-space panel work as native.
- No store distribution; it is a link.
- Threads need SharedArrayBuffer, so cross-origin isolation. Quest Browser is Chromium-based (Wikipedia, not official), so it is expected to work. Check self.crossOriginIsolated on the device (UNCONFIRMED).

Is it the fastest way to try today? Yes, for the owner: no developer account, no developer mode, no cable, no sideload. It still needs about half a day to a day of our code and a deploy before EasyCraft itself shows in VR. The XR Tools WebXR demo can be hosted today with zero code as a device check.

**fit with our web build:**

Good fit, with small changes.

Already in place:
- The live host https://178-104-20-64.sslip.io/play/ is HTTPS (a secure context, required by WebXR) and sends cross-origin-opener-policy: same-origin, cross-origin-embedder-policy: require-corp and cross-origin-resource-policy: same-origin, on the page and on index.wasm (curl -I, 2026-10-15). No Permissions-Policy header blocks xr-spatial-tracking.
- The presets are threaded builds (export_presets.cfg:198,317 variant/thread_support=true) with our shell (lines 202, 321 html/custom_html_shell="res://web/shell.html").
- The shell picks index.mobile.pck when WEBGL_compressed_texture_etc exists (web/shell.html:1075-1094). Quest's Adreno is expected to get the ETC2 pack.

Changes needed:
1. PlatformRules.detect() (core/platform/platform_rules.gd:44-52) will see web_android in Quest Browser, so touch_device/touch_ui (lines 55-66) would turn the touch HUD on. Add an XR or Quest Browser rule (the 'OculusBrowser' user agent, or navigator.xr through WebGlue, the only JavaScriptBridge caller).
2. The full-screen and orientation-lock script in html/head_include (preset.5 and preset.7) should skip when an immersive session is starting or navigator.xr exists. Its interaction with WebXR is UNCONFIRMED.
3. xr/shaders/enabled=true adds multiview shader variants. Re-measure first-sight compiles and the warm-up with ~/src/cdpenv/bin/python tools/web_shader_probe.py build/web, and consider a .web or .quest feature override.
4. The GitHub Pages copy depends on the service worker to add the isolation headers (web/shell.html:1022-1052). Point Quest testers at the sslip.io host.
5. Nakama over WebSocket and the offline service worker are unchanged.


### Testing without headset

Four layers, from cheap and automatic to manual.

(1) Headless GUT in tests/run_tests.sh, CI-like:
- Real OpenXR cannot start under --headless: the dummy renderer has no graphics binding.
- Test the XR logic as pure rules (comfort, snap angle, vignette, locomotion limits, panel placement math, action→game-action mapping, PlatformRules with a simulated {"quest": true} / XR flag; tests already pretend through PlatformRules.simulated, docs/DEVELOPMENT.md:4008).
- Test scenes with fake trackers: XRServer.add_tracker() with XRPositionalTracker 'head' and XRControllerTracker 'left_hand'/'right_hand'; set_pose(...) and set_input(...) on the controller tracker (the XRPositionalTracker input methods are deprecated in its favour). Assert what XROrigin3D, XRCamera3D and XRController3D children do.
- A GDScript XRInterfaceExtension stub registered with XRServer.add_interface is possible in principle. Whether it is scriptable is UNCONFIRMED: spike it first.

(2) A real OpenXR runtime on this PC: Monado 25.0.0 is in Ubuntu 26.04 universe (sudo apt install monado-service libopenxr1-monado; optional openxr-layer-corevalidation 1.1.47). Its monado-service binary contains the SIMULATED_ENABLE, QWERTY_ENABLE, XRT_COMPOSITOR_NULL and XRT_COMPOSITOR_FORCE_XCB options and the text 'Null compositor starting … (for CI'.
- Automatic smoke: SIMULATED_ENABLE=1 XRT_COMPOSITOR_NULL=1 XRT_COMPOSITOR_NULL_FPS=72 IPC_EXIT_ON_DISCONNECT=1 nice monado-service. Monado's source: the null compositor paces at 20 FPS by default; the simulated HMD 'wobbles'.
- Manual: QWERTY_ENABLE=1 XRT_COMPOSITOR_FORCE_XCB=1 monado-service shows a window and drives the headset and controllers from keyboard and mouse.
- Then XR_RUNTIME_JSON=/usr/share/openxr/1/openxr_monado.json nice godot --path . --xr-mode on [--rendering-method mobile|gl_compatibility] --script res://tools/xr_smoke.gd (a new tool). Godot's --xr-mode on forces OpenXR without editing project.godot.
- This covers session start, FOCUSED, the action map binding, multiview shaders in both renderers (Intel Mesa Vulkan 1.4.335 is present) and validation-layer errors (XR_ENABLE_API_LAYERS=XR_APILAYER_LUNARG_core_validation).
- Not representative of Quest performance (desktop iGPU against Adreno), and it needs the KDE desktop session for Godot's own window. Running it on Xvfb is UNCONFIRMED.
- Note: the package registers Monado as the system-wide active OpenXR runtime (update-alternatives, /etc/xdg/openxr/1/active_runtime.json).

(3) No runtime at all: the 'Godot XR Simulator' asset (MIT, v0.0.1, a fork of Cafezinhu/godot-vr-simulator for Godot 4.7.2). The mouse moves the XRCamera; WASD and arrows are the sticks; Q/E pick a controller; left and right click are trigger and grip. Good for flat checks of panels and pointers. Dev-only, kept out of exports.

(4) WebXR on the desktop: Meta's Immersive Web Emulator extension was archived on 2026-05-22. Its runtime IWER (meta-quest/immersive-web-emulation-runtime, MIT, active) can be injected into a page; its WebXR Layers support (which Godot requires) is UNCONFIRMED.

Not available here:
- The Meta XR Simulator: Windows and macOS only.
- Quest Link / Air Link: a Windows PC (UNCONFIRMED here).
- The Android emulator: no OpenXR runtime; keep it for phone regressions only.
Never run the full suite in parallel beyond the 3 PC-wide slots.

### Testing on the owners quest

Prerequisites: the owner's steps (developer account, Developer Mode, USB debugging allowed). Then the lead, from this PC.

1. Find the serial: ANDROID_ADB_SERVER_PORT=5038 ~/android-sdk/platform-tools/adb devices -l. Listing devices is the one call without a serial. Expect a line with model:Quest_2, Quest_3, Quest_3S or Quest_Pro.

2. Every later call names it: ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=<QUEST_SERIAL> ~/android-sdk/platform-tools/adb …
- install -r build/android/EasyCraft-quest.apk
- shell am start -n com.giorgi.easycraft.quest/com.godot.game.GodotAppLauncher (the same launcher as the phone, docs/DEVELOPMENT.md:2529)
- logcat -s godot:V VrApi:I (Quest's VrApi FPS lines; whether they still print for OpenXR apps is UNCONFIRMED)
- shell getprop ro.product.model
- uninstall com.giorgi.easycraft.quest
Never touch emulator-5554's packages from this serial, and never emulator-5556 or Parkingi.

3. USB risk: the other app uses a different adb (/usr/lib/android-sdk). If its server is running, it can also claim the Quest over USB, and the connection flaps or goes offline. Two ways out:
- Switch the Quest to Wi-Fi adb: adb tcpip 5555, then adb connect <quest-ip>:5555; the serial becomes <quest-ip>:5555.
- Or start a private server just for the headset: ANDROID_ADB_SERVER_PORT=5039 ~/android-sdk/platform-tools/adb start-server --one-device <QUEST_SERIAL> (our adb 37.0.0 has --one-device).

4. Performance:
- OVR Metrics Tool (Horizon Store) as a HUD or recording, against VRC.Quest.Performance.1: use the app for 45 minutes and look for long stretches under 60 fps.
- ovrgpuprofiler -t over adb shell (Meta's WebXR docs use it).
- Godot's remote debugger and profiler through the editor's one-click deploy (the lead only).
- Run both the Mobile and the 'Quest GL' APK on the owner's model; record frame times in docs/devlog.

5. WebXR on the headset needs no adb: the owner opens the link in Quest Browser. The lead can still read the console through adb and Chrome remote debugging (UNCONFIRMED for Quest Browser).

6. When the owner is away from this PC: upload a release-signed build with ovr-platform-util (native Linux binary; App ID and Secret from the dashboard API tab) to the ALPHA release channel. Invite his Meta e-mail; he installs from his Library. Alpha, Beta and RC channels are not reviewed (only Production is) but must meet the release packaging rules.

7. Sanity check before our first APK: sideload Godot XR Tools' prebuilt Android-Quest.zip demo (4.5.2, MIT).

Meta Quest Developer Hub is Windows/macOS only and is not needed: adb, OVR Metrics, ovr-platform-util and the Linux udev rules cover everything.

### Budget

Frame budget per displayed frame:
- 72 Hz = 13.9 ms (the default and the floor).
- 90 Hz = 11.1 ms.
- 120 Hz = 8.3 ms.
- With Application SpaceWarp at 72 Hz the app renders 36 fps (27.8 ms per rendered frame). The VRC allows that only with motion vectors.
- VRC.Quest.Performance.1 needs a sustained rendering rate of at least 60 fps (half-rate with SpaceWarp) over a 45-minute OVR Metrics run. Loading screens and fades are excepted.

CPU, render thread and GPU must each fit the budget, and both eyes are drawn. Multiview submits once, but the GPU fills two eye buffers.

For scale:
- Godot's own Quest 3 benchmark in PR #116220 measured 13.89-17.36 ms per marker on the Mobile renderer. Godot's sample scene is already at the edge of 72 Hz.
- Our acceptance target today is 30 FPS on average (33 ms), no frame over 100 ms, on the 4-core emulator in Compatibility (docs/DEVELOPMENT.md:4437-4439). Phones are 3-5× slower than this PC.
- So VR needs frames about 2.4× shorter, in stereo, on a 2020-class chip (Quest 2's XR2 Gen 1).

Start the VR preset from our LOW preset (core/rules/graphics_preset.gd:19-27): view_max 64 or less (MIN_VIEW_DISTANCE 64; VR may need about 48), no shadows, simple water, sway off, half the particles, monsters_near 6 / animals_near 12. No glow (it kills Compatibility foveation). Foveation high and dynamic. 72 Hz. set_cpu_level and set_gpu_level SUSTAINED_HIGH. Physics ticks 72 (Jolt; Godot's default 60 judders against 72 Hz). Collision only within 48 blocks (DEVELOPMENT.md:4778). Scale render size through render_target_size_multiplier or Meta dynamic resolution, not scale_3d.

Pixels per eye:
- Quest 2: 1832×1920 = 3.52 MP.
- Quest 3S: the same 3.52 MP, on the faster XR2 Gen 2 with 8 GB: the easiest target.
- Quest 3: 2064×2208 = 4.56 MP, about +30% fill, on XR2 Gen 2 with 8 GB.
- Quest Pro: XR2+, eye tracking (UNCONFIRMED specs here); Meta says it is not for users under 13.

Measure on the owner's headset. Neither the emulator nor Monado on the iGPU predicts Quest frame times. The WebXR preview has more overhead (WebGL2, wasm, no SpaceWarp), so plan an even shorter view there.

### Store and policy

Store: the Meta Horizon Store. App Lab was merged into it; titles are no longer rejected for subjective quality but must meet technical, content and privacy rules.

Release channels:
- Production, RC, BETA and ALPHA. The last three are invite-only; testers are invited by e-mail or URL, and invite URLs last 90 days.
- Only Production is reviewed. Remove private testers before launch.
- Uploads go through ovr-platform-util (Linux binary available) with the App ID and App Secret.

Manifest:
- target SDK 34 (required for apps created since 2026-03-01; immersive 32-34), min SDK 32 recommended (29-34 allowed);
- com.oculus.intent.category.VR; com.oculus.supportedDevices (quest2|questpro|quest3|quest3s|vrglasses);
- headtracking uses-feature; installLocation auto; not debuggable; excludeFromRecents=true;
- a unique label.
Developer and organization accounts must be verified, or publishing and Developer Mode are blocked.

VRCs:
- Performance.1 (required for immersive apps): 72/80/90/96/100/120 Hz, at least 60 fps, half-rate only with SpaceWarp and motion vectors.
- Security.1 (an entitlement check within 10 s of launch): recommended, not required. It needs the Platform SDK, which a 'Children' app must not use, so we skip it.

Age (the key issue for EasyCraft):
- Meta's minimum is 10. Ages 10-12 need a parent-managed Meta account; Quebec 10-13 (Family Center).
- Developers must self-certify an age group in the Developer Dashboard (policy updated 2026-07-02):
  - 'Teens and Adults' (13+);
  - 'Mixed Ages' (10-12 and 13+): integrate the Get Age Category API within 30 days, which needs the Platform SDK;
  - 'Children' (under 13, ages 10-12): \"must not use Meta Platform SDK features and user data may not be shared with Meta\".
- Not every Platform SDK feature is available for ages 10-12.
- Child-directed apps must \"not include content directed solely to users under the age of 10\".
- The original Quest and Quest Pro \"are not supported for use by users under 13\".
- IARC content ratings are separate from the age group.

Consequences for us:
- The VR build is for ages 10+, although the School has grade 3 content.
- In 'Children': no Meta in-app purchases or entitlement check, so the shop stays off on Quest. Google Play Billing and Age Signals are absent anyway; the wrappers no-op: net/android_age_signals.gd:22-24, core/shop/play_billing.gd:38.
- Online chat and play with others needs a policy review.
- Reuse and extend docs/store/ (Data safety, privacy policy, retention) for the lawyer, plus Meta's Data Use Checkup, the privacy-policy URL, IARC and store art (CC0 or our own).
- Exact content and chat rules for child-directed Quest apps: UNCONFIRMED (read Meta's Content Guidelines before submission).

### Licenses

Shipped in the Quest APK:
- Godot 4.7.2 (MIT).
- Khronos OpenXR loader for Android, org.khronos.openxr:openxr_loader_for_android 1.1.53 (Apache-2.0; KhronosGroup/OpenXR-SDK-Source).
- Godot OpenXR Vendors plugin 5.1.0. Code MIT. addons/godotopenxrvendors/meta/LICENSE-SDK: \"Your use of this SDK or tool is subject to the Oculus SDK License Agreement\" (https://developer.oculus.com/licenses/oculussdk/). meta/LICENSE-LOADER and khronos, androidxr, pico, magicleap LICENSE files: Apache-2.0. The Oculus SDK License is not an open-source licence: add it to THIRD_PARTY_NOTICES.md and have the owner's lawyer note it.
- Voxel Tools 1.7 (MIT; already credited).

Optional:
- Godot XR Tools 4.5.2 (MIT).
- Godot Meta Toolkit 1.0.3 (MIT wrapper; the bundled Meta Platform SDK v77 is under Meta's SDK licence, UNCONFIRMED exact name). Not planned for version 1.

Dev-only, never shipped:
- Monado 25.0.0 (mostly BSL-1.0; parts Apache-2.0, BSD and Expat per the Debian copyright file).
- openxr-layer-corevalidation 1.1.47 (Apache-2.0).
- Godot XR Simulator / godot-vr-simulator (MIT).
- IWER (MIT).
- Meta's ovr-platform-util and OVR Metrics Tool (proprietary Meta tools, used, not redistributed).

Art: no new art is required by the platform. Any new VR art (controller models, hand meshes, comfort-vignette textures) must be CC0 and credited in assets/CREDITS.md. Note: Meta's controller render models through XR_FB_render_model are drawn by the runtime, not shipped by us.

Code plugins go into THIRD_PARTY_NOTICES.md, which is bundled.

### Risks

- Age: Meta allows Quest users from 10 (parent-managed 10-12), forbids content 'directed solely to users under 10', and does not support Quest Pro or the original Quest for under-13s. EasyCraft's School has grade 3 content (ages 8-9), so the VR build must be positioned 10+. The phone and web builds remain the under-10 product.
- Store category trade-off: 'Children' bans the Meta Platform SDK (no Meta in-app purchases, no entitlement check, no Meta social features). 'Mixed Ages' requires the Get Age Category API, which needs the Platform SDK through Godot Meta Toolkit 1.0.3; its 4.7 compatibility is UNCONFIRMED and its licence is Meta's. Online chat with others in a child-directed VR app may draw review problems (UNCONFIRMED).
- Performance: today's acceptance is 30 FPS on the emulator. VR needs a steady 72 FPS in stereo on XR2 Gen 1 (Quest 2) and at least 60 fps over a 45-minute test. Voxel meshing, Jolt, monsters, flights and the online world must all shrink. A judder-heavy first impression can make children sick.
- Renderer: Godot's docs disagree (4.7 release notes: Mobile; the 4.7 'Deploying to Android' page: Compatibility). Quest 2's XR2 Gen 1 Vulkan driver has had issues. Mobile behaviour can be verified only on the headset; the emulator cannot run Vulkan here. Mitigation: Mobile and Compatibility A/B APKs.
- Comfort and safety: smooth locomotion, flying, rocket flights and big scale changes (Size Magic) are classic motion-sickness triggers. Children need short sessions, a boundary and supervision. Quest 2's IPD range against children's eyes is UNCONFIRMED. Game design must default to comfort options (snap turn, vignette, teleport).
- UI: every HUD, menu, palette, chat and the touch controls are 2D CanvasLayer controls that do not render in the headset. All must move to world-space panels; this is the biggest cost. Also PlatformRules marks the Quest (mobile / web_android) as a touch device (core/platform/platform_rules.gd:44-66) until an XR rule is added.
- The vendors plugin GDExtension has no web or iOS library, so it must be excluded from the phone, web and (later) iOS presets. tests/unit/test_assets_pack.gd:160-174 walks every .gdextension and needs updating. It also loads in every headless test run (adds a 5 MB Linux library).
- Turning xr/shaders/enabled on globally may add shader variants and compile time on web and phones, where first-sight compiles already freeze browsers. Use a feature override or measure with tools/web_shader_probe.py before shipping.
- Gradle-only plugins: the Theater WebView plugin (addons/easycraft_webview/plugin.gd:30-37) is added to every Gradle Android build, and its Android View overlay is invisible in immersive VR. Disable the Theater on Quest or show videos on an in-world panel.
- Controllers: Godot 4.7's default action map has only the generic controller profile. Quest runtime support for khr/generic_controller is UNCONFIRMED; add explicit Touch and Touch Plus bindings or the controllers may not bind.
- Manifest details: Godot core writes headtracking required=false, while Meta's page says immersive apps set it true. targetSdk must be 34, not Godot's default 36. Verify the merged manifest before the first store or ALPHA upload.
- adb: the other app's separate adb server can grab the Quest over USB, so the connection flaps. Every call must name the Quest serial, never emulator-5556. Fall back to Wi-Fi adb or a private --one-device server on port 5039.
- Space Warp: it needs correct motion vectors from our custom shaders (voxel, water, leaves) or it shows artifacts. Use it only with vendors 5.0.1 or later on Godot 4.7 (an earlier crash).
- WebXR: Quest Browser cross-origin isolation, SharedArrayBuffer and native WebXR Layers support are UNCONFIRMED until tried on the device. The voxel web build is threads-only. The GitHub Pages copy relies on service-worker headers. The full-screen head_include script may interfere. No Space Warp. Shader-compile freezes in a headset are worse than on a phone.
- Testing gap: nothing on this PC predicts Quest performance (Monado runs on an Intel iGPU, the emulator has no XR), and the owner's time with the headset is the bottleneck. Mitigation: the ALPHA release channel for remote installs and OVR Metrics recordings.
- Ecosystem maturity: the Meta Toolkit has had no release since July 2025. Godot XR Tools 4.6 is still in dev builds. Quest support for some OpenXR features (frame synthesis, generic controller) is unverified. Pin versions and record them in docs/DEVELOPMENT.md.
- Thermal and battery: sustained high CPU and GPU levels throttle on long sessions. The cpu_level_changed / gpu_level_changed signals and OVR Metrics are needed to keep 72 Hz for 45 minutes.
- Legal: the Oculus SDK License covers the Meta part of the vendors plugin. Children's privacy (COPPA/GDPR) applies as on Play. The store forms need the owner's lawyer (docs/store/).

### Sources

- https://docs.godotengine.org/en/4.7/tutorials/xr/deploying_to_android.html
- https://docs.godotengine.org/en/stable/tutorials/xr/setting_up_xr.html
- https://docs.godotengine.org/en/stable/tutorials/xr/openxr_settings.html
- https://godotengine.org/releases/4.7/
- https://github.com/godotengine/godot/pull/116220
- https://github.com/godotengine/godot/pull/117868
- https://github.com/godotengine/godot/pull/97151
- https://github.com/godotengine/godot/pull/100283
- https://github.com/godotengine/godot/pull/99768
- https://github.com/godotengine/godot/pull/124344
- https://github.com/godotengine/godot/pull/99433
- https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/modules/openxr/editor/openxr_editor_plugin.cpp
- https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/export/export_plugin.cpp
- https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/modules/webxr/native/library_godot_webxr.js
- https://docs.godotengine.org/en/stable/classes/class_openxrinterface.html
- https://docs.godotengine.org/en/stable/classes/class_webxrinterface.html
- https://docs.godotengine.org/en/stable/classes/class_xrserver.html
- https://docs.godotengine.org/en/stable/classes/class_xrpositionaltracker.html
- https://docs.godotengine.org/en/latest/tutorials/xr/webxr_intro.html
- https://github.com/godotengine/godot-demo-projects/tree/master/xr/webxr
- https://github.com/GodotVR/godot_openxr_vendors/releases
- https://github.com/GodotVR/godot_openxr_vendors/releases/tag/5.0.0-stable
- https://github.com/GodotVR/godot_openxr_vendors/releases/download/5.1.0-stable/godotopenxrvendorsaddon.zip
- https://raw.githubusercontent.com/GodotVR/godot_openxr_vendors/master/plugin/src/main/cpp/export/meta_export_plugin.cpp
- https://raw.githubusercontent.com/GodotVR/godot_openxr_vendors/master/plugin/src/meta/AndroidManifest.xml
- https://godotvr.github.io/godot_openxr_vendors/getting-started/installation.html
- https://godotvr.github.io/godot_openxr_vendors/manual/meta/application_space_warp.html
- https://godotengine.org/article/godot-xr-update-may-2026/
- https://godotengine.org/article/godot-openxr-vendors-plugin-400/
- https://github.com/GodotVR/godot-xr-tools/releases
- https://godotengine.org/asset-library/asset/5447
- https://github.com/Cafezinhu/godot-vr-simulator
- https://github.com/godot-sdk-integrations/godot-meta-toolkit
- https://www.w4games.com/blog/w4-games-news-1/announcing-the-godot-meta-toolkit-79
- https://www.w4games.com/blog/w4-games-news-1/where-every-millisecond-counts-optimizing-godot-for-standalone-xr-159 (search snippet only; fetch returned 404)
- https://github.com/Zylann/godot_voxel
- https://github.com/KhronosGroup/OpenXR-SDK-Source
- https://developers.meta.com/horizon/resources/publish-mobile-manifest/
- https://developers.meta.com/horizon/blog/meta-quest-apps-android-14-march-1
- https://developers.meta.com/horizon/resources/vrc-quest-performance-1/
- https://developers.meta.com/horizon/resources/vrc-quest-security-1/
- https://developers.meta.com/horizon/policy/age-groups/
- https://developers.meta.com/horizon/faqs/
- https://developers.meta.com/horizon/meta-accounts-for-children/
- https://familycenter.meta.com/our-products/horizon-and-quest/
- https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/
- https://developers.meta.com/horizon/documentation/native/android/ts-mqdh-getting-started/
- https://developers.meta.com/horizon/resources/publish-release-channels
- https://developers.meta.com/horizon/resources/publish-reference-platform-command-line-utility/
- https://developers.meta.com/horizon/documentation/unity/ts-ovrmetricstool
- https://developers.meta.com/horizon/documentation/web/webxr-ffr/
- https://developers.meta.com/horizon/documentation/web/webxr-layers/
- https://developers.meta.com/horizon/documentation/web/browser-intro
- https://trunkstable.developers.meta.com/horizon/downloads/package/meta-xr-simulator-windows
- https://trunkstable.developers.meta.com/horizon/downloads/package/meta-xr-simulator-mac-arm
- https://uploadvr.com/quest-app-lab-merged-into-meta-horizon-store
- https://monado.freedesktop.org/getting-started.html
- https://gitlab.freedesktop.org/monado/monado/-/raw/main/src/xrt/targets/common/target_instance.c
- https://gitlab.freedesktop.org/monado/monado/-/raw/main/src/xrt/targets/common/target_builder_simulated.c
- https://gitlab.freedesktop.org/monado/monado/-/raw/main/src/xrt/targets/common/target_builder_qwerty.c
- https://gitlab.freedesktop.org/monado/monado/-/raw/main/src/xrt/compositor/null/null_compositor.c
- https://github.com/meta-quest/immersive-web-emulation-runtime
- https://github.com/meta-quest/immersive-web-emulator
- https://roadtovr.com/quest-3s-quest-3-quest-2-specs-compared/
- https://www.meta.com/gb/quest/compare/
- https://en.wikipedia.org/wiki/Meta_Quest_Browser
- Local evidence (this PC, 2026-10-15): apt-cache policy monado-service libopenxr1-monado openxr-layer-corevalidation (Ubuntu resolute universe 25.0.0 / 1.1.47); strings of the downloaded monado-service .deb; ~/.local/share/godot/export_templates/4.7.2.stable/android_source.zip config.gradle (openxrLoaderVersion 1.1.53, targetSdk 36, minSdk 24); readelf on addons/zylann.voxel/bin/libvoxel.android.template_release.arm64.so; /usr/lib/udev/rules.d/51-android.rules:620-628; ~/android-sdk/platform-tools/adb --help (--one-device); curl -I https://178-104-20-64.sslip.io/play/
- Repo evidence: export_presets.cfg:11,27-32,78,94-99,113,128,147,163-169,183,198,202,317,321; project.godot:17,47,347,351,355,360; addons/zylann.voxel/voxel.gdextension:4,25-32; core/platform/platform_rules.gd:21-22,44-66; core/rules/graphics_preset.gd:6,14,19-27; world/world_service.gd:196; addons/easycraft_webview/plugin.gd:30-37; net/android_age_signals.gd:22-24; core/shop/play_billing.gd:38; tests/unit/test_assets_pack.gd:160-174; web/shell.html:627-642,1022-1052,1075-1094; docs/DEVELOPMENT.md:42-46,66-76,2529,2585,4437-4446,4778

## The game's adaptation map

EasyCraft is a flat-screen game, but five seams in it turn VR into a retrofit rather than a rewrite.

(1) ONE CAMERA. CameraRig (entities/player/camera_rig.gd:1-130) is a top-level spring-arm orbit with a first-person toggle (HEAD_HEIGHT 1.55 m at :9, follow lerp at :92-101, shake at :69-90, crouch and peek at :109-125). Gameplay only reads rig.yaw and rig.pitch:
- movement: player.gd:305-307, :1749-1750
- swimming: player.gd:718
- avatar facing: player.gd:404-405
- compass and find arrow: ui/hud/find_arrow.gd:66, treasure_compass.gd:50

About 30 game nodes ask get_viewport().get_camera_3d() for distances (audio autoloads/audio.gd:440-442, the choruses, Fx, sky, thought bubbles).

(2) ONE AIM. Every world interaction is a screen-point ray, cam.project_ray_origin/normal(screen_pos). There are 24 call sites in 5 files:
- block_interactor.gd: 17
- weapon_user.gd:186-187
- gadget_user.gd:63-65
- secret_taps.gd:17-18
- trade_director.gd:383

The gesture rule is one place too: TAP = place/use/talk, HOLD 0.25 s = break (core/input/touch_classifier.gd, ui/controls/look_build_area.gd:20-44).

(3) ONE INPUT LAYER. Owner #90 made every world action an input action with a pad event:
- GamepadRules.BINDINGS: core/platform/gamepad_rules.gd:18-60
- 40 actions: project.godot:60-344

Every menu is pad-navigable through PadFocus (ui/help/pad_focus.gd:1-24). Its tests already drive it inside a SubViewport with push_input (DEVELOPMENT.md section 'Game controllers').

(4) ONE UI CANVAS. Every Control is code-built for a 1280x720 canvas (project.godot:41-47; 260 UI scripts, about 73k lines). The world's HUD and about 25 panels hang off one CanvasLayer: scenes/sandbox.gd:38, :103-105, :454, plus 17 _layer.add_child calls. There are 13 more CanvasLayers:
- menu.gd:50 and :173
- loading_card.gd:38
- feel.gd:21
- music.gd:51
- session.gd:2050
- pad_focus.gd:102
- settings_panel.gd:574/589
- dm_panel.gd:25
- coin_shower.gd
- ambience.gd:30
- visit_world.gd:30
- rocket_flight.gd:259

(5) ONE FEEL CHOKE POINT AND ONE TELEPORT PATH.
- Feel.shake/vibrate/flash/slam: autoloads/feel.gd:48-89.
- Every spawn, home, portal and void rescue goes through spawn_at/_try_spawn, then rig.snap_to_target: player.gd:116-131, :443-468, :481-489, :1765-1775, :1808-1820; world/portal_director.gd:226-233.

PROPOSED VR ARCHITECTURE

The Vr autoload:
- A persistent Vr autoload with PROCESS_MODE_ALWAYS (a paused tree must never freeze the head) owns XROrigin3D, XRCamera3D and two XRController3D.
- The main viewport gets use_xr, which is Godot's documented path (https://docs.godotengine.org/en/stable/tutorials/xr/setting_up_xr.html).
- The origin follows an anchor: the local Player's feet, the menu's stand spot, or a rocket seat. It does this in _process, interpolating the anchor's physics-tick positions with Engine.get_physics_interpolation_fraction. Physics stays at 60 Hz with no global interpolation.

The player:
- It stays body-centric, Godot's recommended room-scale layout (https://docs.godotengine.org/en/stable/tutorials/xr/xr_room_scale.html). Each tick the body moves to the head's XZ position and the origin moves back by the same amount.
- A head inside a solid block fades to black.

CameraRig gets a VR mode:
- yaw and pitch are read from the head.
- Writes to them (portal arrival, a saved yaw at sandbox.gd:193) rotate the origin, only during a fade.
- The spring arm, third person and shake are off.

The aim seam:
- A new Player.aim_ray(screen_pos) returns the camera's projection on a flat screen and the right controller's aim pose in VR.
- Godot says XRCamera3D's camera properties are overridden under use_xr (https://docs.godotengine.org/en/stable/classes/class_xrcamera3d.html).

Input:
- The controllers become a virtual gamepad: synthetic InputEventJoypadButton/Motion events go through Input.parse_input_event for the world and are also pushed into the UI viewport. GamepadRules, PadFocus and the CONTROLLER card then work unchanged.
- VR-only parts: the right stick turns by snap steps or aims a teleport; the right trigger is TAP/HOLD on the laser's target (TouchClassifier reused); controller haptics replace Input.vibrate_handheld.

UI:
- The 14 CanvasLayers are routed into one transparent 1280x720 SubViewport, VrUi. It is PROCESS_MODE_PAUSABLE, and each routed layer is freed with its owner scene. PadFocus is installed inside VrUi.
- VrUi is shown on one 3D quad with two placements:
  - Eye panel: about 1.6 x 0.9 m, 1.4 m away, while a panel is up (PadFocus.menu_has_pad(), pause, loading).
  - Chest tray: the HUD, while playing, with the touch-only controls hidden as in pad mode.
- The laser's hit UV is pushed into VrUi as mouse and touch events, the pattern in https://docs.godotengine.org/en/stable/tutorials/xr/openxr_composition_layers.html. OpenXRCompositionLayerQuad can come later for sharper text.

The rest:
- A 'vr' GraphicsPreset, a comfort module (vignette, black fades) and a VR COMFORT settings page.
- PlatformRules gets a 'quest' feature tag, so phones and the web stay byte-for-byte as today.
- Native Quest APK first: Mobile renderer, Vulkan, multiview (xr/shaders/enabled). The same code can run in the Quest Browser through WebXR later; that uses the Compatibility renderer, and the shader warm-up census must then draw stereo variants.

| Phase | Effort | Area | Today | VR change | Files | Risk |
|---|---|---|---|---|---|---|
| P0 | M | Dev loop and tests without a headset | There is a headless GUT suite, smoke tools and the emulator (AVD Pixel_8_API_35). There is no XR runtime on this PC. | Pure rules get GUT tests: VrRules (turn, vignette, eye height, panel placement), TeleportRules, the VR binding table, UI layer routing (in a SubViewport like test_pad_focus), the aim seam, and Feel and the menu in VR (no motion). 'Vr.simulate' lets tests fake a head and hands without OpenXR. A Monado OpenXR runtime with a simulated HMD on Linux could run the real XR path on this desktop (availability on Ubuntu 26.04 and the iGPU is UNCONFIRMED; the platform agent checks). On-device: the owner's Quest over adb, using this PC's adb rules (ANDROID_ADB_SERVER_PORT=5038, the Quest's own serial, never emulator-5556). | new tests/unit/test_vr_*.gd, tests/integration/test_vr_*.gd; new tools/vr_bench.gd; docs/DEVELOPMENT.md (new VR section) | The emulator cannot test VR. The owner's rule 5 (test on the emulator) needs a ruling: the emulator for non-VR regressions, the Quest for VR. |
| P1 | M | XR boot, platform flag, persistent rig | There is no XR code. main.gd:17-20 installs PadFocus and the UI scale. PlatformRules (core/platform/platform_rules.gd:9-179) knows web, android, mobile and opengl. The rendering method is mobile (project.godot:355). The export presets are Android, Phone, Theater, Play and Web (export_presets.cfg:3-402). Scene changes free everything (Game.change_scene). | A new Vr autoload (PROCESS_MODE_ALWAYS). It finds the OpenXR interface, sets get_viewport().use_xr, disables VSync, and keeps one XROrigin3D, XRCamera3D and two XRController3D across scene changes. Its anchor API is: player feet, menu spot or seat. It handles recenter (pose_recentered), focus lost (session_visible vs session_focussed: pause the game) and 'game eye height'. PlatformRules gets a QUEST feature from a custom export tag 'quest' (touch_ui false, captures_mouse false, can_vibrate false, warms_shaders false, a vr preset at first start). OpenXR and xr/shaders are switched on only for that tag (feature override in project.godot: UNCONFIRMED that the OpenXR startup honours feature overrides; the P0 spike checks it). | new autoloads/vr.gd, new entities/vr/vr_rig.gd, new openxr_action_map.tres; project.godot:27-37 (autoload), :349-356; export_presets.cfg (new 'Android Quest' Gradle preset); core/platform/platform_rules.gd:36-52, :59-75, :122-127; scenes/main.gd:17-20 | The rig must keep tracking while get_tree().paused is true (the pause menu), or the world locks to the face. Between change_scene calls there must always be an XRCamera3D, which is why the rig is persistent. The Quest flavour must leave out Google-Play-only parts (age signals net/android_age_signals.gd, the billing backend, the WebView TV). |
| P1 | L | Player camera rig to XR camera | camera_rig.gd is a top-level spring arm, 4.5 m third person by default, with a first-person toggle (:43-46). Touch, mouse and pad look write yaw/pitch (:37-41; player.gd:186-202). The rig lerps after the body (:92-101), offsets the camera for shake (:81-90), and lowers or moves the camera for crouch and peek (:109-125). The Camera3D is fov 70, near 0.1, far 300 (entities/player/player.tscn:55-57). player.gd:80 makes it current for the local player. | Add a VR mode to CameraRig. It is first person always, with no spring arm, and the CAM button and camera_toggle are hidden. yaw and pitch become getters from the XR head (gameplay code keeps reading rig.yaw). Setting yaw rotates the origin, only during a fade (portal_director.gd:232, sandbox.gd:193). Shake is a no-op. height_factor (crouch) lowers the origin, with a fade if it changes by more than 0.3 m. set_peek re-anchors behind a fade. The rig camera stays as an un-rendered stand-in, and its transform is copied from the head every frame, so player.camera() and every get_camera_3d() caller still see the head. Field of view is ignored (XR overrides it). Simple controls' follow-yaw (player.gd:1829-1832) is off in VR. | entities/player/camera_rig.gd:1-130; entities/player/player.gd:54, :80, :150-156, :186-214, :404-405, :1829-1832; entities/player/player.tscn:46-57; world/portal_director.gd:226-233; scenes/sandbox.gd:193 | rig.yaw/pitch are read and written by many tests and tools (about 60 sites under tests/ and tools/), so the desktop behaviour must stay unchanged when VR is off. There is a double-camera risk: whichever camera is current in the root viewport renders, so in VR the XRCamera3D must win every frame. |
| P1 | M | Body follows head (room scale), head in blocks | The body is a CharacterBody3D capsule, r 0.3 m, 1.8 m tall (player.tscn:9-11), moved only by the stick (player.gd:284-326). The camera floats at HEAD_HEIGHT x size above the feet (player.gd:154-155, camera_rig.gd:104-108). | Each physics tick, the head's horizontal offset from the origin moves the body with move_and_slide. The origin is shifted back by the distance actually moved (Godot's room-scale pattern). If the head is inside a solid block, or more than 0.25 m from where the body could go, the view fades to black (no x-ray through terrain: that also protects hide-and-seek). eye_position() stays body-based for game rules. Reach is measured from the real head. | entities/player/player.gd:284-326, :154-155, :389-395; new entities/vr/vr_rig.gd; new core/vr/vr_rules.gd (head-in-block and fade curve, pure) | Jolt move_and_slide is called twice per tick (stick, then head). Auto-step (player.gd:374-382) must not fire from head motion. |
| P1 | S | Eye height, seated/standing, recenter | The eye is at 1.55 m x SizeMagic scale above the feet (camera_rig.gd:9, :104-108). A crouch lowers it (StealthRules.CROUCH_EYE, player.gd:1294). | Default 'game height': at start and on every recenter, the origin's Y offset is set so the tracked eye sits at the avatar's eye height. A seated child and a 1.3 m child then see the same world as on the phone. The option 'real height' uses the floor (Local Floor or Stage reference space: https://docs.godotengine.org/en/stable/tutorials/xr/openxr_settings.html). Later: a physical crouch (head more than 35 cm below the calibrated height) maps to the crouch action. | new core/vr/vr_rules.gd; new autoloads/vr.gd; entities/player/player.gd:1294-1307 | The Stage space needs a guardian. On a recenter that lands mid-play, re-apply the height behind a short fade. |
| P1 | M | Locomotion: walk, turn, vignette | Stick or WASD walking is relative to rig.yaw (player.gd:305-307) at 6 m/s (:12). Flying is 11 m/s with 60 m/s2 acceleration (:13-16, :359-370). Ground acceleration is 45 m/s2. The right stick or mouse turns smoothly (GamepadRules.look_step, player.gd:196-202). | Walking is head-relative by default, with an option for left-hand-relative. Speeds are kept: 6 m/s is the top of Meta's 'reasonable 4-6 m/s' (https://developers.meta.com/horizon/documentation/web/iwsdk-concept-locomotion-slide/). Right stick left/right is a snap turn of 45 degrees (30 as an option); smooth turn is opt-in, as Meta advises (https://developers.meta.com/horizon/design/locomotion-best-practices/). The comfort vignette scales with stick speed, fall speed and any acceleration the child did not cause; it is on by default, with strong/light/off. Pad look (look_* actions) is never mapped in VR. | new entities/vr/vr_comfort.gd (vignette mesh on the XR camera), new core/vr/vr_rules.gd (turn and vignette curves, pure); entities/player/player.gd:196-202, :305-307 | Snap turn must rotate the origin around the head, not around the origin, or the child slides sideways. |
| P1 | M | Input: Quest controllers as a virtual gamepad | Input is keyboard/mouse, touch (TouchButton _input ScreenTouch at ui/controls/touch_button.gd:39-55, VirtualJoystick at hud.gd:47-58) and any gamepad through BINDINGS (gamepad_rules.gd:18-60). PadFocus sets world actions aside while a panel has the pad (pad_focus.gd:331-355). The sandbox maps actions at sandbox.gd:646-675. | A new VrInput maps OpenXR actions to synthetic joypad events (one fake device id), so the existing BINDINGS, PadFocus and the CONTROLLER card all work. Mapping: - left stick: walk - A: jump (double tap: fly, owner #54) - B: crouch / fly down - left grip / right grip: hotbar previous / next (shoulders) - X: MORE - Y: BLOCKS - menu button: pause (START) - left stick click: size - right stick click: walk/fly/ghost - right stick: snap turn and teleport (VR only) - right trigger: TAP place/use, HOLD break (VR only) - left trigger: attack A QUEST family with the words A/B/X/Y/trigger/grip is added to GamepadRules for the CONTROLLER card. Haptics come through XRController3D.trigger_haptic_pulse. Each event goes to the VrUi viewport first, then to the world through Input.parse_input_event if the UI did not handle it. | new entities/vr/vr_input.gd, new openxr_action_map.tres; core/platform/gamepad_rules.gd:9-14, :18-60, :64-80; ui/help/pad_focus.gd:52-60, :147-205; scenes/sandbox.gd:646-675 | UNCONFIRMED: that Input.parse_input_event joypad events from a device with no real joypad update action strengths for Input.get_vector on Android. The P0 spike checks it; the fallback is Input.action_press(action, strength). Avoid double delivery between the UI viewport and the world. |
| P1 | M | Block interaction: aim, laser, break/place | block_interactor.gd:3-4: targets come from a touch point or the screen centre (crosshair_mode, set at sandbox.gd:676-684). _ray (:309-315) uses cam.project_ray_*. There are 24 such call sites: block_interactor.gd (17: :180-191, :312, :352-353, :404-405, :419-448, :470, :597-598), weapon_user.gd:186-187, gadget_user.gd:63-65, secret_taps.gd:17-18, trade_director.gd:383. Reach is PlacementRules.ray_length from the eye. The target highlight and break ring are already 3D meshes (TargetHighlight, break_ring.gd). | Add one seam, Player.aim_ray(screen_pos) -> [origin, direction]. It returns the camera projection on a flat screen and the right (or left_handed) controller's aim pose in VR, and it replaces all 24 call sites mechanically. In VR, crosshair_mode is always true. The right trigger runs the existing TouchClassifier (TAP place/use, HOLD 0.25 s break with the break ring) through place_crosshair/break_crosshair. A thin laser and a dot show the target. When the ray hits a UI panel, world actions are suppressed. Haptic ticks on place and break. | entities/player/block_interactor.gd:51-135, :177-195, :224-230, :282-319, :339-366, :393-456, :595-605; entities/player/weapon_user.gd:186-187; entities/player/gadget_user.gd:60-65; entities/interactables/secret_taps.gd:17-18; world/trade_director.gd:383; scenes/sandbox.gd:679; core/input/touch_classifier.gd (reused); new entities/vr/vr_hand.gd | Weapons' aim assist and melee cone (WeaponRules) assume the camera ray. A hand ray from about 0.4 m below the eye changes what 'in front' means, so re-check the reach and cone tests. |
| P1 | M | UI routing: every CanvasLayer into one VR canvas | The world UI is one CanvasLayer (sandbox.gd:38, :103-105, :454) with the HUD, pause menu, Theater, Mission Board, prospecting board, inventions, keys card, photo, world map, pets, build bars, rewind, quests, trading, tutorial, space, creatures cards and flight cockpit (17 add_child calls, :835-4126). Thirteen more layers: menu.gd:50, :173; loading_card.gd:37-45; feel.gd:21; music.gd:51; session.gd:2047-2058; pad_focus.gd:102; settings_panel.gd:574-589; dm_panel.gd:25; coin_shower.gd:2; ambience.gd:30; visit_world.gd:30; rocket_flight.gd:259. With use_xr, the root canvas is not shown in the headset. | A new UiLayers.route(layer, owner) helper. In VR it reparents the layer into the Vr autoload's VrUi SubViewport (1280x720, transparent_bg, PROCESS_MODE_PAUSABLE) and frees it when its owner leaves the tree. Off VR it is a plain add_child. PadFocus is installed under VrUi in VR (main.gd:18), so focus, D-pad navigation and the ring live there. Feel's red-edge layer is not routed: in VR it becomes a head-locked tint in VrComfort. Fallback if reparenting breaks something: CanvasLayer.custom_viewport (renders elsewhere; input then has to be pushed into the root with a canvas-to-window mapping, UNCONFIRMED). | new core/vr/ui_layers.gd; scenes/sandbox.gd:38, :103-105; ui/menus/menu.gd:50, :173; ui/loading/loading_card.gd:37-45; autoloads/music.gd:51; autoloads/session.gd:2050; ui/help/pad_focus.gd:52-60, :102; ui/menus/settings_panel.gd:574-589; ui/online/dm_panel.gd:25; ui/menus/coin_shower.gd:2; world/ambience.gd:30; world/visit/visit_world.gd:30; entities/flight/rocket_flight.gd:255-262; scenes/main.gd:18 | UI code that calls get_viewport().get_camera_3d() gets null inside a SubViewport (ui/hud/sound_captions.gd:123, danger_arrows.gd:59-107, photo_mode.gd:117): use Vr.camera. Code that assumes the root's window, content scale or keyboard focus. Each extra SubViewport render costs GPU on Quest: render VrUi only when something in it is visible or changed. |
| P1 | M | VR panel, tray and laser pointer into the UI | Panels are full-screen 1280x720 Controls tapped with fingers, clicked with the mouse (emulate_touch_from_mouse, project.godot:347) or driven by a pad. | One quad, VrPanel, shows VrUi in two placements: - EYE: about 1.6 x 0.9 m, 1.4 m ahead at eye height, world-fixed and re-centred when the head turns more than 50 degrees. Used whenever PadFocus.menu_has_pad(), the pause menu or a LoadingCard is up; the world's inputs are already set aside then. - TRAY: the same texture smaller, about 1 m wide, 0.9 m away and 35 degrees below the eyes, lazily following the body's yaw. It shows hearts, hotbar, gold, toasts and context buttons (SLEEP, HELP UP, RIDE, GLIDE). The right-hand ray hits the quad, and the UV maps to canvas pixels. VrPointer pushes InputEventMouseMotion/Button and the matching ScreenTouch/Drag (index 0) into VrUi, as emulate_touch_from_mouse does for the desktop, so Buttons and TouchButtons both work. Stick navigation through PadFocus works as a free fallback. Later the eye panel can become an OpenXRCompositionLayerQuad for sharper text (the doc's intersects_ray/push_input example). | new entities/vr/vr_panel.gd, new entities/vr/vr_pointer.gd; ui/help/pad_focus.gd:84-92 (menu_has_pad); ui/controls/touch_button.gd:39-60 | A composition layer is drawn over the world unless you use hole punching with a negative sort order (the composition layers doc), and it is not visible to desktop spectators. Start with a depth-tested mesh quad and switch only if text is too soft. |
| P1 | S | Main menu in VR | menu.gd builds a live Meadows backdrop with its own Camera3D (fov 60, :12, :117-138) that orbits 34 m out at 0.05 rad/s (:9, :160-169; Reduce motion holds it still, :161). The TitleDiorama rides on that camera (:135). The UI is a CanvasLayer (:172-176) watched by PadFocus (:211). First launch needs the username typed (LineEdits at menu.gd). | In VR the menu treats the camera as Reduce motion: it never orbits. Vr anchors the origin at the camera's spot and yaw (no pitch). The diorama stays where it is (world-fixed, since _cam no longer moves), and the menu's layer goes to the eye panel. Typing uses the VR keyboard (P2); until then a 'pick a name' list. | ui/menus/menu.gd:12, :117-176, :211; ui/menus/title_diorama.gd | A first launch with no keyboard blocks the owner at the username screen: P1 needs at least the names list or a default name. |
| P1 | S | Settings and saves: VR COMFORT | DEFAULT_SETTINGS (core/save/profile_data.gd:6-31) includes reduce_motion, vibration, left_handed, text_size and pad_look. The settings pages are GAME, HELP and BUTTONS & TEXT (ui/menus/settings_panel.gd:354-398, :501). World saves keep player_yaw (sandbox.gd:193). | New keys: - vr_turn: snap45 (default), snap30 or smooth - vr_turn_speed - vr_vignette: strong, light (default) or off - vr_walk_dir: head (default) or hand - vr_teleport: on - vr_height: game (default) or real - vr_break_minutes: 30 A VR COMFORT page shows only when Vr is active, with RECENTER and a height reset. left_handed swaps the laser hand. Reduce motion in VR implies strong vignette and snap turn. Saves are unchanged; the saved yaw is applied as an origin rotation during the spawn fade. | core/save/profile_data.gd:6-31; ui/menus/settings_panel.gd:354-398, :501-570; new ui/vr/vr_comfort_page.gd; new core/vr/vr_rules.gd (defaults readable without profile_data) | A profile synced online (ProfileSync) carries the vr_* keys to phones, where they must be harmless. |
| P1 | S | Feel: shake, flash, vibrate, slams | Feel.shake wobbles the CameraRig camera (feel.gd:48-55; camera_rig.gd:69-90) from combat (world/combat_director.gd:579) and slams (stone_golem.gd:467, frost_giant.gd:266, cake_monster.gd:336, sand_serpent.gd:264). Feel.flash is a full-screen red edge on layer 90 (feel.gd:11, :21, :72-83). vibrate is Input.vibrate_handheld (feel.gd:57-68). | In VR: shake is always a no-op, whatever the Vibration setting. Flash becomes a faint red tint in the vignette mesh, capped at alpha 0.25 and at most 3 per second as today (FeelRules). Vibrate and slams become controller haptics (both hands for a slam), with no camera motion. motion_allowed() returns false in VR, so every 'anything that moves the view' check (menu.gd:161, sound_captions.gd:94, danger_arrows.gd:108, thought_bubble.gd:122) takes its calm branch. | autoloads/feel.gd:43-89; core/rules/feel_rules.gd; entities/vr/vr_comfort.gd | None beyond tests: test_feel.gd expects shakes on the desktop, so guard by Vr.active() only. |
| P1 | M | Teleports, spawns, portals, loading, scene changes | spawn_at parks a hidden body and _try_spawn snaps it (player.gd:116-131, :443-468). Also: go_home (:538-547), rescue (:481-489), void carry_back (:1808-1820), get_off_at (:1765-1775), sleep moves the body onto the bed (:512-529), portals (portal_director.gd:226-233). LoadingCard.cover shows the card until the player stands (ui/loading/loading_card.gd:37-45; sandbox.gd:465). change_scene swaps whole scenes. | Every discontinuity is a black fade: out 0.15 s, in 0.25 s, hooked once in CameraRig.snap_to_target and in _begin_spawn. A safety net fades whenever the anchor jumps more than 2 m in one frame without locomotion. Loading shows a 'loading room': a dim floor grid and horizon (never a black void for more than about 3 s), with the LoadingCard on the eye panel, world-fixed. The world fades in after spawned. Scene changes keep the persistent rig, which re-anchors. | entities/player/camera_rig.gd:63-64; entities/player/player.gd:116-131, :443-468, :481-489, :512-529, :538-547, :1765-1775, :1808-1820; world/portal_director.gd:226-233; ui/loading/loading_card.gd:37-60; autoloads/game.gd (change_scene); entities/vr/vr_comfort.gd | A spawn waiting up to SPAWN_TIMEOUT 10 s (player.gd:23) behind black must show the loading room, not darkness. |
| P1 | S | Audio | Audio is already spatial: a pool of 12 AudioStreamPlayer3D (autoloads/audio.gd:280), cut beyond 40 m of the current camera (:440-442), with choruses using the camera for distance (animal_chorus.gd:40, monster_chorus.gd:45). The listener is the current camera. | Nothing structural: the XRCamera3D is the current camera, so the listener and panning follow the head. UI clicks stay flat. Haptics are added beside the sounds that are physical (place, break, hit). | autoloads/audio.gd:270-300, :440-445; world/animal_chorus.gd:40; world/monster_chorus.gd:45 | UNCONFIRMED: which camera is the 3D audio listener if the rig's stand-in camera and the XR camera are both in the root viewport. Make the XR camera the current camera. |
| P1 | L | GraphicsPreset, view distance, terrain meshing | PRESETS LOW, MEDIUM and HIGH (core/rules/graphics_preset.gd:19-28): view_max 64 or 192, shadows 0/40/80 m, scale_3d 0.75 or 1, MSAA off or 2x. Applied in autoloads/game.gd:115-124 and world/world_service.gd:260-274. The first-start device pick is at graphics_preset.gd:58-63. VoxelTerrain uses 16-cube mesh blocks with no LOD, max_view_distance 256 (world_service.gd:74). The player's VoxelViewer is 128 (player.tscn:60). | A new 'vr' preset (details in the performance plan): - no shadows, scale_3d 1.0 (resolution comes from the OpenXR render target multiplier), MSAA 2x, view_max 64 - particles 0.5, simple water, no sway, caps of 6 monsters and 8 animals - VR-only keys: mesh_block 32 (VoxelTerrain.mesh_block_size), glow false, blocky style on Quest 2, refresh 72, VRS_XR foveation, sky update 2 s, labels' far distance 32 m The first start on a 'quest' device picks 'vr', and the settings page offers 'vr' and 'vr_plus' (Quest 3). | core/rules/graphics_preset.gd:19-63; autoloads/game.gd:115-124; world/world_service.gd:60-80, :190-200, :260-274; world/sky_cycle.gd:9; entities/fx/fx.gd (MAX_LIVE) | mesh_block_size 32 'may speed up rendering, at the cost of slower mesh updates' (https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/), so each block edit remeshes 8x the voxels on a worker. Measure the Build tools' FILL (4,096 cells) in VR. |
| P2 | M | HUD in VR | Hud (ui/hud/hud.gd:1-60) is the touch HUD from the HudLayout spots table (ui/hud/hud_layout.gd:28-80). The touch-only list (hud.gd:72) hides when a pad plays (set_pad, :334; :134). The crosshair '+' label shows in crosshair_mode (:79-81, :195-197). DangerArrows (danger_arrows.gd:59-107) and SoundCaptions (sound_captions.gd:123) project 3D positions onto the screen edge. | P1: VR uses set_pad(true) (touch-only hidden), hides the crosshair (the laser replaces it) and shows the HUD on the tray. P2: a wrist strip on the left controller shows the hotbar and hearts as UV sub-rects of VrUi taken from the HudLayout spots ('hotbar', 'hearts', 'gold'), and a toast strip ('toast', 'wave', 'boss' regions) floats lazily just above the gaze. P3: danger arrows become small 3D arrows on a ring round the head; sound captions become 3D chips toward the sound. | ui/hud/hud.gd:17-80, :125-140, :190-200, :334; ui/hud/hud_layout.gd:28-80; ui/hud/danger_arrows.gd:59-110; ui/hud/sound_captions.gd:94-130; new entities/vr/vr_panel.gd | Head-locked HUD elements cause discomfort and eye strain, so nothing is pinned to the face; everything is world- or hand-anchored. |
| P2 | M | Text input | About 13 LineEdits: chat (ui/hud/chat_panel.gd, 4), the menu's username (ui/menus/menu.gd, 2), codes (code_panel.gd), pet names (pet_panel.gd), online keys (key_sign_in_page.gd, username_claim.gd, online_friends_panel.gd, dm_panel.gd), invite code (invite_code_box.gd), Shorts maker (3). They rely on the phone's system keyboard. | A VR keyboard Control (big ABC keys and digits, plus the chat's quick phrases) is shown in VrUi under any focused LineEdit while Vr is active. It types with laser taps or stick focus. The Meta system keyboard extension is a later option (UNCONFIRMED in Godot through the vendors plugin). | new ui/vr/vr_keyboard.gd; ui/hud/chat_panel.gd; ui/menus/menu.gd; ui/menus/code_panel.gd; ui/pets/pet_panel.gd; ui/online/*.gd | The chat's online safety rules (OnlineChatRules) must apply to keyboard text as they do today; nothing new is sent. |
| P2 | M | School, Mission Board, boards, shop, books, map, Star Map, Shorts, chat | All are 1280x720 Controls in the world layer or the menu: the School (ui/school/*, the menu's screens), the Mission Board (scenes/sandbox.gd:913-919), Gemma's board (:1074-1078), inventions (:1151-1155), the Star Map (space_panel.gd:104-105), the shop and Gold Shop, books (ui/books/*), MY MAP (:2907), Shorts (ui/shorts/shorts_view.gd), chat (ui/hud/chat_panel.gd). The Theater's TV is an Android WebView laid over the panel (DEVELOPMENT.md:2559-2562, ui/theater/theater_webview.gd). Read aloud uses DisplayServer.tts_speak (ui/progress/read_aloud.gd:54). | These need no rewrite: they render on the eye panel and work with the laser or the sticks. Work items: - a readability audit per screen at 1.4 m - drag gestures in the Shorts feed and the School's pictures checked with the pointer's held button - the TV in VR shows 'TV plays on the phone or tablet' (an Android View cannot be drawn into the immersive frame); EasyCraft Shorts (our own SubViewport reels) play - read aloud checked on Quest (a TTS engine on Horizon OS is UNCONFIRMED; otherwise hide READ TO ME in VR) - the Mission Board and boards open on the eye panel when walked up to, as today | ui/school/*; ui/missions/*; ui/shop/*; ui/books/*; ui/map/*; ui/space/space_panel.gd; ui/shorts/shorts_view.gd; ui/theater/theater_panel.gd, theater_webview.gd; ui/progress/read_aloud.gd:40-60; scenes/sandbox.gd:835-919, :1074-1155, :3969-3989 | Panels that open by walking up to them (the Mission Board, the Theater, both watched on purpose) take the eye panel while the child is still moving. The eye panel should appear only once the child stops. |
| P2 | S | Text readability | The theme's default font is 30 px (ui/theme/ui_kit.gd:21). TEXT SIZE BIG is x1.25 for play words, menus excluded (ui/theme/text_size.gd:3-11). Small labels at 20 px exist (menu credit, menu.gd:190). | Panel geometry: 1.6 x 0.9 m at 1.4 m, about 56 x 36 degrees, so about 20 canvas px per degree, roughly 1:1 with Quest 2's display. 30 px text is about 1.5 degrees: readable. 20 px is about 1 degree: too small. Rules for VR: - TEXT SIZE BIG on by default. - No text under 24 px on screens shown in VR. - Keep contrast at least 4.5:1, as in Meta's guidance for Horizon OS panels: at least 14 px minimal, 18 px comfortable, 4.5:1 for text (https://developers.meta.com/horizon/design/styles_typography/, https://developers.meta.com/horizon/design/pwa/). - Try the composition layer on the eye panel. | ui/theme/ui_kit.gd:21; ui/theme/text_size.gd:11-20; ui/menus/menu.gd:183-195 | Quest 3's sharper lenses forgive more; plan for Quest 2. |
| P3 | M | Teleport | There is no player teleport. Developer /tp and the rescues jump the body (player.gd:481-489). | Right stick up shows a parabolic arc from the right hand. Release goes there with a 0.15 s black blink. A new TeleportRules (pure, tested) checks the target: it must be standable (StepRules.first_free_y), at most 1 block higher than the feet (no climbing walls that walking can't), at most 6 m away, in line of sight, and never into a hiding spot or a game area. The body jump goes through spawn-like code so RemoteSmoother snaps rather than glides for peers. | new core/vr/teleport_rules.gd; new entities/vr/vr_teleport.gd; entities/player/player.gd:473-489 (reuse _unstuck/SpawnRules); net/remote_smoother.gd (snap on more than 3 m) | In Survivor, races and the Gold Farm, teleport could skip challenges: the course and game directors may need to refuse it (CourseDirector, games_director). |
| P3 | S | Knock-outs, sleep, hiding, falling, the void | A knock-out lays the avatar down while the body holds still (player.gd:834-857). Sleep lies on the bed (:512-529). A hiding spot moves the camera inside the block (set_peek, camera_rig.gd:117-123; player.gd:1342-1370). Falls: a soft fall when out of gold (:861-905). The Dragon Realm's void carries you back (:1798-1820). | Knock-out: the view dims to 40% with the 'HELP UP' words on the eye panel; the head is never laid down. Sleep: a slow fade to night-black and back, never lying flat. Hiding: fade, then re-anchor the origin at the peek point (the barrel's inside as a small cockpit), then fade out on leaving. Long falls: the vignette ramps with fall speed. The void rescue fades. | entities/player/player.gd:512-529, :825-857, :1254-1395, :859-905, :1777-1820; entities/player/camera_rig.gd:109-125 | Fall damage and long falls in Survivor are the strongest drop sensations in VR, so keep the vignette strong while falling. |
| P3 | M | Riding, dragon flyers, gliders, hooks, ziplines, pads, flying crafts, zero-G, auto-step, knockback | Rides follow the mount's seat every frame (player.gd:1722-1762). Mount acceleration: FLY 12, SAIL 5, DRIVE 10 m/s2; top speeds up to 11 m/s (core/magic/ride_rules.gd:21-24). On a guest the mount comes through the 20 Hz sync and is smoothed (core/net/sync_pace.gd:11, net/remote_smoother.gd). Gadgets: glider, hook pull, zipline (player.gd:1566-1641). Jump and speed pads (PadRules). Invented crafts (FlightCrafts.step, player.gd:359-366). Zero-G drift (:1066-1085). Auto-step is a 7.6 m/s hop (:374-382). Knockback adds impulses (:677-679). | While the child rides, glides, is pulled, ziplines or is launched by a pad, the vignette goes stronger (motion they did not cause). Auto-step keeps the body hop, but the head's vertical is eased with a critically damped spring for steps up to 1.2 m. Knockback on the local VR body is scaled to 0 (the hit is felt as a haptic buzz and tint). A guest's own mount is predicted locally, so the head never judders on 20 Hz updates. The rider's yaw never turns with the mount (already true: only the avatar turns, :1727-1732). | entities/player/player.gd:359-382, :677-679, :1066-1110, :1566-1662, :1722-1762; core/magic/ride_rules.gd:21-28; net/remote_smoother.gd; entities/vr/vr_comfort.gd | Long gentle accelerations (SAIL 5 m/s2 lasting more than 1 s) are worse than short hard ones (Meta: keep acceleration brief). A VR comfort option may need faster ride acceleration. |
| P3 | XL | Rocket flight (RocketFlight, FlightRun, cockpit) | RocketFlight makes its own Camera3D current (entities/flight/rocket_flight.gd:200-207, :235-240, fov 70, far 1500). A BOARD glide moves the camera from the player into the capsule (:438-439). Views INSIDE, CHASE and LAUNCH blend over 0.7 s (:33, :419-442). Random shake up to 0.3 x 0.35 m comes from FlightShots (:444-447; flight_shots.gd:68-213), x0.25 with Reduce motion. The rocket pitches over and turns round with the camera seated (:405-417). FlightCockpit is a 2D overlay hull with a window, dashboard, wheel, throttle lever and ACTION button, and drag to steer (ui/flight/flight_cockpit.gd:1-12). Pad actions rocket_* already exist (gamepad_rules.gd:47-55). The sandbox re-currents the player camera after (sandbox.gd:3919). | In VR the child sits: Vr anchors the origin to the capsule seat (crew flights: each seat, rocket_flight.gd:453-457) and head tracking is free. Rules: - INSIDE view only. - The BOARD glide and view blends become fade cuts. - No shake at all; engine rumble is haptics and sound. - The pitch-over and turn-round rate is capped (about 15 degrees/s). - A 3D capsule interior gives a cockpit frame (walls, a window ring, a dashboard): the strongest vection reducer for flights. - FlightCockpit runs in a 'dashboard mode' (no 2D hull) on a VrUi quad set into the dashboard. - Steering is the left stick (rocket_steer_*), the throttle the right trigger (rocket_throttle), the action A. - The light-speed flash and clouds' white-out are softened. | entities/flight/rocket_flight.gd:190-262, :405-470, :590-600; entities/flight/flight_shots.gd:42-215; entities/flight/flight_plan.gd:6-33; entities/flight/rocket_body.gd; ui/flight/flight_cockpit.gd:1-120, :200-215; scenes/sandbox.gd:3820-3870, :3919 | This is the most VR-hostile part of the game: scripted camera moves, shake, and a rotating frame of reference. FlightShots' tests and the crew net test must keep passing on the desktop. |
| P3 | M | Photo mode, rewind, avatar preview | PhotoMode takes over the main camera with an orbit around the player (ui/photo/photo_mode.gd:113-127, :161). Build Rewind orbits a SubViewport camera shown in a Control (ui/building/rewind_view.gd:18-30). The avatar preview is a SubViewport (ui/avatar/avatar_preview.gd:27-35). | PHOTO in VR is a held camera: a SubViewport camera on the right controller shows its view on a small 3D frame in the hand, and the trigger takes the picture (PhotoFiles unchanged). The main view never orbits. Rewind and the avatar preview stay as pictures on the panel (an orbit inside a frame is comfortable). | ui/photo/photo_mode.gd:46, :110-165, :431-530; ui/building/rewind_view.gd; new entities/vr/vr_photo_camera.gd | Each extra SubViewport costs Quest GPU time: render only while it is open. |
| P3 | S | Size Magic in VR | TINY 0.25, GIANT 3.0 scale the body, capsule and camera height (core/rules/size_magic.gd:9-11; player.gd:175-184). | In VR the size also sets XROrigin3D.world_scale ('the scale of the game world compared to the real world': https://docs.godotengine.org/en/stable/classes/class_xrorigin3d.html), so a giant child feels like a giant (IPD and head motion scale), with a fade on the change. This could be a signature VR moment. | entities/player/player.gd:162-184; new autoloads/vr.gd | Tiny (world_scale 0.25) puts the near plane close to blocks: keep near at 0.05 m or more in world units. Check the world_scale direction (UNCONFIRMED which way is 'giant'). |
| P4 | L | Weapons and attacks | The attack button, the bow draw and blasters use the crosshair centre (weapon_user.gd:44, :120-140; blaster_user.gd:57). HeldItem plays keyframed swings around the avatar's hand (held_item.gd:11-24). | P1: the attack button (left trigger) aims along the right hand's ray. P4 (opt-in): swing detection from the controller's velocity triggers the same WeaponRules melee cone from the hand. The bow is drawn with two hands. The held item hangs from the controller, so no keyframed swing is needed for one's own view. | entities/player/weapon_user.gd:44-60, :120-190; entities/player/blaster_user.gd:57; entities/player/held_item.gd:1-30; core/rules/weapon_rules.gd | Physical swinging by excited children is a real-world safety risk (furniture, walls). Keep it off by default and stationary-friendly. |
| P4 | L | Avatar and animations: own body and hands | In first person the local avatar is hidden (player.gd:210-214). The held item hangs from avatar.hand() (avatar_model.gd:27-33; player.gd:634-648). The blocky and realistic avatars animate walking, swimming, emotes and celebrations (blocky_avatar.gd, realistic_avatar.gd, emote_poser.gd). | P1: controller models and simple box hands in the avatar's skin and colours (AvatarLook). P4: blocky and realistic mitten hands with grip and point poses from the trigger and grip values, the held item on the hand, and an optional mirror (the existing MirrorWall idea) so a child sees their own avatar dance. Emotes from the wheel still play for others. | entities/player/avatar_model.gd:27-35, :92-130; entities/player/held_item.gd; entities/player/player.gd:210-214, :615-660; new entities/vr/vr_hand.gd | A realistic skinned avatar's hands need the skeleton's hand bones or separate meshes (avatar_parts.gd, 1558 lines). |
| P4 | L | Multiplayer: VR bodies | Players replicate position, velocity, Avatar:rotation, physics_mode and size_mode (entities/player/player.tscn:15-32), plus code-added properties (player.gd:624-631 and the _sync_* calls at :58-71), at 20 Hz (core/net/sync_pace.gd:11). The same high-level multiplayer runs over LAN and the Nakama relay (net/nakama_link.gd:78). There is no protocol version check. | Add one replicated vr_pose: a PackedByteArray, empty for non-VR, holding the head pitch/yaw and two hand positions and rotations, quantized to about 30 bytes, at 20 Hz. A remote VR avatar turns its head and floats its hands in front of the body; a 'VR' mark goes on the name tag. The property must ship in a phone and web release before any VR build plays with them, because adding properties changes the sync layout and there is no version gate. | entities/player/player.tscn:15-32; entities/player/player.gd:58-71, :416-441; core/net/sync_pace.gd; net/remote_smoother.gd; entities/player/blocky_avatar.gd, realistic_avatar.gd | Old builds playing with new ones online will misread the sync packets, so release the field everywhere first and document it. Bandwidth is about 0.6 KB/s per VR player. |
| P5 | S | Sky, shaders, stereo correctness, shader warm-up | There are 11 game shaders. Only ui/photo/photo_filter.gdshader reads the screen, and it is 2D; no SCREEN_TEXTURE, depth or FRAGCOORD tricks in 3D. Others: water (blend_mix, shaders/water.gdshader), sway (HIGH only), the flight tunnel (cull_front, blend_add), the planets, the desert portal window (painted parallax), the avatar skin. Sky: ProceduralSkyMaterial or the realistic photo sky, updated every 1 s (sky_cycle.gd:9) incrementally (:40). ACES tonemap and depth fog (world/world.tscn:16-31). Glow in realistic (world_service.gd:196). Label3D with no_depth_test shows through hills (trader.gd:155, quest_giver.gd:73, quest_director.gd:225, prospect_camp.gd:170, helper_robot.gd:56). ShaderWarmup draws into a mono SubViewport (world/shader_warmup.gd:284-296) from data/shader_warmup.json, only for OpenGL (platform_rules.gd:164-169). | Stereo is safe: no shader needs a rewrite. Turn on xr/shaders/enabled (multiview) for the Quest build. Glow is off in VR ('many post process effects have not yet been updated to support stereoscopic rendering': setting_up_xr doc). no_depth_test labels are limited to about 30 m in VR, since the stereo depth fights the occlusion. Native Quest (Vulkan) needs no warm-up. For WebXR (Compatibility), the census and the warm-up stage must draw with multiview variants: re-run the census in an XR viewport. | world/sky_cycle.gd:9, :40; world/world.tscn:16-31; world/world_service.gd:196; world/shader_warmup.gd:284-310; data/shader_warmup.json; entities/npcs/trader.gd:155; entities/npcs/quest_giver.gd:73; world/quest_director.gd:225 | The flight tunnel and stars drawn round the camera are fine in stereo, but the light-speed flash (FlightShots flash) is a photosensitivity concern in a headset: halve it. |
| P5 | L | CPU budget at 72 Hz | Host main thread on this desktop at MEDIUM: 1.5-3.0 ms per frame quiet, 3.2-9.3 ms busy (20 monsters, pets, a ride, a farm, a race) (docs/devlog/parts/m5-task-3.md:174-181). Phones run this 3-5x slower (DEVELOPMENT.md section 7). Jolt runs at 60 ticks (project.godot:351). Long frames of 100-150 ms remain at spawns and first sights (docs/devlog/2026-09-27-m7-web.md:835-839). | Budget the main thread at 9 ms or less of the 13.8 ms frame on Quest 2. Use LOW's crowd caps or lower in VR (monsters 6, animals 8, bots 2). Keep physics at 60 with the origin interpolated (72 only if judder shows). Every frame over 28 ms is moved behind a fade or onto a worker, using the frame_probe and frame_blame tools. Fallback: Application SpaceWarp (36 Hz rendering) through the vendors plugin. Try Godot's separate render thread model, which is UNCONFIRMED for OpenXR on 4.7. | world/monster_director.gd (apply_preset), world/animal_director (apply_preset), tools/frame_probe.gd, tools/host_bench.gd; autoloads/game.gd | The CPU, not the GPU, may be what limits Quest 2 in busy Survivor nights: measure early in P0. |

### Comfort risks

- Camera shake. Feel.shake from combat (world/combat_director.gd:579) and four boss slams (stone_golem.gd:467, frost_giant.gd:266, cake_monster.gd:336, sand_serpent.gd:264) moves the camera (camera_rig.gd:81-90). The rocket adds random shake up to 0.3 x 0.35 m (rocket_flight.gd:444-447; flight_shots.gd:68-213). In VR, shake is always off; use haptics and sound.
- Forced camera moves. The menu's orbit (menu.gd:9, :160-169), the rocket's BOARD glide and 0.7 s view blends (rocket_flight.gd:33, :430-448), the photo orbit (photo_mode.gd:113-127), Simple controls' follow-yaw (player.gd:1829-1832) and the portal yaw set (portal_director.gd:232). In VR these become stationary views or fade cuts.
- Knockback on the child's own body. player.gd:677-679 adds monster and weapon impulses; in VR scale it to 0 for the local VR player and keep the hit as haptics plus a faint tint.
- Accelerations the child did not cause. Rides (ride_rules.gd:21-24: SAIL 5, FLY 12, DRIVE 10 m/s2, long and gentle, the worst kind), the glider, hook pull and zipline (player.gd:1566-1641), jump pads, triple jumps, zero-G drift (:1066-1085), the kite lift, and long falls. The vignette should be driven by acceleration and speed; Meta advises keeping acceleration brief and infrequent (https://developers.meta.com/horizon/design/locomotion-best-practices/).
- The auto-step hop. 7.6 m/s up on every 1-block ledge (player.gd:374-382) jerks the head; ease the head's vertical with a spring for steps up to 1.2 m.
- Smooth turning. The pad or touch look (GamepadRules.look_step) must never reach the VR view. Snap 45 is the default; smooth turn is opt-in (Meta: smooth turning opt-in; teleport and snap turn as defaults for new users, https://developers.meta.com/horizon/documentation/web/iwsdk-concept-locomotion-slide/).
- Head-locked UI. Feel.flash's full-screen red edge (feel.gd:72-83), toasts and the HUD pinned to the face cause strain. Use world- or hand-anchored panels with lazy follow, and a red tint capped at alpha 0.25.
- A paused tree freezing the head. The pause menu pauses the tree; the XR rig must run with PROCESS_MODE_ALWAYS, or the world sticks to the face (nausea within seconds).
- Long frames. Today's budget tolerates 100 ms frames (DEVELOPMENT.md:4437-4441), and single 100-150 ms spikes remain (docs/devlog/2026-09-27-m7-web.md:835-839). In VR every dropped frame judders, so spawns, world loads, saves and first-seen materials go behind fades, with a play budget of no frame over 2 refreshes (about 28 ms).
- Head inside blocks. Leaning or walking physically into terrain shows the hollow inside of the world (also a hide-and-seek cheat). Fade to black as in Godot's room-scale guide (https://docs.godotengine.org/en/stable/tutorials/xr/xr_room_scale.html).
- Black voids. A spawn can wait up to 10 s (player.gd:23) and world loads take 4-12 s on the emulator (docs/devlog/2026-09-26-release-1.0.0.md:36-43). Show a loading room with a floor and horizon, never black for more than about 3 s.
- Network judder while riding as a guest. The mount's position comes at 20 Hz smoothed (core/net/sync_pace.gd:11). Predict the mount locally for the rider's own head.
- The rocket's rotating frame. The pitch-over and the turn-round with the child seated (rocket_flight.gd:405-417). Use a 3D cockpit frame, cap rotation at about 15 degrees/s, and offer no CHASE view in VR.
- Photosensitivity in a headset. The light-speed flash and clouds' white-out (FlightShots flash and cloud), Venus lightning and the confetti bursts: halve flashes in VR and keep FeelRules' 3-a-second cap.
- Stereo conflicts. Label3D with no_depth_test seen through hills (trader.gd:155, quest_giver.gd:73, quest_director.gd:225, prospect_camp.gd:170) shows near-looking text at far stereo depth: cap the distance in VR.
- Scale jumps. Size Magic x0.25 or x3 (size_magic.gd:9) applied instantly to the eye height and world_scale: fade it.
- Speed. Walking 6 m/s and flying 11 m/s (player.gd:12-13) are at or above Meta's 'reasonable 4-6 m/s'; offer a SLOWER comfort option if the child reports discomfort.
- Age and session length. Meta lowered Quest accounts to ages 10+ (parent-managed for 10-12) in 2023 (https://www.roadtovr.com/meta-quest-age-limit-10-years/; Meta's current policy page not checked). Add a gentle break card every 30 minutes and a seated-friendly default (game eye height, no required arm swinging).
- Physical safety. Opt-in swing attacks (P4) and standing play with excited children: keep the guardian on, swings off by default, and nothing that makes the child spin or step backwards.

### Performance today

BUDGET TODAY
On the emulator: at least 30 FPS average and no frame over 100 ms, during the autopilot's 60 s of play and its 2 km flight, in both styles (docs/DEVELOPMENT.md:4437-4441).

PRESETS (core/rules/graphics_preset.gd:19-28)
| Preset | Shadows | 3D scale | MSAA | View max | Other |
|---|---|---|---|---|---|
| LOW | none | 0.75 | off | 64 | half particles, simple water, at most 6 monsters and 12 animals near |
| MEDIUM | sun, 40 m | 1.0 | off | 192 (slider default 128, profile_data.gd:6) | the phones' default |
| HIGH | sun, 80 m | 1.0 | 2x | 192 | swaying leaves |

- Applied in autoloads/game.gd:115-124 and world/world_service.gd:260-274; the fog ends at the view distance.
- A weak phone (under 3.5 GiB or 4 cores or fewer) starts on LOW (graphics_preset.gd:58-63). The emulator counts as weak.
- Terrain: VoxelTerrain with no LOD, 16-cube mesh blocks, max_view_distance 256 (world_service.gd:74). The player's VoxelViewer is 128 (player.tscn:60).

GPU AND DRAW CALLS
The visuals bench: this PC's Intel iGPU, Vulkan Mobile, MEDIUM, 1600x720 = 1.15 MP (docs/devlog/parts/visuals.md:94-112).
- Green Meadows: 6.8-41.9 ms of GPU a frame, mean 22.1 ms; 206-530 draws.
  - blocky noon: 342 draws, 22.8 ms
  - blocky morning: 526 draws, 26.0 ms
  - realistic morning: 530 draws, 41.6 ms
  - realistic ground: 400 draws, 29.6 ms
- Other worlds' views: mean 4.4 ms (visuals.md:114).
- OpenGL draws the same views with 307-1303 draws (visuals.md:76-92).
- World 41's landing: 214 draws after a cut (docs/devlog/2026-09-27-m7-web.md:825).
- M1b spawn on the desktop: 349 draws (docs/devlog/2026-09-23-m1b.md:348).

FRAME RATE ON THE EMULATOR
- 1.0.0: 35.9-58.6 FPS in play, worst frames 33-146 ms (docs/devlog/2026-09-26-release-1.0.0.md:36-43).
- 2026-09-30: 37.8-57.5 FPS, still with single 100-150 ms frames at spawns and in flights (docs/devlog/2026-09-27-m7-web.md:789-795, :835-839).

CPU
- Host main thread on this desktop at MEDIUM: 1.5-3.0 ms per frame quiet, 3.2-9.3 ms busy (docs/devlog/parts/m5-task-3.md:174-181).
- Ruling: at most 10 ms here. Phones are 3-5x slower (DEVELOPMENT.md section 7).
- Jolt physics at the default 60 ticks (project.godot:351).

STYLE, SKY AND SHADERS
- Realistic style: photo pages with normal maps (a 60 MB page budget), glow on (world_service.gd:196), +30-60% GPU against blocky in the Vulkan views.
- Sky: re-tinted every 1 s, incremental radiance (sky_cycle.gd:9, :40).
- Shader warm-up is only for OpenGL and WebGL (platform_rules.gd:164-169). Vulkan compiles pipelines in the background.

### The VR performance plan

WHAT A QUEST 2 NEEDS
Meta's device comparison (https://developers.meta.com/horizon/resources/device-optimization-comparison/):
- 72 Hz, a 13.8 ms frame
- fewer than 100 draw calls
- fewer than 750K triangles
- Quest 3 has about 2.5x the GPU, 8 GB RAM, fewer than 200 draws, 1.5M triangles, 2064x2208 per eye, and 90 Hz recommended

Pixels: 1440x1540 per eye at 100% render scale (https://developers.meta.com/vr/essentials/render-scale/), so 4.4 MP for both eyes.
- Against a 2400x1080 phone (2.6 MP at the 33 ms budget): about 1.7x the pixels in 2.4x less time.
- Against the bench's 1.15 MP: 3.9x the pixels.
- That is 4-9x today's pixel throughput.
- The bench's per-pixel cost on this iGPU (about 19 ms per MP at MEDIUM) would give about 85 ms a frame. The XR2's speed relative to this iGPU is UNCONFIRMED, but plan for about 6x cheaper pixels.
- Multiview submits each draw once for both eyes. Draws still have to fall from 267-530 to 100-150.

CPU: the 13.8 ms frame against today's busy 3-9 ms here, x3-5 on a phone-class CPU = 10-45 ms. Busy Survivor nights are over budget.

THE 'vr' PRESET (Quest 2 floor)

What it turns off or cuts:
1. No sun shadows (they remove the shadow pass's draws and the shadow sampling).
2. View 64 blocks (LOW's), fog as today.
3. Blocky style only, glow off. Realistic waits for Quest 3.
4. Simple water, no sway, particles x0.5, Fx.MAX_LIVE 16.
5. Crowd caps: at most 6 monsters and 8 animals near, at most 2 bot friends.
6. Name tags, plaques and no_depth_test labels hidden past about 32 m.
7. Sky re-tint every 2 s instead of 1 s (sky_cycle.gd:9), with a small radiance size.

What it adds or changes:
8. Resolution: scale_3d stays 1.0. Below 1 it moves tonemapping into a later pass (world/shader_warmup.gd:290-291). Use OpenXRInterface.render_target_size_multiplier instead, which must be set before the interface initialises (https://docs.godotengine.org/en/stable/classes/class_openxrinterface.html): 1.0, with 0.85 as the first lever.
9. Foveation: Viewport.vrs_mode = VRS_XR, the Mobile renderer's path (https://docs.godotengine.org/en/stable/tutorials/xr/openxr_settings.html), vrs_strength 1.0, vrs_min_radius 20.
10. MSAA 2x (4x on Quest 3), with alpha-to-coverage on the cut-out leaves.
11. VoxelTerrain.mesh_block_size 32 (https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/): about 4-8x fewer terrain meshes. Measure edit remesh time.
12. Refresh 72 Hz.

Physics and fallbacks:
- Physics stays at 60 Hz, with the XR origin interpolated between ticks in _process. Godot's alternative, raising Engine.physics_ticks_per_second (setting_up_xr doc), costs +20% physics CPU.
- Emergency lever, not the plan: Application SpaceWarp (render at 36 Hz, frames synthesised). Supported since Godot 4.5 through the OpenXR vendors plugin (https://uploadvr.com/godot-now-supports-more-xr-features-builds-a-universal-openxr-apk ; the 'Meta SpaceWarp Sample' asset, https://godotengine.org/asset-library/asset/edit/17862). It needs motion vectors and costs artefacts.

'vr_plus' for Quest 3: view 96, sun shadows 24 m, MSAA 4x, realistic allowed, 90 Hz.

LONG FRAMES
In a headset every frame over 2 refreshes (about 28 ms) is felt. These go behind the spawn and teleport fades or onto workers:
- world loading, saves, first-seen materials, big edits
- re-use tools/frame_probe.gd and frame_blame with --voxel-threads matched to the Quest's cores

TARGETS
P1 (Green Meadows, blocky, Quest 2):
- at least 72 FPS average
- 1% dropped frames or fewer over 2 minutes of walking and building
- 150 draws or fewer
- after the first 5 s, no frame over 28 ms

P5 (every universe and planet, the autopilot's play phase, plus a FLY cruise instead of the 2 km flight):
- 100 draws or fewer, 750K triangles or fewer
- GPU 11 ms or less, main thread 9 ms or less
- no frame over 28 ms after the spawn fade

MEASUREMENT
- A new tools/vr_bench.gd, plus an in-game VR_BENCH logcat line per world: Performance draw calls, primitives, process and physics ms, viewport GPU time, main-thread CPU.
- Desktop draw and primitive counts with tools/look_shots.gd --preset=vr before each headset run.
- Meta's OVR Metrics Tool on the headset (UNCONFIRMED for this build).
- Always record the Quest model and its refresh rate with the numbers.

### Phases

**P0: Spike and contract: prove the 5 risky engine paths on the owner's Quest and freeze the API both agents build against.**

- 'Android Quest' export preset (Gradle, OpenXR, feature tag 'quest', the vendors plugin per the platform research) that boots a test scene in the headset
- Spike answers, with measurements in the devlog:
(1) the persistent Vr origin survives change_scene
(2) a 1280x720 UI SubViewport on a quad works with laser push_input, and PadFocus works inside it
(3) synthetic joypad events drive Input.get_vector on Quest
(4) OpenXRCompositionLayerQuad text against the mesh quad
(5) Green Meadows at LOW: draws, GPU ms and main-thread ms on the Quest at 72 Hz
- The lead's contract commit: an autoloads/vr.gd stub with its frozen API (active(), camera, hand_ray(side), anchor(node, kind), fade_out/in, ui_viewport(), ui_wants_pointer()), core/vr/vr_rules.gd with the settings keys and defaults, and the seam lines in scenes/sandbox.gd and scenes/main.gd
- Spec section 3b entry and docs/superpowers/plans/2026-10-15-vr-quest.md; a DEVELOPMENT.md VR section (build, install on the Quest, adb rules for the Quest's serial)
- A desktop XR dev loop if available (Monado with a simulated HMD: UNCONFIRMED)

_Acceptance:_ The owner sees Green Meadows in the Quest with head tracking at the headset's refresh rate. All five spike questions are answered with numbers in docs/devlog. The full desktop suite stays green: Vr is inactive off-Quest, so behaviour is unchanged.

**P1: The smallest thing the owner can put on and enjoy: stand in his world, look, walk, turn, break and place blocks, use the main menu and the pause menu as panels.**

- Vr rig: PROCESS_MODE_ALWAYS, origin anchored to the player with interpolation, game eye height, recenter
- CameraRig VR mode: head yaw and pitch, no shake, first person only
- The body follows the head; a head inside a block fades to black
- VrInput: controllers as a virtual gamepad (BINDINGS reuse, a QUEST family for the CONTROLLER card) and haptics
- Snap turn 45, head-relative walking, vignette v1
- The aim seam (24 call sites) with the right-hand laser and TAP/HOLD on the right trigger, with the break ring
- UiLayers routing of the 14 CanvasLayers into VrUi; PadFocus installed there
- VrPanel eye and tray modes; VrPointer into the UI
- The menu stationary in VR; the loading room; spawn fades
- Feel in VR: shake off, flash becomes a tint, vibrate becomes haptics
- 'vr' graphics preset v1: LOW plus mesh blocks 32, VRS_XR, MSAA 2x, glow off
- A minimal VR COMFORT page (turn, vignette, recenter)
- GUT tests: test_vr_rules, test_vr_input_bindings, test_vr_aim_seam, test_vr_ui_layers, test_vr_feel, test_vr_menu_still, test_vr_spawn_fade

_Acceptance:_ On the owner's Quest, without help:
- menu to SANDBOX (NEW and CONTINUE)
- walk 100 m, turn round with snap turn
- break 10 blocks (HOLD) and place 10 (TAP) with the laser; pick another block from the hotbar and from BLOCKS; open MORE
- pause, then SAVE & QUIT, then the menu
Performance and comfort:
- Quest 2 (or the owner's model, recorded), Green Meadows blocky: at least 72 FPS average, 1% dropped frames or fewer over 2 minutes, after the first 5 s no frame over 28 ms, 150 draws or fewer (VR_BENCH line)
- no camera motion the child did not make (the tests above)
The desktop suite is green.

**P2: The School and the boards: every panel readable and usable in VR, typing, and a better HUD.**

- A readability pass over every screen shown in VR: no text under 24 px, TEXT SIZE BIG on by default in VR, contrast checks
- The eye panel as an OpenXRCompositionLayerQuad, if P0 found it sharper
- A VR keyboard for the 13 LineEdits (username, chat, codes, pet names, online keys, invite code, Shorts maker)
- Checked with the laser and with the sticks: School lessons and quizzes, the Mission Board and the Gold Shop, Gemma's board, the inventions book, the Star Map, books, MY MAP, the Shorts feed and maker, chat
- The TV shows a 'TV plays on the phone or tablet' sign in VR; read aloud checked or hidden
- A wrist hotbar and hearts and a toast strip (UV sub-rects from the HudLayout spots)
- A 30-minute break card; the full VR COMFORT settings

_Acceptance:_ A test like test_pad_screens over VrUi finds every School and menu screen reachable with the pointer and with the sticks. On the Quest the child finishes one School lesson, buys a rocket part on the Mission Board and types a pet name. A screenshot audit shows no text under 22 px on the eye panel. The owner confirms the default text is readable.

**P3: Flights and comfort: the rocket, rides, gadgets and every discontinuity made comfortable.**

- Fades on every teleport, portal, home, void rescue, dismount, size change and hiding spot
- Teleport on right stick up, with TeleportRules: standable, at most 1 block up, at most 6 m, in line of sight
- A vignette driven by speed and acceleration for rides, the dragon and flyers, glider, hook, zipline, pads, zero-G and falls
- Knockback 0 for the VR body; the auto-step head eased; a guest's own mount predicted
- The rocket flight in VR:
- the seat anchor (crew seats too) and a 3D capsule interior with a window and dashboard
- FlightCockpit's dashboard mode on a quad
- INSIDE view only, fade cuts instead of glides and blends, no shake, rotation at most about 15 degrees/s
- steering on the left stick, throttle on the right trigger, action on A
- PHOTO as a held camera
- Size Magic through world_scale
- 3D danger arrows and sound captions
- Knock-out dim and sleep fade

_Acceptance:_ A Moon flight from LIFT-OFF to landing, in VR on the Quest: no camera move the cockpit does not share, no shake (a FlightShots VR test: pose shake 0, no blend steps), 72 FPS in the capsule. TeleportRules tests: no wall climbing, no gaps over 6 m, no hiding-spot targets. The crew flight net test still passes on the desktop. The owner rides a flying buddy and flies to the Moon with no discomfort reported.

**P4: Hands and multiplayer bodies.**

- Blocky and realistic hand models in the avatar's colours, with grip and point poses from the trigger and grip
- The held item on the hand
- Opt-in swing attacks through WeaponRules' cone from the hand; the bow drawn with two hands
- vr_pose (head plus two hands, quantized, 20 Hz) replicated, shipped first in a phone and web release
- Remote VR avatars turn their head and float their hands; a VR mark on the name tag
- An optional mirror to see one's own avatar

_Acceptance:_ tools/net_test.sh with a Quest host and a desktop guest (and the reverse): the desktop sees the VR child nod, look round and wave. Older builds' behaviour is documented, with no crash. Bandwidth is at most +1 KB/s per VR player. Swing attacks pass the WeaponRules reach and cooldown tests from a hand ray.

**P5: Performance to 72 Hz everywhere, then what Quest 3 adds.**

- tools/vr_bench.gd and VR_BENCH lines per world (draws, primitives, GPU and CPU ms)
- A VR budget table for every universe, the cosmos worlds and world 41
- Draw-call cuts: mesh blocks 32, far props and labels hidden, MultiMesh for repeated props, fewer surfaces per chunk
- CPU caps for VR crowds
- Every long frame over 28 ms removed or moved behind a fade
- ASW evaluated as a fallback
- 'vr_plus' for Quest 3: 90 Hz, view 96, near shadows, MSAA 4x, realistic style
- For the web path: a WebXR census of multiview shader variants

_Acceptance:_ Quest 2, for every world's autopilot play phase plus a 2 km FLY cruise:
- at least 72 FPS average, 1% dropped frames or fewer
- 100 draws or fewer (150 or fewer at the heaviest landings, logged as exceptions)
- 750K triangles or fewer
- GPU 11 ms or less, main thread 9 ms or less
- no frame over 28 ms after the spawn fade
Quest 3 at 90 Hz with vr_plus meets the same rules. The numbers are recorded in DEVELOPMENT.md section 7 with the headset model and its refresh rate.

### Two agents in parallel

Two VR agents, after the lead's P0 contract commit. The third slot stays on #98, the owner's limit of 3 agents.

THE CONTRACT (by the lead)
- The autoloads/vr.gd stub with a frozen API: active(), camera, hand_ray(side), anchor(node, kind), fade_out(t)/fade_in(t), ui_viewport(), ui_wants_pointer(), plus the signals recentered and focus_changed.
- core/vr/vr_rules.gd with the settings keys and their defaults.
- The seam lines in scenes/sandbox.gd:38/:103 (UiLayers.route), :679 ('or Vr.active()') and scenes/main.gd:18 (PadFocus parent).

The lead keeps: scenes/sandbox.gd, scenes/main.gd, project.godot, export_presets.cfg, docs/ (spec, plan, DEVELOPMENT.md), and the merges.

AGENT VR-RIG (world side)
Owns:
- the body of autoloads/vr.gd
- new entities/vr/vr_rig.gd, vr_hand.gd, vr_comfort.gd, vr_input.gd, vr_teleport.gd, vr_photo_camera.gd
- openxr_action_map.tres
- core/vr/vr_rules.gd (locomotion, turn, vignette, eye height) and core/vr/teleport_rules.gd
- core/platform/gamepad_rules.gd (the QUEST family only) and core/platform/platform_rules.gd
- entities/player/camera_rig.gd, player.gd, player.tscn, block_interactor.gd, weapon_user.gd, gadget_user.gd, blaster_user.gd, held_item.gd
- entities/interactables/secret_taps.gd; world/trade_director.gd:383 and world/portal_director.gd:232 (one line each)
- autoloads/feel.gd, core/rules/feel_rules.gd
- core/rules/graphics_preset.gd, autoloads/game.gd, world/world_service.gd, world/sky_cycle.gd
- entities/flight/* (P3) and ui/photo/photo_mode.gd (P3)
- tests named test_vr_rig_*.gd; notes in docs/devlog/parts/vr-rig.md

AGENT VR-UI (panel side)
Owns:
- new entities/vr/vr_panel.gd and vr_pointer.gd
- new core/vr/ui_layers.gd
- new ui/vr/ (the keyboard, the VR COMFORT page, the Quest CONTROLLER card page, the TV sign, the break card)
- ui/menus/menu.gd, settings_panel.gd, pause_menu.gd, coin_shower.gd
- core/save/profile_data.gd (the vr_* keys only)
- ui/loading/loading_card.gd, ui/help/pad_focus.gd
- autoloads/music.gd:51 and autoloads/session.gd:2047-2058 (the toast layers only)
- ui/online/dm_panel.gd, world/ambience.gd:30, world/visit/visit_world.gd:30
- ui/hud/* (hud.gd, hud_layout.gd reads, danger_arrows.gd, sound_captions.gd)
- ui/flight/flight_cockpit.gd (dashboard mode, P3) and ui/theater/*
- the readability pass across ui/school, ui/missions, ui/shop, ui/books
- tests named test_vr_ui_*.gd; notes in docs/devlog/parts/vr-ui.md

HOW THEY TOUCH
- VR-UI consumes Vr.hand_ray/camera and the trigger state from VR-RIG through the contract only.
- VR-RIG asks Vr.ui_wants_pointer() before a world action.
- In P3 the rocket is split: VR-RIG does rocket_flight.gd and the 3D capsule; VR-UI does the cockpit's dashboard mode. They agree on one node path (the dashboard quad's anchor), written in both notes.
- Neither agent edits the other's files or the lead's files. Seam changes go to the lead as a line list in the notes.
- Both use 'Vr.simulate' (a fake head and hands) for GUT tests, so neither needs the headset to test.
- No block ids, atlas tiles or HUD spots are needed; if one becomes necessary, the lead allocates it.

### Open questions, each with its default

- Which Quest does the owner have (2, 3, 3S or Pro)? Default: plan and measure for Quest 2 as the floor (XR2 Gen 1, 72 Hz, <100 draws); add 'vr_plus' for Quest 3 (about 2.5x GPU, 90 Hz) once its numbers are in. The 3S/Pro specifics were not on Meta's comparison page: UNCONFIRMED.
- Native APK or WebXR in the Quest Browser first? Default: a native OpenXR APK sideloaded on the owner's Quest (Mobile renderer, Vulkan, foveation, ASW available). WebXR from the existing web build comes later on the same code, with the Compatibility renderer and the shader census redone for multiview.
- Store or sideload? Default: sideload for the owner now. A Meta Horizon Store listing (privacy, age and comfort ratings) waits for the owner's word and his lawyer, like the Play drafts in docs/store/.
- Default locomotion for children? Default: smooth stick walking with the vignette on (light), snap turn 45 degrees, and teleport always available on right stick up. Smooth turn is opt-in. Meta's guidance for new users is teleport plus snap (https://developers.meta.com/horizon/documentation/web/iwsdk-concept-locomotion-slide/); we keep walking because the game is built around it. Ruling cost if wrong: a sick child; switch the default to teleport-first.
- Eye height: game or real? Default: 'game height' (the eye always at the avatar's 1.55 m x size, recalibrated on recenter), so seated and short children see the same world as on the phone; 'real height' as an option.
- Third person in VR? Default: no. First person only; the CAM button is hidden in VR (a trailing third-person camera is a strong sickness trigger).
- Realistic style on Quest 2? Default: blocky only on Quest 2 (realistic costs +30-60% GPU in today's Vulkan bench and turns glow on); realistic allowed in vr_plus on Quest 3 after measuring.
- Which hand points? Default: the right hand points and acts, the left moves; the existing left_handed setting swaps them.
- Hand tracking (no controllers)? Default: controllers only until P4; pinch-as-trigger is a later idea.
- Physical sword swings? Default: off (the button attacks), opt-in in P4 because of real-world safety with excited children.
- The TV (YouTube in an Android WebView) in VR? Default: a sign 'TV plays on the phone or tablet'. EasyCraft Shorts (our own reels) play in VR.
- Mixed reality passthrough on Quest 3 (build on your table)? Default: not now; noted for the forever roadmap as a signature idea.
- Cross-play between VR and phones online? Default: yes, same server and worlds. The vr_pose field ships to phones and web in a release before any VR build joins them, since there is no protocol version gate.
- Physics rate in VR? Default: keep 60 Hz and interpolate the XR origin between ticks. Raise physics_ticks_per_second to 72 only if the P0 spike shows judder (costs about 20% more physics CPU).
- Size Magic in VR? Default: yes, through XROrigin3D.world_scale with a fade (a giant child truly feels giant).
- Rocket flight views in VR? Default: INSIDE only, with the 3D capsule interior and no CHASE view; the outside shows through the window. If the capsule art costs too much in P3, a fallback is a dark capsule with the 2D cockpit on the dashboard panel.
- The owner's rule 5 (test on the emulator) for VR? Default: a ruling written in the ledger and devlog. The emulator for non-VR regressions, the owner's Quest (adb on port 5038 with the Quest's own serial) for VR acceptance, GUT with Vr.simulate for everything in between.
- Age: Meta Quest accounts are for 10+ (parent-managed for 10-12; 2023 news, current Meta page UNCONFIRMED). Default: the game does not gate by age (owner #69 switched gates off); add the 30-minute break card and say this to the owner once in the VR plan.
