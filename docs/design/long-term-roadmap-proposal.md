# EasyCraft — Long-term roadmap proposal (engagement and child psychology)

- **Date:** 2026-09-24
- **Status:** proposal for the lead. It extends the spec's roadmap (§8) and does not change it yet.
  The lead decides what goes into the spec and the plans.
- **Based on:** `docs/design/engagement-and-child-psychology.md` (the research and the catalogue).
  Item codes like **F3** or **P5** point to that catalogue (section 5 there).
- **Owner's request (2026-09-24):** "analyze what is exciting in the game and what can we add in our
  long term plan, how to make the game more attractive, research childrens psychology and add tricks
  into game plan". "Tricks" here means healthy, honest engagement techniques (catalogue §6); the tricks
  we reject are in catalogue §7.

---

## 1. How the items were ranked

Each item has two numbers:

- **Impact** on children's enjoyment, 1 (small) to 5 (huge) — the lead designer's judgement, based on
  the research in the catalogue and on what the games children love do.
- **Effort:** **S** = up to about a day for one agent (counts 1), **M** = about one plan task
  (counts 2), **L** = two or more plan tasks (counts 4).

**Score = impact ÷ effort.** Items are listed from the highest score down. Two exceptions are marked:
- **Must** — required by store rules or law for that milestone (catalogue §8), whatever the score.
- **Signature bet** — lower score because it is big, but it is the kind of moment children tell their
  friends about, so it is worth the cost.

---

## 2. Signature moments

The game should be built around moments a child tells a friend about the next day. These ten are the
targets. Every milestone should add at least one, and every playtest should ask "what would you tell a
friend?" to see which ones land.

| # | The child says… | What happens | Why it sticks | Items | Milestone |
|---|---|---|---|---|---|
| 1 | "My build **woke up and blinked at me!**" | Sparkles swirl, the camera leans in, two eyes blink open, a name appears with a tune | The child's own creation comes alive — pride (IKEA effect) and magic | F3 | **M2** (polish of an M1 feature) |
| 2 | "My **dog dug up a treasure chest!**" | The pet sniffs, barks, digs a little hole; the child digs the rest and finds a chest | A companion that helps; a surprise the child caused | P1 | **M2** |
| 3 | "I hid in a barrel and **the goblin walked right past me!**" | Muffled sound, closed-eye icon, the goblin's "?" turns away | Hide-and-seek, the oldest childhood game; tension that ends in relief | G5, T6 | **M2**, mode in M3/M4 |
| 4 | "We beat the Stone Golem — **and it turned into a tiny Pebble Golem that follows me!**" | The Golem crumbles; a small, sleepy Pebble Golem hops out and becomes a buddy | A scary enemy becomes a friend; kindness wins | P5 | **M3** (M2: a Golem statue trophy) |
| 5 | "I built a dragon and **flew on it!**" | A saddle block + wand = a rideable buddy that flies, drives or swims | The ultimate "Build it. Bring it to life." | X1 | **M3** |
| 6 | "My snowman **sings!** I found a secret shape!" | A build in a secret shape gets a special personality; the Secret Book page "Buddy recipes" fills | A discovery that others want to copy | D1 | **M3** |
| 7 | "I shrank and found **a mouse village inside the hill!**" | A mouse hole visible only when Tiny leads to a tiny village with treasure | A hidden world only you can see | D4 | **M3** |
| 8 | "My buddy **learned my dance!**" | Dance three times near your buddy or pet; it copies you from then on | "I taught it" — competence and friendship | P2, X4 | **M3** |
| 9 | "A **baker moved into the house I built!**" | A proper room (door, light, bed) attracts a villager who lives there and helps | Building has a purpose; the base comes alive | R7 | **M4** (M3 if time allows) |
| 10 | "My friend raced **my obstacle course** and got bronze — I got gold!" | Game Blocks course, medals, ghost races | Creating something others play; friendly rivalry | T2 | **M3** (bots), **M4** (friends) |

