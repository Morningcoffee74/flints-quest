extends CanvasLayer

func _ready() -> void:
	$Panel/VBox/RetryButton.pressed.connect(_on_retry)
	$Panel/VBox/MapButton.pressed.connect(_on_map)

func _on_retry() -> void:
	# Volledige nieuwe poging: reset levens en checkpoint, en heft de pauze op.
	GameManager.go_to_level(GameManager.current_world, GameManager.current_level)

func _on_map() -> void:
	GameManager.go_to_world_map()
