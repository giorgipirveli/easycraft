# The Daily Mission, postcards, presents, friendship levels, study buddies and crews (owner #81, #82, #85)

The brief: `docs/superpowers/plans/2026-09-30-daily-mission-brief.md` (items 1-5), with the world game plan §1, §2, §2b, §3
(`docs/superpowers/plans/2026-09-29-world-game-plan.md`; its §2c is the "As built"). Spec §25.7. Branch
`worktree-agent-a51e645ed05a40e63`, cut from `lead-merge` at `4926ac50`. Server module **0.2.18** (from 0.2.17).

The owner: "we must bring more childrens here because they will become educated … bring referal programs which include
all possible motications" (#82), the research of the most successful programs (#85: Wordle's daily card, Pokémon GO's
friendship levels, Duolingo's study buddies, crews), and "remember this is educational game not just random game like
roblox" (#81). Everything here is learning-first: the daily card is a School challenge, friendship grows by learning on
the same day, the crew's goal is learning days, and nothing ranks children or punishes a rest day.

## What a child sees

- **The School's map** has a gold **TODAY'S MISSION** button in its header (Professor Hoot gives it his place there);
  after today's mission it says **MISSION DONE!**
- **Today's Mission** (`ui/daily/daily_page.gd`): "Today's Mission" with the date ("30 September 2026"), Professor Hoot,
  **"5 questions from your grade's subjects. The same mission for every grade 4 explorer today!"**, today's subjects as
  coloured tags (HISTORY, ART, ENGLISH, COMPUTING, CITIZENSHIP), from the second mission day on the last 7 days as gold
  stars (mission days) and sleeping moons (rest days) with their weekday letters and "3 mission days so far. Rest days are
  fine: your mission days never go down.", and **START** (after a STOP: **GO ON: 2 OF 5 DONE**).
- **The questions**: STOP, "Today's Mission", the subject, "1 of 5", then the School's own exercise panel (hints, a
  second try, the worked answer). No gold under the praise here: the mission has its own line.
