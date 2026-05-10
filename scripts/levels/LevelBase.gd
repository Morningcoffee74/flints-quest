class_name LevelBase
extends Node2D

@export var level_width:  int = 4000
@export var level_height: int = 720

## Unlock cabin als dit percentage muntjes verzameld is (0 = geen eis)
@export var coins_needed_pct: int = 0
## Unlock cabin als dit aantal vijanden verslagen is (0 = geen eis)
@export var enemies_needed: int = 0

@onready var player: Player    = $Player
@onready var hud               = $HUD
@onready var _camera: Camera2D = $Player/Camera2D

var _total_coins:    int  = 0
var _coins_got:      int  = 0
var _enemies_killed: int  = 0
var _cabin_open:     bool = false

func _ready() -> void:
	ScoreManager.reset_level()

	_camera.limit_left   = 0
	_camera.limit_right  = level_width
	_camera.limit_top    = -200
	_camera.limit_bottom = level_height + 100

	hud.connect_player(player)
	player.died.connect(_on_player_died)

	# Muntjes en vijanden tellen
	_total_coins = get_tree().get_nodes_in_group("coins").size()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		(enemy as BaseEnemy).died.connect(_on_enemy_killed)
	ScoreManager.coin_collected.connect(func(total: int) -> void:
		_coins_got = total
		_update_cabin()
	)

	if has_node("Cabin"):
		($Cabin as Area2D).level_completed.connect(_on_level_completed)

	_update_cabin()

func _update_cabin() -> void:
	if _cabin_open:
		return

	var no_requirement := coins_needed_pct == 0 and enemies_needed == 0

	var coins_met := coins_needed_pct > 0 and \
		(_total_coins == 0 or _coins_got * 100 / _total_coins >= coins_needed_pct)

	var enemies_met := enemies_needed > 0 and _enemies_killed >= enemies_needed

	# Geen eis → altijd open; anders: OF-conditie (muntjes OF vijanden)
	var should_open := no_requirement or coins_met or enemies_met

	if should_open and not _cabin_open:
		_cabin_open = true
		if has_node("Cabin"):
			($Cabin as Area2D).modulate = Color.WHITE
	elif not should_open and has_node("Cabin"):
		($Cabin as Area2D).modulate = Color(0.45, 0.45, 0.45, 1.0)

func _on_enemy_killed() -> void:
	_enemies_killed += 1
	_update_cabin()

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	get_tree().reload_current_scene()

func _on_level_completed() -> void:
	if not _cabin_open:
		return  # Eis nog niet gehaald — niets doen
	ScoreManager.finalize_level()
	# TODO Fase 3: toon LevelComplete scherm
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()
