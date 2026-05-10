extends Node

var current_profile: String = ""
var current_world: int = 1
var current_level: int = 1
var profile_data: Dictionary = {}

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

func _new_profile(pname: String) -> Dictionary:
	var data: Dictionary = {"name": pname, "total_score": 0, "worlds": {}}
	for w in range(1, 11):
		var world_levels: Dictionary = {}
		for l in range(1, 11):
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
	if profile_data.is_empty():
		return false
	return profile_data["worlds"][str(world)]["levels"][str(level)].get("completed", false)

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
	if not is_level_completed(prev, 10):
		return false
	var count := 0
	for l in range(1, 11):
		if is_level_completed(prev, l):
			count += 1
	return count >= 9

func get_level_highscore(world: int, level: int) -> int:
	if profile_data.is_empty():
		return 0
	return profile_data["worlds"][str(world)]["levels"][str(level)].get("highscore", 0)

func go_to_level(world: int, level: int) -> void:
	current_world = world
	current_level = level
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/world%d/W%dL%d.tscn" % [world, world, level])

func go_to_world_map() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/WorldMap.tscn")

func go_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
