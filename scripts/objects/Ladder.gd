extends Area2D

## Hoogte in pixels; de node-positie is de BOVENKANT van de ladder.
@export var height: int = 160

const WIDTH := 28.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visual()

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, height)
	shape.shape = rect
	shape.position = Vector2(0, height / 2.0)
	add_child(shape)

func _build_visual() -> void:
	var rail_color := Color(0.5, 0.35, 0.18, 1.0)
	var rung_color := Color(0.62, 0.45, 0.24, 1.0)
	for side: float in [-1.0, 1.0]:
		var rail := Polygon2D.new()
		var x := side * (WIDTH / 2.0 - 3.0)
		rail.polygon = PackedVector2Array([
			Vector2(x - 3, 0), Vector2(x + 3, 0),
			Vector2(x + 3, height), Vector2(x - 3, height),
		])
		rail.color = rail_color
		add_child(rail)
	var rungs := int(height / 24.0)
	for i in rungs:
		var y := 12.0 + i * 24.0
		var rung := Polygon2D.new()
		rung.polygon = PackedVector2Array([
			Vector2(-WIDTH / 2.0, y - 2), Vector2(WIDTH / 2.0, y - 2),
			Vector2(WIDTH / 2.0, y + 2), Vector2(-WIDTH / 2.0, y + 2),
		])
		rung.color = rung_color
		add_child(rung)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).enter_ladder()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player).exit_ladder()
