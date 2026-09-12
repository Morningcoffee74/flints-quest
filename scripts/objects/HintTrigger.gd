extends Area2D

## Onzichtbare trigger: toont één keer een HUD-hint zodra de speler erdoorheen
## loopt (bv. "Een zwerm! Spring in het gat!"). De node-positie is het midden
## van een verticale strook van 32×`height` px.

@export var text: String = ""
@export var duration: float = 4.0
@export var height: float = 600.0

var _done := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32.0, height)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _done or not body is Player or text.is_empty():
		return
	_done = true
	var node: Node = self
	while node != null and not node is LevelBase:
		node = node.get_parent()
	if node != null:
		(node as LevelBase).hud.show_hint(text, duration)
