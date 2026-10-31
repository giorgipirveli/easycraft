# Owner feedback #38: bot friends understand what the child says and asks

The owner, 2026-09-24: "also make sure when chatting with bot friends they understand what you say and what
you ask". Brief: `docs/superpowers/briefs/prompt-own38.md`. Spec §12.14a (added first), plan line in the M3
plan ("Owner 38"). Built in an isolated worktree on a branch cut from `m2-survive-the-night` at `5a9771a`;
no editor or emulator (house rule). Engine glue was checked with a new headless smoke run on real terrain.
Commits: `e2ed8f2` (spec and plan), `684346a` (the feature and its tests), and this notes commit.

Before this task bot friends spoke fixed lines but never listened (Task 15's ruling 15: "bots never read the
chat"). Now the child's own words reach the child's own friends, on the device: no internet, no big model.

## What was built

| File | What |
|---|---|
| `core/bots/bot_intents.gd` (`BotIntents`, new) | The understanding: cleans the words (lower case, accents, apostrophes, stretched letters "folllow", chat words "u / plz / thx / wyd", fillers), finds each word in the word list exactly, by its ending ("following", "განძის"), as an English -ing word ("dancing") or as a small typo (1 letter for 4-6 letters, 2 for 7+; a swap like "wiat" beats a change like "what"; a request word beats a plain one: "halp" = help, not halt), takes a bot's name off the start or the end, scores 25 intents from keywords and phrases (English and Georgian) with a question cue, turns "don't / stop" requests around, and gives the details of a build ("a tower", "with my blocks", "next to me") and of a dance (a trick). Georgian letters and Latin-letter Georgian ("gamomyevi", "modi aq", "wavidet") meet through one sound key |
| `core/bots/bot_answers.gd` (`BotAnswers`, new) | Every word a bot answers with, English and Georgian: plain lines, "we" lines for several friends, and answers filled in from the game: directions from where the child looks ("40 blocks to your left, up high"), Tilly's stall, the nearest secret ("I know! There's a hidden room 60 blocks straight ahead. Follow me!"), hearts (halves, "Let's be careful!" when low), the day clock, what the bot is doing, its name (always "…your builder bot!"), where it is |
| `core/bots/bot_talk.gd` (`BotTalk`, new) | Who hears (only the child's own friends: near the child, or named, or a call), who answers (the friend the request is about, else the nearest), who acts (everyone, or one friend for a build, treasure, a race, Tilly), when words not understood get a hint |
| `core/bots/bot_asks.gd` (`BotAsks`, new) | What a friend remembers of its child's requests (fading, half-life 10 min of play): follow asks bring it up to 3 blocks closer ("give me space" undoes most of it), build asks make its own builds up to 40 % sooner; saved with its mind |
| `core/rules/bot_rules.gd` | Section "Owner 38": the talk behaviours `STAY`, `GUIDE`, `HIDE`, `DANCE` (in `choose_behaviour`: after a monster, before everything else; a friend running away never fights), `choose_target`'s guard radius, `request_design` (a 3 × 3 hut of 23 blocks with a doorway and a roof, a 6-high tower with a lamp, a 5 × 2 wall; one block for all when the child's blocks or leaves), the times and distances |
| `entities/bots/bot_friend.gd` | Section "Owner 38": the orders (`talk_follow`, `talk_stay`, `talk_space`, `talk_guard`, `talk_hide`, `talk_dance`, `talk_guide`, `talk_build`, `talk_kind`, `talk_wave`), answers (`talk_reply` never waits for the 20 s gap; `talk_line` takes turns through a key's lines), the steps of each talk behaviour, a requested build placed 5 blocks every 0.35 s from a spot beside it, dances through the avatar's emotes (`_rpc_emote`), `facing_of(player)`. Hooks, one line each: `_talk_tick()` in `_decide`, catch-up held while waiting, `_talk_far` (closer following), facts `order` / `asked_build`, no wandering while following close, the talk step in the behaviour chain, `_talk_enter`, the stuck guide, the guard radius, the build step, `asks` in the build pace and the mind save |
| `world/bot_director.gd` | Section "Owner 38": `hear(peer_id, text)` (parse → who hears / answers / acts → do and say), the nearest secret nobody found from the sandbox's `SecretDirector` (its rules and state; not the golden animals, the Wanderer or stars), Tilly from group `traders`, the day clock from `Animal.time_source`, "others present" from group `players` |
| `autoloads/session.gd` | Section "Owner 38: bot chat": `request_bot_talk(text)` → the host's `_host_bot_talk(peer_id, text)` (the chat's rate limit, 5 per 10 s; cleaned; the chat filter: personal information and bad words never reach a bot) → the director in group `bot_director`; `has_own_bots()`; `bot_talk_reset()`. One comment in Task 15's section updated |
| `ui/hud/chat_panel.gd` | What the child types and taps also reaches their own friends, after the child's own line is sent (so the chat shows the child's words first, then the answer); an under-13 player's typed words and the wheel's BOTS page go to their friends only, never to other people (a local line "Name (to your bots): …"); section at the end |
| `ui/online/quick_chat_wheel.gd` | A BOTS pill when the child has friends of their own; the BOTS page (its phrases and pictures); CHAT goes back |
| `ui/online/bot_talk_wheel.gd` (`BotTalkWheel`, new) | The BOTS page's eight picture phrases: Follow me!, Wait here!, Build a house!, Find treasure!, Guard me!, Let's dance!, Where is Tilly?, Race me! (pictures drawn in code: arrow, hand, blocks, chest, a shield with a star, a note, a coin with "?", a race flag; looked at in a windowed test picture, not committed) |
| `tools/bot_talk_smoke.gd`, `tools/bot_talk_smoke_steps.gd` (new) | Headless smoke run on real terrain (below) |

