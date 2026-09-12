class_name Player
extends CharacterBody2D

enum State { IDLE, RUN, JUMP, FALL, CROUCH, CLIMB, PUNCH, HURT, DEAD, SWIM, SWING }

const SPEED             := 180.0
const JUMP_VELOCITY     := -550.0
const CLIMB_SPEED       := 100.0
const GRAVITY           := 980.0
const PUNCH_DURATION    := 0.35
const HURT_DURATION     := 0.5
const INVINCIBLE_DURATION := 1.5
const POWERUP_DURATION  := 14.0
const SPEED_BOOST_MULT  := 1.5

# Zwemmen (Wereld 2): trager en dempend, langzaam zakken door drijfvermogen,
# stroke omhoog met de springknop. Zie enter_water()/exit_water().
const SWIM_SPEED        := 130.0   # horizontale topsnelheid in water
const SWIM_ACCEL        := 600.0   # hoe snel je op snelheid komt (dempend)
const SWIM_DRAG         := 300.0   # afremmen zonder invoer
const SWIM_STROKE       := -230.0  # opwaartse zet bij een druk op springen
const SWIM_VERTICAL     := 190.0   # omhoog/omlaag sturen met W/S (snel genoeg om de bodem te halen)
const WATER_GRAVITY     := 220.0   # veel lichter dan de gewone 980
const WATER_SINK_SPEED  := 60.0    # maximale zaksnelheid als je niets doet

# Liaan-slingeren (Wereld 4)
const VINE_HANG_OFFSET  := 54.0    # hoeveel lager de voeten hangen dan het grijppunt
const VINE_RELEASE_MULT := 1.25    # extra vaart mee bij loslaten
const VINE_RELEASE_LIFT := -210.0  # zetje omhoog, zodat loslaten altijd een sprong is
const VINE_REGRAB_DELAY := 0.35    # niet meteen terugplakken aan dezelfde liaan
const VINE_LAUNCH_TIME  := 0.9     # hoelang de zwaai-vaart blijft staan na loslaten
const VINE_LAUNCH_DECAY := 150.0   # hoe snel die vaart uitdooft (px/s per seconde)
const VINE_AIR_CONTROL  := 0.35    # hoeveel je tijdens die vlucht nog kunt bijsturen

# Drijfzand (Wereld 4)
const SAND_SPEED_MULT   := 0.45    # je komt er nog wel doorheen, maar traag
const SAND_SINK_SPEED   := 42.0    # zo langzaam dat er tijd is om eruit te springen
const SAND_JUMP_MULT    := 0.72    # springen kan, maar minder hoog

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
var _in_water           := false
var _vine: Vine         = null   # liaan waar je nu aan hangt (Wereld 4)
var _vine_cooldown      := 0.0   # voorkomt dat je meteen terugplakt na loslaten
var _launch_timer       := 0.0   # loopt na het loslaten van een liaan
var _launch_vx          := 0.0   # meegekregen horizontale zwaai-vaart
var _in_quicksand       := false
## Stroming (Current.gd) die de zwemsnelheid verschuift zolang je in de zone zit.
var water_push          := Vector2.ZERO
var _speed_difficulty   := 1.0   # samengestelde wereld/level-opbouw, zie GameManager.get_speed_difficulty()

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var punch_hitbox: Area2D          = $PunchHitbox
@onready var body_collision: CollisionShape2D   = $BodyCollision
@onready var crouch_collision: CollisionShape2D = $CrouchCollision

signal health_changed(new_health: int)
signal died
signal powerup_activated(kind: String)

func _ready() -> void:
	add_to_group("player")
	punch_hitbox.monitoring = false
	punch_hitbox.area_entered.connect(_on_punch_area)
	_speed_difficulty = GameManager.get_speed_difficulty()

func _on_punch_area(area: Area2D) -> void:
	var parent := area.get_parent()
	if parent is SpecialBlock:
		parent.hit_by_punch()
	elif parent is BaseEnemy:
		# Betrouwbare klap, ook op een eindbaas waar je vlak tegenaan staat.
		(parent as BaseEnemy).hit_by_punch(is_strong_punch)

