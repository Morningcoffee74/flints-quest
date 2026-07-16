# Flint's Quest: Hearts and Houses

2D side-scrolling platformer in Godot 4.4, geïnspireerd op Alex Kidd. Modern smooth 2D stijl.
10 werelden × 10 levels = 100 levels totaal. Export target: macOS Apple Silicon (arm64).

## Projectstructuur

- `assets/` — sprites, audio, fonts (in te vullen met Kenney.nl / OpenGameArt assets)
- `scenes/` — Godot .tscn bestanden (ui/, levels/world1-10/, player/, enemies/, objects/)
- `scripts/` — GDScript bestanden
  - `autoloads/` — GameManager, SaveSystem, AudioManager, ScoreManager
- `data/world_config.gd` — wereld/level configuratie (enemies, boss, richting, muziek)

## Kernmechanismen

- **Speler**: CharacterBody2D, state machine (IDLE/RUN/JUMP/FALL/CROUCH/CLIMB/PUNCH/HURT/DEAD); bukken verkleint de hitbox (kraai-duik ontwijken)
- **Physics layers**: 1=World, 2=Player, 3=Enemies, 4=Items, 5=PlayerHitbox, 6=EnemyHitbox
- **Health**: 5 hartjes; elke 10 muntjes = +1 hart (max 5)
- **Levens**: 3 per level-poging (GameManager.lives); dood = respawn bij checkpoint/start, 0 levens = game over
- **Gevaren**: ravijnen (vallen = 1 hart + respawn), stekels (Spikes.tscn, `variant` = small_wood/long_wood/small_metal/long_metal uit `assets/sprites/items/spikes/`), ladders (Ladder.tscn), checkpoints (Checkpoint.tscn, 2 per level)
- **Power-ups** (8s, aftelbalkje in HUD, PowerBlock.gd): paars = onkwetsbaar, blauw = snelheid ×1.5, oranje = hard slaan (2 schade op boss, one-shot op gewone vijand)
- **Vijand-AI**: rat = lunge-sprint, slang = stomp-immuun (springen op kop = schade), vleermuis = duikaanval; health en snelheid schalen met difficulty; grondvijanden keren bij randen
- **Vijand-bibliotheek**: sprites in `assets/sprites/enemies/common/` (9 sets: Bat, Rat, Snake, Hyena, Mummy, Scorpio, Slime, Vulture, Deceased), scenes in `scenes/enemies/common/` — herbruikbaar in alle werelden; bosses blijven per wereld (`scenes/enemies/world<N>/`)
- **Difficulty**: `1.0 + (world-1)*0.15 + (level-1)*0.02` (W1L1=1.0×, W10L10=2.53×)
- **Levels**: runtime-geschilderde TileMapLayer via `scripts/levels/Terrain.gd` (solid_rects in tegels van 32px, grond-bovenkant = rij 20); top-tegels zijn one-way; gegenereerd met `tools/gen_levels_world1.gd` uit secties (flat/steps/gap/high-route/spike-run/bat-alley) — pas dáár levels aan en regenereer; een validatiepas dwingt sprongregels af (max 3 tegels omhoog, gat ≤5 vlak/≤4 stijgend, checkpoints/objecten boven vaste grond)
- **Wereldkaart**: achtergrond per wereld optioneel via `assets/sprites/backgrounds/worldmap/world<N>.png` (tekenprompt: `docs/worldmap-achtergrond-prompt.md`)
- **Cabin-eis**: munten% en/of vijanden (LevelBase.require_both); latere levels eisen beide
- **Save**: JSON in `user://profiles/<naam>.json` via SaveSystem autoload
- **Input**: geregistreerd in GameManager._ready() — geen project.godot input sectie nodig

## Input

| Actie | Toetsen | Gebruik |
|-------|---------|---------|
| Links/rechts | A/D of ←/→ | Lopen |
| Omhoog | W of ↑ | Ladder beklimmen |
| Omlaag | S of ↓ | Bukken (vogel ontwijken), ladder afdalen |
| Springen | Spatie of Z | Springen |
| Boksen | X of Enter | Aanvallen |
| Pauze | Escape | Pauzemenu |

## Vijanden per wereld (world_config.gd)

Wereld 1 (Bos): Rat, Snake, Bat — Boss: ForestBoss (bewegende boom met armen)
Wereld 2 (Water): Crab, Piranha, FlyingFish — Boss: Octopus
Wereld 3 (Grot): Bat, Troll, Spider — Boss: StoneGolem
Wereld 4 (Jungle): Monkey, Snake, Toucan — Boss: Gorilla
Wereld 5 (Lucht): Bird, CloudEnemy, WindSpirit — Boss: DragonBird
Wereld 6 (Strand): Crab, Seagull, Jellyfish — Boss: Pirate
Wereld 7 (IJsberg): Penguin, PolarBear, IceBird — Boss: Walrus
Wereld 8 (Woestijn): Scorpion, SandSnake, Vulture — Boss: Mummy
Wereld 9 (Snoep): CookieMan, CandyWorm, LolliParasol — Boss: CakeMonster
Wereld 10 (Vulkaan): FireBat, LavaStone, FireSnake — Boss: FireMonster (eindbaas)

## Bouwstatus

- [x] Fase 0: Setup — mappenstructuur, project.godot, autoloads, git
- [x] Fase 1: Werkend skelet — speler beweging, test level, camera, HUD
- [x] Fase 2: Core gameplay — enemies, health, coins, power-ups, cabin
- [x] Fase 3: UI & navigatie — menus, profielen, wereldkaart, save/load
- [x] Fase 4: Wereld 1 volledig — 10 levels (11616–19200px, gaten/stekels/ladders/checkpoints), boss, parallax, audio gekoppeld
- [ ] Fase 4b: ontbrekende assets — 5 SFX (zie boodschappenlijst.md); vijand-sprites W1 ✓ (Rat/Snake/Bat)
- [ ] Fase 5: Werelden 2-10
- [ ] Fase 6: Polish & macOS export
