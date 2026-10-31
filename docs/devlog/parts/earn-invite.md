# Earn gold by learning, invite a friend, the Gold Shop (owner #79, #81, #82, #83, #85; spec §25)

The brief: `docs/superpowers/plans/2026-09-29-earn-invite-brief.md` (items 1-6), with the world game plan §1-§2b.
Branch `worktree-agent-a5ab0068a22292a64`, cut from `lead-merge` at `13c53019`. Server module **0.2.16**.

## What a child sees

- **In the School**, an answer right the first time says, under Professor Hoot's praise, in gold: **"+5 gold: right the
  first time!"**; the round's end says **"+30 gold for answers right the first time!"** and, the first time a unit is
  mastered, the old **"+100 gold for Survivor, and the … badge!"**. After 150 gold of answers in a day: **"That's all the
  answer gold for today. Your stars and badges still count!"** STOP keeps the gold earned (the round's stars are not
  recorded, as before).
- **In the Science Lab**, a new star: **"A star for your Lab Book! +25 gold!"** (once per experiment).
- **The main menu** has one row: **SCHOOL, INVITE, GOLD SHOP, AVATAR, SETTINGS** (212 px each; on the screen at 16:9 and
  20:9).
- **INVITE** (`ui/invite/invite_page.gd`): "Invite a friend", "Bring a friend to school! When your friend learns a whole
  unit, you both get gold."; **Your invite code** big on a paper card (e.g. **BLUE-OTTER-42**), the link
  (`https://178-104-20-64.sslip.io/play/?invite=BLUE-OTTER-42`), **COPY LINK** ("Copied! A grown-up can paste it in a
  message."), **SHARE** (a browser's own share sheet, where it has one), **QR CODE** (the link as a QR code another phone's
  camera reads: "A grown-up points another phone's camera here."); "Your friend gets 100 gold at once. When they learn a
  whole unit: you +250 gold, them +50."; **Your explorers**: "2 joined, 1 learned a whole unit", the friends by their
  in-game names ("Sam_22 - learned!", "Bo_9 - joined", "A new explorer" for one with no name yet), **"Your tree: 5
  children learning"**, the rank ("Mentor: a Mentor star and a crew badge") and the next ("Next: Trail Guide, 2 more
  friends who learn"), "Gold from friends so far: 500  (this month 2 of 10 friends)", a friend who brought friends shows how many ("Sam_22  - learned!  (brought 2)", never who), the class and family counts; **"No one to invite? That's fine:
  every lesson, rocket and world is yours to play."**; the grown-ups' line **"For grown-ups: invite links carry no personal
  information. EasyCraft never reads contacts and never asks for a friend's name, e-mail or phone number."**; **I HAVE A
  CODE** (a new account that has not used one); **GROWN-UPS** (the parent gate, then class and family codes: MAKE A CLASS
  CODE / MAKE A FAMILY CODE, the code, "N explorers, M learned", STOP THIS CODE).
