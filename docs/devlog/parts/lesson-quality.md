# The School's lessons, better (owner #94: "lessons quality improvements up to grade 7")

Brief: `docs/superpowers/plans/2026-09-30-lesson-quality-brief.md`. Branch `worktree-agent-ab5121f816030a927`, cut from
`lead-merge` at 870c8ede. Scope: grades 3-6 (every subject, 546 units) and grade 7's written maths, science, English,
computing, art and music (68 units). Grade 7's history, geography and citizenship are left to their own branch; no unit
is added, no id or generator changes.

## The audit tool: `tools/school_audit.py`

```bash
python3 tools/school_audit.py                         # a table per grade, the 30 weakest units
python3 tools/school_audit.py --grades 4 --units      # every unit of grade 4
python3 tools/school_audit.py --unit g4.maths.angles  # one unit's measures and findings
python3 tools/school_audit.py --json before.json      # every unit's measures; later: --compare before.json
python3 tools/school_audit.py --check                 # the content tests' rules that need no Godot (sizes, letters, sums)
python3 tools/school_audit.py --not-yet               # the units under the quality bar (the test's NOT_YET)
```

Per unit it measures (research §5.3): cards (4-8), words a card, long cards (over 45 words) and long sentences (over
22), the reading level (Flesch-Kincaid on the lesson's words, numbers read as one short word) against the grade + 1,
teaching cards without a picture where a picture would teach (half of them in maths, science, geography, D&T,
computing, art and music; a third elsewhere), the memory question first and "Try it in the world" / "Next" last,
hand-written exercises per level and their kinds, the share of choice and true-or-false, hints (missing, only "…", or
saying the right choice), worked answers of a word or two, near-duplicate questions, generators, sounds where listening
is taught, the unit in the agents' notes (where its facts' sources are), and body-shape words outside health. Each
finding costs points (`PENALTY`); the score is out of 100.

**The quality bar** (`tests/unit/test_school_quality.gd`, the same rules as the audit's `bar_problems`): a memory
question first ("Quick memory:" or "Remember?"), "Try it in the world" or "Next" last, 4-8 cards, a lesson picture (two
in the drawing subjects), three kinds of exercise, three hand-written exercises or a generator at every level, every
hint a strategy (three words or more, never only "…"), every worked answer four words or a worked sum, no hint that says
the right choice, no body-shape words outside health. The units under it are `NOT_YET`, a list that only shrinks: a
round takes its units out first (the test fails for them), then rewrites them.

## The first audit (2026-09-30, before any change)

Columns: units, mean score, lowest, units under 70, units under the bar, cards, words a card, reading grade (FK),
pictured cards %, memory first %, world or next last %, kinds of exercise (mean), choice and true-or-false %,
hand-written exercises, generators, weak or missing hints, hints that give the answer, near-duplicates.

### Grade 3

| subject | units | score | min | <70 | <bar | cards | w/card | FK | pic% | mem% | world% | kinds | ch/tf% | ex | gens | weak h | gives | dups |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| maths | 18 | 99.1 | 92 | 0 | 3 | 120 | 28.7 | 1.1 | 91 | 100 | 100 | 3.9 | 35 | 329 | 289 | 9 | 1 | 0 |
| science | 18 | 83.8 | 75 | 0 | 17 | 126 | 29.2 | 3.3 | 42 | 100 | 11 | 4.6 | 82 | 289 | 66 | 6 | 1 | 0 |
| english | 18 | 79.9 | 71 | 0 | 18 | 113 | 27.4 | 2.4 | 11 | 100 | 0 | 3.9 | 85 | 287 | 39 | 7 | 1 | 0 |
| history | 10 | 91.2 | 84 | 0 | 3 | 77 | 30.5 | 3.8 | 14 | 100 | 100 | 3.8 | 83 | 138 | 9 | 0 | 0 | 0 |
| geography | 10 | 88.4 | 80 | 0 | 6 | 76 | 29.0 | 3.5 | 18 | 100 | 100 | 4.4 | 80 | 145 | 9 | 1 | 1 | 1 |
| citizenship | 11 | 85.9 | 78 | 0 | 10 | 88 | 27.6 | 3.3 | 2 | 100 | 100 | 3.6 | 89 | 154 | 9 | 0 | 1 | 0 |
| computing | 11 | 88.9 | 83 | 0 | 9 | 83 | 24.8 | 3.1 | 10 | 100 | 100 | 5.1 | 65 | 169 | 11 | 1 | 1 | 0 |
| art | 9 | 89.8 | 85 | 0 | 6 | 71 | 23.5 | 2.8 | 18 | 100 | 100 | 5.2 | 74 | 149 | 9 | 0 | 0 | 0 |
| music | 9 | 87.2 | 82 | 0 | 7 | 72 | 21.4 | 2.3 | 14 | 100 | 100 | 4.0 | 78 | 153 | 21 | 0 | 0 | 0 |
| health_pe | 11 | 93.0 | 88 | 0 | 4 | 86 | 30.3 | 2.9 | 13 | 100 | 100 | 5.1 | 74 | 163 | 11 | 0 | 0 | 0 |
| design_tech | 9 | 90.6 | 85 | 0 | 6 | 72 | 27.9 | 2.8 | 15 | 100 | 100 | 5.0 | 75 | 130 | 8 | 0 | 0 | 0 |
| projects | 3 | 94.3 | 90 | 0 | 1 | 23 | 31.7 | 2.1 | 13 | 100 | 100 | 6.3 | 57 | 42 | 11 | 0 | 0 | 0 |
| **all** | 137 | 88.8 | 71 | 0 | 90 | 1007 | 27.7 | 2.7 | 26 | 100 | 75 | 4.4 | 73 | 2148 | 492 | 24 | 6 | 1 |

### Grade 4

| subject | units | score | min | <70 | <bar | cards | w/card | FK | pic% | mem% | world% | kinds | ch/tf% | ex | gens | weak h | gives | dups |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| maths | 18 | 79.8 | 72 | 0 | 17 | 79 | 25.8 | 2.0 | 53 | 6 | 6 | 3.6 | 42 | 162 | 235 | 1 | 0 | 0 |
| science | 18 | 82.1 | 61 | 1 | 14 | 128 | 32.3 | 3.6 | 49 | 28 | 61 | 4.1 | 83 | 294 | 112 | 2 | 0 | 0 |
| english | 18 | 71.6 | 50 | 7 | 17 | 99 | 25.3 | 3.0 | 6 | 28 | 28 | 3.1 | 92 | 280 | 15 | 19 | 1 | 0 |
| history | 10 | 93.5 | 87 | 0 | 4 | 80 | 36.3 | 4.3 | 19 | 100 | 100 | 5.3 | 70 | 148 | 15 | 5 | 0 | 0 |
| geography | 10 | 89.1 | 84 | 0 | 8 | 80 | 34.9 | 4.3 | 15 | 100 | 100 | 5.5 | 67 | 141 | 18 | 1 | 0 | 0 |
| citizenship | 11 | 91.2 | 85 | 0 | 6 | 88 | 34.0 | 2.8 | 7 | 100 | 100 | 4.9 | 73 | 154 | 15 | 2 | 0 | 0 |
| computing | 11 | 91.6 | 84 | 0 | 5 | 88 | 30.5 | 2.6 | 20 | 100 | 100 | 5.5 | 61 | 163 | 15 | 0 | 0 | 0 |
| art | 9 | 95.8 | 85 | 0 | 2 | 72 | 29.9 | 3.5 | 35 | 100 | 100 | 6.1 | 61 | 137 | 18 | 0 | 0 | 0 |
| music | 9 | 93.0 | 78 | 0 | 4 | 72 | 28.2 | 2.7 | 35 | 100 | 100 | 5.7 | 63 | 153 | 22 | 1 | 0 | 0 |
| health_pe | 11 | 93.5 | 87 | 0 | 2 | 88 | 34.1 | 2.9 | 14 | 100 | 100 | 5.6 | 71 | 169 | 23 | 0 | 0 | 0 |
| design_tech | 9 | 89.3 | 82 | 0 | 7 | 72 | 32.3 | 3.3 | 14 | 100 | 100 | 5.4 | 70 | 135 | 30 | 0 | 1 | 0 |
| projects | 3 | 93.0 | 87 | 0 | 1 | 24 | 33.0 | 3.0 | 12 | 100 | 100 | 6.7 | 60 | 45 | 10 | 0 | 0 | 0 |
| **all** | 137 | 86.5 | 50 | 8 | 87 | 970 | 30.7 | 3.1 | 24 | 69 | 73 | 4.8 | 69 | 1981 | 528 | 31 | 2 | 0 |

### Grade 5

| subject | units | score | min | <70 | <bar | cards | w/card | FK | pic% | mem% | world% | kinds | ch/tf% | ex | gens | weak h | gives | dups |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| maths | 18 | 79.8 | 66 | 2 | 16 | 89 | 28.3 | 1.7 | 56 | 11 | 17 | 3.6 | 47 | 184 | 273 | 3 | 1 | 1 |
| science | 17 | 71.4 | 55 | 13 | 13 | 91 | 24.7 | 4.1 | 21 | 24 | 24 | 3.5 | 89 | 267 | 39 | 13 | 1 | 0 |
| english | 18 | 72.6 | 59 | 11 | 17 | 97 | 26.3 | 3.3 | 2 | 33 | 39 | 2.9 | 92 | 281 | 27 | 30 | 2 | 0 |
| history | 10 | 89.7 | 84 | 0 | 7 | 80 | 39.3 | 4.8 | 8 | 100 | 100 | 5.6 | 68 | 152 | 15 | 0 | 1 | 0 |
| geography | 10 | 89.7 | 84 | 0 | 9 | 80 | 37.4 | 4.4 | 16 | 100 | 100 | 4.8 | 74 | 150 | 21 | 1 | 1 | 0 |
| citizenship | 11 | 89.2 | 85 | 0 | 10 | 88 | 36.6 | 3.5 | 2 | 100 | 100 | 4.5 | 77 | 165 | 15 | 1 | 1 | 0 |
| computing | 11 | 95.0 | 88 | 0 | 3 | 88 | 30.2 | 3.1 | 32 | 100 | 100 | 5.2 | 55 | 157 | 30 | 1 | 0 | 0 |
| art | 9 | 97.6 | 95 | 0 | 1 | 72 | 30.6 | 3.5 | 49 | 100 | 100 | 5.6 | 69 | 127 | 15 | 1 | 0 | 0 |
| music | 9 | 96.0 | 90 | 0 | 2 | 72 | 29.5 | 2.6 | 42 | 100 | 100 | 5.3 | 59 | 144 | 31 | 0 | 0 | 0 |
| health_pe | 11 | 93.1 | 87 | 0 | 6 | 88 | 34.5 | 3.6 | 15 | 100 | 100 | 5.6 | 71 | 179 | 42 | 2 | 0 | 0 |
| design_tech | 9 | 92.1 | 84 | 0 | 4 | 72 | 32.9 | 3.5 | 28 | 100 | 100 | 6.0 | 66 | 144 | 51 | 0 | 0 | 0 |
| projects | 3 | 93.3 | 90 | 0 | 0 | 24 | 35.0 | 3.5 | 17 | 100 | 100 | 6.7 | 56 | 48 | 12 | 0 | 0 | 0 |
| **all** | 136 | 85.7 | 55 | 26 | 88 | 941 | 31.1 | 3.4 | 24 | 70 | 71 | 4.6 | 70 | 1998 | 571 | 52 | 7 | 1 |

### Grade 6

| subject | units | score | min | <70 | <bar | cards | w/card | FK | pic% | mem% | world% | kinds | ch/tf% | ex | gens | weak h | gives | dups |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| maths | 18 | 71.6 | 57 | 5 | 17 | 76 | 22.1 | 2.5 | 7 | 6 | 6 | 3.1 | 47 | 154 | 117 | 15 | 2 | 2 |
| science | 17 | 73.9 | 55 | 11 | 12 | 97 | 27.2 | 5.1 | 25 | 35 | 35 | 3.9 | 84 | 273 | 63 | 34 | 0 | 0 |
| english | 18 | 73.7 | 52 | 10 | 12 | 98 | 24.9 | 3.9 | 10 | 33 | 33 | 3.3 | 91 | 288 | 48 | 47 | 0 | 0 |
| history | 10 | 89.6 | 85 | 0 | 9 | 80 | 37.0 | 4.5 | 6 | 100 | 100 | 5.6 | 68 | 150 | 27 | 0 | 1 | 0 |
| geography | 10 | 91.4 | 86 | 0 | 6 | 80 | 33.9 | 4.3 | 18 | 100 | 100 | 4.9 | 67 | 150 | 39 | 0 | 0 | 0 |
| citizenship | 11 | 88.5 | 83 | 0 | 9 | 88 | 33.6 | 4.0 | 3 | 100 | 100 | 5.0 | 69 | 165 | 24 | 0 | 0 | 1 |
| computing | 11 | 94.1 | 87 | 0 | 5 | 88 | 29.1 | 3.2 | 32 | 100 | 100 | 4.8 | 58 | 180 | 49 | 3 | 2 | 0 |
| art | 9 | 94.6 | 88 | 0 | 1 | 72 | 29.0 | 4.0 | 42 | 100 | 100 | 4.8 | 68 | 147 | 18 | 1 | 0 | 0 |
| music | 9 | 91.6 | 82 | 0 | 5 | 72 | 29.7 | 3.1 | 40 | 100 | 100 | 4.1 | 74 | 160 | 27 | 4 | 1 | 1 |
| health_pe | 11 | 93.1 | 90 | 0 | 3 | 88 | 33.6 | 3.3 | 19 | 100 | 100 | 5.5 | 67 | 176 | 54 | 0 | 2 | 0 |
| design_tech | 9 | 94.2 | 88 | 0 | 3 | 72 | 34.7 | 3.6 | 39 | 100 | 100 | 5.4 | 66 | 144 | 57 | 1 | 0 | 0 |
| projects | 3 | 95.3 | 91 | 0 | 0 | 24 | 35.8 | 2.6 | 25 | 100 | 100 | 5.7 | 51 | 49 | 9 | 0 | 0 | 0 |
| **all** | 136 | 84.7 | 52 | 26 | 82 | 935 | 29.6 | 3.7 | 21 | 71 | 71 | 4.4 | 69 | 2036 | 532 | 105 | 8 | 4 |

### Grade 7

| subject | units | score | min | <70 | <bar | cards | w/card | FK | pic% | mem% | world% | kinds | ch/tf% | ex | gens | weak h | gives | dups |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| maths | 15 | 65.1 | 58 | 13 | 15 | 60 | 18.1 | 3.6 | 0 | 0 | 0 | 2.9 | 47 | 120 | 60 | 40 | 0 | 0 |
| science | 12 | 60.3 | 52 | 12 | 12 | 49 | 21.1 | 6.3 | 0 | 0 | 0 | 3.0 | 93 | 180 | 0 | 56 | 2 | 0 |
| english | 12 | 61.7 | 54 | 10 | 12 | 48 | 19.7 | 4.1 | 0 | 0 | 8 | 2.6 | 96 | 180 | 0 | 52 | 0 | 0 |
| computing | 11 | 95.5 | 88 | 0 | 3 | 88 | 33.3 | 3.1 | 39 | 100 | 100 | 4.5 | 58 | 174 | 54 | 0 | 0 | 0 |
| art | 9 | 95.4 | 90 | 0 | 1 | 72 | 31.5 | 4.1 | 54 | 100 | 100 | 5.1 | 71 | 144 | 21 | 0 | 0 | 0 |
| music | 9 | 92.8 | 85 | 0 | 5 | 72 | 32.8 | 3.4 | 36 | 100 | 100 | 4.8 | 70 | 148 | 36 | 3 | 0 | 0 |
| **all** | 68 | 76.3 | 52 | 35 | 48 | 389 | 25.1 | 4.1 | 25 | 43 | 44 | 3.7 | 72 | 946 | 171 | 151 | 2 | 0 |

### The 0 weakest units

| unit | score | cards | w/card | FK | pics | mem | world | kinds | levels | ex | gens | findings |
|---|---|---|---|---|---|---|---|---|---|---|---|---|

### The 30 weakest units

 unit | score | cards | w/card | FK | pics | mem | findings 
---|---|---|---|---|---|---|---
 g4.english.sound_alike | 50 | 5 | 24.4 | 0.1 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; listening taught without a sound 
 g6.english.poetry | 52 | 5 | 18.4 | 1.5 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; 9 hints missing or weak 
 g7.science.rock_cycle | 52 | 5 | 20.0 | 8.4 | 0 | - | 3 pictures missing; no memory question first; no 'try it in the world' or 'next' last; 6 thin worked answers 
 g4.english.story_structure | 53 | 4 | 24.2 | 5.0 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; listening taught without a sound; two kinds of exercise 
 g7.english.poem_forms | 54 | 4 | 21.2 | 3.3 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; listening taught without a sound; 5 hints missing or weak 
 g5.science.properties | 55 | 5 | 15.4 | 7.1 | 0 | - | 3 pictures missing; no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise 
 g6.science.climate | 55 | 5 | 22.4 | 5.1 | 0 | - | 3 pictures missing; no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise 
 g7.science.ecosystems | 55 | 4 | 18.8 | 5.4 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; 9 hints missing or weak 
 g6.english.figures_of_speech | 56 | 5 | 13.8 | 6.8 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; two kinds of exercise 
 g7.english.author_purpose | 56 | 4 | 18.0 | 5.6 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 6 hints missing or weak 
 g7.english.connotation_tone | 56 | 4 | 17.2 | 5.4 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 7 hints missing or weak; 7 thin worked answers 
 g7.science.resources | 56 | 4 | 21.8 | 6.2 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; 8 hints missing or weak 
 g6.english.affixes_roots | 57 | 4 | 19.0 | 3.8 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 1 pictures missing 
 g6.english.connotation | 57 | 4 | 13.8 | 6.9 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 6 hints missing or weak; 7 thin worked answers 
 g6.maths.equivalent_expressions | 57 | 4 | 18.5 | 3.9 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; two kinds of exercise 
 g6.science.water_cycle | 57 | 5 | 19.0 | 4.6 | 0 | - | 3 pictures missing; no memory question first; no 'try it in the world' or 'next' last; 5 hints missing or weak 
 g7.english.roots | 57 | 4 | 16.0 | 4.1 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 10 thin worked answers 
 g4.english.word_parts | 58 | 5 | 22.4 | 4.4 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; two kinds of exercise 
 g5.science.plants_air_water | 58 | 4 | 21.2 | 4.7 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; two kinds of exercise 
 g6.science.hazards_forecast | 58 | 4 | 18.2 | 7.4 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; two kinds of exercise 
 g7.english.allusions_analogies | 58 | 4 | 21.2 | 6.2 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 1 pictures missing 
 g7.english.phrases_clauses | 58 | 4 | 17.2 | 3.0 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 1 pictures missing 
 g7.maths.expressions | 58 | 4 | 15.2 | 2.5 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; two kinds of exercise 
 g7.science.photosynthesis | 58 | 4 | 20.2 | 7.7 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; 6 thin worked answers 
 g5.english.conjunctions | 59 | 4 | 19.8 | 3.2 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 1 pictures missing 
 g5.english.homographs | 59 | 4 | 24.0 | 3.2 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 5 hints missing or weak 
 g5.english.roots | 59 | 4 | 17.5 | 2.3 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 5 thin worked answers 
 g5.science.conservation | 59 | 5 | 21.0 | 3.3 | 0 | - | 3 pictures missing; no memory question first; no 'try it in the world' or 'next' last; 93% choice or true/false 
 g5.science.earth_spheres | 59 | 4 | 19.8 | 3.3 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; 2 pictures missing; two kinds of exercise 
 g6.english.point_of_view | 59 | 4 | 22.8 | 4.7 | 0 | - | no memory question first; no 'try it in the world' or 'next' last; two kinds of exercise; 5 hints missing or weak

**What the audit found.** The weakest units are the School's first ones (owner #68, 2026-09-28: grades 4-8 maths,
science and English, 162 of them in scope), written before the research's way of teaching: 4-5 short cards with no
memory question, nothing to try in the world and no "next", almost no pictures in grade 6 and 7 maths, science and
English (none in grade 7), two kinds of exercise (choice and true-or-false, with a few orders), hints of a word or two
ending in "…" ("thrifty and stingy…"), worked answers of a word ("Yes: that is connotation."). Grade 3's science and
English have no "Try it in the world" or "next" at the end (36 units). Pictures are the biggest gap everywhere: 300
units have fewer than the bar's one (two in the drawing subjects). Near-duplicates are rare (the music units' LISTEN
questions share a prompt but not a sound, and are not counted). 395 of 614 units are under the bar.

