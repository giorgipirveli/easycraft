# Owner #98: the rocket easier to build — what the understanding phase found (2026-10-14)

Workflow `rocket-easier-understand` (run `wf_b5ae9374-4dd`, three read-only agents: the child's flow, the cheapest passing rockets, placing parts on the pad). The owner (22:13): "its getting way way to out of hands. so do fix that to make the roket to bulid esier. so lets check the 'buy the parts you don't have' quest". The work paused at 22:48 (#100) after this phase; nothing is designed or built yet. Next on resume: the design (below, proposed), then build it test-first, an adversarial review, merge.

## The flow a child meets

- **1. 'I want to fly to the Moon': the child flies up or opens the Star Map** (both): The Moon's card says 'Mission needed: build a rocket at the Launch Site'. Flying there is refused with the same words. A Short's LEARN IT can open the Mission Board directly, from anywhere.  
  _Evidence:_ core/rules/star_map.gd:33; scenes/sandbox.gd:3408-3409 (travel_to_space refuses a world off the route); scenes/sandbox.gd:856-861 (learn_from_short opens launch_site.board, or toasts 'The Mission Board stands at the Launch Site of your home world.')
- **2. Finding the Launch Site** (both): Nothing points to it. The plaza is about 36 blocks from the spawn (radii 32-46), with a 24-block tower and a blinking light. It has no MY MAP badge, no /find target and no compass arrow. The child has to wander until they see the tower.  
  _Evidence:_ core/rules/launch_site.gd:44-49 (RADII, MIN_EDGE_FROM_SPAWN 24, MAX 58); entities/launch/launch_buildings.gd:24,103 (TOWER_HEIGHT 24, the blinker); core/rules/chat_commands.gd:113 ('/find tilly|home|portal|treasure' only); ui/map/world_map_panel.gd:5-6 (only entries_source = places_director.found_places, scenes/sandbox.gd:2895); no Launch Site words in any hint or toast (grep)
- **3. Walking up to the Mission Board** (both): Within 3.2 blocks of the board it pops open on MISSIONS, with the first mission not yet flown chosen. The speaker reads every mission card. The Moon card: '384,400 km away · the real trip: about 3 days', a fact, and 'The rocket needs: Speed: 15.3 km/s (Earth orbit 9.4, to the Moon 3.3, into orbit round it and down 2.6); A seat for each astronaut; Air and water for 3 days; 3 landing legs and a solar array.' It says nothing about fins, a pointed top, an engine and tank on the top stage, how many stages, how many parts or how much gold. In Survivor the top line says 'Invent the rocket first! INVENT (in MORE, or I on a PC) shows how people learned to fly, from the kite to the rocket.'  
  _Evidence:_ core/rules/launch_site.gd:39-41 (BOARD_AT, BOARD_REACH 3.2); entities/launch/launch_director.gd:192-205; ui/missions/mission_board.gd:91-108 (open: _say(gate), show_page(MISSIONS_PAGE), ReadAloud.auto); ui/missions/mission_board.gd:393-421 (card); core/rules/mission_rules.gd:37,111-125 (needs_words); core/inventions/invention_rules.gd:17-18; scenes/sandbox.gd:950-953
- **4. CHOOSE (or the MY ROCKET tab) with nothing on the pad** (both): One orange line: 'Build a rocket on the pad: engines at the bottom, fuel tanks, a crew capsule on top.' Under it: 'Every part you place on the pad's square counts. Buy parts at the Mission Board.' The line does not say where the blocks are (the palette's SMART tab in the Sandbox) or which tab sells them (PARTS). The button reads 'LAUNCH (not yet)' and is greyed out.  
  _Evidence:_ core/rules/rocket_check.gd:99-103; ui/missions/mission_board.gd:426-457
- **5a. Getting parts in the Sandbox: the palette** (sandbox): The 12 parts sit only on the palette's SMART tab, in a 'SPACE' row under SMART, GAME and HOME. They are free to place and unlimited. No price or 'must be bought' hint is shown. The HUD gold counter says ∞.  
  _Evidence:_ ui/hud/block_palette.gd:299,428-447 (SPACE row on the SMART page), 540-544 (SMART shown in the Sandbox only); data/blocks/rocket_page.gd:31-35; ui/hud/gold_counter.gd:41-45 (∞ when INFINITE_GOLD); core/rules/mode_rules.gd:18,29
- **5b. Getting parts in the Sandbox: buying** (sandbox): PARTS tab: 12 cards in 2 columns, each with 'N gold · you have N' and BUY (one part per tap). 'you have' counts parts bought, not parts on the pad. Main menu GOLD SHOP → ROCKET PARTS: 12 name-and-price cards over 2 pages, one part per tap, and 'It's yours!' after each. Both put the part into the profile (MissionData.parts). Nothing appears in the hotbar.  
  _Evidence:_ ui/missions/mission_board.gd:485-528 (_parts_page, _part_card, 'you have' = have.call), 181-185 (buy_part n=1); scenes/sandbox.gd:928-931 (have = MissionData.parts in the Sandbox), 979-985; core/rules/rocket_parts.gd:176-180 (register_shelf grant = profile.missions.add_part(part, 1)); ui/shop/gold_shop.gd:11,97-109,127
- **5c. Getting parts in Survivor** (survivor): PARTS BUY takes the host wallet's gold and puts 1 part in the bag. 'you have N' is the bag count. Five cards also say how to make the part ('Make 2 at a Workbench: 1 Iron.'): nose cone, fins, legs, separator, heat shield. There is no BUY WHAT MY ROCKET STILL NEEDS and no list of what is still missing. Parts bought in the main menu's Gold Shop or given by a friend are not in the bag.  
  _Evidence:_ scenes/sandbox.gd:965-978 (Survivor branch: gold_spend, bag.add), 926-931 (owned null, have = Session.my_inventory.count); core/crafting/recipes.gd:42-47,66; core/rules/rocket_parts.gd:150-160 (craft_words); ui/missions/mission_board.gd:519-520; core/rules/rocket_check.gd:121-123 (paid line only when owned is a Dictionary); tests/integration/test_mission_board.gd:148-153
- **6. Survivor only: the invention gate before LAUNCH works** (survivor): The rocket must be invented, after the kite, balloon, glider, plane and jet: 10+25+40+60+100+150 = 385 gold (each is free once its School unit is mastered), plus iron, glass, cloth and sticks. The jet and the rocket also need 2 Kerosene each. Kerosene is refined from crude oil at a Refinery (40 gold). Crude oil exists only in the Sandstorm Desert (universe 2), which opens after the Golem is beaten, through Gemma's oil quest and its pump jack.  
  _Evidence:_ core/inventions/invention_line.gd:18-31,104-123 (ROCKET needs iron 8, kerosene 2; gold 150); core/inventions/invention_rules.gd:47-63,113-115,218-220; core/crafting/recipes.gd:76; core/prospecting/deposit_kinds.gd:65 (OIL universe 2); world/prospecting/prospect_director.gd:391-407; core/economy/shop_rules.gd:41 (Refinery 40); core/rules/universe_rules.gd:79-81,121-123; core/save/profile_data.gd:41
- **7. Placing about 33-39 parts in 3 stages, then checking** (both): A first try such as engine, tank, tank, capsule gives 'Lift-off! Your engines push 250 tonnes; your rocket weighs 209.' and 'Your fuel takes you 6.8 km/s; the Moon needs 15.3. Add fuel tanks, or split the rocket into stages.' Adding tanks gives 'Too heavy: … Add an engine or take off a tank.' No rocket of 1 stage, and none of 2 stages under 73 parts, reaches 15.3 km/s, so the child must work out a 3-stage build: a separator layer, space engines directly above it, the crew's parts on the top stage, 3 fins on stage 1, a pointed top, an engine and tank on the top stage. Each check means walking back to the board (pad corner to board about 7-14 blocks). The board reopens on MISSIONS, so the child taps MY ROCKET again and scrolls past the stage lines and 10-14 check lines.  
  _Evidence:_ core/rules/rocket_check.gd:113-118,182-196 (liftoff), 222-229 (speed), 233-301 (crew, fins, top, lander); tests/unit/test_rocket_check.gd:33-62,75-92; ui/missions/mission_board.gd:105 (always reopens on MISSIONS), 426-457, 459-466; entities/launch/launch_director.gd:197-205 (walking away closes it); my search: scratchpad rocket98/minrocket.py and two_stage.py (best 2-stage within 12 engines/24 tanks = 14.59 km/s; smallest passing 2-stage = 73 parts)
- **8. Every line green except the Sandbox 'paid' line** (sandbox): The last line, in orange: 'Buy the parts you don't have yet: 8 Rocket Engine, 3 Space Engine, 15 Fuel Tank, 1 Nose Cone, 1 Crew Capsule, 1 Service Module, 3 Landing Legs, 4 Rocket Fins, 2 Stage Separator, 1 Solar Array (1040 gold).' Under it: 'In the Sandbox building is free; rocket parts are bought with the gold you earn.' This page has no buy button and nothing points to the PARTS tab. 'LAUNCH (not yet)' is disabled and silent.  
  _Evidence:_ core/rules/rocket_check.gd:121-123,305-313; ui/missions/mission_board.gd:443-457 (only CHECK AGAIN and LAUNCH on this page), 449-452; tests/unit/test_rocket_check.gd:221-230
- **9. PARTS tab: 'BUY WHAT MY ROCKET STILL NEEDS: 1040 gold'** (sandbox): An orange button at the top of PARTS. The header says 'Your gold: 25' for a new profile, while the HUD in the same world shows ∞. With too little gold, a tap buys nothing and the top line says 'You need more gold! 1040 gold buys every part still missing.' It does not say how much more is needed or where to earn it. A single BUY says only 'You need more gold!'.  
  _Evidence:_ ui/missions/mission_board.gd:485-489,188-195,557-558; scenes/sandbox.gd:932,979-981; core/save/profile_data.gd:33 (START_GOLD 25); ui/hud/gold_counter.gd:41-45; compare ui/shop/gold_shop.gd:129 ('You need N more gold. Lessons in the SCHOOL earn it!')
- **10. Enough gold: one tap buys everything** (sandbox): All 1,040 gold is spent with no confirmation, one wallet spend and one Profile.save per part kind. The message says 'Every part is paid for!' and the button disappears. The child is still on PARTS and must tap MY ROCKET, scroll, then press 'LAUNCH TO THE MOON!'. The parts stay on the pad and stay owned: they are never used up, so every later Sandbox rocket built from them is free.  
  _Evidence:_ ui/missions/mission_board.gd:196-200,543-548,449-452,210-224; scenes/sandbox.gd:979-985; core/rules/mission_data.gd:21-24 (add_part, never removed); docs/devlog/parts/missions.md:91-96 (ruling 3)
- **11. LAUNCH** (both): The board closes and the RocketFlight starts from the pad (the child at the controls; friends here get the crew call). The rocket stays built on the pad. In Survivor without the rocket invented, LAUNCH (enabled once the check passes) shows the 'Invent the rocket first!' words instead.  
  _Evidence:_ ui/missions/mission_board.gd:210-224; scenes/sandbox.gd:991-1010 (launch_rocket: launch_refusal, mission_gate, crew.launch or fly), 887-896, 3847-3880; core/rules/mission_rules.gd:150-156

## Frictions (most severe first)

- **[blocker] The Moon needs a 3-stage, 33+ part rocket and the game never shows or builds one** — An 8-12-year-old has to find a specific 3-stage layout by trial and error, guided only by km/s numbers and the rocket equation. The advice 'add fuel tanks' makes the rocket too heavy, and 'split it into stages' doesn't say how (separator layer, space engines directly above it).  
  _Evidence:_ core/rules/mission_rules.gd:37 (15.3 km/s); core/rules/rocket_parts.gd:14-27; search over the same numbers and margins (scratchpad rocket98/minrocket.py, two_stage.py): no 1-stage rocket passes; the best 2-stage within 12 engines/24 tanks reaches 14.59 km/s; the smallest passing 2-stage is 73 parts/1,910 gold; the smallest passing rocket is 3 stages, 33 parts, 895 gold (6E+8T+3F+X | 2V+4T+X | V+T+S+C+3L+P, 15.43 km/s). The test design is 39 parts/1,040 gold (tests/unit/test_rocket_check.gd:33-62). The speed line's advice loops: rocket_check.gd:226-228 'Add fuel tanks, or split the rocket into stages', then rocket_check.gd:188-190 'Too heavy'. No blueprint, ghost or 'build it for me' exists in ui/missions/*.  
  _Fix idea:_ A ready plan for each mission on MY ROCKET (a ghost on the pad to fill in, or BUILD IT FOR ME that places a known-good design, the cheapest 33-part one). Speed advice that names the next step ('add a stage: a Stage Separator, then Space Engines on it').
- **[blocker] Survivor's rocket is locked behind 6 inventions, the Golem and the Desert's oil** — In the first Survivor universe the rocket can't be invented at all. A child who wants the Moon must first beat a boss, travel to the Desert, finish an oil prospecting quest, buy a Refinery, and invent five flying machines.  
  _Evidence:_ core/inventions/invention_rules.gd:218-220 (missions open only when ROCKET is invented); core/inventions/invention_line.gd:104-123 (jet and rocket need 2 Kerosene each; 385 gold for the line); core/crafting/recipes.gd:76 (kerosene only from Crude Oil at a Refinery); core/prospecting/deposit_kinds.gd:65 (oil: universe 2); core/rules/universe_rules.gd:121-123 (universe 2 locked until unlocked); core/save/profile_data.gd:41 ('the Golem opens the next'); core/economy/shop_rules.gd:56-57 (Tilly only buys Kerosene, never sells it)  
  _Fix idea:_ A Green Meadows source of kerosene (or a Moon-only rocket that needs no kerosene), and a 'path to the Moon' checklist in the INVENT book or on the board.
