# Flint's Quest: Hearts and Houses

2D side-scrolling platformer in Godot 4.4, geïnspireerd op Alex Kidd. Modern smooth 2D stijl.
10 werelden, ±10 levels elk (aantal per wereld in `WorldConfig.WORLDS[w]["levels"]`,
afgeleid uit het aantal clearings op de wereldkaart-achtergrond — de meeste werelden
hebben er 10, een paar 11 of 12). Export target: macOS Apple Silicon (arm64).

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
- **Power-ups** (14s, aftelbalkje in HUD, PowerBlock.gd): paars = onkwetsbaar, blauw = snelheid ×1.5, oranje = hard slaan (2 schade op boss, one-shot op gewone vijand)
- **Vijand-AI**: rat = lunge-sprint, slang = stomp-immuun (springen op kop = schade), vleermuis = duikaanval; health en snelheid schalen met difficulty; grondvijanden keren bij randen
- **Vijand-bibliotheek**: sprites in `assets/sprites/enemies/common/` (9 sets: Bat, Rat, Snake, Hyena, Mummy, Scorpio, Slime, Vulture, Deceased), scenes in `scenes/enemies/common/` — herbruikbaar in alle werelden; bosses blijven per wereld (`scenes/enemies/world<N>/`)
- **Difficulty**: health/schade schaalt met `1.0 + (world-1)*0.15 + (level-1)*0.02` (W1L1=1.0×, W10L10=2.53×); snelheid (speler én vijanden) schaalt apart en samengesteld via `GameManager.get_speed_difficulty()` = `min(2.0, 1.1^((world-1)+(level-1)))`
- **Levels**: runtime-geschilderde TileMapLayer via `scripts/levels/Terrain.gd` (solid_rects in tegels van 32px, grond-bovenkant = rij 20); top-tegels zijn one-way; gegenereerd met `tools/gen_levels_world1.gd` uit secties (flat/steps/gap/high-route/spike-run/bat-alley) — pas dáár levels aan en regenereer; een validatiepas dwingt sprongregels af (max 3 tegels omhoog, gat ≤5 vlak/≤4 stijgend, checkpoints/objecten boven vaste grond)
- **Wereldkaart**: achtergrond per wereld via `assets/sprites/backgrounds/worldmap/world<N>.png` (tekenprompt: `docs/worldmap-achtergrond-prompt.md`); clearing-coördinaten per wereld in `WorldMap.LEVEL_POSITIONS` (afgelezen zoals `docs/Claude-worldmap-coords-prompt.md` beschrijft); `WorldSelect.tscn` laat spelers tussen unlocked werelden wisselen (ProfileSelect → WorldSelect → WorldMap)
- **Cabin-eis**: munten% en/of vijanden (LevelBase.require_both); latere levels eisen beide
- **Save**: JSON in `user://profiles/<naam>.json` via SaveSystem autoload
- **Input**: geregistreerd in GameManager._ready() — geen project.godot input sectie nodig; elke actie heeft naast toetsenbord ook een gamepad-event (D-pad + linker-stick voor bewegen, face buttons voor jump/punch/pause), dus een Bluetooth-gamepad zoals 8BitDo werkt out of the box zonder aparte configuratie

## Input

| Actie | Toetsen | Gamepad | Gebruik |
|-------|---------|---------|---------|
| Links/rechts | A/D of ←/→ | D-pad of linker-stick | Lopen |
| Omhoog | W of ↑ | D-pad of linker-stick | Ladder beklimmen |
| Omlaag | S of ↓ | D-pad of linker-stick | Bukken (vogel ontwijken), ladder afdalen |
| Springen | Spatie of Z | A-knop | Springen |
| Boksen | X of Enter | X-knop | Aanvallen |
| Pauze | Escape | Start-knop | Pauzemenu |

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
- [x] Fase 4: Wereld 1 volledig — 10 levels (~5400–15600px, gaten/stekels/ladders/checkpoints), boss, parallax, audio gekoppeld
- [ ] Fase 4b: ontbrekende assets — 5 SFX (zie boodschappenlijst.md); vijand-sprites W1 ✓ (Rat/Snake/Bat)
- [x] Fase 4c: speelbaarheid-fixes na doorspelen W1 — generator (munten/stekels, korter L1), slangen-jitter/vlucht, samengestelde snelheidsopbouw, power-up duidelijkheid, cabin-voortgang/muur/vuurwerk, wereldkaart per wereld + WorldSelect, profieloverzicht + instellingenscherm
- [x] Fase 4d: polish na doorspelen W1 (2e ronde) — pauzemenu heeft nu een directe "Hoofdmenu"-knop, power-up-duur 8s→14s met tekst-popup die even lang blijft staan, respawn-onkwetsbaarheid via `Player.grant_spawn_invincibility()` (voorkomt oneerlijke hit vlak na een checkpoint-respawn), uitleg-scherm met "houten huisje"/hartjes-moraal-tekst en echte gekleurde power-up-icoontjes, Bluetooth-gamepad-ondersteuning (8BitDo e.d.) via joypad-events in `GameManager._register_gamepad_events()`
- [x] Fase 4e: polish na doorspelen W1 (3e ronde) — levels ~20% korter (`LENGTH_SCALE` in `tools/gen_levels_world1.gd`, schaalt sectielengtes i.p.v. dichtheid), **scorebug gefixt**: `ScoreManager.reset_level()` liep tot nu toe ook bij elke checkpoint-respawn (scene reload) mee, waardoor score/munten/gedode-vijanden-voortgang verloren ging en een cabin-eis soms onhaalbaar werd — reset gebeurt nu alleen nog in `GameManager.go_to_level()` (een echt nieuwe poging), voortgang wordt bij een reload uit `ScoreManager` gelezen i.p.v. gereset; checkpoints activeren nu ook op x-positie i.p.v. alleen fysieke aanraking (voorkwam een edge case op hoge routes waarbij een speler na de dood alsnog bij het levelbegin verscheen); HUD-tekst iets groter; cabin-munt-voortgang toont nu aantallen i.p.v. een verwarrend %-teken; munten boven stekelloop-secties wisselen nu af tussen boven de eerste stekel/laatste stekel/iets hoger i.p.v. steeds hetzelfde lastig te timen middenpunt; GameOver- en LevelComplete-scherm hebben nu ook een directe "Hoofdmenu"-knop (waren de laatste twee schermen zonder)
- [ ] Fase 5: Werelden 2-10
- [ ] Fase 6: Polish & macOS export
