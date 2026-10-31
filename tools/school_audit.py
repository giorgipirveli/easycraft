#!/usr/bin/env python3
"""The School's lesson-quality audit (owner #94: "lessons quality improvements up to grade 7").

Measures every written unit of the outline (data/school/grade<N>.json units that name their `file`) against the way
the research says a unit teaches (docs/design/school-curriculum-research.md §5.3) and prints a table per grade and the
weakest units, each with a score out of 100 and what cost it points.

    python3 tools/school_audit.py                       # grades 3-7: a table per grade, the 30 weakest units
    python3 tools/school_audit.py --grades 4 --units    # every unit of grade 4, one row each
    python3 tools/school_audit.py --unit g4.maths.angles  # one unit: every measure and every finding
    python3 tools/school_audit.py --weakest 60          # the 60 weakest
    python3 tools/school_audit.py --json out.json       # every unit's measures, for a later --compare
    python3 tools/school_audit.py --compare out.json    # before (the file) and now, per grade

What it measures, per unit (the points each costs are in PENALTY):
- cards: 4-8 lesson cards (the loader allows 2-8); words a card and long cards (over LONG_CARD words); sentences over
  LONG_SENTENCE words.
- reading level: the Flesch-Kincaid grade of the lesson's words (numbers read as one short word, symbols left out),
  against the School's grade + 1 (research §6.2: grade 3 is ages 8-9, US grade 3).
- pictures: teaching cards (not the memory card or the "in the world" card) without a picture, where a picture would
  teach (maths, science, geography, D&T, computing, art and music want one on half their teaching cards; the others
  on a third).
- the spiral: the first card a memory question ("Quick memory", "you met", "in grade N"), the last card "Try it in
  the world" or "Next".
- practice: hand-written exercises per level 1-3 (3 or more, or a generator at that level), kinds of exercise (2 at
  least, better 3 or more; choice and true-or-false under 80% of them), a hint and a worked answer on every one, hints
  that are only "…" or give the answer away, worked answers of a word or two, near-duplicate questions.
- generators (endless practice), sounds where listening is taught (music; English speaking and listening), and the
  facts' sources: the unit's name in the agents' notes (docs/devlog/parts/*.md).
- words to look at again: body-shape words outside health (research §5.4 rule 4 and the health units' kind words).
"""
import argparse
import difflib
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GRADES = [3, 4, 5, 6, 7]
LONG_CARD = 45          # words
LONG_SENTENCE = 22      # words
PICTURE_SUBJECTS = {"maths", "science", "geography", "design_tech", "computing", "art", "music"}
LISTEN_SUBJECTS = {"music"}
LISTEN_WORDS = re.compile(r"\b(listen|listening|hear|heard|pitch|rhythm|tune|melody|beat|pace|volume|pronounc\w*|"
                          r"read aloud|speaking)\b", re.I)
MEMORY = re.compile(r"^(quick memory|remember|memory)|\byou met\b|\bin grade \d\b|\blast (grade|year|unit)\b|"
                    r"\byou learned\b|\bgrade \d\b", re.I)
WORLD = re.compile(r"try it in the world|in the world:|in your world|\bnext\b|in the game|visit it", re.I)
BODY_WORDS = re.compile(r"\b(skinny|scrawny|chubby|plump|overweight|fatty(?! acids?)|slim|slender)\b", re.I)
# Round 3 (2026-10-01): the bar's variety rule (test_school_quality.gd's MAX_CHOICE_SHARE): at most this share of a
# unit's hand-written exercises are choice or true-or-false.
MAX_CHOICE_SHARE = 0.7
CHOOSING = ("choice", "truefalse")
# Round 3: level 3 steps up. A level's demand is the mean of its hand-written exercises' demand (`demand`); a unit
# whose level 3 is less than STEP_UP times its level 1 is "flat" (level 3 no harder than level 1, roughly).
STEP_UP = 1.1
PENALTY = {
    "no_memory": 10, "no_world": 8, "few_cards": 5, "long_card": 2, "long_card_cap": 8, "reading": 3,
    "reading_cap": 12, "picture": 4, "picture_cap": 16, "one_type": 16, "two_types": 7, "mostly_choice": 4,
    "thin_level": 4, "few_exercises": 5, "no_hint": 1, "weak_hint": 1, "hint_cap": 8, "gives_away": 2,
    "gives_away_cap": 6, "thin_explain": 1, "explain_cap": 6, "duplicate": 2, "duplicate_cap": 6, "no_sound": 8,
    "not_noted": 2, "body_words": 3, "long_sentence": 1, "long_sentence_cap": 4, "flat_levels": 3,
}


