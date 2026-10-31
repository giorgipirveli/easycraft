# M4 "Better Together" Implementation Plan — accounts, consent, friends and invites, chat, co-op, server-side codes and clock

> **For agentic workers:** parallel background agents in git worktrees with fixed allocations; a
> notes file in `docs/devlog/parts/m4-task-<n>.md`; the lead merges and verifies with two game
> instances over the relay (emulator + desktop). TDD for every rule; server modules in TypeScript with
> their own tests; the Nakama server runs in Docker (`server/`, compose project `easycraft`).

**Goal:** real friends play together online: consent-gated accounts, friends, invites into the host's
world over Nakama's relay, safe chat, co-op revives, and server-side codes, wallet and farm clock.

**Spec:** §5.13–5.14, §7.3–7.4, **§17** (detailed M4 spec), §16 (research must-haves). Foundation:
the M4 early online spike (`docs/devlog/parts/m4-online-spike.md`).

## Global constraints
- **Consent before social features** (§17.2): nothing online for `under_13` without verified parental
  consent; high-privacy defaults; no voice chat.
- Offline, LAN and bots keep working without a server.
- Host-authoritative gameplay over the relay; server-authoritative wallet, codes, reports, farm clock.
- Performance bar on the emulator with 4 players (host) — relay bandwidth measured.

## Tasks
1. **Server foundation** (from the spike): Nakama + DB compose, TypeScript modules build/test, runtime
   config, health RPC; `Session`'s online peer (`NakamaMultiplayerBridge`) hardened (reconnects,
   timeouts, errors shown to children in plain words).
2. **Accounts**: device auth, username registration/uniqueness (server filter), profile backup to
   storage, migration of the local profile.
3. **Consent and age**: parent gate, verification provider integration (Epic Kids Web Services or an
   equivalent — adapter + a fake for tests), local age of consent table, Play Age Signals, the "stay
   safe online" card, privacy defaults, parent controls (approve friends, switch chat/online).
4. **Friends**: requests, accept/decline, list with presence, block/mute, report → console.
5. **Invites and relayed play**: invite toast, join from friends list, host migration: none (session
   ends when the host leaves; world saved), 4 players.
6. **Chat online**: friends DMs and team chat, age rules, server filter, history 30 days (13+).
   6b. **Owner #49 (2026-09-24, 0.3.2 on phones): a chat you can read** (spec §3b): the open chat over
   the rest of the HUD, the phone keyboard never covering the field, the buttons or the newest lines, the
   lines beside the wheel, a dark backing per line, Georgian from the device's font. Done (agent; notes
   `docs/devlog/parts/owner-49-chat.md`, tests `test_chat_readable.gd`); the lead checks on the emulator.
7. **Co-op**: revive teammates, team scaling for waves/bosses, bots fill seats; hide-and-seek with
   friends, team photo, ghost races, buddy playdates, bottle mail, blueprint gifts and showcase visits
   (research additions, ranked; stretch items last).
8. **Server wallet, codes and farm clock**: wallet ledger for Survivor gold, `redeem_code`,
   `farm_collect`, `report_user` RPCs; client paths switch to the server when online.
8b. **Data rights and retention** (added 17:50 from the M5 store drafts, `docs/store/`; a store and
   COPPA must-have): DELETE MY ONLINE ACCOUNT in the grown-up area (server RPC `delete_account`:
   Nakama's account deletion plus every collection of the player, the game forgets its online link and
   keeps offline play), a parent's deletion request by e-mail (the console steps, `docs/hosting.md`);
   the retention clean-up (a server job: accounts without a sign-in for 13 months, DMs older than 30
   days, reports 12 months after review); log rotation of 14 days in `server/deploy/`; a **snapshot of
   the reported message** stored with a report (the reviewer can read what was said; kept with the
   report, then deleted). Tests: Node (RPC, job, snapshot) and GUT (the grown-up flow, the offline
   game after deletion).
9. **Acceptance and release 0.5.0** (lead): two instances over the relay; consent gates; RPCs;
   performance; `~/Downloads/EasyCraft-0.5.0.apk`.
10. **Whole-branch review and fix pass** (lead).

---