## The School's teaching, beyond the files (UI)

- **Right after a hint, the worked answer too** (`ExercisePanel.check`): an answer right on the second try said only
  "Yes! The hint helped you get there." and never why, so a lucky second tap on a true-or-false taught nothing. Now
  "Here is why: …" (the exercise's `explain`) follows the praise. Right the first time stays praise only.
- **Praise that changes from round to round** (`SchoolWords.RIGHT` 6 → 12 lines, `RIGHT_AFTER_HELP` 3 → 5, all about
  effort and strategy): the praise was picked by the exercise's place in the round, so every round said the same six
  lines in the same order. `ExercisePanel.praise_from` (SchoolScreen gives the round's seed) starts it elsewhere.
- **A worked answer never falls off the card** (`ExercisePanel._fit`): 233 of 9,109 hand-written exercises had a left
  column taller than the panel (540 px, up to 766) once "Let's look at it together" and the worked answer showed under
  the prompt and picture. Now the picture gives way first (down to 110 px, drawn smaller: every kind draws to its
  size), then the words get smaller (22). `test_every_hand_written_worked_answer_fits_its_panel` checks every one.
- Tests: `tests/integration/test_school_quality_panel.gd` (7).

## Rulings (decided here; cost if wrong)

1. **The bar is a ratchet, not a wall**: every unit in scope meets it or is listed in `NOT_YET`, and a listed unit
   that meets it must leave the list. *Cost:* none; the constants (`MIN_KINDS` 3, `MIN_A_LEVEL` 3, pictures 1 or 2)
   are one line each.
2. **Reading level is a guide, not a rule**: Flesch-Kincaid on children's science words over-counts syllables
   ("photosynthesis") and under-counts numbers; the audit charges 3 points a grade over grade + 1 and the bar ignores
   it. *Cost:* none.
3. **Grade 7 in scope is its six written subjects**; its history, geography and citizenship (another branch) are not
   checked by `test_school_quality.gd`, so the merge cannot fail on them. *Cost:* add them to `GRADE7_SUBJECTS` later.
4. **The quality agent's content scripts stay in its scratchpad** (as the grade agents' did): the unit files are the
   plain JSON the School reads, formatted as before (tabs; `json.dumps(indent="\t", ensure_ascii=False)` reproduces 613
   of the 614 files byte for byte), and new exercises go at the end of a unit's list so the others keep their ids.
   *Cost:* none.
5. **The worked answer is shown after a right second try**, not only after a second miss. *Cost:* one line if a
   grown-up finds it too much text; the child can still tap NEXT at once.

## Round 1: the 20 weakest (scores 50-59 → mean 94.8; before 55.5)

g4.english.sound_alike, g6.english.poetry, g7.science.rock_cycle, g4.english.story_structure, g5.science.properties,
g6.science.climate, g7.english.poem_forms, g7.science.resources, g7.english.roots, g7.science.ecosystems,
g6.english.figures_of_speech, g7.english.author_purpose, g7.english.connotation_tone, g7.maths.expressions,
g5.english.roots, g6.english.affixes_roots, g6.english.connotation, g6.maths.equivalent_expressions,
g6.science.plates, g6.science.water_cycle.

What each got (the pattern for every round): a "Quick memory: …?" card first that recalls an earlier unit or grade
with its answer; a last card "Try it in the world: … Next: …" pointing at something the game has (the Science Lab's
experiments, Gemma's prospecting quests, the furnace, the Wonders of the World, Frostpeak and the Sandstorm Desert, the
Moon, a meadow's rabbits and foxes) and at the unit that follows in the spiral; pictures on the teaching cards (tables
that organise the ideas, and the School's own kinds: `climograph`, `latlong` climate bands, `life_cycle` for the rock,
water and matter cycles, `layers`, `energy_chain`, `food_web`, `area_model`, `lab_circuit`, `ruler`, `states`,
`river_course`, `argument_map`, `comic`, `bar_model`, `sankey`); two or three new exercises of other kinds (sort, match,
number, order, and rhythm claps in the poetry units); every hint of a word or "…" rewritten as a strategy, every worked
answer of a word made a sentence that says why. Dense cards were split or rewritten, and examples of our own were added
(a haiku and a limerick for poem forms).

Facts and words fixed (sources):
- g5.science.properties: "Think of a copper coin" (as a metal a magnet does not pull) became a copper pipe: British 1p
  and 2p coins made since 1992 are copper-plated steel, and a magnet picks them up (the Royal Mint).
- g6.english.connotation and g7.english.connotation_tone: the body-shape words (slim, skinny, scrawny, slender, thin)
  were replaced by rooms (cosy, small, cramped), parties and speaking verbs (research §5.4 rule 4; the health units' kind
  words); the audit and the bar now look for them.
- g6.english.poetry: "the snow stabbed our faces" became "stung" (still harsh, not violent).
- g7.english.roots: "a hydrometer measures liquids" (it measures a liquid's density) was taken out; the roots' words
  are now pedestrian, manuscript and metre.
- g7.science.rock_cycle: granite's big crystals (cooled slowly underground) and basalt's tiny ones (cooled fast from
  lava) are now in the lesson, not only in an exercise.

The School's tests after the round (`test_school*`, the generators', the Lab's and the School's screens: 102 scripts,
1,178 tests): all passing.

## Round 2: the next 60 (scores 59-67 → mean 94.5; before 62.7)

g7.science.energy_flow, g4.english.figurative, g4.english.word_parts, g5.science.plants_air_water,
g6.science.hazards_forecast, g7.english.allusions_analogies, g7.english.phrases_clauses, g7.maths.integers_multiply,
g7.science.earth_history, g7.science.photosynthesis, g4.science.earth_maps, g5.english.conjunctions,
g5.english.homographs, g5.science.conservation, g5.science.earth_spheres, g6.english.point_of_view,
g6.english.word_relationships, g7.english.sentence_kinds, g7.maths.inequalities, g7.science.states,
g4.english.context_clues, g5.english.perfect_tenses, g5.science.new_substances, g6.science.heat,
g6.science.senses_memory, g6.science.weather, g7.maths.scale_drawings, g5.english.idioms_proverbs,
g5.science.food_webs, g5.science.protect_earth, g6.science.body_systems, g6.science.human_impact, g7.maths.circles,
g7.science.ecosystem_change, g4.english.relative_words, g5.english.figurative, g7.english.coordinate_adjectives,
g7.maths.area_volume, g7.science.atoms_molecules, g7.science.materials, g5.english.commas, g5.english.text_structure,
g5.english.titles, g5.science.particles, g6.science.energy_transfer, g7.maths.rational_numbers, g7.maths.sampling,
g5.english.point_of_view, g5.maths.convert_units, g5.science.gravity, g5.science.sun_stars, g6.english.pronouns,
g6.english.sentence_variety, g7.maths.constructions, g5.english.theme_compare, g5.science.shadows_seasons,
g5.science.sun_energy_food, g6.english.extra_information, g7.english.arguments, g7.english.theme_development.

The same treatment as round 1. New in this round:
- **Three picture kinds of our own** where no kind fitted, in `ui/school/school_picture_quality.gd`
  (`SchoolPictureQuality`, hooked after `SchoolPictureG7Arts` in `SchoolPicture`'s two dispatch points; samples and
  rules in `tests/integration/test_school_quality_pictures.gd`): `inequality_line` (a number line with the solutions
  of x > 5, x ≤ 4 …: an open or filled circle and a ray with its arrowhead; `holds`, `filled`, `ray_way`),
  `word_blocks` (a word built from coloured prefix, root and suffix blocks with their meanings) and `sentence_parts` (a
  sentence cut into tagged parts: clauses, phrases, subjects, verbs, joining words, modifiers). The existing
  `school_picture*.gd` drawing code is not touched.
- `tools/school_check.gd`: every unit's loader problems, pictures, sounds and hand-written answers in seconds (the
  generators' long run stays the content test's).
- A match's sides and an order's items are checked by hand for ties (two matches that mean the same, two amounts that
  are equal): every one found while writing was changed, because the checker wants one answer.

Facts fixed (sources):
- g5.science.plants_air_water: Jan van Helmont's willow (published 1648) "lost only a few grams" of soil: it was about
  2 ounces, 57 g, while the tree gained about 164 pounds, 74 kg, in 5 years. Now "less than 60 grams", and van Helmont
  is named (a person of the past), with the willow's growth drawn as a bar graph.
- g6.science.senses_memory: pulling a hand from a hot pan is a reflex through the spinal cord, not the brain deciding
  (the brain feels the pain a moment later; the reflex arc as school biology teaches it).
- g5.english.idioms_proverbs, g5.english.figurative, g4.english.relative_words and others: picture tables shortened so
  every cell fits its column at the School's font.