# --- Reading ----------------------------------------------------------------------------------------------------------

def syllables(word):
    w = word.lower().strip("'’")
    if not w:
        return 0
    if len(w) <= 3:
        return 1
    w = re.sub(r"(?:[^laeiouy]es|ed|[^laeiouy]e)$", "", w)
    w = re.sub(r"^y", "", w)
    groups = re.findall(r"[aeiouy]{1,2}", w)
    return max(1, len(groups))


def sentences_of(text):
    """Sentences as a reader hears them: split at . ! ? ; and at a colon that starts a new clause, and after a sentence
    that ends inside brackets or quotes ("(0°.) Today: …", "… said \\"Stop!\\" Then …")."""
    t = re.sub(r"(\d)[.,](\d)", r"\1\2", text)          # 2.5 and 1,000 stay one number
    t = re.sub(r"\b(e\.g|i\.e|etc|Mr|Mrs|Dr|St)\.", r"\1", t)
    parts = re.split(r"(?<=[.!?;:])\s+|(?<=[.!?][)\"”’'])\s+|…\s*", t)
    return [p for p in parts if re.search(r"[A-Za-z0-9]", p)]


def words_of(text):
    """Words as the quality bar counts them in hints and worked answers (tests/unit/test_school_quality.gd's)."""
    return re.findall(r"[A-Za-z][A-Za-z'’-]*|\d+", text)


def reader_words(text):
    """Words as a reader reads them, for a card's length and a sentence's: a number is one word (1,000, 2.5, 1440s,
    2nd), and so is a note or a name with digits (C4, H2O)."""
    return re.findall(r"[A-Za-z][A-Za-z'’-]*\d*|\d+(?:[.,]\d+)*[A-Za-z]*", text)


def reading_grade(texts):
    """Flesch-Kincaid grade of the texts together (numbers count as one-syllable words)."""
    n_words = n_sent = n_syl = 0
    for t in texts:
        for s in sentences_of(t):
            w = reader_words(s)
            if not w:
                continue
            n_sent += 1
            n_words += len(w)
            n_syl += sum(1 if x[0].isdigit() else syllables(x) for x in w)
    if n_words == 0 or n_sent == 0:
        return 0.0
    return 0.39 * n_words / n_sent + 11.8 * n_syl / n_words - 15.59


# --- A unit -----------------------------------------------------------------------------------------------------------

def notes_text():
    out = []
    for path in glob.glob(os.path.join(ROOT, "docs", "devlog", "parts", "*.md")):
        with open(path, encoding="utf-8") as f:
            out.append(f.read())
    return "\n".join(out)


def item_text(c):
    if isinstance(c, dict):
        return str(c.get("text", ""))
    return str(c)


def answer_texts(ex):
    """The answer as words, for 'does the hint give it away' (choice: the right choice; number: its digits)."""
    t = ex.get("type")
    if t == "choice" and isinstance(ex.get("choices"), list):
        i = ex.get("answer", -1)
        if isinstance(i, int) and 0 <= i < len(ex["choices"]):
            return [item_text(ex["choices"][i])]
    if t == "number":
        return [str(ex.get("answer", ""))]
    return []


def gives_away(ex):
    hint = str(ex.get("hint", "")).lower()
    prompt = str(ex.get("prompt", "")).lower()
    for a in answer_texts(ex):
        a = a.lower().strip(" .")
        if len(a) < 4 and not (ex.get("type") == "number" and len(a) >= 2):
            continue
        if ex.get("type") == "number":
            if re.search(r"(?<![\d.,/])" + re.escape(a) + r"(?![\d/]|\.\d)", hint) and a not in prompt:
                return True
        elif a in hint and a not in prompt:
            return True
    return False


def weak_hint(h):
    h = h.strip()
    return h.endswith("…") or h.endswith("...") or len(words_of(h)) < 3


def thin_explain(e):
    """A worked answer of a word or two ("Yes."), unless it is a worked sum ("60 ÷ 6 = 10.")."""
    return len(words_of(e)) < 4 and "=" not in e


