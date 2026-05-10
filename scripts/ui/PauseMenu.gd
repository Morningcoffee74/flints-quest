extends CanvasLayer

func _ready() -> void:
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Panel/VBox/RestartButton.pressed.connect(_on_restart)
	$Panel/VBox/MapButton.pressed.connect(_on_map)

func _on_resume() -> void:
	hide()
	get_tree().paused = false

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_map() -> void:
	GameManager.go_to_world_map()
