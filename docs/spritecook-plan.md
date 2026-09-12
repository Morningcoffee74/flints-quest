# SpriteCook: zwem-sprite voor Flint

Doel: de placeholder-zwemsprite vervangen door een echte zwem-animatie.
**Af (12 sep 2026.)** De mechaniek was al klaar; nu is de art dat ook.

## Status

- [x] Zwemmechaniek: `State.SWIM` in `scripts/player/Player.gd`,
      `scenes/objects/Water.tscn` + `Water.gd`, testscène
      `scenes/levels/W2_SwimTest.tscn`. Runtime geverifieerd.
- [x] SpriteCook-plugin geïnstalleerd en ingelogd (OAuth).
- [x] Zwem-sheet gegenereerd en ingebouwd op
      `assets/sprites/player/SwimFlint.png` (512×128, 4 frames van 128×128).

## Wat er gemaakt is

Drie SpriteCook-assets, vastgelegd in `docs/spritecook/spritecook-assets.json`:

1. `flint-ref.png` geüpload als stijlreferentie.
2. Eén zwempose gegenereerd met die referentie
   (`gemini-3.1-flash-image`, pixel, transparant) — 12 credits.
3. Die pose geanimeerd naar 4 frames, uitvoer als spritesheet — 20 credits.

Verbruik dus 32 van de 40 maandcredits; er stonden er 8 over.

### Nabewerking: `tools/prep_swim_sheet.gd`

De ruwe sheet was 408×102 en had twee mankementen, allebei automatisch
gerepareerd door dat script:

- SpriteCook tekende er cyaanwitte **waterspatten** bij, ondanks een expliciet
  "no water, no splash" in de prompt. Die worden op kleur weggehaald; gaten die
  daardoor midden in de figuur vielen worden met de omringende kleur gevuld, en
  losse schuimspikkels naast de figuur sneuvelen via een grootste-vlek-filter.
- De figuur **dreef per frame ongeveer 30px omhoog**, wat als springerige
  animatie zou uitpakken. Elk frame wordt nu op zijn eigen bounding box
  gecentreerd in een cel van 128×128.

Opnieuw draaien (bijvoorbeeld na een nieuwe generatie):

```
Godot --headless --path . --script tools/prep_swim_sheet.gd -- <bron.png> <doel.png>
```

Levert het script exact 512×128, dan past de sheet 1-op-1 in de bestaande
`swim`-animatie in `scenes/player/player_frames.tres` en hoeft er niets aan
code of resources te wijzigen. Wijkt het formaat af, draai dan
`tools/gen_swim_frames.gd`.

## Inbouwen (voor een volgende keer)

1. Sheet op `assets/sprites/player/SwimFlint.png` zetten.
2. `Godot --headless --path . --import`
   **Niet optioneel.** Een PNG zonder `.import`-bestand laat
   `player_frames.tres` compleet falen, en daarmee `Player.tscn` in álle
   levels — precies dat ging in september mis.
3. Controleren:
   `Godot --headless --path . res://scenes/levels/W2_SwimTest.tscn --quit-after 180`
   (foutloos = goed) en daarna zelf even zwemmen in die scène.

## Daarna

Wereld 2-vijanden (krab, piranha, vliegende vis) zijn de logische volgende
SpriteCook-opdracht, maar dat is een aparte maand-budget-keuze: ongeveer 8 tot
12 credits per statische sprite. Wil je dat ze bij elkaar passen, laat de krab
eerst genereren en gebruik diens `asset_id` als `style_asset_ids` voor de
andere twee. Wil je dat ze bij de W1-vijanden passen, upload dan
`assets/sprites/enemies/common/Rat.png` als referentie.

Twee lessen uit deze ronde, mee te nemen in de volgende prompt:

- Een negatieve instructie ("no water") houdt de generator niet tegen. Reken op
  nabewerking, of vraag de spatten juist bewust aan als ze mooi zijn.
- De animatiestap houdt de figuur niet vanzelf op z'n plek. Frames uitlijnen op
  hun bounding box is vrijwel altijd nodig.

Wat NIET binnen 40 credits past: Flints hele animatieset opnieuw genereren
(idle/walk/run/jump/attack/hurt als animaties) is 100+ credits.
