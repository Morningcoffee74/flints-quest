extends Node

const WORLDS: Array = [
	{
		"id": 1, "name": "Bos", "theme": "forest", "music": "world1",
		"direction": "right",
		"enemies": ["Wolf", "MushroomMan", "Crow"],
		"boss": "ForestBoss",
	},
	{
		"id": 2, "name": "Water", "theme": "water", "music": "world2",
		"direction": "right_down",
		"enemies": ["Crab", "Piranha", "FlyingFish"],
		"boss": "Octopus",
	},
	{
		"id": 3, "name": "Grot", "theme": "cave", "music": "world3",
		"direction": "up_right",
		"enemies": ["Bat", "Troll", "Spider"],
		"boss": "StoneGolem",
	},
	{
		"id": 4, "name": "Jungle", "theme": "jungle", "music": "world4",
		"direction": "right",
		"enemies": ["Monkey", "Snake", "Toucan"],
		"boss": "Gorilla",
	},
	{
		"id": 5, "name": "Lucht", "theme": "sky", "music": "world5",
		"direction": "right",
		"enemies": ["Bird", "CloudEnemy", "WindSpirit"],
		"boss": "DragonBird",
	},
	{
		"id": 6, "name": "Palmstrand", "theme": "beach", "music": "world6",
		"direction": "right",
		"enemies": ["Crab", "Seagull", "Jellyfish"],
		"boss": "Pirate",
	},
	{
		"id": 7, "name": "IJsberg", "theme": "iceberg", "music": "world7",
		"direction": "right",
		"enemies": ["Penguin", "PolarBear", "IceBird"],
		"boss": "Walrus",
	},
	{
		"id": 8, "name": "Woestijn", "theme": "desert", "music": "world8",
		"direction": "right",
		"enemies": ["Scorpion", "SandSnake", "Vulture"],
		"boss": "Mummy",
	},
	{
		"id": 9, "name": "Snoep", "theme": "candy", "music": "world9",
		"direction": "right",
		"enemies": ["CookieMan", "CandyWorm", "LolliParasol"],
		"boss": "CakeMonster",
	},
	{
		"id": 10, "name": "Vulkaan", "theme": "volcano", "music": "world10",
		"direction": "up_right",
		"enemies": ["FireBat", "LavaStone", "FireSnake"],
		"boss": "FireMonster",
	},
]