def exercise_words(ex):
    parts = [str(ex.get("prompt", "")), json.dumps(ex.get("answer"), ensure_ascii=False)]
    parts += [item_text(c) for c in ex.get("choices", []) + ex.get("items", [])]
    return " ".join(parts).lower()


def mostly_choice(exercises):
    """More than MAX_CHOICE_SHARE of the hand-written exercises are choice or true-or-false (the bar's variety)."""
    if not exercises:
        return False
    return sum(1 for ex in exercises if ex.get("type") in CHOOSING) / len(exercises) > MAX_CHOICE_SHARE + 1e-6


def steps_of(explain):
    """The steps a worked answer shows: its sentences and its worked equalities ("= ")."""
    return len(sentences_of(explain)) + explain.count("=")


def numbers_of(text):
    return len(re.findall(r"\d+(?:[.,/]\d+)*", text))


def demand(ex):
    """How much an exercise asks, roughly (round 3's level check): the worked answer's words, numbers (×2) and steps
    (×3), half the question's words and its numbers, and 2 for every item past two in an order, sort, match or label."""
    e = str(ex.get("explain", ""))
    p = str(ex.get("prompt", ""))
    items = len(ex.get("items", [])) or len(ex.get("labels", []))
    return (len(reader_words(e)) + 2 * numbers_of(e) + 3 * steps_of(e) + len(reader_words(p)) / 2 + numbers_of(p)
            + 2 * max(0, items - 2))


def level_demand(exercises):
    """Each level's mean demand ([l1, l2, l3]; None where a level has no hand-written exercise)."""
    out = []
    for lv in (1, 2, 3):
        d = [demand(ex) for ex in exercises if int(ex.get("level", 1)) == lv]
        out.append(round(sum(d) / len(d), 1) if d else None)
    return out


def is_duplicate(a, b):
    """The same kind of question asked twice: the same picture, sound or board, and the words (prompt, answer,
    choices) 92% alike."""
    for key in ("type", "picture", "sound", "board", "target", "grid", "spots", "goal"):
        if a.get(key) != b.get(key):
            return False
    return difflib.SequenceMatcher(None, exercise_words(a), exercise_words(b)).ratio() >= 0.92


def measure(grade, subject, unit, content, notes):
    lesson = content.get("lesson", [])
    exercises = content.get("exercises", [])
    generators = content.get("generators", [])
    texts = [str(c.get("text", "")) for c in lesson]
    words = [len(reader_words(t)) for t in texts]
    m = {"id": unit["id"], "title": unit.get("title", ""), "grade": grade, "subject": subject,
         "cards": len(lesson), "words_card": round(sum(words) / max(1, len(words)), 1),
         "long_cards": sum(1 for w in words if w > LONG_CARD),
         "long_sentences": sum(1 for t in texts for s in sentences_of(t) if len(reader_words(s)) > LONG_SENTENCE),
         "reading": round(reading_grade(texts), 1)}
    m["memory"] = bool(lesson) and bool(MEMORY.search(texts[0]))
    m["world"] = bool(lesson) and bool(WORLD.search(texts[-1]))
    teaching = list(range(len(lesson)))
    if m["memory"] and teaching:
        teaching = teaching[1:]
    if m["world"] and teaching:
        teaching = teaching[:-1]
    pictured = sum(1 for i in range(len(lesson)) if "picture" in lesson[i])
    pictured_teaching = sum(1 for i in teaching if "picture" in lesson[i])
    share = 0.5 if subject in PICTURE_SUBJECTS else 1.0 / 3.0
    wanted = int(len(teaching) * share + 0.5)
    m["pictured"] = pictured
    m["pictures_missing"] = max(0, wanted - pictured_teaching)
    m["exercises"] = len(exercises)
    levels = {1: 0, 2: 0, 3: 0}
    types = {}
    for ex in exercises:
        levels[int(ex.get("level", 1))] = levels.get(int(ex.get("level", 1)), 0) + 1
        types[ex.get("type", "?")] = types.get(ex.get("type", "?"), 0) + 1
    gen_levels = {int(g.get("level", 1)) for g in generators}
    m["levels"] = [levels[1], levels[2], levels[3]]
    m["thin_levels"] = sum(1 for lv in (1, 2, 3) if levels[lv] < 3 and lv not in gen_levels)
    m["types"] = sorted(types)
    m["n_types"] = len(types)
    m["choice_share"] = round((types.get("choice", 0) + types.get("truefalse", 0)) / max(1, len(exercises)), 2)
    m["mostly_choice"] = mostly_choice(exercises)
    m["demand"] = level_demand(exercises)
    d1, d3 = m["demand"][0], m["demand"][2]
    m["step_up"] = round(d3 / d1, 2) if d1 and d3 is not None else None
    m["flat"] = m["step_up"] is not None and m["step_up"] < STEP_UP
    m["generators"] = len(generators)
    m["no_hint"] = sum(1 for ex in exercises if not str(ex.get("hint", "")).strip())
    m["weak_hints"] = sum(1 for ex in exercises if str(ex.get("hint", "")).strip() and weak_hint(str(ex["hint"])))
    m["gives_away"] = sum(1 for ex in exercises if gives_away(ex))
    m["thin_explain"] = sum(1 for ex in exercises if thin_explain(str(ex.get("explain", ""))))
    dups = 0
    for i in range(len(exercises)):
        for j in range(i + 1, len(exercises)):
            if is_duplicate(exercises[i], exercises[j]):
                dups += 1
    m["duplicates"] = dups
    has_sound = any("sound" in c for c in lesson) or any("sound" in ex for ex in exercises)
    listens = subject in LISTEN_SUBJECTS or (subject == "english" and re.search(
        r"speak|listen|present|poem|poetry", unit["id"] + " " + unit.get("title", ""), re.I))
    m["sound"] = has_sound
    m["needs_sound"] = bool(listens) and not has_sound
    short = unit["id"].split(".")[-1]
    m["noted"] = short in notes or unit.get("title", "") in notes
    all_words = " ".join(texts + [str(ex.get(k, "")) for ex in exercises for k in ("prompt", "hint", "explain")]
                         + [item_text(c) for ex in exercises for c in ex.get("choices", []) + ex.get("items", [])])
    m["body_words"] = sorted({w.lower() for w in BODY_WORDS.findall(all_words)}) if subject != "health_pe" else []
    m["bar"] = bar_problems(subject, content)
    return score(m)


