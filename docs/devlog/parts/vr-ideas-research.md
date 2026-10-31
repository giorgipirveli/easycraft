# VR: hands, items and what else is exciting — the ideas research (owner #110, 2026-10-16)

The owner (#110, 11:24): "consider in vr mode we should have hands and be able to hendle items using vr joysticks,
research what can be done else, wjat exciting things with vr". Hands, the held item, the two-handed bow, opt-in swings,
VrPoseLink and the mirror were built in VR-RIG round 3. This note is the second half of #110: what the best VR games do
with hands, what the Quest 3 adds, what children love, what keeps them safe, and the ideas for EasyCraft ranked. It ends
with a proposed **VR round 4**.

Read first (and built on, never re-proposed): `docs/devlog/parts/vr-research.md` (the platform, the adaptation map, the
comfort risks, the budget), `vr-rig.md` (rounds 1-3), `vr-ui.md` (rounds 1-2). Web research on 2026-10-16. Sources are
numbered [S1]… and listed with their URLs in section 9. UNCONFIRMED marks what only the headset or a vendor can settle.
No code, no downloads, no other file changed.

**What EasyCraft's VR already has:** stand in your world; smooth walk with a comfort vignette; snap turn; teleport; a
laser to break and place blocks; menus as floating panels with a VR keyboard; a wrist HUD; both hands in the avatar's
colours; the held item in the hand; a two-handed bow; opt-in swings; other players see your head and hands; a mirror;
the rocket flown seated with an analog trigger; fade cuts; a 30-minute break card. Quest 2 at 72 Hz is the floor, the
owner's headset is a Quest 3, the renderer is Mobile (Vulkan), the store category is "Children" (ages 10-12: no Meta
Platform SDK).

## In short