## Wave 1 — started 2026-09-24 12:20 (owner feedback #25: "start focusing [on the] online game")
Four agents in parallel from the branch with the M4 spike merged. Fixed allocations so they never
collide (and M2's round-2 agents, running at the same time, keep to their own files):

| Agent | Owns | Must not touch |
|---|---|---|
| **A: world sync + robustness** (Task 1 part + §17.0) | the voxel sync (guests generate from the seed, edits only, paced), `net/relay_bridge.gd` pacing and flow control, reconnect within 30 s, plain-word network errors, byte counting in `tools/net_test.*`; Session section `# --- M4 A: world sync` | `server/`, `ui/online/`, menus |
| **B: server** (Tasks 2, 3 server side, 4 hooks, 8) | `server/modules/src/*.ts` + Node tests `server/modules/test/`, `server/nakama/*.yml`: RPCs `claim_username`, `get_account_state`, `set_parent_settings`, `consent_start`, `consent_status` (provider adapter + a fake), `invite_friend`, `report_user`, `redeem_code`, `farm_collect`, `wallet_award`; hooks: username filter on account update, `MatchJoin` refuses the uninvited and a 5th player, under-13 message rules | any `.gd` file |
| **C: online client + UI** (Tasks 2–5 client side) | `net/online_service.gd` (accounts, friends, presence, invites, notifications over `NakamaLink`), `ui/online/` (PLAY ONLINE screen, username claim, friends list, add by username, requests, invite toast, join, block/mute/report, "stay safe online" card, parent settings behind `ParentGate`), the main menu's PLAY ONLINE button, the pause menu's INVITE row; Session section `# --- M4 C: online play` (`host_online`, `join_online`) | the voxel sync, `server/` |
| **D: hosting kit** (Task 1 part, §11) | `server/deploy/` (production compose: Nakama + Postgres + Caddy with automatic TLS on 443, keys from an `.env` never committed, daily database backup), `docs/hosting.md` (step by step for the owner's VPS, cost estimate from A's bandwidth numbers), `OnlineConfig` production address switch | game code other than `core/net/online_config.gd` |

Shared names (all agents use exactly these):
- RPC ids above (JSON in, JSON out: `{"ok": bool, "error": "<code>", ...}`); errors are short codes the
  client turns into plain words.
- Nakama notification code **101** = invite (`{"match_id", "from_username", "world_name"}`), **102** =
  invite cancelled, **103** = parent approved something. Friend requests use Nakama's own friends API.
- Storage collections: `profiles` (backup), `parent` (settings, consent state), `reports`, `codes`
  (redeemed hashes), `farm`.
- Account metadata: `{"age_band": "under_13"|"13_plus", "consent": "none"|"pending"|"verified",
  "online_allowed": bool, "chat": "off"|"quick"|"filtered"}`.
- Consent until the owner registers with a verification provider: the adapter's **fake** provider
  (developer builds only); release builds keep under-13 players to solo, LAN and bots (§17.2).

## Status (16:05)
- Wave 1 merged: A world sync by edits, B server module (0.2.0), C online client and screens, D hosting kit.
- Wave 2: E chat and co-op **merged** (module 0.2.1), A2 world sync part 2 **merged** (rejoin end to end,
  smooth remote bodies), F accounts/parents/economy **merged 17:53** (module 0.2.2; the review's
  online-gold finding fixed); **Task 8b** data rights and retention (agent G) **merged 19:25** (module 0.2.3).

## Wave 3 — co-op games and friends apart (19:25; research §5.2 ranks 1–3, 5, 6, 8)
| Agent | Owns | Must not touch |
|---|---|---|
| **H: co-op games** | hide-and-seek with friends **and bots** (M3 Task 21's item moves here), the team photo after a boss, Storm Run (§13.7); `ui/games/`, a GAMES section in the pause menu's FRIENDS panel, Session `# --- M4 H` | the pause menu's rows, `server/` |
| **I: friends apart** | `BuildPicker` (M3 Task 8 reuses it), blueprint gifts → stamps, read-only showcase visits with guestbook stickers, bottle mail, buddy playdates; RPCs `send_gift`/`list_gifts`/`open_gift`, `publish_showcase`/`get_showcase`/`sign_guestbook`, `send_bottle` (module 0.2.4; own server `easycraft_i`, ports 7689–7691), `ui/gifts/`, GIFT/VISIT on a friend's row | the voxel sync |
Ghost races on friends' courses follow M3 Task 7 (recorded runs).
Agent H's design (spec §17.5 "Co-op games"): pure rules in `core/games/` (`GameRules`, `HideSeekRound`,
`StormRun`, `TeamPhoto`, `BotGamePlans`, `GameWords`), the host's `GamesDirector` (`world/games/`, node
`Games` on every peer: rounds, bots' game brains, the ring and the stars, the photo line-up), the GAMES
page (`ui/games/`), the HUD's round line and TEAM PHOTO context button, the sticker in the profile, the
Storm Run best in `WorldMeta`; hooks: `BotFriend.game_brain`, `WaveDirector.game_on`, `PhotoMode.take_team_photo`.
- **Agent I done, merged 21:50** (branch `worktree-agent-ac91fdd9b34ab4c88`): module **0.2.4**; SHARE (gifts,
  my showcase), GIFT / VISIT / PRESENTS / MY SHOWCASE on the friends page, the visit scene, bottles,
  playdates, the palette's GIFTS tab; item ids 460–479 (gift stamps). Notes: `docs/devlog/parts/m4-i.md`.
- Next: M4 acceptance (Task 9: two games with consent gates, chat by age, revive, reports) and release 0.5.0
  after M2's 0.3.0; co-op extras (hide-and-seek, team photo, ghost races, buddy playdates, bottle mail,
  blueprint gifts, showcase visits) as a later wave; the owner's internet server (`docs/hosting.md`).
