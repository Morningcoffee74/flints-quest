extends Control

@onready var _music_slider: HSlider        = $VBox/MusicRow/MusicSlider
@onready var _music_mute:   CheckBox       = $VBox/MusicRow/MusicMute
@onready var _sfx_slider:   HSlider        = $VBox/SfxRow/SfxSlider
@onready var _sfx_mute:     CheckBox       = $VBox/SfxRow/SfxMute
@onready var _profile_list: VBoxContainer  = $VBox/ProfileList
@onready var _back_btn:     Button         = $VBox/BackButton

var _confirm1: ConfirmationDialog
var _confirm2: ConfirmationDialog
var _pending_delete: String = ""

func _ready() -> void:
	_back_btn.pressed.connect(GameManager.go_to_main_menu)

	_music_slider.value = AudioManager.get_bus_volume("Music")
	_music_mute.button_pressed = AudioManager.get_bus_mute("Music")
	_sfx_slider.value = AudioManager.get_bus_volume("SFX")
	_sfx_mute.button_pressed = AudioManager.get_bus_mute("SFX")

	_music_slider.value_changed.connect(func(v: float) -> void: AudioManager.set_bus_volume("Music", v))
	_music_mute.toggled.connect(func(p: bool) -> void: AudioManager.set_bus_mute("Music", p))
	_sfx_slider.value_changed.connect(func(v: float) -> void: AudioManager.set_bus_volume("SFX", v))
	_sfx_mute.toggled.connect(func(p: bool) -> void: AudioManager.set_bus_mute("SFX", p))

	_confirm1 = ConfirmationDialog.new()
	_confirm1.confirmed.connect(_on_delete_confirm1)
	add_child(_confirm1)
	_confirm2 = ConfirmationDialog.new()
	_confirm2.confirmed.connect(_on_delete_confirm2)
	add_child(_confirm2)

	_refresh_profiles()

func _refresh_profiles() -> void:
	for child in _profile_list.get_children():
		child.queue_free()
	for pname in SaveSystem.get_profiles():
		_profile_list.add_child(_build_profile_row(pname))

func _build_profile_row(pname: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_edit := LineEdit.new()
	name_edit.text = pname
	name_edit.max_length = 20
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_edit)

	var rename_btn := Button.new()
	rename_btn.text = "Hernoem"
	rename_btn.pressed.connect(_on_rename_pressed.bind(pname, name_edit))
	row.add_child(rename_btn)

	var delete_btn := Button.new()
	delete_btn.text = "Verwijder"
	delete_btn.pressed.connect(_on_delete_pressed.bind(pname))
	row.add_child(delete_btn)
	return row

func _on_rename_pressed(old_name: String, name_edit: LineEdit) -> void:
	var new_name := name_edit.text.strip_edges()
	if new_name.length() < 1 or new_name.length() > 20:
		return
	if not SaveSystem.rename_profile(old_name, new_name):
		return
	if GameManager.current_profile == old_name:
		GameManager.current_profile = new_name
	_refresh_profiles()

func _on_delete_pressed(pname: String) -> void:
	_pending_delete = pname
	_confirm1.dialog_text = "Wil je '%s' echt weghalen, weet je het zeker?" % pname
	_confirm1.popup_centered()

func _on_delete_confirm1() -> void:
	_confirm2.dialog_text = "Weet je het heel heel heel heeeeeeeel erg echt zeker?"
	_confirm2.popup_centered()

func _on_delete_confirm2() -> void:
	SaveSystem.delete_profile(_pending_delete)
	if GameManager.current_profile == _pending_delete:
		GameManager.current_profile = ""
		GameManager.profile_data = {}
	_pending_delete = ""
	_refresh_profiles()
