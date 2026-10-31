# Success S3: My Business's shop and the Market Square (owner #115)

The owner (2026-10-16 11:49, #115): "in life skills we need more, we need skills school dont deliver, skills releted to
real life, how to be successfull, business, trading, money, comunications, connections, everything to be sucsessfull".
The brief: `docs/superpowers/plans/2026-10-17-success-s3-brief.md`; the design: `docs/design/success-skills.md` §2
systems 1 (My Business: the Middle track's shop) and 2 (the Market Square), §3 the guardrails, §4 parents; the spec:
§27.8 ("As built (S3)"). Built by the Success S3 agent on the worktree branch `worktree-agent-afa50a9cb114d4053`, from
`lead-merge` at `2b4de380`, on Life's framework and S2's (nothing forked). No editor, no emulator, no adb, no download (a
few web searches to check facts and pages, nothing saved), no agents. Logs: the session scratchpad's `success3_*`. The
experts' review sheet, written from the data: `docs/devlog/parts/success-s3-review.md` (`tools/success_review_sheet.py`,
every source a checkbox).

## What a child sees and does

**The Life map's Money and business** (My Money Stall's area) now has, on each track, My Business's shop unit and the
Market Square's unit beside the stall's, the School's own lessons that fit (grade 3's Money and change; grade 4's
Farming, trade and the first money and grade 5's Trade around the world; grade 8's Chance, gambling and spending), and
two places as cards among them: **MY SHOP** and **THE PRICE BOARD**. Each unit has LESSON, PRACTICE and TRY IT in Life's
way: the before-check the first time, the practice room (Professor Hoot's words read aloud on Little, SHOW ME and I NEED
A BREAK always, the one next thing glowing, the coach after 10 s), the name-it card with its source, the after-check,
the Passport's stamps (EXPERT TRY once done alone), the honest before-and-after and Try it for real. In the world, both
open from the **Market Square**, a second plaza beside Life Town.

### My Business: the shop (Experience `my_shop`, ShopRoom)

