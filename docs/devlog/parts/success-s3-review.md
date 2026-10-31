# Success S3: the review sheet for the experts (owner #115)

Written by `tools/success_review_sheet.py` from the game's own data (`data/success/`): exactly what the game shows and reads aloud. Please tick each source once checked and mark each line: right / change it to ... / remove it. The coins are pretend market coins (never real money); the counters of the dice lesson are pretend too; fake reviews, untrue words and too-big claims appear only as wrong pictures, each with the coach's why. Each hands-on step names its real motion (owner #117).

The values that change with each try are shown as {tokens}:

- `{one_name}, {one_mood}, {one_wish}`: the first customer: one of the Connections Book's people (Lina, Mr Okafor, Grandpa Kenji, Omar, Rosa, Gemma, Ivan, Mei, Tomas), how they come in (smiling, a little shy, after a long day) and their wish (data/success/shop.json's customers)
- `{one_good_word}, {one_good_one}, {one_what}, {one_other_*}`: what the first customer wants (bread, a cake or honey buns) and the other goods offered as the wrong pictures
- `{two_name}, {two_budget}, {two_count}`: the second customer (Middle: unsure; buys honey buns for friends with 6, 8 or 10 coins: 3, 4 or 5 buns); on Little the second customer is always Mo
- `{price}, {cost}, {two_paid}, {two_change}, {money_in}, {flour_out}, {left}`: Little: 2 coins for anything that cost 1; Mo pays 3-5 for bread (change 1-3); 4 coins in, 2 kept for flour, 2 left
- `{one_total}, {one_change}, {flour_g}, {flour_cost}, {wage}, {money_out}, {profit}`: Middle: the first sale (2-8 coins, paid with a 10), 300-500 g of flour costing 3, Bobo's wage 3, profit = money in - money out (2-12)
- `{best_day}, {day_wrong_*}, {loss_day}`: the ledger's week of bars: the tallest bar's day; on Big one rainy day (Tuesday or Wednesday) under the line
- `{old_cost}, {flour_up}, {new_cost}, {new_price}, {greedy_price}`: Big: a loaf cost 2; flour up by 1 or 2; the new cost 3-4; the fair new price 4-5; a greedy one 8-9
- `{normal_loaves}, {rain_loaves}, {order_n}, {order_total}, {honey_g}, {hours}, {rate}, {month_profit}, {save_part}, {oven}, {months}`: Big: 20 or 24 loaves (half on a rainy day); 8-12 honey buns at 2 each; 150-250 g of honey; 2-4 hours at 3 coins; 40-80 profit a month, half saved for a 120-coin oven (3-6 months)
- `{gripe}, {gripe_back}`: Mo's complaint (Talk & Deal's: squashed, too hard or the wrong bread) and saying it back
- `{swap_n}`: Little's market: 2 or 3 apples for as many pears
- `{wheat_base}, {wheat_dry}, {wheat_autumn}, {cake_base}, {cake_festival}, {apple_base}, {apple_many}, {apple_autumn}, {apple_winter}, {flour_price}, {honey_base}`: the Price Board: wheat 2 (4 after a dry summer, 1 at the harvest), cakes 4 (6 at the festival), apples 3 (2 with many sellers or at the harvest, 5 in winter), flour 4, honey 5
- `{flour_words}, {flour_total}, {haggle_bags}, {haggle_full}, {haggle_ask}, {cake_change}`: Middle: 1 or 2 sacks of flour; 4 or 5 bags of apples (12 or 15 coins) and the polite ask 2 less; the festival cake's change from 10
- `{sp_*}`: specialising: you bake 10 loaves or pick 4 bags; Ana picks 10 bags or bakes 2 loaves; half of each makes 6 loaves and 7 bags together; each doing their best makes 10 and 10; swapping 4 for 4 leaves both with more
- `{shed}, {per_month}, {stock}, {sale_bags}, {sale_change}`: Big: a 20-bag shed; 4-6 bags sold a month for 3 months (12-18 bought); 2 or 3 winter bags paid with a 20
- `{dice_pays}, {dice_sixes}, {chart_lost}, {expert_*}`: the dice lesson with pretend counters: pay 1 a throw, a 6 gives 4 back; 6 throws by the child; the chart of 600 throws ends about 200 down (the try's own seed); the Expert try's game pays 5 for a 6: 60 throws, about 50 back, about 10 lost

## My Business: the Shop

For the review by a financial educator or an enterprise educator (prices, profit, the ledger, wages), with a consumer body's adviser (fake reviews, complaints).

The device **till**: controls: the cash drawer; the coin tray. It shows: the price; the change to give. The right order: say the price → take the money into the till → give change coin by coin → say thank you. Safety: count the change twice; pretend coins only: real money with a grown-up.
The device **scales**: controls: the zero button. It shows: the grams. The right order: bowl on, press zero → spoon the flour on slowly → stop at the amount. Safety: spoon slowly near the amount; read the number at eye level.
The device **ledger**: controls: the money-in column; the money-out column; the profit line. It shows: money in, money out and profit; the week's bars. The right order: write each sale in → write each cost out → money in take away money out is the profit → look at the week's bars. Safety: write it down straight away, so nothing is forgotten; check the sums twice.

### Little (about 6-8): My stand: what customers want

The Expert try's twist: A customer asks for something you don't sell, and nothing glows to help.

Steps:

- **hello**: words, then OK
  - Coach: "Your very own stand! You sell bread and cakes made from the farm's wheat. These are pretend coins."
- **sign**: pick a picture
  - Coach: "Every stand needs a sign. Which sign tells people what you sell?"
  - Picture (shop_sign) right: "BREAD AND CAKES"
  - Picture (blank_sign) not this one: "A blank sign": "A blank sign tells nobody what you sell."
  - Picture (toy) not this one: "TOYS": "You don't sell toys! A sign should tell the truth."
  - After: "Now everyone knows what you sell."
- **set_out**: find them `good_bread, good_cake` (motion press)
  - Coach: "Put your bread and your cake out on the stand."
  - Found `good_bread`: "Fresh bread!"
  - Found `good_cake`: "A yummy cake!"
  - After: "Ready for customers."
- **ask**: pick a picture
  - Coach: "{one_mood} What do you say?"
  - Picture (question_bubble) right: "Hello! What would you like?"
  - Picture (bossy) not this one: "Buy my cake!": "Ask first! Then you know what they want."
  - Picture (quiet) not this one: "Say nothing": "A hello and a question make customers feel welcome."
  - After: "Asking first is how you know what people want."
- **no_pies** (Expert try only): pick a picture
  - Coach: ""Do you have pies?" You only sell bread and cakes. What do you say?"
  - Picture (sorry) right: "Sorry, no pies. Would you like bread or a cake?"
  - Picture (fake_claim) not this one: "Yes! (and give a cake)": "Be honest about what you sell. Then offer what you have."
  - Picture (walk_away) not this one: "No. (and look away)": "Say sorry kindly, and offer what you do have."
  - After: "Honest and kind: "No pies, but I have bread and cakes!""
- **wish**: pick a picture
  - Coach: "{one_name} says: "{one_wish}" What will you give?"
  - Picture ({one_good_icon}) right: "{one_good_word}"
  - Picture ({one_other_icon}) not this one: "{one_other_word}": "Listen again: {one_name} asked for {one_good_one}."
  - After: "That's just what {one_name} wanted."
- **take** (normal try only): touch it `good_{one_good}` (motion press)
  - Coach: "Take {one_good_one} from your stand."
  - After: "Here you are!"
- **take** (Expert try only): touch it `good_{one_good}` (motion press, no glow)
  - Coach: "Take {one_good_one} from your stand."
  - After: "Here you are!"
- **price**: pick a picture
  - Coach: "It cost you {cost} coin to make. What is a fair price?"
  - Picture (coins) right: "{price} coins: the cost and a little more"
  - Picture (price_up) not this one: "20 coins": "So much that nobody could pay! A fair price is the cost and a little more."
  - Picture (cross) not this one: "0 coins": "Then you have no money to buy flour and make more."
  - After: "A fair price: good for {one_name}, and good for you."
- **pay_1**: give coins `box` (motion press, tool coins, sum {price})
  - Coach: "{one_name} pays {price} coins. Put them in your cash box, coin by coin."
  - After: "{price} coins in the cash box."
  - The Connections Book: {"meet": ["{one}"]}
  - The shop's ledger: {"sale": "{one}", "in": "{price}", "review": "asked"}
- **thanks**: touch it `customer` (motion press)
  - Coach: "Give it to {one_name}, and say thank you!"
  - After: ""Thank you!" {one_name} gives your stand 5 stars."
- **mo**: words, then OK
  - Coach: "Mo comes for bread. Bread is 2 coins. He gives you {two_paid} coins."
- **change**: give coins `hand` (motion press, tool coins, sum {two_change})
  - Coach: "Give Mo {two_change} coins change, coin by coin."
  - After: "2 and {two_change} make {two_paid}. The right change!"
  - The Connections Book: {"meet": ["mo"]}
  - The shop's ledger: {"sale": "mo", "in": 2, "review": "fresh"}
- **bread**: touch it `good_bread` (motion press)
  - Coach: "Give Mo his bread."
  - After: "Mo says: "Fresh bread and a big smile!""
- **flour**: give coins `flour_jar` (motion press, tool coins, sum {flour_out})
  - Coach: "Keep {flour_out} coins in the FLOUR jar, to buy flour for tomorrow."
  - After: "Money in, some money out for flour: that's how a stand keeps going."
  - The shop's ledger: {"out": "{flour_out}"}
- **left**: pick the number
  - Coach: "You took {money_in} coins and kept {flour_out} for flour. How many coins are left for you?"
  - Picture (coins) right: "{left}"
  - Picture (coins) not this one: "{money_in}": "Take away the flour money first."
  - Picture (cross) not this one: "0": "Count again: {money_in} take away {flour_out}."
  - After: "{left} coins: your profit!"
- **end**: words, then OK
  - Coach: "Wonderful! You asked what people wanted, gave the right things, gave change, and kept money for flour."

The before-and-after check (the right one first here; the game mixes their order):

- "A customer comes to your stand. What do you say first?" **Hello! What would you like?** / Buy this!
- "A cake cost 1 coin to make. A fair price?" **2 coins** / 20 coins / 0 coins
- "Why keep some coins after you sell?" **To buy flour and make more** / To hide them

The "name it" card: **My stand**

1. Ask: "What would you like?"
2. A fair price: the cost and a little more.
3. Give the right change, and say thank you.
4. Keep some money to make more.

Its source line: The OECD/INFE money skills for young people (2015) and EntreComp, the EU's enterprise skills (2016)

Try it for real: With a grown-up: help pay at a shop, and check the change together.

Your child can now: ask customers what they would like, set a fair price, count coins and change, and keep some money to make more

Sources:

- [ ] Earning, prices, paying and getting change, keeping money to spend later. (OECD/INFE Core Competencies Framework on Financial Literacy for Youth (2015)): https://microfinancegateway.org/paper/2015/09/core-competencies-framework-financial-literacy-youth
- [ ] Making something people want and selling it: spotting what others value (value for others). (EntreComp, the EU's Entrepreneurship Competence Framework (2016)): https://publications.jrc.ec.europa.eu/repository/handle/JRC101581
- [ ] Voluntary exchange: people buy when both sides expect to gain (a fair price). (Council for Economic Education, Voluntary National Content Standards in Economics (2010), standard 5): https://www.councilforeconed.org/wp-content/uploads/2012/03/voluntary-national-content-standards-2010.pdf

### Middle (about 9-11): My shop: customers, prices and reviews

The Expert try's twist: Flour costs more this week, a second customer waits while you serve, and nothing glows to help.

Steps:

- **hello**: words, then OK
  - Coach: "Your own bakery! Bread, cakes and honey buns from the farm's wheat. Customers come while you are here. These are pretend coins."
- **sign**: pick a picture
  - Coach: "Your shop needs a sign. Which one is clear and honest?"
  - Picture (shop_sign) right: "FRESH BREAD, CAKES AND HONEY BUNS"
  - Picture (fake_claim) not this one: "THE BEST BAKERY IN THE WHOLE WORLD!": "Can you show that's true? A sign should be clear and honest."
  - Picture (blank_sign) not this one: "SHOP": "It doesn't say what you sell."
  - After: "Clear and honest: customers know what you sell."
- **price** (normal try only): pick a picture
  - Coach: "A loaf costs you 2 coins to make: 1 for flour, 1 for butter and salt. Which price is fair?"
  - Picture (coins) right: "3 coins: the cost and a little profit"
  - Picture (price_up) not this one: "6 coins": "Too high: customers go somewhere else, and nobody buys."
  - Picture (price_down) not this one: "2 coins": "Too low: you make nothing, and there is no money left for more flour."
  - After: "Price = what it costs + a little profit. Cakes are 4 and honey buns 2, the same way."
- **price** (Expert try only): pick a picture
  - Coach: "Flour costs more this week: a loaf now costs you 3 coins to make. Which price is fair?"
  - Picture (coins) right: "4 coins: the cost and a little profit"
  - Picture (price_up) not this one: "8 coins": "Much more than the cost went up: customers notice and go elsewhere."
  - Picture (price_down) not this one: "3 coins": "That's only what it costs now: nothing for your work or more flour."
  - After: "When a cost goes up, a fair price goes up a little. Tell customers why."
- **ask**: pick a picture
  - Coach: "{one_mood} What do you say first?"
  - Picture (question_bubble) right: "Hello! What would you like?"
  - Picture (bossy) not this one: "You should buy a cake!": "Ask first: people buy what they want, not what you push."
  - Picture (quiet) not this one: "Wait for them to speak": "A friendly hello and a question help, most of all with a shy customer."
  - After: "Ask what people want: that's how a shop knows what to make."
- **wish**: pick a picture
  - Coach: "{one_name}: "{one_wish}" What will you get?"
  - Picture ({one_good_icon}) right: "{one_good_word}"
  - Picture ({one_other_a_icon}) not this one: "{one_other_a_word}": "Listen again: {one_name} asked for {one_good_one}."
  - Picture ({one_other_b_icon}) not this one: "{one_other_b_word}": "Listen again: {one_name} asked for {one_good_one}."
  - After: "Just what {one_name} wanted."
- **take** (normal try only): touch it `good_{one_good}` (motion press)
  - Coach: "Take {one_what} from the shelf."
  - After: "Here you are."
- **take** (Expert try only): touch it `good_{one_good}` (motion press, no glow)
  - Coach: "Take {one_what} from the shelf."
  - After: "Here you are."
- **wait** (Expert try only): pick a picture
  - Coach: "While you serve {one_name}, {two_name} comes in and waits. What do you say?"
  - Picture (please) right: "Hello! I'll be with you in a moment."
  - Picture (quiet) not this one: "Nothing: keep your eyes down": "A quick hello tells waiting customers you've seen them."
  - Picture (bossy) not this one: "Go away, I'm busy!": "Rude words send customers away for good."
  - After: "A kind word while they wait: customers feel seen."
- **change**: give coins `hand` (motion press, tool coins, device till, sum {one_change})
  - Coach: "{one_name} pays with a 10 coin for {one_total}. Give {one_change} coins change, coin by coin."
  - After: "{one_total} and {one_change} make 10."
  - The Connections Book: {"meet": ["{one}"]}
  - The shop's ledger: {"sale": "{one}", "in": "{one_total}", "review": "asked"}
- **thanks**: touch it `customer` (motion press)
  - Coach: "Give it to {one_name}, and say thank you."
  - After: "{one_name} leaves a review on your board: 5 stars!"
- **question**: pick a picture
  - Coach: "{two_name} comes in, but can't decide. What could you ask?"
  - Picture (question_bubble) right: "What is it for?"
  - Picture (price_up) not this one: "Just take the dearest one!": "Help people find what they need, not the dearest thing."
  - Picture (clock) not this one: "Be quick, please!": "Customers wait kindly here: there's no rush."
  - After: ""It's for my friends. I have {two_budget} coins.""
- **how_many**: pick the number
  - Coach: "Honey buns are 2 coins each. How many can {two_name} buy with {two_budget} coins?"
  - Picture (honey_bun) right: "{two_count}"
  - Picture (honey_bun) not this one: "{two_budget}": "Each bun is 2 coins: share {two_budget} into twos."
  - Picture (honey_bun) not this one: "{two_count_wrong}": "Count in twos up to {two_budget}."
  - After: "{two_count} honey buns, one for each friend."
- **pay_2**: give coins `till` (motion press, tool coins, device till, sum {two_budget})
  - Coach: "{two_name} pays {two_budget} coins. Put them in the till, coin by coin."
  - After: "In the till. {two_name} takes the honey buns home."
  - The Connections Book: {"meet": ["{two}"]}
  - The shop's ledger: {"sale": "{two}", "in": "{two_budget}", "review": "fair"}
- **weigh**: pour or weigh to the line `scales` (motion measure, tool spoon, device scales, want {flour_g}, full 1000, tol 25, unit g)
  - Coach: "Time to bake more! Weigh {flour_g} grams of flour on the scales."
  - After: "{flour_g} grams. That flour cost {flour_cost} coins: money out."
  - The shop's ledger: {"out": "{flour_cost}"}
- **bake**: the clock runs by itself (seconds 4.0, label Baking: 30 minutes)
  - Coach: "Into the oven! Bobo, your helper, takes the hot tray out with oven gloves."
  - After: "Fresh bread!"
- **listen**: pick a picture
  - Coach: "Mo comes back, a little cross: "My bread got squashed in my bag! (or: My loaf was too hard to cut! / You gave me the wrong bread!)" What do you do first?"
  - Picture (say_back) right: "Listen, and say it back"
  - Picture (talk_over) not this one: ""It was fine when it left here!"": "That's arguing. Listen first, then say sorry."
  - Picture (walk_away) not this one: "Walk away": "Stay and listen: a complaint is a chance to fix things."
  - After: ""Your bread got squashed. Oh no! (said back to match)" Mo nods: you listened."
- **fix**: touch it `good_bread` (motion press)
  - Coach: "Say sorry, and fix it: give Mo a fresh loaf."
  - After: ""Thank you for listening!" Mo smiles again."
  - The Connections Book: {"help": "mo"}
  - The shop's ledger: {"fixed": "mo"}
- **wage**: give coins `bobo` (motion press, tool coins, sum {wage})
  - Coach: "Bobo helped all afternoon. Pay him a fair wage: {wage} coins."
  - After: "Thank you, Bobo! Fair pay for fair work."
  - The shop's ledger: {"out": "{wage}"}
- **ledger**: pick the number (device ledger)
  - Coach: "Your ledger: money in {money_in}, money out {money_out} (flour {flour_cost}, Bobo's wage {wage}). What is your profit?"
  - Picture (ledger) right: "{profit}"
  - Picture (ledger) not this one: "{profit_wrong_a}": "Money out is taken away, not added."
  - Picture (ledger) not this one: "{profit_wrong_b}": "Don't forget the money that went out."
  - After: "{profit} coins profit: money in take away money out."
- **week**: pick a picture (device ledger)
  - Coach: "The ledger's bars show this week's profit, day by day. Which day made the most?"
  - Picture (bars) right: "{best_day}"
  - Picture (bars) not this one: "{day_wrong_a}": "Look for the tallest bar."
  - Picture (bars) not this one: "{day_wrong_b}": "Look for the tallest bar."
  - After: "{best_day}! The bars show which days are busy."
- **reviews**: aim at it `reviews` (motion aim)
  - Coach: "Read your review board: what do your customers say?"
  - After: "Honest reviews tell you what to keep, and what to make better."
- **rival**: pick a picture
  - Coach: "Across the square, Pip-pop opens a bakery, and some customers go there. How do you win them back?"
  - Picture (kind_service) right: "Better bread and kinder service"
  - Picture (fake_review) not this one: "Write pretend 5-star reviews of your shop": "Fake reviews are lies: customers stop trusting you, and real shops are not allowed to use them."
  - Picture (fib) not this one: "Say Pip-pop's bread is bad": "Saying untrue things about someone is unfair and unkind. Win with quality, never with tricks."
  - After: "Customers come back for good bread and a kind welcome."
- **end**: words, then OK
  - Coach: "A real shopkeeper! You asked, priced fairly, gave change, fixed a complaint, paid a fair wage and read your ledger. Honest wins."

The before-and-after check (the right one first here; the game mixes their order):

- "A loaf costs 2 coins to make. Which price makes a profit?" **3 coins** / 2 coins / 1 coin
- "Money in 12, money out 5. What is the profit?" **7** / 17 / 12
- "A customer complains. First you..." **Listen and say it back** / Argue / Walk away
- "A new shop opens nearby. How do you keep your customers?" **Better quality and service** / Fake reviews

The "name it" card: **Running a shop**

1. Ask customers what they want.
2. Price = what it costs + a little profit.
3. A complaint: listen, say sorry, fix it.
4. The ledger: money in, money out, profit.
5. Win customers with quality and service, never tricks.

Its source line: EntreComp (2016), the OECD/INFE framework (2015) and the UK's Competition and Markets Authority on fake reviews

Try it for real: Help a grown-up compare two prices in a shop: which is the better buy, and why?

Your child can now: ask customers what they want, price for a profit, give change, fix a complaint kindly, pay a fair wage, read a ledger and win customers back with quality, never tricks

Sources:

- [ ] Turning ideas into value for others; finding out what customers need; working with others (a helper). (EntreComp, the EU's Entrepreneurship Competence Framework (2016)): https://publications.jrc.ec.europa.eu/repository/handle/JRC101581
- [ ] Prices, costs and profit; comparing prices; keeping records of money in and out. (OECD/INFE Core Competencies Framework on Financial Literacy for Youth (2015)): https://microfinancegateway.org/paper/2015/09/core-competencies-framework-financial-literacy-youth
- [ ] Fake reviews, positive or negative, are banned by law in the UK (from 6 April 2025). (Competition and Markets Authority, Fake reviews guidance (CMA208, 2025)): https://www.gov.uk/government/publications/fake-reviews-cma208
- [ ] A complaint: listen, say it back, say sorry, fix it, thank them (Talk & Deal's way). (CASEL, the CASEL framework (relationship skills)): https://casel.org/fundamentals-of-sel/what-is-the-casel-framework/

### Big (12 and up): Harder days: costs, rain, orders and a rival

The Expert try's twist: The big order's honey comes a day late: tell Mr Okafor early. And nothing glows to help.

Steps:

- **hello**: words, then OK
  - Coach: "Your bakery's harder days: dearer flour, a rainy day, a big order, a fair wage and a rival. These are pretend coins."
- **costs**: pick the number
  - Coach: "A loaf cost you {old_cost} coins to make. Now its flour costs {flour_up} coin more. What does a loaf cost you now?"
  - Picture (flour) right: "{new_cost}"
  - Picture (flour) not this one: "{old_cost}": "Add the dearer flour to the cost."
  - Picture (flour) not this one: "{new_cost_wrong}": "Only the flour went up, by {flour_up}."
  - After: "{new_cost} coins to make a loaf now."
- **price**: pick a picture
  - Coach: "What is your new fair price for a loaf?"
  - Picture (coins) right: "{new_price} coins: the new cost and your profit"
  - Picture (price_down) not this one: "{old_price} coins, the old price": "That is no more than a loaf costs you now: no profit for your work, or for next week's flour."
  - Picture (price_up) not this one: "{greedy_price} coins": "That's far more than the cost went up: customers notice and go elsewhere."
  - After: "When costs rise, a fair price rises a little. Tell customers why: honesty keeps their trust."
- **rain**: pick a picture
  - Coach: "Rain today: about half the usual customers. You usually bake {normal_loaves} loaves. How many today?"
  - Picture (rain_cover) right: "About {rain_loaves}"
  - Picture (price_up) not this one: "{double_loaves}, just in case": "Bread nobody buys is money wasted: flour, butter and work."
  - Picture (cross) not this one: "None at all": "Some customers still come in the rain!"
  - After: "Bake for the customers you expect: less waste, more profit."
- **order**: pick the number
  - Coach: "Mr Okafor orders {order_n} honey buns for the library's party on Saturday, at 2 coins each. What is the total?"
  - Picture (honey_bun) right: "{order_total}"
  - Picture (honey_bun) not this one: "{order_wrong}": "{order_n} buns at 2 coins each: multiply, don't add."
  - Picture (honey_bun) not this one: "{order_n}": "Each bun is 2 coins, not 1."
  - After: "{order_total} coins. "See you on Saturday!""
  - The Connections Book: {"meet": ["okafor"]}
- **weigh**: pour or weigh to the line `scales` (motion measure, tool spoon, device scales, want {honey_g}, full 500, tol 10, unit g)
  - Coach: "Weigh {honey_g} grams of honey for the buns. Slowly near the end!"
  - After: "{honey_g} grams. The honey cost {honey_cost} coins: money out."
  - The shop's ledger: {"out": "{honey_cost}"}
- **late** (Expert try only): pick a picture
  - Coach: "Oh no: the honey for the rest of the buns comes a day late. Saturday is the party. What do you do?"
  - Picture (promise) right: "Tell Mr Okafor early, and agree a new plan"
  - Picture (quiet) not this one: "Say nothing and hope": "Bad news told early can be fixed together. Silence breaks trust."
  - Picture (fib) not this one: "Use no honey and don't tell him": "That isn't what he ordered. Be honest, then fix it together."
  - After: ""Thank you for telling me early. Half on Saturday, half on Sunday is fine!""
- **saturday**: the clock runs by itself (seconds 3.0, label Saturday)
  - Coach: "The buns are baked, and Saturday comes."
  - After: "Mr Okafor is here for his order."
- **deliver** (normal try only): touch it `customer` (motion press)
  - Coach: "Hand Mr Okafor his order."
  - After: ""Just as you promised!" A promise kept builds trust."
  - The shop's ledger: {"sale": "okafor", "in": "{order_total}", "review": "order"}
- **deliver** (Expert try only): touch it `customer` (motion press, no glow)
  - Coach: "Hand Mr Okafor his order."
  - After: ""Just as we agreed!" Telling him early kept his trust."
  - The shop's ledger: {"sale": "okafor", "in": "{order_total}", "review": "order"}
- **change**: give coins `hand` (motion press, tool coins, device till, sum {one_change})
  - Coach: "{one_mood} {one_name} buys 2 loaves at {new_price} and pays with a 20 note. Give {one_change} coins change."
  - After: "{one_total} and {one_change} make 20."
  - The Connections Book: {"meet": ["{one}"]}
  - The shop's ledger: {"sale": "{one}", "in": "{one_total}", "review": "fair"}
- **hours**: pick the number
  - Coach: "Bobo worked {hours} hours. A fair wage is {rate} coins an hour. What do you owe him?"
  - Picture (wage) right: "{wage}"
  - Picture (wage) not this one: "{wage_wrong}": "{hours} hours at {rate} coins an hour: multiply."
  - Picture (wage) not this one: "{rate}": "That's one hour. Bobo worked {hours}."
  - After: "{wage} coins for {hours} hours."
- **wage**: give coins `bobo` (motion press, tool coins, sum {wage})
  - Coach: "Pay Bobo his {wage} coins."
  - After: "Paid in full and on time: good helpers stay with fair bosses."
  - The shop's ledger: {"out": "{wage}"}
- **week**: pick a picture (device ledger)
  - Coach: "Your ledger's week: one bar dips under the line, a loss. Which day, and why?"
  - Picture (bars) right: "{loss_day}: rain, and too much bread baked"
  - Picture (bars) not this one: "{best_day}: the busiest day": "That's the tallest bar: the most profit."
  - Picture (cross) not this one: "Every day lost money": "Only one bar is under the line."
  - After: "A loss happens. The ledger shows why, so you can plan better next time."
- **price_war**: pick a picture
  - Coach: "Pip-pop sells bread at 1 coin, less than it costs her to make. Do you go lower too?"
  - Picture (kind_service) right: "No: keep a fair price, and show your quality"
  - Picture (price_down) not this one: "Sell at half a coin!": "Below the cost every loaf loses money, and soon there is none left for flour."
  - Picture (fib) not this one: "Say her bread is stale": "That's untrue and unkind. Win with quality, never with tricks."
  - After: "Selling below the cost can't last. Quality and kindness can."
- **unfair_review**: pick a picture
  - Coach: "A review says "Not a nice bakery" from someone who never came in. What do you do?"
  - Picture (kind_service) right: "Reply kindly and honestly, and invite them in"
  - Picture (fake_review) not this one: "Write ten pretend 5-star reviews": "Fake reviews are lies, and real shops are not allowed to use them."
  - Picture (bossy) not this one: "Reply with something rude": "Rude words make it worse, and everyone can read them."
  - After: "A kind, honest reply shows everyone what your shop is really like."
- **save**: pick the number (device ledger)
  - Coach: "This month's profit is {month_profit}. A bigger oven costs {oven}. You put {save_part} aside each month. How many months?"
  - Picture (jar) right: "{months}"
  - Picture (jar) not this one: "{months_wrong}": "Count how many lots of {save_part} make {oven}."
  - Picture (jar) not this one: "1": "{save_part} a month is not {oven} yet."
  - After: "{months} months of saving, and the bakery can grow."
- **give**: pick a feeling (any picture is right, nothing kept)
  - Coach: "Your shop is doing well. The school's fair asks the village for help. What would you like to do?"
  - Picture (helping_hands) not this one: "Give buns for the fair"
  - Picture (book) not this one: "Teach a baking class"
  - Picture (jar) not this one: "Save a little first, then give"
- **end**: words, then OK
  - Coach: "You handled dearer flour, rain, a big order, a fair wage, a rival and an unfair review, all honestly. For real money, talk to a grown-up you trust."

The before-and-after check (the right one first here; the game mixes their order):

- "The flour gets dearer. A fair price..." **goes up a little, and you say why** / stays the same / doubles
- "Rain halves your customers. You bake..." **fewer loaves** / twice as many
- "A rival sells below what it costs. You..." **keep a fair price and good quality** / go even lower
- "A fair wage for 3 hours at 3 coins an hour?" **9 coins** / 6 coins / 3 coins

The "name it" card: **A business on harder days**

1. When costs rise, a fair price rises a little: say why.
2. Make what customers will buy: less waste.
3. A promise is a deal: bad news, tell it early.
4. Pay a fair wage for the time worked.
5. Never sell below the cost, and never use tricks.

Its source line: EntreComp (2016), the EU and OECD financial competence framework (2023) and the Competition and Markets Authority (2025)

Try it for real: With a grown-up, look at a shop's receipt: what did each thing cost, and what did it all come to?

Your child can now: change a price fairly when costs rise, bake for the customers expected, take and keep a big order, work out and pay a fair wage, read a loss in the ledger, keep a fair price in a price war, answer an unfair review kindly and save to grow

Sources:

- [ ] Planning and managing: cash in and out, costs, and acting on what the numbers show. (EntreComp, the EU's Entrepreneurship Competence Framework (2016)): https://publications.jrc.ec.europa.eu/repository/handle/JRC101581
- [ ] Income, spending and saving for a goal; how prices change when costs change. (European Union and OECD, Financial competence framework for children and youth (2023)): https://search.oecd.org/daf/fin/financial-education/Financial-competence-framework-youth-EU.pdf
- [ ] Fake reviews, positive or negative, are banned by law in the UK (from 6 April 2025). (Competition and Markets Authority, Fake reviews guidance (CMA208, 2025)): https://www.gov.uk/government/publications/fake-reviews-cma208
- [ ] Prices send signals: when supply or demand changes, market prices adjust. (Council for Economic Education, Voluntary National Content Standards in Economics (2010), standard 8): https://www.councilforeconed.org/wp-content/uploads/2012/03/voluntary-national-content-standards-2010.pdf

## The Market Square

For the review by an economics teacher (supply and demand, specialising and trade) and a gambling-harm educator (the dice lesson: GamCare, YGAM or the national body).

The device **price_board**: controls: the goods' rows. It shows: each good's price today; an arrow up or down; why it moved. The right order: find the good → read its price → read its arrow → read why it moved. Safety: prices change with the seasons: read today's; a fair price is honest for both sides.

### Little (about 6-8): The swap stall: swapping fairly

The Expert try's twist: Lina asks for more after you shook hands, and nothing glows to help.

Steps:

- **hello**: words, then OK
  - Coach: "The Market Square! Today you swap things at the swap stall. A fair swap makes both people happy."
- **why**: pick a picture
  - Coach: "You have lots of apples. Lina has lots of pears. Why swap?"
  - Picture (swap) right: "So you both have apples and pears"
  - Picture (fair_not) not this one: "To take all of Lina's pears": "A swap gives as well as takes."
  - Picture (cross) not this one: "Swapping is never fair": "A fair swap is good for both!"
  - After: "People swap and trade so everyone gets what they need."
  - The Connections Book: {"meet": ["lina"]}
- **offer**: tap it `apples` (motion press, count {swap_n})
  - Coach: "Lina offers {swap_n} pears for {swap_n} apples. Put {swap_n} apples on the swap table."
  - After: "{swap_n} apples for {swap_n} pears."
- **fair**: pick a picture
  - Coach: "Is {swap_n} apples for {swap_n} pears a fair swap?"
  - Picture (handshake) right: "Yes: the same for both of us"
  - Picture (cross) not this one: "No": "You both give the same and you are both happy: that's fair!"
  - After: "Fair for both."
- **shake**: hold it `lina_hand` (motion squeeze, seconds 1.0, reach hand)
  - Coach: "Shake hands on it!"
  - After: "A swap agreed is a promise."
- **more** (Expert try only): pick a picture
  - Coach: "After you shook hands, Lina asks for 2 more apples. What do you say?"
  - Picture (promise) right: "We agreed {swap_n} for {swap_n}: that's our swap"
  - Picture (face_sad) not this one: "Give them, and feel sad": "A swap is a promise for both. Say kindly what you agreed."
  - Picture (cross) not this one: "Grab your apples back": "Talk kindly: grabbing is never the way."
  - After: "Lina smiles: "You're right. A deal is a deal!""
- **pears** (normal try only): touch it `pears` (motion press)
  - Coach: "Take your pears."
  - After: "Now you both have apples and pears."
- **pears** (Expert try only): touch it `pears` (motion press, no glow)
  - Coach: "Take your pears."
  - After: "Now you both have apples and pears."
- **unfair**: pick a picture
  - Coach: "Mo offers 1 sticker for ALL your apples. What do you say?"
  - Picture (please) right: "No, thank you. 1 apple for 1 sticker?"
  - Picture (fair_not) not this one: "Yes, take them all!": "Then you'd have no apples left, for one sticker. Ask for a fair swap."
  - After: ""OK, 1 for 1!" Mo grins. Fair is better."
  - The Connections Book: {"meet": ["mo"]}
- **jar**: pick a picture
  - Coach: "Rosa has a little jar you like. She would love one of your drawings. You are both happy to swap. Is it fair?"
  - Picture (swap) right: "Yes: we both get something we want"
  - Picture (cross) not this one: "No: things must be the same": "A swap is fair when both people are happy with it."
  - After: "A drawing for a jar: both happy!"
  - The Connections Book: {"meet": ["rosa"]}
- **thanks**: touch it `lina` (motion press)
  - Coach: "Say thank you to Lina for a fair swap."
  - After: "Lina wants to swap with you again!"
- **end**: words, then OK
  - Coach: "Well done! You swapped fairly, said no kindly to an unfair swap, and kept your word."

The before-and-after check (the right one first here; the game mixes their order):

- "A fair swap is..." **good for both people** / good for one person
- "Why do people swap and trade?" **To get things they need** / To take things
- "1 sticker for ALL your apples. Fair?" **No** / Yes

The "name it" card: **Swapping fairly**

1. A fair swap is good for both.
2. Say kindly what you would like.
3. No, thank you, to an unfair swap.
4. A swap agreed is a promise.

Its source line: The Council for Economic Education's standards (2010) and the OECD/INFE money skills (2015)

Try it for real: Swap a toy or a book with a friend, fairly, with a grown-up's OK.

Your child can now: say why people swap, make a fair swap that is good for both, say no kindly to an unfair one and keep a swap they agreed

Sources:

- [ ] Voluntary exchange happens only when both sides expect to gain. (Council for Economic Education, Voluntary National Content Standards in Economics (2010), standard 5): https://www.councilforeconed.org/wp-content/uploads/2012/03/voluntary-national-content-standards-2010.pdf
- [ ] Fairness, sharing and keeping your word with others. (CASEL, the CASEL framework (relationship skills)): https://casel.org/fundamentals-of-sel/what-is-the-casel-framework/
- [ ] Money and trade: why people exchange goods. (OECD/INFE Core Competencies Framework on Financial Literacy for Youth (2015)): https://microfinancegateway.org/paper/2015/09/core-competencies-framework-financial-literacy-youth

### Middle (about 9-11): Supply and demand: why prices move

The Expert try's twist: The festival and many cake sellers on the same day, and nothing glows to help.

Steps:

- **hello**: words, then OK
  - Coach: "The Market Square! Buddy merchants sell here, and the Price Board shows today's prices. Prices move for reasons you can see."
- **read**: aim at it `price_board` (motion aim, device price_board)
  - Coach: "Read the Price Board."
  - After: "Wheat {wheat_base}, flour {flour_price}, apples {apple_base}, honey {honey_base}, cakes {cake_base}: the usual prices."
- **dry**: the clock runs by itself (seconds 4.0, label A dry summer)
  - Coach: "Watch a dry summer go by: hardly any rain falls on the wheat fields."
  - After: "The wheat grew short and thin."
- **wheat_up**: pick a picture
  - Coach: "Less wheat grew, but people still want bread. What happens to the price of wheat?"
  - Picture (price_up) right: "It goes up"
  - Picture (price_down) not this one: "It goes down": "Less to sell and the same people buying: the price goes up."
  - Picture (price_same) not this one: "It stays the same": "When there is less to sell, buyers offer more for it."
  - After: "Wheat is {wheat_dry} now. Less supply: a higher price."
- **festival** (normal try only): pick a picture
  - Coach: "It's the festival! Everyone wants cakes today. What happens to the price of cakes?"
  - Picture (price_up) right: "It goes up"
  - Picture (price_down) not this one: "It goes down": "More people want cakes than usual: the price goes up."
  - Picture (price_same) not this one: "It stays the same": "More buyers for the same cakes: the price goes up."
  - After: "Cakes are {cake_festival} today. More demand: a higher price."
- **festival** (Expert try only): pick a picture
  - Coach: "The festival, and many more cake sellers came too! What happens to the price of cakes?"
  - Picture (price_same) right: "It changes less: the two pull opposite ways"
  - Picture (price_up) not this one: "It goes up a lot": "More sellers pull the price down while more buyers pull it up."
  - Picture (cross) not this one: "There are no cakes": "There are more cakes than ever: lots of sellers!"
  - After: "More buyers and more sellers: the price stays about {cake_base}."
- **many**: pick a picture
  - Coach: "Four more farmers bring apples to sell today. What happens to the price of apples?"
  - Picture (price_down) right: "It goes down"
  - Picture (price_up) not this one: "It goes up": "Lots of apples and sellers wanting buyers: sellers lower their prices."
  - Picture (price_same) not this one: "It stays the same": "With so many apples to choose from, prices fall."
  - After: "Apples are {apple_many} today. More supply: a lower price."
- **find_row**: aim at it `row_apples` (motion aim, device price_board)
  - Coach: "Find apples on the Price Board, and read why the price moved."
  - After: "The board says why: many sellers came."
- **to_tomas**: go there `spot_tomas`
  - Coach: "Let's buy flour from Tomas the miller."
  - After: "Here's Tomas's stall."
- **buy_flour**: give coins `tomas` (motion press, tool coins, sum {flour_total})
  - Coach: "Flour is {flour_price} coins a sack. Pay Tomas {flour_total} coins for {flour_words}."
  - After: ""Thank you!" Tomas gives you the flour."
  - The Connections Book: {"meet": ["tomas"]}
- **haggle**: pick a picture
  - Coach: "Ana's apples are {apple_base} coins a bag. You want {haggle_bags} bags: {haggle_full} coins. How do you ask for a better price?"
  - Picture (please) right: ""Could you do {haggle_ask} for all {haggle_bags}?""
  - Picture (bossy) not this one: ""That's a rip-off!"": "Rude words make people stop wanting to trade with you."
  - Picture (fair_not) not this one: ""Give them to me for nothing"": "That's not a deal: both sides should win."
  - After: "Ana smiles: "{haggle_ask}, as you're buying {haggle_bags}. Deal!""
  - The Connections Book: {"meet": ["ana"]}
- **shake**: hold it `ana_hand` (motion squeeze, seconds 1.0, reach hand)
  - Coach: "Shake hands on the deal."
  - After: "A fair deal, politely made."
- **specialise**: pick a picture
  - Coach: "In a day you bake {sp_you_loaves} loaves OR pick {sp_you_bags} bags of apples. Ana picks {sp_ana_bags} bags OR bakes {sp_ana_loaves} loaves. If you only bake, and she only picks?"
  - Picture (swap) right: "{sp_together_loaves} loaves and {sp_together_bags} bags together"
  - Picture (price_same) not this one: "{sp_mixed_loaves} loaves and {sp_mixed_bags} bags": "That's what you make doing half of each. Doing what you each do best makes more!"
  - Picture (price_down) not this one: "Less than before": "Each doing their best thing makes more of both."
  - After: "More of both! Swap {sp_trade} loaves for {sp_trade} bags, and you each have more than before."
- **sell**: give coins `hand` (motion press, tool coins, sum {cake_change})
  - Coach: "At the festival a customer buys a cake at {cake_festival} and pays with a 10 coin. Give {cake_change} coins change."
  - After: "{cake_festival} and {cake_change} make 10."
- **autumn**: the clock runs by itself (seconds 4.0, label Autumn's harvest)
  - Coach: "The seasons pass, and autumn brings the harvest."
  - After: "The fields are full of wheat."
- **wheat_down**: pick a picture
  - Coach: "A big wheat harvest: lots of wheat to sell. What happens to the price of wheat?"
  - Picture (price_down) right: "It goes down"
  - Picture (price_up) not this one: "It goes up": "Lots of wheat for the same buyers: the price falls."
  - Picture (price_same) not this one: "It stays at {wheat_dry}": "The dry summer is over: now there is plenty."
  - After: "Wheat is {wheat_autumn} now: supply and demand, with causes you can see."
- **end**: words, then OK
  - Coach: "You read the Price Board, saw why prices move, bought, haggled politely, specialised and traded. Both sides richer!"

The before-and-after check (the right one first here; the game mixes their order):

- "Less wheat grows this year. Its price..." **goes up** / goes down
- "Many sellers bring apples. The price of apples..." **goes down** / goes up
- "A polite way to ask for a better price:" **Could you do 4 if I buy 3?** / That's a rip-off!
- "Each doing what they do best, then trading..." **makes both richer** / makes both poorer

The "name it" card: **Supply and demand**

1. Less to sell, the same buyers: the price goes up.
2. More to sell, or many sellers: the price goes down.
3. More buyers: the price goes up.
4. Doing what you do best and trading makes both richer.
5. Haggle politely: both sides should win.

Its source line: The Council for Economic Education's standards (2010) and the Bank of England's economics teaching

Try it for real: With a grown-up at a market or a shop, find a price that changed this season, and guess why.

Your child can now: read a price board, say why prices go up or down (supply and demand), buy and sell with change, haggle politely and explain why specialising and trading makes both richer

Sources:

- [ ] Prices send signals: when supply or demand changes, market prices adjust. (Council for Economic Education, Voluntary National Content Standards in Economics (2010), standards 7 and 8): https://www.councilforeconed.org/wp-content/uploads/2012/03/voluntary-national-content-standards-2010.pdf
- [ ] Specialising in what you make at the lowest cost and trading increases production and consumption. (Council for Economic Education, Voluntary National Content Standards in Economics (2010), standard 6): https://www.councilforeconed.org/wp-content/uploads/2012/03/voluntary-national-content-standards-2010.pdf
- [ ] Markets, prices, supply and demand for school students. (Bank of England, Economics in practice (teaching resource)): https://www.bankofengland.co.uk/-/media/boe/files/education/economics-in-practice.pdf
- [ ] A fair deal good for both, asked for politely (interests, not positions). (Program on Negotiation, Harvard Law School): https://www.pon.harvard.edu/tag/batna/

### Big (12 and up): Trading honestly, and why gambling loses

The Expert try's twist: A new dice game pays 5 for a 6: work out what it still takes. And nothing glows to help.

Steps:

- **hello**: words, then OK
  - Coach: "Trading for the long run: buy and sell honestly, keep a stock, spread out, and see why gambling loses. Pretend coins and pretend counters only."
- **read**: aim at it `row_apples` (motion aim, device price_board)
  - Coach: "It's autumn's harvest. Read the apples on the Price Board."
  - After: "Apples are {apple_autumn} a bag now. In winter they are usually about {apple_winter}."
- **plan**: pick a picture
  - Coach: "What is an honest way to trade apples?"
  - Picture (shed) right: "Buy some now, store them well, sell in winter at a fair price"
  - Picture (fib) not this one: "Sell old apples as fresh ones": "That's a lie: customers find out, and never trust you again."
  - Picture (fair_not) not this one: "Buy every apple so nobody else can": "That's unfair to everyone, and your shed would overflow."
  - After: "Buying when there's plenty and selling when it's scarce is honest, and it helps: there are apples in winter."
- **stock**: pick the number
  - Coach: "Your shed holds {shed} bags. Apples keep about 3 months, and you can sell about {per_month} bags a month. How many bags do you buy?"
  - Picture (shed) right: "{stock}"
  - Picture (shed) not this one: "{stock_wrong}: fill the shed": "Apples you can't sell before they go soft are money wasted."
  - Picture (apple) not this one: "1": "Too few: your customers will want more."
  - After: "{stock} bags: what you can store and sell before they go soft."
- **store**: tap it `shed` (motion press, count 3)
  - Coach: "Carry the bags into your shed."
  - After: "Stocked up!"
- **winter**: the clock runs by itself (seconds 4.0, label Winter)
  - Coach: "Autumn turns to winter. Few apples are left in the market."
  - After: "Winter."
- **sell**: give coins `hand` (motion press, tool coins, sum {sale_change})
  - Coach: "Apples are {apple_winter} a bag now. A customer buys {sale_bags} bags and pays with a 20 note. Give {sale_change} coins change."
  - After: "{sale_total} and {sale_change} make 20. A fair price, honestly earned."
- **spread**: find them `basket_wheat, basket_apples, basket_honey` (motion press)
  - Coach: "Spread your trading: put some stock in each basket, wheat, apples and honey."
  - Found `basket_wheat`: "Some wheat."
  - Found `basket_apples`: "Some apples."
  - Found `basket_honey`: "Some honey."
  - After: "Three baskets, not one."
- **storm**: pick a picture
  - Coach: "A storm flattens the wheat fields: no wheat to sell for a while. How is your business?"
  - Picture (baskets) right: "All right: apples and honey still sell"
  - Picture (storm) not this one: "Ruined: wheat was everything": "That happens with only one basket. You have three!"
  - Picture (cross) not this one: "Richer: storms are good": "A storm hurts the wheat traders. Spreading out keeps you steady."
  - After: "Spreading out keeps you steady when one thing goes wrong."
- **dice_intro**: words, then OK
  - Coach: "At the fair, Pip-pop has a pretend game: "Pay 1 counter. Throw a 6 and get {dice_pays} back!" Let's find out what happens, with pretend counters. Nobody bets anything."
- **throws**: tap it `dice` (motion press, count 6)
  - Coach: "Throw the dice 6 times, and count the sixes."
  - After: "{dice_sixes} sixes in 6 throws."
- **how_often**: pick a picture
  - Coach: "On a fair dice, how often does a 6 come up, over many throws?"
  - Picture (dice) right: "About once in every 6 throws"
  - Picture (price_up) not this one: "Every other throw": "A dice has 6 faces, and each comes up as often as the others."
  - Picture (question) not this one: "When you really need one": "The dice can't know what you need: every throw is new."
  - After: "About 1 in 6."
- **chart**: the clock runs by itself (seconds 5.0, label 600 throws)
  - Coach: "Now watch 600 throws, drawn as a chart: 600 counters paid, and {dice_pays} back for each 6."
  - After: "The line went down and down."
- **why_down**: pick a picture
  - Coach: "The line ends {chart_lost} counters down. Why?"
  - Picture (chart_down) right: "A 6 pays {dice_pays}, but it takes about 6 throws to get one"
  - Picture (try_again) not this one: "Bad luck: it will turn soon": "Every throw is new: the dice don't remember. The line keeps going down."
  - Picture (clock) not this one: "Throwing faster wins": "How you throw doesn't change a fair dice."
  - After: "Games like this are made to keep more than they give. Over time, the player always ends up with less."
- **pays_5** (Expert try only): pick the number
  - Coach: "A new game pays {expert_pays} for a 6. In {expert_throws} throws you pay {expert_throws} counters and get about {expert_back} back. About how many are lost?"
  - Picture (chart_down) right: "{expert_lost}"
  - Picture (cross) not this one: "0": "{expert_back} back for {expert_throws} paid: still a loss."
  - Picture (dice) not this one: "{expert_back}": "That's what comes back. Take it away from {expert_throws}."
  - After: "Still a loss: the game always keeps a little more than it gives."
- **not_gambling**: pick a picture
  - Coach: "Which one is gambling?"
  - Picture (dice) right: "Paying for a chance to win a prize"
  - Picture (apple) not this one: "Selling apples you bought honestly": "That's trading: you give people something they want."
  - Picture (bank) not this one: "Saving in the bank": "Saving keeps your money, and it grows a little."
  - After: "Gambling is paying for a chance to win. Trading and saving are not gambling."
- **end**: words, then OK
  - Coach: "You traded honestly, kept a stock, spread out, and saw why gambling loses over time. For real money, talk to a grown-up you trust."

The before-and-after check (the right one first here; the game mixes their order):

- "Over many throws, a game that pays back less than it takes..." **always takes more than it gives** / always pays out more
- "Spreading your trading across goods..." **keeps you steady if one goes wrong** / is always riskier
- "Buying apples in autumn and selling them honestly in winter is..." **trading** / gambling
- "A fair dice shows a 6 about..." **once in 6 throws** / every other throw

The "name it" card: **Trading honestly, and why gambling loses**

1. Buy when there's plenty, sell when it's scarce: honestly.
2. Keep only the stock you can store and sell.
3. Spread across goods: a storm hits one.
4. A game that pays back less than it takes loses over time.
5. For real money, talk to a grown-up you trust.

Its source line: The EU and OECD financial competence framework (2023), the Council for Economic Education (2010) and GamCare

Try it for real: Talk with a grown-up you trust about why games of chance are made to win, and the player is not.

Your child can now: buy when there is plenty and sell when it is scarce honestly, keep only the stock they can store and sell, spread across goods, and explain with averages why games of chance lose over time

Sources:

- [ ] Risk and reward; spreading risk; telling saving and investing apart from gambling. (European Union and OECD, Financial competence framework for children and youth (2023)): https://search.oecd.org/daf/fin/financial-education/Financial-competence-framework-youth-EU.pdf
- [ ] A fair dice: each of the six faces is equally likely; many throws show it. (NRICH (University of Cambridge), What Do You Know About Probability? (2)): https://nrich.maths.org/12151
- [ ] Giving young people the facts about gambling, and the critical thinking to choose. (GamCare, Giving young people the facts about gambling): https://gamcare.org.uk/news-and-blog/blog/giving-young-people-the-facts-about-gambling
- [ ] Loot box spending is linked to problem gambling, more so in older teenagers. (Zendle and Cairns (2018), PLOS ONE): https://pmc.ncbi.nlm.nih.gov/articles/PMC6599795

## My Business's shop: its data (data/success/shop.json)

Every price is in pretend market coins: what it costs to make and its fair price (the cost and 1 coin profit).

- [ ] **bread**: costs 2 to make, sells for 3 (a loaf of bread)
- [ ] **cake**: costs 3 to make, sells for 4 (a cake)
- [ ] **honey bun**: costs 1 to make, sells for 2 (a honey bun)

The customers (the Connections Book's people) and their wishes:

- [ ] lina wants cake: "A cake, please. It's for my new friend!"
- [ ] mo wants bread: "A loaf of bread for my lunch, please."
- [ ] okafor wants honey_bun: "Honey buns for my reading club, please."
- [ ] kenji wants bread: "Some bread to eat by my beehives, please."
- [ ] omar wants cake: "A cake for the clock shop's birthday, please!"
- [ ] rosa wants honey_bun: "Honey buns for the potters' tea break, please."
- [ ] gemma wants bread: "Bread for a day out in the hills, please."
- [ ] ivan wants honey_bun: "A honey bun to go with my tea, please."
- [ ] mei wants cake: "A cake for the Launch Site team, please!"
- [ ] tomas wants bread: "A loaf, please. My flour made it!"

How they come in: ... comes in smiling.; ... comes in quietly and looks a little shy.; ... comes in after a long day.

The shop's signs (MY SHOP, picked, never typed): THE SUNNY BAKERY; THE GOLDEN LOAF; BREAD AND SMILES; THE HONEY OVEN; THE CORNER BAKERY; THE ROCKET BAKERY (each also says: FRESH BREAD, CAKES AND HONEY BUNS)

The customers' reviews (honest and kind; 4 stars when the coach helped with that sale, never fewer):

- [ ] asked: 5 stars, "You asked what I wanted. Just right!"
- [ ] fair: 5 stars, "Good baking at a fair price."
- [ ] fresh: 5 stars, "Fresh bread and a big smile!"
- [ ] fixed: 5 stars, "Something went wrong, and you listened and fixed it. Thank you!"
- [ ] order: 5 stars, "The big order came on time, just as you promised."
- [ ] quicker: 4 stars, "Lovely! Next time it will be even quicker."

**The real gold** (please check the amount with the owner): the shop pays the game's own Survivor gold only for customers served in a try, 5 for each (like a School answer right the first time), never more than 50 a day (a third of the School's 150), through the game's award path (EarnRules.credit; the wallet sync takes it to the server within its limits). Never for time, never while the child is away; a try stopped for now pays only the customers already served. The skill's own 100 once per track is Life's, as for every Life skill.

## The Market Square: its data (data/success/market.json)

A market day is the School's day; a season lasts 7 market days; nothing is random and nothing is paid.

- [ ] **wheat** (a bag): usually 2, sold by ana
- [ ] **flour** (a sack): usually 4, sold by tomas
- [ ] **apples** (a bag): usually 3, sold by ana
- [ ] **honey** (a jar): usually 5, sold by kenji
- [ ] **cakes** (a cake): usually 4, sold by amara

- [ ] spring (a season): honey -1. "Spring: the bees are busy, and there is lots of honey to sell."
- [ ] summer (a season): wheat +2, flour +1. "A dry summer: less wheat grew, so wheat and flour cost more."
- [ ] autumn (a season): wheat -1, apples -1. "Autumn's harvest: lots of wheat and apples to sell, so they cost less."
- [ ] winter (a season): apples +2, honey +1. "Winter: few apples are left and the bees rest, so apples and honey cost more."
- [ ] festival (every 14 days): cakes +2. "The festival! Everyone wants cakes today, so cakes cost more."
- [ ] many_sellers (every 7 days): apples -1. "Many apple sellers came today: lots to choose from, so apples cost less."

The dice lesson (Big): a pretend game, "pay 1 counter, throw a 6 and get 4 back", with pretend counters only (never gold, never a bet). On average a throw loses 1 - 4/6 = 1/3 of a counter; 600 throws end about 200 down (the chart). The Expert try's game pays 5 for a 6: still about 1/6 of a counter lost a throw.
