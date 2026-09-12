class_name Water
extends Area2D

## Waterzone voor Wereld 2. Plaats dit object over het natte deel van een level
## en zet `size` (breedte × hoogte in px; de node-positie is het MIDDEN van de
## zone). Zodra de speler de zone binnenkomt schakelt hij naar de zwem-state
## (zie Player.enter_water/exit_water); bij het verlaten weer terug.
##
## Het uiterlijk wordt hier opgebouwd: een geanimeerd wateroppervlak + lichte
## caustics via water.gdshader (achter de speler), een zwak blauw waas ervóór
## zodat alles in het water onder water lijkt, en wat opstijgende luchtbellen.

@export var size: Vector2 = Vector2(400.0, 300.0):
	set(v):
		size = v
		if is_inside_tree():
			_build()

const SHADER := preload("res://scripts/objects/water.gdshader")

## De speler telt pas als "in het water" wanneer zijn voeten zóveel px onder
## het wateroppervlak zijn. Zijn hitbox-oorsprong ligt bij de voeten en de
## capsule is 66px hoog: zonder deze marge ging hij al zwemmen zodra alleen
## zijn voeten nat waren, en dreef hij met zijn hele lijf bóven het water.
## 33px = het capsule-midden op de waterlijn. Het uiterlijk (shader, waas,
## bellen) gebruikt gewoon de volledige `size`.
@export var submerge: float = 33.0

var _built: Array[Node] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build()

func _build() -> void:
	for n in _built:
		n.queue_free()
	_built.clear()

	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null and shape_node.shape is RectangleShape2D:
		var sub: float = clampf(submerge, 0.0, maxf(0.0, size.y - 16.0))
		# Eigen kopie: de shape uit Water.tscn wordt anders gedeeld door alle
		# vijvers in een level en krijgt de maat van de laatst gebouwde.
		shape_node.shape = shape_node.shape.duplicate()
		(shape_node.shape as RectangleShape2D).size = Vector2(size.x, size.y - sub)
		shape_node.position = Vector2(0.0, sub / 2.0)

	# Achterste laag: het eigenlijke water (kleurverloop + oppervlak + caustics).
	var body := ColorRect.new()
	body.name = "BodyVisual"
	body.position = -size / 2.0
	body.size = size
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.z_index = -1
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("front", false)
	body.material = mat
	add_child(body)
	_built.append(body)

	# Voorste laag: zwak waas over speler/vijanden/munten in het water.
	var front := ColorRect.new()
	front.name = "FrontHaze"
	front.position = -size / 2.0
	front.size = size
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.z_index = 1
	var fmat := ShaderMaterial.new()
	fmat.shader = SHADER
	fmat.set_shader_parameter("front", true)
	front.material = fmat
	add_child(front)
	_built.append(front)

	# Luchtbellen die langzaam opstijgen.
	var bubbles := CPUParticles2D.new()
	bubbles.name = "Bubbles"
	bubbles.z_index = 0
	bubbles.amount = clampi(int(size.x / 40.0), 6, 40)
	bubbles.lifetime = 3.0
	bubbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	bubbles.emission_rect_extents = Vector2(size.x / 2.0 - 8.0, size.y / 2.0 - 8.0)
	bubbles.direction = Vector2.UP
	bubbles.spread = 10.0
	bubbles.gravity = Vector2(0.0, -25.0)
	bubbles.initial_velocity_min = 15.0
	bubbles.initial_velocity_max = 35.0
	bubbles.scale_amount_min = 1.5
	bubbles.scale_amount_max = 3.5
	bubbles.color = Color(0.85, 0.95, 1.0, 0.55)
	add_child(bubbles)
	_built.append(bubbles)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		(body as Player).enter_water()

func _on_body_exited(body: Node) -> void:
	if body is Player:
		(body as Player).exit_water()