## Heldere veeg-boog vóór de speler bij het slaan, zodat de klap duidelijk
## zichtbaar is (de kale boks-animatie was nauwelijks te zien). Oranje bij de
## harde-klap-power-up, anders geel-wit.
func _spawn_punch_fx() -> void:
	var fx := Line2D.new()
	fx.width = 6.0
	fx.default_color = Color(1.0, 0.55, 0.1, 0.95) if is_strong_punch else Color(1.0, 1.0, 0.65, 0.95)
	fx.begin_cap_mode = Line2D.LINE_CAP_ROUND
	fx.end_cap_mode = Line2D.LINE_CAP_ROUND
	fx.joint_mode = Line2D.LINE_JOINT_ROUND
	var pts := PackedVector2Array()
	for i in range(9):
		var a: float = lerpf(-1.0, 1.0, i / 8.0)
		pts.append(Vector2(cos(a), sin(a)) * 26.0)
	fx.points = pts
	fx.z_index = 5
	fx.position = Vector2(34.0 if facing_right else -34.0, -40.0)
	fx.scale.x = 1.0 if facing_right else -1.0
	add_child(fx)
	var tween := create_tween()
	tween.tween_property(fx, "scale", fx.scale * 1.5, 0.18)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, 0.18)
	tween.tween_callback(fx.queue_free)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	# In het water dwingt alles behalve slaan/geraakt/dood naar de zwem-state.
	if _in_water and state in [State.IDLE, State.RUN, State.JUMP, State.FALL, State.CROUCH, State.CLIMB]:
		_transition(State.SWIM)
	match state:
		State.IDLE:   _state_idle(delta)
		State.RUN:    _state_run(delta)
		State.JUMP:   _state_jump(delta)
		State.FALL:   _state_fall(delta)
		State.CROUCH: _state_crouch(delta)
		State.CLIMB:  _state_climb(delta)
		State.PUNCH:  _state_punch(delta)
		State.HURT:   _state_hurt(delta)
		State.SWIM:   _state_swim(delta)
		State.SWING:  _state_swing(delta)
		State.DEAD:   return
	move_and_slide()

func _tick_timers(delta: float) -> void:
	if _punch_timer > 0.0:
		_punch_timer -= delta
		if _punch_timer <= 0.0:
			punch_hitbox.monitoring = false
			if _in_water:
				_transition(State.SWIM)
			else:
				_transition(State.IDLE if is_on_floor() else State.FALL)

	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0 and state == State.HURT:
			if _in_water:
				_transition(State.SWIM)
			else:
				_transition(State.IDLE if is_on_floor() else State.FALL)

	_vine_cooldown      = maxf(0.0, _vine_cooldown - delta)
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
	_move_horizontal(delta)
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
	_move_horizontal(delta)
	if Input.is_action_just_pressed("punch"):
		_transition(State.PUNCH)
	elif _in_quicksand and Input.is_action_just_pressed("jump"):
		_jump()   # spartelen: in drijfzand mag je ook zonder vaste grond afzetten
	if velocity.y >= 0.0:
		_transition(State.FALL)

func _state_fall(delta: float) -> void:
	_apply_gravity(delta)
	_move_horizontal(delta)
	if Input.is_action_just_pressed("punch"):
		_transition(State.PUNCH)
	elif _in_quicksand and Input.is_action_just_pressed("jump"):
		_jump()
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

func _state_swim(delta: float) -> void:
	# Horizontaal: dempend sturen naar links/rechts.
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing_right = dir > 0.0
		anim_sprite.flip_h = not facing_right
		velocity.x = move_toward(velocity.x, dir * SWIM_SPEED + water_push.x, SWIM_ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, water_push.x, SWIM_DRAG * delta)

	# Verticaal: springknop = korte zet omhoog; omhoog/omlaag = rustig sturen;
	# niets = langzaam zakken door drijfvermogen.
	if Input.is_action_just_pressed("jump"):
		velocity.y = SWIM_STROKE
		AudioManager.play_sfx_by_name("jump")
	elif Input.is_action_pressed("move_up"):
		velocity.y = move_toward(velocity.y, -SWIM_VERTICAL, SWIM_ACCEL * delta)
	elif Input.is_action_pressed("move_down"):
		velocity.y = move_toward(velocity.y, SWIM_VERTICAL, SWIM_ACCEL * delta)
	else:
		velocity.y = move_toward(velocity.y, WATER_SINK_SPEED, WATER_GRAVITY * delta)

	if Input.is_action_just_pressed("punch"):
		_transition(State.PUNCH)

