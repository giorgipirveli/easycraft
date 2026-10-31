# Store readiness (M5 Task 4, spec §15.4, §15.6)

Written by the lead on 2026-09-24 from what the game and its server really do (M1–M4 as built:
`server/README.md`, spec §5.12–§5.14, §17); **checked against release 0.4.0 and finished for the console by the M5
Task 4 agent on 2026-09-25** (`docs/devlog/parts/m5-task-4.md`). **These are drafts, not legal advice.** A lawyer
reviews the privacy policy, the children's notice and the data answers before the production release (spec §5.14,
§15.6).

**Start here: `pre-launch-checklist.md`** — what must be true before "Apply for production", who does each step, the
drafted production-access answers, and the findings. The owner's whole hand-off list (keys, lawyer, real phones,
iOS) is `docs/HANDOFF.md`.

| File | What | Who finishes it |
|---|---|---|
| `pre-launch-checklist.md` | Everything before "Apply for production": 12 testers × 14 days, the production-access answers, the console changes, the lawyer's questions, the consent provider, Play Billing, the findings | The owner and the lead, tick by tick |
| `listing.md` | Store name, the final short and full descriptions (English only, owner #52), category, art direction, the trademark note | Owner approves the words; the lead pastes them |
| `screenshots.md` | The shot list for the lead: 8 screenshots, the feature graphic and the icon, with the set-up of each (mode, universe, chat commands) and Play's size rules | The lead, on emulator-5554 |
| `data-safety.md` | Google Play **Data safety** form, answer by answer, every 0.4.0 feature checked, and exactly what to change in the console | The lead makes the changes; the owner's lawyer checks |
| `families-and-rating.md` | **Target audience and content** (Families policy) and the **IARC** content-rating answers, as submitted, with what 0.4.0 changes (nothing) and what future releases change | Owner submits changes when "Later" happens |
| `privacy-policy.md` | The privacy policy (plain language, children first); the public page is made from it | Lawyer reviews; the lead regenerates (`python3 tools/make_store_pages.py`) and deploys |
| `refer-a-friend-note.md` | Invite a friend (owner #79, module 0.2.16): what it collects (no friend data), the rewards (game gold only, tied to learning), the two-level tree, deletion, draft lines for the policy, and four questions | The lawyer answers; the lead adds the policy lines |
| `delete-account.md` | The public "delete your account" page (and deleting only some data) | Same as the policy |
| `childrens-privacy-notice.md` | The notice a child can read (short words, pictures); not in the game yet (M5 art work) | Lawyer reviews; built with its pictures in M5 |
| `data-retention-and-security.md` | The written data-retention and security policies (COPPA 2025 rule) | Owner adopts them; the server follows them |
| `trust-promise.md` | The trust promise for the store page and the grown-up area (now on its PRIVACY page) | Owner approves |
| `play-console.md` | How versions are uploaded, and the console's state | The lead |
| `reviewers-and-testers.md` | The 12 testers, and trusted reviewers for a kids' game | The owner |

**Facts these drafts rely on** (change a draft when one changes; checked for 0.4.0 on 2026-09-25):
- No ads, no analytics, no crash reporting, no third-party SDKs that collect data. Android permissions:
  `INTERNET`, `ACCESS_NETWORK_STATE`, `VIBRATE` (`export_presets.cfg`); the Play bundle's plugins add none (the
  Theater's WebView library asks only for `INTERNET`).
- Offline play (Sandbox, Survivor, LAN, bots) sends nothing anywhere. The profile lives on the device
  (`user://profile.json`): the online name if claimed, the **age band only** (never a birth date),
  settings (read-aloud, controls, sound), gold, unlocks, progress, quests, Pip's lessons, the books, costumes owned; play time,
  the Memory Book and the boy/girl choice stay on the device (never in the backup).
- Online (Nakama, the owner's server, `docs/hosting.md`): a random device id (`user://device_id.json`)
  signs in; stored are the username, age band, consent state, parent settings, friends and blocks, the
  profile backup (without the boy/girl choice and the phone-only settings), Survivor gold and its ledger, redeemed
  code hashes and a wrong-code counter (the typed code is checked, never stored), the farm clock, invites, rate
  limits, reports, shared builds (presents, bottles, the showcase, stickers) and **ghost races** shared with
  friends, and DM history **only between two 13+ players with text chat, 30 days**; never for an under-13 player,
  never in team rooms. Notifications (invites, friend notes) at most 30 days; the age band only ever gets stricter
  from the game (module 0.2.8: an under-13 account is never lifted to 13+ by a game). **Trades** between players pass through the relay and are not stored (the gold moved is in
  the ledger). A parent's contact for consent goes to the consent provider and is never stored by us
  (`consent_start`).
- Photos go to the phone's gallery (Pictures/EasyCraft); sharing opens Android's share sheet (the child's choice
  each time). Read-aloud uses the phone's own text-to-speech; bot friends understand the chat inside the game.
- The Shorts Theater (YouTube/TikTok embeds) is **off** until the owner provides API keys and turns it
  on from the server (§5.12, §14.12). Its answers are marked "(Theater)" or "Later" and change when it is on.
- Voice chat: none, ever (§17.2).
- Payments (owner #35, spec §18): **parent-gated** purchases through Google Play Billing — EasyCraft Plus
  and cosmetic packs, one-time, fixed prices, only in the grown-up area behind the parent gate. The
  Play backend is **off** until the owner creates the products in Play Console and sets their ids in
  `core/shop/shop_catalog.gd` (`PLAY_IDS`); until then release builds say "The shop isn't open" and
  every "purchases" answer stays "No". The profile keeps owned product ids (and the child's wish
  list), nothing about payments.
- The privacy policy is inside the app: SETTINGS → GROWN-UPS → (the parent gate) → PRIVACY opens
  https://178-104-20-64.sslip.io/privacy (`OnlineConfig.privacy_url`, M5 Task 4).
