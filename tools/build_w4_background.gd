extends SceneTree

## Bouwt de drie parallaxlagen voor Wereld 4 (Jungle) uit de OPP-jungleprops
## (CC0, zie assets/CREDITS.md) naar assets/sprites/backgrounds/world4/.
##
## Opzet als bij Wereld 1/3: elke laag is 240px hoog en wordt in
## ParallaxBGJungle.tscn op schaal 3 getekend, dus precies één schermhoogte.
## `back` is dekkend (de basis), `far` en `middle` hebben transparantie zodat de
## lagen erachter doorschijnen. Hoe dichterbij, hoe donkerder en hoe groter —
## zo ontstaat er dieptewerking zonder dat de achtergrond de speler overschreeuwt.
##
## Draaien: Godot --headless --path . --script tools/build_w4_background.gd
## Daarna:  Godot --headless --path . --import

const DIR := "/Users/wb-antal/claude-projecten/Flint-Game/assets/sprites/"
const OUT := DIR + "backgrounds/world4/"
const H := 240

# Regio's in decor/tree_dark.png, gevonden met een vlekken-analyse.
const TREE := Rect2i(0, 99, 304, 253)        # stam met takken
const CANOPY_A := Rect2i(0, 0, 64, 96)       # donkere bladerkroon
const CANOPY_B := Rect2i(75, 9, 73, 80)      # teal bladerkroon
const CANOPY_C := Rect2i(160, 0, 64, 96)
const CANOPY_D := Rect2i(235, 9, 73, 80)
const BUSH_A := Rect2i(192, 192, 64, 64)     # heldergroene struik
const BUSH_B := Rect2i(213, 274, 61, 57)
# Bijna-verticaal stuk van de touwring in decor/vines.png — losse liaan-sliert.
const ROPE := Rect2i(16, 150, 22, 104)

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	var tree := Image.load_from_file(DIR + "tiles/world4_jungle/decor/tree_dark.png")
	var vines := Image.load_from_file(DIR + "tiles/world4_jungle/decor/vines.png")
	if tree == null or vines == null:
		push_error("bron-decor ontbreekt")
		quit(1)
		return
	var ok := true
	ok = _save(_back(tree), "back.png") and ok
	ok = _save(_far(tree), "far.png") and ok
	ok = _save(_middle(tree, vines), "middle.png") and ok
	quit(0 if ok else 1)

## Verste laag: dekkende, nevelige jungle-verte met een silhouet-boomlijn.
func _back(tree: Image) -> Image:
	_rng.seed = 4101
	var w := 608
	var img := Image.create(w, H, false, Image.FORMAT_RGBA8)
	for y in H:
		var t := float(y) / float(H - 1)
		# Bovenin licht doorschijnend groen (zon door het bladerdak), onderin
		# het donkere, vochtige onderhout.
		var c := Color(0.42, 0.63, 0.45).lerp(Color(0.09, 0.21, 0.18), pow(t, 0.75))
		for x in w:
			img.set_pixel(x, y, c)
	# Verre boomlijn: kleine, sterk vervaagde kronen op ~2/3 hoogte.
	var x := -20
	while x < w + 20:
		var reg: Rect2i = [CANOPY_A, CANOPY_B, CANOPY_C, CANOPY_D][_rng.randi() % 4]
		var sc := _rng.randf_range(0.34, 0.52)
		var yy := 108 + _rng.randi_range(-16, 14)
		_stamp(img, tree, reg, x, yy, sc, Color(0.30, 0.45, 0.40), 0.55)
		x += _rng.randi_range(26, 46)
	# Tweede, iets dichterbije rij kronen.
	x = -30
	while x < w + 20:
		var reg2: Rect2i = [CANOPY_A, CANOPY_C][_rng.randi() % 2]
		var sc2 := _rng.randf_range(0.5, 0.75)
		_stamp(img, tree, reg2, x, 132 + _rng.randi_range(-10, 18), sc2, Color(0.20, 0.34, 0.30), 0.75)
		x += _rng.randi_range(40, 64)
	return img

## Middenlaag: stammen met kronen, halfdonker.
func _far(tree: Image) -> Image:
	_rng.seed = 4102
	var w := 704
	var img := Image.create(w, H, false, Image.FORMAT_RGBA8)
	var x := -40
	while x < w + 40:
		var sc := _rng.randf_range(0.42, 0.60)
		var th: int = int(TREE.size.y * sc)
		_stamp(img, tree, TREE, x, H - th + _rng.randi_range(-6, 10), sc, Color(0.22, 0.33, 0.26), 0.85)
		x += _rng.randi_range(78, 128)
	x = -20
	while x < w + 20:
		var reg: Rect2i = [CANOPY_B, CANOPY_D][_rng.randi() % 2]
		var sc2 := _rng.randf_range(0.55, 0.85)
		_stamp(img, tree, reg, x, -10 + _rng.randi_range(0, 22), sc2, Color(0.18, 0.30, 0.24), 0.9)
		x += _rng.randi_range(44, 70)
	return img

