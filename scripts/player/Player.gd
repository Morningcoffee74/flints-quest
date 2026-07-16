class_name Player
extends CharacterBody2D

enum State { IDLE, RUN, JUMP, FALL, CROUCH, CLIMB, PUNCH, HURT, DEAD }

const SPEED             := 180.0
const JUMP_VELOCITY     := -550.0
const CLIMB_SPEED       := 100.0
const GRAVITY           := 980.0
const PUNCH_DURATION    := 0.35
const HURT_DURATION     := 0.5
const INVINCIBLE_DURATION := 1.5
const POWERUP_DURATION  := 8.0
const SPEED_BOOST_MULT  := 1.5

var state: State = State.IDLE
var facing_right      := true
var health            := 5
var is_invincible     := false
var is_strong_punch   := false

var _punch_timer        := 0.0
var _hurt_timer         := 0.0
var _invincible_timer   := 0.0   # korte onkwetsbaarheid na schade
var _star_timer         := 0.0   # ster-power-up: onkwetsbaar
var _speed_timer        := 0.0   # blauwe power-up: sneller lopen
var _strong_punch_timer := 0.0   # oranje power-up: hard slaan
var _on_ladder          := false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_hitbox: Area2D          = $PunchHitbox
@onready var body_collision: CollisionShape2D   = $BodyCollision
@onready var crouch_collision: CollisionShape2D = $CrouchCollision

signal health_changed(new_health: int)
signal died

func _ready() -> void:
	add_to_group("player")
	punch_hitbox.monitoring = false
	punch_hitbox.area_entered.connect(_on_punch_area)

func _on_punch_area(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent is SpecialBlock:
		parent.hit_by_punch()

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	match state:
		State.IDLE:   _state_idle(delta)
		State.RUN:    _state_run(delta)
		State.JUMP:   _state_jump(delta)
		State.FALL:   _state_fall(delta)
		State.CROUCH: _state_crouch(delta)
		State.CLIMB:  _state_climb(delta)
		State.PUNCH:  _state_punch(delta)
		State.HURT:   _state_hurt(delta)
		State.DEAD:   return
	move_and_slide()

func _tick_timers(delta: float) -> void:
	if _punch_timer > 0.0:
		_punch_timer -= delta
		if _punch_timer <= 0.0:
			punch_hitbox.monitoring = false
			_transition(State.IDLE if is_on_floor() else State.FALL)

	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0 and state == State.HURT:
			_transition(State.IDLE if is_on_floor() else State.FALL)

	_invincible_timer   = maxf(0.0, _invincible_timer - delta)
	_star_timer         = maxf(0.0, _star_timer - delta)
	_speed_timer        = maxf(0.0, _speed_timer - delta)
	_strong_punch_timer = maxf(0.0, _strong_punch_timer - delta)
	is_invincible   = _invincible_timer > 0.0 or _star_timer > 0.0
	is_strong_punch = _strong_punch_timer > 0.0
	_update_powerup_tint()

func _state_idle(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, SPEED)
	if not is_on_floor():
		_transition(State.FALL)
		return
	if Input.is_action_just_pressed("punch"):
		_transition(State.PUNCH)
	elif Input.is_action_just_pressed("jump"):
		_jump()
	elif Input.is_action_pressed("move_down"):
		_transition(State.CROUCH)
	elif _on_ladder and Input.is_action_pressed("move_up"):
		_transition(State.CLIMB)
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		_transition(State.RUN)

func _state_run(delta: float) -> void:
	_apply_gravity(delta)
	_move_horizontal()
	if not is_on_floor():
		_transition(State.FALL)
		return
	if Input.is_action_just_pressed("punch"):
		_transition(State.PUNCH)
	elif Input.is_action_just_pressed("jump"):
		_jump()
	elif Input.is_action_pressed("move_down"):
		_transition(State.CROUCH)
	elif _on_ladder and Input.is_action_pressed("move_up"):
		_transition(State.CLIMB)
	elif not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		_transition(State.IDLE)

func _state_jump(delta: float) -> void:
	_apply_gravity(delta)
	_move_horizontal()
	if Input.is_action_just_pressed("punch"):
		_transition(State.PUNCH)
	if velocity.y >= 0.0:
		_transition(State.FALL)

func _state_fall(delta: float) -> void:
	_apply_gravity(delta)
	_move_horizontal()
	if Input.is_action_just_pressed("punch"):
		_transition(State.PUNCH)
	if is_on_floor():
		_transition(State.IDLE)
	elif _on_ladder and Input.is_action_pressed("move_up"):
		_transition(State.CLIMB)

func _state_crouch(_delta: float) -> void:
	velocity.x = 0.0
	if not Input.is_action_pressed("move_down"):
		_transition(State.IDLE)

func _state_climb(_delta: float) -> void:
	velocity = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		velocity.y = -CLIMB_SPEED
	elif Input.is_action_pressed("move_down"):
		velocity.y = CLIMB_SPEED
	if Input.is_action_just_pressed("jump"):
		_on_ladder = false
		_jump()
	elif not _on_ladder:
		_transition(State.FALL)
	elif is_on_floor() and not Input.is_action_pressed("move_up"):
		_transition(State.IDLE)

func _state_punch(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, SPEED * 4.0 * delta)

func _state_hurt(delta: float) -> void:
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)

