# Crew flights: friends fly the rocket together — the agent brief (owner #78, #79; spec §21d.6 phase 2)

You are building **crew flights** in EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools), a game for children. The
owner (#78): "we have to have a mission to mars, mission to moon and etc. where you must build a ship, rocket to get into
planets, **which can be built by team or alone**"; (#79) "when ship is built, you just sit into it at steering wheel and
fly to moon, you actually fly into moon". Phase 1 exists: friends in a shared world build on the pad together and see the
check, but LAUNCH flies only the host, and the host's travel closes the session (`Session.close()` in
`sandbox._travel_space`), so the friends are dropped to the menu. Phase 2 is yours: **the whole crew flies together and
lands together.** Work autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in
your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec **§21d (missions; your part is 21d.6)**, §25.3 (the flight), §17
   (online play: sessions, hosts and guests, rejoin, the network words) and `docs/design/` (fair fun). Study what
   exists: `scenes/sandbox.gd` (`launch_rocket`, `_fly_mission`, `fly_rocket`, `mission_arrive`, `_travel_space`,
   `is_client`), `LaunchDirector` and the Mission Board, `RocketCheck` (seats), `RocketFlight` and the cockpit,
   `MissionRules` (`launch_refusal`, `launched_words`), `autoloads/session.gd` (hosting a LAN or online world, joining,
   `RejoinRules`, `net_notice`, the relay), `OnlineService` (matches, invites), `tools/net_test.gd` + `tools/net_test.sh`
   (two headless games, host and guest, against a local or the live server).

## Allocation
- New files: `core/missions/crew_*.gd` (pure rules), `ui/missions/crew_*.gd`, tests `tests/**/test_crew_*.gd`, notes
  `docs/devlog/parts/crew-flights.md`. No block ids, no atlas pages.
- Careful additions elsewhere (the lead reviews each): `scenes/sandbox.gd` (the launch and the arrival), `session.gd`
  (following the host into its new world), `MissionRules`, `RocketFlight` (a seat per crew member, if needed),
  `tools/net_test.gd`/`.sh` (a `--crew` scenario). Never touch the School, the colonies, the wonders, Venus's world,
  prospecting or the invite server code (other agents), except to call what they offer.

## What to build
1. **The crew call.** The host presses LAUNCH with friends in the world: everyone gets a card with a countdown (about
   10 s): "Anna is launching to the Moon! Take your seat." with TAKE MY SEAT and STAY HERE. The check counts the crew:
   the capsules' seats must fit everyone who takes a seat (kind words when they don't: "3 friends want to fly and the
   rocket has 1 seat: add crew capsules!"; the host may then fly with fewer). A guest who stays goes back to the menu
   with kind words (the world is flying away). A guest still never launches the host's rocket (phase 1's rule stays).
2. **Flying together.** Every crew member sees the real flight from a seat in the capsule (`RocketFlight` from the same
   rocket description on each device, started together; the host's flight is the one that counts; a guest's view
   follows the host's steering, never its own; a guest's device that is slow never holds the others up). Crew
   members see each other in their seats (avatars) and the chat works on the way.
3. **Landing together.** The host's world moves to the destination (`_travel_space`), and the crew follows into the
   host's new world automatically (no menu, no invite, no code: the session carries them; LAN and online both). The
   landing words, the guide card, the postcard offer: for everyone. If a guest cannot follow (the internet dropped),
   it gets `NetWords`-style kind words and the menu, never a hang.
4. **Everyone's mission counts.** Each crew member's own profile flies the mission (`Profile.data.missions.fly(u)`:
   the route, the Space Book, the Moon's first-landing reward to its inviter, `InviteRules.friend_landed("moon")`, #79)
   and gets a **crew badge** ("Crew of the Moon mission with Anna and Sam": in the Space Book or the missions' log,
   names only for friends, as everywhere). Nothing pays twice.
5. **Home together.** HOME from the destination with a crew brings the crew home the same way (the host's HOME; a
   guest's HOME leaves the crew alone and kindly).

## Tests and checks (TDD)
Failing tests first: the crew rules (seats vs takers, who flies, the words), the crew call's flow (a fake session: take
a seat, stay, the countdown), the mission credit for each member, the follow step. Then **`tools/net_test.sh --crew`**:
two headless games (host and guest) on a local server: the host places a rocket that passes the check with 2 seats,
the guest takes its seat, both fly, **both are in the host's Moon world** after the landing, and HOME brings both home:
PASS; also `--crew --drop=close` (the guest's link drops mid-flight: kind words, no hang). Run the existing net tests
too (`--big`, `--freeze`, `--drop=close`, `--drop=dead`): all PASS. `--import` and grep Parse Error after new
class_name scripts; single tests with `tests/run_tests.sh -gtest=…`; the FULL suite once at the end. Never open the
editor or an emulator; never touch adb; never use the live server for anything but reading. Never merge or push. Never
run more agents. If the server must change, bump the module version and say so (the lead deploys it).

## Finish
Notes (rulings, what a child sees step by step, the net tests' output, what the lead must check with two real browsers
or devices); spec §21d "As built" (phase 2); `docs/DEVELOPMENT.md` (the `--crew` test); commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what a child sees, the
net tests' and the full suite's results, what the lead must look at.
