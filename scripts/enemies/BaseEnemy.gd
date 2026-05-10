class_name BaseEnemy
extends CharacterBody2D

@export var base_health: int   = 1
@export var base_speed: float  = 60.0

var health: int  = 1
var speed: float = 60.0

signal died

func _ready() -> void:
	var w := GameManager.current_world
	var l := GameManager.current_level
	var difficulty := 1.0 + (w - 1) * 0.15 + (l - 1) * 0.02
	health = base_health
	speed  = base_speed * difficulty
	add_to_group("enemies")

	if has_node("HurtBox"):
		var hb := $HurtBox as Area2D
		hb.body_entered.connect(_on_body_entered)
		hb.area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var player := body as Player
	if player.velocity.y > 150.0 and player.global_position.y < global_position.y - 5.0:
		_take_hit(player)
	else:
		player.take_damage()

func _on_area_entered(area: Area2D) -> void:
	var player := area.get_parent() as Player
	if player and player.state == Player.State.PUNCH:
		_take_hit(null, player.is_strong_punch)

func _take_hit(stomper: Player = null, instant_kill: bool = false) -> void:
	if instant_kill:
		health = 0
	else:
		health -= 1
	if health <= 0:
		_die(stomper)
	else:
		_on_hurt()

func _die(stomper: Player = null) -> void:
	if stomper != null:
		ScoreManager.add_points(ScoreManager.POINTS_ENEMY_JUMP)
		stomper.velocity.y = -300.0
	else:
		ScoreManager.add_points(ScoreManager.POINTS_ENEMY_PUNCH)
	died.emit()
	queue_free()

func _on_hurt() -> void:
	pass
