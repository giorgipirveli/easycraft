# EasyCraft Privacy Policy

> Filled in 2026-09-24 for the first Google Play listing (owner feedback #46); brought up to release 0.4.0 on
> 2026-09-25 (M5 Task 4: trading, ghost races, secret codes, the books, read-aloud, the tutorial, the boy/girl choice,
> server module 0.2.8's stricter age band and 30-day notifications). Owner #67 (2026-09-28, module 0.2.12): the
> account's sign-in key (a scrambled fingerprint only) and one device code per signed-in device; the backup no longer
> carries gold or one-device settings; worlds stay on each device. Owner #99, #105 (2026-10-16, module 0.2.20): the
> account's **password** (made right after the online name; kept only as a bcrypt hash), LOG IN with the name and the
> password on another device (**one device at a time**: the others are logged out), the counts of wrong tries that slow
> guessing down (no network address is used; gone within 2 days), the note "someone tried to log in
> as you", and DELETE taking the player off the device too. The sign-in key's fingerprint is a bcrypt hash (it was
> written "salted SHA-256" here before; the server has used bcrypt since module 0.2.12).
> Still **not legal advice**: a lawyer checks it against COPPA (with its 2025 amendments), GDPR/GDPR-K, the UK
> Children's Code, Georgia's personal data law, Brazil's Digital ECA, the US state app-store age laws and Play's
> Families policy. Questions for the lawyer are in `pre-launch-checklist.md` ("For the lawyer"). The public page
> (`server/deploy/site/privacy/`) is made from this file by `tools/make_store_pages.py` (this note is left out);
> the lead deploys it.

**Last updated:** 16 October 2026 · **Who we are:** EasyCraft is made by Giorgi Pirveli (API Studio), Tbilisi,
Georgia ("we"). Contact: parkingi-support@googlegroups.com — we answer within 30 days.

## The short version
- You can play EasyCraft **without giving us anything**: Sandbox, Survivor, playing with bot friends and
  playing with family over home Wi-Fi keep everything on your device.
- **Online play** (with friends over the internet) needs a small account on our server: an online
  name you choose, your age group, and your game progress. For children under 13, online play stays
  **off until a parent agrees**.
- No ads. No tracking. No selling or renting of data, ever. No voice chat. No AI chatbots: bot friends understand
  what you say inside the game itself.
- **Purchases** (when the shop is on): only a grown-up can buy EasyCraft Plus or an outfit pack, in the
  grown-up area behind a parent gate. **Google Play** takes the payment; we never see card or bank
  details. We keep only which products the account owns (in the game's profile, and in its online
  backup) so they can be restored on a new phone. Today the shop is not open.

## What stays on your device
- Your worlds, builds and stamps, settings, gold, unlocks and progress, the age group you picked (never your birth
  date), and how long the game was played today (for the grown-up area).
- **Photos** you take in the game go to your phone's gallery, in an album called "EasyCraft". They leave the phone
  only if you share one yourself with Android's share button (you pick the app each time), or if your phone's own
  settings back up its gallery. We never receive them. For a player under 13 the share button is off until a parent
  turns **photo sharing** on in the game's grown-up area (PLAY & PHOTOS, behind the parent check); a parent can
  switch it off for any player.
- The **Memory Book** (your game's special moments and the photos that go with them) is kept only on this device.
- **Boy, girl or just me** (the first choice of your look) stays on this device; we never learn it. Other players
  see only your avatar.
- **Read-aloud:** when the game reads words out loud, it uses your phone's own text-to-speech voice. The words go
  to that voice on your phone, never to us.
- **Bot friends:** what you say to your bot friends is understood by the game on the phone that runs the world.
  There is no online AI service.
- Presents your friends sent you are kept on your device until you delete them. Your friends' races (their ghosts)
  are kept on your device so you can race them offline, until you delete the online account (or report that
  friend).

Deleting the app deletes all of this, except the photos in your gallery (they are your own pictures).

**Worlds stay on the device where they were made**, also when you play online: a world's blocks, what you built,
the Survivor bag in it and its buddies and pets are too big to copy to our server. What the online backup brings to
a new phone is listed below.

**Playing in a web browser** (the game's web page, installed or not): all of the above stays in that browser's own
storage on your device, for the game's page only. The page loads nothing from other websites and sets no cookies:
no ads, no analytics. Photos are offered as a download instead of going to a gallery. Clearing the browser's data
for the game (or uninstalling the installed web app) deletes it; the online backup, if you play online, can bring
your progress back: a grown-up signs the browser in again with the account's **sign-in key** (below).

## What our server keeps when you play online, and why
| What | Why | How long |
|---|---|---|
| A random code made by this copy of the game (not your phone's ID or an advertising ID) for the device that plays as the account (a grown-up's sign-in key can add more). When you LOG IN on another device with your name and password, that device gets its own code and **every other device is logged out**. The game also keeps one small extra code per device that it uses only to ask our server to log in (it holds no name, age or progress) | To sign you in on this device without typing anything, and to carry out LOG IN | Until the account is deleted, until you log in on another device, or until a grown-up uses SIGN OUT OTHER DEVICES; the ask-to-log-in code is removed after 13 months without use |
| Your **password**, made right after you choose your online name (6 to 64 letters, numbers or signs; not your name and not an easy one). We keep **only a scrambled fingerprint** of it (a bcrypt hash), never the password, and nobody, not even we, can read it back | So you can LOG IN with your name and password on another phone, tablet or computer | Until you change it or the account is deleted |
| Wrong password tries: how many, for which account, and from which asking device (no network address is used or kept). Too many make the next try wait (at most 15 minutes on one device; 10 minutes on a new device when a name is being guessed); a device that plays as the account now, and a grown-up's key, are never slowed | To stop someone guessing a password | Each count lasts 15 minutes or a day; the server deletes them within **2 days** |
| A scrambled record (a salted hash) of each device code that was logged out of an account, or whose account was deleted | So that device can never quietly make a new account and take the name again | **13 months** |
| A note to the account when a new device typed a wrong password ("Someone tried to log in as you on a new device"), at most once an hour, and when it was | So the player and a grown-up know, and can change the password | The note: at most 30 days; when it was: until the account is deleted |
| The **sign-in key**, if a grown-up made one (GROWN-UPS → ONLINE PLAY → OTHER DEVICES): 8 letters and numbers the grown-up writes down, so another phone, tablet or browser can sign in to the same account. We keep **only a scrambled fingerprint** of it (a bcrypt hash), never the key; wrong tries are counted for a few minutes to stop guessing | So a new phone, or a browser whose storage was cleared, can get the account back (also when the password is forgotten: CHANGE PASSWORD) | Until a new key replaces it or the account is deleted; the wrong-try counts go after 15 minutes to an hour and are never written to disk |
| Your online name (checked so it can't contain a real name, phone number, e-mail or address) | So friends can find and invite you | Until the account is deleted |
| Your age group (under 13 / 13 and over), whether a parent agreed, and the parent's settings | To apply the right safety rules | Until the account is deleted |
| Friends, blocked players, invitations | To play together safely | Until removed or the account is deleted; an invitation can be used for 1 hour, and invitations and friend notes are deleted after at most **30 days** |
| A backup of your game progress (your settings, unlocks, quests, keepsakes, titles, Pip's lessons, the looks and costumes you have, what your books show, your wish list; not your worlds, and not the settings that fit only one device such as graphics or moved buttons), your Survivor gold and its history, the Gold Farm clock | So progress isn't lost on a new phone or a cleared browser, and gold can't be faked (the gold is kept only as the gold history, never in the backup) | Until the account is deleted |
| Secret codes: the code you type is sent to our server to check it | So a code works once per account | We keep **only a scrambled fingerprint** of a code that worked, and how many wrong codes were tried in a row (to stop guessing); never the text you typed |
| Chat messages | To deliver them to your friends and team | **Not kept**, except private messages between two players aged 13+ who have text chat on: 30 days |
| Trades with another player: what each of you offers | To swap the things in the game you both agreed to | **Not kept**: the offer passes through our server to the game that runs the world; the gold that moves is written in each player's gold history |
| Builds you share with a friend: a present (a small build), a bottle (a picture phrase from the game's list and maybe a tiny build), your showcase (one build area your friends can visit) and the picture stickers friends leave on it | So your friends can see what you made even when you are not online together; only your friends can | A present or a bottle until your friend opens or deletes it, at most **60 days**; your showcase until you take it down or the account is deleted; stickers **60 days** (you can delete each one) |
| Your races shared with friends: your best run on a course you built (where your player went in the game world, 5 times a second, and its time) and your avatar's look, on your showcase or with a present | So your friends can race your ghost on your course; only your friends can, and nobody else ever sees a time | On your showcase until you take it (or the showcase) down or the account is deleted; with a present, like the present |
| Reports you make (who, which reason, and a copy of the one message, build or race reported) | So a person can review bad behaviour | 12 months after the review, then deleted; if your account is deleted first, your name is taken off them |
| Internet (IP) addresses in our server's logs | To keep the service secure | 14 days |

We use this information only to run the game and keep players safe. We do not build profiles of
players, use it for advertising, or combine it with other data. A "place" in the game (where your player stands, a
quest's place, a ghost's path) is a spot in a game world, never your real location; we never ask for your location.

## Children under 13 (and under the age of digital consent where you live)
- **Online play for children under 13 is not open yet.** Before it opens, we will name here the parental
  consent service we use; then, before a child under 13 can add friends, be found by name, be invited,
  chat, trade online or share builds and races, **a parent must give verifiable consent** through it. The parent's
  e-mail address goes to that service to contact the parent; **we don't keep it**.
- In every world, a child can report or block any player from the player's name tag, and the player whose world
  it is can remove anyone from it.
- Even with consent: friend requests wait for a grown-up's OK, chat is picture phrases only (nothing
  typed, nothing stored), a child trades online only with their own friends, other players see a child's name on a
  shared race only with consent, and online play can be switched off at any time in the grown-up area.
- Parents can see and change these settings behind the parent gate in the game (SETTINGS → GROWN-UPS),
  and can ask us at parkingi-support@googlegroups.com to see or delete their child's data, or to stop collecting it.
- The game can make an account's age group stricter (for example when a phone learns the player is under 13), but it
  never moves an account from under 13 to 13 and over. If the age group was picked wrong, or a child has turned 13,
  a parent writes to us and we change it.

## Who else sees data
- **Other players** see your online name, your avatar and what you do in a world you share, the
  messages you send them, what you offer them in a trade, and (only your friends) the builds and races you share
  with them.
- **Service providers** who work only on our instructions: our server host Hetzner Online GmbH
  (Nuremberg, Germany) and, once under-13 online play opens, the parental consent service named above. They may not use the data for anything else.
- **Nobody else.** We don't sell or share data for advertising. We would disclose data only if the law
  requires it.
- (When the Shorts Theater is switched on; it is off today:) videos play in YouTube's and TikTok's own embedded
  players, under their privacy policies; children under 13 see only videos made for kids, with tracking off, and
  never TikTok.

## Your choices and rights
- **Delete your online account:** SETTINGS → GROWN-UPS → ONLINE PLAY → DELETE MY ONLINE ACCOUNT in the game, or
  e-mail parkingi-support@googlegroups.com (how: https://178-104-20-64.sslip.io/delete-account). We delete the
  account and everything the table above lists within 30 days (backups within 35 days). In the game it asks for the
  account's password, and it takes this player off the device too (the name, progress, gold, looks and books; worlds
  on the device stay), so the game starts again for a new player.
- **Log out:** LOG OUT on the main menu, in SETTINGS or in PLAY ONLINE (one tap and YES; your game is saved to the
  account first, and an account with no password makes one first). The device then leaves the account on our server and
  forgets it (the device code, the online settings, the gold markers, the profile); the worlds stay on the device. LOG
  IN with the name and the password brings everything back on any device.
- **A forgotten password:** a grown-up on a device that is still logged in opens GROWN-UPS → ONLINE PLAY → CHANGE
  PASSWORD (the old password, or a sign-in key made there proves it's them).
- **Delete only some of it:** delete a present, a sticker or a friend's stamp in the game, or take your showcase
  down (its races go with it); or e-mail us about anything else.
- **A lost phone or a key given away:** GROWN-UPS → ONLINE PLAY → OTHER DEVICES: MAKE A NEW KEY stops the old key,
  and SIGN OUT OTHER DEVICES stops every other device from signing in to the account.
- See, correct or get a copy of your data; object to or limit its use; withdraw a parent's consent;
  complain to your data protection authority (in Georgia: the Personal Data Protection Service; in the
  EU/UK: your local authority).
- Legal bases (EU/UK): running the game you asked for (contract); a parent's consent for children under
  the age of digital consent; keeping the service secure (legitimate interests, for logs and reports).

## Security
Connections to our server are encrypted (HTTPS/WSS). The server stores data in a database that is not
reachable from the internet, with daily backups. Only the owner can open the admin
console, with a strong password. We follow a written data-retention and security policy.

## Where data is stored
On a server in Germany (European Union), run by Hetzner Online GmbH. If that is outside your country, we
protect the transfer as the data protection law that applies to you requires.

## Changes
If we change this policy in a way that matters, we'll tell players in the game, and ask parents again
where the law requires it, before the change applies.
