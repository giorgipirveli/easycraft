# M4 Wave 1, Agent C: the online client and its screens (2026-09-24)

Spec §17.1-17.3 (with §5.13-5.14, §7.3, §16); plan `docs/superpowers/plans/2026-09-24-m4-better-together.md`
Tasks 2-5, client side (the Wave 1 table's row C). Built in a worktree cut at `1c0e081` (the M4 early
spike merged) while Agents A (world sync), B (server) and D (hosting kit) worked in parallel. No editor
or emulator was used; the lead merges and checks two games together (the list at the end).

## What was built

| File | What |
|---|---|
| `core/net/online_rules.gd` (`OnlineRules`) | Pure rules: the account from the server's answer (safe defaults: the phone's band, else under-13's; no consent; online off for under-13), `social_allowed` (under-13: verified consent and a grown-up's yes; 13+: unless switched off), which PLAY ONLINE screen shows, the stay-safe card's timing (first time, and after 30 days), Nakama's friend states, the typed friend name, invites (101: match id, a valid username, the world name only "Sandbox"/"Survivor"), cancelled invites (102), the 4-player cap, and every error code in plain, kind words (≤ 12 words, no guilt, never a code). |
| `core/net/online_prefs.gd` (`OnlinePrefs`) | What this device remembers: when the stay-safe card was seen and whom it muted, in `user://online.json` (never `profile.json`), written crash-safe by JsonStore. |
| `net/online_backend.gd` (`OnlineBackend`) | The interface: `sign_in`, `call_rpc`, `list_friends`, `add_friend_by_name` / `_by_id`, `remove_friend`, `block`, `follow`, `sign_out`; signals `notified`, `presence_changed`, `closed`. Every call answers `{"ok", "error", ...}`. |
| `net/nakama_online_backend.gd` (`NakamaOnlineBackend`) | The Nakama implementation on its own `NakamaLink`: appears online (`update_status`) so friends see a dot, notifications and status presence as signals, Nakama's errors as codes (`not_yet` for a missing RPC, `no_such_player`, `self`, `rate_limited`, `network`). Loaded by path only. |
| `net/online_service.gd` (`OnlineService`) | Sign-in state (once; a second call waits), the account and its screen, `claim_username` (the claimed name becomes the profile's), consent (`start_consent` with an https-only provider page, `check_consent`), `set_parent_settings`, friends (list sorted: requests, online, away, asked; blocked hidden), `add_friend` / `accept` / `decline` / `block`, `mute` / `unmute` (device), `report` (+ mute), `invite`, open invites (10 min), notifications 101/102/103 and Nakama's -2/-3. Nothing social unless allowed. |
| `ui/online/play_online_screen.gd` (`PlayOnlineScreen`) | PLAY ONLINE: connecting / "Can't reach the game" + TRY AGAIN, the stay-safe card, the name claim, "Ask a grown-up" (GROWN-UP HERE → gate → grown-up's page), waiting (CHECK), "a grown-up turned online play off", HOME (HOST MY WORLD, FRIENDS with "n new", GROWN-UPS), which world (SANDBOX / SURVIVOR). |
| `ui/online/stay_safe_card.gd` (`StaySafeCard`) | Four pictures and short sentences (secret name/home/school, friends you know, tell a grown-up, be kind) and I WILL!; `read_aloud_text()`. |
| `ui/online/username_claim.gd` (`UsernameClaim`) | The profile's name, OK; when taken: edit it here, RANDOM (as at first launch), plain words. |
| `ui/online/grown_up_gate.gd` (`GrownUpGate`) | The M3 `ParentGate` question in words and a number pad (new question after a wrong answer). |
| `ui/online/grown_ups_panel.gd` (`GrownUpsPanel`) | For grown-ups: START / CHECK the consent flow (disabled with "coming soon" when the server has no provider), then ONLINE PLAY ON/OFF and CHAT OFF/QUICK(/TEXT for 13+), SAVE. |
| `ui/online/online_friends_panel.gd` (`OnlineFriendsPanel`) | Add by name (ADD), rows with online dots, YES / NO for requests, "asked", JOIN for an open invite, MORE → MUTE/UNMUTE, BLOCK (asks first), REPORT → MEAN WORDS / SCARY / ASKED SECRETS / SOMETHING ELSE → "Thank you for telling us. A grown-up will look at it." Refreshes every 15 s. |
| `ui/online/invite_panel.gd` (`InvitePanel`) | The pause menu's INVITE page: friends online with INVITE → INVITED, "Players: n of 4", full → plain words. |
| `ui/online/invite_toast.gd` (`InviteToast`) | "Pip invites you to their world!" / "A Survivor world", JOIN / NOT NOW, over every scene (its own CanvasLayer 90, runs while paused), gone by itself after 30 s (no countdown), gone when cancelled. |
| `ui/online/online_dot.gd`, `online_icon.gd`, `online_ui.gd`, `online_flow.gd` | The dot (filled green with a white ring = online, empty grey ring = away: shape and colour), the drawn pictures (lock, friends, grown-up, heart, globe, house, add friend, talk, flag; no image files), the shared look (buttons ≥ 135 × 64 with a picture on the left), and the flows into a world (`OnlineFlow.host(mode)`, `join(match_id)`). |
| `autoloads/session.gd` | Section `# --- M4 C: online play` (appended; the spike's section untouched): `online_service()` (made on first use, `PROCESS_MODE_ALWAYS`), `use_online_service()` (tests), the one invite toast, `online_toast_blockers()`, `online_autostart()`, `online_server()`, `prepare_online_host()` / `prepare_online_join()`, `online_hosted_match()`, `online_players()`, `online_dot_on()`. |
| `ui/menus/menu.gd` | PLAY ONLINE next to SANDBOX and SURVIVOR (the three are 340 wide, were 380), `_show_online()`, `Session.online_autostart()` in `_ready`. |
| `ui/menus/pause_menu.gd` | Section `# --- M4 C`: the INVITE FRIENDS row above SAVE & QUIT (an online host with friends allowed only) → `InvitePanel`. |
| `ui/hud/hud.gd` | Section `# --- M4 C`: the online dot right of the username (the name moves 36 px left while it shows), asked once a second. |
| `scenes/sandbox.gd` | Section `# --- M4 C`: `_setup_online()` (the host's INVITE row and "Your world is online!" once the match exists; plain words if hosting failed), `_setup_online_hud()` (the toast as a look-area blocker), `leave_for_online()` (JOIN: save, `save_and_wait`, join). Three one-line calls. |
| `tests/fakes/fake_online_server.gd`, `fake_online_backend.gd` | The in-memory server (accounts, friend edges, presence, notifications, Agent B's RPCs and hooks as B's module answers them) and its backend (optional latency). No `class_name`: they never ship (exports exclude `tests/*`). |
| `tools/measure_online_backend.gd` (+ `_steps.gd`) | Times the backend's calls against a running server (below). |

## Patterns (GodotPrompter skills `dependency-injection`, `godot-ui`)

- **Chosen:** property injection of a backend behind an interface (`OnlineBackend`), a real one and
  a fake (the skill's "test stubs implement the same interface"); scene injection of the service into
  every screen (`screen.service = ...`); one long-lived owner for the service under the existing
  `Session` autoload (it outlasts scene changes, like the match link); code-built `Control` trees
  with containers and one theme (`UiKit.theme()`), as every menu here is built.
- **Rejected:** a new `Online` autoload (a `project.godot` change every agent would collide on, and
  solo/LAN would load it); a service locator (one service, one owner); `.tscn` scenes for the
  screens (the project builds menus in code; tests build them the same way); image icons (no CC0
  pictures of these; drawn shapes need no licence and scale).

## Aligning with Agent B (read from B's worktree at 13:05, not merged here)

| RPC / hook | What the client sends | What it reads |
|---|---|---|
| `get_account_state` | `{}` | `username`, `claimed`, `age_band`, `consent`, `online_allowed`, `chat`, `consent_available` (at the top or under `metadata`) |
| `claim_username` | `{"username", "age_band"}` | the account (as above) or `error`: `taken`, the name codes |
| `consent_start` | `{"age_band"}` (B ignores it; B also takes an optional `parent_contact`, not sent) | the account; `url` if a provider gives one (https only); errors `not_claimed`, `consent_unavailable` |
| `consent_status` | `{}` | the account (`consent`); notification 103 on a yes |
| `set_parent_settings` | `{"online_allowed", "chat"}` | the account; `consent_needed`, `chat_not_allowed` |
| `invite_friend` | `{"user_id", "username", "match_id", "world_name"}` | `ok`; `not_friends`, `offline`, `full`/`match_full`, `not_allowed_online`, `busy` |
| `report_user` | `{"user_id", "reason"}` with B's reasons `mean_words`, `scary`, `personal_info`, `other` | `ok` |
| Nakama friends API behind B's `beforeAddFriends` | exact username (B matches any case) | `not_found` → "No player has that name", `not_allowed_online` → "Ask a grown-up to say yes first." |
| `MatchJoin` hook | — | `match: not_invited` → "Ask your friend to invite you again.", `match: match_full` → "This world is full." |

B's server needs the **claim before consent** (the first claim sets the band; `consent_start` answers
`not_claimed` otherwise) and keeps a child's name unfindable until consent. So the screens go: card →
name → (under-13) ask a grown-up → home. The fake server mirrors B's answers, so the client's tests
follow B's contract; after the merge, the lead's check with the real module is the proof.

## Tests (RED → GREEN)

Every new class was first a failing test ("Identifier not declared"), then GREEN:
- `tests/unit/test_online_rules.gd` (22): the account (server wins, nested metadata, safe defaults,
  never free text for under-13, `claimed` and `consent_available`), consent gating, the screen order,
  the card's timing, claimed names, friend states and typed names, invites and broken invites, world
  names, cancelled invites, 4 players, every error kind and short, refused joins, unknown codes.
- `tests/unit/test_online_prefs.gd` (5).
- `tests/integration/test_online_service.gd` (28, the fake server): sign-in and the screens in order,
  no server, a build without a server address ("Online play is coming soon!", nothing tried), signing in twice, the connection closing, taken / bad /
  another name, under-13: claim then ask, not findable, consent flow, consent needs the name, no
  provider, provider page, 103, parent settings; friends: request → accept with online dots and
  presence, add errors, list order, decline, block, mute (device, silences invites), report (+ mute,
  reasons); invites: received, cancelled, expired, errors, none for under-13 without consent, broken,
  from a blocked player.
- `tests/integration/test_online_screens.gd` (18): each page fits the menu's panel (1224 × 534) and
  every button is ≥ 135 × 64; a build without a server (coming soon, BACK only, no connection);
  card → claim → home; taken name changed on the spot; no server + TRY
  AGAIN; HOST MY WORLD → SURVIVOR; BACK; a new under-13 goes card → name → ask; the gate (wrong
  answer stays), START / CHECK, the switches (quick chat only), DONE → home; no provider → START off;
  the provider page; a waiting child moves on at 103; a grown-up switches online back on; the friends
  page (requests, dots, JOIN, YES), adding by name, mute / block (asks first) / report; the toast
  (JOIN, NOT NOW keeps the invite, cancel, fits between the pause button and the right column, runs
  while paused, slips away); the invite page (online friends only, INVITED, full).
- `tests/integration/test_online_menus.gd` (9): the server comes from `OnlineConfig.default_server()`
  when it exists; PLAY ONLINE on the main menu's row and it opens the
  screen and signs in; the pause menu with MONSTERS + FRIENDS + INVITE fits (≤ 680 px), INVITE right
  above SAVE & QUIT, opens the invite page, BACK; no INVITE solo / LAN / under-13 without consent;
  the HUD dot (beside the name, clear of WALK, the name moves back); the dot follows Session; one
  toast that follows the service; no toast for an under-13's invite; host / join settings.
- `tests/integration/test_nakama_online_backend.gd` (4, skipped without a server; run against the
  lead's development server on 7350, which has only the spike's module): sign-in + RPC + a missing
  RPC is `not_yet`; no server is a network error; **a real friend request with Nakama's -2
  notification, accept, online in the list, follow presence (join and leave), block**; friend errors.

Suite: **1733 → 1819** (177 → 183 scripts), all passing, 1 pending as before (full runs in this
worktree with the lead's server up, so the server-backed scripts ran).

## Measurements

`tools/measure_online_backend.gd`, 5 rounds against the lead's server on this PC, load average 21.8
(13:12): sign-in (device auth + socket + appear online) median 34.5 ms (max 58.4); an RPC 7.2 ms
(13.9); add friend 13.5 ms, and the friend's -2 notification had arrived by then; accept 13.7 ms;
friends list 13.1 ms; follow 13.8 ms. The ~13 ms are mostly the one frame each call waits before
returning (`_settle`, so a caller may free things). Over the internet add the round trip to the server.
The HUD dot asks `Session.online_dot_on()` once a second (two field reads).

## Rulings (decisions made on the owner's behalf)

1. **The service is not an autoload:** it lives under `Session` (made on first use), with its **own
   Nakama connection**, apart from the match's link. *Cost if wrong:* two sockets per device during an
   online game (pings only); sharing one means `Session._online_start` reusing the service's link.
2. **Card → name → consent → home.** B's server sets the band at the first claim and refuses consent
   before it; a child's claimed name stays unfindable until consent (B's hooks), which meets §17.2's
   "findable username". *Cost if wrong:* reorder `OnlineRules.screen` (one function) and B accepts
   `consent_start` before a claim.
3. **The claimed name becomes the profile's name** (one name everywhere). *Cost if wrong:* a child
   whose first name was taken also shows the new name on LAN.
4. **The client never asks for the parent's contact;** a provider's own page opens in the browser
   (https only). *Cost if wrong:* when the owner's provider needs the parent's email, a field on the
   grown-up page (B passes `parent_contact` on and never stores it).
5. **Mute lives on the device** (`user://online.json`), and a report mutes too. *Cost if wrong:* mutes
   don't follow the child to a new phone.
6. **Invites are open 10 minutes on the client;** NOT NOW keeps them in the friends list (JOIN); the
   toast slips away after 30 s with no countdown. *Cost if wrong:* none (B has its own expiry).
7. **One invite toast over every scene** (CanvasLayer 90 under Session, kept for the whole run: the
   HUD holds it as a blocker). *Cost if wrong:* one hidden control in solo games.
8. **JOIN in a world saves it and leaves;** joining while hosting ends that session for its guests
   (§17.3: the session ends with the host). *Cost if wrong:* a "leave your friends?" question later.
9. **Invites show only "Sandbox" or "Survivor"** as the world name (B accepts filtered free text).
   *Cost if wrong:* none.
10. **Report reasons are B's codes** (`mean_words`, `scary`, `personal_info` as "ASKED SECRETS",
    `other`). *Cost if wrong:* none.
11. **INVITE FRIENDS is its own row above SAVE & QUIT,** only for an online host with friends
    allowed; the fullest menu (MONSTERS, FRIENDS, INVITE) fits. *Cost if wrong:* if M2 adds a row, pair
    INVITE with FRIENDS.
12. **The HUD dot means "online":** signed in for friends or in an online match (not only in a match).
    *Cost if wrong:* one line in `Session.online_dot_on`.
13. **The main menu's three mode buttons are 340 wide** (were 380) so PLAY ONLINE sits on their row.
    *Cost if wrong:* none (the words fit).
14. **Autostart:** a device that has seen the card signs in at the main menu (never headless), so
    invites reach the menu and solo games. *Cost if wrong:* a silent connection try per menu visit
    when offline.
15. **Presence:** this connection appears online (`update_status`), friends' dots come from the
    friends list, `follow` and a 15 s refresh. *Cost if wrong:* see "for the lead" (StatusFollow).
16. **The server address** (the lead's request, 13:20): `--online-server=`, else Agent D's
    `OnlineConfig.default_server()`, called through the script (`get_script_method_list`) so this
    branch runs without D's change (then this PC's server, `10.0.2.2` in a debug build on Android).
    A release build with no server address yet (`{error}`) never tries to connect: PLAY ONLINE shows
    "Online play is coming soon!" with only BACK. *Cost if wrong:* none (one function).
17. **No read-aloud button yet:** the card's words are short and `StaySafeCard.read_aloud_text()` has
    them all; the game has no text-to-speech yet (M3 core set). *Cost if wrong:* a button when it lands.
18. **A new gate control** (`GrownUpGate`) on `ParentGate`, not the Theater's pad (inside M3's panel).
    *Cost if wrong:* two similar pads to merge later.
19. **Release builds and under-13:** the client doesn't look at the build; the server's
    `consent_available` / `consent_unavailable` decides ("coming soon" words). *Cost if wrong:* none.

## For the lead

**Merge notes.** Session: my section is appended after the spike's (A's section may sit next to it).
`Session.online_server()` already uses D's `OnlineConfig.default_server()` once it is there (after the
merge the shim's fallback line can go). `NakamaLink` should use D's `OnlineConfig.key_for(server)` and
the lead's `ws.set_no_delay(true)` (both the match's link and the service's go through `NakamaLink`,
so one change covers both). Menu,
pause menu, HUD and sandbox changes are small sections; the pause menu's fit test now has a sibling
(`test_the_online_host_invites_from_the_pause_menu_and_it_still_fits`).