### What the friends do and answer

| The child says (e.g.) | Who | What happens | Answer (EN; Georgian too) |
|---|---|---|---|
| follow me, come here, let's go, გამომყევი, modi aq | all the child's friends (a call) | follow within 3 blocks for 60 s, no wandering; a far one pops up next to the child | "OK! I'm right behind you!" / "OK! We're right behind you!" |
| wait, stay, stop, stand still, მოიცადე | those near | STAY where they are (3 min; no catch-up unless the child goes 96+ blocks away); a monster at them is still fought | "OK, I'll wait right here!" |
| go home, go to bed, წადი სახლში | those near | STAY at the child's bed (a poof there when 16+ blocks away), until called | "OK! I'll wait for you at home!" / no bed: "You don't have a home yet. Sleep in a bed to make one!" |
| go away, give me space, don't follow me | those near | +2 blocks of space for good, step back for 20 s | "OK! I'll give you some space." |
| build a house / a tower / a wall / something, with my blocks, ააშენე სახლი | one: a builder, else the nearest | plans it 2-4 blocks from the child (never in anyone, only in air, on natural ground), walks beside it, places 5 blocks every 0.35 s | "A house? Coming right up!" … "Ta-da! A little house for you!"; Survivor + my blocks: "In Survivor I build with leaves, so your blocks stay yours!"; no room: "I can't find a flat spot here. Let's try somewhere else!" |
| find treasure, explore, where is the treasure?, იპოვე განძი | one: an explorer, else the nearest | GUIDE to the nearest secret nobody found (≤ 250 blocks), waiting when the child is 9+ blocks behind ("This way!"), then points and sparkles it | "I know! There's buried treasure 29 blocks to your right. Follow me!" … "Here it is!" |
| fight, guard me, protect me, დამიცავი | those near | guard 16 blocks around the child for 2 min, staying close | "I see it! Stay behind me!" / "I'll keep you safe!" |
| help!, help me, save me, მიშველე | all (a call) | close and guarding for 30 s | "I'm coming! Stay close!" |
| run away, hide, დაიმალე | those near | monsters within 16 blocks: run 8 blocks away from them for 10 s, no fighting; else hide quietly behind the child for 20 s | "Run! This way!" / "OK, I'm hiding! Shh!" |
| dance, do a trick, იცეკვე | those near | a dance emote (hop, robot, star spin) for 6 s, a trick (victory) for 3 s | "Watch my moves!" / "Watch this trick!" / "Dance party!" |
| race me, შემეჯიბრე | one | M3 Task 7's race (`BotDirector.race`) | "Ready! Step on START and let's race!" / "Let's race! Finish a course first, …" |
| look!, check this out | those near | come close for 15 s | "Ooh! What is it?" |
| hi, thanks, good job, i love you, bye | the nearest answers | +0.1 liking and a heart; a bye never sends a friend away | "Hello, friend!", "You're welcome!", "Thanks! You're great too!", "Bye! See you soon!" |
| where is Tilly?, სად არის ტილი? | one (explorer first) | leads the way to her stall | "Tilly's shop is 14 blocks to your left! Follow me!" / Sandbox: "There's no shop in this world. Tilly's stall is in Survivor worlds!" |
| what are you doing? | the nearest | — | from its behaviour or order: "I'm waiting here, like you asked!", "I'm showing you the way! Follow me!" … |
| how many hearts do I have? | the nearest | — | "You have 7 and a half hearts out of 10!" |
| is it night soon? | the nearest | — | "It's day. Night comes in about 7 minutes." |
| what's your name?, who are you? | the nearest | — | "I'm Mossy, your builder bot!" |
| can you help me?, what can you do? | the nearest | — | "You can say: follow me, wait, build a house, find treasure, guard me, dance!" |
| where are you? | each of the child's friends | a sparkle over its head | "Over here! I'm 12 blocks behind you." / "I'm at your home! Say come here and I'll come." |
| how are you? | the nearest | — | "I'm great! Playing with you is the best!" |
| ok, yes, lol | — | nothing | — |
| anything else | the nearest | — | "Hmm? You can say: follow me, build a house, find treasure..." (alone in the world, or a friend named) |

