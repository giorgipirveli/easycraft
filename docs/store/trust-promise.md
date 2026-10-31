# The trust promise (store page, grown-up area) — DRAFT

For the last lines of the store description and the top of SETTINGS → GROWN-UPS (spec §16: "the trust
promise on the store page"). Every line must stay true in every release; the whole-game review (M5
Task 6) checks each one against the build.

**Our promise to kids and parents**
1. **No ads.** Not now, not later.
2. **Nothing random for money.** No loot boxes, no paid spins; if we ever sell something, a grown-up
   approves it and it shows exactly what you get. *(Owner #35, spec §18: EasyCraft Plus and outfit
   packs are bought only in the grown-up area behind the parent gate, after a page with every item and
   the price; nothing random, no currency, nothing needed to play — this line stays true, checked by
   `tests/unit/test_shop_catalog.gd` and `tests/integration/test_shop_grown_up.gd`.)*
3. **No streaks, no guilt.** Missing a day never costs anything; the game offers good places to stop.
4. **Private by default.** Online play for under-13s is off until a parent says yes; friends only by
   invitation; picture phrases instead of typing; no voice chat.
5. **Your data stays small.** No real names, no birth dates, no location, no tracking — and a grown-up
   can delete the online account at any time.
6. **People review reports.** A tap on REPORT reaches a person, not just a filter.

**In the game (M5 Task 4, 2026-09-25):** the grown-up area's PRIVACY page (SETTINGS → GROWN-UPS → the parent gate →
PRIVACY) shows the promise as six short lines (`GrownUpsPanel.PROMISE`): "No ads, not now and not later.",
"Nothing random for money.", "No streaks and no guilt.", "Private by default.", "Your child's data stays small.",
"People review every report.", with buttons to the privacy policy
and the deletion page. The store listing's last section ("Made for kids, trusted by parents", `listing.md`) carries
the same promise. **Checked for 0.4.0:** every line is still true (no ads; the shop is closed and would be fixed-price
and parent-gated; no streaks; online off for under-13 until verified consent; age band only; reports reach the
Nakama console for a person).
