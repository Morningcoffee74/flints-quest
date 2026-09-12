extends SceneTree

## Bouwt de tileset-varianten voor Wereld 4 (Jungle), elk als 224×288-sheet op
## EXACT dezelfde atlas-COÖRDINATEN als world1_tileset.tres, zodat Terrain.gd
## niets van de wereld hoeft te weten:
##   (1,5)(2,5)(3,5) top-links/-midden/-rechts · (1,6)(2,6)(3,6) midden-rij
##   (1,7)(2,7)(3,7) lage rij · (5,5) massief · (1,1)(1,2)(1,3) pilaar top/mid/laag
##
## ANDERS DAN W1-W3: de brontegels zijn hier 32px in plaats van 16px, dus het vel
## is 224×288 (7×9 cellen van 32) i.p.v. 112×144. De gegenereerde levels zetten de
## TileMapLayer daarom op scale 1.0 i.p.v. 2.0 — een wereldtegel blijft 32px, maar
## we verliezen geen detail door te verkleinen.
##
## Bronnen (assets/sprites/tiles/world4_jungle/src/, zie assets/CREDITS.md):
##   Open Pixel Project "OPP2017 Jungle and Temple set" (CC0).
##   In het bronvel liggen de grond-tegels 16px verticaal verschoven: een
##   graskap loopt van y=16 tot y=48, niet van 0 tot 32.
## Varianten: jungle (groen gras), moss (grijs steen met mos), temple
##            (zandsteen-blokken), swamp (donkere, vergeelde recolor van jungle).
##
## Draaien: Godot --headless --path . --script tools/build_w4_tilesets.gd
## Daarna:  Godot --headless --path . --import

const T := 32
const SHEET_W := 224
const SHEET_H := 288
const DIR := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/tiles/world4_jungle/"

