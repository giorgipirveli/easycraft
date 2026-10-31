# Word Magic, phase A (research and design) (owner #133, #134)

The brief: `docs/superpowers/plans/2026-10-18-game-word-magic-brief.md`; the authority: `docs/design/future-lessons.md`
(the five tests, the four gated phases); the models of a good phase A: Inside a Leaf's, Balance Altar's and Fraction
Bakery's (`docs/design/games/leaf-voyage.md`, `balance-altar.md`, `fraction-bakery.md`, each with the lead's review at its
end). Phase A only: research and the design, no game code. Done on 2026-10-18 by the game agent on the worktree branch
`worktree-agent-a5602bafa6bc14014`, cut from lead-merge at `d11d6e46` (the brief). No editor, no emulator, no adb, no
agents, no Godot runs.

## What was delivered

- **The design:** `docs/design/games/word-magic.md`: the research (what children of 8-14 get wrong, with the numbers
  where they exist: looking at pictures, not print; over-regular forms; the plural s carried to verbs; the nearest noun;
  sentence boundaries; tense shifts; commas; vague pronouns; homophones; passives read as actives; misplaced modifiers;
  long words not broken into parts; grammar known as labels), why taught grammar transfers poorly to writing and what
  does (Writing Next, the elementary meta-analysis, the EPPI reviews, Exeter's contextualised grammar trial and its two
  failed replications, Englicious, sentence combining), the science of reading briefly (the simple view, phonics,
  orthographic mapping, self-teaching, speech on demand, text-to-speech as access, pictures and print attention, e-book
  extras, morphology, Matthew effects, English learners), games and apps with what their evidence says and does not say,
  the curriculum strand (36 units with their standards, ideas, exercises and generators; two open; 70 left to other
  games, named), the fantasy, the core loop, the verb for every idea and the Spell Reader's literal rules, the First Page
  and the Sleepy Dragons beat by beat with the rules from the models, the English door, the ladder (six floors, grades
  3-8, about 45 pages with their transfer pages), the reading track (how a child who cannot read yet plays, and how their
  own reading moves the fade: the voice, badges, the Word Lights, stage 2, the reading rooms), minute 1, 5 and 30 flat
  and in VR, every voice line of phase B (52 lines, each at most 12 words; no wish's line says its wish's words: checked
  by a script), the meanings of things, the music, the five tests answered with the models' numbers, the evidence model
  into `SkillShown` and the Keeper's journal, the look, the tech plan for phase B, phases and estimates, risks, 37 rulings
  with their costs, 13 open questions, an honesty table, and 47 new sources (and the standards, and Godot's TTS page).
- **The owner's page:** `docs/design/games/word-magic-owner.md` (one page, plain words, three pictures: 01, 03, 10).
- **Pictures:** `docs/design/games/word-magic/01-…12-*.png` and their `.svg` sources, drawn by
  `docs/design/games/word-magic/make_pictures.py` (`/usr/bin/python3 -I docs/design/games/word-magic/make_pictures.py
  [name …]`, rendered with `rsvg-convert`; about 10 s, most of it picture 12 running the models). Picture 12 (the cheat
  test, two small multiples of bars as the bakery's and the altar's) is computed from the models each time.
- **The models:** `docs/design/games/word-magic/model/`: `spell_rules.py` (cards, the lexicon of the First Page with the
  Jumble's made-up forms and stage 2's look-alikes, noun phrases' counts, clauses' agreement, wishes, the players), and
  four runs, each `/usr/bin/python3 -I <file> 1000 [--draft]`: `first_page_model.py` (the phase B slice, about 2 s),
  `sleepy_dragons_model.py` (the transfer room, about 1 s), `word_lights_model.py` (the reading record over ten
  sessions, about 8 s at 500 runs), `ladder_model.py` (eleven later rooms, about 9 s). They load `spell_rules.py` by its
  path, so they run with `-I` and leave no `__pycache__`. `--draft` prints the first drafts the models changed.

## The headline

- **The verb:** write it true. Word cards (each says its word when touched; a small picture shows what it is about,
  never its grammar; endings in gold ink) are laid on the Spell Ribbon and sealed with the star (the full stop casts).
  The Spell Reader does exactly what the sentence says, so the grammar is what happens: a noun's ending says how many
  come, a verb's form how many act and when; joining words decide order and cause; commas decide who is spoken to;
  runes change what a word does. Only the first cast counts; nothing previews a spell; every hand holds the tempting
  wrong card.
- **How a child who cannot read yet plays:** by ear. Every card and frame word speaks on touch; Hoot reads every cast
  spell with each word lighting; the meaning rooms' wrong cards *sound* wrong. The pictures leave word by word as the
  child reads (the Word Lights: three right picks in a row without touching, in different wishes); stage 2 (look-alikes
  that sound right) and the reading rooms (homophones, spelling) open when 20 words are lit. The voice never goes away.
- **The cheat test, measured** (1,000 visits per player, the First Page's eight judged wishes, the bar 7 of 8): knows how
  many (reads or listens) 100 %; slips on 4 % of picks 86.2 %; random cards 0 %; the picture badge 0 %; trial and error
  with the first cast counting 0 %; counts right with any form 0.2 %; "a gold ending means more" 0 %; "sounds like an s
  added" 0 %; "the longest word means more" 0 %; always the plain word 0 %; trial and error with a preview (not built)
  100 %.
- **The transfer test, measured** (the Sleepy Dragons, the bar 5 of 6): the idea 100 % (slips 89.3 %); the First Page's
  habit ("an s means more", carried to verbs) 0 %; copies the subject's ending 0 %; the nearest noun 0 %; always the plain
  verb 0 %; always the s verb 0 %; a coin 0.1 %. The ladder model's eleven later rooms: every named habit 0 % (runned;
  "because" for "so"; listening in the Homophone Hall 0.1 %; a comma where you pause; always at the end; the and-chain;
  the first noun is the doer; un- for every not; the familiar roots; the nice word), guessing at most 1.2 %, the idea 100 %.
- **The reading record, measured** (the Word Lights model, sessions 1 / 2 / 10): a reader has 51 % / 90 % / 99 % of the
  words it reads lit; a child who touches every card none (its pictures stay); a guesser 3 % / 6 % / 7 % lit falsely; a
  first-letter reader 4.5 % / 9 % / 10 %.
- **The ladder:** floor 3 The Summoning Hall, 4 The Rune Workshop, 5 The Clockwork Library, 6 The Loom, 7 The
  Observatory, 8 The Rule Stones; each floor's transfer page is writing for a buddy who acts it out.
- **Thirty-six units** become P1 when their rooms ship (716 hand-written exercises, of which only 116 play without
  reading today; 214 cards, 5,172 words); `g3.english.word_meanings` and `g7.english.connotation_tone` are open.
- **Phase B:** the First Page and the Sleepy Dragons, flat and VR: 7 agent sessions (6 with the leaf's B2 registry hook
  and a proven deep-game host; 6-9 with surprises, mostly the voice on devices). Phase C: C1 (floors 3-4, 16 pages, 14
  units) about 16-20 sessions; C2 (floors 5-8, 27 pages, 22 units) about 22-28.

## What the models changed in the design

1. **The First Page's composition.** The first draft (one gap a wish, the number already in the frame, regular nouns
   only, two cards a gap) let three habits that read the visible ending ("a gold ending means more", "sounds like an s
   added", "the longest word means more") grant every wish on **100 %** of visits. The page now has a number gap and a
   noun gap in every wish, wild words (mice, geese, children), sheep, leaves, the Jumble's made-up forms in every wild
   hand, two wishes for one thing (one wild) and a four-gap Parade: every habit 0 % (ruling 11).
2. **Nothing previews a spell; only the first cast counts** (rulings 6, 7): with a preview, trial and error wins every
   visit; without, 0 %.
3. **The dragons' room.** One verb a wish let a coin reach the bar on **11.0 %** of visits: every wish now links two or
   three decisions. A second draft with one compound subject still let "agree with the nearest noun" pass **100 %**: the
   room now has two compound subjects, each beside a clause about one thing (ruling 12).
4. **The Word Lights' rule.** One right unaided pick (or two) let a guesser light most words within two sessions (63 %
   and 27 % after the first); three in a row with a reset held guessing to a few per cent, but putting a badge back after
   one wrong pick kept about one word in eleven dark for a real reader; the final rule needs two wrong among the word's
   last three (ruling 18).
