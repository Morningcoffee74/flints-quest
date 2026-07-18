extends Control

## Per wereld de pixelposities van de clearings op de bijbehorende
## assets/sprites/backgrounds/worldmap/world<N>.png-achtergrond, afgelezen
## tijdens Fase 4c (zie docs/Claude-worldmap-coords-prompt.md). Aantal punten
## moet overeenkomen met WorldConfig.WORLDS[world-1]["levels"].
const LEVEL_POSITIONS: Dictionary = {
	1: [
		Vector2(120, 560), Vector2(250, 530), Vector2(380, 490), Vector2(490, 430),
		Vector2(570, 350), Vector2(650, 270), Vector2(760, 220), Vector2(890, 240),
		Vector2(1020, 290), Vector2(1140, 330),
	],
	2: [
		Vector2(161, 293), Vector2(267, 293), Vector2(380, 311), Vector2(490, 356),
		Vector2(589, 415), Vector2(692, 480), Vector2(797, 530), Vector2(914, 514),
		Vector2(1036, 469), Vector2(1133, 410), Vector2(1208, 319),
	],
	3: [
		Vector2(70, 473), Vector2(127, 323), Vector2(253, 293), Vector2(366, 289),
		Vector2(488, 361), Vector2(591, 431), Vector2(703, 473), Vector2(811, 506),
		Vector2(938, 431), Vector2(1050, 352), Vector2(1177, 291),
	],
	4: [
		Vector2(136, 619), Vector2(150, 234), Vector2(267, 248), Vector2(384, 270),
		Vector2(497, 300), Vector2(591, 375), Vector2(689, 445), Vector2(792, 488),
		Vector2(914, 403), Vector2(1031, 319), Vector2(1139, 164),
	],
	5: [
		Vector2(153, 180), Vector2(265, 211), Vector2(382, 242), Vector2(495, 300),
		Vector2(598, 368), Vector2(701, 427), Vector2(808, 476), Vector2(923, 450),
		Vector2(1031, 401), Vector2(1144, 354),
	],
	6: [
		Vector2(153, 314), Vector2(258, 305), Vector2(361, 314), Vector2(459, 370),
		Vector2(563, 427), Vector2(670, 473), Vector2(773, 427), Vector2(881, 389),
		Vector2(989, 384), Vector2(1092, 405),
	],
	7: [
		Vector2(167, 352), Vector2(267, 308), Vector2(389, 319), Vector2(499, 345),
		Vector2(608, 397), Vector2(701, 450), Vector2(804, 485), Vector2(923, 480),
		Vector2(1044, 443), Vector2(1167, 398), Vector2(1058, 258),
	],
	8: [
		Vector2(136, 218), Vector2(274, 227), Vector2(396, 251), Vector2(520, 300),
		Vector2(609, 378), Vector2(677, 458), Vector2(792, 504), Vector2(917, 494),
		Vector2(1029, 436), Vector2(1144, 391),
	],
	9: [
		Vector2(94, 309), Vector2(167, 401), Vector2(267, 272), Vector2(281, 464),
		Vector2(384, 281), Vector2(492, 319), Vector2(591, 375), Vector2(680, 441),
		Vector2(792, 481), Vector2(914, 481), Vector2(1027, 429), Vector2(1116, 366),
	],
	10: [
		Vector2(127, 520), Vector2(218, 384), Vector2(326, 295), Vector2(433, 267),
		Vector2(511, 319), Vector2(609, 384), Vector2(701, 450), Vector2(804, 485),
		Vector2(923, 431), Vector2(1039, 370), Vector2(1167, 211),
	],
}

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
	_back_btn.pressed.connect(GameManager.go_to_world_select)
	_add_background(_world)
	_build_map(_world)
	if not _playable.is_empty():
		_set_focus(0)

## Toont assets/sprites/backgrounds/worldmap/world<N>.png als kaartachtergrond
## indien aanwezig (zie docs/worldmap-achtergrond-prompt.md).
func _add_background(world: int) -> void:
	var path := "res://assets/sprites/backgrounds/worldmap/world%d.png" % world
	if not ResourceLoader.exists(path, "Texture2D"):
		return
	# De statische "Background" ColorRect (val-terug-kleur voor als er geen
	# afbeelding is) zit boven op de kaart-achtergrond in de scene-boom en
	# is ondoorzichtig — die moet weg zodra we een echte afbeelding tonen,
	# anders overdekt hij hem volledig.
	if has_node("Background"):
		($Background as ColorRect).visible = false
	var bg := TextureRect.new()
	bg.texture = load(path)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	move_child(bg, 0)

func _build_map(world: int) -> void:
	var positions: Array = LEVEL_POSITIONS.get(world, [])
	var lines := _LineDrawer.new(positions)
	_map_area.add_child(lines)

	var level_count: int = WorldConfig.WORLDS[world - 1]["levels"]
	for i in range(level_count):
		var level   := i + 1
		var pos: Vector2 = positions[i]
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
	for i in range(level_count):
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
	var _positions: Array

	func _init(positions: Array) -> void:
		_positions = positions

	func _draw() -> void:
		for i in range(_positions.size() - 1):
			draw_line(_positions[i], _positions[i + 1], Color(0.6, 0.5, 0.3), 3.0)
