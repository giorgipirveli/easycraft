# Refer-a-friend in a children's app: a note for the owner's lawyer (owner #79; spec §25.2; server module 0.2.16)

Written on 2026-09-29 by the earn-invite agent from what the game and its server do (`docs/devlog/parts/earn-invite.md`,
`server/README.md`, `server/modules/src/rules/referral_rules.ts`, `src/server/referrals.ts`). **A draft for the
lawyer's review, not legal advice.** The questions at the end are the ones we could not answer ourselves.

## What the feature is
- Every player with an online name has an **invite code** of two kid-safe words and a number (BLUE-OTTER-42) and a
  **link** (`https://178-104-20-64.sslip.io/play/?invite=BLUE-OTTER-42`, the GitHub Pages copy the same way). A grown-up
  can make one **class code** and one **family code** (behind the game's parent gate).
- A **new** player (an account younger than 14 days) who types a friend's code, or opens the link, gets **100 game gold**
  at once. The friend who invited gets **250 game gold when the new player masters their first School unit** (learning,
  never a bare sign-up), the new player 50 more; the inviter's own inviter a small 25 (two levels, never deeper). A first
  landing on the Moon brings the inviter 150. At most 10, 20 and 10 of these a rolling 30 days per inviter.
- **Game gold is not money.** It cannot be bought, sold, withdrawn or exchanged; nothing is taken from anyone; it buys
  things inside the game (rocket parts, lessons beyond the grade, weapons, avatar things). No purchase is ever needed to
  invite or to be invited.

## Why we think it fits the rules (please check)
- **COPPA** (US, under 13): the feature collects **no personal information about the friend**. The game never reads the
  device's contacts, never asks for a friend's name, e-mail address or phone number, and sends nothing to anyone. The
  child (or, as the page suggests, a grown-up) passes the code or the link on outside the game, the way they would read out
  a game's name. The link carries only the code. On the server, per player: the account ids and dates of the friends they
  brought and of who brought them, their codes, when capped rewards were paid, and unseen news as ids; names are read from
  the accounts only when shown, and only the in-game name (the username filter keeps real names, numbers and addresses
  out of names). The FTC's COPPA FAQ treats "refer-a-friend" features that collect a friend's contact information as
  collecting personal information that needs a parent's notice and consent; this feature collects none, which is why we
  built it that way.
- **Google Play's Families policy**: no ads, no third-party SDKs, no contact access, no permission added (the Android
  build's permissions are unchanged: `INTERNET`, `ACCESS_NETWORK_STATE`, `VIBRATE`). Incentives are in-game only and tied
  to learning. We found no rule against in-game rewards for inviting friends in a Families app as long as no personal
  information is collected and nothing deceptive is shown; the page says plainly what each friend gets.
- **No pressure** (the design research and the owner's rule, #82): no timers, no "invite or lose", no streaks, no ranking
  of children by invites; the page says "No one to invite? That's fine: every lesson, rocket and world is yours to play."
  Every lesson of the child's own grade stays free.
- **Multi-level** (the "Explorer Tree", owner #85): a small reward when a friend's friend learns. No money moves, nobody
  pays in, nobody loses anything, and a child never sees the names of their friends' friends (counts only).
- **Deletion**: deleting the account (in the game, or by the owner on a parent's e-mail: `docs/hosting.md`) and the
  13-month inactivity clean-up remove the invite record, the account's codes and groups, its place in other groups and in
  its inviter's list, and its friends' links to it (`data-retention-and-security.md` covers the rest of the account).

## What the store pages should say (drafts; the lead adds them when the lawyer agrees)
- **Privacy policy** (`privacy-policy.md`), under "What the online server keeps": "If you use an invite code, the server
  keeps which account's code you used and when, and, for the player who invited you, that your account joined and when
  you first finished a School unit. No names, e-mail addresses, phone numbers or contacts are collected. Deleting the
  account removes it."
- **Data safety** (`data-safety.md`): no new data type (account ids and in-app activity were declared already: the
  invite record is "app activity: other in-app actions", linked to the account, not shared, deletable).
- **Children's notice** (`childrens-privacy-notice.md`): one line that invite links carry no personal information.

## Questions for the lawyer
1. Is an in-game (non-money) reward for inviting a friend acceptable under the Families policy and COPPA as built (no
   friend data collected), or should inviting be offered only from the grown-ups' area?
2. Is the two-level "tree" reward acceptable in the EU and UK (consumer law on multi-level promotions) given that no
   money or purchase is involved? If not, the second level's gift is one switch (`ReferralRules.TREE_GOLD = 0`).
3. Should the share text ("Come and learn with me in EasyCraft! My invite code: …") carry any grown-up wording?
4. Class codes: is a teacher's use covered by the school-consent route (COPPA's school exception), given no names are
   shown to other families and only counts are kept?
