extends SceneTree

## Bouwt de tileset-varianten voor Wereld 3 (Grot), elk als 112×144-sheet op
## EXACT dezelfde atlas-coördinaten als world1_tileset.tres, zodat Terrain.gd
## niets van de wereld hoeft te weten:
##   (1,5)(2,5)(3,5) top-links/-midden/-rechts · (1,6)(2,6)(3,6) midden-rij
##   (1,7)(2,7)(3,7) lage rij · (5,5) massief · (1,1)(1,2)(1,3) pilaar top/mid/laag
##
## Bronnen (assets/sprites/tiles/world3_cave/, zie assets/CREDITS.md):
##   grotto_source.png  — ansimuz "Warped: Super Grotto Escape Pack" (CC0):
##                        blauw steen (grote blok) + donkere bakstenen (diep)
##   rotting_source.png — RottingPixels "2D Cave Platformer Tileset" (CC0):
##                        keien ("rock") en metselwerk ("brick")
## Varianten: grotto (blauw steen), crystal (paarse hue-shift van grotto),
##            rock (roze-bruine keien), brick (bakstenen met gladde blokken bovenop).
## Pilaartegels (1 tegel breed) zijn linker-/rechterhelften van de randtegels.
##
## Draaien: Godot --headless --path . --script tools/build_w3_tilesets.gd
## Daarna:  Godot --headless --path . --import

const T := 16
const DIR := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/tiles/world3_cave/"

const VARIANTS: Dictionary = {
	"grotto": {
		"src": "grotto_source.png",
		"top_left": [200, 32], "top_mid": [232, 32], "top_right": [324, 32],
		"mid_left": [200, 48], "mid_mid": [248, 48], "mid_right": [324, 48],
		"low_left": [16, 64], "low_mid": [32, 64], "low_right": [64, 64],
		"solid": [32, 80],
	},
	"rock": {
		"src": "rotting_source.png",
		"top_left": [48, 0], "top_mid": [64, 0], "top_right": [80, 0],
		"mid_left": [0, 16], "mid_mid": [16, 16], "mid_right": [32, 16],
		"low_left": [0, 32], "low_mid": [16, 32], "low_right": [32, 32],
		"solid": [64, 32],
	},
	"brick": {
		"src": "rotting_source.png",
		"top_left": [0, 128], "top_mid": [16, 128], "top_right": [32, 128],
		"mid_left": [0, 80], "mid_mid": [16, 80], "mid_right": [32, 80],
		"low_left": [0, 96], "low_mid": [16, 96], "low_right": [32, 96],
		"solid": [16, 112],
	},
}

const SLOTS: Dictionary = {
	"top_left": [1, 5], "top_mid": [2, 5], "top_right": [3, 5],
	"mid_left": [1, 6], "mid_mid": [2, 6], "mid_right": [3, 6],
	"low_left": [1, 7], "low_mid": [2, 7], "low_right": [3, 7],
	"solid": [5, 5],
	"pillar_top": [1, 1], "pillar_mid": [1, 2], "pillar_low": [1, 3],
}

func _init() -> void:
	var ok := true
	var sheets: Dictionary = {}
	for name: String in VARIANTS:
		var v: Dictionary = VARIANTS[name]
		var src := Image.load_from_file(DIR + String(v["src"]))
		if src == null:
			push_error("bron ontbreekt: " + String(v["src"]))
			ok = false
			continue
		var tiles: Dictionary = {}
		for role: String in v:
			if role == "src":
				continue
			var s: Array = v[role]
			tiles[role] = src.get_region(Rect2i(s[0], s[1], T, T))
		# Diepteschaduw: lage rij iets donkerder, massief binnenwerk duidelijk
		# donkerder — in klimlevels is 20+ rijen rots in beeld en anders schreeuwt
		# dat patroon.
		for role: String in ["low_left", "low_mid", "low_right"]:
			tiles[role] = _recolor(tiles[role], 0.0, 1.0, 0.78)
		tiles["solid"] = _recolor(tiles["solid"], 0.0, 0.9, 0.5)
		tiles["pillar_top"] = _split(tiles["top_left"], tiles["top_right"])
		tiles["pillar_mid"] = _split(tiles["mid_left"], tiles["mid_right"])
		tiles["pillar_low"] = _split(tiles["low_left"], tiles["low_right"])
		var out := Image.create(112, 144, false, Image.FORMAT_RGBA8)
		for role: String in SLOTS:
			var slot: Array = SLOTS[role]
			out.blit_rect(tiles[role], Rect2i(0, 0, T, T), Vector2i(slot[0] * T, slot[1] * T))
		sheets[name] = out
		ok = _save(out, name) and ok

	# Kristalgrot: paarse hue-verschuiving van het blauwe steen.
	if sheets.has("grotto"):
		ok = _save(_recolor(sheets["grotto"], 0.27, 0.8, 0.9), "crystal") and ok
	quit(0 if ok else 1)

func _save(img: Image, name: String) -> bool:
	var path := DIR + "tileset_%s.png" % name
	if img.save_png(path) != OK:
		push_error("schrijven mislukt: " + path)
		return false
	print("geschreven: ", path)
	return true

## Linkerhelft uit `left`, rechterhelft uit `right` — 1 tegel brede pilaar.
func _split(left: Image, right: Image) -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for y in T:
		for x in T:
			img.set_pixel(x, y, left.get_pixel(x, y) if x < T / 2 else right.get_pixel(x, y))
	return img

func _recolor(src: Image, hue_shift: float, sat_mult: float, val_mult: float) -> Image:
	var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a <= 0.0:
				img.set_pixel(x, y, c)
				continue
			img.set_pixel(x, y, Color.from_hsv(fposmod(c.h + hue_shift, 1.0), clampf(c.s * sat_mult, 0.0, 1.0), clampf(c.v * val_mult, 0.0, 1.0), c.a))
	return img
