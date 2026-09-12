class_name SwimEnemy
extends BaseEnemy

## Zwemmende vijand (Wereld 2). Patrouilleert horizontaal met een lichte
## golfbeweging; met `hunter` aan schiet hij op de speler af zodra die in de
## buurt zwemt — met een korte, zichtbare aanloop (wind-up) zodat je kunt
## wegduiken. Blijft altijd onder de waterlijn (`water_top_y`).

@export var sine_amplitude: float = 22.0
@export var sine_frequency: float = 1.8
@export var patrol_range: float   = 120.0
@export var hunter: bool          = false
@export var hunt_range: float     = 260.0
## Wereld-y van het wateroppervlak; de vis mikt nooit hoger dan iets hieronder.
@export var water_top_y: float    = 640.0

const WINDUP_TIME  := 0.5
const DASH_TIME    := 0.55
const DASH_MULT    := 2.8
const HUNT_COOLDOWN := 3.2

enum Mode { PATROL, WINDUP, DASH, RETURN }

var _mode: Mode = Mode.PATROL
var _time := 0.0
var _start_pos := Vector2.ZERO
var _patrol_dir := 1.0
var _target := Vector2.ZERO
var _timer := 0.0
var _cd := 0.0

func _ready() -> void:
	super._ready()
	_start_pos = global_position

func _physics_process(delta: float) -> void:
	_time += delta
	_cd = maxf(0.0, _cd - delta)

	match _mode:
		Mode.PATROL:
			velocity.x = _patrol_dir * speed
			velocity.y = sin(_time * sine_frequency) * sine_amplitude
			if abs(global_position.x - _start_pos.x) >= patrol_range:
				_patrol_dir = -signf(global_position.x - _start_pos.x)
			elif is_on_wall():
				# Tegen een rots aan: omkeren i.p.v. blijven duwen.
				_patrol_dir *= -1.0
			if hunter:
				_check_hunt()
		Mode.WINDUP:
			# Aanloop: even stil hangen met een waarschuwingstint.
			velocity = velocity.move_toward(Vector2.ZERO, speed * 6.0 * delta)
			_timer -= delta
			modulate = Color(1.0, 0.7, 0.55)
			if _timer <= 0.0:
				modulate = Color.WHITE
				_mode = Mode.DASH
				_timer = DASH_TIME
				var dir := (_target - global_position)
				velocity = dir.normalized() * speed * DASH_MULT if dir.length() > 1.0 else Vector2.ZERO
		Mode.DASH:
			_timer -= delta
			if _timer <= 0.0 or global_position.distance_to(_target) < 10.0:
				_mode = Mode.RETURN
		Mode.RETURN:
			var back := _start_pos - global_position
			if back.length() < 10.0:
				_mode = Mode.PATROL
				velocity = Vector2.ZERO
			else:
				velocity = back.normalized() * speed * 1.4

	# Nooit boven de waterlijn uitkomen.
	if global_position.y < water_top_y + 24.0 and velocity.y < 0.0:
		velocity.y = 0.0
		global_position.y = water_top_y + 24.0

	move_and_slide()
	_update_facing()

func _check_hunt() -> void:
	if _cd > 0.0:
		return
	var player := _get_player()
	if player == null:
		return
	var to_player := player.global_position - global_position
	# Alleen jagen op een speler die zelf in het water is.
	if to_player.length() > hunt_range or player.global_position.y < water_top_y:
		return
	_target = player.global_position + Vector2(0.0, -30.0)
	_target.y = maxf(_target.y, water_top_y + 24.0)
	_mode = Mode.WINDUP
	_timer = WINDUP_TIME
	_cd = HUNT_COOLDOWN

func _get_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