- **At the start**, after the name: **"Did a friend give you an invite code?"** ("It looks like BLUE-OTTER-42. A code is
  all it needs: no names, no numbers."), the box filled in from the web link's `?invite=`, **NO CODE** / **OK**; then
  "Welcome, explorer! Alex_7's code brought you +100 gold." (or "Welcome to the family! +100 gold.") and CONTINUE; without
  the internet: "We'll check the code the next time you're online." Then BOY / GIRL / JUST ME as before.
- **SETTINGS → HELP**: **FRIEND'S CODE** (the same box, BACK instead of NO CODE), while no code was used.
- **Good news** on a card over the main menu, once: **"Your friend Sam_22 joined and learned! +250 gold"**, "A friend of
  your friend learned! Your tree grows. +25 gold", "Your friend Sam_22 landed on the Moon! +150 gold", "You learned a
  whole unit with your guide Alex_7: +50 gold!", and the answer to a code kept offline.
- **GOLD SHOP** (`ui/shop/gold_shop.gd`): "You have 1.2K gold"; shelves **EXPLORER LESSONS** ("New lessons beyond
  your grade. Your grade's own lessons are always free!"), **ROCKET PARTS** ("Rocket parts arrive with the Launch Site."
  until the missions hang parts), **WEAPONS & TOOLS** ("…wait in your backpack for your next Survivor world"), **AVATAR &
  BUDDY**, **DECORATIONS** ("…on their way"); cards with a name and a price (YOURS when owned), 8 a page; **HOW TO EARN**
  (EarnRules' table: "+5 gold An answer right the first time in the School (up to 150 a day)" …, "Gold never comes from
  waiting or from time: only from learning, puzzles and friends who learn."). Buying says "Opened for good! Find it in the
  SCHOOL.", "In your backpack: it comes into your next Survivor world.", "It's yours! Wear it in AVATAR." or "You need 50
  more gold. Lessons in the SCHOOL earn it!".
- **The first Explorer lesson**, "How rockets work" (grade 4 science, 150 gold): its unit page says "An Explorer lesson!
  It opens for good." and **OPEN FOR 150 GOLD** ("You have N gold. Learning earns more!"); once open it is a unit like
  any other (7 cards, 14 exercises). The grade's own units never show a price.

## The numbers

| What | Gold | Limit | Who pays |
|---|---|---|---|
| A School answer right the first time | 5 | 150 a day (`EarnRules.ANSWER_DAY_CAP`) | the game |
| A School unit mastered | 100 | once per unit (`MasteryRules.UNIT_GOLD`) | the game |
| A new Lab star | 25 | once per experiment | the game |
| A treasure, a temple's vault, the Wanderer's riddle, a golden animal | as before (LootRules) | once each, Survivor | the world |
| The first secret of each kind; a fact quiz | 50; 10 | hooks (below) | — |
| Joining with a friend's (class, family) code | 100 | once, a new account | the server |
| A friend you invited learned a whole unit | 250 | once per friend; 10 a rolling 30 days | the server |
| You learned your first unit with your guide | 50 | once | the server |
| A friend of your friend learned (the tree's 2nd level) | 25 | once each; 20 a rolling 30 days | the server |
| A friend you invited landed on the Moon | 150 | once per friend; 10 a rolling 30 days | the server |

A day of learning (the answers' cap, a unit, a star) is about **275 gold**: `SpendRules.GUIDE` suggests the missions'
prices (the first rocket part ~250, the Moon's rocket ~1,000, Mars's ~7,000). An Explorer lesson costs 150-200
(`SpendRules.LESSON_PRICE`, bounded 50-2,000). Weapons and tools cost Tilly's price in the highest universe opened.
Explorer ranks (friends who learned): 1 Mentor (a Mentor star and a crew badge), 3 Trail Guide (a golden rocket paint),
5 Mentor of 5 (a buddy of your own), 10 Ambassador (your own explorers' club), 25 Star Guide (a star on the Star Map with
your name), 50 Great Guide (your statue in the colony dome), 100 Wonder Maker (a wonder named after your crew): things to
show, never power; the things themselves are hooks for the crews, the Star Map and the colonies (`InviteRules.RANKS[].id`).

## Rulings (decided without asking; what each costs if wrong)

1. **Server file names**: `src/rules/referral_rules.ts` and `src/server/referrals.ts`, not `invite_rules.ts` (that file
   already holds the match invites). *Cost:* none.
2. **"Really learned" = the friend's first School unit mastered**, reported once by the friend's game (`invite_progress
   {"event": "learned"}`), not "two different days". The learning is the point and the moment is the proud one. *Cost:* a
   child with two devices can farm at most the monthly cap (10 × 250 gold in 30 days); a second-day rule is a few lines in
   `Referrals.progress`.
3. **A new account = younger than 14 days** by Nakama's own create time (an unknown time counts as new; checked on a real
   Nakama 3.41: seconds, read right). *Cost:* a friend who waited longer can't use a friend's code (a class or family code
   still joins); one constant.
4. **"Never your own device"** is "never your own account": in Nakama a device id belongs to one account, so a second
   account on one phone means the first was deleted (its referral goes with it). No device ids or anything else about the
   friend are stored. *Cost:* a reinstall farm is only bounded by the caps.
5. **Both win**: the friend gets 50 when they learn (the world plan §1), besides the 100 welcome at once. *Cost:* two
   constants.
6. **Monthly caps are rolling 30 days** per kind (learned 10, tree 20, landed 10); past the cap the friend still counts in
   the tree and the ranks, without gold ("This month's friend gold is used up, but it still counts in your tree."). *Cost:*
   constants in `ReferralRules.CAPS`.
7. **The Explorer Tree has two levels, and the second is never named**: a child sees their friends' in-game names, and of
   their friends' friends only counts (strangers to the child). The tree's count is friends who learned plus friends'
   friends who learned. *Cost:* a less personal tree; names could come with crews and their own safety review.
8. **Class and family codes show counts, never names** (members, members who learned); one class and one family per
   account; at most 40 and 12; the maker is its first member; a **new** account joining is also the maker's referral (the
   welcome gift, the maker's rewards); an older account joins without gifts. A grown-up makes and stops them behind the
   parent gate. *Cost:* constants; a class goal and names are the classroom brief's.
9. **An invite doesn't make Nakama friends**: friendship stays the usual request. *Cost:* one tap more; the crews brief
   can add ADD AS FRIEND on the invite page.
10. **The invite flow claims the child's own name** when the account has none and the name is free (the friend is told
    their guide's name, the guide their friend's): the INVITE page asks with UsernameClaim when it is taken; at the start a
    taken name leaves the account unclaimed ("A new explorer" on the guide's page) until a name is claimed. *Cost:* a
    name reserved without PLAY ONLINE's one tap.
11. **A device that used or typed a code signs in by itself at the menu** (`Session.online_autostart`, like a device that
    has been through PLAY ONLINE): the code kept offline, the first unit learned and friends' news go up. *Cost:* one
    sign-in per start for those children.
12. **Android's install referrer is not read** (it needs the Play Install Referrer library: new native code): the Play
    Store link carries `&referrer=invite%3DCODE` for later (`InviteRules.store_link`), and the friend types the code (big
    and read out on the page). *Cost:* a friend installing from the Play Store types 3 words.
13. **SHARE is the browser's own sheet** (`navigator.share`, web only); on Android COPY LINK and the QR code (Godot 4.7 has
    no plugin-free share intent). *Cost:* one more step on Android.
14. **The QR code is the game's own encoder** (`core/invite/qr_code.gd`: byte mode, level M, versions 1-10, the penalty's
    mask). Its matrices equal Project Nayuki's reference encoder (qrcodegen 1.8.0, Python) for a version 1 code with a
    fixed mask, the invite link (version 4, mask 6) and a version 8 code (mask 7, with version bits); zbarimg (zbar-tools
    0.23.93) decoded the game's pictures of three invite links (versions 4 and 5). segno 1.6.6 draws different data
    modules for the same text, version and mask (it pads or orders differently); Nayuki's is the reference. *Cost:* none
    found.
15. **Answer gold is paid at once** (the words beside the praise), capped per day in the profile (`earn_today`); a clock
    turned back pays nothing twice. STOP keeps the gold earned. *Cost:* constants.
16. **A Lab star pays into the profile's Survivor gold wherever the Lab is open** (the menu or a lab bench in a world: the
    HUD's counter is told). *Cost:* none.
17. **The worlds' secrets and puzzles already pay once each** (LootRules: chests, the temple's vault, the Wanderer, golden
    animals): nothing is paid twice. The first secret of each kind (`EarnRules.SECRET_KIND_GOLD`, `secret_gold()`) is a
    hook: wiring it in `SecretDirector._rpc_found` changes the exact gold every world test asserts on the machine's own
    profile, so it waits for the lead's ruling. *Cost:* 50 gold per kind not paid yet; one line to add.
