extends Control

## Per wereld de pixelposities van de clearings op de bijbehorende
## assets/sprites/backgrounds/worldmap/world<N>.png-achtergrond, afgelezen
## tijdens Fase 4c (zie docs/Claude-worldmap-coords-prompt.md). Aantal punten
## moet overeenkomen met WorldConfig.WORLDS[world-1]["levels"].
const LEVEL_POSITIONS: Dictionary = {
	1: [
		Vector2(166, 288), Vector2(283, 248), Vector2(410, 255), Vector2(511, 302),
		Vector2(604, 368), Vector2(691, 438), Vector2(815, 499), Vector2(928, 488),
		Vector2(1038, 431), Vector2(1141, 373),
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

const DOT_SIZE := 46.0

const DOT_DONE   := Color(0.25, 0.75, 0.3, 0.9)
const DOT_OPEN   := Color(0.95, 0.8, 0.15, 0.9)
const DOT_LOCKED := Color(0.25, 0.25, 0.25, 0.75)
const DOT_FOCUS  := Color(1.0, 1.0, 1.0, 0.95)

const DOT_BORDER_DONE   := Color(0.1, 0.4, 0.15, 1.0)
const DOT_BORDER_OPEN   := Color(0.5, 0.35, 0.05, 1.0)
const DOT_BORDER_LOCKED := Color(0.05, 0.05, 0.05, 1.0)
const DOT_BORDER_FOCUS  := Color(1.0, 0.85, 0.3, 1.0)

@onready var _title:    Label   = $VBox/TitleLabel
@onready var _back_btn: Button  = $VBox/BackButton
@onready var _map_area: Control = $MapArea

var _world: int = 1
var _buttons: Array[Button] = []
var _nav: Array[Control] = []   # focus-volgorde: speelbare bolletjes + de Terug-knop

func _ready() -> void:
	_world = GameManager.current_world
	_title.text = "Wereld %d — %s" % [_world, _world_name(_world)]
	_back_btn.pressed.connect(GameManager.go_to_world_select)
	_add_background(_world)
	_build_map(_world)
	AudioManager.play_music_by_name("menu")
	# Beginfocus op het eerste speelbare bolletje (of de Terug-knop als er nog
	# geen speelbaar level is) zodat de gamepad meteen kan navigeren.
	if not _nav.is_empty():
		_nav[0].grab_focus.call_deferred()

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
		# Speelbaar = open OF al voltooid (voltooide levels mag je herspelen).
		var navigable := exists and (completed or unlocked)

		var btn := _make_dot_button(level)
		btn.position = pos - Vector2(DOT_SIZE, DOT_SIZE) / 2.0
		btn.disabled = not navigable
		btn.focus_mode = Control.FOCUS_ALL if navigable else Control.FOCUS_NONE

		if completed:
			_style_dot(btn, DOT_DONE, DOT_BORDER_DONE)
		elif unlocked:
			_style_dot(btn, DOT_OPEN, DOT_BORDER_OPEN)
		else:
			_style_dot(btn, DOT_LOCKED, DOT_BORDER_LOCKED)

		if navigable:
			btn.pressed.connect(_on_level_pressed.bind(world, level))
			# Bolletje oplichten als de focus (gamepad/muis) erop staat, en terug
			# naar de basiskleur zodra de focus weg is.
			btn.focus_entered.connect(_on_dot_focus.bind(btn))
			btn.focus_exited.connect(_on_dot_unfocus.bind(btn, level))
			_nav.append(btn)
		_buttons.append(btn)
		_map_area.add_child(btn)

	# De Terug-knop hoort ook bij de controller-navigatie.
	_nav.append(_back_btn)
	_wire_focus_chain()

## Zet de focus-buren zo dat één druk op links/rechts (of omhoog/omlaag) precies
## één stap zet — langs de speelbare bolletjes en de Terug-knop, met wrap-around.
## Zonder expliciete buren deden Godot's geometrische focus-navigatie én de oude
## kaart-eigen navigatie allebei mee, waardoor één druk soms 2-3 bolletjes
## versprong.
func _wire_focus_chain() -> void:
	var n := _nav.size()
	if n == 0:
		return
	for i in range(n):
		var here: Control = _nav[i]
		var prev: Control = _nav[(i - 1 + n) % n]
		var next: Control = _nav[(i + 1) % n]
		here.focus_neighbor_left   = here.get_path_to(prev)
		here.focus_neighbor_top    = here.get_path_to(prev)
		here.focus_neighbor_right  = here.get_path_to(next)
		here.focus_neighbor_bottom = here.get_path_to(next)
		here.focus_next            = here.get_path_to(next)
		here.focus_previous        = here.get_path_to(prev)

func _on_dot_focus(btn: Button) -> void:
	_style_dot(btn, DOT_FOCUS, DOT_BORDER_FOCUS)

func _on_dot_unfocus(btn: Button, level: int) -> void:
	if GameManager.is_level_completed(_world, level):
		_style_dot(btn, DOT_DONE, DOT_BORDER_DONE)
	else:
		_style_dot(btn, DOT_OPEN, DOT_BORDER_OPEN)

## Bouwt een ronde level-marker (i.p.v. het standaard vierkante Button-uiterlijk)
## via een StyleBoxFlat met corner_radius = straal, zodat hij als een cirkel
## op de clearing van de wereldkaart-achtergrond past.
func _make_dot_button(level: int) -> Button:
	var btn := Button.new()
	btn.text = str(level)
	btn.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.85, 0.85, 0.85))
	btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)
	return btn

func _style_dot(btn: Button, fill: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(DOT_SIZE / 2.0))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, style)

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