## Aan een liaan hangen (Wereld 4). De liaan zwaait zelf; de speler wordt aan
## het grijppunt meegevoerd, stuurt met links/rechts de uitslag groter of
## kleiner, en laat los met de springknop.
func _state_swing(delta: float) -> void:
	if _vine == null:
		_transition(State.FALL)
		return
	var dir := Input.get_axis("move_left", "move_right")
	_vine.pump(dir, delta)

	var tip := _vine.get_tip_velocity()
	if absf(tip.x) > 1.0:
		facing_right = tip.x > 0.0
		anim_sprite.flip_h = not facing_right

	# Handen aan het grijppunt: de speler hangt er met zijn lijf onder.
	global_position = _vine.get_grab_position() + Vector2(0.0, VINE_HANG_OFFSET)
	velocity = Vector2.ZERO

	if Input.is_action_just_pressed("jump"):
		release_vine()

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
			_spawn_punch_fx()
			AudioManager.play_sfx_by_name("punch")
		State.HURT:
			_hurt_timer = HURT_DURATION
			_invincible_timer = INVINCIBLE_DURATION
			is_invincible = true
			var dir := -1.0 if facing_right else 1.0
			# Onder water een zachtere terugslag (geen sprong-achtige knal omhoog).
			velocity = Vector2(dir * 120.0, -60.0) if _in_water else Vector2(dir * 180.0, -200.0)
		State.DEAD:
			velocity = Vector2.ZERO
			set_physics_process(false)
			_play_death_animation()

func _play_death_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(died.emit)

func _jump() -> void:
	velocity.y = JUMP_VELOCITY * (SAND_JUMP_MULT if _in_quicksand else 1.0)
	AudioManager.play_sfx_by_name("jump")
	_transition(State.JUMP)

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	if _in_water:
		# Ook tijdens slaan/geraakt-worden onder water niet als een baksteen
		# zinken: zelfde lichte zwaartekracht en zaksnelheid als bij het zwemmen.
		velocity.y = move_toward(velocity.y, WATER_SINK_SPEED, WATER_GRAVITY * delta)
	elif _in_quicksand:
		# In drijfzand zak je traag maar gestaag; snel vallen bestaat er niet.
		velocity.y = move_toward(velocity.y, SAND_SINK_SPEED, GRAVITY * delta)
	else:
		velocity.y += GRAVITY * delta

func _move_horizontal(delta: float = 0.0) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var top_speed := SPEED * _speed_difficulty * (SPEED_BOOST_MULT if _speed_timer > 0.0 else 1.0)
	if _in_quicksand:
		top_speed *= SAND_SPEED_MULT
	if dir != 0.0:
		facing_right = dir > 0.0
		anim_sprite.flip_h = not facing_right

	# Net van een liaan losgelaten: de zwaai-vaart moet blijven staan. Zou hier
	# gewoon `velocity.x = dir * top_speed` gebeuren, dan wist de loopsnelheid de
	# lancering meteen uit en kwam je nooit verder dan een gewone sprong.
	if _launch_timer > 0.0 and not is_on_floor():
		_launch_timer -= delta
		_launch_vx = move_toward(_launch_vx, 0.0, VINE_LAUNCH_DECAY * delta)
		velocity.x = _launch_vx + dir * top_speed * VINE_AIR_CONTROL
		return
	_launch_timer = 0.0

	if dir != 0.0:
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
	powerup_activated.emit("star")

