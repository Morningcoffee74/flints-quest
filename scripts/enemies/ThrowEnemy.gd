class_name ThrowEnemy
extends BaseEnemy

## Vijand die op zijn plek blijft hangen en met iets gooit — in Wereld 4 de aap
## die vanaf een tak of liaan bananen naar beneden mikt.
##
## Hij loopt niet (collision_mask 0, geen zwaartekracht) maar wiegt zachtjes
## heen en weer. Komt de speler binnen `detect_range`, dan volgt eerst een korte
## waarschuwing (oranje tint, de aap "haalt uit") en pas daarna de worp — zodat
## je 'm ziet aankomen en weg kunt lopen, net als de telegraph van DiveEnemy.
## De banaan wordt als boogje gegooid: hij mikt op waar de speler nú staat.

const PROJECTILE := preload("res://scenes/enemies/common/Banana.tscn")
const WINDUP_TIME := 0.45
## Vluchttijd van de banaan; korter = vlakkere, snellere worp.
const THROW_TIME := 0.85
const SWAY_SPEED := 1.6
const SWAY_PIXELS := 5.0

@export var detect_range: float = 330.0
@export var throw_interval: float = 2.6
## Niet gooien als de speler vrijwel recht onder de aap staat: dan is er geen
## ontwijkruimte. Pas vanaf deze horizontale afstand mikt hij.
@export var min_range: float = 40.0

enum Mode { WAIT, WINDUP }

var _mode: Mode = Mode.WAIT
var _cd := 0.0
var _windup := 0.0
var _time := 0.0
var _anchor := Vector2.ZERO

func _ready() -> void:
	super._ready()
	_anchor = global_position
	_cd = randf_range(0.3, throw_interval)

func _physics_process(delta: float) -> void:
	_time += delta
	# Zachtjes wiegen aan de tak.
	global_position = _anchor + Vector2(sin(_time * SWAY_SPEED) * SWAY_PIXELS, 0.0)

	match _mode:
		Mode.WAIT:
			_cd = maxf(0.0, _cd - delta)
			if _cd <= 0.0 and _target() != null:
				_mode = Mode.WINDUP
				_windup = WINDUP_TIME
				modulate = Color(1.0, 0.75, 0.5)
		Mode.WINDUP:
			_windup -= delta
			if _windup <= 0.0:
				modulate = Color.WHITE
				_mode = Mode.WAIT
				_cd = throw_interval
				var player := _target()
				if player != null:
					_throw_at(player.global_position)

## De speler, mits binnen bereik en niet pal onder de aap.
func _target() -> Player:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	var player := nodes[0] as Player
	if player == null:
		return null
	var d := player.global_position - global_position
	if absf(d.x) < min_range or d.length() > detect_range:
		return null
	return player

func _throw_at(target: Vector2) -> void:
	var banana := PROJECTILE.instantiate() as Node2D
	var from: Vector2 = global_position + Vector2(0.0, 6.0)
	banana.global_position = from
	# Ballistiek: kies een vaste vluchttijd en reken daar de beginsnelheid bij
	# uit, dan komt de banaan netjes in een boog bij de speler uit.
	var d: Vector2 = target - from
	banana.set("velocity", Vector2(
		d.x / THROW_TIME,
		(d.y - 0.5 * 900.0 * THROW_TIME * THROW_TIME) / THROW_TIME))
	if _sprite != null:
		_sprite.flip_h = (d.x > 0.0) != sprite_faces_right
	get_parent().add_child(banana)
