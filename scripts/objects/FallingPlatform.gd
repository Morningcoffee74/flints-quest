class_name FallingPlatform
extends StaticBody2D

## Houten platform dat begint te trillen zodra de speler erop staat en daarna
## naar beneden valt; na een tijdje komt het weer terug op zijn plek.
##
## Met `mode = "sink"` gedraagt hetzelfde object zich als een drijvende boomstam
## in het moeras van Wereld 4: hij valt niet weg maar ZAKT langzaam onder je
## gewicht, en komt weer omhoog zodra je eraf stapt. Je kunt er dus even op
## staan, maar niet blijven treuzelen.

@export var fall_delay: float   = 0.7   # seconden trillen voordat het valt
@export var respawn_time: float = 3.0   # seconden voordat het terugkomt
## "fall" = instortend platform, "sink" = wegzakkende boomstam.
@export var mode: String = "fall"
@export var sink_depth: float = 44.0    # hoe diep een stam wegzakt
@export var sink_speed: float = 26.0    # px/s omlaag terwijl je erop staat
@export var rise_speed: float = 60.0    # px/s terug omhoog als je eraf bent

const FALL_GRAVITY := 900.0
const SHAKE_AMP    := 2.5

enum State { STEADY, SHAKING, FALLING, GONE }

var _state: State = State.STEADY
var _timer: float = 0.0
var _fall_vy: float = 0.0
var _origin: Vector2 = Vector2.ZERO

@onready var _sprite: Node2D            = $Sprite
@onready var _col:    CollisionShape2D  = $Collision

var _standing := false

func _ready() -> void:
	_origin = position
	var detector := $StandDetector as Area2D
	detector.body_entered.connect(_on_body_entered)
	detector.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if mode == "sink":
		_standing = true
		return
	if _state == State.STEADY:
		_state = State.SHAKING
		_timer = fall_delay

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_standing = false

func _physics_process(delta: float) -> void:
	if mode == "sink":
		_sink_step(delta)
		return
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

## Boomstam-stand: zakt weg terwijl de speler erop staat en komt weer omhoog
## zodra hij eraf is. Het platform blijft altijd vast (geen collision uit), dus
## je valt er nooit doorheen — je moet gewoon doorlopen voordat hij te diep ligt.
func _sink_step(delta: float) -> void:
	var target: float = _origin.y + (sink_depth if _standing else 0.0)
	var speed: float = sink_speed if _standing else rise_speed
	position.y = move_toward(position.y, target, speed * delta)
	# Iets dieper = iets donkerder, zodat je ziet dat hij wegzakt.
	var t: float = clampf((position.y - _origin.y) / maxf(sink_depth, 1.0), 0.0, 1.0)
	_sprite.modulate = Color(1.0, 1.0, 1.0).lerp(Color(0.62, 0.66, 0.58), t)
