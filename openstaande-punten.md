# Openstaande punten

Verzameld op 2026-07-19 tijdens het spelen. Nog **niet** opgelost — dit is
een to-do-lijst voor een volgende sessie, in volgorde van vermelding.

---

## 1. Vanuit het spel via Escape → wereldkaart → geen weg naar hoofdmenu

Huidige keten: pauzeren (Escape) → "Terug naar kaart" (`scripts/ui/PauseMenu.gd:16-17`,
roept `GameManager.go_to_world_map()` aan) → op `WorldMap` gaat de
terugknop naar `WorldSelect` (`scripts/ui/WorldMap.gd:84`,
`GameManager.go_to_world_select`), en pas WorldSelect's terugknop gaat naar
`MainMenu`. Er is dus geen *directe* weg terug naar het hoofdmenu vanuit het
pauzemenu of vanaf de wereldkaart — het kost nu 2 extra klikken (kaart →
wereldkeuze → hoofdmenu), en dat voelt aan als doodlopend.

**Voorstel**: een "Hoofdmenu"-knop toevoegen aan `PauseMenu.tscn`/`.gd`
(naast Doorgaan/Herstarten/Terug naar kaart), die rechtstreeks
`GameManager.go_to_main_menu()` aanroept. Eventueel ook een directe
snelkoppeling op `WorldMap` zelf overwegen, maar de pauzemenu-knop lost het
kernprobleem al op.

## 2. Power-up-tekst en -duur langer, in sync met elkaar

- Power-ups duren nu 8 seconden (`POWERUP_DURATION` in
  `scripts/player/Player.gd:13`) — moet langer (voorstel: 12–15s, exact
  getal mag bij implementatie bepaald worden).
- De pop-up tekst ("SNELLER!" etc.) verdwijnt nu na 1 seconde
  (`scripts/ui/HUD.gd:124-138`, `_on_powerup_activated()`: tween-duur
  hardcoded op `1.0`). Moet even lang zichtbaar blijven als de power-up zelf
  duurt.
- Fix: `_on_powerup_activated(kind)` moet de duur kennen (bv.
  `Player.POWERUP_DURATION` doorgeven via het `powerup_activated`-signal, of
  een `AudioManager`-achtige constante delen), en de tween-duur daarop
  baseren i.p.v. de vaste `1.0`.

## 3. Vijand kan pal naast de speler staan net na een respawn

Na een dood + levensverlies wordt de scene herladen
(`scripts/levels/LevelBase.gd:129-134`, `_on_player_died()` →
`get_tree().reload_current_scene()`), waardoor een **nieuwe** Player-node
ontstaat zonder de korte onkwetsbaarheid die normaal na schade geldt
(`_invincible_timer`, `INVINCIBLE_DURATION = 1.5` in
`scripts/player/Player.gd:12,183`). Vijanden (bv. een slang) staan gewoon op
hun patrouilleplek en kunnen zo meteen bij het verschijnen bij een
checkpoint een hartje kosten, wat oneerlijk aanvoelt.

**Voorstel**: een publieke methode op `Player`
(bv. `grant_spawn_invincibility(duration := INVINCIBLE_DURATION)`) die
`_invincible_timer` zet, en die aanroepen vanuit `LevelBase._ready()`
(rond regel 34-36, waar `player.global_position` op het checkpoint gezet
wordt) zodat de speler na elke (her)start/respawn eventjes onkwetsbaar is.

## 4. Uitleg-tekst: meer nadruk op hartjes, en "houten huisje" i.p.v. "huisje"

In `scripts/ui/Help.gd` (`HELP_TEXT`):
- In het stuk over Flint en/of gezondheid iets toevoegen in de trant van:
  Flint heeft een goed hart, en moet goed op zijn hartjes letten om een
  echte man te worden — dit mag gerust een verhalend/moraal-achtig
  toontje krijgen, past bij de titel "Hearts and Houses".
- Overal waar nu kaal "huisje" staat (o.a. "Doel van elk level") consequent
  vervangen door "houten huisje".

## 5. Uitleg-scherm: gekleurde power-up-icoontjes tonen

In de "Power-ups"-sectie van `Help.gd` nu alleen platte tekst
(**Paars**/**Blauw**/**Oranje**). Gebruiker wil de echte icoontjes zien, in
hun eigen kleur — dus `extra-life.png` paars getint, `extra-speed.png`
blauw, `extra-strong.png` oranje.

**Let op bij implementatie**: BBCode in een `RichTextLabel` (`[img]`) kan
geen kleur-modulatie op een afbeelding toepassen — `[color]` werkt alleen
op tekst. De power-ups-sectie kan dus niet als losse regel BBCode-tekst
blijven; die moet (net als in `scripts/ui/HUD.gd:51-64`,
`_build_powerup_rows()`) als losse UI-nodes gebouwd worden: een
`HBoxContainer` per power-up met een `TextureRect` (icoon + `modulate`-tint)
naast een `Label`/`RichTextLabel` met de beschrijving, ingevoegd tussen de
rest van de scrollende BBCode-tekst in `Help.tscn`.

---

Na het oplossen van deze punten: smoke-testen (headless scene-load per
aangepast scherm) en een screenshot-check zoals bij eerdere UI-wijzigingen
in deze sessie, dan committen + pushen.