A bot's name at the start (after a greeting: "hey Pip, …") or at the end talks to that friend only, wherever it is.

## Patterns chosen and rejected (skills `dialogue-system`, `localization`, `state-machine`)

- **Chosen: one scored intent matcher + a table of fixed answers.** Rejected: dialogue trees / Resources
  (`DialogueLine`, Dialogic, Dialogue Manager): a bot answers one line per request and never branches; a
  table is easier to check (the guard tests read every line).
- **Chosen: the answer language follows the child's message** (Georgian letters, or Latin-letter Georgian
  scoring more). Rejected: `tr()` / `TranslationServer` for bot lines: the game has no translation files yet
  (M3 Task 21a) and the language must follow what the child wrote, not the device locale.
- **Chosen: extend Task 15's StringName state machine** with four talk behaviours chosen in
  `BotRules.choose_behaviour` from an `order` fact (a parallel "what the child asked" layer that biases the
  one place transitions are decided). Rejected: node-based states per bot, and a second state machine that
  would fight the first over `_goal`.

## Tests (RED → GREEN)

| Test file | Tests | RED first |
|---|---|---|
| `tests/unit/test_bot_intents.gd` | 16 | "Identifier BotIntents not declared" (then a `const I := BotIntents` alias is "not a constant expression": `preload` like the other tests); first real run 329/333 — misses "wiat" (a tie with "what"), "go hom" (3 letters), "halp" (a tie with "halt"), "i like pizza" ("like" fixed into "life") → the typo rank (swaps first, request words over plain ones), common words in the word list, two chat words |
| `tests/unit/test_bot_answers.gd` | 13 | written before `BotAnswers`; one expectation fixed (a time that is "less than a minute", not "1 minute") |
| `tests/unit/test_bot_talk_rules.gd` | 15 | written before `BotTalk` / `BotAsks`; "asked for space: a little less" failed (a capped follow count outweighed two space asks) → a space ask keeps a quarter of the follow asks |
| `tests/integration/test_bot_talk.gd` | 34 | written before the bot, director, Session and chat code but first run after it (34/34 after two test fixes: the chat's rate limit between a test's many sentences, a username for "likes its child"). **Mutation checks:** without the waiting hold 3 of the 4 waiting tests fail; without the "own friends only" filter (BotTalk and the director) the guest test fails both ways; without the chat filter on the host the filter test fails |

