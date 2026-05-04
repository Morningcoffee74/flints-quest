extends Control

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	GameManager.current_profile = "Speler1"
	GameManager.current_world = 1
	GameManager.current_level = 1
	get_tree().change_scene_to_file("res://scenes/levels/world1/W1L1.tscn")
