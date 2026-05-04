extends AnimatedSprite2D

func _process(_delta: float) -> void:
	if not sprite_frames:
		return
	var player := get_parent() as Player
	if not player:
		return
	var anim: StringName
	match player.state:
		Player.State.IDLE:   anim = &"idle"
		Player.State.RUN:    anim = &"run"
		Player.State.JUMP:   anim = &"jump"
		Player.State.FALL:   anim = &"fall"
		Player.State.CROUCH: anim = &"crouch"
		Player.State.CLIMB:  anim = &"climb"
		Player.State.PUNCH:  anim = &"punch"
		Player.State.HURT:   anim = &"hurt"
		Player.State.DEAD:   anim = &"dead"
		_:                   anim = &"idle"
	if sprite_frames.has_animation(anim) and animation != anim:
		play(anim)
