extends CanvasLayer

func _ready() -> void:
	$Panel/VBox/RetryButton.pressed.connect(_on_retry)
	$Panel/VBox/MapButton.pressed.connect(_on_map)

func _on_retry() -> void:
	get_tree().reload_current_scene()

func _on_map() -> void:
	GameManager.go_to_world_map()
