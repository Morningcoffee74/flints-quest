extends Area2D

var _activated := false

@onready var _flag: Polygon2D = $Flag

func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	if GameManager.respawn_point.is_finite() and GameManager.respawn_point.x >= global_position.x - 4.0:
		_activate()

func _physics_process(_delta: float) -> void:
	# Naast de directe aanraking ook op x-positie activeren: op een hoge route
	# (ladder/platform) boven de checkpoint-paal loopt de speler er anders
	# zonder ooit de Area2D te raken voorbij, en verscheen bij een volgende
	# dood alsnog helemaal aan het begin van het level i.p.v. bij de laatst
	# gepasseerde checkpoint.
	if _activated:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D and (player as Node2D).global_position.x >= global_position.x:
		_trigger()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not _activated:
		_trigger()

func _trigger() -> void:
	GameManager.respawn_point = global_position
	_activate()

func _activate() -> void:
	_activated = true
	_flag.color = Color(0.2, 0.85, 0.3, 1.0)