# --- The quality bar (tests/unit/test_school_quality.gd checks the same rules) -----------------------------------------

def bar_problems(subject, content):
    """What keeps a unit under the quality bar ([] when it meets it). The GDScript test is the authority."""
    lesson = content.get("lesson", [])
    exercises = content.get("exercises", [])
    generators = content.get("generators", [])
    out = []
    first = str(lesson[0].get("text", "")) if lesson else ""
    last = str(lesson[-1].get("text", "")).lower() if lesson else ""
    if not (first.startswith("Quick memory:") or first.startswith("Remember?")):
        out.append("memory")
    if not ("try it in the world" in last or re.search(r"\bnext\b", last)):
        out.append("world")
    if not 4 <= len(lesson) <= 8:
        out.append("cards")
    if sum(1 for c in lesson if "picture" in c) < (2 if subject in PICTURE_SUBJECTS else 1):
        out.append("pictures")
    if len({ex.get("type") for ex in exercises}) < 3:
        out.append("kinds")
    if mostly_choice(exercises):
        out.append("variety")
    gen_levels = {int(g.get("level", 1)) for g in generators}
    for lv in (1, 2, 3):
        if sum(1 for ex in exercises if int(ex.get("level", 1)) == lv) < 3 and lv not in gen_levels:
            out.append("levels")
            break
    if any(weak_hint(str(ex.get("hint", ""))) for ex in exercises):
        out.append("hints")
    if any(thin_explain(str(ex.get("explain", ""))) for ex in exercises):
        out.append("explains")
    if any(ex.get("type") == "choice" and gives_away(ex) for ex in exercises):
        out.append("gives")
    if subject != "health_pe" and any(BODY_WORDS.search(t) for t in all_texts(content)):
        out.append("body")
    return out


def all_texts(content):
    out = [str(c.get("text", "")) for c in content.get("lesson", [])]
    for ex in content.get("exercises", []):
        out += [str(ex.get(k, "")) for k in ("prompt", "hint", "explain")]
        out += [item_text(c) for c in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", [])
                + ex.get("groups", []) + ex.get("labels", [])]
    return out


