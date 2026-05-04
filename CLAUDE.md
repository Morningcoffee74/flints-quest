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

- **Speler**: CharacterBody2D, state machine (IDLE/RUN/JUMP/FALL/PUNCH/HURT/DEAD)
- **Physics layers**: 1=World, 2=Player, 3=Enemies, 4=Items, 5=PlayerHitbox, 6=EnemyHitbox
- **Health**: 5 hartjes; elke 10 muntjes = +1 hart (max 5)
- **Power-ups**: paars blokje = onkwetsbaar 8s, blauw blokje = hard slaan 8s
- **Difficulty**: `1.0 + (world-1)*0.15 + (level-1)*0.02` (W1L1=1.0×, W10L10=2.53×)
- **Save**: JSON in `user://profiles/<naam>.json` via SaveSystem autoload
- **Input**: geregistreerd in GameManager._ready() — geen project.godot input sectie nodig

## Input

| Actie | Toetsen |
|-------|---------|
| Bewegen | A/D of ←/→ |
| Springen | Spatie of Z |
| Boksen | X of Enter |
| Pauze | Escape |

## Vijanden per wereld (world_config.gd)

Wereld 1 (Bos): Wolf, MushroomMan, Crow — Boss: ForestBoss (bewegende boom met armen)
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
- [ ] Fase 1: Werkend skelet — speler beweging, test level, camera, HUD
- [ ] Fase 2: Core gameplay — enemies, health, coins, power-ups, cabin
- [ ] Fase 3: UI & navigatie — menus, profielen, wereldkaart, save/load
- [ ] Fase 4: Wereld 1 volledig — 10 levels, boss, parallax, audio
- [ ] Fase 5: Werelden 2-10
- [ ] Fase 6: Polish & macOS export
