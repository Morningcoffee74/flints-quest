class_name Water
extends Area2D

## Waterzone voor Wereld 2. Plaats dit object over het natte deel van een level
## en schaal de CollisionShape2D (en het blauwe Polygon2D) naar de gewenste
## grootte. Zodra de speler de zone binnenkomt schakelt hij naar de zwem-state
## (zie Player.enter_water/exit_water); bij het verlaten weer terug.

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body is Player:
		(body as Player).enter_water()

func _on_body_exited(body: Node) -> void:
	if body is Player:
		(body as Player).exit_water()