**A real bug fixed in the table kind** (`SchoolPicture._draw_table`, the one change to existing drawing code): a cell's
words were drawn at 22 px whatever their length, so long words ran over the next cell (27 cells in 20 units, up to
289 px in a 186 px cell). Now `SchoolPicture.table_font_size` shrinks them to fit, down to 13 px, and
`tools/school_check.gd` measures every cell with the game's font and names any that would shrink below 17 px (hard to
read on a phone); the last six were reworded (g3.health_pe.heart_exercise, g5.design_tech.test_and_review,
g6.english.research_sources, whose one-column source list became author, year and title columns).
`test_a_table_cell_shrinks_its_words_to_fit`. A fourth kind of our own, `coordinate_plane` (the four quadrants, grade
5's `grid` being the first quadrant only; `quadrant`), was added for the grade 6 coordinate plane.

The School's tests after the round (103 scripts, 1,183 tests): all passing.

## Round 3: the next 59 (scores 68-78 → mean 96.0; before 71.7)

g3.english.poems_plays, g3.english.spelling_patterns, g3.science.food_skeletons, g3.science.weather_hazards,
g4.english.adjectives, g4.english.punctuation, g4.english.reading_to_learn, g4.english.sentences,
g4.english.text_structure, g4.english.verbs, g4.maths.add_fractions, g4.maths.add_subtract, g4.maths.compare_round,
g4.maths.fraction_times, g4.maths.lines_shapes, g4.maths.times_as_many, g4.science.energy_moves,
g4.science.energy_resources, g4.science.hazards, g4.science.light_seeing, g4.science.plant_animal_parts,
g4.science.weathering, g5.maths.decimal_multiply_divide, g5.maths.divide_whole, g5.maths.expressions,
g5.maths.fractions_as_division, g5.maths.shape_families, g5.maths.unlike_fractions, g5.science.water_on_earth,
g6.english.central_idea, g6.english.claims_evidence, g6.english.plot_character, g6.maths.area,
g6.maths.convert_ratios, g6.maths.coordinate_plane, g6.maths.data_displays, g6.maths.divide_fractions,
g6.maths.equations, g6.maths.exponents_expressions, g6.maths.gcf_lcm, g6.maths.multi_digit, g6.maths.negatives,
g6.maths.percent, g6.maths.ratios, g6.maths.statistics, g6.maths.unit_rates, g6.maths.variables,
g6.maths.volume_surface, g6.science.cells, g7.english.modifiers, g7.english.setting, g7.maths.angle_facts,
g7.maths.equations, g7.maths.integers_add, g7.maths.percent_problems, g7.maths.probability, g7.maths.proportional,
g7.science.reactions, g7.science.substances.

Mostly maths, science and English units that missed the bar by one or two things: a second picture where the subject
teaches with drawings (bar models, number lines, the coordinate plane, event timelines, states of matter), a third
exercise kind (an order or a sort beside the choices), a real memory first card, a "Try it in the world" line that
points at the game (the Gold Shop, the furnaces, Frostpeak's cold nights, the Science Lab), and hints and worked
answers that teach instead of naming the answer.

Facts fixed or checked (sources):
- g6.maths.unit_rates: prices in pence (60p, 84p …) became gold: the game's only money is gold (the Gold Shop), and
  the School's other money lessons use gold.
- g7.science.substances: the new table's salt "melts at 801 °C" (sodium chloride; CRC Handbook of Chemistry and
  Physics). Its new world line smelts banded iron ore into iron at a furnace (the game's recipe): a new substance.
  Smelting sand into glass was not used, because melting sand is not the clear chemical change the unit teaches.
- g7.maths.percent_problems: the world line asks for 20% off a Gold Shop price the child picks; the game has no sales,
  so none is claimed.

The School's tests after the round (103 scripts, 1,185 tests): all passing.

## Round 4: the next 112 (scores 77-92 → mean 92.9; before 83.3)

g3.art.my_gallery, g3.citizenship.big_questions_fair, g3.citizenship.caring_nature, g3.citizenship.community_helpers,
g3.citizenship.kindness_respect, g3.computing.computer_parts, g3.computing.internet_what, g3.computing.private_info,
g3.computing.screen_balance, g3.design_tech.designs_changed_world, g3.english.adjectives_adverbs,
g3.english.characters_feelings, g3.english.compare_texts, g3.english.joining_sentences, g3.english.main_idea,
g3.english.nouns_pronouns, g3.english.point_of_view, g3.english.punctuation_speech, g3.english.sequence_cause,
g3.english.story_retell, g3.english.text_features, g3.english.verbs_tenses, g3.english.word_building,
g3.english.word_meanings, g3.english.write_facts_opinions, g3.english.write_stories, g3.geography.globe_equator,
g3.history.first_farmers, g3.history.iron_age, g3.music.loud_quiet_fast_slow, g3.music.music_stories,
g3.music.sing_well, g3.science.animal_groups, g3.science.classification_keys, g3.science.design_solutions,
g3.science.fair_tests, g3.science.fossils, g3.science.life_cycles, g3.science.light_shadows, g3.science.living_things,
g3.science.magnets, g3.science.materials, g3.science.plants_needs, g3.science.rocks_soils,
g3.science.survival_habitats, g3.science.traits, g3.science.weather_climate, g4.computing.tech_changed_world,
g4.design_tech.choosing_materials, g4.design_tech.inventors, g4.english.myths_tales, g4.english.story_characters,
g4.english.write_narrative, g4.english.write_opinion, g4.geography.americas, g4.health_pe.first_aid_basics,
g4.history.shang_china, g4.maths.angles, g4.maths.area_perimeter, g4.maths.big_numbers, g4.maths.decimals,
g4.maths.divide, g4.maths.equal_fractions, g4.maths.factors, g4.maths.line_plots, g4.maths.measure, g4.maths.multiply,
g4.maths.patterns, g4.music.music_for_pictures, g4.music.music_long_ago, g4.projects.ancient_museum,
g4.science.energy_speed, g4.science.rock_layers, g4.science.rockets_explorer, g4.science.sending_messages,
g4.science.senses, g4.science.waves, g5.citizenship.fair_and_just, g5.citizenship.news_opinions,
g5.design_tech.reuse_redesign, g5.english.main_ideas, g5.english.story_techniques, g5.english.write_explain,
g5.geography.atlas_digital_maps, g5.geography.deserts_polar, g5.health_pe.allergies_illness,
g5.health_pe.medicines_harmful, g5.history.romans_in_britain, g5.history.rome_republic_empire, g5.maths.coordinates,
g5.maths.decimal_add_subtract, g5.maths.decimal_place_value, g5.maths.divide_unit_fractions,
g5.maths.multiply_fractions, g5.maths.multiply_whole, g5.maths.powers_of_ten, g5.maths.scaling, g5.maths.volume,
g6.citizenship.disagree_well, g6.citizenship.elections, g6.citizenship.human_rights,
g6.citizenship.identity_belonging, g6.citizenship.income_tax, g6.citizenship.police_courts,
g6.citizenship.risk_protection, g6.computing.online_identity, g6.geography.migration, g6.history.african_kingdoms,
g6.history.black_death_change, g6.history.magna_carta, g6.music.early_music, g6.music.theme_variations.

Two kinds of work. First, the last maths, science and English units under the bar (the r7 patches): pictures where
there were none, a third kind of exercise, and kinder hints. Second, the humanities, health and the arts, which
mostly missed only their pictures: every picture is an existing kind (event timelines, tables, bar models, argument
maps, story arcs, info pages, site plans, pie charts), chosen to teach the card it sits on, not to decorate it.

Dates drawn on the new timelines, each checked (encyclopaedia entries and museum pages; where a date is traditional
or approximate, the card says "about"): Rome founded 753 BC (the traditional date), the republic 509 BC, Caesar killed
44 BC, Augustus emperor 27 BC, the empire at its largest AD 117, the west's end AD 476; Caesar's landing 55 BC,
Claudius AD 43, Boudica about AD 60, Hadrian's Wall begun AD 122, the army's leaving about AD 410; Britain's Iron Age
from about 800 BC; the lyres of Ur about 2500 BC, the Hurrian song on clay about 1400 BC, Marquis Yi's 65 bells 433 BC;
the Shang about 1600-1046 BC; John king 1199, Magna Carta 1215, de Montfort's parliament 1265, Edward I's 1295; the
Black Death in Europe 1347 and England 1348, the Statute of Labourers 1351, the Peasants' Revolt 1381; Great Zimbabwe
built from about 1100, Mali founded about 1235, Mansa Musa's journey to Mecca 1324; Jacquard's loom 1804, Lovelace's
program 1843, ENIAC 1945, the Moon landing 1969, the Web 1989; Gutenberg's press about 1440, light bulbs 1879, the
modern zip 1913; al-Jazari's book of machines 1206, Watt's engine 1769, Volta's battery 1800, Bell's telephone 1876,
the first powered flight 1903. The Universal Declaration of Human Rights table uses its own article numbers (1 free
and equal, 3 life and safety, 4 no slavery, 19 free speech).

The School's tests after the round (103 scripts, 1,185 tests): all passing.

## Round 5: the last 144 under the bar (scores 85-99 → every unit in scope meets the bar)

g3.art.cave_art, g3.art.looking_at_art, g3.art.observation_drawing, g3.art.sculpture_blocks, g3.art.texture_collage,
g3.citizenship.earning_money, g3.citizenship.friendship_conflict, g3.citizenship.honesty, g3.citizenship.needs_wants,
g3.citizenship.responsibilities, g3.citizenship.rules_fairness, g3.computing.algorithms, g3.computing.debugging,
g3.computing.decompose, g3.computing.kind_online, g3.computing.loops, g3.design_tech.design_process,
g3.design_tech.food_origins, g3.design_tech.healthy_snack, g3.design_tech.strong_structures,
g3.design_tech.tools_safety, g3.geography.compass_directions, g3.geography.maps_symbols, g3.geography.settlements,
g3.geography.weather_world, g3.geography.where_food_from, g3.health_pe.feelings, g3.health_pe.germs_hygiene,
g3.health_pe.staying_safe, g3.health_pe.team_games, g3.history.stone_circles, g3.maths.divide_meaning,
g3.maths.multiply_divide_written, g3.maths.times_tables, g3.music.high_low, g3.music.instrument_families,
g3.music.pulse_rhythm, g3.music.world_music, g3.projects.stone_age_camp, g4.art.kind_feedback, g4.art.printmaking,
g4.citizenship.adverts, g4.citizenship.big_questions_truth, g4.citizenship.bullying, g4.citizenship.deciding_together,
g4.citizenship.helping_community, g4.citizenship.keep_going, g4.computing.digital_footprint, g4.computing.is_it_true,
g4.computing.report_concerns, g4.computing.search_smart, g4.design_tech.balanced_meal, g4.design_tech.bread_grains,
g4.design_tech.design_for_someone, g4.design_tech.shelters_frames, g4.design_tech.textile_bag,
g4.english.accounts_evidence, g4.geography.compare_two_regions, g4.geography.countries_capitals,
g4.geography.fieldwork_survey, g4.geography.mountains, g4.geography.rivers, g4.geography.scale_distance,
g4.geography.volcanoes_earthquakes, g4.health_pe.big_feelings, g4.history.ancient_egypt, g4.history.ancient_numbers,
g4.history.kush_nubia, g4.music.beats_in_a_bar, g4.music.the_stave, g4.science.heat_temperature,
g5.art.sketchbook_develop, g5.citizenship.banks_interest, g5.citizenship.big_questions_owe, g5.citizenship.borrowing,
g5.citizenship.courage, g5.citizenship.democracy, g5.citizenship.laws, g5.citizenship.many_cultures,
g5.citizenship.planet_action, g5.computing.people_online, g5.computing.remix_credit, g5.computing.simulations,
g5.design_tech.fabrics_clothes, g5.design_tech.seasonal_cooking, g5.design_tech.test_and_review,
g5.english.present_speak, g5.english.quote_to_prove, g5.english.write_opinion, g5.geography.biomes,
g5.geography.climate_zones, g5.geography.natural_resources, g5.geography.rainforests, g5.geography.time_zones,
g5.geography.trade_links, g5.geography.two_mountain_regions, g5.health_pe.changing_friendships,
g5.health_pe.net_wall_games, g5.health_pe.orienteering, g5.health_pe.self_esteem, g5.history.ancient_india,
g5.history.classical_legacy, g5.history.greek_ideas, g5.history.han_china_silk_road, g5.history.roman_life,
g5.music.great_composers, g5.music.playing_together, g6.art.layered_prints, g6.citizenship.how_a_country_is_run,
g6.citizenship.spot_a_scam, g6.computing.boolean_logic, g6.computing.keep_accounts_safe, g6.computing.pixels_images,
g6.computing.spreadsheet_models, g6.design_tech.cook_on_a_budget, g6.design_tech.structures_forces,
g6.design_tech.user_centred_design, g6.geography.africa, g6.geography.asia, g6.geography.cities,
g6.geography.jobs_industry, g6.geography.population, g6.health_pe.mental_health,
g6.health_pe.respectful_relationships, g6.health_pe.serious_emergencies, g6.history.after_rome,
g6.history.anglo_saxons_vikings, g6.history.aztec_inca, g6.history.baghdad_wisdom, g6.history.medieval_japan,
g6.history.tang_song_china, g6.music.instruments_world, g6.music.intervals, g6.music.keyboard_skills,
g7.art.portfolio, g7.computing.collect_clean_data, g7.computing.copyright, g7.computing.wellbeing_online,
g7.music.baroque, g7.music.classical_era, g7.music.folk_music, g7.music.perform_together, g7.music.popular_music,
g6.science.nutrition_digestion.

Mostly the later-written 8-card units of the humanities, citizenship, health, computing, D&T and the arts, which had
no picture at all or one where their subject teaches with two; and 31 units that missed only on a hint that ended in
"…", a worked answer of one word, or a hint that said the right choice. Every picture is an existing kind picked to
teach its card: a flowchart for the steps of a routine (the Green Cross Code, hand-washing, the design cycle, what to
do when someone is unkind), a table for a comparison, an event timeline for dates, a map of latitude and longitude for
places, a site plan for a village or a map key, and the arts' own kinds (world instruments, beat grids, orchestra
seats, shading, still life, masterworks). Computing's lessons on staying safe
and searching well now show them with the chat, search page, phishing mail, privacy panel and code pictures.

`NOT_YET` is empty: all 614 units of grades 3-6 and grade 7's written subjects (maths, science, English, computing,
art, music) meet the bar, and `test_every_unit_meets_the_bar_or_is_not_yet_rewritten` holds every new or changed unit
to it. Grade 7's history, geography and citizenship are outside the bar until their branch is merged (the lead's
instruction).

