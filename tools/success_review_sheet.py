#!/usr/bin/env python3
"""Owner #115 (docs/design/success-skills.md §3: "facts checked, experts asked"): writes Success S2's review sheet for the
owner's experts from the game's own data, so it always says exactly what the game says: the four Experiences
(data/success/experiences/*.json, every track's steps, words, picture answers and their kind "why", the checks, the
"name it" cards, Try it for real and the sources), the Goal Board's and the habit garden's parts (data/success/goals.json),
the Connections Book's people (data/success/people.json) and the twenty Success Stories with every fact's source
(data/success/stories.json). It reuses Life's sheet writer (tools/life_review_sheet.py) for the steps.

Owner #115 (S3): it also writes Success S3's sheet (docs/devlog/parts/success-s3-review.md): My Business's shop and the
Market Square (their Experiences, the shop's goods, customers, review words and signs from data/success/shop.json, the
market's goods, seasons and days from data/success/market.json, the gold the shop pays), each source a checkbox.

  /usr/bin/python3 tools/success_review_sheet.py            # writes success-s2-review.md and success-s3-review.md
  /usr/bin/python3 tools/success_review_sheet.py --check    # exits 1 when a sheet is out of date
"""
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.dont_write_bytecode = True   # no __pycache__ in tools/ from importing Life's sheet writer
sys.path.insert(0, str(HERE))
import life_review_sheet as life  # noqa: E402  (Life's step writer: the same words, the same layout)

ROOT = HERE.parent
DATA = ROOT / "data" / "success"
OUT = ROOT / "docs" / "devlog" / "parts" / "success-s2-review.md"
IDS = ["goal_board", "talk_deal", "connections", "success_stories"]
REVIEWER = {"goal_board": "a child psychologist or school counsellor (goals, if-then plans, habits)",
	"talk_deal": "a teacher of speaking and listening, and a financial educator (deals, the pitch, investors)",
	"connections": "a child psychologist or school counsellor, and an online-safety educator (CEOP or the national body)",
	"success_stories": "a history teacher (every fact against its source)"}
TOKENS = {"{gripe}": "My bread got squashed in my bag! (or: My loaf was too hard to cut! / You gave me the wrong bread!)",
	"{gripe_back}": "Your bread got squashed. Oh no! (said back to match)", "{cake_gripe}": "dry (or too sweet, or squashed)",
	"{gift}": "crayons (or paints, or coloured pencils)", "{moon_gold}": "the Moon rocket's gold (Mission Control's plan for one astronaut)"}


def fill(text):
	out = life.fill(text)
	for token, words in TOKENS.items():
		out = out.replace(token, words)
	return out


OUT_S3 = ROOT / "docs" / "devlog" / "parts" / "success-s3-review.md"
IDS_S3 = ["my_shop", "market_square"]
REVIEWER_S3 = {"my_shop": "a financial educator or an enterprise educator (prices, profit, the ledger, wages), with a "
	"consumer body's adviser (fake reviews, complaints)",
	"market_square": "an economics teacher (supply and demand, specialising and trade) and a gambling-harm educator "
	"(the dice lesson: GamCare, YGAM or the national body)"}
