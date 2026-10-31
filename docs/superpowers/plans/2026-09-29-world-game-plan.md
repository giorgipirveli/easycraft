# The world game: invite, involve, everyone — THE MOST IMPORTANT PLAN (owner #79, #81; 2026-09-29)

The owner (#81): "implement into plan referal program, find out a ways how we can invite into game more people, how to
motivate them involve more, how can we make this game world game, game for every age, every child and everyone. this
is the most important plan" — and: "find a ways what can be motivations for children, psychological motivations to
bring more people. remember this is educational game not just random game like roblox".

**The goal (owner #82):** "we must bring more childrens here because they will become educated, we dont care about
money … our goal is child education. i want to educate my child and all childrens, so bring referal programs which
include all possible motications". Every child who joins is a child who learns: the referral program uses **every**
motivation below, and the game tells children the truth: **bringing a friend brings a friend to school.**

**The principle:** a child brings friends because the game is **better together and learning is better together**,
not because we pay them to spam. Every invite reward is tied to **learning** (the friend learns, both win), every
social feature makes the child **prouder, kinder and smarter**, and nothing uses pressure, fear of missing out or
public ranking of children. The core loop (roadmap §0, spec §25) is the engine: **learn → earn gold → build the rocket →
fly** — and the rocket, the colonies, the wonders and the quests are all **bigger with friends**.

## 1. Why a child invites a friend (the motivations we build on)
| Motivation (psychology) | What it looks like in EasyCraft |
|---|---|
| **Belonging** (relatedness: children want a crew, a club, a class) | **Crews**: a crew of 2-6 explorers with a crew name, a crew badge and a crew rocket. Mars needs a crew: a Mars rocket has 3 seats and the Mars mission gives more with a full crew (spec §21d). |
| **Teaching a friend** (the protégé effect: children love to teach, and teaching makes them learn better) | **Mentor**: the child who invited a friend becomes their guide: "Show Sam how to build a rocket!" When the friend masters their first lesson, both get gold, and the mentor gets a **Mentor star** (and later **Mentor of 5, of 10** titles: a teacher's badge, not a salesman's). The friend's first missions show "Your guide ALEX flew this one: ask them!" |
| **Pride and showing** (competence; the peak moments) | **Postcards**: at a peak (landing on the Moon, finding gold, mastering a grade, a wonder stamped) the game makes a picture postcard ("I landed on the Moon!") with the invite code on it, to share. Shared at a proud moment, never asked for at a random one. |
| **Giving** (the warm glow; reciprocity) | **Gifts**: send a friend a present they can only open in the game (a rocket part, seeds for the dome garden, a buddy egg, a map piece of a gold quest). The friend joins to open it and can send one back. |
| **Doing big things together** (shared goals, cooperation) | **Two-key secrets and co-op quests**: some treasures, doors and quest steps need two explorers (two levers, two answers, one on each side of a canyon); a crew's quests pay more per head; **crew missions** (fly the crew rocket together, spec §21d.6 phase 2). |
| **Curiosity** (a mystery that needs someone else) | **Split maps**: a prospecting quest's map (spec §26) sometimes comes in two halves: one for you, one to give; together they show the deposit. |
| **Fairness and recognition** (being seen) | A crew's wall in the colony dome with each member's avatar and what they learned ("Mia mastered Fractions"); personal bests and the crew's total, never a public ranking of children by invites. |
| **Identity and story** (I am an explorer) | Titles earned by learning and helping: Cadet → Explorer → Mission Specialist → Commander → Mentor. A crew Commander is the one who helped others most, not who paid most. |

**More motivations, all of them used (owner #82):**
| Motivation | In EasyCraft |
|---|---|
| **Purpose** (helping others learn) | "Bring a friend to school!": the invite page says what the friend will learn; the child's own count of **friends they brought to learning** and the world's count ("children brought by children: 12,345") |
| **Both win** (double-sided rewards) | The friend's welcome gift and the inviter's gold, both tied to the friend's learning |
| **Collecting** (completion) | **Friend cards** in the Explorer Album: each friend who learned is a card (their avatar, their first planet); a page to fill |
| **Almost there** (the goal gradient) | "Your crew: 3 of 6 seats filled", "2 more friends to the Golden Rocket paint" |
| **Surprise** (variable, always good, never paid) | A mystery gift box when a friend lands on the Moon (always something good; never a paid box, never gambling) |
| **Team competition** (friendly) | Crew against crew, class against class: weekly learning races (units mastered together); never child against child |
| **Status and roles** | Titles: Mentor, Ambassador (for children who brought 10 learners), crew Commander; an Ambassador can start a **club** |
| **Encouragement** (kindness loops) | "Sam just landed on the Moon: send a cheer!"; "Sam is stuck on Fractions: play it together?" (peer tutoring: the mentor joins the same exercise) |
| **Credit for creating** | Rocket designs shared with the maker's name: "Your Moon rocket flew 5 times!" |
| **Visits** | Invite a friend into your world to see your Moon base (showcase visits, M4) |
| **Thank you** (reciprocity) | The friend's THANK YOU sends a small gift back to the mentor |
| **Special days** | "Bring a friend week" in World Space Week and at the start of the school year: double rewards |
| **Grown-ups who care** | Parents see what the child learned and share with other parents (a parent's invite, from the grown-ups' area); teachers' class codes; printable **Explorer certificates** for fridges and classrooms |

## 2. The referral program (built by the earn-invite agent; spec §25.2)
- **Invite code and link** for every player (kid-safe words + a number); SHARE / COPY / a QR code the game draws; the web
  link `…/play/?invite=CODE`, the Play Store link with the referrer, a code typed at the start or in SETTINGS.
- **Rewards tied to learning** (never to a bare sign-up): the new friend gets a **welcome gift** at once (gold and a
  starter rocket part); the inviter gets gold **when the friend masters their first School unit** (or plays on two
  different days), then a bonus when the friend lands on the Moon. Both get the **Crew badge** when they fly together.
- **Milestones** for inviters (1, 3, 5, 10 friends who learned): a Mentor star, a crew banner, a dome decoration, a rocket
  paint — things to show, never power that makes others weaker.
- **Class codes and family codes**: a teacher's class code (the whole class joins one crew; a **class goal**: "when
  everyone in the class masters 3 units, the class rocket flies to the Moon"); a family code (brothers, sisters, parents
  and grandparents in one family crew).
- **Safe by design**: the invite carries no personal data (only the code); the game never reads contacts, never asks
  for a friend's name, email or number; a friend's name shows only as their in-game name; the server checks everything
  (new accounts only, never your own device, a monthly cap, rewards once); a grown-ups' line on the page ("Invite links
  carry no personal information") and a parent-assisted way (share from the grown-ups' area). The legal note for the
  owner's lawyer (Google Play's Families policy, COPPA's rules on sharing features: no personal information shared) is
  in `docs/store/`.
- **No pressure**: no timers, no "invite or lose", no streak punishments, no leaderboard of invites, no rewards for
  inviting that a child who has no one to invite would miss in learning; the whole game stays fully playable alone.

## 2b. What the most successful referral programs do, and our educational version (owner #85, 2026-09-29)
The owner: "research how financial pyramids work but of course not for this reason, only for good reason … how to
bring more people into this wonderful educational game. we dont plan any financial gains here … i just want more kind
for the whole world and for my boy which is now 4th grade. research the ways best refereal and successfull referal
programs works". Sources: the Dropbox, Wordle and Morning Brew case studies and the K-factor guides listed below.

| What worked | Where | Our version |
|---|---|---|
| **Both sides win something that makes the product better** (not cash): +500 MB for both, the program in onboarding and at the moment of need; 100,000 → 4 million users in 15 months, referrals beat paid ads 2.8× | Dropbox | Gold for both, which buys what the game is about: rocket parts, Explorer lessons (§2); INVITE shown at the moments of need ("2 more rocket parts to Mars: a friend's welcome brings gold to you both") |
| **Something to share that shows pride without spoiling, and one puzzle for everyone each day** (the coloured grid, no letters: "did you do today's?"); 90 → 3 million players in two months, no ads | Wordle | **The Daily Mission**: the same short challenge for every player each day (a School question set, a map puzzle, a rocket problem); a **result card** (stars and a picture, no answers, the invite link) to share; the same mission the next day for everyone, so every card starts a conversation |
| **Milestone tiers**: small rewards early, bigger ones later, all visible; super-advocates carry it | Morning Brew | **Explorer ranks** for friends who learned: 1 → a crew badge, 3 → a rocket paint, 5 → a buddy, 10 → Ambassador and a club, 25 → a named star on the Star Map, 50 → a statue in the colony dome, 100 → a wonder named after your crew in the Wonders world (things to show, none that make others weaker) |
| **A tree that grows** (multi-level: credit reaches the people who brought the people; this is what makes pyramid schemes spread, and what harms people in them is money in, money up, and those at the bottom losing) | network growth, used for good | **The Explorer Tree**: your friends are your tree's branches, their friends its leaves; every learner in your tree makes it grow on your page ("Your tree: 23 children learning"); a small gold gift when a friend's friend learns (two levels, capped). **No money in, nothing taken from anyone** (the gold is the game's), nobody loses, nobody is asked to recruit, and every leaf is a child learning |
| **The viral number K** = invites per player × the share who join; above 1 the game grows by itself | K-factor guides | We measure it privately (no child's name): invites sent, friends who joined, friends who learned; the aim is K ≥ 0.5 among families and classes, above 1 with the Daily Mission cards and class codes |
| **Every shared thing carries the way in** (the first free email's signature line) | Hotmail | Postcards, Daily Mission cards, rocket designs, showcases, the Wonders Passport's pages: each with the invite link |
| **Friendship levels and daily gifts** (good, great, best friends: gifts and playing together raise them) | Pokémon GO | **Friendship levels**: learning together, gifts and cheers raise them; each level opens a shared reward (a two-seat rover, a shared dome room) |
| **Shared streaks** (friends who share one are far likelier to learn every day) | Duolingo | **Study buddies**: a shared daily goal with one friend that forgives a missed day |
| **One code brings a whole room** (a game PIN on the board: 25 players at once) | classroom quiz games | **Class codes** (the teacher shows one code; the whole class joins one crew); **family codes** |

**Who shares:** children share inside the game (gifts, crews, cheers, class codes); **grown-ups** share outside it
(parents post the Daily Mission card or the week's learning card, teachers show the class code), because young children
have no social media and the link carries no personal data (§2).

## 2c. As built (2026-09-30; notes `docs/devlog/parts/daily-and-friends.md`; spec §25.7; server module 0.2.18)
- **The Daily Mission** (§2b Wordle): TODAY'S MISSION on the School's map, the same 5 questions for every child of a grade
  each UTC day, a star per first-try answer, 10 gold a star once a day, the result card (stars as pictures, the invite
  code and link, never an answer) with SHARE / COPY / SAVE PICTURE and the grown-ups' line, mission days that never go
  down and rest days. Other kinds of daily mission (a map puzzle, a rocket problem) are next.
- **Postcards** (§1 Pride): offered once at a unit or a grade mastered (built) and, through the `PostcardOffer` hook, at a
  first landing, a mission, a wonder's stamp, a deposit found (the lead wires them); the invite link on every one.
- **Gifts** (§1 Giving): a rocket part, seeds, a buddy egg, a treasure map piece; one a day to each friend; one waits on the
  invite code for a new friend; THANK YOU sends 10 gold back.
- **Friendship levels, cheers, study buddies** (§2b Pokémon GO, Duolingo): days together (learning the same day, presents,
  cheers) make Good, Great and Best friends (the two-seat rover and the dome room are hooks); kind-word cheers for
  friends' proud moments; study buddies whose days together never fall.
- **Crews** (§1 Belonging): 2-6 friends, a kid-safe name and a badge, each member's week (never a ranking), a weekly goal
  together. Next: the crew rocket and crew flights (§21d.6 phase 2), the crew wall in the dome, class crews from class
  codes, "Your guide ALEX flew this one", the Mentor's peer tutoring ("play it together?"), world events.

## 3. Staying involved (motivation to come back — the educational way)
- **The core loop's next goal is always visible**: the next lesson, the gold still needed for the next rocket part, the
  next planet on the Mission Board, the next wonder on the tour.
- **Daily learning goal** (small, gentle: "3 right answers today"), **weekly missions** (a quest, a lesson group, a
  build), **collections** (the Space Book, the Wonders Passport, the Animal Book, the rock and mineral collection from
  mining), **surprises** (secrets, a new planet card, a gift from a friend), **the buddy** who grows with the child.
- **Streaks that forgive** (a missed day is never a loss: a "rest day" is fine), rewards for learning, never for time.
- **World events** (educational, the same days everywhere): World Space Week (4-10 October: a space mission week),
  Earth Day (22 April: the wonders of nature and clean fuels), the day people first walked on the Moon (20 July),
  International Day of Education (24 January), the Science Lab's experiment week; each a shared goal of all players
  ("together we flew 1,000,000 km this week") shown without anyone's name.
- **Creating and sharing** (the proudest thing a child can show): builds, stamps, courses, showcases and bottle mail
  (M4) — now also rocket designs ("my Moon rocket: 3 stages") that friends can try on their pad.

## 4. A game for every age and everyone
| Who | What we give them |
|---|---|
| **3-6 (pre-readers)** | Everything read aloud, pictures before words, big buttons, **Little Explorer** lessons (counting, letters, colours, shapes, animals): the School's early years before grade 3 (roadmap §1: grades K-2 next). |
| **7-14** (the heart) | The School grades 3-8 in 12 subjects, the core loop, crews, missions, quests. |
| **14-18 (teens)** | The School grades 9-12 (algebra, physics, chemistry, biology, history), **Engineer mode** for rockets (real orbital numbers, staging design), text coding after block coding, leading a crew (Commander), creator tools and challenges. |
| **Parents and grandparents** | The family crew: play together (co-op on one world, simple controls), the grown-ups' page shows what the child learned this week, the same missions at a relaxing pace; learning for grown-ups too (space science, geology, history's wonders). |
| **Teachers and schools** | **Free for classrooms**: class codes, assign School units, see the class's progress, class goals and the class rocket; lessons that follow the curricula (the research maps them). |
| **Every child** | Free core forever (the School, the Moon mission, the colonies' first dome; Plus is only extra worlds, never learning); works on cheap phones and in any browser (no install), offline after the first download, small and fast; clear text, colour-blind-safe colours, one-hand and big-button controls; avatars for every child; a kind, safe community (chat by age, filters, reports). |

## 5. A world game
- **Reach**: the web version (a link is enough, any country, any device), Android, iPhone (M6); small downloads for
  slow internet; offline play.
- **Language**: the owner's standing rule is English only (2026-09-25: never a translation or a language picker). The
  game reaches the world with **pictures first, everything read aloud, simple English**; translations only if the
  owner decides so later.
- **The world inside the game**: the wonders of every continent (spec §24), real resources of every land (§26), world
  events on the same days, and the crews' shared goals (all players together).
- **Getting the word out** (the owner's and the lead's steps, no child involved): the Play Store listing and a short
  video of the Moon flight; teachers' and homeschool communities (a free classroom guide); family and education
  reviewers; a "Build a Moon base" challenge for classes; the postcards children share.

## 6. Order of work (the core loop first; briefs in `docs/superpowers/plans/`)
1. **Earning and the referral program** (brief `2026-09-29-earn-invite-brief.md`, extended by §2 above: mentor, welcome
   gift, milestones, class and family codes, postcards later): an agent now.
2. **Missions and the rocket bought with gold** (`2026-09-29-missions-brief.md`), **the flight**
   (`2026-09-29-rocket-flight-brief.md`).
3. **Crews** (belonging, the crew rocket, the crew wall, two-key secrets and co-op quests) and **crew flights** (phase 2):
   a brief after the missions merge.
4. **Postcards and gifts** (sharing at proud moments; presents to open in the game).
5. **Classroom and family** (class codes, class goals, the grown-ups' progress page).
6. **Little Explorer** (ages 3-6) and **grades 9-12** (teens), **Engineer mode**.
7. **World events** (the calendar above), **daily and weekly goals** that forgive.
Every step tested, measured on the emulator, deployed, and written in the dev log; never called "done" (#71).

Sources (owner #85's research, 2026-09-29): [Dropbox referral program](https://referralrock.com/blog/dropbox-referral-program/),
[Wordle's growth](https://www.smithsonianmag.com/smart-news/heres-why-the-word-game-wordle-went-viral-180979439/),
[Morning Brew's milestones](https://referralrock.com/blog/morning-brew-referral-program/),
[K-factor](https://getlaunchlist.com/blog/viral-coefficient-k-factor-guide), [Duolingo friends](https://blog.duolingo.com/friends-social-features/),
[FTC COPPA FAQ](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions).
