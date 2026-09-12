extends SceneTree

## Bouwt de vijand-sprites voor Wereld 4 (Jungle).
##
## 1. Aap + banaan: het OPP-bronvel `Monkey_Source.png` is één kolom van drie
##    cellen van 48×48 (aap, twee kleine bananen, één grote banaan). Die wordt
##    gesplitst in losse, strak bijgesneden sprites.
## 2. Gorilla-eindbaas: omkleuring van de Minotaurus (chierit, itch.io) zoals
##    de Stenen Golem uit de Frost Guardian is gemaakt — zie
##    tools/build_stone_golem.gd. De vacht wordt bijna zwart, het lichte
##    "pantser" (en de hoorns, die dezelfde kleuren delen) wordt donkergrijs
##    zodat het als vacht/schaduw leest in plaats van als harnas, en de oranje
##    bijlsteel wordt hout: de gorilla zwaait met een afgerukte tak.
##    Het bronvel is 4608×480 = 16 × 3 cellen van 288×160, rijen:
##      0 idle (16 frames) · 1 walk (12) · 2 attack (16)
##    Er is GEEN hurt- of death-rij; Boss.gd valt daarvoor terug op een tween.
##
## Draaien: Godot --headless --path . --script tools/build_w4_enemies.gd
## Daarna:  Godot --headless --path . --import

const ROOT := "/Users/wb-antal/claude-projecten/Flint-Game/"
const MONKEY_SRC := ROOT + "assets/sprites/enemies/common/Monkey/Monkey_Source.png"
const MONKEY_DIR := ROOT + "assets/sprites/enemies/common/Monkey/"
const MINO_SRC := ROOT + "assets/sprites/enemies/common/Endboss/mino_v1.1_free/animations/minotaur_288x160_SpriteSheet.png"
const GORILLA_OUT := ROOT + "assets/sprites/enemies/world4/Gorilla.png"

func _init() -> void:
	var ok := _monkey()
	ok = _gorilla() and ok
	quit(0 if ok else 1)

func _monkey() -> bool:
	var src := Image.load_from_file(MONKEY_SRC)
	if src == null:
		push_error("aap-bron ontbreekt")
		return false
	var monkey := src.get_region(Rect2i(5, 3, 30, 45))
	var banana := src.get_region(Rect2i(1, 96, 40, 37))
	var ok := _save(monkey, MONKEY_DIR + "Monkey.png")
	ok = _save(banana, MONKEY_DIR + "Banana.png") and ok
	return ok

func _gorilla() -> bool:
	var src := Image.load_from_file(MINO_SRC)
	if src == null:
		push_error("minotaurus-bron ontbreekt")
		return false
	var out := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a <= 0.0:
				out.set_pixel(x, y, c)
				continue
			out.set_pixel(x, y, _remap(c))
	return _save(out, GORILLA_OUT)

## Kleurafbeelding minotaurus → gorilla.
func _remap(c: Color) -> Color:
	var h := c.h
	var s := c.s
	var v := c.v
	# Lichte, weinig verzadigde tinten = hoorns, been-/armpantser en het
	# bijlblad. Die worden donkergrijze vacht/schaduw, zodat er geen wit
	# harnas en geen oplichtende hoorns meer overblijft.
	if s < 0.28:
		return Color.from_hsv(0.08, 0.14, clampf(v * 0.56, 0.08, 0.50), c.a)
	# Fel oranje/rood = de bijlsteel en de banden erop → houtbruin (een tak).
	if (h < 0.055 or h > 0.93) and s > 0.45:
		return Color.from_hsv(0.075, clampf(s * 0.80, 0.0, 0.70), clampf(v * 0.80, 0.10, 0.62), c.a)
	# De rest is de bruine vacht → donker houtskoolgrijs met een warme zweem.
	# Niet bijna-zwart: de jungle-achtergrond is zelf al donker, dus dan valt de
	# eindbaas weg tegen de bomen.
	return Color.from_hsv(0.07, clampf(s * 0.32, 0.0, 0.24), clampf(v * 0.62, 0.06, 0.58), c.a)

func _save(img: Image, path: String) -> bool:
	if img.save_png(path) != OK:
		push_error("schrijven mislukt: " + path)
		return false
	print("geschreven: %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	return true
