class_name BlockIds
extends RefCounted
## Block ids. A block id is also its model index in the voxel library (world/block_library.gd).

const AIR := 0
const GRASS := 1
const DIRT := 2
const STONE := 3
const SAND := 4
const LOG := 5
const PLANKS := 6
const LEAVES := 7
const GLASS := 8
const BRICK := 9
const LIGHT := 10
const WATER := 11
const RED := 12
const YELLOW := 13
const GREEN := 14
const BLUE := 15
const PURPLE := 16
const DEEPSTONE := 17
const BEDROCK := 18     # the world's floor: never placed, never broken
const COAL := 19
const IRON := 20
const GOLD := 21
const DIAMOND := 22
const CRYSTAL := 23
const BED := 24         # half-height; sleeping in it makes it your home
# M2 (plan allocations): defenses (Task 8, placeable and drawn) and hiding spots (Task 5; placeholder
# looks until that task draws its own tiles and adds them to PLACEABLE).
const DOOR := 25          # closed; tap to open (monsters cannot open doors)
const DOOR_OPEN := 26     # walk-through
const SPIKE_TRAP := 27    # hurts monsters, never players
const LANTERN := 28       # light; keeps weak monsters away
const BUSH := 29          # walk into it and crouch to hide
const BARREL := 30        # tap to hide inside
const CLOSET := 31        # tap to hide inside
# M2 Task 16 (secrets and treasures): built by the terrain generator in secret places. None is in PLACEABLE:
# the fake wall and the plates belong to secrets, and the decorations exist only in treasure.
const FAKE_WALL := 32       # looks like stone; a tap knocks hollow and it opens
const PRESSURE_PLATE := 33  # a low plate in puzzle temples; step on them in the riddle's order
const TROPHY := 34          # golden trophy (treasure and golden animals only)
const GOLD_LAMP := 35       # glowing golden lamp (treasure only)
# M3 Task 6 (Physics Lab). Pads stay here on page 0 (their ids are in old saves).
const JUMP_PAD := 36      # throws whoever stands on it up high (PadRules)
const SPEED_PAD := 37     # a burst of speed the way you were going (PadRules)
# M3 Task 2 (Sandstorm Desert): block atlas page 1 (ids 64-79; DesertBlocks has the tiles). Gathered and
# traded in the desert, not in the Sandbox palette; the last three are built only by the desert's secrets.
const SANDSTONE := 64
const CUT_SANDSTONE := 65
const CHISELED_SANDSTONE := 66
const RED_SAND := 67
const RED_SANDSTONE := 68
const CACTUS := 69           # pushes whoever walks into it a little (never hurts)
const DEAD_BUSH := 70        # walk-through
const DESERT_GLASS := 71
const PALM_LOG := 72
const PALM_LEAVES := 73
const PYRAMID_GOLD := 74     # the golden tip of a pyramid (glows)
const DESERT_LAMP := 75      # glows
const ARROW_SLIT := 76       # a pyramid trap: darts fly out of it (DesertTraps)
const TRAP_SAND := 77        # a sand pit's lid: looks like sand, holds nobody
const FAKE_SANDSTONE := 78   # looks like sandstone; a tap knocks and it opens (like FAKE_WALL)
# M3 Task 3 (Frostpeak): block atlas page 2 (ids 80-95; FrostBlocks has the tiles). Gathered and traded in
# Frostpeak, not in the Sandbox palette; the last one is built only by Frostpeak's secrets.
const SNOW := 80
const SNOWY_GRASS := 81      # snow on top, dirt below (the valleys' ground)
const PACKED_SNOW := 82
const ICE := 83              # slippery (FrostRules.grip): frozen lakes
const BLUE_ICE := 84         # even more slippery
const PINE_LOG := 85
const PINE_NEEDLES := 86     # a pine's leaves (snow on top)
const FROZEN_ORE := 87       # ice crystals in stone: an ore
const SNOW_BRICK := 88
const ICE_LANTERN := 89      # glows
const FROSTED_GLASS := 90
const FAKE_SNOW := 91        # looks like packed snow; a tap knocks and it opens (like FAKE_WALL)
# M3 Task 5 (portals, block page 10: ids 208-223). Blocks and items share one id space (a hotbar slot or
# a bag holds either kind): items own 100-175 and 400+, new block pages live at 176-255 (the lead's
# allocation, M3 dev log 18:20). Two cores whose frames are whole link (PortalRules, PortalLinks).
const PORTAL_FRAME := 208   # frames a doorway
const PORTAL_CORE := 209    # the glowing core in a frame's bottom row
# M3 Task 7 (smart blocks and Game Blocks, block page 9: ids 192-207; SmartPage). Power is one step
# (PowerRules); the "_ON"/"_OPEN" states are made by power only. None is in PLACEABLE: the palette has a
# SMART tab for them (SmartPage.SMART_ROW, GAME_ROW).
const BUTTON := 192             # a tap powers what it touches for a second
const BUTTON_ON := 193
const LEVER := 194              # a tap switches it on or off
const LEVER_ON := 195
const POWERED_DOOR := 196       # opens while powered (a doorway of up to 3, like doors)
const POWERED_DOOR_OPEN := 197  # walk-through
const LAMP := 198               # lights up while powered
const LAMP_ON := 199
const LIGHT_SWITCH := 200       # a lever for lamps
const LIGHT_SWITCH_ON := 201
const TELEPORT_PAD := 202       # step on it: out on its partner (TeleportLinks)
const START := 203              # Game Blocks (CourseRules): a runner's clock starts here
const CHECKPOINT := 204         # a fallen runner comes back here
const FINISH := 205             # the clock stops here: time and medal
const COIN := 206               # walked through during a run: the course's score (never gold)
const BOUNCE := 207             # a trampoline (PadRules)
# M3 Task 4 (Candy Kingdom): block atlas page 8 (ids 176-191; CandyBlocks has the tiles). Gathered and
# traded in the kingdom, not in the Sandbox palette; the last two are built only by its secrets.
const FROSTING := 176        # the ground's pink icing (on cake, like grass on dirt)
const CAKE := 177            # sponge
const CHOCOLATE := 178       # chocolate rivers' beds and banks, and deeper down
const CANDY_CANE := 179      # striped: candy canes and lollipop sticks (the kingdom's logs)
const LOLLIPOP := 180        # a lollipop tree's swirly top (its leaves)
const GUMDROP := 181         # green: gumdrop hills; bouncy to land on (CandyRules)
const RED_GUMDROP := 182
const CREAM := 183           # a cake mountain's layers of cream ...
const JAM := 184             # ... and jam
const SUGAR_GLASS := 185
const GINGERBREAD := 186     # gingerbread houses (the kingdom's puzzle temples)
const CANDY_LAMP := 187      # glows
const COTTON_CANDY := 188    # walk-through
const SPRINKLES := 189       # frosting with sprinkles: cake tops and the treasure's X
const GOLDEN_CANDY := 190    # glows: the gingerbread house's and the floating cake's treasure
const FAKE_CHOCOLATE := 191  # looks like chocolate; a tap knocks and it opens (like FAKE_WALL)
# Survivor games and crafting (owner feedback #34, spec §12.19; page 10, tiles in its row 6).
const CRAFTING_TABLE := 220   # most recipes are made next to one
const FURNACE := 221          # glass, bricks and charcoal; burns coal or a log
# M3 Task 14a (the action kit's gadget blocks, page 10 with the portals: PortalPage has the tiles). Not in
# PLACEABLE: the palette's ARMORY page has a GADGETS box for them (ItemIds.GADGETS); Tilly sells them.
const ZIPLINE_POST := 210       # two posts a player placed up to 48 blocks apart link with a line (ZiplineLinks)
const LAUNCH_PAD := 211         # throws whoever stands on it up very high; a glider opens by itself (PadRules)
# M3 Task 20a (rideable buddies, block page 10): a buddy built with a saddle can be ridden (RideRules).
# Not in PLACEABLE: the Sandbox palette shows it in the MAGIC row beside the wand (BlockPalette.MAGIC_BLOCKS).
const SADDLE := 216
# M3 Task 21b (books and memories, block page 10): a trophy shelf shows the world owner's badges as little trophies
# (TrophyRules); a bookshelf opens the books when tapped. Not in PLACEABLE: the palette's MAGIC row, Tilly's HOME.
const TROPHY_SHELF := 217
const BOOKSHELF := 218
# M3 Task 8 (building tools): the paint bucket's 16 tints are 16 painted blocks on block atlas page 12 (ids
# 240-255; PaintPage has the tiles, PaintRules the tints). A plain block a child paints turns into one; it
# drops as itself. Not in PLACEABLE: the palette's BUILD tab paints them (the paint items 435-450).
const PAINTED_WHITE := 240
const PAINTED_SILVER := 241
const PAINTED_GREY := 242
const PAINTED_BLACK := 243
const PAINTED_BROWN := 244
const PAINTED_RED := 245
const PAINTED_ORANGE := 246
const PAINTED_YELLOW := 247
const PAINTED_LIME := 248
const PAINTED_GREEN := 249
const PAINTED_TEAL := 250
const PAINTED_SKY := 251
const PAINTED_BLUE := 252
const PAINTED_PURPLE := 253
const PAINTED_MAGENTA := 254
const PAINTED_PINK := 255
const PAINTED_FIRST := PAINTED_WHITE
const PAINTED_LAST := PAINTED_PINK