5. **Every hand holds the tempting wrong card** (ruling 9): in the ladder model, hands that drew their other cards at
   random let "because for so" pass 12.2 % and "un- for every not" 19.4 % whenever the tempting card happened to be
   missing; the first drafts of nine later rooms let a named habit pass 10-100 % (regular verbs only; lists only; a phrase
   always at the end; no slot limit on the Loom; one homophone or one scene a wish; one job at the Forge; always a warm
   feeling).
6. **Stage 2 is reading evidence, not a wall:** at stage 2 a child who only listens still masters the First Page (its
   look-alike wish right half the time), so the look-alikes record reading and the grade does not open stage 2: reading
   does (ruling 20).

## How the research was done (and what is uncertain)

Web reading (WebSearch and WebFetch); nothing was downloaded and no file was saved by the fetch tool this time (checked
afterwards: no PDF, doc or epub appeared anywhere). Most figures come from abstracts, publishers' and repositories'
pages, clearinghouse pages (the EEF, the What Works Clearinghouse), PubMed Central and summaries. Honest flags:
- **Self-reported, vendor-funded or promotional:** Duolingo ABC's "28 %" (a company-funded study, reported in sponsored
  content); NoRedInk's WestEd analysis (vendor-partnered, a correlation) and case studies; GraphoGame's "0.48 with adult
  engagement" (as reported on the developer's own page; the review itself not read); Lexia's 0.08 (Lexia's own summary of
  the EEF trial; the EEF's own page says one month); Teach Your Monster to Read (testimonials only, no trial found).
