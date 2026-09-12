extends Area2D

## Zeemijn (Wereld 2): vaste hindernis in het water. Aanraken kost een hartje
## en laat de mijn ontploffen (knal + deeltjes); na `respawn_time` seconden
## drijft er weer een nieuwe op dezelfde plek. Kapotslaan kan niet — je moet
## eromheen zwemmen. Dobbert langzaam op en neer.

@export var bob_amplitude: float = 6.0
@export var bob_speed: float = 1.6
@export var respawn_time: float = 4.0

var _base_y := 0.0
var _t := 0.0
var _armed := true

@onready var _sprite: Sprite2D = $Sprite
@onready var _shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_base_y = position.y
	_t = randf() * TAU
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta * bob_speed
	position.y = _base_y + sin(_t) * bob_amplitude

func _physics_process(_delta: float) -> void:
	if not _armed:
		return
	for body in get_overlapping_bodies():
		if body is Player:
			_explode(body as Player)
			return

func _on_body_entered(body: Node2D) -> void:
	if _armed and body is Player:
		_explode(body as Player)

func _explode(player: Player) -> void:
	_armed = false
	player.take_damage()
	AudioManager.play_sfx_by_name("explosion")
	_sprite.visible = false
	_shape.set_deferred("disabled", true)

	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.emitting = true
	burst.amount = 28
	burst.lifetime = 0.6
	burst.explosiveness = 1.0
	burst.spread = 180.0
	burst.direction = Vector2.UP
	burst.initial_velocity_min = 90.0
	burst.initial_velocity_max = 220.0
	burst.gravity = Vector2(0.0, -40.0)
	burst.scale_amount_min = 3.0
	burst.scale_amount_max = 6.0
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([Color(1.0, 0.95, 0.6, 1.0), Color(1.0, 0.5, 0.15, 1.0), Color(0.3, 0.3, 0.3, 0.0)])
	burst.color_ramp = grad
	add_child(burst)
	get_tree().create_timer(0.8).timeout.connect(burst.queue_free)

	# Schokgolf-ring.
	var ring := Polygon2D.new()
	ring.color = Color(1.0, 1.0, 1.0, 0.6)
	var pts := PackedVector2Array()
	for i in 24:
		pts.append(Vector2.from_angle(i * TAU / 24.0) * 10.0)
	ring.polygon = pts
	add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector2(6.0, 6.0), 0.35)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	tween.tween_callback(ring.queue_free)

	await get_tree().create_timer(respawn_time).timeout
	if not is_inside_tree():
		return
	_sprite.visible = true
	_sprite.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(_sprite, "modulate:a", 1.0, 0.5)
	_shape.set_deferred("disabled", false)
	_armed = true
