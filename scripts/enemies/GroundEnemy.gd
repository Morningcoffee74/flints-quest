class_name GroundEnemy
extends BaseEnemy

const GRAVITY       := 980.0
const DETECT_RANGE  := 220.0
const LUNGE_TIME    := 0.4
const LUNGE_COOLDOWN := 2.5

## Als true sprint de vijand kort op de speler af zodra die gezien wordt.
@export var lunge_enabled: bool = false

var _patrol_dir := 1.0
var _lunge_timer := 0.0
var _lunge_cd := 0.0
var _lunge_dir := 1.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_lunge_cd = maxf(0.0, _lunge_cd - delta)

	if _lunge_timer > 0.0:
		_lunge_timer -= delta
		velocity.x = _lunge_dir * speed * 2.5
		if not _ground_ahead(_lunge_dir):
			_lunge_timer = 0.0
			velocity.x = 0.0
	else:
		var player := _get_player()
		var sees_player := player != null \
			and global_position.distance_to(player.global_position) < DETECT_RANGE
		if sees_player and lunge_enabled and _lunge_cd <= 0.0:
			_lunge_dir = sign(player.global_position.x - global_position.x)
			_lunge_timer = LUNGE_TIME
			_lunge_cd = LUNGE_COOLDOWN
			velocity.x = _lunge_dir * speed * 2.5
		elif sees_player:
			velocity.x = sign(player.global_position.x - global_position.x) * speed * 1.3
			if not _ground_ahead(sign(velocity.x)):
				velocity.x = 0.0
		else:
			if not _ground_ahead(_patrol_dir):
				_patrol_dir *= -1.0
			velocity.x = _patrol_dir * speed

	move_and_slide()
	_update_facing()

	if is_on_wall():
		_patrol_dir *= -1.0

## Voorkomt dat grondvijanden van randen aflopen (en in ravijnen verdwijnen).
func _ground_ahead(dir: float) -> bool:
	if not is_on_floor() or dir == 0.0:
		return true
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * 20.0, -8.0)
	var params := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 48.0), 1)
	return not space.intersect_ray(params).is_empty()

func _get_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
