extends Node

var current_profile: String = ""
var current_world: int = 1
var current_level: int = 1

func _ready() -> void:
	_register_input_actions()

func _register_input_actions() -> void:
	var actions: Dictionary = {
		"move_left":  [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump":       [KEY_SPACE, KEY_Z],
		"punch":      [KEY_X, KEY_ENTER],
		"pause":      [KEY_ESCAPE],
	}
	for action: String in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for keycode: int in actions[action]:
				var event := InputEventKey.new()
				event.physical_keycode = keycode
				InputMap.action_add_event(action, event)