Customers are the Connections Book's people (Lina, Mr Okafor, Grandpa Kenji, Omar, Rosa, Gemma, Ivan, Mei, Tomas and
Mo), each with a wish in their own words, coming in smiling, a little shy or after a long day; they come while the child
is there, one by one. Every coin is a pretend market coin.
- **Little, my stand (Little keeps the stand; 16 steps):** pick the sign that tells the truth (BREAD AND CAKES, not a
  blank one or TOYS) → put the bread and the cake out → a customer comes: "Hello! What would you like?" (not "Buy my
  cake!") → their wish in their words → give the right thing (a picture, then take it from the stand) → a fair price
  for something that cost 1 coin (2, not 20 or 0) → their 2 coins into the cash box, coin by coin → give it, say thank you
  (5 stars) → Mo pays 3-5 for 2-coin bread: his change coin by coin → his bread → keep 2 coins in the FLOUR jar for
  tomorrow → how many coins are left for you (the profit). Expert: a customer asks for pies: "Sorry, no pies. Would you
  like bread or a cake?" (not a cake called a pie), and nothing glows.
- **Middle, my shop (the bakery; 20 steps):** a clear, honest sign (FRESH BREAD, CAKES AND HONEY BUNS, not THE BEST
  BAKERY IN THE WHOLE WORLD! or SHOP) → the fair price: a loaf costs 2 (flour 1, butter and salt 1): 3, the cost and a
  little profit (6: nobody buys; 2: no money left for more flour); cakes 4 and honey buns 2 the same way → the first
  customer: ask first → their wish → take it from the shelf → they pay with a 10: the change coin by coin at the till →
  thank them (a review on the board) → an unsure customer: "What is it for?" ("for my friends, 6, 8 or 10 coins") → how
  many honey buns → their coins into the till → the bake corner: weigh 300-500 g of flour on the scales (it cost 3: money
  out) → the oven (Bobo takes the tray out with oven gloves) → Mo comes back cross (his bread got squashed, was too hard,
  or was the wrong one): listen and say it back (not "it was fine when it left", not walking away) → sorry, and a fresh
  loaf → pay Bobo a fair wage, 3 → the ledger: money in, money out (flour and wage), the profit → the week's bars: which
  day made the most → read the review board → Pip-pop opens a bakery across the square: win customers back with better
  bread and kinder service (pretend 5-star reviews: "Fake reviews are lies ... real shops are not allowed to use them";
  "Pip-pop's bread is bad": "unfair and unkind. Win with quality, never with tricks."). Expert: the flour costs more (a
  loaf costs 3: the fair price 4, not 3 or 8), a second customer waits ("Hello! I'll be with you in a moment."), no glows.
- **Big, the shop's harder days (17 steps; Expert 18):** the flour goes up 1 or 2 a loaf: the new cost → the new fair
  price (not the old 3, nor 8-9) and say why → a rainy day: about half the usual 20 or 24 loaves (not "twice as many,
  just in case") → Mr Okafor orders 8-12 honey buns for the library's party on Saturday: the total → weigh the honey on
  the scales (it cost 4) → Saturday: hand him his order ("Just as you promised!") → a customer buys 2 loaves at the new
  price with a 20 note: the change → Bobo worked 2-4 hours at 3 an hour: his wage, then pay it → the ledger's week: one
  bar under the line, the rainy day when too much was baked → Pip-pop sells at 1 coin, below her cost: keep a fair price
  and your quality (not half a coin, not "her bread is stale") → a review "Not a nice bakery" from someone who never came
  in: reply kindly and honestly (not ten pretend reviews, not a rude reply) → save half of a month's profit for a
  120-coin oven: how many months → the school's fair asks for help (give buns, teach a class, save a little first: any
  answer is kind) → "For real money, talk to a grown-up you trust." Expert: the honey comes a day late: tell Mr Okafor
  early and agree a new plan (not silence, not leaving the honey out), and nothing glows.

### The Market Square (Experience `market_square`, MarketSquareRoom)

The buddy merchants are the Connections Book's people: Tomas's flour, Ana's apples and wheat, Kenji's honey, Amara's
cakes; the big PRICE BOARD at the back has a row for each good: its name, today's price, an arrow (UP, DOWN) and why it
moved. Every price is in pretend coins; the dice lesson's counters are pretend too.
- **Little, the swap stall (11 steps; Expert 12):** why swap (so you both have apples and pears) → Lina offers 2 or 3
  pears for as many apples: put them on the swap table → is it fair (yes: the same for both) → shake hands (a promise)
  → take your pears → Mo offers 1 sticker for ALL your apples: "No, thank you. 1 apple for 1 sticker?" → Rosa's little
  jar for one of your drawings, both happy: fair → thank Lina (she wants to swap again). Expert: Lina asks for 2 more
  after the handshake: "We agreed: that's our swap", kindly.
- **Middle, supply and demand (16 steps):** read the Price Board (wheat 2, flour 4, apples 3, honey 5, cakes 4) → watch a
  dry summer (the wheat field grows short and brown) → wheat goes up (to 4: less supply) → the festival's bunting: cakes
  go up (to 6: more demand) → four more apple carts: apples go down (to 2: more supply) → find apples on the board and
  read why → go to Tomas: pay for 1 or 2 sacks of flour → haggle politely with Ana ("Could you do 10 for all 4?", not
  "That's a rip-off!" nor "for nothing") → shake on it → specialise: you bake 10 loaves or pick 4 bags, Ana picks 10 bags
  or bakes 2 loaves: half of each makes 6 loaves and 7 bags, doing your best things 10 and 10, and 4 for 4 leaves you
  both with more → sell a festival cake: change from 10 → autumn's harvest: wheat goes down again (to 1). Expert: the
  festival and many cake sellers on one day: the price changes less (the two pull opposite ways).
- **Big, trading honestly, and why gambling loses (16 steps; Expert 17):** read the apples on the board at the harvest
  (2; in winter usually 5) → an honest plan: buy some now, store them well, sell in winter at a fair price (not old
  apples sold as fresh, nor buying every apple so nobody else can) → keep a stock: a 20-bag shed, apples keep 3 months,
  4-6 sell a month: buy 12-18 (not fill the shed) → carry them in → winter: sell 2 or 3 bags, change from a 20 → spread
  across three baskets (wheat, apples, honey) → a storm flattens the wheat: apples and honey still sell → **the dice
  lesson** (pretend counters only, "Nobody bets anything"): Pip-pop's pretend game "pay 1 counter, throw a 6 and get 4
  back" → throw the dice 6 times and count the sixes (the try's own throws) → how often a 6 comes (about once in 6) →
  watch 600 throws drawn as a chart (the line ends about 200 down) → why: "A 6 pays 4, but it takes about 6 throws to get
  one" (not "bad luck: it will turn", not "throwing faster") → which one is gambling (paying for a chance to win a prize;
  not selling apples you bought, not saving) → "For real money, talk to a grown-up you trust." Expert: a game that pays
  5 for a 6: 60 throws, about 50 back: about 10 lost.

