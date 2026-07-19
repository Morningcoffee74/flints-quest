extends Control

const ICON_STAR:   Texture2D = preload("res://assets/sprites/items/extra-life.png")
const ICON_SPEED:  Texture2D = preload("res://assets/sprites/items/extra-speed.png")
const ICON_STRONG: Texture2D = preload("res://assets/sprites/items/extra-strong.png")

## Zelfde iconen/tinten als de HUD-power-up-balkjes (scripts/ui/HUD.gd:10-14),
## zodat de uitleg klopt met wat je tijdens het spelen ziet.
const POWERUP_INFO: Array[Dictionary] = [
	{"icon": ICON_STAR,   "tint": Color(0.75, 0.4, 1.0),  "title": "Paars",  "desc": "tijdelijk onkwetsbaar voor vijanden"},
	{"icon": ICON_SPEED,  "tint": Color(0.25, 0.65, 1.0), "title": "Blauw",  "desc": "flink sneller lopen"},
	{"icon": ICON_STRONG, "tint": Color(1.0, 0.55, 0.15), "title": "Oranje", "desc": "harder slaan (verslaat gewone vijanden in één klap, en doet extra schade aan een eindbaas)"},
]

const HELP_TEXT_1 := """[center][font_size=30]Speluitleg[/font_size][/center]

[font_size=20]Flint en zijn avontuur[/font_size]
Flint is een dappere jongen van 12 jaar die nergens bang voor is. Hij is ontvoerd door een vuurmonster en moet nu, ver van huis, zijn weg terugvinden. Onderweg trekt hij door 10 heel verschillende werelden, van een rustig bos tot een gloeiende vulkaan, om uiteindelijk het vuurmonster te verslaan en eindelijk weer thuis te komen.

[font_size=20]Doel van elk level[/font_size]
Elk level eindigt bij een houten huisje. Loop naar dat houten huisje om het level te voltooien. In latere levels moet je eerst genoeg munten verzamelen en/of genoeg vijanden verslaan voordat het houten huisje opengaat — je ziet de voortgang daarvan bovenin het scherm tijdens het spelen. Onderweg vind je ook checkpoints: kom je daarna te overlijden, dan begin je vanaf dat punt opnieuw in plaats van helemaal bij het begin.

[font_size=20]Gezondheid en levens[/font_size]
Flint heeft een goed hart — letterlijk: hij heeft 5 hartjes, en hoe beter hij daarop past, hoe dichter hij bij huis komt. Raakt een vijand hem aan, val je in een ravijn of loop je tegen stekels aan, dan gaat er een hartje af. Elke 10 verzamelde munten geeft je 1 hartje terug (tot een maximum van 5). Zijn alle hartjes op, dan verlies je een leven — je begint met 3 levens per poging aan een level. Zijn ook je levens op, dan is het game over en begin je het level opnieuw. Goed op zijn hartjes passen is niet alleen slim gespeeld — het is ook een beetje hoe Flint onderweg opgroeit tot een echte man: iemand die goed voor zichzelf en voor anderen zorgt.

[font_size=20]Besturing[/font_size]
[table=2]
[cell]Links / rechts[/cell][cell]A/D, pijltjestoetsen, D-pad of linker-stick — lopen[/cell]
[cell]Omhoog[/cell][cell]W, ↑, D-pad omhoog of linker-stick — een ladder beklimmen[/cell]
[cell]Omlaag[/cell][cell]S, ↓, D-pad omlaag of linker-stick — bukken (ontwijk duikende vleermuizen) of een ladder afdalen[/cell]
[cell]Springen[/cell][cell]Spatie, Z of A-knop (gamepad)[/cell]
[cell]Boksen[/cell][cell]X, Enter of X-knop (gamepad)[/cell]
[cell]Pauze[/cell][cell]Escape of de +-knop / Start-knop (gamepad)[/cell]
[/table]
Een Bluetooth-gamepad zoals een 8BitDo-controller werkt ook: verbind hem voordat je het spel start, dan werken de knoppen hierboven automatisch mee.

[font_size=20]Vijanden verslaan[/font_size]
De meeste vijanden versla je door er bovenop te springen, of door ze te boksen. Let op: sommige vijanden (zoals de slang) zijn ongevoelig voor een sprong op hun kop — die moet je boksen om te verslaan. Raakt een vijand jóu aan zonder dat je hem net verslaat, dan kost dat een hartje. Aan het einde van elke wereld (level 10) wacht een extra grote eindbaas.

[font_size=20]De 10 werelden[/font_size]
Elke wereld heeft een eigen thema, eigen vijanden en eigen muziek. Wereld 1 (het Bos) heeft bijvoorbeeld ratten, slangen en vleermuizen als vijanden. De werelden zijn in deze volgorde:
1. Bos  2. Water  3. Grot  4. Jungle  5. Lucht
6. Palmstrand  7. IJsberg  8. Woestijn  9. Snoepland  10. Vulkaan (met het vuurmonster als eindbaas)

Een wereld gaat pas open als je bijna alle levels van de vorige wereld hebt uitgespeeld (je mag er 1 overslaan, behalve het allerlaatste level van een wereld). Uitgespeelde levels en werelden mag je altijd opnieuw spelen.

[font_size=20]Power-ups[/font_size]
Tijdens het spelen kom je gekleurde power-up-blokjes tegen. Elke boost duurt 14 seconden, met een afteltimer in beeld:"""