The phrase table (`TABLE`, 333 child-like sentences: 228 English with typos and chat words, 105 Georgian — 82
in Georgian letters, 23 typed in Latin letters; 10 of them name one bot, 8 are nonsense): **333 / 333 (100 %)**. A held-out set of 51
sentences written before the matcher and never tuned on: **51 / 51 (100 %)** — optimistic: the same author
wrote the word lists; the owner's and children's real sentences should be added to `TABLE` as they come.
Required tests, by name: phrase table ≥ 150 at ≥ 90 % (`test_the_phrase_table_is_understood_at_least_nine_times_in_ten`),
each behaviour switch (`test_follow_me_…`, `test_wait_…`, `test_go_home_…`, `test_give_me_space_…`,
`test_build_a_house_…`, `test_find_treasure_…`, `test_guard_me_…`, `test_run_away_…`, `test_hide_…`,
`test_dance_…`, `test_race_me_…`), each answer from a stub state (`test_bot_answers.gd`,
`test_questions_are_answered_from_the_game`, `test_where_is_tilly_from_her_stall`,
`test_each_friend_says_where_it_is`), targeting by name (`test_a_name_talks_to_one_friend`,
`test_a_name_at_the_start_or_the_end_talks_to_one_bot`, `test_a_misspelled_or_georgian_name_still_finds_its_bot`),
the quick-chat phrases (`test_the_quick_chat_phrases_reach_the_friends`,
`test_under_13_players_talk_to_their_friends_with_pictures_and_words`), host routing
(`test_a_guests_words_reach_only_the_guests_own_friends`), the kind hint (`test_words_not_understood_get_a_kind_hint`),
the filter (`test_the_chat_filter_still_applies`), memory (`test_asked_often_to_follow_it_keeps_closer_and_remembers_it`).

Existing tests unchanged and green: `test_bot_rules` (32), `test_bot_friends` (31), `test_bot_minds` (8),
`test_bot_race`, `test_bot_seats`, `test_bot_mind`, `test_world_meta_bots`, `test_quick_chat_wheel`,
`test_chat_panel`, `test_chat_panel_online`, `test_no_guilt_words`.

