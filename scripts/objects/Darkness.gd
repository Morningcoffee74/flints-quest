extends Node2D

## Donker grot-level (Wereld 3): alles wordt gedimd via een CanvasModulate,
## de speler draagt een warm lichtschijnsel (PointLight2D) en checkpoints,
## power-ups en het huisje krijgen een eigen klein licht als bakens. De
## parallax-achtergrond zit in een eigen CanvasLayer en wordt apart gedimd.

@export var ambient: Color = Color(0.13, 0.12, 0.2, 1.0)
@export var player_radius: float = 300.0
@export var beacon_radius: float = 150.0

func _ready() -> void:
	var cm := CanvasModulate.new()
	cm.color = ambient
	add_child(cm)

	var tex := _radial_texture()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var light := _make_light(tex, player_radius, 1.4, Color(1.0, 0.9, 0.72))
		light.position = Vector2(0.0, -36.0)
		player.add_child(light)

	var level := get_parent()
	for cp in get_tree().get_nodes_in_group("checkpoints"):
		var l := _make_light(tex, beacon_radius, 1.0, Color(0.6, 1.0, 0.7))
		l.position = Vector2(0.0, -40.0)
		cp.add_child(l)
	for pu in get_tree().get_nodes_in_group("powerups"):
		var l := _make_light(tex, beacon_radius * 0.6, 0.9, Color(0.9, 0.8, 1.0))
		pu.add_child(l)
	if level.has_node("Cabin"):
		var l := _make_light(tex, beacon_radius * 1.6, 1.1, Color(1.0, 0.85, 0.6))
		l.position = Vector2(0.0, -60.0)
		level.get_node("Cabin").add_child(l)

	# Achtergrond dimmen (eigen CanvasLayer → buiten bereik van de CanvasModulate).
	# Elke wereld heeft zijn eigen achtergrond-scene (ParallaxBGCave,
	# ParallaxBGJungle, …), dus zoeken op type in plaats van op naam.
	var bg: Node = null
	for child in level.get_children():
		if child is ParallaxBackground:
			bg = child
			break
	if bg != null:
		for layer in bg.get_children():
			for spr in layer.get_children():
				if spr is CanvasItem:
					(spr as CanvasItem).modulate = Color(0.3, 0.28, 0.42, 1.0)

func _make_light(tex: Texture2D, radius: float, energy: float, color: Color) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = tex
	light.texture_scale = radius * 2.0 / 256.0
	light.energy = energy
	light.color = color
	light.shadow_enabled = false
	return light

func _radial_texture() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex
