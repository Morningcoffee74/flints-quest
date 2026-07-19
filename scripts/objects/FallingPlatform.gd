class_name FallingPlatform
extends StaticBody2D

## Houten platform dat begint te trillen zodra de speler erop staat en daarna
## naar beneden valt; na een tijdje komt het weer terug op zijn plek.

@export var fall_delay: float   = 0.7   # seconden trillen voordat het valt
@export var respawn_time: float = 3.0   # seconden voordat het terugkomt

const FALL_GRAVITY := 900.0
const SHAKE_AMP    := 2.5

enum State { STEADY, SHAKING, FALLING, GONE }

var _state: State = State.STEADY
var _timer: float = 0.0
var _fall_vy: float = 0.0
var _origin: Vector2 = Vector2.ZERO

@onready var _sprite: Node2D            = $Sprite
@onready var _col:    CollisionShape2D  = $Collision

func _ready() -> void:
	_origin = position
	($StandDetector as Area2D).body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _state == State.STEADY and body is Player:
		_state = State.SHAKING
		_timer = fall_delay

func _physics_process(delta: float) -> void:
	match _state:
		State.SHAKING:
			_timer -= delta
			_sprite.position.x = randf_range(-SHAKE_AMP, SHAKE_AMP)
			if _timer <= 0.0:
				_sprite.position.x = 0.0
				_state = State.FALLING
				_fall_vy = 0.0
				# Speler valt er nu doorheen.
				_col.set_deferred("disabled", true)
		State.FALLING:
			_fall_vy += FALL_GRAVITY * delta
			position.y += _fall_vy * delta
			_sprite.modulate.a = maxf(0.0, _sprite.modulate.a - delta * 1.2)
			if _sprite.modulate.a <= 0.0:
				visible = false
				_state = State.GONE
				_timer = respawn_time
		State.GONE:
			_timer -= delta
			if _timer <= 0.0:
				_respawn()

func _respawn() -> void:
	position = _origin
	_sprite.position = Vector2.ZERO
	_sprite.modulate.a = 1.0
	visible = true
	_col.set_deferred("disabled", false)
	_state = State.STEADY
