class_name BaseEnemy
extends CharacterBody2D

@export var base_health: int   = 1
@export var base_speed: float  = 60.0
## Als true straft een sprong op de kop de speler af (schade) in plaats van de vijand te doden.
@export var stomp_immune: bool = false
## Kijkrichting van de sprite-tekening zelf (voor flip_h bij omdraaien).
@export var sprite_faces_right: bool = false

var health: int  = 1
var speed: float = 60.0

var _sprite: AnimatedSprite2D = null
## Korte drempel zodat één klap maar één keer telt, ook als zowel de speler-kant
## (Player._on_punch_area) als de vijand-kant (HurtBox.area_entered) dezelfde
## klap oppikken.
var _hit_cd: float = 0.0

signal died

func _ready() -> void:
	var w := GameManager.current_world
	var l := GameManager.current_level
	var difficulty := 1.0 + (w - 1) * 0.15 + (l - 1) * 0.02
	health = maxi(1, roundi(base_health * difficulty))
	speed  = base_speed * GameManager.get_speed_difficulty()
	add_to_group("enemies")
	_sprite = get_node_or_null("Sprite") as AnimatedSprite2D

	if has_node("HurtBox"):
		var hb := $HurtBox as Area2D
		hb.body_entered.connect(_on_body_entered)
		hb.area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if _hit_cd > 0.0:
		_hit_cd -= delta

## Aangeroepen vanuit Player._on_punch_area: de speler-kant vuurt betrouwbaar af
## op het moment van slaan (de PunchHitbox zet dan monitoring aan, waardoor Godot
## area_entered opnieuw afvuurt voor al-overlappende zones) — dus ook als je al
## tegen de vijand aan staat.
func hit_by_punch(strong: bool) -> void:
	_take_hit(null, strong)

## True (en start de cooldown) als deze klap mag tellen; anders False.
func _can_register_hit() -> bool:
	if _hit_cd > 0.0:
		return false
	_hit_cd = 0.2
	return true

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var player := body as Player
	if player.velocity.y > 150.0 and player.global_position.y < global_position.y - 5.0:
		if stomp_immune:
			player.take_damage()
			_start_flee(player)
		else:
			_take_hit(player)
	else:
		player.take_damage()

func _on_area_entered(area: Area2D) -> void:
	var player := area.get_parent() as Player
	if player and player.state == Player.State.PUNCH:
		_take_hit(null, player.is_strong_punch)

func _take_hit(stomper: Player = null, instant_kill: bool = false) -> void:
	if not _can_register_hit():
		return
	if instant_kill:
		health = 0
	else:
		health -= 1
	if health <= 0:
		_die(stomper)
	else:
		if stomper != null:
			stomper.velocity.y = -300.0
		_on_hurt()

func _die(stomper: Player = null) -> void:
	if stomper != null:
		ScoreManager.add_points(ScoreManager.POINTS_ENEMY_JUMP)
		stomper.velocity.y = -300.0
	else:
		ScoreManager.add_points(ScoreManager.POINTS_ENEMY_PUNCH)
	AudioManager.play_sfx_by_name("enemy_die")
	died.emit()
	queue_free()

## Overschreven door subklassen die na een mislukte stomp-poging op een
## stomp_immune-vijand even wegvluchten in plaats van te blijven jitteren.
func _start_flee(_player: Player) -> void:
	pass

## Draait de sprite mee met de horizontale bewegingsrichting.
func _update_facing() -> void:
	if _sprite != null and absf(velocity.x) > 1.0:
		_sprite.flip_h = (velocity.x > 0.0) != sprite_faces_right

func _on_hurt() -> void:
	var tween := create_tween()
	modulate = Color(1.0, 0.4, 0.4, 1.0)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