const HELP_TEXT_2 := """[font_size=20]Punten[/font_size]
Je verdient punten met bijna alles wat je doet:
Muntje oprapen — 1 punt
Vijand verslaan door erop te springen — 10 punten
Vijand verslaan door te boksen — 15 punten
Een speciaal blokje kapotslaan — 5 punten
Een eindbaas verslaan — 100 punten
Level voltooien — 50 punten bonus, plus nog eens 25 punten extra als je het level zonder enige schade uitspeelt
Je hoogste score per level én je totaalscore worden bewaard bij je profiel.

[font_size=20]Profielen[/font_size]
Je kunt meerdere spelprofielen aanmaken (handig als je met meerdere spelers bent) — kies of maak er een via 'Spel Spelen'. Elk profiel bewaart zijn eigen voortgang, scores en ontgrendelde werelden. Profielnamen aanpassen of verwijderen kan via Instellingen."""

## Pixels per seconde waarmee het Uitleg-scherm met de gamepad (of pijltjes)
## verticaal scrollt zolang omhoog/omlaag ingedrukt blijft.
const SCROLL_SPEED := 700.0

## Wordt gezet vóór add_child() als de Help als overlay bovenop een gepauzeerd
## spel getoond wordt (vanuit het pauzemenu). In dat geval keert 'Terug' terug
## naar het pauzemenu i.p.v. naar het hoofdmenu te wisselen.
var overlay_mode: bool = false
signal overlay_closed

@onready var _scroll:      ScrollContainer = $ContentPanel/VBox/ScrollContainer
@onready var _rich_text_1: RichTextLabel  = $ContentPanel/VBox/ScrollContainer/ContentVBox/TextBefore
@onready var _powerup_box: VBoxContainer  = $ContentPanel/VBox/ScrollContainer/ContentVBox/PowerupBox
@onready var _rich_text_2: RichTextLabel  = $ContentPanel/VBox/ScrollContainer/ContentVBox/TextAfter
@onready var _back_btn:    Button         = $ContentPanel/VBox/BackButton

func _ready() -> void:
	_rich_text_1.text = HELP_TEXT_1
	_build_powerup_rows()
	_rich_text_2.text = HELP_TEXT_2
	_back_btn.pressed.connect(_on_back)
	# Beginfocus zodat de gamepad meteen 'Terug' kan aanklikken; omhoog/omlaag
	# scrollt de tekst (zie _process).
	_back_btn.grab_focus.call_deferred()
	if not overlay_mode:
		AudioManager.play_music_by_name("menu")

func _on_back() -> void:
	if overlay_mode:
		overlay_closed.emit()
	else:
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

## Scrollt de uitleg met de D-pad/stick (of pijltjestoetsen) zolang omhoog/omlaag
## ingedrukt blijft — met maar één knop in beeld zou focusnavigatie anders niets
## doen. Werkt ook tijdens de pauze (overlay-modus draait met PROCESS_MODE_ALWAYS).
func _process(delta: float) -> void:
	if _scroll == null:
		return
	var dir := Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if absf(dir) > 0.1:
		_scroll.scroll_vertical += int(dir * SCROLL_SPEED * delta)

## In overlay-modus sluit de B-/Annuleer-knop (of Escape) het Uitleg-scherm en
## keert terug naar het pauzemenu.
func _unhandled_input(event: InputEvent) -> void:
	if overlay_mode and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()

## Bouwt per power-up een rij met het echte, gekleurde icoon i.p.v. platte
## BBCode-tekst — RichTextLabel's [img] kan geen kleur-modulatie toepassen,
## dus dit gaat via losse UI-nodes, net als HUD._build_powerup_rows().
func _build_powerup_rows() -> void:
	for info: Dictionary in POWERUP_INFO:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var icon := TextureRect.new()
		icon.texture = info["icon"]
		icon.modulate = info["tint"]
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "[b]%s[/b] — %s" % [info["title"], info["desc"]]
		row.add_child(label)

		_powerup_box.add_child(row)
