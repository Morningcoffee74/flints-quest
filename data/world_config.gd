extends Node

## "levels": aantal open plekken op de wereldkaart-achtergrond
## (assets/sprites/backgrounds/worldmap/world<N>.png), afgeteld tijdens Fase 4c
## — zie docs/Claude-worldmap-coords-prompt.md. Standaard 10; werelden met een
## afwijkend aantal clearings op de kaart krijgen hier een override zodat
## WorldMap/GameManager/SaveSystem het juiste aantal levels gebruiken.
const WORLDS: Array = [
	{
		"id": 1, "name": "Bos", "theme": "forest", "music": "world1",
		"direction": "right", "levels": 10,
		"enemies": ["Rat", "Snake", "Bat"],
		"boss": "ForestBoss",
	},
	{
		"id": 2, "name": "Water", "theme": "water", "music": "world2",
		"direction": "right_down", "levels": 11,
		"enemies": ["Crab", "Piranha", "FlyingFish"],
		"boss": "Octopus",
	},
	{
		"id": 3, "name": "Grot", "theme": "cave", "music": "world3",
		"direction": "up_right", "levels": 11,
		"enemies": ["Bat", "Troll", "Spider"],
		"boss": "StoneGolem",
	},
	{
		"id": 4, "name": "Jungle", "theme": "jungle", "music": "world4",
		"direction": "right", "levels": 11,
		"enemies": ["Monkey", "Snake", "Toucan"],
		"boss": "Gorilla",
	},
	{
		"id": 5, "name": "Lucht", "theme": "sky", "music": "world5",
		"direction": "right", "levels": 10,
		"enemies": ["Bird", "CloudEnemy", "WindSpirit"],
		"boss": "DragonBird",
	},
	{
		"id": 6, "name": "Palmstrand", "theme": "beach", "music": "world6",
		"direction": "right", "levels": 10,
		"enemies": ["Crab", "Seagull", "Jellyfish"],
		"boss": "Pirate",
	},
	{
		"id": 7, "name": "IJsberg", "theme": "iceberg", "music": "world7",
		"direction": "right", "levels": 11,
		"enemies": ["Penguin", "PolarBear", "IceBird"],
		"boss": "Walrus",
	},
	{
		"id": 8, "name": "Woestijn", "theme": "desert", "music": "world8",
		"direction": "right", "levels": 10,
		"enemies": ["Scorpion", "SandSnake", "Vulture"],
		"boss": "Mummy",
	},
	{
		"id": 9, "name": "Snoep", "theme": "candy", "music": "world9",
		"direction": "right", "levels": 12,
		"enemies": ["CookieMan", "CandyWorm", "LolliParasol"],
		"boss": "CakeMonster",
	},
	{
		"id": 10, "name": "Vulkaan", "theme": "volcano", "music": "world10",
		"direction": "up_right", "levels": 11,
		"enemies": ["FireBat", "LavaStone", "FireSnake"],
		"boss": "FireMonster",
	},
]
