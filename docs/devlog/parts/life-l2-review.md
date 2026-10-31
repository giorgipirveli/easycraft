# Life L2: the review sheet for the experts (owner #112)

Written by `tools/life_review_sheet.py` from the Experiences' own data (`data/life/experiences/*.json`): exactly what the game shows and reads aloud. `{number}` is shown as 112 (Georgia's and Europe's number: the game uses the region a grown-up sets). Please mark each step: right / change it to ... / remove it. Every Experience says it is practice; the kerb drill and the street's sign are shown as Georgia's (the game follows the grown-up's region: "right, left, right" where cars drive on the left, 20 mph in the UK and the US); a car stops gently for a child who steps out when it isn't safe; nothing a child picks in Calm Corner is kept. Each hands-on step names its real motion (owner #117: one of strike, stroke, twist, squeeze, press, spread, measure, pour, aim, cut), the thing in the hand, and the device it uses.

The Kitchen's recipes (they vary with each try's seed: `core/life/life_kitchen.gd`): Little a rainbow fruit salad, raita (India), Bircher muesli (Switzerland), a cucumber and tomato salad (Georgia); Middle pancakes (the UK and France), an omelette (France), fried rice (China), porridge (Scotland); Big lentil dal (India), shakshuka (Tunisia), jollof rice (West Africa), pasta with tomato sauce (Italy). The cup's amount is a quarter, a half or three quarters.

## Safe Streets