func activate_speed(duration: float = POWERUP_DURATION) -> void:
	_speed_timer = maxf(_speed_timer, duration)
	powerup_activated.emit("speed")

func activate_strong_punch(duration: float = POWERUP_DURATION) -> void:
	is_strong_punch = true
	_strong_punch_timer = maxf(_strong_punch_timer, duration)
	powerup_activated.emit("strong")

## Voor de loop-animatie: laat het lopen zichtbaar sneller aanvoelen tijdens de boost.
func is_speed_boosted() -> bool:
	return _speed_timer > 0.0

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

## Korte onkwetsbaarheid bij (her)start/respawn, zodat een vijand die toevallig
## op de checkpoint-plek staat niet meteen een hartje kost.
func grant_spawn_invincibility(duration: float = INVINCIBLE_DURATION) -> void:
	_invincible_timer = maxf(_invincible_timer, duration)
	is_invincible = true

## Aangeroepen door het Water-object (Water.gd) als de speler het water in/uit gaat.
func enter_water() -> void:
	if _in_water:
		return
	_in_water = true
	# Splash-demping: een snelle val niet door het water heen laten schieten.
	velocity.y = clampf(velocity.y, -120.0, 90.0)
	if state != State.DEAD and state != State.HURT and state != State.PUNCH:
		_transition(State.SWIM)

## Extra zet omhoog bij het uit het water springen: zo kom je betrouwbaar op
## een oever die ~20px boven de waterlijn ligt, maar niet op rotsen die verder
## boven water uitsteken (W2: vanaf rij 17 = 84px boven water). De waterzone
## begint pas `Water.submerge` (33px) onder het oppervlak, dus de zet vertrekt
## van dáár: −400 ≈ 82px stijgen → voeten tot ~49px boven de waterlijn.
const WATER_EXIT_BOOST := -400.0

func exit_water() -> void:
	_in_water = false
	if state == State.SWIM:
		# Bij het verlaten van het water de opwaartse snelheid behouden (uit het
		# water springen); de gewone zwaartekracht neemt het weer over.
		if velocity.y < -80.0:
			velocity.y = minf(velocity.y, WATER_EXIT_BOOST)
		_transition(State.FALL)

func enter_ladder() -> void:
	_on_ladder = true

func exit_ladder() -> void:
	_on_ladder = false
	if state == State.CLIMB:
		_transition(State.FALL)

## --- Liaan (Wereld 4) ---

## Aangeroepen door Vine.gd zodra de speler het grijppunt raakt. Vastpakken kan
## alleen vanuit de lucht of vanaf de grond — niet tijdens slaan, geraakt
## worden, zwemmen of klimmen — en niet vlak nadat je losliet.
func grab_vine(vine: Vine) -> void:
	if _vine != null or _vine_cooldown > 0.0 or _in_water:
		return
	if state in [State.PUNCH, State.HURT, State.DEAD, State.CLIMB]:
		return
	_vine = vine
	_transition(State.SWING)

## Loslaten: je vertrekt met de baansnelheid van de liaanpunt, dus op het
## uiterste punt van de zwaai kom je het verst.
func release_vine() -> void:
	if _vine == null:
		return
	var tip := _vine.get_tip_velocity()
	_vine = null
	_vine_cooldown = VINE_REGRAB_DELAY
	_launch_vx = tip.x * VINE_RELEASE_MULT
	_launch_timer = VINE_LAUNCH_TIME
	velocity = Vector2(_launch_vx, minf(tip.y, 0.0) + VINE_RELEASE_LIFT)
	AudioManager.play_sfx_by_name("jump")
	_transition(State.JUMP)

## Valt de liaan weg (level herladen), dan gewoon vallen.
func drop_vine() -> void:
	if _vine == null:
		return
	_vine = null
	_vine_cooldown = VINE_REGRAB_DELAY
	_transition(State.FALL)

## --- Drijfzand (Wereld 4) ---

func enter_quicksand() -> void:
	_in_quicksand = true

func exit_quicksand() -> void:
	_in_quicksand = false

func is_in_quicksand() -> bool:
	return _in_quicksand
