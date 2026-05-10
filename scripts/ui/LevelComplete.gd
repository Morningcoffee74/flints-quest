extends CanvasLayer

func _ready() -> void:
	var bd := ScoreManager.get_level_breakdown()
	$Panel/VBox/PlayLabel.text      = "Gameplay:       %d" % bd["play"]
	$Panel/VBox/CompleteLabel.text  = "Level voltooid: +%d" % bd["complete_bonus"]
	var no_dmg: int = bd["no_damage_bonus"]
	$Panel/VBox/NoDmgLabel.text     = "Geen schade:    +%d" % no_dmg
	$Panel/VBox/TotalLabel.text     = "Totaal:         %d" % bd["total"]

	var world := GameManager.current_world
	var level := GameManager.current_level
	var has_next := level < 10 and FileAccess.file_exists(
		"res://scenes/levels/world%d/W%dL%d.tscn" % [world, world, level + 1]
	)
	$Panel/VBox/NextButton.visible = has_next
	$Panel/VBox/NextButton.pressed.connect(_on_next)
	$Panel/VBox/MapButton.pressed.connect(_on_map)

func _on_next() -> void:
	GameManager.go_to_level(GameManager.current_world, GameManager.current_level + 1)

func _on_map() -> void:
	GameManager.go_to_world_map()
