class_name PowerBlock
extends Area2D

enum Type { PURPLE, BLUE }

@export var type: Type = Type.PURPLE

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var player := body as Player
	match type:
		Type.PURPLE:
			player.activate_invincible(8.0)
		Type.BLUE:
			player.activate_strong_punch(8.0)
	queue_free()
