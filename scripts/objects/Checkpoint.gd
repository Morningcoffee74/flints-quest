extends Area2D

var _activated := false

@onready var _flag: Polygon2D = $Flag

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if GameManager.respawn_point.is_finite() \
			and GameManager.respawn_point.distance_to(global_position) < 8.0:
		_activate()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not _activated:
		GameManager.respawn_point = global_position
		_activate()

func _activate() -> void:
	_activated = true
	_flag.color = Color(0.2, 0.85, 0.3, 1.0)
