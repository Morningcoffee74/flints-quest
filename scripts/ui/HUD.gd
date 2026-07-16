extends CanvasLayer

const HEART_FULL:  Texture2D = preload("res://assets/sprites/heart-full.png")
const HEART_EMPTY: Texture2D = preload("res://assets/sprites/heart-empty.png")
const ICON_STAR:   Texture2D = preload("res://assets/sprites/items/extra-speed.png")
const ICON_STRONG: Texture2D = preload("res://assets/sprites/items/extra-strong.png")

## Per power-up: icoon, tint en balkkleur.
const POWERUP_STYLE: Dictionary = {
	"star":   {"tint": Color(0.75, 0.4, 1.0), "bar": Color(0.75, 0.4, 1.0)},
	"speed":  {"tint": Color.WHITE,           "bar": Color(0.25, 0.65, 1.0)},
	"strong": {"tint": Color.WHITE,           "bar": Color(1.0, 0.55, 0.15)},
}

var _hearts: Array[TextureRect] = []
var _player: Player = null
var _powerup_rows: Dictionary = {}   # kind -> {row, bar}

@onready var _score_label: Label = $Control/ScoreLabel
@onready var _coin_label:  Label = $Control/CoinLabel
@onready var _lives_label: Label = $Control/LivesLabel
@onready var _powerup_box: VBoxContainer = $Control/PowerupContainer

func _ready() -> void:
	for child in $Control/HeartsContainer.get_children():
		if child is TextureRect:
			_hearts.append(child as TextureRect)
	ScoreManager.score_changed.connect(_on_score_changed)
	ScoreManager.coin_collected.connect(_on_coin_collected)
	set_lives(GameManager.lives)
	_build_powerup_rows()

func connect_player(player: Player) -> void:
	_player = player
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health)

func _build_powerup_rows() -> void:
	for kind: String in POWERUP_STYLE:
		var style: Dictionary = POWERUP_STYLE[kind]
		var row := HBoxContainer.new()
		row.visible = false
		row.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.texture = ICON_STRONG if kind == "strong" else ICON_STAR
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

func _on_health_changed(new_health: int) -> void:
	for i in _hearts.size():
		_hearts[i].texture = HEART_FULL if i < new_health else HEART_EMPTY

func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Score: %d" % new_score

func _on_coin_collected(total_coins: int) -> void:
	_coin_label.text = "x%d" % (total_coins % 10)
