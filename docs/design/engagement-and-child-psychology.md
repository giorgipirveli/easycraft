# EasyCraft — Engagement and child psychology

- **Date:** 2026-09-24
- **Status:** research and proposal for the lead; nothing here is built yet. The lead folds accepted
  items into the spec (`docs/superpowers/specs/2026-09-23-realm-hoppers-design.md`) and the plans.
- **Requested by the owner (2026-09-24):** "while coding run ultrathink to analyze what is exciting in
  the game and what can we add in our long term plan, how to make the game more attractive, research
  childrens psychology and add tricks into game plan".
- **Companion document:** `docs/design/long-term-roadmap-proposal.md` puts the catalogue below
  (section 5) into milestones M2–M5 and "Later".
- **Not legal advice.** Section 8 summarises store rules and laws so the team knows what to ask the
  lawyer before launch (spec §5.14 already requires a legal review).

**About "tricks".** The owner asked for "tricks". We read this as: *techniques that make children
want to play, and that are honest, healthy and allowed*. Section 6 lists 20 of them. Section 7 lists
the tricks other games use that we will **not** use, and why: app stores reject them, laws forbid
them, research shows they harm children, and our own Fair-fun rules (spec §6) forbid them.

**Words used in this document** (one-line explanations):

| Word | Meaning |
|---|---|
| Juice | Small effects (sound, sparkles, bounce, shake) that make an action feel good |
| Flow | Being so absorbed in a task that time flies; happens when the challenge matches the skill |
| Information gap | Knowing that something is missing ("3 of 8 found"), which makes us curious |
| Overjustification | When a reward for something a child already loves makes them love it less |
| FOMO | "Fear of missing out": pressure from things that disappear if you do not act now |
| Dark pattern | A design that tricks people into doing what the company wants, not what they want |
| Parasocial pressure | A game character "feels sad" to make a child keep playing or pay |
| VPC | Verifiable parental consent: a real check that a parent agreed (required by COPPA) |
| DDA | Dynamic difficulty adjustment: the game changes difficulty to fit the player |
| Non-reader | A child who cannot read game text yet (most 5–6-year-olds, many 7-year-olds) |

---

## 0. The short version

1. **Children play for three feelings:** *I choose* (autonomy), *I can do it* (competence), and
   *I belong* (friends and companions). Games that feed all three are played longer and enjoyed more
   (§1.1). EasyCraft's signature — build it, bring it to life — feeds all three at once.
2. **Controls are fun or frustration.** Research links good controls directly to the feelings of
   competence and autonomy (§1.1). Today most HUD buttons are about 0.8–0.9 cm on a phone; children
   under 9 need about 2 cm (§4, R1). This is the biggest cheap win.
3. **Many players cannot read.** 6–8-year-olds are beginner readers. Every message, button and
   riddle needs a picture and a sound, not only words (§4, R2).
4. **Curiosity is our strongest engine.** A visible gap ("???" in the Secret Book), a small clue and a
   surprise at the end pull children forward without any pressure (§1.3, §1.4).
5. **Rewards can backfire.** Promising children rewards (gold, stars) for things they already love,
   like building, can make them love it less. Reward challenge and discovery; let creativity be its own reward
   (§1.8).
6. **Many children start collecting around 6–8.** Finite, visible collections (animals, buddies,
   secrets) are healthy; random paid boxes are not (§1.6, §7).
7. **Companions matter.** Pets, buddies and bot friends give solo children someone to play with. They
   must never guilt a child for leaving (§1.9, §7).
8. **Failure must be gentle.** No game-over; clear warnings before attacks; honest help after repeated
   losses; a choice of difficulty (§1.2, §5 G).
9. **Healthy stopping points are a feature.** An EasyCraft day is 20 minutes, and going to bed is a
   natural place to stop. Parents are our allies, not obstacles (§5 H).
10. **The law is strict and getting stricter** (COPPA 2025 rule, the UK Children's Code, EU guidance,
    new US app-store age laws in force since 2026). Our Fair-fun rules already point the right way;
    section 8 lists what is still missing for online play (M4) and launch (M5).

---

## 1. How children 6–12 play: what research says

### 1.1 Three needs: I choose, I can do it, I belong

**Self-Determination Theory** (SDT) says people are most motivated when three needs are met:
**autonomy** (choosing for yourself), **competence** (feeling able), and **relatedness** (feeling
connected to others). Four studies by Ryan, Rigby and Przybylski found that these three needs, each on
its own, predicted enjoyment and the wish to play again. They also found that competence and autonomy
were linked to **intuitive controls** [S1]. A later model by the same team made the same point for
long-term engagement [S2]. A study of Animal Crossing players during the 2020 pandemic found the game helped exactly
because it met these three needs, and that players stopped when the needs were no longer met [S23].

**For EasyCraft:** every feature should answer at least one of: *What can the child choose? What
can the child get better at? Who is the child with?* Controls that a 7-year-old can use are not polish;
they are the base of competence.

### 1.2 Flow: not too easy, not too hard

**Flow** (Csikszentmihalyi) happens when challenge and skill are both high and matched. Too hard
gives anxiety; too easy gives boredom [S3]. An experiment with a shooter game found that being
"enjoyably challenged" was the key to enjoyment [S3b]. Children's skill varies hugely between a
6-year-old and a 12-year-old, so one fixed difficulty cannot fit them all.

Nintendo's answer for Mario is **invisible difficulty**: an easy route, a normal route and optional
hard extras (hidden coins, secret levels) in the same level, plus temporary help such as the
**Super Guide** in *New Super Mario Bros. Wii* (offered after 8 failures) and **Assist Mode** in
*Super Mario Odyssey* [S27]. Research on **dynamic difficulty adjustment** found that players do not
necessarily feel cheated when a game quietly adapts [S28].

**For EasyCraft:** let the child choose the challenge (the Monster Totem already does this: waves
start only when the child taps it), add a world difficulty choice, and offer honest help after
repeated losses (§5 G).

### 1.3 Curiosity: the information gap

Loewenstein's **information-gap theory**: curiosity is a feeling of deprivation that appears when we
notice a gap in what we know. A small clue ("priming dose") makes curiosity *stronger*, not weaker
[S4]. Partial knowledge motivates more than knowing nothing.

**For EasyCraft:** the Secret Book with "???" slots and a found/total count (§12.16) is textbook
information-gap design. Treasure maps that point to the next chest, and silhouettes of unknown animals,
work the same way. **Guard:** every gap must be closable by *playing*, never by paying or waiting.

### 1.4 Surprise makes children look closer

Stahl and Feigenson showed that when infants saw objects "break the rules" (a ball passing through a
wall), they looked longer, explored those objects more, tested them (banging, dropping) and learned
more about them [S5]. *(Evidence note: studied in 11-month-olds; the principle — surprise triggers
exploration and learning — is widely applied to older children, but we apply it with care.)*

**For EasyCraft:** a buddy that floats because it is made of glass, or glows because it contains a
light block, is a "rule-breaking object" that invites experiments: *What if I build it out of ice? What
if it is tiny?* Emergent rules the child can discover are worth more than rules we explain.

### 1.5 Kinds of fun

Roger Caillois described four kinds of play [S6]:

| Kind | Meaning | In EasyCraft now |
|---|---|---|
| *Agon* | competition, skill | Totem waves, the Stone Golem, bullseye scores |
| *Alea* | chance | treasure chests, golden animals, shooting stars (free, found by playing) |
| *Mimicry* | pretend, role-play | pets, homes and beds, buddies, the realistic avatar |
| *Ilinx* | vertigo, thrill of movement | triple jump, fly, ghost, Size Magic (Giant/Tiny), swimming and diving |

Richard Bartle's player types (achievers, explorers, socialisers, "killers") come from adult online
games [S7]. For children, a simpler set works well and matches the M2 bot personalities: **builders,
explorers, fighters, carers** (pets and companions) and **collectors**. A good kids' game has
something for each, and lets the child move between them.

### 1.6 Collecting and completing

Children often start collecting around ages 6–8, become little "experts" on their collections, and
collect more than adults do; Piaget linked collecting to the concrete-operational stage, when children
learn to sort and order things [S12]. Pokémon's creator, Satoshi Tajiri, built the game on his
childhood hobby of catching and swapping insects with friends [S13].

**For EasyCraft:** collections (animals, buddies, secrets, treasure decorations) fit the age exactly.
**Guard:** collections must be finite, visible ("12 of 20") and complete-able by play. No random paid
packs (§7).

### 1.7 Making things and owning them

The **IKEA effect**: people value things they built themselves much more — even simple ones — and
expect others to like them too. The effect **disappears if the creation fails or is destroyed** [S8].

**For EasyCraft:** this is why "Build it. Bring it to life." is strong: the buddy is *the child's own
creation*, and waking it up is the moment of success. It also gives two design rules:
1. **Help children finish** (stamps, mirror mode, undo): an unfinished build gives no pride.
2. **Never destroy a child's build** (monsters must not break player blocks; griefing must be
   impossible for visitors in M4).

### 1.8 Rewards: when they help and when they hurt

- Lepper, Greene and Nisbett (1973): preschool children who *expected* a reward for drawing later drew
  less in free time than children who got no reward or an *unexpected* one [S9].
- A meta-analysis of 128 studies (Deci, Koestner and Ryan 1999): expected, tangible rewards for an
  activity lower free-choice interest in it. **Informational** feedback that supports competence can
  raise it [S10].
- Mueller and Dweck (1998): children praised for being *smart* gave up sooner and enjoyed tasks less
  after failure than children praised for *effort* [S11].

**For EasyCraft:**
- Do not pay gold for building, decorating or waking buddies. Those are already loved; let the magic
  itself be the reward.
- Use rewards for *challenge* (waves, bosses) and *discovery* (treasure) — things with a clear goal.
- Surprise celebrations ("Your 10th buddy! Confetti!") are fine because they are unexpected and
  informational.
- Pip, bots and messages praise effort and strategy ("You hid in the bush — clever!"), not talent
  ("You're a genius!").

### 1.9 Friends, showing off, and playing with grown-ups

Relatedness is one of the three needs (§1.1). Children want to **show** what they made — the
LittleBigPlanet motto "Play, Create, Share" built a whole series on it [S30]. Playing **together
with a parent** ("joint media engagement") helps children learn and talk about what they do [S31].

Many children play alone. For them, companions (pets, buddies, bot friends) supply relatedness. This
is powerful, which is also why it can be abused: in a study of 133 apps played by 3–5-year-olds,
about one in four (24.8%) used characters to pressure children — for example "Do you want to give
up?", or a notification saying "people are protesting your absence!" — and only 19.6% of the apps had
no manipulative design at all (§7, [S36]).

### 1.10 Pretend play, characters and stories

The most-visited Roblox experience ever is **Brookhaven RP**, a pretend-play town with houses, cars
and families; it passed **Adopt Me!**, which exploded after adding pets in 2019 [S22]. **Toca Boca**
built a company on "digital toys" with no rules, no winning or losing and almost no text [S21].
Research on whether pretend play *causes* development is mixed [S20]; we do not claim learning
benefits. We only note that children clearly *love* it.

**For EasyCraft:** homes, beds, pets, jobs and daily-life props make pretend play easy. Characters
(Pip, Tilly, the Wanderer, the Stone Golem, buddies) need faces, voices and simple wishes.

### 1.11 Fear and excitement

Joanne Cantor's research: children from about 3 to 8 are most frightened by **darkness, animals and
fantastic monsters**, especially grotesque ones; older children fear realistic dangers more [S18].
PEGI 7 allows "scenes or sounds that can possibly be frightening to younger children" and only
non-realistic violence [S19].

**For EasyCraft:** night monsters, dark caves and the Golem are exciting for 8–12-year-olds and can
be too scary for some 6-year-olds. Keep monsters cute-scary (slimes with faces, cartoon goblins), give
the child control (Monsters ON/OFF, a Cozy difficulty, lanterns), and make hiding feel safe.

### 1.12 Age stages

Nielsen Norman Group studies split children into 3–5 (pre-readers), 6–8 (beginner readers) and 9–12
[S14, S15, S16].