- **[major] The 'Buy the parts you don't have yet' line has no button; buying and LAUNCH are on two other pages** — The child reads a 10-item list ending in '(1040 gold)', sees a greyed-out LAUNCH, and has to guess that the PARTS tab has the button. After buying, they have to go back to MY ROCKET and scroll down to LAUNCH.  
  _Evidence:_ core/rules/rocket_check.gd:305-313 (the paid line, last); ui/missions/mission_board.gd:443-457 (MY ROCKET has only CHECK AGAIN and LAUNCH), 485-489 (BUY WHAT MY ROCKET STILL NEEDS only on PARTS), 543-548 (after buying the child stays on PARTS)  
  _Fix idea:_ Put 'BUY THEM: 1040 gold' right under the paid line on MY ROCKET, and after buying, switch to LAUNCH there.
- **[major] With too little gold, the bulk buy does nothing and the words don't say how much more is needed or where to earn it** — A child with 500 of 1,040 gold learns neither that they are 540 short nor that the School pays. The only partial path is tapping BUY once per part on a page that scrolls back to the top after every tap.  
  _Evidence:_ ui/missions/mission_board.gd:192-195 ('You need more gold! %d gold buys every part still missing.', returns before buying anything); scenes/sandbox.gd:976,981 ('You need more gold!'); the Gold Shop already says it better: ui/shop/gold_shop.gd:129 ('You need N more gold. Lessons in the SCHOOL earn it!')  
  _Fix idea:_ 'You have 500 gold: 540 more buys the rest. Lessons in the SCHOOL earn it!', and a 'buy what I can afford now' option.
- **[major] The Sandbox shows ∞ gold, yet rocket parts cost real gold** — The corner says ∞, everything else in the Sandbox is free, and the palette places rocket parts for free. Then the board says 'Your gold: 25' and 'You need more gold!'. That reads as a contradiction.  
  _Evidence:_ core/rules/mode_rules.gd:18 (INFINITE_GOLD: 'the HUD shows ∞; nothing is earned or spent'), 29; ui/hud/gold_counter.gd:41-45; scenes/sandbox.gd:932 (board.gold = Profile.data.survivor_gold), 979-985 (spent directly, no Session.gold_changed); docs/devlog/parts/missions.md:97-99 (ruling 4 accepts this)  
  _Fix idea:_ Show the real gold, or 'rocket gold', on the HUD whenever the board is open or at the Launch Site, and mark the SPACE row 'bought at the Mission Board'.
- **[major] Build first, pay later: BUY WHAT MY ROCKET STILL NEEDS is offered for rockets that can't fly, with no confirmation and no selling back** — A child can pay about 1,000 gold (days of learning) for a 2-stage rocket that tops out at 14.6 km/s, then have to buy different parts for the 3-stage one. A child who built the whole rocket for free hits a multi-day wall at the very last line.  
  _Evidence:_ ui/missions/mission_board.gd:485-488 (visible whenever missing_cost > 0, regardless of result.ok), 188-200 (one tap spends it all); core/rules/rocket_check.gd:121-123 (missing is counted for any rocket); no sell path for MissionData.parts anywhere (grep)  
  _Fix idea:_ Offer the bulk buy only when every other line is green, or say 'this rocket doesn't reach the Moon yet: fix it before buying'. Confirm big spends.
- **[major] The mission card's 'The rocket needs' list leaves out half of the check** — The child builds to the card's list and then finds new orange lines one at a time. Nothing says 'about 35 parts, 3 stages, about 1,000 gold' before they start.  
  _Evidence:_ core/rules/mission_rules.gd:111-125 (speed, a seat, air and water, 3 legs and a solar array, heat shield and parachute) against core/rules/rocket_check.gd:274-301 (3 fins on stage 1, a pointed top, an engine and fuel on the top stage), 199-219 (space engines not in stage 1, upper stage push at least half)  
  _Fix idea:_ List every rule, plus the part count, stage count and gold of the ready plan, on the card.