For the review by a road safety officer (the national road safety authority; the WHO's pedestrian safety manual).

The device **crossing** (owner #117, the device model): controls: the button on the pole. It shows: WAIT; the red man; the green man; the green man flashing. The right order: press the button → wait for the green man → look both ways: have the cars stopped? → cross while the green man shows → keep looking and listening as you cross. Safety: never cross on the red man; the green man flashing: don't start to cross; even on green, check the cars have stopped.
The device **seat_belt** (owner #117, the device model): controls: the belt; the buckle. It shows: the click. The right order: sit in your seat (a booster seat for children) → pull the belt across you → push it into the buckle: click → over the shoulder, low across the hips. Safety: every seat, every trip; never under the arm or behind the back; children in the back seat.
The device **helmet** (owner #117, the device model): controls: the straps; the buckle. It shows: the click; the fit. The right order: level on the head → two fingers above the eyebrows → the straps make a V under each ear → buckle it: one finger fits under the strap. Safety: a helmet for every ride; not tipped back; a new helmet after a crash.
The device **car** (owner #117, the device model): controls: the steering wheel; the accelerator; the brake; the seat belt. It shows: the speed; the traffic lights ahead. The right order: seat belt on → check everyone's belt → stop at red → give way to people crossing → keep to the speed limit. Safety: never a phone while driving; slower near schools and homes; give cyclists plenty of room.

### Little (about 6-8): Stop, look and listen

The Expert try's twist: A car is hidden round the bend: listen for it. And no glow shows you when it is safe.

Steps:

- **hello**: words, then OK
  - Coach: "This is the practice street. Real cars drive here at real speeds, but this is practice. Gus the grown-up buddy will cross with you."
- **hand**: hold it `gus_hand` (motion squeeze, seconds 1.5)
  - Coach: "Near roads, hold a grown-up's hand. Hold Gus's hand."
  - After: "Holding hands: safe and together."
- **kerb**: go there `kerb`
  - Coach: "Walk to the kerb, the edge of the pavement, and stop just before it."
  - After: "Stop! You stopped at the kerb."
- **look**: look both ways (VR: the head turns) (sides left, right, left)
  - Coach: "Look all around: left, right, left. The nearest cars come from the left."
  - After: "You looked left, right, left. Looking is how you stay safe."
- **listen** (Expert try only): pick a picture
  - Coach: "Shh... listen. Can you hear a car coming round the bend?"
  - Picture (ear) right: "Yes: I wait"
  - Picture (run) not this one: "No car: I go": "Listen again: you can hear an engine. Wait until it has gone."
  - After: "You listened. Your ears help your eyes."
- **listen_now** (normal try only): pick a picture
  - Coach: "Now listen. Cars make a noise. What do you do while you listen?"
  - Picture (stand) right: "Stand still at the kerb"
  - Picture (run) not this one: "Run across": "Never run across. Stand still at the kerb and listen."
  - After: "Standing still and listening: well done."
- **cross** (normal try only): cross only when it is safe (a car stops gently if not) `far_kerb` (reach trigger)
  - Coach: "Wait until there is a big gap and no car is coming. Then cross with Gus."
  - A miss: "Wait! A car is coming. The car stops. Step back and wait for a big gap."
  - After: "You waited for a big gap. Walk straight across, keep looking and listening."
- **cross** (Expert try only): cross only when it is safe (a car stops gently if not) `far_kerb` (reach trigger, no glow)
  - Coach: "Now you judge the gap: wait until no car is coming, then cross with Gus."
  - A miss: "Wait! A car is coming. The car stops. Step back and wait for a big gap."
  - After: "You judged the gap by yourself. Walk straight across, keep looking and listening."
- **across**: words, then OK
  - Coach: "Across! Walk, don't run, and keep looking and listening while you cross."
- **ball** (Expert try only): pick a picture
  - Coach: "Oh! A ball rolls into the road. What do you do?"
  - Picture (grown_up) right: "Stay on the pavement and ask a grown-up"
  - Picture (run) not this one: "Run after it": "Never run into the road after a ball. A grown-up can get it safely."
  - After: "Stay on the pavement. A grown-up gets the ball."
- **to_car**: words, then OK
  - Coach: "Now the car. It is parked at the kerb with its back door open. Let's practise getting in safely."
- **where**: pick a picture
  - Coach: "Where do children sit in a car?"
  - Picture (booster) right: "In the back, in a booster seat"
  - Picture (front_seat) not this one: "In the front": "Children are safest in the back seat, in a child seat or a booster seat."
  - After: "In the back, in your booster seat."
- **sit**: touch it `booster`
  - Coach: "Climb in and sit in the booster seat."
  - After: "Sitting back in the booster seat."
- **belt**: press in order `belt_top, belt_buckle` (motion stroke, device seat_belt)
  - Coach: "Pull the belt across you and push it into the buckle."
  - After: "Click! The belt is on."
- **belt_where**: pick a picture
  - Coach: "Where does the belt go?"
  - Picture (belt_good) right: "Over the shoulder, low on the hips"
  - Picture (belt_neck) not this one: "On the neck": "Not on the neck: the belt goes over the middle of your shoulder."
  - Picture (belt_arm) not this one: "Under the arm": "Never under the arm. Over the shoulder and across the chest."
  - After: "Over the shoulder, low across the hips. A booster seat makes it fit."
- **end**: words, then OK
  - Coach: "You did it! Stop at the kerb, look and listen, wait for a big gap, cross with a grown-up, and belt up in the back."

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "You want to cross the road. Where do you stop?" **At the kerb** / In the road / I don't stop
- "At the kerb, what do you do?" **Look and listen** / Run across
- "When do you cross?" **When there is a big gap** / When a car is near
- "Who do you cross with?" **A grown-up** / On my own
- "Where do you sit in a car?" **The back, in a booster** / The front

The "name it" card: **Stop, look, listen, think**

1. Hold a grown-up's hand near roads.
2. Stop at the kerb.
3. Look left, right, left, and listen.
4. Wait for a big gap, then walk straight across.
5. In the car: the back seat, a booster seat, belt on.

Its source line: The road safety authorities' advice (the WHO, the UK's Green Cross Code, the US NHTSA)

Try it for real: With a grown-up, on a quiet street: stop at the kerb together, look left, right, left and listen. Show your grown-up how you wait for a big gap. In the car, show them how your belt fits.

Your child can now: stop at the kerb, look left, right, left and listen, and wait for a big gap before crossing with a grown-up

Sources:

- [ ] The Green Cross Code: think, stop at the kerb, look all around and listen, wait until it is safe, look and listen as you cross; young children cross with a grown-up. (The Highway Code (UK), rules for pedestrians, Rule 7 and Rules 4-6): https://www.gov.uk/guidance/the-highway-code/rules-for-pedestrians-1-to-35
- [ ] Children ride in the back seat, in a car seat or a booster seat until the adult belt fits: the shoulder belt across the shoulder and chest, not the neck; the lap belt low on the hips and upper thighs, not the stomach. (NHTSA, car seats and booster seats): https://www.nhtsa.gov/vehicle-safety/car-seats-and-booster-seats
- [ ] Road traffic injuries are among the biggest dangers to children and young people worldwide; children walking near traffic are among the most at risk. (WHO, road traffic injuries fact sheet): https://www.who.int/news-room/fact-sheets/detail/road-traffic-injuries
- [ ] Practising street crossing in virtual reality improved children's crossing behaviour after several short sessions. (Schwebel et al., randomized trials of VR pedestrian training): https://pmc.ncbi.nlm.nih.gov/articles/PMC4990383

### Middle (about 9-11): Crossing alone, at night and on a bike

The Expert try's twist: The green man starts to flash just as you get there, and at night a car comes fast.

Steps:

- **hello**: words, then OK
  - Coach: "The practice street again: you cross alone today. A van is parked here. Drivers can't see you behind it, and you can't see them."
- **edge**: go there `van_edge`
  - Coach: "Go to the edge of the van, where you can see and be seen. Stop there: never step into the road to look."
  - After: "At the edge, like a kerb."
- **look**: look both ways (VR: the head turns) (sides left, right, left)
  - Coach: "Look left, right, left. The nearest cars come from the left."
  - After: "You looked round the van both ways."
- **cross_van**: cross only when it is safe (a car stops gently if not) `far_kerb_van` (reach trigger)
  - Coach: "Wait for a big gap, then walk straight across."
  - A miss: "Wait! A car is coming. Stay at the edge of the van until there is a big gap."
  - **The safe mistake** (owner #118: the child may try it; time freezes, the scene goes soft and still): the wrong way: stepping out from behind a parked van while a car comes (tried by: `the right thing at the wrong moment (unsafe)`); the room's gentle picture: `step_out_van`; the why card's picture: `car_close`
    - The coach's calm why: "Behind a parked van the drivers can't see you, and a car needs time to stop: it couldn't stop in time."
    - Then the right way: "Wait at the van's edge, where drivers can see you, until there is a big gap."
  - After: "A big gap: you crossed. Keep looking and listening."
- **to_button**: words, then OK
  - Coach: "Now a button crossing. The button makes the traffic lights stop the cars for you."
- **button**: touch it `button` (motion press, device crossing)
  - Coach: "Press the button."
  - After: "WAIT lights up. Wait for the green man."
- **red_man**: pick a picture
  - Coach: "The red man shows. What does it mean?"
  - Picture (red_man) right: "Wait on the pavement"
  - Picture (run) not this one: "Cross now": "The red man means don't cross. Wait for the green man."
  - After: "Wait for the green man."
- **green** (normal try only): cross only when it is safe (a car stops gently if not) `far_kerb` (device crossing, rule green, reach trigger)
  - Coach: "When the green man shows, check the cars have stopped, then cross. If it flashes before you start, wait for the next one."
  - A miss: "Not yet: wait for the green man, and for the cars to stop."
  - **The safe mistake** (owner #118: the child may try it; time freezes, the scene goes soft and still): the wrong way: starting to cross before the green man (tried by: `the right thing at the wrong moment (unsafe)`); the room's gentle picture: `step_out_red`; the why card's picture: `car_close`
    - The coach's calm why: "Before the green man the cars still have their green light: they keep going, and a car can't stop in a moment."
    - Then the right way: "Wait for the green man, and check the cars have stopped."
  - After: "The green man, the cars stopped: you crossed."
- **green** (Expert try only): cross only when it is safe (a car stops gently if not) `far_kerb` (device crossing, rule green, reach trigger, no glow)
  - Coach: "When the green man shows, check the cars have stopped, then cross. If it flashes before you start, wait for the next one."
  - A miss: "Not yet: wait for the green man, and for the cars to stop."
  - **The safe mistake** (owner #118: the child may try it; time freezes, the scene goes soft and still): the wrong way: starting to cross before the green man (tried by: `the right thing at the wrong moment (unsafe)`); the room's gentle picture: `step_out_red`; the why card's picture: `car_close`
    - The coach's calm why: "Before the green man the cars still have their green light: they keep going, and a car can't stop in a moment."
    - Then the right way: "Wait for the green man, and check the cars have stopped."
  - After: "The green man, the cars stopped: you crossed."
- **night**: words, then OK
  - Coach: "Now it is getting dark. In the dark, drivers find it hard to see people walking."
- **clothes**: pick a picture
  - Coach: "What helps drivers see you at night?"
  - Picture (light_clothes) right: "Light clothes and something that shines"
  - Picture (dark_clothes) not this one: "Dark clothes": "Dark clothes are hard to see at night. Wear something light, and something that shines in car lights."
  - After: "Light colours, and something that shines in the headlights."
- **band**: touch it `band`
  - Coach: "Put on the shiny band. It glows when car lights shine on it."
  - After: "It shines! Drivers see you from far away."
- **torch**: touch it `torch` (motion press, tool torch)
  - Coach: "Switch on the torch."
  - After: "A light helps you see, and be seen."
- **cross_night** (Expert try only): cross only when it is safe (a car stops gently if not) `far_kerb` (reach trigger, no glow)
  - Coach: "Cross in the dark: stop, look left, right, left, listen, wait for a big gap. Car lights can be far away and still come fast."
  - A miss: "Wait! Headlights are coming. Wait for a big gap."
  - **The safe mistake** (owner #118: the child may try it; time freezes, the scene goes soft and still): the wrong way: stepping out when headlights are coming (tried by: `the right thing at the wrong moment (unsafe)`); the room's gentle picture: `step_out_gap`; the why card's picture: `car_close`
    - The coach's calm why: "In the dark it is hard to tell how fast a car is coming, and drivers see you later."
    - Then the right way: "Wait for a big gap, with no headlights coming."
  - After: "You judged the gap in the dark."
- **day**: words, then OK
  - Coach: "Daylight again. Pip-pop is going for a bike ride. Let's check her helmet fits."
- **level**: pick a picture
  - Coach: "Which helmet fits?"
  - Picture (helmet) right: "Level, low on the forehead"
  - Picture (helmet_back) not this one: "Tipped back": "Tipped back, it can't protect the forehead. It sits level, two fingers above the eyebrows."
  - After: "Level on the head."
- **fingers**: hold it `helmet_brow` (motion measure, device helmet, seconds 1.0)
  - Coach: "Put two fingers above Pip-pop's eyebrows: the helmet sits just there."
  - After: "Two fingers: just right."
- **straps**: press in order `strap_left, strap_right` (motion stroke, device helmet)
  - Coach: "Slide the straps so they make a V under each ear."
  - After: "A V under each ear."
- **buckle**: touch it `helmet_buckle` (motion squeeze, device helmet)
  - Coach: "Buckle it under the chin."
  - After: "Click!"
- **chin**: hold it `chin_strap` (motion measure, device helmet, seconds 1.0)
  - Coach: "One finger should fit under the chin strap, no more."
  - After: "Snug, not tight. Pip-pop is ready to ride."
- **end**: words, then OK
  - Coach: "Well done! The edge of a parked car, the green man, being seen at night, and a helmet that fits."

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "A van is parked. Where do you look from?" **The edge of the van** / The middle of the road
- "The green man is flashing and you haven't started. What do you do?" **Wait for the next one** / Run across
- "At night, what helps drivers see you?" **Light clothes and a shiny band** / Dark clothes
- "How far above the eyebrows does a helmet sit?" **Two fingers** / Far back on the head
- "Even when the green man shows, you..." **Check the cars have stopped** / Close your eyes

The "name it" card: **Cross safely, be seen**

1. Use a crossing when there is one: wait for the green man and check the cars have stopped.
2. Parked cars: stop at their edge, look and listen.
3. At night: light clothes, something that shines, a light.
4. Bike helmet: level, two fingers above the eyebrows, a V under each ear, one finger under the strap.

Its source line: The UK Highway Code's rules for pedestrians and the US NHTSA's helmet fit advice

Try it for real: With a grown-up, walk to a button crossing and show them every step. At home, fit your bike helmet in front of a mirror: two fingers, a V, one finger.

Your child can now: cross at a button crossing on the green man, step out from parked cars only to their edge, be seen at night, and fit a bike helmet

Sources:

- [ ] Parked vehicles: use the outside edge of the vehicles as if it were the kerb; stop there and make sure you can see all around and that the traffic can see you. (The Highway Code (UK), Rule 14): https://www.gov.uk/guidance/the-highway-code/rules-for-pedestrians-1-to-35
- [ ] At a button (pelican or puffin) crossing: press the button, wait for the green figure, check the traffic has stopped, then cross with care; do not start to cross if the green figure is flashing. (The Highway Code (UK), Rules 21-23): https://www.gov.uk/guidance/the-highway-code/rules-for-pedestrians-1-to-35
- [ ] Help others see you: wear something light-coloured, bright or fluorescent in daylight, and reflective materials in the dark. (The Highway Code (UK), Rule 3): https://www.gov.uk/guidance/the-highway-code/rules-for-pedestrians-1-to-35
- [ ] A helmet fits when it sits level, about two fingers above the eyebrows, the side straps form a V under the ears, and the buckled chin strap lets about one finger fit under it. (NHTSA, bicycle safety): https://www.nhtsa.gov/road-safety/bicycle-safety
- [ ] Being visible (light, bright and reflective clothing) helps pedestrians at night. (WHO, pedestrian safety: a road safety manual): https://www.who.int/publications/i/item/pedestrian-safety-a-road-safety-manual-for-decision-makers-and-practitioners

### Big (12 and up): The rules of the road

The Expert try's twist: A ball rolls into the road ahead: brake in time, and expect a child after it.

Steps:

- **hello**: words, then OK
  - Coach: "The driver's seat of a practice car: it stands still on rollers, so nothing can go wrong. Drivers follow rules that keep everyone safe. Let's see them."
- **belt**: press in order `driver_belt_top, driver_buckle` (motion stroke, device seat_belt)
  - Coach: "First, the seat belt: pull it across and click it in."
  - After: "Click. Belt on, every trip."
- **everyone**: pick a picture
  - Coach: "Who wears a seat belt in a car?"
  - Picture (belt_good) right: "Everyone, in every seat"
  - Picture (front_seat) not this one: "Only the driver": "Everyone wears one, in the front and the back, on every trip, even short ones."
  - After: "Everyone, every seat, every trip."
- **red**: pick a picture
  - Coach: "The light ahead turns red. What does the driver do?"
  - Picture (traffic_red) right: "Stop at the line"
  - Picture (speed) not this one: "Drive on": "Red means stop and wait behind the line, every time."
  - After: "Stop at the line."
- **brake**: hold it `brake` (motion press, device car, seconds 1.5, reach trigger)
  - Coach: "Press and hold the brake pedal (in VR: the trigger) until the car stops."
  - After: "Stopped at the red light."
- **people**: words, then OK
  - Coach: "People cross on their green man while your light is red. Wait for them: they have the right of way."
- **amber**: pick a picture
  - Coach: "What does an amber light mean?"
  - Picture (traffic_amber) right: "Stop, unless it isn't safe to stop"
  - Picture (speed) not this one: "Go faster": "Amber means stop at the line, unless you are so close that stopping would not be safe."
  - After: "Amber: stop if you safely can."
- **green**: pick a picture
  - Coach: "Now the light is green. What does green mean?"
  - Picture (traffic_green) right: "Go, if the way is clear"
  - Picture (run) not this one: "Go, whatever is there": "Green means you may go, but only if the way is clear: look for people still crossing."
  - After: "Go only when the way is clear."
- **speed**: keep the needle in its band `accelerator` (motion press, device car, seconds 4.0, reach trigger, unit km/h, lo 20, hi 30, top 60)
  - Coach: "Press the accelerator gently. Keep the needle at the limit on the sign, 30 km/h, or below, for 4 seconds."
  - After: "Steady, at the limit. Near schools and homes, slow is safe."
- **ball** (Expert try only): pick a picture
  - Coach: "A ball rolls into the road ahead! What does the driver do?"
  - Picture (ball) right: "Brake: a child may run after it"
  - Picture (speed) not this one: "Drive round it fast": "Where there is a ball, a child may follow. Brake and be ready to stop."
  - After: "Expect a child after a ball."
- **ball_brake** (Expert try only): touch it `brake` (motion press, device car, reach trigger)
  - Coach: "Brake!"
  - After: "You stopped in time."
- **phone**: pick a picture
  - Coach: "The phone buzzes while you are driving. What do you do?"
  - Picture (phone_off) right: "Leave it: never a phone while driving"
  - Picture (phone) not this one: "Read the message": "A phone takes your eyes and your mind off the road. Leave it; stop safely first if you must."
  - After: "Eyes on the road. The phone can wait."
- **stopping**: pick a picture
  - Coach: "A car at 20 mph (about 30 km/h) needs about 12 metres to stop. At 30 mph (about 50 km/h)?"
  - Picture (speed) right: "About 23 metres: nearly twice as far"
  - Picture (question) not this one: "The same, 12 metres": "Faster needs much more room: about 23 metres at 30 mph. That is why limits near schools are low."
  - After: "Faster needs much more room to stop."
- **cyclist**: pick a picture
  - Coach: "A cyclist is ahead. How much room do you give when you pass?"
  - Picture (bike) right: "Plenty: at least 1.5 metres"
  - Picture (car) not this one: "Very close": "Give cyclists plenty of room, at least 1.5 metres in town, and pass slowly."
  - After: "Plenty of room, and slowly."
- **zebra**: pick a picture
  - Coach: "Someone waits at a zebra crossing. What do you do?"
  - Picture (crossing) right: "Slow down and give way"
  - Picture (speed) not this one: "Drive on": "Give way to people waiting at a zebra crossing: slow down and stop for them."
  - After: "People first at a crossing."
- **end**: words, then OK
  - Coach: "You know the rules of the road: belts on, stop at red, give way to people, keep to the limit, and never a phone. As a walker, you now know what drivers see."

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "The light is amber. What does it mean?" **Stop, if you safely can** / Go faster
- "Who wears a seat belt?" **Everyone, every seat** / Only the driver
- "Faster cars need... to stop" **Much more room** / The same room
- "The phone buzzes while driving. You..." **Leave it** / Read it
- "Someone waits at a zebra crossing. The driver..." **Gives way** / Drives on

The "name it" card: **The rules of the road**

1. Everyone belted, every seat, every trip.
2. Red: stop. Amber: stop if you safely can. Green: go if the way is clear.
3. Give way to people crossing.
4. Keep to the limit: faster needs much more room to stop.
5. Never a phone while driving.

Its source line: The UK Highway Code (rules for drivers) and the WHO's road safety facts

Try it for real: On your next car trip, be the safety helper: check everyone's belt before the car moves, and spot the traffic lights and the crossings with your grown-up.

Your child can now: explain the rules of the road from the driver's seat: belts, the traffic lights, giving way to people crossing, the speed limit and never a phone

Sources:

- [ ] Traffic lights: red means stop and wait behind the stop line; amber means stop unless you have crossed the line or are so close that pulling up might cause a collision; green means you may go on if the way is clear, giving way to pedestrians who are crossing. (The Highway Code (UK), Rules 175-176): https://www.gov.uk/guidance/the-highway-code/using-the-road-159-to-203
- [ ] Typical stopping distances: about 12 metres at 20 mph and about 23 metres at 30 mph. (The Highway Code (UK), Rule 126): https://www.gov.uk/guidance/the-highway-code/general-rules-techniques-and-advice-for-all-drivers-and-riders-103-to-158
- [ ] It is illegal to hold a phone while driving; give cyclists at least 1.5 metres when overtaking at speeds up to 30 mph; give way to pedestrians waiting at a zebra crossing. (The Highway Code (UK), Rules 149, 163 and 195): https://www.gov.uk/guidance/the-highway-code/using-the-road-159-to-203
- [ ] Seat belts cut the risk of a fatal injury for drivers and front-seat passengers by 45-50%, and the risk of serious injury for rear-seat passengers by about 25%; lower speeds save lives. (WHO, road traffic injuries fact sheet): https://www.who.int/news-room/fact-sheets/detail/road-traffic-injuries

## The Kitchen

For the review by a food safety and nutrition educator (the WHO's Five Keys to Safer Food and healthy diet advice).

The device **tap** (owner #117, the device model): controls: the tap's handle. It shows: the water. The right order: turn it on → wet your hands → turn it off when you are done. Safety: test hot water with a fingertip first; turn it off: save water.
The device **scales** (owner #117, the device model): controls: the on button; the zero button. It shows: the grams. The right order: put the bowl on → press zero → spoon the food on slowly → stop at the amount. Safety: spoon slowly near the amount; read the number at eye level.
The device **hob** (owner #117, the device model): controls: the knobs. It shows: the hot light. The right order: pan on the ring → handle turned in → knob to low → cook with a grown-up → knob off. Safety: a grown-up is always there; handles turned in, away from the edge; the hot light: still hot, don't touch; never leave it on.
The device **oven** (owner #117, the device model): controls: the door; the knob. It shows: the light; the temperature. The right order: oven gloves on → open the door and step back from the hot air → take the tray out with both hands → put it on a heat mat → close the door, turn it off. Safety: oven gloves, never a wet cloth; a grown-up is always there; hot air comes out when the door opens.
The device **till** (owner #117, the device model): controls: PAY. It shows: the basket's total. The right order: the needs first → add up → a treat only if it fits → pay. Safety: stay within the budget.
The device **kettle** (owner #117, the device model): controls: the switch; the lid. It shows: the water window: MIN and MAX; the light. The right order: fill it at the tap between MIN and MAX → close the lid, switch it on → it switches itself off when it boils → pour slowly, away from you. Safety: never above MAX: boiling water spits out; the cord away from the edge; steam is hot; a grown-up pours for younger children.

### Little (about 6-8): Clean hands and a healthy plate

The Expert try's twist: Three vegetables and fruit for the plate this time, and one more question: when do you wash your hands?

Steps:

- **hello**: words, then OK
  - Coach: "The practice kitchen! Today we make {recipe}, from {recipe_from}. In a real kitchen a grown-up is always near. First: clean hands."
- **tap**: touch it `tap` (motion twist, tool tap, device tap)
  - Coach: "Turn on the tap and wet your hands."
  - After: "Water on."
- **soap**: touch it `soap` (motion press, tool soap)
  - Coach: "Press the soap pump."
  - After: "Soap on your hands."
- **rub**: rub for its seconds `hands` (motion stroke, seconds 20.0, label 20 seconds)
  - Coach: "Rub your hands for 20 seconds: palms, backs, between the fingers, thumbs and nails. Hum Happy Birthday twice!"
  - After: "20 seconds! Watch the germs' glow fade away."
- **rinse**: hold it `water` (seconds 1.5)
  - Coach: "Rinse the soap off under the water."
  - After: "All rinsed."
- **tap_off**: touch it `tap` (motion twist, tool tap, device tap)
  - Coach: "Turn the tap off."
  - After: "Off: we save water."
- **dry**: hold it `towel` (motion stroke, tool towel, seconds 1.5)
  - Coach: "Dry your hands on a clean towel."
  - After: "Clean and dry. Ready to cook!"
- **hot_tap**: pick a picture
  - Coach: "The red tap is the hot tap. Its water can be very hot."
  - Picture (tap_cold) right: "Cold first, and a grown-up checks it"
  - Picture (tap_hot) not this one: "Turn the hot tap on full": "Hot water can scald: a grown-up runs the cold first, then checks the water."
  - After: "Cold first, and a grown-up checks the hot tap."
- **when** (Expert try only): pick a picture
  - Coach: "When do you wash your hands?"
  - Picture (hands_wash) right: "Before cooking and eating, and after the toilet"
  - Picture (hand) not this one: "Only when they look dirty": "Germs are too small to see. Wash before cooking and eating, and after the toilet."
  - After: "Before food, and after the toilet."
- **plate**: words, then OK
  - Coach: "A healthy plate: half is vegetables and fruit, a quarter is grains like rice or bread, a quarter is protein like beans, eggs or fish. And water to drink."
- **veg** (Expert try only): find them `carrot, broccoli, tomato, apple` (need 3)
  - Coach: "Fill half the plate with vegetables and fruit. Pick three."
  - Found `carrot`: "A carrot: crunchy!"
  - Found `broccoli`: "Broccoli: little trees!"
  - Found `tomato`: "A tomato: juicy!"
  - Found `apple`: "An apple: sweet!"
  - After: "Half the plate: vegetables and fruit."
- **veg** (normal try only): find them `carrot, broccoli, tomato, apple` (need 2)
  - Coach: "Fill half the plate with vegetables and fruit. Pick two."
  - Found `carrot`: "A carrot: crunchy!"
  - Found `broccoli`: "Broccoli: little trees!"
  - Found `tomato`: "A tomato: juicy!"
  - Found `apple`: "An apple: sweet!"
  - After: "Half the plate: vegetables and fruit."
- **grains**: find them `rice, bread` (need 1)
  - Coach: "A quarter of the plate: grains. Pick one."
  - Found `rice`: "Rice."
  - Found `bread`: "Brown bread."
  - After: "Grains give you energy."
- **protein**: find them `beans, egg, fish` (need 1)
  - Coach: "The last quarter: protein. Pick one."
  - Found `beans`: "Beans."
  - Found `egg`: "An egg."
  - Found `fish`: "Fish."
  - After: "Protein helps you grow."
- **drink**: pick a picture
  - Coach: "What is the best drink with your meal?"
  - Picture (water_glass) right: "Water"
  - Picture (fizzy) not this one: "A fizzy drink": "Fizzy drinks have lots of sugar. Water is best."
  - After: "Water: the best drink."
- **grip**: pick a picture
  - Coach: "How do you hold the food to cut it?"
  - Picture (knife_bridge) right: "The bridge: fingers and thumb make a bridge, the knife goes under it"
  - Picture (knife_wrong) not this one: "Fingers in front of the knife": "Keep fingers out of the knife's way: make a bridge and cut under it."
  - After: "The bridge keeps fingers safe."
- **cut**: sweep across it `cut_food` (motion cut, tool knife, sweeps 3, reach hand)
  - Coach: "Cut {cut_food} with the child-safe knife, under the bridge: slowly, back and forth."
  - After: "Neat slices, fingers safe."
- **pour**: pour or weigh to the line `jug` (motion pour, tool measuring_jug, want {pour_want}, full 1.0, tol 0.06, unit cup)
  - Coach: "Pour {pour_words} of {pour_what} into the measuring cup. Stop at the line."
  - After: "{pour_words}: exactly!"
- **stir**: sweep across it `bowl` (motion stroke, tool spoon, sweeps 4, reach hand)
  - Coach: "Stir it all together in the bowl."
  - After: "Mixed! {recipe} is ready."
- **wipe**: sweep across it `worktop` (motion stroke, tool cloth, sweeps 3, reach hand)
  - Coach: "Now clean up: wipe the table with the cloth."
  - After: "All clean."
- **baby**: words, then OK
  - Coach: "Your baby cousin Nia is coming to play. Babies put things in their mouths, and small things can get stuck and stop them breathing."
- **tidy** (normal try only): find them `small_marble, small_coin, small_wheel, small_beads`
  - Coach: "Help a grown-up tidy away the small things on the floor, before Nia comes."
  - Found `small_marble`: "A marble: into the box."
  - Found `small_coin`: "A coin: into the box."
  - Found `small_wheel`: "A little toy wheel: into the box."
  - Found `small_beads`: "Beads: into the box."
  - After: "All the small things are up high, out of Nia's reach."
- **tidy** (Expert try only): find them `small_marble, small_coin, small_wheel, small_beads, small_battery` (no glow)
  - Coach: "Find all 5 small things Nia could put in her mouth."
  - Found `small_marble`: "A marble: into the box."
  - Found `small_coin`: "A coin: into the box."
  - Found `small_wheel`: "A little toy wheel: into the box."
  - Found `small_beads`: "Beads: into the box."
  - Found `small_battery`: "A tiny round battery: give it to a grown-up."
  - After: "All 5, even the tiny battery: well spotted!"
- **grapes**: pick a picture
  - Coach: "A snack for Nia: grapes. How does a grown-up give them to a little child?"
  - Picture (grapes_cut) right: "Cut into quarters"
  - Picture (grapes) not this one: "Whole": "Whole grapes can get stuck in a small child's throat: grown-ups cut them into quarters."
  - After: "Cut small, and Nia sits down to eat."
- **end**: words, then OK
  - Coach: "You did it! Clean hands for 20 seconds, a healthy plate, a safe cut and a measured cup. Enjoy your {recipe}!"

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "How long do you rub your hands with soap?" **20 seconds** / 1 second
- "What fills half a healthy plate?" **Vegetables and fruit** / Sweets
- "What is the best drink?" **Water** / A fizzy drink
- "How do you hold food to cut it?" **The bridge** / Fingers in front

The "name it" card: **Clean hands, a healthy plate**

1. Wash with soap for 20 seconds, rinse, dry.
2. Half the plate vegetables and fruit, a quarter grains, a quarter protein.
3. Water is the best drink.
4. Cut with a child-safe knife and the bridge grip, a grown-up near.
5. Small things up high, away from babies; a grown-up cuts grapes small.

Its source line: The WHO's healthy diet and hand-washing advice, and the UK's Eatwell Guide

Try it for real: Show your grown-up your 20-second hand wash before the next meal (hum Happy Birthday twice). Then help them put the meal on the plate: half vegetables and fruit!

Your child can now: wash their hands for 20 seconds, build a healthy plate, cut soft food with a child-safe knife and the bridge grip, and measure a cup

Sources:

- [ ] Small things such as marbles, coins, button batteries and small toy parts can choke a baby or toddler: keep them out of reach; cut grapes and other small round foods lengthways into quarters for young children. (Child Accident Prevention Trust, choking; NHS, choking in babies and children): https://capt.org.uk/
- [ ] Hot tap water can scald: run the cold first and check the temperature; a grown-up checks water for a child. (Child Accident Prevention Trust, burns and scalds): https://capt.org.uk/
- [ ] Wash hands with soap and water: wet, apply soap, rub all surfaces (palms, backs, between the fingers, thumbs, nails) for at least 20 seconds, rinse, dry with a clean towel. (CDC, clean hands: how to wash your hands): https://www.cdc.gov/clean-hands/about/index.html
- [ ] Hand washing takes about 20 seconds: about as long as singing Happy Birthday twice. (NHS, how to wash your hands): https://www.nhs.uk/live-well/healthy-body/best-way-to-wash-your-hands/
- [ ] A healthy diet has plenty of fruit and vegetables (at least 400 g a day), whole grains and pulses, and little free sugar and salt. (WHO, healthy diet fact sheet): https://www.who.int/news-room/fact-sheets/detail/healthy-diet
- [ ] A healthy plate: half vegetables and fruit, a quarter whole grains, a quarter healthy protein, and water to drink. (Harvard T.H. Chan School of Public Health, the Healthy Eating Plate): https://nutritionsource.hsph.harvard.edu/healthy-eating-plate/
- [ ] Children learn the bridge hold and the claw grip to cut food safely, with supervision. (British Nutrition Foundation, Food - a fact of life (cooking skills)): https://www.foodafactoflife.org.uk/

### Middle (about 9-11): Measure, cut and cook safely

The Expert try's twist: The scales show 35 with the empty bowl on them: press zero first.

Steps:

- **hello**: words, then OK
  - Coach: "The practice kitchen. Today: {recipe}, from {recipe_from}. A grown-up is always with you at the hob. Clean hands first."
- **soap**: touch it `soap` (motion press, tool soap)
  - Coach: "Wet your hands and press the soap pump."
  - After: "Soap on."
- **rub**: rub for its seconds `hands` (motion stroke, seconds 20.0, label 20 seconds)
  - Coach: "Rub for 20 seconds: palms, backs, between the fingers, thumbs and nails."
  - After: "Clean hands!"
- **dry**: hold it `towel` (motion stroke, tool towel, seconds 1.0)
  - Coach: "Rinse and dry on a clean towel."
  - After: "Ready to cook."
- **zero** (Expert try only): touch it `scales_zero` (motion press, device scales)
  - Coach: "The scales show 35 with the empty bowl on them. Press zero first."
  - After: "Zero. Now it weighs only the food."
- **weigh**: pour or weigh to the line `scales` (motion measure, tool spoon, device scales, want {weigh_g}, full 500, tol 10, unit g)
  - Coach: "Spoon {weigh_what} onto the scales until it reads {weigh_g} grams. Slowly near the end!"
  - After: "{weigh_g} grams exactly."
- **pour**: pour or weigh to the line `jug` (motion pour, tool measuring_jug, want {pour_want}, full 1.0, tol 0.06, unit cup)
  - Coach: "Pour {pour_words} of {pour_what}."
  - After: "{pour_words}. Fractions in the kitchen!"
- **grip**: pick a picture
  - Coach: "To slice {cut_food}, which grip keeps your fingers safe?"
  - Picture (knife_claw) right: "The claw: fingertips tucked in"
  - Picture (knife_wrong) not this one: "Fingers flat and straight": "Flat fingers can slip under the knife. Tuck the fingertips in like a claw."
  - After: "The claw: fingertips tucked away."
- **cut**: sweep across it `cut_food` (motion cut, tool knife, sweeps 4, reach hand)
  - Coach: "Slice {cut_food}, the claw holding it and the knife going up and down."
  - After: "Even slices, fingers tucked in."
- **whisk**: sweep across it `bowl` (motion stroke, tool whisk, sweeps 6, reach hand)
  - Coach: "Whisk it in the bowl, quickly back and forth."
  - After: "Smooth! Ready for the pan."
- **handle**: touch it `pan_handle` (motion twist, device hob)
  - Coach: "The pan's handle sticks out over the edge. Turn it in, away from the edge."
  - After: "Handle in: nobody can knock it."
- **knob**: touch it `knob` (motion twist, device hob)
  - Coach: "With your grown-up, turn the knob to low."
  - After: "Low heat. The ring glows."
- **cook**: the clock runs by itself (seconds 4.0, label cooking)
  - Coach: "It cooks. Stay with the hob: never leave cooking alone."
- **off**: touch it `knob` (motion twist, device hob)
  - Coach: "Done: turn the knob off."
  - After: "Off."
- **hot**: pick a picture
  - Coach: "The hob is off, but the hot light is still on. What does it mean?"
  - Picture (hob_hot) right: "It is still hot: don't touch"
  - Picture (hand) not this one: "It is cool now": "The hot light means the hob is still hot. Never touch it until the light is off."
  - After: "Still hot. Keep hands away until the light goes off."
- **pan_fire**: words, then OK
  - Coach: "Practice time: on another day, the oil in a pan catches fire. In real life you get out and tell a grown-up: they do this. Here you practise, so you know why."
- **heat_off**: touch it `knob` (motion twist, device hob, a danger moment: its time slows on the first tries, real time on the Expert try)
  - Coach: "First, turn the heat off, if you can reach it safely."
  - After: "Heat off."
- **lid** (normal try only): touch it `pan_lid` (motion press, tool pan_lid, a danger moment: its time slows on the first tries, real time on the Expert try)
  - Coach: "The flames are still there. What puts them out?"
  - **The safe mistake** (owner #118: the child may try it; time freezes, the scene goes soft and still): the wrong way: throwing water on a pan fire (tried by: `water_jug`); the room's gentle picture: `flare`; the why card's picture: `water_pan`
    - The coach's calm why: "Water makes burning oil jump up in a big flare of flame. That's why we put a lid on it."
    - Then the right way: "Slide the lid on to cover the pan, and leave it."
  - After: "The lid keeps the air out: the fire goes out."
- **lid** (Expert try only): touch it `pan_lid` (motion press, tool pan_lid, no glow, a danger moment: its time slows on the first tries, real time on the Expert try)
  - Coach: "Heat off, and the flames are still there. What now?"
  - **The safe mistake** (owner #118: the child may try it; time freezes, the scene goes soft and still): the wrong way: throwing water on a pan fire (tried by: `water_jug`); the room's gentle picture: `flare`; the why card's picture: `water_pan`
    - The coach's calm why: "Water makes burning oil jump up in a big flare of flame. That's why we put a lid on it."
    - Then the right way: "Slide the lid on to cover the pan, and leave it."
  - After: "The lid, all by yourself: the fire is out."
- **leave**: pick a picture
  - Coach: "The fire is out under the lid. Now?"
  - Picture (pan_lid) right: "Leave it covered until it is cold"
  - Picture (eye) not this one: "Lift the lid to look": "Air can make it flare up again: leave the lid on until the pan is cold."
  - Picture (pan_out) not this one: "Carry the pan to the sink": "Never move a burning or hot pan: leave it where it is, covered."
  - After: "Covered until it's cold."
- **bigger**: pick a picture
  - Coach: "And if a pan fire doesn't go out, or gets bigger?"
  - Picture (fire_engine) right: "Get out, stay out, call 112"
  - Picture (water_pan) not this one: "Throw water on it": "Never water on a pan fire. Get out, close the door behind you, and call 112."
  - After: "Get out, stay out, call 112."
- **wipe**: sweep across it `worktop` (motion stroke, tool cloth, sweeps 3, reach hand)
  - Coach: "Clean up: wipe the table."
  - After: "All clean. Enjoy your {recipe}!"
- **end**: words, then OK
  - Coach: "Well done! You weighed and measured, cut with the claw, whisked, and used the hob safely with a grown-up."

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "To weigh flour, the scales first show..." **Zero, with the bowl on** / Any number
- "Half a cup is..." **1/2** / 1/4
- "Which grip keeps fingers safe when slicing?" **The claw** / Flat fingers
- "A pan's handle on the hob points..." **In, away from the edge** / Out over the edge
- "The hob's hot light is on. You..." **Don't touch it** / Touch it

The "name it" card: **Measure, cut, cook safely**

1. Clean hands first.
2. Scales at zero, then weigh; cups in fractions.
3. Cut with the claw grip, slowly.
4. At the hob: a grown-up there, handles in, low heat, never left alone; the hot light means still hot.
5. A pan fire: heat off, a lid on, leave it covered. Never water.

Its source line: The WHO's food safety keys, the British Nutrition Foundation's cooking skills, and home safety advice (RoSPA)

Try it for real: Cook {recipe} with your grown-up: you weigh and measure, you slice with the claw, and you turn the pan's handle in. Your grown-up does the hob with you.

Your child can now: weigh and measure ingredients, cut with the claw grip, whisk, and use a hob safely with a grown-up: handles in, a low heat, the hot light

Sources:

- [ ] A small pan fire: turn off the heat if it is safe, slide a lid over the pan and leave it covered until it is completely cool; never throw water on burning oil. (NFPA, cooking fire safety): https://www.nfpa.org/education-and-research/home-fire-safety/cooking
- [ ] If a pan fire doesn't go out or spreads: get out, close the door, stay out and call 999 or 112. (London Fire Brigade, kitchen fire safety): https://www.london-fire.gov.uk/safety/the-home/cooking/
- [ ] Keep clean: wash your hands before handling food and often during food preparation. (WHO, Five Keys to Safer Food): https://www.who.int/publications/i/item/9789241594639
- [ ] The claw grip and the bridge hold are the safe knife grips taught to children, who cook with an adult supervising. (British Nutrition Foundation, Food - a fact of life (cooking skills)): https://www.foodafactoflife.org.uk/
- [ ] Turn pan handles inwards, away from the edge of the cooker, and use the back rings where you can; never leave cooking unattended. (RoSPA (Royal Society for the Prevention of Accidents), home safety): https://www.rospa.com/home-safety
- [ ] Hot drinks, pans and hobs cause most scalds to children at home; a hob stays hot after it is switched off. (Child Accident Prevention Trust, burns and scalds): https://capt.org.uk/burns-and-scalds/

### Big (12 and up): Cook a meal and plan a week

The Expert try's twist: The kettle is filled above MAX: tip some out. And the week's money is tighter.

Steps:

- **hello**: words, then OK
  - Coach: "The practice kitchen. Today: {recipe}, from {recipe_from}, and a plan for the week. Hands washed? Let's keep food safe."
- **rub**: rub for its seconds `hands` (motion stroke, seconds 20.0, label 20 seconds)
  - Coach: "Soap and 20 seconds of rubbing, then rinse."
  - After: "Clean hands. Wash again after touching raw meat or eggs."
- **boards**: pick a picture
  - Coach: "You cut raw chicken and salad. How many chopping boards?"
  - Picture (two_boards) right: "Two: raw meat on its own board"
  - Picture (board) not this one: "One for everything": "Germs from raw meat can get onto food you eat raw. Keep raw meat on its own board, or wash it well between."
  - After: "Raw and ready-to-eat food apart."
- **fridge**: touch it `fridge_bottom`
  - Coach: "Raw meat goes on the bottom shelf of the fridge, so it can't drip onto other food. Put it there."
  - After: "Bottom shelf, covered."
- **cold**: pick a picture
  - Coach: "How cold should a fridge be?"
  - Picture (fridge) right: "5 °C or below"
  - Picture (question) not this one: "Room warm, 20 °C": "Germs grow fast when it is warm. A fridge keeps food at 5 °C or below."
  - After: "Cold food stays safe longer."
- **fill**: pour or weigh to the line `kettle` (motion pour, device kettle, want 0.6, full 1.0, tol 0.18, unit line)
  - Coach: "Fill the kettle at the tap, between MIN and MAX."
  - After: "Between MIN and MAX."
- **too_full** (Expert try only): pick a picture
  - Coach: "Someone filled this kettle above MAX. What do you do?"
  - Picture (kettle) right: "Tip some out to below MAX"
  - Picture (kettle_max) not this one: "Switch it on anyway": "Above MAX, boiling water can spit out. Tip some out first."
  - After: "Below MAX: safe to boil."
- **switch**: touch it `kettle_switch` (motion press, device kettle)
  - Coach: "Close the lid and switch it on. Keep the cord away from the edge."
  - After: "It's heating."
- **boil**: the clock runs by itself (seconds 4.0, label boiling)
  - Coach: "It boils, then switches itself off. Stand back from the steam."
- **pour_hot**: pour or weigh to the line `kettle` (motion pour, device kettle, want {pour_want}, full 1.0, tol 0.06, unit cup)
  - Coach: "Pour {pour_words} of hot water into the pan, slowly and away from you."
  - After: "Slowly and steadily. Kettle back on its base."
- **weigh**: pour or weigh to the line `scales` (motion measure, tool spoon, device scales, want {weigh_g}, full 500, tol 10, unit g)
  - Coach: "Weigh {weigh_g} grams of {weigh_what}."
  - After: "{weigh_g} grams."
- **cut**: sweep across it `cut_food` (motion cut, tool knife, sweeps 5, reach hand)
  - Coach: "Slice {cut_food} with the claw grip."
  - After: "Even slices."
- **gloves**: touch it `gloves` (motion squeeze, tool oven_gloves, device oven)
  - Coach: "The roasted vegetables are ready. Oven gloves on first."
  - After: "Gloves on, both hands."
- **door**: touch it `oven_door` (device oven)
  - Coach: "Open the oven door and step back from the hot air."
  - After: "Open. Hot air comes out: wait a moment."
- **tray**: hold it `tray` (motion squeeze, tool oven_gloves, device oven, seconds 1.0)
  - Coach: "Take the tray out with both gloved hands."
  - After: "Out, held level."
- **mat**: touch it `heat_mat` (device oven)
  - Coach: "Put it on the heat mat."
  - After: "Safe on the mat."
- **oven_off**: touch it `oven_knob` (motion twist, device oven)
  - Coach: "Close the door and turn the oven off."
  - After: "Off. {recipe} is ready!"
- **scald**: words, then OK
  - Coach: "Practice time: a splash of hot water lands on Bobo's paw. Burns and scalds need cooling, straight away."
- **cool**: hold it `water` (tool tap, seconds 2, reach hand)
  - Coach: "Hold Bobo's paw under cool running water."
  - After: "Cool water on it."
- **cool_time**: the clock runs by itself (seconds 6.0, label 20 minutes)
  - Coach: "Cool running water for 20 minutes: that's how long a burn needs. Let's speed up the clock."
  - After: "Twenty minutes of cool running water."
- **cover**: pick a picture
  - Coach: "Then?"
  - Picture (cling_film) right: "Cover it loosely with cling film, and tell a grown-up"
  - Picture (butter) not this one: "Butter or ice on it": "Never butter, ice or creams: cool running water for 20 minutes, then cling film."
  - After: "Loosely covered, and a grown-up decides if it needs a doctor."
- **week**: words, then OK
  - Coach: "Now plan a week of meals with pretend coins. Needs first: the food for the meals. Then a treat only if there is money left."
- **shop** (Expert try only): shop (motion press, device till, budget 19)
  - Coach: "Money is tighter this week: 19 coins. Put the needs in the basket: rice, lentils, vegetables, eggs and milk. Then PAY."
  - After: "Needs first, and it fits: 18 of 19 coins."
- **shop** (normal try only): shop (motion press, device till, budget 23)
  - Coach: "You have 23 coins. Put the week's needs in the basket: rice, lentils, vegetables, eggs and milk. One treat fits too. Then PAY."
  - After: "The week's food, within the budget!"
- **better**: pick a picture
  - Coach: "Rice: one 2 kg bag for 6 coins, or two 1 kg bags for 4 coins each. Which is the better buy?"
  - Picture (big_bag) right: "The 2 kg bag: 3 coins a kilo"
  - Picture (small_bags) not this one: "Two small bags": "Two small bags cost 8 coins for 2 kg: 4 a kilo. The big bag is 3 a kilo."
  - After: "Compare the price per kilo. The big bag saves 2 coins."
- **end**: words, then OK
  - Coach: "Brilliant! Food kept safe, the kettle and the oven used safely, a meal cooked, and a week's shopping on a budget. Pretend coins today; real money with your grown-up."

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "Raw chicken and salad: chopping boards?" **Two: raw meat apart** / One for both
- "A fridge should be..." **5 °C or below** / Warm
- "You fill a kettle..." **Between MIN and MAX** / To the very top
- "To take a hot tray out of the oven, you use..." **Oven gloves** / A wet cloth
- "Shopping on a budget: first..." **The needs** / The treats

The "name it" card: **Cook safely, plan wisely**

1. Keep clean: wash hands, and again after raw meat or eggs.
2. Separate raw and cooked: raw meat on its own board, at the bottom of the fridge.
3. Keep food cold: the fridge at 5 °C or below.
4. Kettle between MIN and MAX; oven gloves; a grown-up there.
5. Plan the week: needs first, compare the price per kilo.

Its source line: The WHO's Five Keys to Safer Food, the UK Food Standards Agency, and money basics (the OECD/INFE framework)

Try it for real: With your grown-up, plan three dinners for next week, write the shopping list (needs first) and check the prices per kilo in the shop. Then cook one of them together.

Your child can now: keep food safe (raw and cooked apart, the fridge cold), use a kettle and an oven safely, cook a meal and plan a week's meals on a budget

Sources:

- [ ] Burns and scalds: cool under cool running water for 20 minutes, remove anything near it that isn't stuck, cover loosely with cling film; never ice, butter or creams. (NHS, burns and scalds): https://www.nhs.uk/conditions/burns-and-scalds/
- [ ] The Five Keys to Safer Food: keep clean; separate raw and cooked; cook thoroughly; keep food at safe temperatures; use safe water and raw materials. (WHO, Five Keys to Safer Food manual): https://www.who.int/publications/i/item/9789241594639
- [ ] Keep the fridge at 5 °C or below; store raw meat and poultry covered on the bottom shelf so it can't drip onto other food. (UK Food Standards Agency, chilling): https://www.food.gov.uk/safety-hygiene/chilling
- [ ] Never fill a kettle above its MAX mark; keep the cord away from the worktop's edge; hot drinks and kettles cause many scalds to children. (Child Accident Prevention Trust, burns and scalds): https://capt.org.uk/burns-and-scalds/
- [ ] Planning and managing money: a budget, needs before wants, comparing prices (such as the unit price). (OECD/INFE Core Competencies Framework on Financial Literacy for Youth (2015)): https://microfinancegateway.org/paper/2015/09/core-competencies-framework-financial-literacy-youth

## Calm Corner

For the review by a child psychologist or school counsellor (CASEL; the national children's mental-health guidance).

The device **tablet** (owner #117, the device model): controls: BLOCK; REPORT. It shows: the messages. The right order: don't reply to unkind messages → keep them to show a grown-up → block the sender → report it → tell a grown-up you trust. Safety: never share someone's photo without asking; you are never to blame for someone else's unkindness.

### Little (about 6-8): Name it, calm it

The Expert try's twist: A new story: a friend says you can't play. And four slow breaths.

Steps:

- **hello**: words, then OK
  - Coach: "This is the Calm Corner: a quiet place to practise feeling calm. Everyone has big feelings sometimes. Nothing you pick here is kept."
- **name**: pick a picture
  - Coach: "Bobo's tower fell down. Look at Bobo's face. How does Bobo feel?"
  - Picture (face_sad) right: "Sad"
  - Picture (face_happy) not this one: "Happy": "Look again: Bobo's mouth turns down and the eyes look down. Bobo feels sad."
  - Picture (face_cross) not this one: "Cross": "Look again: Bobo's mouth turns down and the eyes look down. Bobo feels sad."
  - After: "Sad. Naming a feeling is the first step to feeling better."
- **me**: pick a feeling (any picture is right, nothing kept)
  - Coach: "How do you feel right now? Any answer is fine."
  - Picture (face_happy) not this one: "Happy"
  - Picture (face_calm) not this one: "Calm"
  - Picture (face_sad) not this one: "Sad"
  - Picture (face_cross) not this one: "Cross"
  - Picture (face_worried) not this one: "Worried"
- **breathe** (normal try only): breathe with the balloon `balloon` (breaths 3, in 3.0, out 3.0)
  - Coach: "Balloon breathing: breathe in slowly while the balloon grows, then out slowly while it shrinks. Three times."
  - After: "Slow breaths. Your body feels calmer."
- **breathe** (Expert try only): breathe with the balloon `balloon` (breaths 4, in 3.0, out 3.0)
  - Coach: "Balloon breathing: in slowly while the balloon grows, out slowly while it shrinks. Four times."
  - After: "Four slow breaths. Calm."
- **after**: words, then OK
  - Coach: "Bobo breathed with you. Look: Bobo's face is calm now."
- **five**: find them `lamp, plant, window, books, cat, clock, fish` (need 5)
  - Coach: "Look all around the room. Find five things you can see."
  - Found `lamp`: "A lamp."
  - Found `plant`: "A plant."
  - Found `window`: "The window, with clouds."
  - Found `books`: "Books."
  - Found `cat`: "A sleepy cat."
  - Found `clock`: "A clock."
  - Found `fish`: "A fish in its bowl."
  - After: "Five things! Noticing what is around you helps your mind feel calm."
- **worry**: pick a feeling (any picture is right, nothing kept)
  - Coach: "Is anything worrying you? Pick a picture. You don't have to say more."
  - Picture (worry_school) not this one: "School"
  - Picture (worry_friend) not this one: "A friend"
  - Picture (worry_dark) not this one: "The dark"
  - Picture (worry_cloud) not this one: "Something else"
  - Picture (face_calm) not this one: "Nothing today"
- **box**: touch it `worry_box`
  - Coach: "Put the worry in the worry box. Later, you can take it out and talk about it with a grown-up you trust."
  - After: "In the box. Worries get smaller when we share them."
- **story** (normal try only): words, then OK
  - Coach: "Look: Mo and Bobo are playing ball. Pip-pop is all on her own and looks sad."
- **left_out** (normal try only): pick a picture
  - Coach: "What could you do?"
  - Picture (join) right: "Ask Pip-pop to play"
  - Picture (ball) not this one: "Keep playing without her": "Being left out feels sad. Asking someone to join in is kind."
  - After: "Pip-pop joins in. Everyone smiles."
- **story** (Expert try only): words, then OK
  - Coach: "A new story: Mo says to you, "You can't play with us." How might that feel?"
- **cant_play** (Expert try only): pick a picture
  - Coach: "What could you do?"
  - Picture (talk) right: "Say how I feel, find someone else to play with, and tell a grown-up"
  - Picture (face_cross) not this one: "Push Mo": "Pushing hurts and makes things worse. Say how you feel, play with someone else, and tell a grown-up."
  - After: "Calm words, a new friend to play with, and a grown-up who can help."
- **tell**: pick a picture
  - Coach: "When you feel sad or worried, who can you tell?"
  - Picture (grown_up) right: "A grown-up I trust"
  - Picture (question) not this one: "Nobody": "Telling a grown-up you trust helps. You don't have to keep a worry on your own."
  - After: "A grown-up you trust: at home, or at school."
- **end**: words, then OK
  - Coach: "You named feelings, breathed slowly, looked around, put a worry away and helped a friend. The Calm Corner is always here."

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "Bobo's mouth turns down. Bobo feels..." **Sad** / Happy
- "You feel cross. What can help you calm down?" **Slow breaths** / Shouting
- "Someone is left out. You can..." **Ask them to play** / Leave them
- "A worry won't go away. Who can you tell?" **A grown-up I trust** / Nobody

The "name it" card: **Name it, calm it**

1. Name the feeling: sad, cross, worried, happy...
2. Breathe slowly: in like a balloon, out slowly.
3. Look around: find five things you can see.
4. Share a worry with a grown-up you trust.

Its source line: CASEL's social and emotional learning (self-awareness, self-management) and UNICEF's advice for children

Try it for real: Teach your grown-up balloon breathing: breathe in while your hands rise, out while they fall. Make a worry box at home together.

Your child can now: name a feeling, calm down with slow balloon breaths and by noticing what they see, and ask a trusted grown-up for help

Sources:

- [ ] Self-awareness (identifying one's emotions) and self-management (managing emotions, using stress-management strategies) are core social and emotional competencies; so is seeking or offering help. (CASEL, the CASEL framework): https://casel.org/fundamentals-of-sel/what-is-the-casel-framework/
- [ ] Slow, deep breathing in and out can calm the body when you feel stressed or anxious. (NHS, breathing exercises for stress): https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/
- [ ] Children feel better when they talk to an adult they trust about their worries; sharing a worry makes it smaller. (Childline (NSPCC)): https://www.childline.org.uk/
- [ ] Inclusion and kindness: inviting a child who is left out is a simple way to help. (UNICEF, how to talk to your children about bullying): https://www.unicef.org/parenting/child-care/how-talk-your-children-about-bullying

### Middle (about 9-11): The calm toolbox

The Expert try's twist: The unkindness is online too: a mean message about Pip-pop.

Steps:

- **hello**: words, then OK
  - Coach: "The Calm Corner. Today: a toolbox of calm, and some tricky moments with friends. Nothing you pick here is kept."
- **quarrel**: pick a picture
  - Coach: "Bobo and Mo both want the ball. Look at their faces. How do they feel?"
  - Picture (face_cross) right: "Both cross"
  - Picture (face_calm) not this one: "Both calm": "Look at their eyebrows and mouths: they both feel cross."
  - After: "Cross. Big feelings: first, calm down."
- **breathe**: breathe with the balloon `balloon` (breaths 4, in 3.0, out 3.0)
  - Coach: "Stop and breathe with them: slowly in while the balloon grows, slowly out. Four times."
  - After: "Calmer. Now we can think."
- **toolbox**: find them `tool_breathe, tool_count, tool_walk, tool_talk, tool_draw, tool_music` (need 3)
  - Coach: "The calm toolbox: pick three tools that help you calm down."
  - Found `tool_breathe`: "Slow breaths."
  - Found `tool_count`: "Count slowly to ten."
  - Found `tool_walk`: "A short walk."
  - Found `tool_talk`: "Talk to someone."
  - Found `tool_draw`: "Draw your feeling."
  - Found `tool_music`: "Calm music."
  - After: "Your own toolbox: use it whenever a feeling gets big."
- **say**: pick a picture
  - Coach: "Bobo wants to tell Mo how it feels. Which words help?"
  - Picture (talk) right: ""I feel cross when you take the ball.""
  - Picture (face_cross) not this one: "Shouting "You're mean!"": "Shouting makes the other person cross too. Say how you feel, calmly: "I feel... when...""
  - After: ""I feel... when...": calm words, clear words."
- **fair**: pick a picture
  - Coach: "Now they listen to each other. What is a fair way?"
  - Picture (join) right: "Take turns, or play together"
  - Picture (ball) not this one: "The biggest one grabs it": "Grabbing isn't fair. Taking turns, or playing together, is."
  - After: "Turns! They play together again."
- **unkind**: pick a picture
  - Coach: "In the playground, Mo says something unkind to Pip-pop. Pip-pop looks upset. What can you do?"
  - Picture (grown_up) right: "Stay with Pip-pop and tell a grown-up"
  - Picture (face_happy) not this one: "Laugh along": "Laughing along hurts Pip-pop more. Stay with her, and tell a grown-up."
  - Picture (question) not this one: "Do nothing": "Pip-pop needs a friend. Stay with her and tell a grown-up."
  - After: "Being a kind friend, and getting help: brave."
- **online** (Expert try only): pick a picture
  - Coach: "On the tablet, someone sends a mean message about Pip-pop. What do you do?"
  - Picture (grown_up) right: "Don't reply, keep it, show a grown-up"
  - Picture (message) not this one: "Send a mean message back": "A mean reply makes it worse. Don't reply: keep the message and show a grown-up you trust."
  - After: "No reply. A grown-up can help block and report it."
- **block** (Expert try only): touch it `block` (motion press, device tablet)
  - Coach: "With your grown-up, press BLOCK."
  - After: "Blocked: they can't message you now."
- **who**: pick a picture
  - Coach: "Who can help when someone is unkind?"
  - Picture (grown_up) right: "A teacher or a grown-up I trust"
  - Picture (question) not this one: "Nobody can": "Grown-ups can help: a parent, a teacher, someone at school. Keep telling until someone helps."
  - After: "Keep telling until someone helps."
- **now**: pick a feeling (any picture is right, nothing kept)
  - Coach: "How do you feel after practising? Any answer is fine."
  - Picture (face_calm) not this one: "Calm"
  - Picture (face_happy) not this one: "Happy"
  - Picture (face_worried) not this one: "A bit worried"
- **end**: words, then OK
  - Coach: "You calmed down with your toolbox, said how you feel, found a fair way, and stood by a friend. Those are real skills."

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "A feeling is getting big. First you..." **Stop and breathe** / Shout
- "Which words help in a quarrel?" **"I feel... when..."** / "You're mean!"
- "Two friends want the same ball. A fair way is..." **Take turns** / Grab it
- "Someone is unkind to a friend. You..." **Stay with them, tell a grown-up** / Laugh along

The "name it" card: **The calm toolbox**

1. Stop and breathe slowly.
2. Use your tools: count to ten, walk, talk, draw.
3. Say it calmly: "I feel... when..."
4. Find a fair way: take turns, listen.
5. Unkindness: stay with your friend, tell a grown-up you trust.

Its source line: CASEL's social and emotional learning, and anti-bullying advice (UNICEF, StopBullying.gov)

Try it for real: Make your calm toolbox at home: draw your three tools on a card and keep it in your bag. Tell your grown-up which ones you picked.

Your child can now: use a calm toolbox (breathing, counting, a walk, talking), say how they feel calmly, solve a quarrel fairly, and know what to do when someone is unkind

Sources:

- [ ] Relationship skills include communicating clearly, listening, cooperating and resolving conflicts constructively; responsible decision-making considers what is fair. (CASEL, the CASEL framework): https://casel.org/fundamentals-of-sel/what-is-the-casel-framework/
- [ ] When you see bullying: be there for the person, don't join in, and tell a trusted adult. (StopBullying.gov (US Department of Health and Human Services)): https://www.stopbullying.gov/
- [ ] Cyberbullying: don't respond, keep the evidence, block the person, report it, and talk to someone you trust. (UNICEF, cyberbullying: what is it and how to stop it): https://www.unicef.org/end-violence/how-to-stop-cyberbullying
- [ ] Slow, deep breathing can calm the body when you feel stressed. (NHS, breathing exercises for stress): https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/

### Big (12 and up): Pressure, and getting help

The Expert try's twist: The pressure grows: a whole group chat laughs at a post, and you are asked to add to it.

Steps:

- **hello**: words, then OK
  - Coach: "The Calm Corner. Today: pressure from friends, being unkind online, and knowing where to get help. Nothing you pick here is kept."
- **pressure**: pick a picture
  - Coach: "Friends say: share this silly photo of Mo, everyone will laugh. Mo didn't say yes. What do you do?"
  - Picture (phone_off) right: "Say no: I don't share it"
  - Picture (share) not this one: "Share it": "Sharing someone's photo without asking can hurt them a lot. You can say no, even to friends."
  - After: "No is a strong word. Real friends accept it."
- **mo_feels**: pick a picture
  - Coach: "How might Mo feel if it was shared?"
  - Picture (face_sad) right: "Hurt and embarrassed"
  - Picture (face_happy) not this one: "Happy": "Imagine it was your photo. Mo would probably feel hurt and embarrassed."
  - After: "Thinking how others feel helps you choose well."
- **group** (Expert try only): pick a picture
  - Coach: "A whole group chat is laughing at a post about Mo, and they ask you to add a joke. What do you do?"
  - Picture (grown_up) right: "Don't add to it; tell Mo you're there, tell a trusted adult"
  - Picture (share) not this one: "Add a joke, everyone is": "Even if everyone is, adding to it hurts Mo more. Stay out of it, support Mo, and tell a trusted adult."
  - After: "Standing apart from a crowd takes courage."
- **unkind**: words, then OK
  - Coach: "Now someone sends YOU a mean message. It is never your fault. Here is what to do."
- **reply**: pick a picture
  - Coach: "First: should you reply?"
  - Picture (message) right: "No: don't reply"
  - Picture (face_cross) not this one: "Yes, send something worse": "A reply gives them what they want and makes it bigger. Don't reply."
  - After: "No reply."
- **keep**: pick a picture
  - Coach: "Should you delete it straight away?"
  - Picture (grown_up) right: "Keep it to show a trusted adult"
  - Picture (question) not this one: "Delete it and tell nobody": "Keep it (a screenshot) so a trusted adult can see it and help report it."
  - After: "Kept, to show someone who can help."
- **block**: touch it `block` (motion press, device tablet)
  - Coach: "Press BLOCK."
  - After: "Blocked."
- **report**: touch it `report` (motion press, device tablet)
  - Coach: "Press REPORT, so the app knows."
  - After: "Reported."
- **breathe**: breathe with the balloon `balloon` (breaths 4, in 4.0, out 4.0)
  - Coach: "Messages like that can make your heart race. Breathe slowly: in for four, out for four. Four times."
  - After: "A slower heart, a clearer mind."
- **five**: find them `lamp, plant, window, books, cat, clock, fish` (need 5)
  - Coach: "Bring your mind back to the room: find five things you can see."
  - Found `lamp`: "A lamp."
  - Found `plant`: "A plant."
  - Found `window`: "The window."
  - Found `books`: "Books."
  - Found `cat`: "The cat."
  - Found `clock`: "A clock."
  - Found `fish`: "A fish."
  - After: "Back in the here and now."
- **when**: pick a picture
  - Coach: "When should you get help from an adult?"
  - Picture (grown_up) right: "A worry that won't go away, or someone hurting me"
  - Picture (question) not this one: "Never: I should cope alone": "Everyone needs help sometimes. Asking for help is brave, not weak."
  - After: "Asking for help is brave."
- **where**: words, then OK
  - Coach: "Where: a parent or carer, a teacher, a school counsellor, a doctor. Many countries have a free children's helpline too. Keep telling until someone helps."
- **now**: pick a feeling (any picture is right, nothing kept)
  - Coach: "How do you feel after practising? Any answer is fine."
  - Picture (face_calm) not this one: "Calm"
  - Picture (face_happy) not this one: "Strong"
  - Picture (face_worried) not this one: "A bit worried"
- **end**: words, then OK
  - Coach: "You said no to pressure, handled a mean message, calmed your body and know where help is. That is strength."

The before-and-after check (the same questions, the right one first here; the game mixes their order):

- "Friends push you to share someone's photo. You..." **Say no** / Share it
- "Someone sends you a mean message. First..." **Don't reply** / Reply with worse
- "A mean message: keep it or delete it?" **Keep it to show an adult** / Delete it and tell nobody
- "Asking an adult for help is..." **Brave** / Weak

The "name it" card: **Pressure, and getting help**

1. You can say no to pressure, even to friends.
2. Unkind online: don't reply, keep it, block, report.
3. Calm your body: slow breaths, notice five things.
4. Tell an adult you trust. Keep telling until someone helps.

Its source line: UNICEF's cyberbullying advice, CASEL's social and emotional learning, and Child Helpline International

Try it for real: With your grown-up, find the BLOCK and REPORT buttons in an app you use, and write down who you can talk to: at home, at school, and your country's children's helpline.

Your child can now: say no to pressure, deal with online unkindness (don't reply, keep it, block, report, tell), calm a stressed body, and know when and where to get help

Sources:

- [ ] If you are cyberbullied: don't respond, keep the evidence (screenshots), block the person, report it on the platform, and talk to someone you trust. (UNICEF, cyberbullying: what is it and how to stop it): https://www.unicef.org/end-violence/how-to-stop-cyberbullying
- [ ] Responsible decision-making and relationship skills include resisting negative social pressure and seeking help when needed. (CASEL, the CASEL framework): https://casel.org/fundamentals-of-sel/what-is-the-casel-framework/
- [ ] Free child helplines exist in more than 130 countries; Child Helpline International lists them. (Child Helpline International): https://childhelplineinternational.org/
- [ ] Slow breathing (for example in for a count of four, out for a count of four) can calm stress. (NHS, breathing exercises for stress): https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/
