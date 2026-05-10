class_name LevelBase
extends Node2D

@export var level_width:  int = 4000
@export var level_height: int = 720

@onready var player: Player    = $Player
@onready var hud               = $HUD
@onready var _camera: Camera2D = $Player/Camera2D

func _ready() -> void:
	_camera.limit_left   = 0
	_camera.limit_right  = level_width
	_camera.limit_top    = -200
	_camera.limit_bottom = level_height + 100
	hud.connect_player(player)
	player.died.connect(_on_player_died)

	if has_node("Cabin"):
		($Cabin as Area2D).level_completed.connect(_on_level_completed)

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	get_tree().reload_current_scene()

func _on_level_completed() -> void:
	ScoreManager.finalize_level()
	# TODO Fase 3: toon LevelComplete scherm met score
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()
