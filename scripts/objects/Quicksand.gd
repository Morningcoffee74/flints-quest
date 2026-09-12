class_name Quicksand
extends Area2D

## Drijfzand voor Wereld 4. Plaats dit over een kuil in de grond en zet `size`
## (breedte × hoogte in px; de node-positie is het MIDDEN van de zone).
##
## In het zand loop je half zo snel, zak je langzaam weg en spring je minder
## hoog — maar springen kán, ook zonder vaste grond onder je voeten, dus je kunt
## je er altijd uit worstelen. Blijf je staan, dan zak je kopje-onder en dat
## kost een hartje + een respawn bij het checkpoint, precies zoals in een
## ravijn vallen (LevelBase.hazard_respawn).
##
## Het uiterlijk wordt hier opgebouwd, net als bij Water.gd: een korrelig
## zandvlak met een paar tragere "bellen" die naar boven borrelen.

@export var size: Vector2 = Vector2(160.0, 140.0):
	set(v):
		size = v
		if is_inside_tree():
			_build()

## Hoe diep de speler moet wegzakken voordat hij verdrinkt, gemeten vanaf de
## ONDERKANT van de zone. Zijn positie ligt bij zijn voeten, dus dit is krap:
## pas als hij echt op de bodem van de kuil zit is het mis.
@export var drown_margin: float = 10.0

var _built: Array[Node] = []
var _player_inside := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build()

func _build() -> void:
	for n in _built:
		n.queue_free()
	_built.clear()

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# Elke zone een EIGEN shape: gedeelde RectangleShape2D's lieten meerdere
	# vijvers in Wereld 2 dezelfde maat aannemen.
	rect.size = size
	shape.shape = rect
	add_child(shape)
	_built.append(shape)

	var body := Polygon2D.new()
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	body.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	body.color = Color(0.44, 0.36, 0.18, 0.92)
	body.z_index = 3
	add_child(body)
	_built.append(body)

	# Lichtere bovenrand zodat de zandput duidelijk afsteekt tegen de grond.
	var lip := Polygon2D.new()
	lip.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, -hh + 7.0), Vector2(-hw, -hh + 7.0)])
	lip.color = Color(0.62, 0.52, 0.27, 0.95)
	lip.z_index = 4
	add_child(lip)
	_built.append(lip)

	var bubbles := CPUParticles2D.new()
	bubbles.amount = maxi(6, int(size.x / 26.0))
	bubbles.lifetime = 3.2
	bubbles.position = Vector2(0.0, hh * 0.4)
	bubbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	bubbles.emission_rect_extents = Vector2(hw * 0.9, hh * 0.4)
	bubbles.direction = Vector2.UP
	bubbles.spread = 12.0
	bubbles.gravity = Vector2.ZERO
	bubbles.initial_velocity_min = 5.0
	bubbles.initial_velocity_max = 13.0
	bubbles.scale_amount_min = 2.0
	bubbles.scale_amount_max = 4.0
	bubbles.color = Color(0.58, 0.49, 0.26, 0.8)
	bubbles.z_index = 4
	add_child(bubbles)
	_built.append(bubbles)

func _physics_process(_delta: float) -> void:
	if not _player_inside:
		return
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return
	var player := nodes[0] as Player
	if player == null or player.state == Player.State.DEAD:
		return
	if player.global_position.y >= global_position.y + size.y / 2.0 - drown_margin:
		_drown(player)

func _drown(player: Player) -> void:
	player.exit_quicksand()
	_player_inside = false
	var level := _find_level()
	if level != null:
		level.hazard_respawn()
	else:
		player.take_damage()

func _find_level() -> LevelBase:
	var n := get_parent()
	while n != null:
		if n is LevelBase:
			return n as LevelBase
		n = n.get_parent()
	return null

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player != null:
		_player_inside = true
		player.enter_quicksand()

func _on_body_exited(body: Node2D) -> void:
	var player := body as Player
	if player != null:
		_player_inside = false
		player.exit_quicksand()