def score(m):
    P = PENALTY
    found = []

    def cost(points, why):
        if points > 0:
            found.append((points, why))

    cost(P["no_memory"] * (not m["memory"]), "no memory question first")
    cost(P["no_world"] * (not m["world"]), "no 'try it in the world' or 'next' last")
    cost(P["few_cards"] * max(0, 4 - m["cards"]), "%d cards" % m["cards"])
    cost(min(P["long_card_cap"], P["long_card"] * m["long_cards"]), "%d long cards" % m["long_cards"])
    cost(min(P["long_sentence_cap"], P["long_sentence"] * m["long_sentences"]),
         "%d long sentences" % m["long_sentences"])
    over = m["reading"] - (m["grade"] + 1)
    cost(min(P["reading_cap"], int(round(P["reading"] * max(0.0, over)))), "reading level %.1f" % m["reading"])
    cost(min(P["picture_cap"], P["picture"] * m["pictures_missing"]), "%d pictures missing" % m["pictures_missing"])
    if m["n_types"] <= 1:
        cost(P["one_type"], "one kind of exercise")
    elif m["n_types"] == 2:
        cost(P["two_types"], "two kinds of exercise")
    cost(P["mostly_choice"] * m["mostly_choice"], "%d%% choice or true/false" % (m["choice_share"] * 100))
    cost(P["flat_levels"] * m["flat"], "level 3 no harder than level 1 (demand %s)" % "/".join(
        "-" if d is None else str(d) for d in m["demand"]))
    cost(P["thin_level"] * m["thin_levels"], "%d thin levels %s" % (m["thin_levels"], m["levels"]))
    cost(P["few_exercises"] * (m["exercises"] < 12 and m["generators"] == 0), "%d exercises" % m["exercises"])
    cost(min(P["hint_cap"], P["no_hint"] * m["no_hint"] + P["weak_hint"] * m["weak_hints"]),
         "%d hints missing or weak" % (m["no_hint"] + m["weak_hints"]))
    cost(min(P["gives_away_cap"], P["gives_away"] * m["gives_away"]), "%d hints give the answer" % m["gives_away"])
    cost(min(P["explain_cap"], P["thin_explain"] * m["thin_explain"]), "%d thin worked answers" % m["thin_explain"])
    cost(min(P["duplicate_cap"], P["duplicate"] * m["duplicates"]), "%d near-duplicates" % m["duplicates"])
    cost(P["no_sound"] * m["needs_sound"], "listening taught without a sound")
    cost(P["not_noted"] * (not m["noted"]), "not in the notes")
    cost(P["body_words"] * bool(m["body_words"]), "body words: %s" % ", ".join(m["body_words"]))
    m["score"] = max(0, 100 - sum(p for p, _ in found))
    m["findings"] = [why for _, why in sorted(found, key=lambda x: -x[0])]
    return m


# --- Quick checks (the content tests' rules that need no Godot; the tests stay the authority) --------------------------

ALLOWED = set("×÷−°²³½¼¾•’“”—…√≤≥π·⁰¹⁴⁵⁶⁷⁸⁹ëçèéü")
US_SPELLINGS = ["color", "colors", "colored", "center", "centers", "meter", "meters", "centimeter", "centimeters",
                "kilometer", "kilometers", "liter", "liters", "milliliter", "milliliters", "favorite", "gray",
                "neighbor", "neighbors", "math", "behavior", "flavor", "honor", "organize", "realize", "trapezoid"]
UNKIND = ["miss you", "don't go", "lonely", "last chance", "hurry", "only today", "you failed", "failure", "loser",
          "for babies", "noob", "streak", "wrong!", "stupid", "dumb", "idiot", "lazy", "you lose", "minecraft",
          "roblox", "creeper", "enderman", "nether", "redstone", "steve", "robux", "fortnite", "pokemon", "mario"]
NUM = r"(?<![\d/.,])(\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?)(?![\d/])"
SUM = re.compile(NUM + r"\s*([+−×÷-])\s*" + NUM + r"\s*=\s*" + NUM)


def sums_wrong(t):
    """test_the_sums_in_the_lessons_are_right's check: every plain "a op b = c" is right (its exceptions kept)."""
    out = []
    for m in SUM.finditer(t):
        before = t[:m.start()].strip()
        after = t[m.end():m.end() + 24].strip()
        dot = max(t.rfind(".", 0, m.start()), 0)
        sentence = t[dot:m.end() + 40]
        if before.endswith(("+", "−", "×", "÷", "(")) or after.startswith(("+", "−", "×", "÷", "remainder", "r ",
                "%", "tens", "hundreds", "1/", "2/", "3/")) or (m.group(2) == "÷" and "left" in after) \
                or "says" in sentence or "?" in sentence:
            continue
        a, b, c = (float(m.group(i).replace(",", "")) for i in (1, 3, 4))
        op = m.group(2)
        r = a + b if op == "+" else a - b if op in "−-" else a * b if op == "×" else (a / b if b else float("inf"))
        if abs(r - c) > 0.0001:
            out.append(m.group(0))
    return out