**Asks for other agents / later.**
- B: an `rtBefore("StatusFollow")` hook allowing follows of friends only (Nakama lets anyone follow a
  user id; a stranger who learns a child's id could see when they are online). B's `MatchJoin` code
  names reach the client as "match: <code>" (handled).
- B: notification 102 is "not sent yet" in B's module; the client removes a cancelled invite when it
  comes, and otherwise lets invites run out.
- A guest whose join fails goes back to the menu with no words (the spike's `disconnected`); A's
  plain-word errors could show `OnlineRules.message(Session's last error)` there.

**Check with two games** (emulator + desktop, B's module and `EASYCRAFT_CONSENT_PROVIDER=fake` on the
server; desktop with a private `XDG_DATA_HOME`):
1. Both: main menu → PLAY ONLINE → the stay-safe card → I WILL → the name → OK → HOME. A taken name
   (claim the same name on the second game) says so and can be changed.
2. Desktop → FRIENDS → type the emulator's name → ADD → "Asked!"; the emulator's HOME shows
   "FRIENDS 1 new"; YES; both lists show a green dot; quit one game → the other's dot becomes a ring.
3. Desktop → HOST MY WORLD → SANDBOX: "Your world is online!"; pause → INVITE FRIENDS → the emulator
   is listed → INVITE → INVITED. The emulator (menu, or its own solo world) shows the toast → JOIN →
   it joins the desktop's world (its own world saved first). The HUD dot shows on both.
4. Under-13 profile on one game: card → name → "Ask a grown-up" → GROWN-UP HERE → the sum in words
   → START → CHECK (the fake provider answers after ~2 s: "Not finished yet", then yes) → "Thank you!
   Online play is on." → DONE → HOME. Before that: no FRIENDS, no INVITE row, invites never show,
   and the other game can't find the child's name.
5. MORE → MUTE (their invites stop showing), REPORT → a reason → the report is in the console
   (collection `reports`), BLOCK → YES, BLOCK → gone from both lists.
6. The pause menu fits the emulator's screen with MONSTERS, FRIENDS and INVITE; the toast's JOIN
   doesn't build a block under it; Android Back from PLAY ONLINE returns to the main menu.
