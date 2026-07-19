extends Control

func _ready() -> void:
	$VBoxContainer/PlayButton.pressed.connect(_on_play)
	$VBoxContainer/HelpButton.pressed.connect(_on_help)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings)
	# Beginfocus zodat een gamepad meteen kan navigeren (D-pad/stick = kiezen,
	# A-knop = aanklikken) zonder dat er eerst met de muis geklikt hoeft te worden.
	$VBoxContainer/PlayButton.grab_focus.call_deferred()
	AudioManager.play_music_by_name("menu")

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ProfileSelect.tscn")

func _on_help() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Help.tscn")

func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/Settings.tscn")
