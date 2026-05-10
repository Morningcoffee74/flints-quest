class_name FlyingEnemy
extends BaseEnemy

@export var sine_amplitude: float  = 40.0
@export var sine_frequency: float  = 2.0
@export var patrol_range: float    = 200.0

var _time        := 0.0
var _start_pos   := Vector2.ZERO
var _patrol_dir  := 1.0

func _ready() -> void:
	super._ready()
	_start_pos = global_position

func _physics_process(delta: float) -> void:
	_time += delta
	velocity.x = _patrol_dir * speed
	velocity.y = sin(_time * sine_frequency) * sine_amplitude

	if abs(global_position.x - _start_pos.x) >= patrol_range:
		_patrol_dir *= -1.0

	move_and_slide()
