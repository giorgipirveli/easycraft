# Target audience (Families policy) and content rating (IARC) — answers for 0.4.0 and after

Checked against every feature of release 0.4.0, and what merged after it (Pip's tutorial, the MOBS tab, weapons'
strength by rarity, server module 0.2.8, M5 Task 1's accessibility, the player card in every world with module
0.2.9), on 2026-09-25 (M5 Task 4). The console answers were submitted on
2026-09-24 (`play-console.md`) and approved by Google on 2026-09-25. **Draft for the owner's lawyer; not legal
advice.** A higher-than-expected rating is a signal to review the answers, never to change a true answer.

## The result (as recommended)
- **Target audience and content: no change.**
- **Content rating (IARC): no answer changes.** Trading, ghost races, presents, showcases and the costume code are
  all covered by the "users interact" answer already given; the MOBS tab brings out the same cartoon creatures; the
  weapons' new strengths change no kind of violence; nothing is bought, gambled, located, or opens the internet. **Re-submit the questionnaire unchanged only if Play asks** (a new questionnaire version,
  or a change below). The answers change only when the shop opens or the Theater is switched on ("Later").
- The ratings Google gave (2026-09-24): Google Play **"Rated for 7+"**, **PEGI 7**, **ESRB Everyone 10+** (Fantasy
  Violence, Users Interact), **USK 12**, **GRAC 12**. The earlier guess (USK 6) was low: USK and GRAC raise games
  where users interact; nothing to change.

## Target audience and content (Play Console → App content → Target audience and content; as submitted)
- **Target age groups:** 9–12, 13–15, 16–17, 18 and over. (Spec §2 wants all ages with kids as the core; Play does
  not allow the groups under 9 with an ESRB 10+ rating, so 6–8 was left out. Children under 9 still play; the store
  just does not target them.)
