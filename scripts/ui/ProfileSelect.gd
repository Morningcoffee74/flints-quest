extends Control

@onready var _name_input:    LineEdit        = $VBox/NameRow/NameInput
@onready var _create_btn:    Button          = $VBox/NameRow/CreateButton
@onready var _error_label:   Label           = $VBox/ErrorLabel
@onready var _profile_list:  VBoxContainer   = $VBox/ProfileList
@onready var _back_btn:      Button          = $VBox/BackButton

func _ready() -> void:
	_create_btn.pressed.connect(_on_create_pressed)
	_back_btn.pressed.connect(GameManager.go_to_main_menu)
	_refresh_profiles()
	AudioManager.play_music_by_name("menu")

func _refresh_profiles() -> void:
	for child in _profile_list.get_children():
		child.queue_free()

	var profiles := SaveSystem.get_profiles()
	if profiles.is_empty():
		var lbl := Label.new()
		lbl.text = "Nog geen profielen."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_profile_list.add_child(lbl)
		return

	for pname in profiles:
		var play_btn := Button.new()
		play_btn.text = "%s   (%s)" % [pname, _summarize_progress(pname)]
		play_btn.pressed.connect(_on_profile_selected.bind(pname))
		_profile_list.add_child(play_btn)

## Hoogst bereikte wereld/level + totaalscore, voor het profieloverzicht.
func _summarize_progress(pname: String) -> String:
	var data := SaveSystem.load_profile(pname)
	if data.is_empty():
		return "nog niet gespeeld"
	var best_world := 1
	var best_level := 0
	for w in range(1, 11):
		var wdata: Dictionary = data.get("worlds", {}).get(str(w), {})
		var levels: Dictionary = wdata.get("levels", {})
		for lkey: String in levels:
			if levels[lkey].get("completed", false):
				var l := lkey.to_int()
				if w > best_world or (w == best_world and l > best_level):
					best_world = w
					best_level = l
	var score: int = data.get("total_score", 0)
	if best_level == 0:
		return "score %d" % score
	return "wereld %d level %d · score %d" % [best_world, best_level, score]

func _on_create_pressed() -> void:
	var pname := _name_input.text.strip_edges()
	if pname.length() < 1 or pname.length() > 20:
		_error_label.text = "Naam moet 1–20 tekens zijn."
		return
	if SaveSystem.profile_exists(pname):
		_error_label.text = "Profiel '%s' bestaat al." % pname
		return
	GameManager.create_profile(pname)
	GameManager.go_to_world_select()

func _on_profile_selected(profile_name: String) -> void:
	GameManager.load_profile(profile_name)
	GameManager.go_to_world_select()