## The values that change with each try (SuccessShop.vars, SuccessMarket.vars): the sheet shows them as tokens.
GLOSSARY_S3 = [
	("{one_name}, {one_mood}, {one_wish}", "the first customer: one of the Connections Book's people (Lina, Mr Okafor, "
		"Grandpa Kenji, Omar, Rosa, Gemma, Ivan, Mei, Tomas), how they come in (smiling, a little shy, after a long day) "
		"and their wish (data/success/shop.json's customers)"),
	("{one_good_word}, {one_good_one}, {one_what}, {one_other_*}", "what the first customer wants (bread, a cake or honey "
		"buns) and the other goods offered as the wrong pictures"),
	("{two_name}, {two_budget}, {two_count}", "the second customer (Middle: unsure; buys honey buns for friends with 6, 8 "
		"or 10 coins: 3, 4 or 5 buns); on Little the second customer is always Mo"),
	("{price}, {cost}, {two_paid}, {two_change}, {money_in}, {flour_out}, {left}", "Little: 2 coins for anything that "
		"cost 1; Mo pays 3-5 for bread (change 1-3); 4 coins in, 2 kept for flour, 2 left"),
	("{one_total}, {one_change}, {flour_g}, {flour_cost}, {wage}, {money_out}, {profit}", "Middle: the first sale (2-8 "
		"coins, paid with a 10), 300-500 g of flour costing 3, Bobo's wage 3, profit = money in - money out (2-12)"),
	("{best_day}, {day_wrong_*}, {loss_day}", "the ledger's week of bars: the tallest bar's day; on Big one rainy day "
		"(Tuesday or Wednesday) under the line"),
	("{old_cost}, {flour_up}, {new_cost}, {new_price}, {greedy_price}", "Big: a loaf cost 2; flour up by 1 or 2; the new "
		"cost 3-4; the fair new price 4-5; a greedy one 8-9"),
	("{normal_loaves}, {rain_loaves}, {order_n}, {order_total}, {honey_g}, {hours}, {rate}, {month_profit}, {save_part}, "
		"{oven}, {months}", "Big: 20 or 24 loaves (half on a rainy day); 8-12 honey buns at 2 each; 150-250 g of honey; "
		"2-4 hours at 3 coins; 40-80 profit a month, half saved for a 120-coin oven (3-6 months)"),
	("{gripe}, {gripe_back}", "Mo's complaint (Talk & Deal's: squashed, too hard or the wrong bread) and saying it back"),
	("{swap_n}", "Little's market: 2 or 3 apples for as many pears"),
	("{wheat_base}, {wheat_dry}, {wheat_autumn}, {cake_base}, {cake_festival}, {apple_base}, {apple_many}, {apple_autumn}, "
		"{apple_winter}, {flour_price}, {honey_base}", "the Price Board: wheat 2 (4 after a dry summer, 1 at the harvest), "
		"cakes 4 (6 at the festival), apples 3 (2 with many sellers or at the harvest, 5 in winter), flour 4, honey 5"),
	("{flour_words}, {flour_total}, {haggle_bags}, {haggle_full}, {haggle_ask}, {cake_change}", "Middle: 1 or 2 sacks of "
		"flour; 4 or 5 bags of apples (12 or 15 coins) and the polite ask 2 less; the festival cake's change from 10"),
	("{sp_*}", "specialising: you bake 10 loaves or pick 4 bags; Ana picks 10 bags or bakes 2 loaves; half of each makes "
		"6 loaves and 7 bags together; each doing their best makes 10 and 10; swapping 4 for 4 leaves both with more"),
	("{shed}, {per_month}, {stock}, {sale_bags}, {sale_change}", "Big: a 20-bag shed; 4-6 bags sold a month for 3 months "
		"(12-18 bought); 2 or 3 winter bags paid with a 20"),
	("{dice_pays}, {dice_sixes}, {chart_lost}, {expert_*}", "the dice lesson with pretend counters: pay 1 a throw, a 6 "
		"gives 4 back; 6 throws by the child; the chart of 600 throws ends about 200 down (the try's own seed); the Expert "
		"try's game pays 5 for a 6: 60 throws, about 50 back, about 10 lost"),
]


def experiences(ids=None, reviewer=None, checkbox=False):
	ids = ids or IDS
	reviewer = reviewer or REVIEWER
	lines = []
	for exp_id in ids:
		d = json.loads((DATA / "experiences" / (exp_id + ".json")).read_text())
		lines += ["## %s" % d["title"], "", "For the review by %s." % reviewer[exp_id], ""]
		for dev, model in d.get("devices", {}).items():
			lines.append("The device **%s**: controls: %s. It shows: %s. The right order: %s. Safety: %s." % (dev,
				"; ".join(model["controls"]), "; ".join(model["shows"]), " → ".join(model["order"]), "; ".join(model["safety"])))
		lines.append("")
		for track, words in life.TRACKS:
			t = d["tracks"][track]
			lines += ["### %s: %s" % (words, t["skill"]), "", "The Expert try's twist: %s" % t["twist"], "", "Steps:", ""]
			for step in t["steps"]:
				for l in life.step_lines(step):
					lines.append(fill(l))
				if step.get("book"):
					lines.append("  - The Connections Book: %s" % json.dumps(step["book"]))
				if step.get("story"):
					lines.append("  - The story it acts: %s" % step["story"])
				if step.get("shop"):   # owner #115 (S3): what the step puts in the shop's ledger
					lines.append("  - The shop's ledger: %s" % json.dumps(step["shop"]))
			lines += ["", "The before-and-after check (the right one first here; the game mixes their order):", ""]
			for q in t["check"]:
				lines.append("- \"%s\" %s" % (fill(q["say"]), " / ".join(
					("**%s**" if i == q["answer"] else "%s") % fill(c["text"]) for i, c in enumerate(q["choices"]))))
			card = t["name_it"]
			lines += ["", "The \"name it\" card: **%s**" % card["title"], ""]
			for i, l in enumerate(card["lines"], 1):
				lines.append("%d. %s" % (i, l))
			lines += ["", "Its source line: %s" % card["source"], "", "Try it for real: %s" % t["try_real"], "",
				"Your child can now: %s" % t["can_now"], "", "Sources:", ""]
			for s in t["sources"]:
				lines.append("- %s%s (%s): %s" % ("[ ] " if checkbox else "", s["fact"], s["source"], s["url"]))
			lines.append("")
	return lines