Ruling 6: "fatty acids" (g6.science.nutrition_digestion's enzymes) is chemistry, not a body-shape word; the body-word
pattern in the test and the audit is now `fatty(?! acids?)`, with the case in `test_the_bar_finds_what_it_should`.
Cost if wrong: none for children; the pattern still catches "fatty" said of a body.

Facts drawn in this round, each checked (encyclopaedia entries, museum and government pages; "about" where the source
gives a range): the Han dynasty from 206 BC, Zhang Qian's journey west from 138 BC, Cai Lun's paper AD 105, Zhang
Heng's earthquake detector AD 132; the Tang from 618, the Diamond Sutra printed 868 (the oldest dated printed book),
the first government paper money 1024, Bi Sheng's clay type about 1040, Shen Kuo's compass needle 1088; Stonehenge's
ditch and bank about 3000 BC and its great stones about 2500 BC; Baghdad founded 762, its paper mill by 794,
al-Khwarizmi's al-jabr about 820, Baghdad taken 1258; Heian-kyo the capital from 794, The Tale of Genji about 1010,
the first shogun 1192, the Mongol fleets 1274 and 1281; Cleisthenes' reforms about 508 BC, Plato's Academy about 387
BC, Euclid's Elements about 300 BC; Chandragupta Maurya about 321 BC, Ashoka emperor about 268 BC, Brahmagupta's
zero 628; the Romans leaving Britain about 410, Sutton Hoo about 625, Lindisfarne 793, Edington 878, Athelstan king of
all England 927; the first Olympic Games 776 BC (the traditional date); UK copyright 70 years after the maker's death
to the end of that year (Copyright, Designs and Patents Act 1988), so a 1950 death frees the work on 1 January 2021.
Places and numbers: Canberra, Ottawa, Brasília and Nairobi on the latitude and longitude map at their real positions;
Manaus 3° S 60° W; Australia's Pilbara iron ore and Chile's Atacama copper; Mont Blanc about 4,800 m and Aconcagua
6,961 m; people per km² about 1,300 in Bangladesh, 280 in the UK and 2 in Mongolia (World Bank, 2022); rain in a year
about 3,000 mm in the Lake District's wettest valleys, 2,300 mm in Manaus and 600 mm in London; about 4 in 5 UK jobs
in services (ONS); 112 answered across Europe and in the UK. Fixed in passing: g3.geography.where_food_from's hint no
longer names Africa for "which continent", and g5.geography.time_zones' hint no longer says "east".

The School's tests after the round (103 scripts, 1,185 tests): 1,184 passing, and one risky: with `NOT_YET` empty,
`test_not_yet_names_only_written_units` had nothing to assert. It is now
`test_not_yet_names_only_written_units_and_stays_empty` (at least 600 units in scope, and the list stays empty); its
file passes (3 of 3).

## Round 6: above the bar, weakest first (112 units, scores 80-98 → mean 98.9; before 91.0)

g3.art.cave_art, g3.citizenship.big_questions_fair, g3.citizenship.caring_nature, g3.citizenship.community_helpers,
g3.citizenship.earning_money, g3.citizenship.honesty, g3.citizenship.kindness_respect, g3.citizenship.needs_wants,
g3.citizenship.responsibilities, g3.citizenship.rules_fairness, g3.citizenship.saving, g3.computing.computer_parts,
g3.computing.internet_what, g3.english.adjectives_adverbs, g3.english.characters_feelings,
g3.english.joining_sentences, g3.english.main_idea, g3.english.nouns_pronouns, g3.english.point_of_view,
g3.english.punctuation_speech, g3.english.sequence_cause, g3.english.spelling_patterns, g3.english.story_retell,
g3.english.word_meanings, g3.english.write_facts_opinions, g3.english.write_stories, g3.geography.continents_oceans,
g3.geography.grid_references, g3.geography.landforms_water, g3.geography.settlements, g3.health_pe.getting_help,
g3.history.first_farmers, g3.history.inventions_timeline, g3.history.iron_age, g3.history.local_history,
g3.history.stone_age_hunters, g3.history.stone_circles, g3.maths.times_tables, g3.music.loud_quiet_fast_slow,
g3.music.music_stories, g3.music.sing_well, g3.science.animal_groups, g3.science.fair_tests,
g3.science.forces_friction, g3.science.fossils, g3.science.magnets, g3.science.materials, g3.science.plants_needs,
g3.science.survival_habitats, g3.science.weather_hazards, g4.citizenship.big_questions_truth,
g4.citizenship.rights_responsibilities, g4.design_tech.balanced_meal, g4.design_tech.inventors,
g4.english.myths_tales, g4.english.story_structure, g4.english.text_structure, g4.english.write_narrative,
g4.english.write_opinion, g4.geography.americas, g4.geography.compare_two_regions, g4.geography.countries_capitals,
g4.geography.europe, g4.geography.water_on_the_move, g4.health_pe.outdoor_adventure, g4.history.first_cities,
g4.history.indus_valley, g4.history.sumer_writing, g4.music.music_for_pictures, g4.music.music_long_ago,
g4.science.earth_maps, g4.science.energy_resources, g4.science.hazards, g4.science.plant_animal_parts,
g4.science.sound, g5.citizenship.courage, g5.citizenship.fair_and_just, g5.citizenship.news_opinions,
g5.computing.people_online, g5.english.present_speak, g5.english.quote_to_prove, g5.english.story_techniques,
g5.english.theme_compare, g5.english.write_explain, g5.health_pe.changing_friendships, g5.health_pe.medicines_harmful,
g5.history.greek_daily_life, g5.history.han_china_silk_road, g5.history.persian_empire, g5.history.roman_life,
g5.history.romans_in_britain, g5.projects.fair_with_budget, g5.projects.roman_town, g5.science.particles,
g6.art.two_point_perspective, g6.citizenship.how_a_country_is_run, g6.citizenship.identity_belonging,
g6.citizenship.spot_a_scam, g6.computing.what_is_ai, g6.english.discuss_present, g6.english.figures_of_speech,
g6.health_pe.smoking_vaping_alcohol, g6.history.after_rome, g6.maths.gcf_lcm, g6.music.early_music,
g6.music.instruments_world, g6.music.theme_variations, g6.projects.design_for_a_need, g6.science.heat,
g6.science.weather, g7.music.film_music, g7.science.rock_cycle.

With every unit at the bar, this round took the lowest-scoring units the audit still finds and fixed what it names:
- **Dense cards.** Sentences over 22 words were split where a child would take a breath ("Most maps draw the line
  along the Ural Mountains. So Russia is partly in Europe and partly in Asia."), and cards over 45 words were cut.
  Across the round's units, sentences over 22 words went from 134 to 9 (most of the 9 left are a quotation that the
  audit reads together with the sentence after it, or a list of things). The hardest reads came down on the reading
  scale: grade 3's continents and oceans 6.6 → 5.9 and people who help us 5.6 → 4.5, grade 4's Americas 6.4 → 5.8
  and inventors 6.2 → 5.8 (the names of continents, countries and inventors keep them above their grade; they are
  the lesson).
- **Hints.** Two hints that said the answer (7 × 8 by doubling "14, 28, 56"; "12 goes into both") now give a way to
  find it.
- **Exercise variety.** A unit whose exercises were more than 80% choice or true/false got a match, a sort, an order
  or a number exercise that asks for the same knowledge in another way (a match of weather hazards to the designs
  that help, a match of tales to the lands they come from, an order of a story's parts, a sort of what to change,
  keep and measure in a fair test). Units over 80%: 76 → 7 in this round. New exercises are appended, so every
  existing exercise keeps its id (`<unit>#<index>`) and every child's mastery record (ruling 4).
- **Pictures where the subject teaches with them.** Force arrows for balanced and unbalanced pulls, a food web for
  "living things depend on each other", a river's long profile and a meander, beat grids and tracks for rhythm and
  polyphony, a keyboard for a bell's two notes, a lever for a jar opener, a mosaic for a Roman floor, timelines,
  tables and latitude and longitude maps.
- **Sounds where listening is taught.** Grade 4's "Music long ago" plays a flute-like tune and one bronze bell's two
  notes, grade 4's "Poems, plays and stories" claps the rhythm of "Twinkle, twinkle, little star" (Jane Taylor, 1806),
  and grade 6's "Instruments of the world" plays five notes from five dents of a steelpan.
- **A real world line.** g3.science.forces_friction ended on "…what it will do next", which passed the bar's "next"
  without pointing anywhere; it now has a last card to try in the world and "Next: magnets".

Ruling 7: the audit's six near-duplicates are kept. Each is a practice pair, the same kind of question with other
numbers or another note (the least common multiple of 3 and 4, then of 6 and 8; parks, then farms on one land-use
map; the chord under A, then under B). Cost if wrong: a child may meet two alike questions in one round, as extra
practice.

Facts drawn or added in this round, each checked (encyclopaedia entries, museum and government pages): farming
reached Britain about 4000 BC, Skara Brae was built about 3100 BC and the Great Pyramid about 2560 BC; Newcomen's
steam pump 1712, the telephone 1876, the first powered flight 1903, ENIAC 1945, four computers linked (ARPANET) 1969,
the Web 1989; the Indus cities at their biggest from about 2600 BC, Mohenjo-daro built about 2500 BC, emptied about
1900 BC; the first wheels about 3500 BC and writing in Uruk about 3200 BC; Cyrus about 550 BC, Darius's empire about
500 BC, Marathon 490 BC, Persepolis taken 330 BC; the Universal Declaration of Human Rights 1948 and the Convention on
the Rights of the Child 1989; Margaret Knight's paper-bag machine 1871, Josephine Cochrane's dishwasher 1886, Mary
Anderson's windscreen wiper 1903, Garrett Morgan's traffic signal 1923; Mary Anning born 1799, her ichthyosaur found
about 1811-1812; Haydn 1732-1809, Mozart 1756-1791, Elgar 1857-1934, Saint-Saëns 1835-1921 (The Carnival of the
Animals, 1886); the Volga about 3,530 km, the Danube about 2,850 km and the Thames about 350 km long; a tsunami
crosses the deep ocean at about 700 km an hour (NOAA gives over 800 km/h at the fastest, so "about 700" is safe);
Chang'an, Samarkand and Antioch on the Silk Road map at their real positions; the Ring of Fire's Japan, Indonesia,
Alaska and Chile; Lascaux and Chauvet in France and Altamira in Spain; Londinium, Eboracum and Aquae Sulis for London,
York and Bath; the Vindolanda tablets' sock parcel and birthday invitation; the Marquis Yi bells ring two notes each,
struck in two places; one of the Jiahu crane-bone flutes has been played.

The School's tests after the round (103 scripts, 1,185 tests): 1,184 passing and one failing, rightly:
`test_no_unit_asks_the_same_question_twice` found that a new match in g6.health_pe.smoking_vaping_alcohol repeated
an older one's prompt. A check of every new exercise against its unit's older ones (the same words in the prompt and
items) then found five more that asked what an older one already asked in the same way (a continent's wonders, the
weather hazards' designs, text structures' signal words, the order of the states of matter, high and low pressure,
and a grid reference the true-or-false had already given away). All six were replaced by exercises that ask something
new (a sort of what the UK law forbids, a number for land and water, a problem-and-solution order, a sort into solid,
liquid and gas, a cold front's drop in temperature, and another grid reference). The eight content test files that
check repeats, and the quality test, then passed (8 scripts, 80 tests).

## Round 7: the next weakest (58 units, scores 92-100 → mean 99.0; before 93.3)

g3.art.pattern_print, g3.design_tech.levers_linkages, g3.english.punctuation_speech, g3.geography.local_area,
g3.health_pe.sleep_rest, g4.art.ancient_art, g4.art.printmaking, g4.citizenship.bullying, g4.citizenship.ways_to_pay,
g4.computing.tech_changed_world, g4.english.sentences, g4.english.write_report, g4.geography.fieldwork_survey,
g4.geography.mountains, g4.geography.volcanoes_earthquakes, g4.health_pe.first_aid_basics, g4.health_pe.fitness_parts,
g4.history.archaeology, g4.history.shang_china, g4.projects.ancient_museum, g4.projects.river_town, g4.science.senses,
g5.computing.real_or_edited, g5.design_tech.control_with_code, g5.design_tech.reuse_redesign,
g5.geography.atlas_digital_maps, g5.geography.climate_zones, g5.geography.deserts_polar, g5.health_pe.create_a_dance,
g5.health_pe.sleep_screens, g5.history.persian_empire, g5.history.rome_republic_empire, g5.music.write_a_song,
g5.science.conservation, g5.science.gravity, g5.science.new_substances, g5.science.properties,
g5.science.protect_earth, g6.art.elements_principles, g6.citizenship.police_courts, g6.citizenship.risk_protection,
g6.citizenship.sustainable_choices, g6.design_tech.cook_on_a_budget, g6.english.read_closely,
g6.geography.climate_graphs, g6.geography.detailed_maps, g6.geography.maps_with_layers, g6.health_pe.food_as_fuel,
g6.history.aztec_inca, g6.history.baghdad_wisdom, g6.history.black_death_change, g6.history.magna_carta,
g6.history.medieval_japan, g6.history.tang_song_china, g6.science.climate, g6.science.senses_memory,
g7.computing.copyright, g7.english.poem_forms.

The same work as round 6 for the next units up. Pictures where the audit's share was short (54 missing → 2): a bar
graph of mountain heights, a latitude and longitude map of London, Moscow and Mumbai for why climates differ, a bar
model for al-Khwarizmi's "a thing and 7 make 20", a printing block and its mirror print, a reversing linkage, an arch
bridge, a dance's rondo as a song form, flowcharts for a bedtime routine, a survey, the traffic lights and making a
pencil pot from a tin, chats for standing by a friend, and tables for a museum label, a map's scales, a GIS's points,
lines and areas, a credit line, the Lords and the Commons, and criminal and civil law. Sentences over 22 words split
(82 → 7), and a match, sort, order or number exercise where a unit was mostly choice and true/false (12 units → 0).
Every new exercise was checked against its unit's older ones (`overlap` in the scratchpad: the same words in prompt
and items), so none repeats an older one; the few that share a topic ask it in a new form.

Facts drawn or added in this round, each checked (encyclopaedia entries and government pages): Ben Nevis 1,345 m,
Kilimanjaro 5,895 m and Everest 8,849 m; the UK traffic lights' order (red, red and amber, green, amber); the fastest
nerve messages travel at about 100 metres a second (the quickest nerves reach about 120); the UK Chief Medical
Officers' advice for children (60 minutes of activity a day on average, and muscle and bone strengthening on at least
3 days a week); the Shang signs for sun (a circle with a dot) and mountain (three peaks); Egyptian artists' paints
(ochre, malachite, soot, chalk and Egyptian blue); how finds are dated (a coin's ruler, pottery styles, tree rings,
radiocarbon); the Indus seals of Mohenjo-daro, about 4,500 years old; Tenochtitlan founded about 1325 and taken in
1521, Pachacuti's empire from 1438; the Sahara's cactus, camel and fennec fox; in England and Wales, a jury of 12 and
proof beyond reasonable doubt.

Four timeline labels of rounds 5 and 6 were made exact: 1024's "first paper money" became "state paper money" (the
Jiaozi, the first notes a government issued; merchants' notes came before); 1192 is when Minamoto Yoritomo was made
shogun and the shoguns' rule began (army commanders called shogun existed before him), so "the first shogun" became
"Yoritomo made shogun"; Shen Kuo described the magnetic needle compass in 1088 rather than inventing it, so "Shen
Kuo's compass" became "Shen Kuo: the compass", as the card says; and "Cyrus begins" became "Cyrus's conquests".

The tests after the round: the full suite (below).

## After seven rounds (2026-10-01): the audit before and after, per grade

`python3 tools/school_audit.py --compare` against the first audit's `--json` (grades 3-6 and grade 7's written
subjects; "now" is after round 7):

| grade | units | score | min | <70 | <bar | cards | w/card | FK | pic% | mem% | world% | kinds | ch/tf% | ex | gens | weak h | gives | dups |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 3 before | 137 | 88.8 | 71 | 0 | 90 | 1007 | 27.7 | 2.7 | 26 | 100 | 75 | 4.4 | 73 | 2148 | 492 | 24 | 6 | 1 |
| 3 now | 137 | 97.9 | 94 | 0 | 0 | 1037 | 27.9 | 2.6 | 39 | 100 | 100 | 4.9 | 70 | 2224 | 492 | 0 | 0 | 1 |
| 4 before | 137 | 86.5 | 50 | 8 | 87 | 970 | 30.7 | 3.1 | 24 | 69 | 73 | 4.8 | 69 | 1981 | 528 | 31 | 2 | 0 |
| 4 now | 137 | 97.8 | 94 | 0 | 0 | 1040 | 31.1 | 2.8 | 34 | 100 | 100 | 5.2 | 67 | 2043 | 528 | 0 | 0 | 0 |
| 5 before | 136 | 85.7 | 55 | 26 | 88 | 941 | 31.1 | 3.4 | 24 | 70 | 71 | 4.6 | 70 | 1998 | 571 | 52 | 7 | 1 |
| 5 now | 136 | 97.6 | 94 | 0 | 0 | 1023 | 31.7 | 3.1 | 34 | 100 | 100 | 5.1 | 67 | 2075 | 571 | 0 | 0 | 1 |
| 6 before | 136 | 84.7 | 52 | 26 | 82 | 935 | 29.6 | 3.7 | 21 | 71 | 71 | 4.4 | 69 | 2036 | 532 | 105 | 8 | 4 |
| 6 now | 136 | 97.4 | 92 | 0 | 0 | 1015 | 30.7 | 3.4 | 33 | 100 | 100 | 5.1 | 65 | 2137 | 532 | 0 | 0 | 4 |
| 7 before | 68 | 76.3 | 52 | 35 | 48 | 389 | 25.1 | 4.1 | 25 | 43 | 44 | 3.7 | 72 | 946 | 171 | 151 | 2 | 0 |
| 7 now | 68 | 97.2 | 94 | 0 | 0 | 468 | 28.1 | 3.3 | 38 | 100 | 100 | 4.8 | 65 | 1028 | 171 | 0 | 0 | 0 |
| all before | 614 | 85.3 | 50 | 95 | 395 | 4242 | 29.3 | 3.3 | 24 | 73 | 69 | 4.4 | 71 | 9109 | 2294 | 363 | 25 | 6 |
| all now | 614 | 97.6 | 92 | 0 | 0 | 4583 | 30.1 | 3.0 | 35 | 100 | 100 | 5.0 | 67 | 9507 | 2294 | 0 | 0 | 6 |

445 units scored higher, 0 lower

In words: all 614 units meet the bar (395 did not); the mean score went from 85.3 to 97.6 and the lowest from 50 to
92, with 219 units at 100; no unit scored lower. Every unit now starts with a memory question and ends with something
to try in the world or what comes next (73% and 69% before). Weak hints went from 363 to 0 and hints that said the
answer from 25 to 0; over a third of all cards have a picture (a quarter before); a unit has 5.0 kinds of exercise on
average (4.4), the share of choice and true/false fell from 71% to 67%, and hand-written exercises went from 9,109 to
9,507, all appended at the end of their lists.

