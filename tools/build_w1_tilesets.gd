extends SceneTree

## Bouwt extra tileset-varianten voor Wereld 1 (en recolors voor Wereld 2), elk
## als 112×144-sheet op EXACT dezelfde atlas-coördinaten als world1_tileset.tres,
## zodat Terrain.gd niets hoeft te weten van de variant:
##   (1,5)(2,5)(3,5) top-links/-midden/-rechts · (1,6)(2,6)(3,6) midden-rij
##   (1,7)(2,7)(3,7) lage rij · (5,5) massief · (1,1)(1,2)(1,3) pilaar top/mid/laag
##
## Varianten Wereld 1 (assets/sprites/tiles/world1_forest/):
##   tileset_sunny.png — bruine aarde met fel gras (ansimuz "Sunny Land", CC0)
##   tileset_hedge.png — oranje herfstheg (CC0 "A platformer in the forest")
##   tileset_teal.png  — blauwgroene heg (zelfde sheet)
## Varianten Wereld 2 (assets/sprites/tiles/world2_water/), hue-verschuivingen
## van het groene koraal: tileset_reef.png (paars-blauw), tileset_sand.png (warm).
##
## Draaien: Godot --headless --path . --script tools/build_w1_tilesets.gd
## Daarna: Godot --headless --path . --import

const T := 16
const W1 := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/tiles/world1_forest/"
const W2 := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/tiles/world2_water/"

## Per variant: bron + bronvenster (x, y) per tegel-rol.
const VARIANTS: Dictionary = {
	"sunny": {
		"src": W1 + "sunny_source.png",
		"top_left": [16, 16], "top_mid": [48, 16], "top_right": [80, 16],
		"mid_left": [16, 48], "mid_mid": [48, 80], "mid_right": [80, 48],
		"low_left": [16, 80], "low_mid": [48, 80], "low_right": [80, 80],
		"solid": [48, 48],
		"pillar_top": [48, 16], "pillar_mid": [112, 16], "pillar_low": [112, 16],
	},
	"hedge": {
		"src": W1 + "hedge_source.png",
		"top_left": [160, 0], "top_mid": [176, 0], "top_right": [192, 0],
		"mid_left": [160, 16], "mid_mid": [176, 16], "mid_right": [192, 16],
		"low_left": [160, 16], "low_mid": [176, 16], "low_right": [192, 16],
		"solid": [176, 16],
		"pillar_top": [208, 0], "pillar_mid": [208, 16], "pillar_low": [208, 16],
	},
	"teal": {
		"src": W1 + "hedge_source.png",
		"top_left": [160, 32], "top_mid": [176, 32], "top_right": [192, 32],
		"mid_left": [160, 48], "mid_mid": [176, 16], "mid_right": [192, 48],
		"low_left": [160, 48], "low_mid": [176, 16], "low_right": [192, 48],
		"solid": [176, 16],
		"pillar_top": [208, 32], "pillar_mid": [208, 48], "pillar_low": [208, 48],
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
	for name: String in VARIANTS:
		var v: Dictionary = VARIANTS[name]
		var src := Image.load_from_file(v["src"])
		if src == null:
			push_error("bron ontbreekt: " + String(v["src"]))
			ok = false
			continue
		var out := Image.create(112, 144, false, Image.FORMAT_RGBA8)
		for role: String in SLOTS:
			var s: Array = v[role]
			var slot: Array = SLOTS[role]
			out.blit_rect(src, Rect2i(s[0], s[1], T, T), Vector2i(slot[0] * T, slot[1] * T))
		var path := W1 + "tileset_%s.png" % name
		if out.save_png(path) != OK:
			push_error("schrijven mislukt: " + path)
			ok = false
		else:
			print("geschreven: ", path)

	# Wereld 2: recolors van het koraal.
	var coral := Image.load_from_file(W2 + "tileset.png")
	if coral == null:
		push_error("W2 tileset.png ontbreekt (draai eerst build_w2_tileset.gd)")
		ok = false
	else:
		for spec: Array in [["reef", 0.62, 1.0, 0.95], ["sand", -0.22, 0.7, 1.15]]:
			var img := _recolor(coral, spec[1], spec[2], spec[3])
			var path := W2 + "tileset_%s.png" % spec[0]
			if img.save_png(path) != OK:
				push_error("schrijven mislukt: " + path)
				ok = false
			else:
				print("geschreven: ", path)
	quit(0 if ok else 1)

## Hue-verschuiving (0..1 = hele cirkel), verzadiging en helderheid.
func _recolor(src: Image, hue_shift: float, sat_mult: float, val_mult: float) -> Image:
	var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a <= 0.0:
				img.set_pixel(x, y, c)
				continue
			var h := fposmod(c.h + hue_shift, 1.0)
			var s := clampf(c.s * sat_mult, 0.0, 1.0)
			var v := clampf(c.v * val_mult, 0.0, 1.0)
			var n := Color.from_hsv(h, s, v, c.a)
			img.set_pixel(x, y, n)
	return img