### MY SHOP and THE PRICE BOARD (the places)

- **MY SHOP** (`MyShopPage`): the shop's sign (CHANGE SIGN: six names from pictures, never typed: THE SUNNY BAKERY, THE
  GOLDEN LOAF, BREAD AND SMILES, THE HONEY OVEN, THE CORNER BAKERY, THE ROCKET BAKERY), the reviews (the stars on average
  and the last three in their words), **the ledger in pictures**: the last seven days' profit as bars (a loss under the
  line in red), this week's money in, money out and profit, and the shop's days, customers and complaints fixed in all
  (pretend coins); "Your shop's gold today: 15 of 50"; and **OPEN MY SHOP**, a shop day in the practice room (the shop's
  try on the child's track). Read aloud on Little, a speaker on every page.
- **THE PRICE BOARD** (`PriceBoardPage`): today's market day (the School's day): its season and picture, every good's
  price with its arrow and the reason in words and a picture ("A dry summer: less wheat grew, so wheat and flour cost
  more."), what the next season brings and in how many days, and TRY IT AT THE MARKET. The same day always shows the
  same board; nothing to buy there.

### The Market Square in the world

Beside Life Town (Life Town is full after L3c's third row): a second plaza with the **bakery** (cream walls, a red and
white striped awning, a big window with loaves, MY SHOP over the door) and **the market** (three little stalls with their
goods, and the Price Board on its legs with its rows and arrows; THE MARKET SQUARE). Walking up to one opens Life on its
unit on the child's track, like the town's places; walking up to one never opens another.

### Flat and VR

Flat: a finger on a thing does it (a coin on the tray, a good on the shelf, a customer, the scales held to spoon on, a
Price Board row), the picture answers on the bottom bar. VR: the child stands behind the counter (and turns round to the
bake corner, to the review board on the left wall and the ledger on the right: a blink each time); **the till's coins in
the hand** (a hand squeezing a coin on the tray gives it; the tray moves to Tomas's counter to pay him), **the scales**
by the hand at them, **the goods on the shelf** by the hand or the laser (the honey buns are a lean away), **the Price
Board to read** by the laser (its rows are targets of their own, 15 cm, the words billboards), the handshakes with Lina
and Ana (the hand squeezing at the spot), the dice tapped by the hand. Everything to touch is within a child's reach of
its spot (Life's room tests).

### The grown-ups' Life page

"My Business and the market": "My Business: ran their shop on 3 days: 9 customers served, 21 coins profit (pretend
market coins), 1 complaint listened to and fixed. The shop earned 45 game gold for Survivor in all (5 a customer, at most
50 a day, only while playing)."; "The Market Square: practised trading at the Market Square 2 times (pretend market
coins); read the Price Board (prices that move for reasons) on 3 days; did the dice lesson: why a game of chance loses
over time (pretend counters only, never a bet)."; and what the shop and the market use (pretend coins and counters, the
game's own gold only for customers served while playing, no real money anywhere).

## How much gold the shop pays, and why

**5 gold for each customer served in a try, at most 50 a day**, into the account's Survivor gold through the game's own
award path (`EarnRules.credit`: the wallet sync takes it to the server, whose limits are 2,000 an award and 20,000 an
hour in Green Meadows), on top of Life's 100 once per skill and track (the Passport's, like every Life skill). A customer
served is a sale finished or a complaint fixed (a step's `"shop"`); only the steps done count: a try stopped for now pays
the customers already served, and nothing is ever paid for time or while away (customers come only in the practice
room). Why: 5 is what a School answer right the first time pays (`EarnRules.ANSWER_GOLD`): a customer served kindly at a
fair price is the same kind of learning by doing; 50 is a third of the School's 150 a day (about two shop days), so
learning stays the main way to earn and a child can't farm the shop (a day of learning is about 275; the Moon rocket
about 470: the shop alone takes ten days). The market pays nothing of its own (ruling 5).

## How it is built

- **Rules (`core/success/`):** `SuccessShop` (`data/success/shop.json`: the goods' costs and fair prices, the customers'
  wishes, moods, signs, review words, the rival; `vars` per track and seed; `day_from` a try's steps and log; the ledger
  `record`, `week`, `totals`, `reviews`, `stars`; the gold `pay`, `gold_left`), `SuccessMarket` (`data/success/market.json`:
  the goods, the seasons and days that move prices; `board(day)`, `board_words`, `specialise`, `dice_run`,
  `loss_per_throw`, `vars`), `MarketPlaza` (the second plaza's layout and search), `SuccessData` (`shop`, `market`:
  parsed field by field, merged without losing a day; it holds the shop's limits itself), `SuccessExperiences` (the two
  ids and rooms; their `vars`).
- **Rooms (`entities/success/`):** `ShopRoom`, `MarketSquareRoom`, `SuccessTill` (the coin tray and the piles where coins
  go), `MarketPlazaPlacer` (the plaza in the world), `MarketPlazaBuildings` (its models). Only LifeRoomKit's warmed
  shaders; no shadows of their own; 66-213 meshes a room.
- **Places (`ui/success/`):** `MyShopPage`, `ShopWeekBars`, `PriceBoardPage`, `SuccessIconsMarket` (31 pictures);
  `SuccessPlaces` (the money area's two cards: `AREA_PLACES`; the pages; `after_try`; the grown-ups' section),
  `SuccessPage.try_it`.
- **Data:** `data/success/experiences/my_shop.json`, `market_square.json` (Life's format); `data/success/units/`
  (`my_stand`, `my_shop`, `shop_hard_days`, `swap_stall`, `supply_demand`, `trade_honestly`: the School's bar, 10-11
  exercises on three levels); `data/success/shop.json`, `market.json`.
- **The hooks outside Success** (each marked "owner #115 (S3)"):
  - `core/life/life_experience.gd:31`: the two ids in `LifeExperience.IDS`.
  - `core/life/life_town.gd:102-115` (`TOWN_GAP`, `PLAZA_SIGHT_GAP`, `town_layout`, `_lay`), `:123` (`pick`'s `layout`
    and `town`; the town's own search unchanged), `:153` (`_pick_near`), `:225` (`on_plaza`), `:306-321`
    (`to_save`/`from_save` carry `site.market`), `:346`, `:353`, `:395` (`_try`'s gaps and the town's plaza); and the
    layout parameter on `door_position`, `near`, `experience_at`, `natural_box`, `natural`, `clear_changes`.
  - `entities/life/life_town_director.gd:15, 42, 58, 78, 128-155, 258`: the placer made once the town stands, its save
    with the town's, walking up to its places.
  - `ui/life/life_screen.gd:630` (a finished try: the ledger and the shop's gold, `record.shop_gold`), `:671` (STOP FOR
    NOW: the customers served pay), `:736` (the result's `ShopGold` line), `:848` (a place's `try_it`).
  - `data/life/life.json:143-165`: the six units and four School links (new entries).
  - `data/tools/tools.json:1183-1250`: the Tool Book's `ledger` and `price_board` (new entries).
  - Tests: `tests/unit/test_life_experience.gd:38` (the IDS list), `tests/unit/test_life_town.gd:44` (every Experience
    has its place: the Market Square's two count).
  - Tools: `tools/life_smoke_steps.gd:575` (the shop's gold in the gold check), `tools/life_town_smoke_steps.gd:17, 78,
    155` (the Market Square in a real world).

## Rulings (decided, with what each costs if wrong)

1. **Two Life Experiences** (`my_shop`, `market_square`) in Life's framework, their data in `data/success`, their rooms in
   `entities/success`; Life reached only through the hooks above. *Cost:* a Life agent editing the IDS line merges one
   line.
2. **A shop day is a try**: the practice room's guided day with customers made from the try's seed; MY SHOP's OPEN MY
   SHOP starts it; nothing runs by itself. *Cost:* no free-running shop beyond the guided steps (a sandbox shop later).
3. **The gold**: 5 a customer served, at most 50 a day, through `EarnRules.credit`, paid at the try's end or at STOP FOR
   NOW for the steps done (above). No `EarnRules.TABLE` row (core/economy is not mine). *Cost:* the numbers; the Gold
   Shop's "How to earn" list doesn't name the shop yet: one row for the lead (`{"id": "shop", "gold": 5, "when": "A
   customer served in My Business's shop", "limit": "up to 50 a day", "by": "game"}`).
4. **Pretend market coins** inside the shop and the market (My Money Stall's ruling); the real gold is the game's,
   separate, and the result page says it in its own line. *Cost:* two kinds of money on one page (the words say which).
5. **The Market Square pays no gold of its own** (Life's 100 once per track only): trading game gold on moving prices
   could be farmed or feel like speculation. *Cost:* less pull for the market.
6. **Reviews are honest and kind**: 5 stars, or 4 with "Lovely! Next time it will be even quicker." when the coach helped
   with that sale; never fewer, never harsh. *Cost:* a child never meets a low review (Big's unfair review is the one,
   and it is answered kindly).
7. **Little keeps the stand**: the shop's Little track is the stand grown a sign, a customer's wish, a fair price,
   change and money kept for flour; no bakery, ledger board or rival. *Cost:* Little sees no ledger (the jar is its
   picture).
8. **The shop's place is the Market Square beside Life Town** (and Life's map), not the child's own world build. *Cost:*
   the child can't put the shop in their own build.
9. **The goods are given** ("bread from the farm's wheat"), not taken from a world's bag (L1's ruling 11). *Cost:* no link
   to the real farm.
10. **Customers are the Connections Book's people**; serving one meets them in the book, fixing Mo's complaint helps him.
    *Cost:* their warmth rises from shop tries too (at most 2 a try, as ever).
11. **Tricks are wrong pictures with the coach's why** (fake reviews, untrue words, a too-big claim), never the answer and
    never a safe mistake (no frozen picture of trust lost). *Cost:* the why is words only.
12. **The room's week of bars is the try's own** (seeded); MY SHOP's is the child's own shop days. *Cost:* the room's bars
    aren't the child's.
13. **Market days are the School's days**; a season is 7 market days (a year 28); the festival every 14th day and many
    sellers every 7th; a price is the usual one plus each cause's effect, at least 1. Deterministic: every child sees the
    same board on the same day. *Cost:* a simple additive model; real markets are subtler.
14. **The dice lesson** is the Big track's, with pretend counters only: the child throws 6 (the try's seeded faces), then
    600 throws are drawn (seeded); "bet" is never offered; gambling is named so it can be taught. *Cost:* 6 throws can
    show many sixes (the chart and the averages carry the lesson).
15. **Specialising** is one worked example (10 loaves or 4 bags; 10 bags or 2 loaves). *Cost:* one example.
16. **Money and business keeps My Money Stall's area**; the new units go there; its two places are cards among the units
    (two rows of units leave no room for a row under them in the School's frame). *Cost:* a different place style from
    S2's areas.
17. **The School links**: grade 3's Money and change, grade 4's Farming, trade and the first money, grade 5's Trade around
    the world, grade 8's Chance, gambling and spending. *Cost:* data.
18. **The Tool Book**: the ledger and the price board are new; the till and the scales were there (each Experience
    describes its own device model). *Cost:* none known.
19. **The second plaza by Life Town's own search**: `LifeTown.pick` takes a layout and the town; the town's own search
    unchanged (6 of 8 real meadows, measured); for the plaza the rings' cells nearest the town first, each with every
    tier (a near site with trees to clear beats a far clear one); off the town's plaza by CLEAR, at least `TOWN_GAP` 30
    degrees round from it (beside, never behind), at least `PLAZA_SIGHT_GAP` 20 degrees from the Theater and the Launch
    Site (with the town's 28, two of six towns had no room beside them and it went across the spawn, 70-74 m away).
    *Cost:* from the spawn the low stalls can stand a little nearer, round, to the Theater or the Launch Site than the
    town may (their CLEAR blocks unchanged).
20. **Saved with the town**: `WorldMeta.life_town` holds the town's four numbers then the Market Square's
    (`LifeTown.to_save`/`from_save`; WorldMeta's own line round-trips both); a world saved before S3 searches it and checks
    its ground on the next play (a child's build there moves it). *Cost:* an older build of the game reading a new save
    keeps only the town.
21. **A LAN guest stands it from the seed** (as the town). *Cost:* if the host moved it (a build), the guest's may differ.
22. **Not on MY MAP yet** (`scenes/sandbox.gd`'s `_mark_life_town` is not mine). *Cost:* one line for the lead.
23. **MY SHOP's class is `MyShopPage`**: the grown-ups' SHOP page owns `ShopPage`; the first name made MY SHOP fail to load
    by the class cache's order. `test_no_class_name_is_used_twice` now guards the whole game. *Cost:* none.
24. **SuccessData keeps the shop's limits** and never calls the rules (a compile cycle through the profile's autoload);
    `GOLD_PER_CUSTOMER` is written as 5 (a constant made from `EarnRules.ANSWER_GOLD` can't be evaluated in that cycle;
    a test holds them equal). *Cost:* none.
25. **Facts checked with web searches this session** (reading only, nothing saved), as S2 did. *Cost:* if the lead meant
    no network at all, the searches went beyond it.
26. **S2's sheet regenerated**: L3c's device hook in the Goal Board's data had left it out of date. *Cost:* none.
27. **VR**: the goods are pressed by the hand or the laser (`reach` any: the honey buns are 1.14 m from the eye), the Price
    Board's rows by the laser (point steps); the board's own target is its title, so a laser on a row never hits the whole
    board first (the smoke found it). *Cost:* goods aren't hand-only.
28. **Price tags** show the price the step taught (the usual ones; Big's new bread price; the Middle Expert try's dearer
    loaf, 4: its own event `prices_up_dear`). *Cost:* none known.
29. **Owner #122 (learning is play, 18:49 the same day) came after the brief**: the shop and the market are Experiences
    played in rooms with the hands (a sale is coins given, flour weighed, a good handed over; the market's causes happen
    in front of the child); their six units keep the School's format that the catalogue still holds Life's units to
    (cards and exercises) and move to G0's generic mechanics with the rest. *Cost:* those cards and quizzes until G0.

## The facts and their sources

Every step's words, picture answers, whys and sources are in `docs/devlog/parts/success-s3-review.md` (each source a
checkbox for the expert's review before it ships). The authorities:
- **Money and enterprise:** the OECD/INFE Core Competencies Framework on Financial Literacy for Youth (2015)
  (https://microfinancegateway.org/paper/2015/09/core-competencies-framework-financial-literacy-youth); the EU and OECD
  Financial competence framework for children and youth (2023)
  (https://search.oecd.org/daf/fin/financial-education/Financial-competence-framework-youth-EU.pdf); EntreComp (2016)
  (https://publications.jrc.ec.europa.eu/repository/handle/JRC101581).
- **Economics:** the Council for Economic Education's Voluntary National Content Standards in Economics (2010), standards
  5 (voluntary exchange: both sides expect to gain), 6 (specialising and trading increases production and consumption),
  7 and 8 (markets set prices; when supply or demand changes, prices adjust)
  (https://www.councilforeconed.org/wp-content/uploads/2012/03/voluntary-national-content-standards-2010.pdf); the Bank of
  England's teaching resource Economics in practice
  (https://www.bankofengland.co.uk/-/media/boe/files/education/economics-in-practice.pdf).
- **Consumers:** the Competition and Markets Authority's fake reviews guidance (CMA208, 4 April 2025; fake reviews,
  positive or negative, banned under the Digital Markets, Competition and Consumers Act from 6 April 2025)
  (https://www.gov.uk/government/publications/fake-reviews-cma208); complaints the CASEL way (relationship skills)
  (https://casel.org/fundamentals-of-sel/what-is-the-casel-framework/); polite, interest-based deals: the Program on
  Negotiation, Harvard Law School (https://www.pon.harvard.edu/tag/batna/).
- **Chance and gambling:** NRICH (University of Cambridge), What Do You Know About Probability? (2): a fair dice's six
  equally likely faces (https://nrich.maths.org/12151); GamCare, Giving young people the facts about gambling
  (https://gamcare.org.uk/news-and-blog/blog/giving-young-people-the-facts-about-gambling); Zendle and Cairns (2018), loot
  box spending linked to problem gambling (https://pmc.ncbi.nlm.nih.gov/articles/PMC6599795). The dice lesson's numbers
  are the game's own arithmetic: a throw costs 1 and a 6 (one in six) pays 4, so a throw loses 1/3 of a counter on
  average; 600 throws about 200.
- **Checked in this session** (web searches, nothing saved): the CMA208 page and its dates; the FTC's 2024 rule (secondary
  write-ups only: not cited); the Council for Economic Education's standards 5-8 wording; NRICH's probability activity;
  GamCare's page; the Bank of England's teaching PDF exists (its content for the expert to confirm). **Not re-fetched:**
  the OECD/INFE, EU/OECD and EntreComp pages (L1's and S2's), CASEL's and the Program on Negotiation's (S2's).

## Tests and measurements

- **Unit:** `test_success_shop.gd` (16: the goods' fair prices, a price too high or too low and why, the customers from
  the book, every track's values add up for 40 seeds, they vary, a try's day from its steps (only the steps done), kind
  honest reviews, the ledger's week, the gold per customer and the day's cap (and a clock turned back), its words, the
  grown-ups' line, the reviews kept, the profile and backup round trip, bad fields, the merge never losing a day),
  `test_success_market.gd` (9: sellers and pictures, seasons in days, every moved price has its cause, supply and demand
  the right way, specialising makes both richer, the dice game always loses over 600 throws for 30 seeds (about 200 on
  average), every track's values, the board's words and the grown-ups' line), `test_success_s3_experiences.gd` (12: Life
  Experiences with their rooms and units, Little keeps the stand, every part the brief names in the shop and in the
  market, never gambling but the lesson (pretend counters, never gold, never an offer to bet), no real money and no
  pressure tricks, honesty always the answer and a trick never, the customers and merchants are the book's people, every
  device in the Tool Book (the till, the scales, the ledger, the price board), a shop try serves customers on every
  track, each try varies, no class name used twice in the game, every fact's source), `test_success_s3_plaza.gd` (6).
- **Integration:** `test_success_s3_rooms.gd` (12: the customer and the change, a good held out then given and a review,
  the ledger's bars and the loss under the line, the price tags follow the price taught, the scales' grams and the rival, the Price Board's causes, its targets
  never overlap, the tray to Tomas, the try's own dice and the falling chart, winter and the storm, the swap stall, the
  mesh budget), `test_success_s3_places.gd` (9: the money area's cards on every track and the fit, MY SHOP and its sign,
  OPEN MY SHOP, a finished day fills the ledger and pays 100 + 15, a stopped try pays only the customer served, the
  day's cap, THE PRICE BOARD's rows and a reading once a day, the dice lesson marked, the grown-ups' page),
  `test_success_s3_town.gd` (5: saved, the host's check and clearing and the save, a child's build moves it, a guest,
  walking up to each). Life's own tests cover both Experiences too (every step's targets and views, everything to tap in
  the screen's free band, everything to touch within reach in VR, warmed shaders only, no shadows, the automatic player
  on every track and try with no hint, every picture known, kind British words, nothing typed).
- **Meshes per room** (Little / Middle / Big): the shop 66 / 135 / 170, the Market Square 78 / 145 / 213 (the budget 320).
- **The plaza on the real meadows** (`test_real_meadows_keep_their_town_and_get_their_market_square`, the eight seeds
  Life Town is measured on): Life Town keeps its **6 of 8**; **6 of 6** towns get their Market Square, **26-34 m** from
  the town's middle, the slowest search **19 ms** (on a worker). Life Town's own test still prints 6 of 8, 111 ms.
- **The Life smoke** (`tools/life_smoke.gd --only=my_shop,market_square`, 5x time, the real screen, room and host):
  **18 of 18** (every track flat, Expert and VR; 2.6-7.4 s each; the shop's gold checked). Its first run failed 11: the
  smoke's gold check didn't know the shop's gold (9) and the laser on a Price Board row hit the whole board first (2):
  both fixed, the second test-first.
- **The Life Town smoke** (`tools/life_town_smoke.gd`, a new Green Meadows world): the town stood after 5.2 s; **the Market
  Square stood 29 m from the town's middle**, the save kept it with the town, its two places with signs; all twenty
  town places and the bakery and the stalls opened their Experiences; the kitchen's room 186 frames, average 32.4 ms,
  worst 95.3 ms (headless on this shared desktop); fails 0.
- **Life's, Success's and the Tools' tests** (81 scripts, before the merge): 792 of 792 passed.
- **The full suite** (2026-10-17, after merging `lead-merge` at `c9aff724` (owner #122's design and the read-aloud fix; no
  conflicts) into the branch at `1cca068f`, one run in a PC-wide slot): 1,248 scripts, 11,576 tests: **11,573 passed, 0
  failed**, 3 risky or pending (the same three as before: `test_the_column_cache_changes_nothing` and
  `test_chunks_meet_without_seams` "did not assert", and the device move's pending by design), 4,947 s. `lead-merge`
  then gained grade 7's and grade 8's core units (to `52b29eba`), merged at `d613d2be` with no conflicts: the catalogue,
  Life's experience, room, screen and town tests, every Success test and the School's grade 7 and 8 content tests (23
  scripts) passed 306 of 306 on it.

## What the lead must check (I could not: no editor, no emulator, no headset)

On the emulator (`Pixel_8_API_35`), flat:
- Money and business on each track: two rows of five cards (220 px wide, 18 px words), MY SHOP's and THE PRICE BOARD's
  pictures on their cards; the units' titles at the real font.
- MY SHOP's two panels (the sign and the reviews; the ledger's week bars and their day letters drawn with the fallback
  font), the sign picker's six cards; THE PRICE BOARD's five rows (the why words at 17 px).
- The shop: the counter's tray coins, the goods on the little shelf, the till's count, Bobo, the review board and the
  ledger board's words (billboards at 0.0016-0.004 a pixel: the week's day letters are the smallest), Pip-pop's bakery
  across the square; the bake corner (the scales' grams). The market: the Price Board's rows, UP/DOWN and why (0.0025-
  0.0045), the stalls and merchants, the wheat field drying, the bunting, the shed, the baskets, the dice and its face,
  the chart's points. **FPS >= 30, no frame over 100 ms** in each (213 meshes at most).
- Life Town in a new world: the Market Square beside the town, its two models and signs; in a world saved before S3: it
  appears on the next play (searched and checked); MY MAP doesn't mark it yet (ruling 22).
On the Quest 3:
- The coins in the hand at the till (a squeeze on a 3-4 cm coin), the tray moving to Tomas's counter; the scales by hand;
  the goods on the shelf (the honey buns a lean, 1.14 m); turning round to the bake corner and to the side walls' boards
  (the blinks, the facing); the review and ledger words at 2.4 m; the Price Board read and its rows pressed by laser at
  3.5 m (15 cm targets); the handshakes with Lina and Ana; the dice by hand; 72 Hz in the market (213 meshes).

## Next

S4 (the design §5): Team Projects, the Big track's company (a supply chain, a loan, investors, cash flow), shares and
dividends in buddy businesses (patient owning, never gambling), trading with approved friends online (the server's
part: the owner's go). For the lead: the EarnRules row (ruling 3), MY MAP's mark (ruling 22), the experts' review of
`success-s3-review.md` (a financial or enterprise educator, a consumer body's adviser, an economics teacher, a
gambling-harm educator).