def check_exercise(ex, where):
    out = []
    t = ex.get("type")
    for key, most in (("prompt", 180), ("hint", 200), ("explain", 260)):
        if len(str(ex.get(key, ""))) > most:
            out.append("%s: its %s has %d letters (at most %d)" % (where, key, len(str(ex[key])), most))
    if not str(ex.get("hint", "")).strip():
        out.append("%s: no hint" % where)
    if ex.get("level") not in (1, 2, 3):
        out.append("%s: level %s" % (where, ex.get("level")))
    if t == "choice":
        ch = ex.get("choices", [])
        texts = [item_text(c) for c in ch]
        keys = [item_text(c) + json.dumps(c.get("picture", {}), sort_keys=True) if isinstance(c, dict) else str(c)
                for c in ch]
        if not 2 <= len(ch) <= 6 or len(set(keys)) != len(keys) or any(len(x) > 48 for x in texts):
            out.append("%s: 2-6 different choices of 48 letters" % where)
        if not isinstance(ex.get("answer"), int) or not 0 <= ex["answer"] < len(ch):
            out.append("%s: the answer is a choice's index" % where)
    elif t == "truefalse":
        if not isinstance(ex.get("answer"), bool):
            out.append("%s: true or false" % where)
    elif t == "order":
        items, ans = ex.get("items", []), ex.get("answer", [])
        if not 2 <= len(items) <= 6 or sorted(ans) != list(range(len(items))) or ans == list(range(len(items))):
            out.append("%s: 2-6 items, each once, never already in order" % where)
        if any(len(item_text(x)) > 48 for x in items):
            out.append("%s: an item over 48 letters" % where)
    elif t == "sort":
        g, items, ans = ex.get("groups", []), ex.get("items", []), ex.get("answer", [])
        if not 2 <= len(g) <= 3 or any(len(x) > 24 for x in g) or not 2 <= len(items) <= 6 \
                or len(ans) != len(items) or len(set(ans)) < 2 or any(not 0 <= a < len(g) for a in ans):
            out.append("%s: 2-3 groups of 24 letters, 2-6 items, two groups used" % where)
        if any(len(item_text(x)) > 48 for x in items):
            out.append("%s: an item over 48 letters" % where)
    elif t == "match":
        items, matches, ans = ex.get("items", []), ex.get("matches", []), ex.get("answer", [])
        if not 2 <= len(items) <= 5 or len(matches) != len(items) or sorted(ans) != list(range(len(items))) \
                or ans == list(range(len(items))):
            out.append("%s: 2-5 pairs, each match once, never already side by side" % where)
        if any(len(item_text(x)) > 32 for x in items + matches):
            out.append("%s: a side over 32 letters" % where)
    elif t == "number":
        if not re.fullmatch(r"-?[\d,]*\.?\d+(/\d+)?", str(ex.get("answer", ""))):
            out.append("%s: the answer is a number as text" % where)
    return out


def check(grades):
    problems = []
    for g in grades:
        for path in sorted(glob.glob(os.path.join(ROOT, "data", "school", "g%d" % g, "*", "*.json"))):
            with open(path, encoding="utf-8") as f:
                content = json.load(f)
            uid = content.get("id", path)
            lesson = content.get("lesson", [])
            if not 2 <= len(lesson) <= 8:
                problems.append("%s: %d cards" % (uid, len(lesson)))
            for i, c in enumerate(lesson):
                if len(str(c.get("text", ""))) > 260:
                    problems.append("%s card %d: %d letters" % (uid, i, len(c["text"])))
            for i, ex in enumerate(content.get("exercises", [])):
                problems += check_exercise(ex, "%s#%d" % (uid, i))
            texts = all_texts(content)
            sum_texts = [str(c.get("text", "")) for c in lesson]
            for ex in content.get("exercises", []):
                if not (ex.get("type") == "truefalse" and ex.get("answer") is False):
                    sum_texts.append(str(ex.get("prompt", "")))
                sum_texts += [str(ex.get("hint", "")), str(ex.get("explain", ""))]
            for t in sum_texts:
                for w in sums_wrong(t):
                    problems.append("%s: a wrong sum %s" % (uid, w))
            for t in texts:
                low = t.lower()
                for ch in t:
                    if ord(ch) > 127 and ch not in ALLOWED:
                        problems.append("%s: the letter '%s' in: %s" % (uid, ch, t))
                        break
                for w in US_SPELLINGS + UNKIND:
                    if re.search(r"\b" + re.escape(w) + r"\b", low):
                        problems.append("%s: '%s' in: %s" % (uid, w, t))
    return problems


