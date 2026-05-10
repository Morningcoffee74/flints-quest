class_name Boss
extends BaseEnemy

const GRAVITY      := 980.0
const ATTACK_RANGE := 110.0
const ARM_DURATION := 0.6

var _phase2    := false
var _attack_cd := 3.0
var _arm_active := false
var _arm_timer  := 0.0

func _ready() -> void:
	super._ready()
	for arm in ["LeftArm", "RightArm"]:
		if has_node(arm):
			var a := get_node(arm) as Area2D
			a.monitoring = false
			a.body_entered.connect(_on_arm_hit)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_attack_cd = max(0.0, _attack_cd - delta)

	if _arm_active:
		_arm_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if _arm_timer <= 0.0:
			_end_arm_attack()
	else:
		var player := _get_player()
		if player != null:
			var dx := player.global_position.x - global_position.x
			if abs(dx) < ATTACK_RANGE and _attack_cd <= 0.0:
				_begin_arm_attack(sign(dx))
			else:
				velocity.x = sign(dx) * speed

	move_and_slide()

func _begin_arm_attack(direction: float) -> void:
	_arm_active = true
	_arm_timer  = ARM_DURATION
	_attack_cd  = 1.6 if _phase2 else 2.5
	var arm_name := "RightArm" if direction > 0.0 else "LeftArm"
	if has_node(arm_name):
		(get_node(arm_name) as Area2D).monitoring = true

func _end_arm_attack() -> void:
	_arm_active = false
	for arm in ["LeftArm", "RightArm"]:
		if has_node(arm):
			(get_node(arm) as Area2D).monitoring = false

func _on_arm_hit(body: Node2D) -> void:
	if body is Player:
		(body as Player).take_damage()

func _take_hit(stomper: Player = null, instant_kill: bool = false) -> void:
	if instant_kill:
		health = 0
	else:
		health -= 1

	if not _phase2 and health <= base_health / 2:
		_phase2 = true
		speed  *= 1.6
		modulate = Color(1.0, 0.55, 0.55)

	if health <= 0:
		_die(stomper)

func _die(stomper: Player = null) -> void:
	ScoreManager.add_points(ScoreManager.POINTS_BOSS)
	died.emit()
	queue_free()

func _get_player() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] as Player if not nodes.is_empty() else null
