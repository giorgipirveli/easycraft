# Word Magic — the design (phase A)

The fourth future lesson and the first for English (owner #133, #134; `docs/design/future-lessons.md` §5). This is
**phase A**: the research and the design, reviewed by the lead (and shown to the owner as `word-magic-owner.md`) before
any code. The brief: `docs/superpowers/plans/2026-10-18-game-word-magic-brief.md`. Pictures: `docs/design/games/word-magic/`
(drawn by `make_pictures.py`). The models: `docs/design/games/word-magic/model/`. Notes on how this was made:
`docs/devlog/parts/game-words-a.md`. Written 2026-10-18 on the worktree branch `worktree-agent-a5602bafa6bc14014` (cut from
lead-merge at `d11d6e46`, the brief).

The owner, 2026-10-17, after watching their child play for half an hour and meet no learning: "consider no one will
start reading in the game … deliver education without just reading", and "we need future lessons, not just texts with
visuals like slides". In fractions and algebra the answer was to take the words away. In English that is impossible:
**the words are the material, and reading is the skill**. So the question this design answers is: what would a child of
8 to 14 do with their hands, by choice, that *is* grammar; that a child who cannot read yet can play happily from the
first minute; that carries that child towards reading and writing real sentences; and that nobody can win by guessing.

---

## 0. In one page

**The fantasy.** At the Discovery Academy stands **the Word Tower** (W1's English door already bears that name). At its
top, under a dome painted with stars, lies **the Great Book**, open on a lectern; its two pages fold up into a little
**pop-up valley** drawn in pencil: hills, a pond, a path, a few cottages, all grey and blank, nobody living there. The
child is the Tower's new **Word Keeper**, Professor Hoot (in a wizard's hat) their teacher. The Book has one law:
**whatever is written true on its golden ribbon comes true in the valley.** A spell is a sentence. The valley's living
buddies (EasyCraft's block creatures with googly eyes) come to the page's edge with wishes in thought bubbles (pictures:
three mice and a cheese; presents falling from the sky); the child writes the sentence that makes the wish true; the
words lift off in ink, fly into the page, and the thing appears there while its patch of pencil valley blooms into
watercolour. A wrong word does exactly what it says: one duck flaps in beside four empty outlines; a made-up word brings
**the Jumble**, an ink blob from the inkwell that giggles, sneezes ink and hops home. A night ends with **the Story
Parade**, everything the child wrote marching across the coloured page. Each floor of the tower is a school year, with
its own Book.

**The verb that is the concept.** *Write it true.* Word cards come off the tower's shelves; each **says its word when
touched**, and at first a small picture badge shows what the word is about (a fox), never its grammar (the badge on
"foxes" shows one fox). The child lays cards on the **Spell Ribbon** in order and seals the spell with the **star** (the
full stop: punctuation is the cast). **The world does exactly what the sentence says, so the grammar is what happens**:
a noun's ending says how many come, a verb's form says how many act and when, an adjective shapes, an adverb says how,
a joining word decides which event comes first and why, a comma decides who is spoken to, a rune (un-, re-, dis-; -ful,
-less) changes what a word does. Only the first cast counts, nothing previews a spell, and every hand holds the tempting
wrong card.

**A child who cannot read yet** plays from minute one by ear: every card speaks when touched, Hoot reads every cast spell
aloud with each word lighting as it is said, and the early rooms' choices *sound* different (fox, foxes; mouse, mice,
mouses). The support fades word by word with the child's own reading: a word picked right without touching it, three
times in a row in different wishes, **lights gold** in the child's Spellbook and loses its picture; when enough words
are lit, **stage 2** opens, where wrong cards *sound* right and only reading tells them apart (ponies, ponys), and the
reading rooms (homophones, spelling) open. The voice never goes away: a non-reader is never stuck, only not yet tested.

**The five tests** (the models' numbers: 1,000 seeded visits per player, §3.9).

| Test | This game's answer | Checked in phase B by |
|---|---|---|
| Choice | Words that make things appear; a valley that fills with colour because of you; buddies with wishes; the Jumble's sneezes; short wishes (20-40 s), nights of 6 minutes; in VR you pull cards off a shelf and tap the star with your own Magic Wand; later, your own page of wishes for a friend | The owner's child: do they start the Sleepy Dragons unasked, and come back another day? |
| Mute | Playable by a child who cannot read yet: the wish is a picture, every card speaks, the spell is read aloud as it lands, the meaning rooms' choices sound different; words are on screen because words are the subject, and none has to be read before it has been heard | Every card, frame word and line is spoken (a test); a child who cannot read yet plays the First Page by ear (the model's listener reaches the bar on 100 % of visits); the owner's child plays it |
| Cheat | Random cards, the picture badge, "a gold ending means more", "it sounds like an s added", "the longest word means more", "always the plain word", counting right with any form, trial and error with the first cast counting: the First Page's bar (7 of 8 first time) is reached by **100 %** of visits that know how English says how many (86.2 % with slips on 4 % of picks) and by **0-0.2 %** of every other player | Bots in the tests (the models' players, thresholds as tests) |
| Transfer | Every floor has rooms where the old habit fails. Phase B ships **the Sleepy Dragons**: on a noun an s means more, on a verb it means one ("the dragons snore", "the baby sneezes"); the First Page's habit reaches the bar in **0 %** of visits, the idea in **100 %** (89.3 % with slips). Eleven later rooms modelled: each named habit (runned, "because" for "so", the apostrophe means "belongs", a comma wherever you pause, the first noun is the doer, un- for every "not", the and-chain…) **0 %**, guessing at most 1.2 % | Phase B: the habit bot never wins the dragons, the idea bot always; a child solves it unhelped |
| Wow | A pencil valley blooming into watercolour where the words land; ink flying off the ribbon as Hoot reads it; the Jumble; a dragon that snores alone while its friends sleep on; the Story Parade; in VR the cards in your hand and the star under your wand | The owner's verdict; whether the child shows it to someone |

**The ladder (grades 3-8), the tower's six floors**: floor 3 *The Summoning Hall* (nouns and number, pronouns, time,
shaping words, joining, speech marks and owners, runes, spelling, shades of meaning), floor 4 *The Rune Workshop*
(-ing time and helping verbs, adjective order and place words, who/which/that, whole sentences, homophones, commas in
speech, word parts), floor 5 *The Clockwork Library* (perfect tenses, either/or, commas, titles, roots, two-faced
words), floor 6 *The Loom* (pronoun case and clarity, extra information, sentence combining, affixes, word webs,
connotation), floor 7 *The Observatory* (clauses, sentence kinds, wandering phrases, comma adjectives, roots, tone),
floor 8 *The Rule Stones* (verbals, voice, moods and rules, pauses, word relationships). It covers **36 units** of our
English strand (two more are open questions) and makes each P1 when its room ships (§2.5).

**Minute 1:** up the tower's stairs to the star-domed room; the Book's pencil valley; the ghost lays "frog" and "jumps"
on the ribbon and taps the star; Hoot reads "A frog jumps!", the ink flies, a frog splashes into the pond and the pond
turns blue. **Minute 5:** the mice's wish: "three" and "mice" (the Jumble's "mouses" left on the shelf); three mice nibble
the cheese and the pond's meadow is green. **Minute 30:** the First Page and the Story Parade, the Sleepy Dragons (one
dragon snored alone, then all four), the Shaping Room (the tallest tower), three words lit gold in the Spellbook.

**Phase B** (the vertical slice): the First Page and the Sleepy Dragons, flat and VR, complete and beautiful. Estimate:
**7 agent sessions** (6 if Inside a Leaf's phase B2 has landed the registry hook for deep games and another deep game has
proved its host pattern; 6-9 with surprises, mostly the voice on devices, §6). The open questions for the lead are in §8.

---

## 1. The bar this game must clear

From `future-lessons.md` §2 (the authority): a future lesson is a game a child chooses to play, where the knowledge is
the only way to win, nothing has to be read, and the game knows what the child learned from how they play. Five tests
(choice, mute, cheat, transfer, wow), four gated phases. From `learning-is-play.md` §3: the concept is the mechanic, play
first and words after, the world answers, shown when stuck, short and again, in the world and for the world, words as
tools ("reading is taught only where reading the word is itself the move"). EasyCraft's own rules: calm, kind, never
scary, no gambling, no pressure tricks, English only (never a translation or a language picker), nothing personal kept
or sent, **no microphone, ever**, flat and VR, the phones' budget.

Three things are special about English:
1. **Reading is the skill, so the words cannot be hidden.** The bakery could keep numerals away until stage 2. Here the
   cards *are* words. The mute test becomes "playable by a child who cannot read yet", and the design must also make
   reading *necessary* exactly where reading is the skill (homophones sound the same; only the eye tells "their" from
   "there"), and nowhere else.
2. **Children already speak the grammar.** A native-speaking eight-year-old says "mice", "ran" and "the dogs bark"
   without knowing why. What school adds is the written forms (spelling an ending, punctuation), the forms speech
   rarely uses (the perfect tenses, the passive, the subjunctive), choosing forms on purpose, and words to talk about
   them. And the strongest finding in writing research is that **grammar taught as naming parts does not improve
   writing**; using grammar to make meaning (sentence combining, grammar in context) sometimes does (§2.2). So the game
   must never be "find the noun": every form must *do* something, and the words for the parts come only after use.
3. **A sentence's grammar changes its meaning quietly.** "The dragons snore" and "the dragons snores", "Let's paint,
   Pip!" and "Let's paint Pip!": the difference is one letter or one mark. The game makes the world act the sentence out
   literally, so every difference is something you see. Where real English is redundant (a verb that doesn't agree
   changes nothing in real life), the world's literal reading is a fiction, and the honesty table (§9) says so.

Some players will be children learning English as another language. The game stays English-only (owner #52), so its
support is the same for everyone: pictures for what words are about, a voice for every word, a world that shows what
each sentence means.

---

## 2. Research

### 2.1 What children of 8-14 get wrong, and what fixes it

| What children do | Who, how often | Why it sticks | What fixes it (the research) | How this game fixes it |
|---|---|---|---|---|
| **Look at the pictures, not the print** | In shared picture-book reading, preschoolers' eyes were on the print only about **7 %** of the time (eye-tracking: Evans & Saint-Aubin [R11], Justice et al. [R12]; the 7 % as reported by a later paper) | Pictures carry the story; the print looks like decoration | Pictures paired with new words can slow learning the words (Samuels' focal-attention hypothesis [R9], disputed; words alone were learned fastest by 5 of 6 students in Didden et al. [R10]); highlighting each word as it is read doubled the time on print, **19 % to 38 %** (61 children aged 4-5, Liao et al. [R13]) | **A card's picture shows what the word is about, never its grammar**: the badge on "foxes" is one fox, so the ending must be heard or read. Badges fade word by word as the child reads (§3.6). Every cast spell is read with each word lighting as it is said |
| **Make-up regular forms**: mouses, sheeps, runned, goed | In speech, rare: a median of **2.5 %** of irregular past forms in 83 children's recorded talk (Marcus et al. [E2]); in writing, forming plurals and past tenses is a grade 3 standard (L.3.1b, L.3.1d) and our own units' commonest wrong options are these forms (`G3WordsGen`'s "wrongs", likeliest first) | A rule that works for most words is applied to all | Meeting the irregular form in use; the rule's limits made visible | **The Jumble's words**: a made-up form is a card like any other; cast, it summons the Jumble, never the thing. Wild words (mice, geese, children, sheep) are in every room's hands |
| **"An s means more than one" carried to verbs** (the dogs barks; he go) | Children master the plural -s years before the verb's third-person -s: in Brown's study of three children's 14 grammatical morphemes the plural came early and the third-person -s among the last (the order as commonly reproduced; the book itself not read here [E1]) | The same sound means "more" on a noun and "one" on a verb | Agreement used in meaning, not as a rule to recite | **The Sleepy Dragons** (§3.5b): the verb's form decides how many dragons act; "-s means more" picks the wrong form every time (the model: **0 %**) |
| **Agree with the nearest noun** (the fox and the dragon laughs) | A known error in agreement; no prevalence figure found for children | The noun beside the verb looks like its subject | Compound subjects met on purpose | Two compound subjects in the dragons' room (the model's second draft let this habit pass every visit) |
| **Run-ons and fragments; no sentence boundary** | Our grade 4 unit's own errors (L.4.1f); a whole chapter of Kress's study of children's writing is how the idea of "a sentence" develops [E4]; comma splices, fragments and fused sentences are among college writers' commonest marked errors (Connors & Lunsford [E5], as listed in a later handout) | Speech has no full stops; "and then" joins everything | Building sentences, not labelling them; sentence combining [W1][W4] | **The star seal is the cast**: a fragment cannot be sealed (Hoot: "Who? Doing what?"); two spells on one ribbon with no joint crash into each other (§3.6, 4.4) |
| **Tense shifts and wrong tense forms** | Our grade 5 unit names the shift ("She opened the door and sees a fox"); no prevalence figure found for children | Stories are told aloud in a mix of tenses | Time made visible | **Time Windows** (3.3): a spell's tense decides *when* it happens (an old photo, now, a dotted plan); "add -ed" (runned) and "always now" **0 %** (the ladder model) |
| **Commas: none, or one wherever you pause** | A missing comma after an introductory element was the single most frequent error in Connors & Lunsford's 1988 study of college papers (per Otte's review) [E5]; three of the five commonest errors there were missing commas | Commas taught as "where you breathe" | Commas that change meaning ("Let's eat, Grandma!", which our own unit uses) | **The Comma Bridge** (5.3): a missing list comma fuses a cat and a dog into a cat-dog; a comma before a name makes Pip help, none makes Pip the thing painted; "comma everywhere" and "comma where you pause" **0 %** |
| **Vague pronouns; pronoun case** (When Ali met Ben, he laughed; me and Sam went) | Vague pronoun reference is among college writers' commonest errors (the same handout, second-hand [E5]); no figure for children | The writer knows who "he" is | Seeing what the reader would think | **Who Did It?** (6.1): an unclear pronoun's arrow splits and both laugh; "it" sticks to the nearest thing it can (the log sings) |
| **Commonly confused words** (their, there, they're; its, it's) | "Wrong word" replaced misspelling as the commonest error in college papers (Lunsford & Lunsford [E6], as reported); its/it's is on the handout's top-twenty list [E5] | They sound the same; spellcheck can't see them | Spelling tied to meaning | **The Homophone Hall** (4.5), a reading room: the cards all *say* the same sound; only reading tells them apart (the model: the listener **0.1 %**, "the apostrophe means it belongs" **0 %**) |
| **Passives read as actives: the first noun is the doer** | Children of 3-4 act out "the girl is followed by the boy" as the girl following; by about 5 reversible passives are understood (as reported of Bever 1970 and later work [E3]) | Word order usually says who did it | The doer and the spotlight made visible | **The Spotlight** (8.2): the sentence's subject stands in the light, the doer is who acts; "the first noun is the doer" **0 %** |
| **Misplaced and dangling modifiers** | On the same handout's list [E5]; our grade 7 unit's own example: the school with a wagging tail | The writer sees the picture the reader doesn't | The reader's literal picture | **The Wandering Phrase** (7.3): a describing phrase sticks to the noun beside it, so the school grows a tail |
| **Long words not broken into parts** | Morphology instruction helps less able readers *more* (22 studies, preschool-grade 8: Bowers, Kirby & Deacon [R14]); four prefixes (un-, re-, in-, dis-) cover about 58 % of prefixed words in school texts, and -s/-es, -ed, -ing about 65 % of suffixed ones (White, Sowell & Yanagihara, as quoted [R16]) | Words are seen as wholes | Word parts taught and used | **Runes**: endings are drawn in gold on every card; prefix and suffix runes snap onto words and change what they do (un-lock opens the lock); the Word Forge names gadgets from roots |
| **Grammar known as labels, not used** | See §2.2: grammar taught in isolation had a small *negative* average effect on writing quality | Labelling is easy to teach and to test | Grammar as choices that make meaning [W5][W6] | Nothing is ever labelled in play; the parts get their names only after the child has used them ("Grown-ups call these nouns") |

**What we take from this:** (1) pictures help a non-reader find a word but must never carry the grammar, and must leave
as reading grows; (2) every form choice must change what happens, visibly; (3) the habits that work for easy cases
(add an s, add -ed, a comma where you pause, the first noun is the doer) must meet wishes where they fail; (4) sentence
building, not labelling; (5) words are built from parts, and the parts should be seen.

### 2.2 Grammar and writing: why taught grammar transfers poorly, and what does