# Owner feedback #39 (universe portals, block page 10: two tiles per id at index 2 x (id - 208)): a universe
# crystal placed in a portal frame's core slot is its universe's portal core (CrystalRules); breaking it gives the
# crystal back. Not in PLACEABLE: the crystals are what a child holds (the palette's PORTALS row, Tilly's HOME).
const CORE_MEADOWS := 212
const CORE_DESERT := 213
const CORE_FROST := 214
const CORE_CANDY := 215
const CORE_DRAGON := 222
const CORE_GLOW := 223          # universe 6, the Glow Caves (page 10's cores' row: tiles (6, 3), (7, 3))
# Owner 39: the Dragon Realm (block page 11: ids 224-239; DragonBlocks has the tiles). Gathered and traded in the
# realm, not in the Sandbox palette; the last two are built only by its secrets.
const SKY_GRASS := 224         # the islands' violet moss (on floatstone, like grass on dirt)
const FLOATSTONE := 225        # the islands' pale lavender rock
const DEEP_FLOATSTONE := 226   # darker violet: the islands' tapering undersides
const CRYSTAL_SPIRE := 227     # glows: tall golden crystal pillars (the realm's trees; owner #43)
const MUSHROOM_STEM := 228     # a giant mushroom's stalk (its log)
const GLOW_CAP := 229          # glows: a giant mushroom's cap (its leaves)
const DRAGON_SCALE := 230      # emerald scales
const EMBER_SCALE := 231       # red-orange scales
const STARGLASS := 232         # see-through, with little stars
const MOON_LAMP := 233         # glows
const CLOUD := 234             # walk-through: clouds drift under and between the islands
const NEST := 235              # woven golden twigs: dragon nests
const FLOATSTONE_BRICK := 236  # the realm's sky shrines
const DRAGON_GOLD := 237       # glows: the realm's treasure (secrets only)
const FAKE_FLOATSTONE := 238   # looks like floatstone; a tap knocks and it opens (like FAKE_WALL)