- **[major] Each check means walking back to the board, which reopens on MISSIONS** — Fix one part, walk about 7-14 blocks, wait for the board, tap MY ROCKET, scroll, read, walk back: repeated dozens of times while learning the 3-stage rules.  
  _Evidence:_ core/rules/launch_site.gd:39-41 (board at local (-10, 3) from the pad's middle, reach 3.2); entities/launch/launch_director.gd:197-205 (walking away closes it; X keeps it shut until you leave); ui/missions/mission_board.gd:105 (open() always shows MISSIONS_PAGE), 426-457 (long list of stage lines and 10-14 check lines to scroll)  
  _Fix idea:_ Reopen on the last page (MY ROCKET), and add a HUD 'check' readout or a check button near the pad.
- **[major] Survivor: no bulk buy, no missing list, and one BUY per part on a page that jumps to the top** — For the Moon a Survivor child taps BUY 25-29 times (6-8 engines, 3 space engines, 13-15 tanks, capsule, service module, solar array) and crafts the rest. Nothing says what is still short, and the lower cards (legs, fins, separator, solar array) need scrolling back to after every tap.  
  _Evidence:_ core/rules/rocket_check.gd:121-123 (no paid line or missing when owned is null); ui/missions/mission_board.gd:485-487 (button hidden when missing_cost is 0), 181-185 (BUY = 1), 155 + 543-548 (every buy rebuilds the page and sets scroll_vertical = 0); tests/integration/test_mission_board.gd:148-153  
  _Fix idea:_ The same 'still needed' list and buy button in Survivor (pad + bag vs the plan), BUY ×N, and keep the scroll position.
- **[major] Rocket parts hide on the palette's SMART tab, and the board never says so** — A child looks for rocket parts under BLOCKS. 'SMART' doesn't suggest rockets, and the board points them to buying instead.  
  _Evidence:_ ui/hud/block_palette.gd:299 (tab 'SMART'), 428-432 (SPACE is the 4th row of SMART); core/rules/rocket_check.gd:101-102 (the empty-pad words say 'Buy parts at the Mission Board' and nothing about the palette)  
  _Fix idea:_ A ROCKET or SPACE tab, or a 'PUT PARTS IN MY HOTBAR' button on the board.
- **[major] Sandbox and Survivor keep separate rocket parts, and no words say so** — A child who bought a Moon rocket in the Sandbox finds 'you have 0' in Survivor and has to pay again. Parts bought in Survivor don't count in the Sandbox either.  
  _Evidence:_ scenes/sandbox.gd:926-931 (Sandbox: MissionData.parts; Survivor: the world's bag), 961-985; docs/devlog/parts/missions.md:91-96 (ruling 3); core/economy/spend_rules.gd:29,34 ('Parts to build your rocket and fly to new planets.')  
  _Fix idea:_ Say on each card and in the Gold Shop where a bought part goes ('for your Sandbox rockets' or 'into this Survivor bag').
- **[minor] No wayfinding to the Launch Site** — The site is 32-46 blocks out in a random direction. A child who wants the Moon from the Star Map is told to go to a place nothing points to.  
  _Evidence:_ core/rules/chat_commands.gd:113 (/find has no launch target); ui/map/world_map_panel.gd:5-6 + scenes/sandbox.gd:2895 (map shows found places only); no toast, hint or compass (grep 'Launch Site' in core/ui/scenes)  
  _Fix idea:_ A MY MAP badge and '/find launch', and the Star Map's MISSION card setting the find arrow.
- **[minor] Long, unpluralised lists: '8 Rocket Engine, 15 Fuel Tank, 2 Stage Separator…'** — A 10-item run-on sentence with wrong plurals is hard for young readers and for the read-aloud.  
  _Evidence:_ core/rules/rocket_check.gd:308-311 ('%d %s' with display_name); ui/missions/mission_board.gd:459-466 (stage words)  
  _Fix idea:_ Plurals, and pictures with counts instead of a sentence.
- **[minor] The greyed-out LAUNCH never says why** — A child taps LAUNCH and nothing happens.  
  _Evidence:_ ui/missions/mission_board.gd:347,449-452 (disabled when not ok); 214-218 (MissionRules NOT_READY 'Not yet: the check has lines to fix first.' can only be reached through press_launch, which a disabled button never fires)  
  _Fix idea:_ Keep it tappable and say which line to fix first.
- **[minor] 'you have N' on PARTS means 'bought', not 'standing on your pad'** — With 8 engines standing on the pad (placed free), the card says 'you have 0'.  
  _Evidence:_ scenes/sandbox.gd:928-930 (Sandbox: MissionData.parts); ui/missions/mission_board.gd:521  
  _Fix idea:_ 'bought N · on your rocket M · still to buy K'.
- **[minor] The Gold Shop's rocket shelf is a weak place to buy a rocket** — 39 taps across 2 pages, no picture, no count, no idea which parts a Moon rocket needs, and no word on where the part went.  
  _Evidence:_ ui/shop/gold_shop.gd:11 (8 per page: 12 parts over 2 pages), 97-109 (a name and a price, no count owned), 127 ('It's yours!'); core/rules/rocket_parts.gd:176-180 (registers 'block' not 'picture', so spend_rules.gd:121-122 gives no picture)  
  _Fix idea:_ A 'Moon rocket kit' item at the plan's price, and pictures and counts on the cards.
- **[minor] The 'build a rocket' Short teaches a different and dearer Moon rocket** — A child who copies the reel pays about 30-50% more gold and places 16-22 more parts.  
  _Evidence:_ core/shorts/studio/studio_rockets.gd:5-9,40-66 (9 engines, a 3×3 separator ring, 8 fins, 5 space engines…: 55 parts, 1,370 gold) against the board's test design of 39 parts, 1,040 gold (tests/unit/test_rocket_check.gd:33-62) and the cheapest 33 parts, 895 gold  
  _Fix idea:_ Make the reel's rocket the board's ready plan.
- **[minor] Survivor: a knock-out drops gold-bought rocket parts like dirt** — About 900 gold of parts can end up in a bag at night, and in multiplayer another player can take it after 5 minutes.  
  _Evidence:_ core/survival/knockout_rules.gd:2-6,59-66 (every carried block, rocket parts included, goes into a bag that is the owner's for 5 minutes, then anyone's); core/rules/mode_rules.gd:20,31  
  _Fix idea:_ Keep rocket parts (like tools) on a knock-out.
- **[minor] Hidden shape rules: side-by-side touching, a separator's whole layer, engines over own-stage parts** — Fins placed corner-to-corner are visible but counted as 0. Legs placed under the lander's engine block it or drop to the lower stage. No line says 'parts must touch side to side'.  
  _Evidence:_ core/rules/rocket_check.gd:31-56 (the biggest piece touching side to side), 60-82 (a layer holding a separator ends the stage), 146-148 (an engine over a part of its own stage is blocked); fins line rocket_check.gd:290 says 'you have 0' for fins placed diagonally  
  _Fix idea:_ Highlight parts not counted on the pad, and add 'touching side to side' to the fins and legs lines.
- **[minor] Survivor: placing parts 10-13 layers up without free flying** — The child has to build and remove scaffolding to reach the capsule and nose cone, or pay plane or jet fuel.  
  _Evidence:_ core/rules/mode_rules.gd:31 (Survivor has no FREE_FLY); core/inventions/invention_rules.gd:15; tests/unit/test_rocket_check.gd:58-59 (the top parts at y 11-12)  
  _Fix idea:_ A ladder on the service tower that reaches the pad's top layers.

## Bugs found (each with a repro)

- **Gold Shop ROCKET PARTS never reach a Survivor bag (gold spent, part unusable in Survivor)**  
  _Evidence:_ core/rules/rocket_parts.gd:176-180 (the shelf's grant is always profile.missions.add_part(part, 1)); scenes/sandbox.gd:926-931 (Survivor: owned = null, have = Session.my_inventory.count); MissionData.parts is read only in the Sandbox branch (grep: sandbox.gd:927,930 only); ui/shop/gold_shop.gd:127 ('It's yours!'). The missions notes asked for the Survivor path to go to the bag: docs/devlog/parts/missions.md:174-177. Tests check only MissionData (tests/unit/test_gold_shop_rocket_shelf.gd:25-34); nothing tests scenes/sandbox.gd buy_rocket_part (grep).  
  _Repro:_ New profile with at least 15 gold. Main menu → GOLD SHOP → ROCKET PARTS → tap 'Fuel Tank 15 gold' → 'It's yours!' (gold -15). Start a Survivor world, walk to the Mission Board → PARTS: 'Fuel Tank … 15 gold · you have 0'. The palette's BLOCKS page has no Fuel Tank. The part shows up only in a Sandbox world's 'you have'.
- **A friend's 'rocket part' present (Fuel Tank) says it waits at the Launch Site but never reaches a Survivor bag**  
  _Evidence:_ core/social/friend_presents.gd:20,68-70 (profile.missions.add_part(FUEL_TANK, 1); 'A Fuel Tank for your rocket! It waits at the Launch Site.'); scenes/sandbox.gd:926-931  
  _Repro:_ Receive and open a ROCKET PART present from a friend. Start a Survivor world → Mission Board → PARTS: 'Fuel Tank … you have 0'. It counts only on a Sandbox pad.
- **Two devices of one account: rocket parts are merged by the larger count while gold spends add up, so parts bought on both devices are lost**  
  _Evidence:_ core/rules/mission_data.gd:69-71 (merge_from: parts[id] = max(mine, theirs)); core/save/profile_backup.gd:151 (merged at sign-in and on every version_clash: net/profile_sync.gd:4-11,83-110,142); core/economy/wallet_sync.gd:21-23 (each device reports its own change since its marker, so both spends reach the server's wallet); core/save/profile_backup.gd:31 (survivor_gold is device-only)  
  _Repro:_ One account signed in on a phone and a PC, both synced, Sandbox parts {}. On the phone buy 8 Rocket Engines (BUY WHAT MY ROCKET STILL NEEDS or the Gold Shop): gold -400, parts {Rocket Engine: 8}, uploaded. On the PC (still holding its pre-purchase copy) buy 8 Rocket Engines: gold -400. The PC's upload clashes and merges: parts = max(8, 8) = 8. The next wallet sync takes both -400s: the account paid 800 gold and owns 8 engines.
- **Shared Sandbox world: a friend's BUY WHAT MY ROCKET STILL NEEDS charges the friend but does not pay for the owner's launch**  
  _Evidence:_ scenes/sandbox.gd:926-927 (owned = this device's profile parts in any Sandbox game), 965-985 (the Sandbox branch has no is_client() refusal, unlike Survivor at 970-971); core/rules/mission_rules.gd:25,150-156 (only the host launches; a guest gets the GUEST words); ui/missions/mission_board.gd:188-200  
  _Repro:_ Host a Sandbox world, a friend joins. Build the Moon rocket on the host's pad. The friend walks to the board → PARTS → taps 'BUY WHAT MY ROCKET STILL NEEDS: 1040 gold': the friend's gold drops by 1,040 and the parts go into the friend's own profile. The host's MY ROCKET still says 'Buy the parts you don't have yet: … (1040 gold)'. The friend's LAUNCH says 'This pad is your friend's: they launch from here…'.
- **Every BUY on PARTS rebuilds the page and scrolls back to the top**  
  _Evidence:_ ui/missions/mission_board.gd:181-185 (buy_part → _after_buying), 543-548 (_after_buying → show_page(page)), 155 (show_page sets _scroll.scroll_vertical = 0); PARTS is a 2-column grid of 12 tall cards (485-528) in a 460-px scroll area (PANEL_SIZE.y - 190, line 307-ish _build)  
  _Repro:_ Survivor (or a Sandbox child buying one by one): open PARTS, scroll down to 'Landing Legs', tap BUY. '+1 Landing Legs' appears, the list jumps to the top, and the Legs card is off-screen. Buying 3 legs, 2 separators and 4 fins takes a scroll before every tap.
- **The bulk-buy button's price can be stale: it charges whatever the pad needs at the moment of the tap, with no confirmation**  
  _Evidence:_ ui/missions/mission_board.gd:488 (the text is set when the page is drawn) against 188-200 (buy_missing re-reads the pad with check() and buys the new missing set); the board never refreshes while friends build (docs/devlog/parts/missions.md ruling 15)  
  _Repro:_ Shared Sandbox world. The host opens PARTS: 'BUY WHAT MY ROCKET STILL NEEDS: 1040 gold'. While it is open, a friend adds 4 Fuel Tanks to the rocket. The host taps the button: 1,100 gold is spent and the message is 'Every part is paid for!', though the button said 1040.

## The gold economy

Starting gold: 25 for a new profile (core/save/profile_data.gd:33), or 125 with a friend's invite code (core/invite/invite_rules.gd:13). The Sandbox world itself pays nothing (core/rules/mode_rules.gd:18, INFINITE_GOLD; autoloads/session.gd gold_add returns early), so the gold comes from the School, Lab, Daily Mission, prospecting and invites. Earning (core/economy/earn_rules.gd): +5 per School answer right first time, capped at 150 a day (lines 18-19); +100 once per unit mastered, i.e. one round with 5 of 6 right first time, not capped per day (core/school/mastery_rules.gd:11-17); +10 per Daily Mission star, 5 a day = 50 (line 30); +25 per new Lab star (line 21). In Survivor also +20 per invention TRY IT, +100 per prospecting quest, +20 per find (100 a day), treasure and golden animals 60-100 (core/rules/loot_rules.gd:48), and monsters. The code's own estimate is about 275 gold a day (earn_rules.gd:13). The steady floor, once units run out, is 200 a day (150 + 50). Moon rocket prices (core/rules/rocket_parts.gd:32-36): the cheapest passing design is 33 parts / 895 gold, 3 stages (search: scratchpad rocket98/minrocket.py). The test and notes design is 39 parts / 1,040 gold (tests/unit/test_rocket_check.gd:33-62; docs/devlog/parts/missions.md:77). The 'build a rocket' reel's design is 55 parts / 1,370 gold (core/shorts/studio/studio_rockets.gd:40-66; scratchpad rocket98/costs.py). No 1-stage rocket passes, and the smallest passing 2-stage is 73 parts / 1,910 gold. Mars at its cheapest is 54 parts / 1,540 gold. Time for the Moon: from 25 gold, about 4.4-5.1 days at 200 a day, about 3.2-3.7 days at 275 a day, about 2 days for a child mastering 3 or more fresh units a day (about 500 a day). Survivor adds the invention line: 385 gold (10/25/40/60/100/150, core/inventions/invention_line.gd; each free when its School unit is mastered, invention_rules.gd:113-115), a Refinery for 40 (core/economy/shop_rules.gd:41), and parts bought at 815-945 gold (25-29 parts; the iron parts are crafted from 15-17 iron, core/crafting/recipes.gd:44-47). That is about 1,240-1,370 gold, plus beating the Golem and a Desert oil quest for 4 Kerosene. Parts are never used up (Sandbox: the profile keeps them; a copy flies), so the first rocket is the only one paid for in each mode, but the Sandbox and Survivor pots are separate. The docs don't match the real prices: SpendRules.GUIDE says first_part 250 and mars_rocket 7000 (core/economy/spend_rules.gd:43), and the only test checks GUIDE itself (tests/unit/test_spend_rules.gd:128). Real parts cost 5-80 gold and Mars costs about 1,540, so the spec's 'Mars a few weeks' (§25.1, §25.5) is not true; ruling 5 in docs/devlog/parts/missions.md:100-102 already notes this. No test ties RocketParts.PRICES to EarnRules.

## The cheapest rocket that passes the check, per mission and crew (verified with the real RocketCheck)

_Method:_ I read core/rules/rocket_check.gd and core/rules/rocket_parts.gd line by line and copied every rule into a Python model:
- lift-off: `push >= mass * 1.1` (:181), using the same float expression.
- upper stages: `push < carries * 0.5` fails (:214).
- blocked engines: only the cell directly below is checked (:158). Space engines fail in stage 1 (:160, :191).
- a layer holding a separator ends its stage (:77-86).
- the top stage needs engine + fuel (:297); seats, supplies, legs, solar array, heat shield/parachute (air) or heat shield (skim) are all read from the last stage (:233-285); the 3 fins count only in stage 1 (:286); the top layer may hold only nose cones or capsules (:317-324).
- find_rocket keeps the biggest connected piece touching y 0 inside 9 × 9 × 64 (:30-63).
- Δv per stage = isp × g0 × ln((full + above) / (empty + above)) (:173).
- missions from mission_rules.gd:34-79. Ganymede comes from `git show worktree-agent-a1926aaadcc0732ee:core/rules/mission_rules.gd` (17.5 km/s, 4,260 days, no air). rocket_check.gd and rocket_parts.gd are identical on that branch.

Search (exact within this model), in scratch rocket98/cheapest/:
- K stages, bottom first. The top stage holds the minimal payload: crew capsules, ceil(crew × days / 200) service modules, 3 legs, 1 solar array, heat shield + parachute (air) or heat shield (skim), and optionally a nose cone.
- Each stage holds tanks and the fewest engines that pass its push rule; adding more only adds mass and gold and lowers Isp. There is one separator per boundary, and 3 fins in stage 1.
- Top-down dynamic programming over states (mass carried, gold, Δv of the stages above), with exact 3D Pareto pruning: a lighter, cheaper, faster state beats any completion of a worse one. The bottom stage is found by scanning its tanks.
- search2.py allows any mix of rocket and space engines in the upper stages (up to 6 stages). search3.py uses space engines only in the upper stages and goes up to 10 stages. The mixed search never beat space engines only: every case it reached matched or was worse.
- Ranges: lander tanks ≤ 12, middle-stage tanks ≤ 200, bottom tanks ≤ 900, at most 81 engines per stage (one layer of the 9 × 9 square).

layout.py turns each plan into pad cells a child reads as a rocket:
- all stages centred on column (4, 4); each stage's engines in its bottom layer. Stage 1's engines sit on the pad with the 3 fins round them; the lander's engine is ringed by 3 legs.
- tank layers no wider than the stage below, about 4 layers tall at most; one separator alone in the middle of its own layer under the next stage's engines.
- the lander from the bottom up: engine and legs, tank(s), service modules (3 × 3 at most) with the solar array on the side, a heat shield and parachute layer, the capsule(s), and a nose cone on top.

verify.gd runs the REAL RocketCheck headless: `nice godot --headless --path <lead-merge> -s rocket98/cheapest/verify.gd -- cells_final.json`. It checks `check(cells, mission, crew, null).ok`, that the gold `RocketParts.cost(RocketParts.count(r.cells))` equals the plan's, and that the rocket is all of the cells. It also prints the "Buy the parts you don't have yet: … (n gold)" line for an empty owned list. Result in verify_final.log: "VERIFY: 94 passed, 0 failed". That is the cheapest with a nose cone, the cheapest with 4 stages or fewer, and the cheapest without a nose cone, for every mission and crew that can be met.

Reference points:
- The test's moon rocket (test_rocket_check.gd:37-66) is 39 parts and 1,040 gold. The cheapest Moon rocket is 33 parts and 940 gold (4 stages), or 950 gold with 3 stages.
- Mercury, Saturn's rings, Pluto and Triton cannot be met with 3 stages even for 1 crew.
- Long trips explode in size because supplies scale with crew × days: Triton with 4 crew needs 88 service modules (352 t) in the lander.
- What-if with one service module (crew × days ≤ 200), crew 1, gold before → after:

| Mission | Gold now | With 1 service module |
|---|---|---|
| Triton | 8,945 | 1,940 |
| Pluto | 7,835 | 2,070 |
| Saturn's rings | 7,045 | 2,435 |
| Ganymede | 7,065 | 1,455 |
| Titan | 4,305 | 1,675 |
| Europa | 3,580 | 2,040 |

  Every crew-4 mission then fits on the pad (for example Triton with 4 crew: 3,230 gold, 101 parts). Mercury stays at 6,680 gold, because its cost is the 24.3 km/s speed, not supplies.
- The mission board's crew is always 1 today (mission_board.gd:51, checked at :172). Crews of 2 to 4 matter for CrewFlightRules.room (crew_flight_rules.gd:66-72).

| Mission | Crew | Parts | Gold | Δv km/s | Layers | Passes |
|---|---|---|---|---|---|---|
| moon | 1 | 33 | 940 | 15.303 | 15 | yes |
| moon | 2 | 40 | 1180 | 15.326 | 15 | yes |
| moon | 3 | 46 | 1415 | 15.374 | 15 | yes |
| moon | 4 | 53 | 1655 | 15.321 | 15 | yes |
| mars | 1 | 49 | 1485 | 16.154 | 17 | yes |
| mars | 2 | 64 | 1940 | 16.151 | 18 | yes |
| mars | 3 | 74 | 2390 | 16.101 | 22 | yes |
| mars | 4 | 89 | 2845 | 16.112 | 19 | yes |
| europa | 1 | 113 | 3580 | 19.24 | 23 | yes |
| europa | 2 | 189 | 5980 | 19.215 | 24 | yes |
| europa | 3 | 260 | 8475 | 19.202 | 27 | yes |
| europa | 4 | 339 | 11005 | 19.205 | 25 | yes |
| io | 1 | 127 | 3975 | 19.736 | 22 | yes |
| io | 2 | 216 | 6710 | 19.709 | 23 | yes |
| io | 3 | 295 | 9485 | 19.711 | 26 | yes |
| io | 4 | 371 | 12475 | 19.701 | 27 | yes |
| titan | 1 | 137 | 4305 | 17.533 | 24 | yes |
| titan | 2 | 236 | 7665 | 17.505 | 26 | yes |
| titan | 3 | 332 | 10945 | 17.505 | 27 | yes |
| titan | 4 | 425 | 15275 | 17.5 | 31 | yes |
| mercury | 1 | 212 | 6680 | 24.32 | 26 | yes |
| mercury | 2 | 297 | 9500 | 24.306 | 28 | yes |
| mercury | 3 | 344 | 11250 | 24.304 | 28 | yes |
| mercury | 4 | — | — | — | — | no plan |
| venus | 1 | 29 | 800 | 13.537 | 12 | yes |
| venus | 2 | 38 | 1095 | 13.511 | 13 | yes |
| venus | 3 | 44 | 1400 | 13.408 | 16 | yes |
| venus | 4 | 48 | 1565 | 13.441 | 18 | yes |
| rings | 1 | 219 | 7045 | 20.002 | 26 | yes |
| rings | 2 | 386 | 13295 | 20.009 | 29 | yes |
| rings | 3 | — | — | — | — | no plan |
| rings | 4 | — | — | — | — | no plan |
| pluto | 1 | 251 | 7835 | 18.604 | 25 | yes |
| pluto | 2 | 436 | 15975 | 18.602 | 37 | yes |
| pluto | 3 | — | — | — | — | no plan |
| pluto | 4 | — | — | — | — | no plan |
| triton | 1 | 277 | 8945 | 18.505 | 26 | yes |
| triton | 2 | — | — | — | — | no plan |
| triton | 3 | — | — | — | — | no plan |
| triton | 4 | — | — | — | — | no plan |
| ganymede | 1 | 223 | 7065 | 17.507 | 22 | yes |
| ganymede | 2 | 390 | 13210 | 17.504 | 28 | yes |
| ganymede | 3 | — | — | — | — | no plan |
| ganymede | 4 | — | — | — | — | no plan |

_Search advice:_ Precompute the plans. Do not search when the board opens.

Why:
1. The exact cheapest plan needs 3 to 9 stages (most far missions need 6 or 7) and a Pareto dynamic program over (mass, gold, Δv). In Python with numpy that took about 2 minutes for all 88 cases (11 missions × 4 crews × with/without nose cone).
2. I measured a restricted search in real GDScript (scratch rocket98/cheapest/runtime_search.gd). Its space: 3 or 4 stages; space engines only above stage 1, the fewest passing the 0.5 rule; lander 1-3 tanks, stage 3 1-15 tanks, stage 2 1-80 tanks; the bottom stage by binary search on tanks, capped at (81 × 250 / 1.1 − 81 × 4 − 2.5 − carried) / 100.
   - Time per mission and crew on this desktop: 1.5-5 ms for the Moon and Venus, 5-11 ms for Mars, about 18 ms for every far world (565 ms for all 40). Phones are 3-5× slower.
   - It finds the 4-stage optimum but misses the real optimum: Europa crew 1 costs 3,790 instead of 3,580; Mercury crew 1 costs 8,895 instead of 6,680.
   - It cannot build plans that need 5 or more stages (Europa crew 4, Io crew 4, Titan crew 4, Mercury crew 2-3, the rings, Pluto and Ganymede crew 2). It also misses Io crew 3 and Titan crew 3 at 4 stages, because their stage 2 needs more than 80 tanks.

Suggested shape:
- A pure class, for example `RocketPlans`, with a const table keyed by mission id, then crew 1-4. Each entry holds only the stages bottom first, as [engine kind, engine count, tank count], plus the gold. Everything else follows from the rules: 3 fins in stage 1, one separator per boundary, and the lander payload (crew capsules, ceil(crew × days / 200) service modules, 3 legs, 1 solar array, heat shield/parachute by air or skim, a nose cone).
- `RocketPlans.counts(mission, crew)` returns {id: count}. For the "buy the parts you don't have" step, use `RocketParts.missing(counts, owned)` and `RocketParts.cost(...)` (rocket_parts.gd:146-160) on the plan's counts, not on the pad's.
- `RocketPlans.cells(mission, crew)` is a port of layout.py (about 80 lines: rings around the pad's middle, engines at each stage's bottom, a separator layer, legs and fins round the engines). It gives a ghost/blueprint or a BUILD IT FOR ME.
- A GUT test, like the reel studio's test, asserting for every entry: `RocketCheck.check(cells, mission, crew, null).ok`, gold == `RocketParts.cost(RocketParts.count(cells))`, all cells are in the rocket, and the height is under 64.
- An offline tool (search3.py + final.py, or a GDScript port run as a tool) to regenerate the table whenever PARTS, PRICES or MISSIONS change. Cosmos missions (Ganymede) get rows when that branch merges.

Opening the board then costs one dictionary lookup plus building about 50-400 cells (well under 1 ms).

If a runtime search is still wanted, for example to make use of parts the child already owns, keep it to the precomputed plan's shape: the same stage count and engine kinds, with each stage's tank count varied by ±3 and the fewest engines recomputed. That is about 7^K evaluations for K stages (343 for 3, 2,401 for 4), but 7^6 and 7^7 are 117,649 and 823,543, so it is only cheap for the 3-4 stage plans (Moon, Mars, Venus). Restrict it to those missions or vary only 2-3 stages. Alternatively, run the measured 3-4 stage space for the Moon, Mars and Venus only.

_Pitfalls:_

- The 9 × 9 square caps stage 1 at 81 rocket engines. PAD 9 (rocket_check.gd:18) × push 250 (rocket_parts.gd:15) / LIFT_MARGIN 1.1 (rocket_check.gd:20, :181) means at most 18,409 t can lift off. Space engines cannot help in stage 1 (:160, :191-195). Every plan for 2+ crew to a far world sits at 81 engines and about 18,350 t. Ten mission × crew pairs cannot be met with up to 10 stages: Mercury 4, rings 3-4, Pluto 3-4, Triton 2-4, Ganymede 3-4. They would need 107 to 228 engines.
- Supplies, not speed, make far missions huge. The check needs crew × days of supplies (rocket_check.gd:249) at 200 days per service module (rocket_parts.gd:20), all in the lander. Triton with 1 crew needs 22 modules; with 4 crew, 88 modules (352 t). With one module's worth of days, crew-1 costs fall: Triton 8,945 → 1,940 gold, Pluto 7,835 → 2,070, rings 7,045 → 2,435, Ganymede 7,065 → 1,455, Titan 4,305 → 1,675, Europa 3,580 → 2,040. Every crew-4 mission then fits (for example Triton crew 4: 3,230 gold, 101 parts). Mercury is the exception (6,680), because its cost is the 24.3 km/s speed. This is the strongest lever if the owner wants rockets easier.
- The plans clear the needed speed by very little: Titan crew 4 by 0.0004 km/s, Moon crew 1 by 0.003, Ganymede crew 1 by 0.007. Any change to PARTS, a mission's legs, or even the order floats are summed in can break a plan. A stored table must be guarded by a GUT test and regenerated after changes. Optionally build it to need + 0.05 km/s for a few gold more.
- Use the check's exact float expressions in any planner: `push >= mass * 1.1` (rocket_check.gd:181) and `push < carries * 0.5` (:214). For example 500 * 1.1 = 550.0000000000001, so a 500 t rocket with exactly 550 t of push fails. My Python mirrors these, and every plan was confirmed with the real check.
- A separator anywhere in a layer ends the stage, together with that whole layer (rocket_check.gd:77-86). The next stage's engines must go in the layer above it. A decorative separator ring placed in a tank layer cuts the stage there. My layout puts one separator alone in the middle of its own layer; the next stage's engines sit on it and overhang beside it, which the check allows (an engine is blocked only when the cell directly below is in its own stage, :158).
- Loophole in the blocked-engine rule: only the cell directly below is checked (rocket_check.gd:158). An engine with an empty cell under it counts even high up inside its stage, so engines stacked with gaps could get around the 81-engine cap. I did not use this. Consider closing it if the cap is meant.
- Everything the crew needs is read from the top stage only: seats, supplies, legs, power, heat shield, parachute and the lander engine plus fuel (rocket_check.gd:112-114, :233-302). Fins count only in stage 1 (:286). The top layer may hold only nose cones or capsules (:317-324), so without a nose cone and with 2+ crew the top is several capsules side by side.
- Upper stages use only space engines, the fewest that pass the 0.5 rule. In my search that allowed any mix of rocket and space engines (up to 6 stages), mixes never beat space engines only (cross-check logs in rocket98/cheapest/k5.log and k6.log).
- The board checks with crew 1 only today (mission_board.gd:51, check at :172). Crews of 2-4 matter only for CrewFlightRules.room (crew_flight_rules.gd:66-72), which reruns the check with 1 + friends, so a crew-1 plan seats no friends. BUY WHAT MY ROCKET STILL NEEDS works from the pad's parts (mission_board.gd:188-200). A plan or kit flow should compute what is missing from the plan's counts against what the child owns (RocketParts.missing, rocket_parts.gd:154).
- Ganymede exists only on the cosmos branch (worktree-agent-a1926aaadcc0732ee: core/rules/mission_rules.gd, 17.5 km/s, 4,260 days), not on lead-merge. My verifier builds that mission by hand; rocket_check.gd and rocket_parts.gd are identical on that branch.
- `godot -s` with --path starts the project's autoloads. Profile reads the real profile (read-only: autoloads/profile.gd:18-30) and prints SCRIPT ERROR lines after the script finishes. Those are harmless; filter them out.
- The scratch folder rocket98/ is shared: other agents' files appeared there (best2.py, costs.py, minrocket.py, two_stage.py). All my work, including verify.gd, is in rocket98/cheapest/, not rocket98/verify.gd.
- For scale: the test's Moon rocket (test_rocket_check.gd:37-66) is 39 parts and 1,040 gold; the cheapest Moon rocket is 33 parts and 940 gold (4 stages) or 950 gold with 3 stages, which looks like the test's rocket. With 3 stages, Mercury, the rings, Pluto and Triton cannot be built even with one astronaut. The cheapest plans for Europa and beyond need 5-7 stages and 113-436 parts.

_Scratch (not in the repo):_ /tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/rocket98/cheapest/ (search3.py: exact search with space engines only above stage 1, up to 10 stages; search2.py/search.py: search allowing engine mixes; layout.py: plan to pad cells; final.py: picks the cheapest per mission and crew and writes cells_final.json and table_final.json; verify.gd: the real RocketCheck run headless, log in verify_final.log, 94 passed and 0 failed; runtime_search.gd: the GDScript timing test; structured_plans.json: these records; nocap_plans.json: the plans that exceed 81 engines)

## Placing a plan on the pad (BUILD IT FOR ME)

- **place api:** How the game writes blocks today. This is a read-only survey; nothing was edited.

1) WorldService, the only code that touches voxels. Its header says set_block is host-only and that clients go through Session.request_set_block (world/world_service.gd:1-4).
- set_block(pos, id), world_service.gd:155-163: silently does nothing when the cell is not editable (not loaded). Otherwise it writes and emits block_changed(pos, old, new).
- put_block, :166-168: used on a guest for host edits. It announces nothing.
- is_editable(pos), :170-171.
- box_reader(origin, size), :144-152: one bulk copy. A chunk that is not loaded reads as generated terrain, never as a placed block.
- blocks_at(cells), :340-354.
- set_blocks([[pos, id], ...]), :357-382: returns [[pos, old, new]] for the cells that really changed.
  - When the cells fill their box well enough (BULK_SPREAD 8, BULK_MAX 65536, :335-336, _bulk_box :385+) and the whole box is editable, it does one copy and one paste, then announces every changed cell.
  - Otherwise it falls back to set_block cell by cell, so cells in chunks that are not loaded are dropped silently. The returned list shows what was really written.
- Every block_changed on the host feeds WorldSync. WorldSync._on_block_changed (net/world_sync.gd:225-234) records the cell in the EditLog and queues a single change for every guest. WorldSync._send_all (:283-305) sends at most one paced packet per guest per frame through Session.a_send_world_edits/_rpc_world_edits (autoloads/session.gd:2149-2166). So any host-side write reaches friends with no extra code.

2) Player edits, through Session.
- request_set_block (session.gd:95-102) and request_set_blocks (:106-112). A guest sends _rpc_request_set_block/_rpc_request_set_blocks (any_peer, :115-118, :256-259) and the host checks the request.
- _host_apply (:262-284) and _host_apply_batch (:121-154) check:
  - Game.allows(BUILDING);
  - PlacementRules.validate_edit (core/building/placement_rules.gd:52-71): not bedrock, within reach of the requester's eye (single edits REACH 10 + 2, batches BATCH_REACH 32, :6-8), the id valid, and the block not inside any player AABB (_player_bodies, session.gd:294-299, spawned players only, no bots, no animals);
  - in Survivor, the GatherLedger.
- A batch is sanitized and capped by EditBatch.sanitize (MAX_BATCH 1600, core/building/edit_batch.gd:5-24). Each request becomes one undo step, sent back by the host (_undo_entry :157-163, _send_undo_step :166-172, _rpc_undo_step :175-177). Placed blocks also count for the builder's XP (progress_placed :151, :2818-2822).
- BlockInteractor._apply_edits (entities/player/block_interactor.gd:199-206) adds mirror copies when mirror mode is on. A plan must never go through it with mirrored=true.

3) Building tools (M3 Task 8), Session.request_build_tool / host_build_tool (session.gd:4035-4098).
- FILL and PASTE are Sandbox only (TOOLS_SANDBOX_ONLY) and write only into air or water. They are not checked for reach until written (PowerTools.REACH 48, core/building/power_tools.gd:16) and never write into a body.
- Writes are sliced: TOOL_CHUNK 16 cells, TOOL_FRAME_MS 8 ms a frame (session.gd:4015-4017), done by _tool_tick (:4104-4138, called from _physics_process :1203) and _tool_write (:4145-4157, which re-reads the cells and uses world.set_blocks).
- A request is one undo step through the host's tool log (TOOL_UNDO, :4169+). That undo goes through no ledger: in Survivor, undone parts would vanish.
- At most 2 unfinished jobs per player (:4022). Tool edits do not count as XP.

4) Host-only writes with no request.
- LaunchDirector._stamp_step (entities/launch/launch_director.gd:124-160) writes the pad with world.set_blocks, WRITE_BATCH 48 cells a frame (:16).
- Session.bot_set_blocks (session.gd:1418-1434) checks bodies, including bot_friends, and only fills empty cells.
- The tools that put a rocket on the pad today write directly with world.set_blocks at corner + rel: tools/mission_smoke_steps.gd:141-146, tools/launch_shots_steps.gd:49-54, tools/net_test.gd:699-704.

Conclusion: BUILD IT FOR ME should write on the host with world.set_blocks, one layer at a time, after its own checks (bodies, bedrock, Survivor ledger, editability). WorldSync then carries the blocks to friends.
- **pad coordinates:** Where the rocket's cells are in the world:
- A site is {pos: Vector3i(the pad's middle x, the concrete's y, z), facing: 0..3} (core/rules/launch_site.gd:14-15).
- The build square is SQUARE_HALF 4, so 9 × 9 (= RocketCheck.PAD, rocket_check.gd:18). The stripe ring is PAD_HALF 5, so 11 × 11 (launch_site.gd:17-18).
- LaunchSite.corner(site) = Vector3i(pos.x - 4, pos.y + 1, pos.z - 4) (launch_site.gd:100-103): the rocket's first layer, one above the concrete.
- Plan or rocket cells are relative to that corner with y up: x and z in 0..8, y in 0..MAX_HEIGHT-1 (64) (RocketCheck.in_square, rocket_check.gd:29-31). The world cell is corner + rel.
- LaunchDirector.read_pad() (launch_director.gd:209-223) returns the non-air cells of the box corner .. corner + (9, 64, 9), relative to the corner. It reads one box_reader copy of about 5,200 cells.
- The concrete is at rel y = -1, so it is never read as part of the rocket (tests/integration/test_launch_director.gd:140-150).
- The flight uses the same frame: _fly_mission sets rocket.origin = Vector3(LaunchSite.corner(site)) (scenes/sandbox.gd:887-891, also :4027).

Facing:
- facing turns local plaza coordinates (+Z local points at the spawn) through _turn (launch_site.gd:214-222): f0 means +Z, f1 +X, f2 -Z, f3 -X towards the spawn.
- It is used by to_world and to_world_point (:88-97), so it places the board, Mission Control (CONTROL_MIN/MAX :37-38) and the tower (TOWER_MIN/MAX :35-36) around the pad.
- corner() ignores facing, because the 9 × 9 square is symmetric. Rocket cells are therefore in world axes (+x is world +X, +z is world +Z) whatever the facing.
- To turn a plan towards Mission Control, turn its cells around the square's middle: rel' = (4, y, 4) + _turn((rel.x - 4, rel.z - 4), facing). Because 9 is odd, every cell stays inside 0..8. The check does not depend on orientation.
- The tower (local x 6..8) and Mission Control (x -12..-8) are models outside the square, so a plan never overlaps them.

The board:
- BOARD_AT (-10, 3) from the middle cell's centre, at pos.y + 1 (launch_site.gd:39, :180-191). near_board allows a horizontal distance of 3.2 or less and a height difference of 4 or less.
- From the board's eye (HEAD_HEIGHT 1.55, entities/player/camera_rig.gd:9) to the farthest cell of a rocket H layers tall, as I computed it:
  - H 13 (the Moon test rocket): 19.1
  - H 20: 23.8
  - H 24: 26.9
  - H 30: 32.0 (the BATCH_REACH limit)
  - H 40: 41
  - H 64: 63.8
- The test Moon rocket (tests/unit/test_rocket_check.gd:42-67; tools/mission_smoke_steps.gd:53) has 39 parts in 13 layers (y 0..12) and 3 stages. Its largest layer is y 0 with 12 cells. It costs 1,040 gold over 10 kinds of part.

Pad states:
- stamped is true on the host only after the stamp. A guest never stamps, so its stamped is always false (launch_director.gd:80-89; test_launch_director.gd:113-118).
- Before the stamp, the host's natural check (LaunchSite.natural, launch_site.gd:141-151) rejects the site if any block other than ground, trees, plants or air is on the plaza. Rocket parts count as such blocks, and the site then moves (_take_check, launch_director.gd:162-176). Building before the stamp must be refused.

Blocks already on the pad:
- RocketCheck.find_rocket (rocket_check.gd:36-63) takes the biggest connected piece of parts standing at y 0. Non-part blocks never count, and parts that don't touch the piece are ignored. Parts that touch it change mass and stages; an engine with a tank under it is "blocked" (rocket_check.gd:158-159).
- Recommended diff, pure, per plan cell:
  - same part already there: keep, at no cost;
  - air or water: place;
  - a different rocket part: replace (in Survivor the old part returns to the bag through the ledger's drop);
  - a non-part block: blocked. Refuse with a count, never break a child's build.
- Rocket parts inside the 9 × 64 × 9 box that are not in the plan are cleared, so they can't fuse with the new rocket. In Survivor they return to the bag. Other non-part blocks off the plan's cells stay where they are.
- **multiplayer:** Authority:
- The host owns the world. WorldService.set_block is host-only (world_service.gd:1-4).
- sandbox.is_client() is Game.net_mode == &"client" (scenes/sandbox.gd:130-131). Session.is_host() is true with no peer or as the server (session.gd:52-53).
- LaunchDirector.host = not is_client() (sandbox.gd:907). Only the host stamps the pad (_process → _stamp_step, launch_director.gd:108-115) and saves the site (sandbox.gd:909-915).

Friends build on the pad together (spec §21d.2/§21d.6, docs/superpowers/specs/2026-09-23-realm-hoppers-design.md:2813-2849):
- A guest places parts through request_set_block(s) RPCs that the host checks.
- The host's writes reach guests through WorldSync: block_changed → GuestSync, paced one packet per guest per frame and held back while the relay has a backlog (net/world_sync.gd:225-234, 283-305).
- A guest's world gets the cells via receive/_apply (:318-345). Cells in chunks that are not loaded wait in the EditOverlay and are re-applied on load (:349-358).

Guest specifics:
- A guest finds the site from the seed, not from the host's save (sandbox.gd:912 passes [] when not host). Ruling 10 (docs/devlog/parts/missions.md:118-119): if the host passed over a site because a child had built there, the guest's buildings and board stand at a different place from the host's pad. The cost of fixing it is one RPC with the saved site.
- A guest's LAUNCH is refused (MissionRules.launch_refusal → GUEST, core/rules/mission_rules.gd:150-155; sandbox.gd:991-998).
- A Survivor guest can't buy parts ("Buy rocket parts in your own world…", sandbox.gd:969-971).
- A guest's MY ROCKET reads its own mirror of the world (board.read_rocket = launch_site.read_pad, sandbox.gd:925).

Crew: launch_rocket with peers calls CrewFlights (sandbox.gd:1007-1008; ui/missions/crew_flights.gd). Session.MAX_CLIENTS is 3 (session.gd:26), so a crew can be up to 4. The check counts the crew (board.crew, mission_board.gd:51).

Recommendation for BUILD IT FOR ME: host-authoritative.
- A guest sends only the mission's world id in a new reliable any_peer RPC, never a list of cells.
- The host checks the request against its own site and its own copy of the guest's player: LaunchSite.near_board(host site, Session._player_for_peer(peer).global_position), with a little slack for lag. Session._player_for_peer is at session.gd:287-291.
- The host builds the plan on its own pad and pays from the requester's bag (inventory_of(peer)).
- It sends the stage words to everyone with Session.send_feedback (session.gd:196-200, which shows a HUD toast through magic_feedback, ui/hud/hud.gd:129).
- At the end it sends one undo step to the requester only (_send_undo_step).
- One build job per pad. A second request gets "Mission Control is already building!".
- This also means a guest's BUILD always uses the host's real pad, avoiding the ruling-10 mismatch for building. The guest's watching position and read_pad can still differ until the site RPC is added.
- **survivor bag:** Inventories are the host's:
- Session._inventories, keyed by peer (session.gd:779). inventory_of(peer) is at :864-867. my_inventory (:931) is the host's own Inventory object, and on a LAN guest the last snapshot the host sent (_rpc_inventory :997-1001).
- Changes are sent once per frame (_on_inventory_changed / _send_inventories, :984-994). The HUD and hotbar listen to inventory_changed.
- board.have reads Session.my_inventory.count(id) in Survivor (sandbox.gd:928-931). board.owned returns null in Survivor, so there is no "paid" line (sandbox.gd:926-927; test_mission_board.gd:148-154).

Paying for edits:
- GatherLedger (core/survival/gather_ledger.gd), created by Session.gather_ledger(peer, is_undo) (session.gd:938-942).
- reserve([[old, new], ...]) only checks, it never takes (:28-43). A batch is paid whole or not at all. Its message is "You need N more X!" or "You have no X left!" (:76-82).
- pays(old, new) (:47-62) and changed(old, new) (:66-73) take one `new` and give the drop of `old`. GatherRules.change, core/survival/gather_rules.gd:111-119.
- Rocket parts are not in DROPS and have no NEEDS_TIER, so placing one costs the part itself (cost → PowerRules.item_of(id) = id, core/rules/power_rules.gd:54-55). Breaking or replacing one gives it back, whatever the pickaxe.
- An undo is the exact reverse: undoing a placed part returns it to the bag (gather_rules.gd:106-119; tests/integration/test_survivor_gathering.gd:292-299, 335-348).
- Inventory.MAX_COUNT is 999 (core/survival/inventory.gd:6).

How the batch path pays: _batch_ledger (session.gd:946-957) reserves the whole batch, but only the cells that pass validate_edit with BATCH_REACH. Then pays() and changed() run per cell (:139-145).

For BUILD IT FOR ME in Survivor (new host function; no reach check, since the request is gated by near_board):
- Up front: GatherLedger.new(inventory_of(peer)).reserve(all [old, new] of the diff, the clears included, so recycled parts count towards the need). If it fails, refuse before placing anything, telling the child exactly what is missing: RocketParts.missing(net need, bag), RocketParts.cost(...) in gold, and a BUY offer.
- Per slice: a fresh ledger with reserve, then pays and changed per written cell, using the old/new pairs world.set_blocks returns. The bag can change mid-build (a friend trades, a knock-out drops the bag); if a slice can't be paid, stop with the ledger's message and send the undo step for what was built.
- The board's buy hook already puts parts into the host-side bag for the host player (sandbox.gd:972-979; tools/mission_smoke_steps.gd step 6). A "BUY AND BUILD" for the host can call buy_rocket_part for every missing id and then request the build.
- A guest's build in Survivor pays from inventory_of(guest peer), the guest's bag in this world. The guest can't buy here, so its build is refused with the list of what it lacks.
- Do not use the build-tool path (TOOL_PASTE / TOOL_UNDO) in Survivor. It refuses Survivor (session.gd:4069-4072), and its undo runs no ledger, so undone parts would be lost.
- **sandbox palette:** Sandbox (Game.allows(ModeRules.UNLIMITED_BLOCKS), core/rules/mode_rules.gd:16 and :29):
- Every block is free and never counted. Session.gather_ledger returns null (session.gd:938-942), so _host_apply_batch charges nothing (:132).
- The 12 rocket parts are in the palette's SMART page, SPACE row (ui/hud/block_palette.gd:422 and :430-432; RocketPage.SPACE_ROW, data/blocks/rocket_page.gd:33-35). Placing them on the pad costs nothing.
- Only LAUNCH needs the parts bought:
  - board.owned returns Profile.data.missions.owned() in the Sandbox (sandbox.gd:926-927);
  - RocketCheck.check adds the "paid" line with RocketParts.missing(count(rocket), owned) (rocket_check.gd:119-121, 305-313);
  - bought parts live in MissionData.parts (core/rules/mission_data.gd:10, 21-29) and are never used up. Owning 8 engines covers every later rocket with 8 or fewer. It is a profile purchase made with Profile.data.survivor_gold (sandbox.gd:980-985; missions.md rulings 3-4).
- BUY WHAT MY ROCKET STILL NEEDS exists only on the PARTS page (MissionBoard._parts_page, mission_board.gd:485-490; buy_missing :188-202).
- Sandbox has INFINITE_GOLD, so Session.gold_spend always succeeds there (session.gd:794-798). That does not matter here: Sandbox parts are paid from the profile's gold directly.

So in the Sandbox, BUILD IT FOR ME can place the whole plan for free. Right after, the board's MY ROCKET should show the plan's price and the gold still needed, with the buy button on the same page (owner #98, docs/playtests/owner-feedback.md, row 98).

Survivor (UNLIMITED_BLOCKS off):
- The palette is "counted": BLOCKS shows only what Session.my_inventory holds, and the SMART tab, with its SPACE row, is hidden (block_palette.gd:7 and :135-139).
- Parts are bought at the board into the bag (sandbox.gd:969-979) or crafted: 5 simple parts at a Workbench or Clay Oven (RocketParts.craft_words, rocket_parts.gd:124-134; missions.md ruling 12).
- Placing a part goes through the GatherLedger.
- Survivor's missions are gated until the rocket is invented (mission_gate, sandbox.gd:950-953; board.gate, mission_board.gd:49). BUILD IT FOR ME should honour the same gate as press_launch (mission_board.gd:210-214).
- **undo and saves:** Undo, how it works today:
- BlockInteractor keeps an UndoStack(20) (UNDO_DEPTH 20, entities/player/block_interactor.gd:12 and :21; core/building/undo_stack.gd, oldest dropped at 20). A batch is one entry (push_batch).
- Steps come only from the host: Session.undo_step_received → _on_undo_step (block_interactor.gd:211-221). A step is [[pos, id to put back, id now], ...]. One entry becomes push; several become one batch.
- Undo (block_interactor.gd:234-255):
  - a batch → Session.request_set_blocks([[pos, old]], is_undo = true);
  - a tool step (via &"tool") → request_build_tool(TOOL_UNDO).
- A normal undo is checked like an edit: bedrock, BATCH_REACH 32 from the eye, bodies, and the Survivor ledger, which refunds the parts. Cells it can't restore yet, because someone stands there or they are too far, come back as a new step kept for later (_undo_entry, session.gd:157-163; tests/integration/test_edit_undo.gd:162-193).
- Undo never counts as XP (progress_placed only when not is_undo, session.gd:2818-2822).

Recommendation: the host gathers every [pos, old, new] the build wrote (clears and replacements included) and sends one normal undo step at the end with Session._send_undo_step(peer, step) (session.gd:166-172; give it a public wrapper).
- One press of UNDO takes the whole auto-built rocket down and puts back what was there. In Survivor the parts return to the bag.
- It uses 1 of the 20 slots, not one slot per layer.
- Undo of a very tall plan from the board leaves the far cells pending: farther than 32 means more than about 26-30 layers. Keep plans at 24 layers or fewer.
- Do not count the build as placed blocks (no progress_placed), as for the building tools (session.gd:3993). Otherwise build, undo, build would farm XP.
- Rejected: the tool path's single TOOL_UNDO step. It has no ledger and is Sandbox only.

Saves:
- Blocks written with set_block/set_blocks live in the VoxelTerrain. WorldService.save() calls save_modified_blocks (world_service.gd:243-246), save_and_wait :249-257.
- The sandbox saves the world:
  - every AUTOSAVE_SECONDS 60, more often in a browser (sandbox.gd:10, 240-244);
  - in save_world (:521-566): the host only (is_client returns early, :522). It also writes the Survivor bag into meta.inventories (:558-559) and calls Profile.save (:564);
  - on quit or app pause (:568-575 and _notification).
- Bag and terrain are saved together, so a ledger that charges only for cells actually written keeps them consistent.
- The host's EditLog gives guests who join later the edited chunks (WorldSync._offer/_list_of).
- Guests save nothing.
- The Sandbox's bought parts are saved in the profile by buy_rocket_part (sandbox.gd:980-985).
- meta.launch_site ([x, y, z, facing, stamped], launch_site.gd:194-211; world/world_meta.gd:60-61) is not touched by building.
- The build job's own state should not be saved. If the game closes mid-build, the layers already written stay (they are saved with the next save). Pressing BUILD IT FOR ME again completes the rocket, because the diff keeps cells that already hold the right part.

**Recommended hook:**

Host-authoritative build job, placed layer by layer, five pieces. Names are proposals; existing code is cited as path:line.

1) Pure rules: core/rules/rocket_plan.gd (class_name RocketPlan, RefCounted, unit-tested).
- static func for_mission(mission: Dictionary, crew: int = 1) -> Dictionary: {Vector3i relative to LaunchSite.corner, y up: part id}. Height 24 or less; one piece; passes RocketCheck.check(plan, mission, crew, RocketParts.count(plan)).ok.
- static func layers(plan) -> Array: bottom first, [[Vector3i, id], ...] per y.
- static func stage_tops(plan) -> Array[int]: from RocketCheck.stages_of(plan) (rocket_check.gd:67-89), the top y of each stage.
- static func stage_words(plan, i) -> String: like MissionBoard._stage_words (mission_board.gd:459-466), e.g. "Stage 1: 8 rocket engines and 10 fuel tanks lift everything."
- static func diff(plan, pad: Dictionary) -> Dictionary: {place, keep, clear, blocked}, with pad = LaunchDirector.read_pad().
- Optional static func turned(plan, facing): turns cells around (4, 4).
- Test: for every MissionRules.MISSIONS entry, the plan passes; find_rocket(plan).size() == plan.size(); every cell in_square; height 24 or less.

2) LaunchDirector (entities/launch/launch_director.gd) owns the paced job on the host.
- Declarations:
  - signal build_stage(peer_id: int, stage: int, words: String)
  - signal build_done(peer_id: int, step: Array, why: String)
  - const BUILD_LAYER_SECONDS := 0.4, const BUILD_CELLS_PER_FRAME := 16, const BUILD_WAIT_SECONDS := 15.0
  - var write_cells: Callable, default Session.host_rocket_cells; tests inject the FakeWorld writer
  - var bodies: Callable
- func build(plan: Dictionary, peer_id: int) -> String, returning "" when started. Refuses when:
  - host is false;
  - site is empty or not stamped ("The pad is still being made: wait a moment!");
  - a job is already running ("Mission Control is already building!");
  - the diff has blocked cells ("%d blocks stand where the rocket goes: break them first").
  Otherwise it queues the clears (top down) then the places (bottom up) as world cells (corner + rel), keeps the stage tops, and returns "".
- func _build_step(delta), called from _process right after _stamp_step() inside `if host:` (launch_director.gd:113-115):
  - skip while get_tree().paused;
  - every BUILD_LAYER_SECONDS, take the next layer;
  - wait while any body intersects AABB(corner, (9, H, 9)), saying it once and giving up after BUILD_WAIT_SECONDS;
  - wait while any of the layer's cells is not world.is_editable;
  - re-read the layer with world.blocks_at, skipping cells someone changed;
  - write at most 16 cells a frame through write_cells.call(peer, chunk) and append the returned [pos, old, new] to step;
  - after a stage-top layer, emit build_stage;
  - at the end, emit build_done(peer, step, "").
- func building() -> bool. In _exit_tree, emit build_done for what was written.

3) Session (autoloads/session.gd), a new section after the M3 Task 8 tools (~:4255).
- signal rocket_build_requested(peer_id: int, world: int), on the host.
- signal rocket_build_done(ok: bool, text: String), on the requester's game.
- func request_rocket_build(world: int) -> void: the host emits for its own id; a guest calls _rpc_rocket_build.rpc_id(1, world).
- @rpc("any_peer", "call_remote", "reliable") func _rpc_rocket_build(world: int): if is_host(), emit rocket_build_requested(get_remote_sender_id(), world).
- func host_rocket_cells(peer_id: int, changes: Array) -> Array:
  - checks world != null and Game.allows(BUILDING);
  - EditBatch.sanitize;
  - per cell: BlockIds.is_breakable(old), and for non-air ids PlacementRules.can_place against _player_bodies() plus the bot_friends group;
  - no reach check;
  - in Survivor, a gather_ledger(peer, false) that reserves the chunk, then pays per cell;
  - world.set_blocks(ok cells), then ledger.changed(old, new) for each returned entry;
  - if the ledger has a message, send_feedback;
  - returns the entries;
  - no progress_placed.
