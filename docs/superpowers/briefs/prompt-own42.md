# Owner feedback #42 — more secrets, chests and treasures
(Use `owner-common.md` as the house rules header.)
The owner (2026-09-24 20:43): "also please create more secrets in the game" and "more chests and treasures".
Read M2 Task 16 (`docs/devlog/parts/m2-task-16.md`: `SecretRules`, `SecretDirector`, the Secret Book, chests and treasure, `SurpriseRules`, rarity colours §13.2, treasure maps, the dog/fox sniffing), the desert's secret kinds (`DesertSecretRules`), the universes' descriptors, row #42.
Add secret kinds (deterministic from the seed, chunk-seam safe like `SecretRules`, never blocking paths, host-decided, saved as found):
- **Shipwreck** on a beach (a small broken ship of planks/logs) with a chest, and **sunken chests** on the seabed (swimming, M2 Task 14).
- **Mineshaft**: a short tunnel with rails-like planks, torches (lanterns), and a **loot cart** chest.
- **Dungeon vault** deep underground: a small room behind a puzzle (three levers or plates in the right order — reuse M3 Task 7's smart blocks if merged, else plates), a legendary chest.
- **Waterfall cave** behind a waterfall; **hollow tree** with a chest in its trunk.
- **Rainbow's end**: after rain (or at sunrise if there is no rain yet), a rainbow arch appears; at its end a **pot of gold** (Survivor gold, fixed, once per rainbow).
- **Wishing well** in a village-like clearing: toss a coin, a friendly sparkle and a small fixed gift once a day of play (not a timer that pressures — just once per in-game day).
- **Pirate cove**, **ancient ruins**, a **friendly haunted house** (gentle ghosts that giggle and give a riddle), **campsites** with a supply chest.
- **Chest rarities**: common, rare, epic, legendary with the §13.2 colours and a glow; contents from fixed tables by rarity and universe (never random for money; a random pick from a fixed, free table is fine).
- Secret Book pages for the new kinds, with picture riddles; the dog/fox/parrot hints know them.
Tests: each kind's placement rules (determinism, seams, spacing, never on paths), chest tables by rarity (no gold loops, no dupes), the vault puzzle, rainbow timing, the well's once-a-day rule, the book pages and hints. Notes: `docs/devlog/parts/owner-42-secrets.md`.
