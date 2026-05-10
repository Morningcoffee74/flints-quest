extends Control

func _ready() -> void:
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game)
	$VBoxContainer/LoadGameButton.pressed.connect(_on_load_game)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ProfileSelect.tscn")

func _on_load_game() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ProfileSelect.tscn")