- **Appeal to children:** yes, intentionally. So the whole **Families policy** applies (the owner certified
  compliance with children's laws on 2026-09-24).
- **Neutral age screen:** yes: the first launch asks for the age without steering the answer, and only the age band
  is kept (spec §5.14, M1). It decides the online and chat rules; it never locks a child out of offline play.
- **Families policy checklist, re-checked (0.4.0 and after):**
  - Ads: none. Analytics, crash or attribution SDKs: none. The Nakama client talks only to the owner's own server.
  - Permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `VIBRATE` only (all four Android presets, and the Play bundle's
    plugins add none: the Theater's WebView library asks only for `INTERNET`); no location, contacts, camera,
    microphone, storage, phone state or advertising id. Photos go to the gallery through Android's MediaStore, which
    needs no permission.
  - Content is appropriate for children (the rating answers below); nothing random for money (§6 fair fun).
  - Links out of the app: the parental-consent provider's page (from the grown-up area, behind the parent gate, once
    a provider exists) and Android's share sheet for a photo (the child's own action; for an under-13 player only after
    a grown-up turns **photo sharing** on in the grown-up area, behind the parent gate: off by default, finding F1).
    The Theater's embeds are off.
  - Online social features for under-13 players need **verifiable parental consent** first; strict defaults (online
    off, picture phrases only, friends only by invitation, a grown-up approves each friend request); no voice chat;
    reports reviewed by a person (spec §17.2–17.4); a game can only make an account's age band stricter, never lift an
    under-13 account (module 0.2.8). Report and block from the friends page, the chat, presents and visits, and (after
    0.4.0) from a **player card in every world** (tap a player's name tag: REPORT, BLOCK, and for the host REMOVE FROM
    MY WORLD; spec §17.3; online the removal needs module 0.2.9 on the server, on LAN the host drops the guest). New in 0.4.0 and inside the same rules: **trading** (an under-13
    player trades online only with their own friends; `docs/devlog/parts/owner-37-trade.md` ruling 13), **ghost races**
    (friends only; names only for 13+ or with consent), **presents and showcases** (friends only, server-checked).
  - Account deletion in the app and on the web (`delete-account.md`).
  - **Privacy policy inside the app:** Play's User Data policy asks for the privacy policy in the app as well as in
    the console. 0.4.0 has it only in the console: finding **F3** in `pre-launch-checklist.md` (fixed after 0.4.0: the
    grown-up area's PRIVACY page, in the next upload).
  - Accessibility (M5 Task 1): button size, a left-handed layout, movable buttons, text size and sound captions help
    every child; nothing in them changes an answer.
- **Expert Approved** (formerly Teacher Approved): "not now" (2026-09-24); apply after the production release when
  the game is polished (`reviewers-and-testers.md`).

## Content rating questionnaire (IARC) — category: Game
| Topic | Answer (as submitted) | Does anything since change it? |
|---|---|---|
| Violence | **Yes — fantasy violence** against fantasy creatures (slimes, goblins, mummies, bosses); pixel/childlike style; unrealistic reactions (defeated monsters puff into sparkles); no blood or gore; players are "knocked out" and get up | No. The new monsters (shadow bats, wisp spirits) and the Sky Dragon are fantasy creatures in the same style; its "sun lanterns" are towers you break |
| Humanlike creatures | Yes (goblins, mummies) | No |
| Real animals can be harmed | Yes (#26: they can be defeated; no blood) | No. #41's 19 new animals follow the same rules; riding horses and camels is not violence |
| Violence against humans or realistic humans | **No** | No: there is still no player-versus-player (spec §13.7); blaster shots fly through players, bot friends and buddies (M3 Task 14b ruling 3, "no friendly fire") |
| Fear | **Mild, often**: monsters at night, no fierce or dark overtones, no jump scares | No: the Dragon Realm is at sunrise (#43); its night monsters are the same kind of cartoon fright |
| Sexual content, nudity | No | No. The costumes and the girl avatars are ordinary children's clothes |
| Language (profanity, crude humour) | No | No. Chat is filtered; under-13 players have picture phrases only; bot friends say only written lines; players' names are filtered |
| Controlled substances (drugs, alcohol, tobacco) | No | No. Potions are fantasy items; the ninja costume's "smoke puffs" are a trail effect, not smoking |
| Gambling, simulated gambling | **No** | No. **Trading** is items and earned gold between players, one for one, both see everything and press READY; nothing can be bought, sold or cashed out for money, and nothing is random. Surprise drops and piñatas are earned in play, never bought |
| Users interact or exchange content | **Yes** (with block, report, moderation, friends only) | Still yes, and it now also covers trading items, ghost races, presents, bottles and showcase visits between friends; the tools grew after 0.4.0 (report and block from a player card in every world, and the host can remove a player; module 0.2.9). **Answer unchanged** |
| Shares the user's location with other users | No | No. A ghost race's positions and a quest's "place" are spots in the game world, not the player's location |
| Digital purchases | **No** | No: the shop is closed in 0.4.0 (no Play product ids). **Yes** in the release that opens it ("Later") |
| Unrestricted internet access | No | No: the Theater is off; when on, it plays only curated embedded videos (re-check the answer then) |
| Is the app a web browser or search engine / news or education product | No | No |

## Later (answers that change with a future release)
- **The shop opens** (Play product ids set in `core/shop/shop_catalog.gd` `PLAY_IDS`, owner #35, spec §18):
  IARC "Does the app allow users to purchase digital goods?" → **Yes** (not random: IARC shows "In-Game Purchases",
  not "Includes Random Items"); the store listing's **"Contains in-app purchases" → Yes**; Data safety "Purchase
  history" (`data-safety.md`); the listing's "No purchases" line (`listing.md` → "When the shop opens"). The Families
  policy allows purchases that are clearly marked and aimed at the grown-up (the parent gate, the price shown first).
- **The Theater is switched on:** re-answer "Unrestricted internet access" (probably still No: curated embeds) and
  check the Families policy's rules on embedded third-party content and ads before switching it on
  (`data-safety.md` → "Later").
- **The consent provider goes live:** no rating answer changes (under-13 players then use the same friends-only
  features).
