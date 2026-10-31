extends GutTest
## Merge of Tasks 10 + 13: sleeping used to turn the avatar node onto its back AND the model's
## set_pose(sleep) turned its body again, so sleepers lay upside down. The model owns the pose now;
## sleeping only faces the bed. Both avatar styles must lie on their back once, head to the pillow.

var world: WorldService
var player: Player


func before_each() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)


func _check_lying(style: String) -> void:
	player.set_avatar_style(style)
	player.avatar.rotation.y = 1.3                  # whatever the player was facing
	player.set_sleeping(true, Vector3i(0, 30, 0))
	var basis := player.avatar.body_pivot().global_transform.basis.orthonormalized()
	var head := basis.y                             # the body's up axis runs to the head
	var face := -basis.z                            # the body faces its -Z
	assert_gt(head.z, 0.9, "%s: head towards the pillow (+Z), got %s" % [style, head])
	assert_gt(face.y, 0.9, "%s: lying on the back, face up, got %s" % [style, face])
	player.set_sleeping(false, Vector3i(0, 30, 0))
	var up := player.avatar.body_pivot().global_transform.basis.orthonormalized().y
	assert_gt(up.y, 0.9, "%s: standing again" % style)


func test_blocky_avatar_lies_on_its_back_once() -> void:
	_check_lying("blocky")


func test_realistic_avatar_lies_on_its_back_once() -> void:
	_check_lying("realistic")


## Merge of Tasks 11 + 13: the held weapon hangs in the avatar's hand; switching the graphics style
## replaces the avatar, which must not take the weapon down with it.
func test_the_held_weapon_moves_to_the_new_avatar() -> void:
	player.held_item = ItemIds.SWORD
	player._update_held_item()
	var held := player._held
	assert_not_null(held)
	player.set_process(false)          # the swap can happen after the player's _process this frame
	player.set_avatar_style("realistic")
	await get_tree().process_frame   # the old avatar is freed now
	assert_true(is_instance_valid(held), "the weapon survives the swap")
	player._update_held_item()
	assert_same(player._held.get_parent(), player.avatar.hand(), "and sits in the new hand")
