extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var total := ScoreManager.add_coin()
	if total % 10 == 0:
		(body as Player).heal(1)
	queue_free()
