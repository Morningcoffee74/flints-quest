extends AnimatedSprite2D

const STAND_SPRITE_Y := -64.0
const SWIM_SPRITE_Y  := -33.0

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
		Player.State.SWIM:   anim = &"swim"
		Player.State.DEAD:   anim = &"dead"
		_:                   anim = &"idle"
	if sprite_frames.has_animation(anim) and animation != anim:
		play(anim)
	# De zwemsprite ligt horizontaal en is in zijn 128-cel gecentreerd (figuur-
	# midden op cel-y 64); de staande sprites staan met hun voeten onderin de
	# cel. Zonder correctie hangt de zwemmer dus 31px boven zijn hitbox: hij
	# "zweeft" boven het water en komt nooit tot de zeebodem. In het water het
	# figuur-midden op het capsule-midden (y −33) leggen.
	position.y = SWIM_SPRITE_Y if player.state == Player.State.SWIM else STAND_SPRITE_Y
	# Blauwe power-up: loop-animatie merkbaar sneller zodat de boost ook voelt als sprinten.
	speed_scale = 1.4 if player.is_speed_boosted() else 1.0
