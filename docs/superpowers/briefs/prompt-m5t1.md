# M5 Task 1 — the accessibility pass (spec §15.1)
(House rules: `docs/superpowers/briefs/owner-common.md`. Start from main after the night's merges.)
Read spec §15.1 and §5.15, `ui/hud/hud_layout.gd` (every HUD spot in one table), the settings panel (now full:
its toggles row fits 1280 px exactly; add a page or a second row that still fits 1280×720), the MORE panel,
UiKit, and the audio pass's sounds.
Build, test-first:
1. **Button size** setting (Normal / Big / Bigger) scaling every HUD button from the layout table, re-checked by
   `test_every_button_is_big_with_a_picture_and_nothing_overlaps` at every size and screen.
2. **Movable controls:** an edit mode (grown-up or child) to drag JUMP/ATTACK/CROUCH/joystick within safe areas,
   saved in the profile, with RESET; **left-handed** layout (mirror the thumb clusters).
3. **Text size** (Normal / Big) for labels, toasts, chat and dialogs.
4. **Never colour alone:** every colour-coded thing (rarity rims, hearts, team, danger arrow) also has a shape or
   an icon; a test scans the rarity and status widgets.
5. **Captions** for important sounds (a monster nearby, a wave horn, a boss, a friend's call): small icon captions
   near the edge in the direction of the sound; a setting.
6. Reduce motion already exists: make sure new effects (gadgets, rides, blasters, piñatas) respect it.
Tests for each, both graphics styles, 1280×720 and 2400×1080. Notes: `docs/devlog/parts/m5-task-1.md`, with the
emulator checklist. Suites through the slot gate: `tests/suite_slots.sh tests/run_tests.sh`.