| | 6–7 | 8–10 | 11–12 |
|---|---|---|---|
| Reading | Beginner; icons and sounds needed | Reads short text; still slow | Reads well |
| Touch and motor | Limited fine motor; big targets (≥ 2 cm); two-hand coordination hard [S14]; misses small targets and leaves the finger down too long [S17] | Better, still imprecise | Nearly adult |
| Thinking | Symbolic, magical; believes objects can be alive | Logic about concrete things; sorting, rules, fairness | Starts abstract thinking |
| Fears | Dark, monsters, being alone | Losing, unfairness | Looking "babyish" to peers |
| Social | Plays beside others (parallel play) | Plays with friends, team play, secret codes | Status, identity, showing off |
| Loves | Cause and effect, animals, repetition, surprise | Collecting, secrets, mastery, cheat codes | Challenge, self-expression, friends |
| EasyCraft hooks | Buddies, pets, stamps, Tiny/Giant | Secret Book, treasure, tiers, waves | Brave mode, REALISTIC style, building, sharing |

**Note:** the REALISTIC style switch is valuable for 10–12-year-olds who reject a "little kids'"
look. Our age band (`under_13` / `13_plus`) cannot tell a 6-year-old from a 12-year-old, so the game
should offer choices ("Simple controls?") instead of guessing.

### 1.13 Games and children's well-being

Screen time is not simply bad. In a large US study of 9–10-year-olds (with genetic and family
background controlled), children who played more video games gained about 2.5 IQ points more over two
years than average; the authors conclude that screen time generally does not harm cognitive abilities
[S32]. US 8–12-year-olds averaged 5 h 33 min of entertainment screen media a day in 2021, 1 h 27 min
of it gaming [S33]. What matters is *how* games are designed: whether they respect the child's time and
choices. UNICEF and the LEGO Group's **RITEC** project names eight well-being outcomes of digital play:
safety and security; diversity, equity and inclusion; autonomy; emotions; competence; relationships;
creativity; and identities [S59]. We use these as a checklist in section 6.

---

## 2. What the games children love actually do

| Game | The mechanic | Why it holds children | Lesson for EasyCraft | What we do *not* copy |
|---|---|---|---|---|
| **Minecraft** | Open world, no instructions, creative + survival, peaceful setting | Autonomy; emergent discovery; creativity. The dominant game for ages 3–12 in a 753-parent survey, mostly played on tablets; many children also follow Minecraft videos [S24] | Keep Sandbox free; emergent rules; test on tablets too | Slow one-block-at-a-time touch building; dead blocks |
| **Roblox** | Player-made games; role-play towns (Brookhaven); pets (Adopt Me!); obstacle courses ("obbys") | Endless variety; pretend play; friends [S22] | Game Blocks (M3) = obbys without code; home and role-play props | Paid avatar status ("noob" shaming); open trading; stranger chat — Roblox is now fighting many lawsuits over child safety [S55] and limited under-13 messaging in 2024 [S54] |
| **Pokémon** | Catch, collect, name and grow companions; trade with friends | Collecting (§1.6); companionship; friends [S13] | Animal Book; befriend monsters; buddy album | Random paid packs (TCG boosters) |
| **Animal Crossing** | Real-time daily life, a museum to fill, villagers who remember you, yearly events | Calm autonomy; collections; relatedness [S23] | Neighbours who move in (R7); seasonal events that *return every year* | Weeds and "you were away!" guilt; the turnip "stock market" (speculation) |
| **Toca Boca** | "Digital toys": no rules, no winning, almost no text | Pure pretend play for non-readers [S21] | Picture-first UI; toy-like props | — |
| **LEGO games** | No game over: you lose a few studs and pop back; drop-in co-op; collectibles; replay levels with new powers [S26] | Low frustration; family co-op | Sandbox pop-back (already §12.15); revisit areas with new powers (Tiny, iron pickaxe) | — |
| **Fortnite (Creative)** | Emotes and dances; islands made by players; seasons | Self-expression; social language without words | Free emotes; buddies that dance | Battle-pass FOMO; item-shop countdowns; Epic paid $520 M to the FTC over COPPA and dark patterns [S41] |
| **Terraria** | Build a proper room and a villager **moves in**; the player summons bosses | Building has a purpose; visible progress; "one more try" bosses [S25] | Neighbours (R7); the Totem (already) | — |
| **Nintendo (Mario, Kirby)** | Invisible difficulty; Super Guide / Assist Mode; dense small rewards [S27] | Everyone succeeds; experts still find challenge | Cozy/Normal/Brave; honest help; "something to find every 30 seconds" | — |

---

## 3. What already works in EasyCraft, and why

EasyCraft already has an unusually strong core. The loop a child feels is:

> **Build** something → **bring it to life** with the wand → **play** with it (it follows, cheers,
> floats, glows) → **show** it to someone → build something new.

| Feature (spec) | What the child feels | Why it works |
|---|---|---|
| **Magic Wand buddies** (§3a) | "I made it and it's ALIVE!" | IKEA effect (§1.7); young children's magical thinking (§1.12); competence in seconds; surprise from emergent personality (§1.4); a companion (§1.9) |
| **Personality from blocks** (small = zippy, light = glows, glass = ghost) | "What happens if I build it from…?" | Rules to discover → experiments (§1.4); curiosity (§1.3) |
| **Size Magic** (Tiny / Giant) | "I'm a bug!" / "I'm a giant!" | *Ilinx* (§1.5); a new view of your own build; future Tiny-only secrets |
| **Stamps and Mirror** | "I made a house in one tap!" | Helps young children *finish* (§1.7); competence |
| **Triple jump, Fly, Ghost** | Freedom and speed | *Ilinx*; autonomy; mastery of movement |
| **Caves, ores, crystals, water, underground lakes** | Adventure and treasure | Exploration; Minecraft familiarity |
| **Pets** (tap 3× → hearts, collar, name) | "My dog!" | Carer play; relatedness; the Adopt Me! pull (§2) |
| **Beds, day/night, home** | "My house, my bed" | Pretend play; daily rhythm; a natural stopping point (§5 H) |
| **Weapons and dummy with hit numbers** | Power and clear feedback | Competence; juice |
| **Tappable chat commands** (`/summon`, `/time`) | "I have magic codes!" | 8–10-year-olds love secret codes; autonomy |
| **BLOCKY / REALISTIC switch** | "My world, my style" | Self-expression; older kids avoid a "babyish" look (§1.12) |
| **M2: Totem waves** | "I start the fight when I'm ready" | Autonomy over challenge (§1.2) |
| **M2: Stealth (? and !, bushes, barrels)** | Hide-and-seek with monsters | A universal childhood game; a non-violent choice |
| **M2: Stone Golem with warnings and a dazed state** | "I learned its moves and won" | Readable patterns → competence; *agon* |
| **M2: Real water and splashes** | Swimming, diving, splashing | *Ilinx*; juice; no drowning (fear-free) |
| **M2: Bot friends** | "I'm not alone" | Relatedness for solo children; parallel play for young ones |
| **M2: Secrets and treasures, Secret Book** | "What's behind this wall?" | Information gap (§1.3); surprise (§1.4); collecting (§1.6) |
| **§6 Fair-fun rules** | Parents trust the game | Matches store rules and research (§7, §8) |

---

## 4. Gaps and risks

Each risk says what we found, why it matters and which catalogue items (section 5) fix it.

**R1. Buttons are too small and too many for young hands.**
The HUD is designed in a 1280 × 720 space (`project.godot`, stretch `canvas_items`). In `ui/hud/hud.gd`
the WALK/SIZE/CAM/UNDO buttons are 94 px, MIRROR 90 px, DOWN 110 px, ATTACK 130 px and JUMP 165 px. On
a Pixel 8 held sideways (screen about 6.4 cm tall), 94 px is about **0.85 cm** and JUMP about **1.5 cm**.
NN/g recommends at least **2 × 2 cm** for children under 9 [S14] (about 225 px here). Children also
miss small targets more often and leave the finger down longer [S17]. By the end of M2 the screen also
gets CROUCH, hearts, gold, wave and boss bars. *Why it matters:* controls drive competence and
autonomy [S1]. *Fix:* O1, A4, A5, A6.