- **The best VR games make the hand the controller.** You reach, squeeze and the thing is in your hand. Far things are
  pulled to you with a flick (Half-Life: Alyx). The held object can *become* the hand (Job Simulator's "tomato
  presence"). Throws use the hand's last moments of speed. Tools live on the body: a backpack over the shoulder, a
  hotbar on the wrist (Vivecraft, Alyx).
- **Children 10-13 are best served by kinematic hands** (they never push the body or wrestle physics), big targets,
  magnetism, "small motion, big result" throws, and things placed at hand height that can be raised or lowered
  (Owlchemy's adjustable desks).
- **The voxel insight:** an EasyCraft block is 1 m. A child's arm reaches about 0.6 m. So building "by hand" at normal
  size is clumsy. It works when the blocks are small in the hands: a **Build Table** of 10 cm blocks at hand height, or
  the world seen as a model from above (the **Giant's Table**). Both build on Size Magic's `world_scale`, which VR-RIG
  already drives.
- **The Quest 3 adds** hand tracking, colour passthrough (mixed reality), room scanning, depth occlusion, anchors and
  same-room discovery. The Godot OpenXR Vendors plugin 5.1.0 (installed) supports all of these except PCM haptics and
  (UNCONFIRMED) Meta's newer group sharing of anchors. None needs the Meta Platform SDK.
- **What children love that a flat screen cannot give:** holding something huge in your hands (a planet), being giant or
  tiny, things that look at you and answer your wave, hitting a real-feeling drum, looking through a telescope you hold,
  doing the experiment with your own hands.
- **Safety:** Meta: 10+, parent-managed 10-12, adult supervision, start short (30 minutes plus a 15-minute break).
  AAP: ~15-minute breaks, adults guide them. No open voice chat with strangers. A personal bubble round each child.
- **Round 4, the top 8** (after the shared grab foundation, "task 0"): hold a planet; a telescope and a magnifier in
  your hand; wave and high-five (buddies, pets, friends); the Lab bench by hand (float or sink, magnets); build with
  your hands (the Build Table); the Giant's Table (your world as a model); instruments you play; the cockpit you touch.
  Three agents, the owner's cap. Mixed reality (your world on your real table) is round 5: it builds on the Giant's
  Table.

## 1. What the best games do with hands

### 1.1 Grabbing: near and far

- **Half-Life: Alyx's gravity gloves** add a third stage to the usual "select, confirm" force pull: the object glows
  (select), the trigger locks it (so moving the hand no longer changes the target), and a pull gesture (a flick of the
  wrist) throws it to the hand. Each stage has its own sound. The flight is tuned so the object arrives catchable, not
  snapped [S1]. Valve's reason: moving around is "one of the highest-friction areas" of VR, so reaching far things from
  where you stand matters [S2].
- **Meta's Interaction SDK guidance** [S10][S11]:
  - combine distance grab with direct grab (never distance grab alone); add **magnetism** so targeting is easy;
    show which object is targeted with light and sound;
  - grab poses should match the object's size, shape and "virtual weight"; a pinch should turn into a palm grab
    without dropping the object; don't assume the same hand or the same fingers;
  - poke targets at least **22 × 22 mm with 12 mm between them**; select only when the fingertip really touches;
    "touch limiting" so the virtual finger does not pass through the panel; place controls where people naturally reach;
  - ray: don't make targets small or crowded; give a hover state;
  - long press: a clear delay (0.5 s), early release is a tap, never the main way to do something important.
- **Cubism** (one of the best-rated Quest games, built around small pieces) kept the hands **physics-free**: they pass
  through pieces until one is grabbed. With hand tracking, the fingertips that take part in a grab light up, and the hand
  turns red when it is badly tracked [S16].

### 1.2 Holding

- **Tomato presence** (Owlchemy, Job Simulator): the hand is hidden while it holds an object, and the feeling of having
  a hand carries over to the object. "Players can continue to have full hand presence with visuals other than their
  hand" [S4][S5]. EasyCraft shows the mitten *and* the item today; for tools that is right (the child sees the grip).
  For small round things (a planet, a ball, a magnet) hiding the mitten avoids the fingers clipping through them.
- **Two hands:** in Blade & Sorcery big weapons need both hands to be steady, a hand can slide along a handle without
  letting go, and weight shows as the object lagging behind a hand that moves too fast; players tune the springs
  themselves [S12]. EasyCraft's bow is already two-handed; the same "second hand steadies or scales" idea fits a planet
  (two hands stretch it bigger) and a telescope (two hands hold it still).

### 1.3 Throwing

- Weak throws usually come from too much smoothing of the hand's speed: use the **fastest last frames**, a short
  window, and a velocity scale above 1 [S22]. Research on the moment of release finds wrist motion and rotation the
  best signals [S22].
- For children, a scale above 1 is also a safety tool: a **small flick throws far**, so nobody has to swing an arm
  hard in a living room.

### 1.4 Tools, pockets and the body as the inventory

- **Vivecraft** (Minecraft Java in VR) [S7]: break blocks and fight by swinging the hand; eat by bringing food up to
  your face; drink by turning the bottle over; draw a bow by nocking an arrow; reach behind your head to get hotbar
  slot 1 or swap the hands' items; touch a hotbar slot on the wrist to pick it; the hotbar sits on the inside of the
  forearm; a "VR Interact": touch a block with either hand and squeeze to use it; climb ladders and vines by touching
  and pulling; roomscale crouch and jump; breaststroke to swim; row boats with your arms; climbing claws [S8].
- **Alyx** stores ammo with an over-the-shoulder reach into a backpack and has wrist pockets; the gloves show health
  and ammo [S1][S3].
- Mojang removed VR from Minecraft Bedrock in 2025; the only Minecraft VR left is the unofficial Vivecraft and its Quest
  port QuestCraft [S9]. There is room for a child-friendly block game that is good in VR.

### 1.5 Moving with your hands

- **Gorilla Tag** moves you with your arms only: "no buttons, no sticks, no teleportation"; you push off surfaces, and
  holding on makes you fall. Voice chat is on by default [S6].
- Body-based movement causes less sickness than a stick in a thesis on embodied locomotion [S26]. But arm locomotion
  in a living room means fast swings near furniture: opt-in at most for EasyCraft (ruling R11).

### 1.6 Physics hands or ghost hands

- The common pattern: a physics hand stops at walls, and a faint ghost shows where the real hand is. The Godot 4 VR
  physics template does it with a small `CharacterBody3D` per hand that `move_and_slide`s after the controller [S14].
  The gap shows most at the moment of contact [S14].
- Full-body physics (Bonelab) is impressive but players call grabbing and climbing "fiddly" [S13].
- **For EasyCraft:** kinematic hands, with the *picture* of the hand stopped at a block's face (one short sphere cast
  per hand per frame against the voxel collision that already exists near the player) and a faint outline where the
  real hand is when the two are more than 3 cm apart. Held things are kinematic while held and get the hand's speed when
  let go. The body is never pushed by the hands (ruling R2).

### 1.7 Building by hand

- **LEGO Bricktales (Quest):** reviewers call building the highlight: zooming into dioramas on "a virtual table in your
  lap" is more intuitive than on a console; bricks go in only one way, so snapping is satisfying; mixed reality is
  "just a plain passthrough" there; the warning: "it's easy to lock into bad neck and back positions" bending over the
  model [S15].
- **Demeo's mixed reality:** the board snaps onto a real table that the Quest knows and scales to fit it [S21].
- **The voxel lesson:** EasyCraft's blocks are 1 m; within arm's reach only one or two cells fit. At GIANT (×3) a block
  is 33 cm in the hands; at ×10 it is 10 cm, a toy brick. Hand building belongs at a small scale (ideas 5 and 6).

### 1.8 Characters, social play, small and seated players

- **Moss:** the mouse hero makes eye contact, points at puzzle answers, high-fives the player, and you can pick her up
  and feel her heartbeat. Polyarc wanted players to believe she "has a soul"; the world is a diorama within arm's reach,
  and the fixed viewpoint avoids sickness [S20].
- **Walkabout Mini Golf:** up to 8 friends in a private room, cross-play, and hunting lost balls round the course [S17].
- **Rec Room:** Junior accounts (under 13) limit voice and text chat, usernames, where they can create, and mature
  content; youth workers advise private rooms rather than public ones [S18]. ("Toast" in the brief: no VR title of that
  name with design writing was found; Rec Room is covered here.)
- **Owlchemy's accessibility update for Cosmonious High:** one-handed mode (also when a battery dies), seated play that
  adjusts to the eye height, every table "like a standing desk" with a handle, a "small student" mode, and easier grabs
  that need less precise movement [S19]. EasyCraft's game height already covers the eye; the adjustable table is the
  piece to copy for the Lab bench and the Build Table.

## 2. What the Quest 3 adds, and what Godot can use today

The plugin is **Godot OpenXR Vendors 5.1.0**, installed in `addons/godotopenxrvendors/` (its changelog is the repo
evidence [S39]). Every feature below is an OpenXR extension; none uses the Meta Platform SDK, which the "Children"
category forbids [S78].

| Feature | What it gives | In Godot 4.7.2 + Vendors 5.1.0 | Fit for EasyCraft |
|---|---|---|---|
| **Hand tracking** (no controllers) | 26 joints per hand; pinch, poke, grab; Meta recommends controllers for fast games [S45] | Core: `XRHandTracker`, `XRHandModifier3D` (Bone Update Full or Rotation Only), the hand interaction profile (`XR_EXT_hand_interaction`: pinch, grasp, poke pose) in the same action map as controllers [S40]. Plugin: `OpenXRFbHandTrackingMesh` (Meta's skinned hand), `OpenXRFbHandTrackingAimExtension` (pinch strengths 0-1, `index_pinch`, the menu gesture on the left hand), `OpenXRFbHandTrackingCapsulesExtension` (collision capsules) [S32]; `OpenXRMetaSimultaneousHandsAndControllersExtension` (one hand on a controller, the other free) [S38]; microgestures (thumb tap and swipes on the index finger) registered in Godot's OpenXR code [S44] | Good for calm things: School lessons, menus, the keyboard, petting. Not for walking or fighting. Later (idea 14). |
| **Passthrough** (colour on Quest 3, grey on Quest 2) | Mixed reality: the room shows, the game draws over it | `OpenXRFbPassthroughExtension`; set the viewport's `transparent_bg`, the environment's background to a colour with alpha 0 and `environment_blend_mode = XR_ENV_BLEND_MODE_ALPHA_BLEND`; a passthrough loading screen; filters (colour map, LUT); `OpenXRFbPassthroughGeometry` for hole-punched areas [S31]. On the Mobile renderer: UNCONFIRMED (the docs show the settings, no renderer note) | The tabletop world (idea 9), the portal (idea 20). Round 5. |
| **Scene** (walls, doors, tables; Quest 3: the room's mesh) | Where the real table and walls are | `OpenXRFbSceneManager` under `XROrigin3D`; per-label scenes; `request_scene_capture()`; signals `openxr_fb_scene_data_missing`, `openxr_fb_scene_capture_completed`; the Scene API setting [S34]; a spatial-data permission (UNCONFIRMED wording on the device) | Put the world model on the real table (idea 9); keep MR things inside the room's walls [S46]. |
| **Depth API** (environment depth) | Real things hide virtual ones (a sofa hides a pet) | `OpenXRMetaEnvironmentDepth` under the `XRCamera3D`, or the global shader uniforms (`META_ENVIRONMENT_DEPTH_TEXTURE`); `start_environment_depth()` / `stop_…`; optional hand removal; it costs GPU, stop it when not needed [S33] | Only in MR scenes (ideas 9, 20). "Hello, Dot" shows why children love it: the pet hides behind real things [S49]. |
| **Spatial anchors** | A place in the room that stays across sessions | `OpenXRFbSpatialAnchorManager`: `create_anchor`, `load_anchors(… STORAGE_LOCAL …)`; the game saves its own data beside the UUIDs [S35] | "My table is here" remembered (idea 9). |
| **Same-room discovery and shared anchors** | Two headsets in one room find each other and share one coordinate frame | `OpenXRMetaColocationDiscoveryExtension` (Bluetooth; a payload of at most 1024 bytes; one advertisement and one discovery at a time) [S37]; `OpenXRFbSpatialEntitySharingExtension` (the older, user-based sharing) [S38]. Meta's newer group sharing (v71+, no user IDs) [S43]: no Godot class seen (UNCONFIRMED). Meta's restrictions: colocation discovery works only for verified developer teams, test users or release-channel invitees outside production; shared anchors need internet and a dashboard permission [S43]; whether a "Children" app may turn that permission on: UNCONFIRMED (child apps cannot complete a Data Use Checkup [S78]) | Two children in one room playing on one shared table (idea 16). Later. |
| **Haptics** | Buzzes; Touch Plus has a voice-coil motor that plays different frequencies [S42] | Core: `XRNode3D.trigger_haptic_pulse(action, frequency, amplitude, duration, delay)` [S41]. EasyCraft's `Vr.haptic` passes frequency 0.0 (the runtime's default) today. PCM haptics (`XR_FB_haptic_pcm`) have no Godot class [S38]: not available | Frequency per material and per event (a low rumble for the engine, a high tick for glass): cheap (idea 17, and inside 7 and 8). |
| **Spatial audio** | Sound from the right place, HRTF | Godot's `AudioStreamPlayer3D` pans and attenuates; no HRTF. Nexus Resonance (Steam Audio, MIT, Godot 4.6+) has HRTF; its Android/Quest binaries are UNCONFIRMED [S48]. Meta XR Audio has no Godot plugin [S48] | The listener is already the head (`vr-research.md`). HRTF: not now (idea 21). |
| **Composition layers** | Sharper panels drawn by the compositor | `OpenXRCompositionLayerQuad`; Meta filter settings (sharpening, supersampling) [S36] | VR-UI ruled it out for WebXR; a native-only eye panel stays a P5 option if text is soft. |
| **Passthrough Camera API** | Raw camera frames | Meta allows it with the camera permission; the frames are "Device User Data" [S47] | **Never** in a children's game (ruling R10). |
| **Boundary visibility** | Hide the boundary in passthrough apps | `OpenXRMetaBoundaryVisibilityExtension` [S31] | Never hide it in a full-VR scene; only MR scenes inside the room may. |
| **Body tracking** | Upper body from the cameras | `OpenXRFbBodyTrackingExtension` [S38] | Not needed: VrPoseLink's head and hands are enough. |

Godot XR Tools 4.5.2 (MIT, not installed) has pickables with ranged grab and an impulse factor for throws, snap zones,
climbing grab-points, hand-pose detection, collision hands and a two-handed "world grab" that turns and scales the
world [S23]. It is a reference for our own small classes; adding it needs the owner's yes for a download and is not
required.

## 3. What children love in VR that a flat screen cannot give

- **Being big or small changes how big the world looks.** In "Being Barbie", people given a doll-sized body saw the
  same cubes as larger and farther away, and a giant body made them look smaller and closer; it worked only when the
  body felt like their own [S60]. EasyCraft's Size Magic in VR (`world_scale`) is exactly this. Next: let the child *use*
  the size (build in the hands as a giant; look at the world as a model).
- **Holding something huge.** Titans of Space shrinks the solar system a millionfold so Earth is a 12.7 m ball, and
  players can hold a planet in their hands; reviewers call it one of the best educational VR apps [S61].
- **Things that notice you.** Moss's eye contact and high-fives build a bond; a child tester talked about the hero for
  a week [S20]. VR characters influence young children more than TV characters do (Stanford, Bailey and Bailenson,
  2017) [S68], which is power to use gently.
- **Flying, with a frame.** Eagle Flight found sickness came from fast things in the side view and narrowed the view in
  sharp moves ("dynamic blinders") [S24]. Meta: cabins and cockpits reduce optic flow [S25]. EasyCraft's capsule and
  vignette already follow this.
- **A launch felt from the seat.** Apollo 11 VR puts you in the seat with the countdown on the radio [S67]; the museum
  version shakes the seats [S67]. In a headset the shake must be a buzz, never a camera move.
- **Doing it with your hands.** Embodied, gesture-based mixed-reality science lessons gave larger gains than ordinary
  teaching in Johnson-Glenberg's studies [S64]; an algebra RCT with VR (Prisms, 514 students, grades 8-9) beat the
  normal class on its own test [S62]. **But** adding VR to a science simulation gave students more presence and *less*
  learning, with more cognitive load (Makransky, Terkildsen and Mayer, 2019) [S63]. So: one thing at a time, short
  words, the hands do the experiment and the words come after. The Lab's "predict, try, why" order fits that.
- **Drawing in space.** Children of 10-12 improved their 3D drawing in VR in a small Utrecht study (spatial test scores
  did not move) [S65]; art students "draw in space using their bodies" with Tilt Brush [S65].
- **Music you hit.** Paradiddle (VR drums) has beginner lessons and 50+ percussion instruments, xylophone and
  glockenspiel included; a hit sounds different by where and how hard [S66]. The School already has music units
  (instrument families, the orchestra, ostinato layers, rhythms).
- **Pets in your room.** Niantic's "Hello, Dot" on Quest 3: grab the creature from the air, dip it in paint, point to a
  spot, feed it; it hides behind real objects (depth occlusion) [S49].
- **Playing together.** Gorilla Tag's arm chases and voice chat made it a hit [S6]; Walkabout Mini Golf's private
  rooms of 8 friends [S17].

## 4. Safety and comfort for children

**What the platform and the experts say**

- **Age.** Meta: no one under 10; ages 10-12 need a parent-managed account (Quest 2 and 3 only) [S70][S78]. The Quest 3
  warnings: "Not recommended for use by younger or smaller-sized children or if the headset cannot be adjusted to fit
  properly", and "Children's use of Meta Quest should always be supervised by an adult" [S71]. Children's "eyes, necks,
  backs and strength may not allow them to use Meta Quest comfortably" (Meta) [S71]. The headset is about 515 g, mostly
  at the front (secondary sources) [S80].
- **Session length.** Meta: start short, "a maximum use period of 30 minutes plus a break of 15 minutes", regular
  breaks [S71]; a 2-hour daily limit by default for parent-managed accounts, and younger children "should take more
  frequent longer breaks" [S70]. AAP: breaks of about 15 minutes between sessions; children "might not instinctively
  remove the headset when it feels wrong", so adults set the breaks; play in shared rooms so adults can watch [S69].
  Common Sense Media with Stanford (2018): measure VR in minutes, not hours; 5-10 minute stretches for young children
  and about 20 for older ones; sit when possible; a "spotter"; ask "would I want my child to have this experience in the
  real world?" [S68]. EasyCraft's 30-minute break card (VR COMFORT, I'M BACK) matches Meta's figure.
- **Cybersickness and children.** The research is thin: children are "severely understudied", and the age findings
  conflict [S79]. Treat every child as sensitive: the existing defaults (snap turn, vignette, teleport, fade cuts, no
  shake) stay.
- **Eyes and IPD.** The Quest 3 lens spacing runs 58-70 mm and supports IPDs of 53-75 mm [S72]. Children's IPD grows
  from about 51 mm at 5 to about 63 mm in adults [S73], so most 10-13-year-olds sit at the low end: the parent should
  use the smallest lens step when the picture is blurry (Meta's IPD help). The AAP cites a study of 50 children aged
  4-10 with no clinically significant change in vision [S69]. Photosensitivity: about 1 in 4,000 people [S71]; VR's
  flash caps (FeelRules, the halved flashes) stay.
- **The play space.** Meta's boundary has stationary and roomscale modes and must be set again in a new place [S74];
  Meta's developer docs give a 6 × 6 ft playable area for roomscale, and seated play should need no more than a reach
  or a lean [S74]. Passthrough "is not as clear or wide as your natural vision" and "cannot show physical objects that
  are dynamic, unmarked, or have moved since being marked" [S71]; Meta recommends the boundary for every immersive app
  [S46].
- **Voice chat and strangers.** CCDH found minors in 66 of 100 Horizon Worlds recordings and 19 incidents of abuse aimed
  at minors by adults; in VRChat about 100 potential violations in 11.5 hours, only half reportable [S75]. Meta's own
  teen defaults garble the voices of people a teen does not know [S77]; Rec Room's Junior accounts limit voice and text
  [S18]. Meta's Personal Boundary keeps avatars about 1.2 m apart by default (high-fives still work across it) and,
  before that, hid hands that came into someone's personal space [S76]. The AAP flags "fantasy-reality blurring" in
  young children [S69].
- **Mixed reality.** Keep MR content inside the room's known walls and off marked furniture; teach clearing the floor
  [S46].

**What this means for round 4 (each idea's notes below apply these)**

1. Nothing new needs fast or big arm motion. Throws are amplified flicks; swings stay opt-in.
2. Every hand-height thing (the Lab bench, the Build Table, the instruments) can be raised and lowered with one handle
   and starts at the eye height minus 0.45 m (the seated child too). No floor reaching: anything on the floor can be
   pulled to the hand.
3. A **personal bubble**: other players' hands (and heads) fade out inside 0.5 m of the child's head (Meta hid hands in
   personal space for the same reason [S76]).
4. **No open voice chat in VR** (ruling R9). Hands are the social language: waves, high-fives, thumbs-up.
5. The view never moves by itself (VR-RIG ruling 3 still holds): scale changes and "model view" jumps are behind a
   blink; nothing rotates the world smoothly.
6. Sound: every new sound goes through `Loudness` (core/rules/loudness.gd); instruments are capped.
7. Session: the break card stays at 30 minutes; the new "focus" activities (the Build Table, the Lab) are seated-friendly.

## 5. The ideas, ranked

### 5.1 The score

**Score = (fun for a child × learning value) ÷ effort.** Fun 1-5 (the lead's judgement from the research above).
Learning 1-5 (5: a School unit is done with the hands; 1: no learning). Effort S = 1 (a few days of one agent), M = 2
(a round of one agent), L = 3 (more than a round, or new platform risk). Ties go to the smaller one.

### 5.2 The ranking

| # | Idea | Fun | Learn | Size | Score |
|---|---|---|---|---|---|
| 1 | Hold a planet: the solar system in your hands | 5 | 5 | M | 12.5 |
| 2 | Lens tools: a telescope and a magnifier in your hand | 4 | 3 | S | 12 |
| 3 | Wave and high-five: buddies, pets and friends answer your hands | 5 | 2 | S | 10 |
| 4 | The Lab bench by hand: float or sink, and magnets | 4 | 5 | M | 10 |
| 5 | Build with your hands: the Build Table (and the School's block answers) | 5 | 4 | M | 10 |
| 6 | The Giant's Table: your own world as a model you hold | 5 | 4 | M | 10 |
| 7 | Instruments you play: xylophone and drums | 4 | 4 | M | 8 |
| 8 | The cockpit you touch: buttons to poke, the engine's rumble | 5 | 3 | M | 7.5 |
| 9 | Your world on your real table (mixed reality) | 5 | 4 | L (M after 6) | 6.7 (10 after 6) |
| 10 | Walk-in wonder models: inside a volcano, the Earth's layers, a flower | 4 | 5 | L | 6.7 |
| 11 | Draw in the air | 4 | 3 | M | 6 |
| 12 | Fly a kite on a string | 3 | 2 | S | 6 |
| 13 | Grab, pocket and throw (the foundation, "task 0") | 5 | 2 | M | 5 |
| 14 | Hand tracking: put the controllers down for lessons and menus | 3 | 3 | M | 4.5 |
| 15 | Pet, feed and hold small animals and pets | 4 | 2 | M | 4 |
| 16 | Two headsets, one room (same-room play) | 5 | 2 | L | 3.3 |
| 17 | Feel the world: haptic textures | 3 | 1 | S | 3 |
| 18 | Climb with your hands | 5 | 1 | M | 2.5 |
| 19 | Crouch and jump for real | 2 | 1 | S | 2 |
| 20 | A portal in your room (mixed reality) | 5 | 1 | L | 1.7 |
| 21 | HRTF spatial sound | 2 | 1 | L | 0.7 |

Idea 13 scores low on its own but ideas 1, 4, 5, 6, 7 and 8 all use it, and it is the owner's own ask ("handle items").
It goes first in round 4 as task 0.

### 5.3 Each idea

#### Task 0 (idea 13). Grab, pocket and throw — the foundation (M)

- **What a child sees and does.** A hand near something it can take glows its outline and gives a soft tick. Squeeze
  the grip: the mitten closes and the thing is in the hand. Something far away (a coin, a pickup bag, a planet on its
  orbit, a mallet on its stand): point, it glows; squeeze the grip to lock it; flick the wrist up: it flies into the
  hand (Alyx's three stages [S1]). Small round things hide the mitten while held (tomato presence [S4]). Let go with a
  little flick: it flies far. Drop a thing over your shoulder: it goes into the bag (Vivecraft's backpack [S7]).
- **How to build it.**
  - `core/vr/vr_grab_rules.gd` (pure, tested): the near pick (the nearest grabbable within 0.10 m of the grip point,
    a little magnetism toward the hand's forward), the far pick (the laser's target with a 6° cone for magnetism), the
    lock and flick (wrist upward speed over 1.2 m/s within 0.3 s; or the grip held 0.6 s, for children who can't
    flick), the release speed (the peak of the last 0.1 s, ×1.5, capped at 12 m/s), the over-the-shoulder zone (behind
    the head plane, above the shoulder).
  - `entities/vr/vr_grabbable.gd` (a small node a thing adds: `grab_points`, `two_hand` mode none / steady / scale,
    `hide_hand`, signals `grabbed(side)`, `released(side, velocity)`, `scaled(factor)`), and `entities/vr/vr_grabber.gd`
    per hand (reads `Vr.hand_grip(side)`, the grip value through `VrInput.read(side, "grip")`, and drives
    `VrHandModel`'s fist).
  - Held things are kinematic; on release a `RigidBody3D` (Jolt) gets the velocity; other things decide what a release
    means (snap back to an orbit, land in a bin).
  - **The grip's two jobs (ruling R1):** today the grips step the hotbar (L1/R1). New: the grip grabs when something is
    grabbable in reach or under the laser; otherwise it steps the hotbar exactly as now. The wrist hotbar's slots become
    touchable by the other hand's index finger (Vivecraft's touch hotbar [S7]).
  - The picture of the hand stops at a block's face (one sphere cast, radius 0.05 m, from the wrist to the grip point,
    against the near collision) with a faint outline where the real hand is (section 1.6).
  - Network: what is held is shown to friends through VrPoseLink's existing grip bits plus the held item it already
    sends; no new sync field.
- **Comfort and safety.** No floor reaching (the pull); throws amplified, never needed for progress; no pushing the
  body; the grab outline and tick so a child knows it worked (Meta's feedback rule [S10]).
- **Score:** fun 5 × learning 2 ÷ M = 5 (the foundation).

#### 1. Hold a planet: the solar system in your hands (M) — score 12.5

- **What a child sees and does.** The Star Map in VR is a moving orrery in front of the child at chest height, about
  1.6 m across: the Sun in the middle, the planets on their orbits where they really are today (the flat map's data),
  their moons going round. Reach out and take Jupiter: it leaves its orbit and sits in the hand, its bands turning.
  Hold it with both hands and pull them apart: it grows. Take Earth in the other hand: Jupiter is eleven Earths across.
  The card's three facts are read aloud. Press TRUE SIZE: everything takes its real size against the Sun (the Sun is
  109 Earths across). Let go: it floats back to its orbit. To fly there, drop the planet into the glowing ring by the
  rocket's icon: LAND, as today.
- **How to build it.** `entities/vr/vr_orrery.gd`, made by `SpacePanel` when `Vr.active()` (the 2D map stays on the eye
  panel for the cards and the buttons). Bodies from `StarMap` (core/rules/star_map.gd: colours, bands, Saturn's ring,
  `longitude` of the date); one `MultiMeshInstance3D` of spheres with per-instance colour and band (one draw), Saturn's
  ring and the Sun separate, moons in the same MultiMesh. Grab and two-hand scale through task 0 (`two_hand = scale`,
  0.5× to 4×). The size ratios come from the data the cards already use; a test checks Jupiter/Earth and Sun/Earth. The
  existing `PlanetGuideCard` shows the facts; LAND reuses `travel_requested`.
- **Comfort and safety.** The child stands still; the objects move, never the world. The Sun's glow capped (no
  flashes). Within reach (no walking into the room's edge): the orrery's radius 0.8 m, its centre 0.5 m ahead.
- **Learning.** g4 science "rockets and explorers", the cosmos (spec §21b), scale and ratio (maths). Fun 5, learning
  5.

#### 2. Lens tools: a telescope and a magnifier in your hand (S) — score 12

- **What a child sees and does.** A telescope item: hold it up and look into its round lens. Far things come close
  inside the lens: an animal across the valley, a landmark, the Moon in the night sky where the sky draws it. A
  magnifier: hold it over a leaf block and see the leaf's veins; over sand and see grains; a short fact the first time
  ("Sand is tiny bits of rock and shell").
- **How to build it.** Reuse `VrPhotoCamera`'s pattern (a `SubViewport` camera on the hand, a small screen above the
  hand): a round 512 × 512 lens, a narrow field of view (telescope 6-10°, magnifier at a short range), drawn only while
  held. The lens camera's rotation is smoothed (a steady filter: a zoomed hand tremor is magnified too). The close-up
  pictures for the magnifier are a small table of block id → a CC0-or-our-own texture and a fact (Survivor finds the
  telescope; the Sandbox has both). Off VR on phones: the same items as a zoom view in the HUD (a later small task).
- **Comfort and safety.** The zoom is only inside the lens, never the whole view (a zoomed full view breaks the head's
  match with the world). The lens is world-locked to the hand.
- **Cost.** A second, small render of what the lens sees; a narrow frustum keeps it to a few draws (measure in
  VR_BENCH).
- **Learning.** g4 "light and seeing", astronomy, materials. Fun 4, learning 3.

#### 3. Wave and high-five: buddies, pets and friends answer your hands (S) — score 10

- **What a child sees and does.** Buddies' googly eyes and pets' heads turn to look at the child when near (Moss's eye
  contact [S20]). Wave (a hand above the shoulder, side to side): the buddy hops and waves back, animals look up, a bot
  friend waves. After a wave the buddy holds up a paw: slap it: a clap, sparkles, both controllers buzz. A friend in VR
  waves: the child sees it (VrPoseLink already sends the hands); hands that meet at speed clap for both. Thumbs-up shows
  a small "+1" over the name tag.
- **How to build it.** `core/vr/vr_gesture_rules.gd` (pure): wave (two direction changes within 1.2 s, the hand above
  the shoulder), high-five (two hands meeting at a closing speed over 1 m/s), thumbs-up (grip closed, thumb off the
  thumbstick: the action map's `thumbstick_touch`, UNCONFIRMED binding). Buddy eyes: `Buddy._eye` nodes' pupils offset
  toward `Vr.camera` within 8 m. Animals and pets: a head turn already used by their minds' "look at" (if none, a
  yaw-only turn). A high-five with a remote player is detected on each side for its own hand against the other's drawn
  hand; a short reliable RPC on the existing `VrPoseLink` node says "clap" (no sync change).
- **Comfort and safety.** The **personal bubble** (section 4): another player's hands fade inside 0.5 m of the head,
  so nobody can push hands into a child's face; high-fives happen at arm's length. Only gestures, no voice.
- **Learning.** Social: greeting and kindness (small). Fun 5, learning 2.

#### 4. The Lab bench by hand: float or sink, and magnets (M) — score 10

- **What a child sees and does.** Tap the lab bench block: in VR a real bench stands in front of the child at hand
  height (a handle lifts or lowers it, Owlchemy's standing desk [S19]). **Float or sink:** a glass tank of water and a
  shelf of little cubes (wood, ice, a leaf, a sponge, stone, iron, gold, glass). First sort them with your hands into
  two baskets, FLOAT and SINK: that is the prediction. Then drop each one in: it bobs at the top or sinks to the bottom.
  **Magnets:** hold the magnet and bring it to each cube: iron jumps and clicks onto it (a buzz), the others stay put.
  The "why" cards come after, on the panel, read aloud, and the Lab Book gets the star as today.
- **How to build it.** `entities/vr/vr_lab_bench.gd` opened by `LabPanel` in VR (the panel keeps the predict prompt and
  the why cards). The outcome of every cube comes from the tested pure models (`core/lab/lab_tank.gd`,
  `lab_magnet.gd`, `lab_experiments.gd`, the data in `data/lab/*.json`): the 3D only *shows* it (a bob or a sink tween,
  no buoyancy physics), so the facts stay those `test_lab_content.gd` checks. Grabs through task 0; the baskets are snap
  zones; the sort becomes the existing "sort" prediction form's answer. The other four experiments later (heat, colours,
  plants, the circuit: wires that snap to posts).
- **Comfort and safety.** Seated-friendly; nothing on the floor; no fire play (the burner stays a lab burner "used with a
  grown-up", spec §23.2).
- **Cost.** About 12 small meshes in one MultiMesh plus the tank: a few draws, only while the bench is open.
- **Learning.** g3 materials and buoyancy, magnets (spec §23.1); the scientist's order (predict, try, why), and
  Makransky's warning [S63] is why the words come after the doing. Fun 4, learning 5.

#### 5. Build with your hands: the Build Table (M) — score 10

- **What a child sees and does.** BUILD TABLE (on MORE, or the Sandbox's palette): a floating table at hand height with
  a 16 × 16 grid, each cell 10 cm. Pull a block from the wrist hotbar (or hold the selected block in the hand); a ghost
  cube snaps to the grid where the hand is; squeeze the trigger: it is placed with a click (LEGO Bricktales' snapping
  [S15]). Touch a block and hold the trigger: it breaks (the break ring). The paint bucket paints by touch; MIRROR shows
  its plane as a glass sheet on the table. Turn the table with two hands (in 90° steps). Finished: SAVE AS STAMP (My
  Stamps, then place it in the world like any stamp, one undo) or WAKE IT (it becomes a buddy in the world: build a
  little dog in your hands, then it walks beside you). The School's "build the answer with blocks" rounds use the same
  table in VR: an array for 3 × 4, an area, a volume, a symmetric shape.
- **How to build it.** `entities/vr/vr_build_table.gd` (a MultiMesh per block atlas material: a few draws) with the
  table's own small grid model (`core/building/build_table_rules.gd`, pure: snap, the cell under the hand, the 16-a-side
  cap). It saves through `MyStampBook` (MAX_SIDE, `EditBatch.MAX_BATCH`) and wakes through the buddy path (`Buddy`,
  `BuddyMagicDirector`; the 200-block cap). Mirror through `MirrorRules`, paint through `PaintRules` (never a block with
  a job). The School's block exercises: their checker reads the table's cells in VR (the exercise data unchanged).
  Follow-up (S): as a GIANT (×3, blocks 33 cm in the hand) the same ghost-at-the-hand placement works right in the
  world, through `BlockInteractor`'s host-checked edits.
- **Comfort and safety.** The table at hand height and adjustable (no bending over a model: LEGO Bricktales' neck
  warning [S15]); arms below the shoulders; seated works.
- **Learning.** Spatial reasoning, symmetry, area and volume, the School's maths units. Fun 5, learning 4.

#### 6. The Giant's Table: your own world as a model you hold (M) — score 10

- **What a child sees and does.** In the Sandbox, press MODEL VIEW: a blink, and the child is a giant 40 m tall standing
  in their own world: the land around them is a model about 5 m across on the floor at their feet, every build and
  animal tiny and alive. Turn the world with both hands in steps; walk round it in the room. See their own avatar
  standing in it, small. Pick the avatar up and put it down somewhere else: another blink and they are there, normal
  size (a teleport). Hold a tiny house stamp and put it on a hill: the house is built there (one undo).
- **How to build it.** Size Magic's `Vr.set_world_scale` already scales the play space; MODEL VIEW sets about 25 behind
  a blink and anchors the origin at a model spot above the player (the body stays where it stood, still, as in a
  seated anchor). The 64-block view distance becomes a 2.5 m radius round the feet: no new terrain work. Grab the avatar
  through task 0; its drop point goes through `TeleportRules.check` and the games' `vr_teleport_refuse` (so a race or a
  round refuses). Stamps through the existing stamp edit. World turning: the origin turns 45° per two-hand twist (never
  smooth).
- **Comfort and safety.** The ground is at the real floor, so there is no height fear; scale changes and every jump are
  behind a blink; no smooth rotation (Meta: optic flow and vection [S25]); Sandbox only, and a ghost of the boundary
  is respected (the model is centred on the child).
- **Cost.** The same chunks render; measure the far plane and fog at scale 25 (UNCONFIRMED that the sky and fog look
  right scaled).
- **Learning.** Maps and a bird's-eye view (g4 "earth maps", g6 "detailed maps", "maps with layers"), scale. Fun 5,
  learning 4.

#### 7. Instruments you play: xylophone and drums (M) — score 8

- **What a child sees and does.** Two music blocks: a xylophone and a drum (bongos). In VR, near one, a mallet appears
  in each hand (or two drumsticks). Hit a bar: a note; longer bars are lower (the sign says so). Hit the drum harder: it
  is louder. LOOP records 4 bars and plays them back while the child plays over them. A friend plays the drum while the
  child plays the xylophone. On a phone, a tap on a bar plays it, so the blocks are for everyone.
- **How to build it.** Two block ids and atlas tiles from the lead (allocation). The notes are our own: a tool script
  renders the tones (a simple bell and wood timbre) to `.ogg` files, credited as our own work in `assets/CREDITS.md`
  (ruling R12). `AudioStreamPlayer3D` from the bar, through `Loudness`. The mallet's tip is an `Area3D`; the hit speed
  sets the volume and a short haptic pulse with a frequency per note (`trigger_haptic_pulse`'s frequency [S41]: Touch
  Plus plays it [S42]). The loop is a list of (time, note) events; friends get the notes by RPC as events, never audio.
- **Comfort and safety.** The instrument's reach zone is in front and small (no wild swings); a volume cap; no hearing
  risk from stacking loops (a cap of 3 layers).
- **Learning.** g3 "instrument families", g4 "ostinato layers", g4 science "sound" (pitch and length), rhythm. Fun 4,
  learning 4.

#### 8. The cockpit you touch: buttons to poke, the engine's rumble (M) — score 7.5

- **What a child sees and does.** In the seated capsule the dashboard is 0.55 m ahead: in reach. Big buttons light up:
  STAGE, LEGS, LIGHTS. Poke them with a finger (a click, a buzz, the button goes in). On the burns both controllers
  rumble low, stronger with more throttle; the stage separation is a thump; the touchdown is the round 3 buzz. The
  countdown's last three seconds tick on the hands.
- **How to build it.** The dashboard quad (`RocketFlight.vr_dashboard()`) gets a few poke targets from
  `FlightCockpit` (each at least 40 × 40 mm, twice Meta's 22 mm minimum [S10], 15 mm apart); the index fingertip of the
  hand model is the poker with touch limiting (the finger stops on the panel). This changes VR-UI's ruling 22 ("the
  dashboard is a display") for those buttons only; A and the trigger keep working as now. The rumble: `Vr.haptic` gains
  a frequency (default 0.0 as now).
- **Comfort and safety.** Never a visual shake; the rumble's amplitude capped and pulsed (never a constant long buzz).
- **Learning.** Staging and the order of a launch (g4 "rockets and explorers"). Fun 5, learning 3.

#### 9. Your world on your real table — mixed reality (L; M after idea 6) — score 6.7 (10 after 6)

- **What a child sees and does.** The room is there (passthrough). On the real table sits a round island of their own
  world, a model, alive: animals walking, water moving. Walk round the real table to look. Reach in to place a stamp or
  pick up their avatar, as in the Giant's Table.
- **How to build it.** The Giant's Table's view with passthrough on (`environment_blend_mode` alpha blend,
  `transparent_bg`, the sky and fog off) [S31]; the table from the Scene Manager (a "table" label) or placed by hand
  [S34]; remembered with a spatial anchor [S35]; the island's edge cut round by a radius uniform in the voxel material.
  The Scene permission and passthrough need lines in the privacy drafts (docs/store/) for the lawyer. Passthrough on the
  Mobile renderer: UNCONFIRMED until tried.
- **Comfort and safety.** Only inside the scanned room; the boundary stays; Meta's MR health rules [S46]; passthrough
  is not natural vision [S71].
- **Learning.** As idea 6. Fun 5, learning 4. Round 5.

#### 10. Walk-in wonder models (L) — score 6.7

- Giant models built of blocks the child can walk into at TINY size: the Earth's layers as a cut-away ball, a volcano's
  inside, a flower, the eye, the teeth (g4 "rock layers", "digestion and teeth", "plant and animal parts"). Each is a
  blueprint plus labels that read aloud when the hand points at a part. Effort is mostly content (each model is art,
  facts and a test). Comfort: TINY's near plane (0.05 m) is fine; the model's insides lit. Later.

#### 11. Draw in the air (M) — score 6

- A brush draws glowing ribbons from the hand; strokes can be baked into painted blocks or kept as decoration; a drawn
  outline can become a buddy. An `ImmediateMesh`/`ArrayMesh` ribbon with a point cap (draws grow with strokes: cap them
  and merge). Learning: art, 3D shapes [S65]. Later.

#### 12. Fly a kite on a string (S) — score 6

- The kite item (it exists) held by its string: pull to make it climb, the wind's strength on a little gauge (weather).
  Later.

#### 14. Hand tracking for lessons and menus (M) — score 4.5

- Put the controllers down: pinch is the trigger on panels (the hand interaction profile [S40] or Meta's aim pinch
  [S32]), poke the eye panel's buttons when brought close, type with a finger. Walking and fights stay on controllers
  (Meta: controllers for fast games; few, simple gestures [S45]). A "hand tracked badly" red tint (Cubism [S16]). Later.

#### 15. Pet, feed and hold small animals and pets (M) — score 4

- Stroke a pet's back slowly: hearts, a happy sound, a soft buzz; hold food near its mouth; hold a chick in your palm
  and feel its heartbeat (Moss [S20]). Gentle-only rules (no throwing creatures: a creature let go floats down). Later.

#### 16. Two headsets, one room (L) — score 3.3

- Two Quest 3s find each other by Bluetooth (colocation [S37]), join the LAN session EasyCraft already has, and share
  one table in MR. Restrictions on discovery and shared anchors (section 2) and two children moving in one room make it
  MR-only and later [S43].

#### 17. Feel the world: haptic textures (S) — score 3

- A different frequency per material on place and break (stone low, glass high, wood in between), a giant's footsteps,
  water. `trigger_haptic_pulse`'s frequency [S41]. Small; can ride along inside ideas 7 and 8.

#### 18. Climb with your hands (M) — score 2.5

- Grab ladder rungs and ledges and pull yourself up (Vivecraft [S7][S8], Gorilla Tag [S6]). Big arm motion and falls:
  opt-in only, never needed for progress. Later.

#### 19. Crouch and jump for real (S) — score 2

- The real head 35 cm below the calibrated height crouches (the research's P1 note); a real jump jumps. Risky with
  excited children (landing on furniture, cables): not proposed.

#### 20. A portal in your room (L) — score 1.7

- A glowing portal on the real wall shows the world; buddies come through and run round the real floor and hide behind
  the sofa (depth occlusion [S33], as First Encounters and Hello, Dot do [S52][S49]); stepping "through" is a button and
  a blink, never walking into the wall. Spectacular, little learning. Later, after idea 9.

#### 21. HRTF spatial sound (L) — score 0.7

- Steam Audio through Nexus Resonance [S48] would add HRTF; Quest binaries are unknown and it is a download and a CPU
  cost at 72 Hz. Not now; the head is already the listener.

## 6. Proposed VR round 4: the top 8

**Goal:** the owner picks up things with his hands, holds a planet, builds a little dog on the Build Table and wakes
it, sorts and tests cubes in the tank, looks at his world as a model, plays a xylophone, and pokes STAGE in the
capsule. Everything works with the controllers ("vr joysticks"); nothing needs a download, a new permission, the
Platform SDK or mixed reality.

**Order.** The lead freezes a small contract first (as in P0): `VrGrabbable`'s names and signals, `VrGrabRules`'
constants, `Vr.haptic(side, amplitude, seconds, frequency := 0.0)`, and the rulings below. Then three agents (the
owner's cap), each in its own worktree, each with `Vr.simulate` tests (`tests/**/test_vr_r4_*.gd`) and a notes file:

| Agent | Builds | Owns (new files unless marked) | Needs from the lead |
|---|---|---|---|
| **VR-HANDS** | Task 0 (grab, pull, throw, the backpack, the touchable wrist hotbar, the hand stopped at a block), idea 3 (wave, high-five, eyes that look at you, the personal bubble), idea 5 (the Build Table, the School's block rounds in VR), idea 6 (the Giant's Table) | `core/vr/vr_grab_rules.gd`, `vr_gesture_rules.gd`, `core/building/build_table_rules.gd`, `entities/vr/vr_grabber.gd`, `vr_grabbable.gd`, `vr_build_table.gd`, `vr_model_view.gd`; VR-RIG's `entities/vr/*`, `autoloads/vr.gd`, `entities/player/*` | a MORE button spot for BUILD TABLE and MODEL VIEW; the School exercise checker's seam |
| **VR-WONDER** | Idea 1 (the orrery), idea 2 (the telescope and the magnifier), idea 4 (the Lab bench: float or sink, magnets) | `entities/vr/vr_orrery.gd`, `vr_lens.gd`, `vr_lab_bench.gd`; `ui/space/space_panel.gd`, `ui/lab/lab_panel.gd` (the VR branch only) | two item ids (TELESCOPE, MAGNIFIER) and their icons; the magnifier's close-up textures (CC0 or our own) |
| **VR-SOUND** | Idea 7 (xylophone and drum blocks, the loop, phone taps too), idea 8 (the cockpit's poke buttons and the rumble) | `world/music_director.gd`, `core/rules/music_block_rules.gd`, `tools/make_instrument_tones.gd`, the tones; `ui/flight/flight_cockpit.gd` (poke targets), `entities/flight/rocket_flight.gd` (rumble) | two block ids and atlas tiles; one line in `assets/CREDITS.md` |

**Acceptance (desktop, GUT with `Vr.simulate`):** each rule file has its pure tests; each idea has an integration test
that drives fake hands (a grab, a flick, a two-hand scale, a sort into a basket, a hit on a bar, a poke) and checks the
outcome; nothing changes off VR (the phone, the web and the full suite as before), except the music blocks' taps, which
get their own tests. Each feature's draws in a VR_BENCH line beside the P5 budget (≤ 100 draws in play; the orrery, the
lens and the table counted while open).

**What only the headset can check (the lead, on the owner's Quest 3):** a grab feels sure (the outline, the tick, the
pull's catch); the flick works for a child's small wrist; the hand stops at a block without feeling stuck; the planet's
two-hand scale; the lens is steady at 8×; the tank's cubes are big enough to pick; the Build Table's 10 cm ghost snaps
where the hand is; the Giant's Table's scale looks right (fog, sky) and the blinks feel calm; mallets hit what the eye
expects; the poke buttons press at the fingertip; the rumble is pleasant, not tiring.

**Round 5 and later (in order):** idea 9 (the world on your real table, MR), 10 (wonder models), 11 (draw in the air),
14 (hand tracking), 15 (pets by hand), 12 (the kite), 16 (two headsets in one room), 20 (the portal). Not proposed:
18 (climbing) unless the owner asks, 19 (real crouch and jump), 21 (HRTF).

## 7. Rulings (decided here; the cost if wrong)

- **R1. The grip grabs when something is in reach or under the laser; otherwise it steps the hotbar as today.** [A child
  who meant to grab steps the hotbar, or the reverse: move the hotbar to the wrist slots only and keep the grip for
  grabbing.]
- **R2. Hands are kinematic; the picture stops at a block's face; the body is never pushed by a hand.** [Children miss
  pushing things: physics hands for a few objects only.]
- **R3. A release flies at the peak of the last 0.1 s ×1.5, capped at 12 m/s.** [Throws feel floaty or too strong: the
  scale and the window are two constants.]
- **R4. The far pull is Alyx's three stages, plus "hold the grip 0.6 s" for children who can't flick.** [Too many ways:
  keep only the hold.]
- **R5. Hand building at hand scale happens on the Build Table (10 cm blocks), not by shrinking the child.** [The owner
  wants it in the world: the GIANT follow-up places blocks in the world from the hand.]
- **R6. The Giant's Table is Sandbox only and the body waits where it stood.** [Survivor players want it: allow it when
  no monster is within 32 blocks.]
- **R7. Zoom only inside the lens.** [None known: a full-view zoom is a known sickness trigger.]
- **R8. The personal bubble is 0.5 m round the head for other players' hands and heads.** [Friends can't high-five
  close: high-fives are at arm's length anyway; 0.4 m if it gets in the way.]
- **R9. No open voice chat in VR.** [Friends want to talk: a later push-to-talk only between accepted friends, with the
  grown-up's switch, after a policy review.]
- **R10. No Passthrough Camera API, ever; mixed reality waits for round 5.** [None for the camera; MR is a schedule
  choice.]
- **R11. Arm-powered movement (climbing, Gorilla-style) is opt-in and never needed to progress.** [Children who love
  it find it in VR COMFORT.]
- **R12. Instrument tones are rendered by our own tool, credited as our own work.** [The owner wants real recorded
  instruments: CC0 samples, credited.]

## 8. Not recommended (and why)

- Smooth world rotation or a camera that zooms the whole view: sickness (Meta [S25], Eagle Flight [S24]).
- Gorilla-style arm locomotion as the default: big swings in living rooms (section 1.5).
- Open voice chat with strangers (section 4).
- Hiding the boundary in full VR (section 2).
- Reading the raw cameras (section 2).
- Physics-heavy hands for children: "fiddly" even for adults [S13].
- Long seated focus without a break: the break card stays.

## 9. Sources

Games and interaction design

- [S1] Road to VR, "VR Design Unpacked: The Incredible Details of 'Half-Life: Alyx'": https://www.roadtovr.com/these-details-make-half-life-alyx-unlike-any-other-vr-game-inside-xr-design/
- [S2] Engadget, "How Valve brought Half-Life to VR": https://www.engadget.com/2020-03-31-half-life-alyx-valve-interview-vr.html
- [S3] PCGamesN, Half-Life: Alyx VR design: https://www.pcgamesn.com/half-life-alyx/vr-design
- [S4] Owlchemy Labs, Tomato Presence: https://owlchemylabs.com/tomatopresence
- [S5] Road to VR, "'Job Simulator' and the Magic of Hand Presence": https://roadtovr.com/job-simulator-magic-hand-presence/ ; Voices of VR #315: https://voicesofvr.com/315-job-simulator-and-the-magic-of-hand-presence/
- [S6] UploadVR, "Everyone loves Gorilla Tag": https://www.uploadvr.com/everyone-loves-gorilla-tag/
- [S7] Vivecraft, How to play: https://www.vivecraft.org/how-to-play/
- [S8] Vivecraft, ClimbeyMotion: https://www.vivecraft.org/climbeymotion/
- [S9] UploadVR, Minecraft Bedrock ending PC VR support: https://www.uploadvr.com/minecraft-bedrock-ending-pc-vr-support/ ; Road to VR: https://roadtovr.com/minecraft-openxr-pc-vr-psvr-support-dropped/ ; Gigazine: https://gigazine.net/gsc_news/en/20250507-minecraft-vr
- [S10] Meta, Hands interaction types: https://developers.meta.com/horizon/design/hands-interaction-types/
- [S11] Meta, Grab best practices: https://developers.meta.com/vr/design/grab_bp/ ; Unreal ISDK best practices: https://developers.meta.com/horizon/documentation/unreal/unreal-isdk-best-practices/
- [S12] Blade & Sorcery: VRScout hands-on: https://vrscout.com/news/hands-on-blade-sorcery/amp/ ; player and developer posts on Steam (community sources): https://steamcommunity.com/app/629730/discussions/2/3362406825551877390 , https://steamcommunity.com/app/629730/discussions/0/1743355067135550800 , https://steamcommunity.com/app/629730/discussions/2/2619339023022513454?l=german
- [S13] Bonelab reviews: Android Central: https://www.androidcentral.com/gaming/virtual-reality/bonelab-review-the-new-standard-for-vr-physics-based-games ; Mixed: https://mixed-news.com/en/bonelab-review-vr-shooter-hit-or-failed-experiment/ ; Gaming Trend: https://gamingtrend.com/reviews/bonelab-review-the-future-isnt-here-yet/
- [S14] Physics hands: godot4-vr-physics-template: https://github.com/jtnicholl/godot4-vr-physics-template ; Roblox DevForum, VR hand collisions: https://devforum.roblox.com/t/2426545 ; Meta community forum: https://communityforums.atmeta.com/discussions/dev-unity/hydra-collision-detection/106829
- [S15] LEGO Bricktales (Quest): Road to VR review: https://roadtovr.com/lego-bricktales-review-quest-3-2-pro/ ; Siliconera: https://www.siliconera.com/review-lego-bricktales-vr-is-the-coziest-quest-game/ ; CGMagazine: https://www.cgmagonline.com/review/game/lego-bricktales-meta-quest-review
- [S16] Cubism: Road to VR, "How a Solo Indie Developer Built the Best Rated Game on Oculus Quest": https://roadtovr.com/cubism-solo-indie-developer-lessons-thomas-van-bouwel/ ; UploadVR, hand tracking update: https://uploadvr.com/cubism-hand-tracking-update-oculus-quest/ ; Mixed review: https://mixed-news.com/en/cubism-review-beautiful-3d-puzzler-now-with-mixed-reality-mode/
- [S17] Walkabout Mini Golf: PlayStation listing: https://playstation.com/en-ca/games/walkabout-mini-golf ; "They create worlds": https://adamnfinecup.com/2025/01/25/they-create-worlds-walkabout-mini-golf/
- [S18] Rec Room: Wikipedia: https://en.wikipedia.org/wiki/Rec_Room_(video_game) ; Internet Matters: https://www.internetmatters.org/advice/apps-and-platforms/online-gaming/rec-room/ ; MRU youth activity: https://edu.mruni.eu/fi/activities/21512
- [S19] Owlchemy, Cosmonious High accessibility update: https://owlchemylabs.com/blog/accessibilityupdate ; UploadVR: https://uploadvr.com/cosmonious-high-accessibility-update-adds-one-handed-mode-more-available-now/ ; Unity blog: https://unity.com/blog/games/accessible-vr-game-design-tips-from-owlchemy-labs
- [S20] Moss: GamesBeat: https://gamesbeat.com/polyarcs-post-e3-mission-making-mosss-cute-vr-hero-feel-real/ ; GamesBeat: https://gamesbeat.com/polyarcs-moss-hides-clever-vr-game-design-under-its-cuteness/ ; Meta blog (Tam Armstrong): https://www.meta.com/blog/polyarc-tam-armstrong-moss-quill-oculus-rex-vr-ar-mr/ ; GeekWire: https://www.geekwire.com/2018/ex-bungie-engineers-aim-steal-heart-sword-wielding-vr-mouse-called-quill/
- [S21] Demeo mixed reality: Road to VR: https://roadtovr.com/demeo-mixed-reality-update-quest-pro/ ; UploadVR: https://uploadvr.com/demeo-mixed-reality/ ; Android Central: https://androidcentral.com/gaming/virtual-reality/i-played-virtual-dandd-on-a-real-table-with-the-quest-pro-and-it-was-amazing
- [S22] Throwing: Bugnet guide: https://bugnet.io/blog/how-to-fix-vr-thrown-object-velocity-too-weak-unity-xr-grab ; UCL throw-detection poster: https://discovery-pp.ucl.ac.uk/10129945/1/VR2021___Throw_Detection__Poster__IEEE_.pdf ; FauxThrow: https://ar5iv.labs.arxiv.org/html/2208.02166
- [S23] Godot XR Tools: pickup docs: https://github.com/godotvr/godot-xr-tools/blob/docs/_docs/interaction/pickup.md ; world grab: https://github.com/godotvr/godot-xr-tools/blob/docs/_docs/movement/world_grab.md ; releases: https://github.com/GodotVR/godot-xr-tools/releases
- [S24] Eagle Flight: UploadVR: https://uploadvr.com/ubisoft-eagle-flight-comfort/ ; Game Developer: https://gamedeveloper.com/design/devising-the-vr-gaze-controls-of-i-eagle-flight-i-
- [S25] Meta, Locomotion comfort and usability: https://developers.meta.com/horizon/design/locomotion-comfort-usability/ ; Locomotion best practices: https://developers.meta.com/horizon/design/locomotion-best-practices/ ; Research into comfortable locomotion: https://developers.meta.com/horizon/blog/research-into-comfortable-locomotion/ ; LaValle, Vection reduction strategies: https://lavalle.pl/vr/node319.html
- [S26] Embodied locomotion (SFU thesis): https://summit.sfu.ca/item/35698 ; VR climbing posture preprint: https://arxiv.org/pdf/2602.23500v1
- [S27] Children's hand-tracking gestures (taxonomy, CHI EA 2023): https://academicrepository.khas.edu.tr/xmlui/handle/20.500.12469/4948 ; Leap Motion vs Touch, grab-and-place: https://doaj.org/article/050bad090d8d41d490f6988452ba729e

Quest 3 and Godot

- [S30] Godot OpenXR Vendors manual: https://godotvr.github.io/godot_openxr_vendors/
- [S31] Passthrough: https://godotvr.github.io/godot_openxr_vendors/manual/meta/passthrough.html
- [S32] Hand tracking: https://godotvr.github.io/godot_openxr_vendors/manual/meta/hand_tracking.html
- [S33] Environment depth: https://godotvr.github.io/godot_openxr_vendors/manual/meta/environment_depth.html
- [S34] Scene Manager: https://godotvr.github.io/godot_openxr_vendors/manual/meta/scene_manager.html
- [S35] Spatial anchors: https://godotvr.github.io/godot_openxr_vendors/manual/meta/spatial_anchors.html
- [S36] Composition layers: https://godotvr.github.io/godot_openxr_vendors/manual/meta/composition_layers.html
- [S37] Colocation discovery: https://godotvr.github.io/godot_openxr_vendors/api/class_openxrmetacolocationdiscoveryextension.html
- [S38] API index: https://godotvr.github.io/godot_openxr_vendors/api/index.html
- [S39] Repo evidence: `addons/godotopenxrvendors/GodotOpenXRVendors_CHANGES.md` (5.1.0; microgestures in the hand-tracking sample, simultaneous hands and controllers, colocation discovery, environment depth fixes); `autoloads/vr.gd:820-826` (`Vr.haptic` sends frequency 0.0)
- [S40] Godot, OpenXR hand tracking: https://docs.godotengine.org/en/stable/tutorials/xr/openxr_hand_tracking.html
- [S41] Godot, XRNode3D (`trigger_haptic_pulse`): https://docs.godotengine.org/en/stable/classes/class_xrnode3d.html
- [S42] Meta, OpenXR haptics: https://developers.meta.com/horizon/documentation/native/android/mobile-openxr-haptic/ ; Touch Plus: https://developers.meta.com/horizon/documentation/native/pc/native-touch-plus-controllers
- [S43] Meta, Colocation discovery and group sharing: https://developers.meta.com/horizon/blog/colocation-discovery-group-sharing-shared-spatial-anchors-mixed-reality/ ; Shared spatial anchors (Unity): https://developer.oculus.com/documentation/unity/unity-shared-spatial-anchors ; Unreal colocation sample: https://developers.meta.com/horizon/documentation/unreal/unreal-sample-colocation-discovery
- [S44] Meta, Hand tracking microgestures: https://developers.meta.com/horizon/documentation/native/android/mobile-openxr-hand-tracking-microgestures/
- [S45] Meta, Hands gesture design: https://developers.meta.com/horizon/design/hands-gesture-design/ ; Horizon OS input: https://developers.meta.com/horizon/essentials/horizon-os-input/ ; GDC 2026 day 1: https://prod.developers.meta.com/horizon/blog/gdc-2026-day-1-hands-agents-performance
- [S46] Meta, MR health and safety: https://developers.meta.com/horizon/design/mr-health-safety-guideline/ ; Passthrough health: https://developers.meta.com/horizon/design/mr-health-passthrough/
- [S47] Passthrough Camera API: Road to VR: https://roadtovr.com/meta-quest-passthrough-camera-api-public-publish-horizon-store/ ; Meta: https://developers.meta.com/horizon/documentation/android-apps/passthrough-camera
- [S48] Spatial audio: Nexus Resonance: https://store.godotengine.org/asset/movec/nexus-resonance/ ; godot-steam-audio: https://github.com/stechyo/godot-steam-audio/wiki ; Meta XR Audio (Unreal): https://developers.meta.com/horizon/documentation/unreal/unreal-sample-meta-xr-audio
- [S49] Hello, Dot: UploadVR: https://www.uploadvr.com/pokemon-go-studio-niantic-lets-peridot-loose-on-quest/ ; Road to VR: https://www.roadtovr.com/niantic-virtual-pet-hello-dot-quest-3-release/
- [S50] W4 Games, optimizing Godot for standalone XR: https://www.w4games.com/blog/w4-games-news-1/where-every-millisecond-counts-optimizing-godot-for-standalone-xr-159
- [S51] Godot passthrough (4.2 docs): https://docs.godotengine.org/en/4.2/tutorials/xr/openxr_passthrough.html ; Godot XR update Oct 2024: https://godotengine.org/article/godot-xr-update-oct-2024/
- [S52] First Encounters (Quest 3's MR tutorial): CNN Underscored hands-on: https://amp.cnn.com/cnn/cnn-underscored/electronics/meta-quest-3-hands-on ; Mixed, best MR apps: https://mixed-news.com/en/meta-quest-3-the-best-mixed-reality-apps-and-games/
- [S53] Godot, XROrigin3D `world_scale`: https://docs.godotengine.org/en/stable/classes/class_xrorigin3d.html

Children, learning and safety

- [S60] "Being Barbie": ScienceDaily: https://www.sciencedaily.com/releases/2011/05/110525181416.htm ; National Geographic: https://www.nationalgeographic.com/science/article/the-alice-illusion-scientists-convince-people-that-theyre-dolls-or-giants
- [S61] Titans of Space: UploadVR review: https://www.uploadvr.com/titans-of-space-plus-vr-review/ ; Road to VR: https://www.roadtovr.com/titans-of-space-oculus-rift-virtual-dk2-virtual-reality-education/ ; Illinois review: https://test.atlas.illinois.edu/node/693
- [S62] Prisms RCT: WestEd: https://www.wested.org/resource/algebra-and-immersive-vr-prisms-project/ ; GovTech: https://govtech.com/education/k-12/study-finds-ohio-math-scores-improved-with-vr-gamification
- [S63] Makransky, Terkildsen, Mayer (2019): iMotions summary: https://imotions.com/blog/adding-immersive-virtual-reality-to-a-science-lab-simulation-causes-more-presence-but-less-learning ; University of Copenhagen: https://test01.ku.dk/:obvius/pureproxy/3974268/en/publications/adding-immersive-virtual-reality-to-a-science-lab-simulation-caus
- [S64] Johnson-Glenberg et al., embodied learning in mixed reality: https://asu.elsevierpure.com/en/publications/collaborative-embodied-learning-in-mixed-reality-motion-capture-e
- [S65] VR drawing, children 10-12 (Utrecht): https://research-portal.uu.nl/en/publications/drawing-in-a-virtual-3d-space-introducing-vr-drawing-in-elementar/ ; Yale and Tilt Brush: https://edu.google.com/resources/customer-stories/yale-vrar
- [S66] Paradiddle: Steam: https://store.steampowered.com/app/685240/Paradiddle/ ; Mixed (Quest): https://mixed-news.com/en/?p=19156
- [S67] Apollo 11 VR: Steam: https://store.steampowered.com/app/1120410/Apollo_11_VR/ ; Naval Aviation Museum ride: https://navalaviationmuseum.org/?p=455 ; NYU list: https://nexus.sps.nyu.edu/vr-apps-list/apollo-11
- [S68] Common Sense Media and Stanford (2018): GeekWire: https://www.geekwire.com/2018/kid-use-virtual-reality-new-common-sense-media-report-gives-guidelines-parents/ ; Stanford News: https://news.stanford.edu/2018/04/04/emerging-research-shows-potential-power-vr-kids/ ; report PDF: https://moody.utexas.edu/sites/default/files/Common-Sense-Media.pdf
- [S69] American Academy of Pediatrics, "Are VR headsets safe for kids?": https://aap.org/en/patient-care/media-and-children/center-of-excellence-on-social-media-and-youth-mental-health/qa-portal/qa-portal-library/qa-portal-library-questions/virtual-reality-use-and-children
- [S70] Meta, Quest parent info: https://www.meta.com/quest/parent-info/
- [S71] Meta, Quest 3 health and safety warnings: https://www.meta.com/ca/legal/quest/health-and-safety-warnings/quest-3/
- [S72] Quest 3 IPD: Meta help (lens spacing and IPD; localized pages): https://www.meta.com/ko-kr/help/quest/261777072346131/ , https://www.meta.com/fi-fi/help/quest/261777072346131/ ; Mixed specs: https://mixed-news.com/en/meta-quest-3-info/
- [S73] Children's IPD: Filipović (ages 5-60): https://hrcak.srce.hr/en/28167 ; pediatric IPD norms: https://core.ac.uk/works/61673894
- [S74] Boundary and play space: Meta help, physical safety and supervision: https://www.meta.com/help/quest/272018665705488/ ; Meta Guardian (developer): https://developers.meta.com/horizon/documentation/native/android/mobile-guardian/
- [S75] CCDH: Horizon Worlds Exposed: https://counterhate.com/research/horizon-worlds-exposed/ ; Metaverse not safe for kids: https://counterhate.com/blog/new-research-shows-metaverse-is-not-safe-for-kids/
- [S76] Meta Personal Boundary: Gizmodo: https://gizmodo.com/metas-brings-personal-boundary-to-horizon-worlds-and-ve-1848487482 ; TechCrunch: https://techcrunch.com/?p=2266856
- [S77] Meta Family Center, Horizon and Quest: https://familycenter.meta.com/ca/our-products/horizon-and-quest/ ; Meta Quest parent guide: https://familycenter.meta.com/ca/static-resource/meta-quest-parent-guide
- [S78] Meta, Age groups: https://developers.meta.com/horizon/resources/age-groups/ ; FAQ: https://developers.meta.com/horizon/faqs/
- [S79] Cybersickness in children: Columbia project: https://cic-apps.datascience.columbia.edu/grants/13681 ; TCNJ project: https://computerscience.tcnj.edu/?p=5723 ; 2025 review: https://avestia.com/EECSS2025_Proceedings/files/paper/MHCI/MHCI_113.pdf
- [S80] Headset weight and the neck: Mixed (Palmer Luckey on neck torque): https://mixed-news.com/en/palmer-luckey-vr-headset-comfort-metric/ ; Meta's warning on children's necks: [S71]