Two flakes seen in full runs at load 40-55, neither from this task's code:
- `test_bot_minds.gd::test_a_fighter_guards_the_side_monsters_come_from` failed twice in six runs ("idle"
  instead of "wander"). Cause: after its fights the fighter stands 2-4 blocks east of the child, exactly where
  its guard-side wander spot is rolled (the roll depends on the friend's random name); a spot within 1.2 m ends
  the wander in the same decision, the next wander is 2-6 s away, and the test's loop lasts 2.3 s. Fixed in the
  test (bot area): the wander wait is set to nothing before each decision and the loop waits for a wander with a
  spot; 5 of 5 runs green after.
- `test_nakama_chat.gd` (against the lead's shared Nakama server) failed two checks once ("blocked_word",
  "chat_off") and passed alone right after: the shared server's state under other agents' parallel runs.

Full suite on the committed tree: **3087 → 3165 tests, all passing, exit 0** (78 new: 16 + 13 + 15 + 34; load
average 40-55 while it ran).

## Headless smoke run on real terrain (`tools/bot_talk_smoke.gd`)

New Sandbox world (fresh profile, so an under-13 child): a builder and an explorer join; "follow me" typed
in the HUD's real chat bar reaches them (to the friends only) → "OK! We're right behind you!"; "build a house"
→ a 23-block house on real ground in 1.9 s ("Ta-da! A little house for you!"); "where is the treasure?" → the
world's own nearest buried treasure ("I know! There's buried treasure 29 blocks to your right. Follow me!"),
the explorer led the (teleported-behind) child there in 6 s and said "Here it is!"; "is it night soon?" → "It's
day. Night comes in about 11 minutes."; "where is tilly?" → the Sandbox no-shop line; "გამომყევი" →
"კარგი! უკან მოგყვებით!"; "banana" → the kind hint. `failed=0`, no script errors.

## Numbers (desktop, this thread's CPU clock, load 37-50)

- Reading a sentence: **354-386 µs** the first time, **134-192 µs** for words read before (a memo of 1,024
  words); a long message is cut at 120 characters before any work. It runs once per chat message on the host,
  never per frame. Phones are 3-5× slower: ~1-2 ms per message.
- Per friend per decision: `_talk_tick` and `_talk_far` (a few float operations and two `pow`); nothing per
  frame.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **A scored matcher and a word list, no classifier** (the brief's option: a TinyNet classifier trained on the
   phrase table). The matcher scores 100 % on the table and on the held-out set, so a classifier cannot do
   better there; `TinyNet` takes 16 numbers and cannot read words (a word classifier would be a different,
   ~10k-weight net), it would be harder to explain, and a native speaker can edit a word list. *Cost if
   wrong:* sentences outside the word list get the kind hint; adding a word is one line.
2. **Under-13 players may type to their own bot friends.** The spec's "quick chat only" is about chatting with
   people; typed words to one's own friends never reach anyone else, pass the chat filter, and are not stored
   (a local "Name (to your bots): …" line only). The wheel also gets a BOTS picture page. *Cost if wrong:* if the
   owner or the lawyer reads "quick chat only" strictly, remove the typed path (`ChatPanel._submit`'s one line);
   the pictures stay.
3. **A grown-up's "chat off" (online) blocks typing; the wheel's pictures to one's own bots still work** (they are
   play with game characters, not chat). *Cost if wrong:* one check in `_send_phrase`.
4. **"Go home" = wait at the child's bed**, not the FRIENDS page's BYE (which would forget the friend's saved
   mind). No bed: the answer says how to make one. "Go away" = give me space; "bye" never sends a friend away.
   *Cost if wrong:* a child who meant "leave" still uses FRIENDS → BYE.
5. **Calls ("follow me", "come here", "help!", "where are you?") reach all the child's friends wherever they
   are; everything else reaches those within 32 blocks, or the one named.** *Cost if wrong:* a far friend
   ignores an unnamed "wait".
6. **One friend answers for the group ("We're right behind you!"), the one the request is about (builder,
   explorer, fighter) or the nearest; "where are you?" is answered by each.** Builds, treasure, races and Tilly
   are done by one friend (one house, not three). *Cost if wrong:* children may want every friend to answer.
7. **Words not understood get the hint only alone in a world, or when a friend is named**, so chat between
   people is never interrupted by bots. *Cost if wrong:* in multiplayer an unnamed request the bots don't know
   stays unanswered.
8. **Answers skip the friends' 20 s chat gap**; the host's rate limit (5 messages per 10 s per child, like chat)
   keeps them few. *Cost if wrong:* up to five answers in ten seconds for a child who keeps asking.
9. **Answers go to everyone's chat like other bot lines**, in the child's language; the friend keeps that language
   for its follow-up lines ("Ta-da!", "Here it is!"). *Cost if wrong:* other players read the bot's answer.
10. **Georgian needs a font with Georgian letters.** The game's theme has no font of its own; Godot falls back to
    system fonts. On this desktop a Georgian chat line rendered through that fallback (a windowed test picture of
    the BOTS page and "Mossy (bot): კარგი! უკან მოგყვები!"); Android ships Noto Sans Georgian. The lead should
    check on the emulator that Georgian chat lines render (the child's own Georgian typing needs it too). If they
    show boxes, a Georgian font is needed, and the CC0-only rule (Noto is OFL) needs the owner's word.
11. **Georgian words, names and answers: native check needed** (below). The Georgian answers are short and plain.
12. **Survivor builds stay leaves** (Task 15's ruling 3); "with my blocks" in Survivor is answered with the
    leaves line. Sandbox "with my blocks": the child's favourite block (BotStyle), else the block in hand.
    Requested builds are not mind-picked designs, so they teach no "kept / broken" lessons. *Cost if wrong:*
    plainer Survivor builds.
13. **Leading the way:** only to places within 250 blocks (farther ones are told, not led to); the guide waits
    when the child is 9+ blocks behind, gives up after 4 minutes or when stuck ("I can't get through here. It's
    that way!"). Golden animals, the Wanderer and falling stars are not led to (they move or come and go).
14. **"Run away / hide":** with monsters within 16 blocks of the child the friends run 8 blocks away from them
    for 10 s and don't fight; otherwise they hide quietly behind the child for 20 s. Hide-and-seek games are
    M4 H's (co-op games, running in parallel): once merged, "let's play hide and seek" should start that game.
15. **Memory:** each recent follow ask brings a friend 0.75 blocks closer (at most 3; half-life 10 minutes; a
    "give me space" keeps a quarter of them); each recent build ask makes its own builds 8 % sooner (at most
    40 %); kind words add 0.1 liking and a heart. Saved in `WorldMeta.bots[i].mind.a`.
16. **"Don't / stop" turns a request around:** "don't follow me", "stop following me" = give me space; "don't
    build", "stop dancing" = stop and wait.
17. **Names:** at the start (also after "hey / hi / ok") or the end; a 4+ letter name misspelled by one letter,
    a Georgian -ი ending ("pipi"), or Georgian letters (`BotIntents.NAMES_KA`); a word of the word list is never
    taken for a name ("come here" with a friend called Comet).
18. **The BOTS page's phrases are English words under pictures** (the game's UI is English until M3 Task 21a).
19. **The word list can't hold words the guilt test bans** (it scans every string literal in `core/`): a child's
    "hurry" or "don't go" is understood through other words ("come on", "wait") or not at all.

### Georgian for a native check

- Requests (`BotIntents.KA_WORDS`): follow — გამომყევი, მომყევი, წამომყევი, გამყევი, მოდი (აქ), წამოდი,
  წავიდეთ, ჩემთან (მოდი); wait — მოიცადე, დაიცადე, მოიცა, დაელოდე, დამელოდე, დარჩი (აქ), გაჩერდი, შეჩერდი,
  დადექი, არ გაინძრე, სტოპ, მოითმინე; home — (წადი) სახლში, შინ (წადი), საწოლი; space — მომშორდი, თავი
  დამანებე, ნუ მომყვები, წადი აქედან; build — ააშენე, აგვიშენე, ავაშენოთ, აშენება, გააკეთე, სახლი, კოშკი,
  კედელი, ციხე, ქოხი, ხიდი, ჩემს გვერდით, ჩემი ბლოკებით, რამე; treasure — განძი, საიდუმლო, იპოვე, მოძებნე,
  ვიპოვოთ, მოვძებნოთ, გამოიკვლიე, ზარდახშა, სკივრი, ოქრო, თავგადასავალი; fight — იბრძოლე, ებრძოლე,
  ვიბრძოლოთ, დამიცავი, დაიცავი, მოკალი, შეუტიე, ურტყი, დაარტყი; hide — დაიმალე, დავიმალოთ, გაიქეცი,
  გავიქცეთ, გაქცევა, მიიმალე; dance — იცეკვე, ვიცეკვოთ, ცეკვა, (გააკეთე) ხრიკი, იხტუნე, დატრიალდი, იმღერე;
  race — შეჯიბრი, რბოლა, შემეჯიბრე, შევეჯიბროთ, ვინ უფრო სწრაფია; help — მიშველე, დამეხმარე, დახმარება,
  გადამარჩინე, მეშინია; questions — სად არის ტილი / მაღაზია / ვაჭარი / მოვაჭრე, რას აკეთებ / შვრები, რამდენი
  გული მაქვს, მალე / როდის დაღამდება, რომელი საათია, რა გქვია, ვინ ხარ, რა შეგიძლია, შეგიძლია დამეხმარო, რა
  ვთქვა, სად ხარ, ვერ გხედავ, სად წახვედი, როგორ ხარ, კარგად ხარ; friendly — გამარჯობა, გაუმარჯოს, სალამი,
  ჰეი, დილა მშვიდობისა, მადლობა, გმადლობ, მადლობთ, მერსი, ყოჩაღ, მაგარია, კარგად გააკეთე, მიყვარხარ,
  საუკეთესო, სუპერ, ბრავო, ძალიან კარგი, ვაუ, ნახვამდის, ჯერჯერობით, მშვიდობით, ღამე მშვიდობისა, წავედი,
  შეხედე, ნახე (ეს), დახედე, უყურე; ok — კი, ხო, არა, კარგი, ოკ, ჰო.
- Bot names in Georgian letters (`BotIntents.NAMES_KA`): პიპ(ი), ბოლტ(ი), ზუზუ, სპრაუტ(ი), ნიმბუს(ი), პებლ(ი),
  ტინკერ(ი), კომეტა / კომეტ(ი), მოსი, ვიჯეტ(ი), ბლუპ(ი), ფიზ(ი), დუდლ(ი), სპარკი, ვობლ(ი), გიზმო.
- Answers: every `KA` line in `core/bots/bot_answers.gd` (`LINES`, `WE`, `DOING`, `KINDS`, `PERSONALITY`,
  `SIDES`, `TEMPLATES`).
- Latin-letter Georgian is read through a sound key (`BotIntents.key`: kh/x = ხ, q/y/k = ყ/ქ/კ, w/ts/c = წ/ც,
  sh = შ, ch = ჩ/ჭ, gh = ღ, dz = ძ, zh = ჟ): a native speaker may know spellings children use that it misses.

## Merge notes (what will conflict)

- `entities/bots/bot_friend.gd`: one-line hooks in `_decide` (5 places), `_enter`, `_check_progress` (a new
  `else:`), `_update_target`, `_build_here` (2), `mind_save` / `mind_load`; a section at the end.
- `core/rules/bot_rules.gd`: `choose_target` (a new optional argument), `choose_behaviour` (the order facts); a
  section at the end.
- `world/bot_director.gd`, `autoloads/session.gd`: sections at the end (Session: one comment line in Task 15's
  section too).
- `ui/hud/chat_panel.gd`: `setup` (1 line), `_submit` (3), `_send_phrase` (2), a section at the end.
- `ui/online/quick_chat_wheel.gd`: `page`, the BOTS / CHAT pills, `phrases()` in the slots, the pick and the
  pictures (M4 E's file).
- `tests/integration/test_bot_minds.gd`: the fighter guard test's wander loop (the flake above).
- Spec §12.14a, the M3 plan's "Owner 38" line, `docs/DEVELOPMENT.md` (§4 smoke run, §5 bot chat, §8 one line),
  `docs/playtests/owner-feedback.md` row #38.

## What the lead should check on the emulator

1. Sandbox, add a builder, an explorer and a fighter (FRIENDS). CHAT → type (13+) or, for an under-13 profile,
   the wheel's BOTS pill → pictures: "follow me" (all come close), "wait" (they stay while you walk off),
   "come here" (they come), "build a house" (a hut goes up beside you, then "Ta-da!"), "find treasure" (the
   explorer leads to a secret and sparkles it), "guard me", "run away" at night, "dance", "race me" near a
   course, "where are you?" (each answers and sparkles).
2. Questions: "where is Tilly?" in Survivor (the direction matches where you look), "how many hearts do I
   have?" after a hit, "is it night soon?", "what are you doing?" while one waits, "what's your name?".
3. Georgian: type "გამომყევი", "ააშენე სახლი", "სად არის განძი?" and Latin "gamarjoba": answers in Georgian,
   **and check the Georgian letters render** (ruling 10).
4. "Mossy, wait" makes only Mossy wait; "banana" alone gives the hint; with a LAN guest, the guest's words move
   no host friend.
5. Save & Quit after asking "follow me" a few times: after continuing, that friend still keeps closer.
6. The BOTS pill and page: big enough, pictures readable, CHAT goes back, the wheel still closes with the middle.