| Finding | Source | What we take |
|---|---|---|
| **Writing Next**, a meta-analysis for grades 4-12: explicit grammar instruction had an average effect on writing quality of **-0.32** (11 studies), the only negative one of the practices reviewed; **sentence combining +0.50** (5 studies) | Graham & Perin 2007 [W1] (the figures as recorded from Graham's own talk and in summaries; the report itself not read here) | Never teach grammar as naming; sentence combining is a verb (the Loom, chain spells) |
| A meta-analysis for grades 1-6: grammar instruction **-0.41** (4 studies; the interval spans zero), the only category without a significant effect | Graham, McKeown, Kiuhara & Harris 2012 [W2] (as reported in a summary table) | The same |
| Two systematic reviews for ages 5-16: "little evidence" that teaching formal grammar (syntax) is effective; sentence combining "a more positive effect", with some fading at delayed tests; both reviews say the research is not good enough to prove either case | Andrews et al. 2006 [W3] (EPPI-Centre) | Measure our own transfer (phase C's before-and-after) |
| **Contextualised grammar** (Exeter's Grammar for Writing: grammar taught at the point of writing, as choices): a randomised trial with 744 Year 8 students in 31 schools improved writing (a summary reports +20 % against +11 %; an effect of 0.21 in a later paper), and helped able writers more than weaker ones | Myhill, Jones, Lines & Watson 2012 [W4]; Jones, Myhill & Bailey 2013 | Grammar as choice: the child chooses the form for the effect they want (the world's answer) |
| But the same idea delivered by others did not replicate: the EEF's trial with less able Year 6 writers found **+0.10, not significant**; a larger later trial found no impact, and the EEF dropped it from its promising list | Torgerson et al. 2014 [W5] (and the EEF's project pages) | Honest: even grammar-in-context is not a sure thing. Our transfer claims are tested in play, then in the School's written exercises |
| **Englicious** (grammar for 6-7-year-olds): 1,246 pupils in 70 classes, no effect on narrative writing; an effect on sentence generation not significant but large enough for the authors to reflect on | Wyse et al. [W6] | Manipulating words and sentences may help sentence building; it is not writing |
| A peer-assisted sentence-combining programme for young writers: a randomised trial that meets the What Works Clearinghouse's standards without reservations | Saddler & Graham 2005 [W7] (its outcomes not read here) | Combining as a game move, with a buddy |
| Teaching handwriting, spelling, **sentence construction**, typing: moderate evidence for elementary writers | IES practice guide (Graham et al. 2012) [W8] | Sentence construction belongs in the game; handwriting and typing do not (cards, not typing) |
| "Grammar as choice": grammar is a set of meaning-making options; talk about choices matters more than naming structures | Myhill and colleagues, Exeter [W9] | The see-why lines name the choice and its effect, never a definition |
| Written syntax grows slowly: Hunt's T-units (a main clause with what hangs on it) lengthen from grade 4 to 8 to 12, by embedding more into each clause | Hunt 1965 [W10] (the lengths as summarised, not checked) | The ribbon's slot budget (the Loom) rewards embedding over and-chains |

### 2.3 The science of reading, briefly

| Finding | Source | What we take |
|---|---|---|
| **The simple view**: reading comprehension is the product of decoding and language comprehension | Gough & Tunmer 1986 [R1] | Word Magic grows language (grammar, vocabulary, morphology) and word recognition; it is **not a decoding course** |
| **Systematic phonics** helps children learn to read: d = 0.41 at the end of training in the National Reading Panel's analysis, larger in kindergarten and grade 1 (about 0.55) than in grades 2-6 (0.27); reanalyses found smaller effects | Ehri, Nunes, Stahl & Willows 2001 [R2] (grade figures as reported); Camilli et al.'s reanalyses | A child who cannot decode at grade 3 needs phonics, which this game does not teach (ruling 3; open question 9) |
| Foundational skills guide (K-3): decoding, word parts and word writing and recognition, **strong** evidence; sounds and letters strong; academic language minimal; daily connected text moderate | IES practice guide, Foorman et al. 2016 [R3] | Word parts and word recognition are in scope; the game reads connected sentences aloud with the words highlighted |
| **Orthographic mapping**: sight words are stored by connecting their letters to sounds, and later to syllables and morphemes | Ehri 2014 [R4] | Gold endings make the morpheme boundary visible; a long word's card can play beat by beat (§3.6) |
| **Self-teaching**: decoding a new word yourself builds its spelling in memory; when second graders' phonological processing was minimised, they learned the spellings less well | Share 1995, 1999 [R5] | A card speaks when *touched*, not when shown; Hoot reads a spell *after* the child builds it. The child always gets a moment to try reading first |
| Why phonics is central in English, from novice to expert | Castles, Rastle & Nation 2018 [R6] | The game's honest limit |
| **Speech on demand**: a talking computer that says a word (in segments) when the child targets it supported poor readers' word recognition (the Colorado project); beginners asked for spoken help only in their first sessions, poor readers kept relying on it, and poor readers given speech on *every* word did not learn less than those who chose | Olson & Wise 1992 [R7]; van Daal & Reitsma 1993 [R8] | Every card speaks on touch, for everyone, without limit; a long word can be heard part by part |
| Text-to-speech as a reading accommodation: comprehension **d = .35** (22 studies, students with reading difficulties); it removes the decoding demand | Wood, Moxley, Tighe & Wagner 2018 [R15] | The voice is access; it is not, by itself, reading instruction (hence the word lights and stage 2) |
| Pictures and print: see §2.1 (focal attention; 7 % of time on print; highlighting doubles it) | [R9]-[R13] | Badges never carry grammar and fade; words light as they are read |
| E-books: across 43 studies (2,147 children), **animation, music and sound effects helped** story comprehension and vocabulary; **interactive extras (hotspots, games, dictionaries) distracted**, and most were unrelated to the story; worst for children from less stimulating homes | Takacs, Swart & Bus 2015 [R17] | The magic must be the sentence itself, never a decoration beside it (rule: seductive details, LP [G8]) |
| **Morphology**: instruction helps, especially less able readers, is no less effective for younger ones, and works best combined with other literacy teaching (22 studies) | Bowers, Kirby & Deacon 2010 [R14]; Goodwin & Ahn 2010, 2013 [R18] (their effect sizes as reported, not read) | Runes from floor 3; roots from floor 4 |
| School texts hold about 88,500 word families: far too many to teach one by one | Nagy & Anderson 1984 [R19] | Teach the parts that unlock many words |
| **Matthew effects**: poor readers read less, so they fall further behind | Stanovich 1986 [R20] | A non-reader must keep playing *and* keep meeting words; never stuck, never shamed |
| English learners: intensive academic vocabulary, oral and written English together, structured writing, small-group help | IES practice guide, Baker et al. 2014 [R21] (the four recommendations; their evidence levels not checked) | Words met as things and actions, heard and seen at once |

### 2.4 Games and apps for grammar and early reading: what works, what fails, and why

| Game or study | What it is | Worked? | Why | What we take |
|---|---|---|---|---|
| **Scribblenauts** (5th Cell) [A1] | Type a noun and it appears; adjectives change it (one review counts 800 objects and 10,000 adjectives) | **No controlled learning study found.** A qualitative doctoral study with 30 Chinese junior-high English learners reported persistence and vocabulary growth; a small Indonesian thesis's results not found | Words become things: an instant wow | Nouns summon, adjectives shape; we add that the *form* decides, take away typing (cards), add a voice |
| **Baba Is You** (Hempuli) [A2] | The rules are sentences of pushable word blocks ("BABA IS YOU", "WALL IS STOP"); change a sentence, change the world | Not a learning game; no learning study; studied as design | Rules as sentences, discovered by play | The Rule Stones (floor 8): conditional spells set rules ("If the moon rises, the gate opens") |
| **GraphoGame** [A3] | A phonics game used in many countries | A critical review found **no significant effect** against controls when all studies were combined, and a medium effect (0.48) when adults were engaged with it (as reported on the developer's own page) | Drill without a reason to read; adults made the difference | Reading must be the move, inside a reason to play; the grown-ups' page in phase C |
| **Lexia Core5** [A4] | Adaptive reading software | The EEF's trial (697 struggling Year 2 pupils, 57 schools): about **one month's** extra progress overall (an effect of 0.08), two months in word recognition and decoding, none on the national reading test | Practice helps a little; effects on wider reading are small | Short daily play; honest expectations |
| **Teach Your Monster to Read** [A5] | A phonics adventure | No randomised trial found; testimonials on the developer's site | — | — |
| **Duolingo ABC** [A6] | Early reading app | A study funded by the company reports a **28 %** gain in literacy scores after 9 weeks (self-reported; design not checked) | — | — |
| **NoRedInk** [A7] | Grammar practice for older students | A vendor-partnered correlation (7,330 middle schoolers: mastery predicted test growth); case studies; no independent trial found | Practice items, not meaning | — |
| **Talking computers (ROSS)** [R7] | Speech feedback on words a child targets | Supported poor readers' word recognition (the Colorado project) | Help on demand, segmented | Every card speaks on touch, part by part for long words |
| **E-books with read-aloud** [R17] | Narrated stories with extras | Multimedia helps; interactive extras distract | Extras not tied to the text compete with it | No extras: the sentence is the magic |
| **Montessori grammar symbols** [A8] | Shapes for word classes (a black triangle for a noun, a red circle for a verb) laid over sentences | A long classroom tradition; no controlled study of grammar learning found | Word jobs made visible | Word jobs are shown *as they act* after a cast (a noun glows as its thing appears), never as slot shapes before (shape-matching would win without grammar) |
| Educational technology for reading, all kinds [A9] | 84 studies, over 60,000 K-12 pupils | **+0.16** overall; supplemental drill software **+0.11**, which the authors did not call meaningful; better studies found smaller effects | Software beside teaching adds little | A game must be the concept, not a worksheet on a screen |
| Digital games for second-language vocabulary [A10] | 26 studies (2001-2017) | Large effects of games against other activities; no meta-analysis of grammar found | — | Vocabulary through things and actions |

**Why grammar and reading games usually fail:** they are worksheets with points (pick the noun, fill the blank), the
grammar is a label to name, the reward is beside the language, and reading support is a crutch with no way off it.
**Why the good ones work:** words make things happen (Scribblenauts), rules are sentences (Baba Is You), help is
there on demand (ROSS), and the parts of words are seen. Word Magic does all four in one verb, and adds the one thing
none of them has: the grammatical *form* decides what the world does.

### 2.5 The curriculum strand: the units this game replaces

Our English units for grades 3-8 follow the Common Core English Language Arts standards ([S1]-[S6]; the UK references in
some units). Of the 108 English units, the **language strand** (grammar and usage L.1, conventions L.2, word parts and
vocabulary L.4-L.5, and word analysis RF.3.3) is Word Magic's. Each row: the unit, its standards, its ideas (from its
cards), its hand-written exercises (and generators), the room that teaches it, and its level after phase C (P1 when its
room teaches all of it; the cards stay as the Book).

| Unit | Standards | Its ideas (from the cards) | Ex. | Taught by | After C |
|---|---|---|---|---|---|
| `g3.english.nouns_pronouns` | L.3.1a, b, c | plurals: -s, -es, -ies, -ves; irregular (mice, children, feet, geese); the same (sheep); abstract nouns; pronouns stand in (she means Zara) (gen. `g3e.plural`, `g3e.pronoun`) | 22 | **3.1 The First Page, 3.T1 The Sleepy Dragons (phase B)**, 3.2 Who's Who | **P1** |
| `g3.english.verbs_tenses` | L.3.1d, e, f; UK Y3 | past, present, future; regular and irregular past; agreement (one dog barks, two dogs bark); the present perfect (has seen) (`g3e.past_tense`, `verb_agree`) | 20 | 3.3 Time Windows (and the dragons' agreement) | **P1** |
| `g3.english.adjectives_adverbs` | L.3.1a, g | adjectives describe; adverbs say how, when, where; -er and -est; bigger, happier; more and most; good, better, best (`g3e.compare`) | 20 | 3.4 The Shaping Room | **P1** |
| `g3.english.joining_sentences` | L.3.1h, i; L.3.3a | simple, compound, complex; and, but, so; because, when, if, while, before, after (`g3e.conjunction`) | 19 | 3.5 Chain Spells | **P1** |
| `g3.english.punctuation_speech` | L.3.2a-d | capitals in titles; speech marks round the words said; apostrophes for owners (the girls' bikes); commas in addresses (`g3e.possessive`, `speech_marks`) | 20 | 3.6 The Speaking Stones | **P1** |
| `g3.english.word_building` | RF.3.3; L.3.4b | prefixes un-, re-, dis-, pre-; suffixes -ful, -less, -ly, -er, -able; syllables (`g3e.word_part`, `syllables`) | 17 | 3.7 The Rune Bench | **P1** |
| `g3.english.spelling_patterns` | L.3.2e, f, g | word families (-ight); double the last letter, drop the e, y to i; tricky words; alphabetical order (`g3e.add_suffix`, `alpha_order`) | 19 | 3.8 The Spelling Forge (a reading room) | **P1** |
| `g4.english.verbs` | L.4.1b, c | the -ing tenses (was, am, will be walking); can, may, must | 20 | 4.1 The Ongoing Clock | **P1** |
| `g4.english.adjectives` | L.4.1d, e | the order of adjectives; prepositions and their phrases | 20 | 4.2 The Charm String and the Place Runes | **P1** |
| `g4.english.relative_words` | L.4.1a | who, which, that, where, when, whose | 22 | 4.3 The Which Gate | **P1** |
| `g4.english.sentences` | L.4.1f | subject and verb; fragments; run-ons; fixing them | 20 | 4.4 The Sentence Seals | **P1** |
| `g4.english.sound_alike` | L.4.1g | to, too, two; there, their, they're; your, you're; its, it's (`g4e.homophone_blank`, `homophone_check`) | 18 | 4.5 The Homophone Hall (a reading room) | **P1** |
| `g4.english.punctuation` | L.4.2a, b, c | capitals; speech marks and their commas; a comma before and, but, so | 20 | 4.6 The Quotation Gate | **P1** |
| `g4.english.word_parts` | L.4.4b | un-, dis-, re-, pre-, mis-; -ful, -less, -able, -er; roots tele, graph, port, aqua | 22 | 4.7 The Rune Bench II | **P1** |
| `g5.english.perfect_tenses` | L.5.1b, c, d | have, had, will have; keeping tenses steady | 20 | 5.1 The Clock of Before | **P1** |
| `g5.english.conjunctions` | L.5.1a, e | conjunctions, prepositions, interjections; either/or, neither/nor | 22 | 5.2 Either-Or Doors | **P1** |
| `g5.english.commas` | L.5.2a, b, c | lists; after an opening phrase; yes and no; tag questions; a name spoken to ("Let's eat, Grandma!") | 22 | 5.3 The Comma Bridge | **P1** |
| `g5.english.titles` | L.5.2d | long works in italics or underlined, short ones in quotation marks; capitals in titles | 22 | 5.4 The Title Shelves | **P1** |
| `g5.english.roots` | L.5.4b | Greek and Latin roots (photo, graph, tele, micro, scope; port, spect, dict, rupt, struct, aud, vis) | 22 | 5.5 The Word Forge | **P1** |
| `g5.english.homographs` | L.5.5c | homographs (bat, bow, wind, tear); synonyms, antonyms | 22 | 5.6 The Two-Faced Words | **P1** |
| `g6.english.pronouns` | L.6.1a-d | subject and object case (Sam and I, Sam and me); intensive; shifts; vague pronouns | 22 | 6.1 Who Did It? | **P1** |
| `g6.english.extra_information` | L.6.2a | extra information in commas, brackets or dashes; take it out and the sentence still stands | 20 | 6.2 The Side-Note Gate | **P1** |
| `g6.english.sentence_variety` | L.6.3a | simple, compound, complex; varied openings; a short sentence for punch | 20 | 6.3 The Loom | **P1** |
| `g6.english.affixes_roots` | L.6.4b | audi, bene, chron, cred, ject, log, vid; anti-, inter-, sub-, trans-, bi-; -ology, -ible, -ist | 22 | 6.4 The Word Forge II | **P1** |
| `g6.english.word_relationships` | L.6.5b | part and whole; item and category; cause and effect; analogies | 22 | 6.5 Word Webs | **P1** |
| `g6.english.connotation` | L.6.5c | denotation and connotation (thrifty, stingy) | 20 | 6.6 Mood Dyes | **P1** |
| `g7.english.phrases_clauses` | L.7.1a | clause and phrase; independent and dependent | 22 | 7.1 The Clause Stars | **P1** |
| `g7.english.sentence_kinds` | L.7.1b | simple, compound, complex, compound-complex | 20 | 7.2 The Constellations | **P1** |
| `g7.english.modifiers` | L.7.1c | misplaced and dangling modifiers | 22 | 7.3 The Wandering Phrase | **P1** |
| `g7.english.coordinate_adjectives` | L.7.2a | commas between coordinate adjectives; none between cumulative ones | 20 | 7.4 The Equal Charms | **P1** |
| `g7.english.roots` | L.7.4b | bellum, ped, manu, scrib; phon, therm, hydr, metron | 22 | 7.5 The Word Forge III | **P1** |
| `g8.english.verbals` | L.8.1a | gerunds, participles, infinitives | 15 | 8.1 Shapeshifting Verbs | **P1** |
| `g8.english.voice` | L.8.1b; L.8.3a | active and passive, and choosing for effect | 15 | 8.2 The Spotlight | **P1** |
| `g8.english.moods` | L.8.1c, d | indicative, imperative, interrogative, conditional, subjunctive | 15 | 8.3 The Rule Stones | **P1** |
| `g8.english.pauses_breaks` | L.8.2a, b | ellipsis, dash, comma for pauses and breaks | 15 | 8.4 The Pause Marks | **P1** |
| `g8.english.word_relationships` | L.8.5b, c | relationships (degree: warm, hot, scorching); connotation; analogies | 15 | 8.5 Word Webs II | **P1** |
| `g3.english.word_meanings` | L.3.4a; L.3.5a, c | context clues; literal and non-literal; shades of meaning (knew, believed, guessed) | 19 | 3.9 The Strength Dial (shades, the literal pond) | open question 2 |
| `g7.english.connotation_tone` | RL.7.4; L.7.5c | connotation; an author's tone through word choice | 20 | 7.6 The Tone Lantern (word choice's tone) | half: stays P0 (its RL half is reading) |

**Thirty-six units become P1**: their **716** hand-written exercises (403 written choices, 109 true-or-false claims, 84
sorts, 50 matches, 48 orders, 22 number answers) stop being what a child meets; today only **116** of them play without
reading (`tools/play_audit.py`: 600 are reading debt: 403 written choices, 109 claims, 79 words to read on things, 9
long questions). Their 214 cards (5,172 words) become the Book. Their generators (`G3WordsGen`'s twelve: plural, pronoun,
past tense, agreement, compare, conjunction, possessive, speech marks, suffixes, alphabetical order, word parts,
syllables; `G4EnglishGen`'s homophones, with `GenWords`) are where the spells' words come from, so the game and the Book
agree. English is the subject G0 could do least for: of its 2,119 hand-written exercises, **192** play without reading
(91 % reading debt).

**What Word Magic does not cover** (and which game in the queue does, `learning-is-play.md` §5.2):
- **Reading comprehension and literature** (story_retell, characters_feelings, point_of_view ×3, main_idea, main_ideas,
  central_idea, central_ideas, text_features, sequence_cause, compare_texts, comparing_texts, reading_to_learn,
  text_structure ×2, story_structure, story_characters, myths_tales, theme_compare, theme_development, plot_character,
  setting, dialogue_incidents, dramatic_irony, old_stories_new, fiction_and_history, author_purpose, accounts_evidence,
  quote_to_prove, many_sources, read_closely, strong_evidence, strongest_evidence, claims_evidence, arguments ×2):
  **Story Theater** (stories), **Detective Reader** (information texts, evidence), **Persuade the Council** (argument).
- **Writing whole texts** (write_stories, write_facts_opinions, write_narrative ×4, write_opinion ×2, write_report,
  write_explain, story_techniques, write_argument ×3, write_informative ×3, research_sources, research): Story Theater
  (narrative), Persuade the Council (opinion, argument), Detective Reader (report, research). Word Magic's sentence
  combining feeds them; it does not replace them.
- **Figurative language** (figurative ×2, idioms_proverbs, figures_of_speech, allusions_analogies, irony_puns, poems_plays,
  poetry, poem_forms): **Poetry Music**. Word Magic's literal world is a natural joke about idioms ("it's raining cats and
  dogs" taken literally: 3.9's literal pond), but teaching figurative language is Poetry Music's.
- **Context clues** (context_clues; half of word_meanings): Detective Reader (open question 2).
- **Speaking and presenting** (present_speak, discuss_present, speeches_media, present_multimedia): **no microphone,
  ever**, so these stay in the School (P0); Persuade the Council may build a speech from cards for Hoot to perform.

### 2.6 What the five tests need from the design (the research's verdict)

Choice comes from autonomy, competence and relatedness (`engagement-and-child-psychology.md` §1.1), from a place that
visibly grows because of you (the valley in colour), creatures with wishes, surprise and humour (the Jumble, the literal
world), making (your own page for a friend), and short, winnable wishes. Mute, for this game, means **playable by ear**:
the wish is a picture, every word speaks, the meaning rooms' choices sound different. Cheat comes from forms that must be
chosen (pictures never show grammar), first casts that count, no preview, and hands that always hold each habit's
tempting card (the models, §3.9). Transfer comes from rooms where habits fail, from writing for others (the transfer
rooms: notes, maps, labels, rules that buddies act out), and from the School's written exercises as the outside check.
Reading growth comes from print attention (highlighting), speech on demand, the child's own first try (self-teaching),
pictures that leave, and morphology made visible. Wow must be the sentence itself coming true, never decoration.

---

## 3. The game

### 3.1 The fantasy and the purpose

**You are the Word Keeper.** The Word Tower is a slim tower of cream stone with a spiral of round windows, a domed top
and a golden quill turning in the wind as a weathervane (picture 01). At night its windows glow and loose letters
drift out of the dome like fireflies. Inside, at the top of a winding stair, is a round room under a dome painted deep
blue with gold stars: curving shelves of glowing word cards, a big round window onto the night, an inkwell where the
Jumble lives, and in the middle a lectern holding **the Great Book**. The Book lies open, and its pages rise into a
pop-up valley, drawn in soft pencil: folded hills, a pond, a winding path, a few cottages, a tree on a hill, all grey
and blank. A golden bookmark ribbon floats above the pages: **the Spell Ribbon**.

The Book's law: **whatever is written true on the ribbon comes true in the valley.** The valley's buddies (EasyCraft's
living buddies: wand-woken block creatures with googly eyes) come to the page's edge with wishes in thought bubbles,
drawn as pictures. The child writes the sentence that makes the wish true, seals it with the star, and the words lift
off the ribbon in ink, swirl down into the page and become what they say: the thing appears with an ink splash and its
patch of the valley blooms from pencil into watercolour. The buddy hops for joy and moves into the valley. A wrong
word does exactly what it says (§3.4's literal world): one duck where five were wished for, beside four empty
outlines; the Jumble instead of mice. Then the ink flows back up into the ribbon (nothing is ruined; the page can't be
spoiled) and the child tries again.

A night's last wish is **the Story Parade**: everything the child has written that night marches across the page, and
the whole valley is in colour. At dawn the Book turns its page: a new valley waits. Each floor of the tower is a school
year with its own Book (§3.6).

**Why it matters to the child:** words *do* things here, at once and visibly, which is what children want from words
(Scribblenauts' wow); the valley is theirs (everything they wrote stays in it, and they can visit it); the buddies'
wishes are small kindnesses; the Jumble is funny and a little cheeky, and out-reading it is a quiet triumph. The long
purpose ties into EasyCraft's loop (learn → gold → build a rocket → fly): every judged wish records through `SkillShown`,
so stars and the School's gold come from the tower.

**The guide** is Professor Hoot (DISCOVER's owl) in a purple wizard's hat with gold stars, perched on the lectern's edge.
He speaks every line and reads every spell. The buddies babble and chirp. **The Jumble** never speaks words: it giggles,
sneezes ink, says "ta-da!" in a squeak and hops back into the inkwell. It is never a villain: it slips its made-up words
onto the shelves because it thinks they are funny, and it is delighted to be summoned.

**The tone:** a bedtime picture book with a twinkle: the scratch of a quill, the soft chime of the star seal, ink
swooshing, the Jumble's giggle, Bach's *Goldberg Aria* while you write. Never scary, never rushed: nothing is timed, a
buddy with a wish just waits and wiggles.

### 3.2 Where it lives

- **Phase B:** the tower's top room is a place of its own far above the world (like Life's rooms, G0's play arena and
  the other deep games), its window always on a starry night. It opens from DISCOVER (the unit `g3.english.nouns_pronouns`
  shows the tower's picture, a book with a star, on the English map; its PLAY opens the First Page; Hoot's pick opens it
  whenever that unit is the child's next or due one), from W1's **Word Tower** door at the Discovery Academy (today a
  calm "coming soon"; `AcademyPlaza.opens()` switches it to Word Magic when the child's unit is one it covers), and by a
  developer argument (`--word-magic-page=first`).
- **Phase C:** the Word Tower stands beside the Academy as a building of its own, where W1's English gate is today: the
  gate becomes its door. Walking in climbs the stair to the child's floor (the grade's Book). The tower's windows show
  progress from outside: a floor's window glows in colour once its Book's pages are coloured. Like the crystals and the
  bakery, it is local to each child (never synced). A discovery crystal (W1) for a child whose English unit is one of
  Word Magic's can open a short page (four wishes).
- **Phase D:** your own page for a friend (§3.6, 8.6); spells on signposts in your own world: a sign you write in
  words from your Spellbook makes a small ink picture appear beside it (the world task: "write a sign for your farm").

**The English door: how a child of each grade finds the right game.** Word Magic is the first English deep game; Story
Theater, Detective Reader, Persuade the Council and Poetry Music will follow. The door (and Hoot's pick) opens **the
deep game that teaches the child's current English unit** (`DiscoveryPlays.subject_unit`: a review due, else the next not
mastered), as the Maths door does for the bakery and the temple. Today most of each grade's English units are reading
units with no game yet, so a child at one of them would get G0's round or "coming soon". Ruling 24: until those games
come, **the door opens Word Magic at the child's floor** (its first unit not mastered) whenever the child's current
English unit has no deep game; the School's order is kept inside the language strand. The door's picture shows a book
with a star and Hoot names it as the child walks up ("The Word Tower is open tonight!").

### 3.3 The core loop

| Every | The child | The world answers | Example (the First Page) |
|---|---|---|---|
| **10 seconds** | one act: lift a card (it says its word), lay it in a gap of the ribbon | at once: the card settles with a soft click and glows | "mice" says "mice" and settles beside "three" |
| **minute** | one wish: fill the gaps, tap the star | Hoot reads the spell, each word lighting as it is said; the ink flies; the thing appears; its patch blooms into colour; the buddy hops | three mice nibble the cheese; the meadow by the pond turns green |
| **10 minutes** | one page (a night) | the valley fills with colour; the Story Parade; dawn turns the page; the Spellbook gains golden words | the Parade: geese and sheep carrying lanterns across a coloured valley |
| **days and weeks** | the floors | a floor a school year: new runes, new marks, new buddies, new Books; the Spellbook fills; in phase D, your own page for a friend | next: the Sleepy Dragons, Who's Who, Time Windows |

Picture 06. Inside a page the rhythm alternates: a new kind of wish shown once by the ghost, three or four wishes that
use it, a mixed run where the child must decide what each wish needs, then the night's Parade.

### 3.4 The verbs are the concepts

**The Spell Reader**, the game's referee, reads the ribbon's cards as English and turns them into what happens. It is
literal: it does what the sentence says, not what the child meant. That is the whole design: every grammatical choice
changes what the world does, so the child can see the grammar.

| Idea | Verb | What the world does | Why guessing loses |
|---|---|---|---|
| A noun names a thing | **lay a noun card** | the thing appears | the badge finds the word; the wish is about *which form*, and the badge never shows it |
| Number: singular and plural, regular and irregular | **choose the noun's form** (fox, foxes; mouse, mice) | that many appear; a made-up form (mouses) brings the Jumble; a number and a noun that disagree bring the noun's count beside empty outlines | every hand holds the other number and the Jumble's form; habits that read the ending (gold, sound, length) **0 %** |
| Agreement | **choose the verb's form** (snore, snores) | the -s form: exactly one of them does it; the plain form: all of them do (ink copies join a lone one) | "an s means more" picks wrong every time; two linked decisions per wish (a coin **0.1 %**) |
| Pronouns | **choose it, they, he, she, we** | the pronoun sticks to the nearest thing that matches; "it" with no single thing in the spell grabs the nearest single thing in the scene (the log sings) | the wish shows who acts |
| Abstract nouns | **lay an idea word** (courage, kindness) | an idea can't be touched: it appears as a glow around whoever has it (a mouse full of courage stands tall in gold light) | — |
| Tense | **choose the verb's form** (swim, swam, will swim) | past: already happened, shown in an old photo frame of sepia ink; now: happens live; future: a dotted plan that comes true at dawn | the bubble's frame shows when; every past wish holds a wild verb, so "add -ed" brings the Jumble (runned): **0 %** |
| Adjectives shape; comparing | **lay adjective cards** (tiny, purple; taller, tallest) | size, colour and kind change; -er needs a "than" and compares two; -est picks the one at the end of the line | the wish names nothing: it shows which tower must change |
| Adverbs say how | **lay an adverb** (quietly, quickly) | the action's manner: tiptoe past the sleeping dragon *quietly*, or wake it | an adjective in its place (quiet) tangles the spell |
| Joining words | **choose the joining word and which event comes first** | and: both at once, unlinked; so: the second happens because of the first (a domino); because: the reason is told second; but: a surprise; if: only if; when: it waits | "because" for "so" plays the effect before its cause; every hand holds "and" and "so" (and "because" in a cause wish): **0 %** |
| Whole sentences | **seal with the star; join or split** | a fragment can't be sealed (the star stays dim: "Who? Doing what?"); two spells with no joint crash into each other | — |
| Speech marks | **put the speech-bubble runes round words** | the words inside come out of the speaker's beak as speech and don't happen; without them they happen ("The king said the moon is cheese": the moon turns to cheese) | the wish shows a speech bubble, or a moon |
| Owners (apostrophe) | **place the owner rune** | the thing goes to one owner or to many (the dog's bones, the dogs' bones) | — |
| Commas | **place a comma or none** | a missing list comma fuses two things (a cat dog: a cat-dog); a comma before a name speaks to them ("Let's paint, Pip!": Pip helps; "Let's paint Pip!": Pip is painted); a comma between a subject and its verb cuts the verb loose (it drifts off and puts Hoot to sleep) | "comma everywhere" and "comma where you pause" **0 %** |
| Relative words and extra information | **choose who, which, that, and commas** | "the dragons that sleep" picks only those; "the dragons, which sleep," means all of them (and by the way, they sleep) | always commas **0 %**, never commas **0 %** |
| Modifiers | **place a describing phrase** | it sticks to the noun beside it ("with a wagging tail" beside "school": the school grows a tail) | always at the end **0 %** |
| Voice | **choose the frame** (active, passive, passive without "by") | the subject stands in the spotlight; "by…" shows who did it; no "by" keeps the doer hidden | "the first noun is the doer" **0 %** |
| Moods | **choose a statement, a command, a question, an if, a wish** | a statement makes it so; a command makes a buddy do it; a question makes the world show the answer without changing anything; an if sets a rule stone that waits; "I wish it were" shows a dream bubble | — |
| Prefix and suffix runes | **snap runes onto a word** | un- undoes, re- does again, dis- does the opposite, pre- before, mis- wrongly; -ful full of, -less without, -able can be, -er a person who, -ly in that way (un-lock: the lock opens) | made-up words bring the Jumble; "un- for every not" (unappear) **0 %** |
| Roots | **forge two roots** | the gadget the name says appears and does its job (tele + scope: a far-seer) | "the most familiar roots" (tele, phone) **0 %** |
| Shades of meaning and connotation | **choose among near-synonyms** | strength sets strength (warm, hot, scorching: the snowman drips, melts or steams away); feeling sets feeling (a cosy room: the buddies snuggle; a cramped one: they squeeze) | "always the nice word" **0 %** |
| Spelling (stage 2) | **choose among look-alikes** (ponies, ponys) | a misspelt word brings the Jumble | they sound the same: only reading tells them apart |
| Homophones (a reading room) | **choose among same-sound cards** | their: a name tag (it belongs to them); there: a star far over there; they're: "they are" | the cards all say the same sound: listening alone **0.1 %** |

**The Spell Reader's literal rules for phase B** (`SpellReader`, from the phase A model, `model/spell_rules.py`):

| The spell | What the world does |
|---|---|
| a number word (or "a") and a noun that agree | that many of the thing appear |
| "The" and a plural noun | several appear (as many as the bubble shows) |
| a number word and a noun that disagree ("five duck", "a foxes") | the noun's count appears; empty glowing outlines stand where the number wanted more, and extra ones fade away |
| a made-up word ("mouses", "sheeps") | the Jumble pops out of the inkwell instead |
| a verb with -s | exactly one of the subject does it (the first one; the others carry on as they were) |
| a plain verb | all of the subject do it; if there is only one, ink copies appear and do it too, then fade |
| "It", "They" | the nearest thing earlier in the spell that matches (it: one, they: many); "it" with no single thing there grabs the nearest single thing on the page |
| an empty gap | the star stays dim: nothing can be cast |

### 3.5 The First Page, beat by beat (the phase B slice)

Pictures: `word-magic/01-the-word-tower.png`, `02-write-it-true.png`, `03-the-literal-world.png`, `04-the-first-page.png`.

**The place** (the tower's top room at night): the lectern with the Great Book in front of the child at waist height;
the pop-up valley rising from its pages; the Spell Ribbon floating just above the near edge of the pages; the shelf of
word cards curving round the lectern's left and right (the cards a wish offers float out and hover in a fan along the
ribbon); the inkwell at the lectern's right corner; Hoot on the left corner; the round window behind the Book with the
night sky. The child never walks (in VR the child stands at the lectern).

1. **The arrival (0:00).** The camera climbs the tower's spiral stair; letters drift past like fireflies; the top room
   opens; the Book's pencil valley. Hoot: "Welcome to the Word Tower! Here, words are magic." Then: "Whatever we write
   in the Great Book comes true."
2. **T1, taught (0:20): the first spell.** The ribbon shows "A [ ] [ ]." with two gaps; four cards hover: frog, cat,
   jumps, sleeps (each with its badge). The ghost finger lifts "frog" (it says "frog"), lays it in the first gap, lifts
   "jumps" ("jumps"), lays it in the second, and taps the star. Hoot reads "A frog jumps!", each word lighting gold as
   he says it; the words lift off as ink, swirl into the pond: a pencil outline of a frog fills with green, the frog
   jumps in with a splash, and the pond turns blue. Hoot: "Watch: a frog jumps!" … "Your turn!"
3. **T2, free spells (0:45, about 60 s, not judged).** The ribbon: "A [ ] [ ] [ ]." (the describing gap may stay empty);
   the fan: frog, cat, dragon, duck; big, tiny, purple, golden; jumps, dances, sleeps, flies. Hoot: "Make anything you
   like. Touch a card to hear it." A tiny purple dragon dances; a big golden duck flies over the hill; each lands as ink
   and blooms. After three spells or a minute: "The valley has wishes. Look at the bubble!" (play first, words after:
   the child has felt that the words make things before anything is asked).
4. **T3, taught (1:50): more than one.** A lily-pad buddy at the pond's edge; its bubble: three frogs in the pond. The
   ribbon: "Three [ ] swim." The fan: frog, frogs. The ghost lays "frogs" (its gold "s" glows as it is said). Cast:
   three frogs. Hoot: "Watch: frogs. The ending says more than one."
5. **T4, taught: the trap (2:15).** A duck buddy's bubble: five ducks flying. "Five [ ] fly." The fan: duck, ducks. No
   ghost. A child who lays "duck" sees one duck flap up and four empty glowing duck outlines flap uselessly beside it.
   Hoot: "Just one duck came! The wish needs five." Then the see-why: "Ducks: the s says more than one duck." The ink
   flows back; "ducks": five ducks fly over the moon.
6. **J1-J7, judged (2:45-5:30).** Each wish arrives with Hoot's situation line (it never says the wish's words): a
   sleepy fox (J1: one), presents falling from the sky (J2: boxes or foxes, two to five), hungry mice and a cheese (J3:
   mice), someone who wants a swim (J4: one goose or one mouse), autumn on the tree (J5: "The [ ] fell from the tree":
   leaves; or wolves howling), a dance on the hill (J6: ponies or bunnies), a snowy game (J7: children or sheep, two to
   five). Every wish but J5 has a number gap (three number words) and a noun gap (the noun's forms and, for wild words,
   the Jumble's made-up forms). Silent but for the situation line; praise after. The first made-up word cast brings the
   Jumble: "Oops! That's not a real word. The Jumble!" and, for a wild word, the see-why: "One mouse, two mice. Some
   words change inside."
7. **J8, judged: the Story Parade (5:30).** All the valley but the path is in colour. Hoot: "The Story Parade! Write the
   last wish of the night." The bubble: a line of geese and sheep (or children, or wolves) carrying lanterns. The ribbon:
   "[ ] [ ] and [ ] [ ] carried the lanterns." Four gaps.
8. **The parade (6:00).** Everything the child summoned that night marches along the path: the frogs hop, the mice ride
   a goose, the ponies dance, the lanterns bob; the last pencil patch blooms; *The Marriage of Figaro*'s overture. Hoot:
   "Everyone's marching! The whole page is in colour!" The see-why of the night: "The end of a word says how many." Then
   the names, after use: "Grown-ups call these nouns. One is singular, more is plural."
9. **The end card (6:30).** Pictures only: the coloured page, the stars, the gold, the Spellbook with any newly golden
   words, three picture buttons (↻ again, ▶ the Sleepy Dragons, a door: back). Hoot: "Wonderful writing! Shall we visit
   the dragons?" (a spoken question answered by a picture button).

A child who knows the idea takes 6-7 minutes; a slower one 8-9. Nothing is timed. After two wrong casts on a wish the
ghost lays one card (that wish counts as helped); SHOW ME (the eye) lays one card any time (helped); idle 10 s,
everything that can be touched glows for 3 s (never only the right card: no help).

**The First Page's rules for phase B** (the starting rules for `WishBook`, `SpellReader` and `SpellJudge`, from the
phase A model, `model/first_page_model.py`):

| Rule | Value |
|---|---|
| A wish | a picture in a buddy's bubble (what, and how many) and a frame on the ribbon: words written in ink (each says itself when touched) with gaps |
| Gaps | a number gap (three number words: a, two, three, four, five, the right one among them) and a noun gap (the noun's forms: singular, plural, and the Jumble's made-up forms for a wild word: three or four cards) |
| Cards | each says its word when touched or lifted; a picture badge of what it is about (the same for every form); the ending in gold ink; cards look alike: a made-up word is drawn like a real one |
| The cast | the star lights when every gap holds a card; a tap (in VR a touch of the Magic Wand) casts; Hoot reads the spell word by word, each word lighting as it is said; the world does what it says |
| Granted | the right thing, the right number (the sheep: one or many, either is right) |
| SOLVED | granted at the first cast, with no help |
| A wrong cast | the world plays it (outlines, the Jumble, too many), Hoot's line, the ink flows back, the cards return to the fan; the wish's first-time credit is gone |
| No preview | nothing shows what a spell will do before the star |
| Help | after every second wrong cast the ghost lays the next card of the right spell (HELPED); SHOW ME lays one any time (HELPED); after a third wrong cast the ghost finishes the spell (SHOWN) |
| The night's wishes | J1 one fox, frog or duck; J2 two to five boxes or foxes (-es); J3 two to five mice; J4 one goose or one mouse; J5 "The [ ]" leaves or wolves (-ves); J6 two to five ponies or bunnies (-ies); J7 two to five children or sheep; J8 the Parade: two or three geese and two or three sheep, children or wolves (§3.9 says why) |
| Stage 2 | when the child's reading has opened it (§3.6): look-alike made-up words that sound right (ponys) join J6 |
| The night's record | 8 judged wishes → 8 `SkillShown` events for `g3.english.nouns_pronouns`; MasteryRules' bar: 7 of 8 |

### 3.5b The Sleepy Dragons, beat by beat (the phase B transfer room)

It opens from the First Page's end card, or as the night goes on. Picture `word-magic/05-the-sleepy-dragons.png`.

1. **The hook (0:00).** The Book turns its page to Dragon Hill under a huge moon: four little round dragons asleep in
   a heap, a baby dragon curled apart, an egg in a nest, a fox, a goose, the mice and the sheep from the First Page.
   *Gymnopédie No. 1*. Hoot whispers: "Shh! Dragon Hill. The baby dragons are sleeping." The frame (teaching, not a
   move): "Here the words are written. You choose how they act."
2. **D1, judged (0:15).** The bubble: the four dragons snoring (a z above each) and the baby sneezing a tiny puff of
   flame. The ribbon: "The dragons [ ], and the baby [ ]." The fan: snore, snores; sneeze, sneezes. A child who carries
   the First Page's habit ("an s means more") lays "snores" and "sneeze": one dragon snores while the other three sleep
   silently, and three ink copies of the baby appear and sneeze with it, a chorus of little flames. Hoot, the first
   time: "Only one dragon snored! The others slept on." If nothing happens for 15 s, once: "Make the dragons do what the
   bubble shows." (the goal, never the move). The first right cast's see-why: "Snore: they all do it. Snores: just one
   does it."
3. **D2, judged:** "[ ] [ ], and the mouse [ ]." The bubble: all the dragons dancing, the mouse squeaking. "It dances"
   finds no single thing in the spell, so it grabs the moon: the moon wobbles in a dance (the buddies point and laugh).
4. **D3, judged:** "The egg [ ], and the mice [ ]." (hatch, hatches; cheer, cheers). Right: the egg cracks and a baby
   dragon peeps out; the mice cheer. Hoot: "The egg hatched! Welcome, little one!"
5. **D4, judged: two subjects.** "The fox and the dragon [ ]. [ ] [ ] down the hill." The bubble: both laughing, then
   both rolling. "The fox and the dragon laughs": only the dragon laughs (the nearest one) while the fox looks puzzled.
   The see-why, the first time: "The fox and the dragon: two of them, so laugh."
6. **D5, judged:** "The goose and the mouse [ ], and the dragon [ ]." (two subjects, then one).
7. **D6, judged: only the verb says how many.** "The sheep [ ]. [ ] [ ] again." The bubble shows one sheep yawning, or
   the whole flock: "the sheep" is the same for one or many, so only the verb (and the pronoun) can say which.
8. **The end (about 3:30).** The moon is high; the dragons tumble back into a heap and snore together; the valley's
   night sky fills with stars. The rule in words, after the child has used it: "On a noun, s means more. On a verb, s
   means one." Then: "Goodnight, little dragons!" End card.

**Its six wishes** are `SkillShown.NEW_SETTING` events for `g3.english.nouns_pronouns` when granted at the first cast with
no help (HELPED or SHOWN otherwise): a full round, its transfer kept apart (open question 1 offers the alternative: SOLVED
events for `g3.english.verbs_tenses`, whose L.3.1f this is). The model (`model/sleepy_dragons_model.py`): the First Page's
habit grants none of the six (**0 %** of visits reach 5 of 6); the idea all six (**100 %**).

### 3.6 The ladder across grades 3-8: the tower's floors

Each floor is a school year with its own Great Book; its rooms are pages (each a short night of 6-10 wishes, 4-8
minutes). The grade (DISCOVER's) picks the child's floor after the prologue (the First Page and the Sleepy Dragons,
everyone's first pages); every floor stays open to everyone. Inside a floor the pages open one after another; transfer
pages (T) come after their idea, and each is a piece of **writing for someone**: notes, directions, labels, rules that a
buddy reads and acts out literally (the transfer from spells to writing). Picture `word-magic/07-the-ladder.png`; the
later rooms: `11-later-rooms.png`.

**Floor 3, The Summoning Hall** (grade 3; the Meadow Book). Units: `nouns_pronouns`, `verbs_tenses`, `adjectives_adverbs`,
`joining_sentences`, `punctuation_speech`, `word_building`, `spelling_patterns` (and `word_meanings`: open question 2).
- *3.1 The First Page* (phase B, §3.5): number in nouns.
- *3.T1 The Sleepy Dragons* (phase B, §3.5b): number in verbs.
- *3.2 Who's Who* (L.3.1a, c, f): pronouns stand in (it, they, he, she, we, us, them; "It sang" with a log in the spell:
  the log sings); abstract nouns as glows (courage, kindness).
- *3.3 Time Windows* (L.3.1d, e): the bubble's frames say when (an old photo, now, a dotted plan); regular and wild past
  (ran, swam, flew, ate, sang, dug: "runned" brings the Jumble); "has seen" as a photo that is still true now.
- *3.4 The Shaping Room* (L.3.1a, g): adjectives shape; adverbs say how; taller, tallest; bigger, happier; more and
  most; good, better, best (three towers on the hill: make the middle one the tallest).
- *3.5 Chain Spells* (L.3.1h, i): two events joined: and, but, so, because, when, if, before, after; dominoes fall in the
  order the joining word says.
- *3.6 The Speaking Stones* (L.3.2a-d): speech marks make a buddy *say* the words; the owner rune (the dog's bone, the
  dogs' bones); capitals in book titles on the tower's shelves; a letter that the post-owl delivers only with its
  address's commas right.
- *3.7 The Rune Bench* (RF.3.3, L.3.4b): un-, re-, dis-, pre-; -ful, -less, -ly, -er, -able; a long word's card splits
  into its beats (syllables) as it is said.
- *3.8 The Spelling Forge* (L.3.2e-g; a reading room, stage 2): ending runes with spelling rules (hop + ing: the p
  doubles; make + ing: the e drops; cry + ed: y to i); -ight families; finding a word in the Spellbook by its ABC tabs.
- *3.9 The Strength Dial* (L.3.5a, c; open question 2): shades of meaning (warm, hot, scorching; knew, believed, guessed)
  and the literal pond ("It's raining cats and dogs": cats and dogs float down under umbrellas).
- *3.T2 The Picnic Notes*: the child writes the buddies' picnic notes ("Pack three apples before it rains") and a buddy
  packs and acts exactly as written: plurals, time and joining words in someone else's hands. The habit that fails:
  "spells happen now" (a note's "before" and "will" matter).
- Harder: badges to words alone; frames with gaps to whole spells built from an empty ribbon; more cards in a hand.

**Floor 4, The Rune Workshop** (grade 4). Units: `verbs`, `adjectives`, `relative_words`, `sentences`, `sound_alike`,
`punctuation`, `word_parts`.
- *4.1 The Ongoing Clock* (L.4.1b, c): -ing tenses stretch across the frames (was swimming when the bell rang); can (a
  bridge that can hold you), may (a shimmering maybe-bridge), must (a rule).
- *4.2 The Charm String and the Place Runes* (L.4.1d, e): adjectives threaded in their usual order (opinion, size, age,
  shape, colour, material: a lovely little old red wooden boat); prepositions place things (under, behind, through).
- *4.3 The Which Gate* (L.4.1a): who, which, that, where, when, whose pick the right one of many (wake the dragon that
  sleeps under the bridge).
- *4.4 The Sentence Seals* (L.4.1f): a fragment can't be sealed; two spells without a joint crash; fix with a star or a
  comma and a joining word.
- *4.5 The Homophone Hall* (L.4.1g; a reading room): their, there, they're; to, too, two; its, it's; your, you're.
- *4.6 The Quotation Gate* (L.4.2a-c): capitals for names and days; speech marks and their commas; a comma before and,
  but, so in a compound spell.
- *4.7 The Rune Bench II* (L.4.4b): un-, dis-, re-, pre-, mis-; -ful, -less, -able, -er; first roots (tele, graph, port,
  aqua).
- *4.T1 The Map Room*: directions for a buddy across a map, followed literally: place words, which-clauses, whole
  sentences. The habit that fails: "a fragment is enough" (the buddy stands still at "Under the bridge.").

**Floor 5, The Clockwork Library** (grade 5). Units: `perfect_tenses`, `conjunctions`, `commas`, `titles`, `roots`,
`homographs`.
- *5.1 The Clock of Before* (L.5.1b-d): had, have, will have on the time windows ("By the time the bus came, we had
  walked home"); a tense shift tears the scene in two.
- *5.2 Either-Or Doors* (L.5.1a, e): either…or opens one of two doors, neither…nor opens none; prepositions;
  interjections ("Wow!" fills the room with sparkles).
- *5.3 The Comma Bridge* (L.5.2a-c): lists, an opening phrase, yes and no, a tag question, a name spoken to.
- *5.4 The Title Shelves* (L.5.2d): title marks make words a name ("Pip read *The Lost Map*": a book; without them Pip
  reads an actual lost map).
- *5.5 The Word Forge* (L.5.4b): two roots name a gadget, and the gadget appears.
- *5.6 The Two-Faced Words* (L.5.5c): homographs change with the sentence (the bat flew out of the cave; she swung the
  bat); synonyms and antonyms.
- *5.T1 The Story Clock*: a buddy's whole day told in order, played back as a film strip: perfect tenses and steady
  tenses. The habit that fails: "everything in the past" (the morning's plan).

**Floor 6, The Loom** (grade 6). Units: `pronouns`, `extra_information`, `sentence_variety`, `affixes_roots`,
`word_relationships`, `connotation`.
- *6.1 Who Did It?* (L.6.1a-d): subject and object pronouns (Sam and I; Sam and me); myself; a vague pronoun's arrow
  splits (both laugh).
- *6.2 The Side-Note Gate* (L.6.2a): extra information in commas, brackets or dashes is "by the way": take it out and the
  spell still works; without the marks it picks only some.
- *6.3 The Loom* (L.6.3a; with L.3.1i and L.7.1b): sentence combining: three things to say and a ribbon of eight slots.
- *6.4 The Word Forge II* (L.6.4b): anti-, inter-, sub-, trans-, bi-; -ology, -ible, -ist; audi, bene, chron, cred.
- *6.5 Word Webs* (L.6.5b): part and whole, item and category, cause and effect; the Analogy Bridge (page is to book as
  petal is to flower: the bridge's planks fit only in that relationship).
- *6.6 Mood Dyes* (L.6.5c): the same meaning, a different feeling (cosy, small, cramped): the buddies' faces change.
- *6.T1 The Museum Labels*: labels for the tower's museum that visiting buddies follow: clear pronouns, side notes, woven
  sentences. The habit that fails: "he means whoever I'm thinking of".

**Floor 7, The Observatory** (grade 7). Units: `phrases_clauses`, `sentence_kinds`, `modifiers`, `coordinate_adjectives`,
`roots` (and half of `connotation_tone`).
- *7.1 The Clause Stars* (L.7.1a): a clause shines (it can act), a phrase only describes; a dependent clause alone can't be
  sealed.
- *7.2 The Constellations* (L.7.1b): simple, compound, complex, compound-complex as star patterns that make the sky move.
- *7.3 The Wandering Phrase* (L.7.1c): misplaced and dangling modifiers stick to the wrong noun.
- *7.4 The Equal Charms* (L.7.2a): a comma between equal adjectives (a cool, shady forest), none between ones that build
  on each other (a big red bus) (a convention: the honesty table).
- *7.5 The Word Forge III* (L.7.4b): manu, scrib, ped, bellum; phon, therm, hydr, metron.
- *7.6 The Tone Lantern* (L.7.5c): one changed word changes the whole scene's mood (the house stood quietly; the house
  loomed).
- *7.T1 The Star Charts*: a sailor buddy steers by the child's description of the sky: modifiers in the right place.

**Floor 8, The Rule Stones** (grade 8; the tower's roof under the open sky). Units: `verbals`, `voice`, `moods`,
`pauses_breaks`, `word_relationships`.
- *8.1 Shapeshifting Verbs* (L.8.1a): a verb takes another job: -ing as a thing (swimming is fun: a pool party appears),
  as a describing word (the crying baby), to + verb as a purpose.
- *8.2 The Spotlight* (L.8.1b, L.8.3a): active and passive: who stands in the light, who did it, who stays hidden.
- *8.3 The Rule Stones* (L.8.1c, d): moods; if-spells carve rules into stones that wait ("If the moon rises, the gate
  opens"): Baba Is You's idea as grammar.
- *8.4 The Pause Marks* (L.8.2a, b): an ellipsis makes the magic trail off; a dash makes it break and switch.
- *8.5 Word Webs II* (L.8.5b, c): degree (warm, hot, scorching), connotation, analogies.
- *8.T1 The Valley's Rulebook*: write the rules that run a festival by themselves (conditionals, moods).
- *8.6 Your Own Page* (making, phase D): write a page of wishes for a friend; the game checks every wish can be written.

**The reading track: how a child who cannot read yet plays, and how their reading moves the fade** (picture 10).

| Support | What it is | When it leaves |
|---|---|---|
| **The voice** | every card says its word when touched or lifted; every frame word too; Hoot reads every cast spell aloud, each word lighting gold as it is said; long words can be heard beat by beat | never (a non-reader is never stuck) |
| **Picture badges** | a small ink drawing on a content word's card of what it is about (fox; dancing; purple); never of its grammar (no badge shows how many or when) | word by word: when the word **lights** (below); a child can also hide all badges with one picture button (an eye with a slash: "words only") and bring them back |
| **Sound-different choices (stage 1)** | in the meaning rooms, the wrong cards sound different from the right one (fox, foxes; mouse, mice, mouses) | at **stage 2**, look-alikes that sound right but are spelt wrong (ponys) join the hands |
| **The reading rooms** | rooms where reading is the skill itself (the Spelling Forge, the Homophone Hall) | they *open* at stage 2; they are not walls in a non-reader's way |

**The Word Lights** (the game's record of the child's own reading, `WordLights`; the model `model/word_lights_model.py`):
a word **lights gold** in the child's Spellbook when the child picks it right **without touching it first**, three times in
a row, in three different wishes, each time beside cards that look like it (its other forms, or a word with the same
first letter). A wrong pick without a touch puts its count back to nought; when two of a lit word's last three unaided
picks are wrong, its badge comes back until it lights again. A touch is never a mistake; it just isn't evidence. The
model's numbers (ten sessions of 120 picks, 40 word forms, hands of three):

| Player | Words it can't read, lit (after sessions 1 / 2 / 10) | Of the words it reads, lit (1 / 2 / 10) |
|---|---|---|
| Reads the words | 0 | **51.4 % / 89.9 % / 99.4 %** |
| Never reads: touches every card | **0** (its badges never fade) | — |
| Never touches: guesses by the picture | 3.1 % / 6.4 % / 7.2 % (each only until its next misses) | — |
| Reads only the first letter and the gold ending | 4.5 % / 9.1 % / 10.3 % | — |
| Learns from the voice (an assumed learning rate, not a measurement) | 0 | 24.5 % / 62.3 % / 99.5 % |

**What the model changed:** lighting a word after one right pick, or two, let a child who never touches and guesses
light most words within two sessions (63 % and 27 % after the first); three in a row with a reset holds guessing to a few
words in a hundred; putting a badge back after *one* wrong pick kept about one word in eleven dark for a real reader,
so the final rule needs two wrong of the last three. Guessing still keeps about 7 % of words lit at any moment: its cost
is a picture taken away too soon, and the child simply touches the card (ruling 18).

**Stage 2** opens on a floor when 20 of the floor's words are lit (about the first two pages for a child who reads).
**The grade sets the start:** grades 3-4 start with badges on; grades 5-8 start with badges hidden, and a badge appears
on a card the child has touched twice in a row (so an older reader isn't shown baby pictures and an older non-reader
still gets them; ruling 19). The Book always shows words only.

### 3.7 Minute 1, 5 and 30 of a first session

| | Flat (phone, tablet, PC, the web) | VR (the Quest 3) |
|---|---|---|
| **Minute 1** | DISCOVER's English stop shows the tower (Hoot's pick opens it at once for a grade-3 child). Up the spiral stair, letters drifting like fireflies; the star-domed room; the Book's pencil valley. "Welcome to the Word Tower!" The ghost finger lifts "frog" (it says "frog"), lays it on the ribbon, lifts "jumps", taps the star: Hoot reads "A frog jumps!", each word lighting; the ink flies into the pond; a frog jumps in with a splash and the pond turns blue. "Your turn!" | The child stands at the lectern; the valley rises from the pages at waist height, the dome overhead. The ghost hands pull "frog" off the shelf (it speaks in the hand), slot it into the ribbon, slot "jumps", and touch the star with the Magic Wand: a buzz, Hoot reads, the ink pours past the child's hands into the page |
| **Minute 5** | J3: the hungry mice. The child touches "mouses" (it says "mouses"), frowns, touches "mice", lays "three" and "mice", taps the star: three mice nibble the cheese; the meadow by the pond turns green. (A child who casts "mouses" meets the Jumble: it giggles, sneezes ink, says "ta-da!" and hops home.) | The same with the hands: a card held up to the ear says its word; the wand on the star |
| **Minute 30** | The First Page (7 min) and the Story Parade; the Sleepy Dragons (4 min: one dragon snored alone at first, then all four; "On a noun, s means more. On a verb, s means one."); Who's Who (6 min: "It sang" made the log sing); the Shaping Room (7 min: the tallest tower). Three words lit gold in the Spellbook, their badges gone. The end card shows a star on *Nouns and pronouns* | The same pages with the hands: pulling cards off the shelf, slotting a whole spell, the wand on the star; watching the dragons from above like a giant |

### 3.8 Show, say, do (rule 0)

**Shown, not told.** Each new kind of wish is shown once by the ghost (the ghost finger flat, ghost hands in VR), then
"Your turn!": building and casting (T1), a plural (T3); in later pages each new rune, mark and frame. Transfer pages have
no demonstration (they test the idea). After two wrong casts on a wish the ghost lays one card (helped); the eye (SHOW
ME) lays one any time (helped). Idle 10 s: everything that can be touched glows for 3 s (never only the right card).

**Every voice line of phase B** (Professor Hoot, through `PlayVoice.say`; each line cuts in; at most 12 words; a wish's
line describes the situation and **never says the wish's words**, so a child cannot match sounds instead of choosing
forms):

| # | When | Line |
|---|---|---|
| H1 | the arrival | Welcome to the Word Tower! Here, words are magic. |
| H2 | inside | Whatever we write in the Great Book comes true. |
| H3 | T1, the ghost's spell | Watch: a frog jumps! |
| H4 | after a demonstration | Your turn! |
| H5 | T2, free spells | Make anything you like. Touch a card to hear it. |
| H6 | after a free spell (one of) | Ha! Look at that! · What a spell! · The valley loves it! |
| H7 | wishes begin | The valley has wishes. Look at the bubble! |
| H8 | T3, the ghost's plural | Watch: frogs. The ending says more than one. |
| H9 | the trap: one duck | Just one duck came! The wish needs five. |
| H10 | see why, after the trap | Ducks: the s says more than one duck. |
| H11 | too many came | Too many came! The wish wants just one. |
| H12 | the Jumble, the first time | Oops! That's not a real word. The Jumble! |
| H13 | see why, a wild word | One mouse, two mice. Some words change inside. |
| H14 | the ghost's card after two wrong casts | Let me show you one card. |
| H15 | the first granted wish | It came true! Look, the valley has colour! |
| H16 | the Story Parade begins | The Story Parade! Write the last wish of the night. |
| H17 | the parade | Everyone's marching! The whole page is in colour! |
| H18 | see why of the night | The end of a word says how many. |
| H19 | the names, after the night | Grown-ups call these nouns. One is singular, more is plural. |
| H20 | the end card | Wonderful writing! Shall we visit the dragons? |
| H21 | a word lights gold | A golden word! You read it all by yourself. |
| W1 | J1 arrives | A sleepy wish by the fire. |
| W2 | J2 arrives | Party presents are coming! Look how many. |
| W3 | J3 arrives | Someone's hungry for cheese! |
| W4 | J4 arrives | Somebody wants a swim. |
| W5 | J5 arrives | Autumn is here! Look at the tree. |
| W6 | J6 arrives | Time for a dance on the hill! |
| W7 | J7 arrives | A snowy wish! Look how many. |
| R1 | a card touched or lifted | its word ("foxes"); a frame word too ("swim") |
| R2 | a cast | the spell, word by word, each word lighting as it is said |
| R3 | a long word touched twice | its beats, one by one ("but-ter-fly") |
| D1 | the dragons' page opens | Shh! Dragon Hill. The baby dragons are sleeping. |
| D2 | the frame (teaching: the situation, not the move) | Here the words are written. You choose how they act. |
| D3 | one dragon acted alone, the first time | Only one dragon snored! The others slept on. |
| D4 | ink copies, the first time | Ink copies! The plain word made lots of them do it. |
| D5 | waiting 15 s (once; the goal, not the move) | Make the dragons do what the bubble shows. |
| D6 | see why after the first right cast | Snore: they all do it. Snores: just one does it. |
| D7 | see why, two subjects | The fox and the dragon: two of them, so laugh. |
| D8 | the egg hatches | The egg hatched! Welcome, little one! |
| D9 | see why of the room | On a noun, s means more. On a verb, s means one. |
| D10 | the end | The moon is high. Goodnight, little dragons! |
| P1-P6 | praise (the choice and the effort, one at a time, never twice in a row; never speed) | Spell-tastic! · Perfect words! · Just right! · You wrote it true! · Hoo hoo! Wonderful! · What a Word Keeper! |
| G1-G6 | the place's own | (break) Need a rest? The tower will wait. · (Back) Leave the tower? Your page stays in colour. · (the Jumble hops home) Bye, Jumble! Back to the inkwell. · (idle 30 s) Touch a card to hear it. · ("words only" on) Words only. You're reading! · (badges back) The pictures are back. |

All lines are at most 12 words (checked by a script, `docs/devlog/parts/game-words-a.md`); the only questions (H20, G1,
G2) are spoken and answered with picture buttons, so none needs reading. Each later page carries its hook line and its
see-why line (§3.6 gives their ideas); phase C writes the rest to the same rules. Without a voice (Read to me turned off
by a grown-up, or no English voice on the device) a non-reader cannot hear the cards: Word Magic then keeps every badge
on and says so to the grown-up's page; it is fully playable only by readers (ruling 29).

**How the voice carries the words** (picture 10):
1. A card speaks when **touched or lifted**, never by itself, so the child always gets a moment to try to read it first
   (self-teaching, [R5]).
2. Hoot reads a spell **after** it is cast, never before (the wish line describes the situation, never the words).
3. Each word lights gold as it is said (print attention, [R13]); in VR the words float up past the child's eyes in order.
4. A long word touched twice is said beat by beat, each syllable lighting (segmented speech, [R7]); a word with an ending
   is said stem first, then whole ("fox … foxes"), its gold ending lighting on the second.
5. On the screen during play: the words (the subject), their pictures until they light, the bubble's picture, and
   nothing else written. Hoot's lines are never on screen while the voice is on.

**Things and their meanings** (picture `08-cards-and-runes.png`). Shape, motion and sound carry each meaning too, so
nothing depends on colour alone.

| Thing | Its look | Its sound |
|---|---|---|
| A word card | a parchment tile, the word in dark ink in a big clear round hand; its ending in gold ink; a small round picture badge in the corner until the word lights | its word, when touched or lifted |
| A made-up word (the Jumble's) | exactly like a real card (it must be read or heard to be told apart) | its letters as written ("mouses") |
| The Spell Ribbon | the Book's golden bookmark ribbon, floating, with gaps as soft hollows; frame words written on it in ink | a soft click as a card settles |
| The star seal (the full stop) | a gold star at the ribbon's end; dim until every gap holds a card, then glowing | a two-note chime as it casts |
| Runes (later floors) | gold glyph tiles that snap to a card's front (un-, re-) or back (-ful, -less); marks as runes: the comma a gold hook, the speech-bubble pair, the owner rune (a small key-shaped apostrophe) | a snap; a soft bump when one won't fit |
| Ink | words lift off the ribbon as black ink, swirl and dive into the page; a splash where the thing appears | a whoosh, a splash |
| The colour bloom | a pencil patch of the valley floods with watercolour from where the ink landed | a soft rising chord |
| Outlines (a number that wasn't filled) | glowing dashed outlines of the missing things, which flap or hop uselessly, then fade | a hollow "pip" each |
| Ink copies (a plain verb with one doer) | translucent ink twins that do the action with the real one, then fade | the action's sound, doubled |
| The Jumble | a round ink-black blob with big white eyes and letter-shaped feet; pops out of the inkwell | a giggle, a sneeze, "ta-da!" |
| The bubble's time frames (floor 3+) | an old photo with a curled corner and sepia ink (it happened); a live picture (now); a dotted outline with a little sunrise (it will) | — |
| The glows | gold: a word being said, a lit word; teal: the star ready; green: a wish granted; a soft lilac shimmer: not yet | a chime (granted); a soft "hmm" (not yet) |
| A golden word | the word in the Spellbook turns gold, its badge gone | a tiny bell |

**Sounds and music** (all already in the repo, public domain or CC0, `assets/CREDITS.md`): Bach's *Goldberg Variations:
Aria* for writing in the tower; Mozart's *The Marriage of Figaro* overture for the Story Parade; Satie's *Gymnopédie No. 1*
for Dragon Hill; later floors: Mozart's *Symphony No. 40* (the Time Windows), Rimsky-Korsakov's *Flight of the
Bumblebee* (Chain Spells), Grieg's *Morning Mood* (dawn turning the page). New sounds (the quill, the card's click, the
star's chime, the ink's whoosh and splash, the bloom's chord, the Jumble's giggle and sneeze, the buddies' babble, the
dragons' snores and sneezes, the egg's crack) are made by a tool like `tools/make_tiny_sfx.py`: original, so CC0 by
construction.

**Words on the screen during play:** the cards' words and the frame's words (the subject, always said aloud on touch),
nothing else. The HUD shows pictures (G0's glyphs: the ear repeats Hoot's line, the eye is SHOW ME, two bars are a
break, the eye with a slash is "words only"). The end card shows numbers (the gold) and stars.

### 3.9 The five tests, answered

**Choice.** What an 8-14-year-old chooses, and how this game gives it: *words with power* (a word makes a thing appear:
the oldest magic in stories, and Scribblenauts' whole appeal); *a place that grows because of you* (a valley in colour,
yours to visit); *creatures* (buddies with wishes, baby dragons, the Jumble); *humour* (the literal world: the log that
sings, the school with a tail, the cat-dog); *getting good, visibly* (golden words, longer spells, new runes); *the
body* (in VR, cards off a shelf and your own Magic Wand on the star); *making* (your own page for a friend, 8.6);
*short* (a wish 20-40 s, a page 4-8 minutes, never timed). Risks: a confident older reader may find the prologue easy
(it is ten minutes; the grade then picks the floor, and floors 5-8 are not easy for anyone); a child who dislikes "school
words" may see cards as homework (the answer is the magic: nothing is labelled, everything happens). **How we check:**
the owner's child plays phase B; we note voluntary time, whether they start the dragons unasked, whether they come back,
and what they say about the Jumble. A game nobody returns to is redesigned before phase C.

**Mute (playable by a child who cannot read yet).** The wish is a picture; every card and frame word speaks when
touched; Hoot reads every cast spell, each word lighting; the First Page's and the dragons' wrong cards sound different
from the right ones; the world answers every cast in pictures. The only text on screen is words, which are the subject,
and every one of them is heard on a touch. The models' listener (who only hears) is the idea player: **100 %** on both
rooms. At stage 2 a listener still masters the First Page (it misses the look-alike wish half the time: 49 % on J6), which
is why stage 2 opens by reading and its look-alikes are reading evidence, not a wall. **How we check:** a test that every
card, frame word and line is spoken (`PlayVoice`); no text on screen while a wish plays but the cards' and frame's words
(`WordMagicHud.screen_words()`); a child who cannot read yet plays the First Page; the owner's child plays it.

**Cheat.** A form must be chosen (badges never show grammar), the first cast counts, nothing previews a spell, and every
hand holds the tempting wrong card. The phase A model (`model/first_page_model.py`, 1,000 visits per player, eight
judged wishes, new numbers and words every visit; the bar is MasteryRules': 7 of 8 right first time):

| Player | Reaches 7 of 8 | Right first time (of 8) | What happens |
|---|---|---|---|
| Knows how English says how many (reads or listens) | **100 %** | 8.00 | the right number word and the right form, wild words included |
| Knows it, slips on 4 % of picks | 86.2 % | 7.32 | a mis-tap costs that wish (two or four picks a wish) |
| Random cards | **0 %** | 1.14 | — |
| Matches the picture badge | 0 % | 1.14 | the badge is the same on every form |
| Trial and error, the first cast counting | 0 % | 1.14 | its first cast is a guess |
| Counts right, then any form | 0.2 % | 2.76 | knows "three"; the form is still a guess |
| A gold ending means more | **0 %** | 4.15 | right on regular plurals; wrong on mice, geese, children, sheep (their made-up forms have gold endings) |
| Sounds like an s added (the by-ear regulariser) | **0 %** | 3.99 | right on frogs and foxes; mouses, gooses, childs, sheeps |
| The longest word means more | **0 %** | 4.28 | mouses, gooses, sheeps; and wrong on a single goose half the time |
| Always the plain word | 0 % | 2.71 | right only on single things and sheep |
| Trial and error with a preview (**not built**) | 100 % | 8.00 | why nothing previews a spell (ruling 7) |

**What the model changed.** The first draft had one gap a wish (the number already written), regular nouns only (frog,
duck, fox, box, pony, bunny) and two cards a gap. There, "a gold ending means more", "it sounds like an s added" and "the
longest word means more" each granted every wish on **100 %** of visits, with no idea that English has plurals that don't
add an s; random cards reached the bar on 1.7 %. The final page has a number gap *and* a noun gap in every wish, wild
words (mice, geese, children), a word that stays the same (sheep), f to v (leaves), the Jumble's forms in every wild hand,
two wishes for ONE thing (one of them wild), and a four-gap Parade: every habit **0 %**. Reported honestly: a slip rate
of 4 % per pick still loses about one visit in seven.

**Transfer.** Each idea comes back somewhere new, where the old habit fails and the idea works. The phase A model of the
Sleepy Dragons (`model/sleepy_dragons_model.py`, 1,000 visits, six judged wishes, the bar 5 of 6):

| Player | Reaches 5 of 6 | Right first time (of 6) |
|---|---|---|
| Knows it (the verb agrees: s means one) | **100 %** | 6.00 |
| Knows it, slips 4 % | 89.3 % | 5.44 |
| **The First Page's habit: an s means more** | **0 %** | 0.00 |
| Copies the subject's ending (dragons, snores) | **0 %** | 1.25 |
| Agrees with the nearest noun (the fox and the dragon laughs) | **0 %** | 4.00 |
| Always the plain verb (he go) | 0 % | 2.27 |
| Always the s verb | 0 % | 0.25 |
| Flips a coin | 0.1 % | 1.13 |

**What the model changed:** the first draft had one verb a wish (snore or snores): a coin-flipper reached the bar on
**11.0 %** of visits and "always the s verb" on 11.6 %. Linking two or three decisions in every wish brought the coin to
0.1 %; but with one compound subject, "agree with the nearest noun" still passed **100 %** (it fails only that wish): the
final room has two compound subjects, each beside a clause about one thing (0 %).

The ladder's model (`model/ladder_model.py`, 1,000 visits each, six wishes a room, the bar 5 of 6) checks eleven later
rooms the same way:

| Room (floor) | The habit that fails | The idea | Others |
|---|---|---|---|
| (a) Time Windows (3) | adds -ed for the past (runned): **0 %**; always now: 0 %; the longest (will run): 0 % | **100 %** | any real word, any time 0 %; random 0 % |
| (b) Chain Spells (3, 5) | "because" for "so" (the cause told second): **0 %**; and everywhere: 0 %; so everywhere: 0 % | **100 %** | random 0.3 % |
| (c) The Homophone Hall (4) | only listens (they sound the same): **0.1 %**; the apostrophe means it belongs: 0 %; always the commonest: 0.1 % | **100 %** | — |
| (d) The Comma Bridge (5) | a comma everywhere: **0 %**; a comma wherever you pause: **0 %**; never a comma: 0 % | **100 %** | random 0.5 % |
| (e) The Wandering Phrase (7) | always at the end: **0 %**; always at the start: 0 % | **100 %** | random 0 % |
| (f) The Which Gate (4, 6) | commas always: **0 %**; never commas: 0 % | **100 %** | random 0 % |
| (g) The Loom (3, 6, 7) | joins with and, and, and: **0 %**; says only the first thing: 0 % | **100 %** | any weave that fits 1.2 %; random 0.2 % |
| (h) The Spotlight (8) | the first noun is the doer: **0 %**; always active: 0 % | **100 %** | random 0 % |
| (i) The Rune Bench (3, 4) | un- for every "not" (unappear): **0 %**; knows the suffixes only: 0.1 % | **100 %** | random 0 % |
| (j) The Word Forge (5-7) | the most familiar roots (telephone): **0 %**; knows the first root only: 0.7 % | **100 %** | random 0 % |
| (k) Mood Dyes (6, 7) | always the nice word: **0 %**; always the strongest: 0 % | **100 %** | random 0.1 % |

**What the ladder's model changed** (its `--draft` flag prints the first drafts): (a) regular verbs only let "add -ed"
pass **100 %**: every wish now has a wild past; (b) a fixed order (the cause told first) let "so everywhere" reach 17.4 %
and "because for so" 16.0 %, and a second draft that drew the other words at random still let "because for so" pass 12.2 %
whenever "because" was missing from the hand: every hand now holds "and" and "so" (and "because" in a cause wish); (c)
one homophone a wish let a listener reach 11.2 %: two a wish; (d) lists only let "comma everywhere" and "a comma where you
pause" pass 100 %: names spoken to and names done to, and long subjects where a reader pauses but no comma belongs; (e) a
phrase always at the end let "always at the end" pass 100 %; (f) things only: people and things, both kinds of clause;
(g) a ribbon with no slot limit let the and-chain pass 100 %: eight slots; (h) one frame a wish let the first-noun habit
reach 10.1 %: two scenes a wish, passives with and without the doer; (i) un- words only let "un- for every not" pass 100 %,
and a second draft without un- in every hand still let it pass 19.4 %: every "not" wish now offers un-; (j) one job (a
far-hearer: telephone) let familiar roots pass 100 %: six jobs; (k) always a warm feeling let "the nice word" pass 100 %.
**The rule the drafts taught: every hand holds the tempting wrong card** (ruling 9), as the bakery's queues hold their
traps.

The first unhelped right wish in a new setting is recorded as `SkillShown.NEW_SETTING`. The written exercises of the
School and the Book stay as the outside check (the lead's audit, phase C).

**Wow.** The tower's star-domed room; a pencil valley rising from the Book; the first spell's ink diving into the pond
and the pond turning blue; the Jumble popping out of the inkwell, sneezing ink; one dragon snoring alone while its
friends sleep on; the Story Parade across a valley in full colour; in a headset, a card speaking in your hand and your
own Magic Wand touching the star. Each wow *is* the concept (the thing appears because of the noun's form; the dragon
snores alone because of the verb's -s), never decoration. **How we check:** the owner's verdict on phase B, and whether
the child shows it to someone.

### 3.10 What the game records as learning (invisible assessment)

The game never asks a question to check. Its evidence model (evidence-centred design, as the other deep games'; stealth
assessment, LP [G9]): each **competency** is an idea of §3.4; each **wish** is a situation where the child's spell shows
it, judged by the Spell Reader; each judged wish becomes one `SkillShown` event for the page's unit.

**The wishes of phase B** (unit `g3.english.nouns_pronouns`):

| Wishes | When | Judged when | Kind | Strength of the evidence |
|---|---|---|---|---|
| T1-T4 | the First Page's ghost spell, free spells, the ghost's plural, the trap | not judged | — | teaching (a wrong cast here is how the idea is met) |
| J1-J7 | the First Page | granted at the first cast, no help | SOLVED (else HELPED; SHOWN if the ghost finished it) | strong: random 2-33 % per wish (one-gap J5 is the weakest), every habit 0 % of visits |
| J8, the Parade | the page's end | as above (four gaps) | SOLVED / HELPED / SHOWN | stronger: random 2 % |
| D1-D6 | the Sleepy Dragons | as above | NEW_SETTING (else HELPED / SHOWN) | strongest: the First Page's habit grants none of them |

So the First Page gives **8 events** (MasteryRules counts a round at 6; 7 of 8 right first time masters the unit, ★★,
its gold once) and the dragons **6 events**, `NEW_SETTING` when unhelped (a full round, its transfer kept apart). Events
are added as each wish is judged; `record` runs once when the page ends (never on "stop for now", G0's rule); each SOLVED
or NEW_SETTING wish pays the first-try gold through `SkillShown.pay_first_try` (the daily cap holds).

**What each event's note says** (for the journal and the grown-ups): "one for many" (a singular where the bubble showed
more), "many for one", "made-up word" (the Jumble came: which word), "number and noun disagree", "s means more" (the
dragons: an -s verb for many), "plain for one", "nearest noun", "ghost card", "eye". A wish granted but not at the first
cast is HELPED with a note (the altar's ruling, approved).

**What "help" means:** the ghost's card (after two wrong casts, or on SHOW ME) and the ghost finishing a spell. The
teaching lines (H3, H5, H8, D2) and D5 (which restates the goal, never the move) are not help. **Touching a card to hear
it is never help:** listening is how a non-reader reads the cards, and the grammar is still theirs to choose. **Gold:**
each SOLVED or NEW_SETTING wish pays the School's first-try gold; nothing pays for time.

**The reading record** (separate from the units): the Word Lights (§3.6) are kept in the game's own **Keeper's journal**
(device-only in phase B, `user://word_magic.json`): each word's state (heard, lit, when), the stage, the badges' setting,
which wishes were granted and with what notes ("cast 'mouses' once on the first night, never since; read 'children' on
their own on the second"). They are not `SkillShown` events (no School unit is about reading single words: our School
starts at grade 3; ruling 17), but phase C shows them on the grown-ups' page in plain words ("Reads 34 of the tower's
words on their own").

**The room-to-unit map** (one main unit per room, so each room is a full round for its unit; other units get review
events only when already mastered, as the leaf's ruling 9): every room of §3.6 names its one unit (the transfer pages:
NEW_SETTING for their floor's main unit of the idea they test: 3.T1 `nouns_pronouns`, 3.T2 `joining_sentences`, 4.T1
`relative_words`, 5.T1 `perfect_tenses`, 6.T1 `pronouns`, 7.T1 `modifiers`, 8.T1 `moods`).

**Adaptivity (honest).** After two helped wishes in a row, an extra wish of the same kind is slipped in and taught again
(the ghost lays its first card; not judged; the journal notes "re-taught"); the badges and stages move as §3.6 says.

**Why this shows learning:** a wish is granted first time only by the forms that say what the bubble shows; the habits
that read endings, sounds or lengths were tested and fail (§3.9); in the dragons' page only by agreement, the opposite of
the First Page's habit. What wishes cannot show (whether the child can *explain* the rule, or *write* it on paper) is the
Book's and the School's written exercises' business, never a quiz.

### 3.11 The look

**The idea:** a bedtime book come alive, built from the game's own shapes in the Life rooms' kit look (lit matte shapes,
glowing parts), so it is EasyCraft and it runs on a phone and a Quest: a deep-blue dome with gold stars, cream stone,
warm wood, parchment cards, gold ribbon and runes, black ink; a valley of pale grey pencil that blooms into soft
watercolour colours where the words land. The pictures in `word-magic/` are the sketches:

- `01-the-word-tower.png`: the tower at night beside the Academy, letters drifting from its dome; inside, the star-domed
  room: the Great Book's pop-up valley (half pencil, half in colour), the Spell Ribbon, the shelves, the inkwell and the
  Jumble, Hoot in his wizard's hat.
- `02-write-it-true.png`: the verb in four steps (the wish, the cards that speak, the spell on the ribbon, the cast and
  the colour), the Jumble's wrong cast, and why only the first cast counts.
- `03-the-literal-world.png`: what wrong words do: five duck, mouses, the dragons snores, the baby sneeze, it sings (the
  log), the school with a tail, the cat-dog.
- `04-the-first-page.png`: the night as a timeline with its wishes.
- `05-the-sleepy-dragons.png`: the transfer: the habit's "snores" (one dragon) against "snore" (all four).
- `06-core-loop.png`, `07-the-ladder.png`, `08-cards-and-runes.png`, `09-vr.png`, `10-the-reading-track.png`,
  `11-later-rooms.png`, `12-cheat-test.png` (the models' results, computed from the models when the pictures are made).

**Scale.** The top room is about 8 m across under a 6 m dome; the lectern 0.85 m high (child height in VR), the Book's
pop-up valley 1.2 m wide and 0.8 m deep with hills up to 0.35 m; the ribbon 1.0 m long at the Book's near edge with gaps
0.16 m wide; a card 0.14 × 0.09 m (in VR the word's letters are at least 3.5 cm tall: legible at arm's length); summoned
things 4-12 cm tall in the valley (buddy-sized for a giant). Flat, the camera looks at the Book and the ribbon from the
front and a little above, the dome and window behind (the station view of G0's arena); the fan of cards along the bottom
of the free band, each card a fingertip and more.

**Light:** one warm key light (the lamps), a cool moonlight fill from the window, no shadows (the budget); the cards'
words, the star, the ink and the lit windows of the valley glow. **Colour:** deep blue and cream around, gold for the
magic (the ribbon, the endings, the runes, the star), black ink, and the valley's watercolours standing out against the
pencil grey. **Motion:** cards float and settle; ink swirls and dives; colour blooms outward from a landing; buddies hop;
the Jumble bounces; dragons breathe as they sleep.

**Both graphics styles:** phase B has one look (the kit's), used in blocky and realistic; a realistic twin is phase C's.

### 3.12 Kind, fair and safe

Never timed: a wish waits as long as the child thinks; a buddy just wiggles. Never lost: a wrong cast's ink flows back
and the cards return; nothing is ruined; stopping keeps every coloured patch; nothing happens to the valley while the
child is away (no timers, no decay, no streaks). No failure screen: the ghost helps after two wrong casts. A buddy is
never sad or in danger (it tilts its head and waits). The dragons are baby dragons, round and sleepy, their flames tiny
puffs; the Jumble is cheeky, never mean, and never scary. **Only curated words**: the shelves hold the room's words and
nothing else; there is no typing, so nothing unkind or unsafe can be written or summoned; the Jumble's made-up words are
chosen from the classic wrong forms, never rude ones. No money, no shop, no random rewards, no gambling. No real names (the
studies and apps stay in this document; the buddies' names are the game's own). **No microphone, ever**: the game speaks,
the child builds. Calm sounds (the "not yet" is a soft "hmm", never a buzzer). Reduce motion (SETTINGS) makes things
appear without the ink's flight and the bloom fade in, and stills the drifting letters. VR comfort: the child stands at
the lectern; nothing moves the child; blink is the comfort choice for any move.

---

## 4. The tech plan for phase B

### 4.1 What phase B builds

The First Page and the Sleepy Dragons, complete and beautiful, flat and VR: the arrival up the stair, the star-domed
room, the Great Book's pop-up valley and its colour bloom, the Spell Ribbon, the cards (speaking, badges, gold endings),
the star seal, the Spell Reader and the judge, the voice (a card on touch; a spell read word by word with each word
lighting), the ink's flight, the summoned things and their actions (a library of about 16 things and 12 actions), the
outlines, the ink copies and the Jumble, the ghost's demonstrations, the free spells, the Story Parade, the dragons'
page, the end card, the Word Lights and the Spellbook (its page of golden words), and a two-page board (the First Page
again, the dragons). Opened from DISCOVER (the unit page's PLAY for `g3.english.nouns_pronouns`, and Hoot's pick), from
the Academy's Word Tower door, and by a developer argument.

### 4.2 What G0's and W1's foundation gives, and what this game adds

| The foundation gives (`docs/devlog/parts/play-g0.md`, `play-w1.md`, DEVELOPMENT.md "The foundation's API") | This game adds |
|---|---|
| `PlayVoice.say` / `on()` and `ReadAloud.speak` (the system's text-to-speech through `DisplayServer.tts_speak`, each line cutting in); words only without a voice | `WordVoice`: a card's word on touch (cutting in); a spell read **word by word**, each word lighting as it is said (one utterance per word, stepped by the "ended" callback; Godot also reports word boundaries through `tts_set_utterance_callback(TTS_UTTERANCE_BOUNDARY, …)`, but "the granularity of the boundary callbacks is engine dependent" [T1], so it is an upgrade where it is measured, not the base); the stem-then-whole reading; the lines as data (`data/play/words/lines.json`), each tested for length and for never containing its wish's words |
| `SkillShown`: `begin`, `add(unit, kind, note)`, `pay_first_try`, `record`; the round rule (6 events) | `WishBeats`: each judged wish into one event with its note |
| `PlayHost`'s pattern: a place far above the world, hiding the screen it came from, its own camera, `LifeReach` for fingers, hands, laser and head, the VR anchor and blink, the idle glow, SHOW ME, the break card, Android Back (`any_open`) | `WordMagicHost`: the same pattern for a page of wishes (not exercise by exercise): wishes arriving, the fan of cards, the ribbon, the star, the cast and its playback |
| `LifeGhostFinger` (flat) and `LifeGhostHands` (VR): show a step | the demonstrations: building and casting (T1), the plural (T3); the ghost's card after two wrong casts (the next card of `SpellSolver`'s right spell) |
| `PlayGlyph`, `PlayHud`'s ear, eye and break pictures; the screen-word budget | `WordMagicHud`: the "words only" glyph, the end card's pictures; no words on screen but the cards' and the frame's |
| `LifeRoomKit`: shapes and materials the warm-up already holds | `TowerKit` on top of it: stone, wood, parchment, gold, ink; the valley's pencil and watercolour as two kit colours per patch, tweened (no new shader) |
| `Buddy` (the living buddies' mesher: a block build with googly eyes) and `LifeBuddy` | `ValleyCreature`: small block builds with `Buddy`'s look (frog, cat, dragon, duck, fox, presents, mouse, goose, leaves, wolf, pony, bunny, child, sheep, baby dragon, egg), no physics; procedural actions: appear, hop, dance, sleep, snore, sneeze, fly, swim, eat, howl, roll, laugh, march |
| `VrGrabber.claimers` (`grip_claim(side)`, `grip_release(side)`), `Vr.hand_busy`, `Vr.simulate` / `sim_hand` / `sim_input`; the Magic Wand item (`WAND`) | the lectern claims a grip near a card or a gap; the wand in the other hand touches the star (a palm press works too) |
| DISCOVER, the registry's `signature` entries, P0/P1 and the audit; W1's `AcademyPlaza.opens()` (the lead's switch), `DiscoveryPlays.subject_unit`, the crystals' `DiscoveryPlays.play_for` | one registry entry (`word_magic`) that names a **host** (the leaf's B2 mechanism, §4.7); the English door's rule (§3.2) |
| The School's generators (`G3WordsGen`, `G4EnglishGen`, `GenWords`) | `SpellLexicon` takes its words from the same lists (plurals and their likeliest wrong forms, past tenses, comparisons, conjunctions, homophones), so the game and the Book agree |

### 4.3 Files

- **Pure rules, `core/play/words/`** (no nodes; deterministic; seeded; the phase A model's rules, `model/spell_rules.py`):
  - `SpellLexicon`: every word's stem, class, forms (number, tense, comparison), badge, the Jumble's forms (the classic
    wrong forms), the look-alikes (stage 2), from `data/play/words/lexicon.json`; checked against `G3WordsGen`'s lists.
  - `SpellCard`: a card (a word or a rune) as the child sees it: letters, gold ending, badge, what it says.
  - `SpellReader`: reads a ribbon of cards as English: noun phrases (number, describing words, noun), clauses (subject,
    verb, object or place), pronoun reference, joins; gives a `SpellMeaning` or a Jumble, outlines, ink copies, or a dim
    star (§3.4's literal rules).
  - `SpellMeaning`: the things (kind, count, look), the actions (who acts: one or all; when; how), the links.
  - `SpellJudge`: a meaning against the wish: granted or not, and the note (one for many, made-up word, s means more…);
    SOLVED / NEW_SETTING / HELPED / SHOWN.
  - `WishBook`: the wish forms per page, seeded by night and slot, with the First Page's composition (§3.5's rules
    table), the dragons', the tempting card in every hand, stage 2's look-alikes.
  - `SpellSolver`: the right spell for a wish (the ghost's next card; SHOW ME).
  - `WishBeats`: one judged wish into one `SkillShown` event.
  - `WordLights`: the reading evidence rule (three in a row, different wishes, a reset; two wrong of the last three put
    a badge back), the badges' state, the stage.
  - `WordVoice`: what is said when (a card on touch, the spell after the cast, word by word, the beats of a long word).
  - `WordMagicPages`: the catalogue (`data/play/words/pages.json`): each page's wishes (form, taught or judged, its
    buddy), lines, music, unit, unlocks; the ladder.
  - `WordMagicProgress`: the coloured patches, the golden words, the stage, the Keeper's journal; a device file in phase
    B (`user://word_magic.json`, like `PlayQuests`).
  - `WordHandRules` (VR): a card in the hand over a gap; the wand's touch on the star.
- **The place, `entities/play/words/`:** `WordMagicHost` (open/close, input, camera, VR, the demonstrations, the record,
  the `finished` / `stopped` signals as `PlayHost`'s, `any_open`), `TowerRoom` (the dome, the shelves, the window, the
  lectern), `GreatBook` (the pop-up valley: hills, pond, path, cottages and tree that fold up from the pages; the colour
  bloom per patch), `SpellRibbon` (gaps, frame words, the star), `WordCard` (a parchment tile: its word as text, its gold
  ending, its badge), `CardFan` (the hand along the ribbon), `ValleyCreature` (the things and their actions),
  `InkFlight` (the words' flight and splash), `Outline`, `InkCopy`, `Jumble`, `Spellbook` (the golden words page), and
  Hoot's wizard's hat.
- **UI, `ui/play/words/`:** `WordMagicHud` (the ear, the eye, the break, "words only", the end card, the page board).
- **Data:** `data/play/words/lexicon.json`, `pages.json`, `lines.json`; the unit's `play` block names the game (§4.7).
- **Sounds:** `tools/make_word_magic_sfx.py` (the quill, the card's click, the star's chime, the ink's whoosh and
  splash, the bloom, the Jumble's giggle, sneeze and "ta-da", the buddies' babble, the dragons' snores and sneezes, the
  egg's crack); the music is in `assets/`.
- **Tools:** `tools/word_magic_smoke.gd` (plays both pages with the idea bot, flat and simulated VR, headless; checks the
  record), `tools/word_magic_shots.gd` (pictures in a real window: the arrival, a cast, the Jumble, the Parade, the
  dragons), `tools/word_magic_bench.gd` (draws and frame times, VR preview).

### 4.4 Flat and VR

**Flat (phones, tablets, PC, the web).** The camera looks at the Book and the ribbon from the front and a little above,
the dome and the window behind. **Cards:** the fan floats along the bottom of the free band (`PlayHud.FREE`), at most 8
cards, each at least a fingertip wide with its word at least 28 px tall on a phone; a tap on a card lifts it and it
speaks; a tap on a gap puts it there; a drag does both; a tap on a placed card lifts it back out (free until the cast); a
long press (0.6 s) on a card says its beats. **The star** glows when every gap holds a card and is tapped to cast. The
eye (SHOW ME), the ear (Hoot's last line), the break, and "words only" are HUD pictures. A developer argument opens a
page directly (`--word-magic-page=first` or `dragons`).

**VR (the Quest 3).** The child stands at the lectern (`Vr.anchor`), the Book at waist height, the dome above. **Cards:**
the fan floats in an arc at chest height between the child and the Book; a grip on a card takes it (the lectern claims the
grip: `grip_claim(side)`) and it speaks; raising a held card near the head says it again; letting go over a gap places it
(the gap glows under the hand); elsewhere it floats back to the fan. **The star:** touched with the Magic Wand held in the
other hand (EasyCraft's own wand), or pressed with a palm. **One-handed** (a comfort setting): a trigger on a card, then
on a gap; a trigger on the star. The HUD stays hidden; the raised forearm shows the small panel (owner #127). Hoot perches
on the lectern, his voice placed there; the cast's words float up past the child's eyes as they are said. Tests drive it
with `Vr.simulate`, `sim_hand`, `sim_input`.

### 4.5 The budget

Targets: **≥ 30 FPS average and no frame over 100 ms on the emulator**; **≤ 100 draws a frame on the Quest** (the floor
preset, 72 Hz), aim ≤ 70; one light, no shadows; only shaders the warm-up holds (the kit's materials; a new one goes into
the census with its test). Estimated draws at the heaviest moment (the Story Parade): the room's shell (dome, walls,
floor) merged 3; the shelves merged 1 and their card tiles 1 (a MultiMesh); the window and sky 1; the lectern and the
Book's cover 1; the valley's pencil pieces merged 2 and its coloured patches 3 (a material per state); trees 1 (a
MultiMesh); cottages merged 1; the pond 1; the ribbon 1 and the star 1; the fan's tiles 1 and their words 8 (one
`Label3D` per visible card, an MSDF font; or one text atlas for the fan if Label3D costs more on the Quest); badges 1;
creatures (each kind merged, eyes one MultiMesh for all) 8 + 1; ink particles 2; the Jumble 2; Hoot 5; the VR hands 4
(flat: none); the HUD canvas 10-20 (pictures batched like `CanvasBatch`) → **about 60-80**. Ordinary wishes: about 45-60.
The text is the new cost: phase B measures it first (session 1's pictures and draw count).

### 4.6 Tests (TDD, each failing first)

- `tests/unit/test_spell_lexicon.gd`: every word's forms; the Jumble's forms are never real words; look-alikes sound
  like their real forms (as data); every word spelt the same in British and American English (the generators' rule).
- `tests/unit/test_spell_reader.gd`: noun phrases' counts; disagreement brings outlines; a made-up word brings the
  Jumble; a verb's -s makes one act, the plain form all (ink copies for one); pronouns stick to the nearest match; an
  empty gap keeps the star dim.
- `tests/unit/test_spell_judge.gd`: granted and not; every note; SOLVED, NEW_SETTING in the dragons' page, HELPED after
  help or a second cast, SHOWN when the ghost finishes.
- `tests/unit/test_wish_book.gd`: every wish can be written from its hand; the First Page's composition slot by slot;
  the dragons'; every hand holds its tempting card; stage 2's look-alikes only at stage 2.
- `tests/unit/test_word_magic_cheat_bots.gd`: **the cheat test as a test**, the models' players over 1,000 seeded
  visits: random, picture, gold-more, sounds-more, longest, plain and count-only reach the First Page's bar in under 1 %;
  the idea always; the slip bot in over 80 %; in the dragons' page the habit, copy-the-ending, nearest-noun and
  always-plain never, the coin under 1 %, the idea always.
- `tests/unit/test_word_lights.gd`: the rule (three in a row in different wishes; the reset; two wrong of the last three
  put the badge back); the model's guesser keeps under 10 % of words lit over ten sessions, a reader over 85 % by the
  second; a listener never lights a word.
- `tests/unit/test_word_voice.gd`: every line at most 12 words and never a question that needs reading; no wish's line
  contains its wish's words; a card speaks on touch only; a spell is read word by word after the cast.
- `tests/unit/test_word_magic_pages.gd`: the data: every page names a written unit; every page has its hook and see-why.
- `tests/unit/test_word_hand_rules.gd` (VR): a card released over a gap; the wand's touch on the star.
- `tests/integration/test_word_magic_place.gd`: every target in the flat view's free band and at least a fingertip; the
  cards' words legible (size); everything within both hands' reach from the VR spot; only warmed shaders; no shadows.
- `tests/integration/test_word_magic_host.gd`: flat and simulated VR through both pages: the arrival, the demonstrations,
  the free spells, the trap, the Jumble, the Parade, the dragons, the record (`SkillShown` events, the stars), the Word
  Lights, the break, stop for now (nothing recorded), Android Back.
- `tests/integration/test_word_magic_voice.gd`: every line spoken by itself; no text on screen but the cards' and the
  frame's words.
- `tests/integration/test_word_magic_budget.gd`: draws at the Parade ≤ 100 (the place's own counter).
- The full suite once at the end; the smoke; pictures in a real window; the bench; then the lead on the emulator and the
  Quest (the voice above all), and the owner's child.

### 4.7 The hooks phase B needs from others (the lead decides: §8)

1. **The registry for a deep game with its own host**, as the leaf's review decided: `data/play/mechanics.json`'s
   `"signature": {"word_magic": {"name": "Word Magic", "host": "res://entities/play/words/word_magic_host.gd"}}` and
   `SchoolScreen`'s PLAY opening a host when the unit's `play.game` names one (the leaf's phase B2 builds it).
2. `g3.english.nouns_pronouns`'s `play` block: `{"game": "word_magic", "params": {"page": "first"}}` (a content file).
3. Back and the pause key belong to the tower while it shows (`WordMagicHost.any_open` beside `PlayHost.any_open` in
   `menu.gd`; W1's `room_open` / `close`).
4. W1's Academy: the Word Tower door (`AcademyPlaza.opens` for `english`) opens Word Magic by §3.2's rule.
5. **The voice:** `ReadAloud`'s system voice speaks without an utterance id today; word-by-word reading needs an id and
   an "ended" signal (a small addition to G0's `ReadAloud.SystemVoice`, with its fake in tests). G0's files are the
   lead's: phase B's first brief asks for it.

### 4.8 The order of work (one agent, four briefs; the lead checks between)

1. **The spells work** (sessions 1-2): `SpellLexicon`, `SpellCard`, `SpellReader`, `SpellMeaning`, `SpellJudge`,
   `WishBook`, `SpellSolver`, `WishBeats`, `WordLights`, the data, `WordMagicProgress`, the bots as tests (the models'
   thresholds); then the places (`TowerKit`, `TowerRoom`, `GreatBook` with its bloom, `SpellRibbon`, `WordCard`,
   `ValleyCreature` with its actions) and their pictures in a real window; the draws counted (the text first).
2. **The tower opens** (sessions 3-4): `WordMagicHost` flat (the fan, the ribbon, the star, the voice and the highlight,
   the ink, outlines, copies and the Jumble, the demonstrations, the record, the end card, DISCOVER's and the door's
   hooks), then VR (the grip claimer, the wand, the ghost hands, comfort), the budget bench.
3. **The tower glows** (sessions 5-6): the dragons' page complete, the Parade, sounds and music, juice (the bloom, the
   ink, the Jumble, the dragons' breathing), the Spellbook, the full suite.
4. **The voice on devices** (session 7): word timing and the made-up words' pronunciations on the emulator and the
   Quest; fixes after the lead's device check and the owner's child's first play.

---

## 5. Phases and estimates

| Phase | What | Gate | Estimate |
|---|---|---|---|
| **A** (this) | research and design | the lead's review; the owner sees `word-magic-owner.md` | done |
| **B** | the First Page and the Sleepy Dragons, complete and beautiful, flat and VR | played on the emulator (≥ 30 FPS, no frame > 100 ms) and the Quest (≤ 100 draws, 72 Hz); the voice checked on both; the owner's child plays; the five tests checked honestly (the bots, a child who can't read plays by ear, the dragons solved unhelped, the child's choice, the owner's wow) | **7 agent sessions** (one agent; 6 if the leaf's B2 host hook has merged and another deep game has proved the host pattern; 6-9 with surprises, mostly the voice on devices) |
| **C1** | floors 3-4 at their minimum (16 pages: 3.2-3.8, 3.T2, 4.1-4.7, 4.T1), each with its wishes and events; 14 units to P1; runes, the time windows, chains, speech-bubble runes; the tower beside the Academy; stage 2 and the reading rooms; the School's written exercises as a before-and-after check | the full suite; the lead's device check; playtest data | about 16-20 agent sessions |
| **C2** | floors 5-8 (27 pages); 22 units to P1; the Word Forge, the Loom, the Spotlight, the Rule Stones | the same | about 22-28 agent sessions |
| **D** | grow: your own page for a friend (8.6), spells on signposts in the world, writing together online, the realistic twin, the open units if the lead adds them (3.9, 7.6) | voluntary time, returns, transfer in playtests | ongoing |

This is the largest strand of the four games so far (36 units against the bakery's 16 and the altar's 11): English's
language strand is a third of our English units, and it runs across all six grades.

---

## 6. Risks

| Risk | Why it matters | What we do |
|---|---|---|
| The literal world needs many things and actions | art and code scope; a spell the world can't show breaks the magic | each page's words are curated (8-16 nouns, 6-12 verbs); creatures from `Buddy`'s mesher; actions procedural; phase B's library about 16 things and 12 actions |
| The voice: text-to-speech mispronounces a made-up word, says a look-alike differently on some devices, or is missing | rule 0 leans on the voice harder here than in any game | stage 1 uses made-up words with clear spellings; stage 2's look-alikes checked per device; word-by-word reading; session 7 on the emulator and the Quest; without a voice, badges stay on and readers can still play (ruling 29); a recorded voice is the owner's later choice (open question 6) |
| The voice becomes a crutch: a child listens to every card for ever | the game would not carry them to reading | the Word Lights, stage 2, the reading rooms, more cards per hand (reading becomes faster than listening); never forced (a forced removal would leave a non-reader stuck) |
| Older children feel babied (by pictures, by the prologue) | choice | badges hidden by default from grade 5; "words only" at any time; badges drawn as ink sketches, not toddler pictures; the prologue is ten minutes |
| Native speakers find the meaning rooms easy (they already say "mice") | choice; nothing learned | short; floors by grade; the reading rooms and later floors are hard for anyone; the Jumble's humour |
| The fiction teaches something false (agreement "changing" meaning) | honesty | the honesty table; the see-why lines state the real rule ("on a verb, s means one"); the Book |
| The knowledge stays in the tower | transfer | transfer pages that are writing for someone; the Loom (sentence combining, the best-evidenced practice); phase C's before-and-after with the School's written exercises; signposts in the world (phase D) |
| Even grammar-in-context has mixed evidence (two null trials, §2.2) | our claims could be wrong | we measure transfer in play and on paper before claiming it; the design leans on sentence combining and on meaning, the parts with the better evidence |
| The Jumble's made-up words could prime wrong spellings (the child *sees* "mouses") | spelling | a made-up word is met only as a choice that fails at once; a granted wish always shows the right form last; made-up cards are a minority; open question 10 offers blots instead |
| British and American spelling | a look-alike must not depend on a spelling that differs | the lexicon uses words spelt the same in both where possible (the generators' rule) |
| Words that could be unkind or unsafe | a game that summons anything | curated words only; no typing; the lexicon reviewed |
| Text legibility in VR and on phones | a word you can't read can't be read | MSDF text, ≥ 3.5 cm letters in VR, ≥ 28 px on phones; a test |
| Not a phonics course | a non-decoder needs more than this | said plainly (ruling 3, open question 9) |
| Overlap with Story Theater, Poetry Music, Detective Reader, Persuade the Council | confusion, duplicated work | the split in §2.5 |
| Scope (36 units, about 45 pages) | a long tail | phases B, C1, C2; one place (the tower) re-dressed for every page |
| The registry and the menus' hooks; the voice's utterance id (G0's files) | without them DISCOVER can't open the tower and the highlight can't step | the lead's decision (§8); the leaf's B2 mechanism; a developer argument meanwhile |

---

## 7. Rulings (each with its cost if wrong)

1. **The core verb is writing a sentence that comes true, read literally by the Spell Reader.** *Cost:* a curated
   vocabulary and an animation library per page; sentences outside them can't be written.
2. **Cards, never typing; never a microphone.** *Cost:* no free composition (the child chooses among offered words);
   spelling from memory is not practised (stage 2 and the Spelling Forge judge spelling by recognition).
3. **Word Magic is not a phonics course.** *Cost:* a child who cannot decode at all is carried (the voice) but not taught
   to decode; the School has no grades below 3.
4. **A picture badge shows what a word is about, never its grammar.** *Cost:* a non-reader must listen for endings.
5. **Every card speaks on touch, for everyone, for ever.** *Cost:* a child could listen to every card for ever; the Word
   Lights and stage 2 are the only nudges.
6. **Only the first cast counts** (a second cast is HELPED). *Cost:* an explorer's second try isn't credited (the free
   spells and the taught wishes are free to explore).
7. **Nothing previews a spell.** *Cost:* no live feedback while building (the model: with a preview, trial and error
   wins every visit).
8. **Cards move freely until the cast.** *Cost:* none for the evidence.
9. **Every hand holds the tempting wrong card** (each habit's trap). *Cost:* the hands repeat their shapes (their words
   vary); the models: without it, habits reached 12-19 % in two rooms.
10. **The Jumble's made-up words are drawn exactly like real cards.** *Cost:* a child sees a misspelling now and then
    (open question 10).
11. **The First Page's composition** (§3.5's rules table: number and noun gaps, wild words, sheep, leaves, two wishes for
    one thing, a four-gap Parade). *Cost:* a busier first page than "just add an s"; the model: regular nouns only let
    three habits win every visit.
12. **The dragons' page links two or three decisions per wish and has two compound subjects.** *Cost:* longer spells for
    grade 3; the model: one verb a wish let a coin reach 11 %, one compound subject let "the nearest noun" pass 100 %.
13. **A verb's form decides how many act (a fiction).** *Cost:* English doesn't work that way (agreement is redundant);
    the honesty table and the see-why line say the real rule.
14. **A wish's line describes the situation and never says the wish's words.** *Cost:* a non-reader must look at the
    bubble, not only listen.
15. **The dragons' wishes are NEW_SETTING events for `g3.english.nouns_pronouns`** (open question 1). *Cost:*
    `verbs_tenses`' agreement gets no events until 3.3.
16. **Teaching wishes are not judged** (four on the First Page). *Cost:* 8 events a night, not 12.
17. **The Word Lights are the Keeper's journal, not `SkillShown` events.** *Cost:* reading growth gives no stars or gold
    (the grown-ups' page shows it in phase C).
18. **A word lights after three right unaided picks in a row in different wishes; a wrong one resets the count; two wrong
    of the last three put its badge back.** *Cost:* about 7 % of a guesser's words lose their badge at any time (it
    touches them instead); a reader waits about two sessions for most badges to go.
19. **Grades 3-4 start with badges on; grades 5-8 with badges hidden (shown on a card touched twice in a row); "words
    only" at any time.** *Cost:* an older non-reader must touch a card twice before its badge helps.
20. **Stage 2 opens on a floor at 20 lit words, and with it the reading rooms.** *Cost:* a child who doesn't read yet
    never meets them, so the homophone and spelling units stay unmastered until they do.
21. **The First Page and the Sleepy Dragons are everyone's first pages; then the grade picks the floor.** *Cost:* an
    older child spends ten minutes on grade 3 ideas once.
22. **The tower is a place of its own in phase B; phase C builds it beside the Academy, its door replacing the English
    gate.** *Cost:* phase B's tower isn't seen from the world.
23. **One main unit per room** (the transfer pages: NEW_SETTING for their floor's unit). *Cost:* a page that touches two
    units' ideas counts for one.
24. **The English door opens the deep game of the child's current English unit; while the reading units have no game,
    it opens Word Magic at the child's floor** (open question 3). *Cost:* the School's order across reading and language
    units is not followed.
25. **A card speaks when touched, not when shown; Hoot reads a spell after it is cast, never before.** *Cost:* a
    non-reader touches more (that is the self-teaching moment, [R5]).
26. **A cast is read word by word with each word lighting; one utterance per word first, the engine's word boundaries
    only where measured.** *Cost:* word-by-word speech sounds a little less natural.
27. **The parts' names come only after use** ("Grown-ups call these nouns"). *Cost:* a child who wants the words
    early opens the Book.
28. **Only curated words; no money, no shop, no random rewards.** *Cost:* no free summoning of anything.
29. **Without a voice, every badge stays on and the grown-ups' page says so; the tower is fully playable only by
    readers.** *Cost:* a non-reader on a device without English speech can't play it fully (G0's ruling 28's cost).
30. **In VR the cards are held and slotted, and the star is touched with the child's own Magic Wand; one-handed play
    stays possible.** *Cost:* the wand must be in the child's inventory or given at the lectern.
31. **Music from the repo's public-domain and CC0 recordings** (the *Goldberg Aria*, *Figaro*'s overture, *Gymnopédie No.
    1*, *Symphony No. 40*, *Flight of the Bumblebee*, *Morning Mood*). *Cost:* none.
32. **The models' rules are phase B's starting rules** (`model/spell_rules.py`, `first_page_model.py`,
    `sleepy_dragons_model.py`, `word_lights_model.py`), and the bots become tests. *Cost:* a little test time.
33. **No real names in the game** (the studies and apps stay in this document). *Cost:* none.
34. **The tower's state is a device file in phase B**, the profile in phase C (merged so nothing is lost). *Cost:* a new
    device starts with a pencil valley in phase B.
35. **Figurative language, context clues, reading and writing whole texts, and speaking belong to the other games**
    (§2.5); the literal pond is a joke, not a lesson. *Cost:* four of our English units' neighbours wait for other games.
36. **Phase B ships the First Page and the Sleepy Dragons**, so the gate can check all five tests. *Cost:* pronouns,
    time and the runes wait for phase C.
37. **Words spelt the same in British and American English where possible** (the generators' rule). *Cost:* a few
    favourite words are left out.

---

## 8. Open questions for the lead

1. **The dragons' events**: NEW_SETTING for `g3.english.nouns_pronouns` (my proposal: number tested where the plural
   habit fails, one main unit per room, as the bakery's Midnight), or SOLVED events for `g3.english.verbs_tenses` (a
   first round of agreement, L.3.1f)?
2. **`g3.english.word_meanings`**: does Word Magic take it (the Strength Dial: shades of meaning and the literal pond,
   plus a "mystery word" page for sentence-level context clues), or do context clues go to Detective Reader with the unit
   P0 until both exist (my proposal; the Strength Dial ships anyway for its shades)?
3. **The English door**: Word Magic at the child's floor whenever their current English unit has no deep game (my
   proposal), or strictly the School's order (G0's round or "coming soon" for reading units)?
4. **Where the tower lives in phase C**: a building beside the Academy whose door replaces the English gate (my
   proposal), or a room behind the gate?
5. **The registry hook**: adopted from the leaf's B2 (as decided for the altar and the bakery)?
6. **A recorded voice**: Word Magic leans on the voice harder than any game. The system's voice for phase B (my
   proposal, checked on devices in session 7), or plan a recorded voice (the owner's decision; it must be CC0: the
   owner's own recordings released as CC0, or a generated voice)?
7. **The reading track's numbers**: stage 2 at 20 lit words, three in a row to light a word: accept the model's choice,
   or tune after the owner's child plays (my proposal: accept now, tune then)?
8. **Badges by grade** (on for grades 3-4; hidden for 5-8 until a card is touched twice): accept?
9. **A phonics game** for children who cannot decode: out of Word Magic's scope (my proposal: note it in the forever
   roadmap as a future lesson for the youngest, below our grade 3), or a pre-floor of Word Magic?
10. **The Jumble's made-up words on screen**: drawn like real cards (my proposal: met only as choices that fail at
    once, the right form always shown last), or made-up cards that speak their word but show an ink blot instead of
    letters?
11. **When phase B starts** relative to the leaf's B2-B3, the altar's B and the bakery's B (the cap of three agents).
12. **The grown-ups' page** (phase C): the Keeper's journal in plain words ("Reads 34 of the tower's words on their own;
    cast 'mouses' once, never since")?
13. **A reading font**: the engine's default for phase B; in phase C an original font with a single-storey a and g drawn
    by a tool (CC0 by construction), friendlier for beginning readers?

---

## 9. The honesty table: what is real English, what is simplified, what is magic

| In the game | Real? | Note |
|---|---|---|
| A noun's ending says how many (fox, foxes; -es, -ies, -ves) | real | plural morphology (L.3.1b) |
| Wild words (mice, geese, children) and words that stay the same (sheep) | real | irregular plurals |
| The Jumble's made-up words (mouses, sheeps, runned) | real errors, magic result | the forms are children's classic over-regular forms; the Jumble is the game's |
| A number word and a noun that disagree bring outlines | **magic** | in English "five duck" is simply wrong; the outlines make the disagreement visible |
| A verb's -s means exactly one acts; the plain verb means all of them act (ink copies) | **fiction** | real agreement is redundant: "the dogs barks" means what "the dogs bark" means and is wrong; the game shows the disagreement as a different event; the see-why says the real rule |
| "It" grabs the nearest single thing (the log sings) | simplified | real readers resolve pronouns by meaning and context, not only nearness; an unclear pronoun really is unclear |
| The tense frames (an old photo, now, a dotted plan) | real idea, magic look | tense places an event in time |
| Speech marks make words said, not done | real | quoted words are reported, not asserted |
| A comma before a name speaks to them; a missing list comma fuses two things | real | the classic examples ("Let's eat, Grandma!"); a list without commas really is ambiguous |
| A comma between a subject and its verb cuts the verb loose | **magic** | in English it is a punctuation error, not a change of meaning |
| "That" picks some; "which" with commas means all | real | restrictive and non-restrictive clauses |
| A describing phrase sticks to the noun beside it (the school's tail) | real tendency, taken literally | readers lean to the nearest noun; real readers are usually rescued by sense; the valley isn't |
| Adjective order; commas between equal adjectives | convention | the charms fall off in the wrong order; the meaning doesn't change in English |
| Prefix and suffix runes change what a word does | real | morphology (un-, re-, dis-, -ful, -less) |
| Roots forge gadgets | real meanings, magic look | Greek and Latin roots |
| Homophones' meanings (their, there, they're) | real | the spelling carries the meaning |
| The passive's spotlight; hiding the doer | real idea | the passive puts the receiver first and can leave out the doer |
| An if-spell carves a rule stone that waits | simplified | "if" states a condition; the stone is a picture of it |
| Shades of meaning set strength; connotation sets feeling | real, simplified | real connotation depends on context too |
| The Great Book makes sentences come true; the buddies, Hoot, the Jumble, the dragons | **fiction** | EasyCraft's world |

---

## 10. Sources

Learning-is-play's sources (`docs/design/learning-is-play.md` §10, cited here as LP [G3], [G4], [G7], [G8], [G9]) and
Fraction Bakery's ([F24]: Durkin & Rittle-Johnson 2012, incorrect examples) are used as they are. New here (reading the
web only; nothing was downloaded, and no file was saved by the fetch tool: `docs/devlog/parts/game-words-a.md` says
which figures are second-hand or self-reported):

**Grammar and writing**
- [W1] Graham, S., & Perin, D. (2007). *Writing Next: Effective strategies to improve writing of adolescents in middle
  and high schools*. Alliance for Excellent Education (the meta-analysis also in *Journal of Educational Psychology*,
  99(3), 445-476). The grammar and sentence-combining figures as recorded from Graham's talk:
  https://hickstro.org/notes-from-steve-grahams-evidence-based-practice-in-writing/ ; a summary:
  https://www.adlit.org/topics/writing/summary-writing-next
- [W2] Graham, S., McKeown, D., Kiuhara, S., & Harris, K. R. (2012). A meta-analysis of writing instruction for students
  in the elementary grades. *Journal of Educational Psychology*, 104(4), 879-896. https://doi.org/10.1037/a0029185 (the
  grammar figure as reported in a summary table: https://texasldcenter.org/?p=311)
- [W3] Andrews, R., Torgerson, C., Beverton, S., Freeman, A., Locke, T., Low, G., Robinson, A., & Zhu, D. (2006). The
  effect of grammar teaching on writing development. *British Educational Research Journal*, 32(1), 39-55.
  https://doi.org/10.1080/01411920500401997 ; https://eprints.whiterose.ac.uk/5733
- [W4] Myhill, D., Jones, S., Lines, H., & Watson, A. (2012). Re-thinking grammar: the impact of embedded grammar teaching
  on students' writing and students' metalinguistic understanding. *Research Papers in Education*.
  https://ore.exeter.ac.uk/repository/handle/10036/4479 ; the teachers' summary (20 % against 11 %):
  https://education.exeter.ac.uk/v8media/facultysites/hass/docs/Research_Summary_for_Teachers.pdf ; Jones, Myhill &
  Bailey (2013), *Reading and Writing* (the 0.21 effect, as reported)
- [W5] Torgerson, D., Torgerson, C., Mitchell, N., Buckley, H., Ainsworth, H., Heaps, C., & Jefferson, L. (2014). *Grammar
  for Writing: Evaluation report and executive summary*. Education Endowment Foundation.
  https://educationendowmentfoundation.org.uk/projects-and-evaluation/projects/grammar-for-writing ; the second trial:
  https://educationendowmentfoundation.org.uk/projects-and-evaluation/projects/grammar-for-writing-effectiveness-trial/
- [W6] Wyse, D., Aarts, B., Anders, J., De Gennaro, A., Dockrell, J., Manyukhina, Y., Sing, S., & Torgerson, C. Teaching
  grammar and writing: a randomised controlled trial and implementation process evaluation of Englicious. *Journal of
  Writing Research*. https://www.jowr.org/jowr/article/view/1346 ;
  https://www.ucl.ac.uk/news/2022/mar/what-extent-does-grammar-teaching-help-children-learn-write
- [W7] Saddler, B., & Graham, S. (2005). The effects of peer-assisted sentence-combining instruction on the writing
  performance of more and less skilled young writers. *Journal of Educational Psychology*, 97(1), 43-54; the What Works
  Clearinghouse's review: https://ies.ed.gov/ncee/WWC/Study/74410
- [W8] Graham, S., et al. (2012). *Teaching elementary school students to be effective writers* (IES practice guide,
  NCEE 2012-4058). https://www.readingrockets.org/article/teaching-elementary-school-students-be-effective-writers
- [W9] Myhill, D., and the University of Exeter's Grammar as Choice pedagogy:
  https://www.exeter.ac.uk/research/centres/languageandliteracy/grammar-teacher-resources/grammaraschoice/thegrammarforwritingpedagogy/
- [W10] Hunt, K. W. (1965). *Grammatical structures written at three grade levels* (NCTE Research Report No. 3); the
  T-unit: https://en.wikipedia.org/wiki/T-unit

**Reading**
- [R1] Gough, P. B., & Tunmer, W. E. (1986). Decoding, reading, and reading disability. *Remedial and Special
  Education*, 7, 6-10. https://en.wikipedia.org/wiki/Simple_view_of_reading
- [R2] Ehri, L. C., Nunes, S. R., Stahl, S. A., & Willows, D. M. (2001). Systematic phonics instruction helps students
  learn to read. *Review of Educational Research*, 71, 393-447 (the grade figures as reported:
  https://www.ldaustralia.org/app/uploads/2022/09/Buckingham-Evidence-strongly-favours-systematic-synthetic-phonics.pdf ;
  a reanalysis: https://texasldcenter.org/wp-content/uploads/2008/11/jep08-stuebingetal.pdf)
- [R3] Foorman, B., et al. (2016). *Foundational skills to support reading for understanding in kindergarten through 3rd
  grade* (IES practice guide). https://ies.ed.gov/ncee/wwc/Docs/PracticeGuide/wwc_foundationalreading_070516.epub
- [R4] Ehri, L. C. (2014). Orthographic mapping in the acquisition of sight word reading, spelling memory, and vocabulary
  learning. *Scientific Studies of Reading*, 18(1), 5-21. https://doi.org/10.1080/10888438.2013.819356
- [R5] Share, D. L. (1995). Phonological recoding and self-teaching: sine qua non of reading acquisition. *Cognition*, 55,
  151-218. https://pubmed.ncbi.nlm.nih.gov/7789090/ ; Share, D. L. (1999). Phonological recoding and orthographic
  learning: a direct test of the self-teaching hypothesis. *Journal of Experimental Child Psychology*, 72, 95-129.
- [R6] Castles, A., Rastle, K., & Nation, K. (2018). Ending the reading wars: reading acquisition from novice to expert.
  *Psychological Science in the Public Interest*, 19(1), 5-51.
  https://www.psychologicalscience.org/publications/ending-the-reading-wars-reading-acquisition-from-novice-to-expert.html
- [R7] Olson, R. K., & Wise, B. W. (1992). Reading on the computer with orthographic and speech feedback. *Reading and
  Writing*, 4(2), 107-144. https://experts.colorado.edu/display/pubid_85886
- [R8] van Daal, V. H. P., & Reitsma, P. (1993). The use of speech feedback by normal and disabled readers in
  computer-based reading practice. *Reading and Writing*.
  https://research.edgehill.ac.uk/en/publications/the-use-of-speech-feedback-by-normal-and-disabled-readers-in-comp-2/
- [R9] Samuels, S. J. (1967). Attentional process in reading: the effect of pictures on the acquisition of reading
  responses. *Journal of Educational Psychology*, 58, 337-342 (as cited; disputed by Arlin, Scott & Webster, *Reading
  Research Quarterly*, 1978-79).
- [R10] Didden, R., Prinsen, H., & Sigafoos, J. (2000). The blocking effect of pictorial prompts on sight-word reading.
  *Journal of Applied Behavior Analysis*, 33.
  https://figshare.utas.edu.au/articles/journal_contribution/The_blocking_effect_of_pictorial_prompts_on_sight-word_reading/22853168 ;
  Solman's review, "Teaching sight-words": https://d7.nzcer.org.nz/node/47378
- [R11] Evans, M. A., & Saint-Aubin, J. (2005). What children are looking at during shared storybook reading.
  *Psychological Science*, 16(11), 913-920. https://experts.mcmaster.ca/scholarly-works/338682 ;
  https://www.uoguelph.ca/mediarel/2005/11/kids_not_lookin.html
- [R12] Justice, L. M., Skibbe, L., Canning, A., & Lankford, C. (2005). Pre-schoolers, print and storybooks: an
  observational study using eye movement analysis. *Journal of Research in Reading*, 28(3), 229-243.
- [R13] Liao et al. (2020). Electronic storybook design, kindergartners' visual attention, and print awareness: an
  eye-tracking investigation. *Computers & Education*.
  https://scholar.lib.ntnu.edu.tw/en/publications/electronic-storybook-design-kindergartners-visual-attention-and-p-2/
- [R14] Bowers, P. N., Kirby, J. R., & Deacon, S. H. (2010). The effects of morphological instruction on literacy skills: a
  systematic review of the literature. *Review of Educational Research*, 80(2). https://doi.org/10.3102/0034654309359353
- [R15] Wood, S. G., Moxley, J. H., Tighe, E. L., & Wagner, R. K. (2018). Does use of text-to-speech and related read-aloud
  tools improve reading comprehension for students with reading disabilities? A meta-analysis. *Journal of Learning
  Disabilities*, 51(1), 73-84. https://pmc.ncbi.nlm.nih.gov/articles/PMC5494021/
- [R16] White, T. G., Sowell, J., & Yanagihara, A. (1989). Teaching elementary students to use word-part clues. *The
  Reading Teacher*, 42 (the percentages as quoted by Marzano:
  https://www.vocabulary.com/articles/booknook/teaching-word-parts-to-enhance-student-understanding/)
- [R17] Takacs, Z. K., Swart, E. K., & Bus, A. G. (2015). Benefits and pitfalls of multimedia and interactive features in
  technology-enhanced storybooks: a meta-analysis. *Review of Educational Research*, 85(4), 698-739.
  https://doi.org/10.3102/0034654314566989
- [R18] Goodwin, A. P., & Ahn, S. (2010). A meta-analysis of morphological interventions: effects on literacy achievement
  of children with literacy difficulties. *Annals of Dyslexia*; (2013). A meta-analysis of morphological interventions in
  English. *Scientific Studies of Reading*, 17, 257-285 (their effect sizes as reported, not read)
- [R19] Nagy, W. E., & Anderson, R. C. (1984). How many words are there in printed school English? *Reading Research
  Quarterly*. https://www.proquest.com/docview/63450364
- [R20] Stanovich, K. E. (1986). Matthew effects in reading. *Reading Research Quarterly*, 22, 360-407.
  https://www.readingrockets.org/resources/resource-library/matthew-effects-reading-some-consequences-individual-differences
- [R21] Baker, S., et al. (2014). *Teaching academic content and literacy to English learners in elementary and middle
  school* (IES practice guide, NCEE 2014-4012). https://texasldcenter.org/?p=1784

**Language development and errors**
- [E1] Brown, R. (1973). *A first language: the early stages*. Harvard University Press (the study as described:
  https://en.wikipedia.org/wiki/Order_of_acquisition ; the plural's and the third-person -s's ranks as commonly
  reproduced, not checked in the book)
- [E2] Marcus, G. F., Pinker, S., Ullman, M., Hollander, M., Rosen, T. J., & Xu, F. (1992). Overregularization in language
  acquisition. *Monographs of the Society for Research in Child Development*, 57(4).
  https://stevenpinker.com/publications/year/1992 ; https://apps.dtic.mil/sti/tr/pdf/ADA356731.pdf
- [E3] Bever, T. G. (1970). The cognitive basis for linguistic structures (as reported in later work); Lempert, H., &
  Kinsbourne, M. (1975), *Journal of Child Language*; a review of the word-order strategy:
  https://www.cambridge.org/core/journals/journal-of-child-language/article/preschool-childrens-sentence-comprehension-strategies-with-respect-to-word-order/1BCBEAC2F5748629E726CC3E7D35A498
- [E4] Kress, G. (1994). *Learning to write* (2nd ed.). Routledge.
  https://www.routledge.com/Learning-to-Write/Kress/p/book/9780415072410
- [E5] Connors, R. J., & Lunsford, A. A. (1988). Frequency of formal errors in current college writing. *College
  Composition and Communication*, 39, 395-409 (as reviewed by Otte: https://innovationtest1.colostate.edu/jbw/v10n2/otte.pdf ;
  a top-twenty list attributed to their 1993 data: https://www.iwu.edu/writing/faculty/20-most-common-errors.doc)
- [E6] Lunsford, A. A., & Lunsford, K. J. (2008). "Mistakes are a fact of life": a national comparative study. *College
  Composition and Communication*, 59(4).
  https://digfir-published.macmillanusa.com/wh_lunsford/asset/pdfs/01_Luns_Annos_lr_1-27.pdf ;
  https://teachingandlearninginhighered.org/2013/04/08/the-grammar-apocalypse/

**Games and apps**
- [A1] Scribblenauts (5th Cell): https://www.commonsense.org/education/reviews/scribblenauts-unlimited ;
  https://www.gamepeople.co.uk/teaching_ds_superscribblenauts.htm ; a doctoral study (Drexel, 2020):
  https://researchdiscovery.drexel.edu/esploro/outputs/doctoral/991014632330604721
- [A2] Baba Is You (Hempuli, 2019): https://thinkygames.com/games/baba-is-you/ ; Campos (2020), *Loading*:
  https://loading.journals.publicknowledgeproject.org/index.php/loading/article/download/363/321/2425
- [A3] GraphoGame: McTigue, E. M., Solheim, O. J., Zimmer, W. K., & Uppstad, P. H. (2020). Critically reviewing GraphoGame
  across the world. *Reading Research Quarterly*, 55(1), 45-; the developer's account of it (promotional):
  https://group.graphogame.com/?p=185
- [A4] Lexia Core5, the EEF's trial: https://educationendowmentfoundation.org.uk/projects-and-evaluation/projects/lexia ;
  https://www.lexialearning.com/resources/research/an-independent-study-of-lexia-core5-reading-funded-by-the-education-endowment-foundation
- [A5] Teach Your Monster to Read (a school's testimonial on the developer's site): https://www.teachyourmonster.org/?p=1281
- [A6] Duolingo ABC (sponsored content reporting the company-funded study):
  https://www.smartbrief.com/original/strengthen-early-literacy-skills-with-duolingo-abc
- [A7] NoRedInk: https://noredink.com/about/casestudies/map ;
  https://www.edsurge.com/n/2015-07-07-noredink-partners-with-nwea-to-give-students-better-feedback-on-writing-and-grammar
- [A8] Montessori grammar symbols: https://www.montessoriservices.com/the-land-of-the-parts-of-speech
- [A9] Cheung, A. C. K., & Slavin, R. E. (2012). The effects of educational technology applications on reading outcomes
  (Best Evidence Encyclopedia): https://bestevidence.org/wp-content/uploads/2021/02/tech_read_april_25_2012.doc
- [A10] Tsai, Y.-L., & Tsai, C.-C. (2018). Digital game-based second-language vocabulary learning and conditions of
  research designs: a meta-analysis study. *Computers & Education*, 125.
  https://scholar.lib.ntnu.edu.tw/en/publications/digital-game-based-second-language-vocabulary-learning-and-condit-2/

**The standards and the engine**
- [S1]-[S6] Common Core English Language Arts, Language, grades 3-8: https://www.thecorestandards.org/ELA-Literacy/L/3/
  (and /L/4/ … /L/8/); RF.3.3: https://www.thecorestandards.org/ELA-Literacy/RF/3/
- [T1] Godot's `DisplayServer` text-to-speech (`tts_speak`, `tts_set_utterance_callback`, `TTS_UTTERANCE_BOUNDARY`):
  https://docs.godotengine.org/en/stable/classes/class_displayserver.html

## The lead's review (2026-10-18 08:20): phase A passes; the open questions decided
**Verdict: approved for phase B.** The verb ("write it true": the valley does exactly what the sentence says, not what
the child meant) makes grammar something that happens, with the wrong word's result funny and visible, never a red
cross; the non-reader plays by ear from minute one (every card speaks, Hoot reads each cast word by word, pictures that
show the thing but never the grammar), and the reading track (a word turns gold after three right picks without
touching it, in different wishes) moves a child from listening to reading without ever taking the voice away; it never
asks for the name of a part of speech, as the writing research advises. The models changed the design (irregular
words and number and noun gaps in every wish; two or three linked choices per dragons' wish and two compound subjects;
the word lights' rule; the tempting card in every hand). The research's second-hand and vendor figures are marked. The
owner sees `word-magic-owner.md` and can stop or change it at any point.
1. **The dragons' events:** NEW_SETTING evidence for `g3.english.nouns_pronouns` (as the altar's and the bakery's).
2. **`g3.english.word_meanings`:** context clues go to Detective Reader; the unit stays P0 until both exist; the Strength
   Dial ships for shades of meaning.
3. **The English door:** Word Magic at the child's floor whenever their current English unit has no deep game.
4. **Where it lives:** the Word Tower beside the Academy; its door replaces the English gate (W1 already names it so).
5. **The registry:** adopted from Inside a Leaf's B2.
6. **The voice:** the system's text-to-speech for phase B, checked on the devices in its last session; a recorded voice
   stays the owner's later decision (CC0 only: the owner's own recordings released as CC0, or a generated voice).
7. **The reading track's numbers:** accepted now (20 lit words, three in a row); tuned after the owner's child plays.
8. **Badges by grade:** accepted.
9. **Phonics:** out of Word Magic's scope; a future lesson for the youngest goes into the forever roadmap.
10. **The Jumble's made-up words, changed from the proposal:** seeing a misspelling can make people more likely to
    spell the word that way later (the exposure effect in spelling research), so **while the child is listening (stage
    1), a made-up card speaks its word but shows an ink blot instead of letters**; spelling traps written in letters
    ("ponys") appear only in the reading rooms, where spelling is the skill, always as a choice that fails at once, its
    card fading as the right form is shown last and read aloud. Cost: stage 1's made-up cards are heard, not seen; the
    model's numbers hold, since those players decide by ear.
11. **When:** phase B after Balance Altar's and Fraction Bakery's (the queue: the leaf's B2-B3, the altar's B, the
    bakery's B, Word Magic's B), one game agent beside the leaf's while the rooms' look runs, two once it has finished.
12. **The grown-ups' page:** phase C, the Keeper's journal in plain words.
13. **The reading font:** the engine's default for phase B; an original font drawn by a tool (CC0 by construction) in
    phase C.
