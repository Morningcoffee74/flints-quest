extends Control

@onready var _grid:     GridContainer = $VBox/WorldGrid
@onready var _back_btn: Button        = $VBox/BackButton

func _ready() -> void:
	_back_btn.pressed.connect(GameManager.go_to_main_menu)
	_build_grid()

func _build_grid() -> void:
	for w in range(1, 11):
		var cfg: Dictionary = WorldConfig.WORLDS[w - 1]
		var unlocked := GameManager.is_world_unlocked(w)

		var btn := Button.new()
		btn.text = "%d. %s" % [w, cfg["name"]]
		btn.custom_minimum_size = Vector2(150, 90)
		btn.disabled = not unlocked
		btn.modulate = Color.WHITE if unlocked else Color(0.5, 0.5, 0.5, 1.0)
		if unlocked:
			btn.pressed.connect(_on_world_pressed.bind(w))
		_grid.add_child(btn)

func _on_world_pressed(world: int) -> void:
	GameManager.go_to_world_map(world)
