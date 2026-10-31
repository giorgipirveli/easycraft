# Owner feedback #48 — girl avatars ("when choosing avatar there should be avatar of girls as well" + "beautifull girl")
(Use `owner-common.md` as the house rules header. Start from main after the 22:xx merges; M3 Task 9's avatar
editor and the #35 shop's packs are the base: `core/avatar/` (AvatarCatalog, AvatarLook, AvatarUnlocks),
`entities/player/` (AvatarParts, AvatarSkin, blocky and realistic avatar models), `ui/avatar/` (AvatarEditor,
AvatarPreview, AvatarTile). Read `docs/devlog/parts/m3-task-9.md` and `docs/devlog/parts/owner-35-shop.md` first.)

The owner (2026-09-24 22:53) wants the avatar choice to include girls, and beautiful ones. Build a lovely,
child-appropriate girl look in both graphics styles: stylised and cute, like a cartoon heroine. Never
sexualised: no body shaping, no makeup beyond cartoon eyelashes and rosy cheeks, child-appropriate clothes.
1. **A first choice: BOY or GIRL** (or "Just me", which keeps today's neutral look) at the top of the avatar
   editor and in the first-launch flow's avatar step. It picks a matching starting look; after that every part
   stays free to mix (a girl can wear a cape and a boy long hair), so the choice is a starting point, not a lock.
   Save it in `AvatarLook` (e.g. `base: &"boy" / &"girl" / &"neutral"`), read old profiles as neutral.
2. **Girl parts, all FREE** (never behind gold or purchases: a child's gender look is never for sale):
   - Hair: long straight, ponytail, two pigtails, braid, bun, curly bob, with bangs; the existing hair colours
     plus pink, purple and blonde. Hair clips and a flower crown as HAT items.
   - Face: eyes with cartoon eyelashes, a sweet smile, rosy cheeks (in the face atlas, both styles).
   - Clothes: a dress and a skirt (as OUTFIT/PANTS parts that suit the blocky body and the realistic body),
     leggings, a hoodie, overalls; colours children like (pink, lilac, mint, sky blue, yellow).
   - Two ready-made **beautiful girl presets** (e.g. "Adventurer" with a ponytail, a jacket and boots, and
     "Princess of the Realms" with a flower crown and a dress) and two boy presets, one tap each.
3. Remote players, bots and the showcase show the look the same way (the look is already synced in M3 Task 9).
   Bot friends get a mix of girl and boy looks, so the default team isn't all boys.
4. Tests first: the catalog has the girl parts free in both styles, the presets are valid wearable looks, the
   BOY/GIRL choice picks the starting look and every part can still be mixed, old profiles load as neutral, the
   look syncs, and no girl part is for sale (a scan of the shop catalog and gold prices).
Notes: `docs/devlog/parts/owner-48-girl-avatars.md`; update spec §14.5 (avatar) and the plan first. Check both
graphics styles in the editor's preview, and screenshots for the lead.
