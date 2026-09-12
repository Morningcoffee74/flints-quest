extends Area2D

## Stroming (Wereld 2): duwt een zwemmende speler in `push`-richting zolang die
## in de zone zit (tegenstroom maakt een stuk zee zwaarder, meestroom sneller).
## Zichtbaar door meedrijvende streepjes. Zet `size` en `push` per zone.

@export var size: Vector2 = Vector2(600.0, 500.0):
	set(v):
		size = v
		if is_inside_tree():
			_build()
@export var push: Vector2 = Vector2(-70.0, 0.0)

var _player: Player = null
var _particles: CPUParticles2D = null

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_build()

func _build() -> void:
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		(shape.shape as RectangleShape2D).size = size
	if _particles != null:
		_particles.queue_free()
	_particles = CPUParticles2D.new()
	_particles.amount = clampi(int(size.x * size.y / 9000.0), 12, 90)
	_particles.lifetime = 2.2
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = size / 2.0
	_particles.direction = push.normalized()
	_particles.spread = 4.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = push.length() * 1.2
	_particles.initial_velocity_max = push.length() * 1.8
	_particles.scale_amount_min = 1.0
	_particles.scale_amount_max = 2.0
	_particles.color = Color(0.85, 0.95, 1.0, 0.35)
	_particles.z_index = 0
	add_child(_particles)

func _physics_process(_delta: float) -> void:
	if _player != null and is_instance_valid(_player):
		_player.water_push = push

func _on_enter(body: Node2D) -> void:
	if body is Player:
		_player = body as Player

func _on_exit(body: Node2D) -> void:
	if body == _player:
		_player.water_push = Vector2.ZERO
		_player = null