Already in the M2 plan and on the same level: the shooting star that lands near your house, the fake
wall that opens with a hollow knock, and the first night survived. They need good juice (sound,
sparkles, the secret chime **F8**) to become stories.

---

## 3. M2 "Survive the Night" — quick wins

**M2's scope stays as it is** (plan `docs/superpowers/plans/2026-09-24-m2-survive-the-night.md`,
Tasks 1–16). These are small items (all **S**) that ride along inside tasks that are being built
anyway. The "Where" column says which task owns each, so agents can pick them up without new
allocations.

### 3.1 Do these first (top 8)

| # | Quick win | Item | Where in M2 | Impact | Why now |
|---|---|---|---|---|---|
| 1 | **Icon-first buttons** with a small word underneath; JUMP and ATTACK ≈ 225 px in the 1280 × 720 design space (≈ 2 cm on a 6" phone), every other button ≥ 135 px (≈ 1.2 cm); rarely used ones (CAM, MIRROR) may move into a small menu | O1 | Lead (HUD, `ui/hud/hud.gd`); CROUCH in Task 5 | 5 | Buttons are about 0.85 cm today; children under 9 need about 2 cm; 6–8-year-olds are beginner readers |
| 2 | **First-time picture hints** (first night, first ore that needs iron, arrows to Tilly and the Totem) and **picture tips after a knock-out** | O5, G2 | Tasks 2, 3, 7, 9 | 5 | Survivor has many new systems and no tutorial until M3 |
| 3 | **Break ring and place pop** | F1 | Task 3 (gathering touches the block interactor) | 4 | Holding does something invisible today; young children leave fingers down longer |
| 4 | **Buddy wake-up ceremony** | F3 | Lead or any free agent (`entities/buddy/buddy.gd`) | 4 | Our signature moment deserves the best juice (signature moment 1) |
| 5 | **Picture riddles** for temple notes and the Wanderer's three answers | O2 | Task 16 (content) | 4 | Text riddles exclude 6–7-year-olds; it is cheaper to write them as pictures now than to redo them |
| 6 | **Cozy / Normal / Brave** choice for a new Survivor world (Cozy: monsters do half damage and no block bag; Brave: harder hits and a name-tag badge; same gold for all) | G1 | Tasks 1–2 (`ModeRules`, knock-out rules) | 4 | One difficulty cannot fit ages 6 to 12; scared children need a way in |
| 7 | **Your dog finds treasure**: a pet within about 12 blocks of an unfound buried chest sniffs, barks and digs a small hint hole | P1 | Task 16, with the M1b animal code | 4 | Signature moment 2 for very little code |
| 8 | **Bot friends' rules**: robot badge; lines that admire the child's builds; never "don't go", never pretend to be real children, never ask for anything | T1 | Task 15 (content and tests) | 4 | Companions are powerful; guilt from characters is a common manipulation (about 1 in 4 apps young children use) |

### 3.2 If time allows

| # | Quick win | Item | Where in M2 | Impact |
|---|---|---|---|---|
| 9 | **Honest Golem help:** after a loss, "You got it to 20%!"; after 3 lost fights the Golem arrives "tired" (−25% health) and says so | G3 | Task 10 | 3 |
| 10 | **Sleep and save:** the sleep screen offers *Wake up* and *Stop for today* (equal buttons), "Your world is saved" | H1 | Lead (`ui/hud/sleep_overlay.gd`) | 3 |
| 11 | **Never colour alone:** tool tiers get 1–5 dots or stripes, not only colour | A1 | Task 6 | 3 |
| 12 | **Reduce motion and flashes:** a setting for screen shake and camera bob; nothing flashes more than 3 times a second | A2 | Task 11 | 3 |
| 13 | **Danger arrow** at the screen edge when a monster's "!" is aimed at you (for muted play and deaf children) | A3 | Task 5 | 3 |
| 14 | **The secret chime:** one short tune for every secret found | F8 | Task 16 | 3 |
| 15 | **Portal peek:** the portal after the Golem shows sand blowing out of a window into the desert | D8 | Task 10 | 3 |
| 16 | **Short numbers and have/need bars** ("1.2K" with a coin; "340 / 1200" bars at Tilly's) | F9 | Tasks 1, 7 | 2 |
| 17 | **No-guilt word test:** a GUT test that fails if any player-facing string contains "miss you", "don't go", "last chance", "hurry", "only today", "you'll lose", "come back" | H3 | Lead (`tests/unit/`) | 2 (protects forever) |
| 18 | **Monsters never break player builds** — state it as a rule with a test now, before M3's diggers | G4 | Task 4 | 2 (protects the IKEA effect) |

**Also inside normal M2 polish:** hit feel (a short hit-stop, squash, confetti — **F4**) in Tasks 4
and 6, and hiding that feels safe (muffled sound, cosy vignette, closed-eye icon — **G5**) in Task 5.

---

## 4. M3 "Worlds of Wonder"

The spec's M3 is already large: universes 2–4 and the ladder, portals, the Secret Book for new
universes, the avatar editor, pets, the Gold Farm, Pip's tutorial, admin codes, missions, the Physics
Lab, smart blocks, the Shorts Theater, photo mode, Game Blocks, Build-and-Wear and Build Rewind. So the
proposal splits additions into a **core set** (recommended for M3) and a **stretch set** (M3 if there
is time, otherwise early M4).

### 4.1 Changes to items already planned for M3 (do these whatever else happens)

| Spec item | Change | Item | Why |
|---|---|---|---|
| §5.8 "3 daily missions and a daily gift" | An **adventure board**: 3 picture goals the child picks, which never expire; a new one appears when one is done. **No daily login gift**; instead, pets sometimes bring a present *while the child plays* | R4 | Daily gifts are appointment mechanics; rewards should follow play, not returning |
| §5.6 Gold Farm notification | **Off by default**; for `under_13` only a parent can switch it on; at most one a day; never 20:00–08:00; only informative | H4 | UK Children's Code standard 5 (notifications are "sticky" features) |
| §5.12 Shorts Theater | For `under_13`: no autoplay of the *next* video; an end card after 5 videos; a parent switch; the first channel is **EasyCraft TV** (our clips and the child's own Build Rewinds) | H6 | Autoplay undermines children's self-regulation |
| §5.7 and §5.11 admin codes | Codes are also hidden **in the game** (the Wanderer, bottles, a news board at spawn); no short expiry | H7 | Most social networks are 13+; children should not need them |
| §5.10 Pip's tutorial | **Voice-first and icon-first** (babble voice, pictures, one action per step, replay any step) | O4 | Many players cannot read yet |
| §5.9 photo mode | Also feeds the **Animal Book** and the **Memory Book** | C1, R2 | One feature, three uses |
| §5.9 emotes | A **free base set** of emotes and dances | X4 | Self-expression and wordless talk must not be paid status |
| §3a Game Blocks | **Medals and ghost races against bots** in M3; against friends in M4 | T2 | Gives creators an audience before online play exists |

### 4.2 Core set (ranked by score)

| Rank | Item | Code | Impact | Effort | Score | Notes |
|---|---|---|---|---|---|---|
| 1 | Read-aloud button on any game text (Godot `DisplayServer.tts_speak`) | O6 | 4 | S | 4.0 | Enable text-to-speech in project settings; never read chat |
| 2 | Pets find more secrets (cat meows at fake walls, rabbit finds mouse holes) | P1 | 3 | S | 3.0 | Builds on the M2 dog |
| 3 | Trophy shelf for treasure decorations | C3 | 3 | S | 3.0 | Showing off at home |
| 4 | Idea cards ("A house for your dog") — no reward attached | X5 | 3 | S | 3.0 | Helps the blank canvas |
| 5 | Wish list with a progress bar | R3 | 3 | S | 3.0 | A goal the child chooses |
| 6 | Honest help for every boss (Sand Serpent, Frost Giant, Cake Monster) | G3 | 3 | S | 3.0 | Same rule as the Golem |
| 7 | The Totem asks "Try again" or "Try an easier wave" | G6 | 3 | S | 3.0 | Player-chosen difficulty |
| 8 | Secret Book page-complete rewards (a hat + a Hub Tree ornament) | C4 | 3 | S | 3.0 | Needs R1 for the ornament |
| 9 | Material sounds and a building melody | F2 | 3 | S | 3.0 | CC0 sounds |
| 10 | Wake more world objects (snowman, pumpkin, cactus, a chest "mimic") | D2 | 3 | S | 3.0 | Per universe: cacti in the desert, snowmen in Frostpeak |
| 11 | Message in a bottle (solo: picture riddles and map pieces) | D5 | 3 | S | 3.0 | Becomes social in M4 |
| 12 | Other ways to break and aim (BREAK toggle, hold time, aim-assist strength) | A5 | 3 | S | 3.0 | Accessibility |
| 13 | "Simple controls?" choice at first launch | O8 | 3 | S | 3.0 | Needs A6 |
| 14 | **Secret buddy shapes** (Buddy recipes page) | D1 | 5 | M | 2.5 | Signature moment 6 |
| 15 | **Buddy Album and My Stamps** | C2 | 5 | M | 2.5 | Uses M3's planned copy/paste |
| 16 | **Befriend a monster** with the wand | P4 | 5 | M | 2.5 | A kind alternative to fighting |
| 17 | **The boss becomes a friend** (mini-buddy per boss) | P5 | 5 | M | 2.5 | Signature moment 4 |
| 18 | **Simple controls** (auto-jump, camera follows, context buttons) | A6 | 5 | M | 2.5 | The biggest control win after O1 |
| 19 | Teach pets and buddies tricks | P2 | 4 | M | 2.0 | Signature moment 8 |
| 20 | The Tiny world (mouse holes and villages) | D4 | 4 | M | 2.0 | Signature moment 7 |
| 21 | The Animal Book | C1 | 4 | M | 2.0 | Collecting age |
| 22 | The Hub Tree at spawn | R1 | 4 | M | 2.0 | Progress you can see |
| 23 | The Memory Book | R2 | 4 | M | 2.0 | Pride; parents see it |
| 24 | Gibberish voices for characters | F7 | 4 | M | 2.0 | Personality without reading |
| 25 | Languages: all strings in translation files (the owner's language + English first) | O7 | 4 | M | 2.0 | Foundation now; more languages in M5 |
| 26 | Parent corner on the device (play time, gentle reminders at natural stops, switches, "what they built") | H2 | 4 | M | 2.0 | Parents as allies |
| 27 | Hide-and-seek mode with bots | T6 | 4 | M | 2.0 | Reuses M2 stealth |
| 28 | **Rideable buddies** | X1 | 5 | L | 1.25 | **Signature bet** (moment 5) |
| — | Notifications off by default | H4 | — | S | — | **Must** (see 4.1) |
| — | Theater guardrails for under-13s | H6 | — | S | — | **Must** (see 4.1) |

### 4.3 Stretch set (M3 if time, otherwise early M4)

| Item | Code | Impact | Effort | Score |
|---|---|---|---|---|
| Home and pretend-play pack (furniture stamps, job hats, TV with Build Rewinds) | X3 | 4 | M | 2.0 |
| Play-style titles ("Buddy Maker", "Monster Friend") | R5 | 2 | S | 2.0 |
| Happy greetings; pets sleep at your bed | P3 | 2 | S | 2.0 |
| Movement flourishes | F6 | 2 | S | 2.0 |
| Haptics | F5 | 2 | S | 2.0 |
| First-time badges | C5 | 2 | S | 2.0 |
| Crowns for experts | G7 | 2 | S | 2.0 |
| Text size and a clear font | A7 | 2 | S | 2.0 |
| Free emotes and the team high-five | X4 | 3 | M | 1.5 |
| Build-and-Wear for pets | X2 | 3 | M | 1.5 |
| A living sky (rainbows, fireflies, meteor showers, snow) | D3 | 3 | M | 1.5 |
| The sleeping giant | D6 | 3 | M | 1.5 |
| Button size slider, movable buttons, left-handed layout (promised in §5.15) | A4 | 3 | M | 1.5 |
| **Neighbours move in** | R7 | 5 | L | 1.25 (signature bet, moment 9) |

---

## 5. M4 "Better Together"

### 5.1 Must-haves (store rules and law — catalogue §8)

These are not optional. They come before any new social fun.

| Must-have | Why | Notes |
|---|---|---|
| **Verifiable parental consent (VPC)** before an `under_13` player gets friends, invites, a username others can find, chat history or shared builds | COPPA (2025 rule, in force since 22 April 2026) | Epic's Kids Web Services does parent verification free for developers. Offline and solo play need no consent. |
| **Local digital age of consent**, not only "13" | GDPR Article 8: 13–16 by country (Germany, the Netherlands, Ireland 16; France 15; Spain, Italy, Austria 14; the UK 13) | Store the band as "child under the local age" / "not a child". |
| **Store age signals** | Texas SB 2420 in force since 4 June 2026; Utah and Louisiana in 2026 | Read Google Play Age Signals (Android now) and Apple Declared Age Range (iOS in M5); map under 13 / 13–15 / 16–17 / 18+ to our bands. |
| **"Stay safe online" card** (pictures + read-aloud) before the first online game | Google Play Families: an in-app reminder for social features | Shown again after long breaks. |
| **High-privacy defaults** | UK Children's Code; FTC's Fortnite case (voice chat on by default was "unfair") | Online play off for `under_13` until a parent turns it on; profiles private; no voice chat. |
| **Parent controls from the parent's side** (with consent) | Families policy: adults can manage social features | Extends H2: approve friends, switch chat and online play. |
| **Report, block, mute reviewed by a person** | Spec §5.13–5.14; lessons from Roblox's lawsuits | Keep the review queue small by keeping under-13 chat to quick phrases. |
| **Written data-retention and security policies** | COPPA 2025 rule | Reconsider 30-day chat history for `under_13` (quick-chat only anyway). |

### 5.2 Additions (ranked by score)

| Rank | Item | Code | Impact | Effort | Score | Notes |
|---|---|---|---|---|---|---|
| 1 | Hide-and-seek with friends (the M3 mode, now online) | T6 | 4 | S | 4.0 | Mostly reuse |
| 2 | Team photo after a boss | T5 | 3 | S | 3.0 | Into the Memory Book |
| 3 | Ghost races on friends' Game Blocks courses | T2 | 4 | M | 2.0 | Medals among friends only |
| 4 | Remote parent dashboard (with consent) | H2 | 3 | M | 1.5 | Play time, friends, switches |
| 5 | Buddy playdates | T4 | 3 | M | 1.5 | §3a "Buddies meet friends' buddies" |
| 6 | Bottle mail between friends (preset phrases and small builds) | D5 | 3 | M | 1.5 | Asynchronous, safe |
| 7 | "Show a grown-up" tour | T7 | 3 | M | 1.5 | Joint play with parents |
| 8 | **Blueprint gifts and showcase visits** (read-only copies, guestbook stickers) | T3 | 5 | L | 1.25 | **Signature bet** for social play when friends are not online at the same time |
| 9 | **Neighbours move in** (if not done in M3) | R7 | 5 | L | 1.25 | Signature moment 9 |
| 10 | Friends' build weeks | E3 | 2 | M | 1.0 | Same sticker for everyone |

---

## 6. M5 "Launch"

| Rank | Item | Code | Impact | Effort | Score | Notes |
|---|---|---|---|---|---|---|
| — | **Playtests with children in three age groups** (6–7, 8–10, 11–12), phones and tablets, sound on and off | catalogue §9 | — | M | — | **Must** (spec §7.6) |
| — | **Legal review, privacy policy, age rating** (target PEGI 7 / ESRB E10+) | catalogue §8 | — | M | — | **Must** (spec §5.14, §11) |
| — | **A privacy notice children can read** (pictures, short sentences) plus the full one for parents | catalogue §8 | — | S | — | **Must** (UK Children's Code transparency) |
| — | **Kids category or general listing** (Apple) — decide; parental gate on links, sharing and settings either way | catalogue §8 | — | S | — | **Must** |
| 1 | Tablets and small phones: check the HUD layout on a tablet AVD and a small phone | A8 | 3 | S | 3.0 | Most young children play on tablets |
| 2 | The trust promise on the store page and in the parent corner ("No ads. No purchases. No loot boxes. No chat with strangers for children.") | H5 | 3 | S | 3.0 | Also aims at Google's Teacher Approved |
| 3 | Store screenshots and video built on the signature moments | §2 here | 3 | S | 3.0 | Parents and children decide in seconds |
| 4 | More languages | O7 | 4 | M | 2.0 | Translation files exist from M3 |
| 5 | Accessibility audit: colour-alone, flashes, text size, captions, button sizes | A1–A7 | 3 | M | 1.5 | Use the Game Accessibility Guidelines checklist |

---

## 7. Later

| Rank | Item | Code | Impact | Effort | Score | Notes |
|---|---|---|---|---|---|---|
| 1 | Real seasons in the world | E1 | 3 | M | 1.5 | Cosmetic only |
| 2 | Yearly festivals (Star Night, Pumpkin Days, Snow Day, Kite Day) | E2 | 3 | M each | 1.5 | Items return every year; no countdowns |
| 3 | Music blocks | X6 | 3 | M | 1.5 | Smart-block family |
| 4 | Surprise visitors from the server (whales, balloons) | E4 | 2 | M | 1.0 | Delight, not deadlines |
| 5 | The EasyCraft Museum (curated, human-reviewed builds) | T8 | 3 | L | 0.75 | Only with consent and review |

**If money is ever added** (spec §8 "optional cosmetic shop"), these rules protect children and the
store listing:
- Prices in real money (local currency), never a premium currency (EU guidance; Google Play requires
  virtual and real money to be clearly separate).
- A parent gate on every purchase; for `under_13`, consider a single "supporter pack" instead of an
  ongoing shop.
- No random items, no timers, no "limited forever" items, nothing that gives power (spec §6).
- Nothing bought can look "better" than what can be built or found (Build-and-Wear stays the main
  source of cosmetics), so children who cannot pay are never marked out.
- No ads for children. **Remove "rewarded ads" from spec §2** now (it contradicts §6).

---

## 8. Proposed spec edits (for the lead)

| Spec section | Proposed edit |
|---|---|
| §2 Decisions log, Monetization | Delete "or rewarded ads"; keep "cosmetic purchases may be added later, parent-gated, never random". |
| §3a Signature features | Add: secret buddy shapes (D1), rideable buddies (X1), befriend a monster (P4), bosses become mini-buddies (P5), the Buddy Album (C2). |
| §5.3 Combat | Add: "Monsters never break player builds." Add Cozy / Normal / Brave (G1). |
| §5.6 Gold Farm | Notification off by default; `under_13` via the parent gate only; at most once a day; quiet hours 20:00–08:00. |
| §5.7 / §5.11 Secrets and codes | Codes are also hidden in the game; no short expiry. |
| §5.8 Progress and rewards | Replace "3 daily missions and a daily gift" with the adventure board and presents found during play (R4). Titles for every play style (R5). |
| §5.9 Avatar, pets, photo mode | Free base emotes; pets never get sick, starve, run away or feel sad; Animal Book, Memory Book, Buddy Album. |
| §5.10 Tutorial | Voice-first and icon-first; one action per step; any step can be replayed. |
| §5.12 Shorts Theater | Under-13: no autoplay-next, end card after 5 videos, parent switch, EasyCraft TV first. |
| §5.13 Accounts, friends, chat | VPC for under-13 social features; local age of consent; store age signals; a "stay safe" card; high-privacy defaults. |
| §5.14 Safety and age | Add the parent corner (H2): local play time, reminders at natural stops, switches, gallery. |
| §5.15 Look, sound, feel, accessibility | Icon-first HUD with minimum sizes (about 2 cm for main buttons); break ring; reduce motion; ≤ 3 flashes a second; danger arrows and captions; read-aloud; languages; never colour alone. |
| §6 Fair-fun rules | Add: no random rewards for *any* currency; no countdowns or "never returns" items; no guilt from characters, bots or notifications; bots are always labelled; natural stopping points (sleep and save) with equal buttons; no autoplay-next for under-13s; no analytics or advertising IDs for children. |
| §7.6 Testing | Add the playtest questions and the automated checks (button sizes, no-guilt words, flashes, density of points of interest, no network before consent). |
| §8 Roadmap | Add the items of sections 3–7 of this proposal. |
| §12 (M2) | Add the M2 quick wins (section 3) to the tasks named there. |

---

## 9. Rulings in this proposal

Following the project's rule ("decide from the spec, write the decision down with what it costs if
wrong"):

1. **"Tricks" means healthy techniques only.** The catalogue lists 20 we use and 21 we reject.
   *Cost if wrong:* none known — the rejected ones would break store rules, laws or §6.
2. **The daily gift becomes presents found during play.** *Cost if wrong:* fewer daily returns; if the
   owner wants the gift back, it must wait for the child indefinitely and never show a streak.
3. **Cozy gives the same gold as Normal; Brave gives only a badge.** *Cost if wrong:* older children
   may farm gold on Cozy; gold only buys gear, so the harm is small.
4. **Bosses turn into mini-buddies after defeat.** *Cost if wrong:* one extra small model per boss; the
   owner may prefer trophies (the M2 statue remains as a fallback).
5. **Befriending monsters counts toward the 3-pet cap.** *Cost if wrong:* children may want more;
   the Buddy Album idea could hold extras.
6. **Parent reminders wait for the next natural stop** (end of a wave, reaching home, sleeping), with an
   option "stop exactly on time (saves first)". *Cost if wrong:* a few minutes of overrun.
7. **Notifications are off by default; for `under_13` only a parent can turn them on.** *Cost if
   wrong:* fewer returns to the Gold Farm.
8. **Game Blocks medals are shared among friends only; no public leaderboards.** *Cost if wrong:*
   less competition for older players; can be revisited for `13_plus` later.
9. **Rideable buddies go into M3 as a signature bet; Neighbours into M3 stretch / M4.** *Cost if
   wrong:* M3 grows by one large task; the order can swap if playtests show more interest in villages.
10. **The Shorts Theater keeps its place but under-13s get no autoplay-next and EasyCraft TV first.**
    *Cost if wrong:* children watch fewer videos — which is the intent.

---

## 10. Risks to watch

- **Scope.** M3 is already the biggest milestone. Use the core/stretch split; every item must still
  pass the performance budget (≥ 30 FPS average, no frame over 100 ms on the emulator).
- **Performance of the big bets.** Riding, the sleeping giant and weather add moving bodies and
  particles. Keep the buddy's compact footprint (owner feedback #9) and shared materials.
- **CC0 assets.** Icons (Kenney has CC0 icon packs), babble voices (can be made from CC0 syllable
  samples) and fonts (popular dyslexia fonts are OFL, not CC0 — the owner decides).
- **Monsters in Sandbox vs. scared young children.** The owner wants monsters in Sandbox (§12.15);
  the world ON/OFF setting, Cozy and befriending keep it safe for 6-year-olds.
- **Legal work is real work.** VPC, age signals and parent controls in M4 are at least one plan task
  each; budget them before new social fun.
- **No child playtest yet.** M1's acceptance item 10 is still waiting on the owner. Everything here is
  research-based; only real children can confirm which moments land. Run the playtest before M3 is
  planned in detail.