const VARIANTS: Dictionary = {
	"jungle": {
		"top": "ground_green.png", "body": "wall_brown.png", "fill": "",
		"top_left": [0, 16], "top_mid": [32, 16], "top_right": [64, 16],
		"mid_left": [0, 0], "mid_right": [32, 0],
		"low_left": [0, 128], "low_right": [32, 128],
	},
	"moss": {
		"top": "ground_grey.png", "body": "wall_grey.png", "fill": "",
		"top_left": [0, 16], "top_mid": [32, 16], "top_right": [64, 16],
		"mid_left": [0, 0], "mid_right": [32, 0],
		"low_left": [0, 128], "low_right": [32, 128],
	},
	"temple": {
		"top": "temple.png", "body": "temple.png", "fill": "temple.png",
		"top_left": [0, 16], "top_mid": [32, 16], "top_right": [64, 16],
		"mid_left": [0, 48], "mid_right": [64, 48],
		"low_left": [0, 80], "low_right": [64, 80],
		"fill_at": [32, 48],
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
		var top_src := _load(String(v["top"]))
		var body_src := _load(String(v["body"]))
		if top_src == null or body_src == null:
			ok = false
			continue

		# Binnenvulling. De OPP-bron heeft géén naadloze vultegel: `bottom_*` is
		# een ónderrand (rots boven, donker onder) en de `wall_*`-tegels hebben
		# hun rotsen juist op de randen. Daarom voor jungle/moss een vulling
		# gemaakt uit het palet van de wand — gegarandeerd naadloos, en de
		# diepte-tegels worden toch fors donkerder gezet.
		var fill: Image
		if String(v["fill"]).is_empty():
			fill = _make_fill(body_src, int(v["n"]) if v.has("n") else 4000)
		else:
			var fill_src := _load(String(v["fill"]))
			if fill_src == null:
				ok = false
				continue
			fill = fill_src.get_region(Rect2i(v["fill_at"][0], v["fill_at"][1], T, T))
		var tiles: Dictionary = {}
		for role: String in ["top_left", "top_mid", "top_right"]:
			tiles[role] = top_src.get_region(Rect2i(v[role][0], v[role][1], T, T))
		for role: String in ["mid_left", "mid_right", "low_left", "low_right"]:
			tiles[role] = body_src.get_region(Rect2i(v[role][0], v[role][1], T, T))
		# De randtegels van de bron zijn half doorzichtig (rotsrand op een gat);
		# achter elke midden-/lage tegel hoort de massieve vulling, anders zie je
		# de achtergrond door de berg heen.
		for role: String in ["mid_left", "mid_right", "low_left", "low_right"]:
			tiles[role] = _over(fill, tiles[role])
		tiles["mid_mid"] = fill
		tiles["low_mid"] = fill

		# Diepteschaduw: lage rij donkerder, massief binnenwerk duidelijk
		# donkerder — anders schreeuwt het rotspatroon in hoge wanden.
		for role: String in ["low_left", "low_mid", "low_right"]:
			tiles[role] = _recolor(tiles[role], 0.0, 1.0, 0.86)
		tiles["solid"] = _recolor(fill, 0.0, 0.92, 0.72)
		tiles["pillar_top"] = _split(tiles["top_left"], tiles["top_right"])
		tiles["pillar_mid"] = _split(tiles["mid_left"], tiles["mid_right"])
		tiles["pillar_low"] = _split(tiles["low_left"], tiles["low_right"])

		var out := Image.create(SHEET_W, SHEET_H, false, Image.FORMAT_RGBA8)
		for role: String in SLOTS:
			var slot: Array = SLOTS[role]
			out.blit_rect(tiles[role], Rect2i(0, 0, T, T), Vector2i(slot[0] * T, slot[1] * T))
		sheets[name] = out
		ok = _save(out, name) and ok

	# Moeras: vergeelde, ontzadigde en donkere versie van de jungle-tegels.
	if sheets.has("jungle"):
		ok = _save(_recolor(sheets["jungle"], 0.06, 0.65, 0.7), "swamp") and ok
	quit(0 if ok else 1)

func _load(file: String) -> Image:
	var img := Image.load_from_file(DIR + "src/" + file)
	if img == null:
		push_error("bron ontbreekt: " + file)
	return img

func _save(img: Image, name: String) -> bool:
	var path := DIR + "tileset_%s.png" % name
	if img.save_png(path) != OK:
		push_error("schrijven mislukt: " + path)
		return false
	print("geschreven: ", path)
	return true

## Naadloze binnenvulling uit het palet van een brontegel: de donkerste tinten
## als ondergrond, met een gespikkelde lichtere steenkleur erover. Per pixel
## willekeurig, dus er loopt geen vorm over de tegelrand en hij tilet perfect.
func _make_fill(src: Image, seed_value: int) -> Image:
	var dark := Color(0, 0, 0, 1)
	var light := Color(0, 0, 0, 1)
	var n_dark := 0
	var n_light := 0
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a < 0.9:
				continue
			# Middentonen = de aarde/rots zelf; de bijna-zwarte pixels in de bron
			# zijn de schaduwgaten tussen de keien en zouden een pikzwarte,
			# ruis-achtige vulling opleveren.
			if c.v >= 0.18 and c.v < 0.34:
				dark = Color(dark.r + c.r, dark.g + c.g, dark.b + c.b, 1.0)
				n_dark += 1
			elif c.v >= 0.34 and c.v < 0.62:
				light = Color(light.r + c.r, light.g + c.g, light.b + c.b, 1.0)
				n_light += 1
	if n_dark > 0:
		dark = Color(dark.r / n_dark, dark.g / n_dark, dark.b / n_dark, 1.0)
	else:
		dark = Color(0.12, 0.10, 0.14, 1.0)
	if n_light > 0:
		light = Color(light.r / n_light, light.g / n_light, light.b / n_light, 1.0)
	else:
		light = dark.lightened(0.25)

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for y in T:
		for x in T:
			var r := rng.randf()
			var c := dark.lerp(light, 0.5)
			if r > 0.82:
				c = light
			elif r > 0.55:
				c = dark.lerp(light, 0.72)
			elif r > 0.22:
				c = dark.lerp(light, 0.30)
			else:
				c = dark
			img.set_pixel(x, y, c)
	return img

## `over` bovenop `under` samenstellen (alfa-compositie), zodat half-doorzichtige
## randtegels een massieve achtergrond krijgen.
func _over(under: Image, over: Image) -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for y in T:
		for x in T:
			var u := under.get_pixel(x, y)
			var o := over.get_pixel(x, y)
			img.set_pixel(x, y, u.lerp(o, o.a) if o.a > 0.0 else u)
	return img

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