def in_scope(u):
    """Grades 3-6 every subject; grade 7 only its subjects written before the owner's pause (#94)."""
    return u["grade"] < 7 or u["subject"] in GRADE7_SUBJECTS


GRADE7_SUBJECTS = ["maths", "science", "english", "history", "geography", "citizenship", "computing", "art", "music",
                   "health_pe", "design_tech", "projects"]


# --- The School -------------------------------------------------------------------------------------------------------

def audit(grades):
    notes = notes_text()
    out = []
    for g in grades:
        path = os.path.join(ROOT, "data", "school", "grade%d.json" % g)
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            outline = json.load(f)
        for subject in outline["subjects"]:
            for unit in subject["units"]:
                if not unit.get("file"):
                    continue
                with open(os.path.join(ROOT, "data", "school", unit["file"]), encoding="utf-8") as f:
                    content = json.load(f)
                out.append(measure(g, subject["id"], unit, content, notes))
    return out


def summary(units):
    n = max(1, len(units))
    return {
        "units": len(units),
        "score": round(sum(u["score"] for u in units) / n, 1),
        "min": min((u["score"] for u in units), default=0),
        "under70": sum(1 for u in units if u["score"] < 70),
        "under_bar": sum(1 for u in units if u.get("bar")),
        "cards": sum(u["cards"] for u in units),
        "words_card": round(sum(u["words_card"] for u in units) / n, 1),
        "reading": round(sum(u["reading"] for u in units) / n, 1),
        "pictured": round(100 * sum(u["pictured"] for u in units) / max(1, sum(u["cards"] for u in units))),
        "memory": round(100 * sum(u["memory"] for u in units) / n),
        "world": round(100 * sum(u["world"] for u in units) / n),
        "types": round(sum(u["n_types"] for u in units) / n, 1),
        "choice": round(100 * sum(u["choice_share"] for u in units) / n),
        "mostly_choice": sum(1 for u in units if u.get("mostly_choice", u["choice_share"] > MAX_CHOICE_SHARE)),
        "flat": sum(1 for u in units if u.get("flat")),
        "step_up": round(sum(u["step_up"] for u in units if u.get("step_up") is not None)
                         / max(1, sum(1 for u in units if u.get("step_up") is not None)), 2),
        "exercises": sum(u["exercises"] for u in units),
        "generators": sum(u["generators"] for u in units),
        "weak_hints": sum(u["weak_hints"] + u["no_hint"] for u in units),
        "gives_away": sum(u["gives_away"] for u in units),
        "duplicates": sum(u["duplicates"] for u in units),
    }


COLUMNS = [("units", "units"), ("score", "score"), ("min", "min"), ("under70", "<70"), ("under_bar", "<bar"), ("cards", "cards"),
           ("words_card", "w/card"), ("reading", "FK"), ("pictured", "pic%"), ("memory", "mem%"), ("world", "world%"),
           ("types", "kinds"), ("choice", "ch/tf%"), ("mostly_choice", ">70%"), ("step_up", "L3/L1"),
           ("flat", "flat"), ("exercises", "ex"), ("generators", "gens"),
           ("weak_hints", "weak h"), ("gives_away", "gives"), ("duplicates", "dups")]


def table(rows, first):
    head = "| %s | %s |" % (first, " | ".join(c[1] for c in COLUMNS))
    lines = [head, "|" + "---|" * (len(COLUMNS) + 1)]
    for name, s in rows:
        lines.append("| %s | %s |" % (name, " | ".join(str(s[c[0]]) for c in COLUMNS)))
    return "\n".join(lines)


def grade_tables(units, grades):
    out = []
    for g in grades:
        mine = [u for u in units if u["grade"] == g]
        if not mine:
            continue
        subjects = []
        for u in mine:
            if u["subject"] not in subjects:
                subjects.append(u["subject"])
        rows = [(s, summary([u for u in mine if u["subject"] == s])) for s in subjects]
        rows.append(("**all**", summary(mine)))
        out.append("### Grade %d\n\n%s\n" % (g, table(rows, "subject")))
    return "\n".join(out)


