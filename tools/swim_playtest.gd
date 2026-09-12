extends Node

## Headless zwem-regressietest voor W2L1 (eilanden + zee). Twee scenario's:
##  1. Vanaf het starteiland de pilaren-zee in, aan de overkant weer op het
##     eiland klimmen (alleen rechts duwen + af en toe een slag omhoog).
##  2. De poorten-zee (duik-/stijgpoorten, mijnen, jager) oversteken met een
##     simpel "zit ik vast → wissel tussen duiken en stijgen"-beleid.
## Print per halve seconde state/positie. Start:
##   Godot --headless --path . res://tools/SwimPlaytest.tscn --quit-after 4000
## Exitcode 0 = beide overkanten gehaald, 1 = niet.

var _player: Node2D
var _fail := false

func _ready() -> void:
	_run()

func _run() -> void:
	var level: Node = (load("res://scenes/levels/world2/W2L1.tscn") as PackedScene).instantiate()
	add_child(level)
	await get_tree().create_timer(0.5).timeout
	_player = level.get_node("Player")
	# Zeeën afleiden uit het terrein: kolommen zonder rots op rij 19 (eilandtop).
	# Een eiland heeft rots op rij 19 én op rij 35 (rotsen die uit het water
	# steken reiken niet tot de bodem en tellen dus niet als eiland).
	var top_cols: Dictionary = {}
	var deep_cols: Dictionary = {}
	var island_cols: Dictionary = {}
	var max_x := 0
	for r: Rect2i in level.get_node("Terrain").solid_rects:
		for x in range(r.position.x, r.end.x):
			if r.position.y <= 19 and r.end.y > 19:
				top_cols[x] = true
			if r.position.y <= 35 and r.end.y > 35:
				deep_cols[x] = true
		max_x = maxi(max_x, r.end.x)
	for x in top_cols:
		if deep_cols.has(x):
			island_cols[x] = true
	var seas: Array = []
	var run_start := -1
	for x in range(0, max_x + 1):
		var is_sea: bool = not island_cols.has(x) and x < max_x
		if is_sea and run_start < 0:
			run_start = x
		elif not is_sea and run_start >= 0:
			seas.append([run_start * 32, x * 32])
			run_start = -1
	print("zeeën: ", seas)

	await _cross(seas[0], "pilaren", 20.0)
	await _cross(seas[1], "poorten", 45.0)

	print("RESULTAAT: %s" % ("GELUKT" if not _fail else "MISLUKT"))
	get_tree().quit(1 if _fail else 0)

func _cross(sea: Array, label: String, max_time: float) -> void:
	var x0: float = sea[0]
	var x1: float = sea[1]
	_player.global_position = Vector2(x0 - 60.0, 608.0)
	_player.velocity = Vector2.ZERO
	_player.grant_spawn_invincibility(0.5)
	Input.action_press("move_right")
	var t := 0.0
	var last_x: float = _player.global_position.x
	var last_y: float = _player.global_position.y
	var last_hp: int = _player.health
	var diving := false
	var stall := 0
	while t < max_time:
		# Slag omhoog tenzij we bewust duiken.
		if not diving:
			Input.action_press("jump")
			await get_tree().process_frame
			await get_tree().process_frame
			Input.action_release("jump")
		await get_tree().create_timer(0.45).timeout
		t += 0.5
		var px: float = _player.global_position.x
		_report("%s t=%.1f%s" % [label, t, " duik" if diving else ""])
		# Reflex: net geraakt → terugslaan (piranha's gaan in één klap, de jager in twee).
		if _player.health < last_hp:
			Input.action_press("punch")
			await get_tree().process_frame
			Input.action_release("punch")
		last_hp = _player.health
		if _player.state == 8:  # DEAD
			print("  → speler dood in zee '%s'" % label)
			_fail = true
			break
		if px > x1 + 40.0 and _player.is_on_floor() and _player.global_position.y <= 609.0:
			print("  → overkant van zee '%s' gehaald na %.1fs" % [label, t])
			break
		# Geen vooruitgang meer? Dan van tactiek wisselen: aan het oppervlak →
		# gaan duiken (omlaag houden); al duikend tot op de bodem/tegen rots
		# zonder vooruitgang → weer omhoog met slagen.
		var py: float = _player.global_position.y
		if px - last_x < 20.0:
			stall += 1
		else:
			stall = 0
		# Alleen op de uitersten wisselen: aan het oppervlak vast → duiken; op de
		# bodem vast → stijgen. Onderweg (tegen een wand) volhouden.
		if not diving and stall >= 2 and py < 700.0:
			diving = true
			Input.action_press("move_down")
			stall = 0
		elif diving and stall >= 2 and _player.is_on_floor():
			diving = false
			Input.action_release("move_down")
			stall = 0
		last_x = px
		last_y = py
	Input.action_release("move_right")
	Input.action_release("move_down")
	if t >= max_time:
		print("  → tijd op in zee '%s'" % label)
		_fail = true
	await get_tree().create_timer(0.3).timeout

func _report(label: String) -> void:
	print("%-22s state=%d pos=(%.0f, %.0f) vel=(%.0f, %.0f) floor=%s hp=%d" % [
		label, _player.state, _player.global_position.x, _player.global_position.y,
		_player.velocity.x, _player.velocity.y, _player.is_on_floor(), _player.health])
