# Crew flights: friends fly the rocket together and land together (owner #78, #79; spec §21d.6 phase 2, §21d.9)

The owner: "we have to have a mission to mars, mission to moon and etc. where you must build a ship, rocket to get into
planets, **which can be built by team or alone**" (#78); "when ship is built, you just sit into it at steering wheel and
fly to moon, you actually fly into moon" (#79). Phase 1 (the missions) let friends build on one pad, but LAUNCH flew only
the host, and the host's travel closed the session: the friends were dropped to the menu. Phase 2, here: **the whole crew
flies together and lands together.** Brief: `docs/superpowers/plans/2026-09-30-crew-flights-brief.md`. Built by a worker
agent in its own worktree (branch `worktree-agent-a98b95cbb2af171e7`, reset to `lead-merge` 062fe26e), without the editor,
an emulator or adb; checked with GUT and two headless games (`tools/net_test.sh --crew`) over LAN and over the lead's
local development server (127.0.0.1:7350; nothing ran against the live server). **No server change** (the relay carries
everything; no module version bump).

## Allocations (used)

| What | Where |
|---|---|
| New code | `core/missions/crew_flight_rules.gd` (CrewFlightRules), `crew_call.gd` (CrewCall), `crew_badges.gd` (CrewBadges): pure; `ui/missions/crew_flights.gd` (CrewFlights, the flow on every game), `crew_call_card.gd` (the call's card), `crew_seats.gd` (the crew in their seats) |
| Tests | `tests/unit/test_crew_flight_rules.gd`, `test_crew_call.gd`, `test_crew_badges.gd`, `test_crew_follow_run.gd`; `tests/integration/test_crew_flights.gd` (the flow over a fake session), `test_crew_session.gd`, `test_crew_flight_follow.gd`, `test_crew_board_badges.gd`: 70 tests |
| Careful additions (the lead reviews each) | `scenes/sandbox.gd`: `_setup_crew()` in `_ready`, `_crew_local()` after `_rocket_local()`, `launch_rocket` (friends here: `crew.launch`), `mission_arrive` (`crew.landed`), `fly_rocket`/`_rocket_refusal` (a crew flight is not refused for friends), `_start_flight` (a crew member's `landed` only fades), `_rocket_take_over` (the chat back), `_travel_space`/`_travel_sandbox`/`_travel` (`_close_or_move` instead of `Session.close()`), `go_home_from_space` (the crew's HOME, a guest's HOME), `_start_host_or_solo` (a moved world keeps hosting), `_goodbye(words)`, the board's `badges`, and the section "Spec §21d.6 phase 2: crew flights" at the end. `autoloads/session.gd`: `_rpc_hello` split into `_answer_hello` (held while the world moves), `close()` forgets crew state, and the section "Crew flights" at the end (the messages). `entities/flight/flight_run.gd`: `snapshot()`, `follow()`. `entities/flight/rocket_flight.gd`: `crew_follow`, `pilot`, `seat`, `crew_size`, `crew_state()`, `follow_pilot()`, `SEAT_GAP`. `ui/flight/flight_cockpit.gd`: `crew_member`, `keys_free`. `core/rules/mission_data.gd`: `crews` (CrewBadges: to_dict, from_dict, merge_from, is_empty). `ui/missions/mission_board.gd`: `badges` (a ★ line on a mission's card). `tools/net_test.gd`, `tools/net_test.sh`: `--crew` |
| Block ids, pages, HUD spots | none (the crew's seats sit inside the cockpit, down its right side under OUTSIDE) |
| Never touched | the School, the colonies, the wonders, Venus's world, prospecting, the invite server code, the social Crews (`core/social/crew_rules.gd`, `CrewRules`: another thing; the flight's crew classes are named `Crew…Flight…`, `CrewCall`, `CrewBadges`, `CrewSeats`) |

## What a child sees, step by step (Anna hosts, Sam joined her world; online or on the home Wi-Fi)

1. **Building together** (phase 1, as before): both place rocket parts on Anna's pad; the Mission Board's MY ROCKET
   checks the rocket (for its pilot).
2. **Anna presses LAUNCH TO THE MOON!** The board closes. Anna's card: "Calling your crew to the Moon!", a big yellow
   countdown from 10, a line per friend ("Sam …" → "Sam takes a seat!" or "Sam stays here."), LAUNCH NOW and NOT YET.
   Sam's card, over his world, read aloud: **"Anna is launching to the Moon! Take your seat."** with **TAKE MY SEAT** and
   **STAY HERE** and the same countdown. Sam taps TAKE MY SEAT: "Your seat is ready! Lift-off soon…".
3. **Not enough seats?** If Sam and Mia both take a seat and the rocket has one capsule, Anna's card says **"2 friends
   want to fly and the rocket has 1 seat: add crew capsules!"** with FLY ALONE (or FLY WITH 1 FRIEND when one fits) and
   ADD CAPSULES FIRST; the friends' cards say "Anna is checking the seats…". ADD CAPSULES FIRST: "The launch waits: build
   more crew capsules together!" on everyone's card (air and water count too: 2 astronauts to Mars need a service module
   each: "2 astronauts need air and water for the whole trip: add a service module!").
4. **Lift-off, together.** Everyone who took a seat (and anyone who never answered: ruling 2) sits in the capsule of the
   same rocket on the same pad, on their own screen: the camera glides into the capsule, the countdown, the fire and
   smoke, the clouds, the stages falling away, orbit, the Moon growing, the landing, all of it the pilot's flight.
   Anna flies (throttle, STAGE, BURN, LEGS, steering). Sam's cockpit has the dials, the hologram, OUTSIDE/INSIDE and MENU
   but no throttle, ACTION or SKIP; its words say what the pilot does: "Climb in and buckle up! Anna is the pilot, you
   are the crew.", "Anna pushes the throttle up. Hold on tight!", "Anna lets the empty stage go!", "Anna fires the engine.
   Off we go!", "Anna puts the landing legs out!"; the story's own words ("We are in orbit!…") are everyone's; his view
   follows Anna's steering. Down the right side of every crew member's cockpit: **the crew in their seats**, each avatar
   sitting in its own seat with its name (PILOT on Anna's, YOU on Sam's own) and a **WAVE** button: Sam's avatar waves on
   Anna's screen too. The **chat** rides on the cockpit (the CHAT button, quick phrases, typed words for 13+): "Look!".
   Friends who stayed (or had no seat) see "Anna's world is flying to the Moon, so back to the menu for now. Build a
   rocket together next time!" and go to the menu.
5. **Landing together.** Anna's rocket touches down; the screens fade. Sam: "Landing with your crew…"; a moment later he
   stands with Anna by the Moon's landing pad in **Anna's Moon world**: "Mission complete! You landed on the Moon! Jump:
   you float!", the explorer's guide card, the postcard offer (once per place), the lander by the pad. No menu, no
   invite, no code. Seven seconds later: **"New crew badge: Crew of the Moon mission with Anna!"** (Anna's says "…with
   Sam"). The Moon is on Sam's own route now (his Star Map's LAND works for it), his Space Book marks it, and his first
   Moon landing pays his inviter (#79), once. At his own Mission Board, the Moon's card shows "★ Crew of the Moon mission
   with Anna".
6. **Home together.** Anna flies up to the Star Map and taps HOME: "Flying home with your crew…" for Sam, and both stand
   in Anna's Green Meadows world again ("Back home with your crew!"). If Sam taps HOME instead: "You flew home on your
   own. Your crew stays on the Moon: see you soon!", and he is in his own Green Meadows world; Anna stays.
7. **When the internet drops mid-flight** (online): Sam sees "The internet went away. Trying again…"; back in (the same
   45 s window as any rejoin), he is put back in his seat and his flight goes on at Anna's step; if Anna landed
   meanwhile, he comes back straight into the Moon world (and his mission counts there). If he can't come back: "We
   couldn't get back into your friend's world. Back to the menu for now!". If following Anna's world fails: "We couldn't
   follow your crew this time. Back to the menu for now!", after 75 s at most: never a hang.

## How it works (for the lead)

- **The call** (host, `CrewFlights.launch` from `sandbox.launch_rocket` when friends are here): `CrewCall` (pure: the
  answers, the countdown, the takers in the order they answered, `CrewFlightRules.room`: the whole `RocketCheck` with
  1 + k astronauts) → GO / CHOOSING / CANCELLED. GO: the pilot's own flight first (`sandbox._crew_pilot_fly`:
  `fly_rocket` with `"crew": true`, not refused for friends here), then `Session.crew_board` to each crew member (the
  rocket with its pad `origin`, the seat, the crew `[{peer, name, look, seat}]`), `crew_leave` to the others.
- **The flight**: the pilot's `RocketFlight.crew_state()` (`FlightRun.snapshot()`: step, time in it, action done,
  stages let go, burn, autopilot burn, throttle; and the aim) goes to the crew every 0.25 s; each crew member's
  `RocketFlight` (`crew_follow`, `sandbox._crew_fly`) runs `FlightRun.follow(delta, snapshot, upto)`: behind → straight
  to the pilot's step; in it → time runs to `upto` (`CrewFlightRules.upto`: the pilot's time plus the time since its word,
  at most 1 s) and holds; far behind (> 0.5 s) → jumps; an action only when the pilot's is done; the last step's end →
  `landed` (the sandbox only shows "Landing with your crew…"). The seats: `CrewSeats` in the cockpit; WAVE:
  `Session.crew_wave` (the host tells everyone). The chat: `sandbox._lend_chat` moves the HUD's ChatPanel over the
  cockpit (under the pause menu) and back when the flight ends; `FlightCockpit.keys_free` lets keys through while the bar
  is open.
- **The move** (host, `_close_or_move` in `_travel_space`, `_travel_sandbox`, `_travel`): `Session.crew_move(u, home,
  crew)` tells every guest and starts holding hellos; the host waits for its guests to let go (`crew_guests_gone`, at
  most 2 s; measured 28-214 ms), frees their old bodies, stops its viewers and drains the voxel queue (as a guest's rejoin
  does), then `Game.start_world(...)` with `Game.net_mode = &"host"` again. The new sandbox sees `Session.crew_moving()`:
  it keeps the match or the LAN server (no `host_online`/`host_lan`), and when its player stands (`host_spawn` set)
  `Session.crew_world_ready()` answers the held hellos (`_answer_hello`: universe, game, terrain, then world_info).
- **The follow** (guest, `CrewFlights._on_moved` → `sandbox._crew_follow`, deferred): the landing's statics
  (`SpaceDirector.landing`, `mission_landing`, the lander's `FlightTicket.parked`), `Session.crew_follow_leave()` (online:
  `_a_drop_link`, a waiting peer; LAN: the ENet client closes; `online_config` and `Game.join_address` stay), viewers
  stopped, the queue drained, then `Game.join_lan_game(Game.join_address)`: the ordinary guest join (online:
  `join_online(match_id)`) into the host's new world. `CrewFlights.following` carries "Landing with your crew…" into the
  new scene and the crew token (the old peer id) for the welcome; `Session.crew_following()` has a 75 s deadline.
- **The welcome** (host, destination world): a crew member's `client_ready` (online: the same peer id) or its
  `crew_arrived(token)` once it stands (LAN: a new peer id) → `crew_welcome(peer, u, mates)` once → the guest's
  `sandbox._crew_credit(u, mates, true)`: `MissionData.fly(u)` (+ `InviteRules.friend_landed("moon")` the first time) and
  `MissionData.crews.add(u, mates)`. The pilot: its mission in `mission_arrive` as before, its badge in
  `CrewFlights.landed` (`_crew_credit(…, false)`), shown in the new world.

## Rulings (the owner's rule: decide and write down; cost if wrong)

1. **The pilot's flight is the one that counts; the crew's follow it by its word 4 times a second** (not by starting at
   the same moment and running alone): slow devices catch up, fast ones wait, nobody holds the pilot up. *Cost:*
   `CrewFlightRules.STATE_EVERY`, `FOLLOW_AHEAD` (1 s), `CATCH_UP` (0.5 s).
2. **A friend who never answers the call comes along** (nobody is left behind for reading slowly; STAY HERE is a
   choice). *Cost:* `CrewFlightRules.UNANSWERED_TAKES`.
3. **The call is 10 s**; LAUNCH NOW decides at once, NOT YET ends it; a friend who arrives during the call is called with
   the time left; one who leaves is not waited for. *Cost:* `CALL_SECONDS`, `CrewCall`.
4. **The crew fits when the whole check passes with everyone** (a seat each, and air and water for everyone): the words
   name the seats first, then the supplies. The first to take a seat get the seats; the pilot chooses FLY WITH N (FLY
   ALONE) or ADD CAPSULES FIRST (the launch waits for everyone). *Cost:* `CrewFlightRules.room`, `short_words`,
   `CrewCall.choose`.
5. **The Mission Board still checks for the pilot alone** (crew = 1), so LAUNCH works when friends only watch; the crew's
   seats are checked at the call. *Cost:* `MissionBoard.crew` stays 1.
6. **Friends who don't fly leave for the menu when the rocket lifts off**, not when they answer (the pilot may still wait
   and add capsules). *Cost:* `CrewFlights._go`.
