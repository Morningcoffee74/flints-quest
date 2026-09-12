extends Area2D

## Springveer: lanceert de speler die erop landt hoog de lucht in (hoger dan
## een gewone sprong), zodat anders onbereikbare platforms te halen zijn.
## Procedureel getekend (spiraal + plaat); veert kort in bij gebruik.

@export var launch_velocity: float = -900.0

var _cooldown := 0.0
@onready var _plate: Polygon2D = $Plate
@onready var _coil: Line2D = $Coil

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player or _cooldown > 0.0:
		return
	var player := body as Player
	if player.velocity.y < -50.0:
		return  # van onderaf: negeren
	player.velocity.y = launch_velocity
	player.global_position.y = global_position.y - 2.0
	_cooldown = 0.25
	AudioManager.play_sfx_by_name("jump")
	# Inveren-animatie.
	var tween := create_tween()
	tween.tween_property(_plate, "position:y", 8.0, 0.06)
	tween.parallel().tween_property(_coil, "scale:y", 0.5, 0.06)
	tween.tween_property(_plate, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(_coil, "scale:y", 1.0, 0.14).set_trans(Tween.TRANS_BACK)
