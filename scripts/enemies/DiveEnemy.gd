class_name DiveEnemy
extends BaseEnemy

## Vliegt heen en weer en duikt op de speler zodra die eronder loopt.
## Bukken (kleinere hitbox) laat de duik overheen scheren.

@export var sine_amplitude: float = 40.0
@export var sine_frequency: float = 2.0
@export var patrol_range: float   = 200.0
@export var dive_range: float     = 150.0

const DIVE_COOLDOWN := 2.5
const DIVE_SPEED_MULT := 3.0

enum Mode { PATROL, DIVE, RETURN }

var _mode: Mode = Mode.PATROL
var _time := 0.0
var _start_pos := Vector2.ZERO
var _patrol_dir := 1.0
var _dive_target := Vector2.ZERO
var _dive_cd := 0.0

func _ready() -> void:
	super._ready()
	_start_pos = global_position

func _physics_process(delta: float) -> void:
	_time += delta
	_dive_cd = maxf(0.0, _dive_cd - delta)

	match _mode:
		Mode.PATROL:
			velocity.x = _patrol_dir * speed
			velocity.y = sin(_time * sine_frequency) * sine_amplitude
			if abs(global_position.x - _start_pos.x) >= patrol_range:
				_patrol_dir *= -1.0
			_check_dive()
		Mode.DIVE:
			var to_target := _dive_target - global_position
			if to_target.length() < 12.0 or global_position.y > _dive_target.y:
				_mode = Mode.RETURN
			else:
				velocity = to_target.normalized() * speed * DIVE_SPEED_MULT
		Mode.RETURN:
			var back := Vector2(global_position.x, _start_pos.y) - global_position
			if abs(back.y) < 8.0:
				_mode = Mode.PATROL
				velocity = Vector2.ZERO
			else:
				velocity = back.normalized() * speed * 1.5

	move_and_slide()
	_update_facing()

func _check_dive() -> void:
	if _dive_cd > 0.0:
		return
	var player := _get_player()
	if player == null:
		return
	var dx: float = abs(player.global_position.x - global_position.x)
	var below: bool = player.global_position.y > global_position.y + 40.0
	if dx < dive_range and below:
		# Mik op de bovenkant van een stáánde speler; wie bukt wordt gemist.
		_dive_target = player.global_position + Vector2(0, -44.0)
		_mode = Mode.DIVE
		_dive_cd = DIVE_COOLDOWN

func _get_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
