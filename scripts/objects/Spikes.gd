extends Area2D

## Breedte in pixels; spike-sprites worden naast elkaar herhaald over de breedte.
@export var width: int = 48
## Variant uit de spike-bibliotheek: small_wood, long_wood, small_metal, long_metal.
@export var variant: String = "small_wood"

# Laatste (volledig uitgeschoven) frame per variant.
const TEXTURES: Dictionary = {
	"small_wood":  "res://assets/sprites/items/spikes/small_wood/small_wood_spike_04.png",
	"long_wood":   "res://assets/sprites/items/spikes/long_wood/long_wood_spike_05.png",
	"small_metal": "res://assets/sprites/items/spikes/small_metal/small_metal_spike_03.png",
	"long_metal":  "res://assets/sprites/items/spikes/long_metal/long_metal_spike_04.png",
}

## Zichtbare hoogte in px per variant (sprites worden hiernaar geschaald).
const TARGET_H: Dictionary = {
	"small_wood": 40.0, "long_wood": 64.0,
	"small_metal": 32.0, "long_metal": 56.0,
}

func _ready() -> void:
	var tex: Texture2D = load(TEXTURES.get(variant, TEXTURES["small_wood"]))
	var target_h: float = TARGET_H.get(variant, 40.0)
	var s := target_h / tex.get_height()
	var spike_w := tex.get_width() * s
	var count := maxi(1, roundi(width / spike_w))
	for i in count:
		var sprite := Sprite2D.new()
		sprite.texture = tex
		sprite.scale = Vector2(s, s)
		sprite.position = Vector2(
			-width / 2.0 + (i + 0.5) * width / count,
			-target_h / 2.0,
		)
		add_child(sprite)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, target_h * 0.6)
	shape.shape = rect
	shape.position = Vector2(0, -target_h * 0.3)
	add_child(shape)

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage()