**R2. The game speaks in words only.**
Buttons are text ("JUMP", "MIRROR", "CAM"); tips are text toasts ("Tip: build something, then tap it
with the Magic Wand!"); M2 adds text riddles (puzzle temples, the Wanderer), shop prices and messages
like "You need an iron pickaxe for this!". 6–8-year-olds are beginner readers [S15], and many
children worldwide do not read English. *Fix:* O1–O7, F7.

**R3. Tap versus hold is invisible.**
A touch that stays still for 0.25 s breaks a block (`core/input/touch_classifier.gd`), and nothing
shows that holding is doing something. Young children leave fingers down longer [S17], so accidental
breaks are likely, and children who tap cannot discover breaking. *Fix:* F1, A5.

**R4. Survivor arrives before any tutorial.**
M2 adds gold, the trader, tool tiers, stealth, the Totem and knock-outs; Pip's tutorial is M3 (§5.10).
For months, Survivor will be a pile of unexplained systems. *Fix:* O5, G2 (M2 quick wins).

**R5. Night can be too scary for some 6-year-olds** (§1.11), especially in Sandbox where monsters
are ON by default (owner's wish, §12.15). *Fix:* G1 (Cozy), cute monster faces, hiding that feels
safe (G5), P4 (befriend instead of fight).

**R6. Losing the boss again and again.**
The Golem has 300 HP for one player; a young child may fail many times with no help. *Fix:* G3.

**R7. The blank canvas.**
In Sandbox, some children ask "what do I do?". Minecraft-style freedom suits builders; others need a
spark. *Fix:* X5 (idea cards), T1 (builder bots model ideas), R4 (a board of optional goals).

**R8. Daily gift and farm notifications train "come back on time".**
§5.8 plans a daily gift; §5.6 a 12-hour farm cap with an opt-in "Your farm is full!" notification.
"Missing a day never costs anything" is good, but daily login gifts and timers are still
*appointment mechanics* [S37] and notifications are a "sticky feature" in the UK Children's Code
[S48]. *Fix:* R4 (presents found during play), H4.

**R9. Admin codes "on social media".**
§5.7 and §5.11 release codes on social media. Most social networks are 13+, so under-13 children
would be pushed there (or to ask older siblings). *Fix:* H7.

**R10. The Shorts Theater is a short-video feed inside a children's game.**
§5.12 has one autoplaying player and next/previous buttons. Autoplay of the *next* video is a known
"sticky" feature [S48]; in a study with preschoolers, auto-playing more videos after the planned list
led to longer viewing and fewer self-chosen stops [S35]. *Fix:* H6.

**R11. The spec contradicts itself on ads.**
§2 says the economy is "designed so … rewarded ads can be added later"; §6 says "No rewards for
watching videos". Rewarded ads also make the Families and Kids-category rules harder (§8). *Fix:* the
roadmap proposes deleting "rewarded ads" from §2.

**R12. The age band is too coarse for the law.**
`under_13` / `13_plus` fits COPPA, but the EU's digital age of consent ranges from 13 to 16 by country
(Germany, the Netherlands and Ireland 16; France 15; Spain, Italy and Austria 14; the UK 13) [S46], and
new US app-store laws (Texas since June 2026, Utah, Louisiana) send age *ranges* from the store
(under 13, 13–15, 16–17, 18+) [S51, S52]. *Fix:* section 8, M4/M5 items.

**R13. Online features for under-13s need parental consent.**
Usernames that friends can contact, friend lists, invites and 30-day chat history (§5.13) are
personal information under COPPA; the 2025 COPPA rule update applies from 22 April 2026 [S45].
*Fix:* section 8 (VPC through a service such as Epic's free KWS [S53]).

**R14. Shared builds can contain anything.**
Buddies and builds are free-form shapes; once they can be shared (M4), rude or hateful shapes are
possible. *Fix:* T3 guards (friends-only, report, human review for anything public).

**R15. Colour-only signals.**
M2 Task 6 plans "tier looks (colour per tier)". About 1 in 12 boys is colour-blind [S58].
*Fix:* A1 (dots or stripes per tier; monster levels already use spikes).

**R16. Numbers get huge.**
Gold and monster health scale ×2 per universe, forever (§5.1). Universe 10 pays 512×. Big numbers
are exciting but hard for 6–8-year-olds to compare. *Fix:* F9 (short numbers with a coin icon and
"you have / you need" bars), R3 (wish list).

**R17. Most children will play on older phones and tablets, often with the sound off.**
Kids' devices are often hand-me-downs; many children play muted in cars, classrooms or at night. Any
signal that is only a sound (a monster growl behind you) is lost. *Fix:* A3; keep the performance
budget; test on a tablet layout (A8).

---

## 5. Catalogue of additions

**How to read an item.**
- ★★★ = high impact for children; ★★ = clear value; ★ = nice to have.
- **Milestone:** M2 (being built now — only small "quick wins"), M3 "Worlds of Wonder", M4 "Better
  Together", M5 "Launch", or Later.
- **Effort:** **S** = up to about a day for one agent; **M** = about one plan task (a few days);
  **L** = two or more plan tasks.
- Each item says what the **child** experiences, **why** it works (with the principle from section 1),
  how it **fits** EasyCraft, and the ethical **guard** it needs.

**Catalogue index.** Pillars are the spec's five (§3): Freedom, Discovery, Progress you can see,
Together, Fair fun. Every item serves at least one.

| Code | Item | Priority | Milestone | Effort | Pillars |
|---|---|---|---|---|---|
| F1 | Break ring and place pop | ★★★ | M2 quick win | S | Freedom, Fair fun |
| F2 | Material sounds and a building melody | ★★ | M3 | S | Fair fun |
| F3 | The buddy wake-up ceremony | ★★★ | M2 quick win | S | Discovery, Fair fun |
| F4 | Hit feel | ★★ | M2 (inside Tasks 4 and 6) | S | Fair fun |
| F5 | Haptics | ★ | M3 | S | Fair fun |
| F6 | Movement flourishes | ★★ | M3 | S | Freedom |
| F7 | Gibberish voices for characters | ★★★ | M3 | M | Together, Fair fun |
| F8 | The secret chime | ★★ | M2 quick win | S | Discovery |
| F9 | Short numbers and "have / need" bars | ★★ | M2 quick win | S | Progress |
| D1 | Secret buddy shapes | ★★★ | M3 | M | Discovery |
| D2 | Wake up the world | ★★ | M3 | S per object | Discovery |
| D3 | A living sky | ★★ | M3 | M | Discovery |
| D4 | The Tiny world | ★★★ | M3 | M | Discovery, Freedom |
| D5 | Message in a bottle | ★★ | M3 (solo), M4 (friends) | S, then M | Discovery, Together |
| D6 | The sleeping giant | ★★ | M3 | M | Discovery |
| D7 | "Something new every 30 seconds" | ★★★ | M2/M3 (a metric) | S | Discovery |
| D8 | Portal peek | ★★ | M2 quick win | S | Discovery, Progress |
| C1 | The Animal Book | ★★★ | M3 | M | Discovery, Progress |
| C2 | The Buddy Album and "My Stamps" | ★★★ | M3 | M | Progress, Freedom |
| C3 | Trophy shelf | ★★ | M3 | S | Progress, Together |
| C4 | Page-complete rewards | ★★ | M3 | S | Progress |
| C5 | First-time badges | ★ | M3 | S | Progress |
| X1 | Rideable buddies | ★★★ | M3 (signature bet) | L | Freedom |
| X2 | Build-and-Wear for pets too | ★★ | M3 | M | Freedom |
| X3 | Home and pretend-play pack | ★★ | M3 | M | Freedom, Together |
| X4 | Free emotes and dances, and a team high-five | ★★ | M3 | M | Together, Freedom |
| X5 | Idea cards | ★★ | M3 | S | Freedom |
| X6 | Music blocks | ★ | Later | M | Freedom |
| T1 | Bot friends done right | ★★★ | M2 (Task 15 wording) | S | Together |
| T2 | Game Blocks with medals and ghost races | ★★★ | M3 (bots), M4 (friends) | M, then M | Together, Progress |
| T3 | Blueprint gifts and showcase visits | ★★★ | M4 | L | Together |
| T4 | Buddy playdates | ★★ | M4 | M | Together |
| T5 | Team photo after the boss | ★★ | M4 | S | Together, Progress |
| T6 | Hide-and-seek mode | ★★ | M3 (bots), M4 (friends) | M | Together, Freedom |
| T7 | "Show a grown-up" tour | ★★ | M4 | M | Together |
| T8 | The EasyCraft Museum | ★ | Later | L | Together |
| P1 | Pets that find secrets | ★★★ | M2 quick win (dog), M3 (others) | S | Together, Discovery |
| P2 | Teach tricks | ★★★ | M3 | M | Together, Progress |
| P3 | Happy greetings, bedtime together | ★★ | M3 | S | Together, Fair fun |
| P4 | Befriend a monster | ★★★ | M3 | M | Freedom, Together |
| P5 | The boss becomes a friend | ★★★ | M3 (M2: a statue trophy) | M | Together, Progress |
| P6 | Pet perks | ★★ | M3 (already in §5.9) | S | Together |
| G1 | Cozy / Normal / Brave | ★★★ | M2 quick win | S | Freedom, Fair fun |
| G2 | Picture tips after a knock-out | ★★★ | M2 quick win | S | Fair fun |
| G3 | Honest help after repeated losses | ★★★ | M2 quick win (Golem), M3 (all bosses) | S | Fair fun |
| G4 | Monsters never break your builds | ★★★ | M2 rule | S | Progress, Fair fun |
| G5 | Hiding feels safe | ★★ | M2 (inside Task 5) | S | Freedom, Fair fun |
| G6 | The Totem asks "easier or again?" | ★★ | M3 | S | Freedom, Fair fun |
| G7 | Crowns for experts | ★ | M3 | S | Progress |
| R1 | The Hub Tree | ★★★ | M3 | M | Progress |
| R2 | The Memory Book | ★★★ | M3 | M | Progress |
| R3 | Wish list | ★★ | M3 | S | Progress, Freedom |
| R4 | Adventure board instead of daily missions and a daily gift | ★★★ | M3 (changes §5.8) | S | Freedom, Fair fun |
| R5 | Play-style titles | ★★ | M3 | S | Progress |
| R6 | New powers, not just numbers | ★★ | M2/M3 | S | Progress |
| R7 | Neighbours move in | ★★★ | M4 (M3 if time allows) | L | Progress, Together |
| O1 | Icon-first buttons | ★★★ | M2 quick win | S | Fair fun |
| O2 | Picture riddles | ★★★ | M2 quick win | S (content) | Discovery, Fair fun |
| O3 | Ghost-hand hints | ★★ | M2 quick win or M3 | S | Fair fun |
| O4 | Pip teaches by doing, voice first | ★★★ | M3 (already §5.10) | M | Fair fun |
| O5 | First-time picture hints | ★★★ | M2 quick win | S | Fair fun |
| O6 | Read-aloud button | ★★★ | M3 | S | Fair fun |
| O7 | Languages | ★★★ | M3 (foundation), M5 (languages) | M | Fair fun |
| O8 | "Simple controls?" at first launch | ★★ | M3 | S | Freedom, Fair fun |
| E1 | Real seasons | ★★ | Later | M | Discovery |
| E2 | Yearly festivals | ★★ | Later | M each | Discovery, Together |
| E3 | Friends' build weeks | ★ | M4/Later | M | Together |
| E4 | Surprise visitors from the server | ★ | Later | M | Discovery |
| H1 | Sleep and save | ★★★ | M2 quick win | S | Fair fun |
| H2 | Parent corner | ★★★ | M3 (on device), M4 (remote) | M | Fair fun, Together |
| H3 | The no-guilt word list (a test) | ★★★ | M2 quick win | S | Fair fun |
| H4 | Notifications off by default | ★★★ | M3 | S | Fair fun |
| H5 | The trust promise | ★★ | M5 | S | Fair fun |
| H6 | Shorts Theater guardrails | ★★★ | M3 | S | Fair fun |
| H7 | Codes found in the game | ★★ | M3 | S | Fair fun, Discovery |
| A1 | Never colour alone | ★★★ | M2 quick win | S | Fair fun |
| A2 | Reduce motion and flashes | ★★★ | M2 quick win | S | Fair fun |
| A3 | See the sounds | ★★★ | M2 (danger arrow), M3 (captions) | S | Fair fun |
| A4 | Button size and layout | ★★ | M3 | M | Freedom, Fair fun |
| A5 | Other ways to break and aim | ★★ | M3 | S | Freedom, Fair fun |
| A6 | Simple controls | ★★★ | M3 | M | Freedom, Fair fun |
| A7 | Text size and a clear font | ★★ | M3 | S | Fair fun |
| A8 | Tablets and small phones | ★★ | M5 | S | Fair fun |

### F — Moment-to-moment feel and juice

Game feel is "real-time control, then a world that behaves predictably, and only then polish" (Swink);
the famous "Juice it or lose it" talk showed how particles, squash and sound turn a dull game lively
[S29]. Children need *exaggerated* feedback: under 6, subtle signals are often missed [S15].

#### F1 ★★★ Break ring and place pop — M2 quick win · S
- **Child:** when I hold my finger on a block, a ring fills around my finger and the block cracks;
  when it pops, bits fly out in the block's colour. When I place a block, it bounces into place with a
  "tock".
- **Why:** shows that holding *does* something (discoverability, R3); clear feedback builds
  competence [S1].
- **Fits:** `look_build_area.gd` already knows when a hold starts; the shared particle material (`Fx`)
  already exists.
- **Guard:** effects use shared materials (performance budget).

#### F2 ★★ Material sounds and a building melody — M3 · S
- **Child:** wood knocks, stone clicks, glass tinkles. Placing blocks quickly plays rising notes like a
  xylophone.
- **Why:** sound turns building into music; delight with no reading.
- **Fits:** the M1 place/break sounds; CC0 sound packs.
- **Guard:** volume settings; no sound is the only signal (A3).

#### F3 ★★★ The buddy wake-up ceremony — M2 quick win · S
- **Child:** I tap my build with the wand: sparkles swirl, the camera leans in, two eyes blink open,
  it says a happy "boing" and a banner shows its name with a little tune.
- **Why:** this is our signature moment; the birth of the creation is when the IKEA effect pays off
  (§1.7). It should be the most celebrated moment in the game.
- **Fits:** `entities/buddy/buddy.gd` (eyes, `cheer()`), `BuddyNames`.
- **Guard:** short (under 1.5 s) and skippable by moving; respects "reduce motion" (A2).

#### F4 ★★ Hit feel — M2 (inside Tasks 4 and 6) · S
- **Child:** my sword hit makes the monster squash, freeze for a blink and burst into confetti and
  coins.
- **Why:** a 40–60 ms "hit-stop", squash and numbers make combat readable and satisfying.
- **Fits:** the M1b dummy already shows hit numbers; `CombatDirector`.
- **Guard:** cartoon only, no blood (§5.3).

#### F5 ★ Haptics — M3 · S
- **Child:** a tiny buzz when I place or break a block or land from a big jump.
- **Why:** touch screens give no physical feedback; a light vibration replaces the "click".
- **Fits:** M2 Task 11 adds vibration for hits.
- **Guard:** a setting; off in "reduce effects"; very short.

#### F6 ★★ Movement flourishes — M3 · S
- **Child:** my third jump is a flip with a sparkle trail; flying fast makes a whoosh; landing puffs
  dust.
- **Why:** *ilinx* (§1.5): movement itself is play.
- **Fits:** triple jump puff (M1), `Fx`.
- **Guard:** reduce motion (A2).

#### F7 ★★★ Gibberish voices for characters — M3 · M
- **Child:** Pip, Tilly, the Wanderer, bots and buddies "talk" in cute babble (like Animal Crossing).
  Tiny buddies squeak; giant ones rumble. Each has its own sound.
- **Why:** personality without reading, and without translation cost; a voice makes a character a
  companion (§1.9).
- **Fits:** buddies' size already sets speed and hop; the pitch can follow size.
- **Guard:** important information is always also shown as an icon.

#### F8 ★★ The secret chime — M2 quick win · S
- **Child:** every time I find a secret, the same little four-note tune plays. I learn that sound
  means "something special!"
- **Why:** a consistent sound becomes a learned promise of surprise (like Zelda's secret jingle).
- **Fits:** §12.16 already has "a sparkle sound and a short banner"; make it one signature tune.
- **Guard:** none needed.

#### F9 ★★ Short numbers and "have / need" bars — M2 quick win · S
- **Child:** my gold shows as a coin and "1.2K", not "1200"; at Tilly's shop each price has a bar
  that shows how much of it I already have ("340 / 1200").
- **Why:** 6–8-year-olds compare pictures and bars more easily than big numbers (R16); the numbers
  grow ×2 per universe (§5.1).
- **Fits:** the HUD gold counter (M2 Task 1) and the shop panel (Task 7).
- **Guard:** the bar never blinks or says "almost there, hurry".

### D — Surprise and discovery (beyond §12.16)

#### D1 ★★★ Secret buddy shapes — M3 · M
- **Child:** I built a snowman from three white blocks and woke it — it sings! I found a secret shape!
  The Secret Book has a "Buddy recipes" page: 3 of 12 found. Other recipes: a four-legged build barks
  and fetches; a tower with a light on top becomes a lighthouse buddy that lights caves; a build shaped
  like Pip speaks with Pip's voice.
- **Why:** information gap (§1.3) + rules to discover (§1.4) + creativity rewarded with *delight*,
  not gold (§1.8).
- **Fits:** `BuddyTraits.from_blocks()` already derives personality from blocks; shape matching adds a
  second rule. The Secret Book (M2 Task 16) gets a new page.
- **Guard:** recipe hints are riddles found in the world (bottles, notes, the Wanderer), never sold.

#### D2 ★★ Wake up the world — M3 · S per object
- **Child:** the wand also wakes a snowman, a pumpkin, a cactus or a treasure chest ("mimic" that
  wants to be my friend).
- **Why:** more "what if?" experiments with the core magic.
- **Fits:** the wand and buddy system; seasonal objects (E2).
- **Guard:** the 10-buddy cap per world stays (performance).

#### D3 ★★ A living sky — M3 · M
- **Child:** after rain there is a rainbow; at dusk fireflies come out; some nights there is a meteor
  shower; foggy mornings; snow in winter.
- **Why:** variety and small surprises make the world feel alive; every day is a little different.
- **Fits:** `sky_cycle.gd`, shooting stars (§12.16), the particle system.
- **Guard:** no event is "limited — act now"; performance; flash limits (A2).

#### D4 ★★★ The Tiny world — M3 · M
- **Child:** when I shrink, I find mouse holes in hills. Inside is a tiny village with tiny
  furniture, tiny treasure and friendly mice. It is only visible when I'm tiny.
- **Why:** perspective change + a secret only a special power reveals (the LEGO "come back with a new
  power" pattern, §2); a story children retell.
- **Fits:** spec §3a already plans Tiny-only passages; §12.16's deterministic secret placement.
- **Guard:** none.

#### D5 ★★ Message in a bottle — M3 (solo) · S; M4 (friends) · M
- **Child:** a bottle washes up on the beach. Inside: a picture riddle or a piece of a treasure map.
  In M4, a friend can send me a bottle with a quick-chat message or a small build.
- **Why:** surprise + information gap; later, safe asynchronous friendship.
- **Fits:** treasure maps (§12.16); quick-chat phrases (`ChatRules.QUICK_PHRASES`).
- **Guard:** under 13: preset phrases and stamps only, friends only, after parental consent (§8).

#### D6 ★★ The sleeping giant — M3 · M
- **Child:** a mountain has a stone face. When I bring it three crystal hearts from deep caves, I wake
  it with my wand — a giant friend walks with me until sunset, then goes back to sleep.
- **Why:** a legend to discover and a spectacular payoff; *ilinx* of scale.
- **Fits:** buddies, crystals, Size Magic.
- **Guard:** one giant at a time (performance).

#### D7 ★★★ "Something new every 30 seconds" — M2/M3 · S (a metric)
- **Child:** wherever I walk, I soon see something: an animal, a strange tree, a chest, a ruin.
- **Why:** density of small rewards is how Mario keeps children moving [S27]; empty land bores.
- **Fits:** the autopilot already walks and flies 2 km; add a count of "points of interest seen per
  minute" and aim for at least 2.
- **Guard:** it is a test, not a feature.

#### D8 ★★ Portal peek — M2 quick win · S
- **Child:** after I beat the Golem, the portal shows a moving window into a desert: sand blows out,
  I hear wind. "Opens in the next update!"
- **Why:** anticipation by curiosity (§1.3), not by a timer.
- **Fits:** §12.9 portal.
- **Guard:** no countdown; no "come back tomorrow".

### C — Collection and completion

#### C1 ★★★ The Animal Book — M3 · M
- **Child:** a book with every animal — dog, cat, pig, cow, sheep, chicken, rabbit, many fish — and
  rare colours (spotted cow, black sheep, golden rabbit). Unknown ones are silhouettes. I fill a page by
  petting, feeding or photographing the animal.
- **Why:** collecting fits the age (§1.6); silhouettes are information gaps (§1.3); like
  Pokémon's Pokédex or Animal Crossing's museum.
- **Fits:** the 8 animal kinds (M1b), golden animals (§12.16), photo mode (§5.9).
- **Guard:** finite; every entry found by play; no paid shortcut; no "limited" animals.

#### C2 ★★★ The Buddy Album and "My Stamps" — M3 · M
- **Child:** every buddy I ever woke is in my album with its picture and name. I can wake it again,
  or use it as a stamp to place a copy.
- **Why:** a collection of *my own creations* — IKEA effect plus collecting; it also softens the
  10-buddy cap ("put one to sleep in the album").
- **Fits:** buddies save their blocks (`Buddy.pack()`); stamps (§3a); copy/paste is already planned for
  M3 (§5.5).
- **Guard:** stored on the device; shared only with friends in M4 (T3).

#### C3 ★★ Trophy shelf — M3 · S
- **Child:** the golden trophy, lamp and flag I found in treasure stand on a shelf block in my house,
  each with a little plaque.
- **Why:** showing off (§1.9) and pride of collection.
- **Fits:** §12.16 "unique decorations that exist only in treasure".
- **Guard:** none.

#### C4 ★★ Page-complete rewards — M3 · S
- **Child:** when I finish a Secret Book page, I get a hat and a new ornament on my Hub Tree (R1).
- **Why:** completion gives a sense of competence; the reward is *informational* ("you explored
  everything here") and cosmetic.
- **Fits:** Secret Book (§12.16); avatar items (§5.9).
- **Guard:** no "streak" or "hurry" pages.

#### C5 ★ First-time badges — M3 · S
- **Child:** "First buddy!", "First night survived!", "First geode!" — each with a picture in my
  Memory Book (R2).
- **Why:** marks progress children can see and tell others about.
- **Guard:** no badges for logging in or for play time.

### X — Creativity and self-expression

#### X1 ★★★ Rideable buddies — M3 · L (signature bet)
- **Child:** I build a dragon, put a saddle block on it and wake it. I climb on and fly! A car buddy
  drives, a boat buddy swims.
- **Why:** the ultimate "build it, bring it to life" moment; vehicles and mounts are hugely popular
  (Brookhaven's cars, Minecraft's horses); *ilinx* (§1.5).
- **Fits:** buddies already have speed/hop by size and "floaty" for glass; riding = the player follows
  the buddy's body. Survivor flying could cost gold like Fly (§12.7) or be a slow glide.
- **Guard:** performance (the buddy keeps its compact 1.8-block footprint, owner feedback #9).

#### X2 ★★ Build-and-Wear for pets too — M3 · M
- **Child:** I build a tiny crown and put it on my dog.
- **Why:** self-expression through creation, not purchase.
- **Fits:** Build-and-Wear (§3a, M3); pets (M1b).
- **Guard:** size limits so pets stay readable.

#### X3 ★★ Home and pretend-play pack — M3 · M
- **Child:** stamps for a kitchen, a table and chairs, a bookshelf, a TV that plays my Build Rewinds,
  a shop counter, a mailbox, a doorbell; job hats (chef, builder, doctor, firefighter).
- **Why:** pretend play is what Brookhaven proves children love (§1.10).
- **Fits:** stamps (§3a), beds (M1b), Build Rewind (§3a).
- **Guard:** a shop counter uses pretend coins with no value (no trading, §7).

#### X4 ★★ Free emotes and dances, and a team high-five — M3 · M
- **Child:** I wave, dance, cheer and point. When a friend and I both press high-five, we do a
  special double animation. Buddies copy my dance.
- **Why:** self-expression and a language that needs no reading; safe for under-13s.
- **Fits:** §5.9 lists emotes and dances.
- **Guard:** the base set is free; no emote is only for payers.

#### X5 ★★ Idea cards — M3 · S
- **Child:** a light-bulb button shows a picture card: "A house for your dog", "A tower taller than
  the tallest tree", "A buddy with 4 legs", "A bridge over the river".
- **Why:** helps with the blank canvas (R7) without pressure.
- **Fits:** stamps; builder bots can hold up the same cards.
- **Guard:** **no reward** for doing a card (§1.8, overjustification).

#### X6 ★ Music blocks — Later · M
- **Child:** blocks that play notes when stepped on or powered; I build a song; buddies dance nearby.
- **Why:** a different kind of creativity; Minecraft's note blocks are loved.
- **Fits:** smart blocks (§5.5).
- **Guard:** the host limits how many notes play at once, so nobody can spam noise in multiplayer.

### T — Together: friends, bots and sharing

#### T1 ★★★ Bot friends done right — M2 (Task 15 wording) · S
- **Child:** my bot friends admire my builds ("Wow, that tower is huge!"), build next to me, find
  secrets and help in fights. They wear a small robot badge.
- **Why:** relatedness for solo children (§1.1); young children often play *beside* others (§1.12),
  which the builder bot models.
- **Fits:** §12.14 (builder, explorer, fighter).
- **Guard:** bots are always labelled as bots; they never pretend to be real children; they never say
  "don't go" or "we'll miss you"; they never ask for anything.

#### T2 ★★★ Game Blocks with medals and ghost races — M3 (bots) · M; M4 (friends) · M
- **Child:** I build an obstacle course with start, checkpoints and finish. My bot friends try it and
  I race their ghosts. In M4, my friend races my ghost and gets bronze; I have gold.
- **Why:** *agon* among friends; creation plus play; Roblox obbys without code (§2).
- **Fits:** Game Blocks (§3a, M3).
- **Guard:** medals only between friends; no public ranking for under-13s.

#### T3 ★★★ Blueprint gifts and showcase visits — M4 · L
- **Child:** I send my best dragon to a friend as a stamp. When my friend is offline I can still walk
  around a read-only copy of their showcase and leave a sticker in their guestbook.
- **Why:** showing off (§1.9); play when friends' times do not match.
- **Fits:** buddy packing, stamps, Nakama storage (M4).
- **Guard:** friends only; parental consent for under-13s (§8); report button; no public gallery
  unless a human reviews it (T8); visitors can never break anything (§1.7).

#### T4 ★★ Buddy playdates — M4 · M
- **Child:** when my friend visits, our buddies meet, jump around each other and dance.
- **Why:** the signature feature becomes social.
- **Fits:** §3a "Buddies meet friends' buddies" (M2–M4).
- **Guard:** friends only; a visitor can never take, change or wake another player's buddy.

#### T5 ★★ Team photo after the boss — M4 · S
- **Child:** after we beat the Golem, everyone does a victory pose and the game takes a group photo
  for our Memory Books.
- **Why:** a shared memory of a shared win.
- **Fits:** photo mode (§5.9); R2.
- **Guard:** photos stay on the device; sharing goes through the parent gate.

#### T6 ★★ Hide-and-seek mode — M3 (bots) · M; M4 (friends)
- **Child:** one player seeks, the others hide in bushes, barrels and closets. "I hid in a barrel and
  my friend walked right past me!"
- **Why:** a universal childhood game; reuses the M2 stealth system.
- **Fits:** §12.5 hiding spots, crouch, visibility.
- **Guard:** rounds are short; the seeker gets hints after a while so nobody waits forever.

#### T7 ★★ "Show a grown-up" tour — M4 · M
- **Child:** a "Follow me!" beacon lets me lead a visitor (a parent's phone in LAN) around my world.
  My Build Rewinds play for them like a film.
- **Why:** joint media engagement (§1.9, [S31]); parents who see what their children make become
  allies.
- **Fits:** LAN, Build Rewind (§3a).
- **Guard:** only the child starts a tour; LAN or friends only.

#### T8 ★ The EasyCraft Museum — Later · L
- **Child:** a building in the Theater shows the week's best builds by children, chosen by the team.
- **Why:** public celebration of creativity.
- **Guard:** human review of every entry; parental consent; no names shown for under-13s
  (generated usernames only); no voting by strangers.

### P — Pets and companions

**Guard for every item here:** pets and buddies never get sick, never starve, never die, never run
away, and are never sad because the child was away. There is no hunger (§5.3).

#### P1 ★★★ Pets that find secrets — M2 quick win (dog) · S; M3 (others) · S
- **Child:** my dog sniffs, barks and starts digging — there's a treasure chest! My cat meows at a
  wall — it's a fake wall! My rabbit finds a mouse hole (D4).
- **Why:** a pet that *helps* makes the bond meaningful; it also teaches young children where secrets
  hide.
- **Fits:** buried treasure and fake walls (§12.16); pets follow the player (M1b).
- **Guard:** a hint, not a solution: the dog digs a small hole; the child digs the rest.

#### P2 ★★★ Teach tricks — M3 · M
- **Child:** I dance three times next to my dog and it learns to dance. My buddy learns to jump when
  I jump.
- **Why:** competence (I taught it!) and relatedness; like Nintendogs.
- **Fits:** pets and buddies; emotes (X4).
- **Guard:** learned tricks are never forgotten; no "practise every day" timers.

#### P3 ★★ Happy greetings, bedtime together — M3 · S
- **Child:** when I come back, my dog wiggles and runs to me. When I sleep, my pet curls up at the
  foot of the bed.
- **Why:** warmth without guilt.
- **Guard:** greetings are happy only — never "Where were you?"

#### P4 ★★★ Befriend a monster — M3 · M
- **Child:** a slime is tired after a fight. I tap it with the wand, it blinks, smiles and becomes my
  pet slime.
- **Why:** gives a kind choice: fight, hide *or* befriend (autonomy); comforts children who are scared
  of monsters (§1.11); catching creatures is the Pokémon pull (§2).
- **Fits:** monsters (§12.4), the wand, pets (3 per player).
- **Guard:** befriending is never paid; befriended monsters never fight other players.

#### P5 ★★★ The boss becomes a friend — M3 · M (M2 small version: a Golem statue trophy)
- **Child:** when the Stone Golem falls, it crumbles … and a tiny Pebble Golem hops out, rubs its eyes
  and follows me. Every boss has a mini-buddy.
- **Why:** turns a scary enemy into a friend (§1.11); a story children retell; the kindest version of
  "Build it. Bring it to life."
- **Fits:** §12.9 Golem; buddies.
- **Guard:** everyone who fought gets one; it is not sold.

#### P6 ★★ Pet perks — M3 (already in §5.9) · S
- **Child:** my cat glows in caves, my dog barks when a monster is near, my rabbit pulls coins to me.
- **Why:** a pet that is useful makes the bond meaningful (like P1).
- **Fits:** keep §5.9's perks as planned; the warning bark doubles as an accessibility cue (A3).
- **Guard:** perks are never sold and never lost when the child is away.

### G — Gentle challenge and failure

#### G1 ★★★ Cozy / Normal / Brave — M2 quick win · S
- **Child:** when I make a Survivor world I choose a picture: a cosy bed (monsters do half damage, no
  block bag), a sword (normal), or a flame (monsters hit harder; a "Brave" badge on my name tag).
- **Why:** autonomy over difficulty (§1.2); fits the 6-to-12 spread; Minecraft has Peaceful to Hard.
- **Fits:** `ModeRules`, `Health`, knock-out rules (M2 Tasks 1–2).
- **Guard:** the same gold in every setting (no shaming of Cozy); Brave gives only a badge.

#### G2 ★★★ Picture tips after a knock-out — M2 quick win · S
- **Child:** "You were knocked out!" shows a picture tip: a lantern (monsters stay away), a bush
  (hide), a shield (buy one from Tilly).
- **Why:** turns failure into learning; strategy praise (§1.8).
- **Fits:** §12.3 knock-out screen.
- **Guard:** the words are kind and short; never "You failed" or "Game over".

#### G3 ★★★ Honest help after repeated losses — M2 quick win (Golem) · S; M3 all bosses
- **Child:** after I lose, the boss bar shows how far I got ("You got it to 20%!"). After three lost
  fights the Golem arrives "tired" (−25% health), and it says so.
- **Why:** Super Guide-style help (§1.2, [S27]); honesty keeps it fair. Showing real progress in a
  *skill* game is honest feedback, unlike a fake "near miss" in a lottery (§7).
- **Fits:** §12.9 boss rules.
- **Guard:** the help is announced, not hidden; it resets after a win.

#### G4 ★★★ Monsters never break your builds — M2 rule · S
- **Child:** my house is always safe.
- **Why:** the IKEA effect disappears when creations are destroyed (§1.7).
- **Fits:** M2 monsters do not dig; keep it a rule (and a test) for M3's Sand Serpent and other
  universes.
- **Guard:** this item *is* a guard; keep a test for it in the suite.

#### G5 ★★ Hiding feels safe — M2 (inside Task 5) · S
- **Child:** inside a barrel, the sound gets muffled, a cosy vignette appears and a closed-eye icon
  shows "they can't see me".
- **Why:** gives scared children a reliable safe place (§1.11); makes stealth readable without
  meters.
- **Guard:** fair, not a trick: a monster that saw you go in still searches next to the hiding spot (§12.5).

#### G6 ★★ The Totem asks "easier or again?" — M3 · S
- **Child:** after I lose a wave, the Totem offers "Try again" or "Try an easier wave".
- **Why:** player-chosen difficulty, honest DDA (§1.2).
- **Guard:** the easier wave pays the normal gold per monster; the words never shame ("easy mode for babies").

#### G7 ★ Crowns for experts — M3 · S
- **Child (older):** a crown for beating the Golem without being hit; a gold medal time on my
  obstacle course.
- **Why:** optional hard goals keep 11–12-year-olds engaged (Mario's "three pipes").
- **Guard:** cosmetic only.

### R — Progress without pressure

#### R1 ★★★ The Hub Tree — M3 · M
- **Child:** a magic tree grows at my world spawn. Every boss I beat adds a glowing fruit; every
  finished Secret Book page adds an ornament. It gets bigger with every universe.
- **Why:** "progress you can see" (pillar 3) at home; a monument to show friends; a light story
  thread for the universe ladder.
- **Fits:** universes (§5.1), Secret Book (§12.16).
- **Guard:** the tree only grows; it never withers, even after a long break.

#### R2 ★★★ The Memory Book — M3 · M
- **Child:** the game takes a picture at big moments — my first buddy, my first night, the Golem —
  and puts it in a scrapbook with the date.
- **Why:** pride and identity (RITEC "identities" [S59]); a natural thing to show parents (§1.9).
- **Fits:** photo mode (§5.9).
- **Guard:** stored on the device only.

#### R3 ★★ Wish list — M3 · S
- **Child:** I pin the crystal sword at Tilly's shop. A small bar on my screen shows my gold filling
  up toward it.
- **Why:** a goal the child chose (autonomy); big numbers made visual (R16).
- **Fits:** shop (§12.7).
- **Guard:** no timers or "sale ends soon".

#### R4 ★★★ Adventure board instead of daily missions and a daily gift — M3 · S (changes §5.8)
- **Child:** a board shows three picture goals ("Find a geode", "Tame a cat", "Win wave 3"). I pick
  one. When I finish, a new one appears. Goals never expire. Sometimes, while I play, my pet brings me a
  little present.
- **Why:** keeps the goals of §5.8 but removes the "come back every day" pull (appointment mechanics
  [S37]); presents reward *playing*, not returning.
- **Fits:** §5.8 missions; pets.
- **Guard:** no calendar, no "day 5 of 7", no refresh countdown.

#### R5 ★★ Play-style titles — M3 · S
- **Child:** my name tag can say "Buddy Maker", "Secret Hunter", "Monster Friend" or "Brave".
- **Why:** identity; every play style is valued (builders as much as fighters).
- **Fits:** §5.8 titles.
- **Guard:** the child picks which title to show; no titles for logging in or for hours played.

#### R6 ★★ New powers, not just numbers — M2/M3 · S
- **Child:** "Triple jump unlocked!" feels bigger than "+10% damage".
- **Why:** abilities open new play (the LEGO pattern of returning to old places with new powers).
- **Fits:** Survivor starts with double jump (§3b); iron pickaxe opens gold ore.
- **Guard:** Sandbox never locks creative tools.

#### R7 ★★★ Neighbours move in — M4 (M3 if time allows) · L
- **Child:** I build a room with a door, a light and a bed. That night a friendly villager moves in —
  a baker, a gardener, a musician or a painter. The baker leaves a cake on my table (in Survivor it
  heals a heart; there is still no hunger), the gardener
  plants flowers around my house, the musician plays at dusk. My base becomes a little village.
- **Why:** building gets a purpose (Terraria [S25]); a town full of life that the child caused is
  "progress you can see"; companionship for children who play alone (Animal Crossing [S23]); pretend
  play (§1.10).
- **Fits:** beds and homes (M1b), bots' avatar bodies (§12.14), the host-side simulation rules
  (10 Hz decisions, rest far away).
- **Guard:** neighbours never leave because the child was away, never complain, never ask for money;
  optional small wishes ("I'd love a garden!") with no timer.

### O — Onboarding for non-readers

#### O1 ★★★ Icon-first buttons — M2 quick win · S
- **Child:** every button has a clear picture (a spring for JUMP, a wing for FLY, a curved arrow for
  UNDO, a mirror for MIRROR) with a small word underneath. JUMP and ATTACK get bigger (about 2 cm on a
  phone, ≈ 225 px); every other button is at least ≈ 1.2 cm (135 px); rarely used ones (CAM, MIRROR)
  may move into a small menu to make room.
- **Why:** 6–8-year-olds are beginner readers [S15]; bigger targets [S14].
- **Fits:** `HUD._button()` sets text; CC0 icon packs (Kenney) exist.
- **Guard:** keep the word too (helps readers and screen-reader users).

#### O2 ★★★ Picture riddles — M2 quick win · S (content)
- **Child:** the temple note shows three pictures in order — a flower, a stone, a drop — and the
  plates have the same pictures. The Wanderer's three answers are pictures, not sentences.
- **Why:** puzzles a 6-year-old can solve; universal across languages.
- **Fits:** §12.16 riddle notes, puzzle temples and the Wanderer (Task 16 writes the content now).
- **Guard:** wrong answers cost nothing.

#### O3 ★★ Ghost-hand hints — M2 quick win or M3 · S
- **Child:** on my first minutes, a see-through hand shows me: drag here to look, tap to place, hold
  to break.
- **Why:** show, don't tell; children learn by trying [S16].
- **Fits:** the first Sandbox launch; existing tip toast.
- **Guard:** each hint disappears after the child does the gesture once; hints can be turned off.

#### O4 ★★★ Pip teaches by doing, voice first — M3 (already §5.10) · M
- **Child:** Pip babbles, points and shows me one thing at a time: jump the gap, build a bridge, hide
  from the practice monster. I can replay any step.
- **Why:** children learn by trying, not by reading instructions [S15, S16].
- **Fits:** keep §5.10 (tutorial, 500 gold, a hat, Pip as the first pet); add babble voice (F7),
  icons and read-aloud (O6).
- **Guard:** never walls of text; skipping stays possible.

#### O5 ★★★ First-time picture hints — M2 quick win · S
- **Child:** the first night, a moon picture: "Monsters come out! Hide or light a lantern." The first
  time I hit gold ore without an iron pickaxe, I see a picture of the iron pickaxe and an arrow to
  Tilly. An arrow shows the Totem the first time.
- **Why:** M2 has many systems and no tutorial until M3 (R4).
- **Fits:** existing HUD toasts.
- **Guard:** each hint shows once; a setting turns hints off.

#### O6 ★★★ Read-aloud button — M3 · S
- **Child:** a speaker icon next to any text (riddle, tip, shop item) reads it out loud.
- **Why:** helps beginner readers and children with dyslexia.
- **Fits:** Godot's built-in text-to-speech (`DisplayServer.tts_speak`, supported on Android and iOS;
  enable "Audio > General > Text to Speech" in the project settings) [S60].
- **Guard:** read game text only, never chat messages from other players.

#### O7 ★★★ Languages — M3 (foundation) · M; M5 (languages)
- **Child:** the game speaks my language.
- **Why:** most children in the world do not read English; icons help but do not cover riddles and
  shops.
- **Fits:** Godot `TranslationServer`; keep all strings in translation files from M3 on.
- **Guard:** translate the safety texts first (the stay-safe card, the parent corner, the privacy notice); quick-chat phrases stay preset in every language.

#### O8 ★★ "Simple controls?" at first launch — M3 · S
- **Child:** two pictures: *Simple* (auto-jump, camera follows me, bigger buttons) and *Classic*.
- **Why:** our age band cannot tell a 6-year-old from a 12-year-old (§1.12); a choice respects
  autonomy.
- **Fits:** settings; A4–A6.
- **Guard:** both choices are equal pictures (no nudge, [S49]); the child can switch any time in settings.

### E — Seasonal and live events, done ethically

**Rules for all events:** no countdown timers in the game; nothing is "gone forever" — event items
return every year and can also be earned later another way; events work offline (device date) before
M4; no event is tied to buying anything; parents can see the event calendar.

#### E1 ★★ Real seasons — Later · M
- **Child:** in October leaves turn orange; in December snow falls in Green Meadows; spring has
  blossoms.
- **Why:** the world changes with the child's own life.
- **Fits:** the generator's block palette; the sky cycle.
- **Guard:** follow the device region (winter comes in July in Australia) or keep seasons mild; nothing seasonal is "limited".

#### E2 ★★ Yearly festivals — Later · M each
- **Child:** *Star Night* (a meteor shower with crystal gifts), *Pumpkin Days* (pumpkins you can wake
  with the wand), *Snow Day* (snowman buddies), *Kite Day* (wind currents, kite stamps).
- **Why:** anticipation and shared talk with friends ("Star Night is next week!"); Animal Crossing
  proves returning yearly events work.
- **Guard:** culturally neutral names; items return next year; no event leaderboards for money.

#### E3 ★ Friends' build weeks — M4/Later · M
- **Child:** "Castle week!" — a theme suggestion; friends see each other's castles.
- **Why:** a shared theme gives friends something to talk about and gives creations an audience (§1.9).
- **Guard:** everyone who takes part gets the same sticker; no prizes that create pressure; friends
  only.

#### E4 ★ Surprise visitors from the server — Later · M
- **Child:** this week, whales swim past the coast.
- **Why:** small surprises keep a familiar world fresh (§1.4).
- **Guard:** a delight, not a deadline; nothing to collect that disappears.

### H — Home and parents: healthy play

#### H1 ★★★ Sleep and save — M2 quick win · S
- **Child:** when I sleep in my bed, the screen says "Good night! Your world is saved." with two
  pictures: *Wake up* and *Stop for today*.
- **Why:** a natural stopping point. Research with young children found transitions work better when
  the technology helps (and that arbitrary countdown warnings made things worse) [S34]. The UK
  Children's Code asks for pause and save "without losing progress" [S48].
- **Fits:** beds, sleep and autosave (M1b).
- **Guard:** both choices look equal (no bigger, brighter "keep playing" button) [S49].

#### H2 ★★★ Parent corner — M3 (on device) · M; M4 (remote, with consent)
- **What parents see behind the parent gate:** today's and this week's play time (stored on the
  device only), a gentle reminder they can set (for example 45 minutes), switches for chat, online
  play, the Theater, notifications and monster defaults, and a gallery of what the child built.
- **How the reminder works:** it waits for the next natural stop (a wave ends, the child reaches
  home, the child sleeps), then Pip suggests a rest with the Sleep-and-save screen. It never locks the
  game in the middle of a fight.
- **Why:** parents are allies; the Nintendo Switch parental controls app is the model (daily play
  time, limits, alarms) [S56].
- **Guard:** no data leaves the device before M4; in M4, only with parental consent.

#### H3 ★★★ The no-guilt word list (a test) — M2 quick win · S
- **What:** a unit test that scans all player-facing strings for banned phrases ("miss you",
  "don't go", "last chance", "hurry", "only today", "you'll lose", "come back").
- **Why:** makes section 7 enforceable forever, cheaply.
- **Fits:** `tests/run_tests.sh`.
- **Guard:** this item *is* a guard; it also scans the translation files once they exist (O7).

#### H4 ★★★ Notifications off by default — M3 · S
- **Child and parent:** the game never buzzes the phone unless a parent asked for it.
- **Why:** notifications are a "sticky" feature under the UK Children's Code [S48]; guilt
  notifications are a known manipulation [S36].
- **Fits:** the only planned notification is the Gold Farm's "Your farm is full!" (§5.6).
- **Guard:** off by default; for `under_13` only a parent can turn them on (parent gate); at most one
  a day; never between 20:00 and 08:00; only informative, never emotional ("Your pets miss you!").

#### H5 ★★ The trust promise — M5 · S
- **Parent:** the store page and the parent corner say: "No ads. No purchases. No loot boxes. No chat
  with strangers for children."
- **Why:** parents choose children's games on trust; the promise matches Google's Teacher Approved
  criteria (age-appropriate, delight, no manipulative ads or purchases) [S43].
- **Fits:** it is already true because of spec §6.
- **Guard:** the promise must stay true; any future change goes through the lead and the owner.

#### H6 ★★★ Shorts Theater guardrails — M3 · S
- **Child:** in the Theater I tap to see the next video; after 5 videos a card says "That's the
  show!" with a picture of my world. The first channel is **EasyCraft TV**: our own clips and my own
  Build Rewinds.
- **Why:** autoplay undermines children's self-regulation [S35]; the UK Code lists autoplay as a
  "sticky" feature [S48].
- **Fits:** §5.12 (curated channels, no rewards for watching, server kill-switch); Build Rewind (§3a).
- **Guard:** for `under_13`, no autoplay of the next video; a parent switch turns the Theater off
  (default off for under-13s is worth considering).

#### H7 ★★ Codes found in the game — M3 · S
- **Child:** the Wanderer whispers a secret code; a bottle on the beach has another; the news board
  at spawn shows the code of the week.
- **Why:** most social networks are 13+ (R9); codes found by play are also a discovery reward.
- **Fits:** admin codes (§5.11), the Wanderer (§12.16), bottles (D5).
- **Guard:** codes do not expire within days (no FOMO); codes never unlock random rewards.

### A — Accessibility

The Game Accessibility Guidelines group advice into motor, cognitive, vision, hearing and general
[S57]. Children with dyslexia, colour blindness (about 1 in 12 boys [S58]), motor difficulties or
hearing loss are a large share of players.

#### A1 ★★★ Never colour alone — M2 quick win · S
- **Child:** I can tell an iron sword from a crystal one by its dots, even if I cannot tell the
  colours apart.
- **Why:** about 1 in 12 boys is colour-blind [S58].
- **Fits:** tool tiers get 1–5 dots or stripes (M2 Task 6 plans colour only); monster levels already
  use spikes (§12.4).
- **Guard:** check every new signal for a shape or icon.

#### A2 ★★★ Reduce motion and flashes — M2 quick win · S
- **Child:** if shaking makes me feel sick, I turn it off.
- **Why:** motion sickness in 3D games and photosensitivity; WCAG 2.3.1 sets the limit at 3 flashes a
  second [S61].
- **Fits:** M2 Task 11 adds screen shake; shooting stars, the Golem's slam and lightning add flashes.
- **Guard:** a setting for shake and camera bob; nothing flashes more than 3 times a second.

#### A3 ★★★ See the sounds — M2 (danger arrow) · S; M3 (captions) · S
- **Child:** when a monster behind me notices me, an arrow glows at the edge of the screen; voice lines
  have captions; my dog's warning bark shows an icon.
- **Why:** helps deaf children and everyone playing with the sound off (R17).
- **Fits:** the monster's "!" state (§12.5) triggers the arrow; pet perks (P6).
- **Guard:** arrows are small and fade; they help, they do not nag.

#### A4 ★★ Button size and layout — M3 · M
- **Child:** I can make the buttons bigger and put them where my thumbs are; left-handed players can
  swap sides.
- **Why:** hands and devices differ; children under 9 need about 2 cm targets [S14].
- **Fits:** §5.15 already promises big buttons, movable controls and a left-handed layout.
- **Guard:** the default layout already keeps main buttons at about 2 cm.

#### A5 ★★ Other ways to break and aim — M3 · S
- **Child:** if holding is hard for me, I switch on BREAK mode and just tap; I can make the aim help
  stronger.
- **Why:** holding still for 0.25 s is hard for some hands (R3) [S17].
- **Fits:** `TouchClassifier.HOLD_TIME`, the M1b aim assist.
- **Guard:** the BREAK mode shows clearly on screen, so taps never break blocks by surprise.

#### A6 ★★★ Simple controls — M3 · M
- **Child:** I walk into a one-block step and hop up by myself; the camera turns to follow me; I see
  only the buttons I need right now.
- **Why:** two-hand coordination (joystick + camera drag) is hard for 6–8-year-olds [S14]; intuitive
  controls drive competence and autonomy [S1].
- **Fits:** context buttons already exist (ATTACK only with a weapon, SLEEP near a bed); add CROUCH
  only at night or near hiding spots, auto-jump and a following camera.
- **Guard:** everything can be switched back to Classic (O8).

#### A7 ★★ Text size and a clear font — M3 · S
- **Child:** I can make the words bigger; the letters are clear and not squeezed together.
- **Why:** beginner readers and children with dyslexia read large, well-spaced text more easily.
- **Fits:** §5.15 has a text-size option.
- **Guard:** popular dyslexia fonts use the SIL Open Font License, not CC0 — the owner must decide
  whether OFL fonts are allowed under the CC0 rule.

#### A8 ★★ Tablets and small phones — M5 · S
- **Child:** the game looks right on my family's tablet and on my old small phone.
- **Why:** Mavoa et al. found most young Minecraft players use **tablets** [S24]; many children use
  hand-me-down phones.
- **Fits:** the 1280 × 720 design space with `expand` stretching; the emulator.
- **Guard:** add a tablet AVD for layout checks (layout only; the performance device stays
  `Pixel_8_API_35`).

---

## 6. Engagement techniques we use (healthy)

These are our "tricks": they make children want to play, and a parent would approve if we explained
them.

| # | Technique | In EasyCraft | Why it is healthy | Guard |
|---|---|---|---|---|
| 1 | **Magic payoff in seconds** | Build → wand → alive (F3) | Competence and pride (§1.1, §1.7) | Never paywalled |
| 2 | **Rules to discover** | Buddy personalities, secret shapes (D1) | Curiosity and experiment (§1.4) | Hints found in play |
| 3 | **Visible, closable gaps** | Secret Book "???", Animal Book silhouettes | Information gap (§1.3) | Finite; closed by playing only |
| 4 | **Free surprises** | Shooting stars, golden animals, bottles, living sky | Delight, exploration | Never sold; never a timer |
| 5 | **The child chooses the challenge** | Totem waves, Cozy/Normal/Brave | Autonomy + flow (§1.2) | Same gold for all levels |
| 6 | **Readable challenge** | The Golem's wind-ups and dazed state | Competence | Clear telegraphs, fair hits |
| 7 | **Optional, honest help** | Tired Golem, picture tips | Flow for young players | Announced, not hidden |
| 8 | **Juice** | Pops, cracks, confetti, chimes | Clear feedback, joy | Reduce-motion setting |
| 9 | **Collections** | Animals, buddies, treasures, badges | Fits ages 6–12 (§1.6) | No random paid packs |
| 10 | **Self-expression** | Build-and-Wear, emotes, styles | Identity (RITEC) | Base set free |
| 11 | **Companions** | Pets, buddies, bots, mini-bosses | Relatedness | Never guilt; bots labelled |
| 12 | **Showing off safely** | Trophy shelf, Memory Book, friend visits | Pride, relatedness (§1.9) | Friends only, consent |
| 13 | **Pretend play props** | Home pack, job hats | Mimicry (§1.10) | No real-value trading |
| 14 | **Movement thrills** | Triple jump, Giant, riding a dragon | Ilinx (§1.5) | Reduce motion |
| 15 | **Goals the child sets** | Wish list, adventure board | Autonomy | No expiry, no timers |
| 16 | **Effort and strategy praise** | Pip, bots, tips | Persistence after failure (§1.8) | No "genius" praise |
| 17 | **Unexpected celebrations** | "10th buddy!" confetti | Informational reward (§1.8) | Not promised in advance |
| 18 | **Natural stopping points** | Sleep and save, end of a wave | Self-regulation (H1) | Equal buttons |
| 19 | **Welcome back without loss** | Coin shower after the farm (§5.6), happy pets | Returning feels good | Nothing is lost by being away |
| 20 | **Anticipation from curiosity** | Portal peek, next universe | Wonder | No countdowns |

---

## 7. Techniques we reject

| Technique | Seen in | Why we will not use it |
|---|---|---|
| **Paid loot boxes, gacha, random paid rewards** | Many free-to-play games | Spec §6 and §5.9 ("no random boxes, ever"). Belgium ruled paid loot boxes illegal gambling in 2018 [S39]; the Netherlands acted too. Spending on loot boxes is linked to problem gambling (7,422 gamers; replicated) [S38]. The EU's 2025 guidance says to avoid loot boxes for minors [S50]; England's Children's Commissioner asked for them to be classed as gambling [S40]. |
| **Random boxes bought with earned gold, "spin the wheel"** | Mobile games | Same psychology as loot boxes, and gold may become buyable if a cosmetic shop comes later (§8 "Later"). Belgium's law does not require the prize to have money value [S39]. Treasure *found in the world* stays fine. |
| **Daily streaks and streak loss** | Duolingo, Snapchat | Spec §6. An "appointment" dark pattern [S37]. |
| **Things that wither, starve or run away while you are away** | FarmVille crops, virtual pets | Appointment dark pattern using loss aversion [S37]; guilt. |
| **Fake time pressure: countdowns, "only today", "last chance"** | Shops, events | One of the four main manipulations found in children's apps [S36]; the EU guidance targets it [S50]. |
| **Guilt from characters** ("Don't go! I'll be sad!") | About 1 in 4 apps used by young children (24.8% of 133) [S36] | Harms children; parasocial pressure. Enforced by the H3 test. |
| **Emotional or guilt notifications** ("Your pet misses you!") | Many mobile games | Spec §6; the UK Code lists notifications as "sticky" features [S48]. |
| **Premium currencies that hide real money** (gems) | Free-to-play | The EU guidance says avoid tokens that obscure real value [S50]; Google Play requires virtual and real money to be clearly separate [S42]. |
| **Pay to win, pay to skip, energy timers** | Free-to-play | Spec §6; "monetary" dark patterns [S37]. |
| **Rewarded ads, "watch a video for a bonus"** | Mobile games | Spec §6 ("No rewards for watching videos"). §2 must drop its "rewarded ads" line (R11). |
| **Autoplay-next and endless feeds** | Video apps | Undermines self-regulation [S35]; UK Code [S48]. |
| **Tracking to maximise play time** (behaviour analytics, advertising IDs) | Many apps | COPPA [S45]; Google Play Families forbids sending advertising IDs from children [S42]; Apple's Kids category bans third-party analytics and ads [S44]; UK Code: profiling off by default [S47]. |
| **Hard-to-find exit, "Are you sure? You'll lose your bonus!"** | Many apps | "Navigation constraints" [S36]; the UK Code asks that one option is not made harder than another [S49]. |
| **Flashing "FREE GIFT!" lures on the way out** | Children's apps | "Lures" [S36]. |
| **Bots or fake activity pretending to be real children** ("Mia just joined!") | Some social games | Deception; "impersonation" dark patterns [S37]. Our bots are always labelled. |
| **Fake "near miss" in random rewards** | Slot-machine design | Gambling psychology. (Showing real progress in a skill fight is honest and allowed, G3.) |
| **Open trading of valuable items between players** | Roblox trading culture | Scams, pressure and tears; needs heavy moderation. Gifts between friends (T3) are fine. |
| **"Limited edition, never returns" items** | Battle passes, rotating shops | FOMO; our events return every year (E rules). |
| **Public leaderboards and shaming for young children** | Competitive games | Social pressure; medals stay among friends (T2). |
| **Paid cosmetics as social status** | "Default skin" teasing in big games | Children who cannot pay get mocked; our cosmetics are built, found or earned (§5.9, X2). |
| **Default-on voice chat or public profiles** | Fortnite (FTC case) | The FTC called Fortnite's default-on voice chat an unfair default [S41]; high privacy by default is the UK Code's standard [S47]. |

---

## 8. Law and store rules: what they mean for EasyCraft

*Not legal advice. Dates checked on 2026-09-24. The lawyer review (spec §5.14, M5) decides.*

| Rule | What it says (short) | What EasyCraft must do | When |
|---|---|---|---|
| **Google Play Families policy** [S42] | Mixed-audience apps need a neutral age screen; no advertising ID or precise location from children; only certified ad SDKs; social features need an in-app safety reminder, **adult action before children exchange personal information**, and parent controls; virtual and real money clearly separate | Keep the neutral birth-year picker (already neutral: decade, then year). Add a picture "stay safe online" card before the first online game. Parent gate before friends and free text. No third-party SDKs that collect data. | M4 (social), M5 (review) |
| **Google Play Teacher Approved** [S43] | Teachers rate apps for age-appropriateness, quality, enrichment, **delight**, and ads/purchases | Aim for it: no ads, no purchases, icon-first UI, voice | M5 |
| **Apple App Store, guideline 1.3 (Kids category) and 5.1.4** [S44] | No third-party analytics or ads in Kids-category apps; a **parental gate** before links out, purchases or permission requests | Decide in M5: list in the Kids category or as a general app with an age screen (a ruling for the lead). Either way: the parent gate guards links (Theater), sharing and settings. | M5 |
| **COPPA (US), 2025 rule update** [S45] | Personal information of under-13s needs **verifiable parental consent**; separate consent for disclosure to third parties; written security and data-retention policies; compliance date 22 April 2026 | Before friends, invites, usernames visible to others, chat or shared builds for `under_13`: get VPC (Epic's **Kids Web Services** is free for developers [S53]). Offline play needs nothing. Suggest the existing RANDOM username first (fewer real names typed in). | M4 |
| **GDPR Article 8 ("GDPR-K")** [S46] | Under the national digital age of consent (13–16), a parent must consent to data processing based on consent | Treat "child" as *under the local age* (for example under 16 in Germany or the Netherlands), not simply under 13. | M4 |
| **UK Children's Code** (15 standards) [S47] | High privacy by default; **Standard 5:** no "sticky" features (reward loops, notifications, autoplay) that harm well-being; present "continue" options neutrally; pause without losing progress [S48]. **Standard 13:** no nudges toward lower privacy; nudges toward well-being are welcome [S49] | H1, H3, H4, H6; high-privacy defaults in M4 (profiles private, online off until a parent turns it on). | M3–M4 |
| **EU Digital Services Act, Article 28 guidelines (July 2025)** [S50] | Benchmark for protecting minors on online platforms: avoid loot boxes and virtual currencies that hide real value; safe defaults | Already in §6. Becomes directly relevant if we add public sharing (T8). | M4/Later |
| **US state app-store age laws** (Texas SB 2420 in force since 4 June 2026; Utah May 2026; Louisiana July 2026) [S51, S52] | The stores send age ranges (and parental consent status) to apps; apps must respect them | Read **Google Play Age Signals** and Apple's **Declared Age Range** when available; map "under 13 / 13–15 / 16–17 / 18+" to our bands; tell the store about significant changes. | M4 (Android), M5 (iOS) |
| **Loot-box rules** (Belgium, Netherlands, UK debate, EU guidance) [S39, S40, S50] | Paid random rewards are gambling or strongly discouraged for minors | Already forbidden by §6; keep "no random rewards for any currency" (§7). | Always |
| **Age ratings (IARC: PEGI, ESRB)** [S19] | PEGI 7 allows mild scares and non-realistic violence to fantasy creatures | Target PEGI 7 / ESRB E10+: cartoon weapons against fantasy monsters, no blood (§5.3), no fighting players. Chat and sharing add interactive-element notices. | M5 |

**Lessons from others.** Epic paid $520 million to the FTC (2022) for COPPA violations and purchase
dark patterns, including voice chat on by default [S41]. Roblox restricted messaging for under-13s in
2024 [S54] and faces lawsuits from several US states (2025) over child safety [S55]. Ofcom's 2025 report
highlights children gaming with strangers online [S62]. For EasyCraft: friends by exact username
only (already §5.13), quick chat only for under-13s (already), no public lobbies, no DMs with strangers,
reports reviewed by a human.

---

## 9. How we will know it works

**Playtests with children** (spec §7.6 and M1 acceptance item 10 — still waiting on the owner).
Use `docs/playtests/m1-template.md` and add, per session:
- Age group (6–7, 8–10, 11–12), device (phone or tablet), sound on or off.
- **Watch, don't help, for 5 minutes.** Count: help requests; mis-taps; "what do I do?" moments.
- **Time to the first buddy** (target: under 3 minutes without help).
- **Delight:** smiles, laughs, "look!" moments — and which feature caused them.
- **The friend test:** "What would you tell a friend about this game?" Their answer shows which
  signature moments land.
- **The stopping test:** at the end, does the child stop easily when asked? (Tantrums mean our
  stopping points are not working.)

**Automated checks** (cheap, fit the TDD rule):
- *Button size test:* JUMP and ATTACK ≥ 225 px in the 1280 × 720 design space (≈ 2 cm on a 6" phone);
  every other touch button ≥ 135 px (≈ 1.2 cm).
- *No-guilt word test* (H3).
- *Colour-alone review:* every new status has a shape or icon (A1).
- *Flash test:* effects flash at most 3 times a second (A2).
- *Density metric:* points of interest per minute in the autopilot walk (D7).
- *Privacy test:* no personal data goes to any server before M4 (LAN play stays local), and in M4
  nothing for `under_13` before consent.

**Local-only measurement.** Any play-time numbers (H2) stay on the device. We do not add analytics
SDKs for children (§7, §8).

---

## 10. Sources

- **[S1]** Ryan, Rigby & Przybylski (2006). *The motivational pull of video games: A self-determination theory approach.* Motivation and Emotion. <https://selfdeterminationtheory.org/SDT/documents/2006_RyanRigbyPrzybylski_MandE.pdf>
- **[S2]** Przybylski, Rigby & Ryan (2010). *A motivational model of video game engagement.* <https://selfdeterminationtheory.org/SDT/documents/2010_PrzybylskiRigbyRyan_ROGP.pdf>
- **[S3]** Fong, Zaleski & Leach (2015). *The challenge–skill balance and antecedents of flow: A meta-analytic investigation.* <https://www.researchgate.net/publication/267450034_The_challenge-skill_balance_and_antecedents_of_flow_A_meta-analytic_investigation>
- **[S3b]** *Being enjoyably challenged is the key to an enjoyable gaming experience: an experimental approach in a first-person shooter game* (2018). <https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5954478/>
- **[S4]** Loewenstein (1994). *The psychology of curiosity: A review and reinterpretation.* <https://www.cmu.edu/dietrich/sds/docs/loewenstein/PsychofCuriosity.pdf>
- **[S5]** Stahl & Feigenson (2015). *Observing the unexpected enhances infants' learning and exploration.* Science. <https://www.science.org/doi/10.1126/science.aaa3799>
- **[S6]** Caillois (1958/1961). *Man, Play and Games.* <https://en.wikipedia.org/wiki/Man,_Play_and_Games>
- **[S7]** Bartle (1996). *Hearts, Clubs, Diamonds, Spades: Players who suit MUDs.* <https://mud.co.uk/richard/hcds.htm>
- **[S8]** Norton, Mochon & Ariely (2012). *The IKEA effect: When labor leads to love.* Journal of Consumer Psychology. <https://www.sciencedirect.com/science/article/abs/pii/S1057740811000829>
- **[S9]** Lepper, Greene & Nisbett (1973). *Undermining children's intrinsic interest with extrinsic reward.* <https://web.mit.edu/curhan/www/docs/Articles/15341_Readings/Motivation/Lepper_et_al_Undermining_Childrens_Intrinsic_Interest.pdf>
- **[S10]** Deci, Koestner & Ryan (1999). *A meta-analytic review of experiments examining the effects of extrinsic rewards on intrinsic motivation.* Psychological Bulletin. <https://home.ubalt.edu/tmitch/642/articles%20syllabus/Deci%20Koestner%20Ryan%20meta%20IM%20psy%20bull%2099.pdf>
- **[S11]** Mueller & Dweck (1998). *Praise for intelligence can undermine children's motivation and performance.* <https://pubmed.ncbi.nlm.nih.gov/9686450/>
- **[S12]** Psychology Today (2023). *Children who collect are not uncommon.* <https://www.psychologytoday.com/us/blog/the-mind-of-a-collector/202311/children-who-collect-are-not-uncommon>
- **[S13]** Satoshi Tajiri and the origin of Pokémon. <https://en.wikipedia.org/wiki/Satoshi_Tajiri>
- **[S14]** Nielsen Norman Group. *Design for kids based on their stage of physical development.* <https://www.nngroup.com/articles/children-ux-physical-development/>
- **[S15]** Nielsen Norman Group. *Designing for kids: cognitive considerations.* <https://www.nngroup.com/articles/kids-cognition/>
- **[S16]** Nielsen Norman Group. *UX design for children (ages 3–12)*, report. <https://www.nngroup.com/reports/children-on-the-web/>
- **[S17]** Anthony, Brown, Nias, Tate & Mohan (2012). *Interaction and recognition challenges in interpreting children's touch and gesture input on mobile devices.* <https://www.researchgate.net/publication/235410901_Interaction_and_Recognition_Challenges_in_Interpreting_Children's_Touch_and_Gesture_Input_on_Mobile_Devices>
- **[S18]** Cantor (1994). *Children's fright reactions to television and films.* Poetics. <https://www.sciencedirect.com/science/article/abs/pii/0304422X9400012U>
- **[S19]** PEGI. *What do the labels mean?* <https://pegi.info/what-do-the-labels-mean>
- **[S20]** Lillard et al. (2013). *The impact of pretend play on children's development: A review of the evidence.* Psychological Bulletin. <https://psycnet.apa.org/record/2012-22641-001>
- **[S21]** Motionographer (2016). *The design process behind Toca Boca's infectious apps.* <https://motionographer.com/2016/04/27/the-design-process-behind-toca-bocas-infectious-apps/>
- **[S22]** Naavik. *Roblox success stories: Blox Fruits, Brookhaven RP & Adopt Me!* <https://naavik.co/deep-dives/roblox-blox-fruits-brookhaven-adopt-me/> and Roblox Wiki, *Brookhaven RP*. <https://roblox.fandom.com/wiki/Brookhaven_by_Voldex/Brookhaven_RP>
- **[S23]** *Animal Crossing and COVID-19: A qualitative study examining how video games satisfy basic psychological needs during the pandemic* (2022). Frontiers in Psychology. <https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2022.800683/full>
- **[S24]** Mavoa, Carter & Gibbs (2018). *Children and Minecraft: A survey of children's digital play.* New Media & Society. <https://journals.sagepub.com/doi/abs/10.1177/1461444817745320>
- **[S25]** Official Terraria Wiki. *House.* <https://terraria.wiki.gg/wiki/House>
- **[S26]** LEGO Games Wiki. *LEGO Star Wars: The Video Game* (no game over; lose studs and respawn). <https://legogames.fandom.com/wiki/LEGO_Star_Wars:_The_Video_Game>
- **[S27]** Mark Brown (Game Maker's Toolkit). *Super Mario's invisible difficulty settings.* <https://gmtk.substack.com/p/super-marios-invisible-difficulty>; Nintendo Wiki, *Super Guide*. <https://nintendo.fandom.com/wiki/Super_Guide>
- **[S28]** Hunicke (2005). *The case for dynamic difficulty adjustment in games.* <https://dl.acm.org/doi/10.1145/1178477.1178573>
- **[S29]** Jonasson & Purho (2012). *Juice it or lose it* (GDC Europe). <https://www.gdcvault.com/play/1016487/juice-it-or-lose>; Swink, *Game Feel* (2008), summary: <https://eolt.org/articles/game-feel/>
- **[S30]** *LittleBigPlanet* ("Play, Create, Share"). <https://en.wikipedia.org/wiki/LittleBigPlanet>
- **[S31]** Takeuchi & Stevens (2011). *The new coviewing: Designing for learning through joint media engagement.* Joan Ganz Cooney Center. <https://joanganzcooneycenter.org/publication/the-new-coviewing-designing-for-learning-through-joint-media-engagement/>
- **[S32]** Sauce, Liebherr, Judd & Klingberg (2022). *The impact of digital media on children's intelligence while controlling for genetic differences in cognition and socioeconomic background.* Scientific Reports. <https://www.nature.com/articles/s41598-022-11341-2>
- **[S33]** Common Sense Media (2021). *The Common Sense Census: Media use by tweens and teens.* <https://www.commonsensemedia.org/sites/default/files/research/report/8-18-census-integrated-report-final-web_0.pdf>
- **[S34]** Hiniker, Suh, Cao & Kientz (2016). *Screen time tantrums: How families manage screen media experiences for toddlers and preschoolers.* CHI. <https://faculty.washington.edu/alexisr/ScreenTimeTantrums.pdf>
- **[S35]** Hiniker, Heung, Hong & Kientz (2018). *Coco's Videos: An empirical investigation of video-player design features and children's media use.* CHI. <https://dl.acm.org/doi/10.1145/3173574.3173828>
- **[S36]** Radesky et al. (2022). *Prevalence and characteristics of manipulative design in mobile applications used by children.* JAMA Network Open. <https://jamanetwork.com/journals/jamanetworkopen/fullarticle/2793493>
- **[S37]** Zagal, Björk & Lewis (2013). *Dark patterns in the design of games.* FDG. <https://www.semanticscholar.org/paper/Dark-patterns-in-the-design-of-games-Zagal-Bj%C3%B6rk/19a241378b06d868eb5f6b76027172c3aaca86f4>
- **[S38]** Zendle & Cairns (2018). *Video game loot boxes are linked to problem gambling.* <https://pmc.ncbi.nlm.nih.gov/articles/PMC6248934/>; replication (2019): <https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0213194>
- **[S39]** Game Informer (2018). *Belgium classifies loot boxes as illegal.* <https://gameinformer.com/b/news/archive/2018/04/25/belgium-classifies-loot-boxes-as-illegal>; UK Gambling Commission advisory board, *International approaches*. <https://www.gamblingcommission.gov.uk/manual/lootboxes-advice-to-the-gambling-commission-from-absg/international-approaches-lootboxes-advice-to-the-gambling-commission-from>
- **[S40]** Children's Commissioner for England (2019). *Gaming the system.* <https://www.childrenscommissioner.gov.uk/publication/gaming-the-system/>
- **[S41]** US FTC (2022). *Fortnite video game maker Epic Games to pay more than half a billion dollars over FTC allegations.* <https://www.ftc.gov/news-events/news/press-releases/2022/12/fortnite-video-game-maker-epic-games-pay-more-half-billion-dollars-over-ftc-allegations>
- **[S42]** Google Play. *Families policies.* <https://support.google.com/googleplay/android-developer/answer/9893335?hl=en>
- **[S43]** Google Play. *Teacher Approved.* <https://play.google.com/console/about/programs/teacherapproved/>
- **[S44]** Apple. *App Review Guidelines* (1.3 Kids Category; 5.1.4 Kids). <https://developer.apple.com/app-store/review/guidelines/>
- **[S45]** US Federal Register (22 April 2025). *Children's Online Privacy Protection Rule* (final amendments). <https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule>; FTC press release: <https://www.ftc.gov/news-events/news/press-releases/2025/01/ftc-finalizes-changes-childrens-privacy-rule-limiting-companies-ability-monetize-kids-data>
- **[S46]** GDPR Article 8. <https://gdpr-info.eu/art-8-gdpr/>; ages by country: euCONSENT. <https://euconsent.eu/digital-age-of-consent-under-the-gdpr/>
- **[S47]** UK ICO. *Age appropriate design: a code of practice — code standards.* <https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/code-standards/>
- **[S48]** UK ICO. *Standard 5: Detrimental use of data.* <https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/5-detrimental-use-of-data/>
- **[S49]** UK ICO. *Standard 13: Nudge techniques.* <https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/13-nudge-techniques/>
- **[S50]** European Commission (14 July 2025). *Guidelines on the protection of minors under the Digital Services Act.* <https://digital-strategy.ec.europa.eu/en/library/commission-publishes-guidelines-protection-minors>; summary: <https://www.osborneclarke.com/insights/new-european-guidelines-issued-protect-minors-digital-environment>
- **[S51]** Google Play Console Help. *Changes to Google Play for upcoming app store bills* (Texas SB 2420, Play Age Signals API). <https://support.google.com/googleplay/android-developer/answer/16569691?hl=en>; Texas Tribune (28 May 2026). <https://www.texastribune.org/2026/05/28/texas-apple-google-app-store-age-verification/>
- **[S52]** Apple Developer. *Age requirements for apps distributed in Brazil, Australia, Singapore, Utah, and Louisiana* (Declared Age Range API). <https://developer.apple.com/news/?id=f5zj08ey>; WWDC25 *Deliver age-appropriate experiences in your app*. <https://developer.apple.com/videos/play/wwdc2025/299/>
- **[S53]** Epic Games. *Epic Games and SuperAwesome offer free parent verification for all developers* (Kids Web Services). <https://www.epicgames.com/site/en-US/news/epic-games-and-superawesome-offer-free-parent-verification-for-all-developers>
- **[S54]** Roblox (November 2024). *Major updates to our safety systems and parental controls.* <https://about.roblox.com/newsroom/2024/11/major-updates-to-our-safety-systems-and-parental-controls>
- **[S55]** Kentucky Attorney General (2025), lawsuit against Roblox. <https://www.kentucky.gov/Pages/Activity-stream.aspx?n=AttorneyGeneral&prId=1832>; Tennessee Attorney General (Dec 2025). <https://www.tn.gov/attorneygeneral/news/2025/12/18/pr25-60.html>
- **[S56]** Nintendo. *Nintendo Switch Parental Controls app.* <https://www.nintendo.com/us/mobile-apps/parental-controls/>
- **[S57]** *Game Accessibility Guidelines* (full list). <https://gameaccessibilityguidelines.com/full-list/>
- **[S58]** Colour Blind Awareness. *About colour blindness.* <https://www.colourblindawareness.org/colour-blindness/>
- **[S59]** UNICEF. *RITEC Design Toolbox* (RITEC-8 well-being dimensions). <https://www.unicef.org/childrightsandbusiness/workstreams/responsible-technology/online-gaming/ritec-design-toolbox>
- **[S60]** Godot documentation. *Text to speech.* <https://docs.godotengine.org/en/stable/tutorials/audio/text_to_speech.html>
- **[S61]** W3C. *Understanding WCAG 2.1 success criterion 2.3.1: Three flashes or below threshold.* <https://www.w3.org/WAI/WCAG21/Understanding/three-flashes-or-below-threshold.html>
- **[S62]** Ofcom (2025). *Children and parents: media use and attitudes report 2025.* <https://www.ofcom.org.uk/media-use-and-attitudes/media-habits-children/children-and-parents-media-use-and-attitudes-report-2025>
