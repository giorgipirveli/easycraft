# Data retention and information security — written policies (DRAFT)

> Checked on 2026-09-25 (M5 Task 4) against 0.4.0 and what merged after it (Pip's tutorial, the MOBS tab, module
> 0.2.8): trading, ghost races, the costume code, quests, the books, the tutorial and read-aloud add no new kind of
> stored data except what the rows below name; every new row is deleted with the account.
> Owner #99, #105 (2026-10-16, module 0.2.20): the password rows, one device at a time (a LOG IN unlinks the others),
> the password windows' 2-day clean-up, the "someone tried" note; the sign-in key's hash is bcrypt (not SHA-256 as
> written here before).

COPPA's 2025 amendments require an operator of a child-directed service to keep a **written data
retention policy** (what, why, how long; published in the privacy notice) and a **written information
security program**. These are the drafts; the owner adopts them (and names the responsible person) and
a lawyer checks them. The server code already enforces the parts marked **(enforced)**.

## 1. Retention schedule
| Data (server) | Purpose | Kept | How it is removed |
|---|---|---|---|
| Account: device id, username, age band, consent state, parent settings | Sign-in, safety rules | Until the account is deleted, or **13 months without a sign-in** (then deleted) **(enforced)** | Account deletion **(enforced: DELETE MY ONLINE ACCOUNT in the grown-up area; the owner's console steps for a parent's e-mail, `docs/hosting.md`)** and a daily clean-up job **(enforced)** (M4 Task 8b) |
| Last sign-in time | The 13-month rule | Until the account is deleted | Account deletion **(enforced)** |
| Friends, blocks, friend requests waiting for a grown-up | Play together, safety | With the account | Account deletion **(enforced: gone from both players' lists, and from other children's waiting requests)** |
| Invitations | Joining a friend's world | 1 h to join; 24 h to come back, and only while the two are still friends **(enforced)** | Overwritten by the next invite |
| Profile backup, gold wallet and ledger, code hashes, farm clock | Progress, fair play | With the account. Owner #67 (module 0.2.12): the backup is one object, cleaned on every write **(enforced: ProfileRules)**: never the gold (only the ledger has gold), never the settings of one device, the account's own name and age band, sane size and shape | Account deletion **(enforced)** |
| Linked device ids (owner #67: one per phone, tablet or browser a grown-up signed in with the sign-in key; owner #105: the device of a LOG IN with the name and the password) | Sign-in on every device of the account | With the account, until SIGN OUT OTHER DEVICES, or until a LOG IN on another device **(enforced: unlinked; their sessions end and their open connections close; one device at a time)** | Account deletion **(enforced: Nakama's cascade)**, SIGN OUT OTHER DEVICES, LOG IN elsewhere **(enforced)** |
| The password (owner #105): its bcrypt hash and when it was made (`account/password`, server only), never the password | LOG IN on another device; DELETE and CHANGE ask for it | Until changed, or the account is deleted **(enforced: the `account` collection)** | Account deletion **(enforced)** |
| A tombstone of each device id unlinked from a claimed account (owner #105: `account/removed_device:<salted hash>` on the system user, never the id itself; made when a LOG IN elsewhere, SIGN OUT OTHER DEVICES, a DELETE or the 10-device cap unlinks an id; never for a never-claimed account) | So such a device is refused with its own answer (it shows "logged out") and can never quietly make a NEW account for itself and re-claim a freed name | **13 months (enforced: `SQL_OLD_REMOVED_DEVICES` in the daily clean-up)** | Daily clean-up job **(enforced)** |
| Linked device ids per account (owner #105) | Sign-in on the account's devices | At most 10 per account **(enforced: a link beyond that unlinks an older id)** | As the linked-device row above |
| The device's own asking account (owner #105: a tiny unclaimed account, its random id in `user://login_device.json`, used to ask the server to LOG IN; it holds no name, age or progress) | So LOG IN can ask the server without signing the player out first | On the server until 13 months without a sign-in (the inactive-account clean-up) **(enforced)**; on the device until the app is deleted | The retention clean-up **(enforced)** |
| Wrong password tries (owner #105, the frozen design: exactly two windows; **no network address is used or kept at all**). The **pair** (`limits/password_pair:<account>` on the asking account): 5 wrong from one asking device for one account in 15 minutes, then a wait to that window's end. The **name** (`limits/password_name` on the account): a 24-hour window (from its first wrong try) counting wrong tries from devices not linked to the account; past 10, each further try from such a device waits 10 minutes (one fixed wait). A device linked to the account, and a grown-up's key, are never slowed. Also: the old password or a key for a change or a delete, 5 per 15 min | Slowing guesses: at most about 144 + 10 a day per name | The window's own time (15 minutes, or 24 hours); **deleted by the daily clean-up 2 days after the last write (enforced: `SQL_OLD_PASSWORD_WINDOWS`)**; a pair window kept on another (asking) account outlives a DELETE of the account it named by at most those 2 days | Daily clean-up job, account deletion **(enforced)** |
| "Someone tried to log in as you" (owner #105): a notification to the account (code 112) and when it was (`account/password_tried`), at most once an hour | The player and a grown-up know; CHANGE PASSWORD | The notification: at most 30 days **(enforced: the notifications' clean-up)**; the time: with the account | Daily clean-up job, account deletion **(enforced)** |
| The sign-in key (owner #67): its bcrypt hash and when it was made, never the key; the key is shown once to the grown-up who made it | Signing another device in to the account; CHANGE PASSWORD when the password is forgotten | Until a new key replaces it, or the account is deleted **(enforced: the `account` collection)** | Account deletion **(enforced)** |
| Wrong sign-in keys (owner #67; owner #105): a count per asking account only, never per name (so a stranger's wrong keys can never keep a grown-up's right key out) | Stopping guesses (10 wrong from one asking account lock it 1 h) | In the server's memory only, at most two lock windows **(enforced)**; never on disk; a server restart clears it | Expires |
| Secret codes (M3 Task 13, the Cube Hero's code of owner #36) | A code works once per account; no guessing | The typed code: **never stored**, only checked (`redeem_code`; nothing of it is logged). A code that worked: its salted SHA-256 fingerprint, with the account **(enforced)**. Wrong tries: a count and a lock time (5 wrong in a row lock it for 30 s), overwritten by the next try, with the account **(enforced)** | Account deletion **(enforced: the `codes` collection)** |
| Trade offers between players online (owner #37; 0.4.0) | Swapping things in a game | **Not stored (enforced)**: offers and READY pass through the match relay to the host's game; the gold a trade moves is an entry in each player's gold ledger (with the account) | — |
| DMs between two 13+ players with text chat | Message history | 30 days **(enforced: older messages are removed when the DM opens, and by the daily clean-up)**; with the account (both sides of every DM with a deleted player) **(enforced)** | Nakama message deletion |
| Invites, a grown-up's "yes" notes and friend notes (notifications) | Delivery | At most **30 days (enforced: the daily clean-up, module 0.2.8; the game never reads them later)**, or until the sender's or the receiver's account is deleted **(enforced)** | Daily clean-up job, account deletion |
| Under-13 chat, team-room chat | Delivery only | **Not stored (enforced)** | — |
| Presents and bottles a player sent to a friend (a build; a preset phrase) (M4 Wave 3) | Delivery to a friend who is not online | Until the friend opens or deletes it, at most **60 days (enforced)**; the sender's unopened ones go with the sender's account **(enforced)**; from a player who is no longer a friend (or blocked): deleted when the list is read **(enforced)** | Daily clean-up job, account deletion **(enforced)** |
| A player's showcase (one build area, maybe a buddy's blocks) | Friends visit it | Until taken down, or the account is deleted **(enforced)** | Account deletion **(enforced)** |
| Ghosts: a player's best run on a course they built (positions 5 times a second, the time, the avatar's look code) (M4 ghost races) | Friends race it | On the showcase: until replaced, taken down (a new showcase or none takes them down) or the account is deleted **(enforced)**; with a present: like the present **(enforced)**; at most 3 per showcase, one per course **(enforced)** | Account deletion **(enforced)** |
| Guestbook stickers (a preset picture and the visitor's online name) | The owner sees who visited | **60 days (enforced)**, the newest 30; the owner can delete each; a visitor's stickers go with the visitor's account **(enforced)** | Daily clean-up job, account deletion **(enforced)** |
| Reports (who reported whom, the reason, and a copy of the one reported chat message or build) | Human review | 12 months after the review **(enforced)**; a report nobody reviewed is kept for the reviewer. When the reporter's account is deleted, their id and name are removed from it **(enforced)**; a report about a deleted player stays | Daily clean-up job **(enforced)** |
| Recently passed-on chat messages (for a report's copy) | Human review of reports | 1 hour, in the server's memory only **(enforced)** | Expires; a server restart clears it |
| Rate-limit windows | Abuse prevention | ≤ 1 h of use; the report window (which names the players someone reported) is deleted by the daily clean-up once its last report is an hour old **(enforced, module 0.2.10)** | Overwritten; daily clean-up job (the report window); account deletion **(enforced)** |
| Server logs with IP addresses | Security | 14 days **(enforced: Caddy's access log, a new file every midnight, none older than 14 days; Docker's logs hold no addresses and are limited by size)** | Log rotation (`server/deploy/`) |
| Database backups | Recovery | 7 daily backups (`server/deploy/`); a deleted account is gone from the server's own backups within 8 days (the provider's backups: as they keep them, at most 35 days) | Backup rotation |
| Parent contact for consent | Consent | **Not stored by us (enforced)** — the consent provider's policy applies | — |
| On the device (not the server): friends' opened presents (`user://gifts.json`), friends' ghost races and kept showcases (`user://ghosts.json`), the install id and online settings | Playing offline with what friends shared | Until the online account is deleted **(enforced: `OnlineService.forget_online` removes them)**, or that friend is reported (their ghosts) | Account deletion in the game |
| On the device only, never sent: worlds (their blocks, the Survivor bag, buddies and pets in them), photos (the gallery), the Memory Book, play time, the boy/girl choice, graphics and the other settings of one device, moved buttons | The child's own play | Until the app is deleted (photos: until the family deletes them) | Deleting the app |

## 2. Information security program
- **Responsible person:** [OWNER NAME] (reviews this program once a year and after any incident).
- **Risk assessment:** yearly; the first one before launch (lead's review notes: online economy,
  consent, chat rules, match joins are server-decided: `docs/devlog/2026-09-24-m2.md` 16:00 review).
- **Safeguards:**
  - Encryption in transit: HTTPS/WSS only in production (Caddy, automatic certificates).
  - The database is not published to the internet; the Nakama console is behind a strong password and
    only reachable by [the owner] (change the default password: `docs/hosting.md`).
  - Server decides every rule that matters (age, consent, who may join, chat level, gold): a modified
    game can't turn them off (M4 Wave 1–2 tests). Owner #67: a modified game can't put gold into its backup,
    write other storage objects, or read the sign-in key back; a key is 40 random bits, kept only as a bcrypt hash, and
    wrong keys are counted per asking account only (the second review: so a stranger's wrong keys on a child's name can
    never keep a grown-up's right key out).
    Owner #105: a password is kept only as a bcrypt hash; the server checks the same rules as the game (6 to 64
    characters and at most 72 bytes, not the name, not one of the commonest, no straight runs like 123456 or qwerty);
    every try is counted before the password is checked, in windows that fail closed; one bcrypt compare runs on every
    path, so neither the answer nor its timing says whether a name exists; a wrong name and a wrong password get one
    answer. The brake (frozen, the lead, 2026-10-16) is exactly two windows: the pair (5 wrong per asking device per
    account in 15 minutes) and the name (a 24-hour window, from its first wrong try, counting tries from devices not
    linked to the account; past 10, one try every 10 minutes). **True numbers:** at most about 144 + 10 guesses a day per name; a child's longest
    wait on a brand-new device is 10 minutes (her own repeated typos on one device: the pair's 15 minutes); a device
    linked to the account and a grown-up's key are never slowed, so the key path always works. **Accepted residual:**
    an attacker can slow a child's FIRST login on a brand-new device to one try per 10 minutes. The account is told
    "Someone tried to log in as you" at most hourly. A device unlinked from a claimed account is refused for good
    (its own answer, so the game shows "logged out"); it never makes a new account.
  - Least data: no birth dates, no real names, no location, no contacts, no advertising ids.
  - Secrets (server key, console password, the upload key) never in the repository.
  - Updates: the Nakama and PostgreSQL versions are pinned and updated at least every 6 months, or at
    once for a security fix.
- **Service providers** (hosting, consent) are chosen for their security and bound by contract to use
  data only for us.
- **Incidents:** a breach is contained, assessed, and reported to the affected parents/players and the
  authorities within the legal deadlines (72 h under GDPR); written up in the dev log.
