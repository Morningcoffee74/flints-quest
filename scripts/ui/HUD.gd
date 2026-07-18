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
## moet gebeuren i.p.v. te concluderen dat het huisje kapot is.
func set_cabin_progress(coins_got_pct: int, coins_needed_pct: int, enemies_killed: int, enemies_needed: int, cabin_open: bool) -> void:
	if cabin_open or (coins_needed_pct <= 0 and enemies_needed <= 0):
		_cabin_progress_label.text = ""
		return
	var parts: Array[String] = []
	if coins_needed_pct > 0:
		parts.append("Munten %d%%/%d%%" % [coins_got_pct, coins_needed_pct])
	if enemies_needed > 0:
		parts.append("Vijanden %d/%d" % [enemies_killed, enemies_needed])
	_cabin_progress_label.text = " · ".join(parts)

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

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 30.0, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)