def unit_rows(units):
    lines = ["| unit | score | cards | w/card | FK | pics | mem | world | kinds | levels | ex | gens | findings |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for u in units:
        lines.append("| %s | %d | %d | %s | %s | %d | %s | %s | %d | %s | %d | %d | %s |" % (
            u["id"], u["score"], u["cards"], u["words_card"], u["reading"], u["pictured"], "y" if u["memory"] else "-",
            "y" if u["world"] else "-", u["n_types"], "/".join(str(x) for x in u["levels"]), u["exercises"],
            u["generators"], "; ".join(u["findings"][:4])))
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--grades", type=int, nargs="*", default=GRADES)
    ap.add_argument("--units", action="store_true", help="every unit's row")
    ap.add_argument("--unit", help="one unit's measures and findings")
    ap.add_argument("--weakest", type=int, default=30)
    ap.add_argument("--json", help="write every unit's measures here")
    ap.add_argument("--compare", help="a --json file from before: print before and now per grade")
    ap.add_argument("--not-yet", action="store_true",
                    help="the units under the quality bar, for the test's NOT_YET and NOT_YET_VARIED")
    ap.add_argument("--flat", action="store_true", help="the units whose level 3 is no harder than level 1")
    ap.add_argument("--check", action="store_true", help="quick checks of the words' sizes, letters and sums")
    a = ap.parse_args()
    if a.check:
        problems = check(a.grades)
        print("\n".join(problems) if problems else "no problems found")
        sys.exit(1 if problems else 0)
    units = audit(a.grades)
    if a.not_yet:
        scope = [u for u in units if in_scope(u)]
        ids = sorted(u["id"] for u in scope if [b for b in u["bar"] if b != "variety"])
        varied = sorted(u["id"] for u in scope if u["bar"] == ["variety"])
        print("%d of %d units under the bar; %d more only for variety" % (len(ids), len(scope), len(varied)),
              file=sys.stderr)
        print("NOT_YET:\n" + "\n".join('\t"%s",' % i for i in ids))
        print("NOT_YET_VARIED:\n" + "\n".join('\t"%s",' % i for i in varied))
        return
    if a.flat:
        flat = sorted((u for u in units if u["flat"]), key=lambda u: (u["step_up"], u["id"]))
        print("%d units whose level 3 asks less than %.1f × level 1 (demand per level: 1/2/3)" % (len(flat), STEP_UP))
        for u in flat:
            print("%s\t%.2f\t%s" % (u["id"], u["step_up"], "/".join("-" if d is None else str(d) for d in u["demand"])))
        return
    if a.unit:
        for u in units:
            if u["id"] == a.unit:
                print(json.dumps(u, indent=1, ensure_ascii=False))
                return
        sys.exit("no written unit %s" % a.unit)
    if a.json:
        with open(a.json, "w", encoding="utf-8") as f:
            json.dump(units, f, indent=0, ensure_ascii=False)
    if a.compare:
        with open(a.compare, encoding="utf-8") as f:
            before = json.load(f)
        rows = []
        for g in a.grades:
            b = [u for u in before if u["grade"] == g]
            n = [u for u in units if u["grade"] == g]
            if n:
                rows.append(("%d before" % g, summary(b)))
                rows.append(("%d now" % g, summary(n)))
        rows.append(("all before", summary([u for u in before if u["grade"] in a.grades])))
        rows.append(("all now", summary(units)))
        print(table(rows, "grade"))
        was = {u["id"]: u["score"] for u in before}
        moved = sorted(((u["score"] - was.get(u["id"], u["score"]), u["id"]) for u in units), reverse=True)
        print("\n%d units scored higher, %d lower" % (sum(1 for d, _ in moved if d > 0), sum(1 for d, _ in moved if d < 0)))
        for d, i in [x for x in moved if x[0] < 0]:
            print("  lower: %s %+d" % (i, d))
        return
    print(grade_tables(units, a.grades))
    if a.units:
        print(unit_rows(units))
        print()
    weakest = sorted(units, key=lambda u: (u["score"], u["id"]))[:a.weakest]
    print("### The %d weakest units\n" % len(weakest))
    print(unit_rows(weakest))


if __name__ == "__main__":
    main()
