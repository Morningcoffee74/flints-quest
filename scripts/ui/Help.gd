extends Control

const HELP_TEXT := """[center][font_size=30]Speluitleg[/font_size][/center]

[font_size=20]Flint en zijn avontuur[/font_size]
Flint is een dappere jongen van 12 jaar die nergens bang voor is. Hij is ontvoerd door een vuurmonster en moet nu, ver van huis, zijn weg terugvinden. Onderweg trekt hij door 10 heel verschillende werelden, van een rustig bos tot een gloeiende vulkaan, om uiteindelijk het vuurmonster te verslaan en eindelijk weer thuis te komen.

[font_size=20]Doel van elk level[/font_size]
Elk level eindigt bij een houten huisje. Loop naar dat huisje om het level te voltooien. In latere levels moet je eerst genoeg munten verzamelen en/of genoeg vijanden verslaan voordat het huisje opengaat — je ziet de voortgang daarvan bovenin het scherm tijdens het spelen. Onderweg vind je ook checkpoints: kom je daarna te overlijden, dan begin je vanaf dat punt opnieuw in plaats van helemaal bij het begin.

[font_size=20]Gezondheid en levens[/font_size]
Flint heeft 5 hartjes. Raakt een vijand hem aan, val je in een ravijn of loop je tegen stekels aan, dan gaat er een hartje af. Elke 10 verzamelde munten geeft je 1 hartje terug (tot een maximum van 5). Zijn alle hartjes op, dan verlies je een leven — je begint met 3 levens per poging aan een level. Zijn ook je levens op, dan is het game over en begin je het level opnieuw.

[font_size=20]Besturing[/font_size]
[table=2]
[cell]Links / rechts[/cell][cell]A/D of pijltjestoetsen — lopen[/cell]
[cell]Omhoog[/cell][cell]W of ↑ — een ladder beklimmen[/cell]
[cell]Omlaag[/cell][cell]S of ↓ — bukken (ontwijk duikende vleermuizen) of een ladder afdalen[/cell]
[cell]Springen[/cell][cell]Spatie of Z[/cell]
[cell]Boksen[/cell][cell]X of Enter[/cell]
[cell]Pauze[/cell][cell]Escape[/cell]
[/table]

[font_size=20]Vijanden verslaan[/font_size]
De meeste vijanden versla je door er bovenop te springen, of door ze te boksen. Let op: sommige vijanden (zoals de slang) zijn ongevoelig voor een sprong op hun kop — die moet je boksen om te verslaan. Raakt een vijand jóu aan zonder dat je hem net verslaat, dan kost dat een hartje. Aan het einde van elke wereld (level 10) wacht een extra grote eindbaas.

[font_size=20]De 10 werelden[/font_size]
Elke wereld heeft een eigen thema, eigen vijanden en eigen muziek. Wereld 1 (het Bos) heeft bijvoorbeeld ratten, slangen en vleermuizen als vijanden. De werelden zijn in deze volgorde:
1. Bos  2. Water  3. Grot  4. Jungle  5. Lucht
6. Palmstrand  7. IJsberg  8. Woestijn  9. Snoepland  10. Vulkaan (met het vuurmonster als eindbaas)

Een wereld gaat pas open als je bijna alle levels van de vorige wereld hebt uitgespeeld (je mag er 1 overslaan, behalve het allerlaatste level van een wereld). Uitgespeelde levels en werelden mag je altijd opnieuw spelen.

[font_size=20]Power-ups[/font_size]
Tijdens het spelen kom je gekleurde power-up-blokjes tegen. Elke boost duurt 8 seconden, met een afteltimer in beeld:
[b]Paars[/b] — tijdelijk onkwetsbaar voor vijanden
[b]Blauw[/b] — flink sneller lopen
[b]Oranje[/b] — harder slaan (verslaat gewone vijanden in één klap, en doet extra schade aan een eindbaas)

[font_size=20]Punten[/font_size]
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

@onready var _rich_text: RichTextLabel = $ContentPanel/VBox/ScrollContainer/RichTextLabel
@onready var _back_btn:  Button        = $ContentPanel/VBox/BackButton

func _ready() -> void:
	_rich_text.text = HELP_TEXT
	_back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
	AudioManager.play_music_by_name("menu")