# Owner feedback #45b (spec §14.18, the wild meadows of terrain version 2): block atlas page 13 (ids 256-271;
# MeadowsBlocks has the tiles). Every page up to 255 was taken, and items own only 100-175 and 400+, so blocks
# may use 256-399 (the voxel type channel is 16-bit). Gathered in Survivor like any block, /give in the Sandbox;
# not in the Sandbox palette's BLOCKS grid (it keeps its size).
const BIRCH_LOG := 256
const BIRCH_LEAVES := 257
const DARK_LOG := 258          # a dark oak's trunk (dark forests, swamps)
const DARK_LEAVES := 259
const FLOWERS := 260           # walk-through crossed flowers (flower fields)
const LILY_PAD := 261          # a thin pad on a swamp's water, you can stand on it
const MUD := 262               # a swamp's ground
const STONE_BRICK := 263       # towers, wells, castle ruins
const MOSSY_BRICK := 264
const PLASTER := 265           # white walls: village houses, the windmill, the lighthouse
const ROOF_TILES := 266
const HAY := 267
const WHEAT := 268             # walk-through crossed wheat (village farms)
const SAIL := 269              # sail cloth: windmill sails, a ship's sails
const GLOW_MUSHROOM := 270     # a giant glowing mushroom's cap (glows; mushroom caves)
const PATH := 271              # a village's dirt path
# M3 Task 21c, the wonder pack (block atlas page 14, ids 272-287; TinyPage): what the Magic Wand wakes, and the
# mice's present. 276-287 stay free.
const PUMPKIN := 272            # the wand wakes a pumpkin buddy (WakeKinds); mouse holes' markers in the meadows
const JACK_O_LANTERN := 273     # glows: a carved, smiling pumpkin
const SNOWMAN_HEAD := 274       # a snowman's face (coal eyes, a carrot nose): on snow blocks it wakes as a snowman
const CHEESE := 275             # the mouse villages' tiny treasure (treasure only)
# Owner #55 (spec §21), space: the Moon on block atlas page 15 (ids 288-303; MoonBlocks has the tiles; 299-303 free).
const MOON_DUST := 288          # the Moon's silvery ground
const MOON_ROCK := 289
const DEEP_MOON_ROCK := 290
const MOON_CRYSTAL := 291       # glows: pale blue crystals in the craters
const MOON_CHEESE := 292        # the Moon IS made of cheese: its hidden rooms' walls
const BASE_PANEL := 293         # the Moon Base's silver walls
const PORTHOLE := 294           # glows: a round window with a warm light inside
const LANDING_PAD := 295        # glows: the teal pad with a golden star where a child lands
const STAR_GOLD := 296          # glows: space treasure (secrets only)
const FAKE_MOON_ROCK := 297     # looks like moon rock; a tap knocks and it opens (like FAKE_WALL)
const BASE_LIGHT := 298         # glows: the Moon Base's lamps
# Planet Boing on page 16 (ids 304-319; BoingBlocks; 313-319 free): boing moss, jelly and spring caps are bouncy.
const BOING_MOSS := 304         # lime moss: the planet's bouncy ground
const BOING_SOIL := 305
const BOING_ROCK := 306
const JELLY := 307              # bouncy pink jelly: the planet's pools
const SPRING_STEM := 308        # a spring mushroom's stalk
const SPRING_CAP := 309         # its bouncy cap
const BOING_GLOW := 310         # glows: a bulb lamp
const BOING_BRICK := 311        # lilac bricks: the Boing Tower, the temples
const FAKE_BOING_ROCK := 312    # looks like boing rock; a tap knocks and it opens
# Rainbow Planet on page 17 (ids 320-335; RainbowBlocks; 331-335 free).
const PRISM_GRASS := 320        # pastel grass with rainbow sparkles
const RAINBOW_RED := 321        # the hills' rock, in stripes (RainbowBlocks.STRIPES)
const RAINBOW_ORANGE := 322
const RAINBOW_YELLOW := 323
const RAINBOW_GREEN := 324
const RAINBOW_BLUE := 325
const RAINBOW_VIOLET := 326
const PRISM_CRYSTAL := 327      # glows: clear crystal spires with rainbow edges
const PRISM_BRICK := 328        # white bricks: the temples, the arch's stair
const PRISM_LAMP := 329         # glows
const FAKE_RAINBOW := 330       # looks like the blue stripe; a tap knocks and it opens
# Cosmos (spec §21b.2): Mars on page 18 (ids 336-351; MarsBlocks; 350-351 free). 331-335 stay Rainbow Planet's.
const MARS_DUST := 336          # red dust: iron oxide (rust) on Mars's ground
const MARS_REGOLITH := 337      # rusty broken rock and pebbles under the dust
const BASALT := 338             # dark rock made by old lava: Mars's rock and its volcano
const DEEP_BASALT := 339
const MARS_SEDIMENT := 340      # pale layered rock: the dry river beds, the layers in the canyon's walls
const POLAR_ICE := 341          # white water ice: the ice caps (with dusty layers inside)
const DRY_ICE := 342            # frosty blue-white frozen carbon dioxide: the south cap's top, frost
const GYPSUM := 343             # glows: gypsum crystals (a mineral that forms in water): river beds, geodes
const ROVER_PANEL := 344        # the rover's white body, the old lander's panels
const ROVER_WHEEL := 345
const SOLAR_PANEL := 346        # blue solar cells: the rover's deck
const LANDER_FOIL := 347        # crinkled gold foil: the old lander (secrets)
const FAKE_BASALT := 348        # looks like basalt; a tap knocks and it opens (like FAKE_WALL)
const ROVER_LIGHT := 349        # glows: the rover's camera eyes, the explorers' lamps
# Spec §23 (owner #74): the Science Lab on page 19 (ids 352-367; LabPage). A tap opens the Lab; not in PLACEABLE: the
# palette's HOME row (BlockPalette.HOME_BLOCKS); Survivor crafts it at a Workbench and finds one in some village houses.
const LAB_BENCH := 352
# Cosmos (spec §21b.2): Europa on page 20 (ids 368-383; EuropaBlocks; 381-383 free). 352-367 (page 19) are the Science
# Lab's.
const EUROPA_ICE := 368         # the smooth white water-ice crust
const LINEA_ICE := 369          # reddish-brown ice: the long cracks (lineae), stained by salts and sulphur
const BAND_ICE := 370           # pale stained ice: the cracks' ridges
const DEEP_ICE := 371           # blue deep ice, in layers with white bands (the cliffs' faces, the well's walls)
const EUROPA_ROCK := 372        # the rocky seafloor under the ice (under y 0); ores are in it
const GLOW_ICE := 373           # glows: blue ice lighting the ocean well, the Ice Lander's melt hole
const SALT := 374               # glows: sea salt crystals (the cracks, the plumes' mounds, geodes)
const GEYSER_VENT := 375        # glows: a water plume's vent; a pad (PadRules): it throws a child up
const PROBE_PANEL := 376        # the Ice Lander's white panels
const MELT_PROBE := 377         # the Ice Lander's legs and its melt probe
const PROBE_LIGHT := 378        # glows: the Ice Lander's lights
const ICE_BRICK := 379          # the explorers' ice station (secrets), the hidden rooms' floors
const FAKE_DEEP_ICE := 380      # looks like deep ice; a tap knocks and it opens (like FAKE_WALL)
# Cosmos (spec §21b.2): Io on page 21 (ids 384-399; IoBlocks; 399 free): the last page under the items' ids (400 on).
const SULPHUR := 384            # yellow sulphur: Io's plains
const ORANGE_SULPHUR := 385     # orange sulphur patches
const SULPHUR_FROST := 386      # white frost: frozen sulphur dioxide
const RED_SULPHUR := 387        # red sulphur: the rings a plume drops round its volcano
const IO_ROCK := 388            # Io's rock under the sulphur (with layers of black lava), its mountains
const BLACK_LAVA := 389         # black lava rock: cooled lava (the lava lakes' shores, old flows, lava bombs)
const LAVA_CRUST := 390         # glows: a lava lake's black crust with glowing cracks; safe to walk on
const HOT_LAVA := 391           # glows: bright hot lava; a pad (PadRules): a warm bounce throws a child out, never hurts
const VOLCANO_VENT := 392       # glows: a volcano's vent; a pad (PadRules): its plume throws a child up
const SULPHUR_CRYSTAL := 393    # glows: yellow sulphur crystals (the plains, geodes, the treasure's X)
const HEAT_TILE := 394          # the Volcano Lander's white heat tiles, the explorers' station's floors
const LANDER_LEG := 395         # the Volcano Lander's metal legs and mast
const HEAT_CAMERA := 396        # glows: the Volcano Lander's heat camera and lights
const SULPHUR_BRICK := 397      # yellow bricks: the explorers' station (secrets)
const FAKE_IO_ROCK := 398       # looks like Io rock; a tap knocks and it opens (like FAKE_WALL)
# Ids 400-511 are the items' (RESERVED_FIRST … RESERVED_END below): block pages 22-28 are never used.
# Cosmos (spec §21b.2): Titan on page 29 (ids 512-527; TitanBlocks; 523-527 free): the first block page past the items'.
const TITAN_SOIL := 512         # Titan's orange-brown soil: the plains (under an orange haze)
const ICE_PEBBLES := 513        # rounded pebbles of water ice on the soil (what a probe saw where it landed)
const DUNE_SAND := 514          # the dunes' dark grains
const WET_SHORE := 515          # the dark, wet shore round a methane lake or the sea, and their beds
const ICY_ROCK := 516           # Titan's rock: water ice as hard as stone (its crust, its mountains; ores)
const SHORE_CRYSTAL := 517      # glows: the bright crystals a drying lake leaves on its shore (geodes, the treasure's X)
const PROBE_SHELL := 518        # the Landing Probe's round shell (gold foil and white)
const PARACHUTE := 519          # the Landing Probe's parachute, lying on the ground (orange and white stripes)
const PROBE_LAMP := 520         # glows: the Landing Probe's lamps, the explorers' lamps
const TITAN_BRICK := 521        # orange-cream bricks: the explorers' station (secrets)
const FAKE_ICY_ROCK := 522      # looks like icy rock; a tap knocks and it opens (like FAKE_WALL)
# Cosmos (spec §21b.2): Mercury on page 30 (ids 528-543; MercuryBlocks; 542-543 free).
const MERCURY_DUST := 528       # Mercury's grey dust: the plains, the craters' floors
const MERCURY_ROCK := 529       # Mercury's grey rock: under the dust, the long cliffs' faces, the big craters' walls (ores)
const DARK_DUST := 530          # patches of darker, blue-grey dust
const RAY_DUST := 531           # the bright dust a young crater throws out in rays
const SHADOW_ICE := 532         # water ice on the floors of the shadowed craters near the poles
const ICE_CRYSTAL := 533        # glows: ice crystals (the ice craters, geodes, the treasure's X)
const SUNSHADE := 534           # the Sunshade Lander's big white sunshade (ceramic cloth)
const HEAT_BLANKET := 535       # the Sunshade Lander's silvery heat blanket (its body and legs)
const MIRROR_PANEL := 536       # the Sunshade Lander's solar panels, mostly mirrors
const EXPLORER_LAMP := 537      # glows: the Sunshade Lander's and the explorers' lamps
const THERMOMETER := 538        # the explorers' thermometer: its tube with the red line and marks
const THERMO_BULB := 539        # glows: the thermometer's red bulb
const EXPLORER_BRICK := 540     # warm grey bricks: the explorers' station (secrets)
const FAKE_MERCURY_ROCK := 541  # looks like Mercury rock; a tap knocks and it opens (like FAKE_WALL)
# Colonies under domes (spec §21c, owner #77): the colony's blocks on page 31 (ids 544-559; ColonyBlocks). Built by the
# terrain generator in the Moon's and Mars's colonies (ColonyLayout), sold by Tilly on those worlds (build your own).
const DOME_GLASS := 544         # see-through: the domes' and tunnels' glass (a thin white frame, clear inside)
const COLONY_PANEL := 545       # white habitat panels: the domes' base rings, the airlock's walls, the garage
const COLONY_FLOOR := 546       # light floor tiles: inside the small domes, the tunnels, the paths
const GREENHOUSE_SOIL := 547    # dark rich soil: the greenhouse garden's beds
const GROW_LAMP := 548          # glows pink: plants use red and blue light the most
const COLONY_LIGHT := 549       # glows warm white: the colony is always lit
const FRUIT_LEAVES := 550       # see-through leaves with oranges: the fruit trees under the Great Dome
const WATER_TANK := 551         # glows: a glass tank of clean water (the water plant, the oxygen maker)
const ICE_MELTER := 552         # glows: a warm melter; ice on top melts into water
const OXYGEN_MAKER := 553       # glows: splits water into oxygen (bubbles) and hydrogen
const CONTROL_SCREEN := 554     # glows: the control room's screens
const COLONY_MAP := 555         # glows: the control room's big map of the planet
const AIRLOCK_FRAME := 556      # teal-and-white striped frames: the airlock's two doors, the garage's beam
const ROCKET_HULL := 557        # shiny steel: the big rocket on its own pad
const PRINTED_REGOLITH := 558   # printed layers of planet dust: the homes' shield against the Sun's rays
const COLONY_TABLE := 559       # a white table (cut out): the homes, the lab, the control room's desks
# Missions (spec §21d, §25.3; owner #78, #79): the rocket parts and the launch pad on page 32 (ids 560-575; RocketPage;
# 574-575 free). A rocket is the stack of parts standing on a Launch Site's pad (RocketCheck); each part's numbers and
# its price in gold are RocketParts'. The pad's concrete and stripes are stamped once when a world's site is chosen.
const ROCKET_ENGINE := 560      # a kerosene engine with its bell nozzle: pushes hot gas down, the rocket goes up
const SPACE_ENGINE := 561       # a hydrogen engine with a very big bell, made for space (stage 2 and up)
const FUEL_TANK := 562          # fuel and liquid oxygen (there is no air to burn with in space)
const NOSE_CONE := 563          # the pointed top: air flows round it
const CREW_CAPSULE := 564       # a seat and a window for one astronaut
const SERVICE_MODULE := 565     # air, water, food and power for the crew
const HEAT_SHIELD := 566        # keeps the capsule cool coming down through a planet's air
const LANDING_LEGS := 567       # three of them stand a lander steady on the ground
const ROCKET_FINS := 568        # keep a rocket flying straight through the air, like an arrow's feathers
const STAGE_SEPARATOR := 569    # between stages: the empty stage below drops away
const SOLAR_ARRAY := 570        # power from sunlight for the crew
const PARACHUTE_PACK := 571     # slows a lander in a planet's air
const PAD_CONCRETE := 572       # the launch pad's floor (a Launch Site's build square)
const PAD_STRIPE := 573         # the yellow-and-black ring round the build square
# The world's wonders (owner #78, spec §24): pages 33-34 (ids 576-607; WondersBlocks; 598-607 free for the next tours):
# what the Seven Wonders of the Ancient World were built of, in the game's own look (§3c), for world 41.
const LIMESTONE := 576          # the Great Pyramid's core blocks: pale golden limestone, big stones
const CASING_STONE := 577       # the smooth white casing that once covered the pyramid (a few stones remain at its foot)
const GRANITE := 578            # pink granite from Aswan: the King's Chamber and its stone box
const FAKE_LIMESTONE := 579     # looks like limestone; a tap knocks and it opens (the pyramid's hidden room)
const MARBLE := 580             # white marble with grey veins: the Greek temples, the Mausoleum, the Colossus's base
const MARBLE_COLUMN := 581      # a fluted marble column
const CAPITAL := 582            # a column's top with its scrolls (Ionic)
const FRIEZE := 583             # a carved marble band (a key pattern) under a roof
const FAKE_MARBLE := 584        # looks like marble; a tap knocks and it opens (the Mausoleum's tomb room)
const BRONZE := 585             # shiny golden-brown bronze: the Colossus of Rhodes
const IVORY := 586              # creamy ivory: the Statue of Zeus's skin
const GOLD_LEAF := 587          # thin gold over wood: Zeus's robe and throne
const EBONY := 588              # black ebony wood: Zeus's throne
const BABYLON_BRICK := 589      # baked yellow bricks set in dark bitumen: Babylon's walls, the gardens' terraces
const GLAZED_BRICK := 590       # shiny blue glazed bricks with a flower: Babylon's gates and walls
const FAKE_BABYLON_BRICK := 591 # looks like a Babylon brick; a tap knocks and it opens (the gardens' cool room)
const BEACON_FIRE := 592        # glows: the fire at the top of the Lighthouse of Alexandria
const WHITE_BRICK := 593        # white stone blocks: the Lighthouse, the Mausoleum's podium
const PAVING := 594             # big pale paving slabs: the tour's paths and squares
const WONDER_PLAQUE := 595      # a stone with a bronze plaque: a tap opens the wonder's card and its fact quiz
const SCREW_PUMP := 596         # a wooden water screw: turned by hand, it lifts water (the gardens)
const OLIVE_LEAVES := 597       # silvery olive leaves (Olympia's olive trees: the winners' crowns)
# Prospecting on Earth (spec §26, owner #80): the riches on page 35 (ids 608-623; ProspectPage). The first ten are found in
# the ground where real geology puts them (DepositRules: rich deposits and their telltale signs); the next five are what
# refining makes (RefiningRules: the Clay Oven and the Refinery); the last is the Refinery itself.
const GOLD_QUARTZ := 608        # a white quartz vein with gold in it (a lode: mined in a hill)
const GOLD_GRAVEL := 609        # river gravel with gold flakes (a placer: panned)
const COPPER_ORE := 610         # grey rock with brassy copper minerals (the desert's mesas: an open pit)
const MALACHITE := 611          # the green stain copper makes in the air: the sign on top of copper
const BANDED_IRON := 612        # red and silver stripes of iron ore laid down in old seas
const RUSTY_ROCK := 613         # rusty red-brown rock at the top of iron ore: its sign
const FERN_SHALE := 614         # grey shale with fern prints: the sign over a coal seam (old swamp forests)
const OIL_SEEP := 615           # dark sticky sand where oil comes up: the sign over an oil dome
const ROCK_SALT := 616          # halite, rock salt: pink-white crystals under a salt flat
const SALT_CRUST := 617         # the white crust of a salt flat, a dried-up lake: its sign
const COPPER := 618             # refined copper (smelted from its ore): wires, pipes, coins
const TABLE_SALT := 619         # a sack of clean salt (rock salt dissolved, cleaned and dried)
const CRUDE_OIL := 620          # a drum of crude oil from an oil well's pump jack
const KEROSENE := 621           # a drum of kerosene: jet and rocket fuel refined from crude oil (the rocket's fuel hook)
const PLASTIC := 622            # plastic made from oil at a refinery
const REFINERY := 623           # a refinery: crude oil is heated and split into fuels and plastic next to it (a station)
# The world's wonders, second tour (owner #78, spec §24): the New Seven Wonders on pages 36-37 (ids 624-641; WondersBlocks
# PAGE_NEW, PAGE_NEW_MORE; 642-655 are the third tour's), in world 41's second region (the New Seven square).
const WALL_BRICK := 624         # the Great Wall's big grey bricks (the Ming wall), its walkway paved with them
const FAKE_WALL_BRICK := 625    # looks like a wall brick; a tap knocks and it opens (a watchtower's store room)
const ROSE_ROCK := 626          # Petra's rose-red sandstone cliffs, with swirling bands of colour
const ROSE_STONE := 627         # smooth rose stone carved into a facade (Petra's Treasury)
const ROSE_COLUMN := 628        # a column carved out of the rose rock, with its leafy top
const TRAVERTINE := 629         # the Colosseum's cream travertine blocks, full of tiny holes
const FAKE_TRAVERTINE := 630    # looks like travertine; a tap knocks and it opens (the tunnels under the arena)
const MAYA_STONE := 631         # pale grey Maya limestone: Chichen Itza's pyramid, El Castillo
const MAYA_CARVING := 632       # a carved Maya band with a step pattern (the temple on top)
const SERPENT_HEAD := 633       # the feathered serpent's stone head with its open jaws (the foot of the north stairs)
const JAGUAR_THRONE := 634      # a red jaguar with green jade spots: the throne inside the pyramid
const FAKE_MAYA_STONE := 635    # looks like Maya stone; a tap knocks and it opens (the pyramid inside the pyramid)
const INCA_STONE := 636         # grey granite fitted so tightly no knife fits between the stones (Machu Picchu)
const FAKE_INCA_STONE := 637    # looks like Inca stone; a tap knocks and it opens (the cave under the Temple of the Sun)
const SOAPSTONE := 638          # small pale soapstone tiles: the skin of Christ the Redeemer
const INLAID_MARBLE := 639      # white marble with flowers of coloured stones set into it (the Taj Mahal)
const MUGHAL_RED := 640         # red sandstone with white marble lines: the Taj Mahal's great gate
const FAKE_WHITE_BRICK := 641   # looks like white stone; a tap knocks and it opens (the room in the statue's pedestal)
# The world's wonders, third tour (owner #78, spec §24): the Seven Natural Wonders on page 37 too (ids 642-655, its rows
# 1-3; WondersBlocks.TILES_NATURE), in world 41's third region (the nature square, at the end of the Nature Trail).
const KAIBAB_LIMESTONE := 642   # the Grand Canyon's rim rock: pale limestone made on the floor of a warm sea
const COCONINO_SANDSTONE := 643 # cream sandstone with the slanting lines of old desert sand dunes
const SUPAI_REDBED := 644       # red sandstone and mudstone in thin layers (the Supai's ledges)
const REDWALL_LIMESTONE := 645  # grey limestone stained red by the red rock above it (the Redwall's great cliff)
const CANYON_SHALE := 646       # soft green-grey shale (the Bright Angel Shale: the Tonto Platform's slope)
const VISHNU_SCHIST := 647      # dark, shiny schist with pink granite veins: the canyon's oldest rock, about 2 billion years
const SEA_FOSSIL := 648         # grey limestone with a trilobite fossil in it (Everest's top was once a sea's floor)
const BRAIN_CORAL := 649        # a round green-gold coral with winding grooves like a brain
const STAGHORN_CORAL := 650     # pink coral with branches like a stag's antlers
const SEA_FAN := 651            # a purple sea fan's lacy net of branches
const CINDER := 652             # Parícutin's cinders: red-black bits of lava full of holes, cooled as they flew
const CORN := 653               # walk-through crossed corn plants with cobs (Parícutin's cornfield)
const PRAYER_FLAGS := 654       # walk-through: a string of prayer flags in five colours (Everest's camps and top)
const SPRAY := 655              # walk-through: the falls' spray, a cloud of tiny drops (Mosi-oa-Tunya's "smoke")
# Cosmos (spec §21b.2): Venus's cloud city on page 38 (ids 656-671; VenusBlocks): a city floating about 50 km up over the
# yellow clouds.
const VENUS_CLOUD := 656        # the tops of Venus's yellow clouds far below the city (droplets of sulfuric acid)
const DEEP_CLOUD := 657         # the deeper ochre clouds under the tops
const CLOUD_DECK := 658         # the city's cream decks: the platforms' walking floors
const FLOAT_HULL := 659         # a platform's silvery hull, full of the air we breathe: it floats in Venus's heavy air
const SKY_TURF := 660           # the sky gardens' green turf on a deck
const SKY_BRIDGE := 661         # the honey-coloured planks of the bridges between the platforms
const CLOUD_LAMP := 662         # glows: the city's warm lamps (on posts, in the homes, the blimp's lights)
const SKY_FRAME := 663          # white metal frames: lamp posts, the dock's mooring mast, struts, the platforms' rims
const HOME_PANEL := 664         # the cloud homes' peach wall panels
const BLIMP_SKIN := 665         # the Research Blimp's white skin
const BLIMP_STRIPE := 666       # its teal stripe and fins
const GONDOLA := 667            # its gondola's white wall with a round window
const SOLAR_FILM := 668         # dark blue solar cells (the blimp's back, the homes' roofs): the Sun is bright up here
const CLOUD_CRYSTAL := 669      # glows: pale golden crystals (the treasure's X, geodes in a hull)
const TELESCOPE := 670          # a brass telescope (the cloud scope, the west lookout)
const FAKE_FLOAT_HULL := 671    # looks like a float hull; a tap knocks and it opens (like FAKE_WALL)
# Prospecting on the Moon and Mars (spec §26.5, owner #80): the riches of space on page 39 (ids 672-687;
# ProspectSpacePage). The first ten are found in the ground (DepositRules puts them where real geology does), then what
# in-situ resource use makes of them and the Solar Oven (a station).
const ICY_REGOLITH := 672       # Moon dust frozen with water ice: the floors of the dark craters that never see the Sun
const MARE_DUST := 673          # the dark dust of the Moon's "seas" (old lava plains): titanium-rich, holds helium-3
const ILMENITE := 674           # black crystals of iron, titanium and oxygen in the seas' basalt
const KREEP_ROCK := 675         # rock rich in potassium (K), rare earths (REE) and phosphorus (P), dug up by impacts
const IRON_METEORITE := 676     # iron and nickel that fell from space (the Moon and Mars)
const GROUND_ICE := 677         # Mars's water ice under the dust (a fresh little crater shows it)
const BLUEBERRY_SOIL := 678     # Mars's red dust strewn with little grey hematite "blueberries"
const HEMATITE := 679           # layered rock full of hematite spheres, grown in water long ago
const DARK_SAND := 680          # Mars's dark, iron-rich sand (a magnet picks it up)
const MARS_SALT := 681          # a pale salt crust (chlorides and perchlorate) where an old lake dried
const OXYGEN_TANK := 682        # oxygen to breathe, made from water or from rock
const HYDROGEN_FUEL := 683      # liquid hydrogen and oxygen split from water: rocket fuel
const TITANIUM := 684           # a bar of titanium from ilmenite: strong and light
const RARE_EARTHS := 685        # a tray of rare earth powder from KREEP rock (magnets for motors)
const HELIUM_3 := 686           # a flask of helium-3 the Sun's wind left in the Moon's dust
const SOLAR_OVEN := 687         # mirrors focus sunlight to bake dust into bricks and melt rock (a station)
# Cosmos (spec §21b.2): Saturn's rings on page 40 (ids 688-703; RingsBlocks): countless chunks of water ice in bands, with
# gaps, Saturn huge in the sky.
const RING_ICE := 688           # a ring chunk's clean water ice (the rings are mostly water ice)
const RING_FROST := 689         # the frosty, sparkling top of a ring chunk
const DUSTY_ICE := 690          # the C ring's and the Cassini Division's darker, dustier ice
const RING_ROCK := 691          # dark rock bits among the ice (the rings are chunks of ice and rock)
const MOONLET_ICE := 692        # Pan's pale ice: the little walnut-shaped moon in the Encke Gap
const RIDGE_DUST := 693         # the ring dust piled on Pan's ridge round its middle
const RING_CRYSTAL := 694       # glows: pale blue ice crystals (the treasure's X, geodes in a chunk)
const STATION_PANEL := 695      # the Ring Station's and the Ring Explorer's white panels with a teal trim
const STATION_WINDOW := 696     # a station panel with a round window
const STATION_LAMP := 697       # glows: the station's warm lamps
const RADIO_DISH := 698         # a white radio dish that talks to Earth
const POWER_PACK := 699         # glows: a power pack that makes electricity from heat (sunlight is weak out here)
const TRUSS := 700              # dark metal struts: booms, masts, legs
const RING_BEACON := 701        # glows: a teal beacon lamp marking a sight (a gap's edge, a ring)
const SATURN_BAND := 702        # Saturn's pale gold and tan cloud bands (the station's model of Saturn)
const FAKE_RING_ICE := 703      # looks like ring ice; a tap knocks and it opens (like FAKE_WALL)
# Cosmos (spec §21b.2): Pluto on page 41 (ids 704-716, 717-719 free; PlutoBlocks): its heart of nitrogen ice in churning
# cells, water-ice mountains, the red-brown tholin lands, methane snow, a blue haze and Charon still in its sky.
const NITROGEN_ICE := 704       # the heart's plain: frozen nitrogen (the gas that fills most of Earth's air), pale cream
const CELL_EDGE := 705          # the darker edges between the plain's slowly churning cells
const WATER_ICE := 706          # Pluto's water ice, frozen as hard as rock: its bedrock and its mountains
const PLUTO_FROST := 707        # the uplands' peach-tan frost of nitrogen and methane
const THOLIN_DUST := 708        # the dark red-brown lands' dust: tholins, made from gas by sunlight high in the air
const RED_ICE := 709            # water ice stained red by tholins (under the dark lands, the craters' walls)
const METHANE_SNOW := 710       # bright white methane snow (the heart's bright half, snowy hilltops, peaks)
const FROST_CRYSTAL := 711      # glows: pale blue frost crystals (the treasure's X, geodes, the lights of rooms)
const DRAG_BALLOON := 712       # the Balloon Lander's silvery drag balloon (slows a lander in Pluto's thin air)
const CHARON_GLOBE := 713       # a globe of Charon: grey with its red cap (the Charon Lookout)
const HEART_BEACON := 714       # glows: a pink heart beacon
const FROST_BRICK := 715        # the explorers' pale frost bricks (the lookout's floor, the station)
const FAKE_WATER_ICE := 716     # looks like water ice; a tap knocks and it opens (like FAKE_WALL)
# Cosmos (spec §21b.2): Triton on page 42 (ids 720-733, 734-735 free; TritonBlocks): Neptune's big moon, from Voyager 2
# (1989): a bright band of fresh nitrogen frost, the pink south polar cap with its geysers and their dark streaks, the
# cantaloupe terrain, frozen lakes of ice lava. Under its frost it shares Pluto's nitrogen ice and water ice.
const TRITON_FROST := 720       # the bright band's fresh nitrogen frost: bluish white
const PINK_ICE := 721           # the south polar cap's nitrogen ice, turned pink by sunlight on its methane
const MOTTLED_ICE := 722        # the cap's darker mottled patches
const GEYSER_DUST := 723        # dark dust a geyser blew up, dropped downwind on the pink ice (the streaks)
const NITROGEN_GEYSER := 724    # glows: a geyser's vent; a pad (PadRules): a gentle puff carries a child up and away
const CANTALOUPE_ICE := 725     # the cantaloupe terrain's dimpled ice (greyish green, like a melon's rind)
const RIDGE_ICE := 726          # the paler ridges between its dimples
const ICE_LAVA := 727           # the frozen ice lava of a walled plain (icy "lava" of water that froze flat)
const NITROGEN_CRYSTAL := 728   # glows: pale pink-white nitrogen frost crystals (the treasure's X, geodes, lights)
const NITROGEN_TANK := 729      # the Hopper Lander's white tank of nitrogen (its fuel, scooped from the ice)
const NEPTUNE_GLOBE := 730      # a globe of Neptune: deep blue with its dark spot (the Neptune Lookout)
const BLUE_BEACON := 731        # glows: a deep blue beacon lamp (the lookout, the explorers' station)
const CAP_BRICK := 732          # the explorers' pale pink bricks (the lookout's floor, the station)
const FAKE_PINK_ICE := 733      # looks like pink ice; a tap knocks and it opens (like FAKE_WALL)
# Cosmos (spec §21b.2): Ganymede on page 43 (ids 736-747, 748-751 free; GanymedeBlocks): Jupiter's biggest moon, the biggest
# moon of all and the only one with its own magnetic field: the bright grooved terrain, the old dark terrain, a young
# crater's bright rays, the frost at its poles, the auroras. Under its ground its crust is Pluto's water ice.
const GROOVED_ICE := 736        # the bright grooved terrain's pale ice (its ridges)
const TROUGH_ICE := 737         # the floors of its grooves: blue-grey ice
const DARK_ICE := 738           # the old dark terrain's dark brownish-grey ice (ice mixed with dark dust)
const OLD_ICE := 739            # old, dusty ice under it (the furrows' and the old craters' floors)
const RAY_ICE := 740            # a young crater's brilliant fresh ice, thrown out from below in long bright rays
const POLAR_FROST := 741        # the frost at the poles: white with a violet tint
const AURORA_CRYSTAL := 742     # glows: red and green aurora crystals (the treasure's X, geodes, lights, the frost)
const JUPITER_GLOBE := 743      # a globe of Jupiter: its cream zones, brown belts and Great Red Spot (the lookout)
const AURORA_LAMP := 744        # glows: a green aurora lamp (the lookout, the Aurora Watch, the explorers' station)
const MAGNETOMETER := 745       # a magnetometer: a white sensor with a copper coil, on a long boom (the Aurora Watch)
const GROOVE_BRICK := 746       # the explorers' pale bricks (the lookout's floor, the watch, the drill, the station)
const FAKE_GROOVED_ICE := 747   # looks like grooved ice; a tap knocks and it opens (like FAKE_WALL)
# Owner #110 (VR round 4, idea 7; MusicPage, page 44: ids 752-753, 754-767 kept for more instruments on it): the music
# blocks. A tap plays them on a phone, the web and a PC; in VR mallets play them too (MusicDirector, MusicBlockRules).
const XYLOPHONE := 752          # eight coloured bars, C5 to C6 (low on the west end): the C major scale
const DRUM := 753               # bongos: a big low skin (west half) and a small high one (east half); the shell clicks
# Universe 6, the Glow Caves (spec §5.1; GlowBlocks, page 45: ids 768-783, all used): big caverns of limestone lit by their
# own glow (no real light per mushroom): glow moss, giant glowshrooms, glow-worm ceilings, the Cave of Crystals' selenite.
const CAVE_STONE := 768         # limestone, the caves' rock: rainwater (a weak acid) dissolves it (the Rain Carver)
const GLOW_MOSS := 769          # glows: a carpet of soft blue-green glowing moss on the cave floor
const SHROOM_STEM := 770        # a giant glowshroom's pale stalk
const BLUE_SHROOM := 771        # glows: a giant glowshroom's teal-blue cap
const ROSE_SHROOM := 772        # glows: a giant glowshroom's rose-pink cap
const GLOW_WORMS := 773         # glows: a ceiling of glow-worms: tiny blue lights on silk threads (New Zealand's)
const SELENITE := 774           # glows softly: the Cave of Crystals' giant gypsum (selenite) beams
const FLOWSTONE := 775          # cream and orange bands of calcite laid down by flowing water; drip-grown columns
const STALACTITE := 776         # a stone icicle hanging from the roof (two crossed pictures, walked through)
const STALAGMITE := 777         # a stone cone rising from the floor where the drops land (crossed pictures)
const LAKE_STONE := 778         # smooth dark pebbles of an underground lake's floor and shore
const FUNGUS_PLANKS := 779      # planks of giant-mushroom wood (the explorers' camp, bridges)
const SPORE_LAMP := 780         # glows: a lantern of glowing spores; a light (StealthRules, MonsterRules: no spawns near)
const CAVE_PEARL := 781         # glows: cave pearls, round stones that grow in drip pools (the Blind Fish Lake's gift)
const CAVE_GOLD := 782          # glows: gold in selenite (the caves' treasure: secrets only, never given)
const FAKE_CAVE_STONE := 783    # looks like cave stone; a tap knocks and it opens (like FAKE_WALL)
const COUNT := 784
## The Sandstorm Desert's natural ground (M3 Task 2): the lists of natural blocks (bot builders'
## ground, meteors, the axe's trees) take it in as they take GRASS, DIRT and SAND.
const DESERT_GROUND: Array[int] = [SANDSTONE, RED_SAND, RED_SANDSTONE]
## Frostpeak's natural ground (M3 Task 3): snowfields, snowy valleys and frozen lakes. Packed snow and
## snow bricks are what children (and igloos) build with.
const FROST_GROUND: Array[int] = [SNOW, SNOWY_GRASS, ICE]
## The Candy Kingdom's natural ground (M3 Task 4): the same lists take it in (and the Magic Wand never
## wakes it).
const CANDY_GROUND: Array[int] = [FROSTING, CAKE, CHOCOLATE, GUMDROP, RED_GUMDROP, CREAM, JAM, SPRINKLES]
## The Dragon Realm's natural ground (owner 39): the islands' moss and rock. The same lists take it in.
const DRAGON_GROUND: Array[int] = [SKY_GRASS, FLOATSTONE, DEEP_FLOATSTONE]
## The Glow Caves' natural ground (universe 6): the caves' rock, its moss, the lakes' pebbles and the flowstone.
const GLOW_GROUND: Array[int] = [CAVE_STONE, GLOW_MOSS, LAKE_STONE, FLOWSTONE]
## The wild meadows' natural ground (owner #45b): the lists of natural blocks take it in like GRASS and DIRT.
const MEADOWS_GROUND: Array[int] = [MUD, PATH]
## Owner #55: the space worlds' natural ground (the Moon's dust and rock, Planet Boing's moss, soil, rock and jelly,
## Rainbow Planet's prism grass and stripes): the lists of natural blocks take it in.
const SPACE_GROUND: Array[int] = [MOON_DUST, MOON_ROCK, DEEP_MOON_ROCK, BOING_MOSS, BOING_SOIL, BOING_ROCK, JELLY,
	PRISM_GRASS, RAINBOW_RED, RAINBOW_ORANGE, RAINBOW_YELLOW, RAINBOW_GREEN, RAINBOW_BLUE, RAINBOW_VIOLET,
	MARS_DUST, MARS_REGOLITH, BASALT, DEEP_BASALT, MARS_SEDIMENT, POLAR_ICE, DRY_ICE,   # cosmos: Mars
	EUROPA_ICE, LINEA_ICE, BAND_ICE, DEEP_ICE, EUROPA_ROCK,   # cosmos: Europa
	SULPHUR, ORANGE_SULPHUR, SULPHUR_FROST, RED_SULPHUR, IO_ROCK, BLACK_LAVA,   # cosmos: Io
	TITAN_SOIL, ICE_PEBBLES, DUNE_SAND, WET_SHORE, ICY_ROCK,   # cosmos: Titan
	MERCURY_DUST, MERCURY_ROCK, DARK_DUST, RAY_DUST, SHADOW_ICE,   # cosmos: Mercury
	VENUS_CLOUD, DEEP_CLOUD, CLOUD_DECK, FLOAT_HULL, SKY_TURF,   # cosmos: Venus's clouds and its city's decks and hulls
	RING_ICE, RING_FROST, DUSTY_ICE, RING_ROCK, MOONLET_ICE, RIDGE_DUST,   # cosmos: Saturn's rings' chunks and Pan
	NITROGEN_ICE, CELL_EDGE, WATER_ICE, PLUTO_FROST, THOLIN_DUST, RED_ICE, METHANE_SNOW,   # cosmos: Pluto
	TRITON_FROST, PINK_ICE, MOTTLED_ICE, GEYSER_DUST, CANTALOUPE_ICE, RIDGE_ICE, ICE_LAVA,   # cosmos: Triton
	GROOVED_ICE, TROUGH_ICE, DARK_ICE, OLD_ICE, RAY_ICE, POLAR_FROST]   # cosmos: Ganymede
