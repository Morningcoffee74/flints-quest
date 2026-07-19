extends CanvasLayer

const HEART_FULL:  Texture2D = preload("res://assets/sprites/heart-full.png")
const HEART_EMPTY: Texture2D = preload("res://assets/sprites/heart-empty.png")
const ICON_HEART:  Texture2D = preload("res://assets/sprites/items/extra-life.png")
const ICON_SPEED:  Texture2D = preload("res://assets/sprites/items/extra-speed.png")
const ICON_STRONG: Texture2D = preload("res://assets/sprites/items/extra-strong.png")

## Per power-up: icoon, tint en balkkleur.
const POWERUP_STYLE: Dictionary = {
	"star":   {"tint": Color(0.75, 0.4, 1.0), "bar": Color(0.75, 0.4, 1.0)},
	"speed":  {"tint": Color.WHITE,           "bar": Color(0.25, 0.65, 1.0)},
	"strong": {"tint": Color.WHITE,           "bar": Color(1.0, 0.55, 0.15)},
}

## Tekst-popup bij het oppakken van een power-up.
const POPUP_TEXT: Dictionary = {
	"star":   "ONKWETSBAAR!",
	"speed":  "SNELLER!",
	"strong": "HARDE KLAP!",
}

var _hearts: Array[TextureRect] = []
var _player: Player = null
var _powerup_rows: Dictionary = {}   # kind -> {row, bar}

var _boss_box: VBoxContainer = null
var _boss_bar: ProgressBar = null
var _boss_pct: Label = null

@onready var _score_label: Label = $Control/ScoreLabel
@onready var _coin_label:  Label = $Control/CoinLabel
@onready var _lives_label: Label = $Control/LivesLabel
@onready var _powerup_box: VBoxContainer = $Control/PowerupContainer
@onready var _world_level_label: Label = $Control/WorldLevelLabel
@onready var _cabin_progress_label: Label = $Control/CabinProgressLabel

func _ready() -> void:
	for child in $Control/HeartsContainer.get_children():
		if child is TextureRect:
			_hearts.append(child as TextureRect)
	ScoreManager.score_changed.connect(_on_score_changed)
	ScoreManager.coin_collected.connect(_on_coin_collected)
	set_lives(GameManager.lives)
	_build_powerup_rows()
	_world_level_label.text = "Wereld %d — Level %d" % [GameManager.current_world, GameManager.current_level]
	_cabin_progress_label.text = ""

func connect_player(player: Player) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed)
	player.powerup_activated.connect(_on_powerup_activated)
	_on_health_changed(player.health)

func _build_powerup_rows() -> void:
	for kind: String in POWERUP_STYLE:
		var style: Dictionary = POWERUP_STYLE[kind]
		var row := HBoxContainer.new()
		row.visible = false
		row.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		match kind:
			"strong": icon.texture = ICON_STRONG
			"speed":  icon.texture = ICON_SPEED
			_:        icon.texture = ICON_HEART
		icon.modulate = style["tint"]
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

		var bar := ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = 1.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(120, 14)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fill := StyleBoxFlat.new()
		fill.bg_color = style["bar"]
		bar.add_theme_stylebox_override("fill", fill)
		row.add_child(bar)

		_powerup_box.add_child(row)
		_powerup_rows[kind] = {"row": row, "bar": bar}

func _process(_delta: float) -> void:
	var active: Dictionary = {}
	if _player != null and is_instance_valid(_player):
		for p: Dictionary in _player.get_active_powerups():
			active[p["kind"]] = p
	for kind: String in _powerup_rows:
		var row: HBoxContainer = _powerup_rows[kind]["row"]
		if active.has(kind):
			row.visible = true
			var p: Dictionary = active[kind]
			(_powerup_rows[kind]["bar"] as ProgressBar).value = p["left"] / p["total"]
		else:
			row.visible = false

func set_lives(lives: int) -> void:
	_lives_label.text = "Levens: %d" % lives

