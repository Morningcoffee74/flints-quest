# Boodschappenlijst: Assets voor Flint's Quest

Status na de asset-integratie van juli 2026. Wat binnen is, is al in het spel
gekoppeld; hieronder eerst wat er nog ONTBREEKT, daarna wat er al is.

---

## NOG NODIG

### 1. Vijand-sprites Wereld 1 (hoogste prioriteit)

De vijanden zijn nu gekleurde blokjes. Nodig: spritesheets (zoals de speler:
1 PNG per beweging, frames naast elkaar) of losse frames voor:

| Vijand | Zoekterm | Map |
|--------|----------|-----|
| Wolf | "free pixel wolf sprite" | `assets/sprites/enemies/world1/` |
| Paddenstoelman | "free mushroom enemy sprite" | `assets/sprites/enemies/world1/` |
| Kraai | "free crow bird sprite sheet" | `assets/sprites/enemies/world1/` |
| Boom-baas | "free tree monster sprite" | `assets/sprites/enemies/world1/` |

Sites: https://craftpix.net/freebies/ · https://itch.io/game-assets · https://opengameart.org
Kies pixel-art die past bij de speler (frames van ±64–128px).

### 2. Ontbrekende geluidseffecten (5 stuks) — INGEVULD met placeholders (sep 2026)

De 5 geluiden staan er nu als eenvoudige, synthetisch gegenereerde .ogg's
(jump/hurt/enemy_die/level_win/game_over). Ze klinken, maar zijn bewust simpel.
Vervang t.z.t. door mooiere via https://kenney.nl/assets ("Interface Sounds" /
"Impact Sounds", allemaal CC0) of https://freesound.org — behoud exact deze
bestandsnamen, dan hoeft er niets in de code te wijzigen.

### 3. Later vervangen (stijlbreuk, werkt wel)

De munt (euro), hartjes en power-up-iconen zijn gladde vector-stijl tussen
pixel-art. Vervang t.z.t. door pixel-art versies (16–32px):
- munt → `assets/sprites/items/coin.png`
- hart vol/leeg → `assets/sprites/heart-full.png` / `heart-empty.png`
- ster (onkwetsbaar) → `assets/sprites/items/extra-speed.png`
- gem (hard slaan) → `assets/sprites/items/extra-strong.png`

### 4. Optioneel (nu placeholder-graphics in code getekend)

- Ladder-sprite (pixel-art, 28px breed, herhaalbaar)
- Checkpoint-vlag
- Stekels/spikes-tegel
- Huisje/cabin (nu een bruine polygon)
- Extra tegels wereld 1 (de huidige tileset is klein: 1 grondblok + 3 pilaren)
- Buk/kruip-sprite voor de speler (`assets/sprites/player/Crouch.png`, zelfde
  formaat als de andere speler-sheets). Bukken (S/↓) werkt al functioneel
  (verkleinde hitbox, ontwijkt vleermuizen), maar hergebruikt nu de
  spring-pose als animatie omdat er nog geen eigen hurk-frame is — pas
  `"crouch"`-animatie aan in `scenes/player/player_frames.tres` zodra het
  sheet er is.

### 5. Werelden 2–10 (pas bij Fase 5)

Per wereld: tileset, 3 parallax-lagen, 3 vijanden + baas, muziekloop.
Zelfde mappenstructuur: `assets/sprites/tiles/world2_water/`,
`assets/sprites/backgrounds/world2/`, enz.

---

## BINNEN ✓ (al gekoppeld in het spel)

- [x] Parallax bos (3 lagen) → `assets/sprites/backgrounds/world1/back|far|middle.png`
- [x] Tileset wereld 1 → `assets/sprites/tiles/world1_forest/tileset.png`
- [x] Speler-spritesheets (10 stuks, 128×128/frame) → `assets/sprites/player/`
- [x] Munt → `assets/sprites/items/coin.png`
- [x] Hartjes → `assets/sprites/heart-full.png`, `heart-empty.png`
- [x] Power-ups → `assets/sprites/items/extra-speed.png` (ster), `extra-strong.png` (gem), `extra-life.png`
- [x] Muziek wereld 1 → `assets/audio/music/Living Voyage.mp3`
- [x] SFX: `coin.ogg`, `punch.ogg`, `powerup.ogg`, `footstep_wood_001.ogg`
- [x] SFX (placeholder, sep 2026): `jump.ogg`, `hurt.ogg`, `enemy_die.ogg`, `level_win.ogg`, `game_over.ogg`
- [x] Zwem-sprite Flint (placeholder uit eigen frames) → `assets/sprites/player/SwimFlint.png`; optioneel mooiere versie via `tools/generate_swim.py` (Gemini)
- [x] Water-parallax (3 lagen) → `assets/sprites/backgrounds/world2/back|far|middle.png` + `scenes/objects/ParallaxBGWater.tscn` (sinds 12 sep 2026 echte pixel-art: ansimuz "Underwater Fantasy", CC-BY 3.0 — zie `assets/CREDITS.md`)
- [x] Tileset W2 → `assets/sprites/tiles/world2_water/tileset.png` (gebouwd door `tools/build_w2_tileset.gd` uit ansimuz "Underwater Diving Pack", CC0) + decor `props_source.png`
- [x] Vijanden W2: krab (`Crab.tscn`, Enemy Galore CC-BY 4.0), piranha (`Piranha.tscn`) en jagende grote vis (`BigFish.tscn`), zeemijn (`Mine.tscn`, `assets/sprites/items/sea_mine.png`) — alle uit het Underwater Diving Pack; vliegende vis nog niet (`DartFish_Swim.png` ligt klaar)
- [x] Lucht boven de waterlijn W2 → `assets/sprites/backgrounds/world2/sky.png` (procedureel, `tools/build_w2_sky.gd`)
- [x] Muziek W2 → `assets/audio/music/watery_cave_loop.ogg` (Pascal Belisle, CC0)
- [x] Octopus-boss W2 → `scenes/enemies/world2/Octopus.tscn` (rapidpunches, CC-BY 4.0)
- [x] Extra tile-varianten W1 (sunny/hedge/teal) + decor, W2 (reef/sand); zeemijn-knal `explosion.mp3`; W2 levels 1–11 gegenereerd
- [x] Zwemmechaniek → SWIM-state in `Player.gd`, `scenes/objects/Water.tscn` + `Water.gd`; testscène `scenes/levels/W2_SwimTest.tscn`