## Blocks you can walk through (besides air).
const NON_SOLID: Array[int] = [WATER, DOOR_OPEN, BUSH, DEAD_BUSH, TRAP_SAND, POWERED_DOOR_OPEN, COIN, COTTON_CANDY,
	CLOUD,   # owner 39: the Dragon Realm's clouds
	FLOWERS, WHEAT,   # owner #45b
	CORN, PRAYER_FLAGS, SPRAY,   # owner #78, the third tour: the cornfield, the flags, the falls' spray
	STALACTITE, STALAGMITE]   # universe 6: the Glow Caves' dripstone pictures

const PLACEABLE: Array[int] = [
	GRASS, DIRT, STONE, SAND, LOG, PLANKS, LEAVES, GLASS,
	BRICK, LIGHT, WATER, RED, YELLOW, GREEN, BLUE, PURPLE,
	DEEPSTONE, COAL, IRON, GOLD, DIAMOND, CRYSTAL,
	BED,
	JUMP_PAD, SPEED_PAD,
	BUSH, BARREL, CLOSET,   # M2 Task 5: hiding spots
	DOOR, SPIKE_TRAP, LANTERN,   # M2 Task 8 (an open door is made by opening a door, never picked)
	PORTAL_FRAME, PORTAL_CORE,   # M3 Task 5
	CRAFTING_TABLE, FURNACE,     # crafting (spec §12.19)
]

