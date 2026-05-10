extends Control

const LEVEL_POSITIONS: Array[Vector2] = [
	Vector2(120, 560),   # 1
	Vector2(250, 530),   # 2
	Vector2(380, 490),   # 3
	Vector2(490, 430),   # 4
	Vector2(570, 350),   # 5
	Vector2(650, 270),   # 6
	Vector2(760, 220),   # 7
	Vector2(890, 240),   # 8
	Vector2(1020, 290),  # 9
	Vector2(1140, 330),  # 10
]

const DOT_DONE   := Color(0.2, 0.8, 0.2)
const DOT_OPEN   := Color(0.9, 0.8, 0.1)
const DOT_LOCKED := Color(0.4, 0.4, 0.4)
const DOT_FOCUS  := Color(1.0, 1.0, 1.0)

@onready var _title:    Label   = $VBox/TitleLabel
@onready var _back_btn: Button  = $VBox/BackButton
@onready var _map_area: Control = $MapArea

var _world: int = 1
var _buttons: Array[Button] = []
var _playable: Array[int]   = []   # level-nummers die echt gespeeld kunnen worden
var _focus_idx: int = 0            # index in _playable

func _ready() -> void:
	_world = GameManager.current_world
	_title.text = "Wereld %d — %s" % [_world, _world_name(_world)]
	_back_btn.pressed.connect(GameManager.go_to_main_menu)
	_build_map(_world)
	if not _playable.is_empty():
		_set_focus(0)

func _build_map(world: int) -> void:
	var lines := _LineDrawer.new(LEVEL_POSITIONS)
	_map_area.add_child(lines)

	for i in range(10):
		var level   := i + 1
		var pos     := LEVEL_POSITIONS[i]
		var exists    := _scene_exists(world, level)
		var completed := GameManager.is_level_completed(world, level)
		var unlocked  := exists and GameManager.is_level_unlocked(world, level)

		var btn := Button.new()
		btn.text = str(level)
		btn.custom_minimum_size = Vector2(44, 44)
		btn.position = pos - Vector2(22, 22)
		btn.disabled = not unlocked

		if completed:
			btn.modulate = DOT_DONE
		elif unlocked:
			btn.modulate = DOT_OPEN
			_playable.append(i)
		else:
			btn.modulate = DOT_LOCKED

		if unlocked:
			btn.pressed.connect(_on_level_pressed.bind(world, level))
		_buttons.append(btn)
		_map_area.add_child(btn)

	# Voltooide levels zijn ook herbespeelbaar → voeg ze toe achteraan _playable
	for i in range(10):
		var level := i + 1
		if GameManager.is_level_completed(_world, level) and _scene_exists(_world, level):
			_playable.append(i)

func _unhandled_input(event: InputEvent) -> void:
	if _playable.is_empty():
		return
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
		_set_focus((_focus_idx - 1 + _playable.size()) % _playable.size())
		accept_event()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
		_set_focus((_focus_idx + 1) % _playable.size())
		accept_event()
	elif event.is_action_pressed("jump") or event.is_action_pressed("punch"):
		var level := _playable[_focus_idx] + 1
		_on_level_pressed(_world, level)
		accept_event()

func _set_focus(idx: int) -> void:
	# Reset vorige focus-kleur
	if not _playable.is_empty():
		var old_i := _playable[_focus_idx]
		var old_level := old_i + 1
		if GameManager.is_level_completed(_world, old_level):
			_buttons[old_i].modulate = DOT_DONE
		else:
			_buttons[old_i].modulate = DOT_OPEN

	_focus_idx = idx
	var new_i := _playable[idx]
	_buttons[new_i].modulate = DOT_FOCUS
	_buttons[new_i].grab_focus()

func _on_level_pressed(world: int, level: int) -> void:
	GameManager.go_to_level(world, level)

func _scene_exists(world: int, level: int) -> bool:
	return FileAccess.file_exists(
		"res://scenes/levels/world%d/W%dL%d.tscn" % [world, world, level]
	)

func _world_name(world: int) -> String:
	var names := ["Bos", "Water", "Grot", "Jungle", "Lucht",
				  "Strand", "IJsberg", "Woestijn", "Snoep", "Vulkaan"]
	return names[world - 1] if world >= 1 and world <= 10 else ""

class _LineDrawer extends Node2D:
	var _positions: Array[Vector2]

	func _init(positions: Array[Vector2]) -> void:
		_positions = positions

	func _draw() -> void:
		for i in range(_positions.size() - 1):
			draw_line(_positions[i], _positions[i + 1], Color(0.6, 0.5, 0.3), 3.0)