18. **Gold earned outside a world is account gold** in the profile (like the School's 100); the wallet sync reports it;
    the server's invite gold reaches the phone by the same sync (called after a welcome, a news item with gold).
19. **Weapons and tools cost Tilly's price in the highest universe opened** (so the menu's shop is never a cheaper way
    into a later universe) and **wait in a backpack** (profile `backpack`, device-only: never delivered twice), emptied
    into the next Survivor world's bag (`Session.set_inventory`, the local player, Survivor mode only). One of each.
    *Cost:* a bought tool can't be carried between devices before its first Survivor world.
20. **Explorer lessons are units marked `"bonus": true` with a `"price"` in a grade's outline**; they never count for the
    subject's certificate; the unit page offers OPEN FOR N GOLD; the lesson and the round stay closed until bought
    (`profile.bought`, never lost when copies merge). The first, "How rockets work", is in grade 4 science: only that
    subject had room without breaking other tests' pinned research counts (grade 4 computing 11, history 10 …). *Cost:*
    more Explorer lessons need room in an outline or a later outline of their own (`SpendRules.bonus_units` is the one
    place that finds them).
21. **INVITE and GOLD SHOP are main-menu buttons** in one row with SCHOOL, AVATAR and SETTINGS (212 px each). *Cost:* a
    row; SETTINGS keeps FRIEND'S CODE.
22. **A web invite link opened by a child who already plays** is kept as the pending code; the server decides (an old
    account gets "Codes are for new explorers. You can still play with your friend!" on the news card). *Cost:* none.
23. **News live on the server** (`invite_info` "news"; `seen` forgets them) and note 108 only nudges an open game; the
    menu shows them on a card once. The world's count ("children brought by children") is kept (`invite_stats/world`) and
    answered, not shown yet. *Cost:* a page line later.
