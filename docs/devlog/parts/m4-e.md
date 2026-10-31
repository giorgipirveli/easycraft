# M4 Wave 2, Agent E: online chat and co-op (2026-09-24)

Spec §17.4 (chat) and §17.5 (co-op), with §5.13-5.14, §12.3, §12.8, §12.14 and §16; plan
`docs/superpowers/plans/2026-09-24-m4-better-together.md` Tasks 6 and 7. Built in a worktree cut at
`07319d6` (M2, the spike and Wave 1's online client, server 0.2.0 and hosting kit merged) while other
Wave 2 agents worked in parallel. No editor or emulator was used; the lead merges and checks two games
together (the list at the end).

## What was built

### Chat online (§17.4)

| File | What |
|---|---|
| `core/net/online_chat_rules.gd` (`OnlineChatRules`) | Pure rules: the quick-chat wheel's eight phrases (all from the server's `QUICK_PHRASES`) and their pictures, the chat level of an account (the server's `AccountRules.chatLevel`: off without social play or with chat off, never above quick under 13), who may type (13+ at the text level only), what may be sent (`check_send`, the `{"text"}` / `{"emote"}` content), reading a server message carefully (only Nakama code 0, exactly one field, a real emote id, a name that is a username, never free text for an under-13 reader, cleaned), the line it shows as, history for 13+ only and the last 30 days, the team room's name (the relayed match id), kind words for every refusal. |
| `net/online_backend.gd`, `net/nakama_online_backend.gd` | The backend gains `join_chat` / `leave_chat` / `send_chat` / `chat_history` and the `chat_message` signal; the Nakama one runs them on its own socket (`join_chat_async`, `write_chat_message_async`, `list_channel_messages_async`) and keeps the hooks' refusal codes. |
| `net/online_service.gd` (section "M4 E: chat") | `open_dm(friend)` (13+: brings back the last 30 days), `open_team(match)`, `team_channel`, `close_chat`, `messages`, `send_text` / `send_phrase` / `send_emote` (a send limit like the host's: 5 in 10 s), `can_report` / `mute_sender` / `report_message` (report_user with the channel and message ids; mutes too), `chat_level` / `can_type`. Muted and blocked players' messages never come; muting also removes what they said. Names on screen come from the friends list and the account (see the rulings). |
| `ui/online/quick_chat_wheel.gd` (`QuickChatWheel`), `ui/online/chat_pictures.gd` (`ChatPictures`) | The wheel: eight 136 px round slots around the middle with drawn pictures (a waving hand, an arrow, an eye, a ring buoy, a heart, a star, stacked blocks, a hand with motion lines), the close button in the middle, optional `/ COMMANDS` and `EMOTES` pills; a tap outside closes it and says where (the chat panel looks for a message there). |
| `ui/hud/chat_panel.gd` (section "M4 E") | Under-13 chat opens the wheel, never a keyboard (the commands through the wheel's pill); 13+ get QUICK beside SEND. In an online match (`use_team_chat`) players' messages go through the match's team room; the host's relay lines of kind chat are then not shown (system and bot lines still are); a grown-up's chat off stops sending and receiving there (commands still work). A tap on someone else's line (in the history, with the bar open, or through the wheel) opens MUTE / REPORT (the four reasons); the chat takes that touch before the look area hears it, and other lines never block building. |
| `ui/online/dm_panel.gd` (`DmPanel`), `ui/online/online_friends_panel.gd` | TALK on a friend's row (when chat is not off and the friend is not muted) opens the chat page inside the friends page: the messages (buttons), 13+ a text field with SEND, QUICK and EMOTES, everyone else QUICK CHAT and EMOTES only; a friend's message opens MUTE / REPORT; BACK leaves the chat. The wheels sit on a CanvasLayer over the menu. |
| `autoloads/session.gd` (section "M4 E") | `online_match_id()` (the relayed match this game plays in) and the `revive_done` signal. |
| `scenes/sandbox.gd` (section "M4 E") | `_setup_team_chat()`: in an online match with this device's service, the HUD's chat opens the team room (the host's when its match is ready). |
| `server/modules/src/rules/chat_rules.ts`, `src/server/chat.ts` (module **0.2.1**) | History on the server: `rtBeforeChannelJoin` sets the join's persistence itself, true only for a DM between two players at the text level (whatever the game asks), never with an under-13 player or in a team room; opening a kept DM removes its messages older than 30 days (`Chat.purgeExpired`: oldest first, a batch of 100). |
| `tests/fakes/fake_online_server.gd`, `fake_online_backend.gd` | Channels as B's hooks answer them (DM between friends, the team room only for the match's players, the strictest level, the content rules, persistence), `match_members`, `chat_delivered`, the clock for message times. |
| `tools/measure_online_chat.gd` (+ `_steps.gd`) | Times the chat against a server (below). |

### Co-op (§17.5)

| File | What |
|---|---|
| `core/survival/revive_rules.gd` (`ReviveRules`) | Pure: the wait for help (10 s instead of 1.6 s when a teammate who is up is within 24 blocks), the hold (3 s), the reach (3 blocks feet to feet, more for a giant), who may help whom (`SELF`, `NOT_DOWN`, `PROTECTED`, `HELPER_DOWN`, `TOO_FAR`), the ring's progress, the words. |
| `world/knockout_director.gd` (section "M4 E") | The host decides with its own positions: who waits (`_rpc_wait`), a help starting, going on and ending (`request_revive`, checked every tick; `_rpc_help`), the help done (full hearts on the spot, the usual protection, `_rpc_revived`: both cheer, confetti, toasts for the three kinds of players, `revived` and `Session.revive_done`), GET UP (`request_get_up`). This game's player: HELP UP near a waiting teammate (hold; H on a keyboard), GET UP while waiting (G), the ring and the words. |
| `ui/hud/hud.gd` (section "M4 E"), `ui/hud/revive_ring.gd` (`ReviveRing`), `ui/hud/knockout_overlay.gd` | HELP UP and GET UP share a spot above the hotbar (240 × 88, clear of SLEEP, JUMP, ATTACK, DOWN); the ring fills left of them; the knock-out fade's tip becomes "A friend can help you up!" / "Pip is helping you up!" (`set_help_text`). |
| `core/rules/wave_rules.gd`, `world/wave_director.gd`, `ui/hud/totem_panel.gd` | `size` / `roster` take the team: +50% monsters per player or bot friend beyond the first, rounded up, at most 20 (gentle 8); a team's wave is the solo wave plus more (same levels). The director counts the team when the wave begins (`team_size`, default `BotFriend.team_size`), sends it in its state (`team`) so every Totem panel shows the right count, and forgets a helped player's knock-out (paid on a win). |
| `core/rules/bot_rules.gd`, `world/bot_director.gd`, `entities/bots/bot_friend.gd`, `scenes/sandbox.gd` (section "M4 E") | `BotRules.seats_for_bots(players)`: four seats in all, at most three friends. Online (`seats`), the newest friend makes room when a player joins ("I'll make room for your friend!", a poof) and comes back when a seat is free (`fit_seats`, on `client_ready` / `peer_left`); friends making room stay in the world's save; a restored world online brings only as many as there are seats. Solo and LAN are unchanged. |

## Patterns (GodotPrompter skills `multiplayer-basics`, `godot-ui`)

- **Chosen:** client → host requests as `any_peer` reliable RPCs and host → everyone state events as
  `authority` + `call_local` reliable RPCs on the node that owns the feature (the KnockoutDirector, on
  every peer with the same name), the way bags and waves work; the ring is animated on each game from
  the start event (no per-frame sync). The online chat is a service with an injected backend (the
  fake in tests), as C built it. UI: code-built `Control` trees with containers and UiKit's theme
  (the DM page), custom-drawn full-screen overlays for the wheel (as the emote wheel), wheels on a
  `CanvasLayer` when they must cover a menu.
- **Rejected:** a `MultiplayerSynchronizer` for the revive progress (a stream for a 3 s event; the
  host's start/stop events are enough); Nakama's own chat in place of the in-game relay chat for
  every game (LAN and developer matches have no accounts: they keep the host-checked relay chat); a
  new Input Map action for HELP UP (project.godot is shared; physical keys like the sleep director's
  WAKE key instead); `.tscn` scenes for the new screens (the project builds menus in code).

## Tests (RED → GREEN)

Every new rule and class started as a failing test (missing class or method; the wave sizes' "too
many arguments"; the revive and HUD tests' missing API; the Nakama chat test's `not_signed_in` from
the base backend against the running server), then GREEN. The chat panel and revive tests were
mutation-checked (the relay filter and the under-13 wheel removed: 6 of 14 failing; the wait window,
the cheer and the reach removed: 5 and 2 of 12 failing).

- `tests/unit/test_online_chat_rules.gd` (8): the wheel is the server's (reads `chat_rules.ts`), who
  types, history 13+, sending, reading server messages, 30 days, kind words, channel names.
- `tests/integration/test_online_chat.gd` (13): DMs between teens (both see, the sender's echo),
  friends only (client and server), history back for 30 days, under-13 (the wheel, the teen's free
  text refused by the channel, emotes, nothing kept), a grown-up's chat off, the team room (only the
  match's players, nothing kept), leaving, mute from a message, report from a message (ids), my own
  message, the send limit, no chat before signing in / without consent, names from the friends list.
- `tests/integration/test_nakama_chat.gd` (4, the development server; skipped without it): a DM
  between two teen friends (sent, heard, cleaned, kept, an emote), a stranger refused, the filter,
  the team room for the match's players only.
- `tests/integration/test_quick_chat_wheel.gd` (7), `test_chat_panel_online.gd` (15),
  `test_online_dm.gd` (8), `test_team_chat_session.gd` (1, server): the wheel, the chat panel's wheel /
  team chat / chat off / mute and report from a line, the DM page (fits the menu's panel, buttons ≥ 135
  × 64), `Session.online_match_id`.
- `tests/unit/test_revive_rules.gd` (5), `tests/integration/test_revive.gd` (12),
  `test_revive_hud.gd` (5): waiting, GET UP, the 3 s hold on the spot with full hearts and the cheer,
  letting go, walking away, only a knocked-out teammate, not once getting up (protected), a knocked-out
  helper, too far (words), Sandbox, the wave; the buttons, the ring, the words.
- `tests/unit/test_wave_team_rules.gd` (4), `tests/integration/test_wave_team.gd` (5): the sizes, caps,
  the same wave plus more, the director counting the team at the start, the Totem panel.
- `tests/integration/test_bot_seats.gd` (6): seats, solo/LAN unchanged, the host's friends come along,
  making room and coming back, a full world, restoring online.
- Changed: `tests/integration/test_chat_panel.gd` (two tests: under-13 chat opens the wheel now; the
  bar's phrase buttons are checked for a 13+ player, and under-13 free text through the commands bar).
- Server (Node): `chat_rules.test.ts` +2 (history rule, 30 days), `social_rpcs.test.ts` +2 (the join
  hook's persistence, the purge); `test/integration/nakama.server.ts` +1 (a real server: kept for two
  teens, nothing with quick chat or in a team room; version 0.2.1).

Suite: **2173 → 2266 tests** (212 → 225 scripts), all passing, 1 pending as before, with the lead's
server (0.2.0) up (so the server-backed scripts ran). Node: **141 → 145**, integration
**14 → 15** against my own server (compose project `easycraft_e`, ports 7479-7481, module 0.2.1).

## Measurements

- `tools/measure_online_chat.gd` against my own server (0.2.1), 5 rounds, load average 14.3:
  DM join 13.8 ms (median), a message from send to the friend hearing it 13.8 ms (max 13.9, n 25),
  a 13+ DM's history (5 messages) 7.5 ms, team room join 13.7 ms, a quick phrase there 13.8 ms. The
  ~13.8 ms is mostly the one frame each backend call waits (`_settle`); over the internet add the
  round trip to the server.
- The 30-day purge on a real Nakama 3.41 (my server): a DM message aged 40 days in the database was
  removed when the DM was opened again; the fresh one stayed.
- This game's help scan runs five times a second over the waiting players only (usually none); the
  host checks each help in progress every frame (two player lookups).

## Rulings (decisions made on the owner's behalf)

1. **The wheel says "Thanks!", not "Thank you!"** — the server's quick phrases (and the game's
   `ChatRules`, kept in step) have "Thanks!"; a phrase outside that list would be refused for every
   under-13 player. *Cost if wrong:* add "Thank you!" to both lists and reload the server.
2. **The wheel holds 8 of the 13 quick phrases** (the lead's list); a 13+ player's chat bar still shows
   all 13 as buttons. *Cost if wrong:* none (a second page of phrases later).
3. **Under-13 chat opens the wheel, never a keyboard;** the chat commands are one tap away (the
   wheel's `/ COMMANDS`, which opens the bar with "/"). *Cost if wrong:* none known.
4. **In an online match, players talk in the team room** (the server's rules, reportable messages);
   the host's relay lines of kind chat are hidden then; system and bot lines still come through the
   host. LAN and developer matches (no signed-in service) keep the relay chat. *Cost if wrong:* a
   guest whose room join failed (network) falls back to relay chat that the others don't show.
5. **A grown-up's chat off holds in online matches** (nothing sent or shown; commands work).
6. **History on the server:** only a DM between two players at the text level keeps messages;
   never with an under-13 player, never in a team room, whatever the game asks (module 0.2.1);
   opening a kept DM removes what is older than 30 days, and the game shows only the last 30 days.
   *Cost if wrong:* a DM nobody opens again keeps its old messages in the database (never shown); a
   daily `DELETE FROM message WHERE create_time < now() - interval '30 days'` in the hosting kit's
   backup job would close that (the lead's or the owner's call).
7. **A send limit on the device only** (5 messages in 10 s, like the host's); the server has none
   (B's ruling 13). *Cost if wrong:* a modified game could flood a friend's DM; a server limit needs a
   storage write per message.
8. **Names on screen come from the friends list and the account:** Nakama's socket keeps the random
   name it gave until the next sign-in, so a name claimed this session would show as "NztQIhfgxE"
   (seen on the real server). *Cost if wrong:* in a team room, a guest who is not the reader's friend
   and claimed a name this session still shows the random one; C's claim could sign in again.
9. **The DM page lives inside the friends page** (TALK), not a new PLAY ONLINE screen. *Cost:* none.
10. **Emotes in a DM are the player's own emote wheel,** shown as "Pip: *Wave*" (no figure). *Cost:*
    none.
11. **Only players help players up;** bot friends neither help nor are helped (they get up by
    themselves as before). *Cost if wrong:* a solo child with bots is never helped up by them.
12. **Waiting for help only with a teammate near** (up, within 24 blocks): 10 s instead of 1.6 s, with
    GET UP (G) to go at once; alone, nothing changes. *Cost if wrong:* a child waits up to 10 s when a
    friend is near but busy (GET UP is there, no countdown).
13. **Helped up = full hearts on the spot** (and the usual protection); a Survivor bag stays where
    they fell, right there. *Cost if wrong:* half hearts is one line.
14. **"Not while protected":** a player already getting up (the host's arrival protection) can't be
    helped, and a knocked-out player can't help.
15. **HELP UP is a hold button** (touch) **or H**, GET UP **G** (physical keys, no Input Map change).
16. **A helped player counts as standing for the running wave** (paid if it is won; the wave isn't
    lost because they once fell). *Cost if wrong:* one line in `WaveDirector._on_revived`.
17. **The team for waves is players + bot friends** (like the Golem's health, BotFriend.team_size),
    counted when the wave begins: +50% each beyond the first, rounded up, at most 20 (gentle 8).
    *Cost if wrong:* a solo child with three bots gets 13 monsters in wave 1 (5 alone); counting
    players only is one line (`WaveDirector.team_size`).
18. **Bot seats online only:** four seats in all; the host's saved friends come along into free seats
    (none are added by themselves); the newest makes room for a player and comes back later; solo and
    LAN keep three. *Cost if wrong:* auto-added friends are one call in `_setup_bot_seats`.
19. **Module 0.2.1** (history rule, purge). The game works with 0.2.0 too (it asks for history only
    for 13+; 0.2.0 just keeps a 13+ player's side of a DM with an under-13 friend — quick phrases).

## For the lead

**Merge notes.** New sections, appended: Session "M4 E", sandbox "M4 E" (two functions; one-line
calls at the end of `_setup_local_player` and `_start_bots`), HUD "M4 E", KnockoutDirector "M4 E"
(plus one line each in `setup_local`, `_process`, `advance`, `knock_out`, `_get_up`, `_on_peer_left`),
OnlineService "M4 E" (plus one line each in `_watch_backend`, `_went_offline`, `mute`), the backends'
chat sections, the fake server's chat section. Small edits in shared M2 files: `WaveRules.size/roster`
(a defaulted `team` argument), `WaveDirector` (`team_size`, `_team`, `state.team`, the revive hook),
`TotemPanel._refresh`, `BotDirector.can_add/to_save/restore` (+ section), `BotFriend.say_make_room`,
`KnockoutOverlay.set_help_text`, `OnlineFriendsPanel._row` (TALK) + `show_chat`, and the chat panel.
`server/modules` needs `server/dev.sh reload` for 0.2.1 (the integration test checks the version).

**Check with two games** (emulator + desktop; the server with module 0.2.1 and the fake consent
provider; desktop with a private `XDG_DATA_HOME`):
1. Two 13+ players who are friends: FRIENDS → TALK → type → the other's TALK page shows it; BACK and
   TALK again: the message is back (history); the chat page fits the emulator's screen.
2. An under-13 player (fake consent) and a 13+ friend: the child's TALK page has only QUICK CHAT and
   EMOTES; the teen's free text says "Use the quick chat buttons..."; the wheel and an emote arrive;
   BACK and TALK again: nothing kept. Console → Chat: no stored messages for that DM.
3. Host online (HOST MY WORLD), invite, the guest joins: T/Enter (13+) or CHAT (the wheel for
   under-13) talks in the team room; both see it; the host's "joined the game" lines still come.
4. Tap the friend's line in the chat history (or with the bar open) → MUTE (their lines go) /
   REPORT → a reason → "Thank you for telling us..." and the report in the console (collection
   `reports`, with `channel_id` and `message_id`).
5. Revive (Survivor, a wave or `/summon`): the guest is knocked out near the host → the guest's fade
   says "A friend can help you up!" with GET UP; the host sees HELP UP → hold 3 s (H on the desktop):
   the ring fills on both, the guest stands up where they fell with full hearts, both cheer, toasts
   "You helped Pip up!" / "Mia helped you up!"; letting go early or walking away stops it; GET UP (G)
   goes home at once. Alone, a knock-out is as before.
6. Wave 1 with two players: the Totem panel says × 8 (× 5 alone); eight monsters come.
7. Bot seats: host online with three bot friends → a guest joins: one friend says "I'll make room
   for your friend!" and poofs; the guest leaves: it comes back; SAVE & QUIT and back: three friends.
