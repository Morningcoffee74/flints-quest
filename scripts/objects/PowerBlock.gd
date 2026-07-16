class_name PowerBlock
extends Area2D

enum Type { PURPLE, BLUE, ORANGE }

@export var type: Type = Type.PURPLE

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var player := body as Player
	AudioManager.play_sfx_by_name("powerup")
	match type:
		Type.PURPLE:
			player.activate_invincible()
		Type.BLUE:
			player.activate_speed()
		Type.ORANGE:
			player.activate_strong_punch()
	queue_free()