const _NAMES := {
	GRASS: "Grass", DIRT: "Dirt", STONE: "Stone", SAND: "Sand", LOG: "Wood", PLANKS: "Planks",
	LEAVES: "Leaves", GLASS: "Glass", BRICK: "Brick", LIGHT: "Light", WATER: "Water",
	RED: "Red", YELLOW: "Yellow", GREEN: "Green", BLUE: "Blue", PURPLE: "Purple",
	DEEPSTONE: "Deep Stone", BEDROCK: "Bedrock", COAL: "Coal", IRON: "Iron", GOLD: "Gold",
	DIAMOND: "Diamond", CRYSTAL: "Crystal",
	BED: "Bed",
	DOOR: "Door", DOOR_OPEN: "Open Door", SPIKE_TRAP: "Spike Trap", LANTERN: "Lantern", BUSH: "Bush",
	BARREL: "Barrel", CLOSET: "Closet",
	FAKE_WALL: "Stone", PRESSURE_PLATE: "Pressure Plate", TROPHY: "Golden Trophy", GOLD_LAMP: "Golden Lamp",
	JUMP_PAD: "Jump Pad", SPEED_PAD: "Speed Pad",
	SANDSTONE: "Sandstone", CUT_SANDSTONE: "Cut Sandstone", CHISELED_SANDSTONE: "Carved Sandstone",
	RED_SAND: "Red Sand", RED_SANDSTONE: "Red Sandstone", CACTUS: "Cactus", DEAD_BUSH: "Dry Bush",
	DESERT_GLASS: "Desert Glass", PALM_LOG: "Palm Wood", PALM_LEAVES: "Palm Leaves", PYRAMID_GOLD: "Pyramid Gold",
	DESERT_LAMP: "Desert Lamp", ARROW_SLIT: "Arrow Slit", TRAP_SAND: "Sand", FAKE_SANDSTONE: "Sandstone",
	SNOW: "Snow", SNOWY_GRASS: "Snowy Grass", PACKED_SNOW: "Packed Snow", ICE: "Ice", BLUE_ICE: "Blue Ice",
	PINE_LOG: "Pine Wood", PINE_NEEDLES: "Pine Needles", FROZEN_ORE: "Frozen Ore", SNOW_BRICK: "Snow Brick",
	ICE_LANTERN: "Ice Lantern", FROSTED_GLASS: "Frosted Glass", FAKE_SNOW: "Packed Snow",
	PORTAL_FRAME: "Portal Frame", PORTAL_CORE: "Portal Core",
	CRAFTING_TABLE: "Workbench", FURNACE: "Clay Oven",   # owner #43: our own stations (spec §3c)
	BUTTON: "Button", BUTTON_ON: "Pressed Button", LEVER: "Lever", LEVER_ON: "Lever (on)",
	POWERED_DOOR: "Powered Door", POWERED_DOOR_OPEN: "Open Powered Door", LAMP: "Lamp", LAMP_ON: "Lamp (lit)",
	LIGHT_SWITCH: "Light Switch", LIGHT_SWITCH_ON: "Light Switch (on)", TELEPORT_PAD: "Teleport Pad",
	START: "Start Block", CHECKPOINT: "Checkpoint", FINISH: "Finish Block", COIN: "Coin Block", BOUNCE: "Bounce Pad",
	FROSTING: "Frosting", CAKE: "Cake", CHOCOLATE: "Chocolate", CANDY_CANE: "Candy Cane", LOLLIPOP: "Lollipop",
	GUMDROP: "Green Gumdrop", RED_GUMDROP: "Red Gumdrop", CREAM: "Cream", JAM: "Jam", SUGAR_GLASS: "Sugar Glass",
	GINGERBREAD: "Gingerbread", CANDY_LAMP: "Candy Lamp", COTTON_CANDY: "Cotton Candy", SPRINKLES: "Sprinkles",
	GOLDEN_CANDY: "Golden Candy", FAKE_CHOCOLATE: "Chocolate",
	ZIPLINE_POST: "Zipline Post", LAUNCH_PAD: "Launch Pad",   # M3 Task 14a
	SADDLE: "Saddle",
	TROPHY_SHELF: "Trophy Shelf", BOOKSHELF: "Bookshelf",   # M3 Task 21b
	# M3 Task 8: painted blocks
	PAINTED_WHITE: "Painted White", PAINTED_SILVER: "Painted Silver", PAINTED_GREY: "Painted Grey",
	PAINTED_BLACK: "Painted Black", PAINTED_BROWN: "Painted Brown", PAINTED_RED: "Painted Red",
	PAINTED_ORANGE: "Painted Orange", PAINTED_YELLOW: "Painted Yellow", PAINTED_LIME: "Painted Lime",
	PAINTED_GREEN: "Painted Green", PAINTED_TEAL: "Painted Teal", PAINTED_SKY: "Painted Sky Blue",
	PAINTED_BLUE: "Painted Blue", PAINTED_PURPLE: "Painted Purple", PAINTED_MAGENTA: "Painted Magenta",
	PAINTED_PINK: "Painted Pink",
	CORE_MEADOWS: "Meadows Portal Core", CORE_DESERT: "Desert Portal Core", CORE_FROST: "Frost Portal Core",   # owner 39
	CORE_CANDY: "Candy Portal Core", CORE_DRAGON: "Dragon Portal Core", CORE_GLOW: "Glow Portal Core",
	SKY_GRASS: "Sky Grass", FLOATSTONE: "Floatstone", DEEP_FLOATSTONE: "Deep Floatstone",   # owner 39: the Dragon Realm
	CRYSTAL_SPIRE: "Crystal Spire", MUSHROOM_STEM: "Mushroom Stem", GLOW_CAP: "Glow Cap", DRAGON_SCALE: "Dragon Scale",
	EMBER_SCALE: "Ember Scale", STARGLASS: "Starglass", MOON_LAMP: "Moon Lamp", CLOUD: "Cloud", NEST: "Dragon Nest",
	FLOATSTONE_BRICK: "Floatstone Brick", DRAGON_GOLD: "Dragon Gold", FAKE_FLOATSTONE: "Floatstone",
	BIRCH_LOG: "Birch Wood", BIRCH_LEAVES: "Birch Leaves", DARK_LOG: "Dark Wood", DARK_LEAVES: "Dark Leaves",   # owner #45b
	FLOWERS: "Flowers", LILY_PAD: "Lily Pad", MUD: "Mud", STONE_BRICK: "Stone Bricks", MOSSY_BRICK: "Mossy Bricks",
	PLASTER: "White Plaster", ROOF_TILES: "Roof Tiles", HAY: "Hay", WHEAT: "Wheat", SAIL: "Sail Cloth",
	GLOW_MUSHROOM: "Glow Mushroom", PATH: "Dirt Path",
	PUMPKIN: "Pumpkin", JACK_O_LANTERN: "Jack-o-Lantern", SNOWMAN_HEAD: "Snowman Head", CHEESE: "Tiny Cheese",   # M3 Task 21c
	MOON_DUST: "Moon Dust", MOON_ROCK: "Moon Rock", DEEP_MOON_ROCK: "Deep Moon Rock", MOON_CRYSTAL: "Moon Crystal",   # owner #55
	MOON_CHEESE: "Moon Cheese", BASE_PANEL: "Base Panel", PORTHOLE: "Porthole", LANDING_PAD: "Landing Pad",
	STAR_GOLD: "Star Gold", FAKE_MOON_ROCK: "Moon Rock", BASE_LIGHT: "Base Light",
	BOING_MOSS: "Boing Moss", BOING_SOIL: "Boing Soil", BOING_ROCK: "Boing Rock", JELLY: "Jelly",
	SPRING_STEM: "Spring Stem", SPRING_CAP: "Spring Cap", BOING_GLOW: "Glow Bulb", BOING_BRICK: "Boing Brick",
	FAKE_BOING_ROCK: "Boing Rock",
	PRISM_GRASS: "Prism Grass", RAINBOW_RED: "Red Stripe", RAINBOW_ORANGE: "Orange Stripe", RAINBOW_YELLOW: "Yellow Stripe",
	RAINBOW_GREEN: "Green Stripe", RAINBOW_BLUE: "Blue Stripe", RAINBOW_VIOLET: "Violet Stripe",
	PRISM_CRYSTAL: "Prism Crystal", PRISM_BRICK: "Prism Brick", PRISM_LAMP: "Prism Lamp", FAKE_RAINBOW: "Blue Stripe",
	MARS_DUST: "Mars Dust", MARS_REGOLITH: "Regolith", BASALT: "Basalt", DEEP_BASALT: "Deep Basalt",   # cosmos: Mars
	MARS_SEDIMENT: "Layered Rock", POLAR_ICE: "Polar Ice", DRY_ICE: "Dry Ice", GYPSUM: "Gypsum Crystal",
	ROVER_PANEL: "Rover Panel", ROVER_WHEEL: "Rover Wheel", SOLAR_PANEL: "Solar Panel", LANDER_FOIL: "Gold Foil",
	FAKE_BASALT: "Basalt", ROVER_LIGHT: "Rover Light",
	LAB_BENCH: "Lab Bench",   # spec §23: the Science Lab
	EUROPA_ICE: "Europa Ice", LINEA_ICE: "Reddish Ice", BAND_ICE: "Stained Ice", DEEP_ICE: "Deep Ice",   # cosmos: Europa
	EUROPA_ROCK: "Seafloor Rock", GLOW_ICE: "Glow Ice", SALT: "Sea Salt", GEYSER_VENT: "Geyser Vent",
	PROBE_PANEL: "Lander Panel", MELT_PROBE: "Melt Probe", PROBE_LIGHT: "Lander Light", ICE_BRICK: "Ice Brick",
	FAKE_DEEP_ICE: "Deep Ice",
	SULPHUR: "Sulphur", ORANGE_SULPHUR: "Orange Sulphur", SULPHUR_FROST: "Sulphur Frost", RED_SULPHUR: "Red Sulphur",   # Io
	IO_ROCK: "Io Rock", BLACK_LAVA: "Black Lava Rock", LAVA_CRUST: "Lava Crust", HOT_LAVA: "Hot Lava",
	VOLCANO_VENT: "Volcano Vent", SULPHUR_CRYSTAL: "Sulphur Crystal", HEAT_TILE: "Heat Tile", LANDER_LEG: "Lander Leg",
	HEAT_CAMERA: "Heat Camera", SULPHUR_BRICK: "Sulphur Brick", FAKE_IO_ROCK: "Io Rock",
	TITAN_SOIL: "Titan Soil", ICE_PEBBLES: "Ice Pebbles", DUNE_SAND: "Dune Grains", WET_SHORE: "Wet Shore",   # Titan
	ICY_ROCK: "Icy Rock", SHORE_CRYSTAL: "Shore Crystal", PROBE_SHELL: "Probe Shell", PARACHUTE: "Parachute",
	PROBE_LAMP: "Probe Lamp", TITAN_BRICK: "Station Brick", FAKE_ICY_ROCK: "Icy Rock",
	MERCURY_DUST: "Mercury Dust", MERCURY_ROCK: "Mercury Rock", DARK_DUST: "Dark Dust", RAY_DUST: "Ray Dust",   # Mercury
	SHADOW_ICE: "Shadow Ice", ICE_CRYSTAL: "Ice Crystal", SUNSHADE: "Sunshade", HEAT_BLANKET: "Heat Blanket",
	MIRROR_PANEL: "Mirror Panel", EXPLORER_LAMP: "Explorer Lamp", THERMOMETER: "Thermometer",
	THERMO_BULB: "Thermometer Bulb", EXPLORER_BRICK: "Explorer Brick", FAKE_MERCURY_ROCK: "Mercury Rock",
	VENUS_CLOUD: "Yellow Cloud", DEEP_CLOUD: "Deep Cloud", CLOUD_DECK: "Cloud Deck", FLOAT_HULL: "Float Hull",   # Venus
	SKY_TURF: "Sky Turf", SKY_BRIDGE: "Sky Bridge", CLOUD_LAMP: "Cloud Lamp", SKY_FRAME: "Sky Frame",
	HOME_PANEL: "Home Panel", BLIMP_SKIN: "Blimp Skin", BLIMP_STRIPE: "Blimp Stripe", GONDOLA: "Gondola",
	SOLAR_FILM: "Solar Film", CLOUD_CRYSTAL: "Cloud Crystal", TELESCOPE: "Telescope", FAKE_FLOAT_HULL: "Float Hull",
	RING_ICE: "Ring Ice", RING_FROST: "Ring Frost", DUSTY_ICE: "Dusty Ice", RING_ROCK: "Ring Rock",   # Saturn's rings
	MOONLET_ICE: "Moonlet Ice", RIDGE_DUST: "Ridge Dust", RING_CRYSTAL: "Ring Crystal", STATION_PANEL: "Station Panel",
	STATION_WINDOW: "Station Window", STATION_LAMP: "Station Lamp", RADIO_DISH: "Radio Dish", POWER_PACK: "Power Pack",
	TRUSS: "Truss", RING_BEACON: "Ring Beacon", SATURN_BAND: "Saturn Band", FAKE_RING_ICE: "Ring Ice",
	NITROGEN_ICE: "Nitrogen Ice", CELL_EDGE: "Cell Edge Ice", WATER_ICE: "Water Ice", PLUTO_FROST: "Pluto Frost",   # Pluto
	THOLIN_DUST: "Tholin Dust", RED_ICE: "Red Ice", METHANE_SNOW: "Methane Snow", FROST_CRYSTAL: "Frost Crystal",
	DRAG_BALLOON: "Drag Balloon", CHARON_GLOBE: "Charon Globe", HEART_BEACON: "Heart Beacon", FROST_BRICK: "Frost Brick",
	FAKE_WATER_ICE: "Water Ice",
	TRITON_FROST: "Triton Frost", PINK_ICE: "Pink Ice", MOTTLED_ICE: "Mottled Ice", GEYSER_DUST: "Geyser Dust",   # Triton
	NITROGEN_GEYSER: "Nitrogen Geyser", CANTALOUPE_ICE: "Cantaloupe Ice", RIDGE_ICE: "Ridge Ice", ICE_LAVA: "Ice Lava",
	NITROGEN_CRYSTAL: "Nitrogen Crystal", NITROGEN_TANK: "Nitrogen Tank", NEPTUNE_GLOBE: "Neptune Globe",
	BLUE_BEACON: "Blue Beacon", CAP_BRICK: "Cap Brick", FAKE_PINK_ICE: "Pink Ice",
	GROOVED_ICE: "Grooved Ice", TROUGH_ICE: "Trough Ice", DARK_ICE: "Dark Ice", OLD_ICE: "Old Ice",   # Ganymede
	RAY_ICE: "Ray Ice", POLAR_FROST: "Polar Frost", AURORA_CRYSTAL: "Aurora Crystal", JUPITER_GLOBE: "Jupiter Globe",
	AURORA_LAMP: "Aurora Lamp", MAGNETOMETER: "Magnetometer", GROOVE_BRICK: "Groove Brick",
	FAKE_GROOVED_ICE: "Grooved Ice",
	XYLOPHONE: "Xylophone", DRUM: "Bongo Drums",   # owner #110: the music blocks (page 44)
	ROCKET_ENGINE: "Rocket Engine", SPACE_ENGINE: "Space Engine", FUEL_TANK: "Fuel Tank", NOSE_CONE: "Nose Cone",   # §21d
	CREW_CAPSULE: "Crew Capsule", SERVICE_MODULE: "Service Module", HEAT_SHIELD: "Heat Shield",
	LANDING_LEGS: "Landing Legs", ROCKET_FINS: "Rocket Fins", STAGE_SEPARATOR: "Stage Separator",
	SOLAR_ARRAY: "Solar Array", PARACHUTE_PACK: "Parachute Pack", PAD_CONCRETE: "Pad Concrete", PAD_STRIPE: "Pad Stripe",
	GOLD_QUARTZ: "Gold Quartz", GOLD_GRAVEL: "Gold Gravel", COPPER_ORE: "Copper Ore", MALACHITE: "Malachite",   # §26
	BANDED_IRON: "Banded Iron", RUSTY_ROCK: "Rusty Rock", FERN_SHALE: "Fern Shale", OIL_SEEP: "Oil Seep",
	ROCK_SALT: "Rock Salt", SALT_CRUST: "Salt Crust", COPPER: "Copper", TABLE_SALT: "Table Salt", CRUDE_OIL: "Crude Oil",
	KEROSENE: "Kerosene", PLASTIC: "Plastic", REFINERY: "Refinery",
	WALL_BRICK: "Wall Brick", FAKE_WALL_BRICK: "Wall Brick", ROSE_ROCK: "Rose Rock", ROSE_STONE: "Rose Stone",   # §24
	ROSE_COLUMN: "Rose Column", TRAVERTINE: "Travertine", FAKE_TRAVERTINE: "Travertine", MAYA_STONE: "Maya Stone",
	MAYA_CARVING: "Maya Carving", SERPENT_HEAD: "Serpent Head", JAGUAR_THRONE: "Jaguar Throne",
	FAKE_MAYA_STONE: "Maya Stone", INCA_STONE: "Inca Stone", FAKE_INCA_STONE: "Inca Stone", SOAPSTONE: "Soapstone",
	INLAID_MARBLE: "Inlaid Marble", MUGHAL_RED: "Mughal Red Stone", FAKE_WHITE_BRICK: "White Stone",
	KAIBAB_LIMESTONE: "Kaibab Limestone", COCONINO_SANDSTONE: "Coconino Sandstone", SUPAI_REDBED: "Red Canyon Rock",   # §24
	REDWALL_LIMESTONE: "Redwall Limestone", CANYON_SHALE: "Canyon Shale", VISHNU_SCHIST: "Vishnu Schist",
	SEA_FOSSIL: "Sea Fossil", BRAIN_CORAL: "Brain Coral", STAGHORN_CORAL: "Staghorn Coral", SEA_FAN: "Sea Fan",
	CINDER: "Cinders", CORN: "Corn", PRAYER_FLAGS: "Prayer Flags", SPRAY: "Waterfall Spray",
	DOME_GLASS: "Dome Glass", COLONY_PANEL: "Colony Panel", COLONY_FLOOR: "Colony Floor",   # spec §21c: the colonies
	GREENHOUSE_SOIL: "Greenhouse Soil", GROW_LAMP: "Grow Lamp", COLONY_LIGHT: "Colony Light", FRUIT_LEAVES: "Fruit Leaves",
	WATER_TANK: "Water Tank", ICE_MELTER: "Ice Melter", OXYGEN_MAKER: "Oxygen Maker", CONTROL_SCREEN: "Control Screen",
	COLONY_MAP: "Colony Map", AIRLOCK_FRAME: "Airlock Frame", ROCKET_HULL: "Rocket Hull",
	PRINTED_REGOLITH: "Printed Regolith", COLONY_TABLE: "Colony Table",
	LIMESTONE: "Limestone", CASING_STONE: "Casing Stone", GRANITE: "Granite", FAKE_LIMESTONE: "Limestone",   # §24
	MARBLE: "Marble", MARBLE_COLUMN: "Marble Column", CAPITAL: "Column Top", FRIEZE: "Frieze", FAKE_MARBLE: "Marble",
	BRONZE: "Bronze", IVORY: "Ivory", GOLD_LEAF: "Gold Leaf", EBONY: "Ebony", BABYLON_BRICK: "Babylon Brick",
	GLAZED_BRICK: "Glazed Brick", FAKE_BABYLON_BRICK: "Babylon Brick", BEACON_FIRE: "Beacon Fire",
	WHITE_BRICK: "White Stone", PAVING: "Paving", WONDER_PLAQUE: "Wonder Plaque", SCREW_PUMP: "Water Screw",
	OLIVE_LEAVES: "Olive Leaves",
	ICY_REGOLITH: "Icy Regolith", MARE_DUST: "Mare Dust", ILMENITE: "Ilmenite", KREEP_ROCK: "KREEP Rock",   # §26.5
	IRON_METEORITE: "Iron Meteorite", GROUND_ICE: "Ground Ice", BLUEBERRY_SOIL: "Blueberry Soil", HEMATITE: "Hematite",
	DARK_SAND: "Dark Sand", MARS_SALT: "Mars Salt", OXYGEN_TANK: "Oxygen Tank", HYDROGEN_FUEL: "Hydrogen Fuel",
	TITANIUM: "Titanium", RARE_EARTHS: "Rare Earth Powder", HELIUM_3: "Helium-3", SOLAR_OVEN: "Solar Oven",
	CAVE_STONE: "Cave Stone", GLOW_MOSS: "Glow Moss", SHROOM_STEM: "Glowshroom Stem",   # universe 6: the Glow Caves
	BLUE_SHROOM: "Blue Glowshroom", ROSE_SHROOM: "Rose Glowshroom", GLOW_WORMS: "Glow-worm Ceiling",
	SELENITE: "Selenite Crystal", FLOWSTONE: "Flowstone", STALACTITE: "Stalactite", STALAGMITE: "Stalagmite",
	LAKE_STONE: "Cave Lake Stone", FUNGUS_PLANKS: "Fungus Planks", SPORE_LAMP: "Spore Lamp", CAVE_PEARL: "Cave Pearls",
	CAVE_GOLD: "Cave Gold", FAKE_CAVE_STONE: "Cave Stone",
}


