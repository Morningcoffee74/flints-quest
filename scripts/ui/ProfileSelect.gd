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
		var row := HBoxContainer.new()
		var play_btn := Button.new()
		play_btn.text = pname
		play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play_btn.pressed.connect(_on_profile_selected.bind(pname))
		var del_btn := Button.new()
		del_btn.text = "X"
		del_btn.custom_minimum_size = Vector2(36, 0)
		del_btn.pressed.connect(_on_delete_pressed.bind(pname))
		row.add_child(play_btn)
		row.add_child(del_btn)
		_profile_list.add_child(row)

func _on_create_pressed() -> void:
	var pname := _name_input.text.strip_edges()
	if pname.length() < 1 or pname.length() > 20:
		_error_label.text = "Naam moet 1–20 tekens zijn."
		return
	if SaveSystem.profile_exists(pname):
		_error_label.text = "Profiel '%s' bestaat al." % pname
		return
	GameManager.create_profile(pname)
	GameManager.go_to_world_map()

func _on_profile_selected(profile_name: String) -> void:
	GameManager.load_profile(profile_name)
	GameManager.go_to_world_map()

func _on_delete_pressed(profile_name: String) -> void:
	SaveSystem.delete_profile(profile_name)
	_refresh_profiles()