- func host_rocket_built(peer_id, step, text): _send_undo_step(peer_id, step) as one undo step (session.gd:166-172), then rocket_build_done to the requester (emit locally or _rpc_rocket_build_done.rpc_id).

4) Sandbox (scenes/sandbox.gd, inside _setup_launch_site :901-946, beside the board hooks :925-944).
- board.build = func(w: int) -> String: Session.request_rocket_build(w); return ""
- On the host only (not is_client()):
  - Session.rocket_build_requested.connect(_on_rocket_build_requested)
  - launch_site.build_stage.connect: Session.send_feedback(id, words) for the host's own id and every peer, plus ReadAloud.speak(words) (ui/progress/read_aloud.gd:90) on the requester's device, so the line is spoken even when Read to me is off; hud.toast only reads with Read to me (hud.gd:149-153).
  - launch_site.build_done.connect: Session.host_rocket_built.
- New func _on_rocket_build_requested(peer_id: int, world: int):
  - p = Session._player_for_peer(peer_id);
  - require LaunchSite.near_board(launch_site.site, p.global_position), with slack;
  - require mission_gate() == "" (:950);
  - require no crew call or flight active;
  - m = MissionRules.for_world(world);
  - plan = RocketPlan.for_mission(m, 1 + multiplayer.get_peers().size()), turned by launch_site.site.facing if wanted;
  - why = launch_site.build(plan, peer_id); if why != "", send_feedback(peer_id, why).