- **The card**: a paper card, **EASYCRAFT DAILY MISSION**, "30 September 2026 - Grade 4", five drawn stars (gold for each
  right the first time, a soft circle for the others), **"Today's Mission: 4 of 5!"**, "Play and learn with me!", the
  invite code big (BLUE-OTTER-42) and the link; beside it "Great work! Every answer helps you learn.", **"+40 gold for
  today's stars!"** (the first time today, with a coin shower), the week's stars and moons, **SHARE** (where there is a
  share sheet: a browser's sends the words and the link, Android's the picture), **COPY** ("Copied! A grown-up can paste it
  in a message."), **SAVE PICTURE** (DOWNLOAD in a browser: "Saved to your Gallery!"), and **"Grown-ups: share today's
  mission card. It shows the stars, never the answers, and carries only the invite link."**; under it "A new mission
  comes every day, the same for your whole grade." Opening it again the same day shows the card.
- **Shared text** (COPY and a browser's SHARE): "EasyCraft Daily Mission, 30 September 2026, grade 4 / ⭐⭐⭐⭐⚪ Today's
  Mission: 4 of 5! / Come and learn with me in EasyCraft! My invite code: BLUE-OTTER-42 / the link" (Wordle's grid: no
  answers).
- **A unit mastered**: the round's end also shows **MAKE A POSTCARD** (once for that unit, ever); its postcard is a drawn
  picture (Professor Hoot in a teal sky of gold stars) with **"I mastered Big numbers!"** (or, for the subject's last unit,
  **"I mastered grade 4 maths!"**), "Play and learn with me! BLUE-OTTER-42", the link, SAVE PICTURE, SHARE, COPY, CLOSE and
  "Grown-ups: a postcard carries only its picture, its words and the invite link."
- **In a world** (when the lead wires the hook at a first landing): a small card top right, **"I landed on the Moon!"**,
  "What a moment! Make a postcard?", **POSTCARD** / **NO THANKS**; POSTCARD shows the postcard with the photo of the world
  over the game.
- **The main menu** has six buttons in its second row: SCHOOL, INVITE, **FRIENDS**, GOLD SHOP, AVATAR, SETTINGS.
- **FRIENDS** (`ui/social/friends_page.gd`), three tabs:
  - **FRIENDS**: "Cheer your friends" ("Mia_5 just landed on the Moon! Send a cheer?" with **AMAZING!** and **WELL DONE!**
    at one tap, and MORE: all six kind words, Well done!, Amazing!, You're a star!, High five!, So proud of you!, You did
    it!; "Cheers are kind words only. Your friend sees your name and the cheer."), then each friend: "Sam_22 - Great friends", "8 days together. 22 more days together to Best
    friends: a shared room in the colony dome", **GIFT**, **BUDDY?** (then "You asked: study buddies?"; the friend sees
    **BUDDY: YES**), for study buddies "Study buddies: 3 days learning together. This week: 2 days together" and STOP BUDDY.
    No friends yet: "No friends here yet. Add friends in PLAY ONLINE, or invite a friend: learning is better together!" and
    INVITE A FRIEND.
  - **PRESENTS (2)**: "Sam_22 sent you a buddy egg!" with a drawn egg and **OPEN** ("It hatched a secret buddy shape: the
    Jolly Snowman! Build it and wake it with the Magic Wand."), then **THANK YOU** ("Thank you sent! Your friend gets a
    small gift back."); "Give a present": "One present a day to each friend: 5 left today. Tap GIFT beside a friend.";
    **GIFT FOR A NEW FRIEND** ("A present for a new friend waits on your invite code: the next friend who joins with it
    opens it. 1 of 3 waiting."). The picker: ROCKET PART, SEEDS, BUDDY EGG, MAP PIECE, each with its picture and a line,
    and "Presents are free: one a day to each friend. Only the kind of present is sent."
  - **CREW**: "A crew is 2 to 6 friends who learn and explore together.", invitations ("Sam_22 asks you to join the Brave
    Comets (2 of 6)" JOIN / NO THANKS), **MAKE A CREW** (the name from FIRST WORD and SECOND WORD steppers, eight drawn
    badges, MAKE THE CREW); the crew page: its badge and name, "3 of 6 seats filled", each member's avatar with their name
    and week ("3 learning days. Mastered: Big numbers, Multiply bigger numbers", "Resting this week"), the goal bar and
    "This week together: 9 of 9 learning days. Goal reached!", **INVITE A FRIEND TO THE CREW**, **LEAVE THE CREW**.
- **Good news from your friends!** on the main menu's card, once: "Sam_22 cheered: Amazing! (you landed on the Moon)",
  "Sam_22 said thank you for the seeds! +10 gold", "Sam_22 sent you a buddy egg! Open it in FRIENDS.", "Bo_9 joined with
  your code and got your seeds!", "Sam_22 asks: study buddies? Say yes in FRIENDS.", "You and Sam_22 are Great friends now:
  a two-seat rover to drive together!", "Sam_22 asks you to join their crew! See CREW in FRIENDS.", "Sam_22 joined your
  crew!".

Pictures: `XDG_DATA_HOME=/tmp/easycraft-daily-shots godot --path . --disable-vsync --script res://tools/daily_shots.gd`
(15 PNGs: the map, the intro, a question, the card page, the card as SAVE gives it, the postcards, FRIENDS' pages).

## The numbers

| What | Number | Where |
|---|---|---|
| Daily Mission questions | 5, levels 1, 1, 2, 2, 3 | `DailyMission.SIZE`, `LEVELS` |
| Gold for a star in the Daily Mission | 10 (at most 50 a day, once a day) | `EarnRules.DAILY_STAR_GOLD` |
| Days of results kept | 60 (the count of mission days never falls) | `DailyData.KEEP` |
| Friendship levels | Good at 1 day together, Great at 7, Best at 30 | `SocialRules.LEVELS`, `FriendshipRules.LEVELS` |
| Presents sent a day | 5 in all, 1 to each friend | `SENDS_PER_DAY` |
| A friend's inbox | 20 not opened | `INBOX_MAX` |
| Presents waiting on the invite code | 3 | `LINK_GIFTS_MAX` |
| THANK YOU | 10 gold to the sender, 5 a day | `THANK_GOLD`, `THANKS_PER_DAY` |
| What a present gives | a Fuel Tank; 4 Wheat + 4 Flowers; a secret buddy shape (or 3 pet treats); a map piece | `FriendPresents` |
| Proud moments told a day | 5 (each friend's feed keeps 20) | `MOMENTS_PER_DAY`, `FEED_MAX` |
| Cheers a day | 30, six kind words | `CHEERS_PER_DAY`, `CHEERS` |
| Study buddies | 3 at most | `BUDDIES_MAX` |
| Crews | 1-6 members (2-6 once a friend joins), 20 × 20 name words, 8 badges | `CREW_*`, `BADGES` |
| The crew's weekly goal | 3 learning days per member (at least 2 members' worth); the week starts Monday UTC | `CREW_GOAL_PER_MEMBER` |
| Postcards offered | once per moment, 400 remembered | `PostcardRules.MAX_OFFERED` |

A day of learning (EarnRules) is about 275 gold; the mission's 50 at most is a fifth of it, a thank-you's 10 a small
sign.

## Rulings (decided without asking; what each costs if wrong)

1. **Server file names**: `src/rules/social_rules.ts` and `src/server/together.ts` (namespace `Together`), not
   `src/server/social.ts`: that file already holds M4's `invite_friend` and `report_user`. *Cost:* none.
2. **The GDScript class is `FriendPresents`**, not `PresentRules`: M3's progress presents own that name. *Cost:* none.
3. **"The same mission" is per UTC day and per version of the School**: a version that adds units picks differently.
   *Cost:* two game versions on one day show different missions; the card names the date and grade.
4. **The UTC day, not the child's local day** (the brief's seed): a child in Tbilisi (UTC+4) gets the next mission at
   04:00. *Cost:* local days are one line (`DailyMission.today`), but friends in other time zones would then compare
   different missions.
5. **The picks**: a seeded shuffle of the grade's subjects that have written units (a grade with three, like grades 7-8
   now, repeats two); a unit from the outline (never an Explorer lesson); its generators first, made at the slot's level
   (a generator makes any level), else its own exercise nearest the level; only the five units are read. *Cost:*
   constants in `DailyMission`.
6. **One mission a day**: STOP keeps the answers (GO ON goes on, the same mission all day); a finished day opens on its
   card; more practice is the School's. *Cost:* none; a "practise it again" is a button later.
7. **Gold**: 10 a star, once a day at the finish; no answer gold inside the mission (never paid twice). *Cost:* constants.
8. **The calm "streak"**: mission days that never go down and a week of stars and moons ("Rest days are fine"), never a
   run of days that breaks (the fair-fun rules reject streak loss, `docs/design/engagement-and-child-psychology.md` §7).
   *Cost:* less pull than Duolingo's streak, by design.
9. **The card's code** is `profile.invite.code` (known once INVITE, or the Daily page when signed in, read it); a device
   that never signed in shows the game's link only. *Cost:* a first card without the code.
10. **SHARE** is a browser's share sheet (the words and the link) or Android's (the picture), where `PhotoRules.may_share`
    allows (AUTO: on, age rules being off); COPY and SAVE PICTURE everywhere; a grown-ups' line on each card, no gate (the
    INVITE page shares the same way). *Cost:* a switch.
