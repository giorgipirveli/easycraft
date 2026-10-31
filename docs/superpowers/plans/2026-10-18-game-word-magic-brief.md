# Word Magic — phase A (research and design) — the agent brief (owner #133, #134)

The owner (2026-10-17): "consider no one will start reading in the game, we have to rethink all this, try to deliver
education without just reading", and "each game needs a lot time power and thinking … we need future lessons, not just
texts with visuals like slides". **Read `docs/design/future-lessons.md` first: it is the authority** (the five tests:
choice, mute, cheat, transfer, wow; the four gated phases). This is the fourth game and the first for English, one game,
in depth; this run is **phase A only: research and design, no game code**. Three phase A's have passed the lead's review
and are the model: `docs/design/games/leaf-voyage.md`, `balance-altar.md`, `fraction-bakery.md` (each with the lead's
review at its end), their owner pages, pictures and `model/` simulations (the cheat and transfer tests run as numbers
before any game code; each game's models changed its design, which is their point). Work autonomously; do not ask
questions (decide, and write each ruling down with its cost).

## The game (the seed, `docs/design/learning-is-play.md` "English")
English, grades 3-8. Spells are sentences and grammar is the magic: nouns summon, adjectives shape, verbs act, adverbs
say how, tenses say when (a spell in the past shows what was, in the future what will be), conjunctions chain spells,
punctuation ends and joins; prefixes and suffixes are runes that change a word (un- turns the light off). The world
answers exactly what the spell says, so a wrong word does something visibly, funnily wrong, never a red cross.

**The hard part, and the reason this game is in the queue:** here reading *is* the skill. Hidden words are not an option,
so the design must say how a child who cannot read yet still plays from minute one (every word card speaks when touched;
pictures on the cards at the first rungs; Hoot reads a spell aloud as it is cast) and how the support fades as reading
grows, without ever making a non-reader feel stuck or a reader feel babied. The mute test becomes: "playable by a child
who cannot read yet", and the ladder must show the path from there to reading and writing sentences.

**No microphone, ever** (the game's rule: nothing personal kept or sent, no microphone). Spells are built by touching and
placing word cards and runes (in VR: picking them up and slotting them into a staff, a book or a circle), never spoken
into the device. The game speaks; the child builds.

## What to produce (`docs/design/games/word-magic.md`, plus pictures)
1. **Research** (cite each source; reading the web is fine, nothing downloaded; if a fetch saves a file by itself, delete
   it and say so; mark self-reported or second-hand figures): how children of 8-14 learn grammar and why taught grammar
   lessons transfer poorly to writing (and what does: sentence combining, grammar in context); the science of reading
   briefly (decoding, word recognition, morphology for older readers; the evidence for teaching prefixes, suffixes and
   roots); what games and apps do for grammar and early reading and what the evidence says and does not say (name the
   self-reported results); common errors by grade (run-ons and fragments, tense shifts, pronoun reference, comma use,
   commonly confused words); the curriculum strand from our units (`data/school/g3..g8/english/*`, the grammar,
   punctuation, word-building and vocabulary units: e.g. `nouns_pronouns`, `adjectives_adverbs`, `verbs_tenses`,
   `joining_sentences`, `punctuation_speech`, `word_building`, `word_parts`, `relative_words`, `sound_alike`,
   `conjunctions`, `perfect_tenses`, `commas`, `roots`, `homographs`, `affixes_roots`, `pronouns`, `sentence_variety`,
   `connotation`, `word_relationships`, and grades 7-8's) with each unit's standards. Say which English units Word Magic
   does not cover (reading comprehension, stories, argument: Story Theater, Detective Reader and Persuade the Council in
   the queue).
2. **The design document**, concretely (as the three before): the fantasy and purpose; the core loop; **the verb that is
   the concept** for each idea; **the five tests** answered, with **small simulation models** that show guessing cannot
   win (random cards, the always-noun player, the "longest word" player, the right word class but the wrong tense, the
   comma-everywhere player, greedy single-card fixes) and the rule does, and a transfer test in a new setting; **the
   ladder** grades 3-8 (from picture cards read aloud to plain written words; levels, transfer levels; how the child's
   own reading moves it); **minute 1, 5 and 30**, flat and VR; **show, say, do** with every voice line (≤ 12 words, never
   a question that needs reading); **what the game records** through G0's `SkillShown`; **the look** (where the magic
   happens, the cards, the runes, what spells do: sketched as pictures you make); **the tech plan for phase B** (on G0's
   foundation, the host registry Inside a Leaf's B2 builds, `PlayVoice`/`ReadAloud` and the device's text-to-speech,
   `SkillShown`; DISCOVER and W1's Academy English door, `AcademyPlaza.opens()`; where it lives in the world; VR); risks
   and rulings; an honesty table (what is real English, what is simplified, what is magic).
3. **A one-page plain-words summary for the owner** (`docs/design/games/word-magic-owner.md`) with three pictures.

## Rules
- Read also: `docs/design/learning-is-play.md`, spec §22.0, G0's notes (`docs/devlog/parts/play-g0.md`) and
  DEVELOPMENT.md's "The foundation's API, for the game agents", W1's notes (`docs/devlog/parts/play-w1.md`), the three
  approved designs' notes (`docs/devlog/parts/game-leaf-a.md` if present, `game-altar-a.md`, `game-bakery-a.md`).
- English only (the game has no translations or language picker; never add one).
- Write only under `docs/design/games/` and your notes `docs/devlog/parts/game-words-a.md`. Never open the editor or an
  emulator, never touch adb; never merge into lead-merge or push; no downloads; never start agents; no Godot runs (this
  phase has no game code). Python for the models (`/usr/bin/python3`, the standard library and what is installed), heavy
  runs under `nice`. Commits end with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. The owner
  is "they".
- Report: branch, commits, the design's headline (the verb, the five tests with the models' numbers, the ladder, how a
  non-reader plays), what the models changed in the design, the open questions the lead must decide, and phase B's
  estimate in agent sessions.
