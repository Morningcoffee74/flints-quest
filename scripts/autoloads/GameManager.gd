extends Node

const LIVES_PER_LEVEL: int = 3

var current_profile: String = ""
var current_world: int = 1
var current_level: int = 1
var profile_data: Dictionary = {}
var lives: int = LIVES_PER_LEVEL
var respawn_point: Vector2 = Vector2.INF  # INF = geen checkpoint bereikt

func _ready() -> void:
	_register_input_actions()

func _register_input_actions() -> void:
	var actions: Dictionary = {
		"move_left":  [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up":    [KEY_W, KEY_UP],
		"move_down":  [KEY_S, KEY_DOWN],
		"jump":       [KEY_SPACE, KEY_Z],
		"punch":      [KEY_X, KEY_ENTER],
		"pause":      [KEY_ESCAPE],
	}
	for action: String in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for keycode: int in actions[action]:
				var event := InputEventKey.new()
				event.physical_keycode = keycode as Key
				InputMap.action_add_event(action, event)
	_register_gamepad_events()

## Bluetooth-gamepads (bv. 8BitDo) melden zich bij Godot als een generieke
## Xinput-achtige joypad, dus D-pad/linker-stick en de standaard face buttons
## werken hiermee zonder dat de speler zelf iets hoeft in te stellen.
func _register_gamepad_events() -> void:
	# Knop-indeling volgt de fysieke posities van een Nintendo-stijl 8BitDo
	# (SDL mapt op positie, niet op het opschrift):
	#   bovenste knop "X" = JOY_BUTTON_Y (noord)  -> springen
	#   rechter  knop "A" = JOY_BUTTON_B (oost)   -> slaan
	#   linker   knop "Y" = JOY_BUTTON_X (west)   -> slaan (klassieke aanvalsknop)
	# Slaan zit dus op beide zijknoppen; de onderste knop (JOY_BUTTON_A) blijft
	# vrij in het spel maar bevestigt nog wél in menu's (zie ui_accept).
	var button_actions: Dictionary = {
		"move_left":  [JOY_BUTTON_DPAD_LEFT],
		"move_right": [JOY_BUTTON_DPAD_RIGHT],
		"move_up":    [JOY_BUTTON_DPAD_UP],
		"move_down":  [JOY_BUTTON_DPAD_DOWN],
		"jump":       [JOY_BUTTON_Y],
		"punch":      [JOY_BUTTON_B, JOY_BUTTON_X],
		"pause":      [JOY_BUTTON_START],
	}
	for action: String in button_actions:
		for button: int in button_actions[action]:
			var button_event := InputEventJoypadButton.new()
			button_event.button_index = button as JoyButton
			InputMap.action_add_event(action, button_event)

	var stick_axes: Dictionary = {
		"move_left":  [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up":    [JOY_AXIS_LEFT_Y, -1.0],
		"move_down":  [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action: String in stick_axes:
		var motion_event := InputEventJoypadMotion.new()
		motion_event.axis = stick_axes[action][0]
		motion_event.axis_value = stick_axes[action][1]
		InputMap.action_add_event(action, motion_event)
	for action: String in stick_axes:
		InputMap.action_set_deadzone(action, 0.4)
	_register_ui_gamepad_events()

## Godot's ingebouwde menu-acties `ui_accept` (aanklikken) en `ui_cancel` (terug)
## hebben standaard ALLEEN toetsenbord-events (Enter/Spatie/Escape) en geen
## joypad-knop — terwijl `ui_up/down/left/right` wél een D-pad-binding hebben.
## Daardoor kon je met de controller wel door een menu navigeren maar niets
## bevestigen. We voegen hier de face buttons toe. Zowel de onderste (A/0) als
## de rechter (B/1) knop bevestigt, zodat het werkt ongeacht of de 8BitDo in
## Switch- of XInput-modus staat (die twee wisselen de fysieke A/B-knoppen om).
func _register_ui_gamepad_events() -> void:
	for button: int in [JOY_BUTTON_A, JOY_BUTTON_B]:
		if not _action_has_joy_button("ui_accept", button):
			var event := InputEventJoypadButton.new()
			event.button_index = button as JoyButton
			InputMap.action_add_event("ui_accept", event)

func _action_has_joy_button(action: String, button: int) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button:
			return true
	return false

func create_profile(profile_name: String) -> void:
	profile_data = _new_profile(profile_name)
	current_profile = profile_name
	SaveSystem.save_profile(profile_name, profile_data)

func load_profile(profile_name: String) -> void:
	current_profile = profile_name
	profile_data = SaveSystem.load_profile(profile_name)
	if profile_data.is_empty():
		profile_data = _new_profile(profile_name)
		SaveSystem.save_profile(profile_name, profile_data)
	elif _migrate_profile():
		SaveSystem.save_profile(profile_name, profile_data)

## Vult ontbrekende wereld/level-entries aan bij oudere profielen — bv. van
## vóór een wereld meer levels kreeg dan de oorspronkelijke 10 (zie
## WorldConfig.WORLDS[*]["levels"]). Zonder dit crasht is_level_completed()
## op profielen die van vóór die uitbreiding dateren. Geeft true terug als er
## iets is aangevuld, zodat de aanroeper weet of opslaan nodig is.
func _migrate_profile() -> bool:
	var changed := false
	if not profile_data.has("worlds"):
		profile_data["worlds"] = {}
		changed = true
	for w in range(1, 11):
		var wkey := str(w)
		if not profile_data["worlds"].has(wkey):
			profile_data["worlds"][wkey] = {"levels": {}}
			changed = true
		var wdata: Dictionary = profile_data["worlds"][wkey]
		if not wdata.has("levels"):
			wdata["levels"] = {}
			changed = true
		var levels: Dictionary = wdata["levels"]
		var level_count: int = WorldConfig.WORLDS[w - 1]["levels"]
		for l in range(1, level_count + 1):
			var lkey := str(l)
			if not levels.has(lkey):
				levels[lkey] = {"completed": false, "highscore": 0}
				changed = true
	return changed

func _new_profile(pname: String) -> Dictionary:
	var data: Dictionary = {"name": pname, "total_score": 0, "worlds": {}}
	for w in range(1, 11):
		var world_levels: Dictionary = {}
		var level_count: int = WorldConfig.WORLDS[w - 1]["levels"]
		for l in range(1, level_count + 1):
			world_levels[str(l)] = {"completed": false, "highscore": 0}
		data["worlds"][str(w)] = {"levels": world_levels}
	return data

func complete_level(world: int, level: int, score: int) -> void:
	if profile_data.is_empty():
		return
	var ldata: Dictionary = profile_data["worlds"][str(world)]["levels"][str(level)]
	ldata["completed"] = true
	if score > ldata.get("highscore", 0):
		ldata["highscore"] = score
	profile_data["total_score"] = profile_data.get("total_score", 0) + score
	SaveSystem.save_profile(current_profile, profile_data)

func is_level_completed(world: int, level: int) -> bool:
	return _level_data(world, level).get("completed", false)

func is_level_unlocked(world: int, level: int) -> bool:
	if not is_world_unlocked(world):
		return false
	if level == 1:
		return true
	# Unlocked when all previous levels done, OR 1 skip allowed (but not level 10)
	var completed := 0
	for l in range(1, level):
		if is_level_completed(world, l):
			completed += 1
	return completed >= level - 2

func is_world_unlocked(world: int) -> bool:
	if world == 1:
		return true
	if profile_data.is_empty():
		return false
	var prev := world - 1
	var prev_levels: int = WorldConfig.WORLDS[prev - 1]["levels"]
	if not is_level_completed(prev, prev_levels):
		return false
	var count := 0
	for l in range(1, prev_levels + 1):
		if is_level_completed(prev, l):
			count += 1
	return count >= prev_levels - 1

func get_level_highscore(world: int, level: int) -> int:
	return _level_data(world, level).get("highscore", 0)

## Veilige toegang tot profile_data["worlds"][w]["levels"][l], ook als die
## sleutel (nog) niet bestaat (bv. een ouder profiel dat nog niet is
## gemigreerd) — voorkomt een crash i.p.v. een lege Dictionary terug te geven.
func _level_data(world: int, level: int) -> Dictionary:
	if profile_data.is_empty():
		return {}
	var wdata: Dictionary = profile_data.get("worlds", {}).get(str(world), {})
	return wdata.get("levels", {}).get(str(level), {})

func go_to_level(world: int, level: int) -> void:
	current_world = world
	current_level = level
	lives = LIVES_PER_LEVEL
	respawn_point = Vector2.INF
	ScoreManager.reset_level()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/world%d/W%dL%d.tscn" % [world, world, level])

## Trekt een leven af; geeft het resterende aantal terug.
func lose_life() -> int:
	lives -= 1
	return lives

func go_to_world_map(world: int = current_world) -> void:
	current_world = world
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/WorldMap.tscn")

func go_to_world_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/WorldSelect.tscn")

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

## Samengestelde snelheidsopbouw: elke wereld begint 10% hoger dan de vorige,
## en elk level binnen een wereld draagt ook 10% bij (i.p.v. per-wereld te
## resetten), tot een plafond van 2x de basissnelheid.
func get_speed_difficulty() -> float:
	return minf(2.0, pow(1.1, (current_world - 1) + (current_level - 1)))
