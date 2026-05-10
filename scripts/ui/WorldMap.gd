extends Control

# Level-posities op de kaart (Mario-stijl pad omhoog en naar rechts)
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

const DOT_DONE    := Color(0.2, 0.8, 0.2)
const DOT_OPEN    := Color(0.9, 0.8, 0.1)
const DOT_LOCKED  := Color(0.4, 0.4, 0.4)

@onready var _title:    Label  = $VBox/TitleLabel
@onready var _back_btn: Button = $VBox/BackButton
@onready var _map_area: Control = $MapArea

func _ready() -> void:
	var world := GameManager.current_world
	_title.text = "Wereld %d — %s" % [world, _world_name(world)]
	_back_btn.pressed.connect(GameManager.go_to_main_menu)
	_build_map(world)

func _build_map(world: int) -> void:
	# Verbindingslijnen tekenen via een custom node
	var lines := _LineDrawer.new(LEVEL_POSITIONS)
	_map_area.add_child(lines)

	for i in range(10):
		var level := i + 1
		var pos := LEVEL_POSITIONS[i]
		var completed := GameManager.is_level_completed(world, level)
		var unlocked  := GameManager.is_level_unlocked(world, level)

		var btn := Button.new()
		btn.text = str(level)
		btn.custom_minimum_size = Vector2(44, 44)
		btn.position = pos - Vector2(22, 22)
		btn.disabled = not unlocked

		# Kleur via modulate
		if completed:
			btn.modulate = DOT_DONE
		elif unlocked:
			btn.modulate = DOT_OPEN
		else:
			btn.modulate = DOT_LOCKED

		if unlocked:
			btn.pressed.connect(_on_level_pressed.bind(world, level))
		_map_area.add_child(btn)

func _on_level_pressed(world: int, level: int) -> void:
	GameManager.go_to_level(world, level)

func _world_name(world: int) -> String:
	var names := ["Bos", "Water", "Grot", "Jungle", "Lucht",
				  "Strand", "IJsberg", "Woestijn", "Snoep", "Vulkaan"]
	return names[world - 1] if world >= 1 and world <= 10 else ""

# Interne klasse om verbindingslijnen te tekenen
class _LineDrawer extends Node2D:
	var _positions: Array[Vector2]

	func _init(positions: Array[Vector2]) -> void:
		_positions = positions

	func _draw() -> void:
		for i in range(_positions.size() - 1):
			draw_line(_positions[i], _positions[i + 1], Color(0.6, 0.5, 0.3), 3.0)