- On every game: Session.rocket_build_done.connect reopens launch_site.board with open() then show_page(MissionBoard.ROCKET_PAGE). On a guest, wait until read_pad holds the plan.
- Optional: turn the requester's camera (player.rig.yaw/pitch, entities/player/camera_rig.gd:14-15) towards LaunchSite.to_world_point(site, Vector2.ZERO, pos.y + 6).

5) MissionBoard (ui/missions/mission_board.gd).
- var build: Callable = func(_world: int) -> String: return ""
- var build_button: Button "BUILD IT FOR ME", created in _build() and added to both kept-across-pages lists (:136, :357).
- func press_build() -> String:
  - gate first, as press_launch does (:210-214);
  - why = build.call(int(mission.world));
  - "" → close(), so the child watches the rocket grow;
  - else _say(why).
- Shown on _rocket_page (:426-456) next to CHECK AGAIN and LAUNCH, and on the empty-pad state.
- In Survivor it shows the bag shortfall (RocketParts.missing(plan count, have)). In the Sandbox it shows the plan's gold and puts BUY WHAT MY ROCKET STILL NEEDS on the same page (#98).

Timing: the Moon test rocket has 39 cells in 13 layers (largest 12 cells): about 5 s at 0.4 s a layer, plus 3 stage lines.

