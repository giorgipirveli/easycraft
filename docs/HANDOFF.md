# EasyCraft — what only the owner can do (the hand-off list, M5 Task 7, spec §15.6)

Finished 2026-09-26 with release 1.0.1 (`~/Downloads/EasyCraft-1.0.1.apk` for your phone, `EasyCraft-1.0.1-play.aab`
for Google Play; 1.0.0 is the same without the last review's fixes; the acceptance record: `docs/devlog/2026-09-26-release-1.0.0.md`). Everything the lead could do is done
and written down in the project. The steps below need your accounts, your money, your signature or real children,
so only you can do them. Each one says where the prepared material is.

## 1. Google Play (your account "API Studio")
1. ~~**Upload the newest bundle.**~~ **Done:** 1.0.1 is published on the closed test (2026-09-27 00:20). For a later
   version: Play Console → Test and release → Closed testing → Create new release → Upload (the drag-and-drop is yours:
   the browser helper can't upload files over 10 MB) → the notes → Next → Save → Send for review. Full steps:
   `docs/store/play-console.md`.
2. ~~**The store page and the forms.**~~ **Done by the lead on 2026-09-27** (your "do all of them"): the new texts, the
   buddy icon, Data safety and the sign-in instructions for Google's reviewers, approved and live the same night; the 8 new
   screenshots and the feature graphic went up at 02:55 and are in review (`docs/store/play-console.md`). The answers to Google's production questions are in
   `docs/store/pre-launch-checklist.md` (their bracketed parts are yours).
3. **Get 12 testers for 14 days.** Since 2026-09-27 anyone can join, no list to fill: send people the two links.
   (1) https://groups.google.com/g/easycraft-testers/about → **Join group** (any Gmail, no approval);
   (2) on their Android phone, signed in with that same Gmail: https://play.google.com/apps/testing/com.giorgi.easycraft
   → **Become a tester** → install EasyCraft from Google Play. Google counts the 14 days once 12 have joined; aim for
   15. Then **Apply for production** (Dashboard). (Open testing, a link with no group, only unlocks after production.)
4. **Read the pre-launch report** Google makes from your upload (stability, speed, accessibility, security) and send
   the lead anything it flags.
5. **Shop products (only if you want the shop on):** create EasyCraft Plus and the outfit packs in Play Console →
   Monetise, then give the lead their product ids. Until then the shop stays off and the game is fully free
   (`docs/store/README.md`, spec §18).

## 2. Keep the keys safe
- The **upload key** `~/.local/share/godot/keystores/easycraft-upload.jks` and its password file
  `~/.config/easycraft/upload-key.env`: put a copy of both in your password manager. If they are lost, Play support
  can reset the upload key, but that takes days.
- The **server's SSH key** `~/.ssh/easycraft_hetzner` and the server's `.env` (on the server, `~/easycraft/server/deploy/.env`):
  a copy in your password manager too.

## 3. The lawyer
Send them `docs/store/`: the privacy policy, the children's privacy notice, the data-retention and security policy,
Data safety and Families answers, and the trust promise. Also ask them about:
- the **name "EasyCraft"** (a trademark search: the steps are in `docs/store/listing.md`);
- the **costume names** Sherlock Holmes, Aladdin, Pinocchio, Hercules (public-domain characters, but check);
- **verifiable parental consent** for under-13 online play: which provider (or which method) you want. The game asks a
  grown-up behind a parent gate today; the lawyer says whether that is enough where you publish.

## 4. Real phones and real children
- **Your own phone:** install the newest APK from `~/Downloads` (the developer build, package `com.giorgi.game`, sits
  beside the Play one) and play 15 minutes in each universe. Tell the lead anything slow, hard or confusing.
- **Children's playtests** in three age groups (6–8, 9–10, 11–12), with their parents' yes. What to watch for is in
  `docs/design/` (the fair-fun rules); write what you see in `docs/playtests/`.

## 5. Accounts the game can use later (all optional)
- **The Shorts Theater** (YouTube and TikTok clips inside the game) stays off until you make YouTube and TikTok
  developer accounts and give the lead their keys (spec §14.12).
- **The server** runs on your Hetzner machine (178.104.20.64; its address for players is
  https://178-104-20-64.sslip.io). It costs a few euros a month now; if many players come, the lead writes the numbers
  for a bigger machine (`docs/hosting.md`). A real domain name (instead of sslip.io) is yours to buy if you like.

## 6. iOS (later, on your Mac)
An Apple developer account (99 USD a year), Xcode on your Mac, and the project folder copied over. The project keeps
no Linux-only paths, so it opens there; the iOS export is its own step with the lead's help.

## Where everything is
| What | Where |
|---|---|
| The newest APK and Play bundle | `~/Downloads` |
| What each version changed | `docs/playtests/whats-new-*.md` |
| Everything you reported and how it was fixed | `docs/playtests/owner-feedback.md` |
| How the game is built and tested | `docs/DEVELOPMENT.md` |
| The design (the authority) | `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` |
