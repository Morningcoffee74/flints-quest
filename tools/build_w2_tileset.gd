extends SceneTree

## Bouwt assets/sprites/tiles/world2_water/tileset.png (112×144, 16px-tegels)
## uit de losse koraal-stukken van ansimuz' "Underwater Diving Pack" (CC0,
## coral_source.png). De tegels komen op EXACT dezelfde atlas-coördinaten te
## staan als in world1_tileset.tres, zodat Terrain.gd ongewijzigd werkt:
##   (1,5)(2,5)(3,5) = top-links/-midden/-rechts   (rand met lichtgroene algen)
##   (1,6)(2,6)(3,6) = midden-rij                   (rafelige zijkanten)
##   (1,7)(2,7)(3,7) = lage rij
##   (5,5)           = massief binnenwerk
##   (1,1)(1,2)(1,3) = pilaar top/midden/laag
## Draaien: Godot --headless --script tools/build_w2_tileset.gd
## Daarna: Godot --headless --path . --import

const SRC := "res://assets/sprites/tiles/world2_water/coral_source.png"
const OUT := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/tiles/world2_water/tileset.png"
const T := 16

var _src: Image

func _init() -> void:
	_src = Image.load_from_file(ProjectSettings.globalize_path(SRC))
	if _src == null:
		push_error("kan bron niet laden: " + SRC)
		quit(1)
		return
	var out := Image.create(112, 144, false, Image.FORMAT_RGBA8)

	# Bronvensters (x, y) in coral_source.png — zie bbox-analyse in de sessie-log.
	var cap_mid   := _win(48, 110)    # groene algen-kap uit de lange grondstrook
	var cap_left  := _win(36, 110)    # kap-stuk voor de linkerhoek (zijkant komt uit het masker)
	var cap_right := _win(148, 110)   # kap-stuk voor de rechterhoek
	var mid_left  := _win(214, 28)    # rafelige linkerrand (stuk met bulten links)
	var mid_right := _win(298, 28)    # gespiegeld stuk: bulten rechts
	var low_left  := _win(214, 52)
	var low_right := _win(298, 52)
	var mid_mid   := _win(64, 130)
	var low_mid   := _win(96, 150)
	var solid     := _win(128, 134)

	var top_left  := _mask_rows(cap_left, mid_left, 8)
	var top_right := _mask_rows(cap_right, mid_right, 8)

	var pillar_top := _split(_mask_rows(cap_mid, mid_left, 8), _mask_rows(cap_mid, mid_right, 8))
	var pillar_mid := _split(mid_left, mid_right)
	var pillar_low := _split(low_left, low_right)

	_put(out, 1, 5, top_left)
	_put(out, 2, 5, cap_mid)
	_put(out, 3, 5, top_right)
	_put(out, 1, 6, mid_left)
	_put(out, 2, 6, mid_mid)
	_put(out, 3, 6, mid_right)
	_put(out, 1, 7, low_left)
	_put(out, 2, 7, low_mid)
	_put(out, 3, 7, low_right)
	_put(out, 5, 5, solid)
	_put(out, 1, 1, pillar_top)
	_put(out, 1, 2, pillar_mid)
	_put(out, 1, 3, pillar_low)

	var err := out.save_png(OUT)
	if err != OK:
		push_error("schrijven mislukt: %d" % err)
		quit(1)
		return
	print("KLAAR: tileset.png geschreven (112x144)")
	quit(0)

func _win(x: int, y: int) -> Image:
	return _src.get_region(Rect2i(x, y, T, T))

## Kopie van `base` waarvan de alpha vanaf rij `from_row` vermenigvuldigd wordt
## met de alpha van `mask` — geeft de kap-tegel dezelfde rafelige zijkant als
## de tegel eronder, terwijl de algen-kap bovenin intact blijft.
func _mask_rows(base: Image, mask: Image, from_row: int) -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for y in T:
		for x in T:
			var c := base.get_pixel(x, y)
			if y >= from_row and mask.get_pixel(x, y).a < 0.5:
				c.a = 0.0
			img.set_pixel(x, y, c)
	return img

## Linkerhelft uit `left`, rechterhelft uit `right` — een 1 tegel brede pilaar
## met aan beide kanten een rafelige rand.
func _split(left: Image, right: Image) -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for y in T:
		for x in T:
			img.set_pixel(x, y, left.get_pixel(x, y) if x < T / 2 else right.get_pixel(x, y))
	return img

func _put(out: Image, col: int, row: int, tile: Image) -> void:
	out.blit_rect(tile, Rect2i(0, 0, T, T), Vector2i(col * T, row * T))
