class_name SpecialBlock
extends StaticBody2D

const COIN_SCENE := preload("res://scenes/objects/Coin.tscn")

func hit_by_punch() -> void:
	ScoreManager.add_points(ScoreManager.POINTS_SPECIAL_BLOCK)
	var coin := COIN_SCENE.instantiate()
	coin.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(coin)
	_play_break_anim()

func _play_break_anim() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.18)
	tween.tween_callback(queue_free)
