class_name Vine
extends Node2D

## Liaan om aan te slingeren (Wereld 4). Werkt als de slinger zélf: de liaan
## zwaait autonoom heen en weer en de speler wordt, zolang hij vasthoudt, aan
## het uiteinde meegevoerd. Dat is veel stabieler dan echte slingerfysica op de
## speler loslaten, en het laat zich exact valideren in de generator.
##
## Het knooppunt staat op het ANKER (het tak-punt waar de liaan aan hangt); het
## grijppunt hangt `length` px eronder en zwenkt mee. De speler grijpt vast door
## de GrabArea aan te raken en laat los met de springknop — hij vertrekt dan met
## de baansnelheid van de punt, dus op het uiterste punt van de zwaai spring je
## het verst. Links/rechts pompt de zwaai groter of kleiner, net als op een schommel.

## Lengte van de liaan in pixels (anker → grijppunt).
@export var length: float = 170.0
## Tijd voor één volledige heen-en-weer-zwaai.
@export var period: float = 2.6
## Maximale uitslag in graden, vanaf verticaal.
@export var amplitude_deg: float = 40.0
## Verschuiving in de zwaai, zodat liaan 2 niet gelijk loopt met liaan 1.
@export var phase: float = 0.0

const MIN_AMPLITUDE := 12.0
const MAX_AMPLITUDE := 62.0
const PUMP_PER_SECOND := 26.0
## Je grijpt de liaan niet alleen op de punt maar over de hele ONDERSTE helft:
## de speler springt er dwars doorheen en pakt hem waar hij hem raakt. Met
## alleen een bolletje op de punt werd het een kwestie van precies timen, en dat
## is voor dit spel te streng.
const GRAB_SPAN := 0.55     # welk deel van de liaan (vanaf onderen) grijpbaar is
const GRAB_RADIUS := 24.0

var _t := 0.0
var _angle := 0.0
var _amplitude := 0.0
var _grab_pos := Vector2.ZERO
var _prev_grab := Vector2.ZERO
var _tip_velocity := Vector2.ZERO
var _rope: Line2D = null
var _grab_area: Area2D = null
var _leaf: Polygon2D = null

func _ready() -> void:
	_amplitude = amplitude_deg
	_t = phase
	_build_visual()
	_update_swing(0.0)
	_prev_grab = _grab_pos

func _build_visual() -> void:
	_rope = Line2D.new()
	_rope.width = 6.0
	_rope.default_color = Color(0.34, 0.30, 0.12, 1.0)
	_rope.joint_mode = Line2D.LINE_JOINT_ROUND
	_rope.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_rope.end_cap_mode = Line2D.LINE_CAP_ROUND
	_rope.z_index = -1
	add_child(_rope)

	# Bladpluk aan het uiteinde, zodat duidelijk is waar je moet grijpen.
	_leaf = Polygon2D.new()
	_leaf.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(15, -5), Vector2(19, 11), Vector2(7, 21),
		Vector2(-7, 21), Vector2(-19, 11), Vector2(-15, -5),
	])
	_leaf.color = Color(0.30, 0.58, 0.24, 1.0)
	add_child(_leaf)

	_grab_area = Area2D.new()
	_grab_area.collision_layer = 0
	_grab_area.collision_mask = 2  # alleen de spelerlaag
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = GRAB_RADIUS
	capsule.height = maxf(length * GRAB_SPAN, GRAB_RADIUS * 2.0)
	shape.shape = capsule
	_grab_area.add_child(shape)
	add_child(_grab_area)
	_grab_area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_update_swing(delta)

func _update_swing(delta: float) -> void:
	_t += delta
	var omega := TAU / maxf(period, 0.2)
	_angle = deg_to_rad(_amplitude) * sin(_t * omega)
	_grab_pos = global_position + Vector2(sin(_angle), cos(_angle)) * length
	if delta > 0.0:
		_tip_velocity = (_grab_pos - _prev_grab) / delta
	_prev_grab = _grab_pos

	var dir := Vector2(sin(_angle), cos(_angle))
	var local_tip := dir * length
	_rope.points = PackedVector2Array([Vector2.ZERO, local_tip])
	_leaf.position = local_tip
	_leaf.rotation = -_angle
	# De grijpzone ligt langs de onderste helft van het touw en draait mee.
	_grab_area.position = dir * (length - length * GRAB_SPAN * 0.5)
	_grab_area.rotation = -_angle

## Wereldpositie van het grijppunt (waar de handen van de speler zitten).
func get_grab_position() -> Vector2:
	return _grab_pos

## Baansnelheid van de punt — die krijgt de speler mee als hij loslaat.
func get_tip_velocity() -> Vector2:
	return _tip_velocity

## Pompen zoals op een schommel: meebewegen met de richting van de punt maakt
## de zwaai groter, tegenwerken remt hem af.
func pump(direction: float, delta: float) -> void:
	if direction == 0.0:
		return
	var moving := signf(_tip_velocity.x)
	var gain := PUMP_PER_SECOND * delta
	if moving == 0.0 or signf(direction) == moving:
		_amplitude = minf(_amplitude + gain, MAX_AMPLITUDE)
	else:
		_amplitude = maxf(_amplitude - gain, MIN_AMPLITUDE)

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player != null:
		player.grab_vine(self)