def shop_and_market():
	shop = json.loads((DATA / "shop.json").read_text())
	market = json.loads((DATA / "market.json").read_text())
	lines = ["## My Business's shop: its data (data/success/shop.json)", "",
		"Every price is in pretend market coins: what it costs to make and its fair price (the cost and 1 coin profit).", ""]
	for gid, g in shop["goods"].items():
		lines.append("- [ ] **%s**: costs %d to make, sells for %d (%s)" % (g["name"], g["cost"], g["price"], g["one"]))
	lines += ["", "The customers (the Connections Book's people) and their wishes:", ""]
	for cid, c in shop["customers"].items():
		lines.append("- [ ] %s wants %s: \"%s\"" % (cid, c["good"], c["words"]))
	lines += ["", "How they come in: " + "; ".join(m["words"].replace("{name}", "...") for m in shop["moods"]), "",
		"The shop's signs (MY SHOP, picked, never typed): " + "; ".join(x["text"] for x in shop["signs"]) +
		" (each also says: %s)" % shop["sign_line"], "", "The customers' reviews (honest and kind; 4 stars when the coach "
		"helped with that sale, never fewer):", ""]
	for k, r in shop["reviews"].items():
		lines.append("- [ ] %s: %d stars, \"%s\"" % (k, r["stars"], r["words"]))
	lines += ["", "**The real gold** (please check the amount with the owner): the shop pays the game's own Survivor gold "
		"only for customers served in a try, 5 for each (like a School answer right the first time), never more than 50 "
		"a day (a third of the School's 150), through the game's award path (EarnRules.credit; the wallet sync takes it "
		"to the server within its limits). Never for time, never while the child is away; a try stopped for now pays only "
		"the customers already served. The skill's own 100 once per track is Life's, as for every Life skill.", "",
		"## The Market Square: its data (data/success/market.json)", "",
		"A market day is the School's day; a season lasts %d market days; nothing is random and nothing is paid." %
		market["days_per_season"], ""]
	for gid, g in market["goods"].items():
		lines.append("- [ ] **%s** (%s): usually %d, sold by %s" % (g["name"], g["unit"], g["base"], g["who"]))
	lines.append("")
	for x in market["seasons"] + market["events"]:
		fx = ", ".join("%s %+d" % (k, v) for k, v in x["effects"].items())
		when = ("every %d days" % x["every"]) if "every" in x else "a season"
		lines.append("- [ ] %s (%s): %s. \"%s\"" % (x["id"], when, fx, x["why"]))
	lines += ["", "The dice lesson (Big): a pretend game, \"pay 1 counter, throw a 6 and get 4 back\", with pretend "
		"counters only (never gold, never a bet). On average a throw loses 1 - 4/6 = 1/3 of a counter; 600 throws end "
		"about 200 down (the chart). The Expert try's game pays 5 for a 6: still about 1/6 of a counter lost a throw.", ""]
	return lines


def sheet_s3():
	lines = ["# Success S3: the review sheet for the experts (owner #115)", "",
		"Written by `tools/success_review_sheet.py` from the game's own data (`data/success/`): exactly what the game shows "
		"and reads aloud. Please tick each source once checked and mark each line: right / change it to ... / remove it. "
		"The coins are pretend market coins (never real money); the counters of the dice lesson are pretend too; fake "
		"reviews, untrue words and too-big claims appear only as wrong pictures, each with the coach's why. Each hands-on "
		"step names its real motion (owner #117).", "", "The values that change with each try are shown as {tokens}:", ""]
	for token, words in GLOSSARY_S3:
		lines.append("- `%s`: %s" % (token, words))
	lines.append("")
	lines += experiences(IDS_S3, REVIEWER_S3, True) + shop_and_market()
	return "\n".join(lines).rstrip() + "\n"