11. **Postcards are offered once per moment**, remembered on the account; the School's picture is drawn (no world), a
    world's is the screen (the lead's `before_photo` can hide the HUD). *Cost:* none.
12. **The grade's moment** is a subject's last written unit mastered in that grade ("I mastered grade 4 maths!"); it
    replaces that round's unit moment. *Cost:* none.
13. **Proud moments go to friends by themselves** (their feeds, ids only) whether or not the child makes a postcard; 5 a
    day; the Daily Mission's score is never one (it would invite comparing scores). *Cost:* a child can't keep a moment
    from friends yet (a switch later).
14. **"Learning together" = both learned on the same UTC day** (a School round finished or the Daily Mission done); being
    in one world isn't required: the server can't know it without trusting the game. *Cost:* friendships grow a little
    faster; a check against the match record later.
15. **A day together counts once a day per pair** (learning together, a present, a cheer); levels at 1, 7 and 30 days
    (Pokémon GO's 1/7/30/90 without the 90); days never fall. *Cost:* constants.
16. **Level rewards are hooks** (`friendship_badge`, `two_seat_rover`, `dome_room`): the rover and the dome don't exist
    yet; the page names them. *Cost:* words until they exist.
17. **Presents are free** (Pokémon GO's gifts, never bought) and give: a Fuel Tank (every rocket needs tanks; 15 gold of
    parts), 4 Wheat and 4 Flowers for the next Survivor world (the dome garden comes later), a secret buddy shape not found
    yet (else 3 pet treats), a map piece (a count for the prospecting quests: a hook). *Cost:* at most five friends' Fuel
    Tanks a day (~75 gold of parts); what each gives is one function.
18. **A present "for a new player" waits on the sender's invite code** (up to 3), not in the link: the next new friend who
    joins with the code opens it (`Referrals.use` → `Together.welcomePresent`). *Cost:* two friends joining the same day:
    the first gets it.
19. **THANK YOU pays the sender 10 gold** (5 a day), the thanker nothing; a guide's waiting present is thanked though they
    aren't Nakama friends. *Cost:* constants.
20. **Cheers are six fixed kind words**, never typed (no filter needed); two at one tap (AMAZING!, WELL DONE!: the brief's
    "one tap"), MORE for the rest; once per moment; 30 a day. *Cost:* none.
21. **Study buddies**: at most 3; ask, yes, no, stop (quietly); the shared goal is both learning something that day; days
    never fall; the week's row counts from the day they said yes, and a yes on a day both learned counts that day.
    *Cost:* constants.
22. **Crews**: 1-6 members (a new crew waits for a friend: "1 of 6 seats filled: invite a friend to learn with you!"), one
    crew each, names from 20 × 20 kid-safe words (all 400 pass the name filter), 8 badges, members' looks without the boy /
    girl choice, invitations to mutual friends only, the last one out removes it; the goal is 3 learning days per member
    (at least 2 members' worth) a week, Monday UTC to Sunday. *Cost:* constants.
23. **FRIENDS is a sixth main-menu button** (the row's buttons 182 px at font 26 so six fit at 16:9 and 20:9). *Cost:* a
    narrower row; a tab in INVITE instead would hide it.
24. **The School map's header gives Professor Hoot's place to TODAY'S MISSION** (he stays on every other page). *Cost:*
    none.
25. **Friends' news show once** on the main menu's card (the invite card; `"what": "text"`); the server forgets them.
    *Cost:* no news history.
26. **What waits for the server stays on this device** (days learned, units, moments: the backup merge keeps the local
    ones); postcards offered and map pieces travel with the account. *Cost:* a device that never signs in never tells
    friends.
27. **Learning that reaches the server late counts on that day** (the server's clock). *Cost:* a day together may land a
    day late.
28. **PC and controllers**: the in-world postcard card frees a PC's mouse (no new key: one would clash with jump or photo;
    the next click plays on); the KEYS card is unchanged. Every button is focusable for the controllers' focus; no focus is
    grabbed in a world (Space or A would press it). *Cost:* a click at a landing on a PC.
29. **The base's `test/integration/data_rights.server.ts` never parsed** (a stray test header, a merge leftover): fixed; 7 of
    7 on a real Nakama. *Cost:* none.
30. **The Science Lab's stars don't count as "learned today" yet** (School rounds and the Daily Mission do). *Cost:* one
    line in `LabScreen` (`SocialSender.learned`).

## Safety and privacy

- Only ids and kinds travel: a present is a kind, a cheer one of six ids, a moment a kind and a place id, a crew name two
  words from the lists. A friend sees another by their in-game name only. Nothing is typed.
- Everything is between Nakama's mutual friends who may be online; moments and presents of someone who is no longer a
  friend go away unopened; a guide's waiting present is the one exception (the invite joined them).
- The server keeps `together/me` per player (days together, learned days, the week's units, buddies, the feed, the inbox,
  presents waiting, counts, unseen news as ids, the crew's id, invitations) and `crews/<id>`, all server-only.
- Deleting an account (`delete_account`, the retention clean-up) first takes the player out of every friend's record and
  its crew (`Together.forget`, `together` in the answer), then its own record goes with its storage.
- No pressure: no timers, no countdown to the next mission, no streak that breaks, no ranking of children (the crew page
  shows each member's own week and the crew's goal together), no "invite or lose"; every word is checked by the tests for
  pressure and ranking words.

## Tests

- **Server** (`npm --prefix server/modules test`): **390 of 390** (`social_rules.test.ts` 12, `together_rpcs.test.ts` 13,
  every version test at 0.2.18). On a private Nakama 3.41 for this worktree (compose project `easycraft_dm`, ports
  7462-7464, removed after): `test/integration/together.server.ts` 3 of 3, `referrals.server.ts` 3 of 3,
  `data_rights.server.ts` 7 of 7; `gifts.server.ts` 6 of 7 (its bottle to an under-13 friend asks for a consent the
  module no longer needs since 0.2.13, age rules off: the under-13 checks the earn-invite notes list).
- **GDScript**: `test_daily_mission`, `test_daily_data`, `test_postcard_rules`, `test_gift_presents`,
  `test_friendship_rules`, `test_crew_rules` (unit), `test_daily_page`, `test_postcard_page`, `test_friendship_online`,
  `test_friendship_page`, `test_crew_page` (integration): 61 of 61; the related suites (School, menus, invite, profile,
  Gold Shop, online service): 225 of 225. **The full suite (2026-09-30 05:15, on commit 7016465c): 7,977 of 7,979 pass,
  2 risky (`test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`: the base's, they don't assert), no
  failures, no script errors** (872 scripts, 42 min on a PC running three other suites).

## Hooks (for the lead and the next briefs)

- **First landings**: `PostcardOffer.offer(_layer, PostcardRules.landed("moon"))` at `RocketFlight.landed` or
  `sandbox.mission_arrive` when `Profile.data.missions.fly(u)` was the first flight there (a place id: `moon`, `mars`, …;
  `PostcardRules.PLACE_NAMES` has the names); Android Back: `offer.close_if_open()`; `before_photo` / `after_photo` to
  hide the HUD for the picture. A mission complete: `PostcardRules.mission(place)`.
- **Wonders and deposits**: `PostcardOffer.offer(parent, PostcardRules.stamp(wonder_id, "the Great Pyramid"))`,
  `PostcardRules.deposit("gold")`.
- **Friendship rewards**: `FriendshipRules.LEVELS[].reward` (`two_seat_rover`, `dome_room`) with `social_state.friends[]
  .level`; **crew rocket and flights**: `social_state.crew` (`id`, members); **map pieces**: `profile.social.map_pieces`.
- **More daily kinds** (a map puzzle, a rocket problem): `DailyMission.plan` is the one place.

## For the lead: deploy and check

1. **Server**: deploy module 0.2.18 (the kit builds `server/modules`); `healthcheck` says 0.2.18; run
   `EASYCRAFT_SERVER=… node --test test/integration/together.server.ts` (and `referrals.server.ts`) against it.
2. **Web**: rebuild and deploy (nothing web-specific changed; SHARE uses the browser's sheet, SAVE PICTURE downloads).
3. **Wire the landing postcard** (above) when the flight is merged.
4. **Emulator / browser**: the School's TODAY'S MISSION, five questions, the card (Android SHARE opens the share sheet
   with the picture; SAVE PICTURE → "Saved to your Gallery!"); a unit mastered → MAKE A POSTCARD; the main menu's row of
   six fits at 16:9 and 20:9; FRIENDS with two accounts: a present sent, opened (the thing arrives) and thanked (+10 gold on
   the sender's card), a cheer, study buddies, a crew made, joined and left.
5. **Owner feedback**: #81, #82, #85 for `docs/playtests/owner-feedback.md` (the Daily Mission, postcards, gifts,
   friendship levels, study buddies, crews: the tests above).
6. **Rulings to confirm**: 4 (UTC day), 13 (moments go to friends by themselves), 14 (learning together = the same day),
   17 (what presents give), 23 (FRIENDS on the main menu).
