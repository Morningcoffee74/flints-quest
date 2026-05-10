class_name GroundEnemy
extends BaseEnemy

const GRAVITY       := 980.0
const DETECT_RANGE  := 220.0

var _patrol_dir := 1.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var player := _get_player()
	if player != null and global_position.distance_to(player.global_position) < DETECT_RANGE:
		velocity.x = sign(player.global_position.x - global_position.x) * speed * 1.3
	else:
		velocity.x = _patrol_dir * speed

	move_and_slide()

	if is_on_wall():
		_patrol_dir *= -1.0

func _get_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
