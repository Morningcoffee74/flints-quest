We gaan een platformer game maken in Godot 4 voor macOS (Apple Silicon / M2). Voordat je ook maar één regel code schrijft, wil ik dat je een volledig projectplan maakt. We werken in planning mode.

## Wat het spel moet worden

Een 2D side-scrolling platformer geïnspireerd op Alex Kidd. De speler loopt, springt en bokst. Geen schieten. De speler gaat dood bij aanraking door een vijand.
Kijk goed naar hoe Alex Kidd eruit ziet en hoe het gespeeld wordt. Dit spel moet grotendeels de look en feel van Alexx de Kidd overnemen, maar dan wel toch wel een eigen spel zijn.

Gametitel: Flint's Quest: Hearts and Houses
Hoofdpersoon: Flint
Leveldoel: elk level eindigt bij het bereiken van een houten huisje
Hij moet overleven, dus zijn 5 hartjes in leven houden.

## Storyline

Flint is een jongen van 12 jaar, sterk en stoer, die de hele wereld aan kan. niet bang. Hij is ontvoerd door een vuurmonster. Dat vuurmonster is de eindbaas die Flint gaat verslaan.
Einddoel is om zijn eigen huis te komen. Dat eigen huis staat eigenlijk pas aan het eind van level 10 van wereld 10, maar we zien tegelijk al aan het eind van elk level een houten huisje.  


## Werelden en levels

- Elke wereld bestaat uit 10 levels.
- Begin met wereld 1: Europees bos (geen tropisch of oerwoud).
- Na 10 levels volgt een nieuwe wereld. Een wereld is pas toegankelijk als alle 10 levels van de vorige wereld gespeeld zijn. Per wereld mag je 1 level overslaan. Dan krijg je geen punten voor dat niet gespeelde level uiteraard. Laatste level mag niet overgeslagen worden.
- Het moet mogelijk zijn om levels nog een keer te spelen. Ook moet je terug kunnen gaan naar al gespeelde werelden (en levels).  
- Elke wereld heeft een eigen thema, vijanden, en muziek.
- De werelden zijn in volgorde: 
	1) Bos, 
	2) Water, 
	3) Grot in een berg, 
	4) Jungle, 
	5) Lucht (met wolken om over te lopen), 
	6) Palmstrand, 
	7) IJsberg, 
	8) Woestijn,
	9) Snoep (met lollies, zuurstokken, snoepjes)
	10 Vulkaan met veel vuur en extra grote eindbaas.
- De levelrichting varieert per level en past bij het thema. Stel zelf een logische indeling voor (bijv. bos = rechts, water = omlaag, grot = schuin rechts omhoog).
- Aan het eind van elk level is er een duidelijk zichtbaar houten huisje om het einde van het level aan te geven. 
- Doel is dat een normale speler zonder veel tegenslag ongeveer in 5 minuten een level kan uitspelen. Houd hier rekening mee door de lengte van de route, aantallen muntjes en vijanden.
- Totale spel zal daarmee gemiddeld 500 minuten duren (misschien 300 miunuten door een snelle speler en 1000 minuten door een langzame speler). Bedenk dus een manier om snel en effectief 100 levels te maken en op te slaan.


## Vijanden (wereld 1: bos)
- Per level zijn er 3 type normale vijanden.
- In level 10 van een wereld is er een extra vijand: een eindbaas. Deze verschijnt aan het einde van dat level. 
- Vijanden kun je verslaan door erop te springen of door ze te slaan/boksen. Als vijand de speler aanraakt zonder dat de speler slaat, dan heeft de vijand gewonnen en gaat er 1 hartje af van het totaal. Speler kan wel verder spelen in dat level op datzelfde punt totdat de hartjes op zijn.


- Vijanden van level 1:
  Wolven (grondvijand)
  Paddestoelmannetjes (grondvijand, klein)
  Vliegende kraaien (lucht)

