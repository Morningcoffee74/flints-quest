class_name SwarmBat
extends BaseEnemy

## Zwerm-vleermuis (Wereld 3): wacht buiten beeld rechts van de speler en
## schiet, zodra de speler `trigger_x` passeert (na `delay` s), in een rechte
## lijn naar links door de gang op ongeveer stahoogte — bukken helpt niet, je
## moet in een gat (kuil) springen om de zwerm over je heen te laten razen.
## Voorbij `end_x` verdwijnt hij weer. Vliegt dwars door rots/platforms heen
## (collision_mask 0), zodat de zwerm nooit ergens blijft haken.
## Telt niet mee voor de vijanden-eis (de generator laat zwerm-vleermuizen
## buiten de telling), maar een rake klap levert wél punten op.

@export var trigger_x: float = 0.0
@export var end_x: float = -400.0
@export var delay: float = 0.0
@export var fly_speed: float = 260.0
## Kleine golfbeweging zodat de zwerm niet als één streep vliegt.
@export var wobble: float = 10.0

var _flying := false
var _timer := 0.0
var _t := 0.0
var _base_y := 0.0

func _ready() -> void:
	super._ready()
	_base_y = global_position.y
	# Eigen snelheidsopbouw: de gewone difficulty-schaal (tot ×2) zou de zwerm
	# in latere levels onontwijkbaar maken.
	speed = fly_speed * minf(1.4, GameManager.get_speed_difficulty())
	_t = randf() * TAU

func _physics_process(delta: float) -> void:
	_t += delta
	if not _flying:
		var player := _get_player()
		if player != null and player.global_position.x >= trigger_x:
			_timer -= delta
			if _timer <= -delay:
				_flying = true
		velocity = Vector2.ZERO
		return
	velocity.x = -speed
	velocity.y = cos(_t * 6.0) * wobble * 6.0
	move_and_slide()
	_update_facing()
	if global_position.x < end_x:
		queue_free()

func _get_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
