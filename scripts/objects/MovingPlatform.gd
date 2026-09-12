class_name MovingPlatform
extends AnimatableBody2D

## Bewegend houten platform: pendelt van zijn startpositie naar `offset` en
## terug (heen en weer, cosinus-verloop zodat het bij de keerpunten vertraagt).
## Zet `sync_to_physics` aan (staat in de scene) zodat de speler meebeweegt.

@export var offset: Vector2 = Vector2(256.0, 0.0)
@export var period: float = 4.0        # seconden voor heen én terug
@export var width: int = 96            # breedte in px (veelvoud van 32)

const PLANK_TEX := preload("res://assets/sprites/items/platform_long.png")

var _origin := Vector2.ZERO
var _t := 0.0

func _ready() -> void:
	_origin = position
	_build_visual()
	var shape := $Collision as CollisionShape2D
	(shape.shape as RectangleShape2D).size = Vector2(width, 20.0)

func _build_visual() -> void:
	# platform-long.png is 32×16 (Sunny Land, CC0); op schaal 2 = 64×32 per plank.
	var n := maxi(1, int(ceil(width / 64.0)))
	for i in n:
		var s := Sprite2D.new()
		s.texture = PLANK_TEX
		s.scale = Vector2(2.0, 2.0)
		s.position = Vector2(-width / 2.0 + 32.0 + i * 64.0, 0.0)
		# Laatste plank kan uitsteken: bijsnijden via regio.
		var overflow := (i + 1) * 64.0 - width
		if overflow > 0.0:
			s.region_enabled = true
			s.region_rect = Rect2(0, 0, 32.0 - overflow / 2.0, 16)
			s.position.x -= overflow / 2.0
		add_child(s)

func _physics_process(delta: float) -> void:
	_t += delta
	var phase := (1.0 - cos(_t * TAU / period)) * 0.5   # 0 → 1 → 0
	position = _origin + offset * phase