7. **A crew member's cockpit has no throttle, ACTION or SKIP**, and a drag never steers; OUTSIDE/INSIDE and MENU stay; its
   words say what the pilot does. Its inside camera sits `SEAT_GAP` (0.35 m) to the side per seat. *Cost:*
   `FlightCockpit.crew_member`, `CrewFlightRules.crew_words`.
8. **The crew in their seats are drawn in the cockpit** (the game's avatar figures sitting, names, PILOT/YOU, WAVE), not
   3D bodies in the capsule: the capsule has no 3D inside yet (the flight's Next: a 3D cockpit). *Cost:* `CrewSeats`.
9. **The chat rides on the cockpit** (the HUD's own ChatPanel, lent): a PC's T key does not open it mid-flight (the
   cockpit takes the keys), the CHAT button does, and typing works while the bar is open. *Cost:* `sandbox._lend_chat`,
   `FlightCockpit.keys_free`.
10. **The host's world moves without closing the session; each guest leaves its link and joins the same match or LAN
    host again as a fresh guest scene** (the tested join), rather than keeping its connection through a scene change
    (the host's new world would spawn into a guest scene that is not there yet). A join each move: 1.8-4.3 s measured
    from the guest's new scene to standing. *Cost:* the Session crew section and `sandbox._crew_follow`.
11. **The host holds every hello while its world moves** and answers them when its new world stands; it waits up to 2 s
    for its guests to let go before switching, frees their old bodies (a fast rejoin never gets its own old body from the
    old world) and drains the voxel queue (no task finishes into a world already gone). *Cost:* `crew_hold_hello`,
    `crew_guests_gone`, `CREW_LET_GO_SECONDS`, `_close_or_move`.
12. **Everyone in the host's world follows it when it moves** (the session carries them), crew or not; only the crew's
    missions count (a friend who joined during the flight did not fly). *Cost:* `CrewFlights._welcome`.
13. **LAN gives a new peer id on the way**: a crew member names its crew seat (its old id, the "token") when it stands in
    the new world; online the id stays. *Cost:* `Session.crew_arrived`, `CrewFlights.following.token`.
14. **The HOST's HOME from any away world with friends brings them along** (not only after a crew flight); the Star Map's
    LAND with friends stays refused (space needs a mission: a crew flies there). *Cost:* `go_home_from_space`,
    `CrewFlights.moving_crew(true)`.
15. **A guest's HOME goes home on its own, kindly**: the words, then the guest's own world of the mode in Green Meadows
    (universe 1; a guest has no saved take-off column in someone else's world). *Cost:* `sandbox._crew_guest_home`.
16. **Following has a deadline of 75 s** (a rejoin's 45 s window plus the new world's loading), then kind words and the
    menu. *Cost:* `CrewFlightRules.FOLLOW_SECONDS`.
17. **Names are the ones the world shows** (the host's word, `Session.chat_names`; online the server's), "A friend" when
    there is none; the badge keeps them as shown. *Cost:* `CrewFlightRules.shown_name`.
18. **One badge per world and crew** (the same names in any order to the same world), at most 60 kept (the oldest go
    first), names cut to 24 letters, 5 mates at most; in `MissionData.crews` (the profile: backed up, the merge a union).
    *Cost:* `CrewBadges`.
19. **Nothing pays twice**: a crew member's mission counts on its welcome (`MissionData.fly` is true once, and
    `InviteRules.friend_landed` only for a first Moon mission); the pilot's as before in `mission_arrive`. *Cost:*
    `sandbox._crew_credit`.
20. **Each crew member's lander stands by the pad on its own screen** (a model of this game: two landers side by side
    for two crew members' views of the same place is accepted). *Cost:* `FlightTicket.parked` per game.
21. **A crew member whose link drops mid-flight rejoins and boards again** (online, RejoinRules as ever); the host keeps
    its seat. LAN has no rejoin: the menu with the usual words. *Cost:* `CrewFlights._on_client_ready`.
22. **A LAN crew member's Survivor bag starts again in the new world** (a new peer id, as when any LAN guest joins
    again); online it comes along (Session keeps it by the same id). *Cost:* a stash by the crew token (not built).

## Checks

- **GUT**: 70 tests in 8 files (`tests/**/test_crew_*.gd`): the rules, the call (take a seat, stay, the countdown,
  too few seats, the choice, arrivals and departures), the badges and their save and merge, the follow of a run (behind,
  in step, waiting for the pilot's action, a whole trip, a SKIP), the flow on both games over a fake session, Session's
  hold and follow, two RocketFlights (the crew's lands with the pilot's, no controls, the pilot's steering, a seat each),
  the board's ★ line. Plus the existing flight, mission and session tests: unchanged and passing.
- **`tools/net_test.sh --crew`** (online, the local server) — PASS, errors=0 on both games:
  ```
  NETTEST host PASS crew rocket 45 parts in 3 stages, 2 seats, 15.43 km/s
  NETTEST host PASS crew call calling [1270492035]
  NETTEST guest PASS crew card "NetHost is launching to the Moon! Take your seat." (TAKE MY SEAT, STAY HERE)
  NETTEST host PASS crew launched with the crew [1270492035]
  NETTEST guest PASS crew flying seat 1 of 2, the pilot NetHost, controls hidden: true, seats shown: true, the chat over the cockpit: true
  NETTEST host PASS crew chat "Look!" from Player on the way
  NETTEST host PASS crew wave the guest waves from its seat on the pilot's cockpit
  CREW guests let go in 59 ms (0 still here)
  CREW world ready: 1 hellos answered
  NETTEST host PASS crew landed together both players in the host's Moon world (16), 1.6 s after the host
  NETTEST guest PASS crew followed into the host's Moon world; its flight reached step 11 of 12
  NETTEST guest PASS crew counts the Moon on its route, badge "Crew of the Moon mission with NetHost"
  NETTEST host PASS home together both players back in Green Meadows
  NETTEST guest PASS crew home back in the host's Green Meadows world
  net_test: PASS (online)
  ```
  The guest's join into each new world (ms since its new scene started): sign_in 34-49, socket 67-82, joined 84-233,
  world_info 880-1517 (the hello held until the host's world stood), standing 1941-3611.
- **`tools/net_test.sh --lan --crew`** — PASS, errors=0 (the guest came back as a new peer: `CREW welcome 1364132352
  (crew member 1298516201) on 16`).
- **`tools/net_test.sh --crew --drop=close`** — PASS, errors=0: "dropping the link (close) mid-flight" at the ascent,
  "PASS crew back on board 3.0 s after the drop", then the landing, the badge and home as above.
- The existing net tests (plain, `--lan`, `--big`, `--freeze`, `--drop=close`, `--drop=dead`): see "Existing net tests"
  below.
- On the way, two kinds of engine noise were found and removed: the guest's last body syncs reaching the host's next
  world ("Node not found: Sandbox/Players/<id>/Sync": the host now waits for its guests to let go), and Voxel Tools'
  "Condition !is_inside_tree() … get_global_transform" when a world with queued voxel tasks is freed (the host now
  drains first on a crew move; the same messages show in a solo world switch too: `tools/mission_smoke.gd`'s run on this
  branch printed them when it opened its Survivor world; pre-existing, not touched).

## What the lead must check with two real devices (or two browsers)

1. **The call's card** on a phone and in a browser: the words read aloud, the countdown, TAKE MY SEAT / STAY HERE big
   enough; the pilot's card lines; a game controller's focus on the card (PadFocus).
2. **The follow on real networks**: two phones online through the live relay (a real invite: `--invite` accounts are
   friends), and two devices on the home Wi-Fi (LAN): the landing, the "Landing with your crew…" card, standing together
   by the Moon's pad, the words, the guide card and the postcard offer on both, the badge toast on both.
3. **The crew's flight on a slow phone**: the crew member's flight keeps up (catch-ups are small jumps), never ahead of
   the pilot, the fade and the move on time; frame rate in the cockpit with the seats drawn (≥ 30 FPS budget).
4. **The seats' look** (the avatar figures sitting, names, PILOT/YOU) at a phone's size and on a PC; WAVE seen on the
   other device.
5. **The chat in the rocket** on a phone (the CHAT button over the cockpit, the keyboard, the quick-chat wheel) and on a
   PC (click CHAT, type, Enter sends; the rocket's keys come back when the bar closes).
6. **HOME together** and a **guest's HOME alone** on real devices; **a phone's internet off mid-flight** (airplane mode
   for 10 s): back in its seat; and off for more than 45 s: the kind words and the menu.
7. A **3-friend crew** on a 1-seat rocket: the pilot's choice card, FLY ALONE / ADD CAPSULES FIRST, the left-behind
   words on the friends' devices.

## Existing net tests (after every change here; one at a time, the local server)

| Run | Result |
|---|---|
| `tools/net_test.sh` | PASS (online), errors 0 / 0 |
| `tools/net_test.sh --lan` | PASS (lan), errors 0 / 0 |
| `tools/net_test.sh --big` | PASS (online), errors 0 / 0 |
| `tools/net_test.sh --freeze` | PASS (online), errors 0 / 0 |
| `tools/net_test.sh --drop=close` | PASS (online), errors 0 / 0: "rejoin back in 2.8 s, 0.0 m from where it was, D seen" |
| `tools/net_test.sh --drop=dead` | PASS (online), errors 0 / 0: "rejoin back in 2.1 s" |

A flake seen once: `tests/integration/test_flight_cockpit.gd`'s `test_a_drag_steers` failed ("dragged a full reach left")
in a batch of single files run while two net-test games loaded the PC; it passed in four reruns (alone, in pairs with
each crew file, and the same batch again).

## The full suite (once, at the end: `tests/run_tests.sh`, 45 min on the shared PC, load 13-14)

8611 tests, **8607 passing, 2 failing, 2 risky/pending**; both failures are timing flakes outside this work:
- `tests/integration/test_avatar_models.gd` `test_air_jumps_flip_and_come_back_upright` ("BlockyAvatar flips forward":
  -0.17 < -0.3): passed when rerun alone.
- `tests/integration/test_world_sync.gd` `test_a_change_while_a_saved_chunk_is_compared_off_the_main_thread_reaches_the_guest`
  (its 15 s wait for "a saved chunk is being compared" timed out, then `diffing()[0]` on an empty array: the run's only
  SCRIPT ERROR): rerun alone it passed 3 of 5 times on this branch and 3 of 4 times with `lead-merge`'s own
  `session.gd` and `sandbox.gd` put back: the same flake before this work (the comparison window is a race with the
  worker threads).

## Next (the game never ends, #71)

A 3D capsule interior with the crew sitting in it (and seeing each other's avatars in 3D); the Star Map's LAND for a
crew (a landing together on a planet already on the route); the lander on each planet's pad flying the crew home; the
social Crews' (§25.7) crew rocket (their crew's name on the badge); a LAN crew member's Survivor bag carried by its crew
token; crew flights to planets with a long cruise where the crew can do jobs (the navigator, the engineer), not only
watch.
