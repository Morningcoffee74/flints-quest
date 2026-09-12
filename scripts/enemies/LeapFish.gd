class_name LeapFish
extends BaseEnemy

## Vliegende vis (Wereld 2): wacht onder de waterlijn en springt om de zoveel
## seconden in een boog uit het water — gevaarlijk voor wie op een eiland
## staat of aan het oppervlak zwemt. Is in de lucht met een klap of een stomp
## te verslaan. Landt weer op zijn startpunt onder water.

@export var leap_interval: float = 2.6
@export var leap_velocity: float = -620.0
@export var horizontal_speed: float = 60.0
## Wereld-y van de waterlijn; erboven geldt gewone zwaartekracht.
@export var water_top_y: float = 640.0

const GRAVITY := 980.0
const WATER_DRAG := 4.0

var _timer := 0.0
var _start := Vector2.ZERO
var _dir := 1.0

func _ready() -> void:
	super._ready()
	_start = global_position
	_timer = leap_interval * randf_range(0.3, 1.0)

func _physics_process(delta: float) -> void:
	var in_water := global_position.y > water_top_y
	if in_water:
		# Terug naar het startpunt zakken en daar wachten.
		velocity = velocity.lerp(Vector2.ZERO, WATER_DRAG * delta)
		global_position = global_position.lerp(_start, 2.0 * delta)
		_timer -= delta
		if _timer <= 0.0:
			_timer = leap_interval
			_dir = -_dir
			var player := _get_player()
			if player != null:
				_dir = signf(player.global_position.x - global_position.x)
				if _dir == 0.0:
					_dir = 1.0
			velocity = Vector2(_dir * horizontal_speed, leap_velocity)
			global_position.y = water_top_y - 1.0
	else:
		velocity.y += GRAVITY * delta
	move_and_slide()
	_update_facing()
	if _sprite != null:
		# Neus omhoog bij het stijgen, omlaag bij het vallen.
		_sprite.rotation = clampf(velocity.y / 900.0, -0.6, 0.6) * (1.0 if velocity.x >= 0.0 else -1.0) if not in_water else 0.0

func _get_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