- **Second-hand (as reported, the original not read):** Writing Next's -0.32 (11 studies) and +0.50 (5 studies), from
  notes of Graham's own talk and summaries; Graham et al. 2012's -0.41 (a summary table); Hunt's T-unit growth (summaries;
  the lengths not checked, so none are quoted); Brown's 14 morphemes (the study confirmed; the ranks of the plural and the
  third-person -s as commonly reproduced); Bever's first-noun strategy (as described in later papers); the 7 % of time on
  print (Evans & Saint-Aubin; Justice et al.: as reported by a later paper); the phonics grade figures (0.56, 0.54, 0.27:
  a secondary summary); Goodwin & Ahn's effect sizes; White, Sowell & Yanagihara's prefix and suffix shares (as quoted by
  Marzano); Connors & Lunsford's commonest error (Otte's review) and the top-twenty list (a handout that attributes it to
  their 1993 data); Lunsford & Lunsford's "wrong word" (a blog's account of their table); Jones, Myhill & Bailey's 0.21;
  Exeter's 20 % against 11 % (a teachers' summary).
- **Not found:** prevalence figures for children's agreement attraction, tense shifts, vague pronouns and run-ons by
  grade (the table says "no prevalence figure found"); Saddler & Graham 2005's outcomes (the WWC page shows only that it
  meets standards); Baumann et al. 2003's results (not cited); a controlled study of Scribblenauts or of Montessori
  grammar symbols; any meta-analysis of grammar games.
- **Contested:** Samuels' focal-attention hypothesis (critiqued by Arlin, Scott & Webster; one small kindergarten study
  found picture flashcards better); the design takes the cautious reading (pictures never carry grammar and leave as
  reading grows).
- The strand's counts were computed from the units' own files and `tools/play_audit.py --json` (run read-only into the
  session scratchpad); the generators' word lists from `core/school/gen/g3_words_gen.gd` and `g4_english_gen.gd`.

**The voice lines** were checked by a script (`/usr/bin/python3 -I check_lines.py docs/design/games/word-magic.md`, kept in
the session scratchpad, not the repo): 52 lines, the longest 12 words; the only questions are spoken ones answered by
picture buttons (H20, G1, G2); no wish's line contains its wish's words (W1-W7 against their nouns).

## What the lead should check

1. The design's open questions (§8): the dragons' events (NEW_SETTING for `nouns_pronouns` or SOLVED for
   `verbs_tenses`); `word_meanings` and context clues; the English door's rule while the reading units have no game;
   where the tower stands in phase C; the registry hook; a recorded voice; the reading track's numbers; badges by grade;
   a phonics game for non-decoders; the Jumble's made-up words on screen; when phase B starts; the grown-ups' page; a
   reading font.
2. Show the owner `word-magic-owner.md`.
3. Phase B's brief from §4 (7 agent sessions; one agent, four briefs, the lead's checks between; the voice on the
   emulator and the Quest in the last).

## Rulings of this run (the design's §7 has all 37 with their costs)

The most consequential: writing a sentence that comes true, read literally, is the core verb (1); cards, never typing,
never a microphone (2); not a phonics course (3); badges never show grammar (4); every card speaks on touch for ever (5);
only the first cast counts and nothing previews (6, 7); every hand holds the tempting wrong card (9); the First Page's and
the dragons' compositions (11, 12); a verb's form deciding how many act is a fiction the honesty table names (13); wish
lines never say the wish's words (14); the Word Lights are the Keeper's journal, not `SkillShown` events (17); the
lighting rule and badges by grade (18, 19); stage 2 opens by reading (20); the English door opens Word Magic while the
reading units have no game (24); a cast is read word by word (26).