func _transition(new_state: State) -> void:
	if state == new_state:
		return
	var old_state := state
	state = new_state
	if old_state == State.CROUCH and new_state != State.CROUCH:
		body_collision.set_deferred("disabled", false)
		crouch_collision.set_deferred("disabled", true)
	match new_state:
		State.CROUCH:
			body_collision.set_deferred("disabled", true)
			crouch_collision.set_deferred("disabled", false)
		State.PUNCH:
			_punch_timer = PUNCH_DURATION
			punch_hitbox.scale.x = 1.0 if facing_right else -1.0
			punch_hitbox.monitoring = true
			AudioManager.play_sfx_by_name("punch")
		State.HURT:
			_hurt_timer = HURT_DURATION
			_invincible_timer = INVINCIBLE_DURATION
			is_invincible = true
			var dir := -1.0 if facing_right else 1.0
			velocity = Vector2(dir * 180.0, -200.0)
		State.DEAD:
			velocity = Vector2.ZERO
			set_physics_process(false)
			_play_death_animation()

func _play_death_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(died.emit)

func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	AudioManager.play_sfx_by_name("jump")
	_transition(State.JUMP)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _move_horizontal() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var top_speed := SPEED * (SPEED_BOOST_MULT if _speed_timer > 0.0 else 1.0)
	if dir != 0.0:
		facing_right = dir > 0.0
		anim_sprite.flip_h = not facing_right
		velocity.x = dir * top_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, top_speed)

func take_damage() -> void:
	if is_invincible or state == State.DEAD:
		return
	health -= 1
	ScoreManager.register_damage()
	AudioManager.play_sfx_by_name("hurt")
	health_changed.emit(health)
	if health <= 0:
		_transition(State.DEAD)
	else:
		_transition(State.HURT)

func heal(amount: int = 1) -> void:
	health = min(health + amount, 5)
	health_changed.emit(health)

func activate_invincible(duration: float = POWERUP_DURATION) -> void:
	is_invincible = true
	_star_timer = maxf(_star_timer, duration)

func activate_speed(duration: float = POWERUP_DURATION) -> void:
	_speed_timer = maxf(_speed_timer, duration)

func activate_strong_punch(duration: float = POWERUP_DURATION) -> void:
	is_strong_punch = true
	_strong_punch_timer = maxf(_strong_punch_timer, duration)

## Actieve power-ups voor de HUD: [{kind, left, total}].
func get_active_powerups() -> Array:
	var list: Array = []
	if _star_timer > 0.0:
		list.append({"kind": "star", "left": _star_timer, "total": POWERUP_DURATION})
	if _speed_timer > 0.0:
		list.append({"kind": "speed", "left": _speed_timer, "total": POWERUP_DURATION})
	if _strong_punch_timer > 0.0:
		list.append({"kind": "strong", "left": _strong_punch_timer, "total": POWERUP_DURATION})
	return list

## Kleurt de speler licht mee met de actiefste power-up.
func _update_powerup_tint() -> void:
	if _star_timer > 0.0:
		anim_sprite.modulate = Color(1.3, 1.2, 0.6)
	elif _speed_timer > 0.0:
		anim_sprite.modulate = Color(0.7, 1.0, 1.4)
	elif _strong_punch_timer > 0.0:
		anim_sprite.modulate = Color(1.4, 0.9, 0.6)
	else:
		anim_sprite.modulate = Color.WHITE

func enter_ladder() -> void:
	_on_ladder = true

func exit_ladder() -> void:
	_on_ladder = false
	if state == State.CLIMB:
		_transition(State.FALL)