- Bedenk zelf passende vijanden voor overige werelden. Ze mogen ook gedeeltelijk hetzelfde zijn. 
- Vijanden worden (een klein beetje) sterker naarmate levels vorderen: meer health, sneller, agressiever patroon. Begin niet te langzaam, maar ga niet te snel, er zijn immers 10 levels in 10 werelden, oftewel 100 levels in totaal. Het moet wel speelbaar blijven.


## Speler en gezondheid

- Healthbar met 5 levens (hartjes of segmenten).
- Speler gaat dood bij 5 aanrakingen.
- Bij dood: fade-out animatie (speler wordt langzaam transparant als een geest), daarna stijgen er vogeltjes op uit het personage.
- Muntjes verzamelen: elke 10 muntjes = 1 health terug (maximaal 5).

## Power-ups via gekleurde blokjes

- Paars blokje = tijdelijk onkwetsbaar
- Blauw blokje = tijdelijk harder slaan (vijanden sterven in één klap)
- Inspireer het mechanieken op hoe Alex Kidd (Sega Master System) blokjes en power-ups verwerkte.

## Puntensysteem

- Punten voor: vijanden verslaan, muntjes verzamelen, speciale blokjes te slaan/vinden, level voltooien.
- Speciale blokjes zijn redelijk duidelijk herkenbaar met bijvoorbeeld een extra icoontje in het blokje. Speler krijgt een muntje door het betreffende blokje te hebben kapot geslagen.
- Bedenk zelf een logische verhouding tussen al deze verschillende punten.
- Highscore per level opgeslagen.
- Totale highscore opgeslagen.
- Startscherm toont: hoogste levelscore én totale highscore.


## Wereldkaart

- Visuele kaart met levels als stippen verbonden door een pad (Mario-stijl).
- Gespeelde levels zichtbaar, vergrendelde werelden grijs/gesloten.

## Profiel en voortgang

- Bij opstarten: naamscherm. Meerdere profielen mogelijk op één machine.
- Geen wachtwoord. Profielen opgeslagen als lokale bestanden.
- Voortgang per profiel: gespeelde levels, scores, huidige positie.

## Geluid

- Achtergrondmuziek per wereld (loop).
- Geluidseffecten voor: boksen/slaan, muntje oppakken, health verlies, health winst, vijand dood, level gewonnen, game over.
- Gebruik gratis/open-source audiobronnen (bijv. freesound.org, OpenGameArt.org).

## Visuele stijl

- Grafisch mooi en verzorgd. Dit is een prioriteit.
- Gebruik gratis assets van Kenney.nl en OpenGameArt.org als basis.
- Europees bos: bomen, mos, rotsen, paddenstoelen, aarde. Geen palmbomen of tropische kleuren.
- Smooth animaties voor speler en vijanden.
- Parallax achtergrond (meerdere lagen bewegen met verschillende snelheid).

## Besturing

- Toetsenbord: pijltjestoetsen of WASD voor bewegen, spatiebalk of Z voor springen, X of Enter voor boksen.
- Pauzeknop (Escape) met pauzemenu (doorgaan, herstarten, terug naar kaart).

## Platform

- Godot 4, export naar macOS (.app voor Apple Silicon).
- Geen browser, geen tijdslimiet in levels.

## Opdracht voor nu (planning mode)

Schrijf geen code. Maak in plaats daarvan:

1. Een projectstructuur (mappen, scenes, scripts die we nodig hebben).
2. Een fasering in bouwstappen, van werkend skelet tot volledig spel.
3. Een overzicht van welke gratis assets (Kenney, OpenGameArt) het meest geschikt zijn en waar je ze vindt.
4. Een lijst van technische keuzes die je maakt in Godot 4 (physics layer, scene structuur, save systeem) met korte onderbouwing.

Stel me vooral vragen aan mij als er onduidelijkheden zijn!

Wacht op mijn akkoord voordat je naar de volgende fase gaat.