static func display_name(id: int) -> String:
	return _NAMES.get(id, "")


## Ids 400-511 are the items' (ItemIds: 400-499, and room): block pages 22-28 are never used. Block pages go on from
## 29 (ids 512-527: Titan's), then 30 (528-543: Mercury's), 31 (544-559: the colony domes', spec §21c), 32
## (560-575: the rocket parts, spec §21d), 33-34 (576-607: the wonders', spec §24), 35 (608-623: prospecting's
## riches, spec §26), 36-37 (624-655: the New Seven Wonders' and nature's), 38 (656-671: Venus's cloud city), 39 (672-687: the
## riches of the Moon and Mars, spec §26.5), 40 (688-703: Saturn's rings), 41 (704-719: Pluto), 42 (720-735: Triton),
## 43 (736-751: Ganymede), 44 (752-767: the music page, owner #110: 752-753 used, 754-767 kept for more instruments),
## 45 (768-783: universe 6, the Glow Caves, all used) …
## (Io's agent, 2026-09-29: page 21, ids 384-399, was the last one below the items). COUNT
## runs past the gaps: the voxel library holds empty models there (BlockLibrary.build).
const RESERVED_FIRST := 400
const RESERVED_END := 512
const NEXT_PAGE_FIRST_ID := 784   # where the next block page's ids begin (move it on as pages are taken; Ganymede took 43,
                                  # owner #110's music blocks 44: 752-753 used, 754-767 kept for more instruments; the
                                  # Glow Caves 45: 768-783; the next page is 46)


static func is_reserved(id: int) -> bool:
	return id >= RESERVED_FIRST and id < RESERVED_END


## An id in the blocks' range (not air, not an item's), whether or not a block owns it yet.
static func is_block_id(id: int) -> bool:
	return id > AIR and id < COUNT and not is_reserved(id)


## Solid blocks stop movement; air, water, open doors and bushes do not.
static func is_solid(id: int) -> bool:
	return is_block_id(id) and not NON_SOLID.has(id)


## True for ids a player may place (an id no block owns yet, a gap below COUNT, never is).
static func is_valid(id: int) -> bool:
	return is_block_id(id) and id != BEDROCK and _NAMES.has(id)


## False for blocks nobody can break or replace (the bedrock floor).
static func is_breakable(id: int) -> bool:
	return id != BEDROCK