Fallback with no new RPC: the requester's device sends Session.request_set_blocks(layer) about every 0.4 s, or BlockInteractor.apply_edits(edits, false) (block_interactor.gd:344). Ledger, bodies and WorldSync work unchanged. The costs: one undo entry per layer, XP counted, a 32-block reach limit, and a guest building at its own seed-found site.

**Risks:**

- The pad not stamped yet: parts placed on the plaza before the host's natural check make LaunchSite.natural false. The site is then rejected and moved elsewhere (launch_director.gd:162-176; launch_site.gd:141-151). Refuse with 'The pad is still being made' until launch_site.stamped. A guest's stamped is always false (launch_director.gd:80-89), so only the host can decide; the guest's button must ask the host.
- Chunks not loaded or editable: set_block silently writes nothing (world_service.gd:155-157). set_blocks drops to cell by cell when the box isn't wholly editable and returns only the cells really changed (:357-366). LaunchDirector._loaded checks only 5 columns × 2 heights (launch_director.gd:179-189), the same corner-only check that flaked in test_world_bulk_edits (:22-34). The job must check each layer's cells with is_editable and compare set_blocks' returned entries with what it asked for, retrying the rest. A rocket up to 24 above the plaza can cross 2 vertical 16-blocks.
- A friend (or Pip, a bot friend) standing on the pad: the body check skips only the cells inside a body. That leaves holes, and the friend can be boxed in under the upper layers. Session._player_bodies covers spawned players only (session.gd:294-299); bot_set_blocks adds the bot_friends group (:1424-1425); animals are in no check. Pause the whole build while any body intersects the build box AABB(corner, (9, H, 9)), inflated about 0.3 for the host's lagging copy of a guest. Say 'Step off the pad: Mission Control is building!' once, and stop after about 15 s, sending the undo step for what was built.
- Multiplayer authority: never accept a cell list from a guest (any_peer RPC). Send the mission id; the host builds its own plan on its own site after LaunchSite.near_board on its copy of the guest's player. Ruling 10 (missions.md:118-119): a guest's site comes from the seed and can differ from the host's, so a guest's board, read_pad and view may be at another place. Fix it with this work (an RPC carrying meta.launch_site to guests).
- A new @rpc on the Session autoload changes its RPC table. There is no protocol or version check (none found in autoloads or net), so a guest on an older build (Android 1.0.x against a newer web build) could break every Session RPC. The client-driven fallback (request_set_blocks per layer) avoids new RPCs.
- Ordering on guests: WorldSync paces edits (one packet per guest per frame, held while the relay has a backlog, world_sync.gd:283-305), while the 'done' or feedback RPC goes at once. A guest's reopened MY ROCKET may read a partial rocket. Reopen when read_pad holds every plan cell, or after about 3 s, or have the player press CHECK AGAIN.
- Frame spikes: each changed cell costs its ~10 block_changed listeners 13-20 µs on a settled world and up to 0.4-0.9 ms while the world streams (docs/devlog/parts/m3-task-8.md:62), and phones are 3-5× slower. A full 81-cell layer could cost about 73 ms on a streaming PC. Write at most 16 cells a frame (Session.TOOL_CHUNK) or within 8 ms (TOOL_FRAME_MS), one layer about every 0.35-0.4 s. 40-230 parts then spread over 5-15 s, with 1-4 chunk remeshes per layer on worker threads. Budget: 30 FPS average, no frame over 100 ms (CLAUDE.md).
- Blocks already on the pad: a non-part block where a plan cell goes (a child's scaffolding or roof) must refuse with a count, never be broken. Leftover parts touching the plan would fuse into the rocket (find_rocket, rocket_check.gd:36-63) and break the check (extra mass, a 'blocked' engine): clear them (in Survivor they go back to the bag). A half-built rocket's identical cells are kept for free.
- Reach: _host_apply_batch uses BATCH_REACH 32 from the requester's eye (placement_rules.gd:8; session.gd:139-140), and the tool path uses 48 (power_tools.gd:16). From the board, a 30-layer rocket's top is 32 away and a 40-layer one 41. Placing through the existing request paths, and the later UNDO, fail for tall plans: keep plans at 24 layers or fewer and place through a host path with no reach check (gated by near_board).
- Undo semantics: one undo step for the whole rocket uses 1 of 20 slots. Per-layer requests (the client-driven fallback) would push 13+ entries and evict the child's own history (block_interactor.gd:12, 211-221). The tool path's undo has no ledger, so undone parts would be lost in Survivor.
- XP farming: placements through _host_apply(_batch) count progress_placed (session.gd:151, 2818-2822), so build, undo, build would pay XP. The builder must not call it, as the building tools don't (:3993).
- Survivor bag changes mid-build (trade, knock-out bag, a friend's request): reserve per slice and stop cleanly with the ledger's message. A guest can't buy in the host's world (sandbox.gd:969-971), so a guest whose bag is short is refused with the list of what it lacks.
- Crew or flight in progress: refuse while crew.call is active, a flight is active, or the board's LAUNCH is underway (sandbox.gd:1007-1009, 3800+). Plans should seat the crew present (1 + peers, up to 4: Session.MAX_CLIENTS 3), or the crew check says to add capsules (net_test.gd:128-140 shows a 2-seat variant).
- The board: closing it to show the animation sets LaunchDirector._dismissed (launch_director.gd:53), so it will not reopen by walking. Reopen it explicitly with board.open() and then show_page(ROCKET_PAGE) (open() starts on MISSIONS, mission_board.gd:91-109). A new button must be in the kept-across-pages lists (:136, :357) and reachable by controller (test_pad_screens.gd:361-386).
- LaunchDirector runs with process_mode ALWAYS (launch_director.gd:43-44), so a job ticking in its _process would carry on behind the solo pause menu. Skip build ticks while get_tree().paused.
- Plan validity: each mission's plan must be one connected piece standing on y 0, inside 9 × 9 × 64, and pass every RocketCheck line for its mission and crew. In the Sandbox the 'paid' line passes only once the parts are bought. Mars, Europa, Io, Titan and Mercury need many more parts (missions.md:78-80: Mercury about 230 parts, 6 stages, about 7,000 gold), which conflicts with the 24-layer limit unless the stages are built wide.
- Water and plants on the pad: treat water as empty (PowerTools.is_empty). Placing a part next to water triggers water flow through block_changed listeners.

**Existing tests to extend:** tests/unit/test_rocket_check.gd (14 tests): _column and _moon_rocket (:32-67, 39 parts, 13 layers, 3 stages), lift-off, rocket equation, stages, crew lines, find_rocket keeping only the biggest piece (:223), the Sandbox 'paid' line (:235), description (:247). A plan's pass or fail must agree with these.; tests/unit/test_rocket_parts.gd (6): masses, prices, missing/count/cost, craft_words.; tests/unit/test_mission_rules.gd (6) and tests/unit/test_mission_star_map.gd (5): MISSIONS, need km/s, route, MissionData.add_part/owned/fly.; tests/unit/test_launch_site.gd (10): pick, pad_changes (concrete and stripes :106), natural/clear_changes never over a child's build (:132), board position facing the spawn (:153), save round trip (:166).; tests/unit/test_rocket_blocks.gd (7): page 32 ids 560-573.; tests/unit/test_gold_shop_rocket_shelf.gd: the Gold Shop's rocket shelf on RocketParts.PRICES.; tests/unit/test_crew_flight_rules.gd: crew seat rules. tools/net_test.gd:128-140 crew_rocket is the 2-seat Moon rocket.; tests/integration/test_launch_director.gd (6): FakeWorld with box_reader, is_editable and set_blocks (:11-37); site found and pad stamped once (:70); saved site; never over a build (:100); a guest never stamps (:113-118); walking up opens the board (:121); read_pad relative to the corner (:140-150). The model for a host build-job test (inject FakeWorld and run d._process).; tests/integration/test_mission_board.gd (9): fake hooks (:18-42), pages, check, test_sandbox_buys_the_missing_parts_then_launches (:115), gold refusal (:136), test_survivor_has_no_bought_line (:148), empty pad and refused launch (:156), Esc/X, star map button.; tests/integration/test_pad_screens.gd:361-386 test_the_mission_board_s_pages_can_be_reached_and_circle_closes_it: every button on each of the 3 pages must be reachable with a controller (_unreachable(board) == []). A new BUILD IT FOR ME button must pass this.; tests/integration/test_crew_board_badges.gd and tests/integration/test_invention_missions.gd: the board's crew badges and the Survivor gate (the rocket invented first).; tests/integration/test_crew_flights.gd, test_crew_session.gd, test_crew_flight_follow.gd: the crew call and the origin from the pad (test_crew_flights.gd:108, 194, 370).; tests/integration/test_rocket_flight.gd, test_flight_cockpit.gd: the flight of the description; tests/unit/test_flight_*.gd (RocketStages.MAX_CELLS 4096).; tests/integration/test_world_bulk_edits.gd (3): real terrain set_blocks/blocks_at bulk path, every cell announced, scattered cells and a box not all loaded go cell by cell. Its before_all waits for _region_editable over the whole region sampled every 8 cells (:22-34; the lead's 2026-10-01 fix: corners alone missed a chunk about 1 run in 3).; tests/integration/test_build_tool_session.gd (12+): EditWorld extends WorldService (:12-28), real Player instancing (:69-77), slicing of big jobs (:193, :217), into-empty/reach/body checks (:244), a guest's requests checked where the host sees the guest (:261), at most two jobs (:314). The model for a Session-level host_rocket_cells test.; tests/integration/test_edit_undo.gd: skipped cells are not in the undo step (:147); cells an undo could not restore are kept (:162); the host sends a LAN client its step (:204-228); only the local player records steps (:238).; tests/integration/test_survivor_gathering.gd: placing takes one (:148), refusal message (:155), a stamp built whole or not at all (:208), undoing returns blocks (:292, :335), Sandbox never counts (:368), host sends a LAN player its inventory (:395).; tests/unit/test_undo_stack.gd, tests/unit/test_power_tools.gd: the 20-entry stack and PowerTools caps and reach.; tools/mission_smoke.gd + tools/mission_smoke_steps.gd (run with XDG_DATA_HOME containing 'smoke'): waits up to 60 s for the stamp (step 1); writes moon_rocket at corner + rel with p.world.set_blocks (step 3, :141-146); expects 3 stages and 10 kinds missing; BUY WHAT MY ROCKET STILL NEEDS; LAUNCH to the Moon; home with the rocket still on the pad (:195-196); Survivor buys into the bag (step 6). The natural place for a BUILD IT FOR ME smoke step.; tools/launch_shots_steps.gd:49-54 and tools/net_test.gd:685-705 (--crew): place the rocket the same way (world.set_blocks at corner + rel). net_test is the place for a guest BUILD request over LAN and online.

## The design to settle on resume (the lead's proposal, not built)
1. **Mission Control's ready plan per mission** (`RocketPlan`, precomputed, a GUT test checks every mission × crew with the
   real RocketCheck): BUILD IT FOR ME on MY ROCKET builds it on the pad layer by layer (host-authoritative, ≤ 16 cells a
   frame, a spoken line per stage), keeps a half-built rocket's matching cells, never breaks a child's other blocks.
2. **Buying in one place:** the "Buy the parts you don't have yet" line gets its button right there (BUY THE PARTS FOR THIS
   ROCKET: n gold, with a confirmation), the gold still needed said plainly with where to earn it; the same in Survivor
   (into the bag); plurals; the board reopens on MY ROCKET after a check.
3. **Make far rockets sane** (the strongest lever found): supplies scale so far missions are not 100-400 parts (e.g. one
   service module per astronaut for any trip, recycling air and water as real ships do), and a price review so the Moon is
   about a day or two of learning; Mercury's speed stays the hard one.
4. **Fix the six bugs** above (Gold Shop parts never reach a Survivor bag; friend presents; two devices' parts merge; a
   friend's bulk buy; the page jumping to the top; a stale bulk price).
5. Wayfinding to the Launch Site (MY MAP, /find launch), the mission card listing every need, LAUNCH saying why it is grey.

## As built (2026-10-15; brief `docs/superpowers/plans/2026-10-15-rocket-easier-brief.md`)

Branch `worktree-agent-a54df1abfad5b20d7` (from `lead-merge` at 177adc11). Nothing merged or pushed.

### What a child does now, from the Star Map to LAUNCH
1. **The Star Map:** tapping the Moon opens its card: "Mission needed: build a rocket at the Launch Site" and, on its
   hint line, "Follow the arrow: the Launch Site is 32 blocks away." while the find arrow points at the Mission Board
   (`travel_to_space` answers the same if asked). The Launch Site is on MY MAP from the start (a rocket badge), and
   `/find launch` points there too.
2. **The Mission Board** opens on MISSIONS (on MY ROCKET when the pad already holds rocket parts). The Moon's card lists
   every rule the check asks for and says "Mission Control's plan: 36 parts, 450 gold." (for the crew here: with two
   friends, the plan for three).
3. **MY ROCKET** on an empty pad: "Build a rocket on the pad…", the plan's line and **BUILD IT FOR ME**. Tapping it closes
   the board: "Mission Control is building your rocket for the Moon: watch the pad!". The rocket grows from the pad up, a
   layer about every 0.4 s (5 s for the Moon), with a caption and a spoken line per stage: "Stage 1: 7 rocket engines and
   9 fuel tanks lift everything.", "Stage 2: 2 space engines and 4 fuel tanks fire when stage 1 drops away.", "Stage 3,
   the lander: 1 space engine and 1 fuel tank land the crew; 1 crew capsule, 1 service module, 3 landing legs and 1
   solar array keep them safe, under a nose cone.", then "Your rocket for the Moon is ready! Check it, then LAUNCH." and
   the board opens again on MY ROCKET. (A child standing on the pad hears "Step off the pad: Mission Control is
   building!" and the build waits; a child's own blocks where the rocket goes are never broken: "3 blocks stand where the
   rocket goes: move them off the pad first.")
4. **Sandbox:** every line is green but the paid one ("Buy the parts you don't have yet: 7 rocket engines, 2 space
   engines, … (450 gold).") with **BUY THE PARTS FOR THIS ROCKET: 450 gold** right under it. A card asks "Buy 36 parts
   for 450 gold? 7 rocket engines, …" YES / NO. Too little gold: "You have 120 gold: 330 more to go. A School unit
   mastered gives 100 gold." **Survivor** (the rocket invented first; Tilly now sells kerosene): BUILD IT FOR ME says
   "Your bag needs 7 rocket engines, … first: BUY THE MISSING PARTS." and **BUY THE MISSING PARTS: 450 gold** (the same
   card) puts them into the bag; BUILD IT FOR ME then takes them from the bag.
5. **LAUNCH TO THE MOON!** Before that, the grey button reads "NOT YET: 1 LINE TO FIX" and tapping it says "Not yet: 1
   line to fix. First: Buy the parts you don't have yet: …".

### Mission Control's plans (parts and gold per mission and crew; prices below)
The table as `tools/make_rocket_plans.gd` printed it (E rocket engines, V space engines, T fuel tanks; each stage also
has its separator, stage 1 its 3 fins, the lander its payload). Every plan passes the real check for its mission and
crew with its parts bought (`test_rocket_plan.gd`).

| Mission | Crew | Parts | Gold | Over the need (km/s) | Layers | Stages | Stages from the bottom |
|---|---|---|---|---|---|---|---|
| moon | 1 | 36 | 450 | 0.11 | 12 | 3 | 7E+9T / 2V+4T / 1V+1T |
| moon | 2 | 47 | 645 | 0.08 | 16 | 4 | 9E+10T / 3V+6T / 1V+1T / 1V+1T |
| moon | 3 | 56 | 835 | 0.10 | 18 | 4 | 10E+7T / 5V+10T / 2V+3T / 1V+1T |
| moon | 4 | 66 | 1025 | 0.08 | 16 | 4 | 12E+5T / 7V+15T / 2V+4T / 1V+1T |
| mars | 1 | 45 | 615 | 0.12 | 16 | 4 | 8E+5T / 4V+9T / 1V+1T / 1V+1T |
| mars | 2 | 61 | 825 | 0.09 | 18 | 4 | 12E+15T / 4V+9T / 1V+1T / 1V+1T |
| mars | 3 | 70 | 1040 | 0.09 | 18 | 4 | 13E+8T / 7V+15T / 2V+4T / 1V+1T |
| mars | 4 | 85 | 1270 | 0.05 | 20 | 4 | 17E+14T / 8V+17T / 2V+4T / 1V+1T |
| europa | 1 | 69 | 955 | 0.08 | 22 | 5 | 14E+10T / 7V+15T / 2V+3T / 1V+1T / 1V+1T |
| europa | 2 | 97 | 1360 | 0.06 | 21 | 5 | 21E+20T / 9V+18T / 3V+6T / 1V+1T / 1V+1T |
| europa | 3 | 122 | 1785 | 0.06 | 23 | 6 | 26E+23T / 12V+23T / 4V+6T / 2V+3T / 1V+1T / 1V+1T |
| europa | 4 | 154 | 2200 | 0.07 | 23 | 6 | 35E+40T / 13V+26T / 4V+6T / 2V+3T / 1V+1T / 1V+1T |
| io | 1 | 77 | 1060 | 0.09 | 24 | 5 | 16E+12T / 8V+18T / 2V+3T / 1V+1T / 1V+1T |
| io | 2 | 108 | 1525 | 0.07 | 22 | 5 | 24E+20T / 11V+24T / 3V+6T / 1V+1T / 1V+1T |
| io | 3 | 138 | 1990 | 0.05 | 23 | 6 | 31E+30T / 13V+26T / 4V+6T / 2V+3T / 1V+1T / 1V+1T |
| io | 4 | 164 | 2445 | 0.06 | 21 | 6 | 36E+24T / 19V+41T / 5V+9T / 2V+3T / 1V+1T / 1V+1T |
| titan | 1 | 58 | 790 | 0.06 | 20 | 4 | 11E+11T / 5V+9T / 2V+3T / 1V+1T |
| titan | 2 | 75 | 1080 | 0.08 | 19 | 4 | 15E+9T / 8V+18T / 2V+4T / 1V+1T |
| titan | 3 | 95 | 1355 | 0.06 | 23 | 5 | 20E+20T / 8V+18T / 2V+3T / 1V+1T / 1V+1T |
| titan | 4 | 111 | 1645 | 0.06 | 22 | 5 | 23E+18T / 11V+24T / 3V+6T / 1V+1T / 1V+1T |
| mercury | 1 | 220 | 3090 | 0.05 | 24 | 6 | 53E+44T / 25V+56T / 6V+12T / 2V+3T / 1V+1T / 1V+1T |
| mercury | 2 | 308 | 4395 | 0.05 | 24 | 7 | 75E+68T / 33V+71T / 9V+15T / 4V+6T / 2V+3T / 1V+1T / 1V+1T |
| mercury | 3 | — | — | — | — | — | no plan |
| mercury | 4 | — | — | — | — | — | no plan |
| venus | 1 | 29 | 380 | 0.14 | 17 | 3 | 4E+3T / 2V+4T / 1V+1T |
| venus | 2 | 38 | 515 | 0.11 | 13 | 3 | 6E+8T / 2V+4T / 1V+1T |
| venus | 3 | 46 | 670 | 0.10 | 15 | 3 | 8E+8T / 3V+6T / 1V+2T |
| venus | 4 | 53 | 800 | 0.11 | 15 | 3 | 9E+8T / 4V+9T / 1V+2T |
| rings | 1 | 83 | 1130 | 0.07 | 21 | 5 | 18E+16T / 8V+18T / 2V+3T / 1V+1T / 1V+1T |
| rings | 2 | 116 | 1630 | 0.07 | 22 | 5 | 26E+22T / 12V+27T / 3V+6T / 1V+1T / 1V+1T |
| rings | 3 | 145 | 2120 | 0.06 | 23 | 6 | 32E+27T / 15V+29T / 5V+9T / 2V+3T / 1V+1T / 1V+1T |
| rings | 4 | 186 | 2615 | 0.05 | 23 | 6 | 44E+51T / 16V+35T / 4V+6T / 2V+3T / 1V+1T / 1V+1T |
| pluto | 1 | 70 | 985 | 0.05 | 19 | 4 | 14E+7T / 8V+18T / 2V+4T / 1V+1T |
| pluto | 2 | 97 | 1335 | 0.09 | 23 | 5 | 21E+23T / 8V+18T / 2V+3T / 1V+1T / 1V+1T |
| pluto | 3 | 119 | 1695 | 0.06 | 23 | 5 | 26E+25T / 11V+24T / 3V+6T / 1V+1T / 1V+1T |
| pluto | 4 | 138 | 2075 | 0.06 | 22 | 6 | 29E+20T / 15V+32T / 4V+6T / 2V+3T / 1V+1T / 1V+1T |
| triton | 1 | 64 | 905 | 0.05 | 23 | 5 | 12E+6T / 7V+15T / 2V+3T / 1V+1T / 1V+1T |
| triton | 2 | 92 | 1255 | 0.08 | 24 | 5 | 20E+24T / 7V+15T / 2V+3T / 1V+1T / 1V+1T |
| triton | 3 | 116 | 1620 | 0.06 | 22 | 5 | 26E+31T / 9V+18T / 3V+6T / 1V+1T / 1V+1T |
| triton | 4 | 138 | 1980 | 0.06 | 23 | 5 | 31E+30T / 13V+30T / 3V+6T / 1V+1T / 1V+1T |
| ganymede | 1 | 49 | 680 | 0.06 | 17 | 4 | 9E+5T / 5V+10T / 2V+3T / 1V+1T |
| ganymede | 2 | 68 | 975 | 0.09 | 17 | 4 | 14E+9T / 7V+15T / 2V+4T / 1V+1T |
| ganymede | 3 | 85 | 1245 | 0.06 | 20 | 5 | 17E+11T / 9V+21T / 2V+3T / 1V+1T / 1V+1T |
| ganymede | 4 | 104 | 1540 | 0.06 | 21 | 5 | 22E+18T / 10V+21T / 3V+6T / 1V+1T / 1V+1T |

For one astronaut: Venus 380, the Moon 450, Mars 615, Ganymede 680, Titan 790, Triton 905, Europa 955, Pluto 985, Io
1,060, Saturn's rings 1,130, Mercury 3,090 (the dearest: its 24.3 km/s). Before (the understanding phase's cheapest at
the old prices): Moon 940, Mars 1,485, Triton 8,945, Mercury 6,680; the far worlds took 113-277 parts for one
astronaut, now 49-220.

### The prices (owner #98: halved, multiples of 5, at least 5)
| Part | Before | Now |
|---|---|---|
| Rocket Engine | 50 | 25 |
| Space Engine | 60 | 30 |
| Fuel Tank | 15 | 5 |
| Nose Cone | 10 | 5 |
| Crew Capsule | 80 | 40 |
| Service Module | 40 | 20 |
| Heat Shield | 40 | 20 |
| Landing Legs | 15 | 5 |
| Rocket Fins | 5 | 5 |
| Stage Separator | 10 | 5 |
| Solar Array | 20 | 10 |
| Parachute Pack | 30 | 15 |

`SpendRules.GUIDE` = {first_part: 40 (the dearest part), moon_rocket: 450, mars_rocket: 615}; `test_rocket_plan.gd`
keeps it equal to the plans.

### Rulings (each with what it costs if wrong)
1. **Supplies per astronaut** (the lead's): `RocketParts.keeps` 1 replaces "200 days" (`crew_days` is gone); the check
   wants a service module per astronaut on the top stage, whatever the trip; the line and the card still say the real
   trip. Even the Moon's 3 days now wants one module each for a crew of 4. *Cost:* less real about food on 12-year trips;
   one constant and the check's line.
2. **Prices: 7.5 rounds down to 5** (tank and legs), one rule both ways; the Moon's plan lands at 450 (the brief: about
   400-550). Tanks at 10 gave 530 for the Moon and 3,660 for Mercury. *Cost:* the economy a little easy; one table, then
   re-run the generator (the test fails until then).
3. **The search** (`tools/rocket_plans_search.gd`): the cheapest by the check's own sums, 2-8 stages, space engines only
   above stage 1 (the understanding phase found mixes never cheaper), the fewest engines per stage, stage 1 at most 78
   engines so its 3 fins fit round them in the pad's layer, 0.05 km/s margin. Many plans end with one or two little
   stages of 1 space engine and 1 tank: the real optimum of the rocket equation with these parts. *Cost:* a child may
   find the little top stages odd; a minimum stage size in the search.
4. **The layout** (`RocketPlan.layout`, the same code the generator verified): about 3 tank layers per stage, round
   layers (a plus, a 3 × 3, …) never wider than the stage below; each separator alone in the middle of its own layer (a
   visible waist between stages); a plan too tall for 24 layers gets fewer, wider tank layers, then its separators in
   the middle of the stage's top tank layer. *Cost:* some upper stages overhang their separator (the check allows it: an
   engine is blocked only by its own stage under it).
5. **Mercury with 3 or 4 astronauts has no plan** (24.3 km/s needs more than the 78 first-stage engines; searched to 8
   stages). The card and MY ROCKET say "Mission Control has no plan for a crew of 3 to Mercury yet: a rocket that big
   doesn't fit on the pad. Try fewer astronauts!". *Cost:* those crews can't fly to Mercury (no rocket on this pad could).
6. **BUILD IT FOR ME is the host's only** (a guest gets LAUNCH's words, as the brief says), so no new RPC (no protocol
   risk for older builds): `LaunchDirector.build` writes on the host, WorldSync carries the blocks, friends get the lines
   as toasts (`Session.send_feedback`). No XP, no undo step (the child's 20 steps stay theirs).
7. **It clears every stray rocket part in the 9 × 9 build box** (from the pad to 64 up), not only those touching the
   plan: a leftover piece could otherwise be "the biggest piece" the check reads. Sandbox: gone; Survivor: back into the
   bag (the ledger). A child's other blocks are never touched; one where the rocket goes refuses the build with a count.
   *Cost:* a second little rocket a child kept on the same pad is cleared.
8. **The spoken line per stage uses `ReadAloud.speak`** (it speaks even with Read to me off: the brief asks for a spoken
   line). *Cost:* 4-8 short lines for a child who wanted quiet; one call to change to `auto`.
9. **It waits while someone stands in the build box** (players and bot friends; said once), while a chunk isn't loaded,
   and while the game is paused; after 30 s it stops: "Mission Control stopped: the pad never cleared. Press BUILD IT
   FOR ME again." (pressing again finishes it: the right cells are kept).
10. **One purchase, both pots:** a part from the Gold Shop or a friend's present counts for the Sandbox's rockets
    (`MissionData`) and waits in the backpack for the next Survivor world's bag (bugs 1 and 2; the shop and the present
    say so). *Cost:* a cheap part counted twice; one line in `RocketParts.grant`.
11. **Two devices** (bug 3): each install counts its own purchases under a random key (`user://rocket_parts_device.json`,
    never the sign-in id); a merge keeps the bigger count per device, the total is the sum. A copy from an older game
    (a total only) merges into `older` minus this copy's purchases (an older game may have read our total). *Cost:* an
    account mixing old and new builds can be off by what the old build bought; old builds go with the update.
12. **A friend's bulk buy is refused** (bug 4: "This rocket is your friend's: they buy its parts. Parts you buy on PARTS
    are for your own rockets."): the host's pad is paid by the host's profile; paying across profiles would need the
    server. Single BUYs on PARTS still buy for the friend's own rockets.
13. **Kerosene at Tilly's** (her HOME shelf, 10 gold in the first universe, × 2 per universe like everything; she buys
    it back for 6): the jet and the rocket need 2 each, so 40 gold, no Golem, no Desert. The Desert's oil stays the free
    way and the invention book says both. *Cost:* the oil quest loses one reason; one line in `ShopRules.HOME_PRICES`.
14. **The board opens on MY ROCKET when the pad holds rocket parts**, else on MISSIONS; a grey LAUNCH can be pressed and
    says how many lines to fix and the first.
15. **The mission card lists every rule** (`MissionRules.needs_words`: engines and 3 fins, stages and separators, a
    capsule and a module each, the top stage's engine, fuel, legs and solar array, a pointed top) and the plan's size and
    gold.
16. **Shorts:** the "build a rocket" Short (`core/shorts/studio/studio_rockets.gd`: 55 parts, about 685 gold now) is left
    for the reels agent to align with the plan (36 parts, 450 gold). The `crew_flight` Short's supplies scene taught the
    old 200-day sums and its test pinned them: rewritten minimally ("To Mars: 210 days. One service module keeps one
    astronaut the whole way."; two modules, one each); its closing puzzle (three friends) still asks, answer 3.
17. The 2-seat crew rocket of `tools/net_test.gd` (`crew_rocket`, used by the crew tests) is now Mission Control's plan
    for two (it had one service module for two).

### What the lead must check
- **BUILD IT FOR ME's frame times on the emulator** (budget: 30 FPS, no frame over 100 ms). Headless on this PC, with
  the world still streaming round the teleported child (three runs): the Moon's 36 parts stood in 5.0-5.2 s; frames
  while building median 7-25 ms, slowest 70-149 ms; Mission Control's own slowest write (16 cells and their world
  updates) 5.4-6.3 ms, so the slow frames are the streaming, not the build (phones 3-5× slower: 16-32 ms a write). The biggest layers are the far plans' first
  (Mercury crew 2: 75 engines and 3 fins, 5 frames of 16 cells); a layer every 0.4 s.
- **The board on a phone:** MY ROCKET is longer (the plan's line, BUILD IT FOR ME, the buy buttons); the buy card (720 px
  wide, YES / NO) at a phone's scale and with a controller (it takes the focus on YES; Back, B or Esc closes the card
  first).
- **With friends** (`tools/net_test.sh --crew`, which now builds the 2-seat plan): the stage lines arrive as toasts on a
  friend's game; the blocks through WorldSync.
- Owner feedback #98's row in `docs/playtests/owner-feedback.md`: mark it with the tests below.

### Files
New: `core/rules/rocket_plan.gd` (RocketPlan), `tools/make_rocket_plans.gd`, `tools/rocket_plans_maker.gd`,
`tools/rocket_plans_search.gd`; tests `tests/unit/test_rocket_plan.gd`, `test_rocket_parts_two_devices.gd`,
`test_rocket_presents.gd`, `test_rocket_kerosene.gd`, `tests/integration/test_mission_board_buy.gd`,
`test_launch_build.gd`. Changed: `core/rules/rocket_parts.gd`, `rocket_check.gd`, `mission_rules.gd`, `mission_data.gd`,
`chat_commands.gd`; `core/economy/spend_rules.gd`, `earn_rules.gd`, `shop_rules.gd`; `core/social/friend_presents.gd`;
`core/inventions/invention_line.gd` (the kerosene hint); `ui/missions/mission_board.gd`;
`entities/launch/launch_director.gd`; `scenes/sandbox.gd` (the section "Owner #98" after `buy_rocket_part`, the board's
hooks, `travel_to_space`'s hint, `_on_star_map_body` connected in `_space_local`); `scenes/chat_command_runner.gd` (/find launch); `ui/map/world_map_panel.gd` (the rocket
badge); `ui/shop/gold_shop.gd` (where a part went); `data/shorts/crew_flight.json`; `tools/mission_smoke_steps.gd`,
`tools/net_test.gd`. Tests adjusted to the new rules: `test_rocket_check`, `test_rocket_parts`, `test_spend_rules`,
`test_short_library`, `test_crew_flight_rules`, `test_triton_universe`, `test_refining`, `test_chat_commands_more`,
`test_chat_commands_run`, `test_mission_board`, `test_invention_missions`. Nothing of the player, the camera, the input
map, `ui/hud/*` or `ui/menus/*` was touched.

### Checks
- The new and changed tests: pass. The missions smoke (`tools/smoke_all.sh mission`): 0 fails (BUILD IT FOR ME on real
  terrain in about 5 s, the card buy, LAUNCH to the Moon and home, the Gold Shop's tanks in the Survivor bag).
- The full suite (once, on 84dac696): 9,815 tests, 9,810 passing, 3 failing, 11 risky or pending (the Nakama tests
  without a server and two old tests that assert nothing: none of this work's). The 3 were this work's and are fixed
  after it: `test_girl_avatars` (the backup must carry no `"base"` key: MissionData's old-copy field is now `older`),
  `test_m3_review_plurals` (the Launch Site's distance through `Lang.blocks`), `test_short_quality` (the crew_flight
  scene's two "1 astronaut" labels overlapped: moved apart). Those files and their neighbours (backup, MissionData,
  Shorts): 94 of 94 pass. The missions smoke on 84dac696: 0 fails.

