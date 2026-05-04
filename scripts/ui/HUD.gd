extends CanvasLayer

const HEART_FULL  := Color(0.95, 0.15, 0.15, 1.0)
const HEART_EMPTY := Color(0.25, 0.25, 0.25, 1.0)

var _hearts: Array[ColorRect] = []

@onready var _score_label: Label = $Control/ScoreLabel
@onready var _coin_label:  Label = $Control/CoinLabel

func _ready() -> void:
	for child in $Control/HeartsContainer.get_children():
		if child is ColorRect:
			_hearts.append(child as ColorRect)
	ScoreManager.score_changed.connect(_on_score_changed)
	ScoreManager.coin_collected.connect(_on_coin_collected)

func connect_player(player: Player) -> void:
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health)

func _on_health_changed(new_health: int) -> void:
	for i in _hearts.size():
		_hearts[i].color = HEART_FULL if i < new_health else HEART_EMPTY

func _on_score_changed(new_score: int) -> void:
	_score_label.text = "Score: %d" % new_score

func _on_coin_collected(total_coins: int) -> void:
	_coin_label.text = "Munten: x%d" % (total_coins % 10)