What the audit still finds, for the next rounds (weakest first, with the same tools): 142 units have fewer pictures
than the audit's share (half the teaching cards in maths, science, geography, D&T, computing, art and music; a third
elsewhere); 183 units have a sentence over 22 words, many of them a quotation or a list read as one; 100 units are
more than 80% choice and true/false; 27 units have a card over 45 words; 85 units are not yet named in the agents'
notes (their facts' sources); 8 units read above their grade (the names of places and people in geography and
history); 6 near-duplicates are kept (ruling 7). Grade 7's history, geography and citizenship (merged into lead-merge
after this branch was cut) are outside the bar: once this branch is merged too, add them to `GRADE7_SUBJECTS` in
`tests/unit/test_school_quality.gd` and `tools/school_audit.py`, and the test names what they miss.

The next round's weakest 30 (`python3 tools/school_audit.py`, after round 7): g6.design_tech.sensors_switches 92,
g6.health_pe.outdoor_challenge 92, g6.health_pe.team_tactics 92, then at 94 g3.computing.data_charts,
g3.geography.continents_oceans, g3.history.sources_clues, g3.music.compose_loops, g4.citizenship.local_government,
g4.computing.data_tables, g4.design_tech.wheels_axles, g4.health_pe.food_labels, g4.health_pe.invasion_games,
g4.health_pe.personal_safety, g4.health_pe.striking_fielding, g5.citizenship.make_a_budget,
g5.computing.search_ranking, g5.health_pe.personal_best, g6.art.analyse_artwork, g6.computing.complex_decisions,
g6.computing.variables_types, g6.design_tech.food_science, g6.health_pe.analyse_improve,
g6.health_pe.athletics_technique, g6.history.tang_song_china, g6.music.scales_keys, g6.music.sound_science,
g6.science.light_travels, g7.art.colour_harmony, g7.art.designing_buildings and g7.art.portfolio.

For the lead's merge: a dry run (`git merge-tree lead-merge HEAD`, 2026-10-01) finds one conflict,
`ui/school/school_picture.gd`, where lead-merge's grade 7 humanities hook (`SchoolPictureG7Hum`) and this branch's
`SchoolPictureQuality` hook sit at the same three places (the header comment, `problem()`, the draw dispatch): keep
both, one after the other. `_draw_table`'s fit (`table_font_size`), `exercise_panel.gd`, `school_screen.gd` and
`DEVELOPMENT.md` merge by themselves, and no unit file is changed on both sides. The new kinds' names
(`inequality_line`, `word_blocks`, `sentence_parts`, `coordinate_plane`) are used by no other kind. After the merge:
`python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md`, and the full suite (the panel's
fit test measures `ExercisePanel`, which the animations changed too).

The full suite on this branch after round 7 (2026-10-01, `tests/run_tests.sh`, 57 minutes with the PC shared): 1,004
scripts, 9,179 tests, 9,177 passing, 2 risky (`test_meadows_biome_generator.gd`'s two tests that make no assert, world code this
branch does not touch), none failing, exit 0.

# Round 2 of the lesson quality (2026-10-01, the lead's second brief)

Branch `worktree-agent-abb89c3f242e2d600`, cut from `lead-merge` at 63d817bf (round 1 merged). The work, in the lead's
order: grade 7's history, geography and citizenship into the bar; the moving pictures on the lesson cards where motion
teaches; a picture on every unit short of the audit's picture share; shorter sentences and easier words where a unit
reads above its grade. No unit is added, no id, generator or field name changes (the "Lessons in a minute" Shorts read
these files at run time).

## Part 1: grade 7 history, geography and citizenship at the bar

