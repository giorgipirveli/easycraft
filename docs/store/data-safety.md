# Google Play Data safety form — answers for 0.4.0 and after (checked 2026-09-25, M5 Task 4)

Play's definitions: data is **collected** when it leaves the device (to our server); **shared** when it goes to a
third party. Data a user chooses to send to another player (a chat message, a present, a ghost race on the
showcase) passes through our server, so it is *collected*, but it is **not "shared"**: Play excludes transfers the
user starts and expects. Data that goes from one phone to another on the home Wi-Fi (LAN play) never reaches us and
is neither. Answers below are for the release build with the owner's Nakama server, **the shop closed** (no Play
product ids) and **the Shorts Theater off**; "Later" at the end says what changes when either opens.
**Draft for the owner's lawyer; not legal advice.**

## What the lead or the owner changes in Play Console (0.4.0 and the next upload)
The form as submitted on 2026-09-24 (`play-console.md`: collected, none shared, all optional; User IDs, Other info,
Other in-app messages, Other user-generated content, Other actions, Device or other IDs; encrypted in transit;
account with username and other authentication; the deletion link) **still covers every data type the game sends**:
trading, ghost races, the costume code, quests, the books, Pip's tutorial, the accessibility settings and the in-world
player card all fall inside types already declared (the check, feature by feature, is below). So **no data type is added or removed**. Owner #67 (module 0.2.12,
the account on every device) adds no type either: a linked device's random id is a **Device or other ID** like the
first one, and the sign-in key is **authentication** (the form's "username and other authentication"; only its salted
hash is stored, never readable); the backup now leaves out the gold (the ledger keeps it) and one device's settings. What to check and set
(App content → Data safety → Edit), field by field:

| Where in the form | Answer to have | Why |
|---|---|---|
| Data types → Personal info → **User IDs** → purposes | App functionality; Account management; Fraud prevention, security and compliance | unchanged; set any that is missing |
| Personal info → **Other info** → purposes | App functionality; Account management | unchanged (the age band, consent state and parent settings) |
| **Device or other IDs** → purposes | App functionality; Account management | unchanged (the random install id signs in) |
| Messages → **Other in-app messages** → purposes | App functionality; **Fraud prevention, security and compliance** | a report keeps a copy of the one reported message for the person who reviews it; bottles carry a picture phrase to a friend |
| App activity → **Other user-generated content** → purposes | App functionality; Account management; **Fraud prevention, security and compliance** | the profile backup (restores progress: account management), builds and **ghost races** sent to friends (app functionality), a report keeps a copy of the reported build or ghost (safety) |
| App activity → **Other actions** → purposes | **App functionality**; Fraud prevention, security and compliance | **trades** and co-op play pass through the server's relay to the host's game (app functionality, not stored); gold moved by a trade and codes used go into the account's history, reports, invites and rate limits (safety) |
| Each type → "Is this data processed ephemerally?" | **No** for every type | each type has a stored part (a trade offer alone is ephemeral, but "Other actions" also holds reports) |
| Each type → "Is this data required or optional?" | **Users can choose** (optional) | all of it only when a player chooses online play; offline and LAN play send nothing |
| Each type → "Is this data shared?" | **No** | ghosts, presents, showcases and trades go only to the player's friends, at the player's choice (a user-initiated transfer, not "sharing"); our host (Hetzner) is a service provider |
| Data deletion → "request that some or all of their data is deleted, without deleting their account" (optional question) | **Yes**, the same URL (https://178-104-20-64.sslip.io/delete-account, its new "Deleting only some data" part) | a player deletes a present, a sticker, a stamp, or takes the showcase down (its ghosts go with it) in the game; a parent can ask by e-mail for any single part |
| App content → **App access** (not in Data safety; recommended) | "All or some functionality is restricted", with the instructions: "Online play: at the first question choose 13 or older; PLAY ONLINE then asks for an online name and a password (any name not taken and a password like moon7tiger). Online play for players under 13 needs verified parental consent, which is not available yet." | a reviewer who picks "under 13" finds online play off and may think it broken |

Nothing else in the form changes. **When the lead has made these changes**, note the date in `play-console.md` and
tick the line in `pre-launch-checklist.md`.

## Overview questions (as submitted; unchanged)
| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | Online play signs in to our server |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | The production server is only reachable over HTTPS/WSS (Caddy, `server/deploy/`); LAN play stays in the home network and reaches no server |
| Do you provide a way for users to request that their data is deleted? | **Yes** | DELETE MY ONLINE ACCOUNT in the grown-up area (SETTINGS → GROWN-UPS → ONLINE PLAY, behind the parent gate; the server deletes the account and everything below) and by e-mail; the web page https://178-104-20-64.sslip.io/delete-account (`delete-account.md`) |

## Data types (the answers in full)
| Play category → type | Collected? | Shared? | Ephemeral? | Required or optional | Purposes | What exactly |
|---|---|---|---|---|---|---|
| Personal info → **User IDs** | Yes | No | No | Optional (online only) | App functionality, Account management, Fraud prevention/security | The online name the child chose (filtered for personal info), our account id |
| Personal info → **Other info** | Yes | No | No | Optional | App functionality, Account management | The **age band** only (`under_13` / `13_plus`; from module 0.2.8 a game can only make it stricter, never lift an under-13 account), the parent-consent state and the parent's settings (online on/off, chat level) |
| **Device or other IDs** | Yes | No | No | Optional | App functionality, Account management | A random id made by this install (`user://device_id.json`); not an advertising id, not a hardware id. Owner #67: one more random id for each phone, tablet or browser a grown-up signs in to the account with its sign-in key (the key itself: only a salted hash, as authentication) |
| Messages → **Other in-app messages** | Yes | No | No | Optional | App functionality, Fraud prevention/security | Chat relayed to friends and teammates; stored **only** for a DM between two 13+ players with text chat, 30 days; under-13 players use picture phrases only, nothing kept; a bottle's picture phrase (from the game's list) until opened, at most 60 days; the copy of one reported message in a report |
| App activity → **Other user-generated content** | Yes | No | No | Optional | App functionality, Account management, Fraud prevention/security | The profile backup (owner #67: brought to every device of the account; never the gold, the graphics, the moved buttons or the install card, which stay on each device): settings (read-aloud, controls, sound, button size, the left hand, text size, captions), unlocks, progress, quests, keepsakes and titles, Pip's lessons (how far the tutorial got), costumes and looks owned (**not** the boy/girl choice), the books' marks (animals met, pages, the saving list), buddy magic, Pip and the baby dragon (with the names the child gave them), the wish list, redeemed code hashes; the Survivor gold ledger; the Gold Farm clock; builds a player sends to a friend (presents, bottles' tiny builds, the showcase and the preset stickers friends leave on it); **ghost races** (a best run on the player's own course: in-game positions 5 times a second, the time, the avatar's look), on the showcase or with a present; copies kept in reports |
| App activity → **Other actions** | Yes | No | No | Optional | App functionality, Fraud prevention/security | **Trades** between players online and co-op play (block edits, moves, games), relayed through the server to the host's game and **not stored**; the gold a trade moves and the codes used, in the account's history; reports a player makes (who, whom, a reason, ids, the one copy); invites; rate-limit counters; the last sign-in time |
| Location, Financial info, Health and fitness, Contacts, Calendar, Photos and videos, Audio, Files and docs, Web browsing, App info and performance (crash logs, diagnostics), Personal info → Name / E-mail / Address / Phone / Race / Religion / Sexual orientation | **No** | No | — | — | — | See "Kept on the device only" below. A ghost's positions are places in a game world, not the player's location |

## Every feature, checked (0.4.0, and what merged after it)
| Feature | Leaves the device? | Where it goes | Play type | Change? |
|---|---|---|---|---|
| Trading between players (#37) | Online only: each offer and READY pass through the server's relay to the host's game; the host is a player's phone | Relay (not stored); the gold moved is written to each player's gold history | Other actions | None (declared) |
| The account on every device (#67, module 0.2.12) | Yes, when a grown-up makes a sign-in key (GROWN-UPS, behind the parent gate) and signs another device in with the name and the key | Our server: the key's bcrypt hash (never the key), one random id per signed-in device; the profile backup comes to the new device (worlds stay on each device). Wrong keys are counted in the server's memory only. MAKE A NEW KEY and SIGN OUT OTHER DEVICES for a lost phone | Device or other IDs; authentication (account creation "username and other authentication") | None (declared types); no e-mail or phone number is ever asked |
| The password and LOG IN (#105, module 0.2.20) | Yes: the child makes a password right after the online name, and LOG IN sends the name and the password to sign another device in (one device at a time: the others are logged out) | Our server: the password's bcrypt hash (never the password), counts of wrong tries per account and asking device (no network address; deleted within 2 days), a salted tombstone of logged-out device codes (13 months), a "someone tried" note. CHANGE PASSWORD (with the old one, or a grown-up's key) | Authentication ("username and other authentication": Play counts a password as authentication info for account creation, not as a data type); Device or other IDs | **Re-check the form before the next upload** (the lead or the owner): the account-creation answer becomes "username and password"; no new data type |
| Ghost races (M4) | Yes, when a player shares a race on the showcase or with a present | Our server, to the player's **friends only** (friends-only by the server; names shown only for 13+ or with consent) | Other user-generated content | None (declared); not "shared": a user-initiated transfer to friends, no third party |
| Presents, bottles, showcase, stickers (M4 I) | Yes, to friends | Our server; 60 days unopened, the showcase until taken down | Other UGC; bottles' phrases also Other in-app messages | None |
| The costume code (#36) and every secret code | Online: the typed code goes to the server to be checked; offline it is checked on the phone | The server keeps only a scrambled fingerprint (salted SHA-256) of a code that worked and a count of wrong tries (a 30-second lock after 5); the typed text is never stored or logged | Other UGC (hashes), Other actions | None |
| Quests, keepsakes, titles, places (#45a) | Only in the profile backup (online) | Our server (the backup) | Other UGC | None. A "place" is a spot in a game world (universe, seed, x/y/z), not a real location |
| Read-aloud (T21a, #45a) | **No** | The words go to the phone's own text-to-speech voice (the system's engine), never to us | — | None |
| Babble voices, Simple controls (T21a) | No | — | — | — |
| Bot friends understand the chat (#38) | No (offline) / as chat (online, to the host's game) | Understood on the host's phone; no internet service, no AI model | Other in-app messages (online only) | None |
| Memory Book and its photos (T21b) | **No** | A file on the device (`user://memories/`); not in the backup | — | None |
| MAKE MY SHORT: a child's own Shorts (spec §5.12b, 2026-10-01) | **No** | Small recipes in the profile on the device, **left out of the profile backup** (with their hearts); small copies of the child's photos and stamps in `user://my_shorts/`. No upload, no sharing, no export; nobody else ever sees them. Typed words go through the game's word filter and a no-names rule | — | None |
| Photos (M3 Task 16; the photo sharing switch, M5 F1) | **No** | The phone's gallery album (Pictures/EasyCraft). SHARE opens Android's share sheet (the child picks the app each time) **only where a grown-up's switch allows it**: off by default for under-13, on for 13+ (grown-up area → PLAY & PHOTOS, behind the parent gate; kept on the phone and in the profile backup). Where it is off, photo mode only saves to the gallery | — | None (the share is the child's own action to an app they choose, and for under-13 only after a grown-up's yes; finding F1 in `pre-launch-checklist.md`, fixed) |
| Animal Book, Secret Book pages, saving list, Hub Tree (T21b) | In the profile backup | Our server | Other UGC | None |
| Boy / girl / just me (#48) | **No** | Kept on the phone only: left out of the backup and of the look other players receive | — | None (no gender record is collected) |
| Girl avatars, costumes, the look (#36, #48) | The look (without boy/girl) in the backup, and to players in the same world | Our server; other players' games | Other UGC | None |
| Universes, portals, the Dragon Realm, animals, villages, MY MAP (#39, #41, #45b) | Only as progress in the backup | Our server | Other UGC | None |
| Pip's tutorial (M3 Task 15, after 0.4.0) | Only its record (started, skipped, done, the step) in the profile backup | Our server (the backup) | Other UGC | None |
| The MOBS page (owner #51), weapons' strength (owner #53) | No (a LAN or online guest's tap is a request to the host's game, like `/summon`) | — | — | None |
| Accessibility settings (M5 Task 1, after 0.4.0): button size, the left hand, text size, captions, moved buttons | Only as settings in the profile backup, like the others; the moved buttons stay on the device (owner #67: they fit one screen) | Our server (the backup) | Other UGC | None |
| Server module 0.2.8 (the M4 review) | The age band only gets stricter from a game; notifications deleted after 30 days | Our server | Other info; Other in-app messages / actions | None (less kept, not more) |
| The player card in every world (after 0.4.0; module 0.2.9's `remove_guest`, spec §17.3): REPORT, BLOCK, the host's REMOVE FROM MY WORLD | A report and a block, like the friends page's; a removal takes the guest off the host's invite list (the same `invites` record), nothing new is kept. On LAN the host's game just drops the connection | Our server (reports, the block list, the invite record) | Other actions (reports, invites), User IDs (blocks) | None: the same data, reachable from one more place |
| The shop (#35) | No: closed in 0.4.0 (no Play product ids) | — | — | "Later" |
| The Shorts Theater (M3 Task 17) | No: off (server switch); the player's WebView library is inside the Play build | — | — | "Later"; finding F2 |
| **Content updates** (owner #123; the Android updater, from 1.0.7): the app runs the web's game from its next start | Yes, a request: at each start the app asks our server for `update.json` and, when there is a newer game, downloads its signed patch pack (game content and GDScript only, never native code) over HTTPS. Nothing about the player goes with it: no account, name, device id or progress | Our server (the files under `/play/android/` and `/play/quest/`); Caddy's access log keeps the request's address 14 days, as for every web visit | None new (no user data is sent; the address in the server log is the same as every online request's; the owner's lawyer may want to confirm) | **The listing's description** should say the app keeps itself up to date with new content; the form's answers stay |

## Kept on the device only (never collected)
Worlds and builds, the child's own stamps, photos (the gallery), the Memory Book, the child's own Shorts (MY SHORTS), play time (`user://play_time.json`,
shown in the grown-up area), the boy/girl choice, friends' presents once opened (stamps) and friends' ghost races
kept for offline racing (both forgotten when the online account is deleted), graphics settings. Deleting the app
removes all of them except the photos in the gallery, which are the family's own pictures.

- **Parent contact for consent** (an e-mail the parent types): passed to the consent provider and **not stored by
  us**. The provider is a service provider acting for us (Play: not "sharing"); it is named in the privacy policy
  when the owner registers one (Epic's Kids Web Services or PRIVO: `pre-launch-checklist.md`).
- **Server logs**: the server's web front end (Caddy) keeps IP addresses in its access log for 14 days, for security
  (`data-retention-and-security.md`), never to find where anyone is. *For the lawyer:* whether Play wants an IP
  address in the logs declared (some read it as "Approximate location" only when an app derives a location from it,
  which we never do).

## Security practices section (unchanged)
| Question | Answer |
|---|---|
| Data is encrypted in transit | Yes |
| You can request that data be deleted | Yes (in the app's grown-up area, on the web page, or by e-mail) |
| Committed to follow the Play Families Policy | Yes |
| Independent security review | No (not at launch) |

## Later (a new answer before the release that turns it on)
- **The shop (owner #35, spec §18):** parents buy EasyCraft Plus and cosmetic packs in the grown-up area, behind the
  parent gate, through **Google Play Billing**. Then: Financial info → **Purchase history**: collected (in the
  profile backup: which products the account owns, e.g. `plus`, `pack_sky`; never prices, order ids or payment
  details), not shared, optional, purposes App functionality (restoring what was bought). Google Play is the payment
  processor, not a third party we share with. When the server checks receipts (`ShopService.verify_receipt`), the
  purchase token goes to our server for that check: re-answer then. Also the listing's "Contains in-app purchases",
  the IARC "digital purchases" answer and the listing's "No purchases" line (`listing.md`, `families-and-rating.md`).
- **The Shorts Theater:** the YouTube/TikTok embedded players load in a WebView; those services receive the
  device's IP address and the video requests under their own policies. For under-13 players: only Made-for-Kids
  videos, tracking off, behind the parent gate, and no TikTok (spec §5.12). Re-answer "shared" and check the Families
  policy's rules on embedded third-party content and ads (the Families ads rules) **before** turning it on.
- **The consent provider:** name it in the privacy policy; no new data type (the parent's e-mail goes to the
  provider, not to us).