## Live voortgang richting de cabin-eis, zodat de speler altijd ziet wat er nog
## moet gebeuren i.p.v. te concluderen dat het huisje kapot is. Toont aantallen
## (net als bij vijanden), geen percentages — die zeggen een speler niets over
## hoeveel munten er nog te vinden zijn.
func set_cabin_progress(coins_got: int, coins_needed: int, enemies_killed: int, enemies_needed: int, cabin_open: bool, boss_active: bool = false) -> void:
	if cabin_open:
		_cabin_progress_label.text = ""
		return
	# Een levende eindbaas is de enige eis die telt zolang die er staat.
	if boss_active:
		_cabin_progress_label.text = "Versla de eindbaas!"
		return
	if coins_needed <= 0 and enemies_needed <= 0:
		_cabin_progress_label.text = ""
		return
	var parts: Array[String] = []
	if coins_needed > 0:
		parts.append("Munten %d/%d" % [coins_got, coins_needed])
	if enemies_needed > 0:
		parts.append("Vijanden %d/%d" % [enemies_killed, enemies_needed])
	_cabin_progress_label.text = " · ".join(parts)

## Levensbalk voor de eindbaas, midden bovenin. Wordt lui opgebouwd en pas
## getoond zodra LevelBase een boss in het level vindt.
func _build_boss_bar() -> void:
	_boss_box = VBoxContainer.new()
	_boss_box.visible = false
	_boss_box.add_theme_constant_override("separation", 2)
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.offset_left = -230.0
	_boss_box.offset_right = 230.0
	_boss_box.offset_top = 16.0
	_boss_box.grow_horizontal = Control.GROW_DIRECTION_BOTH

	var title := Label.new()
	title.text = "EINDBAAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title.add_theme_constant_override("shadow_offset_y", 1)
	_boss_box.add_child(title)

	_boss_bar = ProgressBar.new()
	_boss_bar.min_value = 0.0
	_boss_bar.max_value = 1.0
	_boss_bar.value = 1.0
	_boss_bar.show_percentage = false
	_boss_bar.custom_minimum_size = Vector2(460, 22)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	bg.set_corner_radius_all(5)
	bg.set_border_width_all(2)
	bg.border_color = Color(0, 0, 0, 0.8)
	_boss_bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.2, 0.2)
	fill.set_corner_radius_all(5)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	_boss_box.add_child(_boss_bar)

	_boss_pct = Label.new()
	_boss_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_pct.add_theme_font_size_override("font_size", 14)
	_boss_pct.add_theme_color_override("font_color", Color.WHITE)
	_boss_pct.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_boss_pct.add_theme_constant_override("shadow_offset_y", 1)
	_boss_box.add_child(_boss_pct)

	$Control.add_child(_boss_box)

func show_boss_bar() -> void:
	if _boss_box == null:
		_build_boss_bar()
	_boss_box.visible = true

## Wordt aangeroepen door de boss (boss_health_changed) en initieel door
## LevelBase; toont resterend leven als balk plus "% verslagen".
func set_boss_health(current: int, max_health: int) -> void:
	if _boss_box == null:
		_build_boss_bar()
	_boss_box.visible = true
	var frac := 0.0 if max_health <= 0 else float(current) / float(max_health)
	_boss_bar.value = frac
	var defeated := int(round((1.0 - frac) * 100.0))
	_boss_pct.text = "%d%% verslagen" % defeated

func hide_boss_bar() -> void:
	if _boss_box != null:
		_boss_box.visible = false

## Korte instructie-popup (bv. hoe je de eindbaas verslaat) die na een paar
## seconden vervaagt.
func show_hint(text: String, duration: float = 6.0) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vp_size := get_viewport().get_visible_rect().size
	label.size = Vector2(640.0, 60.0)
	label.position = Vector2(vp_size.x / 2.0 - 320.0, 120.0)
	$Control.add_child(label)
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)

func _on_health_changed(new_health: int) -> void:
	for i in _hearts.size():
		_hearts[i].texture = HEART_FULL if i < new_health else HEART_EMPTY

func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Score: %d" % new_score

func _on_coin_collected(total_coins: int) -> void:
	_coin_label.text = "x%d" % (total_coins % 10)

## Korte grote tekst-popup bovenin het scherm bij het oppakken van een power-up.
func _on_powerup_activated(kind: String) -> void:
	var label := Label.new()
	label.text = POPUP_TEXT.get(kind, "")
	label.add_theme_font_size_override("font_size", 36)
	label.modulate = POWERUP_STYLE.get(kind, {}).get("bar", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var vp_size := get_viewport().get_visible_rect().size
	label.position = Vector2(vp_size.x / 2.0 - 150.0, 130.0)
	label.size = Vector2(300.0, 48.0)
	$Control.add_child(label)

	var duration := Player.POWERUP_DURATION
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30.0, duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	tween.tween_callback(label.queue_free)
