extends Area2D

## Banaan die een hangende aap (ThrowEnemy) naar de speler gooit: een boogje met
## zwaartekracht, tollend in de lucht. Raakt hij de speler of de wereld, dan is
## hij weg. Vergelijkbaar met BossProjectile.gd, maar met een echte
## worprichting in plaats van alleen vallen.

const GRAVITY := 900.0
const LIFETIME := 5.0

var velocity: Vector2 = Vector2.ZERO
var _age := 0.0
var _spin := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_spin = 7.0 if velocity.x >= 0.0 else -7.0

func _physics_process(delta: float) -> void:
	_age += delta
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation += _spin * delta
	if _age > LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage()
	queue_free()
