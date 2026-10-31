class_name AnimalBoxes
extends RefCounted
## The box models of owner feedback #41's animals (spec §14.19), in BlockyAnimal's format: [center, size, colour]
## and a fourth element PART for the boxes of the part that moves on its own (BlockyAnimal.PART_PIVOT: a head
## that bobs, a tail that wags, an owl's head that turns). Animals face -Z and stand on y = 0. c = body colour,
## d = detail colour (AnimalRules.SPECIES colors). Built once per species by BlockyAnimal and shared.

const P := BlockyAnimal.PART
const BLACK := BlockyAnimal.BLACK
const WHITE := BlockyAnimal.WHITE
const ORANGE := Color("f29a2e")
const BEAK := Color("f2c230")


static func boxes(species: StringName, c: Color, d: Color) -> Array:
	var dark := c.darkened(0.3)
	match species:
		&"horse":   # a brown horse with a dark mane and tail; its head bobs to graze
			return [
				[Vector3(0, 1.0, 0.05), Vector3(0.55, 0.5, 1.3), c],             # body
				[Vector3(0, 1.28, -0.62), Vector3(0.28, 0.5, 0.3), c],          # neck
				[Vector3(0, 1.42, -0.52), Vector3(0.08, 0.5, 0.32), d],         # mane
				[Vector3(0, 1.05, 0.73), Vector3(0.12, 0.55, 0.12), d],         # tail
				[Vector3(0, 1.6, -0.92), Vector3(0.28, 0.3, 0.5), c, P],        # head
				[Vector3(0, 1.53, -1.19), Vector3(0.24, 0.2, 0.06), Color("5a3a22"), P],   # muzzle
				[Vector3(-0.09, 1.8, -0.8), Vector3(0.06, 0.12, 0.06), c, P],   # ears
				[Vector3(0.09, 1.8, -0.8), Vector3(0.06, 0.12, 0.06), c, P],
				[Vector3(-0.145, 1.65, -0.98), Vector3(0.02, 0.06, 0.06), BLACK, P],
				[Vector3(0.145, 1.65, -0.98), Vector3(0.02, 0.06, 0.06), BLACK, P],
			] + BlockyAnimal._legs(0.2, -0.45, 0.5, 0.16, 0.75, c) + _hooves(0.2, -0.45, 0.5, 0.17, dark)
		&"donkey":   # grey with a pale belly and muzzle, long ears, a dark stripe down its back
			return [
				[Vector3(0, 0.8, 0.03), Vector3(0.45, 0.42, 1.0), c],
				[Vector3(0, 0.585, 0.03), Vector3(0.36, 0.02, 0.8), d],         # belly
				[Vector3(0, 1.015, 0.03), Vector3(0.06, 0.02, 0.9), Color("4a4640")],   # stripe
				[Vector3(0, 0.98, -0.46), Vector3(0.2, 0.3, 0.2), c],           # neck
				[Vector3(0, 0.8, 0.56), Vector3(0.06, 0.35, 0.06), c],          # tail
				[Vector3(0, 1.1, -0.68), Vector3(0.26, 0.3, 0.36), c, P],       # head
				[Vector3(0, 1.02, -0.88), Vector3(0.22, 0.18, 0.06), d, P],     # muzzle
				[Vector3(-0.08, 1.38, -0.6), Vector3(0.07, 0.3, 0.06), c, P],   # long ears
				[Vector3(0.08, 1.38, -0.6), Vector3(0.07, 0.3, 0.06), c, P],
				[Vector3(-0.131, 1.15, -0.76), Vector3(0.02, 0.06, 0.06), BLACK, P],
				[Vector3(0.131, 1.15, -0.76), Vector3(0.02, 0.06, 0.06), BLACK, P],
			] + BlockyAnimal._legs(0.16, -0.36, 0.38, 0.13, 0.6, c)
		&"goat":   # white with curved horns and a little beard
			return [
				[Vector3(0, 0.55, 0.02), Vector3(0.36, 0.32, 0.62), c],
				[Vector3(0, 0.68, 0.34), Vector3(0.06, 0.12, 0.06), c],         # tail
				[Vector3(0, 0.72, -0.4), Vector3(0.22, 0.24, 0.26), c, P],      # head
				[Vector3(-0.07, 0.9, -0.36), Vector3(0.05, 0.14, 0.05), d, P],  # horns
				[Vector3(0.07, 0.9, -0.36), Vector3(0.05, 0.14, 0.05), d, P],
				[Vector3(-0.07, 0.96, -0.3), Vector3(0.05, 0.05, 0.1), d, P],
				[Vector3(0.07, 0.96, -0.3), Vector3(0.05, 0.05, 0.1), d, P],
				[Vector3(0, 0.56, -0.5), Vector3(0.06, 0.12, 0.04), d, P],      # beard
				[Vector3(-0.15, 0.76, -0.38), Vector3(0.08, 0.04, 0.06), c, P], # ears
				[Vector3(0.15, 0.76, -0.38), Vector3(0.08, 0.04, 0.06), c, P],
				[Vector3(-0.06, 0.77, -0.531), Vector3(0.04, 0.04, 0.01), BLACK, P],
				[Vector3(0.06, 0.77, -0.531), Vector3(0.04, 0.04, 0.01), BLACK, P],
			] + BlockyAnimal._legs(0.12, -0.2, 0.22, 0.09, 0.4, d)
		&"deer":   # a fawn-brown deer with white spots, a white tail and little antlers
			return [
				[Vector3(0, 0.78, 0.03), Vector3(0.36, 0.34, 0.8), c],
				[Vector3(-0.1, 0.955, 0.1), Vector3(0.06, 0.01, 0.06), d],      # spots
				[Vector3(0.1, 0.955, -0.12), Vector3(0.06, 0.01, 0.06), d],
				[Vector3(0.05, 0.955, 0.28), Vector3(0.05, 0.01, 0.05), d],
				[Vector3(0, 0.9, 0.44), Vector3(0.08, 0.1, 0.04), d],           # tail
				[Vector3(0, 1.0, -0.42), Vector3(0.16, 0.34, 0.16), c, P],      # neck
				[Vector3(0, 1.18, -0.52), Vector3(0.2, 0.2, 0.3), c, P],        # head
				[Vector3(0, 1.14, -0.7), Vector3(0.12, 0.12, 0.08), Color("5a3a22"), P],
				[Vector3(-0.13, 1.3, -0.46), Vector3(0.1, 0.12, 0.04), c, P],   # ears
				[Vector3(0.13, 1.3, -0.46), Vector3(0.1, 0.12, 0.04), c, P],
				[Vector3(-0.06, 1.36, -0.5), Vector3(0.03, 0.16, 0.03), Color("c8b28a"), P],   # antlers
				[Vector3(0.06, 1.36, -0.5), Vector3(0.03, 0.16, 0.03), Color("c8b28a"), P],
				[Vector3(-0.101, 1.22, -0.6), Vector3(0.01, 0.05, 0.05), BLACK, P],
				[Vector3(0.101, 1.22, -0.6), Vector3(0.01, 0.05, 0.05), BLACK, P],
			] + BlockyAnimal._legs(0.12, -0.28, 0.3, 0.08, 0.61, c)
		&"duck":   # a mallard: brown body, green head, white collar, yellow beak, orange feet
			return [
				[Vector3(0, 0.18, 0.03), Vector3(0.28, 0.2, 0.4), c],
				[Vector3(0, 0.26, 0.24), Vector3(0.14, 0.08, 0.1), c],          # tail up
				[Vector3(-0.145, 0.2, 0.05), Vector3(0.02, 0.12, 0.26), c.darkened(0.2)],   # wings
				[Vector3(0.145, 0.2, 0.05), Vector3(0.02, 0.12, 0.26), c.darkened(0.2)],
				[Vector3(-0.06, 0.03, -0.02), Vector3(0.06, 0.06, 0.08), ORANGE],   # feet
				[Vector3(0.06, 0.03, -0.02), Vector3(0.06, 0.06, 0.08), ORANGE],
				[Vector3(0, 0.3, -0.14), Vector3(0.15, 0.03, 0.15), WHITE, P],  # collar
				[Vector3(0, 0.38, -0.15), Vector3(0.16, 0.16, 0.16), d, P],     # head
				[Vector3(0, 0.35, -0.27), Vector3(0.1, 0.04, 0.1), BEAK, P],    # beak
				[Vector3(-0.081, 0.41, -0.18), Vector3(0.01, 0.03, 0.03), BLACK, P],
				[Vector3(0.081, 0.41, -0.18), Vector3(0.01, 0.03, 0.03), BLACK, P],
			]
		&"frog":   # green with big round eyes and strong back legs
			return [
				[Vector3(0, 0.1, 0.02), Vector3(0.26, 0.14, 0.3), c],
				[Vector3(0, 0.16, -0.1), Vector3(0.24, 0.1, 0.16), c],          # head
				[Vector3(0, 0.035, 0.0), Vector3(0.22, 0.01, 0.26), d],         # belly
				[Vector3(-0.07, 0.23, -0.12), Vector3(0.07, 0.07, 0.07), WHITE],   # eyes
				[Vector3(0.07, 0.23, -0.12), Vector3(0.07, 0.07, 0.07), WHITE],
				[Vector3(-0.07, 0.235, -0.157), Vector3(0.04, 0.04, 0.01), BLACK],
				[Vector3(0.07, 0.235, -0.157), Vector3(0.04, 0.04, 0.01), BLACK],
				[Vector3(0, 0.13, -0.182), Vector3(0.16, 0.01, 0.01), dark],    # smile
				[Vector3(-0.15, 0.05, 0.1), Vector3(0.06, 0.08, 0.18), c],      # back legs
				[Vector3(0.15, 0.05, 0.1), Vector3(0.06, 0.08, 0.18), c],
				[Vector3(-0.1, 0.03, -0.12), Vector3(0.04, 0.06, 0.04), c],     # front legs
				[Vector3(0.1, 0.03, -0.12), Vector3(0.04, 0.06, 0.04), c],
			]
		&"turtle":   # a green shell with a darker top and a brown rim; its head pokes out
			return [
				[Vector3(0, 0.2, 0.02), Vector3(0.46, 0.18, 0.56), c],          # shell
				[Vector3(0, 0.31, 0.02), Vector3(0.34, 0.06, 0.42), c.darkened(0.15)],
				[Vector3(0, 0.12, 0.02), Vector3(0.5, 0.04, 0.6), Color("8d6e3f")],   # rim
				[Vector3(-0.2, 0.05, -0.18), Vector3(0.1, 0.1, 0.1), d],        # legs
				[Vector3(0.2, 0.05, -0.18), Vector3(0.1, 0.1, 0.1), d],
				[Vector3(-0.2, 0.05, 0.2), Vector3(0.1, 0.1, 0.1), d],
				[Vector3(0.2, 0.05, 0.2), Vector3(0.1, 0.1, 0.1), d],
				[Vector3(0, 0.1, 0.34), Vector3(0.05, 0.04, 0.08), d],          # tail
				[Vector3(0, 0.17, -0.38), Vector3(0.14, 0.12, 0.16), d, P],     # head
				[Vector3(-0.071, 0.2, -0.42), Vector3(0.01, 0.03, 0.03), BLACK, P],
				[Vector3(0.071, 0.2, -0.42), Vector3(0.01, 0.03, 0.03), BLACK, P],
			]
		&"squirrel":   # red-brown with a pale chest and a big bushy tail that flicks
			return [
				[Vector3(0, 0.16, 0.0), Vector3(0.18, 0.18, 0.3), c],
				[Vector3(0, 0.27, -0.16), Vector3(0.16, 0.15, 0.14), c],        # head
				[Vector3(0, 0.18, -0.151), Vector3(0.12, 0.12, 0.01), d],       # chest
				[Vector3(-0.05, 0.37, -0.15), Vector3(0.04, 0.06, 0.03), c],    # ears
				[Vector3(0.05, 0.37, -0.15), Vector3(0.04, 0.06, 0.03), c],
				[Vector3(-0.05, 0.3, -0.231), Vector3(0.03, 0.03, 0.01), BLACK],
				[Vector3(0.05, 0.3, -0.231), Vector3(0.03, 0.03, 0.01), BLACK],
				[Vector3(0, 0.34, 0.24), Vector3(0.12, 0.36, 0.12), c, P],      # tail
				[Vector3(0, 0.52, 0.18), Vector3(0.12, 0.1, 0.14), c, P],
			] + BlockyAnimal._legs(0.06, -0.08, 0.08, 0.05, 0.07, c)
		&"owl":   # brown with a pale face disc, big yellow eyes and ear tufts; its head turns
			return [
				[Vector3(0, 0.27, 0), Vector3(0.3, 0.36, 0.26), c],
				[Vector3(0, 0.25, -0.131), Vector3(0.2, 0.26, 0.01), d],        # belly
				[Vector3(-0.16, 0.27, 0.02), Vector3(0.03, 0.3, 0.22), c.darkened(0.15)],   # wings
				[Vector3(0.16, 0.27, 0.02), Vector3(0.03, 0.3, 0.22), c.darkened(0.15)],
				[Vector3(-0.06, 0.04, -0.05), Vector3(0.06, 0.08, 0.06), BEAK], # feet
				[Vector3(0.06, 0.04, -0.05), Vector3(0.06, 0.08, 0.06), BEAK],
				[Vector3(0, 0.54, 0), Vector3(0.3, 0.2, 0.26), c, P],           # head
				[Vector3(0, 0.54, -0.131), Vector3(0.24, 0.16, 0.01), d, P],    # face disc
				[Vector3(-0.06, 0.56, -0.14), Vector3(0.07, 0.07, 0.01), Color("ffd23f"), P],
				[Vector3(0.06, 0.56, -0.14), Vector3(0.07, 0.07, 0.01), Color("ffd23f"), P],
				[Vector3(-0.06, 0.56, -0.146), Vector3(0.035, 0.035, 0.01), BLACK, P],
				[Vector3(0.06, 0.56, -0.146), Vector3(0.035, 0.035, 0.01), BLACK, P],
				[Vector3(0, 0.51, -0.15), Vector3(0.04, 0.05, 0.03), Color("e0a030"), P],
				[Vector3(-0.1, 0.66, 0), Vector3(0.05, 0.06, 0.05), c, P],      # ear tufts
				[Vector3(0.1, 0.66, 0), Vector3(0.05, 0.06, 0.05), c, P],
			]
		&"hedgehog":   # a spiky brown back, a pale pointy face and a black nose
			return [
				[Vector3(0, 0.15, 0.03), Vector3(0.3, 0.2, 0.4), c],
				[Vector3(0, 0.27, 0.0), Vector3(0.24, 0.06, 0.32), c.darkened(0.2)],   # spines
				[Vector3(0, 0.305, 0.05), Vector3(0.14, 0.03, 0.2), c.darkened(0.35)],
				[Vector3(0, 0.1, -0.2), Vector3(0.16, 0.12, 0.12), d],          # face
				[Vector3(0, 0.1, -0.265), Vector3(0.04, 0.04, 0.02), BLACK],    # nose
				[Vector3(-0.05, 0.14, -0.261), Vector3(0.03, 0.03, 0.01), BLACK],
				[Vector3(0.05, 0.14, -0.261), Vector3(0.03, 0.03, 0.01), BLACK],
			] + BlockyAnimal._legs(0.1, -0.1, 0.12, 0.05, 0.05, d)
		&"camel":   # sandy with one hump, a long neck and a darker muzzle
			return [
				[Vector3(0, 1.1, 0.05), Vector3(0.55, 0.5, 1.25), c],
				[Vector3(0, 1.45, 0.1), Vector3(0.4, 0.25, 0.5), c],            # hump
				[Vector3(0, 1.35, -0.72), Vector3(0.2, 0.5, 0.22), c],          # neck
				[Vector3(0, 1.1, 0.7), Vector3(0.06, 0.3, 0.06), d],            # tail
				[Vector3(0, 1.62, -0.9), Vector3(0.24, 0.24, 0.42), c, P],      # head
				[Vector3(0, 1.56, -1.12), Vector3(0.2, 0.16, 0.06), d, P],      # muzzle
				[Vector3(-0.1, 1.77, -0.82), Vector3(0.05, 0.06, 0.05), d, P],  # ears
				[Vector3(0.1, 1.77, -0.82), Vector3(0.05, 0.06, 0.05), d, P],
				[Vector3(-0.121, 1.67, -0.97), Vector3(0.01, 0.05, 0.05), BLACK, P],
				[Vector3(0.121, 1.67, -0.97), Vector3(0.01, 0.05, 0.05), BLACK, P],
			] + BlockyAnimal._legs(0.2, -0.45, 0.5, 0.15, 0.85, c) + _hooves(0.2, -0.45, 0.5, 0.16, d)
		&"lizard":   # a green lizard with a yellow stripe and a long tail that swishes
			return [
				[Vector3(0, 0.07, 0.0), Vector3(0.16, 0.08, 0.3), c],
				[Vector3(0, 0.113, 0.0), Vector3(0.05, 0.01, 0.26), d],         # stripe
				[Vector3(0, 0.08, -0.2), Vector3(0.12, 0.07, 0.12), c],         # head
				[Vector3(-0.061, 0.1, -0.22), Vector3(0.01, 0.03, 0.03), BLACK],
				[Vector3(0.061, 0.1, -0.22), Vector3(0.01, 0.03, 0.03), BLACK],
				[Vector3(-0.11, 0.03, -0.1), Vector3(0.08, 0.04, 0.05), c],     # legs
				[Vector3(0.11, 0.03, -0.1), Vector3(0.08, 0.04, 0.05), c],
				[Vector3(-0.11, 0.03, 0.1), Vector3(0.08, 0.04, 0.05), c],
				[Vector3(0.11, 0.03, 0.1), Vector3(0.08, 0.04, 0.05), c],
				[Vector3(0, 0.06, 0.3), Vector3(0.06, 0.05, 0.3), c, P],        # tail
				[Vector3(0, 0.05, 0.48), Vector3(0.03, 0.03, 0.08), d, P],
			]
		&"fennec":   # a small cream fox with huge ears and a black-tipped tail
			return [
				[Vector3(0, 0.28, 0.04), Vector3(0.24, 0.2, 0.42), c],
				[Vector3(0, 0.27, -0.17), Vector3(0.18, 0.14, 0.04), d],        # chest
				[Vector3(0, 0.4, -0.24), Vector3(0.22, 0.19, 0.19), c],         # head
				[Vector3(0, 0.36, -0.37), Vector3(0.1, 0.08, 0.1), d],          # snout
				[Vector3(0, 0.38, -0.425), Vector3(0.04, 0.03, 0.02), BLACK],
				[Vector3(-0.085, 0.58, -0.23), Vector3(0.1, 0.2, 0.04), c],     # big ears
				[Vector3(0.085, 0.58, -0.23), Vector3(0.1, 0.2, 0.04), c],
				[Vector3(-0.085, 0.58, -0.251), Vector3(0.06, 0.14, 0.01), Color("f7c6a3")],
				[Vector3(0.085, 0.58, -0.251), Vector3(0.06, 0.14, 0.01), Color("f7c6a3")],
				[Vector3(-0.055, 0.43, -0.331), Vector3(0.04, 0.04, 0.01), BLACK],
				[Vector3(0.055, 0.43, -0.331), Vector3(0.04, 0.04, 0.01), BLACK],
				[Vector3(0, 0.33, 0.38), Vector3(0.12, 0.12, 0.24), c, P],      # tail
				[Vector3(0, 0.33, 0.52), Vector3(0.1, 0.1, 0.06), Color("3a2a22"), P],
			] + BlockyAnimal._legs(0.08, -0.1, 0.18, 0.06, 0.18, c)
		&"penguin":   # black with a white belly and face patches, an orange beak and feet
			return [
				[Vector3(0, 0.34, 0), Vector3(0.3, 0.5, 0.26), c],
				[Vector3(0, 0.32, -0.131), Vector3(0.22, 0.4, 0.01), d],        # belly
				[Vector3(-0.165, 0.36, 0.0), Vector3(0.03, 0.3, 0.14), c],      # flippers
				[Vector3(0.165, 0.36, 0.0), Vector3(0.03, 0.3, 0.14), c],
				[Vector3(-0.06, 0.03, -0.07), Vector3(0.08, 0.04, 0.1), ORANGE],
				[Vector3(0.06, 0.03, -0.07), Vector3(0.08, 0.04, 0.1), ORANGE],
				[Vector3(0, 0.68, 0), Vector3(0.24, 0.2, 0.22), c, P],          # head
				[Vector3(-0.06, 0.7, -0.111), Vector3(0.06, 0.06, 0.01), WHITE, P],
				[Vector3(0.06, 0.7, -0.111), Vector3(0.06, 0.06, 0.01), WHITE, P],
				[Vector3(-0.06, 0.7, -0.117), Vector3(0.03, 0.03, 0.01), BLACK, P],
				[Vector3(0.06, 0.7, -0.117), Vector3(0.03, 0.03, 0.01), BLACK, P],
				[Vector3(0, 0.65, -0.14), Vector3(0.06, 0.04, 0.08), ORANGE, P],
			]
		&"polar_bear":   # big, white and fluffy, with a black nose; its head bobs
			return [
				[Vector3(0, 0.85, 0.05), Vector3(0.8, 0.65, 1.4), c],
				[Vector3(0, 0.95, 0.77), Vector3(0.14, 0.12, 0.06), c],         # tail
				[Vector3(0, 1.0, -0.95), Vector3(0.46, 0.42, 0.42), c, P],      # head
				[Vector3(0, 0.9, -1.2), Vector3(0.24, 0.2, 0.14), c.darkened(0.04), P],   # snout
				[Vector3(0, 0.96, -1.275), Vector3(0.1, 0.07, 0.03), d, P],     # nose
				[Vector3(-0.12, 1.1, -1.161), Vector3(0.05, 0.05, 0.01), BLACK, P],
				[Vector3(0.12, 1.1, -1.161), Vector3(0.05, 0.05, 0.01), BLACK, P],
				[Vector3(-0.18, 1.25, -0.9), Vector3(0.1, 0.1, 0.06), c, P],    # ears
				[Vector3(0.18, 1.25, -0.9), Vector3(0.1, 0.1, 0.06), c, P],
			] + BlockyAnimal._legs(0.26, -0.5, 0.52, 0.26, 0.55, c)
		&"seal":   # grey with darker spots, big black eyes and flippers
			return [
				[Vector3(0, 0.22, 0.1), Vector3(0.44, 0.4, 0.8), c],
				[Vector3(0, 0.12, 0.6), Vector3(0.3, 0.2, 0.3), c],             # tail end
				[Vector3(-0.14, 0.05, 0.8), Vector3(0.14, 0.04, 0.16), c.darkened(0.2)],   # back flippers
				[Vector3(0.14, 0.05, 0.8), Vector3(0.14, 0.04, 0.16), c.darkened(0.2)],
				[Vector3(-0.26, 0.06, -0.15), Vector3(0.12, 0.04, 0.2), c.darkened(0.2)],  # front flippers
				[Vector3(0.26, 0.06, -0.15), Vector3(0.12, 0.04, 0.2), c.darkened(0.2)],
				[Vector3(0.1, 0.425, 0.0), Vector3(0.08, 0.01, 0.08), d],       # spots
				[Vector3(-0.12, 0.425, 0.25), Vector3(0.06, 0.01, 0.06), d],
				[Vector3(0, 0.4, -0.42), Vector3(0.32, 0.28, 0.3), c, P],       # head
				[Vector3(0, 0.35, -0.6), Vector3(0.16, 0.12, 0.08), c.lightened(0.15), P],
				[Vector3(0, 0.38, -0.645), Vector3(0.05, 0.04, 0.02), BLACK, P],
				[Vector3(-0.09, 0.46, -0.571), Vector3(0.06, 0.06, 0.01), BLACK, P],
				[Vector3(0.09, 0.46, -0.571), Vector3(0.06, 0.06, 0.01), BLACK, P],
			]
		&"gummy_bunny":   # a shiny red gummy with long ears and a pale belly
			return [
				[Vector3(0, 0.17, 0.04), Vector3(0.28, 0.26, 0.32), c],
				[Vector3(0, 0.2, -0.121), Vector3(0.16, 0.14, 0.01), d],        # belly shine
				[Vector3(0, 0.36, -0.1), Vector3(0.24, 0.2, 0.2), c],           # head
				[Vector3(-0.06, 0.56, -0.1), Vector3(0.07, 0.22, 0.05), c],     # ears
				[Vector3(0.06, 0.56, -0.1), Vector3(0.07, 0.22, 0.05), c],
				[Vector3(-0.06, 0.64, -0.126), Vector3(0.04, 0.08, 0.01), d],
				[Vector3(0.06, 0.64, -0.126), Vector3(0.04, 0.08, 0.01), d],
				[Vector3(-0.06, 0.39, -0.201), Vector3(0.04, 0.05, 0.01), Color("7a0f2a")],
				[Vector3(0.06, 0.39, -0.201), Vector3(0.04, 0.05, 0.01), Color("7a0f2a")],
				[Vector3(0, 0.22, 0.22), Vector3(0.1, 0.1, 0.06), d],           # tail puff
				[Vector3(-0.08, 0.03, -0.02), Vector3(0.08, 0.06, 0.14), c],    # feet
				[Vector3(0.08, 0.03, -0.02), Vector3(0.08, 0.06, 0.14), c],
			]
		&"moon_bunny":   # owner #55: a round silver-white bunny, very long ears with pale blue insides, big dark eyes
			return [
				[Vector3(0, 0.19, 0.04), Vector3(0.3, 0.28, 0.34), c],
				[Vector3(0, 0.38, -0.12), Vector3(0.26, 0.22, 0.22), c],        # head
				[Vector3(-0.07, 0.62, -0.1), Vector3(0.07, 0.3, 0.05), c],      # ears
				[Vector3(0.07, 0.62, -0.1), Vector3(0.07, 0.3, 0.05), c],
				[Vector3(-0.07, 0.64, -0.126), Vector3(0.04, 0.2, 0.01), d],    # their pale blue insides
				[Vector3(0.07, 0.64, -0.126), Vector3(0.04, 0.2, 0.01), d],
				[Vector3(-0.065, 0.41, -0.231), Vector3(0.06, 0.07, 0.01), Color("1d2233")],   # big eyes
				[Vector3(0.065, 0.41, -0.231), Vector3(0.06, 0.07, 0.01), Color("1d2233")],
				[Vector3(-0.05, 0.43, -0.236), Vector3(0.02, 0.02, 0.01), Color.WHITE],        # their shine
				[Vector3(0.08, 0.43, -0.236), Vector3(0.02, 0.02, 0.01), Color.WHITE],
				[Vector3(0, 0.34, -0.236), Vector3(0.04, 0.03, 0.01), d],       # a little blue nose
				[Vector3(0, 0.24, 0.24), Vector3(0.12, 0.12, 0.08), d],         # a blue tail puff
				[Vector3(-0.09, 0.03, -0.03), Vector3(0.09, 0.06, 0.16), c],    # feet
				[Vector3(0.09, 0.03, -0.03), Vector3(0.09, 0.06, 0.16), c],
			]
		&"candy_bird":   # a sky-blue bird with pink wings, a white candy stripe and a crest
			return [
				[Vector3(0, 0.2, 0.02), Vector3(0.2, 0.2, 0.26), c],
				[Vector3(0, 0.2, -0.111), Vector3(0.18, 0.04, 0.01), WHITE],    # candy stripe
				[Vector3(-0.11, 0.21, 0.03), Vector3(0.02, 0.14, 0.2), d],      # wings
				[Vector3(0.11, 0.21, 0.03), Vector3(0.02, 0.14, 0.2), d],
				[Vector3(0, 0.35, -0.06), Vector3(0.16, 0.15, 0.15), c],        # head
				[Vector3(0, 0.33, -0.16), Vector3(0.05, 0.04, 0.06), BEAK],
				[Vector3(-0.05, 0.37, -0.136), Vector3(0.03, 0.03, 0.01), BLACK],
				[Vector3(0.05, 0.37, -0.136), Vector3(0.03, 0.03, 0.01), BLACK],
				[Vector3(0, 0.45, -0.05), Vector3(0.03, 0.06, 0.08), d],        # crest
				[Vector3(-0.04, 0.05, 0.02), Vector3(0.02, 0.1, 0.02), Color("8a8a8a")],   # legs
				[Vector3(0.04, 0.05, 0.02), Vector3(0.02, 0.1, 0.02), Color("8a8a8a")],
				[Vector3(0, 0.24, 0.22), Vector3(0.1, 0.03, 0.16), d, P],       # tail
			]
	return [[Vector3(0, 0.5, 0), Vector3.ONE * 0.5, c]]


## Darker hooves at the bottom of four legs (horse, camel).
static func _hooves(x: float, front: float, back: float, w: float, color: Color) -> Array:
	var out: Array = []
	for lx in [-x, x]:
		for lz in [front, back]:
			out.append([Vector3(lx, 0.05, lz), Vector3(w, 0.1, w), color])
	return out
