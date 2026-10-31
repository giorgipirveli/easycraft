# Owner #99: the adversarial security and data-safety review (2026-10-15 22:24)

Reviewed: branch `worktree-agent-a45831f837d05a838` (module 0.2.20) against lead-merge, read-only, by a separate agent.
Its throwaway server tests (9/9, each reproducing a finding): copied to `docs/devlog/parts/accounts-99-review.test.ts`.
**Verdict: not merged, not deployed.** The fix round waits for the owner's word (#102 hold).

I found one high-severity hole and four medium ones. The first review's two fixes do hold: there is no presence leak, and every count is a versioned write that fails closed. But the move's main protection against a stranger, the parent gate, does nothing in shipped builds. Nothing in the worktree was changed. My throwaway server tests (9/9 pass, each reproducing a finding) are in `/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/review99/mod/test/review99.test.ts`, run against a scratch copy of the module. The module's own move and key tests pass there too (55/55).

## Findings, by severity

**1. HIGH: a stranger can take a child's account by telling her a code, then lock her out. CONFIRMED.**
- **The gate is off.** `ui/online/grown_up_gate.gd:28` passes the gate at once when `AgeBand.restrictions` is false, and `core/validation/age_band.gd:13` ships it false. So TYPE THE CODE (`move_ask_card.gd:106-111`) goes straight to the number pad. The tests never see this because `tests/pre_run.gd:8` turns restrictions on for every test.
- **Chat carries the code.** Everyone gets filtered free chat (age rules are off), and the filter only blocks runs of 7 or more digits (`chat_rules.ts:14`, `:104-108`). R1: "482913", "482 913", "4 8 2 9 1 3" and "482-913" all get through.
- **The attack:**
  1. The stranger knows the name (from an online world or friends) and calls `move_request start`, choosing `kind: "phone"` so the card looks like her own phone.
  2. In chat: "tap TYPE THE CODE and type 482 913 for free gold".
  3. She types it and the stranger gets the one-time key.
  4. With plain RPC calls the stranger then runs `account_key sign_out_others` with their own device id (`keys.ts:86`), which unlinks her phone, and `account_key new` to keep a way back in.
  5. Her phone's next sign-in quietly creates a fresh account (the client creates one by default). R2 reproduces all of this on the server.
- **What the stranger gets:** her friends, 30 days of DM history, and the ability to chat as her.
- **No lasting warning.** The "moved" note is sent non-persistent (`moves.ts:52`), so a phone that is offline at that moment never hears it.
- **Fixes:**
  - Make the move approval's gate independent of `AgeBand.restrictions`: always use the real ParentGate here.
  - Block 4 or more digits in chat.
  - Refuse `sign_out_others` and `account_key new` from a device linked by a move within the last 7 days.
  - Store a persistent "a new device joined" record on the account, with THAT WASN'T ME to unlink that one device.

**2. MEDIUM: a stranger can block a child's move and her key sign-in indefinitely, and push about 20 cards an hour onto her devices. CONFIRMED.**
- **R3:** four throwaway accounts (new accounts cost nothing) keep the name's window full (5 asks per 15 minutes). Every one of the family's own asks becomes a decoy that reaches no device, while the stranger's 20 cards an hour pop up over every scene and are read aloud.
- **R4:** three stranger asks made after the family's push it out (OPEN_MAX), but the family's new device still shows "waiting".
- **Wrong ask on the card.** The card always shows the newest ask (`move_ask_card.gd:76`), so the grown-up types the family's code into the stranger's ask and gets "wrong".
- **R5:** five wrong keys lock the name for 15 minutes, longer than the 5-minute life of an approved key. That disproves ruling 4's "the key still works".
- **Fixes:**
  - Let the approver pick an ask, or try the typed code against every open ask of the account.
  - Count asks per target account rather than in one shared name window, or give approved and family asks priority.
  - NOT ME should mute that asker for a while.
  - Put a cap on account creation.

**3. MEDIUM: LOG OUT never removes anyone from the device. CONFIRMED.**
- `AccountList` and `AccountsFlow` have no way to remove a kept player.
- Anyone who ever logged in on a shared or school tablet stays one tap away in Who is playing?, with no PIN and the gate off. Whoever taps gets that child's chat and DM history, OTHER DEVICES (sign out others, make a key) and DELETE ACCOUNT.
- Ruling 7's "nothing is lost or sent anywhere" is not true.
- **Fix:** add REMOVE FROM THIS DEVICE (after the save), or make LOG OUT forget the credential once the account has a name and another device or a key.

