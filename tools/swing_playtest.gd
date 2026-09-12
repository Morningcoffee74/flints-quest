extends Node

## Headless regressietest voor de twee nieuwe Wereld 4-mechanieken, op
## scenes/levels/W4_JungleTest.tscn:
##  1. SLINGEREN: een gat van ~900px met drie lianen erboven oversteken. De bot
##     loopt naar rechts, springt het gat in, grijpt de liaan die hem raakt, en
##     laat los zodra de punt naar rechts beweegt én bijna op zijn uiterste
##     staat — dat is precies het moment waarop je het verst komt.
##  2. DRIJFZAND: een zandkuil oversteken door te blijven springen, zonder
##     kopje-onder te gaan.
##
## Start: Godot --headless --path . res://tools/SwingPlaytest.tscn --quit-after 6000
## Exitcode 0 = allebei gehaald, 1 = niet.

const SWING := 10   # Player.State.SWING
const DEAD := 8     # Player.State.DEAD

var _player: Node2D
var _level: Node
var _fail := false

func _ready() -> void:
	_run()

func _run() -> void:
	_level = (load("res://scenes/levels/W4_JungleTest.tscn") as PackedScene).instantiate()
	add_child(_level)
	await get_tree().create_timer(0.5).timeout
	_player = _level.get_node("Player")

	await _swing_across()
	await _wade_across()
	await _drown_check()

	print("RESULTAAT: %s" % ("GELUKT" if not _fail else "MISLUKT"))
	get_tree().quit(1 if _fail else 0)

## Van de linkeroever (x≈300) naar de middelste oever (x≈1500) via drie lianen.
func _swing_across() -> void:
	_player.global_position = Vector2(420.0, 600.0)
	_player.velocity = Vector2.ZERO
	_player.grant_spawn_invincibility(1.0)
	await get_tree().create_timer(0.3).timeout

	Input.action_press("move_right")
	var t := 0.0
	var jumped := false
	var best_x: float = _player.global_position.x
	while t < 40.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		var px: float = _player.global_position.x
		best_x = maxf(best_x, px)

		if _player.state == DEAD:
			print("  → speler dood tijdens het slingeren")
			_fail = true
			break

		# Aanloopsprong zodat hij de eerste liaan op hoogte raakt.
		if not jumped and px > 560.0 and _player.is_on_floor():
			_tap("jump")
			jumped = true

		if int(t * 2.0) != int((t - get_physics_process_delta_time()) * 2.0):
			print("  t=%.1f x=%.0f y=%.0f state=%d floor=%s" % [
				t, px, _player.global_position.y, _player.state, _player.is_on_floor()])

		if _player.state == SWING:
			var vine: Node = _player.get("_vine")
			if vine != null:
				var tip: Vector2 = vine.call("get_tip_velocity")
				# Loslaten op de OPGAANDE zwaai naar rechts (punt beweegt naar
				# rechts én omhoog). Onderaan loslaten geeft wel vaart maar geen
				# hoogte, en dan zak je onder de volgende liaan door.
				if tip.x > 120.0 and tip.y < -60.0:
					_tap("jump")
		elif _player.is_on_floor() and px > 1290.0:
			print("  → overkant gehaald na %.1fs (x=%.0f)" % [t, px])
			break
		# In het gat gevallen: opnieuw beginnen vanaf de startoever, zodat één
		# misser de test niet ophangt.
		if _player.global_position.y > 1100.0:
			_player.global_position = Vector2(420.0, 620.0)
			_player.velocity = Vector2.ZERO
			jumped = false
			await get_tree().create_timer(0.2).timeout
	Input.action_release("move_right")
	if t >= 40.0:
		print("  → tijd op tijdens het slingeren (verst: x=%.0f, nodig: 1290)" % best_x)
		_fail = true
	await get_tree().create_timer(0.3).timeout

## Door de drijfzandkuil bij x≈2000 naar de oever erachter.
func _wade_across() -> void:
	_player.global_position = Vector2(1700.0, 600.0)
	_player.velocity = Vector2.ZERO
	_player.grant_spawn_invincibility(1.0)
	var hp0: int = _player.health
	await get_tree().create_timer(0.3).timeout

	Input.action_press("move_right")
	var t := 0.0
	var best_x: float = _player.global_position.x
	while t < 30.0:
		# Blijven spartelen: elke ~0.35s een sprong.
		_tap("jump")
		await get_tree().create_timer(0.35).timeout
		t += 0.35
		var px: float = _player.global_position.x
		best_x = maxf(best_x, px)
		if _player.state == DEAD:
			print("  → speler dood in het drijfzand")
			_fail = true
			break
		if px > 2300.0:
			print("  → drijfzand doorwaad na %.1fs (hartjes: %d → %d)" % [t, hp0, _player.health])
			break
	Input.action_release("move_right")
	if t >= 30.0:
		print("  → tijd op in het drijfzand (verst: x=%.0f, nodig: 2300)" % best_x)
		_fail = true

## Eén druk op een knop. Twee physics-frames vasthouden: bij één frame valt de
## druk soms tussen twee stappen in en ziet de speler hem nooit.
func _tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)

## Wie in het drijfzand blijft staan, moet kopje-onder gaan: een hartje kwijt.
## Zo blijft het gevaar echt een gevaar en niet alleen vertraging.
func _drown_check() -> void:
	_player.global_position = Vector2(2000.0, 620.0)
	_player.velocity = Vector2.ZERO
	_player.health = 5
	_player.grant_spawn_invincibility(0.0)
	await get_tree().create_timer(0.2).timeout
	var hp0: int = _player.health
	var t := 0.0
	while t < 12.0:
		await get_tree().create_timer(0.25).timeout
		t += 0.25
		if _player.health < hp0:
			print("  → stilstaan in drijfzand kost een hartje na %.1fs (%d → %d)" % [
				t, hp0, _player.health])
			return
	print("  → stilstaan in drijfzand deed NIETS (y=%.0f) — verdrinken werkt niet" % _player.global_position.y)
	_fail = true
