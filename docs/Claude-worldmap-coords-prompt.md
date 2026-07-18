# Promptje voor Claude Code: coördinaten uit een wereldkaart-afbeelding lezen

Gemini (en beeld-LLM's in het algemeen) houden zich niet betrouwbaar aan
exacte pixel-coördinaten in een prompt (zie `Gemini-prompt.md`). Werk daarom
omgekeerd: laat de afbeelding eerst genereren, en lees daarna de échte
pixel-posities van de 10 open plekken af — en zet die in de code, in plaats
van andersom.

## Zo gebruik je dit

Plak (of parafraseer) onderstaande prompt in een Claude Code sessie in deze
repo, met `<N>` vervangen door het werelnummer en het pad naar de nieuw
gegenereerde afbeelding.

---

> Ik heb een nieuwe wereldkaart-achtergrond gegenereerd voor wereld `<N>` op
> `assets/sprites/backgrounds/worldmap/world<N>.png` (canvas 1280×720, zie
> `docs/worldmap-achtergrond-prompt.md` voor de originele tekenprompt).
>
> Open die afbeelding met de Read tool en bekijk hem. Zoek het pad dat van
> linksonder naar rechtsboven loopt en identificeer de 10 open plekken
> (clearings) langs dat pad — dit zijn de plekken waar de levelknoppen op de
> wereldkaart moeten komen.
>
> Schat voor elke clearing, in volgorde van level 1 (start, linksonder) tot
> level 10 (einde, rechtsboven), de pixel-coördinaten (x, y) op het 1280×720
> canvas. Rapporteer de 10 (x, y) paren.
>
> Werk daarna `LEVEL_POSITIONS` in `scripts/ui/WorldMap.gd` (regels 3–14) bij
> zodat die overeenkomt met de werkelijke posities in de afbeelding.

---

## Let op

- `LEVEL_POSITIONS` in `WorldMap.gd` is op dit moment één array die voor
  **alle** werelden wordt gebruikt (`_build_map()` gebruikt geen
  wereld-specifieke posities). Zolang alle wereldkaarten qua pad-vorm min of
  meer overeenkomen is dat geen probleem; wijkt een nieuwe wereld sterk af,
  dan moet dit eerst per-wereld gemaakt worden (bijv. een dictionary
  `world -> Array[Vector2]`) voordat je de nieuwe coördinaten invult.
- Vergeet niet de afbeelding op te slaan als
  `assets/sprites/backgrounds/worldmap/world<N>.png` — **enkelvoud**
  `worldmap`, niet `worldmaps`. De code laadt alleen uit die exacte map
  (`WorldMap.gd:42`); een afwijkende mapnaam faalt stil, zonder foutmelding.