**4. MEDIUM, PLAUSIBLE (traced, not run): a switch does not wait for online work already on its way, so the last player's results land in the new player's files.**
- `AccountsFlow._switch` (`accounts_flow.gd:109`) only checks its own busy flag. `forget_session` does not stop calls in flight, and several of them write to the shared `Profile.data` and the root files after their await, with no check that the session is still the same:
  - **Profile mixing:** `profile_sync.gd:112` `_take(remote)` merges A's server backup into B's profile and saves it.
  - **Wrong name:** `online_service.gd:125` sets `account` to A's. `sign_in` then marks the game ONLINE with no link (it stays stuck that way), and `_o67_take_account_name` (`:1912`) renames B's profile to A.
  - **Gold double:** `_f_sync_read` writes A's marker into B's `wallet_sync.json`. A's own file keeps the old marker, so A's next sync reports the same gold again.
- **Realistic trigger:** a network blip while the child is on Who is playing? makes the reconnect watcher sign A in, and the child taps another player during that sign-in.
- **Fixes:**
  - Refuse the switch while the service is connecting, syncing, paying or sending, or while the profile sync is busy.
  - Add a session counter that `forget_session` bumps; every coroutine checks it, or `backend.user_id()`, before writing anything.

**5. LOW-MEDIUM: a failed final write leaves the files swapped but the old player in memory. CONFIRMED by trace; needs a storage write failure.**
- `AccountList._finish` returns `save()`'s error after `current` has already changed (`account_list.gd:164`). `to_new` can also fail writing `device_id.json` after the swap (`account_switch.gd:72`).
- `AccountSwitch.to`/`to_new` then return without `_after()`. `Profile.data` is still the old player, so the next `Profile.save` writes it over the incoming player's `profile.json`.
- A failed rename when files come back in only logs a warning (`:222`). The next swap-out then deletes that leftover folder (`:205`), losing those worlds.
- **Fix:** run `_after()` whenever `list.current` changed, and never delete a non-empty destination folder.

**6. LOW: retention and deletion leftovers. CONFIRMED.**
- **R6:** the 30-minute clean-up of ended asks only happens when the book is written again, because `list` (`moves.ts:240`) never saves its tidied copy. Ended asks, with the asker's id and the code, stay stored indefinitely.
- **R7/R8:** deleting the asking account leaves its id in the child's ask book, and deleting the child's account leaves her id in the asker's pointer.
- **Docs not updated:** the store drafts (`privacy-policy.md:64-65`, `data-retention-and-security.md:20-22`) don't list the new objects. They still say devices are linked only by a grown-up, and they say SHA-256 where the code uses bcrypt (that last drift was there before #99).

**7. LOW (traced).** The asker's pointer is written without a version check, so two `start` calls at once from one account leave an extra open ask: one account can fill the open slots.

**8. LOW.**
- A phone on a pre-#99 build gets the ask but has no card, so the new device waits out 5 minutes behind "open EasyCraft and type this code there". The words should mention updating, or offer USE A KEY.
- After a successful move, if the sign-in answer is lost (R9), a retry is refused and the child must start a new move. It recovers.
- By design: YES, IT'S ME from the claim screen merges the local player's progress and any gold beyond the server's into the account.

## Checked and sound
- **The code itself:**
  - It comes from the server's own randomness (UUIDs), separate from the ask id.
  - It never appears in a notification, the log, or anything the game can read.
  - It is bound to one ask id, and the asker never types a code, so there is nothing to brute-force.
  - Three wrong tries end the ask.
- **The one-time key:**
  - It is bound to the asking account and its newest ask only; the "approved" note carries no id.
  - Only the newest key's hash is kept, at most 5 are handed out, and the 5-minute limit is checked twice.
  - It is used up by a versioned write before the device is linked, so a second use fails.
  - NOT ME, BACK, replacement and expiry all end an approved ask too.
  - The wrong-key lock is checked before the key.
- **Accounts and names:** the self-ask is refused. A deleted and recreated name is a new account id, so old pointers don't match. Names are ASCII-only, and lowercase quirks only map to the same name.
- **The two earlier fixes:** they hold. The decoy's few milliseconds is the only remaining timing tell, as documented.
- **Old builds and deletion:** code 110 is new and old builds ignore it. `sign_in_with_key` answers as before. The new objects are removed on account deletion via the `account` and `limits` collections.
- **Device side:**
  - The swap journal recovers from a kill at any step: Profile is the first autoload that touches player files, and recovery runs before the profile is read.
  - The per-player file list covers every per-player path in the game.
  - LOG OUT refuses while gold reports or codes are still waiting.