## Dichtstbijzijnde laag: grote donkere stammen, hangende lianen bovenin en
## struiken langs de onderrand.
func _middle(tree: Image, vines: Image) -> Image:
	_rng.seed = 4103
	var w := 736
	var img := Image.create(w, H, false, Image.FORMAT_RGBA8)
	var x := -60
	while x < w + 60:
		var sc := _rng.randf_range(0.8, 1.05)
		var th: int = int(TREE.size.y * sc)
		_stamp(img, tree, TREE, x, H - th + _rng.randi_range(6, 26), sc, Color(0.11, 0.18, 0.15), 0.95)
		x += _rng.randi_range(150, 240)
	# Hangende lianen vanaf de bovenrand. Het lianen-vel is eigenlijk één grote
	# touwring; ROPE is het bijna-verticale linkerstuk daarvan, dat zich onder
	# elkaar laat herhalen tot een slierten van wisselende lengte.
	x = 8
	while x < w:
		var vh := _rng.randi_range(38, 104)
		var vy := -_rng.randi_range(0, 12)
		var drawn := 0
		while drawn < vh:
			var piece := mini(ROPE.size.y, vh - drawn)
			_stamp(img, vines, ROPE, x, vy + drawn, 1.0, Color(0.14, 0.24, 0.18), 0.9, piece)
			drawn += piece
		x += _rng.randi_range(44, 92)
	# Struiken op de onderrand.
	x = -10
	while x < w + 10:
		var reg: Rect2i = [BUSH_A, BUSH_B][_rng.randi() % 2]
		var sc2 := _rng.randf_range(0.7, 1.1)
		var bh: int = int(reg.size.y * sc2)
		_stamp(img, tree, reg, x, H - bh + _rng.randi_range(2, 14), sc2, Color(0.10, 0.17, 0.13), 0.95)
		x += _rng.randi_range(38, 70)
	return img

## Tekent `region` uit `src` op (x, y) in `dst`, geschaald met nearest-neighbour,
## getint naar `tint` en met `alpha` dekking. `clip_h` > 0 knipt de hoogte af
## (voor hangende lianen van wisselende lengte).
func _stamp(dst: Image, src: Image, region: Rect2i, x: int, y: int, scale: float,
		tint: Color, alpha: float, clip_h: int = 0) -> void:
	var dw: int = int(region.size.x * scale)
	var dh: int = int(region.size.y * scale)
	if clip_h > 0:
		dh = mini(dh, clip_h)
	for dy in dh:
		var ty := y + dy
		if ty < 0 or ty >= dst.get_height():
			continue
		var sy: int = region.position.y + int(dy / scale)
		if sy >= region.position.y + region.size.y:
			continue
		for dx in dw:
			var tx := x + dx
			if tx < 0 or tx >= dst.get_width():
				continue
			var sx: int = region.position.x + int(dx / scale)
			if sx >= region.position.x + region.size.x:
				continue
			var c := src.get_pixel(sx, sy)
			if c.a < 0.5:
				continue
			# Silhouetteren: de eigen helderheid blijft licht meewegen zodat er
			# nog vorm in zit, maar de kleur wordt die van de dieptelaag.
			var shade := clampf(0.75 + c.v * 0.5, 0.0, 1.4)
			var col := Color(tint.r * shade, tint.g * shade, tint.b * shade, 1.0)
			var under := dst.get_pixel(tx, ty)
			var a: float = alpha
			var out_a: float = a + under.a * (1.0 - a)
			dst.set_pixel(tx, ty, Color(
				(col.r * a + under.r * under.a * (1.0 - a)) / maxf(out_a, 0.001),
				(col.g * a + under.g * under.a * (1.0 - a)) / maxf(out_a, 0.001),
				(col.b * a + under.b * under.a * (1.0 - a)) / maxf(out_a, 0.001),
				out_a))

func _save(img: Image, name: String) -> bool:
	if img.save_png(OUT + name) != OK:
		push_error("schrijven mislukt: " + OUT + name)
		return false
	print("geschreven: %s%s (%dx%d)" % [OUT, name, img.get_width(), img.get_height()])
	return true