`GRADE7_SUBJECTS` in `tests/unit/test_school_quality.gd` and `tools/school_audit.py` now names history, geography and
citizenship (the scope's floor is 640 units; 645 are written). The test then failed for 26 of the 31 units, rightly:
19 had worked answers of a word ("2015.", "Tokyo.", "A tarn."), 12 missed the drawing subjects' two pictures or the
others' one (citizenship had none at all), 2 had a hint of a word or "…", one a hint that said the answer ("the 2030
Agenda" for "by which year?") and one a body-shape word (the Süleymaniye's "slender minarets", now "tall,
pencil-shaped"). Every one was fixed, and the rest of each unit brought up to round 1's level:

- **Pictures** (existing kinds only, chosen for the card they sit on): event timelines for the press (Jikji 1377,
  Gutenberg's Bible about 1455, Caxton 1476, Luther 1517), the voyages (1405, 1488, 1492, 1498, 1522), the Ottomans
  (1299, 1453, 1529, 1922, with Suleiman's reign shaded), the Mughals (1526, 1556, 1575, 1632, 1857), the Stuarts and
  Parliament (1603, 1642, 1649, 1660, 1689, 1707) and active citizens (1918, 1928, 1930, 1955, 1977); a zoomed
  `voyage_map` of Tenochtitlan, Cusco and Hispaniola; a one-point `perspective` road for Brunelleschi's vanishing point;
  the moving `orbit` (gravity and speed arrows) for Newton's card; a `step_chain` of the spice traders who each added a
  profit, and a `pie_chart` of Ana's, Ben's and Cai's shares; freeze-thaw as a loop of steps and a table of the three
  kinds of weathering; a moving `food_web` for "energy flows"; a pie of farming's, industry's and homes' water and a bar
  graph of a shower, a bath and a day; Riyadh's climate graph and a qanat's steps; Russia's clocks from Kaliningrad to
  Kamchatka, its three zones, and Oymyakon's −67.7 °C on a thermometer beside a freezer; tables of sampling, a bar graph
  of the worked mean and range; a braced and an unbraced frame, "Drop, Cover and Hold On" as a flowchart, and Haiti and
  Chile side by side; for citizenship, tables (the UK's and the USA's law-making, codified constitutions, what free
  speech protects and does not, petitions' thresholds, jobs by people, things and ideas, pathways, a juice stall's
  profit at 5, 10 and 30 sold, risk and return, debit and credit, the three ways to think about a dilemma), `step_chain`s
  (a US amendment, SIFT, one T-shirt's journey), a pie of a charity's spending, a bar graph of the UN's 51 and 193
  members and of 500 gold owed at 24%, and a chat that says back what the other person meant.
- **Worked answers** of a word became sentences that say why ("A tarn: a small lake left in a corrie's armchair-shaped
  hollow."); **long sentences** (58) were split and cards over 45 words cut.
- **Facts checked** (Britannica, the Library of Congress, UNESCO, the UN, the UK Parliament and government pages;
  the grade 7 agent's notes `m8-grade7-humanities.md` hold the rest): Gutenberg's press about 1450 in Mainz (the card
  said "the 1440s and 1450s": his first experiments were in Strasbourg); the Great Wave about 1831; Galileo's trial 1633;
  the Royal Society 1660, the Principia 1687; James VI and I 1603, the Civil War 1642, the republic 1649, the monarchy's
  return 1660, the Bill of Rights 1689, the Union 1707; Taharqa king 690 BC; the UN Charter in force 24 October 1945
  with 51 members, 193 today; the Global Goals 2015 for 2030, Goal 17 "Partnerships for the Goals"; the Green Belt
  Movement founded 1977; women's votes in the UK 1918 and 1928; the Salt March 1930; the Montgomery bus boycott 1955-1956
  (381 days); the Red Cross 1863 after Solferino (1859), Barnardo's first home 1870; Russia's time zones UTC+2
  (Kaliningrad) to UTC+12 (Kamchatka), Moscow +3, Novosibirsk +7, Vladivostok +10; Oymyakon −67.7 °C (1933); Riyadh's
  monthly normals rounded (about 15 °C in January to 36 °C in July, about 95 mm of rain a year, none in summer); the UK's
  140 litres a day and farming's 70 in 100 litres (the grade 7 agent's sources); the 1:25 model of St Paul's.
- Units named here so the audit finds their notes: g7.history.printing_press, g7.history.renaissance,
  g7.history.voyages, g7.history.encounters_americas, g7.history.ottoman_empire, g7.history.mughal_india,
  g7.history.ming_edo, g7.history.scientific_revolution, g7.history.crowns_parliaments, g7.history.trade_companies,
  g7.geography.plates_and_people, g7.geography.rocks_soils_geo, g7.geography.glaciers, g7.geography.coasts,
  g7.geography.world_ecosystems, g7.geography.water_supply, g7.geography.middle_east, g7.geography.russia,
  g7.geography.fieldwork_enquiry, g7.geography.hazard_management, g7.citizenship.how_laws_are_made,
  g7.citizenship.constitutions_rights, g7.citizenship.active_citizens, g7.citizenship.charities,
  g7.citizenship.media_bias, g7.citizenship.global_citizens, g7.citizenship.careers, g7.citizenship.small_business,
  g7.citizenship.cards_credit, g7.citizenship.saving_investing, g7.citizenship.ethics_dilemmas.
- Six table cells of the new pictures shrank below 17 px at the School's font (`tools/school_check.gd`) and were
  reworded ("fair shares of each area" became "some in each area").

**The Lesson in a minute left the Quick memory's question in** (found by the School's tests, fixed here with a test):
after round 1 and the Shorts were both merged, `tests/unit/test_lesson_short.gd` failed twice. `LessonShort.teaching`
left out only the sentence beginning "Quick memory" and a bracketed answer right after it, but 372 of 645 memory cards
put a lead-in line first ("Quick memory: in grade 5 you learned latitude. What is the latitude of the Equator? (0°.)")
or answer without brackets (grade 7 maths and science), so 230 minutes opened on an earlier unit's question and
answer. `teaching` now leaves out the whole memory, up to its bracketed answer or to the lesson's own "Today" or
"Now" (kept); a memory without either is all memory (only two such cards have four sentences, both all memory). The
test's "then the first card's words" now means the first words that teach. `test_the_minute_leaves_out_the_whole_quick_memory`
(four cases and every written unit). One memory with two questions (g5.maths.angles_triangles_quads) became one.

## Part 2: the moving pictures on the lesson cards

The animations work (`docs/devlog/parts/animations.md`) made five kinds for motion (`SchoolPictureMotion`) and let
gears, pulleys, cams, levers, lit circuits, food webs and unlabelled waves move; no lesson used the new kinds. They are
now on the cards where the motion is the lesson (a lesson card plays; an exercise holds still unless `"animate": true`):

| Kind | Unit, card | What the motion teaches |
|---|---|---|
| `water_cycle` | g4.geography.water_on_the_move 1, g6.science.water_cycle 3, g4.science.states_of_matter 6 | vapour rising, the cloud, rain on the hill, the river back to the sea: the cycle has no start and no end |
| `moon_phases` | g4.science.light_seeing 6 (it replaced a Moon icon) | the Moon shines by sunlight; as it goes round, we see more or less of its lit half (the card says so now) |
| `orbit` | g5.science.gravity 5 (with gravity and speed arrows), g5.science.shadows_seasons 4 (Earth's year), g4.science.rockets_explorer 4 (round the Earth, arrows), g7.history.scientific_revolution 6 (Newton) | moving fast along the path while gravity pulls in keeps a body going round |
| `pendulum` | g3.science.forces_friction 6 (a short and a long one; it replaced a "back, front, back, ?" table), g6.science.energy_transfer 1 (with energy bars) | a repeating motion can be predicted, and a longer string swings more slowly; kinetic energy is biggest at the bottom, stored at the top |
| `rocket_stages` | g4.science.rockets_explorer 5 (it replaced the stages table) | each stage burns, drops away empty, and the next fires |
| `wave` (moving) | g4.science.sound 2, g4.science.waves 6 (loud and quiet), g6.music.sound_science 3 (an octave: twice as many waves) | sound travels; a bigger amplitude is louder; a higher note vibrates faster at the same speed |
| `food_web` (moving) | g7.geography.world_ecosystems 3, g5.science.food_webs 3 (a food chain) | energy flows from the food to its eater |

Five exercises ask the child to watch (`"animate": true`), where the motion is what is observed and the question is
about the pattern, not a fact the picture hides: which pendulum swings more slowly (g3 forces), which takes less time
to go round (the Moon or the Earth: g5 gravity), where the kinetic energy is biggest (g6 energy transfer), which stage
burns first (g4 rockets); and one still picture asks which stage of the water cycle the "?" hides (g6 water cycle).
`test_every_moving_kind_teaches_on_a_lesson_card` (in `test_school_quality.gd`) holds every kind of
`SchoolPictureMotion.KINDS` to a lesson card, and every exercise that asks for motion to a picture that moves (it
failed for four kinds before this part; orbit was already on Newton's card).

Ruling 8: **the Moon's phases enter at grade 4, as a picture, not as a lesson**: the grade 4 card says only that we see
more or less of the Moon's sunlit half; naming the phases stays grade 8's (the research). Cost if wrong: none; the
picture shows no names (`names` is off).

## Part 3: a picture where it teaches, on every unit short of the audit's share (140 units)

The audit wants a picture on half the teaching cards in maths, science, geography, D&T, computing, art and music, and
a third elsewhere; 142 units were one short (two of them were given a moving picture in part 2). Each got one more,
weakest first, on the card where a picture teaches most, using the existing kinds only:

- **Steps in order** (`step_chain`, a loop where the process repeats): looking at art, drawing what you see, debugging,
  a castle in parts, the days of the week as a loop, testing a program, making, getting ready to cook (twice),
  catch it bin it kill it, calming down, farm to fork, election day, an emergency call, the SIFT-like checks before
  sharing, how pages are found, procedures calling procedures, a reduction print, restorative justice, how a law is
  made, needs then saving then wants, from wheat to a shop's bread (primary to tertiary), the three phases of a skill,
  what to do about bullying, call and response in a sea shanty, how our digits travelled, Socrates to Aristotle.
- **Tables** that organise what the card lists (all checked by `tools/school_check.gd` for cells that fit at 17 px or
  more): switches, a route card worked with Naismith's rule, map colours, food groups, rocks and their uses, ways to
  decide, shelters of the world, map scales in words, mosaics, greetings, fibres, linking words, a mountain's cooling
  (6.5 °C every 1,000 m), place value (305 and 35), tempo words, what taxes pay for, sparse places, West Africa's salt
  and gold, closed and open questions, the seasons' food, paper shapes that hold a book, workshop rules, syllables,
  what every map has, hunted and gathered, adverts' tricks, empathy's clues, rope value, sorting a table, footprints on
  purpose and not, needs and wants, fabrics, food-label sugars (the UK's FSA: 5 g or less low, over 22.5 g high),
  invasion games' rules, a surprise and an unsafe secret, batting and fielding, time signatures, signals, loan
  repayments, direct and representative democracy, renewable and not, allergic reactions, SMART goals, unit
  conversions, multiplying by 7/8, 8/8 and 9/8, the edge of gems ≥ 5, weak and strong passwords, data types, fridge
  shelves (the FSA: raw meat at the bottom), a specification's numbers, everyday mental health, place-name endings
  (-ton, -ham, Old English; -by, -thorpe, Norse), dynamics marks.
- **Charts and diagrams**: bar graphs (favourite pets, a bridge test against its criteria, Tilly's savings, a class's
  rubbish falling by a quarter, rivers of Asia, heights from Kilimanjaro to Ben Nevis, a bus's cost for each child),
  a line graph of the share of people in cities (UN World Urbanization Prospects: about 30% in 1950, half by 2007, 56% in
  2020), pies (trade by sea, a charity's spending), bar models (a book read 20 pages a day, a pulse counted for 15 s,
  a wheel's 4 turns, 5/6 split, a subtraction checked by adding back, halves in 3), a fraction wall for halves, sixths
  and thirds, thermometers (the tundra's winter and summer), Manaus's climate graph (about 2,300 mm of rain a year), a
  latitude map with the climate bands, compasses (a needle; a robot turned to face west), beat grids, a melody (the
  first line of Frère Jacques, C D E C), a food chain as a moving food web, an energy chain for a solar panel, chats
  (feedback starters, thinking words, saying back what someone meant), timelines (Kush from Kerma to AD 350; the UN,
  the Declaration, the European Convention and the children's rights convention; Handel's Water Music 1717 and
  Fireworks 1749), lifespans of Vivaldi, Bach and Handel, and a zoomed map of the Mongol fleets of 1274 and 1281
  (from Korea and from Ningbo, China, to Hakata Bay).

**Looked at in a real window** (a scratch script drew each new picture alone in a 560 × 380 SubViewport, the lesson
card's size; the 120 new pictures of parts 1-3 but the tables): fixed on sight, the Mongol fleets' map (the 1274 route was a dot on
a whole-sea window; now a closer window with Korea and Ningbo named, clear of the key), the Ottoman timeline (Suleiman's
46 years were a sliver with an unreadable name; now an event), and five step boxes whose words shrank to fit (now
shorter: "find other sources", "check the headline", "council meets", "water in the hills", "it becomes law").

Facts drawn (each checked; "about" where the sources differ): Yangtze about 6,300 km, Yellow River about 5,500 km
(5,464), Ganges about 2,500 km (2,510) (Britannica; the Mekong and the Indus were left out, their lengths differ too
much between sources); Kilimanjaro 5,895 m, Mont Blanc 4,805 m (the 2023 survey), Ben Nevis 1,345 m; Kerma a busy town
by about 2500 BC, Kush ruled Egypt from about 730 BC (the 25th dynasty), Taharqa king 690 BC, Kush's end about AD 350;
the secret ballot in Victoria 1856 and Britain 1872; the Convention on the Rights of the Child 1989; Vivaldi
1678-1741, Bach 1685-1750, Handel 1685-1759; the tundra about −30 °C in winter and 10 °C in summer (National
Geographic's biome pages give −34 °C and 3-12 °C); Manaus's months (INMET normals, rounded); a pupil's pulse of 20 in
15 s is 80 a minute; Frère Jacques in C.

Units given a picture in this part: g3.art.looking_at_art, g3.art.my_gallery, g3.art.observation_drawing,
g3.computing.algorithms, g3.computing.data_charts, g3.computing.debugging, g3.computing.decompose,
g3.computing.internet_what, g3.computing.kind_online, g3.computing.loops, g3.computing.private_info,
g3.computing.screen_balance, g3.computing.sequences, g3.design_tech.design_process,
g3.design_tech.designs_changed_world, g3.design_tech.food_origins, g3.design_tech.healthy_snack,
g3.design_tech.strong_structures, g3.design_tech.tools_safety, g3.english.poems_plays, g3.english.word_building,
g3.geography.maps_symbols, g3.geography.weather_world, g3.geography.where_food_from, g3.health_pe.dance_moves,
g3.health_pe.feelings, g3.health_pe.germs_hygiene, g3.health_pe.healthy_eating, g3.health_pe.heart_exercise,
g3.health_pe.team_games, g3.music.compose_loops, g3.music.instrument_families, g3.music.pulse_rhythm,
g3.projects.map_my_village, g3.projects.stone_age_camp, g3.science.design_solutions, g3.science.rocks_soils,
g4.art.kind_feedback, g4.citizenship.adverts, g4.citizenship.deciding_together, g4.citizenship.empathy,
g4.citizenship.keep_going, g4.citizenship.local_government, g4.citizenship.smart_spending, g4.computing.data_tables,
g4.computing.digital_footprint, g4.computing.events, g4.computing.is_it_true, g4.computing.report_concerns,
g4.computing.search_smart, g4.design_tech.bread_grains, g4.design_tech.choosing_materials,
g4.design_tech.design_for_someone, g4.design_tech.shelters_frames, g4.design_tech.textile_bag,
g4.design_tech.wheels_axles, g4.geography.scale_distance, g4.health_pe.food_labels, g4.health_pe.invasion_games,
g4.health_pe.personal_safety, g4.health_pe.striking_fielding, g4.history.first_cities, g4.history.kush_nubia,
g4.maths.add_fractions, g4.maths.add_subtract, g4.music.beats_in_a_bar, g4.music.rounds, g4.science.energy_moves,
g4.science.sending_messages, g5.art.mosaics, g5.citizenship.banks_interest, g5.citizenship.big_questions_owe,
g5.citizenship.borrowing, g5.citizenship.democracy, g5.citizenship.fair_and_just, g5.citizenship.laws,
g5.citizenship.make_a_budget, g5.citizenship.many_cultures, g5.citizenship.news_opinions,
g5.citizenship.planet_action, g5.computing.procedures, g5.computing.remix_credit, g5.computing.search_ranking,
g5.design_tech.fabrics_clothes, g5.design_tech.seasonal_cooking, g5.design_tech.test_and_review,
g5.english.write_opinion, g5.geography.biomes, g5.geography.natural_resources, g5.geography.rainforests,
g5.geography.trade_links, g5.geography.two_mountain_regions, g5.health_pe.allergies_illness,
g5.health_pe.personal_best, g5.health_pe.self_esteem, g5.history.ancient_india, g5.history.classical_legacy,
g5.history.greek_ideas, g5.maths.convert_units, g5.maths.decimal_multiply_divide, g5.maths.scaling,
g5.maths.unlike_fractions, g5.music.great_composers, g5.music.playing_together, g5.science.food_webs,
g6.art.analyse_artwork, g6.art.layered_prints, g6.citizenship.disagree_well, g6.citizenship.elections,
g6.citizenship.human_rights, g6.citizenship.income_tax, g6.computing.complex_decisions,
g6.computing.keep_accounts_safe, g6.computing.online_identity, g6.computing.spreadsheet_models,
g6.computing.variables_types, g6.design_tech.food_science, g6.design_tech.sensors_switches,
g6.design_tech.user_centred_design, g6.geography.africa, g6.geography.asia, g6.geography.cities,
g6.geography.jobs_industry, g6.geography.migration, g6.geography.population, g6.health_pe.analyse_improve,
g6.health_pe.mental_health, g6.health_pe.outdoor_challenge, g6.health_pe.respectful_relationships,
g6.health_pe.serious_emergencies, g6.history.african_kingdoms, g6.history.anglo_saxons_vikings,
g6.history.medieval_japan, g6.history.tang_song_china, g7.art.portfolio, g7.computing.collect_clean_data,
g7.computing.wellbeing_online, g7.music.baroque, g7.music.folk_music, g7.music.perform_together.

## Part 4: shorter sentences, and easier words where a unit read above its grade

Every sentence over 22 words in grades 3-7 (272 in 193 units, as the audit now counts) was split where a child takes a
breath, and every card over 45 words cut (40 in 37 units): mostly lists ("Designs that help: flood walls and barriers,
and houses on stilts. Lightning rods on tall buildings, strong roofs and storm shutters. And reservoirs that store
water for dry times."), "Try it in the world" lines with three things to build, and definitions with brackets
("Interactions. Competition: two species need the same food, like rabbits and mice. Predation: …"). Facts, numbers,
names and worked sums were kept (a few sums lost a step only where the card said it twice); where a line had to lose
a detail to fit, the detail was the least needed ("and the 10s end in 0", "called the Father of the Blues", "dogs
and" bats). The one left is a quoted limerick (g7.english.poem_forms), read as one by the audit (ruling 9).

The units above their grade's reading level (Flesch-Kincaid over the grade + 1) got shorter words where the lesson's
own words allow ("Continents are made of countries", "Differences make the world more fun! Families have many special
days", "People need each other"): grade 3's continents and oceans 5.8 to 5.5, kindness 5.0 to 4.4, computer parts 4.7
to 4.3, people who help us and the inventions timeline 4.4 to 4.1; grade 3's shapes (4.1 to 4.0) and grade 5's ancient
India (6.0 to 5.8) came under the line. The eight still above it are above it because of their lesson's words
(continents, the Americas, capitals, inventors' names, Antarctica, information, processor): ruling 2 of round 1 stands.

**The audit counts words as a reader reads them** (`reader_words`): a number with a comma or a point, a decade, an
ordinal and a note or formula ("1,000", "2.5", "1440s", "2nd", "C4", "H2O") are one word each (they were two or
three), and a sentence that ends inside brackets or quotes ("(0°.) Today: …", "says, 'I'm no good at this.' Kind
…") ends there. The bar's hint and worked-answer counts keep `words_of`, the GDScript test's own count. The before
figures below are lead-merge's lessons measured with this audit (`git archive lead-merge data/school docs/devlog/parts`
into the scratchpad, the final `school_audit.py` beside them).

Units rewritten in this part: g3.art.my_gallery, g3.citizenship.community_helpers, g3.citizenship.kindness_respect,
g3.computing.computer_parts, g3.computing.private_info, g3.computing.screen_balance, g3.design_tech.boxes_nets,
g3.design_tech.designs_changed_world, g3.english.compare_texts, g3.english.poems_plays, g3.english.verbs_tenses,
g3.geography.continents_oceans, g3.geography.globe_equator, g3.geography.maps_symbols,
g3.health_pe.balance_gymnastics, g3.health_pe.germs_hygiene, g3.health_pe.healthy_eating, g3.health_pe.run_jump_throw,
g3.health_pe.staying_safe, g3.history.inventions_timeline, g3.history.timelines, g3.maths.fractions_number_line,
g3.maths.numbers_to_10000, g3.maths.perimeter, g3.maths.shapes_lines_angles, g3.maths.times_tables,
g3.projects.habitat_park, g3.science.life_cycles, g3.science.living_things, g3.science.rocks_soils,
g3.science.survival_habitats, g3.science.weather_hazards, g4.art.kind_feedback, g4.art.portraits,
g4.art.relief_sculpture, g4.citizenship.big_questions_truth, g4.citizenship.deciding_together,
g4.citizenship.helping_community, g4.citizenship.keep_going, g4.citizenship.rights_responsibilities,
g4.computing.events, g4.computing.is_it_true, g4.computing.networks, g4.computing.plan_programs,
g4.computing.report_concerns, g4.computing.search_smart, g4.design_tech.choosing_materials,
g4.design_tech.electric_products, g4.design_tech.inventors, g4.design_tech.shelters_frames,
g4.english.accounts_evidence, g4.english.adjectives, g4.english.figurative, g4.english.myths_tales,
g4.english.sound_alike, g4.english.verbs, g4.english.write_opinion, g4.geography.countries_capitals,
g4.geography.rivers, g4.geography.scale_distance, g4.health_pe.athletics, g4.health_pe.big_feelings,
g4.health_pe.water_safety, g4.history.ancient_egypt, g4.history.ancient_numbers, g4.history.compare_civilisations,
g4.history.farming_trade_money, g4.maths.equal_fractions, g4.maths.lines_shapes, g4.maths.tables_line_graphs,
g4.music.ostinato_layers, g4.science.digestion_teeth, g4.science.heat_temperature, g4.science.plant_animal_parts,
g5.art.abstract_art, g5.art.architecture, g5.art.mosaics, g5.art.one_point_perspective, g5.art.sketchbook_develop,
g5.art.still_life, g5.citizenship.banks_interest, g5.citizenship.many_cultures, g5.citizenship.planet_action,
g5.computing.how_messages_travel, g5.computing.remix_credit, g5.computing.simulations,
g5.computing.spreadsheets_intro, g5.computing.tech_for_everyone, g5.design_tech.cams_toys,
g5.design_tech.design_on_screen, g5.design_tech.fabrics_clothes, g5.design_tech.gears_pulleys, g5.english.homographs,
g5.english.many_sources, g5.english.write_opinion, g5.geography.atlas_digital_maps, g5.geography.biomes,
g5.geography.deserts_polar, g5.geography.lat_long, g5.geography.time_zones, g5.geography.trade_links,
g5.geography.two_mountain_regions, g5.health_pe.net_wall_games, g5.health_pe.orienteering, g5.health_pe.self_esteem,
g5.health_pe.tactics, g5.history.ancient_india, g5.history.classical_legacy, g5.history.greek_daily_life,
g5.history.greek_ideas, g5.history.han_china_silk_road, g5.history.maya, g5.history.roman_life,
g5.history.rome_republic_empire, g5.maths.multiply_fractions, g5.maths.volume, g5.music.music_tech,
g5.music.playing_together, g5.science.electric_systems, g5.science.reproduction_life, g6.art.art_from_nature,
g6.art.geometric_patterns, g6.art.layered_prints, g6.art.lettering, g6.art.medieval_world_art,
g6.citizenship.compound_interest, g6.citizenship.elections, g6.citizenship.human_rights, g6.citizenship.income_tax,
g6.computing.online_identity, g6.design_tech.design_movements, g6.design_tech.ideas_from_nature,
g6.design_tech.sensors_switches, g6.design_tech.structures_forces, g6.english.affixes_roots,
g6.english.claims_evidence, g6.english.plot_character, g6.english.poetry, g6.english.point_of_view,
g6.english.research_sources, g6.english.write_informative, g6.english.write_narrative, g6.geography.asia,
g6.geography.cities, g6.geography.migration, g6.geography.population, g6.geography.river_processes,
g6.health_pe.athletics_technique, g6.health_pe.outdoor_challenge, g6.health_pe.serious_emergencies,
g6.health_pe.stress_coping, g6.health_pe.team_tactics, g6.health_pe.training_principles, g6.history.african_kingdoms,
g6.history.aztec_inca, g6.history.baghdad_wisdom, g6.history.castles_feudal, g6.history.magna_carta,
g6.history.medieval_japan, g6.history.tang_song_china, g6.maths.problem_solving_toolkit, g6.maths.volume_surface,
g6.music.blues, g6.music.intervals, g6.music.keyboard_skills, g6.projects.weather_station, g6.science.classification,
g6.science.energy_changes, g6.science.engineering_design, g6.science.hazards_forecast, g6.science.light_travels,
g6.science.nutrition_digestion, g6.science.skeleton_muscles, g7.art.designing_buildings, g7.art.drawing_people,
g7.art.graphic_design, g7.art.portfolio, g7.art.renaissance_art, g7.art.woodcut_prints, g7.art.world_art_1450_1750,
g7.computing.blocks_to_text, g7.computing.collect_clean_data, g7.computing.functions_parameters,
g7.computing.how_internet_works, g7.computing.searching, g7.computing.testing, g7.computing.wellbeing_online,
g7.english.theme_development, g7.music.baroque, g7.music.bass_clef, g7.music.classical_era, g7.music.folk_music,
g7.music.popular_music, g7.music.riffs_hooks, g7.science.atoms_molecules, g7.science.ecosystems,
g7.science.energy_flow, g7.science.resources, g7.science.substances.

## Rulings of round 2 (cost if wrong)

8. (Part 2, above.) The Moon's phases enter at grade 4 as a picture only. Cost: none.
9. **A quoted poem is read whole**: g7.english.poem_forms' limerick is one "sentence" of 54 words to the audit, and
   splitting it would break the poem. Cost: one long-sentence finding left.
10. **The lesson-quality agent changed the Shorts' `LessonShort.teaching`** (the merged EasyCraft Shorts' file, not the
    Reel Studio's), because the School's tests failed on it after both branches were merged and the fix belongs with
    how lessons are written: the whole Quick memory is left out. Cost if wrong: a minute that wanted a memory's
    lead-in line loses it; the line was never this unit's teaching.
11. **Exercises that ask the child to watch** (`"animate": true`) ask about the pattern the motion shows (which is
    slower, which first, where most), never a fact the motion hides; the rest of the moving kinds' exercises hold
    still (the animations' rule). Cost: none.
12. **One picture added to a unit short of the share, not two**: every unit was exactly one short. Cost: none.
13. **Lengths and heights that sources disagree on are left out of the charts** (the Mekong, the Indus), and the ones
    drawn are rounded with "about" in the chart's name. Cost: a chart of three rivers, not five.

## After round 2 (2026-10-01): the audit before and after, per grade

`python3 tools/school_audit.py --compare` against lead-merge's lessons (63d817bf) measured with the same audit; "now"
is after part 4:

| grade | units | score | min | <70 | <bar | cards | w/card | FK | pic% | mem% | world% | kinds | ch/tf% | ex | gens | weak h | gives | dups |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 3 before | 137 | 98.0 | 95 | 0 | 0 | 1037 | 27.8 | 2.5 | 39 | 100 | 100 | 4.9 | 70 | 2224 | 492 | 0 | 0 | 1 |
| 3 now | 137 | 99.4 | 96 | 0 | 0 | 1037 | 27.8 | 2.4 | 42 | 100 | 100 | 4.9 | 70 | 2225 | 492 | 0 | 0 | 1 |
| 4 before | 137 | 98.0 | 95 | 0 | 0 | 1040 | 31.0 | 2.7 | 34 | 100 | 100 | 5.2 | 67 | 2043 | 528 | 0 | 0 | 0 |
| 4 now | 137 | 99.4 | 96 | 0 | 0 | 1040 | 31.0 | 2.7 | 38 | 100 | 100 | 5.2 | 67 | 2044 | 528 | 0 | 0 | 0 |
| 5 before | 136 | 97.6 | 95 | 0 | 0 | 1023 | 31.5 | 3.0 | 34 | 100 | 100 | 5.1 | 67 | 2075 | 571 | 0 | 0 | 1 |
| 5 now | 136 | 99.3 | 96 | 0 | 0 | 1023 | 31.5 | 3.0 | 38 | 100 | 100 | 5.1 | 67 | 2076 | 571 | 0 | 0 | 1 |
| 6 before | 136 | 97.6 | 94 | 0 | 0 | 1015 | 30.6 | 3.3 | 33 | 100 | 100 | 5.1 | 65 | 2137 | 532 | 0 | 0 | 4 |
| 6 now | 136 | 99.2 | 96 | 0 | 0 | 1015 | 30.6 | 3.2 | 36 | 100 | 100 | 5.1 | 65 | 2139 | 532 | 0 | 0 | 4 |
| 7 before | 99 | 95.1 | 83 | 0 | 26 | 716 | 31.5 | 3.7 | 31 | 100 | 100 | 5.1 | 65 | 1494 | 321 | 2 | 1 | 0 |
| 7 now | 99 | 98.8 | 94 | 0 | 0 | 716 | 31.5 | 3.6 | 38 | 100 | 100 | 5.1 | 65 | 1494 | 321 | 0 | 0 | 0 |
| all before | 645 | 97.4 | 83 | 0 | 26 | 4831 | 30.4 | 3.0 | 34 | 100 | 100 | 5.1 | 67 | 9973 | 2444 | 2 | 1 | 6 |
| all now | 645 | 99.3 | 94 | 0 | 0 | 4831 | 30.4 | 2.9 | 38 | 100 | 100 | 5.1 | 67 | 9978 | 2444 | 0 | 0 | 6 |

307 units scored higher, 0 lower.

The round's own measures (the same before and now):

| grade | units | long sentences | units with one | cards over 45 words | units with one | units short of pictures | pictures | units above grade + 1 | not in notes | score |
|---|---|---|---|---|---|---|---|---|---|---|
| 3 before | 137 | 27 | 24 | 0 | 0 | 37 | 403 | 6 | 8 | 98.0 |
| 3 now | 137 | 0 | 0 | 0 | 0 | 0 | 440 | 5 | 5 | 99.4 |
| 4 before | 137 | 42 | 33 | 6 | 6 | 33 | 357 | 3 | 10 | 98.0 |
| 4 now | 137 | 0 | 0 | 0 | 0 | 0 | 394 | 3 | 5 | 99.4 |
| 5 before | 136 | 44 | 38 | 9 | 9 | 36 | 347 | 0 | 18 | 97.6 |
| 5 now | 136 | 0 | 0 | 0 | 0 | 0 | 385 | 0 | 9 | 99.3 |
| 6 before | 136 | 69 | 48 | 8 | 7 | 30 | 333 | 0 | 14 | 97.6 |
| 6 now | 136 | 0 | 0 | 0 | 0 | 0 | 365 | 0 | 5 | 99.2 |
| 7 before | 99 | 90 | 50 | 17 | 15 | 27 | 222 | 0 | 30 | 95.1 |
| 7 now | 99 | 0 | 0 | 1 | 1 | 0 | 273 | 0 | 2 | 98.8 |
| all before | 645 | 272 | 193 | 40 | 37 | 163 | 1662 | 9 | 80 | 97.4 |
| all now | 645 | 0 | 0 | 1 | 1 | 0 | 1857 | 8 | 26 | 99.3 |

In words: all 645 units of grades 3-7 meet the bar (26 of grade 7's humanities did not); the mean score went from
97.4 to 99.3 and the lowest from 83 to 94. No sentence over 22 words is left but a quoted limerick (272 before), no
card over 45 words but the same one (40), no unit short of the audit's picture share (163), and 195 more lesson
pictures (1,662 to 1,857: 38% of the cards have one), 16 of them moving where motion is the lesson, and 4 exercises
that ask the child to watch the motion.

What the audit finds next (weakest first, the same tools): about 100 units whose exercises are more than 80% choice and
true/false (most of grade 3's English and science: a match, a sort or an order beside the choices would ask the same
in another way); 26 units not yet named in any notes (their facts' sources are in the grade agents' notes by subject,
not by unit); the 8 units that read above their grade on their own subject words; 6 near-duplicates kept (ruling 7).

## For the lead (round 2)

- **Merge:** the branch was rebased onto lead-merge at 7cac4a26 (after the visuals' merge), so it fast-forwards. The
  one conflict on the way was `tests/unit/test_lesson_short.gd`, which the lead had loosened in 4c9ef554 while this
  branch fixed `LessonShort.teaching`: kept both, the lead's headline check ("a headline from the lesson") and this
  branch's exact one for the first caption (the first sentence that teaches, by the Shorts' own rule) beside the lead's
  "never the quick memory". Outside the lesson files this round touches `core/shorts/lesson_short.gd` (`teaching`),
  `tests/unit/test_lesson_short.gd`, `tests/unit/test_school_quality.gd`, `tools/school_audit.py` and the docs; no
  picture-drawing code, and none of the Reel Studio's or the visuals' files.
- **After the merge:** `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md` (no title or
  outline changed, so it should be the same).
- **On the emulator (the School, a phone's size):** the moving pictures on their cards (grade 4 light's Moon, grade 5
  gravity's orbit with its arrows, grade 3 forces' two pendulums, grade 4 rockets' stages, grade 6 energy's pendulum
  with its bars, the water cycle in grade 4 geography); the four "watch" exercises move, the rest hold still; a few
  of the new tables at phone size (grade 3 private information, grade 7 cards and credit) and the Mongol fleets' map
  (grade 6 medieval Japan). A Lesson in a minute of a unit whose memory card has a lead-in line (grade 7 voyages): it
  should open on "Today: how sailors found their latitude…", not on the Equator's question.

The full suite on this branch after round 2 (2026-10-01, `tests/run_tests.sh`, 61 minutes with the PC shared): 1,033
scripts, 9,469 tests, 9,466 passing, 2 risky (the terrain's two tests that make no assert, as before), 1 failing:
`test_world_bulk_edits.gd`'s `test_scattered_cells_go_one_by_one` (a far cell not yet loaded when the load was over 20;
world code this branch does not touch), which passes on its own (3/3). The School's 117 test files (1,388 tests) passed
after every part.

# Round 3 of the lesson quality (2026-10-01, the lead's third brief)

Start: the lead's brief says to reset to `lead-merge`, or to `worktree-agent-abb89c3f242e2d600` when lead-merge does
not yet carry round 2. lead-merge (47f35a8b, after the Reel Studio's merge) has no round 2 commits, so this round starts
from **worktree-agent-abb89c3f242e2d600** (17b3b5b8: round 2 rebased on lead-merge at 7cac4a26). The brief's check
(`grep -c "moving pictures on lesson cards"`) finds 0 on both branches because round 2's commit says "the moving
pictures on the lesson cards"; the branch was chosen by its commits, not by that string.

Round 3's three parts: exercises that teach by doing (no unit over 70% choice and true-or-false), the 26 units no notes
named (facts checked, sources written down), and a learning check on difficulty (level 3 steps up from level 1). No
unit was added, no id changed, no exercise removed: new exercises are appended, so every old exercise keeps its id.

## The audit's new measures (`tools/school_audit.py`)

```bash
python3 tools/school_audit.py --not-yet   # two lists: NOT_YET (any rule of the bar) and NOT_YET_VARIED (only the 70% rule)
python3 tools/school_audit.py --flat      # the units whose level 3 asks less than 1.1 × level 1, with each level's demand
```

- **Variety** (`MAX_CHOICE_SHARE` 0.7, `mostly_choice`, column ">70%"): more than 70% of a unit's hand-written exercises
  are choice or true-or-false. It costs points, and it is part of the bar (`bar_problems` "variety").
- **Demand** (`demand`, `level_demand`, column "L3/L1" and "flat"): a rough measure of how much an exercise asks: the
  worked answer's reader words, plus 2 for each number in it, plus 3 for each step (sentences and "=" signs), plus half
  the prompt's words and its numbers, plus 2 for each item beyond two in an order, sort or match. A unit is "flat" when
  its level 3's mean demand is less than `STEP_UP` (1.1) × level 1's. It costs points but is not a test (ruling 15).

## Part 1: exercises that teach by doing (the 70% bar)

The first audit of round 3 found 352 of the 645 units over 70% choice and true-or-false (100 of them over 80%), most of
grade 3-7 English, science, citizenship and the arts. The bar now has a fifth rule, written test first:
`test_school_quality.gd`'s `bar()` adds "variety" when `_mostly_choice` (more than `MAX_CHOICE_SHARE` of the
hand-written exercises are choice or true-or-false); `NOT_YET_VARIED` listed the 352, a unit had to leave it as soon as
it met the rule, and `test_the_bar_finds_what_it_should` checks 8 of 10 (mostly choice), 7 of 10 (not) and an empty
list (not). The test failed on all 352 for "variety" before the list existed, and the list is empty now.

What the 352 units got, weakest first (100 over 80% in the first commit, then the other 252): **859 new exercises**:
354 sort, 202 match, 174 order, 126 number and 3 rhythm; 9 at level 1, 321 at level 2 and 529 at level 3. Each asks the
lesson's idea a new way: a sort where the choices tested one fact at a time (rights and responsibilities; Arctic or
Antarctica; on the beat or off it), a match of causes to effects or tools to jobs, an order of a process (the reflex
arc, a warm front's clouds, a woodcut's blocks, a forward roll), and a number that takes two or three steps (fourth
score from a mean, change from 10 gold, the lighthouses' common multiple). Most new level-3 exercises add a step the
level-1 ones did not need, and their worked answers show each step and a check. 46 existing exercises' worked answers
were filled out at the same time where their level-3 question was harder than its answer showed.

New facts that came with the new exercises, and where they were checked: sound in air about 340 m a second, so thunder
3 seconds after lightning is about 1 km away (the Met Office); a cricket boundary scores 4 along the ground and 6 over
it (MCC Laws of Cricket, law 19); tennis counts love, 15, 30, 40, game (the LTA); netball 7 a side, passing within 3
seconds (England Netball); rugby players run with the ball, basketball players dribble; at the coast call 999 for the
Coastguard, inland the fire service (the RNLI and the National Water Safety Forum); Egyptian figures drawn on a grid of
18 squares from the feet to the hairline (Gay Robins, Proportion and Style in Ancient Egyptian Art, 1994); Egyptian
blue made by heating sand, copper and lime over 4,000 years ago (the British Museum); Vivaldi's Four Seasons is 4
concertos of 3 movements, fast, slow, fast (printed 1725); Haydn's Surprise Symphony written in 1791 (first played in
London in 1792); Hildegard of Bingen 1098-1179; the bronze bells of the Marquis of Zeng about 2,500 years old (433 BC),
the Jiahu crane-bone flutes about 9,000, the lyres of Ur about 4,500, the German bone flutes about 40,000 (the British
Museum; Nature 2009 on the Hohle Fels flute); viscose is made from wood pulp; recycling aluminium saves about 95% of the
energy (the Aluminium Federation); hedgehogs eat slugs and beetles (the British Hedgehog Preservation Society); the
first home video game console in 1972 (the Magnavox Odyssey); manga, Hokusai's word for his sketchbooks (1814), means
something like playful or whimsical pictures. Made-up numbers (a glacier's length, a shop's prices, a game's music
loops) are said to be examples, never facts.

Two of the new rhythm exercises' worked answers did not name the boxes, which the grade 3 arts content test requires
of every "copy the rhythm" (`test_the_rhythms_to_copy_start_with_a_clap`); the School's test run caught it, the two
answers now say which boxes clap, and the batch script checks it before writing.

## Part 2: the 26 units not named in any notes, their facts checked

Round 2 left 26 written units that no agent's notes named (their sources were in the grade agents' notes by subject, not
by unit). Each was read card by card and exercise by exercise; every dated or measured fact is listed here with where
it was checked. Nothing was wrong enough to change; one point is a ruling (19, below).

- **g3.history.then_and_now** (Then and now): 1920s homes, many without electricity (oil and gas lamps, coal fires),
  washboards, mangles and outside toilets; classes of 40 or more, slates for the youngest; toys of wood, tin and cloth.
  Television first shown in 1926 (John Logie Baird's demonstration in London, 26 January 1926); the teddy bear about 1902;
  home video games from the 1970s (1972); gas lighting about 200 years ago (London's first gas street lights, in Pall Mall, from 1807).
  Sources: the Science Museum and the National Archives on homes and schools in the 1920s; the BBC's history of
  television; the V&A Museum of Childhood on toys.
- **g3.history.bronze_age** (The Bronze Age): smelting; copper first, bronze about 9 parts copper to 1 tin; metalworking
  in Britain from about 4,500 years ago (about 2500 BC, with the Beaker people); copper mined under the Great Orme in
  Wales and tin from Cornwall; the Dover Boat about 3,500 years old (about 1550 BC), seaworthy for the Channel. Sources:
  the British Museum (Bronze Age Britain), Great Orme Mines, Dover Museum.
- **g3.art.line_shape** (Lines and shapes): art vocabulary only (kinds of line, geometric and organic shapes, starting a
  drawing from simple shapes); no dated facts. Source: the National Curriculum for art and design, key stage 2.
- **g3.music.rhythm_notation** (Reading rhythms): crotchet (quarter note) one beat, two quavers (eighth notes) share a
  beat, the crotchet rest; ta and ti-ti are the Kodály rhythm names; 4 beats in a bar of 4/4. Source: ABRSM's music
  theory glossary.
- **g3.design_tech.sewing_weaving** (Sewing and weaving): running stitch, backstitch, overstitch, a knot at the back;
  warp and weft, plain weave over one, under one, swapping each row; needle safety. Source: the Design and Technology
  Association's primary guidance on textiles.
- **g4.computing.variables_intro** and **g5.computing.variables_at_work** (Variables): SET and CHANGE … BY as in Scratch
  blocks; every worked example traced again by hand (0, 10, 20, 15; 0 + 10 + 10 = 20 and 3 − 1 = 2; 90 + 20 = 110 > 100).
  Source: the National Curriculum for computing, key stage 2; Scratch's own block reference.
- **g4.art.light_and_shade** (Light and shade): tone, highlight, cast shadow; H pencils hard and light, B soft and dark,
  HB between; chiaroscuro (Italian, light-dark); Rembrandt (1606-1669) nearly 400 years ago; Leonardo's soft blending
  (sfumato). Sources: the National Gallery's glossary; the Rijksmuseum on Rembrandt.
- **g4.music.note_values** (Note values): semibreve 4 beats, minim 2, crotchet 1, quaver half; the US names whole, half,
  quarter, eighth; 4/4 bars. Source: ABRSM's music theory glossary.
- **g4.music.compose_melody** (Compose a melody): the pentatonic scale C, D, E, G, A (no F or B); the black keys make a
  pentatonic scale too; steps and leaps; the treble stave's spaces F, A, C, E. Source: ABRSM; the Oxford Companion to
  Music on the pentatonic scale.
- **g4.health_pe.gymnastics_sequence** (Gymnastics sequences): the five basic jumps (straight, tuck, star, pike,
  straddle), landing toes then heels with knees bent, the forward roll on a rounded back with the chin tucked, unison,
  canon, mirroring, counter balance and counter tension. Source: British Gymnastics' primary resources and the PE
  programme of study.
- **g5.computing.nested_loops** (Loops inside loops): 3 × 4 = 12 runs of the inner line; MOVE up a row runs 3 times; a
  pen square inside a loop of 3; 10 × 10 = 100; a clock's 60 minutes for every hour. Checked by tracing.
- **g5.art.greek_roman_art** (Greek and Roman art): the Doric, Ionic and Corinthian capitals (Greek Doric has no base);
  black-figure pots from about 700 BC and red-figure invented in Athens about 530 BC; painted marble statues (traces of
  colour); Roman copies of Greek bronzes; the Parthenon built 447-432 BC; Vesuvius buried Pompeii in AD 79. Sources: the
  Metropolitan Museum's Heilbrunn Timeline (Greek vase painting, the orders), the British Museum.
- **g5.art.textile_art** (Textile art): indigo blue, madder red, weld yellow; cochineal red from an insect; tie-dye,
  batik (wax resist; Indonesian batik on UNESCO's list since 2009), bandhani (India), shibori (Japan); kente woven in
  narrow strips (Ghana); twill and denim; the Bayeux Tapestry about 70 m long (68.4 m) telling 1066. Sources: the V&A
  (textiles, natural dyes), the Bayeux Museum, UNESCO.
- **g5.music.song_structure** (How songs are built): binary, ternary and rondo forms; Beethoven's Für Elise is a rondo
  (A B A C A); verse, chorus, bridge, intro, outro. Source: the Oxford Companion to Music; ABRSM.
- **g5.music.world_rhythms** (Rhythms of the world): the djembe (West Africa), polyrhythm and bell patterns, call and
  response; samba's surdo and the leader's whistle (apito) at carnival in Brazil; the gamelan of Indonesia, whose
  biggest gong (gong ageng) ends each cycle; the 3 + 3 + 2 pattern x--x--x- (the tresillo, from West Africa to Cuba to
  pop). Sources: the British Library's world music collections; the Southbank Centre's gamelan resources.
- **g5.music.read_melodies** (Reading melodies): note values with the dotted minim (3 beats); 4/4 and 3/4; steps from a
  line to the next space; the worked example 1 + 1 + 1 + 1 + 2 = 6 beats. Source: ABRSM.
- **g5.health_pe.emergency_first_aid** (Emergency first aid): DR ABC; check breathing for up to 10 seconds; the recovery
  position; 999 or 112 with the phone on speaker; the call handler talks anyone through CPR, and a defibrillator (AED)
  speaks each step; choking: encourage coughing, an adult gives back blows and calls 999. Sources: St John Ambulance's
  and the British Red Cross's first aid guides, Resuscitation Council UK.
- **g5.projects.biome_expedition** (A biome expedition): hot deserts under 250 mm of rain a year, tropical rainforests
  often over 2,000 mm; camels store fat in their humps and can go days without drinking; arctic foxes grow white winter
  fur; drip tips on rainforest leaves. Sources: National Geographic's biome pages; the Royal Geographical Society.
- **g6.computing.binary_numbers** (Binary numbers): bits, place values 1, 2, 4, 8, 16; binary cards (the CS Unplugged
  activity); 10110 = 22, 13 = 1101, 9 = 1001, 100 = 1100100, 202 from its byte; a byte holds 0 to 255. All checked by
  hand. Source: CS Unplugged (University of Canterbury, New Zealand), "Count the dots".
- **g6.computing.flowcharts_pseudocode** (Flowcharts and pseudocode): ovals, boxes, diamonds and arrows; SET, IF, ELSE,
  REPEAT, OUTPUT; the countdown 3, 2, 1, Lift off! traced; REPEAT UNTIL checks its condition first (as Scratch's "repeat
  until" does: ruling 19). Sources: the National Curriculum for computing; Scratch's block reference.
- **g6.computing.hardware_software** (Hardware and software): the processor's fetch, decode, execute; RAM forgets when
  the power is off; storage keeps files; 8 bits a byte, 1,000 bytes a kilobyte and so on (the SI prefixes, as GCSE
  specifications now use, with the kibibyte for 1,024); a 2 GB card holds 500 photos of 4 MB. Source: AQA's GCSE
  Computer Science specification (8525), section 3.3.
- **g6.design_tech.material_families** (Material families): hardwoods from broad-leaved trees (balsa among them),
  softwoods from conifers; plywood and MDF; ferrous and non-ferrous metals; steel (iron and carbon), brass (copper and
  zinc), bronze (copper and tin); thermoplastics (acrylic, polythene, PVC) and thermosets (melamine, epoxy); carbon
  fibre and reinforced concrete; pine about 0.5 g/cm³. Sources: the Design and Technology Association; BBC Bitesize
  GCSE D&T on materials.
- **g6.projects.market_town** (A medieval market town): a royal charter to hold a market; guilds that set prices and
  standards and trained apprentices for about 7 years; tolls on sales; the market court that settled quarrels on the
  spot (the court of piepowder); ratio and percent examples checked (6 ÷ 3 = 2, 10% of 30). Sources: the British
  Library's medieval towns pages; the National Archives on market charters.
- **g7.computing.secret_codes** (Secret codes): Julius Caesar (100-44 BC) and his shift of 3 (Suetonius); 25 shifts to
  try; al-Kindi (about 801-873) and frequency analysis; E the commonest letter in English; Alan Turing (1912-1954) and
  Bletchley Park's work on Enigma; public-key padlocks; a 5-digit PIN has 100,000 codes. Sources: Bletchley Park;
  Simon Singh, The Code Book (1999).
- **g7.music.chord_progressions** (Chord progressions): the chords of C major (I, ii, iii, IV, V, vi); the primary
  chords hold every note of the scale; IV and V in G major are C and D; perfect, plagal (Amen) and imperfect cadences;
  I-V-vi-IV. Source: ABRSM's music theory; the Oxford Companion to Music.

Each of the 26 is now named in these notes, so the audit's "not in the notes" cost is gone (26 before, 0 now).

## Part 3: does level 3 really step up? (a learning check on difficulty)

The School plays a unit's exercises in three rounds, level 1 (recall), level 2 (apply) and level 3 (reason, several
steps). The audit now measures each level's demand (above) and lists the units whose level 3 asks less than 1.1 × their
level 1. Before round 3, 211 of the 645 units were "flat" by that measure; the variety work, which put most of its new
exercises at levels 2 and 3 with worked answers of several steps, left 69; this part took the 69 one by one.

What a flat unit usually was: a maths unit with only two hand-written level-3 exercises, whose worked answers were a
bare result ("x = 45°", "12 × 15 = 180 m²"), beside a level-1 match or sort that asked four calculations at once and
explained all four. So each of the 69 got, as it needed:

- **a new level-3 exercise that takes several steps** (66 in all), mostly numbers and orders: an equation formed from
  a story and solved (3 friends' tickets, 3(t + 2) = 27), a discount then a tax, a path's area round a pond, the
  biggest third side of a triangle, a percent of the rest, a box twice the size (8 times the volume), the better
  buy's saving on 30 eggs, the 4th score from a mean, a ribbon cut in centimetres after metres;
- **level-3 worked answers that show their steps and a check** (97 answers): "Take 4 from both sides:
  −3x = 15. Divide both sides by −3: x = −5. Check: −3 × −5 + 4 = 19.";
- **a level-1 exercise moved to level 2** where it asked several calculations (a match of four sums, four conversions, four
  equations) and level 1 kept at least three hand-written exercises (19 exercises; ruling 16).

After it: 0 flat units, and the mean level-3 demand is 1.53 × level 1's (1.25 before round 3).

The measure is rough, and it is read as a prompt to look, not a verdict: a worked answer that lists numbers (the
factors of 18 and 24) scores high, and a short answer to a hard question scores low. "0 flat" says every one of the 69
was read and its level 3 now asks for more steps than its level 1; `--unit <id>` prints a unit's three demands.

## Rulings of round 3 (cost if wrong)

14. **At most 70% choice and true-or-false is part of the bar** (a test), with a ratchet list like `NOT_YET`
    (`NOT_YET_VARIED`, now empty). The brief set the number; choice stays the main kind because it is quick on a phone.
    Cost if wrong: one constant (`MAX_CHOICE_SHARE`) in the test and the audit.
15. **The difficulty measure is the audit's, not a test**: words, numbers and steps are a rough proxy, and a test would
    reward long answers for their own sake. Cost if wrong: a unit can turn flat again unnoticed until the next audit
    (`--flat` lists them in a second).
16. **Re-levelling**: a hand-written exercise moves up a level only when it asks several calculations or steps at once
    (a match or sort of four worked items) and its old level keeps three hand-written exercises (`MIN_A_LEVEL`). Ids do
    not change, and no exercise moved down. Cost: 19 exercises now come in the second round of a lesson, not the first.
17. **`STEP_UP` is 1.1**: level 3 asks at least a tenth more than level 1. Cost: one constant.
18. **New exercises of other kinds go mostly to levels 2 and 3** (916 of 925), because level 1 is recall and choice suits
    it. Cost: none.
19. **REPEAT UNTIL tests its condition first, as Scratch's "repeat until" does** (grade 6 flowcharts and pseudocode):
    some exam boards' pseudocode REPEAT … UNTIL tests after the loop's lines, so it runs at least once. The School's
    programs are Scratch-like blocks, so they keep Scratch's meaning. Cost if wrong: one exercise's answer and one line
    on a card, when the School reaches exam-style pseudocode in grade 8.
20. **The batch script checks before it writes** (sizes, letters, spelling, sums, prompts asked twice, rhythm boxes),
    and nothing is written when any exercise has a problem; the Godot check (`tools/school_check.gd`) then runs each
    exercise right by its own answer. Cost: none.

## After round 3 (2026-10-01): the audit before and after, per grade

`python3 tools/school_audit.py --compare` against the lessons at round 3's start (17b3b5b8), measured with round 3's
audit (so "before" already counts the new measures):

| grade | units | score | min | <70 | <bar | cards | w/card | FK | pic% | mem% | world% | kinds | ch/tf% | >70% | L3/L1 | flat | ex | gens | weak h | gives | dups |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 3 before | 137 | 96.3 | 89 | 0 | 97 | 1037 | 27.8 | 2.4 | 42 | 100 | 100 | 4.9 | 70 | 97 | 1.23 | 35 | 2225 | 492 | 0 | 0 | 1 |
| 3 now | 137 | 99.9 | 96 | 0 | 0 | 1037 | 27.8 | 2.4 | 42 | 100 | 100 | 5.3 | 63 | 0 | 1.44 | 0 | 2469 | 492 | 0 | 0 | 1 |
| 4 before | 137 | 96.9 | 93 | 0 | 75 | 1040 | 31.0 | 2.7 | 38 | 100 | 100 | 5.2 | 67 | 75 | 1.32 | 38 | 2044 | 528 | 0 | 0 | 0 |
| 4 now | 137 | 99.9 | 98 | 0 | 0 | 1040 | 31.0 | 2.7 | 38 | 100 | 100 | 5.4 | 61 | 0 | 1.5 | 0 | 2229 | 528 | 0 | 0 | 0 |
| 5 before | 136 | 96.6 | 91 | 0 | 76 | 1023 | 31.5 | 3.0 | 38 | 100 | 100 | 5.1 | 67 | 76 | 1.24 | 47 | 2076 | 571 | 0 | 0 | 1 |
| 5 now | 136 | 99.9 | 98 | 0 | 0 | 1023 | 31.5 | 3.0 | 38 | 100 | 100 | 5.3 | 62 | 0 | 1.46 | 0 | 2261 | 571 | 0 | 0 | 1 |
| 6 before | 136 | 97.0 | 91 | 0 | 64 | 1015 | 30.6 | 3.2 | 36 | 100 | 100 | 5.1 | 65 | 64 | 1.28 | 46 | 2139 | 532 | 0 | 0 | 4 |
| 6 now | 136 | 99.9 | 98 | 0 | 0 | 1015 | 30.6 | 3.2 | 36 | 100 | 100 | 5.4 | 60 | 0 | 1.67 | 0 | 2322 | 532 | 0 | 0 | 4 |
| 7 before | 99 | 97.0 | 91 | 0 | 40 | 716 | 31.5 | 3.6 | 38 | 100 | 100 | 5.1 | 65 | 40 | 1.15 | 45 | 1494 | 321 | 0 | 0 | 0 |
| 7 now | 99 | 99.9 | 98 | 0 | 0 | 716 | 31.5 | 3.6 | 38 | 100 | 100 | 5.4 | 60 | 0 | 1.61 | 0 | 1622 | 321 | 0 | 0 | 0 |
| all before | 645 | 96.7 | 89 | 0 | 352 | 4831 | 30.4 | 2.9 | 38 | 100 | 100 | 5.1 | 67 | 352 | 1.25 | 211 | 9978 | 2444 | 0 | 0 | 6 |
| all now | 645 | 99.9 | 96 | 0 | 0 | 4831 | 30.4 | 2.9 | 38 | 100 | 100 | 5.4 | 61 | 0 | 1.53 | 0 | 10903 | 2444 | 0 | 0 | 6 |

416 units scored higher, 0 lower.

In words: no unit is over 70% choice and true-or-false (352 were; the share is 61% across the School, from 67%), every
unit's level 3 asks more than its level 1 by the audit's measure (211 were flat), the mean score is 99.9 (96.7) and the
lowest 96 (89), and every written unit is named in these notes. 925 exercises were added (9,978 to 10,903) and 143
existing worked answers filled out; no lesson card, title, id or generator changed.

## For the lead (round 3)

- **Merge:** this branch's base is round 2's tip (17b3b5b8), which lead-merge has merged (02d71496), so round 3 merges
  onto lead-merge without the round-2 history again. Round 3 touches only `data/school/g3..g7/**` (lesson files: new
  exercises appended, worked answers, 19 levels), `tests/unit/test_school_quality.gd`, `tools/school_audit.py`,
  `docs/devlog/parts/lesson-quality.md` and a few lines of `docs/DEVELOPMENT.md`'s School section (lead-merge's
  DEVELOPMENT changes are in other sections); none of the Shorts', the Reel Studio's or the Wonders' files.
- **After the merge:** `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md` should
  print no change (no title or unit changed).
- **On the emulator (the School, a phone's size):** a few of the long new sorts and matches, for how the boards fit:
  grade 6 health "a feeling to notice, or time to get help" (six items of up to 41 letters), grade 7 citizenship "the
  Global Goals" sort (groups like "6: clean water"), grade 5 computing "Real or edited?" match (sides of up to 31
  letters), grade 4 history's Egypt order (items of 45 letters), grade 7 maths' rational-number order (−3/4, −0.7…).
- **Lessons in a minute:** they read the lesson cards, which round 3 did not touch, and borrow exercises' pictures, of
  which round 3 added none, so the Shorts are unchanged.

The School's 107 test files (1,276 tests) passed after each part of round 3 (after the first variety commit; after the
second, but for two rhythm worked answers without their boxes, fixed in that commit and the file re-run 12 of 12; after
the difficulty part). The full suite on this branch after round 3 (2026-10-01, `tests/run_tests.sh`, 55 minutes with
the PC shared): 1,033 scripts, 9,469 tests, 9,467 passing, 2 risky (the terrain's two tests that make no assert,
`test_the_column_cache_changes_nothing` and `test_chunks_meet_without_seams`, as before), 0 failing.