def goals():
	g = json.loads((DATA / "goals.json").read_text())
	lines = ["## The Goal Board and the habit garden (MY GOAL BOARD)", "",
		"Everything is picked from these lists: nothing is typed. A goal the game can measure says so (the child's gold "
		"against Mission Control's rocket plan, a flight, a universe opened, lessons mastered, Life stamps by myself); the "
		"others are the child's ticks. Habits count the days kept in all, never in a row; a missed day takes nothing away.",
		"", "Dreams, their goals and their steps:", ""]
	for d in g["dreams"]:
		lines.append("- **%s**: goals %s; steps %s" % (d["title"], " / ".join("\"%s\" (%s)" % (x["title"], x["measure"] or
			"the child's ticks") for x in d["goals"]), "; ".join(s["title"] for s in d["steps"])))
	for key, words in [("cues", "WHEN"), ("actions", "I WILL"), ("obstacles", "IF (the Big track)"),
			("responses", "THEN (the Big track)")]:
		lines.append("- %s: %s" % (words, "; ".join(x["title"] for x in g[key])))
	lines.append("- The Little track's ready plans: %s" % "; ".join("\"%s, %s.\"" % (
		next(c["title"] for c in g["cues"] if c["id"] == p["w"]), next(a["title"] for a in g["actions"] if a["id"] == p["a"]))
		for p in g["ready_plans"]))
	lines.append("- Habits: %s" % "; ".join(h["title"] for h in g["habits"]))
	return lines + [""]


def people():
	p = json.loads((DATA / "people.json").read_text())
	lines = ["## The Connections Book's people (the practice village; not real people)", ""]
	for x in p["people"]:
		extra = (" Different from many children: %s" % x["different"]) if x.get("different") else ""
		tip = (" Mentor's tip: \"%s\"" % x["tip"]) if x.get("tip") else ""
		lines.append("- **%s**, %s at %s. Wishes: %s. Needs: %s (helped by %s). Offers: %s.%s%s New chance: %s" % (x["name"],
			x["job"], x["place"], x["wish"], x["needs"], x["helped_by"], x["offers"], extra, tip, x["chance"]))
	return lines + [""]


def stories():
	s = json.loads((DATA / "stories.json").read_text())
	lines = ["## The twenty Success Stories, every fact with its source", "",
		"Real people of the past only (no living people's politics), many countries and jobs, no brands; each read aloud "
		"line by line, then \"Which skill did they use?\" (the right answer first here; the game mixes them).", ""]
	for x in s["stories"]:
		lines += ["### %s (%s), %s: %s" % (x["name"], x["life"], x["country"], x["title"]), ""]
		for i, l in enumerate(x["lines"], 1):
			lines.append("%d. %s" % (i, l))
		q = x["question"]
		lines += ["", "Question: \"%s\" %s" % (q["say"], " / ".join(("**%s**" if i == q["answer"] else "%s") % c["text"]
			for i, c in enumerate(q["choices"]))), "", "Sources:", ""]
		for src in x["sources"]:
			lines.append("- %s %s" % (src["fact"], src["url"]))
		lines.append("")
	return lines


def sheet():
	lines = ["# Success S2: the review sheet for the experts (owner #115)", "",
		"Written by `tools/success_review_sheet.py` from the game's own data (`data/success/`): exactly what the game shows "
		"and reads aloud. Please mark each line: right / change it to ... / remove it. The coins in Talk & Deal are pretend "
		"market coins (never the child's gold, never real money); the investors are friendly practice characters; the "
		"pressure trick (\"sign now, or the offer is gone for ever\") appears once, on the Big track's Expert try, to be "
		"spotted. Each hands-on step names its real motion (owner #117).", ""]
	lines += experiences() + goals() + people() + stories()
	return "\n".join(lines).rstrip() + "\n"


def main():
	sheets = [(OUT, sheet()), (OUT_S3, sheet_s3())]   # owner #115 (S3): S3's sheet too
	if "--check" in sys.argv:
		stale = [str(out) for out, text in sheets if not out.exists() or out.read_text() != text]
		if stale:
			print("success_review_sheet: %s out of date: run tools/success_review_sheet.py" % ", ".join(stale))
			return 1
		print("success_review_sheet: up to date")
		return 0
	for out, text in sheets:
		out.write_text(text)
		print("success_review_sheet: wrote %s (%d lines)" % (out, text.count("\n")))
	return 0


if __name__ == "__main__":
	sys.exit(main())
