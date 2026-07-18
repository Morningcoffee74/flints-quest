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

### 2. Ontbrekende geluidseffecten (5 stuks)

De code roept ze al aan; zodra het bestand er staat, doet het geluid het.
Site: https://kenney.nl/assets (bijv. "Interface Sounds" / "Impact Sounds") of https://freesound.org

```
assets/audio/sfx/jump.ogg        (springen)
assets/audio/sfx/hurt.ogg        (speler geraakt)
assets/audio/sfx/enemy_die.ogg   (vijand verslagen)
assets/audio/sfx/level_win.ogg   (level voltooid)
assets/audio/sfx/game_over.ogg   (game over)
```

Let op: exact deze bestandsnamen (of pas `SFX_PATHS` aan in
`scripts/autoloads/AudioManager.gd`).

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
