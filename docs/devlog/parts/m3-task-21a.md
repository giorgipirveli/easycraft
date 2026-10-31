# M3 Task 21a: the wonder pack, words and voices (notes)

Brief `docs/superpowers/briefs/prompt-m3t21a.md`; spec **§14.20** (new); plan M3 Task 21 (21a). Research
`docs/design/engagement-and-child-psychology.md` O6 (read-aloud), O7 (languages), O8 and A6 (simple controls),
F7 (babble voices). Built by a background agent in its own worktree after `git merge lead-merge` (`3e4519b`),
without the editor or the emulator. It builds on owner #45a's `ReadAloud` (the quest card's speaker), owner #49's
Georgian font fallback, owner #38's bilingual bot answers, the audio pass and owner #50's chorus.

## What was built

| Piece | Where | What it does |
|---|---|---|
| Languages | `core/words/lang.gd` (`Lang`), `i18n/ka.po`, `project.godot` `[internationalization]`, `autoloads/game.gd` (one line), `core/save/profile_data.gd` (`language`) | English and Georgian. English is the key: every Control translates its own text; `Lang.t` / `tr()` for lines filled in with `%`; `Lang.plural_s`, `Lang.article` (nothing in Georgian). Until the child chooses, the device's language decides. Headless runs (tests, smoke runs) speak English. |
| The Georgian | `i18n/ka.po` (2,046 lines) | Every player-facing word of the game. **Native check needed** (below). |
| The word scanner and its test | `tools/i18n/word_scanner.gd`, `tools/i18n/words.gd`, `i18n/not_words.txt`, `tests/unit/test_georgian_words.gd` | Like the no-guilt test, it reads every string literal of `autoloads/ core/ data/ entities/ net/ scenes/ ui/ world/` and keeps the ones that read like words (not StringNames, paths, keys, node names, log calls, regexes, pixel maps, names passed to find_child/get_meta/…). Every one needs a Georgian line with the same format codes in the same order; every formatted one must be translated before it is filled in. `not_words.txt` lists the rest (names, node names, the chat filter's lists, the developer menu). `--missing` prints what to translate. |
| `tr()` at the sources | 249 one-line changes in ~85 files | `"…" % x` → `tr("…") % x` (instance code) or `Lang.t("…") % x` (static code), done by a script from the scanner's list; names filled into them through `Lang.t(X.display_name(…))` (18); constants used as formats (`EARNED_MESSAGE`, `CRYSTAL_WORDS`, `HATCHED`, `CLEARED_WORDS`, `RATE_TEXT`, `CAP_TEXT`, `SQUAWK`, `BOT_TALK_FROM`); ternaries (`(tr("A") if c else tr("B")) % x`). |
| Drawn words | `TouchButton`, `QuickChatWheel`, `EmoteWheel`, `AvatarTile`, `PhotoChip`, `FindArrow` | `draw_string(atr(text))`: the HUD's words under the pictures, the wheels' phrases. |
| The chat | `ui/hud/chat_panel.gd` (section "M3 Task 21a") | Its lines never translate by themselves (a player's words stay exactly as typed); game lines, bot lines and quick-chat phrases are translated as they go in. Name labels (the HUD's and the menu's username, `NameTag`) never translate. |
| Read-aloud | `ui/progress/read_aloud.gd` (`ReadAloud`, extended), `core/words/speech_queue.gd` (`SpeechQueue`) | A speaker beside a panel's title reads it at once (`with_speaker`, `words_of`: the visible words in the game's language, never labels that don't translate). "Read to me" (off by default) reads toasts (`Hud.toast`), banners, first-time tips, riddles and notes, the stay-safe card and each menu screen's title, one at a time; never twice in a row, never late (8 s), at most 3 waiting. The voice is the game's language's (`tts_get_voices_for_language`); none: nothing is read and the speakers hide. Another player's name is read as "a friend". The chat is never read. |
| Speakers | the main menu's screens (`_vbox`), the pause menu, SETTINGS, the Secret Book, riddle notes, the stay-safe card; the quest card and book had theirs (#45a) | |
| Babble voices | `core/rules/babble_rules.gd` (`BabbleRules`), `world/babble_voices.gd` (`BabbleVoices`, node `Babble` in the sandbox), `tools/make_babble_sfx.py`, 12 takes `assets/audio/sfx/babble_*.wav`, Audio's `&"babble"` | Nonsense syllables (a gliding voice through two vowel formants after a soft consonant; never real words), as many as the line is long (2–7), at the speaker's pitch: its kind (pets high, Tilly bright), its size (1/√(size/3)) and a personality from its name (±12 %). Bot friends' chat lines (heard from `Session.chat_received`), a buddy's cheer and wake-up, Tilly's hello at her shop, a story friend's hello on its card, the parrot's echo. |
| Simple controls | `core/rules/simple_controls.gd` (`SimpleControls`); sections in `entities/player/player.gd`, `camera_rig.gd`, `ui/hud/hud.gd` | Auto-jump over a 1-block gap (2+ deep, ground at the same level beyond, room to hop) as well as up a step; the camera follows (turns 1.8 rad/s with the stick fully sideways, never 1.5 s after the child turned it, never walking back); ATTACK only with a weapon or blaster in the hand or a monster within 16 blocks, CROUCH only with a monster near or while crouching. |
| SETTINGS | `ui/menus/settings_panel.gd` | Two pages chosen beside the title: GAME (as before, minus Reduce motion) and LANGUAGE & HELP (LANGUAGE: English / ქართული, Read to me with a test speaker, Controls: SIMPLE / CLASSIC, Comfort: Reduce motion). BACK and GROWN-UPS on both; coming back from GROWN-UPS keeps the page. `saver` lets tests change settings without writing the shared profile file. |
| First launch | `ui/menus/welcome_cards.gd` (`WelcomeCards`), `ui/menus/menu.gd` (`_welcome`) | After the age screen: "Pick your language" (the device's language lit). After the look: "How do you like to play?" with SIMPLE and CLASSIC as equal picture cards (drawn in code) and a line under each. A child who played before sees both once at the next start. |
| The bow emote | `core/avatar/avatar_catalog.gd` | "Bow" (the emote) is "Take a Bow": the weapon "Bow" is another word in Georgian. |

## Skills and patterns (godot-prompter)

- **localization:** kept Godot's own path (a `.po` registered in the project, `TranslationServer.set_locale`,
  Controls' auto-translation, `tr()` before `%`). **Rejected** the skill's semantic keys (`MENU_START`): the game's
  2,000 English literals are already the Controls' texts, and changing every one would touch every file other
  agents edit; English-as-key costs only that an English change orphans its Georgian line, which the test catches.
  PO over CSV: plain text, comments, and the tool writes it. Rejected Godot's editor POT generation (it needs the
  editor and misses constants' tables): our own scanner is the test.
- **audio-system:** the babble plays through Audio's fixed pools (no new players), one short WAV per syllable
  (no decoding latency), pitch on the player. Rejected a pooled `AudioStreamPlayer3D` per speaker and
  `AudioStreamPlaylist`/`Interactive` (a line is 2–7 takes with a small random gap: a step list is simpler).
- **godot-ui:** SETTINGS' pages are two toggle buttons showing and hiding rows. Rejected `TabContainer` (its
  internal nodes break the tests that count rows, §8) and a `ScrollContainer` (a child doesn't know there is more).
  Cards are containers in the menu's `PanelContainer`; every page is measured against 1280 × 720 in both languages.

## Tests (RED → GREEN)

| File | Tests | RED |
|---|---|---|
| `tests/unit/test_lang.gd` | 10 | `Lang` not declared; then the setting round trip and the project's translation list |
| `tests/unit/test_georgian_words.gd` | 4 | 2,031 words without Georgian and 223 formatted literals not translated first (the real RED) |
| `tests/unit/test_speech_queue.gd` | 8 | `SpeechQueue` not declared |
| `tests/integration/test_read_aloud.gd` | 12 | `ReadAloud.Voice` / `auto` / `words_of` missing. **Mutation check:** reading every chat line (`ReadAloud.auto` in `ChatPanel.add_line`) failed `test_the_chat_is_never_read` ("my phone is 555", "That isn't a command…"); restored |
| `tests/unit/test_babble_rules.gd` | 9 | `BabbleRules` not declared |
| `tests/integration/test_babble_voices.gd` | 8 | written after `BabbleVoices` (engine glue); checks bot lines at the bot in its voice, players never, one line at a time, far never, pools never grow, the chorus rests, the parrot |
| `tests/unit/test_simple_controls.gd` | 12 | `SimpleControls` not declared |
| `tests/integration/test_simple_controls_hud.gd` | 3 | written after the glue (real Player and HUD) |
| `tests/integration/test_settings_words_page.gd` | 5 | `SettingsPanel.WORDS` missing; then **the Georgian game page was 1482 px wide** (Reduce motion moved) |
| `tests/integration/test_welcome_cards.gd` | 6 | `WelcomeCards` not declared |

Suite counts and commits: at the end of this file.

## Rulings (decisions on the owner's behalf; cost if wrong)

1. **"Read to me" is off by default for everyone.** The age screen keeps only under 13 / 13 and older, so it can't
   tell a 6-year-old from a 12-year-old (research §1.12); the brief's "on for the youngest band" has no such band.
   The speaker buttons are always there (where the phone has a voice), so a child who can't read taps the speaker;
   "Read to me" is one switch in SETTINGS → LANGUAGE & HELP. *Cost if wrong:* a non-reader who wants everything read
   needs a grown-up to switch it on once.
2. **The chat is never read aloud, bot friends' lines included** (they babble instead), and another player's name
   in a toast is read as "a friend" (safety: players' words and chosen names are never spoken). *Cost if wrong:* a
   bot's answer is not spoken to a non-reader (its babble and the picture replies remain).
3. **No voice for the game's language: nothing is read and the speakers hide** (Georgian is never read by an English
   voice). *Cost if wrong:* on a phone without a Georgian text-to-speech voice (Google's engine has none that we
   know of), a Georgian child gets no read-aloud in Georgian; English still reads.
4. **English is the key** (the code's English literals are the msgids). *Cost if wrong:* an English change orphans its
   Georgian line (the test fails until it is translated again).
5. **Names stay as they are:** bot friends, pets, villagers, places ("Maple Mill"), ships, composers and Tilly, Zara,
   Bram, Mimi, Pip as single words (inside Georgian sentences they are written in Georgian with case endings).
   *Cost if wrong:* a child who reads only Georgian letters can't read the names.
6. **The LANGUAGE card comes right after the age screen** (the brief), and until a choice the device's language
   decides, so a Georgian phone shows the age question in Georgian already. A child who played before sees the
   language card and the controls card once at the next start. *Cost if wrong:* one or two extra taps once.
7. **Headless runs speak English** (tests, smoke runs): they read the shared profile and this PC's language
   (Georgian). A windowed desktop run follows the setting. *Cost if wrong:* none known.
8. **Fonts:** the game's font is the engine's built-in one (Open Sans), which has no Georgian letters; owner #49's
   `UiKit.add_script_fallbacks` adds the device's own Georgian font (Android: Noto Sans Georgian) to every text,
   HUD words and 3D labels included. No font is bundled: the CC0-only rule forbids Noto (OFL) and no CC0 Georgian
   font is known. *Cost if wrong:* a device without a Georgian system font shows boxes (every Android since 5 has one).
9. **A formatted line is translated on the device that builds it:** a host's replies and bot lines reach a LAN guest
   in the host's language (plain ones are translated again on arrival). *Cost if wrong:* a guest who plays in the
   other language sees some lines in the host's.
10. **Simple controls keep M1b's auto-step for everyone** (Classic too: the owner's children play with it) and add
    the gap hop, the following camera and context-only ATTACK and CROUCH. WALK/FLY, JUMP, MORE, BOOK and CHAT stay.
    *Cost if wrong:* a Simple child walking into a 1-block hole on purpose hops over it (stop and step in slowly).
11. **Babble budget** (like the chorus): one line at a time per device with 1 s after it, a speaker rests 4 s, 20
    blocks at most, quieter far; an answer to the child's own tap (a buddy's cheer, Tilly's shop, a giver's card, the
    parrot) or a bot's line within 4 s of the child speaking is never held back. The chorus rests 3 s after babble.
    **Animals keep their real voices** (owner #27); only the parrot babbles (it echoes the child's words). *Cost if
    wrong:* tuning numbers in `BabbleRules`.
12. **SETTINGS has two pages; Reduce motion moved to LANGUAGE & HELP → Comfort** (the game page's toggle row was
    1426 px wide in Georgian). *Cost if wrong:* a parent looks for Reduce motion on the first page.
13. **The emote "Bow" is "Take a Bow"** (Georgian needs different words for the weapon and the bow of the head).
14. **Merges:** every branch that adds on-screen English will fail `test_georgian_words` until its words are
    translated (`tools/i18n/words.gd -- --missing`). That is the point of the test, and the lead's cost per merge.

## Georgian: native check needed

All 2,046 lines of `i18n/ka.po` were translated by the build agents (seven batches with one glossary), not by a
Georgian speaker. Choices to check first: Sandbox = სენდბოქსი, Survivor = სერვაივერი (as owner #38's bot answers
say), universe and world = სამყარო (as owner #40's `/universe`), buddy = მეგობრუკა, pet = შინაური ცხოველი, chest =
სკივრი, grown-up = უფროსი (polite თქვენ only in grown-ups' and store texts), UNDO = გაუქმება, Hide & Seek =
დამალობანა. Riddles whose English pun doesn't work were adapted ("I have hands, but I can't clap" → clock hands
are ისრები, arrows). Lines with a name in them are written so the name needs no case ending ("%s: …", "გამოფენა:
%s"). Known leftovers (English inside Georgian, for M5): place names, the parent gate's number words ("twenty-three"),
`/time` choices (day, night), `/style` choices, the Theater's ON/OFF inside a sentence, `PlayTime` words.

## What the lead should check on the emulator

1. **First launch** (clear the app's data): PLAY → the age question → "Pick your language" (English / ქართული, the
   phone's language lit) → ქართული: the name step and everything after it in Georgian letters (no boxes) → the look →
   "How do you like to play?" (two equal cards) → the main menu. On the owner's current profile: the two cards once.
2. **SETTINGS → LANGUAGE & HELP:** English / ქართული switch the menu at once; the page and GAME fit 2400 × 1080 in
   both languages; Reduce motion is under Comfort; coming back from GROWN-UPS keeps the page.
3. **Read-aloud:** does the emulator have a Georgian voice? (Settings → System → Languages → Text-to-speech.) In
   English: the speaker beside "Choose your game", the pause menu's title, SETTINGS, the Secret Book, a riddle note and
   the stay-safe card read aloud; "Read to me" on: toasts and banners are read one after another, never the chat.
4. **Babble:** add a bot friend and say "hi" in the chat: it answers in babble at its place (not every chat line of
   yours); tap a buddy (it cheers and babbles; a tiny one squeaks, a giant rumbles); Tilly's shop and a story friend's
   card say hello; a parrot pet echoes in babble. The chickens and the babble don't talk over each other.
5. **Simple controls on:** walk into a 1-block ditch (2 deep): the child hops over it; walk sideways: the camera turns
   to follow; with empty hands and no monster ATTACK and CROUCH are gone, and come back at night when a monster is near.
6. **Georgian HUD:** the words under the HUD buttons, the hotbar tooltips, toasts and the chat's game lines in
   Georgian; players' chat lines exactly as typed; names unchanged.
7. **Performance:** nothing new runs per frame except the HUD's quarter-second monster look (Simple) and the babble
   steps while a line plays.

## Suite counts and commits

- Before (lead-merge `3e4519b`, as the lead last ran it): 4605+ tests (the #45a and M3 Task 8 merges); this branch's
  own new tests: 77 in 10 files, and 1 in `test_welcome_cards.gd` after the merge.
- **Full suite after `git merge lead-merge` (`fcf1b46`: #41's animals, Nell):** 536 scripts, **5,169 tests, 5,166
  passing**, 2 risky/pending (existing "did not assert"), **1 failing**: `test_avatar_start_choice`'s "then the main
  screen" (after the look the menu now shows the Simple controls card once). Fixed in the test (the cards marked seen
  for that test) and covered by the new `test_the_menu_asks_after_the_look_step`; both files 16/16 again.
- Commits: `a7c9834` feat (the whole pack), `b8b1ddd` docs, `15c3fca` merge of lead-merge (the spec's §14.19 went to
  #41's animals: this is §14.20; `pet_director.gd`'s treat line kept #41's "arctic fox" and translates it), then the
  merge fix (#41's and Nell's words in Georgian, three lines translated before filling in) and the test fix.
- **After a merge**, run `godot --headless --path . --script res://tools/i18n/words.gd -- --missing`: #41 and Nell
  brought 32 new words; every later branch will bring its own.
