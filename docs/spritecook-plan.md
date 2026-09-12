# SpriteCook: zwem-sprite voor Flint

Doel: de placeholder-zwemsprite vervangen door een echte zwem-animatie in
Flints eigen stijl. De zwemmechaniek zelf is af en getest (zie onderaan) —
alleen de art is nog een noodoplossing.

## Status

- [x] Zwemmechaniek: `State.SWIM` in `scripts/player/Player.gd`,
      `scenes/objects/Water.tscn` + `Water.gd`, testscène
      `scenes/levels/W2_SwimTest.tscn`. Runtime geverifieerd: in het water gaat
      de speler naar SWIM, speelt de `swim`-animatie, zakt traag (60 px/s
      i.p.v. vrije val) en valt bij het verlaten weer normaal.
- [x] SpriteCook-marketplace toegevoegd aan Claude Code.
- [ ] Plugin installeren + inloggen (moet je zelf doen, zie hieronder).
- [ ] Zwem-sheet genereren en inbouwen.

## Stap 1 — plugin installeren (eenmalig, door jou)

De marketplace staat er al in. Wat nog moet:

1. Gratis account op https://app.spritecook.ai (40 credits per maand, geen
   creditcard).
2. In Claude Code: `/plugin install spritecook@spritecook`
   (of via `/plugin` → Browse marketplaces → spritecook).
3. Claude Code herstarten — MCP-servers laden alleen bij het opstarten.
4. Eerste SpriteCook-opdracht opent een OAuth-inlog in je browser. Plak nooit
   API-sleutels of tokens in de chat; dat is niet nodig.
5. Controle: `Use SpriteCook to check my credit balance.` → ongeveer 40.

## Stap 2 — de opdracht

Kosten: ongeveer 8 credits per statische sprite, ongeveer 20 voor een
animatie. Een zwem-animatie van 4 frames is hier het juiste product, dus reken
op ~20 credits. Dan blijft er binnen de maand nog ~20 over — genoeg voor twee
statische Wereld 2-vijanden, niet voor drie.

Deze prompt kun je letterlijk plakken:

```
Use SpriteCook to generate a swimming animation sprite sheet for my 2D
platformer character, using docs/spritecook/flint-ref.png as the style
reference.

Stay close to the reference in spirit — small chibi pixel-art boy, big spiky
blond hair, dark navy jacket, dark trousers, black outline — but a slightly
different rendering is fine; it does not have to match pixel for pixel.

Pose: side view facing RIGHT, body horizontal, front crawl — arms reaching
forward and pulling back, legs kicking behind him, head turned so the face
stays visible.

Output: ONE horizontal sprite sheet, 4 frames in a single row, each frame
exactly 128x128 pixels (sheet 512x128), fully transparent background, no
padding differences between frames. The character should fill roughly 72x43
pixels inside each frame, vertically centered. No water, no bubbles, no
shadow, no text, no frame borders.

Save it to assets/sprites/player/ as a transparent PNG.
```

Let op waar de vrijheid zit: de **stijl** mag afwijken (besluit 2026-09-12 —
een mooie zwemsprite die er iets anders uitziet is beter dan lang pielen aan
een perfecte match; de hele set kan later in één keer gelijkgetrokken worden).
De **technische spec** hieronder is wél hard, want daar hangt de inbouw aan.

Waarom deze getallen: in de referentie is Flint ~43 breed × 72 hoog binnen een
128×128-cel. Zwemmend ligt hij horizontaal, dus die maten draaien om. Houdt
SpriteCook zich hieraan, dan past de sheet 1-op-1 in de bestaande animatie en
hoeft er geen code of resource te wijzigen.

## Stap 3 — inbouwen

1. Zet het resultaat op `assets/sprites/player/SwimFlint.png` (overschrijf de
   placeholder). Bewaar de oude desnoods als `SwimFlint_placeholder.png`.
2. Importeren: `Godot --headless --path . --import`
   **Dit is niet optioneel.** Een PNG zonder `.import`-bestand laat Godot
   `player_frames.tres` compleet falen, en daarmee `Player.tscn` in álle
   levels — precies dat ging in september mis.
3. Zijn de afmetingen níet 512×128? Draai dan
   `Godot --headless --path . --script tools/gen_swim_frames.gd`
   Dat script leidt het aantal frames af uit de sheet (vierkante frames, één
   rij) en herschrijft de `swim`-animatie in `player_frames.tres`. Bij een
   afwijkende framehoogte zet je `FRAME_W`/`FRAME_H` bovenin het script.
4. Controleren:
   `Godot --headless --path . res://scenes/levels/W2_SwimTest.tscn --quit-after 180`
   (foutloos = goed) en daarna zelf even zwemmen in die scène.

## Daarna

Wereld 2-vijanden (krab, piranha, vliegende vis) zijn de logische volgende
SpriteCook-opdracht, maar dat is een aparte maand-budget-keuze. Wil je dat ze
bij elkaar passen: laat de krab eerst genereren en die als stijl-referentie
voor de andere twee gebruiken. Wil je dat ze bij de W1-vijanden passen: gebruik
`assets/sprites/enemies/common/Rat.png` als referentie.

Wat NIET binnen 40 credits past: Flints hele animatieset opnieuw genereren
(idle/walk/run/jump/attack/hurt als animaties) is 100+ credits.
