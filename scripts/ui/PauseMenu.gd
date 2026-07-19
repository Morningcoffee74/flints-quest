extends CanvasLayer

@onready var _dimmer: ColorRect = $Dimmer
@onready var _panel:  Panel      = $Panel
@onready var _resume_btn:  Button = $Panel/VBox/ResumeButton
@onready var _restart_btn: Button = $Panel/VBox/RestartButton
@onready var _help_btn:    Button = $Panel/VBox/HelpButton
@onready var _menu_btn:    Button = $Panel/VBox/MainMenuButton

## De Uitleg-overlay die bovenop het (nog altijd gepauzeerde) spel getoond wordt
## als de speler in het pauzemenu op 'Uitleg' drukt. null = niet open.
var _help_overlay: Control = null

func _ready() -> void:
	_resume_btn.pressed.connect(_on_resume)
	_restart_btn.pressed.connect(_on_restart)
	_help_btn.pressed.connect(_on_help)
	_menu_btn.pressed.connect(_on_main_menu)

## Toont het pauzemenu en pauzeert het spel. Zet meteen de gamepad-focus op
## 'Verder spelen' zodat de controller kan navigeren.
func open() -> void:
	show()
	_dimmer.visible = true
	_panel.visible = true
	get_tree().paused = true
	_resume_btn.grab_focus.call_deferred()

## Verbergt het pauzemenu (incl. een eventueel open Uitleg-scherm) en hervat.
func close() -> void:
	_close_help()
	hide()
	get_tree().paused = false

## Zodat LevelBase weet dat de +/pauze-knop nu het Uitleg-scherm moet negeren
## i.p.v. het hele pauzemenu weg te klikken.
func is_help_open() -> bool:
	return _help_overlay != null

func _on_resume() -> void:
	close()

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

## Toont de bestaande Help-scene als overlay bovenop het gepauzeerde spel, zodat
## de speler daarna gewoon verder kan spelen (i.p.v. een scene-wissel die het
## level zou weggooien). Het pauze-paneel gaat zolang verborgen.
func _on_help() -> void:
	if _help_overlay != null:
		return
	var packed: PackedScene = load("res://scenes/ui/Help.tscn")
	if packed == null:
		return
	_help_overlay = packed.instantiate() as Control
	if _help_overlay == null:
		return
	_help_overlay.process_mode = Node.PROCESS_MODE_ALWAYS  # blijft werken tijdens de pauze
	_help_overlay.set("overlay_mode", true)                # Help._ready leest dit
	_help_overlay.connect("overlay_closed", _close_help)
	_dimmer.visible = false
	_panel.visible = false
	add_child(_help_overlay)

func _close_help() -> void:
	if _help_overlay != null:
		_help_overlay.queue_free()
		_help_overlay = null
	_dimmer.visible = true
	_panel.visible = true
	_resume_btn.grab_focus.call_deferred()

func _on_main_menu() -> void:
	GameManager.go_to_main_menu()
