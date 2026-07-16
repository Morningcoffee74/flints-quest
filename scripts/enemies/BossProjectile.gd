extends Area2D

## Vallende tak van de ForestBoss (fase 2).

const GRAVITY := 600.0
const LIFETIME := 4.0

var _velocity_y := 40.0
var _age := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = randf_range(-0.3, 0.3)

func _physics_process(delta: float) -> void:
	_age += delta
	_velocity_y += GRAVITY * delta
	position.y += _velocity_y * delta
	if _age > LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage()
	queue_free()