24. **Hooks, not features** (later briefs): `InviteRules.friend_landed("moon")` for the missions (this child's first Moon
    landing: the inviter's bonus), `SpendRules.register(shelf, item, grant)` for rocket parts and decorations,
    `InviteRules.share_text` and the links for postcards and the Daily Mission card, the news kinds for gifts and
    cheers, `InviteRules.RANKS[].id` for the rank rewards, `profile.invite.guide` for "Your guide ALEX flew this one", and the welcome's starter rocket part (the brief's "if the parts exist": they don't on this base, so the welcome is gold; the missions can give a part once when `profile.invite.used`).

## Safety and privacy (the lawyer's note: `docs/store/refer-a-friend-note.md`)

- A link carries only the code; the share text is "Come and learn with me in EasyCraft! My invite code: CODE" and the
  link. The game never reads contacts and never asks for a friend's name, e-mail or number.
- The server keeps, per player, the account ids and dates of the friends they brought and who brought them, their codes,
  the month's reward times and unseen news (ids, never names: names are read from the accounts when shown). Codes and
  groups are the system's objects. Nothing is readable or writable by a game (checked on a real Nakama).
- A friend is shown by their in-game name only; a friend's friend never.
- Deleting an account (`delete_account`, and the retention clean-up's inactive accounts) removes its record, its codes,
  the groups it made, its place in other groups, its place and news in its inviter's list, and its friends' links to it
  (`Referrals.forget`; the answer's `invites` counts them).
- No pressure: no timers, no "invite or lose", no streaks, no ranking of children; every lesson, rocket and world is
  reachable without inviting anyone (a test keeps pressure words out of every line).

## Tests

- Server (Node, `npm --prefix server/modules test`): **354 of 354 pass** (`referral_rules.test.ts` 15, `referrals_rpcs.test.ts`
  16, the version tests at 0.2.16). On a private Nakama 3.41 for this worktree (compose project `easycraft_inv`, ports
  7459-7461, removed after): `test/integration/referrals.server.ts` 3 of 3 (the code, the welcome in the wallet, learned
  paid once, the news, the deletion, a family code, storage closed to the game); the other integration scripts pass
  except 13 under-13 checks that fail on the base too (the module ships with age rules off since 0.2.13).
- GDScript: `test_earn_rules`, `test_invite_rules`, `test_qr_code`, `test_spend_rules`, `test_explorer_lessons`,
  `test_school_earn`, `test_invite_online`, `test_invite_page`, `test_invite_menu`, `test_gold_shop`, and additions to
  `test_school_screen`, `test_lab_screen`, `test_web_glue`. **The full suite (2026-09-29 23:50, on commit 6e3f25b6): 7,650 of
  7,650 pass, no script errors** (38 min). The run before it found one false positive (`test_shop_child_side`: its code scan
  forbids the text `ShopPage.new(` outside the grown-ups' area, and `GoldShopPage.new(` held it): the class is `GoldShop` now.

## For the lead: deploy and check

1. **Server**: deploy module 0.2.16 (the kit builds `server/modules`); `healthcheck` says 0.2.16; run
   `EASYCRAFT_SERVER=… node --test test/integration/referrals.server.ts` against the dev server first.
2. **Web**: rebuild and deploy (web/shell.html keeps `?invite=` across its redirect to the server's copy).
3. **Live check** (two browsers, or a browser and the emulator): A opens INVITE (a code, the link, COPY LINK, QR CODE:
   scan it with a phone); B opens `…/play/?invite=<A's code>` fresh: after the name the box is filled in, OK → "Welcome,
   explorer! A's code brought you +100 gold." and B's gold +100; B masters a unit → B's card "You learned a whole unit with
   your guide A: +50 gold!", A's card "Your friend B joined and learned! +250 gold" and A's gold +250; A's INVITE shows B
   learned, "Your tree: 1 child learning", "Mentor"; B deletes its account → A's list forgets B.
4. **Emulator**: the main menu's row of five fits; INVITE, QR CODE, GROWN-UPS (class and family codes), the start's code
   box (the phone keyboard), GOLD SHOP's five shelves, the School's "+5 gold: right the first time!", a Lab star's "+25
   gold!", the Explorer lesson's OPEN FOR 150 GOLD.
5. **Owner feedback**: #79 (earning and inviting built: the tests above), #83 (the Gold Shop's frame and the first
   Explorer lesson), #85 (the Explorer Tree and the ranks) for `docs/playtests/owner-feedback.md`.
6. **Rulings to confirm**: 2 (learned = first unit), 17 (the first-secret bonus), 20 (where Explorer lessons live).
