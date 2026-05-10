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
var _level_done:     bool = false
var _pause_menu: CanvasLayer = null

func _ready() -> void:
	ScoreManager.reset_level()

	_camera.limit_left   = 0
	_camera.limit_right  = level_width
	_camera.limit_top    = -200
	_camera.limit_bottom = level_height + 100

	hud.connect_player(player)
	player.died.connect(_on_player_died)

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
	_setup_pause_menu()

func _setup_pause_menu() -> void:
	var packed: PackedScene = load("res://scenes/ui/PauseMenu.tscn")
	if packed == null:
		push_error("LevelBase: kon PauseMenu.tscn niet laden")
		return
	_pause_menu = packed.instantiate() as CanvasLayer
	if _pause_menu == null:
		push_error("LevelBase: PauseMenu.tscn is geen CanvasLayer")
		return
	_pause_menu.hide()
	add_child(_pause_menu)

func _input(event: InputEvent) -> void:
	if _level_done or _pause_menu == null:
		return
	if event.is_action_pressed("pause") and not (event is InputEventKey and event.echo):
		get_viewport().set_input_as_handled()
		if _pause_menu.visible:
			_pause_menu.hide()
			get_tree().paused = false
		else:
			_pause_menu.show()
			get_tree().paused = true

func _update_cabin() -> void:
	if _cabin_open:
		return

	var no_requirement := coins_needed_pct == 0 and enemies_needed == 0

	var coins_met := coins_needed_pct > 0 and \
		(_total_coins == 0 or _coins_got * 100 / _total_coins >= coins_needed_pct)

	var enemies_met := enemies_needed > 0 and _enemies_killed >= enemies_needed

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
	_level_done = true
	await get_tree().create_timer(0.8).timeout
	var packed: PackedScene = load("res://scenes/ui/GameOver.tscn")
	if packed:
		add_child(packed.instantiate())

func _on_level_completed() -> void:
	if not _cabin_open or _level_done:
		return
	_level_done = true
	var final_score := ScoreManager.finalize_level()
	GameManager.complete_level(GameManager.current_world, GameManager.current_level, final_score)
	await get_tree().create_timer(0.4).timeout
	var packed: PackedScene = load("res://scenes/ui/LevelComplete.tscn")
	if packed:
		add_child(packed.instantiate())
